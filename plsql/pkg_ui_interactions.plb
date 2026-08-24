CREATE OR REPLACE PACKAGE BODY pkg_ui_interactions AS

    gc_app_id CONSTANT NUMBER := 121;

    -- =========================================================================
    -- POST_INTERACTION
    -- =========================================================================
    -- POST a note to Fusion via the addInteraction action endpoint.
    -- Uses gc_post_credential (logged-in user's Fusion session via OAuth).
    -- NEVER raises — returns result string so caller can proceed safely.
    -- =========================================================================
    FUNCTION post_interaction (
        p_context_type_code IN VARCHAR2,
        p_context_id        IN NUMBER,
        p_person_id         IN NUMBER,
        p_note_text         IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_url      VARCHAR2(2000);
        l_payload  CLOB;
        l_response CLOB;
        l_status   NUMBER;
        l_result   VARCHAR2(200);
        l_err_msg  VARCHAR2(4000);
    BEGIN
        l_url := RTRIM(pkg_bicc_common.gc_fa_base_url, '/')
            || '/hcmRestApi/resources/11.13.18.05'
            || '/recruitingUIInteractions/action/addInteraction';

        -- Build JSON payload
        SELECT json_object(
                   'interactionDate'     VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD'),
                   'interactionText'     VALUE p_note_text,
                   'interactionTypeCode' VALUE 'GCS_NOTES',
                   'contextTypeCode'     VALUE p_context_type_code,
                   'contextIds'          VALUE json_array(p_context_id),
                   'personIds'           VALUE json_array(p_person_id)
                   RETURNING CLOB
               )
          INTO l_payload
          FROM dual;

        -- POST with user's Fusion credential (OAuth token from APEX session)
        apex_web_service.g_request_headers.DELETE;
        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/vnd.oracle.adf.action+json';
        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url                  => l_url,
            p_http_method          => 'POST',
            p_body                 => l_payload,
            p_credential_static_id => gc_post_credential
        );

        l_status := apex_web_service.g_status_code;

        -- Extract result status from response JSON
        BEGIN
            SELECT jt.result_status
              INTO l_result
              FROM json_table(l_response, '$.result'
                  COLUMNS (result_status VARCHAR2(200) PATH '$.Status')
              ) jt;
        EXCEPTION
            WHEN OTHERS THEN
                l_result := 'PARSE_ERROR';
        END;

        -- Log the attempt
        INSERT INTO bicc_load_log (load_type, step, rows_processed, status, error_message)
        VALUES (
            'UI_INTERACTION',
            'POST_' || p_context_type_code,
            1,
            CASE WHEN l_status BETWEEN 200 AND 299 AND l_result = 'ORA_SUCCESS'
                 THEN 'SUCCESS' ELSE 'ERROR' END,
            CASE WHEN l_status NOT BETWEEN 200 AND 299 OR l_result != 'ORA_SUCCESS'
                 THEN 'HTTP ' || l_status || ': '
                      || DBMS_LOB.SUBSTR(l_response, 2000, 1)
            END
        );
        COMMIT;

        RETURN l_result;

    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            INSERT INTO bicc_load_log (load_type, step, rows_processed, status, error_message)
            VALUES ('UI_INTERACTION', 'POST_EXCEPTION', 0, 'ERROR', l_err_msg);
            COMMIT;
            RETURN 'EXCEPTION: ' || l_err_msg;
    END post_interaction;

    -- =========================================================================
    -- SYNC_PERSON
    -- =========================================================================
    -- GET all interactions for a person from Fusion and merge into local tables.
    -- 3-way match per interaction:
    --   1) interaction_id already exists → UPDATE text
    --   2) text+context match with interaction_id IS NULL → link it
    --   3) no match → INSERT (Fusion-native note)
    -- =========================================================================
    PROCEDURE sync_person (p_person_id IN NUMBER)
    IS
        l_url      VARCHAR2(2000);
        l_body     CLOB;
        l_synced   NUMBER := 0;
        l_rows     NUMBER;
        l_err_msg  VARCHAR2(4000);
    BEGIN
        -- Clear any custom headers left from POST calls
        apex_web_service.g_request_headers.DELETE;

        l_url := pkg_bicc_common.gc_fa_base_url
            || '/hcmRestApi/resources/11.13.18.05/recruitingUIInteractions'
            || '?q=PersonId=' || p_person_id
            || '&limit=500';

        l_body := apex_web_service.make_rest_request(
            p_url                  => l_url,
            p_http_method          => 'GET',
            p_credential_static_id => gc_sync_credential
        );

        IF apex_web_service.g_status_code NOT BETWEEN 200 AND 299 THEN
            INSERT INTO bicc_load_log (load_type, step, rows_processed, status, error_message)
            VALUES ('UI_INTERACTION', 'SYNC_PERSON_' || p_person_id, 0, 'ERROR',
                    'HTTP ' || apex_web_service.g_status_code
                    || ': ' || DBMS_LOB.SUBSTR(l_body, 2000, 1));
            COMMIT;
            RETURN;
        END IF;

        -- Process ORA_SUBMISSION interactions → candidate_note
        FOR r IN (
            SELECT jt.*
              FROM json_table(l_body, '$.items[*]'
                  COLUMNS (
                      interaction_id    NUMBER         PATH '$.InteractionId',
                      context_id        NUMBER         PATH '$.ContextId',
                      context_type_code VARCHAR2(30)   PATH '$.ContextTypeCode',
                      interaction_date  VARCHAR2(30)   PATH '$.InteractionDate',
                      interaction_text  VARCHAR2(4000) PATH '$.Text',
                      display_name      VARCHAR2(240)  PATH '$.DisplayName'
                  )
              ) jt
             WHERE jt.context_type_code = 'ORA_SUBMISSION'
               AND jt.interaction_id IS NOT NULL
        ) LOOP
            -- 1) Already synced by interaction_id
            UPDATE candidate_note
               SET note_text = r.interaction_text
             WHERE interaction_id = r.interaction_id;

            IF SQL%ROWCOUNT = 0 THEN
                -- 2) Match locally-created note (same text + same application)
                UPDATE candidate_note
                   SET interaction_id = r.interaction_id
                 WHERE interaction_id IS NULL
                   AND job_application_id = r.context_id
                   AND note_text = r.interaction_text
                   AND ROWNUM = 1;

                IF SQL%ROWCOUNT = 0 THEN
                    -- 3) Fusion-native note — insert
                    INSERT INTO candidate_note (
                        job_application_id, note_text, created_by, created_on,
                        interaction_id
                    ) VALUES (
                        r.context_id,
                        r.interaction_text,
                        r.display_name,
                        COALESCE(
                            TO_DATE(r.interaction_date, 'YYYY-MM-DD'),
                            TRUNC(SYSDATE)
                        ),
                        r.interaction_id
                    );
                END IF;
            END IF;

            l_synced := l_synced + 1;
        END LOOP;

        -- Process ORA_CAND_PROFILE interactions → applicant_note
        FOR r IN (
            SELECT jt.*
              FROM json_table(l_body, '$.items[*]'
                  COLUMNS (
                      interaction_id    NUMBER         PATH '$.InteractionId',
                      context_id        NUMBER         PATH '$.ContextId',
                      context_type_code VARCHAR2(30)   PATH '$.ContextTypeCode',
                      interaction_date  VARCHAR2(30)   PATH '$.InteractionDate',
                      interaction_text  VARCHAR2(4000) PATH '$.Text',
                      display_name      VARCHAR2(240)  PATH '$.DisplayName'
                  )
              ) jt
             WHERE jt.context_type_code = 'ORA_CAND_PROFILE'
               AND jt.interaction_id IS NOT NULL
        ) LOOP
            -- 1) Already synced by interaction_id
            UPDATE applicant_note
               SET note_text = r.interaction_text
             WHERE interaction_id = r.interaction_id;

            IF SQL%ROWCOUNT = 0 THEN
                -- 2) Match locally-created note (same text + same person)
                UPDATE applicant_note
                   SET interaction_id = r.interaction_id
                 WHERE interaction_id IS NULL
                   AND person_id = p_person_id
                   AND note_text = r.interaction_text
                   AND ROWNUM = 1;

                IF SQL%ROWCOUNT = 0 THEN
                    -- 3) Fusion-native note — insert
                    INSERT INTO applicant_note (
                        person_id, note_text, created_by, created_on,
                        interaction_id
                    ) VALUES (
                        p_person_id,
                        r.interaction_text,
                        r.display_name,
                        COALESCE(
                            TO_DATE(r.interaction_date, 'YYYY-MM-DD'),
                            TRUNC(SYSDATE)
                        ),
                        r.interaction_id
                    );
                END IF;
            END IF;

            l_synced := l_synced + 1;
        END LOOP;

        COMMIT;

        INSERT INTO bicc_load_log (load_type, step, rows_processed, status, error_message)
        VALUES ('UI_INTERACTION', 'SYNC_PERSON_' || p_person_id, l_synced, 'SUCCESS', NULL);
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            ROLLBACK;
            INSERT INTO bicc_load_log (load_type, step, rows_processed, status, error_message)
            VALUES ('UI_INTERACTION', 'SYNC_PERSON_ERR_' || p_person_id, 0, 'ERROR', l_err_msg);
            COMMIT;
    END sync_person;

    -- =========================================================================
    -- SYNC_ALL
    -- =========================================================================
    -- Nightly bulk sync. Iterates distinct person_ids from local tables +
    -- JOB_APPLICANTS_R join, calls sync_person for each.
    -- Creates APEX session if called from DBMS_SCHEDULER.
    -- =========================================================================
    PROCEDURE sync_all
    IS
        l_need_session BOOLEAN := FALSE;
        l_count        NUMBER  := 0;
        l_errors       NUMBER  := 0;
        l_err_msg      VARCHAR2(4000);
    BEGIN
        -- Create APEX session when called from scheduler (no session context)
        IF apex_application.g_flow_id IS NULL THEN
            apex_session.create_session(
                p_app_id   => gc_app_id,
                p_page_id  => 1,
                p_username => 'ADMIN'
            );
            l_need_session := TRUE;
        END IF;

        FOR r IN (
            SELECT DISTINCT person_id FROM (
                -- Persons with local application-level notes
                SELECT a."CANDIDATEPERSONID" AS person_id
                  FROM candidate_note cn
                  JOIN job_applicants_r a
                    ON a."JOBAPPLICATIONID" = cn.job_application_id
                 WHERE a."CANDIDATEPERSONID" IS NOT NULL
                UNION
                -- Persons with local person-level notes
                SELECT person_id FROM applicant_note
            )
            WHERE person_id IS NOT NULL
        ) LOOP
            BEGIN
                sync_person(r.person_id);
                l_count := l_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    l_err_msg := SQLERRM;
                    l_errors := l_errors + 1;
                    INSERT INTO bicc_load_log (
                        load_type, step, rows_processed, status, error_message
                    ) VALUES (
                        'UI_INTERACTION', 'SYNC_ALL_ERR_' || r.person_id,
                        0, 'ERROR', l_err_msg
                    );
                    COMMIT;
            END;
        END LOOP;

        INSERT INTO bicc_load_log (load_type, step, rows_processed, status, error_message)
        VALUES ('UI_INTERACTION', 'SYNC_ALL_COMPLETE', l_count, 'SUCCESS',
                CASE WHEN l_errors > 0
                     THEN l_errors || ' person(s) failed' END);
        COMMIT;

        IF l_need_session THEN
            apex_session.delete_session;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            INSERT INTO bicc_load_log (load_type, step, rows_processed, status, error_message)
            VALUES ('UI_INTERACTION', 'SYNC_ALL_EXCEPTION', l_count, 'ERROR', l_err_msg);
            COMMIT;

            IF l_need_session THEN
                apex_session.delete_session;
            END IF;
            RAISE;
    END sync_all;

END pkg_ui_interactions;
/

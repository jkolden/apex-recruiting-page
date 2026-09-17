CREATE OR REPLACE PACKAGE BODY pkg_eff_update AS

    -- =========================================================================
    -- Private constants
    -- =========================================================================
    gc_credential   CONSTANT VARCHAR2(60)  := 'gcs_reports';
    gc_context_path CONSTANT VARCHAR2(200) :=
        '/child/PersonExtraInformationContextGCS__Recruiting__DetailsprivateVO';

    -- =========================================================================
    -- Private: build the base URL to the personEFF level
    -- =========================================================================
    FUNCTION eff_base_url (p_person_id IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        RETURN pkg_bicc_common.gc_fa_base_url
            || '/hcmRestApi/resources/11.13.18.05/personExtraInformation/'
            || p_person_id
            || '/child/personEFF/'
            || p_person_id;
    END eff_base_url;

    -- =========================================================================
    -- REFRESH_EFF_ROW
    -- =========================================================================
    -- GET current EFF "GCS Recruiting Details" from Fusion REST and MERGE
    -- into ext_flex_stg so the local recruiting report reflects current data.
    -- =========================================================================
    -- Attribute → PEI mapping (from EFF Analysis.xlsx / ext_flex_recruiting_v):
    --   Char: PEI_INFORMATION1  = interviewNotes          (seq 10)  LOV
    --         PEI_INFORMATION2  = certification            (seq 30)  LOV
    --         PEI_INFORMATION3  = sled                     (seq 40)  LOV
    --         PEI_INFORMATION4  = referenceCheck           (seq 50)  LOV
    --         PEI_INFORMATION5  = workKeys                 (seq 60)  LOV
    --         PEI_INFORMATION6  = processingOwner          (seq 90)
    --         PEI_INFORMATION7  = comments                 (seq 130)
    --         PEI_INFORMATION8  = payGrade                 (seq 110)
    --         PEI_INFORMATION9  = payStep                  (seq 120)
    --         PEI_INFORMATION10 = additionalComments       (seq 140)
    --         PEI_INFORMATION11 = contractType             (seq 150) LOV
    --         PEI_INFORMATION12 = contractStip1            (seq 160) LOV
    --         PEI_INFORMATION13 = contractStip2            (seq 170) LOV
    --         PEI_INFORMATION14 = contractStip3            (seq 180) LOV
    --         PEI_INFORMATION15 = rehireEligibility        (seq 190) LOV
    --         PEI_INFORMATION16 = teacherSubjectArea       (seq 210) LOV
    --   Date: PEI_INFORMATION_DATE1 = proposedEffectiveDate (seq 70)
    --   Num:  PEI_INFORMATION_NUMBER1 = teacherAssessmentScore   (seq 20)
    --         PEI_INFORMATION_NUMBER2 = additionalFte            (seq 80)
    --         PEI_INFORMATION_NUMBER3 = teacherYearsOfExperience (seq 200)
    --         PEI_INFORMATION_NUMBER4 = educatorId               (seq 220)
    --         PEI_INFORMATION_NUMBER5 = cateExperience           (seq 230)
    --         PEI_INFORMATION_NUMBER6 = fte                      (seq 240)
    -- =========================================================================
    PROCEDURE refresh_eff_row (p_person_id IN NUMBER)
    IS
        l_url      VARCHAR2(4000);
        l_response CLOB;
        l_status   NUMBER;
    BEGIN
        l_url := eff_base_url(p_person_id) || gc_context_path;

        apex_web_service.g_request_headers.DELETE;

        l_response := apex_web_service.make_rest_request(
            p_url                  => l_url,
            p_http_method          => 'GET',
            p_credential_static_id => gc_credential
        );

        l_status := apex_web_service.g_status_code;

        IF l_status NOT BETWEEN 200 AND 299 THEN
            INSERT INTO bicc_load_log (
                load_type, step, rows_processed, status, error_message
            ) VALUES (
                'EFF_UPDATE', 'REFRESH_GET_' || p_person_id, 0, 'WARN',
                'Refresh GET failed (HTTP ' || l_status || '): '
                    || DBMS_LOB.SUBSTR(l_response, 2000, 1)
            );
            COMMIT;
            RETURN;
        END IF;

        IF json_value(l_response, '$.count' RETURNING NUMBER) = 0 THEN
            RETURN;  -- No row for this context
        END IF;

        MERGE INTO ext_flex_stg t
        USING (
            SELECT
                jt.person_extra_info_id,
                p_person_id                    AS person_id,
                jt.effective_start_date,
                jt.effective_end_date,
                -- Char: PEI_INFORMATION1-16
                jt.pei_info1,  jt.pei_info2,  jt.pei_info3,  jt.pei_info4,
                jt.pei_info5,  jt.pei_info6,  jt.pei_info7,  jt.pei_info8,
                jt.pei_info9,  jt.pei_info10, jt.pei_info11, jt.pei_info12,
                jt.pei_info13, jt.pei_info14, jt.pei_info15, jt.pei_info16,
                -- Date: PEI_INFORMATION_DATE1
                jt.pei_date1,
                -- Number: PEI_INFORMATION_NUMBER1-6
                jt.pei_num1, jt.pei_num2, jt.pei_num3,
                jt.pei_num4, jt.pei_num5, jt.pei_num6
            FROM json_table(l_response, '$.items[0]'
                COLUMNS (
                    person_extra_info_id NUMBER         PATH '$.PersonExtraInfoId',
                    effective_start_date VARCHAR2(50)   PATH '$.EffectiveStartDate',
                    effective_end_date   VARCHAR2(50)   PATH '$.EffectiveEndDate',
                    -- Char columns
                    pei_info1  VARCHAR2(4000) PATH '$.interviewNotes',
                    pei_info2  VARCHAR2(4000) PATH '$.certification',
                    pei_info3  VARCHAR2(4000) PATH '$.sled',
                    pei_info4  VARCHAR2(4000) PATH '$.referenceCheck',
                    pei_info5  VARCHAR2(4000) PATH '$.workKeys',
                    pei_info6  VARCHAR2(4000) PATH '$.processingOwner',
                    pei_info7  VARCHAR2(4000) PATH '$.comments',
                    pei_info8  VARCHAR2(4000) PATH '$.payGrade',
                    pei_info9  VARCHAR2(4000) PATH '$.payStep',
                    pei_info10 VARCHAR2(4000) PATH '$.additionalComments',
                    pei_info11 VARCHAR2(4000) PATH '$.contractType',
                    pei_info12 VARCHAR2(4000) PATH '$.contractStip1',
                    pei_info13 VARCHAR2(4000) PATH '$.contractStip2',
                    pei_info14 VARCHAR2(4000) PATH '$.contractStip3',
                    pei_info15 VARCHAR2(4000) PATH '$.rehireEligibility',
                    pei_info16 VARCHAR2(4000) PATH '$.teacherSubjectArea',
                    -- Date column
                    pei_date1  VARCHAR2(50)   PATH '$.proposedEffectiveDate',
                    -- Number columns
                    pei_num1   VARCHAR2(50)   PATH '$.teacherAssessmentScore',
                    pei_num2   VARCHAR2(50)   PATH '$.additionalFte',
                    pei_num3   VARCHAR2(50)   PATH '$.teacherYearsOfExperience',
                    pei_num4   VARCHAR2(50)   PATH '$.educatorId',
                    pei_num5   VARCHAR2(50)   PATH '$.cateExperience',
                    pei_num6   VARCHAR2(50)   PATH '$.fte'
                )
            ) jt
            WHERE jt.person_extra_info_id IS NOT NULL
        ) s
        ON (t.person_extra_info_id = s.person_extra_info_id)
        WHEN MATCHED THEN UPDATE SET
            t.person_id            = s.person_id,
            t.effective_start_date = s.effective_start_date,
            t.effective_end_date   = s.effective_end_date,
            t.pei_info1  = s.pei_info1,   t.pei_info2  = s.pei_info2,
            t.pei_info3  = s.pei_info3,   t.pei_info4  = s.pei_info4,
            t.pei_info5  = s.pei_info5,   t.pei_info6  = s.pei_info6,
            t.pei_info7  = s.pei_info7,   t.pei_info8  = s.pei_info8,
            t.pei_info9  = s.pei_info9,   t.pei_info10 = s.pei_info10,
            t.pei_info11 = s.pei_info11,  t.pei_info12 = s.pei_info12,
            t.pei_info13 = s.pei_info13,  t.pei_info14 = s.pei_info14,
            t.pei_info15 = s.pei_info15,  t.pei_info16 = s.pei_info16,
            t.pei_date1  = s.pei_date1,
            t.pei_num1   = s.pei_num1,    t.pei_num2   = s.pei_num2,
            t.pei_num3   = s.pei_num3,    t.pei_num4   = s.pei_num4,
            t.pei_num5   = s.pei_num5,    t.pei_num6   = s.pei_num6,
            t.load_ts    = SYSTIMESTAMP
        WHEN NOT MATCHED THEN INSERT (
            person_extra_info_id,
            person_id,
            candidate_number,
            information_type,
            pei_information_category,
            effective_start_date,
            effective_end_date,
            pei_info1,  pei_info2,  pei_info3,  pei_info4,
            pei_info5,  pei_info6,  pei_info7,  pei_info8,
            pei_info9,  pei_info10, pei_info11, pei_info12,
            pei_info13, pei_info14, pei_info15, pei_info16,
            pei_date1,
            pei_num1, pei_num2, pei_num3, pei_num4, pei_num5, pei_num6,
            load_ts
        ) VALUES (
            s.person_extra_info_id,
            s.person_id,
            NULL,                           -- candidate_number: BIP will populate
            'GCS Recruiting Details',       -- information_type
            'GCS Recruiting Details',       -- pei_information_category
            s.effective_start_date,
            s.effective_end_date,
            s.pei_info1,  s.pei_info2,  s.pei_info3,  s.pei_info4,
            s.pei_info5,  s.pei_info6,  s.pei_info7,  s.pei_info8,
            s.pei_info9,  s.pei_info10, s.pei_info11, s.pei_info12,
            s.pei_info13, s.pei_info14, s.pei_info15, s.pei_info16,
            s.pei_date1,
            s.pei_num1, s.pei_num2, s.pei_num3, s.pei_num4, s.pei_num5, s.pei_num6,
            SYSTIMESTAMP
        );

        COMMIT;

    END refresh_eff_row;


    -- =========================================================================
    -- UPDATE_EFF_RECRUITING
    -- =========================================================================
    -- 1. GET the EFF context to obtain the self href (hex row key) + dates
    -- 2. PATCH with the caller's JSON payload + Effective-Of header
    -- 3. Refresh ext_flex_stg via refresh_eff_row
    -- =========================================================================
    PROCEDURE update_eff_recruiting (
        p_person_id  IN NUMBER,
        p_payload    IN CLOB
    )
    IS
        l_url        VARCHAR2(4000);
        l_response   CLOB;
        l_status     NUMBER;
        l_self_href  VARCHAR2(4000);
        l_start_date VARCHAR2(50);
        l_end_date   VARCHAR2(50);
    BEGIN
        -- =================================================================
        -- Step 1: GET to obtain self href and effective dates
        -- =================================================================
        l_url := eff_base_url(p_person_id) || gc_context_path;

        apex_web_service.g_request_headers.DELETE;

        l_response := apex_web_service.make_rest_request(
            p_url                  => l_url,
            p_http_method          => 'GET',
            p_credential_static_id => gc_credential
        );

        l_status := apex_web_service.g_status_code;

        IF l_status NOT BETWEEN 200 AND 299 THEN
            raise_application_error(-20100,
                'EFF GET failed (HTTP ' || l_status || '): '
                || DBMS_LOB.SUBSTR(l_response, 500, 1));
        END IF;

        IF json_value(l_response, '$.count' RETURNING NUMBER) = 0 THEN
            -- =============================================================
            -- No record exists — POST to create
            -- =============================================================
            l_url := eff_base_url(p_person_id) || gc_context_path;

            -- EffectiveStartDate goes in the Effective-Of header only,
            -- NOT in the JSON body (Fusion rejects it in the payload).
            DECLARE
                l_post_body CLOB   := p_payload;
                l_today     VARCHAR2(10) := TO_CHAR(SYSDATE, 'YYYY-MM-DD');
            BEGIN

                apex_web_service.g_request_headers.DELETE;
                apex_web_service.g_request_headers(1).name  := 'Content-Type';
                apex_web_service.g_request_headers(1).value := 'application/json';
                apex_web_service.g_request_headers(2).name  := 'Effective-Of';
                apex_web_service.g_request_headers(2).value :=
                    'RangeMode=UPDATE;RangeStartDate=' || l_today
                    || ';RangeEndDate=4712-12-31';

                l_response := apex_web_service.make_rest_request(
                    p_url                  => l_url,
                    p_http_method          => 'POST',
                    p_body                 => l_post_body,
                    p_credential_static_id => gc_credential
                );

                l_status := apex_web_service.g_status_code;
            END;

            INSERT INTO bicc_load_log (
                load_type, step, rows_processed, status, error_message
            ) VALUES (
                'EFF_UPDATE',
                'POST_CREATE_' || p_person_id,
                1,
                CASE WHEN l_status BETWEEN 200 AND 299 THEN 'SUCCESS' ELSE 'ERROR' END,
                CASE WHEN l_status NOT BETWEEN 200 AND 299
                     THEN 'HTTP ' || l_status || ': ' || DBMS_LOB.SUBSTR(l_response, 2000, 1)
                END
            );
            COMMIT;

            IF l_status NOT BETWEEN 200 AND 299 THEN
                raise_application_error(-20100,
                    'EFF POST (create) failed (HTTP ' || l_status || '): '
                    || DBMS_LOB.SUBSTR(l_response, 500, 1));
            END IF;

        ELSE
            -- =============================================================
            -- Record exists — PATCH to update
            -- =============================================================

            -- Extract self href (contains hex row key) and effective dates
            BEGIN
                SELECT jt.link_href, jt.eff_start, jt.eff_end
                  INTO l_self_href, l_start_date, l_end_date
                  FROM json_table(l_response, '$.items[0]'
                      COLUMNS (
                          eff_start VARCHAR2(50) PATH '$.EffectiveStartDate',
                          eff_end   VARCHAR2(50) PATH '$.EffectiveEndDate',
                          NESTED PATH '$.links[*]' COLUMNS (
                              link_rel  VARCHAR2(100)  PATH '$.rel',
                              link_href VARCHAR2(4000) PATH '$.href'
                          )
                      )
                  ) jt
                 WHERE jt.link_rel = 'self';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    raise_application_error(-20100,
                        'Could not extract self href from EFF response for person ID ' || p_person_id);
            END;

            apex_web_service.g_request_headers.DELETE;
            apex_web_service.g_request_headers(1).name  := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/json';
            apex_web_service.g_request_headers(2).name  := 'Effective-Of';
            apex_web_service.g_request_headers(2).value :=
                'RangeMode=UPDATE;RangeStartDate=' || l_start_date
                || ';RangeEndDate=' || l_end_date;

            l_response := apex_web_service.make_rest_request(
                p_url                  => l_self_href,
                p_http_method          => 'PATCH',
                p_body                 => p_payload,
                p_credential_static_id => gc_credential
            );

            l_status := apex_web_service.g_status_code;

            INSERT INTO bicc_load_log (
                load_type, step, rows_processed, status, error_message
            ) VALUES (
                'EFF_UPDATE',
                'PATCH_' || p_person_id,
                1,
                CASE WHEN l_status BETWEEN 200 AND 299 THEN 'SUCCESS' ELSE 'ERROR' END,
                CASE WHEN l_status NOT BETWEEN 200 AND 299
                     THEN 'HTTP ' || l_status || ': ' || DBMS_LOB.SUBSTR(l_response, 2000, 1)
                END
            );
            COMMIT;

            IF l_status NOT BETWEEN 200 AND 299 THEN
                raise_application_error(-20100,
                    'EFF PATCH failed (HTTP ' || l_status || '): '
                    || DBMS_LOB.SUBSTR(l_response, 500, 1));
            END IF;

        END IF;  -- count = 0 (POST) vs count > 0 (PATCH)

        -- =================================================================
        -- Step 3: Refresh local ext_flex_stg from Fusion
        -- =================================================================
        refresh_eff_row(p_person_id);

    END update_eff_recruiting;

END pkg_eff_update;
/

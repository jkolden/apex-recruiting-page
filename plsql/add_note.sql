-- Ajax Callback: ADD_NOTE (sequence 90)
-- Called by: candidate_notes_js (external JS file)
-- Purpose:   Add a note to a specific job application + dual-write to Fusion
-- Input:     g_x01 = job_application_id, g_x02 = note_text
-- Output:    JSON { status, notes: [...], note_count }
-- Tables:    candidate_note

DECLARE
    l_app_id    NUMBER        := TO_NUMBER(apex_application.g_x01);
    l_note_text VARCHAR2(4000):= SUBSTRB(apex_application.g_x02, 1, 4000);
    l_count     NUMBER;
BEGIN
    INSERT INTO candidate_note (job_application_id, note_text, created_by)
    VALUES (l_app_id, l_note_text,
            COALESCE(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER));

    -- Dual-write to Fusion (fire-and-forget)
    BEGIN
        DECLARE
            l_fusion_result VARCHAR2(200);
            l_person_id     NUMBER;
        BEGIN
            SELECT CANDIDATEPERSONID INTO l_person_id
              FROM (SELECT CANDIDATEPERSONID,
                           ROW_NUMBER() OVER (PARTITION BY JOBAPPLICATIONID
                                              ORDER BY "APEX$ROW_SYNC_TIMESTAMP" DESC) rn
                      FROM JOB_APPLICANTS_R
                     WHERE JOBAPPLICATIONID = l_app_id)
             WHERE rn = 1;

            l_fusion_result := pkg_ui_interactions.post_interaction(
                p_context_type_code => 'ORA_SUBMISSION',
                p_context_id        => l_app_id,
                p_person_id         => l_person_id,
                p_note_text         => l_note_text
            );

            IF l_fusion_result = 'ORA_SUCCESS' THEN
                pkg_ui_interactions.sync_person(l_person_id);
            END IF;
        END;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    -- Return updated notes list so the panel re-renders
    apex_json.open_object;
    apex_json.write('status', 'OK');

    apex_json.open_array('notes');
    FOR r IN (
        SELECT note_text,
               created_by,
               TO_CHAR(created_on, 'DD-Mon-YYYY HH24:MI') AS created_on
          FROM candidate_note
         WHERE job_application_id = l_app_id
         ORDER BY created_on DESC
    ) LOOP
        apex_json.open_object;
        apex_json.write('note_text',   r.note_text);
        apex_json.write('created_by',  r.created_by);
        apex_json.write('created_on',  r.created_on);
        apex_json.close_object;
    END LOOP;
    apex_json.close_array;

    SELECT COUNT(*) INTO l_count
      FROM candidate_note
     WHERE job_application_id = l_app_id;

    apex_json.write('note_count', l_count);
    apex_json.close_object;

EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write('status',  'ERROR');
        apex_json.write('message', SQLERRM);
        apex_json.close_object;
END;

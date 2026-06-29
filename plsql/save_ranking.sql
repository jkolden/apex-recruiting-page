-- Ajax Callback: SAVE_RANKING (sequence 50)
-- Called by: submitRanking() in ranking-drawer.js
-- Purpose:   Save or update an applicant ranking (MERGE pattern)
-- Input:     g_x01 = job_application_id, g_x02 = score (1-5),
--            g_x03 = recommendation text, g_x04 = notes
-- Output:    JSON { status: "OK" } or { status: "ERROR", message: "..." }
-- Tables:    applicant_ranking

DECLARE
    l_app_id NUMBER       := TO_NUMBER(apex_application.g_x01);
    l_score  NUMBER       := CASE WHEN apex_application.g_x02 IS NOT NULL
                                  THEN TO_NUMBER(apex_application.g_x02) END;
    l_text   VARCHAR2(30) := NULLIF(apex_application.g_x03, '');
    l_note   VARCHAR2(500):= NULLIF(apex_application.g_x04, '');
BEGIN
    MERGE INTO applicant_ranking t
    USING (SELECT l_app_id AS job_application_id FROM dual) s
    ON (t.job_application_id = s.job_application_id)
    WHEN MATCHED THEN UPDATE SET
        t.ranking_score = l_score,
        t.ranking_text  = l_text,
        t.ranking_note  = l_note,
        t.ranked_by     = :APP_USER,
        t.ranked_on     = SYSTIMESTAMP
    WHEN NOT MATCHED THEN INSERT
        (job_application_id, ranking_score, ranking_text, ranking_note,
         ranked_by, ranked_on)
    VALUES
        (l_app_id, l_score, l_text, l_note, :APP_USER, SYSTIMESTAMP);
    COMMIT;
    apex_json.open_object;
    apex_json.write('status', 'OK');
    apex_json.close_object;
EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write('status', 'ERROR');
        apex_json.write('message', SQLERRM);
        apex_json.close_object;
END;

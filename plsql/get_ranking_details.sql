-- Ajax Callback: GET_RANKING_DETAILS (sequence 40)
-- Called by: openRankingForm() in ranking-drawer.js
-- Purpose:   Load existing ranking for an applicant
-- Input:     g_x01 = job_application_id
-- Output:    JSON { candidate_name, ranking_score, ranking_text, ranking_note, ranked_by }
-- Tables:    RECRUITING_REPORT_V, applicant_ranking

DECLARE
    l_app_id NUMBER := TO_NUMBER(apex_application.g_x01);
    l_name   VARCHAR2(240);
    l_score  NUMBER;
    l_text   VARCHAR2(30);
    l_note   VARCHAR2(500);
    l_by     VARCHAR2(240);
BEGIN
    -- Get candidate name from the report view
    BEGIN
        SELECT NAME INTO l_name
        FROM RECRUITING_REPORT_V
        WHERE JOB_APPLICATION_ID = l_app_id
          AND ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN l_name := 'Unknown';
    END;
    -- Get existing ranking (if any)
    BEGIN
        SELECT ranking_score, ranking_text, ranking_note, ranked_by
        INTO l_score, l_text, l_note, l_by
        FROM applicant_ranking
        WHERE job_application_id = l_app_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;
    apex_json.open_object;
    apex_json.write('candidate_name', l_name);
    apex_json.write('ranking_score', l_score);
    apex_json.write('ranking_text', l_text);
    apex_json.write('ranking_note', l_note);
    apex_json.write('ranked_by', l_by);
    apex_json.close_object;
END;

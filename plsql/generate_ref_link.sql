-- Ajax Callback: GENERATE_REF_LINK (sequence 60)
-- Called by: openRefLinkForm() in ref-correction-link.js
-- Purpose:   Generate a secure one-time token URL for reference correction
-- Input:     g_x01 = job_application_id
-- Output:    JSON { status, url, candidate_name, candidate_email }
-- Package:   pkg_ref_correction.generate_token
-- Tables:    RECRUITING_CANDIDATES_R, JOB_APPLICANTS_R

DECLARE
    l_app_id NUMBER := TO_NUMBER(apex_application.g_x01);
    l_url    VARCHAR2(4000);
    l_email  VARCHAR2(500);
    l_name   VARCHAR2(500);
BEGIN
    l_url := pkg_ref_correction.generate_token(
        p_job_application_id => l_app_id,
        p_requested_by       => :APP_USER
    );

    BEGIN
        SELECT c.EMAIL INTO l_email
          FROM RECRUITING_CANDIDATES_R c
          JOIN JOB_APPLICANTS_R a
            ON a.CANDIDATEPERSONID = c.PERSONID
         WHERE a.JOBAPPLICATIONID = l_app_id
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN l_email := NULL;
    END;

    BEGIN
        SELECT CANDIDATENAME INTO l_name
          FROM JOB_APPLICANTS_R
         WHERE JOBAPPLICATIONID = l_app_id
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN l_name := 'Unknown';
    END;

    apex_json.open_object;
    apex_json.write('status', 'OK');
    apex_json.write('url', l_url);
    apex_json.write('candidate_name', l_name);
    apex_json.write('candidate_email', l_email);
    apex_json.close_object;
EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write('status', 'ERROR');
        apex_json.write('message', SQLERRM);
        apex_json.close_object;
END;

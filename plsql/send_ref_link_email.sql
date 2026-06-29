-- Ajax Callback: SEND_REF_LINK_EMAIL (sequence 70)
-- Called by: sendRefLinkEmail() in ref-correction-link.js
-- Purpose:   Email the reference correction link to the applicant
-- Input:     g_x01 = job_application_id, g_x02 = email, g_x03 = url
-- Output:    JSON { status: "OK" } or { status: "ERROR", message: "..." }
-- Package:   pkg_ref_correction.send_correction_email
-- Tables:    JOB_APPLICANTS_R

DECLARE
    l_app_id NUMBER := TO_NUMBER(apex_application.g_x01);
    l_email  VARCHAR2(500) := apex_application.g_x02;
    l_url    VARCHAR2(4000) := apex_application.g_x03;
    l_name   VARCHAR2(500);
BEGIN
    BEGIN
        SELECT CANDIDATENAME INTO l_name
          FROM JOB_APPLICANTS_R
         WHERE JOBAPPLICATIONID = l_app_id
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN l_name := 'Applicant';
    END;

    pkg_ref_correction.send_correction_email(
        p_job_application_id => l_app_id,
        p_candidate_email    => l_email,
        p_candidate_name     => l_name,
        p_url                => l_url
    );

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

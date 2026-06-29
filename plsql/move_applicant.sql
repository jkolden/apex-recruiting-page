-- Ajax Callback: MOVE_APPLICANT (sequence 20)
-- Called by: submitMove() in move-applicant.js
-- Purpose:   Move a job application to a new phase/state via Fusion REST API
-- Input:     g_x01 = job_application_id, g_x02 = phase_id,
--            g_x03 = state_id, g_x04 = comments
-- Output:    JSON { status: "OK" } or { status: "ERROR", message: "..." }
-- Package:   pkg_rec_move.move_application (REST POST to Fusion)

DECLARE
    l_response CLOB;
BEGIN
    l_response := pkg_rec_move.move_application(
        p_job_application_id => TO_NUMBER(apex_application.g_x01),
        p_phase_id           => TO_NUMBER(apex_application.g_x02),
        p_state_id           => TO_NUMBER(apex_application.g_x03),
        p_comments           => apex_application.g_x04
    );
    apex_json.open_object;
    apex_json.write('status', 'OK');
    apex_json.close_object;
EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write('status', 'ERROR');
        apex_json.write('message', REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *'));
        apex_json.close_object;
END;

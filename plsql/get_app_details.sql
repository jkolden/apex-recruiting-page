-- Ajax Callback: GET_APP_DETAILS (sequence 10)
-- Called by: openMoveForm() in move-applicant.js
-- Purpose:   Load candidate name, current phase/state for the move drawer
-- Input:     g_x01 = job_application_id
-- Output:    JSON { candidate_name, phase, state, phase_id }
-- Tables:    FBX_QSTNR_APPLICANT_V, rec_routing_phase

DECLARE
    l_name     VARCHAR2(240);
    l_phase    VARCHAR2(240);
    l_state    VARCHAR2(240);
    l_phase_id NUMBER;
BEGIN
    SELECT
        CANDIDATE_NAME,
        APPLICATION_PHASE,
        APPLICATION_STATE
    INTO l_name, l_phase, l_state
    FROM FBX_QSTNR_APPLICANT_V
    WHERE JOB_APPLICATION_ID = TO_NUMBER(apex_application.g_x01)
      AND ROWNUM = 1;

    -- Look up phase_id to pre-select the dropdown
    BEGIN
        SELECT phase_id INTO l_phase_id
          FROM rec_routing_phase
         WHERE phase_name = l_phase
           AND phase_type = 'APPLICATION'
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN l_phase_id := NULL;
    END;

    apex_json.open_object;
    apex_json.write('candidate_name', l_name);
    apex_json.write('phase', l_phase);
    apex_json.write('state', l_state);
    apex_json.write('phase_id', l_phase_id);
    apex_json.close_object;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        apex_json.open_object;
        apex_json.write('candidate_name', 'Unknown');
        apex_json.write('phase', '');
        apex_json.write('state', '');
        apex_json.write('phase_id', '');
        apex_json.close_object;
END;

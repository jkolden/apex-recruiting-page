-- Ajax Callback: GET_APPLICANT_NOTES (sequence 110)
-- Called by: applicant_notes_js (external JS file)
-- Purpose:   Fetch notes for a candidate (person-level, not application-level)
-- Input:     g_x01 = person_id
-- Output:    JSON { notes: [{ note_text, created_by, created_on }], note_count }
-- Tables:    applicant_note

DECLARE
    l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);
    l_count     NUMBER := 0;
BEGIN
    apex_json.open_object;
    apex_json.open_array('notes');

    FOR r IN (
        SELECT note_text,
               created_by,
               TO_CHAR(created_on, 'DD-Mon-YYYY HH24:MI') AS created_on
          FROM applicant_note
         WHERE person_id = l_person_id
         ORDER BY created_on DESC
    ) LOOP
        l_count := l_count + 1;
        apex_json.open_object;
        apex_json.write('note_text',   r.note_text);
        apex_json.write('created_by',  r.created_by);
        apex_json.write('created_on',  r.created_on);
        apex_json.close_object;
    END LOOP;

    apex_json.close_array;
    apex_json.write('note_count', l_count);
    apex_json.close_object;
END;

-- Ajax Callback: GET_PHONES (sequence 100)
-- Called by: candidate_phones_js (external JS file)
-- Purpose:   Fetch phone numbers for a candidate
-- Input:     g_x01 = person_id
-- Output:    JSON { phones: [{ phone_type, phone_number, primary_flag }] }
-- Tables:    candidate_phones_r
-- Functions: fmt_phone (phone number formatter)

DECLARE
    l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);
BEGIN
    apex_json.open_object;
    apex_json.open_array('phones');

    FOR r IN (
        SELECT phone_type,
               fmt_phone(
                   CASE
                       WHEN country_code_number IS NOT NULL
                            AND area_code IS NOT NULL
                       THEN country_code_number || area_code || phone_number
                       WHEN area_code IS NOT NULL
                       THEN area_code || phone_number
                       ELSE phone_number
                   END
               ) AS phone_number,
               NVL(primary_flag, 'N') AS primary_flag
          FROM candidate_phones_r
         WHERE person_id = l_person_id
         ORDER BY DECODE(primary_flag, 'Y', 0, 1),
                  DECODE(phone_type, 'MOBILE', 1, 'HOME', 2, 'WORK', 3, 9),
                  phone_id
    ) LOOP
        apex_json.open_object;
        apex_json.write('phone_type',    r.phone_type);
        apex_json.write('phone_number',  r.phone_number);
        apex_json.write('primary_flag',  r.primary_flag);
        apex_json.close_object;
    END LOOP;

    apex_json.close_array;
    apex_json.close_object;
END;

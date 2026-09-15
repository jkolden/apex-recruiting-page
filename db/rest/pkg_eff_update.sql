CREATE OR REPLACE PACKAGE pkg_eff_update AS
-- =============================================================================
-- EFF REST Update: PATCH "Additional GCS Person Data" via Fusion REST API
-- and refresh local ext_flex_stg row.
--
-- NOTE: The recruiting report reads from ext_flex_person_data_v which filters
-- on information_type = 'Additional GCS Person Data'. If EFF contexts are
-- reorganized before go-live, update gc_context_path in the body.
--
-- Credential: gcs_reports (APEX Web Credential)
-- API base:   personExtraInformation/{PersonId}/child/personEFF/{PersonId}
--             /child/PersonExtraInformationContextAdditional__GCS__Person__DataprivateVO
-- =============================================================================

    -- PATCH one or more EFF fields in Fusion, then refresh local ext_flex_stg.
    -- p_payload is JSON with camelCase REST attribute names, e.g.:
    --   {"certification":"Y","referenceCheck":"N","teacherAssessmentScore":90}
    -- Raises -20100 on failure.
    PROCEDURE update_eff_recruiting (
        p_person_id  IN NUMBER,
        p_payload    IN CLOB
    );

    -- GET current EFF values from Fusion REST and MERGE into ext_flex_stg.
    -- Called automatically after update, or standalone for a refresh button.
    PROCEDURE refresh_eff_row (
        p_person_id  IN NUMBER
    );

END pkg_eff_update;
/

-- =============================================================================
-- APEX Ajax Callback Snippets
-- =============================================================================
-- Add these as ON_DEMAND processes on the recruiting report page.
--
-- UPDATE_EFF (x01 = person_id, x02 = JSON payload):
--
--   DECLARE
--       l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);
--       l_payload   CLOB   := apex_application.g_x02;
--   BEGIN
--       pkg_eff_update.update_eff_recruiting(l_person_id, l_payload);
--       apex_json.open_object;
--       apex_json.write('status', 'OK');
--       apex_json.close_object;
--   EXCEPTION
--       WHEN OTHERS THEN
--           apex_json.open_object;
--           apex_json.write('status', 'ERROR');
--           apex_json.write('message', REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *'));
--           apex_json.close_object;
--   END;
--
-- REFRESH_EFF (x01 = person_id):
--
--   DECLARE
--       l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);
--   BEGIN
--       pkg_eff_update.refresh_eff_row(l_person_id);
--       apex_json.open_object;
--       apex_json.write('status', 'OK');
--       apex_json.close_object;
--   EXCEPTION
--       WHEN OTHERS THEN
--           apex_json.open_object;
--           apex_json.write('status', 'ERROR');
--           apex_json.write('message', REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *'));
--           apex_json.close_object;
--   END;
-- =============================================================================

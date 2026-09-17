CREATE OR REPLACE PACKAGE pkg_eff_update AS
-- =============================================================================
-- EFF REST Update: PATCH "GCS Recruiting Details" context via Fusion REST API
-- and refresh local ext_flex_stg row.
--
-- recruiting_report_v reads from ext_flex_recruiting_v which filters on
-- information_type = 'GCS Recruiting Details'.
--
-- Credential: gcs_reports (APEX Web Credential)
-- API base:   personExtraInformation/{PersonId}/child/personEFF/{PersonId}
--             /child/PersonExtraInformationContextGCS__Recruiting__DetailsprivateVO
-- =============================================================================

    -- PATCH one or more EFF fields in Fusion, then refresh local ext_flex_stg.
    -- p_payload is JSON with camelCase REST attribute names, e.g.:
    --   {"payGrade":"G","payStep":"9","teacherAssessmentScore":10}
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

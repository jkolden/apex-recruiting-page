-- =============================================================================
-- email_config: Add APEX_BASE_URL for correction link generation
-- =============================================================================
-- Update the URL below to match your ATP APEX instance.
-- Used by pkg_ref_correction.generate_token to build the full correction URL.
-- =============================================================================

INSERT INTO email_config (config_key, config_value, description) VALUES (
    'APEX_BASE_URL',
    'https://g0bca26b76b6699-freedemo.adb.us-ashburn-1.oraclecloudapps.com/ords/r/freedemo/fa_integ_ibzsjb_test',
    'Base URL for APEX application (used in correction link generation). Update for each environment.'
);

COMMIT;

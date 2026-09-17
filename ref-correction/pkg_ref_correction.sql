CREATE OR REPLACE PACKAGE pkg_ref_correction AS
-- =============================================================================
-- Applicant Reference Correction
-- =============================================================================
-- Generates secure one-time tokens, validates them for the public correction
-- page, saves applicant-submitted corrections into the ref_correction overlay
-- table, and optionally emails the correction link via pkg_email.
-- =============================================================================

    -- Generate a token and return the full correction URL.
    FUNCTION generate_token (
        p_job_application_id  IN NUMBER,
        p_requested_by        IN VARCHAR2 DEFAULT NULL  -- defaults to APP_USER
    ) RETURN VARCHAR2;

    -- Validate a token. Returns job_application_id if valid, NULL if expired/used/not found.
    FUNCTION validate_token (p_token IN VARCHAR2) RETURN NUMBER;

    -- Mark token as used.
    PROCEDURE consume_token (p_token IN VARCHAR2);

    -- Save corrections from the public form.
    PROCEDURE save_corrections (
        p_token       IN VARCHAR2,
        p_ref_1_name  IN VARCHAR2 DEFAULT NULL,
        p_ref_1_phone IN VARCHAR2 DEFAULT NULL,
        p_ref_1_email IN VARCHAR2 DEFAULT NULL,
        p_ref_2_name  IN VARCHAR2 DEFAULT NULL,
        p_ref_2_phone IN VARCHAR2 DEFAULT NULL,
        p_ref_2_email IN VARCHAR2 DEFAULT NULL,
        p_ref_3_name  IN VARCHAR2 DEFAULT NULL,
        p_ref_3_phone IN VARCHAR2 DEFAULT NULL,
        p_ref_3_email IN VARCHAR2 DEFAULT NULL
    );

    -- Send the correction link via email using pkg_email.
    PROCEDURE send_correction_email (
        p_job_application_id  IN NUMBER,
        p_candidate_email     IN VARCHAR2,
        p_candidate_name      IN VARCHAR2,
        p_url                 IN VARCHAR2,
        p_personal_note       IN VARCHAR2 DEFAULT NULL
    );

    -- Look up candidate email: internal candidates from FBX_HCM_EMPLOYEE, external = NULL.
    FUNCTION get_candidate_email (p_job_application_id IN NUMBER) RETURN VARCHAR2;

END pkg_ref_correction;
/

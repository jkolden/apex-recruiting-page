-- =============================================================================
-- TABLE: REF_CORRECTION
-- =============================================================================
-- Overlay table for applicant-corrected reference contact information.
-- Follows the applicant_ranking pattern: one row per JOB_APPLICATION_ID,
-- MERGE upsert, LEFT JOIN in RECRUITING_REPORT_V with COALESCE overlay.
--
-- Original questionnaire data (FBX_QSTNR_V) is never modified.
-- The view COALESCEs corrected values over originals:
--   COALESCE(rc.REF_1_NAME, tr.GCS_TEACH_REF_1_NAME) AS GCS_TEACH_REF_1_NAME
-- =============================================================================

CREATE TABLE ref_correction (
    job_application_id   NUMBER         NOT NULL,
    -- Corrected values (NULL = no correction for that field)
    ref_1_name           VARCHAR2(500),
    ref_1_phone          VARCHAR2(100),
    ref_1_email          VARCHAR2(500),
    ref_2_name           VARCHAR2(500),
    ref_2_phone          VARCHAR2(100),
    ref_2_email          VARCHAR2(500),
    ref_3_name           VARCHAR2(500),
    ref_3_phone          VARCHAR2(100),
    ref_3_email          VARCHAR2(500),
    -- Original values snapshot (captured at correction time for audit trail)
    orig_ref_1_name      VARCHAR2(500),
    orig_ref_1_phone     VARCHAR2(100),
    orig_ref_1_email     VARCHAR2(500),
    orig_ref_2_name      VARCHAR2(500),
    orig_ref_2_phone     VARCHAR2(100),
    orig_ref_2_email     VARCHAR2(500),
    orig_ref_3_name      VARCHAR2(500),
    orig_ref_3_phone     VARCHAR2(100),
    orig_ref_3_email     VARCHAR2(500),
    -- Audit
    token_id             NUMBER,                    -- FK to ref_correction_token
    corrected_on         TIMESTAMP(6)   DEFAULT SYSTIMESTAMP NOT NULL,
    requested_by         VARCHAR2(240),             -- admin who sent the link (from token record)
    --
    CONSTRAINT ref_correction_pk PRIMARY KEY (job_application_id)
);

COMMENT ON TABLE  ref_correction IS 'Applicant-corrected reference contact info (overlay on questionnaire data)';
COMMENT ON COLUMN ref_correction.ref_1_name IS 'Corrected Reference 1 name (NULL = unchanged)';
COMMENT ON COLUMN ref_correction.orig_ref_1_name IS 'Original Reference 1 name at time of correction (audit snapshot)';
COMMENT ON COLUMN ref_correction.token_id IS 'Token used for this correction (FK to ref_correction_token)';
COMMENT ON COLUMN ref_correction.requested_by IS 'APEX user who generated the correction link';

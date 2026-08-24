CREATE OR REPLACE PACKAGE pkg_ui_interactions AS
-- =============================================================================
-- Fusion recruitingUIInteractions integration.
--
-- POST: dual-write notes to Fusion alongside local table inserts.
-- GET:  sync Fusion interactions into candidate_note / applicant_note.
--
-- Endpoint: /hcmRestApi/resources/11.13.18.05/recruitingUIInteractions
-- POST:     .../recruitingUIInteractions/action/addInteraction
--
-- Context types:
--   ORA_SUBMISSION   → candidate_note (keyed on job_application_id)
--   ORA_CAND_PROFILE → applicant_note (keyed on person_id)
-- =============================================================================

    gc_credential CONSTANT VARCHAR2(60) := 'gcs_reports';

    -- POST a note to Fusion. Returns 'ORA_SUCCESS' or error description.
    -- NEVER raises — caller's local INSERT has already committed.
    FUNCTION post_interaction (
        p_context_type_code IN VARCHAR2,   -- 'ORA_SUBMISSION' or 'ORA_CAND_PROFILE'
        p_context_id        IN NUMBER,     -- job_application_id or person_id
        p_person_id         IN NUMBER,     -- candidate person_id (always required)
        p_note_text         IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Sync all interactions for a single person from Fusion into local tables.
    -- Call after POST to link the new note, or on-demand.
    PROCEDURE sync_person (p_person_id IN NUMBER);

    -- Nightly bulk sync: iterate known persons, call sync_person for each.
    PROCEDURE sync_all;

END pkg_ui_interactions;
/

-- =============================================================================
-- TABLE: CANDIDATE_NOTE
-- =============================================================================
-- Append-only log of notes/comments per job application.
-- Used by vetters, processors, and HR staff to track candidate activity.
-- Keyed on JOB_APPLICATION_ID to match the vetting report grain.
-- =============================================================================

CREATE TABLE candidate_note (
    note_id              NUMBER GENERATED ALWAYS AS IDENTITY,
    job_application_id   NUMBER          NOT NULL,
    note_text            VARCHAR2(4000)  NOT NULL,
    created_by           VARCHAR2(240)   NOT NULL,
    created_on           TIMESTAMP(6)    DEFAULT SYSTIMESTAMP NOT NULL,
    interaction_id       NUMBER,
    CONSTRAINT candidate_note_pk PRIMARY KEY (note_id)
);

CREATE INDEX candidate_note_n1 ON candidate_note (job_application_id, created_on DESC);
CREATE INDEX candidate_note_n2 ON candidate_note (interaction_id);

COMMENT ON TABLE  candidate_note IS 'Append-only candidate notes log per job application';
COMMENT ON COLUMN candidate_note.job_application_id IS 'FK to JOB_APPLICANTS_R.JOBAPPLICATIONID';
COMMENT ON COLUMN candidate_note.note_text          IS 'Free-text note content (max 4000 chars)';
COMMENT ON COLUMN candidate_note.created_by         IS 'APEX username or Fusion DisplayName';
COMMENT ON COLUMN candidate_note.created_on         IS 'Timestamp when the note was created';
COMMENT ON COLUMN candidate_note.interaction_id     IS 'Fusion InteractionId (NULL for local-only notes)';

-- Auto-stamp created_by/created_on for local inserts only.
-- When interaction_id is set (Fusion sync), preserve provided values.
CREATE OR REPLACE TRIGGER candidate_note_bi
BEFORE INSERT ON candidate_note
FOR EACH ROW
BEGIN
    IF :NEW.interaction_id IS NULL THEN
        :NEW.created_by := COALESCE(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
        :NEW.created_on := SYSTIMESTAMP;
    END IF;
END;
/

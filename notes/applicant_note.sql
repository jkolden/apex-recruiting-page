-- =============================================================================
-- TABLE: APPLICANT_NOTE
-- =============================================================================
-- Append-only log of notes/comments per applicant (person).
-- Unlike candidate_note (keyed on job_application_id), this captures notes
-- about the person across ALL their applications.
-- Keyed on PERSON_ID to match RECRUITING_CANDIDATES_R.PERSONID.
-- =============================================================================

CREATE TABLE applicant_note (
    note_id              NUMBER GENERATED ALWAYS AS IDENTITY,
    person_id            NUMBER          NOT NULL,
    note_text            VARCHAR2(4000)  NOT NULL,
    created_by           VARCHAR2(240)   NOT NULL,
    created_on           TIMESTAMP(6)    DEFAULT SYSTIMESTAMP NOT NULL,
    interaction_id       NUMBER,
    CONSTRAINT applicant_note_pk PRIMARY KEY (note_id)
);

CREATE INDEX applicant_note_n1 ON applicant_note (person_id, created_on DESC);
CREATE INDEX applicant_note_n2 ON applicant_note (interaction_id);

COMMENT ON TABLE  applicant_note IS 'Append-only applicant notes log per person (across all applications)';
COMMENT ON COLUMN applicant_note.person_id      IS 'FK to RECRUITING_CANDIDATES_R.PERSONID';
COMMENT ON COLUMN applicant_note.note_text      IS 'Free-text note content (max 4000 chars)';
COMMENT ON COLUMN applicant_note.created_by     IS 'APEX username or Fusion DisplayName';
COMMENT ON COLUMN applicant_note.created_on     IS 'Timestamp when the note was created';
COMMENT ON COLUMN applicant_note.interaction_id IS 'Fusion InteractionId (NULL for local-only notes)';

-- Auto-stamp created_by/created_on for local inserts only.
-- When interaction_id is set (Fusion sync), preserve provided values.
CREATE OR REPLACE TRIGGER applicant_note_bi
BEFORE INSERT ON applicant_note
FOR EACH ROW
BEGIN
    IF :NEW.interaction_id IS NULL THEN
        :NEW.created_by := COALESCE(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
        :NEW.created_on := SYSTIMESTAMP;
    END IF;
END;
/

-- =============================================================================
-- ALTER: Add interaction_id to candidate_note and applicant_note
-- =============================================================================
-- Run once on live database before deploying pkg_ui_interactions.
-- Adds nullable interaction_id column (Fusion InteractionId) and updates
-- triggers to preserve Fusion-supplied created_by/created_on during sync.
-- =============================================================================

-- candidate_note
ALTER TABLE candidate_note ADD (interaction_id NUMBER);
CREATE INDEX candidate_note_n2 ON candidate_note (interaction_id);
COMMENT ON COLUMN candidate_note.interaction_id IS 'Fusion InteractionId (NULL for local-only notes)';

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

-- applicant_note
ALTER TABLE applicant_note ADD (interaction_id NUMBER);
CREATE INDEX applicant_note_n2 ON applicant_note (interaction_id);
COMMENT ON COLUMN applicant_note.interaction_id IS 'Fusion InteractionId (NULL for local-only notes)';

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

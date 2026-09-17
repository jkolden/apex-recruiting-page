-- =============================================================================
-- Trigger: REC_DEPT_GRANT_BI
-- =============================================================================
-- BEFORE INSERT: auto-sets audit columns so the form DML doesn't need to
-- supply them explicitly.
--
--   app_user   → normalized to UPPER (APEX usernames are upper-case)
--   granted_by → APEX session user if called from a page; DB session user
--                as fallback (scheduler, SQL Developer, etc.)
--   granted_ts → SYSTIMESTAMP (overrides the column default so the value
--                is consistent even when inserted outside APEX)
-- =============================================================================

CREATE OR REPLACE TRIGGER rec_dept_grant_bi
    BEFORE INSERT ON rec_dept_grant
    FOR EACH ROW
BEGIN
    :NEW.app_user   := UPPER(TRIM(:NEW.app_user));
    :NEW.granted_by := COALESCE(
        SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
        SYS_CONTEXT('USERENV', 'SESSION_USER')
    );
    :NEW.granted_ts := SYSTIMESTAMP;
END;
/

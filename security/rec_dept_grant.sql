-- =============================================================================
-- REC_DEPT_GRANT: Department-based access overrides for recruiting reports
-- =============================================================================
-- Replaces REC_SCHOOL_GRANT. Drives the VPD policy on RECRUITING_REPORT_V.
--
-- Access rule logic per row:
--
--   dept_name only (recruiter_id IS NULL AND hiring_mgr_id IS NULL):
--     → user sees ALL job reqs for that department
--
--   dept_name + recruiter_id (hiring_mgr_id IS NULL):
--     → user sees reqs for that department where recruiter matches
--
--   dept_name + hiring_mgr_id (recruiter_id IS NULL):
--     → user sees reqs for that department where hiring manager matches
--
--   dept_name + recruiter_id + hiring_mgr_id:
--     → user sees reqs for that department where recruiter OR hiring manager matches
--
-- Multiple rows per user are OR'd together (additive).
-- Overrides are always additive to the user's natural access (reqs where they
-- are already the recruiter or hiring manager — those are always visible).
--
-- dept_name must match DEPARTMENTS_R.NAME exactly (case-sensitive).
-- recruiter_id / hiring_mgr_id are person_id values from FBX_HCM_EMPLOYEE.
-- =============================================================================

CREATE TABLE rec_dept_grant (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    app_user        VARCHAR2(255)  NOT NULL,
    dept_name       VARCHAR2(240)  NOT NULL,
    recruiter_id    NUMBER,
    hiring_mgr_id   NUMBER,
    is_active       VARCHAR2(1)    DEFAULT 'Y' NOT NULL,
    granted_by      VARCHAR2(255),
    granted_ts      TIMESTAMP(6)   DEFAULT SYSTIMESTAMP NOT NULL,
    notes           VARCHAR2(500),
    --
    CONSTRAINT rec_dept_grant_ck1 CHECK (is_active IN ('Y', 'N'))
);

COMMENT ON TABLE  rec_dept_grant               IS 'Department-based access overrides for recruiting report VPD. Replaces rec_school_grant.';
COMMENT ON COLUMN rec_dept_grant.app_user      IS 'APEX username (upper-case), matches :APP_USER';
COMMENT ON COLUMN rec_dept_grant.dept_name     IS 'Fusion department name — must match DEPARTMENTS_R.NAME exactly';
COMMENT ON COLUMN rec_dept_grant.recruiter_id  IS 'Optional: PERSON_ID — if set, user sees only reqs for this dept where this person is the recruiter';
COMMENT ON COLUMN rec_dept_grant.hiring_mgr_id IS 'Optional: PERSON_ID — if set, user sees only reqs for this dept where this person is the hiring manager';
COMMENT ON COLUMN rec_dept_grant.is_active     IS 'Y = active grant, N = revoked';
COMMENT ON COLUMN rec_dept_grant.granted_by    IS 'APEX username of the admin who created this grant';
COMMENT ON COLUMN rec_dept_grant.granted_ts    IS 'Timestamp when the grant was created';
COMMENT ON COLUMN rec_dept_grant.notes         IS 'Reason for the grant (e.g., covering for vacancy — revoke after hire)';

CREATE INDEX rec_dept_grant_n1 ON rec_dept_grant (UPPER(app_user));
CREATE INDEX rec_dept_grant_n2 ON rec_dept_grant (dept_name);

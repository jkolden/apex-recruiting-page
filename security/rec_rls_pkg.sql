-- =============================================================================
-- REC_RLS_PKG: VPD policy function for RECRUITING_REPORT_V
-- =============================================================================
-- Returns a WHERE-clause predicate that Oracle appends to every SELECT
-- against RECRUITING_REPORT_V.
--
-- Bypass rules:
--   1. No APEX session (schema owner / SQL Developer / scheduler) → NULL (no filter)
--   2. ADMIN role in app_user_roles                               → NULL (see everything)
--   3. Otherwise → predicate combining four independent OR clauses:
--
-- Access paths (OR'd together):
--   A. User is the recruiter on the req
--        RECRUITER_ID = <person_id>
--   B. User is the hiring manager on the req
--        HIRING_MANAGER_ID = <person_id>
--   C. Wide dept grant: user has an active grant for this dept with no
--      recruiter/HM restriction — they can see ALL reqs for that dept
--        DEPARTMENT_NAME IN (SELECT dept_name FROM rec_dept_grant WHERE ...)
--   D. Recruiter-specific grant: dept + recruiter pair matches a grant row
--        (DEPARTMENT_NAME, RECRUITER_ID) IN (SELECT dept_name, recruiter_id FROM ...)
--   E. HM-specific grant: dept + HM pair matches a grant row
--        (DEPARTMENT_NAME, HIRING_MANAGER_ID) IN (SELECT dept_name, hiring_mgr_id FROM ...)
--
-- All subqueries in the predicate are standalone (no correlated references to
-- view columns inside a subquery). View columns appear only in the outer
-- predicate — Oracle VPD cannot resolve view column names inside a subquery.
--
-- RECRUITER_ID, HIRING_MANAGER_ID, DEPARTMENT_NAME are columns in RECRUITING_REPORT_V.
-- User's person_id is looked up from FBX_HCM_EMPLOYEE at policy evaluation time.
-- If the user is not found in FBX_HCM_EMPLOYEE, paths A and B are skipped.
-- l_user is embedded as a literal in each subquery — avoids SYS_CONTEXT
-- inside the predicate string, which VPD cannot parse at query time.
-- =============================================================================

CREATE OR REPLACE PACKAGE rec_rls_pkg AS

    FUNCTION read_policy (
        p_schema  IN VARCHAR2,
        p_object  IN VARCHAR2
    ) RETURN VARCHAR2;

END rec_rls_pkg;
/

CREATE OR REPLACE PACKAGE BODY rec_rls_pkg AS

    FUNCTION read_policy (
        p_schema  IN VARCHAR2,
        p_object  IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_user      VARCHAR2(255);
        l_is_admin  NUMBER;
        l_person_id NUMBER;
        l_pred      VARCHAR2(4000);
        l_u         VARCHAR2(255);   -- UPPER(l_user) literal for embedding
    BEGIN
        -- ----------------------------------------------------------------
        -- Bypass 1: No APEX session (schema owner, SQL Developer, scheduler)
        -- ----------------------------------------------------------------
        l_user := SYS_CONTEXT('APEX$SESSION', 'APP_USER');

        IF l_user IS NULL THEN
            RETURN NULL;
        END IF;

        l_u := UPPER(l_user);   -- trigger stores app_user as UPPER; match exactly

        -- ----------------------------------------------------------------
        -- Bypass 2: ADMIN role → see everything
        -- ----------------------------------------------------------------
        SELECT COUNT(*)
          INTO l_is_admin
          FROM app_user_roles
         WHERE UPPER(username) = l_u
           AND role_code       = 'ADMIN'
           AND is_active       = 'Y';

        IF l_is_admin > 0 THEN
            RETURN NULL;
        END IF;

        -- ----------------------------------------------------------------
        -- Look up the user's person_id (NULL if not an HCM employee).
        -- ----------------------------------------------------------------
        BEGIN
            SELECT PERSON_ID
              INTO l_person_id
              FROM FBX_HCM_EMPLOYEE
             WHERE UPPER(USER_NAME) = l_u
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_person_id := NULL;
        END;

        -- ----------------------------------------------------------------
        -- Build predicate.
        --
        -- Paths A + B: user owns the req as recruiter or hiring manager.
        -- ----------------------------------------------------------------
        IF l_person_id IS NOT NULL THEN
            l_pred := 'RECRUITER_ID = '        || TO_CHAR(l_person_id)
                   || ' OR HIRING_MANAGER_ID = ' || TO_CHAR(l_person_id)
                   || ' OR ';
        END IF;

        -- ----------------------------------------------------------------
        -- Path C: wide dept grant — user sees ALL reqs for granted departments.
        --   (recruiter_id IS NULL AND hiring_mgr_id IS NULL on the grant row)
        --
        -- Path D: recruiter-specific grant — (dept, recruiter) pair matches.
        --   View column RECRUITER_ID compared against granted recruiter_id.
        --
        -- Path E: HM-specific grant — (dept, HM) pair matches.
        --   View column HIRING_MANAGER_ID compared against granted hiring_mgr_id.
        --
        -- All subqueries are standalone — no view column references inside them.
        -- View columns (DEPARTMENT_NAME, RECRUITER_ID, HIRING_MANAGER_ID) appear
        -- only in the outer predicate where VPD resolves them correctly.
        -- ----------------------------------------------------------------
        l_pred := NVL(l_pred, '')
               -- Path C
               || 'DEPARTMENT_NAME IN ('
               ||   'SELECT dept_name FROM rec_dept_grant'
               ||   ' WHERE app_user   = ''' || l_u || ''''
               ||   '   AND is_active  = ''Y'''
               ||   '   AND recruiter_id  IS NULL'
               ||   '   AND hiring_mgr_id IS NULL'
               || ')'
               -- Path D
               || ' OR (DEPARTMENT_NAME, RECRUITER_ID) IN ('
               ||   'SELECT dept_name, recruiter_id FROM rec_dept_grant'
               ||   ' WHERE app_user  = ''' || l_u || ''''
               ||   '   AND is_active = ''Y'''
               ||   '   AND recruiter_id IS NOT NULL'
               || ')'
               -- Path E
               || ' OR (DEPARTMENT_NAME, HIRING_MANAGER_ID) IN ('
               ||   'SELECT dept_name, hiring_mgr_id FROM rec_dept_grant'
               ||   ' WHERE app_user  = ''' || l_u || ''''
               ||   '   AND is_active = ''Y'''
               ||   '   AND hiring_mgr_id IS NOT NULL'
               || ')';

        RETURN l_pred;

    EXCEPTION
        WHEN OTHERS THEN
            -- Never let an unexpected error raise ORA-28113.
            -- Return 1=0 (no rows) as a safe default.
            RETURN '1=0';
    END read_policy;

END rec_rls_pkg;
/

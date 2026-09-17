-- =============================================================================
-- Attach VPD policy to RECRUITING_REPORT_V
-- =============================================================================
-- Run as WKSP_FREEDEMO (the schema owner).
-- Requires EXECUTE on DBMS_RLS (granted by ADMIN in ATP).
-- Re-runnable: drops both the old policy name and the new one before re-adding.
-- =============================================================================

-- Drop old location-based policy if it still exists
BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema   => 'WKSP_FREEDEMO',
        object_name     => 'RECRUITING_REPORT_V',
        policy_name     => 'REC_SCHOOL_READ_POLICY'
    );
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -28102 THEN NULL;   -- policy does not exist
        ELSE RAISE;
        END IF;
END;
/

-- Drop new policy if re-running
BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema   => 'WKSP_FREEDEMO',
        object_name     => 'RECRUITING_REPORT_V',
        policy_name     => 'REC_DEPT_READ_POLICY'
    );
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -28102 THEN NULL;   -- policy does not exist
        ELSE RAISE;
        END IF;
END;
/

-- Apply department-based policy
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'WKSP_FREEDEMO',
        object_name     => 'RECRUITING_REPORT_V',
        policy_name     => 'REC_DEPT_READ_POLICY',
        function_schema => 'WKSP_FREEDEMO',
        policy_function => 'REC_RLS_PKG.READ_POLICY',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );
END;
/

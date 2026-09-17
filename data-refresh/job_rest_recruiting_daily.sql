--------------------------------------------------------------------------
-- Daily DBMS_SCHEDULER job for code-based REST recruiting loads
--
-- Runs pkg_rest_recruiting.refresh_all which consolidates:
--   load_requisitions : parent reqs + DFFs + published jobs (1 API pass)
--   load_candidates   : parent candidates + phones (1 API pass)
--   load_applications : incremental job applications (1 API pass)
--
-- Session created here, not in the package — keeps pkg_rest_recruiting
-- app-agnostic.  Change p_app_id if the APEX app moves.
--------------------------------------------------------------------------
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_REST_RECRUITING_DAILY',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN apex_session.create_session(p_app_id=>141,p_page_id=>1,p_username=>''ADMIN''); pkg_rest_recruiting.refresh_all(p_full_refresh => true); apex_session.delete_session; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=14; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Daily full refresh of recruiting (requisitions + DFFs + published jobs + candidates + phones) — 14:00 UTC'
    );
END;
/

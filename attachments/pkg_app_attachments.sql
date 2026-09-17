CREATE OR REPLACE PACKAGE pkg_app_attachments AS
-- =============================================================================
-- Package to list and download attachments from Oracle Fusion Cloud
-- recruiting job applications via REST API.
--
-- Endpoint: GET /hcmRestApi/resources/11.13.18.05/recruitingJobApplications
--               /{JobApplicationId}/child/attachments
--
-- Uses same credential pattern as pkg_rec_move.
-- =============================================================================

    -- List attachments for a job application.
    -- Writes JSON directly to htp.prn for APEX Ajax callback consumption.
    -- Output: {status:"OK", count:N, items:[{attached_document_id, title,
    --          file_name, content_type, category, creation_date}]}
    PROCEDURE list_attachments (p_job_application_id IN NUMBER);

    -- Download a single attachment binary and stream it to the browser.
    -- Called from APEX page 30 Before Header process.
    -- Uses owa_util.mime_header + wpg_docload + stop_apex_engine.
    PROCEDURE download_attachment (
        p_job_application_id   IN NUMBER,
        p_attached_document_id IN NUMBER
    );

END pkg_app_attachments;
/

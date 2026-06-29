-- Ajax Callback: LIST_ATTACHMENTS (sequence 30)
-- Called by: openAttachments() in attachment-modal.js
-- Purpose:   Fetch attachments for a job application from Fusion REST API
-- Input:     g_x01 = job_application_id
-- Output:    JSON { status, items: [{ file_name, file_size, content_type, category, creation_date, download_url }] }
-- Package:   pkg_app_attachments.list_attachments

BEGIN
    pkg_app_attachments.list_attachments(
        p_job_application_id => TO_NUMBER(apex_application.g_x01)
    );
END;

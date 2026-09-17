# Attachments

## What it does

Lists and downloads file attachments for a job application from Oracle Fusion Cloud via REST API. Clicking the attachment icon in the page 24 IR opens a center modal that calls the Fusion `recruitingJobApplications/{id}/child/attachments` endpoint, filters to `DatatypeCode = 'FILE'` (skipping URL and text attachments), and displays a table with file name, size, category, and date. Each row has a download link that routes through hidden APEX page 30, which streams the binary file to the browser. The download procedure tries the enclosure URL first, then falls back to base64 decoding from the self URL if the binary download fails.

## Database objects

| Type | Name | Purpose |
|------|------|---------|
| Package spec | `pkg_app_attachments` | Declares `list_attachments` and `download_attachment` |
| Package body | `pkg_app_attachments` | REST calls to Fusion attachments child resource; JSON parsing; binary streaming |

No local tables are created -- all data comes live from Fusion REST.

## Static files

| File | APEX reference |
|------|---------------|
| `attachments_js.js` | `#APP_FILES#attachments_js#MIN#.js` |
| `attachments_css.css` | `#APP_FILES#attachments_css#MIN#.css` |

## Ajax callbacks

| Name | What it does | Returns |
|------|-------------|---------|
| `LIST_ATTACHMENTS` | Reads `x01` (job_application_id), calls `pkg_app_attachments.list_attachments` | `{status:"OK", count:N, items:[{attached_document_id, title, file_name, content_type, category, creation_date, file_size, download_url}]}` or `{status:"ERROR", message:"..."}` |

## Page items

None. The modal is pure JavaScript DOM -- no APEX page items are used. The job application ID is passed as a function argument from the IR column link.

## Download page (page 30)

Page 30 is a hidden APEX page with two items (`P30_JOB_APPLICATION_ID`, `P30_ATTACHED_DOCUMENT_ID`) and a Before Header PL/SQL process that calls `pkg_app_attachments.download_attachment`. It streams the binary via `owa_util.mime_header` + `wpg_docload.download_file` + `apex_application.stop_apex_engine`. Download URLs are generated server-side by `apex_page.get_url` inside `list_attachments` so they include the APEX session checksum.

## How to deploy

1. Run `pkg_app_attachments.sql` (spec), then `pkg_app_attachments.plb` (body).
2. Upload `attachments_js.js` and `attachments_css.css` as Static Application Files.
3. Add JS/CSS file references to page 24.
4. Create the `LIST_ATTACHMENTS` Ajax callback on page 24.
5. Create page 30 as a hidden page with items `P30_JOB_APPLICATION_ID` and `P30_ATTACHED_DOCUMENT_ID`.
6. Add a Before Header PL/SQL process on page 30 that calls `pkg_app_attachments.download_attachment(:P30_JOB_APPLICATION_ID, :P30_ATTACHED_DOCUMENT_ID)`.
7. Add an attachment icon/link column in the page 24 IR that calls `openAttachments(JOB_APPLICATION_ID)`.
8. Verify the APEX Web Credential `gcs_reports` is configured for the Fusion instance.

## How to modify

- **Adding columns to the file list**: Edit the `json_table` in `list_attachments` to extract additional Fusion fields. Update the JS `data.items.forEach` loop to render the new columns.
- **Changing file type icons**: Edit the `getFileIcon` function in the JS. It maps content types and extensions to Font Awesome icon classes.
- **Supporting URL/text attachments**: Remove the `WHERE datatype_code = 'FILE'` filter in `list_attachments` and handle non-file items in the JS rendering.
- **Credential change**: Update `gc_fa_credential` constant in the package body.

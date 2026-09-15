CREATE OR REPLACE PACKAGE BODY pkg_app_attachments AS

    -- =========================================================================
    -- Private constants
    -- =========================================================================
    gc_fa_credential CONSTANT VARCHAR2(60) := 'gcs_reports';

    -- =========================================================================
    -- LIST_ATTACHMENTS
    -- =========================================================================
    -- GET /hcmRestApi/resources/11.13.18.05/recruitingJobApplications
    --     /{id}/child/attachments
    --
    -- Writes JSON to htp.prn:
    -- { "status": "OK", "count": 3,
    --   "items": [ { "attached_document_id": 12345,
    --                "title": "Resume",
    --                "file_name": "resume.pdf",
    --                "content_type": "application/pdf",
    --                "category": "MISC",
    --                "creation_date": "2025-01-15",
    --                "file_size": 104027 }, ... ] }
    -- =========================================================================
    PROCEDURE list_attachments (p_job_application_id IN NUMBER)
    IS
        l_url      VARCHAR2(2000);
        l_response CLOB;
        l_status   NUMBER;
        l_json     CLOB;
    BEGIN
        l_url := pkg_bicc_common.gc_fa_base_url
            || '/hcmRestApi/resources/11.13.18.05/recruitingJobApplications/'
            || p_job_application_id
            || '/child/attachments';

        apex_web_service.g_request_headers.DELETE;

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET',
            p_credential_static_id => gc_fa_credential
        );

        l_status := apex_web_service.g_status_code;

        IF l_status NOT BETWEEN 200 AND 299 THEN
            apex_json.initialize_clob_output;
            apex_json.open_object;
            apex_json.write('status', 'ERROR');
            apex_json.write('message', 'Fusion returned HTTP ' || l_status);
            apex_json.close_object;
            htp.prn(apex_json.get_clob_output);
            apex_json.free_output;
            RETURN;
        END IF;

        -- Parse Fusion response and re-emit as a simpler JSON structure.
        -- Filter to DatatypeCode = 'FILE' (skip URL/TEXT attachment types).
        SELECT json_object(
            'status' VALUE 'OK',
            'count'  VALUE (
                SELECT COUNT(*)
                FROM json_table(l_response, '$.items[*]'
                    COLUMNS (
                        datatype_code VARCHAR2(30) PATH '$.DatatypeCode'
                    )
                )
                WHERE datatype_code = 'FILE'
            ),
            'items'  VALUE (
                SELECT json_arrayagg(
                    json_object(
                        'attached_document_id' VALUE attached_document_id,
                        'title'                VALUE title,
                        'file_name'            VALUE file_name,
                        'content_type'         VALUE content_type,
                        'category'             VALUE category_name,
                        'creation_date'        VALUE creation_date,
                        'file_size'            VALUE file_size,
                        'download_url'         VALUE apex_page.get_url(
                            p_page   => 30,
                            p_items  => 'P30_JOB_APPLICATION_ID,P30_ATTACHED_DOCUMENT_ID',
                            p_values => p_job_application_id || ',' || TO_CHAR(attached_document_id)
                        )
                    RETURNING CLOB)
                    ORDER BY creation_date DESC
                    RETURNING CLOB
                )
                FROM json_table(l_response, '$.items[*]'
                    COLUMNS (
                        attached_document_id NUMBER        PATH '$.AttachedDocumentId',
                        title                VARCHAR2(500) PATH '$.Title',
                        file_name            VARCHAR2(500) PATH '$.FileName',
                        content_type         VARCHAR2(200) PATH '$.UploadedFileContentType',
                        category_name        VARCHAR2(100) PATH '$.CategoryName',
                        datatype_code        VARCHAR2(30)  PATH '$.DatatypeCode',
                        creation_date        VARCHAR2(40)  PATH '$.CreationDate',
                        file_size            NUMBER        PATH '$.UploadedFileLength'
                    )
                )
                WHERE datatype_code = 'FILE'
            )
        RETURNING CLOB)
        INTO l_json
        FROM dual;

        -- Write using chunked htp.prn for large JSON
        FOR i IN 1 .. CEIL(NVL(DBMS_LOB.GETLENGTH(l_json), 0) / 32000) LOOP
            htp.prn(DBMS_LOB.SUBSTR(l_json, 32000, (i - 1) * 32000 + 1));
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            apex_json.initialize_clob_output;
            apex_json.open_object;
            apex_json.write('status', 'ERROR');
            apex_json.write('message', REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *'));
            apex_json.close_object;
            htp.prn(apex_json.get_clob_output);
            apex_json.free_output;
    END list_attachments;


    -- =========================================================================
    -- DOWNLOAD_ATTACHMENT
    -- =========================================================================
    -- Fetches a single attachment binary from Fusion and streams it to the
    -- browser.  Called from page 30 Before Header process.
    --
    -- Strategy:
    --   1. GET attachment listing to find enclosure URL for this document
    --      (attachment URLs use hex keys, not numeric AttachedDocumentId)
    --   2. GET binary via enclosure href from links array
    --   3. If enclosure fails, fallback to self href + ?fields=FileContents (base64)
    --   4. Stream via owa_util.mime_header + wpg_docload + stop_apex_engine
    -- =========================================================================
    PROCEDURE download_attachment (
        p_job_application_id   IN NUMBER,
        p_attached_document_id IN NUMBER
    )
    IS
        l_url            VARCHAR2(2000);
        l_response       CLOB;
        l_blob           BLOB;
        l_status         NUMBER;
        l_file_name      VARCHAR2(500);
        l_content_type   VARCHAR2(200);
        l_enclosure_href VARCHAR2(4000);
        l_self_href      VARCHAR2(4000);
        l_b64            CLOB;
    BEGIN
        -- =================================================================
        -- Step 1: List attachments to find enclosure URL for this document
        -- =================================================================
        l_url := pkg_bicc_common.gc_fa_base_url
            || '/hcmRestApi/resources/11.13.18.05/recruitingJobApplications/'
            || p_job_application_id
            || '/child/attachments';

        apex_web_service.g_request_headers.DELETE;

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET',
            p_credential_static_id => gc_fa_credential
        );

        l_status := apex_web_service.g_status_code;

        IF l_status NOT BETWEEN 200 AND 299 THEN
            htp.p('<html><body><h3>Error</h3><p>Could not retrieve attachments (HTTP '
                  || l_status || ')</p></body></html>');
            RETURN;
        END IF;

        -- =================================================================
        -- Step 2: Extract filename, content type, and enclosure URL
        -- The links array contains {rel:"enclosure", name:"FileContents",
        -- href:".../{hex_key}/enclosure/FileContents"} for each attachment.
        -- NESTED PATH on $.links[*] joins each link row to its parent item;
        -- we filter to the enclosure link for the matching AttachedDocumentId.
        -- =================================================================
        BEGIN
            SELECT
                NVL(jt.file_name, 'attachment.bin'),
                NVL(jt.content_type, 'application/octet-stream'),
                jt.link_href
            INTO l_file_name, l_content_type, l_enclosure_href
            FROM json_table(l_response, '$.items[*]'
                COLUMNS (
                    attached_document_id NUMBER        PATH '$.AttachedDocumentId',
                    file_name            VARCHAR2(500) PATH '$.FileName',
                    content_type         VARCHAR2(200) PATH '$.UploadedFileContentType',
                    NESTED PATH '$.links[*]' COLUMNS (
                        link_rel  VARCHAR2(100)  PATH '$.rel',
                        link_name VARCHAR2(100)  PATH '$.name',
                        link_href VARCHAR2(4000) PATH '$.href'
                    )
                )
            ) jt
            WHERE jt.attached_document_id = p_attached_document_id
              AND jt.link_rel = 'enclosure'
              AND jt.link_name = 'FileContents';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                htp.p('<html><body><h3>Error</h3><p>Attachment not found (ID '
                      || p_attached_document_id || ').</p></body></html>');
                RETURN;
        END;

        -- =================================================================
        -- Step 3: Download binary from enclosure URL
        -- =================================================================
        apex_web_service.g_request_headers.DELETE;

        BEGIN
            l_blob := apex_web_service.make_rest_request_b(
                p_url         => l_enclosure_href,
                p_http_method => 'GET',
                p_credential_static_id => gc_fa_credential
            );
            l_status := apex_web_service.g_status_code;
        EXCEPTION
            WHEN OTHERS THEN
                l_status := 999;
        END;

        -- =================================================================
        -- Step 4: Fallback — get self href, then base64 decode
        -- =================================================================
        IF l_status NOT BETWEEN 200 AND 299
           OR l_blob IS NULL
           OR DBMS_LOB.GETLENGTH(l_blob) = 0
        THEN
            -- Extract self href for this attachment from the same response
            BEGIN
                SELECT jt.link_href
                INTO l_self_href
                FROM json_table(l_response, '$.items[*]'
                    COLUMNS (
                        attached_document_id NUMBER PATH '$.AttachedDocumentId',
                        NESTED PATH '$.links[*]' COLUMNS (
                            link_rel  VARCHAR2(100)  PATH '$.rel',
                            link_href VARCHAR2(4000) PATH '$.href'
                        )
                    )
                ) jt
                WHERE jt.attached_document_id = p_attached_document_id
                  AND jt.link_rel = 'self';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    htp.p('<html><body><h3>Error</h3><p>Could not resolve attachment URL.</p></body></html>');
                    RETURN;
            END;

            l_url := l_self_href || '?fields=FileContents';

            apex_web_service.g_request_headers.DELETE;

            l_response := apex_web_service.make_rest_request(
                p_url         => l_url,
                p_http_method => 'GET',
                p_credential_static_id => gc_fa_credential
            );

            l_status := apex_web_service.g_status_code;

            IF l_status NOT BETWEEN 200 AND 299 THEN
                htp.p('<html><body><h3>Error</h3><p>Could not download file content (HTTP '
                      || l_status || ')</p></body></html>');
                RETURN;
            END IF;

            l_b64 := json_value(l_response, '$.FileContents');

            IF l_b64 IS NULL THEN
                htp.p('<html><body><h3>Error</h3><p>Attachment has no file content.</p></body></html>');
                RETURN;
            END IF;

            l_blob := apex_web_service.clobbase642blob(l_b64);
        END IF;

        IF l_blob IS NULL OR DBMS_LOB.GETLENGTH(l_blob) = 0 THEN
            htp.p('<html><body><h3>Error</h3><p>Downloaded file is empty.</p></body></html>');
            RETURN;
        END IF;

        -- =================================================================
        -- Step 5: Stream the binary to the browser
        -- =================================================================
        owa_util.mime_header(l_content_type, FALSE);
        htp.p('Content-Length: ' || DBMS_LOB.GETLENGTH(l_blob));
        htp.p('Content-Disposition: attachment; filename="'
              || REPLACE(REPLACE(l_file_name, '"', '_'), CHR(10), '') || '"');
        owa_util.http_header_close;

        wpg_docload.download_file(l_blob);

        apex_application.stop_apex_engine;

    EXCEPTION
        WHEN apex_application.e_stop_apex_engine THEN
            RAISE;  -- Expected after stop_apex_engine; must re-raise
        WHEN OTHERS THEN
            htp.p('<html><body><h3>Download Error</h3><p>'
                  || REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *')
                  || '</p></body></html>');
    END download_attachment;

END pkg_app_attachments;
/

/**
 * Attachment Modal
 * Displays a centered modal with a table of attachments for a
 * job application, fetched from Fusion via REST.
 *
 * Ajax callback used:
 *   - LIST_ATTACHMENTS → calls pkg_app_attachments.list_attachments
 *
 * The modal is injected into the DOM on first use and reused.
 */

function openAttachments(appId) {
    var $modal = $("#attachment_modal");
    if (!$modal.length) {
        $("body").append(
            '<div id="att_backdrop" class="att-backdrop"></div>' +
            '<div id="attachment_modal" class="att-modal">' +
            '  <div class="att-modal-header">' +
            '    <span class="att-modal-title">Attachments</span>' +
            '    <button type="button" class="att-modal-close" onclick="closeAttachments()">&times;</button>' +
            '  </div>' +
            '  <div class="att-modal-body" id="att_modal_body"></div>' +
            '</div>'
        );
        $modal = $("#attachment_modal");
        $("#att_backdrop").on("click", function(){ closeAttachments(); });
    }

    $("#att_modal_body").html(
        '<div class="att-loading"><span class="fa fa-refresh fa-anim-spin"></span> Loading attachments...</div>'
    );
    $modal.addClass("is-open");
    $("#att_backdrop").addClass("is-open");

    apex.server.process("LIST_ATTACHMENTS", {
        x01: String(appId)
    }, {
        dataType: "json",
        success: function(data) {
            if (data.status === "ERROR") {
                $("#att_modal_body").html(
                    '<div class="att-error"><span class="fa fa-exclamation-triangle"></span> '
                    + apex.util.escapeHTML(data.message) + '</div>'
                );
                return;
            }
            if (!data.items || data.items.length === 0) {
                $("#att_modal_body").html(
                    '<div class="att-empty"><span class="fa fa-folder-o"></span> No attachments found.</div>'
                );
                return;
            }
            var html = '<table class="att-table">'
                + '<thead><tr><th>File</th><th>Size</th><th>Category</th><th>Date</th><th></th></tr></thead><tbody>';
            data.items.forEach(function(item) {
                var ic = getFileIcon(item.content_type, item.file_name);
                var url = item.download_url;
                html += '<tr>'
                    + '<td><span class="fa ' + ic + ' att-file-icon"></span> '
                    + apex.util.escapeHTML(item.file_name || item.title || "Untitled")
                    + '</td>'
                    + '<td class="att-size">' + formatFileSize(item.file_size) + '</td>'
                    + '<td>' + apex.util.escapeHTML(item.category || "") + '</td>'
                    + '<td class="att-date">'
                    + (item.creation_date ? item.creation_date.substring(0,10) : "")
                    + '</td>'
                    + '<td><a href="' + url + '" target="_blank" class="t-Button t-Button--small t-Button--noUI">'
                    + '<span class="fa fa-download"></span></a></td>'
                    + '</tr>';
            });
            html += '</tbody></table>';
            $("#att_modal_body").html(html);
        },
        error: function() {
            $("#att_modal_body").html(
                '<div class="att-error"><span class="fa fa-exclamation-triangle"></span> Failed to load attachments.</div>'
            );
        }
    });
}

function closeAttachments() {
    $("#attachment_modal").removeClass("is-open");
    $("#att_backdrop").removeClass("is-open");
}

function getFileIcon(ct, fn) {
    ct = ct || ""; fn = fn || "";
    var ext = fn.split(".").pop().toLowerCase();
    if (ct.indexOf("pdf") > -1 || ext === "pdf") return "fa-file-pdf-o";
    if (ct.indexOf("word") > -1 || ext === "doc" || ext === "docx") return "fa-file-word-o";
    if (ct.indexOf("image") > -1) return "fa-file-image-o";
    if (ct.indexOf("text") > -1 || ext === "txt") return "fa-file-text-o";
    return "fa-file-o";
}

function formatFileSize(bytes) {
    if (!bytes) return "";
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(0) + " KB";
    return (bytes / 1048576).toFixed(1) + " MB";
}

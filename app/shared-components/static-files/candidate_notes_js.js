/**
 * Candidate Notes — Inline Expand/Collapse
 * -----------------------------------------
 * Injects a detail row below a candidate's IR row to show/add notes.
 * No drawers, no popups — expands in-place and collapses on demand.
 *
 * APEX setup:
 *   - Add this as a Page-level JavaScript > File URL, or paste into
 *     Function and Global Variable Declaration.
 *   - Requires two Ajax callbacks on the page: GET_NOTES, ADD_NOTE
 *     (see candidate_notes_apex.sql).
 *   - IR needs an HTML Expression column (see instructions in _apex.sql).
 */
(function () {
    "use strict";

    /* ------------------------------------------------------------------ */
    /*  Toggle handler                                                     */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".cnote-toggle", function (e) {
        e.preventDefault();
        e.stopPropagation();

        var $btn   = $(this),
            appId  = $btn.data("app-id"),
            $tr    = $btn.closest("tr"),
            $exist = $tr.next(".cnote-detail-row");

        // Collapse if already open
        if ($exist.length) {
            collapse($exist, $btn);
            return;
        }

        // Close any other open panel first
        $(".cnote-detail-row").each(function () {
            var $prev = $(this).prev("tr").find(".cnote-toggle");
            collapse($(this), $prev);
        });

        // Flip icon
        $btn.find(".fa-comment-o").removeClass("fa-comment-o").addClass("fa-comment");

        // Build skeleton row
        var colSpan    = $tr.children("td").length,
            $detailRow = $(
                '<tr class="cnote-detail-row">' +
                '<td colspan="' + colSpan + '" class="cnote-detail-td">' +
                '<div class="cnote-panel">' +
                '<div class="cnote-loading">' +
                '<span class="fa fa-refresh fa-anim-spin"></span> Loading notes&hellip;</div>' +
                '</div></td></tr>'
            );

        $tr.after($detailRow);
        $detailRow.hide().slideDown(200);

        fetchNotes(appId, $detailRow.find(".cnote-panel"));
    });

    /* ------------------------------------------------------------------ */
    /*  Fetch notes via Ajax                                               */
    /* ------------------------------------------------------------------ */
    function fetchNotes(appId, $panel) {
        apex.server.process("GET_NOTES", { x01: String(appId) }, {
            dataType: "json",
            success: function (data) { render(appId, data, $panel); },
            error:   function ()     { $panel.html('<div class="cnote-error">Error loading notes.</div>'); }
        });
    }

    /* ------------------------------------------------------------------ */
    /*  Render notes + add-form                                            */
    /* ------------------------------------------------------------------ */
    function render(appId, data, $panel) {
        var h = "";

        // Header row
        h += '<div class="cnote-header">' +
             '<span class="cnote-title">Reviewer Notes</span>' +
             '<button type="button" class="cnote-close t-Button t-Button--icon t-Button--tiny t-Button--noUI" ' +
             'aria-label="Close notes"><span class="fa fa-times"></span></button></div>';

        // Add-note form
        h += '<div class="cnote-add">' +
             '<textarea class="cnote-input" placeholder="Add a note..." rows="2" maxlength="4000"></textarea>' +
             '<button type="button" class="cnote-save t-Button t-Button--hot t-Button--small" ' +
             'data-app-id="' + appId + '">' +
             '<span class="t-Icon fa fa-plus"></span> Add</button></div>';

        // Notes list (newest first)
        if (data.notes && data.notes.length) {
            h += '<div class="cnote-list">';
            for (var i = 0; i < data.notes.length; i++) {
                var n = data.notes[i];
                h += '<div class="cnote-entry">' +
                     '<div class="cnote-meta">' +
                     escHtml(n.created_by) + ' &mdash; ' + escHtml(n.created_on) +
                     '</div>' +
                     '<div class="cnote-text">' + escHtml(n.note_text) + '</div>' +
                     '</div>';
            }
            h += '</div>';
        } else {
            h += '<div class="cnote-empty">No notes yet.</div>';
        }

        $panel.html(h);
        $panel.find(".cnote-input").focus();
    }

    /* ------------------------------------------------------------------ */
    /*  Add note                                                           */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".cnote-save", function () {
        var $btn   = $(this),
            appId  = $btn.data("app-id"),
            $panel = $btn.closest(".cnote-panel"),
            $input = $panel.find(".cnote-input"),
            txt    = $.trim($input.val());

        if (!txt) { $input.focus(); return; }

        $btn.prop("disabled", true)
            .find(".fa-plus").removeClass("fa-plus").addClass("fa-refresh fa-anim-spin");

        apex.server.process("ADD_NOTE", { x01: String(appId), x02: txt }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "OK") {
                    render(appId, data, $panel);
                    // Update badge on the toggle button
                    var $badge = $('.cnote-toggle[data-app-id="' + appId + '"]').find(".cnote-badge");
                    $badge.attr("data-count", data.note_count).text(data.note_count);
                } else {
                    apex.message.showErrors([{ type: "error", location: "page",
                        message: data.message || "Error adding note." }]);
                    $btn.prop("disabled", false)
                        .find(".fa-refresh").removeClass("fa-refresh fa-anim-spin").addClass("fa-plus");
                }
            },
            error: function () {
                apex.message.showErrors([{ type: "error", location: "page",
                    message: "Error adding note." }]);
                $btn.prop("disabled", false)
                    .find(".fa-refresh").removeClass("fa-refresh fa-anim-spin").addClass("fa-plus");
            }
        });
    });

    // Ctrl+Enter in textarea submits
    $(document).on("keydown", ".cnote-input", function (e) {
        if (e.ctrlKey && e.key === "Enter") {
            $(this).closest(".cnote-add").find(".cnote-save").trigger("click");
        }
    });

    /* ------------------------------------------------------------------ */
    /*  Close button                                                       */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".cnote-close", function () {
        var $detailRow = $(this).closest(".cnote-detail-row"),
            $btn       = $detailRow.prev("tr").find(".cnote-toggle");
        collapse($detailRow, $btn);
    });

    /* ------------------------------------------------------------------ */
    /*  Collapse on IR refresh (pagination, filter, etc.)                  */
    /* ------------------------------------------------------------------ */
    $(document).on("apexafterrefresh", function () {
        $(".cnote-detail-row").remove();
        $(".cnote-toggle .fa-comment").removeClass("fa-comment").addClass("fa-comment-o");
    });

    /* ------------------------------------------------------------------ */
    /*  Helpers                                                            */
    /* ------------------------------------------------------------------ */
    function collapse($detailRow, $btn) {
        $detailRow.slideUp(150, function () { $detailRow.remove(); });
        if ($btn && $btn.length) {
            $btn.find(".fa-comment").removeClass("fa-comment").addClass("fa-comment-o");
        }
    }

    function escHtml(s) {
        if (!s) return "";
        if (apex.util && apex.util.escapeHTML) return apex.util.escapeHTML(s);
        var d = document.createElement("div");
        d.appendChild(document.createTextNode(s));
        return d.innerHTML;
    }

})();

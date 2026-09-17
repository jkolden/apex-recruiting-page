/**
 * Person Notes — Inline Expand/Collapse
 * --------------------------------------
 * Injects a detail row below a candidate's report row to show/add notes.
 * Keyed on PERSON_ID — notes follow the candidate across all applications.
 * Uses "pnote-" prefix to avoid collisions with app_notes (appnote-).
 *
 * APEX setup:
 *   - Add this as a Page-level JavaScript > File URL, or paste into
 *     Function and Global Variable Declaration.
 *   - Requires two Ajax callbacks on the page: GET_PERSON_NOTES, ADD_PERSON_NOTE
 *     (see person_notes_apex.sql).
 *   - Report needs an HTML Expression column (see instructions in _apex.sql).
 */
(function () {
    "use strict";

    /* ------------------------------------------------------------------ */
    /*  Toggle handler                                                     */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".pnote-toggle", function (e) {
        e.preventDefault();
        e.stopPropagation();

        var $btn     = $(this),
            personId = $btn.data("person-id"),
            $tr      = $btn.closest("tr"),
            $exist   = $tr.next(".pnote-detail-row");

        // Collapse if already open
        if ($exist.length) {
            collapse($exist, $btn);
            return;
        }

        // Close any other open panel first
        $(".pnote-detail-row").each(function () {
            var $prev = $(this).prev("tr").find(".pnote-toggle");
            collapse($(this), $prev);
        });

        // Flip icon
        $btn.find(".fa-comment-o").removeClass("fa-comment-o").addClass("fa-comment");

        // Build skeleton row
        var colSpan    = $tr.children("td").length,
            $detailRow = $(
                '<tr class="pnote-detail-row">' +
                '<td colspan="' + colSpan + '" class="pnote-detail-td">' +
                '<div class="pnote-panel">' +
                '<div class="pnote-loading">' +
                '<span class="fa fa-refresh fa-anim-spin"></span> Loading notes&hellip;</div>' +
                '</div></td></tr>'
            );

        $tr.after($detailRow);
        $detailRow.hide().slideDown(200);

        fetchNotes(personId, $detailRow.find(".pnote-panel"));
    });

    /* ------------------------------------------------------------------ */
    /*  Fetch notes via Ajax                                               */
    /* ------------------------------------------------------------------ */
    function fetchNotes(personId, $panel) {
        apex.server.process("GET_PERSON_NOTES", { x01: String(personId) }, {
            dataType: "json",
            success: function (data) { render(personId, data, $panel); },
            error:   function ()     { $panel.html('<div class="pnote-error">Error loading notes.</div>'); }
        });
    }

    /* ------------------------------------------------------------------ */
    /*  Render notes + add-form                                            */
    /* ------------------------------------------------------------------ */
    function render(personId, data, $panel) {
        var h = "";

        // Header row
        h += '<div class="pnote-header">' +
             '<span class="pnote-title">Candidate Notes</span>' +
             '<button type="button" class="pnote-close t-Button t-Button--icon t-Button--tiny t-Button--noUI" ' +
             'aria-label="Close notes"><span class="fa fa-times"></span></button></div>';

        // Add-note form
        h += '<div class="pnote-add">' +
             '<textarea class="pnote-input" placeholder="Add a note..." rows="2" maxlength="4000"></textarea>' +
             '<button type="button" class="pnote-save t-Button t-Button--hot t-Button--small" ' +
             'data-person-id="' + personId + '">' +
             '<span class="t-Icon fa fa-plus"></span> Add</button></div>';

        // Notes list (newest first)
        if (data.notes && data.notes.length) {
            h += '<div class="pnote-list">';
            for (var i = 0; i < data.notes.length; i++) {
                var n = data.notes[i];
                h += '<div class="pnote-entry">' +
                     '<div class="pnote-meta">' +
                     escHtml(n.created_by) + ' &mdash; ' + escHtml(n.created_on) +
                     '</div>' +
                     '<div class="pnote-text">' + escHtml(n.note_text) + '</div>' +
                     '</div>';
            }
            h += '</div>';
        } else {
            h += '<div class="pnote-empty">No notes yet.</div>';
        }

        $panel.html(h);
        $panel.find(".pnote-input").focus();
    }

    /* ------------------------------------------------------------------ */
    /*  Add note                                                           */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".pnote-save", function () {
        var $btn     = $(this),
            personId = $btn.data("person-id"),
            $panel   = $btn.closest(".pnote-panel"),
            $input   = $panel.find(".pnote-input"),
            txt      = $.trim($input.val());

        if (!txt) { $input.focus(); return; }

        $btn.prop("disabled", true)
            .find(".fa-plus").removeClass("fa-plus").addClass("fa-refresh fa-anim-spin");

        apex.server.process("ADD_PERSON_NOTE", { x01: String(personId), x02: txt }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "OK") {
                    render(personId, data, $panel);
                    // Update badge on the toggle button
                    var $badge = $('.pnote-toggle[data-person-id="' + personId + '"]').find(".pnote-badge");
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
    $(document).on("keydown", ".pnote-input", function (e) {
        if (e.ctrlKey && e.key === "Enter") {
            $(this).closest(".pnote-add").find(".pnote-save").trigger("click");
        }
    });

    /* ------------------------------------------------------------------ */
    /*  Close button                                                       */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".pnote-close", function () {
        var $detailRow = $(this).closest(".pnote-detail-row"),
            $btn       = $detailRow.prev("tr").find(".pnote-toggle");
        collapse($detailRow, $btn);
    });

    /* ------------------------------------------------------------------ */
    /*  Collapse on IR refresh (pagination, filter, etc.)                  */
    /* ------------------------------------------------------------------ */
    $(document).on("apexafterrefresh", function () {
        $(".pnote-detail-row").remove();
        $(".pnote-toggle .fa-comment").removeClass("fa-comment").addClass("fa-comment-o");
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

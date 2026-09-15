/**
 * Applicant Notes — Inline Expand/Collapse
 * -----------------------------------------
 * Injects a detail row below an applicant's IR row to show/add notes.
 * Keyed on PERSON_ID (applicant level, across all applications).
 * Uses "anote-" prefix to avoid collisions with candidate_notes (cnote-).
 *
 * APEX setup:
 *   - Add this as a Page-level JavaScript > File URL, or paste into
 *     Function and Global Variable Declaration.
 *   - Requires two Ajax callbacks on the page: GET_APPLICANT_NOTES, ADD_APPLICANT_NOTE
 *     (see applicant_notes_apex.sql).
 *   - IR needs an HTML Expression column (see instructions in _apex.sql).
 */
(function () {
    "use strict";

    /* ------------------------------------------------------------------ */
    /*  Toggle handler                                                     */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".anote-toggle", function (e) {
        e.preventDefault();
        e.stopPropagation();

        var $btn     = $(this),
            personId = $btn.data("person-id"),
            $tr      = $btn.closest("tr"),
            $exist   = $tr.next(".anote-detail-row");

        // Collapse if already open
        if ($exist.length) {
            collapse($exist, $btn);
            return;
        }

        // Close any other open panel first
        $(".anote-detail-row").each(function () {
            var $prev = $(this).prev("tr").find(".anote-toggle");
            collapse($(this), $prev);
        });

        // Flip icon
        $btn.find(".fa-comment-o").removeClass("fa-comment-o").addClass("fa-comment");

        // Build skeleton row
        var colSpan    = $tr.children("td").length,
            $detailRow = $(
                '<tr class="anote-detail-row">' +
                '<td colspan="' + colSpan + '" class="anote-detail-td">' +
                '<div class="anote-panel">' +
                '<div class="anote-loading">' +
                '<span class="fa fa-refresh fa-anim-spin"></span> Loading notes&hellip;</div>' +
                '</div></td></tr>'
            );

        $tr.after($detailRow);
        $detailRow.hide().slideDown(200);

        fetchNotes(personId, $detailRow.find(".anote-panel"));
    });

    /* ------------------------------------------------------------------ */
    /*  Fetch notes via Ajax                                               */
    /* ------------------------------------------------------------------ */
    function fetchNotes(personId, $panel) {
        apex.server.process("GET_APPLICANT_NOTES", { x01: String(personId) }, {
            dataType: "json",
            success: function (data) { render(personId, data, $panel); },
            error:   function ()     { $panel.html('<div class="anote-error">Error loading notes.</div>'); }
        });
    }

    /* ------------------------------------------------------------------ */
    /*  Render notes + add-form                                            */
    /* ------------------------------------------------------------------ */
    function render(personId, data, $panel) {
        var h = "";

        // Header row
        h += '<div class="anote-header">' +
             '<span class="anote-title">Applicant Notes</span>' +
             '<button type="button" class="anote-close t-Button t-Button--icon t-Button--tiny t-Button--noUI" ' +
             'aria-label="Close notes"><span class="fa fa-times"></span></button></div>';

        // Add-note form
        h += '<div class="anote-add">' +
             '<textarea class="anote-input" placeholder="Add a note..." rows="2" maxlength="4000"></textarea>' +
             '<button type="button" class="anote-save t-Button t-Button--hot t-Button--small" ' +
             'data-person-id="' + personId + '">' +
             '<span class="t-Icon fa fa-plus"></span> Add</button></div>';

        // Notes list (newest first)
        if (data.notes && data.notes.length) {
            h += '<div class="anote-list">';
            for (var i = 0; i < data.notes.length; i++) {
                var n = data.notes[i];
                h += '<div class="anote-entry">' +
                     '<div class="anote-meta">' +
                     escHtml(n.created_by) + ' &mdash; ' + escHtml(n.created_on) +
                     '</div>' +
                     '<div class="anote-text">' + escHtml(n.note_text) + '</div>' +
                     '</div>';
            }
            h += '</div>';
        } else {
            h += '<div class="anote-empty">No notes yet.</div>';
        }

        $panel.html(h);
        $panel.find(".anote-input").focus();
    }

    /* ------------------------------------------------------------------ */
    /*  Add note                                                           */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".anote-save", function () {
        var $btn     = $(this),
            personId = $btn.data("person-id"),
            $panel   = $btn.closest(".anote-panel"),
            $input   = $panel.find(".anote-input"),
            txt      = $.trim($input.val());

        if (!txt) { $input.focus(); return; }

        $btn.prop("disabled", true)
            .find(".fa-plus").removeClass("fa-plus").addClass("fa-refresh fa-anim-spin");

        apex.server.process("ADD_APPLICANT_NOTE", { x01: String(personId), x02: txt }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "OK") {
                    render(personId, data, $panel);
                    // Update badge on the toggle button
                    var $badge = $('.anote-toggle[data-person-id="' + personId + '"]').find(".anote-badge");
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
    $(document).on("keydown", ".anote-input", function (e) {
        if (e.ctrlKey && e.key === "Enter") {
            $(this).closest(".anote-add").find(".anote-save").trigger("click");
        }
    });

    /* ------------------------------------------------------------------ */
    /*  Close button                                                       */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".anote-close", function () {
        var $detailRow = $(this).closest(".anote-detail-row"),
            $btn       = $detailRow.prev("tr").find(".anote-toggle");
        collapse($detailRow, $btn);
    });

    /* ------------------------------------------------------------------ */
    /*  Collapse on IR refresh (pagination, filter, etc.)                  */
    /* ------------------------------------------------------------------ */
    $(document).on("apexafterrefresh", function () {
        $(".anote-detail-row").remove();
        $(".anote-toggle .fa-comment").removeClass("fa-comment").addClass("fa-comment-o");
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

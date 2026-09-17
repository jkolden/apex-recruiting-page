/**
 * Candidate Phones — Inline Expand/Collapse (read-only)
 * -----------------------------------------------------
 * Injects a detail row below a candidate's IR row to show phone numbers.
 * Same pattern as candidate_notes_js.js but read-only (no add form).
 *
 * APEX setup:
 *   - Add this as a Page-level JavaScript > File URL, or paste into
 *     Function and Global Variable Declaration.
 *   - Requires one Ajax callback on the page: GET_PHONES
 *     (see candidate_phones_apex.sql).
 *   - IR needs an HTML Expression column (see instructions in _apex.sql).
 */
(function () {
    "use strict";

    /* ------------------------------------------------------------------ */
    /*  Toggle handler                                                     */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".cphone-toggle", function (e) {
        e.preventDefault();
        e.stopPropagation();

        var $btn   = $(this),
            personId = $btn.data("person-id"),
            $tr    = $btn.closest("tr"),
            $exist = $tr.next(".cphone-detail-row");

        // Collapse if already open
        if ($exist.length) {
            collapse($exist, $btn);
            return;
        }

        // Close any other open phone panel first
        $(".cphone-detail-row").each(function () {
            var $prev = $(this).prev("tr").find(".cphone-toggle");
            collapse($(this), $prev);
        });

        // Flip icon
        $btn.find(".fa-phone").addClass("cphone-active");

        // Build skeleton row
        var colSpan    = $tr.children("td").length,
            $detailRow = $(
                '<tr class="cphone-detail-row">' +
                '<td colspan="' + colSpan + '" class="cphone-detail-td">' +
                '<div class="cphone-panel">' +
                '<div class="cphone-loading">' +
                '<span class="fa fa-refresh fa-anim-spin"></span> Loading phones&hellip;</div>' +
                '</div></td></tr>'
            );

        $tr.after($detailRow);
        $detailRow.hide().slideDown(200);

        fetchPhones(personId, $detailRow.find(".cphone-panel"));
    });

    /* ------------------------------------------------------------------ */
    /*  Fetch phones via Ajax                                              */
    /* ------------------------------------------------------------------ */
    function fetchPhones(personId, $panel) {
        apex.server.process("GET_PHONES", { x01: String(personId) }, {
            dataType: "json",
            success: function (data) { render(data, $panel); },
            error:   function ()     { $panel.html('<div class="cphone-error">Error loading phones.</div>'); }
        });
    }

    /* ------------------------------------------------------------------ */
    /*  Render phone list                                                  */
    /* ------------------------------------------------------------------ */
    function render(data, $panel) {
        var h = "";

        // Header row
        h += '<div class="cphone-header">' +
             '<span class="cphone-title">Phone Numbers</span>' +
             '<button type="button" class="cphone-close t-Button t-Button--icon t-Button--tiny t-Button--noUI" ' +
             'aria-label="Close phones"><span class="fa fa-times"></span></button></div>';

        // Phone list
        if (data.phones && data.phones.length) {
            h += '<div class="cphone-list">';
            for (var i = 0; i < data.phones.length; i++) {
                var p = data.phones[i];
                h += '<div class="cphone-entry">' +
                     '<span class="cphone-type">' + escHtml(p.phone_type) + '</span>' +
                     '<span class="cphone-number">' + escHtml(p.phone_number) + '</span>' +
                     (p.primary_flag === 'Y' ? '<span class="cphone-primary">Primary</span>' : '') +
                     '</div>';
            }
            h += '</div>';
        } else {
            h += '<div class="cphone-empty">No phone numbers on file.</div>';
        }

        $panel.html(h);
        $panel.attr("tabindex", "-1").focus();
    }

    /* ------------------------------------------------------------------ */
    /*  Close button                                                       */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".cphone-close", function () {
        var $detailRow = $(this).closest(".cphone-detail-row"),
            $btn       = $detailRow.prev("tr").find(".cphone-toggle");
        collapse($detailRow, $btn);
    });

    /* ------------------------------------------------------------------ */
    /*  Collapse on IR refresh (pagination, filter, etc.)                  */
    /* ------------------------------------------------------------------ */
    $(document).on("apexafterrefresh", function () {
        $(".cphone-detail-row").remove();
        $(".cphone-toggle .fa-phone").removeClass("cphone-active");
    });

    /* ------------------------------------------------------------------ */
    /*  Helpers                                                            */
    /* ------------------------------------------------------------------ */
    function collapse($detailRow, $btn) {
        $detailRow.slideUp(150, function () { $detailRow.remove(); });
        if ($btn && $btn.length) {
            $btn.find(".fa-phone").removeClass("cphone-active");
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

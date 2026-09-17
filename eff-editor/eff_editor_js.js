/**
 * EFF Editor — Right-Side Drawer
 * --------------------------------
 * Opens a drawer panel to edit GCS Recruiting Details EFF fields
 * via REST PATCH. Keyed on person_id (CAND_NUM).
 * Uses "eff-" prefix to avoid collisions with notes (cnote-/anote-).
 *
 * APEX setup:
 *   - Upload as Static Application File, reference on page 24:
 *       JS File URL:  #APP_FILES#eff_editor_js#MIN#.js
 *   - Requires two Ajax callbacks: GET_EFF_RECRUITING, UPDATE_EFF_RECRUITING
 *     (see eff_editor_apex.sql).
 *   - IR needs an HTML Expression column with the toggle button.
 */
(function () {
    "use strict";

    /* ================================================================== */
    /*  Field definitions                                                  */
    /*  id = REST camelCase attribute name                                 */
    /*  type: "select" renders a dropdown; options = [{v,l}]              */
    /* ================================================================== */
    var YES_NO = [
        { v: "",  l: "" },
        { v: "Y", l: "Yes" },
        { v: "N", l: "No" }
    ];

    var FIELDS = [
        { id: "rehireEligibility",      label: "Rehire Eligible",         type: "select", options: YES_NO },
        { id: "referenceCheck",         label: "Reference Check",         type: "select", options: YES_NO },
        { id: "sled",                   label: "Background Check",        type: "select", options: YES_NO },
        { id: "certification",          label: "Certification",           type: "select", options: YES_NO },
        { id: "teacherAssessmentScore", label: "Assessment Score",        type: "number" },
        { id: "teacherSubjectArea",     label: "Teacher Subject Area",    type: "text"   }
    ];

    /* ================================================================== */
    /*  Patch a single row's EFF cells in-place (no report refresh)        */
    /* ================================================================== */
    function updateRowCells(personId, values) {
        if (!values) return;
        var $region = $('#applicant_irr');
        var $rows = $region.find('.eff-toggle[data-person-id="' + personId + '"]').closest('tr');
        if (!$rows.length) return;

        // Build header text → column index map
        var headerMap = {};
        $region.find('thead th').each(function (idx) {
            var txt = $.trim($(this).text()).toUpperCase();
            if (txt) headerMap[txt] = idx;
        });

        // Update each row for this person individually
        $rows.each(function () {
            var $cells = $(this).find('td');
            for (var i = 0; i < FIELDS.length; i++) {
                var f = FIELDS[i];
                var colIdx = headerMap[(f.column || f.label).toUpperCase()];
                if (colIdx === undefined || values[f.id] === undefined) continue;

                var val = values[f.id];
                $cells.eq(colIdx).text(val === null || val === undefined ? '' : String(val));
            }
        });

        $rows.addClass('eff-row-fadein');
        setTimeout(function () { $rows.removeClass('eff-row-fadein'); }, 300);
    }

    /* ================================================================== */
    /*  Drawer singleton — created once, reused                            */
    /* ================================================================== */
    var $overlay, $drawer, $body;

    function ensureDrawer() {
        if ($drawer) return;

        $overlay = $('<div class="eff-overlay"></div>').appendTo(document.body);
        $drawer  = $(
            '<div class="eff-drawer">' +
              '<div class="eff-drawer-header">' +
                '<span class="eff-title">GCS Recruiting Details</span>' +
                '<button type="button" class="eff-close t-Button t-Button--icon t-Button--tiny t-Button--noUI" ' +
                  'aria-label="Close"><span class="fa fa-times"></span></button>' +
              '</div>' +
              '<div class="eff-drawer-body"></div>' +
            '</div>'
        ).appendTo(document.body);

        $body = $drawer.find(".eff-drawer-body");

        // Close on overlay click
        $overlay.on("click", closeDrawer);
    }

    function openDrawer(personId) {
        ensureDrawer();

        // Loading state
        $body.html(
            '<div class="eff-loading">' +
            '<span class="fa fa-refresh fa-anim-spin"></span> Loading EFF data&hellip;</div>'
        );

        $overlay.addClass("eff-overlay--open");
        $drawer.addClass("eff-drawer--open");

        // Store person id on drawer
        $drawer.data("person-id", personId);

        fetchEff(personId, $body);
    }

    function closeDrawer() {
        if (!$drawer) return;
        $drawer.removeClass("eff-drawer--open");
        $overlay.removeClass("eff-overlay--open");
        // Reset toggle icons
        $(".eff-toggle .fa-pencil-square").removeClass("fa-pencil-square")
            .addClass("fa-pencil-square-o");
    }

    /* ================================================================== */
    /*  Toggle handler                                                     */
    /* ================================================================== */
    $(document).on("click", ".eff-toggle", function (e) {
        e.preventDefault();
        e.stopPropagation();

        var $btn     = $(this),
            personId = $btn.data("person-id");

        // If drawer is already open for this person, close it
        if ($drawer && $drawer.hasClass("eff-drawer--open") &&
            $drawer.data("person-id") === personId) {
            closeDrawer();
            return;
        }

        // Reset all toggle icons, then highlight this one
        $(".eff-toggle .fa-pencil-square").removeClass("fa-pencil-square")
            .addClass("fa-pencil-square-o");
        $btn.find(".fa-pencil-square-o").removeClass("fa-pencil-square-o")
            .addClass("fa-pencil-square");

        openDrawer(personId);
    });

    /* ================================================================== */
    /*  Fetch current EFF values via Ajax                                  */
    /* ================================================================== */
    function fetchEff(personId, $target) {
        apex.server.process("GET_EFF_RECRUITING", { x01: String(personId) }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "OK") {
                    renderForm(personId, data.values, $target);
                } else {
                    $target.html('<div class="eff-error">' +
                        escHtml(data.message || "Error loading EFF data.") + '</div>');
                }
            },
            error: function () {
                $target.html('<div class="eff-error">Error loading EFF data.</div>');
            }
        });
    }

    /* ================================================================== */
    /*  Render the edit form                                               */
    /* ================================================================== */
    function renderForm(personId, values, $target) {
        values = values || {};
        var h = "";

        // Form fields (empty form = new record, Save will POST to create)
        h += '<div class="eff-form">';
        for (var i = 0; i < FIELDS.length; i++) {
            var f   = FIELDS[i],
                val = (values[f.id] != null) ? values[f.id] : "";

            h += '<div class="eff-field">';
            h += '<label class="eff-label" for="eff_' + f.id + '">' + escHtml(f.label) + '</label>';

            if (f.type === "select") {
                h += '<select class="eff-input" id="eff_' + f.id + '" ' +
                     'data-attr="' + f.id + '">';
                for (var j = 0; j < f.options.length; j++) {
                    var o = f.options[j];
                    h += '<option value="' + escAttr(o.v) + '"' +
                         (String(val) === o.v ? ' selected' : '') +
                         '>' + escHtml(o.l) + '</option>';
                }
                h += '</select>';
            } else if (f.type === "textarea") {
                h += '<textarea class="eff-input" id="eff_' + f.id + '" ' +
                     'data-attr="' + f.id + '" rows="2" maxlength="150">' +
                     escHtml(String(val)) + '</textarea>';
            } else {
                h += '<input class="eff-input" id="eff_' + f.id + '" ' +
                     'data-attr="' + f.id + '" ' +
                     'type="' + f.type + '" ' +
                     (f.step ? 'step="' + f.step + '" ' : '') +
                     'value="' + escAttr(String(val)) + '">';
            }
            h += '</div>';
        }
        h += '</div>';

        // Buttons
        h += '<div class="eff-actions">' +
             '<button type="button" class="eff-save t-Button t-Button--hot t-Button--small" ' +
             'data-person-id="' + personId + '">' +
             '<span class="t-Icon fa fa-save"></span> Save to Fusion</button>' +
             '</div>' +
             '<div class="eff-status-bar"><span class="eff-status"></span></div>';

        $target.html(h);
    }

    /* ================================================================== */
    /*  Save handler                                                       */
    /* ================================================================== */
    $(document).on("click", ".eff-save", function () {
        var $btn     = $(this),
            personId = $btn.data("person-id"),
            $panel   = $btn.closest(".eff-drawer-body"),
            $status  = $panel.find(".eff-status"),
            payload  = {};

        // Gather field values from the form inside the drawer body
        $panel.find(".eff-input").each(function () {
            var $el  = $(this),
                attr = $el.data("attr"),
                val  = $.trim($el.val());

            if (val === "") {
                payload[attr] = null;
            } else if ($el.attr("type") === "number") {
                payload[attr] = Number(val);
            } else {
                payload[attr] = val;
            }
        });

        $btn.prop("disabled", true)
            .find(".fa-save").removeClass("fa-save").addClass("fa-refresh fa-anim-spin");
        $status.text("Saving...").removeClass("eff-status-ok eff-status-err");

        apex.server.process("UPDATE_EFF_RECRUITING", {
            x01: String(personId),
            x02: JSON.stringify(payload)
        }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "OK") {
                    // Re-render with refreshed values
                    if (data.values) {
                        renderForm(personId, data.values, $panel);
                    }
                    $panel.find(".eff-status").text("Saved!").addClass("eff-status-ok");
                    // Patch just the changed cells — no full report refresh
                    updateRowCells(personId, data.values);
                    closeDrawer();
                } else {
                    $status.text(data.message || "Error").addClass("eff-status-err");
                    resetBtn($btn);
                }
            },
            error: function () {
                $status.text("Error saving.").addClass("eff-status-err");
                resetBtn($btn);
            }
        });
    });

    function resetBtn($btn) {
        $btn.prop("disabled", false)
            .find(".fa-refresh").removeClass("fa-refresh fa-anim-spin").addClass("fa-save");
    }

    /* ================================================================== */
    /*  Refresh button — GET from Fusion, update local, refresh IR         */
    /* ================================================================== */
    $(document).on("click", ".eff-refresh", function (e) {
        e.preventDefault();
        e.stopPropagation();

        var $btn     = $(this),
            personId = $btn.data("person-id"),
            $icon    = $btn.find(".fa");

        if ($btn.prop("disabled")) return;

        $btn.prop("disabled", true);
        $icon.addClass("fa-anim-spin");

        apex.server.process("REFRESH_EFF_ROW", { x01: String(personId) }, {
            dataType: "json",
            success: function (data) {
                $icon.removeClass("fa-anim-spin");
                $btn.prop("disabled", false);
                if (data.status === "OK") {
                    updateRowCells(personId, data.values);
                    // If drawer is open for this person, reload it
                    if ($drawer && $drawer.hasClass("eff-drawer--open") &&
                        $drawer.data("person-id") === personId) {
                        fetchEff(personId, $body);
                    }
                }
            },
            error: function () {
                $icon.removeClass("fa-anim-spin");
                $btn.prop("disabled", false);
            }
        });
    });

    /* ================================================================== */
    /*  Close button + Escape key                                          */
    /* ================================================================== */
    $(document).on("click", ".eff-close", closeDrawer);

    $(document).on("keydown", function (e) {
        if (e.key === "Escape" && $drawer && $drawer.hasClass("eff-drawer--open")) {
            closeDrawer();
        }
    });

    /* ================================================================== */
    /*  Close on IR refresh                                                */
    /* ================================================================== */
    $(document).on("apexafterrefresh", function () {
        closeDrawer();
    });

    /* ================================================================== */
    /*  Helpers                                                            */
    /* ================================================================== */
    function escHtml(s) {
        if (!s) return "";
        if (apex.util && apex.util.escapeHTML) return apex.util.escapeHTML(s);
        var d = document.createElement("div");
        d.appendChild(document.createTextNode(s));
        return d.innerHTML;
    }

    function escAttr(s) {
        return escHtml(s).replace(/"/g, "&quot;");
    }

})();

/**
 * Notes Hub v2 — Faceted Search + Declarative Req Cards + Req Tree
 * -----------------------------------------------------------------
 * Prefix: nhub-
 * Page 35, App 121
 *
 * Tab 1 "All Notes": Faceted search drives a Classic Report with card-style
 *   HTML Expression rows.  "Add Note" button opens a dialog with typeahead.
 *
 * Tab 2 "By Candidate": Declarative Classic Report with break columns,
 *   driven by facet bind variables.  Refresh handled by Dynamic Action
 *   (apexafterrefresh on notes_report -> refresh req_cards).
 *
 * Tab 3 "By Requisition": Collapsible tree grouped by req > app > notes.
 *
 * Ajax callbacks: GET_REQ_TREE, ADD_APP_NOTE, ADD_PERSON_NOTE,
 *                 SEARCH_CANDIDATES
 */
(function () {
    "use strict";

    /* ================================================================== */
    /*  Tab 1: "Add Note" dialog                                           */
    /* ================================================================== */
    window.nhubAddNoteDialog = function () {
        var $dlg = $("#nhub-add-dialog");
        if (!$dlg.length) {
            var d =
                '<div id="nhub-add-dialog" class="nhub-dialog" style="display:none">' +
                '<div class="nhub-dialog-backdrop"></div>' +
                '<div class="nhub-dialog-body">' +

                /* header */
                '<div class="nhub-dialog-header">' +
                '<span class="nhub-dialog-title">Add Note</span>' +
                '<button type="button" class="nhub-dialog-close t-Button t-Button--icon t-Button--tiny t-Button--noUI">' +
                '<span class="fa fa-times"></span></button></div>' +

                /* content */
                '<div class="nhub-dialog-content">' +

                '<div class="nhub-dialog-row">' +
                '<label>Note Type</label>' +
                '<select id="nhub-dlg-type">' +
                '<option value="">-- select note type --</option>' +
                '<option value="PERSON">Person Note</option>' +
                '<option value="APPLICATION">Application Note</option>' +
                '</select></div>' +

                '<div class="nhub-dialog-row">' +
                '<label>Candidate / Application</label>' +
                '<input id="nhub-dlg-search" type="text" placeholder="Search by name or req#\u2026" autocomplete="off">' +
                '<div id="nhub-dlg-results"></div>' +
                '<input id="nhub-dlg-person-id" type="hidden">' +
                '<input id="nhub-dlg-app-id" type="hidden">' +
                '<div id="nhub-dlg-selected"></div></div>' +

                '<div class="nhub-dialog-row">' +
                '<label>Note</label>' +
                '<textarea id="nhub-dlg-text" rows="6" maxlength="4000"></textarea></div>' +

                '</div>' +

                /* footer */
                '<div class="nhub-dialog-footer">' +
                '<button type="button" class="nhub-dlg-cancel t-Button t-Button--small">Cancel</button>' +
                '<button type="button" class="nhub-dlg-save t-Button t-Button--hot t-Button--small">' +
                '<span class="t-Icon fa fa-plus"></span> Save</button>' +
                '</div></div></div>';

            $("body").append(d);
            $dlg = $("#nhub-add-dialog");
        }

        // Reset fields
        $dlg.find("#nhub-dlg-text").val("");
        $dlg.find("#nhub-dlg-search").val("");
        $dlg.find("#nhub-dlg-results").empty();
        $dlg.find("#nhub-dlg-selected").empty();
        $dlg.find("#nhub-dlg-person-id, #nhub-dlg-app-id").val("");
        $dlg.show();
        $dlg.find("#nhub-dlg-search").focus();
    };

    /* ------------------------------------------------------------------ */
    /*  Typeahead search                                                   */
    /* ------------------------------------------------------------------ */
    var searchTimer;
    $(document).on("input", "#nhub-dlg-search", function () {
        var val = $.trim($(this).val());
        clearTimeout(searchTimer);
        if (val.length < 2) { $("#nhub-dlg-results").empty(); return; }

        searchTimer = setTimeout(function () {
            apex.server.process("SEARCH_CANDIDATES", { x01: val }, {
                dataType: "json",
                success: function (data) {
                    var $r = $("#nhub-dlg-results").empty();
                    if (!data.results || !data.results.length) {
                        $r.html('<div class="nhub-no-results">No matches</div>');
                        return;
                    }
                    var noteType = $("#nhub-dlg-type").val(),
                        seen = {};
                    for (var i = 0; i < data.results.length; i++) {
                        var r = data.results[i],
                            label = r.candidate_name;
                        if (r.candidate_number) label += " (#" + r.candidate_number + ")";

                        if (noteType === "PERSON") {
                            var key = String(r.person_id);
                            if (seen[key]) continue;
                            seen[key] = true;
                            $r.append(
                                '<div class="nhub-search-result" ' +
                                'data-person-id="' + r.person_id + '" ' +
                                'data-app-id="" ' +
                                'data-name="' + esc(r.candidate_name) + '" ' +
                                'data-label="' + esc(label) + '">' +
                                esc(label) + '</div>'
                            );
                        } else {
                            var reqInfo = (r.req_number || "") +
                                (r.req_title ? " \u2014 " + r.req_title : "") +
                                (r.phase ? " \u2014 " + r.phase : "");
                            $r.append(
                                '<div class="nhub-search-result" ' +
                                'data-person-id="' + r.person_id + '" ' +
                                'data-app-id="' + (r.job_application_id || "") + '" ' +
                                'data-name="' + esc(r.candidate_name) + '" ' +
                                'data-label="' + esc(label) + '" ' +
                                'data-req="' + esc(reqInfo) + '">' +
                                esc(label) +
                                ' <small>(' + esc(reqInfo) + ')</small></div>'
                            );
                        }
                    }
                }
            });
        }, 300);
    });

    $(document).on("change", "#nhub-dlg-type", function () {
        var val = $.trim($("#nhub-dlg-search").val());
        if (val.length >= 2) {
            $("#nhub-dlg-search").trigger("input");
        }
    });

    /* ------------------------------------------------------------------ */
    /*  Select from search results                                         */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".nhub-search-result", function () {
        var $r      = $(this),
            name    = $r.data("name"),
            label   = $r.data("label") || name,
            reqInfo = $r.data("req");
        $("#nhub-dlg-person-id").val($r.data("person-id"));
        $("#nhub-dlg-app-id").val($r.data("app-id"));
        var pillHtml = '<div class="nhub-selected-pill">' +
            '<span class="fa fa-user"></span> ' + esc(label);
        if (reqInfo) {
            pillHtml += ' <small>(' + esc(reqInfo) + ')</small>';
        }
        pillHtml += '</div>';
        $("#nhub-dlg-selected").html(pillHtml);
        $("#nhub-dlg-results").empty();
        $("#nhub-dlg-search").val(name);
    });

    /* ------------------------------------------------------------------ */
    /*  Save from dialog                                                   */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".nhub-dlg-save", function () {
        var noteType = $("#nhub-dlg-type").val(),
            personId = $("#nhub-dlg-person-id").val(),
            appId    = $("#nhub-dlg-app-id").val(),
            txt      = $.trim($("#nhub-dlg-text").val());

        if (!noteType)  { showErr("Select a note type."); return; }
        if (!personId) { showErr("Select a candidate first."); return; }
        if (!txt)      { $("#nhub-dlg-text").focus(); return; }

        if (noteType === "APPLICATION" && !appId) {
            showErr("Select a specific application for application-level notes, or switch to Person Note.");
            return;
        }

        var process = (noteType === "APPLICATION") ? "ADD_APP_NOTE" : "ADD_PERSON_NOTE",
            key     = (noteType === "APPLICATION") ? appId : personId;

        var $btn = $(this);
        spinBtn($btn);

        apex.server.process(process, { x01: String(key), x02: txt }, {
            dataType: "json",
            success: function (data) {
                resetBtn($btn);
                if (data.status === "OK") {
                    $("#nhub-add-dialog").hide();
                    apex.message.showPageSuccess("Note added.");
                    refreshReports();
                } else {
                    showErr(data.message || "Error adding note.");
                }
            },
            error: function () { showErr("Error adding note."); resetBtn($btn); }
        });
    });

    /* ------------------------------------------------------------------ */
    /*  Close dialog                                                       */
    /* ------------------------------------------------------------------ */
    $(document).on("click", ".nhub-dialog-close, .nhub-dlg-cancel, .nhub-dialog-backdrop", function () {
        $("#nhub-add-dialog").hide();
    });

    $(document).on("keydown", function (e) {
        if (e.key === "Escape" && $("#nhub-add-dialog").is(":visible")) {
            $("#nhub-add-dialog").hide();
        }
    });

    /* ================================================================== */
    /*  Ctrl+Enter submits in any nhub textarea                            */
    /* ================================================================== */
    $(document).on("keydown", "#nhub-dlg-text", function (e) {
        if (e.ctrlKey && e.key === "Enter") {
            $(this).closest(".nhub-dialog-body")
                   .find(".nhub-dlg-save").first().trigger("click");
        }
    });

    /* ================================================================== */
    /*  Tab 3: By Requisition — collapsible tree                          */
    /* ================================================================== */

    function getExpandedState() {
        var expanded = { reqs: {}, apps: {} };
        $("#nhub-req-tree .nhub-tree-l1").each(function () {
            var $n = $(this), req = $n.data("req");
            if (req && $n.children(".nhub-tree-children").is(":visible")) {
                expanded.reqs[req] = true;
            }
        });
        $("#nhub-req-tree .nhub-tree-l2").each(function () {
            var $n = $(this), app = $n.data("app");
            if (app && $n.children(".nhub-tree-children").is(":visible")) {
                expanded.apps[app] = true;
            }
        });
        return expanded;
    }

    function restoreExpandedState(expanded) {
        $("#nhub-req-tree .nhub-tree-l1").each(function () {
            var $n = $(this);
            if (expanded.reqs[$n.data("req")]) {
                $n.children(".nhub-tree-children").show();
                $n.find("> .nhub-tree-row .nhub-tree-toggle")
                  .removeClass("fa-chevron-right").addClass("fa-chevron-down");
            }
        });
        $("#nhub-req-tree .nhub-tree-l2").each(function () {
            var $n = $(this);
            if (expanded.apps[$n.data("app")]) {
                $n.children(".nhub-tree-children").show();
                $n.find("> .nhub-tree-row .nhub-tree-toggle")
                  .removeClass("fa-chevron-right").addClass("fa-chevron-down");
            }
        });
    }

    function loadReqTree() {
        var $ct = $("#nhub-req-tree");
        if (!$ct.length) return;

        var prevState = getExpandedState();

        $ct.html(
            '<div class="nhub-loading">' +
            '<span class="fa fa-refresh fa-anim-spin"></span> Loading requisition tree&hellip;</div>'
        );

        apex.server.process("GET_REQ_TREE", {
            pageItems: "#P35_NOTE_TYPE,#P35_CREATED_BY,#P35_CANDIDATE_NAME,#P35_REQ_NUMBER,#P35_APP_PHASE,#P35_SEARCH"
        }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "ERROR") {
                    $ct.html('<div class="nhub-error">' + esc(data.message) + '</div>');
                    return;
                }
                renderReqTree(data, $ct);
                restoreExpandedState(prevState);
            },
            error: function (jqXHR, textStatus, errorThrown) {
                console.error("GET_REQ_TREE failed:", textStatus, errorThrown,
                              jqXHR.responseText && jqXHR.responseText.substring(0, 500));
                $ct.html('<div class="nhub-error">Error loading requisition tree.</div>');
            }
        });
    }

    function renderReqTree(data, $ct) {
        if (!data.reqs || !data.reqs.length) {
            $ct.html('<div class="nhub-empty">No requisitions with notes.</div>');
            return;
        }

        var h = "";
        for (var i = 0; i < data.reqs.length; i++) {
            var req = data.reqs[i];

            h += '<div class="nhub-tree-node nhub-tree-l1" data-req="' + esc(req.req_number) + '">';
            h += '<div class="nhub-tree-row nhub-tree-row--req">';
            h += '<span class="nhub-tree-toggle fa fa-chevron-right"></span>';
            h += '<span class="nhub-tree-icon fa fa-briefcase"></span>';
            h += '<span class="nhub-tree-label">';
            h += '<strong>' + esc(req.req_number) + '</strong> &mdash; ' + esc(req.title);
            h += '</span>';
            h += '<span class="nhub-tree-meta">';
            if (req.phase) {
                h += '<span class="nhub-pill nhub-pill--sm">' + esc(req.phase);
                if (req.state) h += ' / ' + esc(req.state);
                h += '</span>';
            }
            h += '<span class="nhub-badge">' + req.note_count + '</span>';
            h += '</span>';
            h += '</div>';

            h += '<div class="nhub-tree-children" style="display:none">';

            if (req.apps) {
                for (var j = 0; j < req.apps.length; j++) {
                    var app = req.apps[j];

                    h += '<div class="nhub-tree-node nhub-tree-l2" data-app="' + (app.app_id || "") + '">';
                    h += '<div class="nhub-tree-row nhub-tree-row--app">';
                    h += '<span class="nhub-tree-toggle fa fa-chevron-right"></span>';
                    h += '<span class="nhub-tree-icon fa fa-user"></span>';
                    h += '<span class="nhub-tree-label">';
                    h += '<strong>' + esc(app.candidate_name) + '</strong>';
                    h += '</span>';
                    h += '<span class="nhub-tree-meta">';
                    if (app.phase) {
                        h += '<span class="nhub-pill nhub-pill--sm">' + esc(app.phase);
                        if (app.state) h += ' / ' + esc(app.state);
                        h += '</span>';
                    }
                    h += '<span class="nhub-badge">' + app.note_count + '</span>';
                    h += '</span>';
                    h += '</div>';

                    h += '<div class="nhub-tree-children" style="display:none">';
                    if (app.notes) {
                        for (var k = 0; k < app.notes.length; k++) {
                            var note    = app.notes[k],
                                isApp   = note.note_type === "APPLICATION",
                                ntClass = isApp ? "nhub-tree-note--app" : "nhub-tree-note--person",
                                ntIcon  = isApp ? "fa-file-text-o" : "fa-user",
                                ntLabel = isApp ? "APP" : "PERSON";

                            h += '<div class="nhub-tree-note ' + ntClass + '">';
                            h += '<div class="nhub-tree-note-header">';
                            h += '<span class="nhub-tree-note-dot"><span class="fa ' + ntIcon + '"></span></span>';
                            h += '<span class="nhub-tl-type-badge">' + ntLabel + '</span> ';
                            h += '<span class="nhub-tree-note-meta">';
                            h += esc(note.created_by);
                            h += '</span>';
                            h += '</div>';
                            h += '<div class="nhub-tree-note-text">' + esc(note.note_text) + '</div>';
                            h += '</div>';
                        }
                    }
                    h += '</div>';
                    h += '</div>';
                }
            }

            h += '</div>';
            h += '</div>';
        }

        $ct.html(
            '<div class="nhub-tree-toolbar">' +
            '<button type="button" class="t-Button t-Button--tiny t-Button--link nhub-tree-expand-all">' +
            '<span class="fa fa-expand"></span> Expand All</button>' +
            '</div>' + h
        );
    }

    // Expand All / Collapse All toggle
    $(document).on("click", ".nhub-tree-expand-all", function () {
        var $btn      = $(this),
            expanding = $btn.data("state") !== "expanded",
            $tree     = $("#nhub-req-tree");

        if (expanding) {
            $tree.find(".nhub-tree-children").slideDown(150);
            $tree.find(".nhub-tree-toggle").removeClass("fa-chevron-right").addClass("fa-chevron-down");
            $btn.data("state", "expanded")
                .html('<span class="fa fa-compress"></span> Collapse All');
        } else {
            $tree.find(".nhub-tree-children").slideUp(150);
            $tree.find(".nhub-tree-toggle").removeClass("fa-chevron-down").addClass("fa-chevron-right");
            $btn.data("state", "")
                .html('<span class="fa fa-expand"></span> Expand All');
        }
    });

    $(document).on("click", ".nhub-tree-toggle", function (e) {
        e.stopPropagation();
        var $toggle   = $(this),
            $node     = $toggle.closest(".nhub-tree-node"),
            $children = $node.children(".nhub-tree-children");

        if ($children.is(":visible")) {
            $children.slideUp(150);
            $toggle.removeClass("fa-chevron-down").addClass("fa-chevron-right");
        } else {
            $children.slideDown(150);
            $toggle.removeClass("fa-chevron-right").addClass("fa-chevron-down");
        }
    });

    $(document).on("click", ".nhub-tree-row", function () {
        $(this).find(".nhub-tree-toggle").trigger("click");
    });

    /* ================================================================== */
    /*  Tab 2: Collapsible candidate sections in Req Cards               */
    /* ================================================================== */
    $(document).on("click", "#req_cards .nhub-ne-cand-hdr", function () {
        var $hdr = $(this),
            $td  = $hdr.closest("td"),
            $tr  = $hdr.closest("tr"),
            collapsing = !$hdr.hasClass("nhub-collapsed");

        $hdr.toggleClass("nhub-collapsed", collapsing);

        // Hide/show the note(s) in the same cell as the header
        $td.find(".nhub-ne").toggle(!collapsing);

        // Walk subsequent <tr>s until we hit another candidate or req header
        $tr.nextAll("tr").each(function () {
            var $row = $(this),
                html = $row.find("td").first().html() || "";
            if (html.indexOf("nhub-ne-cand-hdr") !== -1 ||
                html.indexOf("nhub-rc-hdr") !== -1) {
                return false; // break — next section starts
            }
            $row.toggle(!collapsing);
        });
    });

    // Load tree on page ready + reload when faceted search updates
    $(function () {
        if ($("#nhub-req-tree").length) loadReqTree();
    });
    $(document).on("apexafterrefresh", "#notes_report", function () {
        loadReqTree();
        // Tab 2 req_cards refresh is handled by a Dynamic Action in Page Designer
    });

    /* ================================================================== */
    /*  Helpers                                                            */
    /* ================================================================== */
    function refreshReports() {
        try { apex.region("notes_report").refresh(); } catch (e) { /* tab not active */ }
        // Tab 2 (req_cards) + Tab 3 (tree) reload via apexafterrefresh / DA cascade
    }

    function showErr(msg) {
        apex.message.showErrors([{ type: "error", location: "page", message: msg }]);
    }

    function spinBtn($btn) {
        $btn.prop("disabled", true)
            .find(".fa-plus").removeClass("fa-plus").addClass("fa-refresh fa-anim-spin");
    }

    function resetBtn($btn) {
        $btn.prop("disabled", false)
            .find(".fa-refresh").removeClass("fa-refresh fa-anim-spin").addClass("fa-plus");
    }

    function esc(s) {
        if (!s) return "";
        if (apex.util && apex.util.escapeHTML) return apex.util.escapeHTML(String(s));
        var d = document.createElement("div");
        d.appendChild(document.createTextNode(String(s)));
        return d.innerHTML;
    }

})();

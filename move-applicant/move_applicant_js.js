/**
 * Move Applicant — Right-Side Drawer
 * ------------------------------------
 * Opens a drawer to move a job application between recruiting
 * phases/states via REST POST to Fusion.
 *
 * APEX setup:
 *   - Upload as Static Application File, reference on page 24:
 *       JS File URL:  #APP_FILES#move_applicant_js#MIN#.js
 *   - Requires Ajax callbacks: GET_APP_DETAILS, MOVE_APPLICANT
 *   - Page items: P24_JOB_APPLICATION_ID, P24_CANDIDATE_DISPLAY,
 *     P24_CURRENT_PHASE, P24_CURRENT_STATE, P24_PHASE_ID,
 *     P24_STATE_ID, P24_COMMENTS
 *   - Region static ID: move_form_region
 */
(function () {
    "use strict";

    /* ── Backdrop + inline alert (injected once on page load) ── */
    $(function () {
        if (!$("#drawer_backdrop").length) {
            $("body").append('<div id="drawer_backdrop"></div>');
            $("#drawer_backdrop").on("click", function () { cancelMoveForm(); });
        }
        if (!$("#drawer_alert").length) {
            $("#move_form_region .t-Region-body").prepend(
                '<div id="drawer_alert" style="display:none">' +
                '<span class="drawer-alert-icon fa fa-exclamation-circle"></span>' +
                '<span class="drawer-alert-msg"></span>' +
                '<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>' +
                '</div>'
            );
            $("#drawer_alert").on("click", ".drawer-alert-close", function () { hideDrawerAlert(); });
        }
    });

    function showDrawerAlert(msg) {
        $("#drawer_alert").find(".drawer-alert-msg").text(msg);
        $("#drawer_alert").slideDown(200);
    }
    function hideDrawerAlert() {
        $("#drawer_alert").slideUp(150);
    }

    /* ── Open drawer ── */
    window.openMoveForm = function (appId) {
        apex.server.process("GET_APP_DETAILS", {
            x01: appId
        }, {
            success: function (data) {
                $s("P24_JOB_APPLICATION_ID", appId);
                $s("P24_CANDIDATE_DISPLAY", data.candidate_name);
                $s("P24_CURRENT_PHASE", data.phase);
                $s("P24_CURRENT_STATE", data.state);
                $s("P24_PHASE_ID", data.phase_id ? String(data.phase_id) : "");
                $s("P24_STATE_ID", "");
                $s("P24_COMMENTS", "");
                hideDrawerAlert();
                $("#move_form_region").addClass("is-open");
                $("#drawer_backdrop").addClass("is-open");
            },
            error: function () {
                apex.message.showErrors([{
                    type: "error",
                    location: "page",
                    message: "Could not load applicant details."
                }]);
            }
        });
    };

    /* ── Submit move ── */
    window.submitMove = function () {
        var appId    = $v("P24_JOB_APPLICATION_ID");
        var phaseId  = $v("P24_PHASE_ID");
        var stateId  = $v("P24_STATE_ID");
        var comments = $v("P24_COMMENTS");

        if (!phaseId || !stateId) {
            showDrawerAlert("Please select both a Phase and a State.");
            return;
        }

        hideDrawerAlert();
        apex.server.process("MOVE_APPLICANT", {
            x01: appId,
            x02: phaseId,
            x03: stateId,
            x04: comments
        }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "ERROR") {
                    showDrawerAlert(data.message || "Move failed.");
                } else {
                    cancelMoveForm();
                    apex.message.showPageSuccess("Applicant moved successfully.");
                    apex.region("applicant_irr").refresh();
                }
            },
            error: function () {
                showDrawerAlert("Move failed. Please try again.");
            }
        });
    };

    /* ── Cancel / close ── */
    window.cancelMoveForm = function () {
        apex.message.clearErrors();
        hideDrawerAlert();
        $("#move_form_region").removeClass("is-open");
        $("#drawer_backdrop").removeClass("is-open");
    };

})();

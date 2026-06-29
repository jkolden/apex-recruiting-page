/**
 * Move Applicant Drawer
 * Allows recruiters to move a job application between recruiting
 * phases and states via a slide-out drawer panel.
 *
 * Ajax callbacks used:
 *   - GET_APP_DETAILS  → loads candidate name, current phase/state
 *   - MOVE_APPLICANT   → calls pkg_rec_move.move_application (REST POST to Fusion)
 *
 * Regions: move_form_region (slide-out drawer)
 * Items:   P24_JOB_APPLICATION_ID, P24_CANDIDATE_DISPLAY,
 *          P24_CURRENT_PHASE, P24_CURRENT_STATE,
 *          P24_PHASE_ID (select), P24_STATE_ID (cascading select),
 *          P24_COMMENTS (textarea)
 */

function openMoveForm(appId) {
    apex.server.process("GET_APP_DETAILS", {
        x01: appId
    }, {
        success: function(data) {
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
        error: function(jqXHR, textStatus, errorThrown) {
            apex.message.showErrors([{
                type: "error",
                location: "page",
                message: "Could not load applicant details."
            }]);
        }
    });
}

function submitMove() {
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
        success: function(data) {
            if (data.status === "ERROR") {
                showDrawerAlert(data.message || "Move failed.");
            } else {
                cancelMoveForm();
                apex.message.showPageSuccess("Applicant moved successfully.");
                apex.region("applicant_irr").refresh();
            }
        },
        error: function(jqXHR) {
            showDrawerAlert("Move failed. Please try again.");
        }
    });
}

function cancelMoveForm() {
    apex.message.clearErrors();
    hideDrawerAlert();
    $("#move_form_region").removeClass("is-open");
    $("#drawer_backdrop").removeClass("is-open");
}

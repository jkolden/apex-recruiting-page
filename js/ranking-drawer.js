/**
 * Applicant Ranking Drawer
 * Allows recruiters to score (1-5) and recommend applicants
 * via a slide-out drawer panel.
 *
 * Ajax callbacks used:
 *   - GET_RANKING_DETAILS → loads existing ranking from applicant_ranking table
 *   - SAVE_RANKING        → MERGE into applicant_ranking
 *
 * Regions: ranking_form_region (slide-out drawer)
 * Items:   P24_RANK_APP_ID, P24_RANK_CANDIDATE,
 *          P24_RANK_SCORE (select 1-5), P24_RANK_TEXT (select recommendation),
 *          P24_RANK_NOTE (textarea), P24_RANK_LAST_BY (display only)
 */

function openRankingForm(appId) {
    apex.server.process("GET_RANKING_DETAILS", {
        x01: appId
    }, {
        dataType: "json",
        success: function(data) {
            $s("P24_RANK_APP_ID", appId);
            $s("P24_RANK_CANDIDATE", data.candidate_name || "");
            $s("P24_RANK_SCORE", data.ranking_score ? String(data.ranking_score) : "");
            $s("P24_RANK_TEXT", data.ranking_text || "");
            $s("P24_RANK_NOTE", data.ranking_note || "");
            $s("P24_RANK_LAST_BY", data.ranked_by || "Not yet ranked");
            hideRankingAlert();
            $("#ranking_form_region").addClass("is-open");
            $("#ranking_backdrop").addClass("is-open");
        },
        error: function() {
            apex.message.showErrors([{type:"error",location:"page",
                message:"Could not load ranking details."}]);
        }
    });
}

function submitRanking() {
    var appId = $v("P24_RANK_APP_ID");
    var score = $v("P24_RANK_SCORE");
    var text  = $v("P24_RANK_TEXT");
    var note  = $v("P24_RANK_NOTE");

    if (!score && !text) {
        showRankingAlert("Please select a Score or Recommendation.");
        return;
    }
    hideRankingAlert();
    apex.server.process("SAVE_RANKING", {
        x01: appId,
        x02: score,
        x03: text,
        x04: note
    }, {
        dataType: "json",
        success: function(data) {
            if (data.status === "ERROR") {
                showRankingAlert(data.message || "Save failed.");
            } else {
                cancelRankingForm();
                apex.message.showPageSuccess("Ranking saved.");
                apex.region("applicant_irr").refresh();
            }
        },
        error: function() {
            showRankingAlert("Save failed. Please try again.");
        }
    });
}

function cancelRankingForm() {
    apex.message.clearErrors();
    hideRankingAlert();
    $("#ranking_form_region").removeClass("is-open");
    $("#ranking_backdrop").removeClass("is-open");
}

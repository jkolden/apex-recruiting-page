/**
 * Ranking — Right-Side Drawer
 * -----------------------------
 * Opens a drawer to score/recommend a job applicant.
 * Stores in local APPLICANT_RANKING table (no Fusion write-back).
 *
 * APEX setup:
 *   - Upload as Static Application File, reference on page 24:
 *       JS File URL:  #APP_FILES#ranking_js#MIN#.js
 *   - Requires Ajax callbacks: GET_RANKING_DETAILS, SAVE_RANKING
 *   - Page items: P24_RANK_APP_ID, P24_RANK_CANDIDATE,
 *     P24_RANK_SCORE, P24_RANK_TEXT, P24_RANK_NOTE, P24_RANK_LAST_BY
 *   - Region static ID: ranking_form_region
 */
(function () {
    "use strict";

    /* ── Backdrop + alert (injected once) ── */
    $(function () {
        if (!$("#ranking_backdrop").length) {
            $("body").append('<div id="ranking_backdrop"></div>');
            $("#ranking_backdrop").on("click", function () { cancelRankingForm(); });
        }
        if (!$("#ranking_alert").length) {
            $("#ranking_form_region .t-Region-body").prepend(
                '<div id="ranking_alert" style="display:none">' +
                '<span class="drawer-alert-icon fa fa-exclamation-circle"></span>' +
                '<span class="drawer-alert-msg"></span>' +
                '<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>' +
                '</div>'
            );
            $("#ranking_alert").on("click", ".drawer-alert-close", function () { hideRankingAlert(); });
        }
    });

    function showRankingAlert(msg) {
        $("#ranking_alert").find(".drawer-alert-msg").text(msg);
        $("#ranking_alert").slideDown(200);
    }
    function hideRankingAlert() {
        $("#ranking_alert").slideUp(150);
    }

    /* ── Open drawer ── */
    window.openRankingForm = function (appId) {
        apex.server.process("GET_RANKING_DETAILS", {
            x01: appId
        }, {
            dataType: "json",
            success: function (data) {
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
            error: function () {
                apex.message.showErrors([{
                    type: "error", location: "page",
                    message: "Could not load ranking details."
                }]);
            }
        });
    };

    /* ── Submit ranking ── */
    window.submitRanking = function () {
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
            success: function (data) {
                if (data.status === "ERROR") {
                    showRankingAlert(data.message || "Save failed.");
                } else {
                    cancelRankingForm();
                    apex.message.showPageSuccess("Ranking saved.");
                    apex.region("applicant_irr").refresh();
                }
            },
            error: function () {
                showRankingAlert("Save failed. Please try again.");
            }
        });
    };

    /* ── Cancel / close ── */
    window.cancelRankingForm = function () {
        apex.message.clearErrors();
        hideRankingAlert();
        $("#ranking_form_region").removeClass("is-open");
        $("#ranking_backdrop").removeClass("is-open");
    };

})();

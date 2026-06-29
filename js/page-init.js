/**
 * Page Initialization
 * Injects backdrop overlays and inline alert banners for the
 * Move Applicant, Ranking, and Ref Correction Link drawers.
 * Runs once on page load via $(function(){...}).
 */

/* ── Move Drawer backdrop + inline alert ── */
$(function(){
    if (!$("#drawer_backdrop").length) {
        $("body").append('<div id="drawer_backdrop"></div>');
        $("#drawer_backdrop").on("click", function(){ cancelMoveForm(); });
    }
    if (!$("#drawer_alert").length) {
        $("#move_form_region .t-Region-body").prepend(
            '<div id="drawer_alert" style="display:none">' +
            '<span class="drawer-alert-icon fa fa-exclamation-circle"></span>' +
            '<span class="drawer-alert-msg"></span>' +
            '<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>' +
            '</div>'
        );
        $("#drawer_alert").on("click", ".drawer-alert-close", function(){ hideDrawerAlert(); });
    }
});

function showDrawerAlert(msg) {
    $("#drawer_alert").find(".drawer-alert-msg").text(msg);
    $("#drawer_alert").slideDown(200);
}
function hideDrawerAlert() {
    $("#drawer_alert").slideUp(150);
}

/* ── Ranking Drawer backdrop + inline alert ── */
$(function(){
    if (!$("#ranking_backdrop").length) {
        $("body").append('<div id="ranking_backdrop"></div>');
        $("#ranking_backdrop").on("click", function(){ cancelRankingForm(); });
    }
    if (!$("#ranking_alert").length) {
        $("#ranking_form_region .t-Region-body").prepend(
            '<div id="ranking_alert" style="display:none">' +
            '<span class="drawer-alert-icon fa fa-exclamation-circle"></span>' +
            '<span class="drawer-alert-msg"></span>' +
            '<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>' +
            '</div>'
        );
        $("#ranking_alert").on("click", ".drawer-alert-close", function(){ hideRankingAlert(); });
    }
});
function showRankingAlert(msg) {
    $("#ranking_alert").find(".drawer-alert-msg").text(msg);
    $("#ranking_alert").slideDown(200);
}
function hideRankingAlert() {
    $("#ranking_alert").slideUp(150);
}

/* ── Ref Link Drawer backdrop + inline alert ── */
$(function(){
    if (!$("#reflink_backdrop").length) {
        $("body").append('<div id="reflink_backdrop"></div>');
        $("#reflink_backdrop").on("click", function(){ cancelRefLinkForm(); });
    }
    if (!$("#reflink_alert").length) {
        $("#reflink_form_region .t-Region-body").prepend(
            '<div id="reflink_alert" style="display:none">' +
            '<span class="drawer-alert-icon fa fa-exclamation-circle"></span>' +
            '<span class="drawer-alert-msg"></span>' +
            '<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>' +
            '</div>'
        );
        $("#reflink_alert").on("click", ".drawer-alert-close", function(){ hideRefLinkAlert(); });
    }
});
function showRefLinkAlert(msg) {
    $("#reflink_alert").find(".drawer-alert-msg").text(msg);
    $("#reflink_alert").slideDown(200);
}
function hideRefLinkAlert() {
    $("#reflink_alert").slideUp(150);
}

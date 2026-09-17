/**
 * Reference Correction Link — Right-Side Drawer
 * ------------------------------------------------
 * Generates a one-time secure URL and optionally emails it
 * to an applicant so they can correct reference contact info.
 *
 * APEX setup:
 *   - Upload as Static Application File, reference on page 24:
 *       JS File URL:  #APP_FILES#ref_correction_link_js#MIN#.js
 *   - Requires Ajax callbacks: GENERATE_REF_LINK, SEND_REF_LINK_EMAIL
 *   - Page items: P24_REFLINK_APP_ID, P24_REFLINK_CANDIDATE,
 *     P24_REFLINK_URL, P24_REFLINK_EMAIL, P24_REFLINK_NOTE
 *   - Region static ID: reflink_form_region
 *   - Button static IDs: COPY_REF_LINK_BTN, SEND_REF_EMAIL_BTN
 */
(function () {
    "use strict";

    /* ── Backdrop + alert (injected once) ── */
    $(function () {
        if (!$("#reflink_backdrop").length) {
            $("body").append('<div id="reflink_backdrop"></div>');
            $("#reflink_backdrop").on("click", function () { cancelRefLinkForm(); });
        }
        if (!$("#reflink_alert").length) {
            $("#reflink_form_region .t-Region-body").prepend(
                '<div id="reflink_alert" style="display:none">' +
                '<span class="drawer-alert-icon fa fa-exclamation-circle"></span>' +
                '<span class="drawer-alert-msg"></span>' +
                '<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>' +
                '</div>'
            );
            $("#reflink_alert").on("click", ".drawer-alert-close", function () { hideRefLinkAlert(); });
        }
    });

    function showRefLinkAlert(msg) {
        $("#reflink_alert").find(".drawer-alert-msg").text(msg);
        $("#reflink_alert").slideDown(200);
    }
    function hideRefLinkAlert() {
        $("#reflink_alert").slideUp(150);
    }

    /* ── Open drawer ── */
    window.openRefLinkForm = function (appId) {
        apex.server.process("GENERATE_REF_LINK", {
            x01: appId
        }, {
            dataType: "json",
            success: function (data) {
                if (data.status === "ERROR") {
                    apex.message.showErrors([{
                        type: "error", location: "page",
                        message: data.message || "Could not generate link."
                    }]);
                    return;
                }
                $s("P24_REFLINK_APP_ID", appId);
                $s("P24_REFLINK_CANDIDATE", data.candidate_name || "");
                $s("P24_REFLINK_URL", data.url || "");
                $s("P24_REFLINK_EMAIL", data.candidate_email || "");
                hideRefLinkAlert();
                $("#reflink_form_region").addClass("is-open");
                $("#reflink_backdrop").addClass("is-open");
            },
            error: function () {
                apex.message.showErrors([{
                    type: "error", location: "page",
                    message: "Could not generate correction link."
                }]);
            }
        });
    };

    /* ── Copy link to clipboard ── */
    window.copyRefLink = function () {
        var url = $v("P24_REFLINK_URL");
        if (!url) {
            showRefLinkAlert("No link generated yet.");
            return;
        }
        navigator.clipboard.writeText(url).then(function () {
            apex.message.showPageSuccess("Link copied to clipboard.");
        }).catch(function () {
            var el = document.getElementById("P24_REFLINK_URL_DISPLAY");
            if (el) {
                var range = document.createRange();
                range.selectNodeContents(el);
                window.getSelection().removeAllRanges();
                window.getSelection().addRange(range);
            }
            showRefLinkAlert("Could not copy automatically. Please select and copy the URL above.");
        });
    };

    /* ── Send email ── */
    window.sendRefLinkEmail = function () {
        var appId = $v("P24_REFLINK_APP_ID");
        var email = $v("P24_REFLINK_EMAIL");
        var url   = $v("P24_REFLINK_URL");
        var note  = $v("P24_REFLINK_NOTE");

        if (!email) {
            showRefLinkAlert("Please enter an email address.");
            return;
        }
        if (!url) {
            showRefLinkAlert("No link generated yet.");
            return;
        }
        hideRefLinkAlert();

        var $btn = $("#SEND_REF_EMAIL_BTN");
        var origLabel = $btn.find(".t-Button-label").text();
        $btn.prop("disabled", true).find(".t-Button-label").text("Sending...");

        apex.server.process("SEND_REF_LINK_EMAIL", {
            x01: appId,
            x02: email,
            x03: url,
            x04: note
        }, {
            dataType: "json",
            success: function (data) {
                $btn.prop("disabled", false).find(".t-Button-label").text(origLabel);
                if (data.status === "ERROR") {
                    showRefLinkAlert(data.message || "Send failed.");
                } else {
                    cancelRefLinkForm();
                    apex.message.showPageSuccess("Email sent to " + email);
                }
            },
            error: function () {
                $btn.prop("disabled", false).find(".t-Button-label").text(origLabel);
                showRefLinkAlert("Send failed. Please try again.");
            }
        });
    };

    /* ── Cancel / close ── */
    window.cancelRefLinkForm = function () {
        apex.message.clearErrors();
        hideRefLinkAlert();
        $("#reflink_form_region").removeClass("is-open");
        $("#reflink_backdrop").removeClass("is-open");
    };

})();

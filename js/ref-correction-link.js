/**
 * Reference Correction Link Drawer
 * Generates a secure one-time URL for applicants to correct their
 * reference contact information, with option to email the link.
 *
 * Ajax callbacks used:
 *   - GENERATE_REF_LINK    → calls pkg_ref_correction.generate_token
 *   - SEND_REF_LINK_EMAIL  → calls pkg_ref_correction.send_correction_email
 *
 * Regions: reflink_form_region (slide-out drawer)
 * Items:   P24_REFLINK_APP_ID, P24_REFLINK_CANDIDATE,
 *          P24_REFLINK_URL, P24_REFLINK_EMAIL
 * Buttons: COPY_REF_LINK_BTN, SEND_REF_EMAIL_BTN, CANCEL_REFLINK_BTN
 */

function openRefLinkForm(appId) {
    apex.server.process("GENERATE_REF_LINK", {
        x01: appId
    }, {
        dataType: "json",
        success: function(data) {
            if (data.status === "ERROR") {
                apex.message.showErrors([{type:"error", location:"page",
                    message: data.message || "Could not generate link."}]);
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
        error: function() {
            apex.message.showErrors([{type:"error", location:"page",
                message:"Could not generate correction link."}]);
        }
    });
}

function copyRefLink() {
    var url = $v("P24_REFLINK_URL");
    if (!url) {
        showRefLinkAlert("No link generated yet.");
        return;
    }
    navigator.clipboard.writeText(url).then(function() {
        apex.message.showPageSuccess("Link copied to clipboard.");
    }).catch(function() {
        var el = document.getElementById("P24_REFLINK_URL_DISPLAY");
        if (el) {
            var range = document.createRange();
            range.selectNodeContents(el);
            window.getSelection().removeAllRanges();
            window.getSelection().addRange(range);
        }
        showRefLinkAlert("Could not copy automatically. Please select and copy the URL above.");
    });
}

function sendRefLinkEmail() {
    var appId = $v("P24_REFLINK_APP_ID");
    var email = $v("P24_REFLINK_EMAIL");
    var url   = $v("P24_REFLINK_URL");

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
        x03: url
    }, {
        dataType: "json",
        success: function(data) {
            $btn.prop("disabled", false).find(".t-Button-label").text(origLabel);
            if (data.status === "ERROR") {
                showRefLinkAlert(data.message || "Send failed.");
            } else {
                cancelRefLinkForm();
                apex.message.showPageSuccess("Email sent to " + email);
            }
        },
        error: function() {
            $btn.prop("disabled", false).find(".t-Button-label").text(origLabel);
            showRefLinkAlert("Send failed. Please try again.");
        }
    });
}

function cancelRefLinkForm() {
    apex.message.clearErrors();
    hideRefLinkAlert();
    $("#reflink_form_region").removeClass("is-open");
    $("#reflink_backdrop").removeClass("is-open");
}

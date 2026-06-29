prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.17'
,p_default_workspace_id=>8325564762610682
,p_default_application_id=>121
,p_default_id_offset=>0
,p_default_owner=>'WKSP_FREEDEMO'
);
end;
/
 
prompt APPLICATION 121 - Fusion Integrated Sample App (ibzsjb-test)
--
-- Application Export:
--   Application:     121
--   Name:            Fusion Integrated Sample App (ibzsjb-test)
--   Exported By:     JOHN.KOLDEN@SIERRA-CEDAR.COM
--   Flashback:       0
--   Export Type:     Page Export
--   Manifest
--     PAGE: 24
--   Manifest End
--   Version:         24.2.17
--   Instance ID:     8325348246048613
--

begin
null;
end;
/
prompt --application/pages/delete_00024
begin
wwv_flow_imp_page.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>24);
end;
/
prompt --application/pages/page_00024
begin
wwv_flow_imp_page.create_page(
 p_id=>24
,p_name=>'Management Report'
,p_alias=>'MANAGEMENT-REPORT3'
,p_step_title=>'Management Report'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#APP_FILES#candidate_notes_js#MIN#.js',
'#APP_FILES#candidate_phones_js#MIN#.js',
'#APP_FILES#applicant_notes_js#MIN#.js',
''))
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('/* \2500\2500 Drawer backdrop + inline alert (injected once on page load) \2500\2500 */'),
'$(function(){',
'    if (!$("#drawer_backdrop").length) {',
'        $("body").append(''<div id="drawer_backdrop"></div>'');',
'        $("#drawer_backdrop").on("click", function(){ cancelMoveForm(); });',
'    }',
'    if (!$("#drawer_alert").length) {',
'        $("#move_form_region .t-Region-body").prepend(',
'            ''<div id="drawer_alert" style="display:none">'' +',
'            ''<span class="drawer-alert-icon fa fa-exclamation-circle"></span>'' +',
'            ''<span class="drawer-alert-msg"></span>'' +',
'            ''<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>'' +',
'            ''</div>''',
'        );',
'        $("#drawer_alert").on("click", ".drawer-alert-close", function(){ hideDrawerAlert(); });',
'    }',
'});',
'',
'function showDrawerAlert(msg) {',
'    $("#drawer_alert").find(".drawer-alert-msg").text(msg);',
'    $("#drawer_alert").slideDown(200);',
'}',
'function hideDrawerAlert() {',
'    $("#drawer_alert").slideUp(150);',
'}',
'',
'function openMoveForm(appId) {',
'    apex.server.process("GET_APP_DETAILS", {',
'        x01: appId',
'    }, {',
'        success: function(data) {',
'            $s("P24_JOB_APPLICATION_ID", appId);',
'            $s("P24_CANDIDATE_DISPLAY", data.candidate_name);',
'            $s("P24_CURRENT_PHASE", data.phase);',
'            $s("P24_CURRENT_STATE", data.state);',
'            $s("P24_PHASE_ID", data.phase_id ? String(data.phase_id) : "");',
'            $s("P24_STATE_ID", "");',
'            $s("P24_COMMENTS", "");',
'            hideDrawerAlert();',
'            $("#move_form_region").addClass("is-open");',
'            $("#drawer_backdrop").addClass("is-open");',
'',
'        },',
'        error: function(jqXHR, textStatus, errorThrown) {',
'            apex.message.showErrors([{',
'                type: "error",',
'                location: "page",',
'                message: "Could not load applicant details."',
'            }]);',
'        }',
'    });',
'}',
'',
'function submitMove() {',
'    var appId    = $v("P24_JOB_APPLICATION_ID");',
'    var phaseId  = $v("P24_PHASE_ID");',
'    var stateId  = $v("P24_STATE_ID");',
'    var comments = $v("P24_COMMENTS");',
'',
'    if (!phaseId || !stateId) {',
'        showDrawerAlert("Please select both a Phase and a State.");',
'        return;',
'    }',
'',
'    hideDrawerAlert();',
'    apex.server.process("MOVE_APPLICANT", {',
'        x01: appId,',
'        x02: phaseId,',
'        x03: stateId,',
'        x04: comments',
'    }, {',
'        dataType: "json",',
'        success: function(data) {',
'            if (data.status === "ERROR") {',
'                showDrawerAlert(data.message || "Move failed.");',
'            } else {',
'                cancelMoveForm();',
'                apex.message.showPageSuccess("Applicant moved successfully.");',
'                apex.region("applicant_irr").refresh();',
'            }',
'        },',
'        error: function(jqXHR) {',
'            showDrawerAlert("Move failed. Please try again.");',
'        }',
'    });',
'}',
'',
'function cancelMoveForm() {',
'    apex.message.clearErrors();',
'    hideDrawerAlert();',
'    $("#move_form_region").removeClass("is-open");',
'    $("#drawer_backdrop").removeClass("is-open");',
'}',
'',
'',
unistr('/* \2500\2500 Attachment Modal \2500\2500 */'),
'function openAttachments(appId) {',
'    var $modal = $("#attachment_modal");',
'    if (!$modal.length) {',
'        $("body").append(',
'            ''<div id="att_backdrop" class="att-backdrop"></div>'' +',
'            ''<div id="attachment_modal" class="att-modal">'' +',
'            ''  <div class="att-modal-header">'' +',
'            ''    <span class="att-modal-title">Attachments</span>'' +',
'            ''    <button type="button" class="att-modal-close" onclick="closeAttachments()">&times;</button>'' +',
'            ''  </div>'' +',
'            ''  <div class="att-modal-body" id="att_modal_body"></div>'' +',
'            ''</div>''',
'        );',
'        $modal = $("#attachment_modal");',
'        $("#att_backdrop").on("click", function(){ closeAttachments(); });',
'    }',
'',
'    $("#att_modal_body").html(',
'        ''<div class="att-loading"><span class="fa fa-refresh fa-anim-spin"></span> Loading attachments...</div>''',
'    );',
'    $modal.addClass("is-open");',
'    $("#att_backdrop").addClass("is-open");',
'',
'    apex.server.process("LIST_ATTACHMENTS", {',
'        x01: String(appId)',
'    }, {',
'        dataType: "json",',
'        success: function(data) {',
'            if (data.status === "ERROR") {',
'                $("#att_modal_body").html(',
'                    ''<div class="att-error"><span class="fa fa-exclamation-triangle"></span> ''',
'                    + apex.util.escapeHTML(data.message) + ''</div>''',
'                );',
'                return;',
'            }',
'            if (!data.items || data.items.length === 0) {',
'                $("#att_modal_body").html(',
'                    ''<div class="att-empty"><span class="fa fa-folder-o"></span> No attachments found.</div>''',
'                );',
'                return;',
'            }',
'            var html = ''<table class="att-table">''',
'                + ''<thead><tr><th>File</th><th>Size</th><th>Category</th><th>Date</th><th></th></tr></thead><tbody>'';',
'            data.items.forEach(function(item) {',
'                var ic = getFileIcon(item.content_type, item.file_name);',
'                var url = item.download_url;',
'                html += ''<tr>''',
'                    + ''<td><span class="fa '' + ic + '' att-file-icon"></span> ''',
'                    + apex.util.escapeHTML(item.file_name || item.title || "Untitled")',
'                    + ''</td>''',
'                    + ''<td class="att-size">'' + formatFileSize(item.file_size) + ''</td>''',
'                    + ''<td>'' + apex.util.escapeHTML(item.category || "") + ''</td>''',
'                    + ''<td class="att-date">''',
'                    + (item.creation_date ? item.creation_date.substring(0,10) : "")',
'                    + ''</td>''',
'                    + ''<td><a href="'' + url + ''" target="_blank" class="t-Button t-Button--small t-Button--noUI">''',
'                    + ''<span class="fa fa-download"></span></a></td>''',
'                    + ''</tr>'';',
'            });',
'            html += ''</tbody></table>'';',
'            $("#att_modal_body").html(html);',
'        },',
'        error: function() {',
'            $("#att_modal_body").html(',
'                ''<div class="att-error"><span class="fa fa-exclamation-triangle"></span> Failed to load attachments.</div>''',
'            );',
'        }',
'    });',
'}',
'',
'function closeAttachments() {',
'    $("#attachment_modal").removeClass("is-open");',
'    $("#att_backdrop").removeClass("is-open");',
'}',
'',
'function getFileIcon(ct, fn) {',
'    ct = ct || ""; fn = fn || "";',
'    var ext = fn.split(".").pop().toLowerCase();',
'    if (ct.indexOf("pdf") > -1 || ext === "pdf") return "fa-file-pdf-o";',
'    if (ct.indexOf("word") > -1 || ext === "doc" || ext === "docx") return "fa-file-word-o";',
'    if (ct.indexOf("image") > -1) return "fa-file-image-o";',
'    if (ct.indexOf("text") > -1 || ext === "txt") return "fa-file-text-o";',
'    return "fa-file-o";',
'}',
'',
'function formatFileSize(bytes) {',
'    if (!bytes) return "";',
'    if (bytes < 1024) return bytes + " B";',
'    if (bytes < 1048576) return (bytes / 1024).toFixed(0) + " KB";',
'    return (bytes / 1048576).toFixed(1) + " MB";',
'}',
'',
unistr('/* \2500\2500 Ranking Drawer \2500\2500 */'),
'function openRankingForm(appId) {',
'    apex.server.process("GET_RANKING_DETAILS", {',
'        x01: appId',
'    }, {',
'        dataType: "json",',
'        success: function(data) {',
'            $s("P24_RANK_APP_ID", appId);',
'            $s("P24_RANK_CANDIDATE", data.candidate_name || "");',
'            $s("P24_RANK_SCORE", data.ranking_score ? String(data.ranking_score) : "");',
'            $s("P24_RANK_TEXT", data.ranking_text || "");',
'            $s("P24_RANK_NOTE", data.ranking_note || "");',
'            $s("P24_RANK_LAST_BY", data.ranked_by || "Not yet ranked");',
'            hideRankingAlert();',
'            $("#ranking_form_region").addClass("is-open");',
'            $("#ranking_backdrop").addClass("is-open");',
'        },',
'        error: function() {',
'            apex.message.showErrors([{type:"error",location:"page",',
'                message:"Could not load ranking details."}]);',
'        }',
'    });',
'}',
'',
'function submitRanking() {',
'    var appId = $v("P24_RANK_APP_ID");',
'    var score = $v("P24_RANK_SCORE");',
'    var text  = $v("P24_RANK_TEXT");',
'    var note  = $v("P24_RANK_NOTE");',
'',
'    if (!score && !text) {',
'        showRankingAlert("Please select a Score or Recommendation.");',
'        return;',
'    }',
'    hideRankingAlert();',
'    apex.server.process("SAVE_RANKING", {',
'        x01: appId,',
'        x02: score,',
'        x03: text,',
'        x04: note',
'    }, {',
'        dataType: "json",',
'        success: function(data) {',
'            if (data.status === "ERROR") {',
'                showRankingAlert(data.message || "Save failed.");',
'            } else {',
'                cancelRankingForm();',
'                apex.message.showPageSuccess("Ranking saved.");',
'                apex.region("applicant_irr").refresh();',
'            }',
'        },',
'        error: function() {',
'            showRankingAlert("Save failed. Please try again.");',
'        }',
'    });',
'}',
'',
'function cancelRankingForm() {',
'    apex.message.clearErrors();',
'    hideRankingAlert();',
'    $("#ranking_form_region").removeClass("is-open");',
'    $("#ranking_backdrop").removeClass("is-open");',
'}',
'',
unistr('/* \2500\2500 Ranking drawer alert (reuses pattern from move drawer) \2500\2500 */'),
'$(function(){',
'    if (!$("#ranking_backdrop").length) {',
'        $("body").append(''<div id="ranking_backdrop"></div>'');',
'        $("#ranking_backdrop").on("click", function(){ cancelRankingForm(); });',
'    }',
'    if (!$("#ranking_alert").length) {',
'        $("#ranking_form_region .t-Region-body").prepend(',
'            ''<div id="ranking_alert" style="display:none">'' +',
'            ''<span class="drawer-alert-icon fa fa-exclamation-circle"></span>'' +',
'            ''<span class="drawer-alert-msg"></span>'' +',
'            ''<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>'' +',
'            ''</div>''',
'        );',
'        $("#ranking_alert").on("click", ".drawer-alert-close", function(){ hideRankingAlert(); });',
'    }',
'});',
'function showRankingAlert(msg) {',
'    $("#ranking_alert").find(".drawer-alert-msg").text(msg);',
'    $("#ranking_alert").slideDown(200);',
'}',
'function hideRankingAlert() {',
'    $("#ranking_alert").slideUp(150);',
'}',
'',
unistr('/* \2500\2500 Ref Correction Link Drawer \2500\2500 */'),
'function openRefLinkForm(appId) {',
'    apex.server.process("GENERATE_REF_LINK", {',
'        x01: appId',
'    }, {',
'        dataType: "json",',
'        success: function(data) {',
'            if (data.status === "ERROR") {',
'                apex.message.showErrors([{type:"error", location:"page",',
'                    message: data.message || "Could not generate link."}]);',
'                return;',
'            }',
'            $s("P24_REFLINK_APP_ID", appId);',
'            $s("P24_REFLINK_CANDIDATE", data.candidate_name || "");',
'            $s("P24_REFLINK_URL", data.url || "");',
'            $s("P24_REFLINK_EMAIL", data.candidate_email || "");',
'            hideRefLinkAlert();',
'            $("#reflink_form_region").addClass("is-open");',
'            $("#reflink_backdrop").addClass("is-open");',
'        },',
'        error: function() {',
'            apex.message.showErrors([{type:"error", location:"page",',
'                message:"Could not generate correction link."}]);',
'        }',
'    });',
'}',
'',
'function copyRefLink() {',
'    var url = $v("P24_REFLINK_URL");',
'    if (!url) {',
'        showRefLinkAlert("No link generated yet.");',
'        return;',
'    }',
'    navigator.clipboard.writeText(url).then(function() {',
'        apex.message.showPageSuccess("Link copied to clipboard.");',
'    }).catch(function() {',
'        var el = document.getElementById("P24_REFLINK_URL_DISPLAY");',
'        if (el) {',
'            var range = document.createRange();',
'            range.selectNodeContents(el);',
'            window.getSelection().removeAllRanges();',
'            window.getSelection().addRange(range);',
'        }',
'        showRefLinkAlert("Could not copy automatically. Please select and copy the URL above.");',
'    });',
'}',
'',
'function sendRefLinkEmail() {',
'    var appId = $v("P24_REFLINK_APP_ID");',
'    var email = $v("P24_REFLINK_EMAIL");',
'    var url   = $v("P24_REFLINK_URL");',
'',
'    if (!email) {',
'        showRefLinkAlert("Please enter an email address.");',
'        return;',
'    }',
'    if (!url) {',
'        showRefLinkAlert("No link generated yet.");',
'        return;',
'    }',
'    hideRefLinkAlert();',
'    var $btn = $("#SEND_REF_EMAIL_BTN");',
'    var origLabel = $btn.find(".t-Button-label").text();',
'    $btn.prop("disabled", true).find(".t-Button-label").text("Sending...");',
'',
'    apex.server.process("SEND_REF_LINK_EMAIL", {',
'        x01: appId,',
'        x02: email,',
'        x03: url',
'    }, {',
'        dataType: "json",',
'        success: function(data) {',
'            $btn.prop("disabled", false).find(".t-Button-label").text(origLabel);',
'            if (data.status === "ERROR") {',
'                showRefLinkAlert(data.message || "Send failed.");',
'            } else {',
'                cancelRefLinkForm();',
'                apex.message.showPageSuccess("Email sent to " + email);',
'            }',
'        },',
'        error: function() {',
'            $btn.prop("disabled", false).find(".t-Button-label").text(origLabel);',
'            showRefLinkAlert("Send failed. Please try again.");',
'        }',
'    });',
'}',
'',
'function cancelRefLinkForm() {',
'    apex.message.clearErrors();',
'    hideRefLinkAlert();',
'    $("#reflink_form_region").removeClass("is-open");',
'    $("#reflink_backdrop").removeClass("is-open");',
'}',
'',
unistr('/* \2500\2500 Ref Link drawer alert + backdrop (injected once) \2500\2500 */'),
'$(function(){',
'    if (!$("#reflink_backdrop").length) {',
'        $("body").append(''<div id="reflink_backdrop"></div>'');',
'        $("#reflink_backdrop").on("click", function(){ cancelRefLinkForm(); });',
'    }',
'    if (!$("#reflink_alert").length) {',
'        $("#reflink_form_region .t-Region-body").prepend(',
'            ''<div id="reflink_alert" style="display:none">'' +',
'            ''<span class="drawer-alert-icon fa fa-exclamation-circle"></span>'' +',
'            ''<span class="drawer-alert-msg"></span>'' +',
'            ''<button type="button" class="drawer-alert-close" aria-label="Close">&times;</button>'' +',
'            ''</div>''',
'        );',
'        $("#reflink_alert").on("click", ".drawer-alert-close", function(){ hideRefLinkAlert(); });',
'    }',
'});',
'function showRefLinkAlert(msg) {',
'    $("#reflink_alert").find(".drawer-alert-msg").text(msg);',
'    $("#reflink_alert").slideDown(200);',
'}',
'function hideRefLinkAlert() {',
'    $("#reflink_alert").slideUp(150);',
'}',
''))
,p_css_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#APP_FILES#candidate_notes_css#MIN#.css',
'#APP_FILES#candidate_phones_css.css',
'#APP_FILES#applicant_notes_css#MIN#.css',
'',
''))
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'/* Uniform base width for all columns */',
'#report_table_applicant_irr th,',
'#report_table_applicant_irr td {',
'    min-width: 110px;',
'    max-width: 150px;',
'    white-space: normal;',
'    word-wrap: break-word;',
'}',
'',
'/* Name and email columns slightly wider */',
'#report_table_applicant_irr td[headers="NAME"],',
'#report_table_applicant_irr td[headers="CANDIDATENAME"],',
'#report_table_applicant_irr td[headers="HIRING_MANAGER"],',
'#report_table_applicant_irr td[headers="RECRUITER"] {',
'    min-width: 160px;',
'    max-width: 200px;',
'}',
'',
'/* Email columns */',
'#report_table_applicant_irr td[headers*="GCS_TEACH"] {',
'    min-width: 225px;',
'    max-width: 280px;',
'}',
'',
unistr('/* \2500\2500 MOVE APPLICANT DRAWER \2500\2500 */'),
'#move_form_region {',
'    position: fixed;',
'    top: 60px;',
'    right: -400px;',
'    width: 380px;',
'    max-width: 90vw;',
'    height: calc(100vh - 60px);',
'    z-index: 1010;',
'    background: #f7f8fa;',
'    box-shadow: -4px 0 30px rgba(0,0,0,0.15);',
'    overflow: hidden;',
'    transition: right 0.35s cubic-bezier(0.4, 0, 0.2, 1);',
'    display: flex;',
'    flex-direction: column;',
'}',
'#move_form_region.is-open {',
'    right: 0;',
'}',
'',
unistr('/* \2500\2500 MOVE DRAWER HEADER \2500\2500 */'),
'#move_form_region .t-Region-header {',
'    background: #312d2a;',
'    padding: 12px 20px;',
'    flex-shrink: 0;',
'}',
'#move_form_region .t-Region-title {',
'    color: #fff;',
'    font-size: 18px;',
'    font-weight: 700;',
'    letter-spacing: -0.01em;',
'}',
'',
unistr('/* \2500\2500 MOVE DRAWER BODY \2500\2500 */'),
'#move_form_region .t-Region-body {',
'    padding: 20px;',
'    flex: 1;',
'    overflow-y: auto;',
'}',
'',
unistr('/* \2500\2500 MOVE DRAWER BUTTON BAR \2500\2500 */'),
'#move_form_region .t-Region-buttons--bottom {',
'    flex-shrink: 0;',
'}',
'',
unistr('/* \2500\2500 INLINE ERROR BANNER (inside drawer body) \2500\2500 */'),
'#drawer_alert {',
'    display: none;',
'    background: #fef2f2;',
'    border: 1px solid #fca5a5;',
'    border-radius: 8px;',
'    padding: 12px 40px 12px 16px;',
'    margin-bottom: 20px;',
'    position: relative;',
'    animation: drawerAlertIn 0.2s ease;',
'}',
'@keyframes drawerAlertIn {',
'    from { opacity: 0; transform: translateY(-6px); }',
'    to   { opacity: 1; transform: translateY(0); }',
'}',
'#drawer_alert .drawer-alert-icon {',
'    color: #dc2626;',
'    margin-right: 8px;',
'    font-size: 14px;',
'}',
'#drawer_alert .drawer-alert-msg {',
'    color: #991b1b;',
'    font-size: 13px;',
'    font-weight: 500;',
'    line-height: 1.4;',
'}',
'#drawer_alert .drawer-alert-close {',
'    position: absolute;',
'    top: 8px;',
'    right: 12px;',
'    background: none;',
'    border: none;',
'    color: #9ca3af;',
'    font-size: 18px;',
'    cursor: pointer;',
'    line-height: 1;',
'    padding: 2px 4px;',
'}',
'#drawer_alert .drawer-alert-close:hover {',
'    color: #dc2626;',
'}',
'',
unistr('/* \2500\2500 GRID ROWS \2500\2500 */'),
'#move_form_region .container {',
'    display: flex;',
'    flex-direction: column;',
'    gap: 0;',
'}',
'#move_form_region .container > .row {',
'    margin: 0;',
'}',
'',
unistr('/* \2500\2500 FIELD COLUMNS \2500\2500 */'),
'#move_form_region .container .col {',
'    font-size: 11px;',
'    color: #6b7280;',
'    font-weight: 600;',
'    text-transform: uppercase;',
'    letter-spacing: 0.05em;',
'    line-height: 1.4;',
'    padding: 0 8px 20px 0;',
'}',
'',
unistr('/* \2500\2500 DISPLAY-ONLY VALUES \2500\2500 */'),
'#move_form_region .display_only {',
'    display: block;',
'    font-size: 15px;',
'    font-weight: 600;',
'    color: #111827;',
'    text-transform: none;',
'    letter-spacing: normal;',
'    margin-top: 4px;',
'    line-height: 1.4;',
'}',
'',
'/* Candidate name: hero treatment */',
'#P16_CANDIDATE_DISPLAY_DISPLAY {',
'    font-size: 20px;',
'    font-weight: 700;',
'    color: #1b7c8a;',
'    margin-top: 6px;',
'}',
'',
'/* Current phase/state: pill badges */',
'#P16_CURRENT_PHASE_DISPLAY {',
'    display: inline-block;',
'    background: #e8f0fe;',
'    color: #1a5276;',
'    border: 1px solid #bdd5ea;',
'    border-radius: 3px;',
'    padding: 4px 14px;',
'    font-size: 13px;',
'    font-weight: 600;',
'    text-transform: none;',
'    letter-spacing: normal;',
'    margin-top: 6px;',
'}',
'#P16_CURRENT_STATE_DISPLAY {',
'    display: inline-block;',
'    background: #fef9e7;',
'    color: #7d6608;',
'    border: 1px solid #f0dca0;',
'    border-radius: 3px;',
'    padding: 4px 14px;',
'    font-size: 13px;',
'    font-weight: 600;',
'    text-transform: none;',
'    letter-spacing: normal;',
'    margin-top: 6px;',
'}',
'',
unistr('/* \2500\2500 SEPARATOR between info and action fields \2500\2500 */'),
'#move_form_region .container > .row:nth-child(3) {',
'    margin-top: 4px;',
'    padding-top: 20px;',
'    border-top: 1px solid #e5e7eb;',
'}',
'',
unistr('/* \2500\2500 Reset inherited label styles on form inputs \2500\2500 */'),
'#move_form_region select.selectlist,',
'#move_form_region textarea.apex-item-textarea,',
'#move_form_region .apex-item-group--textarea {',
'    display: block;',
'    margin-top: 5px;',
'    width: 100%;',
'    text-transform: none;',
'    letter-spacing: normal;',
'    max-height: 70px;',
'}',
'',
unistr('/* \2500\2500 BACKDROP (shared by move drawer) \2500\2500 */'),
'#drawer_backdrop {',
'    position: fixed;',
'    top: 0;',
'    left: 0;',
'    width: 100%;',
'    height: 100%;',
'    background: rgba(0,0,0,0.4);',
'    z-index: 1005;',
'    opacity: 0;',
'    pointer-events: none;',
'    transition: opacity 0.35s ease;',
'    backdrop-filter: blur(2px);',
'    -webkit-backdrop-filter: blur(2px);',
'}',
'#drawer_backdrop.is-open {',
'    opacity: 1;',
'    pointer-events: auto;',
'}',
'',
unistr('/* \2500\2500 PHASE/STATE PILLS in the IR grid \2500\2500 */'),
'.phase-pill {',
'    display: inline-block;',
'    padding: 3px 12px;',
'    border-radius: 3px;',
'    font-size: 12px;',
'    font-weight: 600;',
'    letter-spacing: 0.04em;',
'    background: #e8f0fe;',
'    color: #1a5276;',
'    border: 1px solid #bdd5ea;',
'}',
'.state-pill {',
'    display: inline-block;',
'    padding: 3px 12px;',
'    border-radius: 3px;',
'    font-size: 12px;',
'    font-weight: 600;',
'    letter-spacing: 0.04em;',
'    background: #fef9e7;',
'    color: #7d6608;',
'    border: 1px solid #f0dca0;',
'}',
'',
unistr('/* \2500\2500 RESPONSIVE \2500\2500 */'),
'@media (max-width: 600px) {',
'    #move_form_region {',
'        width: 100vw;',
'        right: -100vw;',
'    }',
'    #ranking_form_region {',
'        width: 100vw;',
'        right: -100vw;',
'    }',
'}',
'',
'.a-IRR-header--group {',
'    background-color: #312d2a !important;',
'    color: #fff !important;',
'    font-size: 14px;',
'    font-weight: 600;',
'    padding: 10px 12px !important;',
'}',
'',
'.status-success { color: #2b7d2b; }',
'.status-error   { color: #c53030; }',
'/* Base badge */',
'.score-badge {',
'    ',
'    font-weight: 800;',
'    font-size: 16px;',
'    background: #fff;',
'    color: #312d2a;',
'    padding: 4px;',
'    border-radius: 50%;',
'    /*border: 1px solid #000;*/',
'}',
'',
'.star-rating {',
'    display: inline-flex;',
'    align-items: center;',
'    gap: 2px;',
'    white-space: nowrap;',
'}',
'.sr-on {',
'    color: #312d2a;',
'    font-size: 16px;',
'}',
'.sr-off {',
'    color: #e0dbd7;',
'    font-size: 16px;',
'}',
'',
'.star-link {',
'    text-decoration: none !important;',
'    color: inherit !important;',
'    cursor: pointer;',
'}',
'',
'',
'',
'',
'',
'',
'/* Gallup Band colors */',
'.band-hp { background: #dcfce7; color: #166534; }',
'.band-lp { background: #fef3c7; color: #92400e; }',
'.band-mp { background: #dbeafe; color: #1e40af; }',
'',
'/* Ranking display colors */',
'.rank-recommend   { background: #dcfce7; color: #166534; }',
'.rank-consider    { background: #dbeafe; color: #1e40af; }',
'.rank-donotmove   { background: #fee2e2; color: #991b1b; }',
'',
unistr('/* Gallup score gradient: green \226550, amber 30-49, red <30 */'),
'.gscore-high { background: #dcfce7; color: #166534; }',
'.gscore-mid  { background: #fef3c7; color: #92400e; }',
'.gscore-low  { background: #fee2e2; color: #991b1b; }',
'',
'',
'.module-badge {',
'    display: inline-block;',
'    padding: 2px 4px;',
'    border-radius: 4px;',
'    font-size: 11px;',
'    font-weight: 600;',
'    color: #fff;',
'}',
'.module-badge--HCM { background: #3b82f6; }',
'.module-badge--FIN { background: #8b5cf6; }',
'.module-badge--GL  { background: #f59e0b; color: #1a1a1a; }',
'.module-badge--PRC { background: #22c55e; }',
'',
unistr('/* \2500\2500 RANKING DRAWER \2500\2500 */'),
'#ranking_form_region {',
'    position: fixed;',
'    top: 60px;',
'    right: -540px;',
'    width: 520px;',
'    max-width: 90vw;',
'    height: calc(100vh - 60px);',
'    z-index: 1010;',
'    background: #f7f8fa;',
'    box-shadow: -4px 0 30px rgba(0,0,0,0.15);',
'    overflow: hidden;',
'    transition: right 0.35s cubic-bezier(0.4, 0, 0.2, 1);',
'    display: flex;',
'    flex-direction: column;',
'}',
'#ranking_form_region.is-open {',
'    right: 0;',
'}',
'#ranking_form_region .t-Region-header {',
'    background: #312d2a;',
'    padding: 12px 20px;',
'    flex-shrink: 0;',
'}',
'#ranking_form_region .t-Region-title {',
'    color: #fff;',
'    font-size: 18px;',
'    font-weight: 700;',
'    letter-spacing: -0.01em;',
'}',
'#ranking_form_region .t-Region-body {',
'    padding: 20px;',
'    flex: 1;',
'    overflow-y: auto;',
'}',
'#ranking_form_region .t-Region-buttons--bottom {',
'    flex-shrink: 0;',
'}',
'#ranking_form_region .container { display: flex; flex-direction: column; gap: 0; }',
'#ranking_form_region .container > .row { margin: 0; }',
'#ranking_form_region .container .col {',
'    font-size: 11px; color: #6b7280; font-weight: 600;',
'    text-transform: uppercase; letter-spacing: 0.05em;',
'    line-height: 1.4; padding: 0 8px 20px 0;',
'}',
'#ranking_form_region .display_only {',
'    display: block; font-size: 15px; font-weight: 600;',
'    color: #111827; text-transform: none; letter-spacing: normal;',
'    margin-top: 4px; line-height: 1.4;',
'}',
'#P29_RANK_CANDIDATE_DISPLAY {',
'    font-size: 20px; font-weight: 700; color: #c2864a; margin-top: 6px;',
'}',
'#P29_RANK_LAST_BY_DISPLAY {',
'    font-size: 13px; color: #6b7280; font-style: italic; margin-top: 4px;',
'}',
'#ranking_form_region .container > .row:nth-child(2) {',
'    margin-top: 4px; padding-top: 20px; border-top: 1px solid #e5e7eb;',
'}',
'#ranking_form_region select.selectlist,',
'#ranking_form_region textarea.apex-item-textarea,',
'#ranking_form_region .apex-item-group--textarea {',
'    display: block; margin-top: 5px; width: 100%;',
'    text-transform: none; letter-spacing: normal;',
'}',
'#ranking_backdrop {',
'    position: fixed;',
'    top: 0; left: 0;',
'    width: 100%; height: 100%;',
'    background: rgba(0,0,0,0.4);',
'    z-index: 1005;',
'    opacity: 0;',
'    pointer-events: none;',
'    transition: opacity 0.35s ease;',
'    backdrop-filter: blur(2px);',
'    -webkit-backdrop-filter: blur(2px);',
'}',
'#ranking_backdrop.is-open {',
'    opacity: 1;',
'    pointer-events: auto;',
'}',
'#ranking_alert {',
'    display: none; background: #fef2f2; border: 1px solid #fca5a5;',
'    border-radius: 8px; padding: 12px 40px 12px 16px; margin-bottom: 20px;',
'    position: relative; animation: drawerAlertIn 0.2s ease;',
'}',
'',
'td:has(.module-badge) {',
'    white-space: nowrap;',
'}',
'',
'td[headers*="EFF_REFERENCE"], td[headers*="GCS_TEACH_REF"] {',
'    min-width: 220px;',
'    white-space: nowrap;',
'}',
'',
'td[headers*="APPLICATION_STATE"], td[headers*="APPLICATION_PHASE"] {',
'    min-width: 220px;',
'    white-space: nowrap;',
'}',
'',
'th[id*="DATE"], td[headers*="DATE"], th[headers*="REFERENCE_CHECK"], td[headers*="REFERENCE_CHECK"] {',
'    min-width: 180px;',
'    white-space: nowrap;',
'}',
'',
unistr('/* \2500\2500 Attachment Modal \2500\2500 */'),
'.att-backdrop {',
'    display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;',
'    background: rgba(0,0,0,0.4); z-index: 1020;',
'}',
'.att-backdrop.is-open { display: block; }',
'.att-modal {',
'    display: none; position: fixed; top: 50%; left: 50%;',
'    transform: translate(-50%, -50%);',
'    width: 820px; max-width: 92vw; max-height: 80vh;',
'    background: #fff; border-radius: 8px; z-index: 1030;',
'    box-shadow: 0 8px 32px rgba(0,0,0,0.25);',
'    overflow: hidden; flex-direction: column;',
'}',
'.att-modal.is-open { display: flex; }',
'.att-modal-header {',
'    display: flex; align-items: center; justify-content: space-between;',
'    padding: 12px 16px;',
'    background: #312d2a;',
'    color: #fff;',
'}',
'.att-modal-title { font-size: 16px; font-weight: 600; }',
'.att-modal-close {',
'    background: none; border: none; color: #fff; font-size: 22px; cursor: pointer;',
'}',
'.att-modal-body { padding: 16px; overflow-y: auto; }',
'.att-table { width: 100%; border-collapse: collapse; }',
'.att-table th {',
'    text-align: left; padding: 6px 8px; border-bottom: 2px solid #e5e7eb;',
'    font-size: 12px; color: #6b7280; text-transform: uppercase;',
'}',
'.att-table td { padding: 8px; border-bottom: 1px solid #f0f0f0; }',
'.att-file-icon { margin-right: 6px; color: #0077b6; }',
'.att-date { white-space: nowrap; color: #6b7280; }',
'.att-size { white-space: nowrap; color: #6b7280; font-size: 12px; }',
'.att-loading, .att-empty, .att-error { text-align: center; padding: 32px 16px; color: #6b7280; }',
'.att-error { color: #dc2626; }',
'.attachment-link { font-size: 16px; color: #6b7280; }',
'.attachment-link:hover { color: #0077b6; }',
'/* Compact body padding */',
'#move_form_region .t-Region-body {',
'    padding: 14px 20px;',
'}',
'',
'/* Tighter spacing between fields */',
'#move_form_region .container .col {',
'    padding: 0 8px 12px 0;',
'}',
'',
'/* Smaller separator gap */',
'#move_form_region .container > .row:nth-child(3) {',
'    margin-top: 2px;',
'    padding-top: 12px;',
'}',
'',
'/* Candidate name slightly smaller */',
'#P16_CANDIDATE_DISPLAY_DISPLAY {',
'    font-size: 18px;',
'    margin-top: 4px;',
'}',
'@font-face {',
'  font-family: "Oracle Sans";',
'  src: url("#APP_FILES#OracleBrandVF_Tb_W_WghtWdth.woff2") format("woff2");',
'  font-weight: 100 900;',
'  font-style: normal;',
'  font-display: swap;',
'}',
'',
'.t-Report-cell,',
'.a-IRR-table td {',
'  font-weight: 400;',
'  font-size: 13px;',
'  line-height: 1.25rem;',
'}',
'',
unistr('/* \2500\2500 REF LINK DRAWER \2500\2500 */'),
'#reflink_form_region {',
'    position: fixed;',
'    top: 60px;',
'    right: -500px;',
'    width: 480px;',
'    max-width: 90vw;',
'    height: calc(100vh - 60px);',
'    z-index: 1010;',
'    background: #f7f8fa;',
'    box-shadow: -4px 0 30px rgba(0,0,0,0.15);',
'    overflow: hidden;',
'    transition: right 0.35s cubic-bezier(0.4, 0, 0.2, 1);',
'    display: flex;',
'    flex-direction: column;',
'}',
'#reflink_form_region.is-open {',
'    right: 0;',
'}',
'#reflink_form_region .t-Region-header {',
'    background: #312d2a;',
'    padding: 12px 20px;',
'    flex-shrink: 0;',
'}',
'#reflink_form_region .t-Region-title {',
'    color: #fff;',
'    font-size: 18px;',
'    font-weight: 700;',
'    letter-spacing: -0.01em;',
'}',
'#reflink_form_region .t-Region-body {',
'    padding: 20px;',
'    flex: 1;',
'    overflow-y: auto;',
'}',
'#reflink_form_region .t-Region-buttons--bottom {',
'    flex-shrink: 0;',
'}',
'#reflink_form_region .container { display: flex; flex-direction: column; gap: 0; }',
'#reflink_form_region .container > .row { margin: 0; }',
'#reflink_form_region .container .col {',
'    font-size: 11px; color: #6b7280; font-weight: 600;',
'    text-transform: uppercase; letter-spacing: 0.05em;',
'    line-height: 1.4; padding: 0 8px 20px 0;',
'}',
'#reflink_form_region .display_only {',
'    display: block; font-size: 15px; font-weight: 600;',
'    color: #111827; text-transform: none; letter-spacing: normal;',
'    margin-top: 4px; line-height: 1.4;',
'}',
'#P24_REFLINK_CANDIDATE_DISPLAY {',
'    font-size: 20px; font-weight: 700; color: #2c5f2d; margin-top: 6px;',
'}',
'#P24_REFLINK_URL_DISPLAY {',
'    font-size: 12px; color: #4338ca; word-break: break-all;',
'    margin-top: 4px; font-family: monospace; line-height: 1.5;',
'    background: #f0f0ff; padding: 8px 12px; border-radius: 6px;',
'    border: 1px solid #e0e0f0;',
'}',
'#reflink_form_region .container > .row:nth-child(2) {',
'    margin-top: 4px; padding-top: 20px; border-top: 1px solid #e5e7eb;',
'}',
'#reflink_form_region input.text_field {',
'    display: block; margin-top: 5px; width: 100%;',
'    text-transform: none; letter-spacing: normal;',
'}',
'#reflink_backdrop {',
'    position: fixed;',
'    top: 0; left: 0;',
'    width: 100%; height: 100%;',
'    background: rgba(0,0,0,0.4);',
'    z-index: 1005;',
'    opacity: 0;',
'    pointer-events: none;',
'    transition: opacity 0.35s ease;',
'    backdrop-filter: blur(2px);',
'    -webkit-backdrop-filter: blur(2px);',
'}',
'#reflink_backdrop.is-open {',
'    opacity: 1;',
'    pointer-events: auto;',
'}',
'#reflink_alert {',
'    display: none; background: #fef2f2; border: 1px solid #fca5a5;',
'    border-radius: 8px; padding: 12px 40px 12px 16px; margin-bottom: 20px;',
'    position: relative; animation: drawerAlertIn 0.2s ease;',
'}',
'@media (max-width: 600px) {',
'    #reflink_form_region { width: 100vw; right: -100vw; }',
'}',
'',
'',
'/*',
'.ref-corrected {',
'    background: gray;',
'    color: #fff;',
'    padding: 2px 8px 2px 6px;',
'    border-radius: 4px;',
'    font-weight: 600;',
'    font-size: 12px;',
'    display: inline-block;',
'    letter-spacing: 0.02em;',
'}',
'.ref-corrected::before {',
unistr('    content: ''\2713 '';'),
'    font-weight: 900;',
'    font-size: 11px;',
'}',
'',
'*/',
'',
'.ref-corrected {',
'    border-left: 3px solid #3b82f6;',
'    background: #eff6ff;',
'    padding: 2px 8px;',
'    font-weight: 600;',
'    color: #1e40af;',
'    display: inline-block;',
'    border-radius: 0 4px 4px 0;',
'}',
'',
'',
'.survey-received {',
'    color: #2d8659;',
'    margin-left: 4px;',
'    font-size: 14px;',
'}',
'.ui-dialog {',
'    max-height: 85vh !important;',
'    top: 10vh !important;',
'}',
'',
'/* Reference 1 columns - light blue */',
'.a-IRR-header--group[data-group="ref1"],',
'td[headers*="REF_1"] { background-color: #f0f4ff; }',
'',
'/* Reference 2 columns - light green */',
'.a-IRR-header--group[data-group="ref2"],',
'td[headers*="REF_2"] { background-color: #f0fff4; }',
'',
'/* Reference 3 columns - light orange */',
'.a-IRR-header--group[data-group="ref3"],',
'td[headers*="REF_3"] { background-color: #fff8f0; }',
'',
'td[headers="SURVEY_RESPONDENT_COUNT"] a {',
'    font-size: 1.4em;',
'    font-weight: bold;',
'}',
'',
'/*styles for job postings*/',
'',
'td[headers="PUBLISHED_VISIBILITY"],',
'td[headers="PUBLISHED_POSTING_STATUS"],',
'td[headers="PUBLISHED_START_DATE"],',
'td[headers="PUBLISHED_END_DATE"],',
'td[headers="PUBLISHED_TIME_ZONE"],',
'td[headers="PUBLISHED_CREATED_BY"]',
' {',
'    background-color: #FFF8DC;',
'}',
''))
,p_step_template=>2526643373347724467
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- =============================================================================',
'-- REFERENCE CORRECTION LINK FEATURE (added 2026-05-15)',
'-- =============================================================================',
'-- Adds a "Send Correction Link" drawer to the Management Report, allowing',
'-- admins to generate a secure one-time URL and email it to applicants so they',
unistr('-- can correct their reference contact information (name, phone, email \00D7 3 refs).'),
'--',
'-- Components added to this page:',
'--   - JavaScript: openRefLinkForm(), copyRefLink(), sendRefLinkEmail(),',
'--     cancelRefLinkForm(), plus alert/backdrop injection on page load',
'--   - CSS: #reflink_form_region drawer, #reflink_backdrop overlay',
'--   - IR column: REF_LINK_ACTION (envelope icon per row, green check if corrected)',
'--   - IR columns (hidden): REFS_CORRECTED_YN, REFS_CORRECTED_ON',
'--   - Region: reflink_form_region (slide-out drawer, Standard template)',
'--   - Items: P24_REFLINK_APP_ID (hidden), P24_REFLINK_CANDIDATE (display),',
'--     P24_REFLINK_URL (display), P24_REFLINK_EMAIL (text field)',
'--   - Buttons: COPY_REF_LINK_BTN, SEND_REF_EMAIL_BTN, CANCEL_REFLINK_BTN',
'--   - Dynamic Actions: click handlers for each button',
'--   - Ajax Callbacks: GENERATE_REF_LINK (pkg_ref_correction.generate_token),',
'--     SEND_REF_LINK_EMAIL (pkg_ref_correction.send_correction_email)',
'--',
'-- Dependencies:',
'--   - Tables: ref_correction_token, ref_correction',
'--   - Package: pkg_ref_correction (generate_token, validate_token,',
'--     save_corrections, send_correction_email, get_candidate_email)',
'--   - View: RECRUITING_REPORT_V (COALESCE overlay for corrected refs,',
'--     REFS_CORRECTED_YN/REFS_CORRECTED_ON columns)',
'--   - Config: email_config row APEX_BASE_URL',
'--   - Public page 100 (alias REF-CORRECT): applicant-facing correction form',
'-- =============================================================================',
''))
,p_page_component_map=>'22'
);
wwv_flow_imp_page.create_report_region(
 p_id=>wwv_flow_imp.id(106452256818618688)
,p_name=>'Search Results'
,p_region_name=>'applicant_irr'
,p_template=>4072358936313175081
,p_display_sequence=>20
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--hideHeader js-addHiddenHeadingRoleDesc:t-Region--scrollBody'
,p_component_template_options=>'#DEFAULT#:t-Report--stretch:t-Report--staticRowColors:t-Report--rowHighlight:t-Report--inline:t-Report--hideNoPagination'
,p_source_type=>'NATIVE_SQL_REPORT'
,p_query_type=>'SQL'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT',
'null notes_toggle,',
'note_count,',
'APPLICANT_NOTE_COUNT,',
'null applicant_notes_toggle,',
'PHONE_COUNT,',
'CAND_NUM ,',
'working_retiree,',
'sc_retirement_date,',
'    JOB_REQUISITION_ID,',
'    JOB_APPLICATION_ID,',
'    REQ,',
'    JOB,',
'    SCHOOL,',
'    DEPARTMENT_NAME ,',
'    LOCATION_CODE,',
'    NAME,',
'    CANDIDATE_NUMBER,',
'    INTEXT,',
'    EE_NUM,',
'    HIRING_MANAGER,',
'    recruiter,',
'    APPLICATION_PHASE,',
'    APPLICATION_STATE,',
'    APPLICATION_DATE,',
'    REHIRE_ELIGIBLE,',
'    REFERENCE_CHECK,',
'    BACKGROUND_CHECK,',
'    CERTIFICATION,',
'    ASSESSMENT_SCORE,',
'    TEACHER_SUBJECT_AREA,',
'    TO_CHAR(',
'    TO_TIMESTAMP_TZ(EFF_EFFECTIVE_DATE, ''YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM''),',
'    ''DD-MON-YYYY''',
') AS EFF_EFFECTIVE_DATE,',
'    TRANSFER_COORDINATED,',
'    VACANCY_TERM_SUBMITTED,',
'    PUBLISHED_VISIBILITY,',
'    PUBLISHED_POSTING_STATUS,',
'    PUBLISHED_START_DATE,',
'    PUBLISHED_END_DATE,',
'    PUBLISHED_TIME_ZONE,',
'    PUBLISHED_CREATED_BY,',
'    CASE WHEN REF_1_NAME_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_1_NAME || ''</span>''',
'     ELSE GCS_TEACH_REF_1_NAME',
'END',
'|| CASE WHEN REF_1_SURVEY_YN = ''Y'' AND GCS_TEACH_REF_1_NAME IS NOT NULL',
'     THEN '' <span class="fa fa-check-circle survey-received" title="Survey response received"></span>''',
'     ELSE '''' END AS GCS_TEACH_REF_1_NAME,',
'',
'',
'CASE WHEN REF_2_NAME_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_2_NAME || ''</span>''',
'     ELSE GCS_TEACH_REF_2_NAME',
'END',
'|| CASE WHEN REF_2_SURVEY_YN = ''Y'' AND GCS_TEACH_REF_2_NAME IS NOT NULL',
'     THEN '' <span class="fa fa-check-circle survey-received" title="Survey response received"></span>''',
'     ELSE '''' END AS GCS_TEACH_REF_2_NAME,',
'',
'',
'CASE WHEN REF_3_NAME_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_3_NAME || ''</span>''',
'     ELSE GCS_TEACH_REF_3_NAME',
'END',
'|| CASE WHEN REF_3_SURVEY_YN = ''Y'' AND GCS_TEACH_REF_3_NAME IS NOT NULL',
'     THEN '' <span class="fa fa-check-circle survey-received" title="Survey response received"></span>''',
'     ELSE '''' END AS GCS_TEACH_REF_3_NAME,',
'',
'',
'',
'CASE WHEN REF_1_PHONE_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_1_PHONE || ''</span>''',
'     ELSE GCS_TEACH_REF_1_PHONE',
'END AS GCS_TEACH_REF_1_PHONE,',
'CASE WHEN REF_1_EMAIL_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_1_EMAIL || ''</span>''',
'     ELSE GCS_TEACH_REF_1_EMAIL',
'END AS GCS_TEACH_REF_1_EMAIL,',
'',
'CASE WHEN REF_2_PHONE_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_2_PHONE || ''</span>''',
'     ELSE GCS_TEACH_REF_2_PHONE',
'END AS GCS_TEACH_REF_2_PHONE,',
'CASE WHEN REF_2_EMAIL_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_2_EMAIL || ''</span>''',
'     ELSE GCS_TEACH_REF_2_EMAIL',
'END AS GCS_TEACH_REF_2_EMAIL,',
'',
'CASE WHEN REF_3_PHONE_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_3_PHONE || ''</span>''',
'     ELSE GCS_TEACH_REF_3_PHONE',
'END AS GCS_TEACH_REF_3_PHONE,',
'CASE WHEN REF_3_EMAIL_CHG = ''Y''',
'     THEN ''<span class="ref-corrected">'' || GCS_TEACH_REF_3_EMAIL || ''</span>''',
'     ELSE GCS_TEACH_REF_3_EMAIL',
'END AS GCS_TEACH_REF_3_EMAIL,',
'GCS_TEACH_REF_1_REL ,',
'GCS_TEACH_REF_2_REL,',
'GCS_TEACH_REF_3_REL,',
'',
'',
'    GALLUP_SCORE,',
'    GALLUP_BAND,',
'    GALLUP_STATUS,',
'    GALLUP_RESULT_URL,',
'    RANKING_SCORE,',
'    RANKING_TEXT,',
'    RANKING_NOTE,',
'    RANKED_BY,',
'    CASE WHEN RANKING_TEXT IS NOT NULL THEN RANKING_TEXT',
'         WHEN RANKING_SCORE IS NOT NULL THEN ''Score: '' || RANKING_SCORE',
'         ELSE ''--''',
'    END AS RANKING_DISPLAY,',
'    ''<a href="javascript:void(0);" onclick="openAttachments(''',
'|| JOB_APPLICATION_ID || '');return false;" ''',
'|| ''class="attachment-link" title="View Attachments">''',
'|| ''<span class="fa fa-paperclip"></span></a>'' AS ATTACHMENTS,',
'',
'    /* -- CSS class columns (hidden in report, used by HTML Expressions) -- */',
'    CASE WHEN GALLUP_SCORE >= 50 THEN ''gscore-high''',
'         WHEN GALLUP_SCORE >= 30 THEN ''gscore-mid''',
'         ELSE ''gscore-low''',
'    END AS GALLUP_SCORE_CLASS,',
'    LOWER(GALLUP_BAND) AS GALLUP_BAND_LC,',
'    CASE WHEN RANKING_TEXT = ''Recommend''   THEN ''recommend''',
'         WHEN RANKING_TEXT = ''Consider''    THEN ''consider''',
'         WHEN RANKING_TEXT = ''Do Not Move'' THEN ''donotmove''',
'         ELSE ''''',
'    END AS RANKING_CSS,',
'',
'    REFS_CORRECTED_YN,',
'    REFS_CORRECTED_ON,',
'    REQUESTED_BY,',
'    ''<button type="button" class="t-Button t-Button--tiny t-Button--link"''',
'||'' onclick="openRefLinkForm(''||JOB_APPLICATION_ID||'');return false;"''',
'||'' title="Send Reference Correction Link">''',
'|| CASE WHEN REFS_CORRECTED_YN = ''Y'' THEN ''<span class="fa fa-envelope-o fa-2x fam-check fam-is-success"></span>''',
'          ELSE ''<span class="fa fa-envelope-o"></span>'' END',
'||''</button>'' AS REF_LINK_ACTION,',
'',
'HRD2_CANDIDATE_ID,',
'SURVEY_RESPONDENT_COUNT,',
'REF_1_SURVEY_YN,',
'REF_2_SURVEY_YN,',
'REF_3_SURVEY_YN',
'',
'',
'',
'FROM RECRUITING_REPORT_V',
''))
,p_ajax_enabled=>'Y'
,p_lazy_loading=>false
,p_query_row_template=>2538654340625403440
,p_query_num_rows=>50
,p_query_options=>'DERIVED_REPORT_COLUMNS'
,p_query_no_data_found=>'no data found'
,p_query_num_rows_type=>'NEXT_PREVIOUS_LINKS'
,p_query_row_count_max=>100000
,p_pagination_display_position=>'BOTTOM_RIGHT'
,p_prn_output=>'N'
,p_prn_format=>'PDF'
,p_sort_null=>'L'
,p_plug_query_strip_html=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116368030498692742)
,p_query_column_id=>1
,p_column_alias=>'NOTES_TOGGLE'
,p_column_display_sequence=>45
,p_column_heading=>'Application Reviewer Notes'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
' <button type="button" class="cnote-toggle"',
'           data-app-id="#JOB_APPLICATION_ID#"',
'           aria-label="Notes">',
'     <span class="fa fa-comment-o"></span>',
'     <span class="cnote-badge" data-count="#NOTE_COUNT#">#NOTE_COUNT#</span>',
'   </button>'))
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116368156198692743)
,p_query_column_id=>2
,p_column_alias=>'NOTE_COUNT'
,p_column_display_sequence=>665
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(126366639986556201)
,p_query_column_id=>3
,p_column_alias=>'APPLICANT_NOTE_COUNT'
,p_column_display_sequence=>75
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(126366719865556202)
,p_query_column_id=>4
,p_column_alias=>'APPLICANT_NOTES_TOGGLE'
,p_column_display_sequence=>55
,p_column_heading=>'Applicant-Specific Notes '
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<button type="button" class="anote-toggle"',
'        data-person-id="#CAND_NUM#"',
'        aria-label="Applicant Notes">',
'  <span class="fa fa-comment-o"></span>',
'  <span class="anote-badge" data-count="#APPLICANT_NOTE_COUNT#">#APPLICANT_NOTE_COUNT#</span>',
'</button>',
''))
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(121639550724818748)
,p_query_column_id=>5
,p_column_alias=>'PHONE_COUNT'
,p_column_display_sequence=>65
,p_column_heading=>'Phone Numbers'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<button type="button" class="cphone-toggle"',
'        data-person-id="#CAND_NUM#"',
'        aria-label="Phones">',
'  <span class="fa fa-phone"></span>',
'  <span class="cphone-badge" data-count="#PHONE_COUNT#">#PHONE_COUNT#</span>',
'</button>',
''))
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_report_column_required_role=>wwv_flow_imp.id(133153510612213767)
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(121639746274818750)
,p_query_column_id=>6
,p_column_alias=>'CAND_NUM'
,p_column_display_sequence=>675
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(126368192658556216)
,p_query_column_id=>7
,p_column_alias=>'WORKING_RETIREE'
,p_column_display_sequence=>235
,p_column_heading=>'Working Retiree'
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(126368257209556217)
,p_query_column_id=>8
,p_column_alias=>'SC_RETIREMENT_DATE'
,p_column_display_sequence=>245
,p_column_heading=>'SC Retirement Date'
,p_column_format=>'RR-MON-DD'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106455771536618704)
,p_query_column_id=>9
,p_column_alias=>'JOB_REQUISITION_ID'
,p_column_display_sequence=>1
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106456203546618704)
,p_query_column_id=>10
,p_column_alias=>'JOB_APPLICATION_ID'
,p_column_display_sequence=>2
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106456610196618704)
,p_query_column_id=>11
,p_column_alias=>'REQ'
,p_column_display_sequence=>3
,p_column_heading=>'Requisition'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<a href="https://ibzsjb-dev4.fa.ocs.oraclecloud.com/fscmUI/faces/deeplink?objType=IRC_RECRUITING&action=REQUISITION_DETAIL_RECRUITING_RESP&objKey=RequisitionId=#JOB_REQUISITION_ID#" target="_blank">#REQ#</a>',
''))
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106456979003618704)
,p_query_column_id=>12
,p_column_alias=>'JOB'
,p_column_display_sequence=>4
,p_column_heading=>'Job'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106457347588618704)
,p_query_column_id=>13
,p_column_alias=>'SCHOOL'
,p_column_display_sequence=>5
,p_column_heading=>'School/Location'
,p_heading_alignment=>'LEFT'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(138668035788047813)
,p_query_column_id=>14
,p_column_alias=>'DEPARTMENT_NAME'
,p_column_display_sequence=>25
,p_column_heading=>'Department Name'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(126369327977556228)
,p_query_column_id=>15
,p_column_alias=>'LOCATION_CODE'
,p_column_display_sequence=>15
,p_column_heading=>'Location Code'
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106457748203618720)
,p_query_column_id=>16
,p_column_alias=>'NAME'
,p_column_display_sequence=>35
,p_column_heading=>'Name'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<a href="https://ibzsjb-dev4.fa.ocs.oraclecloud.com/fscmUI/redwood/recruiting-hiring/job-application/detail?p_called_from=search&submission_id=#JOB_APPLICATION_ID#&tab_id=ORA_JA_DETAILS" target="_blank">#NAME#</a>',
''))
,p_heading_alignment=>'LEFT'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108871201103948426)
,p_query_column_id=>17
,p_column_alias=>'CANDIDATE_NUMBER'
,p_column_display_sequence=>615
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106458184300618720)
,p_query_column_id=>18
,p_column_alias=>'INTEXT'
,p_column_display_sequence=>85
,p_column_heading=>'Intext'
,p_heading_alignment=>'LEFT'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106458580628618720)
,p_query_column_id=>19
,p_column_alias=>'EE_NUM'
,p_column_display_sequence=>95
,p_column_heading=>'EE Number'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106459010560618720)
,p_query_column_id=>20
,p_column_alias=>'HIRING_MANAGER'
,p_column_display_sequence=>105
,p_column_heading=>'Hiring Manager'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(138669488195047827)
,p_query_column_id=>21
,p_column_alias=>'RECRUITER'
,p_column_display_sequence=>106
,p_column_heading=>'Recruiter'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106459405225618720)
,p_query_column_id=>22
,p_column_alias=>'APPLICATION_PHASE'
,p_column_display_sequence=>115
,p_column_heading=>'Application Phase'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106459824275618720)
,p_query_column_id=>23
,p_column_alias=>'APPLICATION_STATE'
,p_column_display_sequence=>125
,p_column_heading=>'Application State'
,p_column_link=>'javascript:openMoveForm(#JOB_APPLICATION_ID#);void(0);'
,p_column_linktext=>'#APPLICATION_STATE#'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106460225784618720)
,p_query_column_id=>24
,p_column_alias=>'APPLICATION_DATE'
,p_column_display_sequence=>135
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106460629360618720)
,p_query_column_id=>25
,p_column_alias=>'REHIRE_ELIGIBLE'
,p_column_display_sequence=>145
,p_column_heading=>'Rehire Eligible'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106461016985618720)
,p_query_column_id=>26
,p_column_alias=>'REFERENCE_CHECK'
,p_column_display_sequence=>155
,p_column_heading=>'Reference Check'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106463808869618720)
,p_query_column_id=>27
,p_column_alias=>'BACKGROUND_CHECK'
,p_column_display_sequence=>165
,p_column_heading=>'Background Check'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106464147552618720)
,p_query_column_id=>28
,p_column_alias=>'CERTIFICATION'
,p_column_display_sequence=>175
,p_column_heading=>'Certification'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106464612248618720)
,p_query_column_id=>29
,p_column_alias=>'ASSESSMENT_SCORE'
,p_column_display_sequence=>185
,p_column_heading=>'Assessment Score'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'{if ASSESSMENT_SCORE/}<span class="score-badge">#ASSESSMENT_SCORE#</span>{endif/}',
''))
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106464974515618720)
,p_query_column_id=>30
,p_column_alias=>'TEACHER_SUBJECT_AREA'
,p_column_display_sequence=>195
,p_column_heading=>'Teacher Subject Area'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106465391027618720)
,p_query_column_id=>31
,p_column_alias=>'EFF_EFFECTIVE_DATE'
,p_column_display_sequence=>205
,p_column_heading=>'EFF Effective Date'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106465776814618720)
,p_query_column_id=>32
,p_column_alias=>'TRANSFER_COORDINATED'
,p_column_display_sequence=>215
,p_column_heading=>'Transfer Coordinated'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106466187389618720)
,p_query_column_id=>33
,p_column_alias=>'VACANCY_TERM_SUBMITTED'
,p_column_display_sequence=>225
,p_column_heading=>'Vacancy Term Submitted'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116367128063692733)
,p_query_column_id=>34
,p_column_alias=>'PUBLISHED_VISIBILITY'
,p_column_display_sequence=>375
,p_column_heading=>'Published Visibility'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116367292012692734)
,p_query_column_id=>35
,p_column_alias=>'PUBLISHED_POSTING_STATUS'
,p_column_display_sequence=>385
,p_column_heading=>'Published Posting Status'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116367394313692735)
,p_query_column_id=>36
,p_column_alias=>'PUBLISHED_START_DATE'
,p_column_display_sequence=>395
,p_column_heading=>'Published Start Date'
,p_column_format=>'DD-MON-YYYY HH:MIPM'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116367418239692736)
,p_query_column_id=>37
,p_column_alias=>'PUBLISHED_END_DATE'
,p_column_display_sequence=>405
,p_column_heading=>'Published End Date'
,p_column_format=>'DD-MON-YYYY HH:MIPM'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116367543473692737)
,p_query_column_id=>38
,p_column_alias=>'PUBLISHED_TIME_ZONE'
,p_column_display_sequence=>415
,p_column_heading=>'Published Time Zone'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(116367688638692738)
,p_query_column_id=>39
,p_column_alias=>'PUBLISHED_CREATED_BY'
,p_column_display_sequence=>425
,p_column_heading=>'Published Created By'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106466560970618720)
,p_query_column_id=>40
,p_column_alias=>'GCS_TEACH_REF_1_NAME'
,p_column_display_sequence=>255
,p_column_heading=>'Reference 1'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106467801597618720)
,p_query_column_id=>41
,p_column_alias=>'GCS_TEACH_REF_2_NAME'
,p_column_display_sequence=>295
,p_column_heading=>'Reference 2'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106469043466618720)
,p_query_column_id=>42
,p_column_alias=>'GCS_TEACH_REF_3_NAME'
,p_column_display_sequence=>335
,p_column_heading=>'Reference 3'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106466962692618720)
,p_query_column_id=>43
,p_column_alias=>'GCS_TEACH_REF_1_PHONE'
,p_column_display_sequence=>265
,p_column_heading=>'Reference 1 Phone'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106467350345618720)
,p_query_column_id=>44
,p_column_alias=>'GCS_TEACH_REF_1_EMAIL'
,p_column_display_sequence=>275
,p_column_heading=>'Reference 1 Email'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106468210382618720)
,p_query_column_id=>45
,p_column_alias=>'GCS_TEACH_REF_2_PHONE'
,p_column_display_sequence=>305
,p_column_heading=>'Reference 2 Phone'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106468593663618720)
,p_query_column_id=>46
,p_column_alias=>'GCS_TEACH_REF_2_EMAIL'
,p_column_display_sequence=>315
,p_column_heading=>'Reference 2 Email'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106469399763618720)
,p_query_column_id=>47
,p_column_alias=>'GCS_TEACH_REF_3_PHONE'
,p_column_display_sequence=>345
,p_column_heading=>'Reference 3 Phone'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106469744403618720)
,p_query_column_id=>48
,p_column_alias=>'GCS_TEACH_REF_3_EMAIL'
,p_column_display_sequence=>355
,p_column_heading=>'Reference 3 Email'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108872479373948438)
,p_query_column_id=>49
,p_column_alias=>'GCS_TEACH_REF_1_REL'
,p_column_display_sequence=>285
,p_column_heading=>'Reference 1 Relationship'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108872591925948439)
,p_query_column_id=>50
,p_column_alias=>'GCS_TEACH_REF_2_REL'
,p_column_display_sequence=>325
,p_column_heading=>'Reference 2 Relationship'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108872667273948440)
,p_query_column_id=>51
,p_column_alias=>'GCS_TEACH_REF_3_REL'
,p_column_display_sequence=>365
,p_column_heading=>'Reference 3 Relationship'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106470204583618720)
,p_query_column_id=>52
,p_column_alias=>'GALLUP_SCORE'
,p_column_display_sequence=>445
,p_column_heading=>'Gallup Score'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'{if GALLUP_SCORE/}<span class="score-badge">#GALLUP_SCORE#</span>{endif/}',
''))
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106470578244618720)
,p_query_column_id=>53
,p_column_alias=>'GALLUP_BAND'
,p_column_display_sequence=>455
,p_column_heading=>'Gallup Band'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106471018591618720)
,p_query_column_id=>54
,p_column_alias=>'GALLUP_STATUS'
,p_column_display_sequence=>465
,p_default_sort_column_sequence=>1
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(104436405654414512)
,p_query_column_id=>55
,p_column_alias=>'GALLUP_RESULT_URL'
,p_column_display_sequence=>475
,p_column_heading=>'Gallup Result URL'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'{if GALLUP_RESULT_URL/}<a href="#GALLUP_RESULT_URL#" target="_blank">Gallup Result</a>{endif/}',
''))
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106471388500618720)
,p_query_column_id=>56
,p_column_alias=>'RANKING_SCORE'
,p_column_display_sequence=>495
,p_column_heading=>'Ranking Score'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'{if RANKING_SCORE/}<a href="javascript:openRankingForm(#JOB_APPLICATION_ID#);void(0);" class="star-link"><span class="star-rating" title="#RANKING_SCORE# out of 5">{case RANKING_SCORE/}{when 1/}<span class="fa fa-star sr-on"></span><span class="fa fa'
||'-star-o sr-off"></span><span class="fa fa-star-o sr-off"></span><span class="fa fa-star-o sr-off"></span><span class="fa fa-star-o sr-off"></span>{when 2/}<span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-'
||'star-o sr-off"></span><span class="fa fa-star-o sr-off"></span><span class="fa fa-star-o sr-off"></span>{when 3/}<span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star'
||'-o sr-off"></span><span class="fa fa-star-o sr-off"></span>{when 4/}<span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star-o sr-o'
||'ff"></span>{when 5/}<span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span><span class="fa fa-star sr-on"></span>{endcase/}</span></a>{else/}<a href="jav'
||'ascript:openRankingForm(#JOB_APPLICATION_ID#);void(0);" class="star-link"><span class="fa fa-plus-circle sr-off" title="Add ranking"></span></a>{endif/}',
''))
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106471802701618720)
,p_query_column_id=>57
,p_column_alias=>'RANKING_TEXT'
,p_column_display_sequence=>505
,p_default_sort_column_sequence=>1
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106472240241618720)
,p_query_column_id=>58
,p_column_alias=>'RANKING_NOTE'
,p_column_display_sequence=>515
,p_column_heading=>'Ranking Note'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106472578464618720)
,p_query_column_id=>59
,p_column_alias=>'RANKED_BY'
,p_column_display_sequence=>525
,p_column_heading=>'Ranked By'
,p_heading_alignment=>'LEFT'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106472944688618720)
,p_query_column_id=>60
,p_column_alias=>'RANKING_DISPLAY'
,p_column_display_sequence=>485
,p_column_heading=>'Ranking '
,p_column_link=>'Javascript:openRankingForm(#JOB_APPLICATION_ID#);void(0);'
,p_column_linktext=>'#RANKING_DISPLAY#'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(106473357381618720)
,p_query_column_id=>61
,p_column_alias=>'ATTACHMENTS'
,p_column_display_sequence=>545
,p_column_heading=>'Attachments'
,p_column_alignment=>'CENTER'
,p_default_sort_column_sequence=>1
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(104437098685414528)
,p_query_column_id=>62
,p_column_alias=>'GALLUP_SCORE_CLASS'
,p_column_display_sequence=>555
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(104437164351414528)
,p_query_column_id=>63
,p_column_alias=>'GALLUP_BAND_LC'
,p_column_display_sequence=>565
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(104437314536414528)
,p_query_column_id=>64
,p_column_alias=>'RANKING_CSS'
,p_column_display_sequence=>575
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(777000000000000101)
,p_query_column_id=>65
,p_column_alias=>'REFS_CORRECTED_YN'
,p_column_display_sequence=>585
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(777000000000000102)
,p_query_column_id=>66
,p_column_alias=>'REFS_CORRECTED_ON'
,p_column_display_sequence=>595
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(107429437640332416)
,p_query_column_id=>67
,p_column_alias=>'REQUESTED_BY'
,p_column_display_sequence=>605
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(777000000000000103)
,p_query_column_id=>68
,p_column_alias=>'REF_LINK_ACTION'
,p_column_display_sequence=>535
,p_column_heading=>'Reference Link'
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_display_as=>'WITHOUT_MODIFICATION'
,p_derived_column=>'N'
,p_include_in_export=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108871496399948428)
,p_query_column_id=>69
,p_column_alias=>'HRD2_CANDIDATE_ID'
,p_column_display_sequence=>625
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108871527876948429)
,p_query_column_id=>70
,p_column_alias=>'SURVEY_RESPONDENT_COUNT'
,p_column_display_sequence=>435
,p_column_heading=>'Survey Respondent Count'
,p_column_link=>'f?p=&APP_ID.:4004:&SESSION.::&DEBUG.::P4004_JOB_APPLICATION_ID:#JOB_APPLICATION_ID#'
,p_column_linktext=>'#SURVEY_RESPONDENT_COUNT#'
,p_column_alignment=>'CENTER'
,p_disable_sort_column=>'N'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108871691853948430)
,p_query_column_id=>71
,p_column_alias=>'REF_1_SURVEY_YN'
,p_column_display_sequence=>635
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108871743880948431)
,p_query_column_id=>72
,p_column_alias=>'REF_2_SURVEY_YN'
,p_column_display_sequence=>645
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(108871897800948432)
,p_query_column_id=>73
,p_column_alias=>'REF_3_SURVEY_YN'
,p_column_display_sequence=>655
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(106452354148618688)
,p_plug_name=>'Search'
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--hideHeader js-addHiddenHeadingRoleDesc:t-Region--scrollBody'
,p_plug_template=>4072358936313175081
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_02'
,p_location=>null
,p_plug_source_type=>'NATIVE_FACETED_SEARCH'
,p_filtered_region_id=>wwv_flow_imp.id(106452256818618688)
,p_landmark_label=>'Filters'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'batch_facet_search', 'N',
  'compact_numbers_threshold', '10000',
  'current_facets_selector', '#active_facets',
  'display_chart_for_top_n_values', '10',
  'show_charts', 'Y',
  'show_current_facets', 'E',
  'show_total_row_count', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(106454774594618704)
,p_plug_name=>'Button Bar'
,p_region_template_options=>'#DEFAULT#:t-ButtonRegion--noPadding:t-ButtonRegion--noUI'
,p_escape_on_http_output=>'Y'
,p_plug_template=>2126429139436695430
,p_plug_display_sequence=>10
,p_query_type=>'SQL'
,p_plug_source=>'<div id="active_facets"></div>'
,p_plug_query_num_rows=>15
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(416125290950876608)
,p_plug_name=>'Rank Applicant'
,p_region_name=>'ranking_form_region'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4072358936313175081
,p_plug_display_sequence=>40
,p_location=>null
,p_ai_enabled=>false
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(777000000000000201)
,p_plug_name=>'Send Correction Link'
,p_region_name=>'reflink_form_region'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4072358936313175081
,p_plug_display_sequence=>50
,p_location=>null
,p_ai_enabled=>false
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(1478477513570825728)
,p_plug_name=>'Move Applicant'
,p_region_name=>'move_form_region'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4072358936313175081
,p_plug_display_sequence=>30
,p_location=>null
,p_ai_enabled=>false
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(106480180812649120)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_button_name=>'MOVE_BTN'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2082829544945815391
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Move Applicant'
,p_button_position=>'CHANGE'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-exchange'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(106483502179650688)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_button_name=>'SAVE_RANKING_BTN'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2082829544945815391
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Save Ranking'
,p_button_position=>'CHANGE'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-check'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(777000000000000401)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(777000000000000201)
,p_button_name=>'COPY_REF_LINK_BTN'
,p_button_static_id=>'COPY_REF_LINK_BTN'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2082829544945815391
,p_button_image_alt=>'Copy Link'
,p_button_position=>'CHANGE'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-copy'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(777000000000000402)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(777000000000000201)
,p_button_name=>'SEND_REF_EMAIL_BTN'
,p_button_static_id=>'SEND_REF_EMAIL_BTN'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2082829544945815391
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Send Email'
,p_button_position=>'CHANGE'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-send-o'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(106480559161649120)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_button_name=>'CANCEL_BTN'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Cancel'
,p_button_position=>'CLOSE'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(106483886329650688)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_button_name=>'CANCEL_RANKING_BTN'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Cancel'
,p_button_position=>'CLOSE'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(777000000000000403)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(777000000000000201)
,p_button_name=>'CANCEL_REFLINK_BTN'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Cancel'
,p_button_position=>'CLOSE'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(106455264950618704)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(106454774594618704)
,p_button_name=>'RESET'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--noUI:t-Button--iconLeft'
,p_button_template_id=>2082829544945815391
,p_button_image_alt=>'Reset'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:24:&APP_SESSION.::&DEBUG.:RR,24::'
,p_icon_css_classes=>'fa-undo'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(113355335443303515)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(106454774594618704)
,p_button_name=>'OPEN_TICKETS'
,p_button_static_id=>'tickets'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--tiny:t-Button--link'
,p_button_template_id=>4072362960822175091
,p_button_is_hot=>'Y'
,p_button_image_alt=>'&P24_TICKET_COUNT. Open Tickets'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:5001:&SESSION.::&DEBUG.::P5001_RETURN_PAGE:24'
,p_button_cattributes=>'style="color: blue"'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(104436695753414528)
,p_name=>'P24_REQUISITION'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Requisition'
,p_source=>'JOB_REQUISITION_ID'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT ',
'    REQ || '' - '' || JOB ',
'    || '' | '' || NVL(SCHOOL, ''No Location'')',
'    || '' | Mgr: '' || NVL(HIRING_MANAGER, ''--'')',
'    || '' | '' || REQ_STATE || '' - '' || POSTING_SUMMARY',
'    AS display_value,',
'    JOB_REQUISITION_ID AS return_value',
'FROM RECRUITING_REPORT_V',
'GROUP BY JOB_REQUISITION_ID, REQ, JOB, POSITION_NAME, ',
'         SCHOOL, HIRING_MANAGER, RECRUITER, REQ_STATE, POSTING_SUMMARY',
'ORDER BY to_number(REQ)',
'',
''))
,p_item_template_options=>'#DEFAULT#'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>false
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(104437364701414528)
,p_name=>'P24_NAME'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Name'
,p_source=>'NAME'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov_sort_direction=>'ASC'
,p_item_template_options=>'#DEFAULT#'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>false
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(106452872601618688)
,p_name=>'P24_SEARCH'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Search'
,p_source=>'GCS_TEACH_REF_1_NAME,GCS_TEACH_REF_2_NAME,GCS_TEACH_REF_3_NAME,REQ,JOB,SCHOOL,NAME,INTEXT,EE_NUM,HIRING_MANAGER,APPLICATION_PHASE,APPLICATION_STATE,REHIRE_ELIGIBLE,REFERENCE_CHECK,EFF_REFERENCE_1_NAME,EFF_REFERENCE_1_EMAIL,EFF_REFERENCE_2_NAME,EFF_RE'
||'FERENCE_2_EMAIL,EFF_REFERENCE_3_NAME,EFF_REFERENCE_3_EMAIL,BACKGROUND_CHECK,CERTIFICATION,ASSESSMENT_SCORE,TEACHER_SUBJECT_AREA,EFF_EFFECTIVE_DATE,TRANSFER_COORDINATED,VACANCY_TERM_SUBMITTED,GCS_TEACH_REF_1_NAME,GCS_TEACH_REF_1_PHONE,GCS_TEACH_REF_1_'
||'EMAIL,GCS_TEACH_REF_2_NAME,GCS_TEACH_REF_2_PHONE,GCS_TEACH_REF_2_EMAIL,GCS_TEACH_REF_3_NAME,GCS_TEACH_REF_3_PHONE,GCS_TEACH_REF_3_EMAIL,GALLUP_BAND,GALLUP_STATUS,RANKING_TEXT,RANKING_NOTE,RANKED_BY,RANKING_DISPLAY,ATTACHMENTS'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_SEARCH'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'input_field', 'FACET',
  'search_type', 'ROW')).to_clob
,p_fc_show_chart=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(106453280835618704)
,p_name=>'P24_JOB'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Job'
,p_source=>'JOB'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov_sort_direction=>'ASC'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>true
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(106453652614618704)
,p_name=>'P24_SCHOOL'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'School'
,p_source=>'SCHOOL'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov_sort_direction=>'ASC'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>true
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(106454126748618704)
,p_name=>'P24_HIRING_MANAGER'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Hiring Manager'
,p_source=>'HIRING_MANAGER'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov_sort_direction=>'ASC'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>true
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(106454493321618704)
,p_name=>'P24_APPLICATION_PHASE'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Application Phase'
,p_source=>'APPLICATION_PHASE'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov_sort_direction=>'ASC'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>true
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(113355682010303518)
,p_name=>'P24_TICKET_COUNT'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(106454774594618704)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(116367758500692739)
,p_name=>'P24_PUBLISHED_POSTING_STATUS'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Published Posting Status'
,p_source=>'PUBLISHED_POSTING_STATUS'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov_sort_direction=>'ASC'
,p_item_template_options=>'#DEFAULT#'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>true
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(138668115315047814)
,p_name=>'P24_DEPARTMENT_NAME'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(106452354148618688)
,p_prompt=>'Department Name'
,p_source=>'DEPARTMENT_NAME'
,p_source_type=>'FACET_COLUMN'
,p_display_as=>'NATIVE_CHECKBOX'
,p_lov_sort_direction=>'ASC'
,p_item_template_options=>'#DEFAULT#'
,p_fc_show_label=>true
,p_fc_collapsible=>false
,p_fc_compute_counts=>true
,p_fc_show_counts=>true
,p_fc_zero_count_entries=>'H'
,p_fc_show_more_count=>7
,p_fc_filter_values=>false
,p_fc_sort_by_top_counts=>true
,p_fc_show_selected_first=>false
,p_fc_show_chart=>true
,p_fc_initial_chart=>false
,p_fc_actions_filter=>true
,p_fc_display_as=>'INLINE'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(416145660463876672)
,p_name=>'P24_RANK_APP_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(416145660464876672)
,p_name=>'P24_RANK_CANDIDATE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_prompt=>'Candidate'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>12
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN',
  'send_on_page_submit', 'Y',
  'show_line_breaks', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(416145660465876672)
,p_name=>'P24_RANK_SCORE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_prompt=>'Score (1-5)'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>'STATIC:1;1,2;2,3;3,4;4,5;5'
,p_lov_display_null=>'YES'
,p_lov_null_text=>'-- Select Score --'
,p_colspan=>6
,p_lov_display_extra=>'NO'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(416145660466876672)
,p_name=>'P24_RANK_TEXT'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_prompt=>'Recommendation'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>'STATIC:Highly Recommended;Highly Recommended,Recommended;Recommended,Consider;Consider,Not Recommended;Not Recommended'
,p_lov_display_null=>'YES'
,p_lov_null_text=>'-- Select --'
,p_begin_on_new_line=>'N'
,p_colspan=>6
,p_lov_display_extra=>'NO'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(416145660467876672)
,p_name=>'P24_RANK_NOTE'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_prompt=>'Notes'
,p_display_as=>'NATIVE_TEXTAREA'
,p_cSize=>60
,p_cHeight=>4
,p_colspan=>12
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'auto_height', 'N',
  'character_counter', 'N',
  'resizable', 'Y',
  'trim_spaces', 'BOTH')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(416145660468876672)
,p_name=>'P24_RANK_LAST_BY'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(416125290950876608)
,p_prompt=>'Last Ranked By'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>12
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN',
  'send_on_page_submit', 'Y',
  'show_line_breaks', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(777000000000000301)
,p_name=>'P24_REFLINK_APP_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(777000000000000201)
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(777000000000000302)
,p_name=>'P24_REFLINK_CANDIDATE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(777000000000000201)
,p_prompt=>'Candidate'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>12
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN',
  'send_on_page_submit', 'Y',
  'show_line_breaks', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(777000000000000303)
,p_name=>'P24_REFLINK_URL'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(777000000000000201)
,p_prompt=>'Correction Link'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>12
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN',
  'send_on_page_submit', 'Y',
  'show_line_breaks', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(777000000000000304)
,p_name=>'P24_REFLINK_EMAIL'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(777000000000000201)
,p_prompt=>'Recipient Email'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>60
,p_colspan=>12
,p_field_template=>wwv_flow_imp.id(2318601014498890498)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Auto-populated for internal candidates. For external candidates, enter the applicant''s email.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(1478511615597826114)
,p_name=>'P24_JOB_APPLICATION_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(1478511615597826115)
,p_name=>'P24_CANDIDATE_DISPLAY'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_prompt=>'Candidate'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>12
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN',
  'send_on_page_submit', 'Y',
  'show_line_breaks', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(1478511615597826116)
,p_name=>'P24_CURRENT_PHASE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_prompt=>'Current Phase'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>6
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN',
  'send_on_page_submit', 'Y',
  'show_line_breaks', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(1478511615597826117)
,p_name=>'P24_CURRENT_STATE'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_prompt=>'Current State'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_begin_on_new_line=>'N'
,p_colspan=>6
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN',
  'send_on_page_submit', 'Y',
  'show_line_breaks', 'Y')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(1478511615597826118)
,p_name=>'P24_PHASE_ID'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_prompt=>'New Phase'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select distinct',
'       v.application_phase    d,',
'       v.application_phase_id r',
'from   fbx_qstnr_applicant_v v',
'where  v.application_phase_id is not null',
'order  by v.application_phase'))
,p_lov_display_null=>'YES'
,p_lov_null_text=>'-- Select Phase --'
,p_colspan=>12
,p_lov_display_extra=>'YES'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(1478511615597826119)
,p_name=>'P24_STATE_ID'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_prompt=>'New State'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select distinct',
'       rs.state_name  d,',
'       s.state_id     r',
'from   irc_routing_steps_stg  p',
'join   irc_routing_steps_stg  s',
'       on  s.process_id = p.sub_process_id',
'       and s.type_code  = ''STATE''',
'join   rec_routing_state  rs',
'       on  rs.state_id = s.state_id',
'where  p.phase_id  = :P24_PHASE_ID',
'and    p.type_code = ''PHASE''',
'order  by rs.state_name',
'',
''))
,p_lov_display_null=>'YES'
,p_lov_null_text=>'-- Select State --'
,p_lov_cascade_parent_items=>'P24_CURRENT_PHASE,P24_PHASE_ID'
,p_ajax_optimize_refresh=>'Y'
,p_colspan=>12
,p_lov_display_extra=>'YES'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(1478511615597826120)
,p_name=>'P24_COMMENTS'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_imp.id(1478477513570825728)
,p_prompt=>'Comments'
,p_display_as=>'NATIVE_TEXTAREA'
,p_cSize=>60
,p_cHeight=>4
,p_colspan=>12
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'auto_height', 'N',
  'character_counter', 'N',
  'resizable', 'Y',
  'trim_spaces', 'BOTH')).to_clob
,p_ai_enabled=>false
);
wwv_flow_imp_page.create_page_computation(
 p_id=>wwv_flow_imp.id(113355779188303519)
,p_computation_sequence=>10
,p_computation_item=>'P24_TICKET_COUNT'
,p_computation_point=>'BEFORE_BOX_BODY'
,p_computation_type=>'QUERY'
,p_computation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT COUNT(*)',
'  FROM app_ticket',
' WHERE status_code NOT IN (''RESOLVED'',''CLOSED'')',
'   AND (submitted_by = :APP_USER OR assigned_to = :APP_USER)',
'',
''))
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(106488269728817008)
,p_name=>'Cancel Button Click'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(106480559161649120)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(106488724140817008)
,p_event_id=>wwv_flow_imp.id(106488269728817008)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'cancelMoveForm();'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(106489124562818608)
,p_name=>'Move Button Click'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(106480180812649120)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(106489456625818608)
,p_event_id=>wwv_flow_imp.id(106489124562818608)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'submitMove();'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(106794150288104656)
,p_name=>'Cancel Ranking Click'
,p_event_sequence=>30
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(106483886329650688)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(106794604473104672)
,p_event_id=>wwv_flow_imp.id(106794150288104656)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'cancelRankingForm();'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(106794984809106384)
,p_name=>'Save Ranking Click'
,p_event_sequence=>40
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(106483502179650688)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(106795347651106384)
,p_event_id=>wwv_flow_imp.id(106794984809106384)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'submitRanking();'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(777000000000000501)
,p_name=>'Copy Ref Link Click'
,p_event_sequence=>50
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(777000000000000401)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(777000000000000601)
,p_event_id=>wwv_flow_imp.id(777000000000000501)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'copyRefLink();'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(777000000000000502)
,p_name=>'Send Ref Email Click'
,p_event_sequence=>60
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(777000000000000402)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(777000000000000602)
,p_event_id=>wwv_flow_imp.id(777000000000000502)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'sendRefLinkEmail();'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(777000000000000503)
,p_name=>'Cancel Ref Link Click'
,p_event_sequence=>70
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(777000000000000403)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(777000000000000603)
,p_event_id=>wwv_flow_imp.id(777000000000000503)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'cancelRefLinkForm();'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(106486689845672336)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'GET_APP_DETAILS'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_name     VARCHAR2(240);',
'    l_phase    VARCHAR2(240);',
'    l_state    VARCHAR2(240);',
'    l_phase_id NUMBER;',
'BEGIN',
'    SELECT',
'        CANDIDATE_NAME,',
'        APPLICATION_PHASE,',
'        APPLICATION_STATE',
'    INTO l_name, l_phase, l_state',
'    FROM FBX_QSTNR_APPLICANT_V',
'    WHERE JOB_APPLICATION_ID = TO_NUMBER(apex_application.g_x01)',
'      AND ROWNUM = 1;',
'',
'    -- Look up phase_id to pre-select the dropdown',
'    BEGIN',
'        SELECT phase_id INTO l_phase_id',
'          FROM rec_routing_phase',
'         WHERE phase_name = l_phase',
'           AND phase_type = ''APPLICATION''',
'           AND ROWNUM = 1;',
'    EXCEPTION',
'        WHEN NO_DATA_FOUND THEN l_phase_id := NULL;',
'    END;',
'',
'    apex_json.open_object;',
'    apex_json.write(''candidate_name'', l_name);',
'    apex_json.write(''phase'', l_phase);',
'    apex_json.write(''state'', l_state);',
'    apex_json.write(''phase_id'', l_phase_id);',
'    apex_json.close_object;',
'EXCEPTION',
'    WHEN NO_DATA_FOUND THEN',
'        apex_json.open_object;',
'        apex_json.write(''candidate_name'', ''Unknown'');',
'        apex_json.write(''phase'', '''');',
'        apex_json.write(''state'', '''');',
'        apex_json.write(''phase_id'', '''');',
'        apex_json.close_object;',
'END;',
''))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>106486689845672336
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(106486990371673216)
,p_process_sequence=>20
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'MOVE_APPLICANT'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_response CLOB;',
'BEGIN',
'    l_response := pkg_rec_move.move_application(',
'        p_job_application_id => TO_NUMBER(apex_application.g_x01),',
'        p_phase_id           => TO_NUMBER(apex_application.g_x02),',
'        p_state_id           => TO_NUMBER(apex_application.g_x03),',
'        p_comments           => apex_application.g_x04',
'    );',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''OK'');',
'    apex_json.close_object;',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_json.open_object;',
'        apex_json.write(''status'', ''ERROR'');',
'        apex_json.write(''message'', REGEXP_REPLACE(SQLERRM, ''^ORA-[0-9]+: *''));',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>106486990371673216
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(106487244362674208)
,p_process_sequence=>30
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'LIST_ATTACHMENTS'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    pkg_app_attachments.list_attachments(',
'        p_job_application_id => TO_NUMBER(apex_application.g_x01)',
'    );',
'END;',
''))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>106487244362674208
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(106487588413675200)
,p_process_sequence=>40
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'GET_RANKING_DETAILS'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_app_id NUMBER := TO_NUMBER(apex_application.g_x01);',
'    l_name   VARCHAR2(240);',
'    l_score  NUMBER;',
'    l_text   VARCHAR2(30);',
'    l_note   VARCHAR2(500);',
'    l_by     VARCHAR2(240);',
'BEGIN',
'    -- Get candidate name from the report view',
'    BEGIN',
'        SELECT NAME INTO l_name',
'        FROM RECRUITING_REPORT_V',
'        WHERE JOB_APPLICATION_ID = l_app_id',
'          AND ROWNUM = 1;',
'    EXCEPTION WHEN NO_DATA_FOUND THEN l_name := ''Unknown'';',
'    END;',
'    -- Get existing ranking (if any)',
'    BEGIN',
'        SELECT ranking_score, ranking_text, ranking_note, ranked_by',
'        INTO l_score, l_text, l_note, l_by',
'        FROM applicant_ranking',
'        WHERE job_application_id = l_app_id;',
'    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;',
'    END;',
'    apex_json.open_object;',
'    apex_json.write(''candidate_name'', l_name);',
'    apex_json.write(''ranking_score'', l_score);',
'    apex_json.write(''ranking_text'', l_text);',
'    apex_json.write(''ranking_note'', l_note);',
'    apex_json.write(''ranked_by'', l_by);',
'    apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>106487588413675200
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(106487865560675968)
,p_process_sequence=>50
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SAVE_RANKING'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_app_id NUMBER       := TO_NUMBER(apex_application.g_x01);',
'    l_score  NUMBER       := CASE WHEN apex_application.g_x02 IS NOT NULL',
'                                  THEN TO_NUMBER(apex_application.g_x02) END;',
'    l_text   VARCHAR2(30) := NULLIF(apex_application.g_x03, '''');',
'    l_note   VARCHAR2(500):= NULLIF(apex_application.g_x04, '''');',
'BEGIN',
'    MERGE INTO applicant_ranking t',
'    USING (SELECT l_app_id AS job_application_id FROM dual) s',
'    ON (t.job_application_id = s.job_application_id)',
'    WHEN MATCHED THEN UPDATE SET',
'        t.ranking_score = l_score,',
'        t.ranking_text  = l_text,',
'        t.ranking_note  = l_note,',
'        t.ranked_by     = :APP_USER,',
'        t.ranked_on     = SYSTIMESTAMP',
'    WHEN NOT MATCHED THEN INSERT',
'        (job_application_id, ranking_score, ranking_text, ranking_note,',
'         ranked_by, ranked_on)',
'    VALUES',
'        (l_app_id, l_score, l_text, l_note, :APP_USER, SYSTIMESTAMP);',
'    COMMIT;',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''OK'');',
'    apex_json.close_object;',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_json.open_object;',
'        apex_json.write(''status'', ''ERROR'');',
'        apex_json.write(''message'', SQLERRM);',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>106487865560675968
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(777000000000000701)
,p_process_sequence=>60
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'GENERATE_REF_LINK'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_app_id NUMBER := TO_NUMBER(apex_application.g_x01);',
'    l_url    VARCHAR2(4000);',
'    l_email  VARCHAR2(500);',
'    l_name   VARCHAR2(500);',
'BEGIN',
'    l_url := pkg_ref_correction.generate_token(',
'        p_job_application_id => l_app_id,',
'        p_requested_by       => :APP_USER',
'    );',
'',
'BEGIN',
'    SELECT c.EMAIL INTO l_email',
'      FROM RECRUITING_CANDIDATES_R c',
'      JOIN JOB_APPLICANTS_R a',
'        ON a.CANDIDATEPERSONID = c.PERSONID',
'     WHERE a.JOBAPPLICATIONID = l_app_id',
'       AND ROWNUM = 1;',
'EXCEPTION',
'    WHEN NO_DATA_FOUND THEN l_email := NULL;',
'END;',
'',
'    BEGIN',
'        SELECT CANDIDATENAME INTO l_name',
'          FROM JOB_APPLICANTS_R',
'         WHERE JOBAPPLICATIONID = l_app_id',
'           AND ROWNUM = 1;',
'    EXCEPTION',
'        WHEN NO_DATA_FOUND THEN l_name := ''Unknown'';',
'    END;',
'',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''OK'');',
'    apex_json.write(''url'', l_url);',
'    apex_json.write(''candidate_name'', l_name);',
'    apex_json.write(''candidate_email'', l_email);',
'    apex_json.close_object;',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_json.open_object;',
'        apex_json.write(''status'', ''ERROR'');',
'        apex_json.write(''message'', SQLERRM);',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>777000000000000701
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(777000000000000702)
,p_process_sequence=>70
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SEND_REF_LINK_EMAIL'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_app_id NUMBER := TO_NUMBER(apex_application.g_x01);',
'    l_email  VARCHAR2(500) := apex_application.g_x02;',
'    l_url    VARCHAR2(4000) := apex_application.g_x03;',
'    l_name   VARCHAR2(500);',
'BEGIN',
'    BEGIN',
'        SELECT CANDIDATENAME INTO l_name',
'          FROM JOB_APPLICANTS_R',
'         WHERE JOBAPPLICATIONID = l_app_id',
'           AND ROWNUM = 1;',
'    EXCEPTION',
'        WHEN NO_DATA_FOUND THEN l_name := ''Applicant'';',
'    END;',
'',
'    pkg_ref_correction.send_correction_email(',
'        p_job_application_id => l_app_id,',
'        p_candidate_email    => l_email,',
'        p_candidate_name     => l_name,',
'        p_url                => l_url',
'    );',
'',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''OK'');',
'    apex_json.close_object;',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_json.open_object;',
'        apex_json.write(''status'', ''ERROR'');',
'        apex_json.write(''message'', SQLERRM);',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>777000000000000702
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(116367866108692740)
,p_process_sequence=>80
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'GET_NOTES'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_app_id   NUMBER := TO_NUMBER(apex_application.g_x01);',
'    l_count    NUMBER := 0;',
'BEGIN',
'    apex_json.open_object;',
'    apex_json.open_array(''notes'');',
'',
'    FOR r IN (',
'        SELECT note_text,',
'               created_by,',
'               TO_CHAR(created_on, ''DD-Mon-YYYY HH24:MI'') AS created_on',
'          FROM candidate_note',
'         WHERE job_application_id = l_app_id',
'         ORDER BY created_on DESC',
'    ) LOOP',
'        l_count := l_count + 1;',
'        apex_json.open_object;',
'        apex_json.write(''note_text'',   r.note_text);',
'        apex_json.write(''created_by'',  r.created_by);',
'        apex_json.write(''created_on'',  r.created_on);',
'        apex_json.close_object;',
'    END LOOP;',
'',
'    apex_json.close_array;',
'    apex_json.write(''note_count'', l_count);',
'    apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>116367866108692740
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(116367976420692741)
,p_process_sequence=>90
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'ADD_NOTE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_app_id    NUMBER        := TO_NUMBER(apex_application.g_x01);',
'    l_note_text VARCHAR2(4000):= SUBSTRB(apex_application.g_x02, 1, 4000);',
'    l_count     NUMBER;',
'BEGIN',
'    INSERT INTO candidate_note (job_application_id, note_text, created_by)',
'    VALUES (l_app_id, l_note_text,',
'            COALESCE(SYS_CONTEXT(''APEX$SESSION'',''APP_USER''), USER));',
'',
'    -- Return updated notes list so the panel re-renders',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''OK'');',
'',
'    apex_json.open_array(''notes'');',
'    FOR r IN (',
'        SELECT note_text,',
'               created_by,',
'               TO_CHAR(created_on, ''DD-Mon-YYYY HH24:MI'') AS created_on',
'          FROM candidate_note',
'         WHERE job_application_id = l_app_id',
'         ORDER BY created_on DESC',
'    ) LOOP',
'        apex_json.open_object;',
'        apex_json.write(''note_text'',   r.note_text);',
'        apex_json.write(''created_by'',  r.created_by);',
'        apex_json.write(''created_on'',  r.created_on);',
'        apex_json.close_object;',
'    END LOOP;',
'    apex_json.close_array;',
'',
'    SELECT COUNT(*) INTO l_count',
'      FROM candidate_note',
'     WHERE job_application_id = l_app_id;',
'',
'    apex_json.write(''note_count'', l_count);',
'    apex_json.close_object;',
'',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_json.open_object;',
'        apex_json.write(''status'',  ''ERROR'');',
'        apex_json.write(''message'', SQLERRM);',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>116367976420692741
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(121639673242818749)
,p_process_sequence=>100
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'GET_PHONES'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);',
'BEGIN',
'    apex_json.open_object;',
'    apex_json.open_array(''phones'');',
'',
'    FOR r IN (',
'        SELECT phone_type,',
'               fmt_phone(',
'                   CASE',
'                       WHEN country_code_number IS NOT NULL',
'                            AND area_code IS NOT NULL',
'                       THEN country_code_number || area_code || phone_number',
'                       WHEN area_code IS NOT NULL',
'                       THEN area_code || phone_number',
'                       ELSE phone_number',
'                   END',
'               ) AS phone_number,',
'               NVL(primary_flag, ''N'') AS primary_flag',
'          FROM candidate_phones_r',
'         WHERE person_id = l_person_id',
'         ORDER BY DECODE(primary_flag, ''Y'', 0, 1),',
'                  DECODE(phone_type, ''MOBILE'', 1, ''HOME'', 2, ''WORK'', 3, 9),',
'                  phone_id',
'    ) LOOP',
'        apex_json.open_object;',
'        apex_json.write(''phone_type'',    r.phone_type);',
'        apex_json.write(''phone_number'',  r.phone_number);',
'        apex_json.write(''primary_flag'',  r.primary_flag);',
'        apex_json.close_object;',
'    END LOOP;',
'',
'    apex_json.close_array;',
'    apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>121639673242818749
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(126366813377556203)
,p_process_sequence=>110
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'GET_APPLICANT_NOTES'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);',
'    l_count     NUMBER := 0;',
'BEGIN',
'    apex_json.open_object;',
'    apex_json.open_array(''notes'');',
'',
'    FOR r IN (',
'        SELECT note_text,',
'               created_by,',
'               TO_CHAR(created_on, ''DD-Mon-YYYY HH24:MI'') AS created_on',
'          FROM applicant_note',
'         WHERE person_id = l_person_id',
'         ORDER BY created_on DESC',
'    ) LOOP',
'        l_count := l_count + 1;',
'        apex_json.open_object;',
'        apex_json.write(''note_text'',   r.note_text);',
'        apex_json.write(''created_by'',  r.created_by);',
'        apex_json.write(''created_on'',  r.created_on);',
'        apex_json.close_object;',
'    END LOOP;',
'',
'    apex_json.close_array;',
'    apex_json.write(''note_count'', l_count);',
'    apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>126366813377556203
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(126366928018556204)
,p_process_sequence=>120
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'ADD_APPLICANT_NOTE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_person_id NUMBER        := TO_NUMBER(apex_application.g_x01);',
'    l_note_text VARCHAR2(4000):= SUBSTRB(apex_application.g_x02, 1, 4000);',
'    l_count     NUMBER;',
'BEGIN',
'    INSERT INTO applicant_note (person_id, note_text, created_by)',
'    VALUES (l_person_id, l_note_text,',
'            COALESCE(SYS_CONTEXT(''APEX$SESSION'',''APP_USER''), USER));',
'',
'    -- Return updated notes list so the panel re-renders',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''OK'');',
'',
'    apex_json.open_array(''notes'');',
'    FOR r IN (',
'        SELECT note_text,',
'               created_by,',
'               TO_CHAR(created_on, ''DD-Mon-YYYY HH24:MI'') AS created_on',
'          FROM applicant_note',
'         WHERE person_id = l_person_id',
'         ORDER BY created_on DESC',
'    ) LOOP',
'        apex_json.open_object;',
'        apex_json.write(''note_text'',   r.note_text);',
'        apex_json.write(''created_by'',  r.created_by);',
'        apex_json.write(''created_on'',  r.created_on);',
'        apex_json.close_object;',
'    END LOOP;',
'    apex_json.close_array;',
'',
'    SELECT COUNT(*) INTO l_count',
'      FROM applicant_note',
'     WHERE person_id = l_person_id;',
'',
'    apex_json.write(''note_count'', l_count);',
'    apex_json.close_object;',
'',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_json.open_object;',
'        apex_json.write(''status'',  ''ERROR'');',
'        apex_json.write(''message'', SQLERRM);',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>126366928018556204
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done

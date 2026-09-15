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
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.15'
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
--     PAGE: 30
--   Manifest End
--   Version:         24.2.15
--   Instance ID:     8325348246048613
--

begin
null;
end;
/
prompt --application/pages/delete_00030
begin
wwv_flow_imp_page.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>30);
end;
/
prompt --application/pages/page_00030
begin
wwv_flow_imp_page.create_page(
 p_id=>30
,p_name=>'Download Attachment'
,p_alias=>'DOWNLOAD-ATTACHMENT'
,p_step_title=>'Download Attachment'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'N'
,p_page_component_map=>'03'
);
-- Hidden item: JOB_APPLICATION_ID
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90040000000000030)
,p_name=>'P30_JOB_APPLICATION_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(0)
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attribute_01=>'N'
);
-- Hidden item: ATTACHED_DOCUMENT_ID
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90040000000000031)
,p_name=>'P30_ATTACHED_DOCUMENT_ID'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(0)
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attribute_01=>'N'
);
-- Before Header process: download the file
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90040000000000032)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DOWNLOAD_FILE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    pkg_app_attachments.download_attachment(',
'        p_job_application_id   => TO_NUMBER(:P30_JOB_APPLICATION_ID),',
'        p_attached_document_id => TO_NUMBER(:P30_ATTACHED_DOCUMENT_ID)',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>90040000000000032
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

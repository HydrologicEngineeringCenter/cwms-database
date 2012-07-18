set define off
set verify off
set feedback off
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
begin wwv_flow.g_import_in_progress := true; end; 
/
 
--       AAAA       PPPPP   EEEEEE  XX      XX
--      AA  AA      PP  PP  EE       XX    XX
--     AA    AA     PP  PP  EE        XX  XX
--    AAAAAAAAAA    PPPPP   EEEE       XXXX
--   AA        AA   PP      EE        XX  XX
--  AA          AA  PP      EE       XX    XX
--  AA          AA  PP      EEEEEE  XX      XX
begin
select value into wwv_flow_api.g_nls_numeric_chars from nls_session_parameters where parameter='NLS_NUMERIC_CHARACTERS';
execute immediate 'alter session set nls_numeric_characters=''.,''';
end;
/
-- Workspace, user group, user and team development export
-- Generated 2012.07.18 20:32:59 by ART
-- This script can be run in sqlplus as the owner of the Oracle Apex owner.
begin
    wwv_flow_api.set_security_group_id(p_security_group_id=>1448312700321587);
end;
/
----------------
-- W O R K S P A C E
-- Creating a workspace will not create database schemas or objects.
-- This API creates only the meta data for this APEX workspace
prompt  Creating workspace CWMS_APEX...
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
end;
/
begin
wwv_flow_fnd_user_api.create_company (
  p_id                           => 1448402674321624,
  p_provisioning_company_id      => 1448312700321587,
  p_short_name                   => 'CWMS_APEX',
  p_display_name                 => 'CWMS_APEX',
  p_workspace_service_id         => null,
  p_first_schema_provisioned     => 'CWMS_APEX',
  p_company_schemas              => 'CWMS_APEX',
  p_expire_fnd_user_accounts     => '',
  p_account_lifetime_days        => '',
  p_fnd_user_max_login_failures  => '',
  p_account_status               => 'ASSIGNED',
  p_allow_plsql_editing          => 'Y',
  p_allow_app_building_yn        => 'Y',
  p_allow_sql_workshop_yn        => 'Y',
  p_allow_websheet_dev_yn        => 'Y',
  p_allow_team_development_yn    => 'Y',
  p_allow_to_be_purged_yn        => 'Y',
  p_source_identifier            => 'CWMS_APE',
  p_builder_notification_message => '',
  p_workspace_image              => wwv_flow_api.g_varchar2_table,
  p_workspace_image_mime_type    => '');
end;
/
----------------
-- G R O U P S
--
prompt  Creating Groups...
----------------
-- U S E R S
-- User repository for use with apex cookie based authenticaion.
--
prompt  Creating Users...
begin
wwv_flow_fnd_user_api.create_fnd_user (
  p_user_id      => '1448214031321587',
  p_user_name    => 'ART',
  p_first_name   => 'Art',
  p_last_name    => 'Pabst',
  p_description  => '',
  p_email_address=> 'cwms-helpdesk@usace.army.mil',
  p_web_password => '4C61E9CF102DB4446181594BB16B9E66',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_APEX',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201207182027','YYYYMMDDHH24MI'),
  p_failed_access_attempts=> 0,
  p_change_password_on_first_use=> 'N',
  p_first_password_use_occurred=> 'Y',
  p_allow_app_building_yn=> 'Y',
  p_allow_sql_workshop_yn=> 'Y',
  p_allow_websheet_dev_yn=> 'Y',
  p_allow_team_development_yn=> 'Y',
  p_allow_access_to_schemas => '');
end;
/
begin
wwv_flow_fnd_user_api.create_fnd_user (
  p_user_id      => '2060232267086146',
  p_user_name    => 'CWMS_DEV',
  p_first_name   => 'CWMS',
  p_last_name    => 'Developer',
  p_description  => '',
  p_email_address=> 'CWMS-HelpDesk@usace.army.mil',
  p_web_password => 'B1A3831B8FF817C5982FB96FB75921D0',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_APEX',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201207180000','YYYYMMDDHH24MI'),
  p_failed_access_attempts=> 0,
  p_change_password_on_first_use=> 'N',
  p_first_password_use_occurred=> 'N',
  p_allow_app_building_yn=> 'Y',
  p_allow_sql_workshop_yn=> 'Y',
  p_allow_websheet_dev_yn=> 'Y',
  p_allow_team_development_yn=> 'Y',
  p_allow_access_to_schemas => '');
end;
/
commit;
begin 
execute immediate 'begin dbms_session.set_nls( param => ''NLS_NUMERIC_CHARACTERS'', value => '''''''' || replace(wwv_flow_api.g_nls_numeric_chars,'''''''','''''''''''') || ''''''''); end;';
end;
/
set verify on
set feedback on
prompt  ...done

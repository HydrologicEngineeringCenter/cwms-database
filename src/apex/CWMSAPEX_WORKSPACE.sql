set define off
set verify off
set serveroutput on size 1000000
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
-- Generated 2011.12.21 19:36:31 by ART
-- This script can be run in sqlplus as the owner of the Oracle Apex owner.
begin
    wwv_flow_api.set_security_group_id(p_security_group_id=>1279909380548202);
end;
/
----------------
-- W O R K S P A C E
-- Creating a workspace will not create database schemas or objects.
-- This API creates only the meta data for this APEX workspace
prompt  Creating workspace CWMSAPEX...
begin
wwv_flow_fnd_user_api.create_company (
  p_id                           => 1280021385548450,
  p_provisioning_company_id      => 1279909380548202,
  p_short_name                   => 'CWMSAPEX',
  p_first_schema_provisioned     => 'CWMS_20',
  p_company_schemas              => 'CWMS_20',
  p_expire_fnd_user_accounts     => 'N',
  p_account_lifetime_days        => '',
  p_fnd_user_max_login_failures  => '',
  p_allow_plsql_editing          => 'Y',
  p_allow_app_building_yn        => 'Y',
  p_allow_sql_workshop_yn        => 'Y',
  p_allow_websheet_dev_yn        => 'Y',
  p_allow_team_development_yn    => 'N',
  p_allow_to_be_purged_yn        => 'Y',
  p_source_identifier            => 'CWMSAPEX',
  p_builder_notification_message => '');
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
  p_user_id      => '1475103251896923',
  p_user_name    => 'ART',
  p_first_name   => '',
  p_last_name    => '',
  p_description  => '',
  p_email_address=> 'Art.Pabst@usace.army.mil',
  p_web_password => '4DDFCE37E6B510D94BF23E941AA06DA1',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201111071935','YYYYMMDDHH24MI'),
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
  p_user_id      => '1289916928562898',
  p_user_name    => 'Q0HECAP3',
  p_first_name   => 'Art',
  p_last_name    => 'Pabst',
  p_description  => '',
  p_email_address=> 'arthur.pabst@usace.army.mil',
  p_web_password => '309A2497A3B169015CB106BD4D612CE5',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'CREATE:EDIT:HELP:MONITOR:SQL:MONITOR:DATA_LOADER',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201111291139','YYYYMMDDHH24MI'),
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
begin
wwv_flow_fnd_user_api.create_fnd_user (
  p_user_id      => '1290403899568535',
  p_user_name    => 'Q0HECCWF',
  p_first_name   => 'Carl',
  p_last_name    => 'Franke',
  p_description  => '',
  p_email_address=> 'Carl.Franke@usace.army.mil',
  p_web_password => 'E8B88888DC5D50D35BE7D517A4A7C62D',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201007082044','YYYYMMDDHH24MI'),
  p_failed_access_attempts=> 0,
  p_change_password_on_first_use=> 'Y',
  p_first_password_use_occurred=> 'N',
  p_allow_app_building_yn=> 'Y',
  p_allow_sql_workshop_yn=> 'Y',
  p_allow_websheet_dev_yn=> 'Y',
  p_allow_team_development_yn=> 'Y',
  p_allow_access_to_schemas => '');
end;
/
begin
wwv_flow_fnd_user_api.create_fnd_user (
  p_user_id      => '1289428918556802',
  p_user_name    => 'Q0HECGHK',
  p_first_name   => 'Gerhard',
  p_last_name    => 'Krueger',
  p_description  => '',
  p_email_address=> 'Gerhard.Krueger@usace.army.mil',
  p_web_password => '8C641E9FD524DED6265E5DEDCD07BFAC',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201007082059','YYYYMMDDHH24MI'),
  p_failed_access_attempts=> 0,
  p_change_password_on_first_use=> 'Y',
  p_first_password_use_occurred=> 'Y',
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

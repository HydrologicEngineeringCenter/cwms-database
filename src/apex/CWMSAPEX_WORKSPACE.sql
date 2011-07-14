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
-- Generated 2011.07.14 18:21:24 by ART
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
  p_expire_fnd_user_accounts     => '',
  p_account_lifetime_days        => '',
  p_fnd_user_max_login_failures  => '',
  p_allow_plsql_editing          => 'Y',
  p_allow_app_building_yn        => 'Y',
  p_allow_sql_workshop_yn        => 'Y',
  p_allow_websheet_dev_yn        => 'Y',
  p_allow_team_development_yn    => 'Y',
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
  p_web_password => 'E1367A8678ACF58C125977AA26F4311E',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201106062103','YYYYMMDDHH24MI'),
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
  p_user_id      => '1460408362567230',
  p_user_name    => 'JEREMY',
  p_first_name   => '',
  p_last_name    => '',
  p_description  => '',
  p_email_address=> 'Jeremy.D.Kellett@usace.army.mil',
  p_web_password => 'C0F30A757F98146C6291A4CCC6572128',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201009020000','YYYYMMDDHH24MI'),
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
  p_user_id      => '1289916928562898',
  p_user_name    => 'Q0HECAP3',
  p_first_name   => 'Art',
  p_last_name    => 'Pabst',
  p_description  => '',
  p_email_address=> 'arthur.pabst@usace.army.mil',
  p_web_password => '239BFADBE9D9DA9BFE134EA024E9D544',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201101271659','YYYYMMDDHH24MI'),
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
begin
wwv_flow_fnd_user_api.create_fnd_user (
  p_user_id      => '1336328383211064',
  p_user_name    => 'U4RT9JDK',
  p_first_name   => 'Jeremy',
  p_last_name    => 'Kellet',
  p_description  => '',
  p_email_address=> 'jeremy.d.kellet@usace.army.mil',
  p_web_password => '5EA3737CADEA42E8E6696DE93AE410D7',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201101041658','YYYYMMDDHH24MI'),
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
  p_user_id      => '1279805550548201',
  p_user_name    => 'U4RT9MDS',
  p_first_name   => 'Michael',
  p_last_name    => 'Smith',
  p_description  => '',
  p_email_address=> 'michael.smith@usace.army.mil',
  p_web_password => 'DD5C72A6DF3E1DB23C1A61F941799799',
  p_web_password_format => 'HEX_ENCODED_DIGEST_V2',
  p_group_ids    => '',
  p_developer_privs=> 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
  p_default_schema=> 'CWMS_20',
  p_account_locked=> 'N',
  p_account_expiry=> to_date('201007091510','YYYYMMDDHH24MI'),
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
prompt Check Compatibility...
begin
-- This date identifies the minimum version required to import this file.
wwv_flow_team_api.check_version(p_version_yyyy_mm_dd=>'2010.05.13');
end;
/
 
begin wwv_flow.g_import_in_progress := true; wwv_flow.g_user := USER; end; 
/
 
--
prompt ...news
--
begin
null;
end;
/
--
prompt ...links
--
begin
null;
end;
/
--
prompt ...bugs
--
begin
null;
end;
/
--
prompt ...events
--
begin
null;
end;
/
--
prompt ...features
--
begin
null;
end;
/
--
prompt ...tasks
--
begin
null;
end;
/
--
prompt ...feedback
--
begin
wwv_flow_team_api.create_feedback (
  p_id => 1376102603188601 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 1
 ,p_feedback_comment => 'Multi-delete locations needs progress bar for large deletes.'
 ,p_feedback_type => 2
 ,p_application_id => 395
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 38
 ,p_page_name => 'Multi-Delete Location'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110607162511','YYYYMMDDHH24MISS')
 ,p_session_id => '8150398731792873'
 ,p_apex_user => 'H1HECTEST'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.95'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=2536D86FDEA5FD59BE4B5C092EB5E2EA80B2E8370BCAB5AA10BC9FF567772D24'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=10-JUN-11'
 ,p_session_state => 'F99_PAGE_COUNT="11"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_PREVIOUS="38"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_s"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_DB_OFFICE_CODE="8"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="40.9"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-77.3"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="6"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_UNIT_SYSTEM="EN"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="F"'||chr(10)||
'F99_LOGON_USER="H1HECTEST"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_ADMIN_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''>(*Super "'||chr(10)||
'F99_ADMIN_FLAG_RIGHT=" </span>"'||chr(10)||
'F99_TMP5="H1HECTEST:H1HECTEST"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_AU"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS Admin User"'||chr(10)||
'F99_UNIQUE_PAGE_ID="79917059050756"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="10-JUN-2011"'||chr(10)||
'F99_LOCAL_TIME="08:50:26"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.103"'||chr(10)||
'P1001_LOGON_INFO="Logon: LRH:H1HECTEST From:155.83.200.103 To:hec-cw"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.06.10.15.48.24"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="756948.6166666666666666666666666666666666"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_AU"'||chr(10)||
'F99_TMP2="10-Jun-2011 15:48"'||chr(10)||
'F99_TMP3="09-Jun-2011 15:48"'||chr(10)||
'P1_MAP_MODE="ELI"'||chr(10)||
'P1_DISTRICT="All"'||chr(10)||
'P1_PARAMETER="Elev"'||chr(10)||
'P1_VERSION="DCP-raw"'||chr(10)||
'P1_DISTRICT_LAST="All"'||chr(10)||
'P1_CLICK_LOC="A Test"'||chr(10)||
'P1_TMP="P1_USER_ROLE"'||chr(10)||
'P1_STALE_AFTER_MINUTES="30"'||chr(10)||
'P1_SUBMIT_REQUEST="P1_USER_ROLE"'||chr(10)||
'F99_TMP0="P1_USER_ROLE"'||chr(10)||
'P35_LOC_FILTER="*"'||chr(10)||
'P35_STATE_INITIAL="%"'||chr(10)||
'P35_ACTIVE="%"'||chr(10)||
'P35_LOC_TYPE="%"'||chr(10)||
'P35_CATEGORY="%"'||chr(10)||
'P35_GROUP="%"'||chr(10)||
'P38_LOC_FILTER="s*"'||chr(10)||
'P38_STATE_INITIAL="%"'||chr(10)||
'P38_ACTIVE="%"'||chr(10)||
'P38_LOC_TYPE="%"'||chr(10)||
'P38_NUMBER_CHECKED="0"'||chr(10)||
'P38_SCOPE_OF_DELETE="BY_FILTER"'||chr(10)||
'P38_REQUEST="DELETE_LOCS"'||chr(10)||
'F99_ROLE_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''> "'||chr(10)||
'F99_ROLE_FLAG_RIGHT=" </span>"'||chr(10)||
'F99_MY_REQUEST="DELETE_LOCS"'||chr(10)||
'P102_APPLICATION_ID="395"'||chr(10)||
'P102_PAGE_ID="38"'||chr(10)||
'P102_FEEDBACK="Multi-delete locations needs progress bar for larg"'||chr(10)||
'P102_FEEDBACK_TYPE="2"'||chr(10)||
''
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/5.0 (Windows NT 5.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1'
 ,p_remote_addr => '155.83.200.103'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'H1HECTEST'
 ,p_created_on => to_timestamp_tz('20110610155105.734849000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'H1HECTEST'
 ,p_updated_on => to_timestamp_tz('20110610155105.734865000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1379022116528320 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 2
 ,p_feedback_comment => 'On TS delete page when you chose the % parameter to delete all % data, it is interpreted as the Oracle % wild character.  Where else is this true? ? ?'
 ,p_feedback_type => 3
 ,p_application_id => 395
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 1
 ,p_page_name => 'Home'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110607173534','YYYYMMDDHH24MISS')
 ,p_session_id => '8150398731792873'
 ,p_apex_user => 'H1HECTEST'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.95'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=2536D86FDEA5FD59BE4B5C092EB5E2EA80B2E8370BCAB5AA10BC9FF567772D24'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=10-JUN-11'
 ,p_session_state => 'F99_PAGE_COUNT="68"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_PREVIOUS="1"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_s"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_DB_OFFICE_CODE="8"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="40.9"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-77.3"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="6"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="F"'||chr(10)||
'F99_LOGON_USER="H1HECTEST"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_ADMIN_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''>(*Super "'||chr(10)||
'F99_ADMIN_FLAG_RIGHT=" </span>"'||chr(10)||
'F99_TMP5="H1HECTEST:H1HECTEST"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_AU"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS Admin User"'||chr(10)||
'F99_UNIQUE_PAGE_ID="306088185245611"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="10-JUN-2011"'||chr(10)||
'F99_LOCAL_TIME="12:32:50"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.103"'||chr(10)||
'P1001_LOGON_INFO="Logon: LRH:H1HECTEST From:155.83.200.103 To:hec-cw"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.06.10.15.48.24"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="757172.6333333333333333333333333333333338"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_AU"'||chr(10)||
'F99_TMP2="10-Jun-2011 19:32"'||chr(10)||
'F99_TMP3="09-Jun-2011 19:32"'||chr(10)||
'P1_MAP_MODE="ELI"'||chr(10)||
'P1_DISTRICT="All"'||chr(10)||
'P1_PARAMETER="Elev"'||chr(10)||
'P1_VERSION="DCP-raw"'||chr(10)||
'P1_DISTRICT_LAST="All"'||chr(10)||
'P1_CLICK_LOC="A Test"'||chr(10)||
'P1_TMP="P1_USER_ROLE"'||chr(10)||
'P1_STALE_AFTER_MINUTES="30"'||chr(10)||
'P1_SUBMIT_REQUEST="P1_USER_ROLE"'||chr(10)||
'F99_TMP0="In (Delete) Delete TS ids"'||chr(10)||
'P35_LOC_FILTER="*"'||chr(10)||
'P35_STATE_INITIAL="%"'||chr(10)||
'P35_ACTIVE="%"'||chr(10)||
'P35_LOC_TYPE="%"'||chr(10)||
'P35_CATEGORY="%"'||chr(10)||
'P35_GROUP="%"'||chr(10)||
'P38_LOC_FILTER="g*"'||chr(10)||
'P38_STATE_INITIAL="%"'||chr(10)||
'P38_ACTIVE="%"'||chr(10)||
'P38_LOC_TYPE="%"'||chr(10)||
'P38_NUMBER_CHECKED="0"'||chr(10)||
'P38_TMP0="In Delete Locs-by filter6"'||chr(10)||
'P38_TMP1="Count = 35 Location: GYHV2"'||chr(10)||
'P38_SCOPE_OF_DELETE="BY_FILTER"'||chr(10)||
'P38_REQUEST="DELETE_LOCS"'||chr(10)||
'P0_TEXT_DROP="Completed 37 records"'||chr(10)||
'P0_ELAPSED="00:24"'||chr(10)||
'P0_ELAPSED_MIN=".4"'||chr(10)||
'P0_NUMBER_PROCESSED="37"'||chr(10)||
'P0_ITEMS_PER_MIN="92"'||chr(10)||
'P0_STEPS_PER_COMMIT="5"'||chr(10)||
'P0_EXE_PATH="1 2"'||chr(10)||
'P430_SCOPE_OF_DELETE="BY_FILTER"'||chr(10)||
'F99_COLLECTION_SIZE="2053"'||chr(10)||
'F99_TMP="Westernport.Conc-Sulfate.Inst.0.0.SHEF-manual-raw"'||chr(10)||
'P490_TS_COUNT="0"'||chr(10)||
'P0_LOC_FILTER_EF="*"'||chr(10)||
'P0_PARAMETER_EF="_%_"'||chr(10)||
'P0_SUB_PARM_EF="%"'||chr(10)||
'P490_START_DATE3="09Jun2011 1300"'||chr(10)||
'P490_END_DATE3="10Jun2011 1300"'||chr(10)||
'P490_CWMS_TS_ID_UNDERBAR3="<span_style="background-color:#99FFFF;font-size:22"'||chr(10)||
'P490_UNITS_DEFAULT="??"'||chr(10)||
'P0_NUMBER_CHECKED="0"'||chr(10)||
'P0_PARM_TYPE_EF="%"'||chr(10)||
'P0_INTERVAL_EF="%"'||chr(10)||
'P0_DURATION_EF="%"'||chr(10)||
'P490_CWMS_TS_ID3="<span style="background-color:#99FFFF;font-size:22"'||chr(10)||
'F99_WIDE_OPEN_TS_FILTER="F"'||chr(10)||
'P802_OLD_CATEGORY_ID="Agency Aliases"'||chr(10)||
'P802_OLD_CATEGORY_OWNER="CWMS"'||chr(10)||
'P802_WHICH_CATEGORY="Agency Aliases"'||chr(10)||
'F99_NUMBER_CHECKED="1"'||chr(10)||
'P0_UNIQUE_PROCESS_ID="395.2465197283635551.430.8150398731792873.PURGE_TI"'||chr(10)||
'P0_PROCESS_NAME="PURGE_TIME_SERIES_VALUES"'||chr(10)||
'P490_TS_VALUE_COUNT3="0"'||chr(10)||
'F99_ROLE_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''> "'||chr(10)||
'F99_ROLE_FLAG_RIGHT=" </span>"'||chr(10)||
' - more state exists'
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/5.0 (Windows NT 5.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1'
 ,p_remote_addr => '155.83.200.103'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'H1HECTEST'
 ,p_created_on => to_timestamp_tz('20110610193423.087529000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'H1HECTEST'
 ,p_updated_on => to_timestamp_tz('20110610193423.087543000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1440818238959361 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 3
 ,p_feedback_comment => 'Make error reports/tables more consistent.  Always give a report, success, or other, with counts, details, etc.'
 ,p_feedback_type => 1
 ,p_application_id => 396
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 38
 ,p_page_name => 'Multi-Delete Location'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110616174143','YYYYMMDDHH24MISS')
 ,p_session_id => '4338611268362015'
 ,p_apex_user => 'H1HECTEST'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.96'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=7049AB0DF556279F8121774D9FF2C2345E0764AC505AE3341C0723B12D926D17'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=16-JUN-11'
 ,p_session_state => 'P805_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P805_TS_FILTER_CHOICE="EF"'||chr(10)||
'P805_RT_CACHE_STALE_AFTER="30"'||chr(10)||
'P10_OFFICE_ID="%"'||chr(10)||
'P102_FEEDBACK="Make error reports/tables more consistent.  Always"'||chr(10)||
'P102_FEEDBACK_TYPE="1"'||chr(10)||
'P601_FILE_EXTENSION=".csv"'||chr(10)||
'P601_IS_A_CSV="T"'||chr(10)||
'P601_DIRECTION="IM"'||chr(10)||
'P601_SELECT_DESIRED_ACTION="IM_PSCF"'||chr(10)||
'P601_SELECT_DESIRED_IMPORT="PSCF"'||chr(10)||
'P601_SELECT_DESIRED_REPORT="PSCF"'||chr(10)||
'P612_FILE_SELECTION_SAVE="F25994/CWMS_PSCF.lrh_nab_shefx927_SubLoc.csv"'||chr(10)||
'P612_DS_CLEAR_MERGE="CLEAR"'||chr(10)||
'P612_UPDATE_ALLOWED="T"'||chr(10)||
'P612_DATA_STREAM_ID="lrh_nab_shef"'||chr(10)||
'P612_ALIAS_GROUP="SHEF Location ID"'||chr(10)||
'P612_TOTAL_LINES_READ="928"'||chr(10)||
'P612_TOTAL_COLUMNS="23"'||chr(10)||
'P612_PARSE_ERRORS="0"'||chr(10)||
'P612_PARSED_LINES="927"'||chr(10)||
'P612_IS_A_CSV="T"'||chr(10)||
'P612_HEADINGS="ImportAction:IgnoreSHEFSpec:NetActiveStatus:TimeSe"'||chr(10)||
'P612_COLUMNS="c001,c002,c003,c004,c005,c006,c007,c008,c009,c010,"'||chr(10)||
'P612_LAST_RECORD_CONTENT=">Store[1]:[2]:[3]:T[4]:[5]:[6]:ZIOP1[7]:PP[8]:RRZ["'||chr(10)||
'P612_STORE_DB_STORED="927"'||chr(10)||
'P612_STORE_DB_REJECTED="0"'||chr(10)||
'F99_COLLECTION_SIZE="3380"'||chr(10)||
'F99_TMP="aafzz-gk-zz.Temp.Inst.1Day.0.gk was here"'||chr(10)||
'P0_STEPS_PER_COMMIT="5"'||chr(10)||
'P0_EXE_PATH="1 2"'||chr(10)||
'P430_SCOPE_OF_DELETE="BY_FILTER"'||chr(10)||
'P0_ELAPSED="---"'||chr(10)||
'P0_ELAPSED_MIN="-1"'||chr(10)||
'P0_NUMBER_PROCESSED="0"'||chr(10)||
'P0_ITEMS_PER_MIN="---"'||chr(10)||
'P38_LOC_FILTER="aaa*"'||chr(10)||
'P38_STATE_INITIAL="%"'||chr(10)||
'P38_ACTIVE="%"'||chr(10)||
'P38_LOC_TYPE="%"'||chr(10)||
'P38_NUMBER_CHECKED="0"'||chr(10)||
'P38_TMP0="In Delete Locs-by filter6"'||chr(10)||
'P38_TMP1="Count = 676 Location: aaaaa"'||chr(10)||
'P38_SCOPE_OF_DELETE="BY_FILTER"'||chr(10)||
'P38_REQUEST="DELETE_LOCS"'||chr(10)||
'P600_SCREEN_ID_LIST="%"'||chr(10)||
'P600_DIRECTION="EX"'||chr(10)||
'P600_SELECT_DESIRED_ACTION="EX_"'||chr(10)||
'P600_FILE_EXTENSION=".csv"'||chr(10)||
'P600_COMBINED_FILTER="*"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_LIST="lrh_nab_shef"'||chr(10)||
'F99_PAGE_COUNT="126"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_PREVIOUS="38"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_s"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_DB_OFFICE_CODE="8"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="40.9"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-77.3"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="6"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="T"'||chr(10)||
'F99_LOGON_USER="H1HECTEST"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_ADMIN_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''>(*Super "'||chr(10)||
'F99_ADMIN_FLAG_RIGHT=" </span>"'||chr(10)||
'F99_TMP5="H1HECTEST:H1HECTEST"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_AU"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS Admin User"'||chr(10)||
'F99_UNIQUE_PAGE_ID="3541533085305509"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="16-JUN-2011"'||chr(10)||
'F99_LOCAL_TIME="11:24:50"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.103"'||chr(10)||
'P1001_LOGON_INFO="Logon: LRH:H1HECTEST From:155.83.200.103 To:hec-cw"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.06.16.15.37.18"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="765706.9666666666666666666666666666666666"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_AU"'||chr(10)||
'F99_TMP2=" l_count: 3380"'||chr(10)||
'F99_TMP3="15JUN2011 1000"'||chr(10)||
'P35_LOC_FILTER="aa*"'||chr(10)||
'P35_STATE_INITIAL="%"'||chr(10)||
'P35_ACTIVE="%"'||chr(10)||
' - more state exists'
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/5.0 (Windows NT 5.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1'
 ,p_remote_addr => '155.83.200.103'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'H1HECTEST'
 ,p_created_on => to_timestamp_tz('20110616182619.187613000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'H1HECTEST'
 ,p_updated_on => to_timestamp_tz('20110616182619.187628000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1440900361963716 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 4
 ,p_feedback_comment => 'make status bar to use smart increments for count and time update.'
 ,p_feedback_type => 1
 ,p_application_id => 396
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 38
 ,p_page_name => 'Multi-Delete Location'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110616174143','YYYYMMDDHH24MISS')
 ,p_session_id => '4338611268362015'
 ,p_apex_user => 'H1HECTEST'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.96'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=7049AB0DF556279F8121774D9FF2C2345E0764AC505AE3341C0723B12D926D17'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=16-JUN-11'
 ,p_session_state => 'P805_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P805_TS_FILTER_CHOICE="EF"'||chr(10)||
'P805_RT_CACHE_STALE_AFTER="30"'||chr(10)||
'P10_OFFICE_ID="%"'||chr(10)||
'P102_FEEDBACK="make status bar to use smart increments for count "'||chr(10)||
'P102_FEEDBACK_TYPE="1"'||chr(10)||
'P601_FILE_EXTENSION=".csv"'||chr(10)||
'P601_IS_A_CSV="T"'||chr(10)||
'P601_DIRECTION="IM"'||chr(10)||
'P601_SELECT_DESIRED_ACTION="IM_PSCF"'||chr(10)||
'P601_SELECT_DESIRED_IMPORT="PSCF"'||chr(10)||
'P601_SELECT_DESIRED_REPORT="PSCF"'||chr(10)||
'P612_FILE_SELECTION_SAVE="F25994/CWMS_PSCF.lrh_nab_shefx927_SubLoc.csv"'||chr(10)||
'P612_DS_CLEAR_MERGE="CLEAR"'||chr(10)||
'P612_UPDATE_ALLOWED="T"'||chr(10)||
'P612_DATA_STREAM_ID="lrh_nab_shef"'||chr(10)||
'P612_ALIAS_GROUP="SHEF Location ID"'||chr(10)||
'P612_TOTAL_LINES_READ="928"'||chr(10)||
'P612_TOTAL_COLUMNS="23"'||chr(10)||
'P612_PARSE_ERRORS="0"'||chr(10)||
'P612_PARSED_LINES="927"'||chr(10)||
'P612_IS_A_CSV="T"'||chr(10)||
'P612_HEADINGS="ImportAction:IgnoreSHEFSpec:NetActiveStatus:TimeSe"'||chr(10)||
'P612_COLUMNS="c001,c002,c003,c004,c005,c006,c007,c008,c009,c010,"'||chr(10)||
'P612_LAST_RECORD_CONTENT=">Store[1]:[2]:[3]:T[4]:[5]:[6]:ZIOP1[7]:PP[8]:RRZ["'||chr(10)||
'P612_STORE_DB_STORED="927"'||chr(10)||
'P612_STORE_DB_REJECTED="0"'||chr(10)||
'F99_COLLECTION_SIZE="3380"'||chr(10)||
'F99_TMP="aafzz-gk-zz.Temp.Inst.1Day.0.gk was here"'||chr(10)||
'P0_STEPS_PER_COMMIT="5"'||chr(10)||
'P0_EXE_PATH="1 2"'||chr(10)||
'P430_SCOPE_OF_DELETE="BY_FILTER"'||chr(10)||
'P0_ELAPSED="---"'||chr(10)||
'P0_ELAPSED_MIN="-1"'||chr(10)||
'P0_NUMBER_PROCESSED="0"'||chr(10)||
'P0_ITEMS_PER_MIN="---"'||chr(10)||
'P38_LOC_FILTER="aaa*"'||chr(10)||
'P38_STATE_INITIAL="%"'||chr(10)||
'P38_ACTIVE="%"'||chr(10)||
'P38_LOC_TYPE="%"'||chr(10)||
'P38_NUMBER_CHECKED="0"'||chr(10)||
'P38_TMP0="In Delete Locs-by filter6"'||chr(10)||
'P38_TMP1="Count = 676 Location: aaaaa"'||chr(10)||
'P38_SCOPE_OF_DELETE="BY_FILTER"'||chr(10)||
'P38_REQUEST="DELETE_LOCS"'||chr(10)||
'P600_SCREEN_ID_LIST="%"'||chr(10)||
'P600_DIRECTION="EX"'||chr(10)||
'P600_SELECT_DESIRED_ACTION="EX_"'||chr(10)||
'P600_FILE_EXTENSION=".csv"'||chr(10)||
'P600_COMBINED_FILTER="*"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_LIST="lrh_nab_shef"'||chr(10)||
'F99_PAGE_COUNT="127"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_PREVIOUS="102"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_s"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="LRH"'||chr(10)||
'F99_DB_OFFICE_CODE="8"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA STREAMS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="40.9"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-77.3"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="6"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="T"'||chr(10)||
'F99_LOGON_USER="H1HECTEST"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_ADMIN_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''>(*Super "'||chr(10)||
'F99_ADMIN_FLAG_RIGHT=" </span>"'||chr(10)||
'F99_TMP5="H1HECTEST:H1HECTEST"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_AU"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS Admin User"'||chr(10)||
'F99_UNIQUE_PAGE_ID="3291296364738772"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="16-JUN-2011"'||chr(10)||
'F99_LOCAL_TIME="11:26:23"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.103"'||chr(10)||
'P1001_LOGON_INFO="Logon: LRH:H1HECTEST From:155.83.200.103 To:hec-cw"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.06.16.15.37.18"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="765706.9666666666666666666666666666666666"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_AU"'||chr(10)||
'F99_TMP2=" l_count: 3380"'||chr(10)||
'F99_TMP3="15JUN2011 1000"'||chr(10)||
'P35_LOC_FILTER="aa*"'||chr(10)||
'P35_STATE_INITIAL="%"'||chr(10)||
'P35_ACTIVE="%"'||chr(10)||
' - more state exists'
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/5.0 (Windows NT 5.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1'
 ,p_remote_addr => '155.83.200.103'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'H1HECTEST'
 ,p_created_on => to_timestamp_tz('20110616182702.733664000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'H1HECTEST'
 ,p_updated_on => to_timestamp_tz('20110616182702.733677000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1483307458577536 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 5
 ,p_feedback_comment => 'Need sanctioned list of location site types, multi-types!'
 ,p_feedback_type => 1
 ,p_application_id => 396
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 35
 ,p_page_name => 'Select Location'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110616195423','YYYYMMDDHH24MISS')
 ,p_session_id => '2677631889719671'
 ,p_apex_user => 'G0NWDP'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.96'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=24F1006E3F3C67DEA2FCDC56B3C016C6B1D6394899776DC0CBC3B5A008CE6633'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=28-JUN-11'
 ,p_session_state => 'F99_APP_EGIS="T"'||chr(10)||
'F99_PAGE_COUNT="29"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_PAGE_PREVIOUS="35"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_s"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="NWDP"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="NWDP"'||chr(10)||
'F99_UNIQUE_PAGE_ID="4494008035774726"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="28-JUN-2011"'||chr(10)||
'F99_LOCAL_TIME="18:15:12"'||chr(10)||
'F99_DB_OFFICE_CODE="26"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="39"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-98"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="4"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_UNIT_SYSTEM="EN"'||chr(10)||
'P805_DISPLAY_TZ="UTC"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="T"'||chr(10)||
'F99_LOGON_USER="G0NWDP"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="UTC"'||chr(10)||
'F99_DISPLAY_TZ="UTC"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_ADMIN_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''>(*Super "'||chr(10)||
'F99_ADMIN_FLAG_RIGHT=" </span>"'||chr(10)||
'F99_TMP5="G0NWDP:G0NWDP"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_SU"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS Super User"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.103"'||chr(10)||
'P1001_LOGON_INFO="Logon: NWDP:G0NWDP From:155.83.200.103 To:hec-cwms"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.06.28.17.40.51"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'F99_ROLE_FLAG_LEFT=" <span style=''font-size:10.0pt;color:red''> "'||chr(10)||
'F99_ROLE_FLAG_RIGHT=" </span>"'||chr(10)||
'P600_SCREEN_ID_LIST="%"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="782980.9833333333333333333333333333333326"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_SU"'||chr(10)||
'F99_TMP2="28-Jun-2011 17:40"'||chr(10)||
'F99_TMP3="27-Jun-2011 17:40"'||chr(10)||
'P1_MAP_MODE="ELI"'||chr(10)||
'P1_DISTRICT="All"'||chr(10)||
'P1_PARAMETER="Elev"'||chr(10)||
'P1_VERSION="DCP-raw"'||chr(10)||
'P1_DISTRICT_LAST="All"'||chr(10)||
'P1_CLICK_LOC="A Test"'||chr(10)||
'P1_TMP="P1_USER_ROLE"'||chr(10)||
'P1_STALE_AFTER_MINUTES="30"'||chr(10)||
'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'P1_SUBMIT_REQUEST="P1_USER_ROLE"'||chr(10)||
'F99_TMP0="P1_USER_ROLE"'||chr(10)||
'P600_DIRECTION="EX"'||chr(10)||
'P600_SELECT_DESIRED_EXPORT="LOCF"'||chr(10)||
'P600_SELECT_DESIRED_REPORT="LOCF"'||chr(10)||
'P600_SELECT_DESIRED_ACTION="EX_LOCF"'||chr(10)||
'P600_FILE_PREFIX="CWMS_LOCF."'||chr(10)||
'P600_FILE_EXTENSION=".csv"'||chr(10)||
'P600_COMBINED_FILTER="*"'||chr(10)||
'P600_LOC_FILTER_2="*"'||chr(10)||
'P102_FEEDBACK="Need sanctioned list of location site types, multi"'||chr(10)||
'P102_FEEDBACK_TYPE="1"'||chr(10)||
'P102_APPLICATION_ID="396"'||chr(10)||
'P102_PAGE_ID="35"'||chr(10)||
'F99_LOCATION_CODE="73772008"'||chr(10)||
'F99_MAP_CLICK="NO"'||chr(10)||
'P36_PAGE_PREVIOUS="35"'||chr(10)||
'P36_TS_COUNT="0"'||chr(10)||
'F99_LOCATION_ID="1122a"'||chr(10)||
'P36_SITE_IMAGE="rainbow.png"'||chr(10)||
'P36_LOCATION_ID_CREATE="1122a"'||chr(10)||
'P36_STATE_INITIAL="-UNK-"'||chr(10)||
'P36_VERTICAL_DATUM="-UNK-"'||chr(10)||
'P600_STATE_INITIAL="%"'||chr(10)||
'P600_ACTIVE="%"'||chr(10)||
'P36_HORIZONTAL_DATUM="-UNK-"'||chr(10)||
'P36_TIME_ZONE_NAME="-UNK-"'||chr(10)||
'P36_LOCATION_TYPE="-UNK-"'||chr(10)||
'P36_SESSION_UNIT_SYSTEM="EN"'||chr(10)||
'P36_SAVE_BUTTON_REQUEST="CREATE_LOCATION"'||chr(10)||
'P36_LOCATION_ID_EDIT="1122a"'||chr(10)||
'F99_TMP="In Create Loc -calling - called"'||chr(10)||
'F99_TMP1="1122a"'||chr(10)||
'P35_LOC_FILTER="*"'||chr(10)||
'P35_STATE_INITIAL="%"'||chr(10)||
'P35_ACTIVE="%"'||chr(10)||
'P35_LOC_TYPE="%"'||chr(10)||
'P35_CATEGORY="%"'||chr(10)||
'P35_GROUP="%"'||chr(10)||
''
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/5.0 (Windows NT 5.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1'
 ,p_remote_addr => '155.83.200.103'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'G0NWDP'
 ,p_created_on => to_timestamp_tz('20110628181612.355010000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'G0NWDP'
 ,p_updated_on => to_timestamp_tz('20110628181612.355024000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1604105742296864 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 6
 ,p_feedback_comment => 'I have tried to import a data feed file two times.One time with the same "SHEF Loc" in two line and the other time with the same "Location" in two line.In both case I have gooten the same type of error as below:'||chr(10)||
'"Alias (BRDM2) would reference multiple locations".'||chr(10)||
''||chr(10)||
'This could be appropriate when we have similar "SHEF Loc" (BRDM2)in different lines for different locations.But I think when the "SHEF Loc" are different and the "Locations"s are the same we should get another error.'
 ,p_feedback_type => 1
 ,p_application_id => 396
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 614
 ,p_page_name => 'Import Crit Feed (scv)'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110708193856','YYYYMMDDHH24MISS')
 ,p_session_id => '3798470024317824'
 ,p_apex_user => 'G4NWWDA'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.96'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=184A0F2154221682ACD34AD5302E30CB6D29A29F44C6B4E0EB45FDCEAF9ACBD2'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=11-JUL-11'
 ,p_session_state => 'P102_APPLICATION_ID="396"'||chr(10)||
'P102_PAGE_ID="614"'||chr(10)||
'P102_FEEDBACK="I have tried to import a data feed file two times."'||chr(10)||
'P102_FEEDBACK_TYPE="1"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'F99_PAGE_COUNT="33"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_PAGE_PREVIOUS="102"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_UNIQUE_PAGE_ID="4468231425970151"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="11-JUL-2011"'||chr(10)||
'F99_LOCAL_TIME="15:02:17"'||chr(10)||
'F99_DB_OFFICE_CODE="29"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="39"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-98"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="4"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_UNIT_SYSTEM="EN"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_LOGON_USER="G4NWWDA"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="801908.5666666666666666666666666666666666"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_DA"'||chr(10)||
'F99_TMP2="11-Jul-2011 21:08"'||chr(10)||
'F99_TMP3="396.799876547514270.614.3798470024317824.STORE_PAR"'||chr(10)||
'F99_ROLE_FLAG_LEFT=" <span style=''font-size:10.0pt;color:BB542B''> "'||chr(10)||
'F99_ROLE_FLAG_RIGHT=" </span>"'||chr(10)||
'P86_OLD_DATA_FEED_ID="DF_B"'||chr(10)||
'F99_ENTERING_PAGE_REQUEST="EDIT_DATA_FEED"'||chr(10)||
'P86_DATA_FEED_USAGE="15"'||chr(10)||
'P600_DIRECTION="EX"'||chr(10)||
'P600_SELECT_DESIRED_EXPORT="PSCFFEED"'||chr(10)||
'P600_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P600_SELECT_DESIRED_ACTION="EX_PSCFFEED"'||chr(10)||
'P600_FILE_PREFIX="CWMS_PSCFFEED."'||chr(10)||
'P600_FILE_EXTENSION=".csv"'||chr(10)||
'P600_COMBINED_FILTER="*"'||chr(10)||
'P600_DATA_FEED="DF_A"'||chr(10)||
'P601_DIRECTION="IM"'||chr(10)||
'P601_SELECT_DESIRED_ACTION="IM_PSCFFEED"'||chr(10)||
'P601_SELECT_DESIRED_IMPORT="PSCFFEED"'||chr(10)||
'P601_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P614_LAST_RECORD_CONTENT=">Store[1]:[2]:[3]:T[4]:[5]:[6]:RAYTW7[7]:TW[8]:RPZ"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="F"'||chr(10)||
'F99_TMP5="Unk:G4NWWDA"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_DA"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS DA User"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.115"'||chr(10)||
'P1001_LOGON_INFO="Logon: NWW:G4NWWDA From:155.83.200.115 To:hec-cwms"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.07.11.21.08.13"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'P1_MAP_MODE="ELI"'||chr(10)||
'P1_DISTRICT="All"'||chr(10)||
'P1_PARAMETER="Elev"'||chr(10)||
'P1_VERSION="DCP-raw"'||chr(10)||
'P1_DISTRICT_LAST="All"'||chr(10)||
'P1_CLICK_LOC="A Test"'||chr(10)||
'P1_TMP="P1_USER_ROLE"'||chr(10)||
'P1_STALE_AFTER_MINUTES="30"'||chr(10)||
'P1_SUBMIT_REQUEST="P1_USER_ROLE"'||chr(10)||
'F99_TMP0="CLEAR Clearing"'||chr(10)||
'P805_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P805_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_NUMBER_CHECKED="1"'||chr(10)||
'P0_UNIQUE_PROCESS_ID="396.799876547514270.614.3798470024317824.STORE_PAR"'||chr(10)||
'P0_PROCESS_NAME="STORE_PARSED_CRIT_CSV_FILE"'||chr(10)||
'P600_SCREEN_ID_LIST="%"'||chr(10)||
'P601_FILE_EXTENSION=".csv"'||chr(10)||
'P601_IS_A_CSV="T"'||chr(10)||
'P614_FILE_EXTENSION=".csv"'||chr(10)||
'P614_FILE_NAME_EXAMPLE="SampleFileName.csv"'||chr(10)||
'P614_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P614_COMMENT_LINES="1"'||chr(10)||
'P0_TEXT_DROP="Initiated"'||chr(10)||
'P0_ELAPSED="---"'||chr(10)||
'P0_ELAPSED_MIN="-1"'||chr(10)||
'P0_NUMBER_PROCESSED="0"'||chr(10)||
'P0_ITEMS_PER_MIN="---"'||chr(10)||
'P0_STEPS_PER_COMMIT="5"'||chr(10)||
'P0_EXE_PATH="1 2"'||chr(10)||
'P614_DF_CLEAR_MERGE="CLEAR"'||chr(10)||
'P614_UPDATE_ALLOWED="T"'||chr(10)||
'P614_DATA_FEED_ID="DF_B"'||chr(10)||
'P805_RT_CACHE_STALE_AFTER="30"'||chr(10)||
'P801_OLD_DATA_FEED_ID="DF_B"'||chr(10)||
' - more state exists'
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2; .NET4.0C)'
 ,p_remote_addr => '155.83.200.115'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'G4NWWDA'
 ,p_created_on => to_timestamp_tz('20110711220938.464111000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'G4NWWDA'
 ,p_updated_on => to_timestamp_tz('20110711220938.464125000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1613724000713499 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 7
 ,p_feedback_comment => 'Seems that if the numbers assigned for "TSE" and "Version" have less than three digits (0-99) parsing the data is ok ,but posting the data has the below error:'||chr(10)||
''||chr(10)||
'Pre-Store: ORA-20000: ERROR: SHEF TSE code - invalid - 0'||chr(10)||
'.'||chr(10)||
'.'||chr(10)||
'.'||chr(10)||
'Pre-Store: ORA-20000: ERROR: SHEF TSE code - invalid - 99'||chr(10)||
''
 ,p_feedback_type => 1
 ,p_application_id => 396
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 614
 ,p_page_name => 'Import Crit Feed (scv)'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110708193856','YYYYMMDDHH24MISS')
 ,p_session_id => '638333399813844'
 ,p_apex_user => 'G4NWWDA'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.96'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=53D609E0753FFF3FD2030ACC113B879932E2019B1AC226E98DDD61AE629E5BBE'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=12-JUL-11'
 ,p_session_state => 'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_DB_OFFICE_CODE="29"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'F99_PAGE_COUNT="16"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_PAGE_PREVIOUS="614"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="39"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-98"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="4"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_UNIT_SYSTEM="EN"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_LOGON_USER="G4NWWDA"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="F"'||chr(10)||
'F99_TMP5="Unk:G4NWWDA"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_DA"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS DA User"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.115"'||chr(10)||
'P1001_LOGON_INFO="Logon: NWW:G4NWWDA From:155.83.200.115 To:hec-cwms"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.07.12.18.25.43"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'P1_MAP_MODE="ELI"'||chr(10)||
'P1_DISTRICT="All"'||chr(10)||
'P1_PARAMETER="Elev"'||chr(10)||
'P1_VERSION="DCP-raw"'||chr(10)||
'P1_DISTRICT_LAST="All"'||chr(10)||
'P1_CLICK_LOC="A Test"'||chr(10)||
'P1_TMP="P1_USER_ROLE"'||chr(10)||
'P1_STALE_AFTER_MINUTES="30"'||chr(10)||
'P1_SUBMIT_REQUEST="P1_USER_ROLE"'||chr(10)||
'F99_TMP0="CLEAR Clearing"'||chr(10)||
'P0_UNIQUE_PROCESS_ID="396.4252373690830131.614.638333399813844.STORE_PAR"'||chr(10)||
'P0_PROCESS_NAME="STORE_PARSED_CRIT_CSV_FILE"'||chr(10)||
'P600_SCREEN_ID_LIST="%"'||chr(10)||
'P600_DIRECTION="EX"'||chr(10)||
'P600_SELECT_DESIRED_ACTION="EX_"'||chr(10)||
'P600_FILE_EXTENSION=".csv"'||chr(10)||
'P600_COMBINED_FILTER="*"'||chr(10)||
'P614_FILE_EXTENSION=".csv"'||chr(10)||
'P614_FILE_NAME_EXAMPLE="SampleFileName.csv"'||chr(10)||
'P614_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P614_COMMENT_LINES="1"'||chr(10)||
'P0_TEXT_DROP="Processing: 1000 of 1001"'||chr(10)||
'P0_ELAPSED="---"'||chr(10)||
'P0_ELAPSED_MIN="-1"'||chr(10)||
'P0_NUMBER_PROCESSED="0"'||chr(10)||
'P0_ITEMS_PER_MIN="---"'||chr(10)||
'P0_STEPS_PER_COMMIT="5"'||chr(10)||
'P0_EXE_PATH="1 2"'||chr(10)||
'P614_DF_CLEAR_MERGE="CLEAR"'||chr(10)||
'P614_UPDATE_ALLOWED="T"'||chr(10)||
'P614_DATA_FEED_ID="DF_B"'||chr(10)||
'P614_ALIAS_GROUP="SHEF Location ID"'||chr(10)||
'P614_TOTAL_LINES_READ="1001"'||chr(10)||
'P614_TOTAL_COLUMNS="23"'||chr(10)||
'P614_PARSE_ERRORS="0"'||chr(10)||
'P614_PARSED_LINES="1000"'||chr(10)||
'P614_IS_A_CSV="T"'||chr(10)||
'F99_TMP="31"'||chr(10)||
'P614_HEADINGS="SpecAction:IgnoreSHEFSpec:NetActiveStatus:TimeSeri"'||chr(10)||
'P614_COLUMNS="c001,c002,c003,c004,c005,c006,c007,c008,c009,c010,"'||chr(10)||
'P614_LAST_RECORD_CONTENT=">Ignore[1]:[2]:[3]:T[4]:[5]:[6]:BLMP1[7]:PP[8]:999"'||chr(10)||
'P102_FEEDBACK="Seems that if the numbers assigned for "TSE" and ""'||chr(10)||
'P102_FEEDBACK_TYPE="1"'||chr(10)||
'P614_STORE_DB_STORED="901"'||chr(10)||
'P614_STORE_DB_REJECTED="100"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="803185.9166666666666666666666666666666664"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_DA"'||chr(10)||
'F99_TMP2="12-Jul-2011 18:25"'||chr(10)||
'F99_TMP3="396.1380965660724062.614.638333399813844.PARSE_CRI"'||chr(10)||
'F99_ROLE_FLAG_LEFT=" <span style=''font-size:10.0pt;color:BB542B''> "'||chr(10)||
'F99_ROLE_FLAG_RIGHT=" </span>"'||chr(10)||
'F99_UNIQUE_PAGE_ID="4448680730487418"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="12-JUL-2011"'||chr(10)||
'F99_LOCAL_TIME="11:41:18"'||chr(10)||
'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'P601_FILE_EXTENSION=".csv"'||chr(10)||
'P601_IS_A_CSV="T"'||chr(10)||
'P601_DIRECTION="IM"'||chr(10)||
'P601_SELECT_DESIRED_ACTION="IM_PSCFFEED"'||chr(10)||
'P601_SELECT_DESIRED_IMPORT="PSCFFEED"'||chr(10)||
'P601_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P102_APPLICATION_ID="396"'||chr(10)||
'P102_PAGE_ID="614"'||chr(10)||
''
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2; .NET4.0C)'
 ,p_remote_addr => '155.83.200.115'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'G4NWWDA'
 ,p_created_on => to_timestamp_tz('20110712184545.671408000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'G4NWWDA'
 ,p_updated_on => to_timestamp_tz('20110712184545.671422000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1618628464462281 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 8
 ,p_feedback_comment => 'Parsing and Posting data are both work great with the numbers from 1 to 999 assigned to "SHEF Loc" and "Location".'
 ,p_feedback_type => 1
 ,p_application_id => 396
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 614
 ,p_page_name => 'Import Crit Feed (scv)'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110708193856','YYYYMMDDHH24MISS')
 ,p_session_id => '2436398232204325'
 ,p_apex_user => 'G4NWWDA'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.96'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=9824553E093B57E357237F90F8AC137699E633A9AE663026162BCBA4F7A1411A'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=12-JUL-11'
 ,p_session_state => 'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="803293.7333333333333333333333333333333328"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_DA"'||chr(10)||
'F99_TMP2="12-Jul-2011 20:13"'||chr(10)||
'F99_TMP3="396.3402728502147795.614.2436398232204325.PARSE_CR"'||chr(10)||
'P1_MAP_MODE="ELI"'||chr(10)||
'P1_DISTRICT="All"'||chr(10)||
'P1_PARAMETER="Elev"'||chr(10)||
'P1_VERSION="DCP-raw"'||chr(10)||
'P1_DISTRICT_LAST="All"'||chr(10)||
'P1_CLICK_LOC="A Test"'||chr(10)||
'P1_TMP="P1_USER_ROLE"'||chr(10)||
'P1_STALE_AFTER_MINUTES="30"'||chr(10)||
'P1_SUBMIT_REQUEST="P1_USER_ROLE"'||chr(10)||
'F99_TMP0="CLEAR Clearing"'||chr(10)||
'P614_FILE_EXTENSION=".csv"'||chr(10)||
'P614_FILE_NAME_EXAMPLE="SampleFileName.csv"'||chr(10)||
'P614_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P614_COMMENT_LINES="1"'||chr(10)||
'P0_TEXT_DROP="Processing: 1000 of 1000"'||chr(10)||
'P0_ELAPSED="---"'||chr(10)||
'P0_ELAPSED_MIN="-1"'||chr(10)||
'P0_NUMBER_PROCESSED="0"'||chr(10)||
'P0_ITEMS_PER_MIN="---"'||chr(10)||
'P0_STEPS_PER_COMMIT="5"'||chr(10)||
'P0_EXE_PATH="1 2"'||chr(10)||
'P614_DF_CLEAR_MERGE="CLEAR"'||chr(10)||
'P614_UPDATE_ALLOWED="T"'||chr(10)||
'P614_DATA_FEED_ID="DF_B"'||chr(10)||
'P614_ALIAS_GROUP="SHEF Location ID"'||chr(10)||
'P614_TOTAL_LINES_READ="1000"'||chr(10)||
'P614_TOTAL_COLUMNS="23"'||chr(10)||
'P614_PARSE_ERRORS="0"'||chr(10)||
'P614_PARSED_LINES="999"'||chr(10)||
'P614_IS_A_CSV="T"'||chr(10)||
'F99_TMP="31"'||chr(10)||
'P614_HEADINGS="SpecAction:IgnoreSHEFSpec:NetActiveStatus:TimeSeri"'||chr(10)||
'P614_COLUMNS="c001,c002,c003,c004,c005,c006,c007,c008,c009,c010,"'||chr(10)||
'P614_LAST_RECORD_CONTENT=">Ignore[1]:[2]:[3]:T[4]:[5]:[6]:999[7]:PP[8]:RRZ[9"'||chr(10)||
'P614_STORE_DB_STORED="1000"'||chr(10)||
'P614_STORE_DB_REJECTED="0"'||chr(10)||
'P102_APPLICATION_ID="396"'||chr(10)||
'P102_PAGE_ID="614"'||chr(10)||
'P102_FEEDBACK="Parsing and Posting data are both work great with "'||chr(10)||
'P102_FEEDBACK_TYPE="1"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'F99_PAGE_COUNT="21"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_PAGE_PREVIOUS="614"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_UNIQUE_PAGE_ID="3400852176959071"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="12-JUL-2011"'||chr(10)||
'F99_LOCAL_TIME="13:49:11"'||chr(10)||
'F99_DB_OFFICE_CODE="29"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="39"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-98"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="4"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_UNIT_SYSTEM="EN"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_LOGON_USER="G4NWWDA"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="F"'||chr(10)||
'F99_TMP5="Unk:G4NWWDA"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_DA"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS DA User"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.115"'||chr(10)||
'P1001_LOGON_INFO="Logon: NWW:G4NWWDA From:155.83.200.115 To:hec-cwms"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.07.12.20.13.33"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'F99_ROLE_FLAG_LEFT=" <span style=''font-size:10.0pt;color:BB542B''> "'||chr(10)||
'F99_ROLE_FLAG_RIGHT=" </span>"'||chr(10)||
'P0_UNIQUE_PROCESS_ID="396.495671774338529.614.2436398232204325.STORE_PAR"'||chr(10)||
'P0_PROCESS_NAME="STORE_PARSED_CRIT_CSV_FILE"'||chr(10)||
'P600_SCREEN_ID_LIST="%"'||chr(10)||
'P600_DIRECTION="EX"'||chr(10)||
'P600_SELECT_DESIRED_EXPORT="PSCFFEED"'||chr(10)||
'P600_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P600_SELECT_DESIRED_ACTION="EX_PSCFFEED"'||chr(10)||
'P600_FILE_PREFIX="CWMS_PSCFFEED."'||chr(10)||
'P600_FILE_EXTENSION=".csv"'||chr(10)||
'P600_COMBINED_FILTER="*"'||chr(10)||
'P601_FILE_EXTENSION=".csv"'||chr(10)||
'P601_IS_A_CSV="T"'||chr(10)||
'P601_DIRECTION="IM"'||chr(10)||
'P601_SELECT_DESIRED_ACTION="IM_PSCFFEED"'||chr(10)||
' - more state exists'
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2; .NET4.0C)'
 ,p_remote_addr => '155.83.200.115'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'G4NWWDA'
 ,p_created_on => to_timestamp_tz('20110712205033.543528000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'G4NWWDA'
 ,p_updated_on => to_timestamp_tz('20110712205033.543544000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
wwv_flow_team_api.create_feedback (
  p_id => 1619412543533361 + wwv_flow_team_api.g_id_offset
 ,p_feedback_id => 9
 ,p_feedback_comment => 'Assigning  number "1000" to "TSE" and "Version" creates an error in parsing data,but for "SHEF Loc" and "Location" it works with out any problem both in  parsing and posting data.'
 ,p_feedback_type => 1
 ,p_application_id => 396
 ,p_application_name => 'CWMS Management Application (CMA)'
 ,p_page_id => 614
 ,p_page_name => 'Import Crit Feed (scv)'
 ,p_page_last_updated_by => 'ART'
 ,p_page_last_updated_on => to_date('20110708193856','YYYYMMDDHH24MISS')
 ,p_session_id => '2436398232204325'
 ,p_apex_user => 'G4NWWDA'
 ,p_user_email => 'unknown'
 ,p_application_version => 'release 3.96'
 ,p_session_info => 'security_group_id=1279909380548202'||chr(10)||
'expires_on='||chr(10)||
'ip_address=9824553E093B57E357237F90F8AC137699E633A9AE663026162BCBA4F7A1411A'||chr(10)||
'session_id='||chr(10)||
'created_by=ANONYMOUS'||chr(10)||
'created_on=12-JUL-11'
 ,p_session_state => 'F99_ERR_MSG_CONTROL="CLEARED"'||chr(10)||
'F99_PAGE_LEAVING="102"'||chr(10)||
'P1_STATE_INITIAL="%"'||chr(10)||
'P1_COUNTY_NAME="%"'||chr(10)||
'P1_LOC_TYPE="%"'||chr(10)||
'P1_ACTIVE="%"'||chr(10)||
'P1_NOW_2010="803293.7333333333333333333333333333333328"'||chr(10)||
'P1_REFRESH_TABLE="N"'||chr(10)||
'P1_USER_ROLE="CWMS_DA"'||chr(10)||
'F99_TMP2="12-Jul-2011 20:13"'||chr(10)||
'F99_TMP3="396.2222421000404316.614.2436398232204325.PARSE_CR"'||chr(10)||
'P1_MAP_MODE="ELI"'||chr(10)||
'P1_DISTRICT="All"'||chr(10)||
'P1_PARAMETER="Elev"'||chr(10)||
'P1_VERSION="DCP-raw"'||chr(10)||
'P1_DISTRICT_LAST="All"'||chr(10)||
'P1_CLICK_LOC="A Test"'||chr(10)||
'P1_TMP="P1_USER_ROLE"'||chr(10)||
'P1_STALE_AFTER_MINUTES="30"'||chr(10)||
'P1_SUBMIT_REQUEST="P1_USER_ROLE"'||chr(10)||
'F99_TMP0="CLEAR Clearing"'||chr(10)||
'P614_FILE_EXTENSION=".csv"'||chr(10)||
'P614_FILE_NAME_EXAMPLE="SampleFileName.csv"'||chr(10)||
'P614_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P614_COMMENT_LINES="1"'||chr(10)||
'P0_TEXT_DROP="Completed 1000 records"'||chr(10)||
'P0_ELAPSED="00:24"'||chr(10)||
'P0_ELAPSED_MIN=".4"'||chr(10)||
'P0_NUMBER_PROCESSED="1000"'||chr(10)||
'P0_ITEMS_PER_MIN="2500"'||chr(10)||
'P0_STEPS_PER_COMMIT="5"'||chr(10)||
'P0_EXE_PATH="1 2"'||chr(10)||
'P614_FILE_SELECTION="F17215/CWMS_PSCFFEED.DF_NWW_B1.csv"'||chr(10)||
'P614_FILE_SELECTION_SAVE="F17215/CWMS_PSCFFEED.DF_NWW_B1.csv"'||chr(10)||
'P614_DF_CLEAR_MERGE="CLEAR"'||chr(10)||
'P614_UPDATE_ALLOWED="T"'||chr(10)||
'P614_DATA_FEED_ID="DF_B"'||chr(10)||
'P614_ALIAS_GROUP="SHEF Location ID"'||chr(10)||
'P614_TOTAL_LINES_READ="902"'||chr(10)||
'P614_TOTAL_COLUMNS="23"'||chr(10)||
'P614_PARSE_ERRORS="1"'||chr(10)||
'P614_PARSED_LINES="900"'||chr(10)||
'P614_IS_A_CSV="T"'||chr(10)||
'F99_TMP="31"'||chr(10)||
'P614_HEADINGS="SpecAction:IgnoreSHEFSpec:NetActiveStatus:TimeSeri"'||chr(10)||
'P614_COLUMNS="c001,c002,c003,c004,c005,c006,c007,c008,c009,c010,"'||chr(10)||
'P614_LAST_RECORD_CONTENT=">Ignore[1]:[2]:[3]:T[4]:[5]:[6]:BLMP1[7]:PP[8]:100"'||chr(10)||
'P614_STORE_DB_STORED="1001"'||chr(10)||
'P614_STORE_DB_REJECTED="0"'||chr(10)||
'P102_APPLICATION_ID="396"'||chr(10)||
'P102_PAGE_ID="614"'||chr(10)||
'P102_FEEDBACK="Assigning  number "1000" to "TSE" and "Version" cr"'||chr(10)||
'P102_FEEDBACK_TYPE="1"'||chr(10)||
'F99_APP_EGIS="T"'||chr(10)||
'F99_PAGE_COUNT="25"'||chr(10)||
'P411_NUM_EDITTED_CRIT_RECORDS="0"'||chr(10)||
'F99_PAGE_PREVIOUS="614"'||chr(10)||
'APP_LOGIC_YES="T"'||chr(10)||
'APP_LOGIC_NO="F"'||chr(10)||
'APP_PAGE_TITLE_PREFIX="CWMS eGIS Metadata "'||chr(10)||
'APP_SAVE_TEXT="Save"'||chr(10)||
'APP_CANCEL_TEXT="Cancel"'||chr(10)||
'APP_PAGE_15_INSTRUCTIONS="Follow the Region Titles for Instructions to uploa"'||chr(10)||
'F99_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_LOGON_DB_OFFICE_ID="NWW"'||chr(10)||
'F99_UNIQUE_PAGE_ID="2472915084786011"'||chr(10)||
'F99_STATUS_LIGHT="<script language="javascript">'||chr(10)||
'var grn = ''bullet_"'||chr(10)||
'F99_PAGE_CURRENT="102"'||chr(10)||
'F99_LOCAL_DATE="12-JUL-2011"'||chr(10)||
'F99_LOCAL_TIME="13:58:50"'||chr(10)||
'F99_DB_OFFICE_CODE="29"'||chr(10)||
'P1001_EMAIL_AT_LOGON="N"'||chr(10)||
'F99_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P805_DATA_STREAM_MGT_STYLE="DATA FEEDS"'||chr(10)||
'P804_EAST_MOST_LONGITUDE="180"'||chr(10)||
'P804_WEST_MOST_LONGITUDE="-180"'||chr(10)||
'P804_NORTH_MOST_LATITUDE="90"'||chr(10)||
'P804_SOUTH_MOST_LATITUDE="-90"'||chr(10)||
'F99_MAP_CENTER_LAT="39"'||chr(10)||
'P1_MAP_CENTER_LAT="39"'||chr(10)||
'F99_MAP_CENTER_LNG="-98"'||chr(10)||
'P1_MAP_CENTER_LNG="-98"'||chr(10)||
'F99_MAP_ZOOM_LEVEL="4"'||chr(10)||
'P1_MAP_ZOOM_LEVEL="4"'||chr(10)||
'F99_LOCALE="US"'||chr(10)||
'F99_ADMIN_USER="N"'||chr(10)||
'P805_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P805_UNIT_SYSTEM="EN"'||chr(10)||
'P805_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P805_WANT_INFO="Y"'||chr(10)||
'F99_LOGON_USER="G4NWWDA"'||chr(10)||
'F99_TS_FILTER_CHOICE="EF"'||chr(10)||
'F99_TS_FILTER_REPORT_STYLE="COL_ID"'||chr(10)||
'P6_LAT_LONG_FORMAT="D.D"'||chr(10)||
'F99_LAT_LONG_FORMAT="D.D"'||chr(10)||
'P6_UNIT_SYSTEM="EN"'||chr(10)||
'F99_UNIT_SYSTEM="EN"'||chr(10)||
'P6_DISPLAY_TZ="US/Pacific"'||chr(10)||
'F99_DISPLAY_TZ="US/Pacific"'||chr(10)||
'P6_WANT_INFO="Y"'||chr(10)||
'F99_SHEF_CLOB_UPDATE_NEEDED="F"'||chr(10)||
'F99_TMP5="Unk:G4NWWDA"'||chr(10)||
'F99_APEX_ROLE_RETURN_ID="CWMS_DA"'||chr(10)||
'F99_APEX_ROLE_DISPLAY_ID="CWMS DA User"'||chr(10)||
'P1001_SHOW_MAPS="TRUE"'||chr(10)||
'P1001_URL="hec-cwmsdb2.hec.usace.army.mil:8080"'||chr(10)||
'P1001_USER_IP="155.83.200.115"'||chr(10)||
'P1001_LOGON_INFO="Logon: NWW:G4NWWDA From:155.83.200.115 To:hec-cwms"'||chr(10)||
'F99_LOGON_DATE_TIME="2011.07.12.20.13.33"'||chr(10)||
'P6_LOC_DISPLAY_SUBS="LID"'||chr(10)||
'F99_ROLE_FLAG_LEFT=" <span style=''font-size:10.0pt;color:BB542B''> "'||chr(10)||
'F99_ROLE_FLAG_RIGHT=" </span>"'||chr(10)||
'P0_UNIQUE_PROCESS_ID="396.2222421000404316.614.2436398232204325.PARSE_CR"'||chr(10)||
'P0_PROCESS_NAME="PARSE_CRIT_CSV_FILE"'||chr(10)||
'P600_SCREEN_ID_LIST="%"'||chr(10)||
'P600_DIRECTION="EX"'||chr(10)||
'P600_SELECT_DESIRED_EXPORT="PSCFFEED"'||chr(10)||
'P600_SELECT_DESIRED_REPORT="PSCFFEED"'||chr(10)||
'P600_SELECT_DESIRED_ACTION="EX_PSCFFEED"'||chr(10)||
'P600_FILE_PREFIX="CWMS_PSCFFEED."'||chr(10)||
'P600_FILE_EXTENSION=".csv"'||chr(10)||
' - more state exists'
 ,p_parsing_schema => 'CWMS_20'
 ,p_http_user_agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2; .NET4.0C)'
 ,p_remote_addr => '155.83.200.115'
 ,p_remote_user => 'ANONYMOUS'
 ,p_server_name => 'XDB HTTP Server'
 ,p_server_port => '8080'
 ,p_logging_security_group_id => 1279909380548202
 ,p_logged_by_workspace_name => 'CWMSAPEX'
 ,p_created_by => 'G4NWWDA'
 ,p_created_on => to_timestamp_tz('20110712210224.361470000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
 ,p_updated_by => 'G4NWWDA'
 ,p_updated_on => to_timestamp_tz('20110712210224.361485000 +00:00 ','YYYYMMDDHH24MISSxFF TZR TZD')
);
end;
/
--
prompt ...task defaults
--
begin
null;
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

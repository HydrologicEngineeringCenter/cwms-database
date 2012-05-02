Rem  Copyright (c) Oracle Corporation 1999 - 2006. All Rights Reserved.
Rem
Rem    NAME
Rem      apxconf.sql
Rem
Rem    DESCRIPTION
Rem      Used to perform the final configuration steps for Oracle Application Express,
Rem      including setting the XDB HTTP listener port and Application Express ADMIN password.
Rem
Rem    NOTES
Rem      Assumes the SYS user is connected.
Rem
Rem    REQUIREMENTS
Rem      - Oracle 11g
Rem
Rem
Rem    MODIFIED   (MM/DD/YYYY)
Rem      jstraub   11/02/2006 - Created
Rem      jstraub   01/19/2007 - Moved setting allow-repository-anonymous-access from apex_epg_config.sql
Rem      jstraub   02/22/2007 - Removed setting allow-repository-anonymous-access, no longer needed because of /i/ servlet
Rem      jkallman  08/02/2007 - Change FLOWS_030000 references to FLOWS_030100
Rem      jstraub   09/04/2007 - Added HIDE to PASSWD accept (Bug 6370075)
Rem      jkallman  09/09/2008 - Change FLOWS_030100 references to APEX_030200
Rem      apabst    05/02/2012 - Change FLOWS_030200 references to APEX_040000
Rem

set define '&'

set verify off

column port new_val HTTPPORT

select decode(dbms_xdb.gethttpport,0,8080,dbms_xdb.gethttpport) port from dual;

prompt Enter values below for the XDB HTTP listener port and the password for the Application Express ADMIN user.
prompt Default values are in brackets [ ].
prompt Press Enter to accept the default value.
prompt
prompt

accept PASSWD CHAR prompt 'Enter a password for the ADMIN user              [] ' HIDE

accept HTTPPORT CHAR default &HTTPPORT prompt 'Enter a port for the XDB HTTP listener [&HTTPPORT] '

prompt ...changing HTTP Port

whenever sqlerror exit

begin
    if nvl(length('&PASSWD'),0) = 0 then
        raise_application_error(-20001,'Invalid password');
    end if;
end;
/

set serveroutput on
declare
    l_port  number;
begin
    l_port := to_number('&HTTPPORT');
    dbms_xdb.sethttpport(l_port);
exception when others then
    dbms_output.put_line('***********************************');
    dbms_output.put_line('* Invalid port number...          *');
    dbms_output.put_line('***********************************');
    raise;
end;
/

alter session set current_schema = APEX_040000;

prompt ...changing password for ADMIN

begin

    wwv_flow_security.g_security_group_id := 10;
    wwv_flow_security.g_user := 'ADMIN';
    wwv_flow_security.g_import_in_progress := true;

    for c1 in (select user_id
                 from wwv_flow_fnd_user
                where security_group_id = wwv_flow_security.g_security_group_id
                  and user_name = wwv_flow_security.g_user) loop

        wwv_flow_fnd_user_api.edit_fnd_user(
            p_user_id       => c1.user_id,
            p_user_name     => wwv_flow_security.g_user,
            p_web_password  => '&PASSWD',
            p_new_password  => '&PASSWD');
    end loop;

    wwv_flow_security.g_import_in_progress := false;

end;
/
commit;

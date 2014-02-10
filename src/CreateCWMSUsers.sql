set time on
set echo off
set define on
set serveroutput on
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept cwms_schema  char prompt 'Enter cwms schema name    : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
set echo &echo_state

spool CreateCWMSUsers.log
--
-- log on as sysdba
--
whenever sqlerror exit sql.sqlcode
connect sys/&sys_passwd@&inst as sysdba

declare
    group_id varchar(64);
    office_id varchar(32);
    group_id_list "&cwms_schema".char_32_array_type;
begin
    for rec in (select at.username,user_db_office_code from "&cwms_schema".at_sec_user_office at, all_users au where at.username=au.username order by username )
    loop
        group_id_list := "&cwms_schema".char_32_array_type();
        select office_id into office_id from "&cwms_schema".cwms_office where office_code = rec.user_db_office_code;
        dbms_output.put_line('Creating ' || rec.username);
       "&cwms_schema".CWMS_SEC.CREATE_USER(rec.username,null,group_id_list,office_id);
    end loop;
    commit;
end;
/
exit 0

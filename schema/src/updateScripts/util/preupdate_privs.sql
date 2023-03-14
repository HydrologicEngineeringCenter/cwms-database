whenever sqlerror continue;
drop table preupgrade_tab_privs;
whenever sqlerror exit;

create table preupgrade_tab_privs as SELECT grantee, table_name, privilege
              FROM dba_tab_privs
             WHERE     owner = '&cwms_schema'
                   AND grantee NOT IN ('CWMS_USER', 'PUBLIC');

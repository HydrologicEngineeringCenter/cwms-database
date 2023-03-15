DECLARE
    l_cmd   VARCHAR (1024);
BEGIN
    FOR c
        IN (SELECT distinct grantee, table_name, privilege
              FROM preupgrade_tab_privs p, dba_objects o
             WHERE     o.OBJECT_NAME=p.TABLE_NAME and o.OWNER='&cwms_schema'
                   AND grantee NOT IN ('CWMS_USER', 'PUBLIC'))
    LOOP
        l_cmd := 'grant ' || c.privilege || ' on ' || c.table_name || ' to ' || c.grantee;
        DBMS_OUTPUT.put_line (l_cmd);

        EXECUTE IMMEDIATE l_cmd;
    END LOOP;
END;
/
drop table preupgrade_tab_privs;

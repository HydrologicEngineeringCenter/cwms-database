    
begin
    for l_table in (select * from dba_tables where owner='&CWMS_SCHEMA' and 
    (table_name like 'AT_%' or table_name like 'CWMS_%')) loop
        --dbms_output.put_line('granting on table ' || l_table.table_name);
        execute immediate 'grant select on &CWMS_SCHEMA..' || l_table.table_name || ' to web_user';
    end loop;
end;
/

grant execute on cwms_20.cwms_env to web_user;
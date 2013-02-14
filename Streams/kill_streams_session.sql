declare
    cursor c is select sid,serial# from v$session where username = '&streams_user';
    kill_command varchar2(128);
begin

    dbms_output.put_line('Kill current schema sessions');
    for rec in c
    loop
        kill_command := 'alter system kill session '''||rec.sid||','||rec.serial#||'''';
        dbms_output.put_line(kill_command);
        execute immediate kill_command;
    end loop;
end;
/

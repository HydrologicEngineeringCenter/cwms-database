set serveroutput on
call dbms_java.set_output(2000);
exec test_ts.checkstore;
/

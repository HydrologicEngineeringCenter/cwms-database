set serveroutput on
call dbms_java.set_output(2000);
exec ncomp_test.ncomp_demo;
/
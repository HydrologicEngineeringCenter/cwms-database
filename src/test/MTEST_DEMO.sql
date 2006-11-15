set serveroutput on
call dbms_java.set_output(2000);
alter session set timed_statistics=true;
alter session set events '10046 trace name context forever, level 12';
exec cwms.mtest.mtest_demo('HQ',0,'MergeTest.Flow.Inst.1Hour.0.Test123');

/

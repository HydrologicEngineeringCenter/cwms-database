select * from cwms_heartbeat order by source_db;
select * from cwms_heartbeat@u4cwmsp1 order by source_db;
select * from v$streams_capture;
select * from v$streams_capture@h4cwmsp2;
select * from v$streams_capture@b5cwmsp1;
select * from v$streams_capture@k7cwmsp1;
select * from v$streams_capture@k3cwmsp1;
select * from v$streams_capture@k5cwmsp1;
select * from v$streams_capture@m3cwmsp1;
select * from v$streams_capture@m4cwmsp1;
select * from v$streams_capture@m5cwmsp1;
select * from v$streams_capture@l4cwmsp1;
select * from dba_capture;
select * from dba_capture@b5cwmsp1;
select * from dba_capture@h4cwmsp2;
select * from dba_capture@k7cwmsp1;
select * from dba_capture@k3cwmsp1;
select * from dba_capture@l4cwmsp1;
exec DBMS_CAPTURE_ADM.START_CAPTURE('CWMS_STR_CP_U4CWMSP2');
exec DBMS_CAPTURE_ADM.STOP_CAPTURE@b5cwmsp1('CWMS_STR_CP_b5CWMSP1');
exec DBMS_CAPTURE_ADM.START_CAPTURE@b5cwmsp1('CWMS_STR_CP_b5CWMSP1');
exec DBMS_CAPTURE_ADM.STOP_CAPTURE@l4cwmsp1('CWMS_STR_CP_L4CWMSP1');
exec DBMS_CAPTURE_ADM.START_CAPTURE@l4cwmsp1('CWMS_STR_CP_L4CWMSP1');
exec DBMS_CAPTURE_ADM.STOP_CAPTURE@h4cwmsp2('CWMS_STR_CP_H4CWMSP2');
exec DBMS_CAPTURE_ADM.START_CAPTURE@h4cwmsp2('CWMS_STR_CP_H4CWMSP2');
exec DBMS_CAPTURE_ADM.START_CAPTURE@k7cwmsp1('CWMS_STR_CP_K7CWMSP1');
exec DBMS_CAPTURE_ADM.STOP_CAPTURE@l4cwmsp1('CWMS_STR_CP_L4CWMSP1');
exec DBMS_CAPTURE_ADM.START_CAPTURE@k7cwmsp1('CWMS_STR_CP_k7CWMSP1');
exec DBMS_CAPTURE_ADM.START_CAPTURE@k3cwmsp1('CWMS_STR_CP_k3CWMSP1');
exec DBMS_CAPTURE_ADM.STOP_CAPTURE@k7cwmsp1('CWMS_STR_CP_k7CWMSP1');
exec DBMS_CAPTURE_ADM.START_CAPTURE@m3cwmsp1('CWMS_STR_CP_m3CWMSP1');
exec DBMS_CAPTURE_ADM.STOP_CAPTURE@m3cwmsp1('CWMS_STR_CP_m3CWMSP1');
exec DBMS_CAPTURE_ADM.START_CAPTURE@m4cwmsp1('CWMS_STR_CP_m4CWMSP1');
exec DBMS_CAPTURE_ADM.STOP_CAPTURE@m4cwmsp1('CWMS_STR_CP_m4CWMSP1');
select * from dba_apply;
select * from dba_apply@u4cwmsp1;

exec DBMS_APPLY_ADM.START_APPLY('CWMS_STR_AP_H4CWMSP2');
exec DBMS_APPLY_ADM.START_APPLY('CWMS_STR_AP_B5CWMSP1');
exec DBMS_APPLY_ADM.START_APPLY@u4cwmsp1('CWMS_STR_AP_U4CWMSP2');
select * from dba_apply@u4cwmsp1;
select * from dba_propagation;
select * from dba_propagation@h4cwmsp2;
select * from V$STREAMS_APPLY_READER ;
select * from V$STREAMS_APPLY_READER@u4cwmsp1;
SELECT * FROM dba_scheduler_jobs@h4cwmsp2 where owner = 'CWMS_STR_ADM';
SELECT * FROM dba_scheduler_jobs@b5cwmsp1 where owner = 'CWMS_STR_ADM';
SELECT * FROM dba_scheduler_jobs@k7cwmsp1 where owner = 'CWMS_STR_ADM';
SELECT * FROM dba_scheduler_jobs@k5cwmsp1 where owner = 'CWMS_STR_ADM';
SELECT * FROM dba_scheduler_jobs@l4cwmsp1 where owner = 'CWMS_STR_ADM';
SELECT * FROM dba_scheduler_jobs@m3cwmsp1 where owner = 'CWMS_STR_ADM';
SELECT * FROM dba_scheduler_jobs@m4cwmsp1 where owner = 'CWMS_STR_ADM';
SELECT * FROM dba_scheduler_jobs where owner = 'CWMS_STR_ADM';
exec UTIL.START_RESET_SCN_JOB@h4cwmsp2;
exec UTIL.START_RESET_SCN_JOB@b5cwmsp1;
exec UTIL.START_RESET_SCN_JOB@k3cwmsp1;
select * from dba_scheduler_job_run_details@k3cwmsp1 where job_name like '%SCN%';

exec UTIL.START_STREAMS@l4cwmsp1('L4CWMSP1','U4CWMSP2')
exec UTIL.START_STREAMS@l1cwmsp2('L1CWMSP2','U4CWMSP2')
exec UTIL.START_RESET_SCN_JOB@k7cwmsp1;
select * from dba_apply_progress;
select * from v$streams_pool_advice;
select * from V$BUFFERED_QUEUES;
exec dbms_propagation_adm.stop_propagation@h4cwmsp2('CWMS_STR_PP_H4CMWSP2')
exec dbms_propagation_adm.start_propagation@h4cwmsp2('CWMS_STR_PP_H4CMWSP2')
select * from errorlog order by logdate asc;
select * from dba_apply_error;
select count(*) from errorlog

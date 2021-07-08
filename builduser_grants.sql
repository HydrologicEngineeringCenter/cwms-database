define builduser=&1
drop user &builduser;
create user &builduser identified by "&2";

grant dba to &builduser;

grant select on dba_scheduler_jobs to &builduser with grant option;
grant select on dba_scheduler_job_log to &builduser with grant option;
grant select on dba_scheduler_job_run_details to &builduser with grant option;

grant execute on dbms_crypto to &builduser with grant option;
grant execute on dbms_aq to &builduser with grant option;
grant execute on dbms_aq_bqview to &builduser with grant option;
grant execute on dbms_aqadm to &builduser with grant option;
grant execute on dbms_lock to &builduser with grant option;
grant execute on dbms_rls to &builduser with grant option;
grant execute on dbms_lob to &builduser with grant option;
grant execute on dbms_random to &builduser with grant option;
grant execute on utl_smtp to &builduser with grant option;
grant execute on utl_http to &builduser with grant option;
grant execute on utl_recomp to &builduser with grant option;
grant select on sys.v_$latch to &builduser with grant option;
grant select on sys.v_$mystat to &builduser with grant option;
grant select on sys.v_$statname to &builduser with grant option;
grant select on sys.v_$timer to &builduser with grant option;

grant execute any procedure to &builduser;

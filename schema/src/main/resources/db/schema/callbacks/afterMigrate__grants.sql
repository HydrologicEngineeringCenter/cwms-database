grant execute on cwms_util to cwms_dba;
/*
This was required for afterMigrate_public_interface to function correctly
after the queues mechanisms were brought in.
*/
grant select on SYS.AQ$_UNFLUSHED_DEQUEUES to CWMS_20 with grant option;

alter user cwms_20 grant connect through cwms_extra;
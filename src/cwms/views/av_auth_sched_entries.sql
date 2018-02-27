whenever sqlerror continue
delete from at_clob where id = '/VIEWDOCS/AV_AUTH_SCHED_ENTRIES';
whenever sqlerror exit sqlcode
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_AUTH_SCHED_ENTRIES', null,
'
/**
 * Displays expected scheduler entries for this database
 *
 * @since CWMS 3.1
 *
 * @field office_id       The office that owns the database in database_name
 * @field database_name   SID of this database or primary database is this is a standby database
 * @field job_owner       Owner of the scheduled job
 * @field job_name        Name of the scheduled job
 * @field job_creator     Creator of the scheduled job
 * @field job_style       ''REGULAR'' or ''LIGHTWEIGHT''
 * @field job_type        ''PLSQL_BLOCK'', ''STORED_PROCEDURE'', ''EXECUTABLE'', or ''CHAIN''
 * @field job_priority    Priority of job 
 * @field schedule_type   ''IMMEDIATE'', ''ONCE'', ''CALENDAR'', ''EVENT'', ''NAMED'', ''WINDOW'', ''WINDOW_GROUP''
 * @field repeat_interval How often the job runs
 * @field comments        Comments on the job   
 * @field job_action      What actually gets executed
 */
');
create or replace force view av_auth_sched_entries
(
   office_id,
   database_name,
   job_owner,
	job_name,
	job_creator,
	job_style,
	job_type,
	job_priority,
	schedule_type,
	repeat_interval,
	comments,
	job_action
)
as
select o.office_id,
       e.database_name,
       e.job_owner,
	    e.job_name,
	    e.job_creator,
	    e.job_style,
	    e.job_type,
	    e.job_priority,
	    e.schedule_type,
	    e.repeat_interval,
	    e.comments,
	    e.job_action 
  from cwms_auth_sched_entries e,
       cwms_office o
 where o.eroc =  case
                 when 0 = (select count(*) from cwms_office where eroc = substr(e.database_name, 1, 2)) then 'X0'
                 else substr(e.database_name, 1, 2)
                 end;          

create or replace public synonym cwms_v_auth_sched_entries for av_auth_sched_entries;  

--drop table at_ts_extents;
create table at_ts_extents (
   ts_code                       integer,   
   version_time                  date,          
   earliest_time                 date,          
   earliest_time_entry           timestamp, 
   earliest_entry_time           timestamp, 
   earliest_non_null_time        date,          
   earliest_non_null_time_entry  timestamp,  
   earliest_non_null_entry_time  timestamp,  
   latest_time                   date,          
   latest_time_entry             timestamp, 
   latest_entry_time             timestamp, 
   latest_non_null_time          date,          
   latest_non_null_time_entry    timestamp, 
   latest_non_null_entry_time    timestamp, 
   least_value                   binary_double, 
   least_value_time              date,          
   least_value_entry             timestamp, 
   least_accepted_value          binary_double, 
   least_accepted_value_time     date,          
   least_accepted_value_entry    timestamp, 
   greatest_value                binary_double, 
   greatest_value_time           date,          
   greatest_value_entry          timestamp, 
   greatest_accepted_value       binary_double, 
   greatest_accepted_value_time  date,          
   greatest_accepted_value_entry timestamp, 
   last_update                   timestamp, 
   constraint at_ts_extents_pk  primary key (ts_code, version_time), 
   constraint at_ts_extents_fk1 foreign key (ts_code)references at_cwms_ts_spec (ts_code)
) 
tablespace cwms_20at_data ;

comment on table  at_ts_extents                               is 'Holds date/time and value extent information for time series';
comment on column at_ts_extents.ts_code                       is 'Unique nummeric value identifying time series';
comment on column at_ts_extents.version_time                  is 'The version date/tim  of the time series (always 11-nov-1111 00:00:00 for unversioned time series)';
comment on column at_ts_extents.earliest_time                 is 'The earliest time that a value exists for the time series';
comment on column at_ts_extents.earliest_time_entry           is 'The time that the earliest value was entered (stored)';
comment on column at_ts_extents.earliest_entry_time           is 'The earliest time that a value (for any time) was entered (stored) for the time series';
comment on column at_ts_extents.earliest_non_null_time        is 'The earliest time that a non-null value exists for the time series';
comment on column at_ts_extents.earliest_non_null_time_entry  is 'The time that the earliest non-null value was entered (stored)';
comment on column at_ts_extents.earliest_non_null_entry_time  is 'The earliest time that a non-null value (for any time) was entered (stored) for the time series';
comment on column at_ts_extents.latest_time                   is 'The latest time that a value exists for the time series';
comment on column at_ts_extents.latest_time_entry             is 'The time that the latest value was entered (stored)';
comment on column at_ts_extents.latest_entry_time             is 'The latest time that a value (for any time) was entered (stored) for the time series';
comment on column at_ts_extents.latest_non_null_time          is 'The latest time that a non-null value exists for the time series';
comment on column at_ts_extents.latest_non_null_time_entry    is 'The time that latest non-null value was entered (stored)';
comment on column at_ts_extents.latest_non_null_entry_time    is 'The latest time that a non-null value (for any time) was entered (stored) for the time series';
comment on column at_ts_extents.least_value                   is 'The least non-null va lue (in database units) that has been stored for the time series';
comment on column at_ts_extents.least_value_time              is 'The timethat the least non-null value (in database units) that has been stored for the time series is for';
comment on column at_ts_extents.least_value_entry             is 'The time that the least non-null value (in database units) that has been stored for the time series was entered (stored)';
comment on column at_ts_extents.least_accepted_value          is 'The least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series';
comment on column at_ts_extents.least_accepted_value_time     is 'The time that the least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series is for';
comment on column at_ts_extents.least_accepted_value_entry    is 'The time that the least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series was entered (stored)';
comment on column at_ts_extents.greatest_value                is 'The greatest non-null value (in database units) that has been stored for the time series';
comment on column at_ts_extents.greatest_value_time           is 'The time that the greatest non-null value (in database units) that has been stored for the time series is for';
comment on column at_ts_extents.greatest_value_entry          is 'The time tha t the greatest non-null value (in database units) that has been stored for the time series was entered (stored)';
comment on column at_ts_extents.greatest_accepted_value       is 'The greatest accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series';
comment on column at_ts_extents.greatest_accepted_value_time  is 'The time that the greatest accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series is for';
comment on column at_ts_extents.greatest_accepted_value_entry is 'The time that the greatest accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series was entered (stored)';
comment on column at_ts_extents.last_update                   is 'The time that this record was updated';

create or replace TRIGGER ST_TS_EXTENTS BEFORE DELETE OR INSERT OR UPDATE
              ON AT_TS_EXTENTS REFERENCING NEW AS NEW OLD AS OLD

             DECLARE

             l_priv   VARCHAR2 (16);
             BEGIN
             SELECT SYS_CONTEXT ('CWMS_ENV', 'CWMS_PRIVILEGE') INTO l_priv FROM DUAL;
             IF ((l_priv is NULL OR l_priv <> 'CAN_WRITE') AND user NOT IN ('SYS', 'CWMS_20'))
             THEN

               CWMS_20.CWMS_ERR.RAISE('NO_WRITE_PRIVILEGE');

             END IF;
           END;
/           

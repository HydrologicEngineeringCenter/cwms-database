declare
   l_clob clob;
begin
   l_clob := '
/**
 * Displays information about time series extents in UTC time zone
 *                                                                             
 * @since CWMS 3.2
 *
 * @field ts_code                       Unique nummeric value identifying the time series
 * @field db_office_id                  The office owning the time series 
 * @field location_id                   The location of the time series 
 * @field parameter_id                  The parameter of the time series 
 * @field ts_id                         The time series identifier 
 * @field time_zone_name                The time zone of the record (always UTC)
 * @field version_time                  The version date/time of the time series (always 11-Nov-1111 00:00:00 for unversioned time series)                                                             
 * @field earliest_time                 The earliest time that a value exists for the time series                                                                                                      
 * @field earliest_time_entry           The time that the earliest value was entered (stored)                                                                                                          
 * @field earliest_entry_time           The earliest time that a value (for any time) was entered (stored) for the time series                                                                         
 * @field earliest_non_null_time        The earliest time that a non-null value exists for the time series                                                                                             
 * @field earliest_non_null_time_entry  The time that the earliest non-null value was entered (stored)                                                                                                 
 * @field earliest_non_null_entry_time  The earliest time that a non-null value (for any time) was entered (stored) for the time series                                                                
 * @field latest_time                   The latest time that a value exists for the time series                                                                                                        
 * @field latest_time_entry             The time that the latest value was entered (stored)                                                                                                            
 * @field latest_entry_time             The latest time that a value (for any time) was entered (stored) for the time series                                                                           
 * @field latest_non_null_time          The latest time that a non-null value exists for the time series                                                                                               
 * @field latest_non_null_time_entry    The time that latest non-null value was entered (stored)                                                                                                       
 * @field latest_non_null_entry_time    The latest time that a non-null value (for any time) was entered (stored) for the time series                                                                  
 * @field si_unit                       The default SI unit for the time series 
 * @field en_unit                       The default English unit for the time series 
 * @field least_value_si                The least non-null value (in database units) that has been stored for the time series in default SI units 
 * @field least_value_en                The least non-null value (in database units) that has been stored for the time series in default English units                                                                         
 * @field least_value_time              The time that the least non-null value (in database units) that has been stored for the time series is for'                                                     
||' 
 * @field least_value_entry             The time that the least non-null value (in database units) that has been stored for the time series was entered (stored)                                       
 * @field least_accepted_value_si       The least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series in default SI units                                       
 * @field least_accepted_value_en       The least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series in default English units
 * @field least_accepted_value_time     The time that the least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series is for                                                                             
 * @field least_accepted_value_entry    The time that the least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series was entered (stored)                                                               
 * @field greatest_value_si             The greatest non-null value (in database units) that has been stored for the time series in default SI units                                                                                                                                  
 * @field greatest_value_en             The greatest non-null value (in database units) that has been stored for the time series in default English units                                                            
 * @field greatest_value_time           The time that the greatest non-null value (in database units) that has been stored for the time series is for                                                                                                             
 * @field greatest_value_entry          The time that the greatest non-null value (in database units) that has been stored for the time series was entered (stored)                                                                                               
 * @field greatest_accepted_value_si    The greatest_accepted non-null value (in database units) that has been stored for the time series in default SI units                                                                                                                         
 * @field greatest_accepted_value_en    The greatest_accepted non-null value (in database units) that has been stored for the time series in default English units                                                              
 * @field greatest_accepted_value_time  The time that the greatest accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series is for                                                                          
 * @field greatest_accepted_value_entry The time that the greatest accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series was entered (stored)                                                            
 * @field last_update                   The time that this record was updated
 */
'; 
   delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_TS_EXTENTS_UTC';
   insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_EXTENTS_UTC', null, l_clob);
end;
/
create or replace force view av_ts_extents_utc (
   ts_code, 
   db_office_id, 
   location_id, 
   parameter_id, 
   ts_id,
   time_zone_name,
   version_time, 
   earliest_time, 
   earliest_time_entry, 
   earliest_entry_time, 
   earliest_non_null_time, 
   earliest_non_null_time_entry, 
   earliest_non_null_entry_time, 
   latest_time, 
   latest_time_entry, 
   latest_entry_time, 
   latest_non_null_time, 
   latest_non_null_time_entry, 
   latest_non_null_entry_time, 
   si_unit, 
   en_unit, 
   least_value_si, 
   least_value_en, 
   least_value_time,
   least_value_entry, 
   least_accepted_value_si, 
   least_accepted_value_en, 
   least_accepted_value_time, 
   least_accepted_value_entry, 
   greatest_value_si, 
   greatest_value_en, 
   greatest_value_time, 
   greatest_value_entry, 
   greatest_accepted_value_si, 
   greatest_accepted_value_en, 
   greatest_accepted_value_time, 
   greatest_accepted_value_entry, 
   last_update)
as 
select tsx.ts_code,
       tid.db_office_id,
       tid.location_id,
       tid.parameter_id,
       tid.cwms_ts_id as ts_id,
      'UTC' as time_zone_name,
       case when tsx.version_time = date '1111-11-11' then null
       else tsx.version_time
       end as version_time,
       tsx.earliest_time,
       tsx.earliest_time_entry,     
       tsx.earliest_entry_time,
       tsx.earliest_non_null_time,
       tsx.earliest_non_null_time_entry,
       tsx.earliest_non_null_entry_time,
       tsx.latest_time,
       tsx.latest_time_entry,
       tsx.latest_entry_time,
       tsx.latest_non_null_time,
       tsx.latest_non_null_time_entry,
       tsx.latest_non_null_entry_time,
       tid.unit_id as si_unit,
       cwms_util.get_default_units(tid.parameter_id, 'EN') as en_unit,
       tsx.least_value as least_value_si,
       cwms_util.convert_units(tsx.least_value, tid.unit_id, cwms_util.get_default_units(tid.parameter_id, 'EN')) as least_value_en, 
       tsx.least_value_time,
       tsx.least_value_entry,
       tsx.least_accepted_value as least_accepted_value_si,
       cwms_util.convert_units(tsx.least_accepted_value, tid.unit_id, cwms_util.get_default_units(tid.parameter_id, 'EN')) as least_accepted_value_en, 
       tsx.least_accepted_value_time,
       tsx.least_accepted_value_entry,
       tsx.greatest_value as greatest_value_si,
       cwms_util.convert_units(tsx.greatest_value, tid.unit_id, cwms_util.get_default_units(tid.parameter_id, 'EN')) as greatest_value_en, 
       tsx.greatest_value_time,
       tsx.greatest_value_entry,
       tsx.greatest_accepted_value as greatest_accepted_value_si,
       cwms_util.convert_units(tsx.greatest_accepted_value, tid.unit_id, cwms_util.get_default_units(tid.parameter_id, 'EN')) as greatest_accepted_value_en, 
       tsx.greatest_accepted_value_time,
       tsx.greatest_accepted_value_entry,
       tsx.last_update                  
  from at_ts_extents tsx,
       at_cwms_ts_id tid
 where tid.ts_code = tsx.ts_code;

create or replace public synonym cwms_v_ts_extents_utc for av_ts_extents_utc;

create or replace package cwms_forecast as

--------------------------------------------------------------------------------
-- function get_forecast_spec_code
--------------------------------------------------------------------------------
function get_forecast_spec_code(
   p_location_id in varchar2,
   p_forecast_id in varchar2,
   p_office_id   in varchar2 default null) -- null = user's office id
   return number;

--------------------------------------------------------------------------------
-- procedure store_spec
--------------------------------------------------------------------------------
procedure store_spec(
   p_location_id    in varchar2,
   p_forecast_id    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_source_agency  in varchar2,
   p_source_office  in varchar2,
   p_valid_lifetime in integer, -- in hours
   p_forecast_type  in varchar2 default null,  -- null = null
   p_source_loc_id  in varchar2 default null,  -- null = null
   p_office_id      in varchar2 default null); -- null = user's office id

--------------------------------------------------------------------------------
-- procedure retrieve_spec
--------------------------------------------------------------------------------
procedure retrieve_spec(
   p_source_agency  out varchar2,
   p_source_office  out varchar2,
   p_valid_lifetime out integer, -- in hours
   p_forecast_type  out varchar2,
   p_source_loc_id  out varchar2,
   p_location_id    in  varchar2,
   p_forecast_id    in  varchar2,
   p_office_id      in  varchar2 default null); -- null = user's office id

--------------------------------------------------------------------------------
-- procedure delete_spec
--------------------------------------------------------------------------------
procedure delete_spec(
   p_location_id    in varchar2,
   p_forecast_id    in varchar2,
   p_delete_action  in varchar2 default cwms_util.delete_key,
   p_office_id      in varchar2 default null); -- null = user's office id

--------------------------------------------------------------------------------
-- procedure rename_spec
--------------------------------------------------------------------------------
procedure rename_spec(
   p_location_id     in varchar2,
   p_old_forecast_id in varchar2,
   p_new_forecast_id in varchar2,
   p_office_id       in varchar2 default null); -- null = user's office id

--------------------------------------------------------------------------------
-- procedure cat_specs
--
-- cursor contains the following field, ordered by the first 3:
--
--    office_id      varchar2(16)
--    location_id    varchar2(49)
--    forecast_id    varchar2(32)
--    source_agency  varchar2(16)
--    source_office  varchar2(16)
--    valid_lifetime number
--    forecast_type  varchar2(5)
--    source_loc_id  varchar2(49)
--
--------------------------------------------------------------------------------
procedure cat_specs(
   p_spec_catalog       out sys_refcursor,
   p_location_id_mask   in  varchar2 default '*',
   p_forecast_id_mask   in  varchar2 default '*',
   p_source_agency_mask in  varchar2 default '*',
   p_source_office_mask in  varchar2 default '*',
   p_forecast_type_mask in  varchar2 default '*',
   p_source_loc_id_mask in  varchar2 default '*',
   p_office_id_mask     in  varchar2 default null); -- null = user's office id

--------------------------------------------------------------------------------
-- function cat_specs_f
--------------------------------------------------------------------------------
function cat_specs_f(
   p_location_id_mask   in varchar2 default '*',
   p_forecast_id_mask   in varchar2 default '*',
   p_source_agency_mask in varchar2 default '*',
   p_source_office_mask in varchar2 default '*',
   p_forecast_type_mask in varchar2 default '*',
   p_source_loc_id_mask in varchar2 default '*',
   p_office_id_mask     in varchar2 default null) -- null = user's office id
   return sys_refcursor;

--------------------------------------------------------------------------------
-- procedure store_ts
--------------------------------------------------------------------------------
procedure store_ts(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_cwms_ts_id      in varchar2,
   p_units           in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_version_date    in date,
   p_time_zone       in varchar2,
   p_timeseries_data in ztsv_array,
   p_fail_if_exists  in varchar2,
   p_store_rule      in varchar2 default null,  -- null = DELETE INSERT
   p_office_id       in varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure retrieve_ts
--------------------------------------------------------------------------------
procedure retrieve_ts(
   p_ts_cursor       out sys_refcursor,
   p_version_date    out date,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_cwms_ts_id      in  varchar2,
   p_units           in  varchar2,
   p_forecast_time   in  date,
   p_issue_time      in  date,
   p_start_time      in  date default null,
   p_end_time        in  date default null,
   p_time_zone       in  varchar2 default null, -- null = location time zone
   p_trim            in  varchar2 default 'F',
   p_start_inclusive in  varchar2 default 'T',
   p_end_inclusive   in  varchar2 default 'T',
   p_previous        in  varchar2 default 'F',
   p_next            in  varchar2 default 'F',
   p_office_id       in  varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure delete_ts
--------------------------------------------------------------------------------
procedure delete_ts(
   p_location_id   in varchar2,
   p_forecast_id   in varchar2,
   p_cwms_ts_id    in varchar2,               -- null = all time series
   p_forecast_time in date,                   -- null = all forecast times
   p_issue_time    in date,                   -- null = all issue times
   p_time_zone     in varchar2 default null,  -- null = location time zone
   p_office_id     in varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure cat_ts
--
-- cursor contains the following field, ordered by the first 4:
--
--    office_id      varchar2(16)
--    forecast_date  date          
--    issue_date     date          
--    cwm_ts_id      varchar2(183)
--    version_date   date          
--    min_time       date          
--    max_time       date
--    time_zone_name varchar2(28)  
--
-- all dates are in the indicated time zone (passed in or location default) and
-- the time series extents are indicated in min_time, max_time
--
--------------------------------------------------------------------------------
procedure cat_ts(
   p_ts_catalog      out sys_refcursor,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_cwms_ts_id_mask in  varchar2 default '*',
   p_time_zone       in  varchar2 default null,  -- null = location time zone
   p_office_id       in  varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- function cat_ts_f
--
-- cursor contains the following field, ordered by the first 4:
--
--    office_id      varchar2(16)
--    forecast_date  date          
--    issue_date     date          
--    cwm_ts_id      varchar2(183)
--    version_date   date          
--    min_time       date          
--    max_time       date
--    time_zone_name varchar2(28)  
--
-- all dates are in the indicated time zone (passed in or location default) and
-- the time series extents are indicated in min_time, max_time
--
--------------------------------------------------------------------------------
function cat_ts_f(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_cwms_ts_id_mask in varchar2 default '*',
   p_time_zone       in varchar2 default null, -- null = location time zone
   p_office_id       in varchar2 default null) -- null = user's office id   
   return sys_refcursor;   

--------------------------------------------------------------------------------
-- procedure store_text
--------------------------------------------------------------------------------
procedure store_text(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_time_zone       in varchar2,
   p_text            in clob,
   p_fail_if_exists  in varchar2,
   p_office_id       in varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure retrieve_text
--------------------------------------------------------------------------------
procedure retrieve_text(
   p_text            out clob,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_forecast_time   in  date,
   p_issue_time      in  date,
   p_time_zone       in  varchar2 default null,  -- null = location time zone
   p_office_id       in  varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure delete_text
--------------------------------------------------------------------------------
procedure delete_text(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,                   -- null = all forecast times
   p_issue_time      in date,                   -- null = all issue times
   p_time_zone       in varchar2 default null,  -- null = location time zone
   p_office_id       in varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure cat_text
--
-- cursor contains the following field, ordered by the first 4:
--
--    office_id      varchar2(16)
--    forecast_date  date          
--    issue_date     date
--    text_id        varchar2(256)          
--    time_zone_name varchar2(28)  
--
-- all dates are in the indicated time zone (passed in or location default)
--
-- office_id and text_id can be used in CWMS_TEXT.RETRIEVE_TEXT
--
--------------------------------------------------------------------------------
procedure cat_text(
   p_text_catalog out sys_refcursor,
   p_location_id  in  varchar2,
   p_forecast_id  in  varchar2,
   p_time_zone    in  varchar2 default null,  -- null = location time zone
   p_office_id    in  varchar2 default null); -- null = user's office id   
            
--------------------------------------------------------------------------------
-- function cat_text_f
--
-- cursor contains the following field, ordered by the first 4:
--
--    office_id      varchar2(16)
--    forecast_date  date          
--    issue_date     date
--    text_id        varchar2(256)          
--    time_zone_name varchar2(28)  
--
-- all dates are in the indicated time zone (passed in or location default)
--
-- office_id and text_id can be used in CWMS_TEXT.RETRIEVE_TEXT
--
--------------------------------------------------------------------------------
function cat_text_f (
   p_location_id  in varchar2,
   p_forecast_id  in varchar2,
   p_time_zone    in varchar2 default null, -- null = location time zone
   p_office_id    in varchar2 default null) -- null = user's office id   
   return sys_refcursor;   

--------------------------------------------------------------------------------
-- procedure store_forecast
--------------------------------------------------------------------------------
procedure store_forecast(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_time_zone       in varchar2, -- null = location time zone
   p_fail_if_exists  in varchar2,
   p_text            in clob,
   p_time_series     in ztimeseries_array,
   p_store_rule      in varchar2 default null,  -- null = DELETE INSERT
   p_office_id       in varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure retrieve_forecast
--------------------------------------------------------------------------------
procedure retrieve_forecast(
   p_time_series     out ztimeseries_array,
   p_text            out clob,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_unit_system     in  varchar2 default null, -- null = retrieved from preferences, SI if none
   p_forecast_time   in  date     default null,  -- null = most recent
   p_issue_time      in  date     default null,  -- null = most_recent
   p_time_zone       in  varchar2 default null,  -- null = location time zone
   p_office_id       in  varchar2 default null); -- null = user's office id   
   
end cwms_forecast;
/
show errors;
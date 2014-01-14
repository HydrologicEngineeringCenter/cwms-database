--
-- AV_CWMS_TS_ID    (View)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Synonym)
--

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_CWMS_TS_ID', null,
'
/**
 * Displays CWMS Time Series Identifiers
 *
 * @since CWMS 2.0
 *
 * @field db_office_id        Identifies office that owns time series
 * @field cwms_ts_id          Identifies the time series
 * @field unit_id             Identifies the database storage unit for the time series
 * @field abstract_param_id   Identifies the abstract parameter (length, volume, etc...) for the time series
 * @field base_location_id    Identifies the base location for the time series
 * @field sub_location_id     Identifies the sub-location for the time series, if any
 * @field location_id         Identifies te full location for the time series
 * @field base_parameter_id   Identifies the base parameter for the time series
 * @field sub_parameter_id    Identifies the sub-parameter for the time series, if any
 * @field parameter_id        Identifies the full parameter for the time series
 * @field parameter_type_id   Identifies the parameter type (Inst, Min, Total, etc...) for the time series
 * @field interval_id         Identifies the data recurrence interval for the time series
 * @field duration_id         Identifies the time span covered by each data value of the time series
 * @field version_id          Identifies the named version (not the version date) of the time series
 * @field interval            Data recurrence interval in minutes (0 indicates irregluar time series)
 * @field interval_utc_offset Data time as an offset into each interval. Intervals are based on UTC
 * @field bas_loc_active_flag Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the base location is marked as active
 * @field loc_active_flag     Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the location is marked as active
 * @field ts_active_flag      Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is marked as active
 * @field net_ts_active_flag  Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is effectively active based on active flag settings
 * @field version_flag        Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is versioned
 * @field ts_code             Unique numeric code that identifies the time series
 * @field db_office_code      Unique numeric code that identifies the office that owns the time series
 * @field base_location_code  Unique numeric code that identifies the base location of the time series
 * @field location_code       Unique numeric code that identifies the full location of the time series
 * @field parameter_code      Unique numeric code that identifies the parameter for the time series
 * @field is_alias            Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the cwms_ts_id is an alias.  If <code><big>''T''</big></code>, all other columns refer to the actual time series identifier.             
*/
');

CREATE OR REPLACE FORCE VIEW av_cwms_ts_id
(
    db_office_id,
    cwms_ts_id,
    unit_id,
    abstract_param_id,
    base_location_id,
    sub_location_id,
    location_id,
    base_parameter_id,
    sub_parameter_id,
    parameter_id,
    parameter_type_id,
    interval_id,
    duration_id,
    version_id,
    interval,
    interval_utc_offset,
    bas_loc_active_flag,
    loc_active_flag,
    ts_active_flag,
    net_ts_active_flag,
    version_flag,
    ts_code,
    db_office_code,
    base_location_code,
    location_code,
    parameter_code,
    is_alias
)
AS
   select db_office_id,
          cwms_ts_id,
          unit_id,
          abstract_param_id,
          base_location_id,
          sub_location_id,
          location_id,
          base_parameter_id,
          sub_parameter_id,
          parameter_id,
          parameter_type_id,
          interval_id,
          duration_id,
          version_id,
          interval,
          interval_utc_offset,
          base_loc_active_flag,
          loc_active_flag,
          ts_active_flag,
          net_ts_active_flag,
          version_flag,
          ts_code,
          db_office_code,
          base_location_code,
          location_code,
          parameter_code,
          'F' as is_alias
     from at_cwms_ts_id
   union all  
   select ts.db_office_id,
          lg.loc_alias_id || substr(ts.cwms_ts_id, instr(ts.cwms_ts_id, '.')) as cwms_ts_id,
          ts.unit_id,
          ts.abstract_param_id,
          ts.base_location_id,
          ts.sub_location_id,
          ts.location_id,
          ts.base_parameter_id,
          ts.sub_parameter_id,
          ts.parameter_id,
          ts.parameter_type_id,
          ts.interval_id,
          ts.duration_id,
          ts.version_id,
          ts.interval,
          ts.interval_utc_offset,
          ts.base_loc_active_flag,
          ts.loc_active_flag,
          ts.ts_active_flag,
          ts.net_ts_active_flag,
          ts.version_flag,
          ts.ts_code,
          ts.db_office_code,
          ts.base_location_code,
          ts.location_code,
          ts.parameter_code,
          'T' as is_alias
     from at_cwms_ts_id ts,
          at_loc_group_assignment lg
    where lg.loc_alias_id is not null
      and ts.location_code = lg.location_code       
   union all  
   select ts.db_office_id,
          lg.loc_alias_id || substr(ts.cwms_ts_id, instr(ts.cwms_ts_id, '-')) as cwms_ts_id,
          ts.unit_id,
          ts.abstract_param_id,
          ts.base_location_id,
          ts.sub_location_id,
          ts.location_id,
          ts.base_parameter_id,
          ts.sub_parameter_id,
          ts.parameter_id,
          ts.parameter_type_id,
          ts.interval_id,
          ts.duration_id,
          ts.version_id,
          ts.interval,
          ts.interval_utc_offset,
          ts.base_loc_active_flag,
          ts.loc_active_flag,
          ts.ts_active_flag,
          ts.net_ts_active_flag,
          ts.version_flag,
          ts.ts_code,
          ts.db_office_code,
          ts.base_location_code,
          ts.location_code,
          ts.parameter_code,
          'T' as is_alias
     from at_cwms_ts_id ts,
          at_loc_group_assignment lg
    where lg.loc_alias_id is not null
      and ts.base_location_code = lg.location_code
      and ts.sub_location_id is not null       
   union all  
   select ts.db_office_id,
          tsg.ts_alias_id as cwms_ts_id,
          ts.unit_id,
          ts.abstract_param_id,
          ts.base_location_id,
          ts.sub_location_id,
          ts.location_id,
          ts.base_parameter_id,
          ts.sub_parameter_id,
          ts.parameter_id,
          ts.parameter_type_id,
          ts.interval_id,
          ts.duration_id,
          ts.version_id,
          ts.interval,
          ts.interval_utc_offset,
          ts.base_loc_active_flag,
          ts.loc_active_flag,
          ts.ts_active_flag,
          ts.net_ts_active_flag,
          ts.version_flag,
          ts.ts_code,
          ts.db_office_code,
          ts.base_location_code,
          ts.location_code,
          ts.parameter_code,
          'T' as is_alias
     from at_cwms_ts_id ts,
          at_ts_group_assignment tsg
    where tsg.ts_alias_id is not null
      and ts.ts_code = tsg.ts_code       
/
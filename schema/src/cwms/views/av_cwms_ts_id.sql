-- delete from at_clob where id = '/VIEWDOCS/AV_CWMS_TS_ID';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_CWMS_TS_ID', null,
'
/**
 * Displays CWMS Time Series Identifiers with LRTS as new LRTS IDs
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
 * @field historic_flag       Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is part of the hitoric record
 * @field time_zone_id        The time zone of the location for this time series
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
    historic_flag,
    time_zone_id
)
AS
    SELECT db_office_id,
           case
           when 'T' = (select 'T'
                         from dual
                        where exists(select str_value
                                       from  at_session_info
                                      where item_name = 'USE_NEW_LRTS_ID_FORMAT'
                                        and str_value = 'T')
                                    )
           then
              ----------------------------
              -- use new LRTS ID format --
              ----------------------------
              case
              when substr(interval_id, 1, 1) = '~' and interval_utc_offset != -2147483648 then
                 ----------------
                 -- TS is LRTS --
                 ----------------
                 location_id
                 ||'.'||parameter_id
                 ||'.'||parameter_type_id
                 ||'.'||regexp_replace(interval_id, '^~(.+)$', '\1Local')
                 ||'.'||duration_id
                 ||'.'||version_id
              else
                 --------------------
                 -- TS is not LRTS --
                 --------------------
                 cwms_ts_id
              end
           else
              ----------------------------
              -- use old LRTS ID format --
              ----------------------------
              cwms_ts_id
           end as cwms_ts_id,
           unit_id,
           abstract_param_id,
           base_location_id,
           sub_location_id,
           location_id,
           base_parameter_id,
           sub_parameter_id,
           parameter_id,
           parameter_type_id,
           case
           when 'T' = (select 'T'
                         from dual
                        where exists(select str_value
                                       from  at_session_info
                                      where item_name = 'USE_NEW_LRTS_ID_FORMAT'
                                        and str_value = 'T')
                                    )
           then
              ----------------------------
              -- use new LRTS ID format --
              ----------------------------
              case
              when substr(interval_id, 1, 1) = '~' and interval_utc_offset != -2147483648 then
                 ----------------
                 -- TS is LRTS --
                 ----------------
                 regexp_replace(interval_id, '^~(.+)$', '\1Local')
              else
                 --------------------
                 -- TS is not LRTS --
                 --------------------
                 interval_id
              end
           else
              ----------------------------
              -- use old LRTS ID format --
              ----------------------------
              interval_id
           end as interval_id,
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
           historic_flag,
           time_zone_id
      FROM at_cwms_ts_id
/

begin
	execute immediate 'grant select on av_cwms_ts_id to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_id for av_cwms_ts_id;
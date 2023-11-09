/**
 * Displays CWMS Time Series Identifiers That Are Available for Undelete
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
 * @field delete_date         The date that this ts_id was marked for deletion
*/
CREATE OR REPLACE FORCE VIEW av_deleted_ts_id
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
    time_zone_id,
    delete_date
)
AS
select co.office_id as db_office_id,
       bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id
          ||'.'||bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id
          ||'.'||pt.parameter_type_id
          ||'.'||i.interval_id
          ||'.'||d.duration_id
          ||'.'||ts.version as cwms_ts_id,
       u.unit_id,
       ap.abstract_param_id,
       bl.base_location_id,
       pl.sub_location_id,
       bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
       bp.base_parameter_id,
       p.sub_parameter_id,
       bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id as parameter_id,
       pt.parameter_type_id,
       i.interval_id,
       d.duration_id,
       ts.version as version_id,
       i.interval,
       ts.interval_utc_offset,
       bl.active_flag as bas_loc_active_flag,
       pl.active_flag as loc_active_flag,
       ts.active_flag as ts_active_flag,
       case
          when bl.active_flag = 'T' and pl.active_flag = 'T' and ts.active_flag = 'T' then 'T'
          else 'F'
       end as net_ts_active_flag,
       ts.version_flag,
       ts.ts_code,
       co.office_code as db_office_code,
       bl.base_location_code,
       pl.location_code,
       ts.parameter_code,
       ts.historic_flag,
       tz.time_zone_name as time_zone_id,
       ts.delete_date
  from at_cwms_ts_spec ts,
       at_physical_location pl,
       at_base_location bl,
       cwms_office co,
       at_parameter p,
       cwms_base_parameter bp,
       cwms_parameter_type pt,
       cwms_interval i,
       cwms_duration d,
       cwms_unit u,
       cwms_abstract_parameter ap,
       cwms_time_zone tz
 where ts.prev_location_code is not null
   and pl.location_code = ts.prev_location_code
   and bl.base_location_code = pl.base_location_code
   and co.office_code = bl.db_office_code
   and p.parameter_code = ts.parameter_code
   and bp.base_parameter_code = p.base_parameter_code
   and pt.parameter_type_code = ts.parameter_type_code
   and i.interval_code = ts.interval_code
   and d.duration_code = ts.duration_code
   and u.unit_code = bp.unit_code
   and ap.abstract_param_code = bp.abstract_param_code
   and tz.time_zone_code = ts.time_zone_code
  with read only;
/

begin
	execute immediate 'grant select on av_deleted_ts_id to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_deleted_ts_id for av_deleted_ts_id;

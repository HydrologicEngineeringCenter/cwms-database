--
-- ZAV_CWMS_TS_ID  (View)
--
--  Dependencies:
--   CWMS_INTERVAL (Table)
--   CWMS_OFFICE (Table)
--   CWMS_PARAMETER_TYPE (Table)
--   CWMS_UNIT (Table)
--   CWMS_ABSTRACT_PARAMETER (Table)
--   CWMS_BASE_PARAMETER (Table)
--   CWMS_DURATION (Table)
--   AT_BASE_LOCATION (Table)
--   AT_CWMS_TS_SPEC (Table)
--   AT_PARAMETER (Table)
--   AT_PHYSICAL_LOCATION (Table)
--

-- delete from at_clob where id = '/VIEWDOCS/ZAV_CWMS_TS_ID';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/ZAV_CWMS_TS_ID', null,
'
/**
 * Displays CWMS Time Series Identifiers
 *
 * @since CWMS 2.1
 *
 * @field db_office_code       Unique numeric code that identifies the office that owns the time series
 * @field base_location_code   Unique numeric code that identifies the base location of the time series
 * @field base_loc_active_flag Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the base location is marked as active
 * @field location_code        Unique numeric code that identifies the full location of the time series
 * @field loc_active_flag      Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the location is marked as active
 * @field parameter_code       Unique numeric code that identifies the parameter for the time series
 * @field ts_code              Unique numeric code that identifies the time series
 * @field ts_active_flag       Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is marked as active
 * @field net_ts_active_flag   Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is effectively active based on active flag settings
 * @field db_office_id         Identifies office that owns time series
 * @field cwms_ts_id           Identifies the time series
 * @field unit_id              Identifies the database storage unit for the time series
 * @field abstract_param_id    Identifies the abstract parameter (length, volume, etc...) for the time series
 * @field base_location_id     Identifies the base location for the time series
 * @field sub_location_id      Identifies the sub-location for the time series, if any
 * @field location_id          Identifies te full location for the time series
 * @field base_parameter_id    Identifies the base parameter for the time series
 * @field sub_parameter_id     Identifies the sub-parameter for the time series, if any
 * @field parameter_id         Identifies the full parameter for the time series
 * @field parameter_type_id    Identifies the parameter type (Inst, Min, Total, etc...) for the time series
 * @field interval_id          Identifies the data recurrence interval for the time series
 * @field duration_id          Identifies the time span covered by each data value of the time series
 * @field version_id           Identifies the named version (not the version date) of the time series
 * @field interval             Data recurrence interval in minutes (0 indicates irregluar time series)
 * @field interval_utc_offset  Data time as an offset into each interval. Intervals are based on UTC
 * @field version_flag         Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is versioned
 * @field historic_flag        Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is part of historic record
 * @field time_zone_id         The (location''s) time zone if the time series is a local-regular time series (LRTS)
*/
');
CREATE OR REPLACE FORCE VIEW zav_cwms_ts_id
(
    db_office_code,
    base_location_code,
    base_loc_active_flag,
    location_code,
    loc_active_flag,
    parameter_code,
    ts_code,
    ts_active_flag,
    net_ts_active_flag,
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
    version_flag,
    historic_flag,
    time_zone_id
)
AS
    SELECT    abl.db_office_code, base_location_code,
                abl.active_flag base_loc_active_flag, location_code,
                l.active_flag loc_active_flag, parameter_code, s.ts_code,
                s.active_flag ts_active_flag,
                CASE WHEN abl.active_flag = 'T' AND l.active_flag = 'T' AND s.active_flag = 'T' THEN 'T' ELSE 'F' END net_ts_active_flag,
                o.office_id db_office_id,
                abl.base_location_id || SUBSTR ('-', 1, LENGTH (l.sub_location_id)) || l.sub_location_id || '.' || base_parameter_id || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id)) || ap.sub_parameter_id || '.' || parameter_type_id || '.' || interval_id || '.' || duration_id || '.' || version cwms_ts_id,
                u.unit_id, cap.abstract_param_id, abl.base_location_id,
                l.sub_location_id,
                abl.base_location_id || SUBSTR ('-', 1, LENGTH (l.sub_location_id)) || l.sub_location_id location_id,
                base_parameter_id, ap.sub_parameter_id,
                base_parameter_id || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id)) || ap.sub_parameter_id parameter_id,
                parameter_type_id, interval_id, duration_id, version version_id,
                i.interval, s.interval_utc_offset, s.version_flag, s.historic_flag, z.time_zone_name
      FROM    at_cwms_ts_spec s
                JOIN at_physical_location l
                    USING (location_code)
                JOIN at_base_location abl
                    USING (base_location_code)
                JOIN cwms_office o
                    ON (abl.db_office_code = o.office_code)
                JOIN at_parameter ap
                    USING (parameter_code)
                JOIN cwms_base_parameter p
                    USING (base_parameter_code)
                JOIN cwms_unit u
                    USING (unit_code)
                JOIN cwms_abstract_parameter cap
                    ON (cap.abstract_param_code = u.abstract_param_code)
                JOIN cwms_parameter_type t
                    USING (parameter_type_code)
                JOIN cwms_interval i
                    USING (interval_code)
                JOIN cwms_duration d
                    USING (duration_code)
                LEFT OUTER JOIN cwms_time_zone z ON z.time_zone_code = s.time_zone_code
     WHERE    s.delete_date IS NULL
/

begin
	execute immediate 'grant select on zav_cwms_ts_id to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_zts_id for zav_cwms_ts_id;
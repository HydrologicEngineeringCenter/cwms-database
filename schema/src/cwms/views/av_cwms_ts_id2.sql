-- delete from at_clob where id = '/VIEWDOCS/AV_CWMS_TS_ID2';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_CWMS_TS_ID2', null,
'
/**
 * Displays CWMS Time Series Identifiers, including aliases
 *
 * @since CWMS 2.0 (modified in CWMS 2.1)
 *
 * @field db_office_id        Identifies office that owns time series
 * @field cwms_ts_id          Identifies the time series or alias
 * @field unit_id             Identifies the database storage unit for the time series
 * @field abstract_param_id   Identifies the abstract parameter (length, volume, etc...) for the time series
 * @field base_location_id    Identifies the base location for the time series
 * @field sub_location_id     Identifies the sub-location for the time series, if any
 * @field location_id         Identifies the full location for the time series
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
 * @field aliased_item        Null if the cwms_ts_id is not an alias, ''LOCATION'' if the entire location is aliased, ''BASE LOCATION'' if only the base location is alaised, or ''TIME SERIES'' if the entire cwms_time_series_id is aliased.
 * @field loc_alias_category  The location category for the location alias if aliased_item is ''LOCATION'' or ''BASE LOCATION''
 * @field loc_alias_group     The location group for the location alias if aliased_item is ''LOCATION'' or ''BASE LOCATION''
 * @field ts_alias_category   The time series category for the time series alias if aliased_item is ''TIME SERIES''
 * @field ts_alias_group      The time series group for the time series alias if aliased_item is ''TIME SERIES''
 * @field historic_flag       Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the time series is part of the hitoric record
 * @field time_zone_id        The time zone of the location for this time series
 */
');

CREATE OR REPLACE FORCE VIEW av_cwms_ts_id2
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
    aliased_item,
    loc_alias_category,
    loc_alias_group,
    ts_alias_category,
    ts_alias_group,
    historic_flag,
    time_zone_id
)
AS
   select db_office_id,
          case
           when 'T' = (select 'T'
                         from dual
                        where exists(select str_value
                                       from at_session_info
                                      where item_name = 'USE_NEW_LRTS_ID_FORMAT'
                                        and bitand(num_value, 4) = 4
                                    )
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
                                       from at_session_info
                                      where item_name = 'USE_NEW_LRTS_ID_FORMAT'
                                        and bitand(num_value, 4) = 4
                                    )
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
          null as aliased_item,
          null as loc_alias_category,
          null as loc_alias_group,
          null as ts_alias_category,
          null as ts_alias_group,
          historic_flag,
          time_zone_id
     from at_cwms_ts_id
   union all
   select ts.db_office_id,
          lga.loc_alias_id || substr(ts.cwms_ts_id, instr(ts.cwms_ts_id, '.')) as cwms_ts_id,
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
          'LOCATION' as aliased_item,
          lc.loc_category_id as loc_alias_category,
          lg.loc_group_id as loc_alias_group,
          null as ts_alias_category,
          null as ts_alias_group,
          ts.historic_flag,
          ts.time_zone_id
     from at_cwms_ts_id ts,
          at_loc_group_assignment lga,
          at_loc_group lg,
          at_loc_category lc
    where lga.loc_alias_id is not null
      and ts.location_code = lga.location_code
      and lg.loc_group_code = lga.loc_group_code
      and lc.loc_category_code = lg.loc_category_code
   union all
   select ts.db_office_id,
          lga.loc_alias_id || substr(ts.cwms_ts_id, instr(ts.cwms_ts_id, '-')) as cwms_ts_id,
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
          'BASE LOCATION' as aliased_item,
          lc.loc_category_id as loc_alias_category,
          lg.loc_group_id as loc_alias_group,
          null as ts_alias_category,
          null as ts_alias_group,
          ts.historic_flag,
          ts.time_zone_id
     from at_cwms_ts_id ts,
          at_loc_group_assignment lga,
          at_loc_group lg,
          at_loc_category lc
    where lga.loc_alias_id is not null
      and ts.base_location_code = lga.location_code
      and lg.loc_group_code = lga.loc_group_code
      and lc.loc_category_code = lg.loc_category_code
      and ts.sub_location_id is not null
   union all
   select ts.db_office_id,
          tsga.ts_alias_id as cwms_ts_id,
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
          'TIME SERIES' as aliased_item,
          null as loc_alias_category,
          null as loc_alias_group,
          tsc.ts_category_id as ts_alias_category,
          tsg.ts_group_id as ts_alias_group,
          ts.historic_flag,
          ts.time_zone_id
     from at_cwms_ts_id ts,
          at_ts_group_assignment tsga,
          at_ts_group tsg,
          at_ts_category tsc
    where tsga.ts_alias_id is not null
      and ts.ts_code = tsga.ts_code
      and tsg.ts_group_code = tsga.ts_group_code
      and tsc.ts_category_code = tsg.ts_category_code
/

begin
	execute immediate 'grant select on av_cwms_ts_id2 to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_id2 for av_cwms_ts_id2;
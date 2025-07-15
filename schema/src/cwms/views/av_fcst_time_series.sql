insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_TIME_SERIES', null,
'
/**
 * Information about forecast time series.
 *
 * @field office_id       The office that owns the forecast
 * @field fcst_spec_id    "Main name" of the forecast specification
 * @field fcst_designator "Sub-name" of the forecast specification, if any
 * @field cwms_ts_id      The text ID of this time series
 * @field office_code     Numerical code of office that owns specification
 * @field fcst_spec_code  UUID of specification
 * @field ts_code         Numerical code of time series
 */
');
create or replace view av_fcst_time_series (
   office_id,
   fcst_spec_id,
   fcst_designator,
   cwms_ts_id,
   office_code,
   fcst_spec_code,
   ts_code)
as
select o.office_id,
       fs.fcst_spec_id,
       fs.fcst_designator,
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
               when substr(tsid.interval_id, 1, 1) = '~' and tsid.interval_utc_offset != -2147483648 then
                    ----------------
                    -- TS is LRTS --
                    ----------------
                    tsid.location_id
                    ||'.'||tsid.parameter_id
                    ||'.'||tsid.parameter_type_id
                    ||'.'||regexp_replace(tsid.interval_id, '^~(.+)$', '\1Local')
                    ||'.'||tsid.duration_id
                    ||'.'||tsid.version_id
               else
                    --------------------
                    -- TS is not LRTS --
                    --------------------
                    tsid.cwms_ts_id
               end
           else
               ----------------------------
               -- use old LRTS ID format --
               ----------------------------
               tsid.cwms_ts_id
           end as cwms_ts_id,
       o.office_code,
       fs.fcst_spec_code,
       fts.ts_code
  from at_fcst_spec fs,
       at_fcst_time_series fts,
       cwms_office o,
       at_cwms_ts_id tsid
 where o.office_code = fs.office_code
   and fs.fcst_spec_code = fts.fcst_spec_code
   and fts.ts_code = tsid.ts_code;

grant select on av_fcst_time_series to cwms_user;
create or replace public synonym cwms_v_fcst_time_series for av_fcst_time_series;

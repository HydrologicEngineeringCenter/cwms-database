insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_INFO', null,
'
/**
 * (key, value) pairs from forecast_info.xml files. Top-level elements in the file with attributes of ''key="true"'' are the keys, with the element data being the values
 *
 * @field office_id           The office that owns the forecast
 * @field fcst_spec_id        The specification ID of the forecast
 * @field location_id         The location that the forecast is for
 * @field fcst_date_time_utc  The date/time the forecast is for
 * @field valid               A flag (''T''/''F'') specifying whether the forecast is currently valid
 * @field key                 The key
 * @field value               The associated value
 */
');
create or replace view av_fcst_info
as
   select o.office_id,
          spec.fcst_spec_id,
          bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
          inst.fcst_date_time as fcst_date_time_utc,
          inst.issue_date_time as issue_date_time_utc,
          case when max_age is null then null when (sysdate - inst.issue_date_time) * 24 <= max_age then 'T' else 'F' end as valid,
          info.key,
          info.value
     from at_fcst_info info,
          at_fcst_inst inst,
          at_fcst_spec spec,
          at_physical_location pl,
          at_base_location bl,
          cwms_office o
    where inst.fcst_inst_code = info.fcst_inst_code
      and spec.fcst_spec_code = inst.fcst_spec_code
      and o.office_code = spec.office_code
      and pl.location_code = spec.location_code
      and bl.base_location_code = pl.base_location_code;

grant select on av_fcst_info to cwms_user;
create or replace public synonym cwms_v_fcst_info for av_fcst_info;

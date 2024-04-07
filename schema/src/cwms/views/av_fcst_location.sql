insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_LOCATION', null,
'
/**
 * Information about forecast time series.
 *
 * @field office_id        The office that owns the forecast
 * @field fcst_spec_id    "Main name" of the forecast specification
 * @field fcst_designator "Sub-name" of the forecast specification, if any
 * @field location_id     The text ID of the primary location for this specification
 * @field office_code     Numerical code of office that owns specification
 * @field fcst_spec_code  UUID of specification
 * @field location code   Numerical code of the location
 */
');
create or replace view av_fcst_location (
   office_id,
   fcst_spec_id,
   fcst_designator,    
   location_id,
   office_code,
   fcst_spec_code,
   location_code_code)
as
select o.office_id,
       fs.fcst_spec_id,
       fs.fcst_designator,
       bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id as location_id,
       o.office_code,
       fs.fcst_spec_code,
       fl.primary_location_code
  from at_fcst_spec fs,
       at_fcst_location fl,
       cwms_office o,
       at_physical_location pl,
       at_base_location bl
 where o.office_code = fs.office_code
   and fs.fcst_spec_code = fl.fcst_spec_code
   and fl.primary_location_code = pl.location_code
   and bl.base_location_code = pl.base_location_code;

grant select on av_fcst_location to cwms_user;
create or replace public synonym cwms_v_fcst_location for av_fcst_location;

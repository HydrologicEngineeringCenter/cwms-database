whenever sqlerror continue
delete from at_clob where id = '/VIEWDOCS/AV_FORECAST_SPEC';
whenever sqlerror exit sqlcode
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FORECAST_SPEC', null,
'
/**
 * Displays information about forecasts in the database
 *
 * @since CWMS 3.1
 *
 * @param office_id            The office that owns the locations and forecast specification
 * @param target_location_id   The target location for the forecast
 * @param forecast_id          The forecast identifier
 * @param source_agency        The agency (USACE or NWS) that produces the forecasts
 * @param source_office        The office within the agency that produces the forecasts
 * @param forecast_type         The NWS forecast type (e.g., RFD, RVF,...) or USACE forecast type (e.g., CWMS)
 * @param source_location_id   The location that is the source of forecasts for the target location
 * @param max_age              Age of existing forecast in hours before a new forecast is considered missing
 * @param office_code          The unique numeric code identifying the office that owns the locations and the forecast specification
 * @param forecast_spec_code   The unique numeric code identifying the forecast specification
 * @param target_location_code The unique numeric code identifying the target location for the forecast
 * @param source_location_code The unique numeric code identifying the location that is the source of forecasts for the target location
 */
');

create or replace force view av_forecast_spec (
   office_id,
   target_location_id,
   forecast_id,
   source_agency,
   source_office,
   forecast_type,
   source_location_id,
   max_age,
   office_code,
   forecast_spec_code,
   target_location_code,
   source_location_code
)  as
select o.office_id,
      cwms_loc.get_location_id(fs.target_location_code) as target_location_id,
      fs.forecast_id,
      fs.source_agency,
      fs.source_office,
      fs.forecast_type,
      cwms_loc.get_location_id(fs.source_location_code) as source_location_id,
      max_age,
      o.office_code,
      fs.forecast_spec_code,
      fs.target_location_code,
      fs.source_location_code
 from at_forecast_spec fs,
      at_physical_location pl,
      at_base_location bl,
      cwms_office o
where pl.location_code = fs.target_location_code
  and bl.base_location_code = pl.location_code
  and o.office_code = bl.db_office_code;

begin
	execute immediate 'grant select on av_forecast_spec to cwms_user';
exception
	when others then null;
end;
/

create or replace public synonym cwms_v_forecast_spec for av_forecast_spec;


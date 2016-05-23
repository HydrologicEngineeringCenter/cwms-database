insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_PUMP', null,
'
/**
 * Displays information about pumps about pump locations in the CWMS database
 *
 * @since CWMS 3.0
 *
 * @field office_id          The office that owns the pump location
 * @field pump_location_id   The text identifier of the pump location
 * @field description        A description of the structure
 * @field pump_location_code The unique numeric code that identifies the pump location in the database
 */
');
create or replace force view av_pump (
   office_id, 
   pump_location_id, 
   description, 
   pump_location_code) 
as 
select o.office_id,
       bl.base_location_id
       ||substr('-', 1, length(pl.sub_location_id))
       ||pl.sub_location_id as pump_location_id,
       ap.description,
       ap.pump_location_code
  from at_pump ap,
       at_physical_location pl,
       at_base_location bl,
       cwms_office o
 where pl.location_code = ap.pump_location_code
   and bl.base_location_code = pl.base_location_code
   and o.office_code = bl.db_office_code;

create or replace public synonym cwms_v_pump for av_pump;


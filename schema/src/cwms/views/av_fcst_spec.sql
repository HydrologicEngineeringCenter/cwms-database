insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_SPEC', null,
'
/**
 * Information about forecast specifications
 *
 * @field office_id      Text ID of office that owns specification
 * @field fcst_spec_id   Text ID of specification (e.g., "CAVI", "RVF")
 * @field location_id    Text ID of location that forecasts are for
 * @field entity_id      Text ID of entity that generates forecast for this specification
 * @field entity_name    Name of entity that generates forecast for this specification
 * @field description    Text description
 * @field office_code    Numerical code of office that owns specification
 * @field fcst_spec_code Numerical code of specification
 * @field location_code  Numerical code of location that forecasts are for
 * @field entity_code    Numerical code of entity that generates forecast for this specification
 */
');
create or replace view av_fcst_spec (
   office_id,      
   fcst_spec_id,   
   location_id,    
   entity_id,      
   entity_name,    
   description,    
   office_code,    
   fcst_spec_code, 
   location_code,  
   entity_code)
as
select o.office_id,
       fs.fcst_spec_id,
       bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
       e.entity_id,
       e.entity_name,
       fs.description,
       o.office_code,
       fs.fcst_spec_code,
       pl.location_code,
       e.entity_code
  from at_fcst_spec fs,
       at_physical_location pl,
       at_base_location bl,
       cwms_office o,
       at_entity e
 where o.office_code = fs.office_code
   and pl.location_code = fs.location_code
   and bl.base_location_code = pl.base_location_code
   and e.entity_code = fs.source_entity;

grant select on av_fcst_spec to cwms_user;
create or replace public synonym cwms_v_fcst_spec for av_fcst_spec;

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_SPEC', null,
'
/**
 * Information about forecast specifications
 *
 * @field office_id       Text ID of office that owns specification
 * @field fcst_spec_id    "Main name" of the forecast specification
 * @field fcst_designator "Sub-name" of the forecast specification, if any
 * @field entity_id       Text ID of entity that generates forecast for this specification
 * @field entity_name     Name of entity that generates forecast for this specification
 * @field description     Text description
 * @field office_code     Numerical code of office that owns specification
 * @field fcst_spec_code  UUID of specification
 * @field entity_code     Numerical code of entity that generates forecast for this specification
 */
');
create or replace view av_fcst_spec (
   office_id,
   fcst_spec_id,
   fcst_designator,
   entity_id,
   entity_name,
   description,
   office_code,
   fcst_spec_code,
   entity_code)
as
select o.office_id,
       fs.fcst_spec_id,
       fs.fcst_designator,
       e.entity_id,
       e.entity_name,
       fs.description,
       o.office_code,
       fs.fcst_spec_code,
       e.entity_code
  from at_fcst_spec fs,
       cwms_office o,
       at_entity e
 where o.office_code = fs.office_code
   and e.entity_code = fs.source_entity;

grant select on av_fcst_spec to cwms_user;
create or replace public synonym cwms_v_fcst_spec for av_fcst_spec;

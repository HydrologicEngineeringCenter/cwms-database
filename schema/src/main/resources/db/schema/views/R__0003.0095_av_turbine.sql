/**
 * Displays information about turbines at CWMS projects
 *
 * @since CWMS 2.1
 *
 * @field office_id       Office owning project
 * @field project_id      Location identifier of project
 * @field turbine_id      Turbine identifier
 */
create or replace force view av_turbine
(
   office_id,
   project_id,
   turbine_id
)
as
select o.office_id,
       bl1.base_location_id
       ||substr('-', 1, length(pl1.sub_location_id))
       ||pl1.sub_location_id as project_id,
       bl2.base_location_id
       ||substr('-', 1, length(pl2.sub_location_id))
       ||pl2.sub_location_id as turbine_id
  from at_turbine t,
       at_physical_location pl1,
       at_base_location bl1,
       cwms_office o,
       at_physical_location pl2,
       at_base_location bl2
 where pl1.location_code = t.project_location_code
   and bl1.base_location_code = pl1.base_location_code
   and o.office_code = bl1.db_office_code
   and pl2.location_code = t.turbine_location_code
   and bl2.base_location_code = pl2.base_location_code;
/

/**
 * Displays information about compound outlets (gate sequences) at CWMS projects
 *
 * @since CWMS 3.1
 *
 * @field office_id            Office owning project
 * @field project_id           Name of project that contains the compound outlet
 * @field compound_outlet_id   Name of the compound oulet
 * @field outlet_id            Name of outlet that participates in compound outlet
 * @field next_outlet_id       Name of outlet is next downstream of outlet specified in outlet_id. If null, the outlet
 *                             specified in outlet_id is a downstream-most outlet of the compound outlet and discharges
 *                             into the downstream channel
 * @field project_code         Numeric code that identifies the project in the database
 * @field compound_outlet_code Numeric code that identifies the compound outlet in the database
 * @field outlet_code          Numeric code that identifies the outlet in the database
 * @field next_outlet_code     Numeric code that identifies the next downstream outlet in the database
 */
create or replace force view av_compound_outlet(
   office_id,
   project_id,
   compound_outlet_id,
   outlet_id,
   next_outlet_id,
   project_code,
   compound_outlet_code,
   outlet_code,
   next_outlet_code)
as
   select co.office_id,
          bl1.base_location_id || substr('-', length(pl1.sub_location_id)) || pl1.sub_location_id as project_id,
          aco.compound_outlet_id,
          cwms_loc.get_location_id(acoc.outlet_location_code) as outlet_id,
          cwms_loc.get_location_id(acoc.next_outlet_code) as next_outlet_id,
          aco.project_location_code as project_code,
          aco.compound_outlet_code,
          acoc.outlet_location_code as outlet_code,
          acoc.next_outlet_code
     from at_comp_outlet aco,
          at_comp_outlet_conn acoc,
          at_physical_location pl1,
          at_base_location bl1,
          cwms_office co
    where pl1.location_code = aco.project_location_code
      and bl1.base_location_code = pl1.base_location_code
      and co.office_code = bl1.db_office_code
      and acoc.compound_outlet_code = aco.compound_outlet_code
/

create or replace public synonym cwms_v_compound_outlet for av_compound_outlet;

/**
 * Displays information about gates at CWMS projects
 *
 * @since CWMS 3.0
 *
 * @field office_id        Office owning project
 * @field project_id       Location identifier of project
 * @field gate_id          Gate identifier
 * @field gate_type_id     Type of gate
 * @field sort_order       The order of the gate within the rating group
 * @field can_be_submerged A flag (''T''/''F'') specifying whether the gate can be submerged
 * @field always_submerged A flag (''T''/''F'') specifying whether the gate is always submerged
 * @field rating_group_id Identifier of rating group outlet belongs to
 * @field rating_spec     Rating specification used for outlet
 * @field opening_unit_en Opening unit in English unit system
 * @field opening_unit_si Opening unit in SI unit system
 */
create or replace force view av_gate
(
   office_id,
   project_id,
   gate_id,
   gate_type_id,
   sort_order,
   can_be_submerged,
   always_submerged,
   rating_group_id,
   rating_spec,
   opening_unit_en,
   opening_unit_si
)
as
select o.office_id as office_id,
       bl1.base_location_id
       ||substr('-', 1, length(pl1.sub_location_id))
       ||pl1.sub_location_id as project_id,
       bl2.base_location_id
       ||substr('-', 1, length(pl2.sub_location_id))
       ||pl2.sub_location_id as gate_id,
       gt.gate_type_id,
       lga.loc_attribute as sort_order,
       gg.can_be_submerged,
       gg.always_submerged,
       lg.loc_group_id as rating_group_id,
       lg.shared_loc_alias_id as rating_spec,
       cwms_rating.get_opening_unit(cwms_rating.get_template(lg.shared_loc_alias_id), 'EN') as opening_unit_en,
       cwms_rating.get_opening_unit(cwms_rating.get_template(lg.shared_loc_alias_id), 'SI') as opening_unit_si
  from cwms_office o,
       at_base_location bl1,
       at_physical_location pl1,
       at_base_location bl2,
       at_physical_location pl2,
       at_project p,
       at_outlet ou,
       at_loc_category lc,
       at_loc_group lg,
       at_loc_group_assignment lga,
       at_gate_group gg,
       cwms_gate_type gt
 where bl1.db_office_code = o.office_code
   and pl1.base_location_code = bl1.base_location_code
   and p.project_location_code = pl1.location_code
   and pl2.base_location_code = bl2.base_location_code
   and ou.outlet_location_code = pl2.location_code
   and ou.project_location_code = p.project_location_code
   and lga.location_code = ou.outlet_location_code
   and lg.loc_group_code = lga.loc_group_code
   and lc.loc_category_code = lg.loc_category_code
   and upper(lc.loc_category_id) = 'RATING'
   and gg.loc_group_code = lg.loc_group_code
   and gt.gate_type_code = gg.gate_type_code
/

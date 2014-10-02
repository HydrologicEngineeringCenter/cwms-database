insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_OUTLET', null,
'
/**
 * Displays information about outlets at CWMS projects
 *
 * @since CWMS 2.1
 *
 * @field office_id       Office owning project
 * @field project_id      Location identifier of project
 * @field outlet_id       Outlet identifier
 * @field rating_group_id Identifier of rating group outlet belongs to
 * @field rating_spec     Rating specification used for outlet
 * @field opening_unit_en Opening unit in English unit system
 * @field opening_unit_si Opening unit in SI unit system
 */
');
create or replace force view av_outlet
(
   office_id,
   project_id,
   outlet_id,
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
       ||pl2.sub_location_id as outlet_id,
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
       at_loc_group_assignment lga
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
/            

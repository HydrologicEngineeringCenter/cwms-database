insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_GATE_SETTING', null,
'
/**
 * Displays information on gate settings at CWMS projects
 *
 * @since CWMS 2.1
 *
 * @field gate_change_code  Unique numeric value identifying gate change
 * @field office_id         Office owning project
 * @field outlet_id         Outlet identifier
 * @field gate_opening_en   Gate opening in English unit
 * @field opening_unit_en   Opening unit in English unit system
 * @field gate_opening_si   Gate opening in SI unit
 * @field opening_unit_si   Opening unit in SI unit system
  */
');
create or replace force view av_gate_setting
(
   gate_change_code,
   office_id,
   outlet_id,
   gate_opening_en,
   opening_unit_en,
   gate_opening_si,
   opening_unit_si
)
as
select gs.gate_change_code,
       o.office_id as office_id,
       bl.base_location_id
       ||substr('-', 1, length(pl.sub_location_id))
       ||pl.sub_location_id as outlet_id,
       case
       when cwms_rating.get_opening_unit(cwms_rating.get_template(lg.shared_loc_alias_id), 'SI') is null
         or cwms_rating.get_opening_unit(cwms_rating.get_template(lg.shared_loc_alias_id), 'EN') is null
       then null
       else
          cwms_rounding.round_dd_f(
             cwms_util.convert_units(
                gs.gate_opening,
                cwms_rating.get_opening_unit(
                   cwms_rating.get_template(lg.shared_loc_alias_id),
                   'SI'),
                cwms_rating.get_opening_unit(
                   cwms_rating.get_template(lg.shared_loc_alias_id),
                   'EN')),
             '9999999999')
       end as gate_opening_en,
       cwms_rating.get_opening_unit(
          cwms_rating.get_template(lg.shared_loc_alias_id), 
          'EN') as opening_unit_en,
       cwms_rounding.round_dd_f(
          gs.gate_opening, 
          '9999999999') as gate_opening_si,
       cwms_rating.get_opening_unit(
          cwms_rating.get_template(lg.shared_loc_alias_id), 
          'SI') as opening_unit_si
  from at_gate_setting gs,
       at_physical_location pl,
       at_base_location bl,
       cwms_office o,
       at_loc_category lc,
       at_loc_group lg,
       at_loc_group_assignment lga
 where pl.location_code = gs.outlet_location_code
   and bl.base_location_code = pl.base_location_code
   and o.office_code = bl.db_office_code
   and lga.location_code = gs.outlet_location_code
   and lg.loc_group_code = lga.loc_group_code
   and lc.loc_category_code = lg.loc_category_code
   and upper(lc.loc_category_id) = 'RATING'        
/

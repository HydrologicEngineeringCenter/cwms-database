insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_USGS_RATING', null,'
/**
 * Contains information for retrieving ratings from USGS into the CWMS database
 *
 * @since CWMS 2.2
 *
 * @param office_id             The office that owns the rating
 * @param location_id           The CWMS text identifier of the location for the rating 
 * @param usgs_site             The USGS station number
 * @param rating_spec           The CWMS text rating specification
 * @param auto_update_flag      A flag (T/F) specifying whether the rating should be auto-retrieved
 * @param auto_activate_flag    A flag (T/F) specifying whether the rating should be activated if it is auto-retrieved
 * @param auto_migrate_ext_flag A flag (T/F) specifying whether the rating should have any extension migrated if it is auto-retrieved
 * @param rating_method_id      The in-range rating behavior, used to help determine whether Base or EXSA rating should be retrieved
 * @param latest_effecitve      The latest effective date for the rating currently in the database
 * @param latest_create         The latest creation date for the rating currently in the database
 * @param location_code         The CWMS numeric code of the location for the rating
 * @param rating_spec_code      The CWMS numeric code of the rating specification
 */
');
create or replace force view av_usgs_rating(
   office_id,
   location_id,
   usgs_site,
   rating_spec,
   auto_update_flag,
   auto_activate_flag,
   auto_migrate_ext_flag,
   rating_method_id,
   latest_effecitve,
   latest_create,
   location_code,
   rating_spec_code)
as
   select o.office_id,
          bl.base_location_id || substr('-', length(pl.sub_location_id)) || pl.sub_location_id as location_id,
          lga.loc_alias_id as usgs_site,
          bl.base_location_id
          || substr('-', length(pl.sub_location_id))
          || pl.sub_location_id
          || '.' || rt.parameters_id
          || '.' || rt.version
          || '.' || rs.version as rating_spec,
          rs.auto_update_flag,
          rs.auto_activate_flag,
          rs.auto_migrate_ext_flag,
          rm.rating_method_id,
          (select max(r.effective_date)
             from at_rating r
            where r.rating_spec_code = rs.rating_spec_code) as latest_effecitve,
          (select max(r.create_date)
             from at_rating r
            where r.rating_spec_code = rs.rating_spec_code) as latest_create,
          pl.location_code,
          rs.rating_spec_code
     from at_rating_spec rs,
          at_rating_template rt,
          at_rating_ind_param_spec rips,
          at_loc_group_assignment lga,
          at_loc_group lg,
          at_loc_category lc,
          at_physical_location pl,
          at_base_location bl,
          cwms_office o,
          cwms_rating_method rm
    where lc.loc_category_id = 'Agency Aliases'
      and lg.loc_category_code = lc.loc_category_code
      and lg.loc_group_id = 'USGS Station Number'
      and lga.loc_group_code = lg.loc_group_code
      and pl.location_code = lga.location_code
      and bl.base_location_code = pl.base_location_code
      and bl.db_office_code = o.office_code
      and rs.location_code = pl.location_code
      and rs.active_flag = 'T'
      and rt.template_code = rs.template_code
      and (   regexp_like(rt.parameters_id, 'Stage(-[^,;]+)?;Flow(-.+)?' )
           or regexp_like(rt.parameters_id, 'Stage(-[^,;]+)?;Stage(-.+)?'))
      and not regexp_like(rt.parameters_id, 'Stage;Stage-(Shift|Offset)' )
      and rips.template_code = rs.template_code
      and rm.rating_method_code = rips.in_range_rating_method
/

create or replace public synonym cwms_v_usgs_rating for av_usgs_rating;

---------------------
-- AV_RATING_LOCAL --
---------------------

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_RATING_LOCAL', null,
'
/**
 * Displays information on ratings in the local time zone of the rating''s location
 *
 * @since CWMS 2.1
 *
 * @field rating_code        Unique numeric code identifying the rating
 * @field parent_rating_code Unique numeric code identifying the parent of this rating, if any
 * @field office_id          The office owning the rating
 * @field rating_id          The rating identifier
 * @field location_id        The location for the rating - may be an actual location or a location alias
 * @field template_id        The rating template identifier for this rating
 * @field version            The version identifier for this rating
 * @field native_units       The native units for each parameter for this rating
 * @field effective_date     The date/time that this rating goes/went into effect in location''s time zone
 * @field create_date        The date/time that this rating was loaded into the database in location''s time zone
 * @field active_flag        Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether this rating is active
 * @field formula            The formula for this rating if it is formula-based
 * @field description        The description for this rating
 * @field aliased_item       Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.  
 * @field loc_alias_category The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.  
 * @field loc_alias_group    The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.              
 * @field database_units     The databse storage units for each parameter for this rating
 * @field rating_spec_code   The unique numeric code that identifies the rating''s specification in the database
 * @field template_code      The unique numeric code that identifies the rating''s template in the database              
 * @field transition_date    The date/time to start transition (interpolation) from previous rating in location''s time zone
 */
');
create or replace force view av_rating_local
(
   rating_code,
   parent_rating_code,
   office_id,
   rating_id,
   location_id,
   template_id,
   version,
   native_units,
   effective_date,
   create_date,
   active_flag,
   formula,
   description,
   aliased_item,
   loc_alias_category,
   loc_alias_group,
   database_units,
   rating_spec_code,
   template_code,
   transition_date
)
as
   select r.rating_code, 
          r.ref_rating_code as parent_rating_code,
          v.db_office_id as office_id,
          v.location_id 
          || '.' 
          || rt.parameters_id 
          || '.' 
          || rt.version 
          || '.' 
          || rs.version as rating_id,
          v.location_id,
          rt.parameters_id 
          || '.' 
          || rt.version as template_id, rs.version,
          r.native_units, 
          cwms_util.change_timezone(r.effective_date, 'UTC', v.time_zone_name) as effective_date,
          cwms_util.change_timezone(r.create_date, 'UTC', v.time_zone_name) as create_date,
          r.active_flag,
          regexp_replace(upper(r.formula), 'ARG(\d+)', 'I\1'), 
          r.description,
          v.aliased_item,
          v.loc_alias_category,
          v.loc_alias_group,
          case
          when r.formula is not null then null
          else cwms_rating.get_database_units(rt.parameters_id)
          end as database_units,
          rs.rating_spec_code,
          rt.template_code,
          cwms_util.change_timezone(r.transition_date, 'UTC', v.time_zone_name) as transition_date
     from at_rating r,
          at_rating_spec rs,
          at_rating_template rt,
          av_loc2 v
    where rs.rating_spec_code = r.rating_spec_code
      and rt.template_code = rs.template_code
      and v.location_code = rs.location_code
      and v.time_zone_name is not null
      and v.unit_system = 'SI';
/
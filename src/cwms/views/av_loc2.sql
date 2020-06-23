/* Formatted on 5/22/2015 11:37:32 AM (QP5 v5.269.14213.34769) */
--
-- AV_LOC2  (View)
--
--  Dependencies:
--   CWMS_LOCATION_KIND (Table)
--   CWMS_NATION (Table)
--   CWMS_OFFICE (Table)
--   CWMS_STATE (Table)
--   CWMS_TIME_ZONE (Table)
--   CWMS_UNIT_CONVERSION (Table)
--   CWMS_COUNTY (Table)
--   AT_BASE_LOCATION (Table)
--   AT_DISPLAY_UNITS (Table)
--   AT_PHYSICAL_LOCATION (Table)
--   AT_LOC_GROUP_ASSIGNMENT (Table)
--   AT_LOC_GROUP (Table)
--   AT_LOC_CATEGORY (Table)
--

insert into at_clob
        values (
                  cwms_seq.nextval,
                  53,
                  '/VIEWDOCS/AV_LOC2',
                  null,
                  '
/**
 * Displays CWMS Locations, Including Location Aliases
 *
 * @since CWMS 2.0 (modified in CWMS 2.1)
 *
 * @field location_code        Unique number identifying location
 * @field base_location_code   Unique number identifying base location
 * @field db_office_id         The office that owns the location
 * @field base_location_id     The base location
 * @field sub_location_id      The sub-location, if any
 * @field location_id          The full location or location alias
 * @field location_type        User-defined type for location
 * @field unit_system          Unit system for elevation
 * @field elevation            Elevation of location (may be inherited from base location)
 * @field unit_id              Unit of elevation
 * @field vertical_datum       Datum used for elevation (may be inherited from base location)
 * @field longitude            Actual longitude of location (may be inherited from base location)
 * @field latitude             Actual latitude of location (may be inherited from base location)
 * @field horizontal_datum     Datum used for actual latitude and longitude (may be inherited from base location)
 * @field time_zone_name       Location''s local time zone (may be inherited from base location)
 * @field county_name          County encompassing location (may be inherited from base location)
 * @field state_initial        State encompassing location (may be inherited from base location)
 * @field public_name          Public name for location
 * @field long_name            Long name for location
 * @field description          Description of location
 * @field base_loc_active_flag Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code> specifying whether the base location is marked as active
 * @field loc_active_flag      Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code> specifying whether the location is marked as active
 * @field location_kind_id     The object type of the location
 * @field map_label            Label to be used on maps for location (may be inherited from base location)
 * @field published_latitude   Published latitude of location (may be inherited from base location)
 * @field published_longitude  Published longitude of location (may be inherited from base location)
 * @field bounding_office_id   Office whose boundary encompasses location (may be inherited from base location)
 * @field nation_id            Nation encompassing location (may be inherited from base location)
 * @field nearest_city         City nearest to location (may be inherited from base location)
 * @field active_flag          Deprecated - loc_active_flag replaces active_flag as of v2.1
 * @field aliased_item         Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category   The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group      The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field db_office_code       Unique number identifying the office that owns the location
 */
');

create or replace force view av_loc2
(
   location_code,
   base_location_code,
   db_office_id,
   base_location_id,
   sub_location_id,
   location_id,
   location_type,
   unit_system,
   elevation,
   unit_id,
   vertical_datum,
   longitude,
   latitude,
   horizontal_datum,
   time_zone_name,
   county_name,
   state_initial,
   public_name,
   long_name,
   description,
   base_loc_active_flag,
   loc_active_flag,
   location_kind_id,
   map_label,
   published_latitude,
   published_longitude,
   bounding_office_id,
   nation_id,
   nearest_city,
   active_flag,
   aliased_item,
   loc_alias_category,
   loc_alias_group,
   db_office_code
)
as
   select q1.location_code,
          q1.base_location_code,
          q1.db_office_id,
          q1.base_location_id,
          q1.sub_location_id,
          q1.location_id,
          q3.location_type,
          q2.unit_system,
          cwms_util.convert_units(
            nvl(q4.elevation, q5.elevation),
            cwms_util.get_default_units('Elev'),
            cwms_display.retrieve_user_unit_f('Elev', q2.unit_system, null, db_office_id)) as elevation,
          cwms_display.retrieve_user_unit_f('Elev', q2.unit_system, null, db_office_id) unit_id,
          nvl(q4.vertical_datum, q5.vertical_datum) as vertical_datum,
          round (nvl(q4.longitude, q5.longitude), 12) as longitude,
          round (nvl(q4.latitude, q5.latitude), 12) as latitude,
          nvl(q4.horizontal_datum, q5.horizontal_datum) as horizontal_datum,
          nvl(q4.time_zone_name, q5.time_zone_name) as time_zone_name,
          nvl(q4.county_name, q5.county_name) as county_name,
          nvl(q4.state_initial, q5.state_initial) as state_initial,
          q3.public_name,
          q3.long_name,
          q3.description,
          q3.base_loc_active_flag,
          q3.loc_active_flag,
          q3.location_kind_id,
          nvl(q4.map_label, q5.map_label) as map_label,
          round (nvl(q4.published_latitude, q5.published_latitude), 12) as published_latitude,
          round (nvl(q4.published_longitude, q5.published_longitude), 12) as published_longitude,
          nvl(q4.bounding_office_id, q5.bounding_office_id) as bounding_office_id,
          nvl(q4.nation_id, q5.nation_id) as nation_id,
          nvl(q4.nearest_city, q5.nearest_city) as nearest_city,
          q3.active_flag,
          q1.aliased_item,
          q1.loc_alias_category,
          q1.loc_alias_group,
          q1.db_office_code
     from (------------------------------------
           -- location and alias ids, office --
           ------------------------------------
           (----------------
            -- un-aliased --
            ----------------
            select pl.location_code,
                   bl.base_location_code,
                   bl.base_location_id,
                   pl.sub_location_id,
                   bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id as location_id,
                   o.office_code as db_office_code,
                   o.office_id as db_office_id,
                   null as aliased_item,
                   null as loc_alias_category,
                   null as loc_alias_group
              from at_physical_location pl,
                   at_base_location bl,
                   cwms_office o
             where bl.base_location_code = pl.base_location_code
               and o.office_code = bl.db_office_code
           )
           union all
           (------------------------
            -- alias for location --
            ------------------------
            select pl.location_code,
                   bl.base_location_code,
                   bl.base_location_id,
                   pl.sub_location_id,
                   lga.loc_alias_id as location_id,
                   o.office_code as db_office_code,
                   o.office_id as db_office_id,
                   'LOCATION' as aliased_item,
                   lc.loc_category_id as alias_category,
                   lg.loc_group_id as alias_group
              from at_physical_location pl,
                   at_base_location bl,
                   at_loc_category lc,
                   at_loc_group lg,
                   at_loc_group_assignment lga,
                   cwms_office o
             where pl.base_location_code <> pl.location_code
               and bl.base_location_code = pl.base_location_code
               and o.office_code = bl.db_office_code
               and lga.location_code = pl.location_code
               and lga.loc_alias_id is not null
               and lg.loc_group_code = lga.loc_group_code
               and lc.loc_category_code = lg.loc_category_code
           )
           union all
           (-----------------------------
            -- alias for base location --
            -----------------------------
            select pl.location_code,
                   bl.base_location_code,
                   bl.base_location_id,
                   pl.sub_location_id,
                   lga.loc_alias_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id as location_id,
                   o.office_code as db_office_code,
                   o.office_id as db_office_id,
                   case
                   when pl.base_location_code = pl.location_code then 'LOCATION'
                   else 'BASE LOCATION'
                   end as aliased_item,
                   lc.loc_category_id as loc_alias_category,
                   lg.loc_group_id as loc_alias_group
              from at_physical_location pl,
                   at_base_location bl,
                   at_loc_category lc,
                   at_loc_group lg,
                   at_loc_group_assignment lga,
                   cwms_office o
             where bl.base_location_code = pl.base_location_code
               and o.office_code = bl.db_office_code
               and lga.location_code = bl.base_location_code
               and lga.loc_alias_id is not null
               and lg.loc_group_code = lga.loc_group_code
               and lc.loc_category_code = lg.loc_category_code
           )
          ) q1
          join
          (--------------------------------------
           -- unit system, unit, and elevation --
           --------------------------------------
           select 'EN' as unit_system from dual
           union all
           select 'SI' as unit_system from dual
          ) q2 on 1=1
          left outer join
          (------------------------------
           -- other non-inherited info --
           ------------------------------
           select location_code,
                  bl.active_flag as base_loc_active_flag,
                  pl.active_flag as loc_active_flag,
                  case
                  when bl.active_flag = 'T' and pl.active_flag = 'T'
                  then 'T'
                  else 'F'
                  end as active_flag,
                  pl.public_name,
                  pl.long_name,
                  pl.description,
                  pl.location_type,
                  lk.location_kind_id
             from at_physical_location pl,
                  at_base_location bl,
                  cwms_location_kind lk
            where bl.base_location_code = pl.base_location_code
              and lk.location_kind_code = pl.location_kind
          ) q3 on q3.location_code = q1.location_code
          left outer join
          (---------------------------------------------------
           -- info that can be inherited from base location --
           ---------------------------------------------------
           select q41.location_code,
                  elevation,
                  vertical_datum,
                  latitude,
                  longitude,
                  horizontal_datum,
                  time_zone_name,
                  county_name,
                  state_initial,
                  map_label,
                  published_latitude,
                  published_longitude,
                  nearest_city,
                  bounding_office_id,
                  nation_id
             from (-----------------------------
                   -- info on location record --
                   -----------------------------
                   select pl.location_code,
                          pl.elevation,
                          pl.vertical_datum,
                          pl.latitude,
                          pl.longitude,
                          pl.horizontal_datum,
                          pl.time_zone_code,
                          pl.county_code,
                          pl.nation_code,
                          pl.map_label,
                          pl.published_latitude,
                          pl.published_longitude,
                          pl.office_code,
                          pl.nearest_city
                     from at_physical_location pl
                  ) q41
                  left outer join
                  (---------------
                   -- time zone --
                   ---------------
                   select pl.location_code,
                          tz.time_zone_name
                     from at_physical_location pl,
                          cwms_time_zone tz
                    where tz.time_zone_code = pl.time_zone_code
                  ) q42 on q42.location_code = q41.location_code
                  left outer join
                  (----------------------
                   -- county and state --
                   ----------------------
                   select pl.location_code,
                          cty.county_name,
                          st.state_initial
                     from at_physical_location pl,
                          cwms_county cty,
                          cwms_state st
                    where cty.county_code = pl.county_code
                      and st.state_code = cty.state_code
                  ) q43 on q43.location_code = q41.location_code
                  left outer join
                  (---------------------
                   -- bounding office --
                   ---------------------
                   select pl.location_code,
                          o.office_id as bounding_office_id
                     from at_physical_location pl,
                          cwms_office o
                    where o.office_code = pl.office_code
                  ) q44 on q44.location_code = q41.location_code
                  left outer join
                  (------------
                   -- nation --
                   ------------
                   select pl.location_code,
                          nt.nation_id
                     from at_physical_location pl,
                          cwms_nation nt
                    where nt.nation_code = pl.nation_code
                  ) q45 on q45.location_code = q41.location_code
          ) q4 on q4.location_code = q1.location_code
          left outer join
          (-------------------------------------------------
           -- base location info to inherit if necessary --
           -------------------------------------------------
           select q51.location_code,
                  elevation,
                  vertical_datum,
                  latitude,
                  longitude,
                  horizontal_datum,
                  time_zone_name,
                  county_name,
                  state_initial,
                  map_label,
                  published_latitude,
                  published_longitude,
                  nearest_city,
                  bounding_office_id,
                  nation_id
             from (-----------------------------
                   -- info on location record --
                   -----------------------------
                   select pl.location_code,
                          pl.elevation,
                          pl.vertical_datum,
                          pl.latitude,
                          pl.longitude,
                          pl.horizontal_datum,
                          pl.time_zone_code,
                          pl.county_code,
                          pl.nation_code,
                          pl.map_label,
                          pl.published_latitude,
                          pl.published_longitude,
                          pl.office_code,
                          pl.nearest_city
                     from at_physical_location pl
                  ) q51
                  left outer join
                  (---------------
                   -- time zone --
                   ---------------
                   select pl.location_code,
                          tz.time_zone_name
                     from at_physical_location pl,
                          cwms_time_zone tz
                    where tz.time_zone_code = pl.time_zone_code
                  ) q52 on q52.location_code = q51.location_code
                  left outer join
                  (----------------------
                   -- county and state --
                   ----------------------
                   select pl.location_code,
                          cty.county_name,
                          st.state_initial
                     from at_physical_location pl,
                          cwms_county cty,
                          cwms_state st
                    where cty.county_code = pl.county_code
                      and st.state_code = cty.state_code
                  ) q53 on q53.location_code = q51.location_code
                  left outer join
                  (---------------------
                   -- bounding office --
                   ---------------------
                   select pl.location_code,
                          o.office_id as bounding_office_id
                     from at_physical_location pl,
                          cwms_office o
                    where o.office_code = pl.office_code
                  ) q54 on q54.location_code = q51.location_code
                  left outer join
                  (------------
                   -- nation --
                   ------------
                   select pl.location_code,
                          nt.nation_id
                     from at_physical_location pl,
                          cwms_nation nt
                    where nt.nation_code = pl.nation_code
                  ) q55 on q55.location_code = q51.location_code
          ) q5 on q5.location_code = q1.base_location_code
/

grant select on av_loc2 to cwms_user;

create or replace public synonym cwms_v_loc_lvl_source for av_loc2;


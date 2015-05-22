--
-- AV_LOC  (View)
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
--

insert into at_clob
        values (
                  cwms_seq.nextval,
                  53,
                  '/VIEWDOCS/AV_LOC',
                  null,
                  '
/**
 * Displays CWMS Locations
 *
 * @since CWMS 2.0 (modified in CWMS 2.1)
 *
 * @field location_code        Unique number identifying location
 * @field base_location_code   Unique number identifying base location
 * @field db_office_id         The office that owns the location
 * @field base_location_id     The base location
 * @field sub_location_id      The sub-location, if any
 * @field location_id          The full location
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
 * @field active_flag          Depricated - loc_active_flag replaces active_flag as of v2.1
 */
');

create or replace force view av_loc
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
   active_flag
)
as
   select location_code,
          base_location_code,
          db_office_id,
          base_location_id,
          sub_location_id,
          location_id,
          location_type,
          unit_system,
          (elevation * factor + offset) elevation,
          to_unit_id unit_id,
          vertical_datum,
          round (longitude, 12) as longitude,
          round (latitude, 12) as latitude,
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
          round (published_latitude, 12) as published_latitude,
          round (published_longitude, 12) as published_longitude,
          bounding_office_id,
          nation_id,
          nearest_city,
          loc_active_flag
     from (select o.office_code db_office_code,
                  p1.location_code,
                  base_location_code,
                  o.office_id db_office_id,
                  base_location_id,
                  p1.sub_location_id,
                     base_location_id
                  || substr ('-', 1, length (p1.sub_location_id))
                  || p1.sub_location_id
                     as location_id,
                  p1.location_type,
                  nvl (p1.elevation, p2.elevation) as elevation,
                  nvl (p1.vertical_datum, p2.vertical_datum)
                     as vertical_datum,
                  nvl (p1.longitude, p2.longitude) as longitude,
                  nvl (p1.latitude, p2.latitude) as latitude,
                  nvl (p1.horizontal_datum, p2.horizontal_datum)
                     as horizontal_datum,
                  time_zone_name,
                  county_name,
                  state_initial,
                  p1.public_name,
                  p1.long_name,
                  p1.description,
                  b.active_flag base_loc_active_flag,
                  p1.active_flag loc_active_flag,
                  location_kind_id,
                  nvl (p1.map_label, p2.map_label) as map_label,
                  nvl (p1.published_latitude, p2.published_latitude)
                     as published_latitude,
                  nvl (p1.published_longitude, p2.published_longitude)
                     as published_longitude,
                  nvl (o1.office_id, o2.office_id) as bounding_office_id,
                  nation_id,
                  nvl (p1.nearest_city, p2.nearest_city) as nearest_city
             from (((((((at_physical_location p1
                         left outer join cwms_office o1 using (office_code))
                        join
                        (at_physical_location p2
                         left outer join cwms_office o2 using (office_code))
                           using (base_location_code)
                        join at_base_location b using (base_location_code))
                       join cwms_office o on b.db_office_code = o.office_code)
                      left outer join cwms_location_kind
                         on location_kind_code = p1.location_kind)
                     left outer join cwms_time_zone t
                        on t.time_zone_code =
                              coalesce (p1.time_zone_code, p2.time_zone_code))
                    left outer join cwms_county c
                       on c.county_code =
                             coalesce (p1.county_code, p2.county_code))
                   left outer join cwms_state using (state_code))
                  left outer join cwms_nation n
                     on n.nation_code =
                           coalesce (p1.nation_code, p2.nation_code)
            where p1.location_code != 0 and p2.sub_location_id is null) aa
          natural join
          (select adu.db_office_code,
                  adu.unit_system,
                  cuc.to_unit_id,
                  factor,
                  offset
             from at_display_units adu, cwms_unit_conversion cuc
            where     adu.parameter_code = 10
                  and adu.display_unit_code = cuc.to_unit_code
                  and cuc.from_unit_code = 38) bb;
/

show errors;
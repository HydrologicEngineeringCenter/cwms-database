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

CREATE OR REPLACE VIEW AV_LOC 
AS
select LOCATION_CODE, 
       BASE_LOCATION_CODE, 
       DB_OFFICE_ID, 
       BASE_LOCATION_ID, 
       SUB_LOCATION_ID, 
       LOCATION_ID, 
       LOCATION_TYPE, 
       UNIT_SYSTEM, 
       ELEVATION, 
       UNIT_ID, 
       VERTICAL_DATUM, 
       round(LONGITUDE,12) LONGITUDE, 
       round(LATITUDE, 12) LATITUDE,
       HORIZONTAL_DATUM, 
       TIME_ZONE_NAME, 
       COUNTY_NAME, 
       STATE_INITIAL, 
       PUBLIC_NAME, 
       LONG_NAME, 
       DESCRIPTION, 
       BASE_LOC_ACTIVE_FLAG, 
       LOC_ACTIVE_FLAG, 
       LOCATION_KIND_ID, 
       MAP_LABEL, 
       round(PUBLISHED_LATITUDE, 12) PUBLISHED_LATITUDE, 
       round(PUBLISHED_LONGITUDE,12) PUBLISHED_LONGITUDE, 
       BOUNDING_OFFICE_ID, 
       NATION_ID, 
       NEAREST_CITY, 
       active_flag
from 
( with phy_loc as
  ( select loc.location_code,
           loc.base_location_code,
           blo.db_office_code,         
           blo.base_location_id,
           loc.sub_location_id,
           blo.base_location_id||nvl2(loc.sub_location_id,'-',null)||loc.sub_location_id as location_id,
           loc.location_type,
           nvl (loc.elevation,        bas.elevation)        as si_elevation,
           nvl (loc.vertical_datum,   bas.vertical_datum)   as vertical_datum,
           nvl (loc.longitude,        bas.longitude)        as longitude,
           nvl (loc.latitude,         bas.latitude)         as latitude,
           nvl (loc.horizontal_datum, bas.horizontal_datum) as horizontal_datum,
           nvl (loc.time_zone_code,   bas.time_zone_code)   as time_zone_code,
           nvl (loc.county_code,      bas.county_code)      as county_code,         
           loc.public_name,
           loc.long_name,
           loc.description,
           loc.location_kind,
           nvl (loc.map_label, bas.map_label)         as map_label,
           nvl (loc.published_latitude,  bas.published_latitude)  as published_latitude,
           nvl (loc.published_longitude, bas.published_longitude) as published_longitude,
           nvl (loc.office_code, bas.office_code)     as office_code,
           nvl (loc.nation_code, bas.nation_code)     as nation_code,
           nvl (loc.nearest_city, bas.nearest_city)   as nearest_city,
           blo.active_flag                            as base_loc_active_flag,
           loc.active_flag                            as loc_active_flag,
           loc.active_flag                            as active_flag
    from  -- join the base location metadata (bas) with the location (loc)
          cwms_20.at_physical_location loc left join
          cwms_20.at_physical_location bas on ( bas.location_code = loc.base_location_code ) left join
          cwms_20.at_base_location     blo on ( blo.base_location_code = loc.base_location_code ) 
  ), 
  unit_system as
  ( select u.*, factor, offset from 
    ( select 'SI' as unit_system, 'm' unit_id from dual 
      union
      select 'EN', cwms_20.cwms_display.retrieve_user_unit_f('Elev', 'EN', null, cwms_util.user_office_id) from dual
    ) u left join 
    cwms_20.cwms_unit_conversion on ( from_unit_id='m' and to_unit_id=unit_id )
  )
  select odb.office_id db_office_id, 
         obo.office_id bounding_office_id,
         location_kind_id, 
         time_zone_name, 
         county_name, 
         state_initial,
         nation_id,
         unit_system,
         unit_id,
         si_elevation*factor elevation,
         p.*
  from   phy_loc p left join  
         cwms_20.cwms_office    odb on ( odb.office_code    = p.db_office_code ) left join
         cwms_20.cwms_office    obo on ( obo.office_code    = p.office_code )    left join
         cwms_20.cwms_location_kind on ( location_kind_code = p.location_kind )  left join
         cwms_20.cwms_time_zone   t on ( t.time_zone_code   = p.time_zone_code ) left join
         cwms_20.cwms_county      c on ( c.county_code      = p.county_code )    left join 
         cwms_20.cwms_state       s on ( s.state_code       = c.state_code )     left join 
         cwms_20.cwms_nation      n on ( n.nation_code      = p.nation_code )    cross join
         unit_system              u     
  where  location_code != 0
);

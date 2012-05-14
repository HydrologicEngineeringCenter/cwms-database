--
-- AV_LOC  (View)
--
--  Dependencies:
--   AT_LOCATION_KIND (Table)
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

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC', null,
'
/**
 * Displays CWMS Time Locations
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
 * @field elevation            Elevation of location
 * @field unit_id              Unit of elevation
 * @field vertical_datum       Datum used for elevation
 * @field longitude            Actual longitude of location
 * @field latitude             Actual latitude of location
 * @field horizontal_datum     Datum used for actual latitude and longitude
 * @field time_zone_name       Location''s local time zone
 * @field county_name          County encompassing location
 * @field state_initial        State encompassing location
 * @field public_name          Public name for location
 * @field long_name            Long name for location
 * @field description          Description of location
 * @field base_loc_active_flag Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code> specifying whether the base location is marked as active
 * @field loc_active_flag      Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code> specifying whether the location is marked as active
 * @field location_kind_id     The geographic type of the location
 * @field map_label            Label to be used on maps for location
 * @field published_latitude   Published latitude of location
 * @field published_longitude  Published longitude of location
 * @field bounding_office_id   Office whose boundary encompasses location
 * @field nation_id            Nation encompassing location
 * @field nearest_city         City nearest to location
 */
');
CREATE OR REPLACE FORCE VIEW av_loc
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
    nearest_city
)
AS
    SELECT    location_code, base_location_code, db_office_id, base_location_id,
                sub_location_id, location_id, location_type, unit_system,
                (elevation * factor + offset) elevation, to_unit_id unit_id,
                vertical_datum, longitude, latitude, horizontal_datum,
                time_zone_name, county_name, state_initial, public_name,
                long_name, description, base_loc_active_flag, loc_active_flag,
                location_kind_id, map_label, published_latitude,
                published_longitude, bounding_office_id, nation_id, nearest_city
      FROM        (SELECT     c.office_code db_office_code, location_code,
                                 base_location_code, c.office_id db_office_id,
                                 base_location_id, sub_location_id,
                                 base_location_id || SUBSTR ('-', 1, LENGTH (sub_location_id)) || sub_location_id location_id,
                                 location_type, elevation, vertical_datum, longitude,
                                 latitude, horizontal_datum, time_zone_name,
                                 county_name, state_initial, a.public_name,
                                 a.long_name, a.description,
                                 b.active_flag base_loc_active_flag,
                                 a.active_flag loc_active_flag, location_kind_id,
                                 map_label, published_latitude, published_longitude,
                                 d.office_id bounding_office_id, nation_id,
                                 nearest_city
                        FROM         (   (    (     (   (    (     (   at_physical_location a
                                                                      LEFT OUTER JOIN
                                                                          cwms_office d
                                                                      USING (office_code))
                                                                 JOIN
                                                                     at_base_location b
                                                                 USING (base_location_code))
                                                            JOIN
                                                                cwms_office c
                                                            ON b.db_office_code =
                                                                    c.office_code)
                                                      LEFT OUTER JOIN
                                                          at_location_kind
                                                      ON location_kind =
                                                              location_kind_code)
                                                 LEFT OUTER JOIN
                                                     cwms_time_zone
                                                 USING (time_zone_code))
                                            LEFT OUTER JOIN
                                                cwms_county
                                            USING (county_code))
                                      LEFT OUTER JOIN
                                          cwms_state
                                      USING (state_code))
                                 LEFT OUTER JOIN
                                     cwms_nation
                                 USING (nation_code)
                      WHERE     location_code != 0) aa
                NATURAL JOIN
                    (SELECT     adu.db_office_code, adu.unit_system, cuc.to_unit_id,
                                 factor, offset
                        FROM     at_display_units adu, cwms_unit_conversion cuc
                      WHERE          adu.parameter_code = 10
                                 AND adu.display_unit_code = cuc.to_unit_code
                                 AND cuc.from_unit_code = 38) bb
/
SHOW ERRORS;

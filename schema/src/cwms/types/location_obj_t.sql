create type location_obj_t
/**
 * Holds information about at CWMS location
 *
 * @see type location_ref_t
 *
 * @member location_ref         the <a href=type_location_ref_t.html>location reference</a>
 * @member state_initial        State encompassing location
 * @member county_name          County encompassing location
 * @member time_zone_name       Location's local time zone
 * @member location_type        User-defined type for location
 * @member latitude             Actual latitude of location if geometry_type_code = 1
 * @member longitude            Actual longitude of location if geometry_type_code = 1
 * @member horizontal_datum     Datum used for actual latitude and longitude
 * @member elevation            Elevation of location
 * @member elev_unit_id         Unit of elevation
 * @member vertical_datum       Datum used for elevation
 * @member public_name          Public name for location
 * @member long_name            Long name for location
 * @member description          Description of location
 * @member active_flag          Flag (<code><big>'T'</big></code> or <code><big>'F'</big></code> specifying whether the location is marked as active
 * @member location_kind_id     The geographic type of the location
 * @member map_label            Label to be used on maps for location
 * @member published_latitude   Published latitude of location
 * @member published_longitude  Published longitude of location
 * @member bounding_office_id   Office whose boundary encompasses location
 * @member nation_id            Nation encompassing location
 * @member nearest_city         City nearest to location
 * @member geometry             Geometry of location (POINT, POLYGON, etc..)
 * @member geometry_type_code   The type of "geometry" member. May be one of
 * <p>
 * <table class="desc">
 *   <tr>
 *     <td>NULL</td>
 *     <td>No geometry stored for location</td>
 *   </tr>
 *   <tr>
 *     <td>1</td>
 *     <td>Single point</td>
 *   </tr>
 *   <tr>
 *     <td>2</td>
 *     <td>Single line string</td>
 *   </tr>
 *   <tr>
 *     <td>3</td>
 *     <td>Single polygon (with or without holes)</td>
 *   </tr>
 *   <tr>
 *     <td>4</td>
 *     <td>Heterogeneous collection of elements</td>
 *   </tr>
 *   <tr>
 *     <td>5</td>
 *     <td>Multiple points</td>
 *   </tr>
 *   <tr>
 *     <td>6</td>
 *     <td>Multiple line strings</td>
 *   </tr>
 *   <tr>
 *     <td>7</td>
 *     <td>Multiple disjoint polygons</td>
 *   </tr>
 * </table>
 */
as object
(
   location_ref         location_ref_t,
   state_initial        VARCHAR2 (2),
   county_name          VARCHAR2 (60),
   time_zone_name       VARCHAR2 (28),
   location_type        VARCHAR2 (32),
   latitude             NUMBER,
   longitude            NUMBER,
   horizontal_datum     VARCHAR2 (16),
   elevation            NUMBER,
   elev_unit_id         VARCHAR2 (16),
   vertical_datum       VARCHAR2 (16),
   public_name          VARCHAR2 (57),
   long_name            VARCHAR2 (80),
   description          VARCHAR2 (1024),
   active_flag          VARCHAR2 (1),
   location_kind_id     varchar2(32),
   map_label            varchar2(50),
   published_latitude   number,
   published_longitude  number,
   bounding_office_id   varchar2(16),
   bounding_office_name varchar2(32),
   nation_id            varchar2(48),
   nearest_city         varchar2(50),
   geometry             SDO_GEOMETRY,
   geometry_type_code   NUMBER,
   /**
    * Constructs a location_obj_t from a <a href=type_location_ref_t.html>location_ref_t</a>.
    * All other fields are undefined.
    *
    * @param p_location_ref the <a href=type_location_ref_t.html>location_ref_t</a> object
    */
   constructor function location_obj_t(
      p_location_ref in location_ref_t)
      return self as result,
   /**
    * Construction a location_obj_t from a location in the datbase
    *
    * @param p_location_code the database location code
    */
   constructor function location_obj_t(
      p_location_code in number)
      return self as result,
   -- undocumented
   member procedure init(
      p_location_code in number)
             
);
/


create or replace public synonym cwms_t_location_obj for location_obj_t;


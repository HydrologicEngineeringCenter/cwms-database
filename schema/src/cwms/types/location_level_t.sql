-- drop type location_level_t force;
create or replace type location_level_t
/**
 * Holds a location level.  A location level combines a location, parameter, parameter type,
 * duration, and specified level to describe a named level that can be compared against values
 * to determine status conditions. Location levels contain up to five indicators that may
 * be set during such a comparison. Location levels also have optional attribute values
 * that make them suitable for describing guide curves/rule curves
 *
 * @see type seasonal_value_tab_t
 * @see type loc_lvl_indicator_tab_t
 * @see type location_level_tab_t
 *
 * @member office_id                   The office that owns the location and specified level
 * @member location_id                 The location component of the location level
 * @member parameter_id                The parameter component of the location level
 * @member parameter_type_id           The parameter type component of the location level
 * @member duration_id                 The duration component of the location level
 * @member specified_level_id          The specified level component of the location level
 * @member level_date                  The effective date of the location level
 * @member timezone_id                 The time zone of the level_date member
 * @member level_value                 The value of the location level if it is a constant value (not recurring pattern or time series)
 * @member level_units_id              The unit used for the constant or varying location level value
 * @member level_comment               A comment about the location level
 * @member attribute_parameter_id      The parameter component of the location level attribute, if any
 * @member attribute_parameter_type_id The parameter type component of the location level attribute, if any
 * @member attribute_duration_id       The duration component of the location level attribute, if any
 * @member attribute_value             The value of the location level attribute, if any
 * @member attribute_units_id          The unit of the location level attribute value, if any
 * @member attribute_comment           A comment about the location level attribute
 * @member interval_origin             The start time of any of the recurring intervals if the location level is a recurring pattern of values
 * @member interval_months             The recurring interval duration if the location level is a recurring pattern and is described in units of months and/or years
 * @member interval_minutes            The recurring interval duration if the location level is a recurring pattern and is described in units of days or less
 * @member interpolate                 A flag ('T' or 'F') specifying whether to interpolate for level values at offsets between the specified offsets into the interval
 * @member seasonal_values             The values of the location level if it is a recurring pattern of values (not constant value or time series)
 * @member tsid                        The time series identifier representing the location level if it is a time series (not constant value or recurring pattern)
 * @member expiration_date             The date/time at which this level expires
 * @member indicators                  The location level indicators associated with this location level
 * @member constituents                The constituents table if this is a virtual location level, one constituent per row. Each row has 3, 5, or 6 values. The first 3 values
 *                                     are the constituent abbreviation, type, and name, respectively. The next values are used only for location level constituents that have
 *                                     attributes, and are the constituent level attribute id, attribute value, and attribute value unit, respectively. If there are only five
 *                                     values, the attribute value is in database storage units for the attribute parameter.
 * @member connections                 The constituents connections string if this is a virtual location level
 */
is object (
   office_id                   varchar2(16),
   location_id                 varchar2(57),
   parameter_id                varchar2(49),
   parameter_type_id           varchar2(16),
   duration_id                 varchar2(16),
   specified_level_id          varchar2(256),
   level_date                  date,
   timezone_id                 varchar2(28),
   level_value                 number,
   level_units_id              varchar2(16),
   level_comment               varchar2(256),
   attribute_parameter_id      varchar2(49),
   attribute_parameter_type_id varchar2(16),
   attribute_duration_id       varchar2(16),
   attribute_value             number,
   attribute_units_id          varchar2(16),
   attribute_comment           varchar2(256),
   interval_origin             date,
   interval_months             integer,
   interval_minutes            integer,
   interpolate                 varchar2(1),
   tsid                        varchar2(191),
   expiration_date             date,
   seasonal_values             seasonal_value_tab_t,
   indicators                  loc_lvl_indicator_tab_t,
   constituents                str_tab_tab_t,
   connections                 varchar2(256),
   -- not documented
   constructor function location_level_t(
      p_obj zlocation_level_t)
      return self as result,
   -- not documented
   constructor function location_level_t
      return self as result,        
   -- not documented
   member function zlocation_level
      return zlocation_level_t,
   /**
    * Returns the full location level identifier
    */
   member function location_level_id
      return varchar2,
   /**
    * Returns the full attribute identifier, if any
    */
   member function attribute_id
      return varchar2,
   /**
    * Converts the location level to the specified time zone. Sets the timzone_id member and converts level_date, expiration_date and interval_origin members
    *
    * @param p_timezone_id The time zone to convert to
    */
   member procedure set_timezone(
      p_timezone_id in varchar2),
   /**
    * Converts the location level to use the specified unit for values. Sets the level_units_id member and converts level_value and seasonal_values members
    *
    * @param p_level_unit The unit to convert the level values to.
    */
   member procedure set_level_unit(
      p_level_unit in varchar2),
   /**
    * Converts the location level to use the specified attribute unit. Sets the attribute_units_id member and converts attribute_value member
    *
    * @param p_attribute_unit The unit to convert the attribute value to.
    */
   member procedure set_attribute_unit(
      p_attribute_unit in varchar2),
   /**
    * Sets the level and attribute units to the default units for the specified unit system
    *
    * @param p_unit_system The unit system to set. Must be ''EN'' or ''SI''
    */
   member procedure set_unit_system(
      p_unit_system in varchar2),
   /**
    * Returns whether this is a virtual location level
    */
   member function is_virtual
      return boolean,
   /**
    * Stores the location level to the database
    */
   member procedure store
);
/


create or replace public synonym cwms_t_location_level for location_level_t;


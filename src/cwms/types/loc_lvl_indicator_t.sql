create type loc_lvl_indicator_t
/**
 * Holds a location level indiator.  A location level indicator indicates the status
 * of a time series of values with respect to a location level.  A location level
 * indicator may have up to five conditions, each with a unique level value in the
 * range (1..5), and multiple conditions may be set simultaneously (e.g. the conditions
 * need not be mutually exclusive).
 *
 * @see type loc_lvl_ind_cond_tab_t
 * @see type loc_lvl_indicator_tab_t
 *
 * @member office_id              The office that owns the location and specified level
 * @member location_id            The location portion of the location level indicator
 * @member parameter_id           The parameter portion of the location level indicator
 * @member parameter_type_id      The parameter type portion of the location level indicator
 * @member duration_id            The duration portion of the location level indicator
 * @member specified_level_id     The specified level portion of the location level indicator
 * @member level_indicator_id     The indicator portion of the location level indicator
 * @member attr_value             The attribute value of the location level, if any, in the specified unit
 * @member attr_units_id          The specified unit of the location level attribute, if any
 * @member attr_parameter_id      The parameter of the location level attribute, if any
 * @member attr_parameter_type_id The parameter type of the location level attribute, if any
 * @member attr_duration_id       The duration of the location level attribute, if any
 * @member ref_specified_level_id The specified level portion of the referenced location level, if any
 * @member ref_attr_value         The attribute value of the referenced location level, if any, in the specified unit
 * @member minimum_duration       The minimum amount of time a condition must continuously evalutate to TRUE for that condition to be considered to be set
 * @member maximum_age            The maximum age of the most current time series value for any conditions to be evalutated
 * @member conditions             The location level indicator conditions
 */
is object
(
   office_id              varchar2(16),
   location_id            varchar2(49),
   parameter_id           varchar2(49),
   parameter_type_id      varchar2(16),
   duration_id            varchar2(16),
   specified_level_id     varchar2(256),
   level_indicator_id     varchar2(32),
   attr_value             number,
   attr_units_id          varchar2(16),
   attr_parameter_id      varchar2(49),
   attr_parameter_type_id varchar2(16),
   attr_duration_id       varchar2(16),
   ref_specified_level_id varchar2(256),
   ref_attr_value         number,
   minimum_duration       interval day to second,
   maximum_age            interval day to second,
   conditions             loc_lvl_ind_cond_tab_t,
   -- not documented
   constructor function loc_lvl_indicator_t(
      p_obj in zloc_lvl_indicator_t)
      return self as result,
   -- not documented
   constructor function loc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result,
   -- not documented
   member procedure init(
      p_obj in zloc_lvl_indicator_t),
   -- not documented
   member function zloc_lvl_indicator
      return zloc_lvl_indicator_t,
   /**
    * Stores the loc_lvl_indicator_t object to the database
    */
   member procedure store,
   /**
    * Retrieves which indicator conditions are set, if any, for the specifed time
    * series values
    *
    * @see type ztsv_array
    * @see type number_tab_t
    *
    * @param p_ts        the time series to use in determining which indicator
    *                    conditions are set
    * @param p_eval_time the date/time to use in determining which indicator conditions
    *        are set.  If NULL, the current date/time is used.
    *
    * @return the condition values for each condition that is set. If no conditions are
    *         set, an empty collection (not NULL) is returned.
    */
   member function get_indicator_values(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number_tab_t,
   /**
    * Retrieves the maximum condition level that is set, if any, for the specified
    * time series values
    *
    * @see type ztsv_array
    *
    * @param p_ts        the time series to use in determining which indicator
    *                    conditions are set
    * @param p_eval_time the date/time to use in determining which indicator conditions
    *        are set.  If NULL, the current date/time is used.
    *
    * @return the maximum condition level that is set, if any, for the specified
    *         time series values. If no condition is set, 0 (zero) is returned.
    */
   member function get_max_indicator_value(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number,
   /**
    * Generates a time series of maximum set level conditions, if, any for the specified
    * time series.
    *
    * @see type ztsv_array
    *
    * @param p_ts         the time series to use in determining which indicator
    *                     conditions are set
    * @param p_start_time the earliest time for which to retrieve the maximum level
    *                     condition that is set
    *
    * @return a time series of the maximum set level conditions, if any. Each element
    *         of the returned time series has its fields set as:
    *         <dl>
    *           <dd>date_time</dd><dt>the time date_time field of the input time series</dt>
    *           <dd>value</dd><dt>the maximum location level condition that was set at that date/time, or 0 (zero) if none were set</dt>
    *           <dd>quality_code</dd><dt>Unused, always set to 0 (zero)</dt>
    *         </dl>
    */
   member function get_max_indicator_values(
      p_ts         in ztsv_array,
      p_start_time in date)
      return ztsv_array

);
/


create or replace public synonym cwms_t_loc_lvl_indicator for loc_lvl_indicator_t;


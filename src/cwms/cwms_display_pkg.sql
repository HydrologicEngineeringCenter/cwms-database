set define off;
create or replace package cwms_display
/**
 * Routines to work with display units and scales
 *
 * @since CWMS 2.1
 *
 * @author Mike Perryman
 */
as

/**
 * Specifies no scale adjustment
 */
scale_as_is constant integer := 0;
/**
 * Specifies adjusting scale so that the range (max - min) follows the 1-2-5 increment
 * rule and the minimum value is an even multiple of the <b>increment</b>.
 */
scale_nice constant integer := 1;
/**
 * Specifies adjusting scale so that the range (max - min) follows the 1-2-5 increment
 * rule and the minimum value is an even multiple of the <b>range</b>.
 */
scale_extra_nice constant integer := 2;
/**
 * Adjusts scale min and max to be "nice".  Nice scales have demarcation increments
 * (tic marks, grid lines, etc...) that are power-of-ten increments of 1, 2, or 5
 * and also have the min and max lie on demarcation increments.
 *
 * @param m_min_value The minimum scale value before/after adjustment
 *
 * @param m_max_value The maximum scale value before/after adjustment
 *
 * @param p_adjustment_level The adjustment level. Adjustment behaviors are
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">p_adjustment_level</th>
 *     <th style="border:1px solid black;">Action</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_display.scale_as_is</td>
 *     <td style="border:1px solid black;">no adjustment is made to the scale<p>(124.87 -&gt; 126.23) =&gt; (124.87 -&gt; 126.23)</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_display.scale_nice</td>
 *     <td style="border:1px solid black;">scale is adjusted so that the range (max - min) follows the 1-2-5 increment rule and the minimum value is an even multiple of the <b>increment</b><p>(124.87 -&gt; 126.23) =&gt; (124.0 -&gt; 129.0)</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_display.scale_extra_nice</td>
 *     <td style="border:1px solid black;">scale is adjusted so that the range (max - min) follows the 1-2-5 increment rule and the minimum value is an even multiple of the <b>range</b><p>(124.87 -&gt; 126.23) =&gt; (120.0 -&gt; 130.0)</td>
 *   </tr>
 * </table>
 */
procedure adjust_scale_limits(
   p_min_value        in out number,
   p_max_value        in out number,
   p_adjustment_level in     integer);
/**
 * Stores pre-set scale limits for specified location, parameter, and unit.  Used
 * for generating standard plots where the scale for a specific parameter should
 * always be the same.
 *
 * @param    p_location_id    The location identifier for the scale limits
 * @param    p_parameter_id   The parameter identifier for the scale limits
 * @param    p_unit_id        The unit for which the scale limits should be applied
 * @param    p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if the specified scale limits already exist.  If 'F', the existing scale limits are updated with the specified parameters.
 * @param    p_ignore_nulls   A flag ('T' or 'F') specifying whether to ignore NULL parameters when updating existing scale limits. If 'T', no existing data will be overwritten by NULL
 * @param    p_scale_min      The minimum scale value for the specified location, parameter, and unit
 * @param    p_scale_max      The maximum scale value for the specified location, parameter, and unit
 * @param    p_office_id      The office owning the scale limits
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified scale limits already exist
 */
procedure store_scale_limits(
   p_location_id    in varchar2,
   p_parameter_id   in varchar2, 
   p_unit_id        in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_scale_min      in number,
   p_scale_max      in number,
   p_office_id      in varchar2 default null);
/**
 * Retrieves pre-set scale limits for specified location, parameter, and unit.  Used
 * for generating standard plots where the scale for a specific parameter should
 * always be the same.
 *
 * @param    p_scale_min        The minimum scale value for the specified location, parameter, and unit
 * @param    p_scale_max        The maximum scale value for the specified location, parameter, and unit
 * @param    p_derived          Specifies whether the scale limits were matched exactly ('F') or derived from limits from the same location and parameter, but a different unit ('T')
 * @param    p_location_id      The location identifier for the scale limits
 * @param    p_parameter_id     The parameter identifier for the scale limits
 * @param    p_unit_id          The unit for which the scale limits should be applied
 * @param    p_fail_if_exists   A flag ('T' or 'F') specifying whether the routine should fail if the specified scale limits already exist.  If 'F', the existing scale limits are updated with the specified parameters.
 * @param    p_adjustment_level Same as for <a href="#procedure adjust_scale_limits(p_min_value in out number,p_max_value in out number,p_adjustment_level in integer)">adjust_scale_limits</a>
 * @param    p_office_id        The office owning the scale limits
 */
procedure retrieve_scale_limits(
   p_scale_min        out number,
   p_scale_max        out number,
   p_derived          out varchar2,
   p_location_id      in  varchar2,
   p_parameter_id     in  varchar2, 
   p_unit_id          in  varchar2, 
   p_adjustment_level in  number default 0,
   p_office_id        in  varchar2 default null);
/**
 * Deletes pre-set scale limits for specified location, parameter, and unit
 *
 * @param    p_location_id  The location identifier for the scale limits
 * @param    p_parameter_id The parameter identifier for the scale limits
 * @param    p_unit_id      The unit for which the scale limits should be deleted.  If NULL, scale limits for all units with the specified location and parameter are deleted
 * @param    p_office_id    The office owning the scale limits
 */
procedure delete_scale_limits(
   p_location_id    in varchar2,
   p_parameter_id   in varchar2, 
   p_unit_id        in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Catalogs scale limits in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_limits_catalog A cursor containing all matching scale limits.  The cursor contains
 * the following columns and is sorted by the first three:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the scale limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">parameter_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The parameter identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The unit identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">scale_min</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The minimum scale limit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">scale_max</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The maximum scale limit</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask  The location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_parameter_id_mask  The parameter pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_unit_id_mask The unit pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_scale_limits(
   p_limits_catalog    out sys_refcursor,
   p_location_id_mask  in  varchar2 default '*',
   p_parameter_id_mask in  varchar2 default '*', 
   p_unit_id_mask      in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null);
/**
 * Catalogs scale limits in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask  The location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_parameter_id_mask  The parameter pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_unit_id_mask The unit pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching scale limits.  The cursor contains
 * the following columns and is sorted by the first three:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the scale limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">parameter_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The parameter identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The unit identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">scale_min</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The minimum scale limit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">scale_max</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The maximum scale limit</td>
 *   </tr>
 * </table>
 */
function cat_scale_limits_f(
   p_location_id_mask  in  varchar2 default '*',
   p_parameter_id_mask in  varchar2 default '*', 
   p_unit_id_mask      in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null)
   return sys_refcursor;
/**
 * Stores a preferred parameter unit to the database
 *
 * @param p_parameter_id   The parameter to store the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if the specified preferred already exists.  If 'F', the existing preferred unit are updated with the specified parameters.
 * @param p_ignore_nulls   A flag ('T' or 'F') specifying whether to ignore NULL parameters when updating existing preferred unit. If 'T', no existing data will be overwritten by NULL
 * @param p_unit_id        The preferred unit for the specified parameter and unit system
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the preferred unit is already exists in the database
 */
procedure store_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_unit_id        in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Retrieves a preferred parameter unit from the database
 *
 * @param p_unit_id        The preferred unit for the specified parameter and unit system
 * @param p_parameter_id   The parameter to retrieve the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_unit(
   p_unit_id        out varchar2,
   p_parameter_id   in  varchar2,
   p_unit_system    in  varchar2,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves a preferred parameter unit from the database
 *
 * @param p_parameter_id   The parameter to delete the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 */
procedure delete_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Catalogs preferred units in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_unit_catalog A cursor containing all matching preferred units.  The cursor contains
 * the following and is sorted by the first three:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">parameter_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The parameter identifier for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">unit_system</td>
 *     <td style="border:1px solid black;">varchar2(2)</td>
 *     <td style="border:1px solid black;">The unit system for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The preferred unit identifier</td>
 *   </tr>
 * </table>
 *
 * @param p_parameter_id_mask  The parameter pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_unit_system_mask The unit system pattern to match. Use 'EN', 'SI', or '*'
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_unit(
   p_unit_catalog      out sys_refcursor,
   p_parameter_id_mask in  varchar2 default '*',
   p_unit_system_mask  in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null);
/**
 * Catalogs preferred units in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_parameter_id_mask  The parameter pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_unit_system_mask The unit system pattern to match. Use 'EN', 'SI', or '*'
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching preferred units.  The cursor contains
 * the following and is sorted by the first three:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">parameter_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The parameter identifier for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">unit_system</td>
 *     <td style="border:1px solid black;">varchar2(2)</td>
 *     <td style="border:1px solid black;">The unit system for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The preferred unit identifier</td>
 *   </tr>
 * </table>
 */
function cat_unit_f(
   p_parameter_id_mask in varchar2 default '*',
   p_unit_system_mask  in varchar2 default '*',
   p_office_id_mask    in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves a time series of the maximum set location level status indicator condition
 * values for a time series, optionally mapping the default values of 1..5 onto a
 * different range.
 *
 * @see cwms_util.eval_expression
 *
 * @param p_indicators      The time series of maximum set location indicator conditions, after any mapping
 * @param p_tsid            The time series to use to determine the which indicator conditions are set
 * @param p_level_id        The location level to use to determine the which indicator conditions are set
 * @param p_indicator_id    The location level indicator to use to determine the which conditions are set
 * @param p_start_time      The start of the time window to retrieve the data for
 * @param p_end_time        The end of the time window to retrieve the data for
 * @param p_attribute_id    The location level attribute identifier, if any
 * @param p_attribute_value The location level attribute value, if any, in the specified unit
 * @param p_attribute_unit  The unit for the location level attribute value, if any
 * @param p_time_zone       The time zone in which to interpret the time window. If not spcecified, UTC will be used
 * @param p_expression      The mapping expression, if any, for mapping the default values of 1..5 onto a different range.
 * This is an algebraic or RPN expression that will be evaluated with cwms_util.eval_expression. The indicator values
 * to mapped are specified as ARG1 in the expression. Various methods of mapping the range of 1..5 onto the
 * range of 1..3 are shown below.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Expression (algebraic)</th>
 *     <th style="border:1px solid black;">Characteristic</th>
 *     <th style="border:1px solid black;">Mapping</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 + 2) / 2)'</td>
 *     <td style="border:1px solid black;">Skinny Bottom</td>
 *     <td style="border:1px solid black;">1,2,2,3,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 + 1) / 2)'</td>
 *     <td style="border:1px solid black;">Skinny Top</td>
 *     <td style="border:1px solid black;">1,1,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'</td>
 *     <td style="border:1px solid black;">Fat Bottom</td>
 *     <td style="border:1px solid black;">1,1,1,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 - 2) / 3 + 2)'</td>
 *     <td style="border:1px solid black;">Fat Middle</td>
 *     <td style="border:1px solid black;">1,2,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'</td>
 *     <td style="border:1px solid black;">Fat Top</td>
 *     <td style="border:1px solid black;">1,2,3,3,3</td>
 *   </tr>
 * </table>
 *
 * @param p_office_id       The office that owns the time series and location level
 */
procedure retrieve_status_indicators(
   p_indicators      out tsv_array,
   p_tsid            in  varchar2,
   p_level_id        in  varchar2,
   p_indicator_id    in  varchar2,
   p_start_time      in  date,
   p_end_time        in  date,
   p_attribute_id    in  varchar2 default null,
   p_attribute_value in  number   default null,
   p_attribute_unit  in  varchar2 default null,
   p_time_zone       in  varchar2 default 'UTC',
   p_expression      in  varchar2 default null,
   p_office_id       in  varchar2 default null);
/**
 * Retrieves a time series of the maximum set location level status indicator condition
 * values for a time series, optionally mapping the default values of 1..5 onto a
 * different range.
 *
 * @see cwms_util.eval_expression
 *
 * @param p_tsid            The time series to use to determine the which indicator conditions are set
 * @param p_level_id        The location level to use to determine the which indicator conditions are set
 * @param p_indicator_id    The location level indicator to use to determine the which conditions are set
 * @param p_start_time      The start of the time window to retrieve the data for
 * @param p_end_time        The end of the time window to retrieve the data for
 * @param p_attribute_id    The location level attribute identifier, if any
 * @param p_attribute_value The location level attribute value, if any, in the specified unit
 * @param p_attribute_unit  The unit for the location level attribute value, if any
 * @param p_time_zone       The time zone in which to interpret the time window. If not spcecified, UTC will be used
 * @param p_expression      The mapping expression, if any, for mapping the default values of 1..5 onto a different range.
 * This is an algebraic or RPN expression that will be evaluated with cwms_util.eval_expression. The indicator values
 * to mapped are specified as ARG1 in the expression. Various methods of mapping the range of 1..5 onto the
 * range of 1..3 are shown below.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Expression (algebraic)</th>
 *     <th style="border:1px solid black;">Characteristic</th>
 *     <th style="border:1px solid black;">Mapping</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 + 2) / 2)'</td>
 *     <td style="border:1px solid black;">Skinny Bottom</td>
 *     <td style="border:1px solid black;">1,2,2,3,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 + 1) / 2)'</td>
 *     <td style="border:1px solid black;">Skinny Top</td>
 *     <td style="border:1px solid black;">1,1,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'</td>
 *     <td style="border:1px solid black;">Fat Bottom</td>
 *     <td style="border:1px solid black;">1,1,1,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 - 2) / 3 + 2)'</td>
 *     <td style="border:1px solid black;">Fat Middle</td>
 *     <td style="border:1px solid black;">1,2,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'</td>
 *     <td style="border:1px solid black;">Fat Top</td>
 *     <td style="border:1px solid black;">1,2,3,3,3</td>
 *   </tr>
 * </table>
 *
 * @param p_office_id       The office that owns the time series and location level
 *
 * @return The time series of maximum set location indicator conditions, after any mapping
 */
function retrieve_status_indicators_f(
   p_tsid            in varchar2,
   p_level_id        in varchar2,
   p_indicator_id    in varchar2,
   p_start_time      in date,
   p_end_time        in date,
   p_attribute_id    in varchar2 default null,
   p_attribute_value in number   default null,
   p_attribute_unit  in varchar2 default null,
   p_time_zone       in varchar2 default 'UTC',
   p_expression      in varchar2 default null,
   p_office_id       in varchar2 default null)
   return tsv_array;   
/**
 * Retrieves the maximum location level indicator condition value that is set for
 * a time series at a specified time, optionally mapping the default value of 1..5 onto a
 * different range.
 *
 * @see cwms_util.eval_expression
 *
 * @param p_tsid            The time series to use to determine the which indicator conditions are set
 * @param p_level_id        The location level to use to determine the which indicator conditions are set
 * @param p_indicator_id    The location level indicator to use to determine the which conditions are set
 * @param p_eval_time       The time to evaluate the location level indicator conditions for
 * @param p_attribute_id    The location level attribute identifier, if any
 * @param p_attribute_value The location level attribute value, if any, in the specified unit
 * @param p_attribute_unit  The unit for the location level attribute value, if any
 * @param p_time_zone       The time zone in which to interpret the evaluation time. If not spcecified, UTC will be used
 * @param p_expression      The mapping expression, if any, for mapping the default value range of 1..5 onto a different range.
 * This is an algebraic or RPN expression that will be evaluated with cwms_util.eval_expression. The indicator values
 * to mapped are specified as ARG1 in the expression. Various methods of mapping the range of 1..5 onto the
 * range of 1..3 are shown below.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Expression (algebraic)</th>
 *     <th style="border:1px solid black;">Characteristic</th>
 *     <th style="border:1px solid black;">Mapping</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 + 2) / 2)'</td>
 *     <td style="border:1px solid black;">Skinny Bottom</td>
 *     <td style="border:1px solid black;">1,2,2,3,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 + 1) / 2)'</td>
 *     <td style="border:1px solid black;">Skinny Top</td>
 *     <td style="border:1px solid black;">1,1,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'</td>
 *     <td style="border:1px solid black;">Fat Bottom</td>
 *     <td style="border:1px solid black;">1,1,1,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'TRUNC((ARG1 - 2) / 3 + 2)'</td>
 *     <td style="border:1px solid black;">Fat Middle</td>
 *     <td style="border:1px solid black;">1,2,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'</td>
 *     <td style="border:1px solid black;">Fat Top</td>
 *     <td style="border:1px solid black;">1,2,3,3,3</td>
 *   </tr>
 * </table>
 *
 * @param p_office_id       The office that owns the time series and location level
 *
 * @return The time series of maximum set location indicator conditions, after any mapping
 */
function retrieve_status_indicator_f(
   p_tsid            in varchar2,
   p_level_id        in varchar2,
   p_indicator_id    in varchar2,
   p_eval_time       in date     default sysdate,
   p_attribute_id    in varchar2 default null,
   p_attribute_value in number   default null,
   p_attribute_unit  in varchar2 default null,
   p_time_zone       in varchar2 default 'UTC',
   p_expression      in varchar2 default null,
   p_office_id       in varchar2 default null)
   return integer;
   
end cwms_display;
/
show errors;
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_adjustment_level</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_display.scale_as_is</td>
 *     <td class="descr">no adjustment is made to the scale<p>(124.87 -&gt; 126.23) =&gt; (124.87 -&gt; 126.23)</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_display.scale_nice</td>
 *     <td class="descr">scale is adjusted so that the range (max - min) follows the 1-2-5 increment rule and the minimum value is an even multiple of the <b>increment</b><p>(124.87 -&gt; 126.23) =&gt; (124.0 -&gt; 129.0)</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_display.scale_extra_nice</td>
 *     <td class="descr">scale is adjusted so that the range (max - min) follows the 1-2-5 increment rule and the minimum value is an even multiple of the <b>range</b><p>(124.87 -&gt; 126.23) =&gt; (120.0 -&gt; 130.0)</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_limits_catalog A cursor containing all matching scale limits.  The cursor contains
 * the following columns and is sorted by the first three:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the scale limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">scale_min</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The minimum scale limit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">scale_max</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The maximum scale limit</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the scale limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit identifier for the scale_limits</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">scale_min</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The minimum scale limit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">scale_max</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The maximum scale limit</td>
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
 * Stores an office's preferred parameter unit to the database
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
   p_unit_id        in varchar2,
   p_fail_if_exists in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Stores a user's preferred parameter unit to the database
 *
 * @param p_parameter_id   The parameter to store the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if the specified preferred already exists.  If 'F', the existing preferred unit are updated with the specified parameters.
 * @param p_ignore_nulls   A flag ('T' or 'F') specifying whether to ignore NULL parameters when updating existing preferred unit. If 'T', no existing data will be overwritten by NULL
 * @param p_unit_id        The preferred unit for the specified parameter and unit system
 * @param p_user_id        The user for which the preferred unit applies. If not specified or NULL, the session user is used.
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the preferred unit is already exists in the database
 */
procedure store_user_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_unit_id        in varchar2,
   p_fail_if_exists in varchar2,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null);
/**
 * Retrieves an office's preferred parameter unit from the database
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
 * Retrieves an office's preferred parameter unit from the database
 *
 * @param p_parameter_id   The parameter to retrieve the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 *
 * @return The preferred unit for the specified parameter and unit system
 */
function retrieve_unit_f(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_office_id      in varchar2 default null)
   return varchar2;
/**
 * Retrieves a user's preferred parameter unit from the database. If the user does not have a
 * preferred unit for the specified parameter, the office's preferred unit is retreieved. If the
 * office does not have a preferred unit, the default unit is retreieved.
 *
 * @param p_unit_id        The preferred unit for the specified parameter and unit system
 * @param p_parameter_id   The parameter to retrieve the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_user_id        The user for which the preferred unit applies. If not specified or NULL, the session user is used.
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_user_unit(
   p_unit_id        out varchar2,
   p_parameter_id   in  varchar2,
   p_unit_system    in  varchar2 default null,
   p_user_id        in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves a user's preferred parameter unit from the database. If the user does not have a
 * preferred unit for the specified parameter, the office's preferred unit is retreieved. If the
 * office does not have a preferred unit, the default unit is retreieved.
 *
 * @param p_parameter_id   The parameter to retrieve the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_user_id        The user for which the preferred unit applies. If not specified or NULL, the session user is used.
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 *
 * @return The preferred unit for the specified parameter and unit system
 */
function retrieve_user_unit_f(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2 default null,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null)
   return varchar2;
/**
 * Deletes an office's preferred parameter unit from the database
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
 * Deletes a user's preferred parameter unit from the database
 *
 * @param p_parameter_id   The parameter to delete the preferred unit for
 * @param p_unit_system    The unit system ('EN' or 'SI') for which the preferred unit applies
 * @param p_user_id        The user for which the preferred unit applies. If not specified or NULL, the session user is used.
 * @param p_office_id      The office for which the preferred unit applies.  If not specified or NULL, the session user's default office is used.
 */
procedure delete_user_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null);
/**
 * Catalogs preferred units in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_unit_catalog A cursor containing all matching preferred units.  The cursor contains
 * the following and is sorted by the first three:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter identifier for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">unit_system</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The unit system for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The preferred unit identifier</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter identifier for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">unit_system</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The unit system for the preferred unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The preferred unit identifier</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Expression (algebraic)</th>
 *     <th class="descr">Characteristic</th>
 *     <th class="descr">Mapping</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 + 2) / 2)'</td>
 *     <td class="descr">Skinny Bottom</td>
 *     <td class="descr">1,2,2,3,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 + 1) / 2)'</td>
 *     <td class="descr">Skinny Top</td>
 *     <td class="descr">1,1,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'</td>
 *     <td class="descr">Fat Bottom</td>
 *     <td class="descr">1,1,1,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 - 2) / 3 + 2)'</td>
 *     <td class="descr">Fat Middle</td>
 *     <td class="descr">1,2,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'</td>
 *     <td class="descr">Fat Top</td>
 *     <td class="descr">1,2,3,3,3</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Expression (algebraic)</th>
 *     <th class="descr">Characteristic</th>
 *     <th class="descr">Mapping</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 + 2) / 2)'</td>
 *     <td class="descr">Skinny Bottom</td>
 *     <td class="descr">1,2,2,3,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 + 1) / 2)'</td>
 *     <td class="descr">Skinny Top</td>
 *     <td class="descr">1,1,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'</td>
 *     <td class="descr">Fat Bottom</td>
 *     <td class="descr">1,1,1,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 - 2) / 3 + 2)'</td>
 *     <td class="descr">Fat Middle</td>
 *     <td class="descr">1,2,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'</td>
 *     <td class="descr">Fat Top</td>
 *     <td class="descr">1,2,3,3,3</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Expression (algebraic)</th>
 *     <th class="descr">Characteristic</th>
 *     <th class="descr">Mapping</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 + 2) / 2)'</td>
 *     <td class="descr">Skinny Bottom</td>
 *     <td class="descr">1,2,2,3,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 + 1) / 2)'</td>
 *     <td class="descr">Skinny Top</td>
 *     <td class="descr">1,1,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'</td>
 *     <td class="descr">Fat Bottom</td>
 *     <td class="descr">1,1,1,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'TRUNC((ARG1 - 2) / 3 + 2)'</td>
 *     <td class="descr">Fat Middle</td>
 *     <td class="descr">1,2,2,2,3</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'</td>
 *     <td class="descr">Fat Top</td>
 *     <td class="descr">1,2,3,3,3</td>
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
/**
 * Sets store rule sort order and default store rule for UI components for an office
 *
 * @param p_ordered_rules A comma-separated list of the store rules in the desired sort order for the office.  If this is NULL, the sort order for the office will revert to the default.  If not all the store rules are specified, the non-specified store rules will follow the specified store rules in default order.
 * @param p_default_rule  The default store rule for the office.  If this is NULL the default store rule will revert to the standard default.  
 * @param p_office_id     The office set the store rule information for.  If unspecified or NULL, the session users' default office is used.
 *
 * @see view av_store_rule_ui
 * @see view av_store_rule
 */    
procedure set_store_rule_ui_info(
   p_ordered_rules in varchar2,
   p_default_rule  in varchar2,
   p_office_id     in varchar2 default null);
/**
 * Sets specified level sort order for UI components for an office
 *
 * @param p_ordered_levels A comma-separated list of the specified levels in the desired sort order for the office.  If this is NULL, the sort order for the office will revert to the default.  If not all the specified levels are included, the unincluded specified levels will follow the included specified levels in default order.
 * @param p_office_id     The office set the store rule information for.  If unspecified or NULL, the session users' default office is used.
 *
 * @see view av_specified_level_ui
 * @see view av_specified_level
 */    
procedure set_specified_level_ui_info (
   p_ordered_levels in varchar2,
   p_office_id      in varchar2 default null);   
end cwms_display;
/
show errors;
create or replace package cwms_basin
/**
 * Routines to work with CWMS basins
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.1
 */
as
-- not documented
function get_basin_code(
   p_basin_id  in varchar2,
   p_office_id in varchar2 default null)
   return number;
/**
 * Stores a basin to the database
 *
 * @param p_basin_id                   The location identifier of the basin
 * @param p_fail_if_exists             A flag ('T' or 'F') that specifies whether the routine should fail if the specified basin already exists.  If 'F' and the basin already exists, it will be updated with the specified parameters.
 * @param p_ignore_nulls               A flag ('T' or 'F') that specifies whether NULL parameters should be ignored when updating a basin.  If 'T', no existing information will be overwritten by a NULL value.
 * @param p_parent_basin_id            The location identifier of the parent basin if this is a sub-basin
 * @param p_sort_order                 A number to be used in sorting the sub-basins of the parent basin
 * @param p_primary_stream_id          The location identifier of the primary stream that drains the basin
 * @param p_total_drainage_area        The total area of the basin, including non-contributing drainage area
 * @param p_contributing_drainage_area The area of the basin that contributes flow to the primary stream
 * @param p_area_unit                  The unit of the area parameters
 * @param p_office_id                  The office that owns the basin location
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the basin location already exists
 * @exception ERROR if the basin location identifier already exists and is not a CWMS basin
 */
procedure store_basin(
   p_basin_id                   in varchar2,
   p_fail_if_exists             in varchar2,
   p_ignore_nulls               in varchar2,
   p_parent_basin_id            in varchar2 default null,
   p_sort_order                 in binary_double default null,
   p_primary_stream_id          in varchar2 default null,
   p_total_drainage_area        in binary_double default null,
   p_contributing_drainage_area in binary_double default null,
   p_area_unit                  in varchar2 default null,
   p_office_id                  in varchar2 default null);
/**
 * Retrieves a basin from the database
 *
 * @param p_parent_basin_id            The location identifier of the parent basin if this is a sub-basin
 * @param p_sort_order                 A number to be used in sorting the sub-basins of the parent basin
 * @param p_primary_stream_id          The location identifier of the primary stream that drains the basin
 * @param p_total_drainage_area        The total area of the basin, including non-contributing drainage area
 * @param p_contributing_drainage_area The area of the basin that contributes flow to the primary stream
 * @param p_basin_id                   The location identifier of the basin
 * @param p_area_unit                  The unit to return areas in
 * @param p_office_id                  The office that owns the basin location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such basin location exists
 */
procedure retrieve_basin(
   p_parent_basin_id            out varchar2,
   p_sort_order                 out binary_double,
   p_primary_stream_id          out varchar2,
   p_total_drainage_area        out binary_double,
   p_contributing_drainage_area out binary_double,
   p_basin_id                   in  varchar2,
   p_area_unit                  in  varchar2,
   p_office_id                  in  varchar2 default null);
/**
 * Deletes a basin from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_basin_id The location identifier of the basin
 *
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only this basin, and then only if it has no sub-basins</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only sub-basins of this basin, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this basin and its sub-basins, if any</td>
 *   </tr>
 * </table>
 * @param p_office_id The office that owns the basin location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such basin location exists
 */
procedure delete_basin(
   p_basin_id      in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Renames an existing basin
 *
 * @param p_old_basin_id The existing location identifier of the basin
 * @param p_new_basin_id The new location identifier of the basin
 * @param p_office_id        The office that owns the basin location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such basin location exists
 */
procedure rename_basin(
   p_old_basin_id in varchar2,
   p_new_basin_id in varchar2,
   p_office_id    in varchar2 default null);
/**
 * Catalogs basins in the database that match input parameters. Matching is
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
 * @param p_basins_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
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
 *     <td class="descr">The office that owns the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the parent basin, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">sort_order</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The sort order of the basin within it parent basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">primary_stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the primary stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">total_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The total drainage area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">contributing_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The contributing area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">area_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of the total and contributing drainage areas</td>
 *   </tr>
 * </table>
 *
 * @param p_basin_id_mask  The basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_parent_basin_id_mask  The parent basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_primary_stream_id_mask   The primary stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_area_unit The unit in which to list areas
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_basins(
   p_basins_catalog         out sys_refcursor,
   p_basin_id_mask          in  varchar2 default '*',
   p_parent_basin_id_mask   in  varchar2 default '*',
   p_primary_stream_id_mask in  varchar2 default '*',
   p_area_unit              in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null);
/**
 * Catalogs basins in the database that match input parameters. Matching is
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
 * @param p_basin_id_mask  The basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_parent_basin_id_mask  The parent basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_primary_stream_id_mask   The primary stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_area_unit The unit in which to list areas
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching basins.  The cursor contains
 * the following columns:
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
 *     <td class="descr">The office that owns the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the parent basin, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">sort_order</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The sort order of the basin within it parent basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">primary_stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the primary stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">total_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The total drainage area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">contributing_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The contributing area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">area_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of the total and contributing drainage areas</td>
 *   </tr>
 * </table>
 */
function cat_basins_f(
   p_basin_id_mask          in varchar2 default '*',
   p_parent_basin_id_mask   in varchar2 default '*',
   p_primary_stream_id_mask in varchar2 default '*',
   p_area_unit              in varchar2 default null,
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves the volume of runoff from a depth of excess precipitation
 *
 * @param p_runoff_volume       The volume of runoff in the specified unit
 * @param p_basin_id            The location identifier of the basin
 * @param p_precip_excess_depth The excess depth of precipitation in the specified unit
 * @param p_precip_unit         The precipitation unit
 * @param p_volume_unit         The volume unit
 * @param p_office_id           The office that owns the basin
 *
 * @exception ITEM_DOES_NOT_EXIST if no such basin location exists
 */
procedure get_runoff_volume(
   p_runoff_volume       out binary_double,
   p_basin_id            in  varchar2,
   p_precip_excess_depth in  binary_double,
   p_precip_unit         in  varchar2,
   p_volume_unit         in  varchar2,
   p_office_id           in  varchar2 default null);
/**
 * Retrieves the volume of runoff from a depth of excess precipitation
 *
 * @param p_basin_id            The location identifier of the basin
 * @param p_precip_excess_depth The excess depth of precipitation in the specified unit
 * @param p_precip_unit         The precipitation unit
 * @param p_volume_unit         The volume unit
 * @param p_office_id           The office that owns the basin
 *
 * @return The volume of runoff in the specified unit
 *
 * @exception ITEM_DOES_NOT_EXIST if no such basin location exists
 */
function get_runoff_volume_f(
   p_basin_id            in varchar2,
   p_precip_excess_depth in binary_double,
   p_precip_unit         in varchar2,
   p_volume_unit         in varchar2,
   p_office_id           in varchar2 default null)
   return binary_double;
         
end cwms_basin;
/
show errors;
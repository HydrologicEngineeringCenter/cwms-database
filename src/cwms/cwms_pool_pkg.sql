create or replace package cwms_pool
/**
 * Routines for working with reservoir pools
 *
 * @author Mike Perryman
 *
 * @since CWMS 3.1
 */
as
/**
 * Stores a pool name to the database
 *
 * @param p_pool_name      The name of the pool
 * @param p_fail_if_exists A flag (T/F) that specifes whether to fail if the pool name (case insensitive) already exists for the office
 * @param p_office_id      The office that owns the pool name. If NULL or not specified, the current session's user is used
 */
procedure store_pool_name(
   p_pool_name      in varchar2,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null);
/**
 * Renames a pool in the database
 *
 * @param p_old_name   The existing name of the pool
 * @param p_new_name   The desired name of the pool
 * @param p_office_id  The office that owns the pool name. If NULL or not specified, the current session's user is used
 */
procedure rename_pool(
   p_old_name  in varchar2,
   p_new_name  in varchar2,
   p_office_id in varchar2 default null);
/**
 * Deletes a pool name from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_pool_name     The name of the pool
 * @param p_delete_action Specifies what to delete. If not specifed, cwms_util.delete_key will be used. Actions are as follows:
 *                        <p>
 *                        <table class="descr">
 *                          <tr>
 *                            <th class="descr">p_delete_action</th>
 *                            <th class="descr">Action</th>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_key</td>
 *                            <td class="descr">deletes only the pool name, and then only if it has no associated pools</td>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_data</td>
 *                            <td class="descr">deletes only pools associated with the pool name, if any</td>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_all</td>
 *                            <td class="descr">deletes the pool name and all associated pools</td>
 *                          </tr>
 *                        </table>
 * @param p_office_id     The office that owns the pool name. If NULL or not specified, the current session's user is used
 */
procedure delete_pool_name(
   p_pool_name     in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**      
 * Catalogs pool names in the database
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_cat_cursor     The cursor containing the pool names that match the specified parameters.
 *                         The cursor will contain the following columns:
 *                         <p>
 *                         <table class="descr">
 *                           <tr>
 *                             <th class="descr">Column No.</th>
 *                             <th class="descr">Column Name</th>
 *                             <th class="descr">Data Type</th>
 *                             <th class="descr">Contents</th>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr-center">1</td>
 *                             <td class="descr">office_id</td>
 *                             <td class="descr">varchar2(16)</td>
 *                             <td class="descr">The office that owns the pool name</td>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr-center">2</td>
 *                             <td class="descr">pool_name</td>
 *                             <td class="descr">varchar2(32)</td>
 *                             <td class="descr">The pool name</td>
 *                           </tr>
 *                         </table>
 * @param p_pool_name_mask The pool name pattern to match (case_insensitive).
 *                         Defaults to '*' if NULL or not specified.
 *                         Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_office_id_mask The office id pattern to match (case insensitive).
 *                         Defaults to the current database if NULL or not specified (which will include CWMS-owned pool namss).
 *                         Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 */
procedure cat_pool_names(
   p_cat_cursor     out sys_refcursor,
   p_pool_name_mask in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null);
/**      
 * Catalogs pool names in the databse
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_pool_name_mask The pool name pattern to match (case_insensitive).
 *                         Defaults to '*' if NULL or not specified.
 *                         Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_office_id_mask The office id pattern to match (case insensitive).
 *                         Defaults to the current database if NULL or not specified (which will include CWMS-owned pool namss).
 *                         Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 *
 * @return The cursor containing the authorized scheduler entries that match the specified parameters.
 *         The cursor will contain the following columns:
 *         <p>
 *         <table class="descr">
 *           <tr>
 *             <th class="descr">Column No.</th>
 *             <th class="descr">Column Name</th>
 *             <th class="descr">Data Type</th>
 *             <th class="descr">Contents</th>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">1</td>
 *             <td class="descr">office_id</td>
 *             <td class="descr">varchar2(16)</td>
 *             <td class="descr">The office that owns the pool name</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">2</td>
 *             <td class="descr">pool name</td>
 *             <td class="descr">varchar2(32)</td>
 *             <td class="descr">The pool name</td>
 *           </tr>
 *         </table>
 */
function cat_pool_names_f(
   p_pool_name_mask in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return sys_refcursor;
/**
 * Stores pool information for a project.
 *
 * @param p_project_id       The name of the project to store the pool information for
 * @param p_pool_name        The name of the pool
 * @param p_bottom_level_id  The name of the location that defines the bottom of the pool. The location portion of the location level name may be omitted (i.e., it may start witht the parameter portion) 
 * @param p_top_level_id     The name of the location that defines the top of the pool. The location portion of the location level name may be omitted (i.e., it may start witht the parameter portion)
 * @param p_fail_if_exists   A flag (T/F) specifying whether to raise an exception if the pool already exists for the project. If F and the pool exists, its top and bottom levels will be updated.
 * @param p_create_pool_name A flag (T/F) specifying whether to create the pool name if it doesn't already exist. 
 * @param p_office_id        The name of the office that owns the pool. If NULL or not specified, the session user's office will be used
 *
 */
procedure store_pool(
   p_project_id       in varchar2,
   p_pool_name        in varchar2,
   p_bottom_level_id  in varchar2,
   p_top_level_id     in varchar2,
   p_fail_if_exists   in varchar2 default 'T',
   p_create_pool_name in varchar2 default 'F',
   p_office_id        in varchar2 default null);
/**
 * Retrieves pool information for a project.
 *
 * @param p_bottom_level_id  The name of the location that defines the bottom of the pool. The location portion of the location level name may be omitted (i.e., it may start witht the parameter portion) 
 * @param p_top_level_id     The name of the location that defines the top of the pool. The location portion of the location level name may be omitted (i.e., it may start witht the parameter portion)
 * @param p_project_id       The name of the project to retrieve the pool information for
 * @param p_pool_name        The name of the pool
 * @param p_office_id        The name of the office that owns the pool. If NULL or not specified, the session user's office will be used
 *
 */
procedure retrieve_pool(
   p_bottom_level_id  out varchar2,
   p_top_level_id     out varchar2,
   p_project_id       in  varchar2,
   p_pool_name        in  varchar2,
   p_office_id        in  varchar2 default null);
/**
 * Retrieves pool information for a project.
 *
 * @param p_project_id The name of the project to retrieve the pool information for
 * @param p_pool_name  The name of the pool
 * @param p_office_id  The name of the office that owns the pool. If NULL or not specified, the session user's office will be used
 *
 * @return A STR_TAB_T object of length 2; the bottom level followed by the top level.
 *
 */
function retrieve_pool_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_office_id  in  varchar2 default null)
   return str_tab_t;
/**
 * Deletess pool information for a project.
 *
 * @param p_project_id The name of the project to delete the pool information for
 * @param p_pool_name  The name of the pool
 * @param p_office_id  The name of the office that owns the pool. If NULL or not specified, the session user's office will be used
 *
 */
procedure delete_pool(
   p_project_id in varchar2,
   p_pool_name  in varchar2,
   p_office_id  in varchar2 default null);
/**
 * Catalogs pools in the database.
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_cat_cursor        The cursor containing the pools that match the specified parameters.
 *                            The cursor will contain the following columns:
 *                            <p>
 *                            <table class="descr">
 *                              <tr>
 *                                <th class="descr">Column No.</th>
 *                                <th class="descr">Column Name</th>
 *                                <th class="descr">Data Type</th>
 *                                <th class="descr">Contents</th>
 *                              </tr>
 *                              <tr>
 *                                <td class="descr-center">1</td>
 *                                <td class="descr">office_id</td>
 *                                <td class="descr">varchar2(16)</td>
 *                                <td class="descr">The office that owns the pool name</td>
 *                              </tr>
 *                              <tr>
 *                                <td class="descr-center">2</td>
 *                                <td class="descr">project_id</td>
 *                                <td class="descr">varchar2(183)</td>
 *                                <td class="descr">The pool name</td>
 *                              </tr>
 *                              <tr>
 *                                <td class="descr-center">3</td>
 *                                <td class="descr">pool_name</td>
 *                                <td class="descr">varchar2(32)</td>
 *                                <td class="descr">The pool name</td>
 *                              </tr>
 *                              <tr>
 *                                <td class="descr-center">4</td>
 *                                <td class="descr">bottom_level_id</td>
 *                                <td class="descr">varchar2(256)</td>
 *                                <td class="descr">The pool name</td>
 *                              </tr>
 *                              <tr>
 *                                <td class="descr-center">5</td>
 *                                <td class="descr">top_level_id</td>
 *                                <td class="descr">varchar2(256)</td>
 *                                <td class="descr">The pool name</td>
 *                              </tr>
 *                            </table>
 * @param p_pool_name_mask    The pool name pattern to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_project_id_mask   The project name pattern to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_pool_name_mask    The pool name pattern to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_bottom_level_mask The pool bottom location_level_id to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_top_level_mask    The pool top location_level_id to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_include_explicit  A flag (T/F) specifying whether to include explicitly-defined pools.
 *                            Explicitly-defined pools are ones with entries in the AT_POOL table
                              in the AT_POOL_NAME table
 * @param p_include_implicit  A flag (T/F) specifying whether to include implicitly-defined pools.
 *                            Implicitly-defined pools are ones without entries in the AT_POOL table, but are defined by virtue of having 
                              defined location levels of ''Top of XXX'' and ''Bottom of XXX'' for pool name XXX, which <b>does</b> need to exist
                              in the AT_POOL_NAME table
 * @param p_office_id_mask    The office id pattern to match (case insensitive).
 *                            Defaults to the current database if NULL or not specified (which will include CWMS-owned pool namss).
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
*/
procedure cat_pools(
   p_cat_cursor      out sys_refcursor,
   p_project_id_mask   in  varchar2 default '*',
   p_pool_name_mask    in  varchar2 default '*',
   p_bottom_level_mask in  varchar2 default '*',
   p_top_level_mask    in  varchar2 default '*',
   p_include_explicit  in  varchar2 default 'T',
   p_include_implicit  in  varchar2 default 'T',
   p_office_id_mask    in  varchar2 default null);
/**
 * Catalogs pools in the database.
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_pool_name_mask    The pool name pattern to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_project_id_mask   The project name pattern to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_pool_name_mask    The pool name pattern to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_bottom_level_mask The pool bottom location_level_id to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_top_level_mask    The pool top location_level_id to match (case_insensitive).
 *                            Defaults to '*' if NULL or not specified.
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_include_explicit  A flag (T/F) specifying whether to include explicitly-defined pools.
 *                            Explicitly-defined pools are ones with entries in the AT_POOL table
                              in the AT_POOL_NAME table
 * @param p_include_implicit  A flag (T/F) specifying whether to include implicitly-defined pools.
 *                            Implicitly-defined pools are ones without entries in the AT_POOL table, but are defined by virtue of having 
                              defined location levels of ''Top of XXX'' and ''Bottom of XXX'' for pool name XXX, which <b>does</b> need to exist
                              in the AT_POOL_NAME table
 * @param p_office_id_mask    The office id pattern to match (case insensitive).
 *                            Defaults to the current database if NULL or not specified (which will include CWMS-owned pool namss).
 *                            Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 *
 * @return The cursor containing the pools that match the specified parameters.
 *         The cursor will contain the following columns:
 *         <p>
 *         <table class="descr">
 *           <tr>
 *             <th class="descr">Column No.</th>
 *             <th class="descr">Column Name</th>
 *             <th class="descr">Data Type</th>
 *             <th class="descr">Contents</th>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">1</td>
 *             <td class="descr">office_id</td>
 *             <td class="descr">varchar2(16)</td>
 *             <td class="descr">The office that owns the pool name</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">2</td>
 *             <td class="descr">project_id</td>
 *             <td class="descr">varchar2(183)</td>
 *             <td class="descr">The pool name</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">3</td>
 *             <td class="descr">pool_name</td>
 *             <td class="descr">varchar2(32)</td>
 *             <td class="descr">The pool name</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">4</td>
 *             <td class="descr">bottom_level_id</td>
 *             <td class="descr">varchar2(256)</td>
 *             <td class="descr">The pool name</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">5</td>
 *             <td class="descr">top_level_id</td>
 *             <td class="descr">varchar2(256)</td>
 *             <td class="descr">The pool name</td>
 *           </tr>
 *         </table>
 */
function cat_pools_f(
   p_project_id_mask   in varchar2 default '*',
   p_pool_name_mask    in varchar2 default '*',
   p_bottom_level_mask in varchar2 default '*',
   p_top_level_mask    in varchar2 default '*',
   p_include_explicit  in varchar2 default 'T',
   p_include_implicit  in varchar2 default 'T',
   p_office_id_mask    in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves a flag (T/F) specifying whether the elevation is in a specified pool at a specified time. 
 *
 * @param p_in_pool    The result: ''T'' if the elevtion is in the specified pool, ''F'' otherwise.
 * @param p_project_id The project containing pool.
 * @param p_elevation  The elevation to test.
 * @param p_unit       The elevation unit.
 * @param p_datetime   The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure in_pool(
   p_in_pool    out varchar2,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_elevation  in  number,
   p_unit       in  varchar2,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null);   
/**
 * Retrieves a flag (T/F) specifying whether the elevation is in a specified pool at a specified time. 
 *
 * @param p_project_id The project containing pool.
 * @param p_elevation  The elevation to test.
 * @param p_unit       The elevation unit.
 * @param p_datetime   The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 * 
 * @return ''T'' if the elevtion is in the specified pool, ''F'' otherwise.
 */
function in_pool_f(
   p_project_id in varchar2,
   p_pool_name  in varchar2,
   p_elevation  in number,
   p_unit       in varchar2,
   p_datetime   in date default null,
   p_timezone   in varchar2 default null,
   p_office_id  in varchar2 default null)
   return varchar2;   
/**
 * Catalogs the pool names for a project that contain the specified elev at the specified time. 
 *
 * @param p_pool_names A cursor of varchar2(32) records that contain the elevation.
 * @param p_project_id The project to catalog the containing pools for.
 * @param p_elevation  The elevation to catalog the containing pools for.
 * @param p_unit       The elevation unit.
 * @param p_datetime   The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure cat_containing_pool_names(
   p_pool_names out sys_refcursor,
   p_project_id in  varchar2,
   p_elevation  in  number,
   p_unit       in  varchar2,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null);
/**
 * Catalogs the pool names for a project that contain the specified elev at the specified time. 
 *
 * @param p_project_id The project to catalog the containing pools for.
 * @param p_elevation  The elevation to catalog the containing pools for.
 * @param p_unit       The elevation unit.
 * @param p_datetime   The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return A cursor of varchar2(32) records that contain the elevation.
 */
function cat_containing_pool_names_f(
   p_project_id in varchar2,
   p_elevation  in number,
   p_unit       in varchar2,
   p_datetime   in date default null,
   p_timezone   in varchar2 default null,
   p_office_id  in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves the pool limit elevation for a specified time.
 *
 * @param p_limit_elev The pool limit elevation for the specified parameters.
 * @param p_project_id The name of the project to retrieve the value for.
 * @param p_pool_name  The name of the pool to retrieve the value for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit to retrieve the value in.
 * @param p_datetime   The time to retrieve the value for. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elev(
   p_limit_elev out number,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_datetime   in  date     default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null);
/**
 * Retrieves the pool limit elevation for a specified time.
 *
 * @param p_project_id The name of the project to retrieve the value for.
 * @param p_pool_name  The name of the pool to retrieve the value for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit to retrieve the value in.
 * @param p_datetime   The time to retrieve the value for. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevation for the specified parameters.
 */
function get_pool_limit_elev_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_datetime   in  date     default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number;
/**
 * Retrieves both pool limit elevations for a specified time.
 *
 * @param p_bottom_elev The pool bottom limit elevation for the specified parameters.
 * @param p_top_elev    The pool top limit elevation for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the values for.
 * @param p_pool_name   The name of the pool to retrieve the values for.
 * @param p_unit        The unit to retrieve the values in.
 * @param p_datetime    The time to retrieve the values for. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elevs(
   p_bottom_elev out number,
   p_top_elev    out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_unit        in  varchar2,
   p_datetime    in  date     default null,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves both pool limit elevations for a specified time.
 *
 * @param p_project_id The name of the project to retrieve the values for.
 * @param p_pool_name  The name of the pool to retrieve the values for.
 * @param p_unit       The unit to retrieve the values in.
 * @param p_datetime   The time to retrieve the values for. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevations in a two-value table, arraged as (bottom_elev, top_elev).
 */
function get_pool_limit_elevs_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_datetime       in  date     default null,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
   return number_tab_t;
/**     
 * Retrieves the pool limit elevations for multiple times.
 *
 * @param p_limit_elevs The pool limit elevation for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_datetimes   The times to retrieve the value for.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elevs(
   p_limit_elevs out number_tab_t,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the pool limit elevations for multiple times.
 *
 * @param p_project_id The name of the project to retrieve the value for.
 * @param p_pool_name  The name of the pool to retrieve the value for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit to retrieve the value in.
 * @param p_datetimes  The timesto retrieve the value for.
 * @param p_timezone   The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevations for multiple times.
 */
function get_pool_limit_elevs_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_datetimes  in  date_table_type,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number_tab_t;
/**
 * Retrieves both pool limit elevations for multiple times.
 *
 * @param p_bottom_elevs The pool bottom limit elevation for the specified parameters.
 * @param p_top_elevs    The pool top limit elevation for the specified parameters.
 * @param p_project_id   The name of the project to retrieve the values for.
 * @param p_pool_name    The name of the pool to retrieve the values for.
 * @param p_unit         The unit to retrieve the values in.
 * @param p_datetimes    The times to retrieve the values for.
 * @param p_timezone     The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elevs(
   p_bottom_elevs out number_tab_t,
   p_top_elevs    out number_tab_t,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves both pool limit elevations for multiple times.
 *
 * @param p_project_id    The name of the project to retrieve the values for.
 * @param p_pool_name     The name of the pool to retrieve the values for.
 * @param p_unit          The unit to retrieve the values in.
 * @param p_datetimes     The time to retrieve the values for. If NULL or not specified, the current time is used.
 * @param p_timezone      The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevations in a table of two-value tables. Each row of outer table is arraged as (bottom_elev, top_elev).
 */
function get_pool_limit_elevs_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_datetimes      in  date_table_type,
   p_timezone       in  varchar2 default null,
   p_datetime_axis  in  varchar2 default 'ROW',
   p_office_id      in  varchar2 default null)
   return number_tab_tab_t;
/**     
 * Retrieves the pool limit elevations for times in a time series.
 *
 * @param p_limit_elevs The pool limit elevation for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_timeseries  The time seires containing the times to retrieve the value for.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elevs(
   p_limit_elevs out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_timeseries  in  ztsv_array,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the pool limit elevations for times in a time series.
 *
 * @param p_project_id The name of the project to retrieve the value for.
 * @param p_pool_name  The name of the pool to retrieve the value for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit to retrieve the value in.
 * @param p_timeseries The time seires containing the times to retrieve the value for.
 * @param p_timezone   The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevations for times in a time series.
 */
function get_pool_limit_elevs_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_timeseries in  ztsv_array,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array;
/**
 * Retrieves both pool limit elevations for times in a time series.
 *
 * @param p_bottom_elevs The pool bottom limit elevation for the specified parameters.
 * @param p_top_elevs    The pool top limit elevation for the specified parameters.
 * @param p_project_id   The name of the project to retrieve the values for.
 * @param p_pool_name    The name of the pool to retrieve the values for.
 * @param p_unit         The unit to retrieve the values in.
 * @param p_timeseries   The time seires containing the times to retrieve the value for.
 * @param p_timezone     The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elevs(
   p_bottom_elevs out ztsv_array,
   p_top_elevs    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves both pool limit elevations for times in a time series.
 *
 * @param p_project_id    The name of the project to retrieve the values for.
 * @param p_pool_name     The name of the pool to retrieve the values for.
 * @param p_unit          The unit to retrieve the values in.
 * @param p_timeseries    The time seires containing the times to retrieve the value for.
 * @param p_timezone      The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevations in a table two ztsv_array objects, arranged as (bottom_elevs, top_elevs)
 */
function get_pool_limit_elevs_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_timeseries     in  ztsv_array,
   p_timezone       in  varchar2 default null,
   p_datetime_axis  in  varchar2 default 'ROW',
   p_office_id      in  varchar2 default null)
   return ztsv_array_tab;
/**     
 * Retrieves the pool limit elevations for times in a time series.
 *
 * @param p_limit_elevs The pool limit elevation for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_tsid        The name of the time series to retrieve the values for.
 * @param p_start_time  The start of the time window of the time seires to use for times.
 * @param p_end_time    The end of the time window of the time seires to use for times.
 * @param p_timezone    The time zone of p_start_time, p_end_time, and p_limit_elevs. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elevs(
   p_limit_elevs out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_tsid        in  varchar2,
   p_start_time  in  date,                                                                                      
   p_end_time    in  date,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the pool limit elevations for times in a time series.
 *
 * @param p_project_id The name of the project to retrieve the value for.
 * @param p_pool_name  The name of the pool to retrieve the value for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit to retrieve the value in.
 * @param p_tsid       The name of the time series to retrieve the values for.
 * @param p_start_time The start of the time window of the time seires to use for times.
 * @param p_end_time   The end of the time window of the time seires to use for times.
 * @param p_timezone   The time zone of p_start_time, p_end_time, and results. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevations for times in a time series.
 */
function get_pool_limit_elevs_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_tsid       in  varchar2,
   p_start_time in  date,
   p_end_time   in  date,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array;
/**
 * Retrieves both pool limit elevations for times in a time series.
 *
 * @param p_bottom_elevs The pool bottom limit elevation for the specified parameters.
 * @param p_top_elevs    The pool top limit elevation for the specified parameters.
 * @param p_project_id   The name of the project to retrieve the values for.
 * @param p_pool_name    The name of the pool to retrieve the values for.
 * @param p_unit         The unit to retrieve the values in.
 * @param p_tsid         The name of the time series to retrieve the values for.
 * @param p_start_time   The start of the time window of the time seires to use for times.
 * @param p_end_time     The end of the time window of the time seires to use for times.
 * @param p_timezone     The time zone of p_start_time, p_end_time, p_bottom_elevs, and p_top_elevs. If NULL or not specified, the local time zone of the project is used. 
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_elevs(
   p_bottom_elevs out ztsv_array,
   p_top_elevs    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves both pool limit elevations for times in a time series.
 *
 * @param p_project_id    The name of the project to retrieve the values for.
 * @param p_pool_name     The name of the pool to retrieve the values for.
 * @param p_unit          The unit to retrieve the values in.
 * @param p_tsid          The name of the time series to retrieve the values for.
 * @param p_start_time    The start of the time window of the time seires to use for times.
 * @param p_end_time      The end of the time window of the time seires to use for times.
 * @param p_timezone      The time zone of p_start_time, p_end_time, and the resuls. If NULL or not specified, the local time zone of the project is used. 
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit elevations in a table two ztsv_array objects, arranged as (bottom_elevs, top_elevs)
 */
function get_pool_limit_elevs_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_tsid          in  varchar2,
   p_start_time    in  date,
   p_end_time      in  date,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return ztsv_array_tab;
/**
 * Retrieves the pool limit storage for a specified time.
 *
 * @param p_limit_stor  The pool limit storage for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_datetime    The time to retrieve the value for. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stor(
   p_limit_stor  out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_datetime    in  date     default null,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the pool limit storage for a specified time.
 *
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_datetime    The time to retrieve the value for. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storage for the specified parameters.
 */
function get_pool_limit_stor_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_datetime    in date     default null,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return number;
/**
 * Retrieves both pool limit storages for a specified time.
 *
 * @param p_bottom_stor The pool bottom limit storage for the specified parameters.
 * @param p_top_stor    The pool top limit storage for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the values for.
 * @param p_pool_name   The name of the pool to retrieve the values for.
 * @param p_unit        The unit to retrieve the values in.
 * @param p_datetime    The time to retrieve the values for. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stors(
   p_bottom_stor out number,
   p_top_stor    out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_unit        in  varchar2,
   p_datetime    in  date     default null,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves both pool limit storages for a specified time.
 *
 * @param p_project_id  The name of the project to retrieve the values for.
 * @param p_pool_name   The name of the pool to retrieve the values for.
 * @param p_unit        The unit to retrieve the values in.
 * @param p_datetime    The time to retrieve the values for. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storages in a two-value table, arraged as (bottom_stor, top_stor).
 */
function get_pool_limit_stors_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_datetime       in  date     default null,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null)
   return number_tab_t;
/**     
 * Retrieves the pool limit storages for multiple times.
 *
 * @param p_limit_stors The pool limit storage for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_datetimes   The times to retrieve the value for.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stors(
   p_limit_stors out number_tab_t,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the pool limit storages for multiple times.
 *
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_datetimes   The timesto retrieve the value for.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storages for multiple times.
 */
function get_pool_limit_stors_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_datetimes   in date_table_type,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return number_tab_t;
/**
 * Retrieves both pool limit storages for multiple times.
 *
 * @param p_bottom_stors The pool bottom limit storage for the specified parameters.
 * @param p_top_stors    The pool top limit storage for the specified parameters.
 * @param p_project_id   The name of the project to retrieve the values for.
 * @param p_pool_name    The name of the pool to retrieve the values for.
 * @param p_unit         The unit to retrieve the values in.
 * @param p_datetimes    The times to retrieve the values for.
 * @param p_timezone     The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stors(
   p_bottom_stors out number_tab_t,
   p_top_stors    out number_tab_t,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves both pool limit storages for multiple times.
 *
 * @param p_project_id    The name of the project to retrieve the values for.
 * @param p_pool_name     The name of the pool to retrieve the values for.
 * @param p_unit          The unit to retrieve the values in.
 * @param p_datetimes     The time to retrieve the values for. If NULL or not specified, the current time is used.
 * @param p_timezone      The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate   A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec   The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                        A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                        If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storages in a table of two-value tables. Each row of outer table is arraged as (bottom_stor, top_stor).
 */
function get_pool_limit_stors_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_datetimes     in date_table_type,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return number_tab_tab_t;
/**     
 * Retrieves the pool limit storages for times in a time series.
 *
 * @param p_limit_stors The pool limit storage for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_timeseries  The time seires containing the times to retrieve the value for.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stors(
   p_limit_stors out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_timeseries  in  ztsv_array,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the pool limit storages for times in a time series.
 *
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_timeseries  The time seires containing the times to retrieve the value for.
 * @param p_timezone    The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storages for times in a time series.
 */
function get_pool_limit_stors_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_timeseries  in ztsv_array,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;
/**
 * Retrieves both pool limit storages for times in a time series.
 *
 * @param p_bottom_stors The pool bottom limit storage for the specified parameters.
 * @param p_top_stors    The pool top limit storage for the specified parameters.
 * @param p_project_id   The name of the project to retrieve the values for.
 * @param p_pool_name    The name of the pool to retrieve the values for.
 * @param p_unit         The unit to retrieve the values in.
 * @param p_timeseries   The time seires containing the times to retrieve the value for.
 * @param p_timezone     The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stors(
   p_bottom_stors out ztsv_array,
   p_top_stors    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves both pool limit storages for times in a time series.
 *
 * @param p_project_id    The name of the project to retrieve the values for.
 * @param p_pool_name     The name of the pool to retrieve the values for.
 * @param p_unit          The unit to retrieve the values in.
 * @param p_timeseries    The time seires containing the times to retrieve the value for.
 * @param p_timezone      The time zone of the p_datetime parameter, if any. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate   A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec   The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                        A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                        If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storages in a table two ztsv_array objects, arranged as (bottom_stors, top_stors)
 */
function get_pool_limit_stors_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_timeseries    in ztsv_array,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return ztsv_array_tab;
/**     
 * Retrieves the pool limit storages for times in a time series.
 *
 * @param p_limit_stors The pool limit storage for the specified parameters.
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_tsid        The name of the time series to retrieve the values for.
 * @param p_start_time  The start of the time window of the time seires to use for times.
 * @param p_end_time    The end of the time window of the time seires to use for times.
 * @param p_timezone    The time zone of p_start_time, p_end_time, and p_limit_stors. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stors(
   p_limit_stors out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_tsid        in  varchar2,
   p_start_time  in  date,
   p_end_time    in  date,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the pool limit storages for times in a time series.
 *
 * @param p_project_id  The name of the project to retrieve the value for.
 * @param p_pool_name   The name of the pool to retrieve the value for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit to retrieve the value in.
 * @param p_tsid        The name of the time series to retrieve the values for.
 * @param p_start_time  The start of the time window of the time seires to use for times.
 * @param p_end_time    The end of the time window of the time seires to use for times.
 * @param p_timezone    The time zone of p_start_time, p_end_time, and the results. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storages for times in a time series.
 */
function get_pool_limit_stors_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_tsid        in varchar2,
   p_start_time  in date,
   p_end_time    in date,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;
/**
 * Retrieves both pool limit storages for times in a time series.
 *
 * @param p_bottom_stors The pool bottom limit storage for the specified parameters.
 * @param p_top_stors    The pool top limit storage for the specified parameters.
 * @param p_project_id   The name of the project to retrieve the values for.
 * @param p_pool_name    The name of the pool to retrieve the values for.
 * @param p_unit         The unit to retrieve the values in.
 * @param p_tsid         The name of the time series to retrieve the values for.
 * @param p_start_time   The start of the time window of the time seires to use for times.
 * @param p_end_time     The end of the time window of the time seires to use for times.
 * @param p_timezone     The time zone p_start_time, p_end_time, p_bottom_stors, and p_top_stors. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_pool_limit_stors(
   p_bottom_stors out ztsv_array,
   p_top_stors    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves both pool limit storages for times in a time series.
 *
 * @param p_project_id    The name of the project to retrieve the values for.
 * @param p_pool_name     The name of the pool to retrieve the values for.
 * @param p_unit          The unit to retrieve the values in.
 * @param p_tsid          The name of the time series to retrieve the values for.
 * @param p_start_time    The start of the time window of the time seires to use for times.
 * @param p_end_time      The end of the time window of the time seires to use for times.
 * @param p_timezone      The time zone of p_start_time, p_end_time, and the results. If NULL or not specified, the local time zone of the project is used. 
 * @param p_always_rate   A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec   The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                        A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                        If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The pool limit storages in a table two ztsv_array objects, arranged as (bottom_stors, top_stors)
 */
function get_pool_limit_stors_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_tsid          in varchar2,
   p_start_time    in date,
   p_end_time      in date,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return ztsv_array_tab;
/**
 * Retrieves the offset of an elevation above the bottom or top limit of the specified pool for a single time.
 *
 * @param p_offset     The offset of the specified elevation above the pool limit, in the specified unit.
 *                     This value will be negative if the specified elevation is below the pool limit.
 * @param p_project_id The project to retrieve the offset for.
 * @param p_pool_name  The pool to retrieve the offset for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the specified elevation and of the offset. 
 * @param p_elevation  The elevation to determine the offset for.
 * @param p_datetime   The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offset(
   p_offset     out number,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevation  in  number,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null);
/**
 * Retrieves the offset of an elevation above the bottom or top limit of the specified pool for a single time.
 *
 * @param p_project_id The project to retrieve the offset for.
 * @param p_pool_name  The pool to retrieve the offset for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the specified elevation and of the offset. 
 * @param p_elevation  The elevation to determine the offset for.
 * @param p_datetime   The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offset of the specified elevation above the pool limit, in the specified unit.
 *         This value will be negative if the specified elevation is below the pool limit.
 */
function get_elev_offset_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevation  in  number,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number;
/**
 * Retrieves the offsets of an elevation above the bottom and top limits of the specified pool for a single time.
 *
 * @param p_bottom_offset The offset of the specified elevation above the pool bottom, in the specified unit.
 *                        This value will be negative if the specified elevation is below the pool bottom.
 * @param p_top_offset    The offset of the specified elevation above the pool top, in the specified unit.
 *                        This value will be negative if the specified elevation is below the pool top.
 * @param p_project_id    The project to retrieve the offset for.
 * @param p_pool_name     The pool to retrieve the offset for.
 * @param p_unit          The unit of the specified elevation and of the offset. 
 * @param p_elevation     The elevation to determine the offset for.
 * @param p_datetime      The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone      The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offsets(
   p_bottom_offset out number,
   p_top_offset    out number,
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_elevation     in  number,
   p_datetime      in  date default null,
   p_timezone      in  varchar2 default null,
   p_office_id     in  varchar2 default null);
/**
 * Retrieves the offsets of an elevation above the bottom and top limits of the specified pool for a single time.
 *
 * @param p_project_id The project to retrieve the offset for.
 * @param p_pool_name  The pool to retrieve the offset for.
 * @param p_unit       The unit of the specified elevation and of the offset. 
 * @param p_elevation  The elevation to determine the offset for.
 * @param p_datetime   The time of the elevation. If NULL or not specified, the current time is used.
 * @param p_timezone   The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a two-value table, arraged as (bottom_offset, top_offset).
 */
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_elevation     in  number,
   p_datetime      in  date default null,
   p_timezone      in  varchar2 default null,
   p_office_id     in  varchar2 default null)
   return number_tab_t;
/**
 * Retrieves the offsets of elevations above the bottom or top limit of the specified pool for multiple times.
 *
 * @param p_offsets    The offsetsof the specified elevation above the pool limit, in the specified unit.
 *                     Values will be negative if the specified elevation is below the pool limit.
 * @param p_project_id The project to retrieve the offsets for.
 * @param p_pool_name  The pool to retrieve the offsets for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the specified elevations and of the offsets. 
 * @param p_elevations The elevations to determine the offsets for.
 * @param p_datetimes  The times of the elevations, one for each elevation in p_elevations.
 * @param p_timezone   The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offsets(
   p_offsets    out number_tab_t,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevations in  number_tab_t,
   p_datetimes  in  date_table_type,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null);
/**
 * Retrieves the offsets of elevations above the bottom or top limit of the specified pool for multiple times.
 *
 * @param p_project_id The project to retrieve the offsets for.
 * @param p_pool_name  The pool to retrieve the offsets for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the specified elevations and of the offsets. 
 * @param p_elevations The elevations to determine the offsets for.
 * @param p_datetimes  The times of the elevations, one for each elevation in p_elevations.
 * @param p_timezone   The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets of the specified elevations above the pool limit, in the specified unit.
 *         Values will be negative if the specified elevation is below the pool limit.
 */
function get_elev_offsets_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevations in  number_tab_t,
   p_datetimes  in  date_table_type,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number_tab_t;
/**
 * Retrieves the offsets of elevations above the bottom and top limits of the specified pool for multiple times.
 *
 * @param p_bottom_offsets The offset of the specified elevation above the pool bottom, in the specified unit.
 *                         Values will be negative if the specified elevation is below the pool bottom.
 * @param p_top_offsets    The offset of the specified elevation above the pool top, in the specified unit.
 *                         Values will be negative if the specified elevation is below the pool top.
 * @param p_project_id     The project to retrieve the offsets for.
 * @param p_pool_name      The pool to retrieve the offsets for.
 * @param p_unit           The unit of the specified elevations and of the offsets. 
 * @param p_elevations     The elevations to determine the offsets for.
 * @param p_datetimes      The times of the elevations, one for each elevation in p_elevations.
 * @param p_timezone       The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id      The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offsets(
   p_bottom_offsets out number_tab_t,
   p_top_offsets    out number_tab_t,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_elevations     in  number_tab_t,
   p_datetimes      in  date_table_type,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves the offsets of elevations above the bottom and top limits of the specified pool for multiple times.
 *
 * @param p_project_id    The project to retrieve the offsets for.
 * @param p_pool_name     The pool to retrieve the offsets for.
 * @param p_unit          The unit of the specified elevations and of the offsets. 
 * @param p_elevations    The elevations to determine the offsets for.
 * @param p_datetimes     The times of the elevations, one for each elevation in p_elevations.
 * @param p_timezone      The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a table of two-value tables with each row arraged as (bottom_offset, top_offset).
 *         Values will be negative if the specified elevation is below the pool limit.
 */
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_elevations    in  number_tab_t,
   p_datetimes     in  date_table_type,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return number_tab_tab_t;
/**
 * Retrieves the offsets of elevations in a time series above the bottom or top limit of the specified pool
 *
 * @param p_offsets    The offsets of the specified elevations above the pool limit, in the specified unit.
 *                     Values will be negative if the specified elevation is below the pool limit.
 * @param p_project_id The project to retrieve the offset for.
 * @param p_pool_name  The pool to retrieve the offset for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the specified elevations and of the offsets. 
 * @param p_timeseries The timeseires with elevations and times.
 * @param p_timezone   The time zone of the elevations and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offsets(
   p_offsets    out ztsv_array,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_timeseries in  ztsv_array,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null);
/**
 * Retrieves the offsets of elevations in a time series above the bottom or top limit of the specified pool.
 *
 * @param p_project_id The project to retrieve the offsets for.
 * @param p_pool_name  The pool to retrieve the offsets for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the specified elevations and of the offsets. 
 * @param p_timeseries The timeseires with elevations and times.
 * @param p_timezone   The time zone of the elevations and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets of the specified elevations above the pool limit, in the specified unit.
 *         Values will be negative if the specified elevation is below the pool limit.
 */
function get_elev_offsets_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_timeseries in  ztsv_array,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array;
/**
 * Retrieves the offsets of an elevation in a time series above the bottom and top limits of the specified pool.
 *
 * @param p_bottom_offsets The offsets of the elevations above the pool bottom, in the specified unit.
 *                         Values will be negative if the specified elevation is below the pool bottom.
 * @param p_top_offsets    The offsets of the elevations above the pool top, in the specified unit.
 *                         Values will be negative if the specified elevation is below the pool top.
 * @param p_project_id     The project to retrieve the offsets for.
 * @param p_pool_name      The pool to retrieve the offsets for.
 * @param p_unit           The unit of the specified elevations and of the offsets. 
 * @param p_timeseries     The timeseires with elevations and times.
 * @param p_timezone       The time zone of the elevations and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id      The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_timeseries     in  ztsv_array,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves the offsets of an elevation above the bottom and top limits of the specified pool for times in a time series.
 *
 * @param p_project_id    The project to retrieve the offset for.
 * @param p_pool_name     The pool to retrieve the offset for.
 * @param p_unit          The unit of the specified elevation and of the offset. 
 * @param p_timeseries    The timeseires with elevations and times.
 * @param p_timezone      The time zone of the elevations and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a table of two-value tables with each row arraged as (bottom_offset, top_offset).
 *         Values will be negative if the specified elevation is below the pool limit.
 */
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_timeseries    in  ztsv_array,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return ztsv_array_tab;
/**
 * Retrieves the offsets of elevations in a time series above the bottom or top limit of the specified pool.
 *
 * @param p_offsets    The offsets of the elevations above the pool limit, in the specified unit.
 *                     Values will be negative if the specified elevation is below the pool limit.
 * @param p_project_id The project to retrieve the offsets for.
 * @param p_pool_name  The pool to retrieve the offsets for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the elevations and of the offsets. 
 * @param p_tsid       The name of the timeseires with elevations and times.
 * @param p_start_time The start of the time window for the time series.
 * @param p_end_time   The end of the time window for the time series
 * @param p_timezone   The time zone of p_start_time, p_end_time, and p_offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offsets(
   p_offsets    out ztsv_array,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_tsid       in  varchar2,
   p_start_time in  date,
   p_end_time   in  date,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null);
/**
 * Retrieves the offsets of an elevations in a time series above the bottom or top limit of the specified pool.
 *
 * @param p_project_id The project to retrieve the offsets for.
 * @param p_pool_name  The pool to retrieve the offsets for.
 * @param p_limit      Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit       The unit of the elevations and of the offsets. 
 * @param p_tsid       The name of the timeseires with elevations and times.
 * @param p_start_time The start of the time window for the time series.
 * @param p_end_time   The end of the time window for the time series
 * @param p_timezone   The time zone of p_start_time, p_end_time, and the results. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id  The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets of the elevations above the pool limit, in the specified unit.
 *         Values will be negative if the specified elevation is below the pool limit.
 */
function get_elev_offsets_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_tsid       in  varchar2,
   p_start_time in  date,
   p_end_time   in  date,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array;
/**
 * Retrieves the offsets of an elevations in a time series above the bottom and top limits of the specified pool.
 *
 * @param p_bottom_offsets The offsets of the elevations above the pool bottom, in the specified unit.
 *                         Values will be negative if the specified elevation is below the pool bottom.
 * @param p_top_offsets    The offsets of the elevations above the pool top, in the specified unit.
 *                         Values will be negative if the specified elevation is below the pool top.
 * @param p_project_id     The project to retrieve the offsets for.
 * @param p_pool_name      The pool to retrieve the offsets for.
 * @param p_unit           The unit of the elevations and of the offsets. 
 * @param p_tsid           The name of the timeseires with elevations and times.
 * @param p_start_time     The start of the time window for the time series.
 * @param p_end_time       The end of the time window for the time series
 * @param p_timezone       The time zone of p_start_time, p_end_time, p_bottom_offsets, and p_top_offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_office_id      The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_elev_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_tsid           in  varchar2,
   p_start_time     in  date,
   p_end_time       in  date,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves the offsets of elevations in a time series above the bottom and top limits of the specified pool.
 *
 * @param p_project_id    The project to retrieve the offsets for.
 * @param p_pool_name     The pool to retrieve the offsets for.
 * @param p_unit          The unit of the elevations and of the offsets. 
 * @param p_tsid          The name of the timeseires with elevations and times.
 * @param p_start_time    The start of the time window for the time series.
 * @param p_end_time      The end of the time window for the time series
 * @param p_timezone      The time zone of p_start_time, p_end_time, and the results. If NULL or not specified, the local time zone of the project is used.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a table of two-value tables with each row arraged as (bottom_offset, top_offset).
 */
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_tsid          in  varchar2,
   p_start_time    in  date,
   p_end_time      in  date,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return ztsv_array_tab;
/**
 * Retrieves the offset of an storage above the bottom or top limit of the specified pool for a single time.
 *
 * @param p_offset      The offset of the specified storage above the pool limit, in the specified unit.
 *                      This value will be negative if the specified storage is below the pool limit.
 * @param p_project_id  The project to retrieve the offset for.
 * @param p_pool_name   The pool to retrieve the offset for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the specified storage and of the offset. 
 * @param p_storage     The storage to determine the offset for.
 * @param p_datetime    The time of the storage. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offset(
   p_offset      out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_storage     in  number,
   p_datetime    in  date default null,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the offset of an storage above the bottom or top limit of the specified pool for a single time.
 *
 * @param p_project_id  The project to retrieve the offset for.
 * @param p_pool_name   The pool to retrieve the offset for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the specified storage and of the offset. 
 * @param p_storage     The storage to determine the offset for.
 * @param p_datetime    The time of the storage. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offset of the specified storage above the pool limit, in the specified unit.
 *         This value will be negative if the specified storage is below the pool limit.
 */
function get_stor_offset_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_storage     in number,
   p_datetime    in date default null,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return number;
/**
 * Retrieves the offsets of an storage above the bottom and top limits of the specified pool for a single time.
 *
 * @param p_bottom_offset The offset of the specified storage above the pool bottom, in the specified unit.
 *                        This value will be negative if the specified storage is below the pool bottom.
 * @param p_top_offset    The offset of the specified storage above the pool top, in the specified unit.
 *                        This value will be negative if the specified storage is below the pool top.
 * @param p_project_id    The project to retrieve the offset for.
 * @param p_pool_name     The pool to retrieve the offset for.
 * @param p_unit          The unit of the specified storage and of the offset. 
 * @param p_storage       The storage to determine the offset for.
 * @param p_datetime      The time of the storage. If NULL or not specified, the current time is used.
 * @param p_timezone      The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate   A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec   The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                        A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                        If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offsets(
   p_bottom_offset out number,
   p_top_offset    out number,
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_storage       in  number,
   p_datetime      in  date default null,
   p_timezone      in  varchar2 default null,
   p_always_rate   in  varchar2 default 'T',
   p_rating_spec   in  varchar2 default null,
   p_office_id     in  varchar2 default null);
/**
 * Retrieves the offsets of an storage above the bottom and top limits of the specified pool for a single time.
 *
 * @param p_project_id  The project to retrieve the offset for.
 * @param p_pool_name   The pool to retrieve the offset for.
 * @param p_unit        The unit of the specified storage and of the offset. 
 * @param p_storage     The storage to determine the offset for.
 * @param p_datetime    The time of the storage. If NULL or not specified, the current time is used.
 * @param p_timezone    The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a two-value table, arraged as (bottom_offset, top_offset).
 */
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,             
   p_unit          in varchar2,
   p_storage       in number,
   p_datetime      in date default null,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_office_id     in varchar2 default null)
   return number_tab_t;
/**
 * Retrieves the offsets of storages above the bottom or top limit of the specified pool for multiple times.
 *
 * @param p_offsets     The offsetsof the specified storage above the pool limit, in the specified unit.
 *                      Values will be negative if the specified storage is below the pool limit.
 * @param p_project_id  The project to retrieve the offsets for.
 * @param p_pool_name   The pool to retrieve the offsets for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the specified storages and of the offsets. 
 * @param p_storages    The storages to determine the offsets for.
 * @param p_datetimes   The times of the storages, one for each storage in p_storages  .
 * @param p_timezone    The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offsets(
   p_offsets     out number_tab_t,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_storages    in  number_tab_t,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the offsets of storages above the bottom or top limit of the specified pool for multiple times.
 *
 * @param p_project_id  The project to retrieve the offsets for.
 * @param p_pool_name   The pool to retrieve the offsets for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the specified storages and of the offsets. 
 * @param p_storages    The storages to determine the offsets for.
 * @param p_datetimes   The times of the storages, one for each storage in p_storages  .
 * @param p_timezone    The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets of the specified storages above the pool limit, in the specified unit.
 *         Values will be negative if the specified storage is below the pool limit.
 */
function get_stor_offsets_f(
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_storages    in  number_tab_t,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in  varchar2 default null)
   return number_tab_t;
/**
 * Retrieves the offsets of storages above the bottom and top limits of the specified pool for multiple times.
 *
 * @param p_bottom_offsets The offset of the specified storage above the pool bottom, in the specified unit.
 *                         Values will be negative if the specified storage is below the pool bottom.
 * @param p_top_offsets    The offset of the specified storage above the pool top, in the specified unit.
 *                         Values will be negative if the specified storage is below the pool top.
 * @param p_project_id     The project to retrieve the offsets for.
 * @param p_pool_name      The pool to retrieve the offsets for.
 * @param p_unit           The unit of the specified storages and of the offsets. 
 * @param p_storages       The storages to determine the offsets for.
 * @param p_datetimes      The times of the storages, one for each storage in p_storages  .
 * @param p_timezone       The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate    A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec    The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                         A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                         If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id      The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offsets(
   p_bottom_offsets out number_tab_t,
   p_top_offsets    out number_tab_t,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_storages       in  number_tab_t,
   p_datetimes      in  date_table_type,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves the offsets of storages above the bottom and top limits of the specified pool for multiple times.
 *
 * @param p_project_id    The project to retrieve the offsets for.
 * @param p_pool_name     The pool to retrieve the offsets for.
 * @param p_unit          The unit of the specified storages and of the offsets. 
 * @param p_storages      The storages to determine the offsets for.
 * @param p_datetimes     The times of the storages, one for each storage in p_storages  .
 * @param p_timezone      The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate   A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec   The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                        A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                        If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a table of two-value tables with each row arraged as (bottom_offset, top_offset).
 *         Values will be negative if the specified storage is below the pool limit.
 */
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_storages      in number_tab_t,
   p_datetimes     in date_table_type,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return number_tab_tab_t;
/**
 * Retrieves the offsets of storages in a time series above the bottom or top limit of the specified pool
 *
 * @param p_offsets     The offsets of the specified storages above the pool limit, in the specified unit.
 *                      Values will be negative if the specified storage is below the pool limit.
 * @param p_project_id  The project to retrieve the offset for.
 * @param p_pool_name   The pool to retrieve the offset for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the specified storages and of the offsets. 
 * @param p_timeseries  The timeseires with storages and times.
 * @param p_timezone    The time zone of the storages and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offsets(
   p_offsets     out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_timeseries  in  ztsv_array,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the offsets of storages in a time series above the bottom or top limit of the specified pool.
 *
 * @param p_project_id  The project to retrieve the offsets for.
 * @param p_pool_name   The pool to retrieve the offsets for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the specified storages and of the offsets. 
 * @param p_timeseries  The timeseires with storages and times.
 * @param p_timezone    The time zone of the storages and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets of the specified storages above the pool limit, in the specified unit.
 *         Values will be negative if the specified storage is below the pool limit.
 */
function get_stor_offsets_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_timeseries  in ztsv_array,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;
/**
 * Retrieves the offsets of an storage in a time series above the bottom and top limits of the specified pool.
 *
 * @param p_bottom_offsets The offsets of the storages above the pool bottom, in the specified unit.
 *                         Values will be negative if the specified storage is below the pool bottom.
 * @param p_top_offsets    The offsets of the storages above the pool top, in the specified unit.
 *                         Values will be negative if the specified storage is below the pool top.
 * @param p_project_id     The project to retrieve the offsets for.
 * @param p_pool_name      The pool to retrieve the offsets for.
 * @param p_unit           The unit of the specified storages and of the offsets. 
 * @param p_timeseries     The timeseires with storages and times.
 * @param p_timezone       The time zone of the storages and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate    A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec    The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                         A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                         If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id      The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_timeseries     in  ztsv_array,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves the offsets of an storage above the bottom and top limits of the specified pool for times in a time series.
 *
 * @param p_project_id    The project to retrieve the offset for.
 * @param p_pool_name     The pool to retrieve the offset for.
 * @param p_unit          The unit of the specified storage and of the offset. 
 * @param p_timeseries    The timeseires with storages and times.
 * @param p_timezone      The time zone of the storages and offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate   A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec   The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                        A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                        If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a table of two-value tables with each row arraged as (bottom_offset, top_offset).
 *         Values will be negative if the specified storage is below the pool limit.
 */
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_timeseries    in ztsv_array,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return ztsv_array_tab;
/**
 * Retrieves the offsets of storages in a time series above the bottom or top limit of the specified pool.
 *
 * @param p_offsets     The offsets of the storages above the pool limit, in the specified unit.
 *                      Values will be negative if the specified storage is below the pool limit.
 * @param p_project_id  The project to retrieve the offsets for.
 * @param p_pool_name   The pool to retrieve the offsets for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the storages and of the offsets. 
 * @param p_tsid        The name of the timeseires with storages and times.
 * @param p_start_time  The start of the time window for the time series.
 * @param p_end_time    The end of the time window for the time series
 * @param p_timezone    The time zone of p_start_time, p_end_time, and p_offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offsets(
   p_offsets     out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_tsid        in  varchar2,
   p_start_time  in  date,
   p_end_time    in  date,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Retrieves the offsets of an storages in a time series above the bottom or top limit of the specified pool.
 *
 * @param p_project_id  The project to retrieve the offsets for.
 * @param p_pool_name   The pool to retrieve the offsets for.
 * @param p_limit       Specifies to offset from bottom or top level. Either ''BOTTOM'' or ''TOP'' (case insensitive) or a beginning substring thereof. 
 * @param p_unit        The unit of the storages and of the offsets. 
 * @param p_tsid        The name of the timeseires with storages and times.
 * @param p_start_time  The start of the time window for the time series.
 * @param p_end_time    The end of the time window for the time series
 * @param p_timezone    The time zone of p_start_time, p_end_time, and the results. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                      A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                      If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id   The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets of the storages above the pool limit, in the specified unit.
 *         Values will be negative if the specified storage is below the pool limit.
 */
function get_stor_offsets_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_tsid        in varchar2,
   p_start_time  in date,
   p_end_time    in date,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;
/**
 * Retrieves the offsets of an storages in a time series above the bottom and top limits of the specified pool.
 *
 * @param p_bottom_offsets The offsets of the storages above the pool bottom, in the specified unit.
 *                         Values will be negative if the specified storage is below the pool bottom.
 * @param p_top_offsets    The offsets of the storages above the pool top, in the specified unit.
 *                         Values will be negative if the specified storage is below the pool top.
 * @param p_project_id     The project to retrieve the offsets for.
 * @param p_pool_name      The pool to retrieve the offsets for.
 * @param p_unit           The unit of the storages and of the offsets. 
 * @param p_tsid           The name of the timeseires with storages and times.
 * @param p_start_time     The start of the time window for the time series.
 * @param p_end_time       The end of the time window for the time series
 * @param p_timezone       The time zone of p_start_time, p_end_time, p_bottom_offsets, and p_top_offsets. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate    A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec    The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                         A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                         If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id      The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_stor_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_tsid           in  varchar2,
   p_start_time     in  date,
   p_end_time       in  date,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves the offsets of storages in a time series above the bottom and top limits of the specified pool.
 *
 * @param p_project_id    The project to retrieve the offsets for.
 * @param p_pool_name     The pool to retrieve the offsets for.
 * @param p_unit          The unit of the storages and of the offsets. 
 * @param p_tsid          The name of the timeseires with storages and times.
 * @param p_start_time    The start of the time window for the time series.
 * @param p_end_time      The end of the time window for the time series
 * @param p_timezone      The time zone p_start_time, p_end_time, and the results. If NULL or not specified, the local time zone of the project is used.
 * @param p_always_rate   A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec   The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                        A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                        If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_datetime_axis ''ROW'' or ''COLUMN'' (or any initial substring thereof).
 *                        If ''ROW'' the results have as many rows as there are datetimes, with each row having a table of two values: (bottom, top).
 *                        If ''COLUMN'' the results have two rows: (bottom, top), with each row being a table of values of each datetime.
 * @param p_office_id     The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The offsets in a table of two-value tables with each row arraged as (bottom_offset, top_offset).
 */
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_tsid          in varchar2,
   p_start_time    in date,
   p_end_time      in date,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return ztsv_array_tab;
/**
 * Retreives the percent of pool storage represented by an elevation or storage at a single time.
 *
 * @param p_percent_full The percent of pool storage filled at the specified elevation or storage.
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_unit         The unit of p_value. Must be a valid elevation unit or storage unit. 
 * @param p_value        The elevation or storage to determine the percent full for.
 * @param p_datetime     The time of p_value. If NULL or not specified, the current time is used.
 * @param p_timezone     The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the result to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_percent_full(
   p_percent_full out number,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_value        in  number,
   p_datetime     in  date default null,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retreives the percent of pool storage represented by an elevation or storage at a single time.
 *
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_unit         The unit of p_value. Must be a valid elevation unit or storage unit. 
 * @param p_value        The elevation or storage to determine the percent full for.
 * @param p_datetime     The time of p_value. If NULL or not specified, the current time is used.
 * @param p_timezone     The time zone of p_datetime, if specified. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the result to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The percent of pool storage filled at the specified elevation or storage.
 */
function get_percent_full_f(
   p_project_id   in varchar2,
   p_pool_name    in varchar2,
   p_unit         in varchar2,
   p_value        in number,
   p_datetime     in date default null,
   p_timezone     in varchar2 default null,
   p_0_to_100     in varchar2 default 'F',
   p_always_rate  in varchar2 default 'T',
   p_rating_spec  in varchar2 default null,
   p_office_id    in varchar2 default null)
   return number;
/**
 * Retreives the percent of pool storages represented by elevations or storages at a multiple times.
 *
 * @param p_percent_full The percent of pool storage filled at the specified elevations or storages.
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_unit         The unit of p_values. Must be a valid elevation unit or storage unit. 
 * @param p_values       The elevations or storages to determine the percent full for.
 * @param p_datetimes    The times of p_values, one per each value.
 * @param p_timezone     The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the results to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_percent_full(
   p_percent_full out number_tab_t,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_values       in  number_tab_t,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retreives the percent of pool storages represented by elevations or storages at a multiple times.
 *
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_unit         The unit of p_values. Must be a valid elevation unit or storage unit. 
 * @param p_values       The elevations or storages to determine the percent full for.
 * @param p_datetimes    The times of p_values, one per each value.
 * @param p_timezone     The time zone of p_datetimes. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the results to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The percent of pool storage filled at the specified elevations or storages.
 */
function get_percent_full_f(
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_values       in  number_tab_t,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
   return number_tab_t;
/**
 * Retreives the percent of pool storages represented by elevations or storages in a time series.
 *
 * @param p_percent_full The percent of pool storage filled at the specified elevations or storages.
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_unit         The unit of values in p_timeseries. Must be a valid elevation unit or storage unit. 
 * @param p_timeseries   The time series containing the elevations or storages.
 * @param p_timezone     The time zone of p_timeseries. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the results to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_percent_full(
   p_percent_full out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retreives the percent of pool storages represented by elevations or storages in a time series.
 *
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_unit         The unit of values in p_timeseries. Must be a valid elevation unit or storage unit. 
 * @param p_timeseries   The time series containing the elevations or storages.
 * @param p_timezone     The time zone of p_timeseries. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the results to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The percent of pool storage filled at the specified elevations or storages.
 */
function get_percent_full_f(
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
   return ztsv_array;
/**
 * Retreives the percent of pool storages represented by elevations or storages in a time series.
 *
 * @param p_percent_full The percent of pool storage filled at the specified elevations or storages.
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_tsid         The name of the time series containing the elevations or storages.
 * @param p_start_time   The start of the time window for p_tsid.
 * @param p_end_time     The end of the time window for p_tsid.
 * @param p_timezone     The time zone of p_start_time, p_end_time, and p_percent_full. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the results to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 */
procedure get_percent_full(
   p_percent_full out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null);
/**
 * Retreives the percent of pool storages represented by elevations or storages in a time series.
 *
 * @param p_project_id   The project to retrieve the percent full for.
 * @param p_pool_name    The pool to retrieve the percent for.
 * @param p_tsid         The name of the time series containing the elevations or storages.
 * @param p_start_time   The start of the time window for p_tsid.
 * @param p_end_time     The end of the time window for p_tsid.
 * @param p_timezone     The time zone of p_start_time, p_end_time, and p_percent_full. If NULL or not specified, the local time zone of the project is used.
 * @param p_0_to_100     A flag (T/F) specifying whether to constrain the results to the range of 0..100. If F, the result may be negative or greater than 100.
 * @param p_always_rate  A flag (T/F) specifying whether to rate from Elev to Stor even if a Stor location level exists for the project.
 * @param p_rating_spec  The rating specification to use if necessary. If NULL or not specified, a "standard" rating will be used if available.
 *                       A "standard" rating is <location>.Elev;Stor.(Linear|Log|Custom|Standard).(Step|Distributed|Custom|Production).
 *                       If rating from Elev with no specified rating, the routine will succeed if exactly one "standard" rating is found.
 * @param p_office_id    The office that owns the project. If NULL or not specified, the session user's office is used.
 *
 * @return The percent of pool storage filled at the specified elevations or storages.
 */
function get_percent_full_f(
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
   return ztsv_array;

end cwms_pool;
/
show errors

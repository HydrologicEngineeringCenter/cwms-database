set define off
create or replace package cwms_turbine
/**
 * Provides facilities to manipulate turbines and their supporting types  
 * in the CWMS database.                                                            
 * <p>                                                                                        
 * An turbine will always have a parent project defined in AT_PROJECT.                      
 * There can be zero to many turbines for a given project.                                  
 * <p>                                                                                        
 * On all routines, if the office identifier is not specified or is specified as
 * <code><big>NULL</big></code> the office of the user calling the routine is assumed.                                                
 *
 * @author Mike Perryman, HEC
 * @author Pete Morris, RMA
 * @since CWMS 2.1                        
 */ 
as

/**
 * Retrieves information about a single specified turbine.
 * 
 * @param p_turbine the retrieved turbine information
 * @param p_turbine_location the specification of the turbine to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_turbine_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_turbine_location</big></code>
 *         exists in the database but is not identified as an turbine.                     
 */   
procedure retrieve_turbine(
   p_turbine          out project_structure_obj_t,
   p_turbine_location in  location_ref_t);
/**
 * Retrieves information about a single specified turbine.
 * 
 * @param p_turbine_location the specification of the turbine to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.
 *
 * @return the retrieved turbine information
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_turbine_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_turbine_location</big></code>
 *         exists in the database but is not identified as an turbine.                     
 */   
function retrieve_turbine_f(
   p_turbine_location in location_ref_t)
   return project_structure_obj_t;
/**
 * Retrieves information about all turbines of a specified project.
 * 
 * @param p_turbines the retrieved turbine information
 * @param p_project_location the specification of the project to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.      
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_project_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_project_location</big></code>
 *         exists in the database but is not identified as a project.                     
 */   
procedure retrieve_turbines(
   p_turbines          out project_structure_tab_t,
   p_project_location in  location_ref_t);
/**
 * Retrieves information about all turbines of a specified project.
 * 
 * @param p_project_location the specification of the project to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.      
 *
 * @param the retrieved turbine information
 *         
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_project_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_project_location</big></code>
 *         exists in the database but is not identified as a project.                     
 */   
function retrieve_turbines_f(
   p_project_location in location_ref_t)
   return project_structure_tab_t;
/**
 * Stores information about a single specified turbine in the database.
 * 
 * @param p_turbine the turbine information to store. The turbine will be created
 *        if it doesn't already exist in the database 
 * @param p_fail_if_exists specifies whether to fail if the specified location for the turbine
 *        already exists in the database.
 *        </ul>
 *            <li><code><big>'T'</big></code> - the procedure will raise an exception if 
 *                the specified location for the turbine already exists in the database</li>   
 *            <li><code><big>'F'</big></code> - the procedure will update the update the 
 *                information if the specified location for the turbine already exists in the  database</li>   
 *        </ul> 
 * 
 * @throws ITEM_ALREADY_EXISTS if the specified location for the turbine already exists in the 
 *         database and <code><big>p_fail_if_exists</big></code> is specified as <code><big>'T'</big></code>
 * @throws ERROR if the specified location for the turbine already exists in the database and 
 *         <code><big>p_fail_if_exists</big></code> is specified as <code><big>'F'</big></code> and the
 *         existing location is identified as some type of object other than a turbine                                
 */ 
procedure store_turbine(
   p_turbine        in project_structure_obj_t,
   p_fail_if_exists in varchar2 default 'T');
/**
 * Stores information about a multiple related turbines in the database.
 * 
 * @param p_turbines the turbine information to store. Each turbine will be created
 *        if it doesn't already exist in the database
 * @param p_fail_if_exists specifies whether to fail if the specifies turbine
 *        already exists in the database.
 *        </ul>
 *            <li><code><big>'T'</big></code> - the procedure will raise an exception if 
 *                the any of the specified locations for the turbines already exists in the database</li>   
 *            <li><code><big>'F'</big></code> - the procedure will update the update the 
 *                information if any of the specified locations for the turbines already exists in the  database</li>   
 *        </ul> 
 * 
 * @throws ITEM_ALREADY_EXISTS if any of the specified locations for the turbines already exists in the 
 *         database and <code><big>p_fail_if_exists</big></code> is specified as <code><big>'T'</big></code>                    
 * @throws ERROR if any of the specified turbines already exists in the database and 
 *         <code><big>p_fail_if_exists</big></code> is specified as <code><big>'F'</big></code> and the
 *         existing location is identified as some type of object other than a turbine.                                
 */ 
procedure store_turbines(
   p_turbines       in project_structure_tab_t,
   p_fail_if_exists in varchar2 default 'T');
/**
 * Renames an existing turbine
 * 
 * @param p_turbine_id_old the location identifier of the turbine as it currently
 *        exists in the database
 * @param p_turbine_id_new the new location identifier of the turbine
 * @param p_office_id the identifier of the office for which to rename the turbine.
 *        if <code><big>NULL</big></code> then the office of the user calling the procedure
 *        is assumed.       
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_turbine_id_old</big></code> does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_turbine_id_old</big></code> exists in the database but is not identified
 *        as an turbine.
 * @throws LOCATION_ID_ALREADY_EXISTS if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_turbine_id_new</big></code> already exists in the database.                               
 */    
procedure rename_turbine(
   p_turbine_id_old in varchar2,
   p_turbine_id_new in varchar2,
   p_office_id     in varchar2 default null);
/**
 * Deletes an turbine from the database.
 *  
 * @param p_turbine_id the location identifier of the turbine
 * @param p_delete_action the type of deletion to perform.
 *        <dl>
 *        <dt><code><big><b>cwms_util.delete_key</b></big></code></dt>
 *        <dd>only the turbine location is deleted. The presence of any dependent
 *            data will cause the procedure to fail.</dd>
 *        <dt><code><big><b>cwms_util.delete_data</b></big></code></dt>
 *        <dd>only dependent data (if any) will be deleted.  The turbine location 
 *            will not be deleted</dd>  
 *        <dt><code><big><b>cwms_util.delete_all</b></big></code></dt>
 *        <dd>the turbine location and any depedent data will be deleted</dd>
 *        </dl> 
 * @param p_office_id the identifier of the office for which to rename the turbine.
 *        if <code><big>NULL</big></code> then the office of the user calling the procedure
 *        is assumed.       
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_turbine_id_old</big></code> does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_turbine_id_old</big></code> exists in the database but is not identified
 *        as an turbine.
 * @throws INVALID_DELETE_ACTION if <code><big>p_delete_action</big></code> is not one
 *         of the values identified above.          
 */    
procedure delete_turbine(
   p_turbine_id    in varchar,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Deletes an turbine from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_turbine_id The location identifier of the turbine
 *
 * @param p_delete_action Specifies what turbine elements to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only this turbine, and then only if it has no dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only dependent data of this turbine, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this turbine and dependent data, if any</td>
 *   </tr>
 * </table>
 * @param p_delete_location A flag (T/F) that indicates whether the underlying location should be deleted.
 * @param p_delete_location_action Specifies what location elements to delete.  Actions are as follows (only if p_delete_location is 'T'):
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the location, does not delete any dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only dependent data but does not delete the actual location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">delete the location and all dependent data</td>
 *   </tr>
 * </table>
 * @param p_office_id The office that owns the turbine location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such turbine location exists
 */
procedure delete_turbine2(
   p_turbine_id          in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null);
/**
 * Store one or more turbine changes.  Any turbine changes in the (implicit or explicit)
 * time window already in the database will be deleted before the specified 
 * changes are stored.  The implicit time window is defined by the <code><big>change_date</big></code>
 * members of the individual <code><big>turbine_change_obj_t</big></code> items specified in the
 * <code><big>p_turbine_changes</big></code> parameter.   
 * 
 * @param p_turbine_changes the turbine changes to store
 * @param p_start_time beginning of the explicit time window. If not specified or
 *        specified as <code><big>NULL</big></code> the time window starts at the 
 *        <code><big>change_date</big></code> member of the first <code><big>turbine_change_obj_t</big></code>
 *        item in the <code><big>p_turbine_changes</big></code> parameter.         
 * @param p_end_time end of the explicit time window. If not specified or
 *        specified as <code><big>NULL</big></code> the time window ends at the 
 *        <code><big>change_date</big></code> member of the last <code><big>turbine_change_obj_t</big></code>
 *        item in the <code><big>p_turbine_changes</big></code> parameter.
 * @param p_time_zone time zone in which to interpret <code><big>p_start_time</big></code>
 *        and <code><big>p_end_time</big></code>.  If not specified or specified as <code><big>NULL</big></code>
 *        then the local time zone of the project will be assumed.   
 * @param p_start_time_inclusive specifies whether the start time is inclusive
 *        </ul>
 *            <li><code><big>'T' - p_start_time</big></code> specifies the earliest time in the time window</li>   
 *            <li><code><big>'F' - p_start_time</big></code> specifies the latest time before the time window</li>   
 *        </ul> 
 * @param p_end_time_inclusive specifies whether the end time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_end_time</big></code> specifies the latest time in the time window</li>   
 *            <li><code><big>'F' - p_end_time</big></code> specifies the earlies time after the time window</li>   
 *        </ul> 
 * @param p_override_protection specifies whether to override the protected status of 
 *        any existing turbine change in the database when attempting to delete it.
 *        </ul>
 *            <li><code><big>'T'</big></code> - delete protected turbine changes</li>   
 *            <li><code><big>'F'</big></code> - do not delete protected turbine changes</li>   
 *        </ul> 
 *
 * @throws ERROR if not all <code><big>turbine_change_obj_t</big></code> refer to the same project
 * @throws ERROR if turbine changes are not specified in ascending time order
 * @throws ERROR if an attempt is made to delete a protected turbine change and 
 *         <code><big>p_override_prot</big></code> is <code><big>'F'</big></code> 
 * @throws ERROR if <code><big>p_start_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_start_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 * @throws ERROR if <code><big>p_end_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_end_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 * @throws ITEM_DOES_NOT_EXIST if a discharge computation or release reason is specified
 *         that does not exist in
 *         the database          
 * @throws ERROR if a discharge computation or release reason is specified that belongs
 *         to a different office than the turbine change.                     
 */ 
procedure store_turbine_changes(
   p_turbine_changes      in turbine_change_tab_t,
   p_start_time           in date default null,
   p_end_time             in date default null,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F');
/**
 * Retrieves turbine changes from the database for a specified project and time window, 
 * optionally limited to a maximum number of changes.
 * 
 * @param p_turbine_changes the turbine changes retrieved from the database
 * @param p_project_location the project for which to retrieve the turbine changes.
 *        If the office_id member is <code><big>NULL</big></code> then the office of the user 
 *        calling the procedure is assumed.
 * @param p_start_time the beginning of the time window
 * @param p_end time the end of the time window              
 * @param p_time_zone time zone in which to interpret <code><big>p_start_time</big></code>
 *        and <code><big>p_end_time</big></code>.  he <code><big>change_date</big></code> members of 
 *        the individual <code><big>turbine_change_obj_t</big></code> items returned will also
 *        be in this time zone. If not specified or specified as <code><big>NULL</big></code>
 *        then the local time zone of the project will be assumed.
 * @param p_unit_system the unit system (<code><big>'EN'</big></code> or <code><big>'SI'</big></code>)
 *        in which to return the turbine change information. If not specified or 
 *        specified as <code><big>NULL</big></code> then the first non-null value in the
 *        following list will be used:
 *        <ol>
 *        <li>database property:
 *            <dl>
 *            <dt><b>office id:</b></dt>
 *            <dd><code><big>'&lt;<em>user's office id</em>&gt;'</big></code></dd>   
 *            <dt><b>category :</b></dt>
 *            <dd><code><big>'Pref_User.&lt;<em>users's user id</em>&gt;'</big></code></dd>   
 *            <dt><b>identifier :</b></dt>
 *            <dd><code><big>'Unit_System'</big></code></dd>
 *            </dl>    
 *        <li>database property:
 *            <dl>
 *            <dt><b>office id:</b></dt>
 *            <dd><code><big>'&lt;<em>user's office id</em>&gt;'</big></code></dd>   
 *            <dt><b>category :</b></dt>
 *            <dd><code><big>'Pref_Office'</big></code></dd>   
 *            <dt><b>identifier :</b></dt>
 *            <dd><code><big>'Unit_System'</big></code></dd>
 *            </dl>                 
 *        <li><code><big>'SI'</big></code>
 *        </ol>
 * @param p_start_time_inclusive specifies whether the start time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_start_time</big></code> specifies the earliest time in the time window</li>   
 *            <li><code><big>'F' - p_start_time</big></code> specifies the latest time before the time window</li>   
 *        </ul> 
 * @param p_end_time_inclusive specifies whether the end time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_end_time</big></code> specifies the latest time in the time window</li>   
 *            <li><code><big>'F' - p_end_time</big></code> specifies the earlies time after the time window</li>   
 *        </ul> 
 * @param p_max_item_count the maximum number of turbine changes to retrieve, regardless of 
 *        time window.  A positive integer is interpreted as the maximum number of 
 *        changes from the beginning of the time window. A negative integer is 
 *        interpreted as the maximum number from the end of the time window.
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_project_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_project_location</big></code>
 *         exists in the database but is not identified as a project.
 * @throws ERROR if <code><big>p_max_item_count</big></code> is specified as zero                               
 * @throws ERROR if <code><big>p_start_time</big></code> is later than <code><big>p_end_time</big></code>                               
 */ 
procedure retrieve_turbine_changes(
   p_turbine_changes      out turbine_change_tab_t,
   p_project_location     in  location_ref_t,
   p_start_time           in  date,
   p_end_time             in  date,
   p_time_zone            in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_start_time_inclusive in  varchar2 default 'T',
   p_end_time_inclusive   in  varchar2 default 'T',
   p_max_item_count       in  integer default null);
/**
 * Retrieves turbine changes from the database for a specified project and time window, 
 * optionally limited to a maximum number of changes.
 * 
 * @param p_project_location the project for which to retrieve the turbine changes.
 *        If the office_id member is <code><big>NULL</big></code> then the office of the user 
 *        calling the procedure is assumed.
 * @param p_start_time the beginning of the time window
 * @param p_end time the end of the time window              
 * @param p_time_zone time zone in which to interpret <code><big>p_start_time</big></code>
 *        and <code><big>p_end_time</big></code>.  he <code><big>change_date</big></code> members of 
 *        the individual <code><big>turbine_change_obj_t</big></code> items returned will also
 *        be in this time zone. If not specified or specified as <code><big>NULL</big></code>
 *        then the local time zone of the project will be assumed.
 * @param p_unit_system the unit system (<code><big>'EN'</big></code> or <code><big>'SI'</big></code>)
 *        in which to return the turbine change information. If not specified or 
 *        specified as <code><big>NULL</big></code> then the first non-null value in the
 *        following list will be used:
 *        <ol>
 *        <li>database property:
 *            <dl>
 *            <dt><b>office id:</b></dt>
 *            <dd><code><big>'&lt;<em>user's office id</em>&gt;'</big></code></dd>   
 *            <dt><b>category :</b></dt>
 *            <dd><code><big>'Pref_User.&lt;<em>users's user id</em>&gt;'</big></code></dd>   
 *            <dt><b>identifier :</b></dt>
 *            <dd><code><big>'Unit_System'</big></code></dd>
 *            </dl>    
 *        <li>database property:
 *            <dl>
 *            <dt><b>office id:</b></dt>
 *            <dd><code><big>'&lt;<em>user's office id</em>&gt;'</big></code></dd>   
 *            <dt><b>category :</b></dt>
 *            <dd><code><big>'Pref_Office'</big></code></dd>   
 *            <dt><b>identifier :</b></dt>
 *            <dd><code><big>'Unit_System'</big></code></dd>
 *            </dl>                 
 *        <li><code><big>'SI'</big></code>
 *        </ol>
 * @param p_start_time_inclusive specifies whether the start time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_start_time</big></code> specifies the earliest time in the time window</li>   
 *            <li><code><big>'F' - p_start_time</big></code> specifies the latest time before the time window</li>   
 *        </ul> 
 * @param p_end_time_inclusive specifies whether the end time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_end_time</big></code> specifies the latest time in the time window</li>   
 *            <li><code><big>'F' - p_end_time</big></code> specifies the earlies time after the time window</li>   
 *        </ul> 
 * @param p_max_item_count the maximum number of turbine changes to retrieve, regardless of 
 *        time window.  A positive integer is interpreted as the maximum number of 
 *        changes from the beginning of the time window. A negative integer is 
 *        interpreted as the maximum number from the end of the time window.
 *         
 * @return the turbine changes retrieved from the database
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_project_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_project_location</big></code>
 *         exists in the database but is not identified as a project.
 * @throws ERROR if <code><big>p_max_item_count</big></code> is specified as zero                               
 * @throws ERROR if <code><big>p_start_time</big></code> is later than <code><big>p_end_time</big></code>                               
 */ 
function retrieve_turbine_changes_f(
   p_project_location      in location_ref_t,
   p_start_time            in date,
   p_end_time              in date,
   p_time_zone             in varchar2 default null,
   p_unit_system           in varchar2 default null,
   p_start_time_inclusive  in varchar2 default 'T',
   p_end_time_inclusive    in varchar2 default 'T',
   p_max_item_count        in integer default null)
   return turbine_change_tab_t;
/**
 * Delete turbine changes for a specified project and time window   
 *
 * @param p_project_location the project for which to delete the turbine changes.  
 * @param p_start_time beginning of the time window.         
 * @param p_end_time end of the time window.
 * @param p_time_zone time zone in which to interpret <code><big>p_start_time</big></code>
 *        and <code><big>p_end_time</big></code>.  If not specified or specified as <code><big>NULL</big></code>
 *        then the local time zone of the project will be assumed.   
 * @param p_start_time_inclusive specifies whether the start time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_start_time</big></code> specifies the earliest time in the time window</li>   
 *            <li><code><big>'F' - p_start_time</big></code> specifies the latest time before the time window</li>   
 *        </ul> 
 * @param p_end_time_inclusive specifies whether the end time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_end_time</big></code> specifies the latest time in the time window</li>   
 *            <li><code><big>'F' - p_end_time</big></code> specifies the earlies time after the time window</li>   
 *        </ul> 
 * @param p_override_protection specifies whether to override the protected status of 
 *        any existing turbine change in the database when attempting to delete it. 
 *        </ul>
 *            <li><code><big>'T'</big></code> - delete protected turbine changes</li>   
 *            <li><code><big>'F'</big></code> - do not delete protected turbine changes</li>   
 *        </ul> 
 *        
 * @throws ERROR if an attempt is made to delete a protected turbine change and 
 *         <code><big>p_override_prot</big></code> is <code><big>'F'</big></code> 
 * @throws ERROR if <code><big>p_start_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_start_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 * @throws ERROR if <code><big>p_end_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_end_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 */ 
procedure delete_turbine_changes(
   p_project_location     in  location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F');
/**
 * Protects or un-protects turbine changes for a specified project and time window   
 *
 * @param p_project_location the project for which to protect or un-protect the turbine changes.  
 * @param p_start_time beginning of the time window.         
 * @param p_end_time end of the time window.
 * @param p_protected specifies whether to set or clear the protected status of turbine changes
 *        </ul>
 *            <li><code><big>'T'</big></code> - set protected status</li>   
 *            <li><code><big>'F'</big></code> - clear protected status</li>   
 *        </ul> 
 * @param p_time_zone time zone in which to interpret <code><big>p_start_time</big></code>
 *        and <code><big>p_end_time</big></code>.  If not specified or specified as <code><big>NULL</big></code>
 *        then the local time zone of the project will be assumed.   
 * @param p_start_time_inclusive specifies whether the start time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_start_time</big></code> specifies the earliest time in the time window</li>   
 *            <li><code><big>'F' - p_start_time</big></code> specifies the latest time before the time window</li>   
 *        </ul> 
 * @param p_end_time_inclusive specifies whether the end time is inclusive 
 *        </ul>
 *            <li><code><big>'T' - p_end_time</big></code> specifies the latest time in the time window</li>   
 *            <li><code><big>'F' - p_end_time</big></code> specifies the earlies time after the time window</li>   
 *        </ul> 
 *        
 * @throws ERROR if <code><big>p_start_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_start_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 * @throws ERROR if <code><big>p_end_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_end_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 */ 
procedure set_turbine_change_protection(
   p_project_location     in  location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_protected            in varchar2,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T');

end cwms_turbine;
/
show errors;
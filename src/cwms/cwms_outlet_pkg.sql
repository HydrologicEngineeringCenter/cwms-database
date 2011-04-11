set define off
create or replace package cwms_outlet
/**
 * Provides facilities to manipulate outlets and their supporting types  
 * in the CWMS database.                                                            
 * <p>                                                                                        
 * An outlet will always have a parent project defined in AT_PROJECT.                      
 * There can be zero to many outlets for a given project.                                  
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
 * Retrieves information about a single specified outlet.
 * 
 * @param p_outlet the retrieved outlet information
 * @param p_outlet_location the specification of the outlet to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_outlet_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_outlet_location</big></code>
 *         exists in the database but is not identified as an outlet.                     
 */   
procedure retrieve_outlet(
   p_outlet          out project_structure_obj_t,
   p_outlet_location in  location_ref_t);
/**
 * Retrieves information about a single specified outlet.
 * 
 * @param p_outlet_location the specification of the outlet to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.
 *
 * @return the retrieved outlet information
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_outlet_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_outlet_location</big></code>
 *         exists in the database but is not identified as an outlet.                     
 */   
function retrieve_outlet_f(
   p_outlet_location in location_ref_t)
   return project_structure_obj_t;
/**
 * Retrieves information about all outlets of a specified project.
 * 
 * @param p_outlets the retrieved outlet information
 * @param p_project_location the specification of the project to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.      
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_project_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_project_location</big></code>
 *         exists in the database but is not identified as a project.                     
 */   
procedure retrieve_outlets(
   p_outlets          out project_structure_tab_t,
   p_project_location in  location_ref_t);
/**
 * Retrieves information about all outlets of a specified project.
 * 
 * @param p_project_location the specification of the project to retrieve
 *        information for. If the office_id member is <code><big>NULL</big></code> then
 *        the office of the user calling the procedure is assumed.      
 *
 * @param the retrieved outlet information
 *         
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_project_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_project_location</big></code>
 *         exists in the database but is not identified as a project.                     
 */   
function retrieve_outlets_f(
   p_project_location in location_ref_t)
   return project_structure_tab_t;
/**
 * Stores information about a single specified outlet in the database.
 * 
 * @param p_outlet the outlet information to store. The outlet will be created
 *        if it doesn't already exist in the database 
 * @param p_fail_if_exists specifies whether to fail if the specified outlet
 *        already exists in the database.
 *        </ul>
 *            <li><code><big>'T'</big></code> - the procedure will raise an exception if 
 *                the specified outlet already exists in the database</li>   
 *            <li><code><big>'F'</big></code> - the procedure will update the update the 
 *                information if the specified outlet already exists in the  database</li>   
 *        </ul> 
 * 
 * @throws ITEM_ALREADY_EXISTS if the specified outlet already exists in the 
 *         database and <code><big>p_fail_if_exists</big></code> is specified as <code><big>'T'</big></code>
 * @throws ERROR if the specified outlet already exists in the database and 
 *         <code><big>p_fail_if_exists</big></code> is specified as <code><big>'F'</big></code> and the
 *         existing location is not identified as an outlet                                
 */ 
procedure store_outlet(
    p_outlet         in project_structure_obj_t,
    p_fail_if_exists in varchar2 default 'T');
/**
 * Stores information about a multiple specified outlets in the database.
 * 
 * @param p_outlets the outlet information to store. Each outlet will be created
 *        if it doesn't already exist in the database 
 * @param p_fail_if_exists specifies whether to fail if the specifies outlet
 *        already exists in the database.
 *        </ul>
 *            <li><code><big>'T'</big></code> - the procedure will raise an exception if 
 *                the any of the specified outlets already exists in the database</li>   
 *            <li><code><big>'F'</big></code> - the procedure will update the update the 
 *                information if any of the specified outlets already exists in the  database</li>   
 *        </ul> 
 * 
 * @throws ITEM_ALREADY_EXISTS if any of the specified outlets already exists in the 
 *         database and <code><big>p_fail_if_exists</big></code> is specified as <code><big>'T'</big></code>                    
 * @throws ERROR if any of the specified outlets already exists in the database and 
 *         <code><big>p_fail_if_exists</big></code> is specified as <code><big>'F'</big></code> and the
 *         existing location is not identified as an outlet                                
 */ 
procedure store_outlets(
   p_outlets        in project_structure_tab_t,
   p_fail_if_exists in varchar2 default 'T');
/**
 * Renames an existing outlet
 * 
 * @param p_outlet_id_old the location identifier of the outlet as it currently
 *        exists in the database
 * @param p_outlet_id_new the new location identifier of the outlet
 * @param p_office_id the identifier of the office for which to rename the outlet.
 *        if <code><big>NULL</big></code> then the office of the user calling the procedure
 *        is assumed.       
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_outlet_id_old</big></code> does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_outlet_id_old</big></code> exists in the database but is not identified
 *        as an outlet.
 * @throws LOCATION_ID_ALREADY_EXISTS if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_outlet_id_new</big></code> already exists in the database.                               
 */    
procedure rename_outlet(
   p_outlet_id_old in varchar2,
   p_outlet_id_new in varchar2,
   p_office_id     in varchar2 default null);
/**
 * Deletes an outlet from the database.
 *  
 * @param p_outlet_id the location identifier of the outlet
 * @param p_delete_action the type of deletion to perform.
 *        <dl>
 *        <dt><code><big><b>cwms_util.delete_key</b></big></code></dt>
 *        <dd>only the outlet location is deleted. The presence of any dependent
 *            data will cause the procedure to fail.</dd>
 *        <dt><code><big><b>cwms_util.delete_data</b></big></code></dt>
 *        <dd>only dependent data (if any) will be deleted.  The outlet location 
 *            will not be deleted</dd>  
 *        <dt><code><big><b>cwms_util.delete_all</b></big></code></dt>
 *        <dd>the outlet location and any depedent data will be deleted</dd>
 *        </dl> 
 * @param p_office_id the identifier of the office for which to rename the outlet.
 *        if <code><big>NULL</big></code> then the office of the user calling the procedure
 *        is assumed.       
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_outlet_id_old</big></code> does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location specified by <code><big>p_office_id</big></code> 
 *        and <code><big>p_outlet_id_old</big></code> exists in the database but is not identified
 *        as an outlet.
 * @throws INVALID_DELETE_ACTION if <code><big>p_delete_action</big></code> is not one
 *         of the values identified above.          
 */    
procedure delete_outlet(
   p_outlet_id     in varchar,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Store one or more gate changes.  Any gate changes in the (implicit or explicit)
 * time window already in the database will be deleted before the specified 
 * changes are stored.  The implicit time window is defined by the <code><big>change_date</big></code>
 * members of the individual <code><big>gate_change_obj_t</big></code> items specified in the
 * <code><big>p_gate_changes</big></code> parameter.   
 * 
 * @param p_gate_changes the gate changes to store
 * @param p_start_time beginning of the explicit time window. If not specified or
 *        specified as <code><big>NULL</big></code> the time window starts at the 
 *        <code><big>change_date</big></code> member of the first <code><big>gate_change_obj_t</big></code>
 *        item in the <code><big>p_gate_changes</big></code> parameter.         
 * @param p_end_time end of the explicit time window. If not specified or
 *        specified as <code><big>NULL</big></code> the time window ends at the 
 *        <code><big>change_date</big></code> member of the last <code><big>gate_change_obj_t</big></code>
 *        item in the <code><big>p_gate_changes</big></code> parameter.
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
 *        any existing gate change in the database when attempting to delete it.
 *        </ul>
 *            <li><code><big>'T'</big></code> - delete protected gate changes</li>   
 *            <li><code><big>'F'</big></code> - do not delete protected gate changes</li>   
 *        </ul> 
 *
 * @throws ERROR if not all <code><big>gate_change_obj_t</big></code> refer to the same project
 * @throws ERROR if gate changes are not specified in ascending time order
 * @throws ERROR if an attempt is made to delete a protected gate change and 
 *         <code><big>p_override_prot</big></code> is <code><big>'F'</big></code> 
 * @throws ERROR if <code><big>p_start_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_start_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 * @throws ERROR if <code><big>p_end_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_end_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 * @throws ITEM_DOES_NOT_EXIST if a discharge computation or release reason is specified
 *         that does not exist in
 *         the database          
 * @throws ERROR if a discharge computation or release reason is specified that belongs
 *         to a different office than the gate change.                     
 */ 
procedure store_gate_changes(
   p_gate_changes         in gate_change_tab_t,
   p_start_time           in date default null,
   p_end_time             in date default null,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F');
/**
 * Retrieves gate changes from the database for a specified project and time window, 
 * optionally limited to a maximum number of changes.
 * 
 * @param p_gate_changes the gate changes retrieved from the database
 * @param p_project_location the project for which to retrieve the gate changes.
 *        If the office_id member is <code><big>NULL</big></code> then the office of the user 
 *        calling the procedure is assumed.
 * @param p_start_time the beginning of the time window
 * @param p_end time the end of the time window              
 * @param p_time_zone time zone in which to interpret <code><big>p_start_time</big></code>
 *        and <code><big>p_end_time</big></code>.  he <code><big>change_date</big></code> members of 
 *        the individual <code><big>gate_change_obj_t</big></code> items returned will also
 *        be in this time zone. If not specified or specified as <code><big>NULL</big></code>
 *        then the local time zone of the project will be assumed.
 * @param p_unit_system the unit system (<code><big>'EN'</big></code> or <code><big>'SI'</big></code>)
 *        in which to return the gate change information. If not specified or 
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
 * @param p_max_item_count the maximum number of gate changes to retrieve, regardless of 
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
procedure retrieve_gate_changes(
   p_gate_changes         out gate_change_tab_t,
   p_project_location     in  location_ref_t,
   p_start_time           in  date,
   p_end_time             in  date,
   p_time_zone            in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_start_time_inclusive in  varchar2 default 'T',
   p_end_time_inclusive   in  varchar2 default 'T',
   p_max_item_count       in  integer default null);
/**
 * Retrieves gate changes from the database for a specified project and time window, 
 * optionally limited to a maximum number of changes.
 * 
 * @param p_project_location the project for which to retrieve the gate changes.
 *        If the office_id member is <code><big>NULL</big></code> then the office of the user 
 *        calling the procedure is assumed.
 * @param p_start_time the beginning of the time window
 * @param p_end time the end of the time window              
 * @param p_time_zone time zone in which to interpret <code><big>p_start_time</big></code>
 *        and <code><big>p_end_time</big></code>.  he <code><big>change_date</big></code> members of 
 *        the individual <code><big>gate_change_obj_t</big></code> items returned will also
 *        be in this time zone. If not specified or specified as <code><big>NULL</big></code>
 *        then the local time zone of the project will be assumed.
 * @param p_unit_system the unit system (<code><big>'EN'</big></code> or <code><big>'SI'</big></code>)
 *        in which to return the gate change information. If not specified or 
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
 * @param p_max_item_count the maximum number of gate changes to retrieve, regardless of 
 *        time window.  A positive integer is interpreted as the maximum number of 
 *        changes from the beginning of the time window. A negative integer is 
 *        interpreted as the maximum number from the end of the time window.
 *         
 * @return the gate changes retrieved from the database
 *        
 * @throws LOCATION_ID_NOT_FOUND if the location in <code><big>p_project_location</big></code>
 *         does not exist in the database.
 * @throws ITEM_DOES_NOT_EXIST if the location in <code><big>p_project_location</big></code>
 *         exists in the database but is not identified as a project.
 * @throws ERROR if <code><big>p_max_item_count</big></code> is specified as zero                               
 * @throws ERROR if <code><big>p_start_time</big></code> is later than <code><big>p_end_time</big></code>                               
 */ 
function retrieve_gate_changes_f(
   p_project_location      in location_ref_t,
   p_start_time            in date,
   p_end_time              in date,
   p_time_zone             in varchar2 default null,
   p_unit_system           in varchar2 default null,
   p_start_time_inclusive  in varchar2 default 'T',
   p_end_time_inclusive    in varchar2 default 'T',
   p_max_item_count        in integer default null)
   return gate_change_tab_t;
/**
 * Delete gate changes for a specified project and time window   
 *
 * @param p_project_location the project for which to delete the gate changes.  
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
 *        any existing gate change in the database when attempting to delete it. 
 *        </ul>
 *            <li><code><big>'T'</big></code> - delete protected gate changes</li>   
 *            <li><code><big>'F'</big></code> - do not delete protected gate changes</li>   
 *        </ul> 
 *        
 * @throws ERROR if an attempt is made to delete a protected gate change and 
 *         <code><big>p_override_prot</big></code> is <code><big>'F'</big></code> 
 * @throws ERROR if <code><big>p_start_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_start_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 * @throws ERROR if <code><big>p_end_time</big></code> is <code><big>NULL</big></code> and
 *         <code><big>p_end_time_inclusive</big></code> is <code><big>'F'</big></code>                                 
 */ 
procedure delete_gate_changes(
   p_project_location     in  location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F');
/**
 * Protects or un-protects gate changes for a specified project and time window   
 *
 * @param p_project_location the project for which to protect or un-protect the gate changes.  
 * @param p_start_time beginning of the time window.         
 * @param p_end_time end of the time window.
 * @param p_protected specifies whether to set or clear the protected status of gate changes
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
procedure set_gate_change_protection(
   p_project_location     in  location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_protected            in varchar2,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T');

end cwms_outlet;
/
show errors;
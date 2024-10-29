CREATE OR REPLACE PACKAGE CWMS_LOCK
/**
 * Facilities for working with locks at CWMS project
 *
 * @author Peter Morris
 *
 * @since CWMS 2.1
 */
AS
/**
 * Catalogs locks stored in the database that for a specified CWMS project.
 *
 * @param p_lock_cat A cursor containing all the locks for the specified project
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
 *     <td class="descr">project_office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the project location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">project_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The location identifier of project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">db_office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">base_location_id</td>
 *     <td class="descr">varchar2(24)</td>
 *     <td class="descr">The base location identifier of the lock</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">sub_location_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The sub-location identifier, if any, of the lock</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">time_zone_name</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The local time zone for the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">latitude</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The actual latitude of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">longitude</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The actual longitude of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">horizontal_datum</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The datum of the latitude and longitude</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">elevation</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The elevation of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">elev_unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The elvation unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">vertical_datum</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The datum of the elevation</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">public_name</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The public name of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">long_name</td>
 *     <td class="descr">varchar2(80)</td>
 *     <td class="descr">The long name of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">15</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(512)</td>
 *     <td class="descr">A description of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">16</td>
 *     <td class="descr">active_flag</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">Specifies whether the lock location is active</td>
 *   </tr>
 * </table>
 *
 * @param p_project_id  The location identifier of the CWMS project
 *
 * @param p_db_office_id  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used.
 */
PROCEDURE cat_lock (
   p_lock_cat     OUT sys_refcursor,            
   p_project_id   IN    VARCHAR2 DEFAULT NULL,  
   p_db_office_id IN    VARCHAR2 DEFAULT NULL); 
/**
 * Retrieves info for a specified lock from the database
 *
 * @param p_lock The retrieved lock info
 * @param p_lock_location_ref Identifies the lock to retrieve
 */
PROCEDURE retrieve_lock(
   p_lock OUT lock_obj_t,                   
   p_lock_location_ref IN location_ref_t);

function get_pool_level_value(
   p_lock_location_code in varchar2,
   p_specified_level_id in varchar2)
   return number;

/**
 * Retrieves info for a specified lock from the database with support for navigational data
 *
 * @param p_lock The retrieved lock info
 * @param p_lock_location_ref Identifies the lock to retrieve
 */
PROCEDURE retrieve_lock_with_nav_data(
   p_lock OUT lock_obj_t,
   p_lock_location_ref IN location_ref_t);
/**
 * Stores a lock to the database
 *
 * @param p_lock The lock to store (insert or update)
 * @param p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if the specified lock already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified lock already exists in the database
 */
procedure store_lock(
   p_lock           IN lock_obj_t,            
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T');

    /**
 * Stores a lock to the database
 *
 * @param p_lock The lock to store (insert or update)
 * @param p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if the specified lock already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified lock already exists in the database
 */
procedure store_lock_with_nav_data(
   p_lock           IN lock_obj_t,
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T');
/**
 * Renames an lock in the database
 *
 * @param p_lock_id_old The existing location identifier of the lock
 * @param p_lock_id_new The new location identifier of the lock
 * @param p_db_office_id      The office that owns the lock.  If not specified or NULL, the session user's default office will be used.
 */
procedure rename_lock(
   p_lock_id_old  IN VARCHAR2,               
   p_lock_id_new  IN VARCHAR2,               
   p_db_office_id IN VARCHAR2 DEFAULT NULL); 
/**
 * Deletes an lock from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_lock_id_ The location identifier of the lock to delete
 * @param p_delete_action  Specifies what to delete. Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the lock location, and then only if it has no data referencing it</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes data that references this lock location, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this lock location and all data referencing it</td>
 *   </tr>
 * </table>
 * @param p_db_office_id   The office that owns the lock.  If not specified or NULL, the session user's default office will be used.
 */
procedure delete_lock(
    p_lock_id       IN VARCHAR,                               
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, 
    p_db_office_id  IN VARCHAR2 DEFAULT NULL);                
/**
 * Deletes a lock from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_lock_id The location identifier of the lock
 *
 * @param p_delete_action Specifies what lock elements to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only this lock, and then only if it has no dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only dependent data of this lock, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this lock and dependent data, if any</td>
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
 * @param p_office_id The office that owns the lock location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such lock location exists
 */
procedure delete_lock2(
   p_lock_id                in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null);

procedure get_lock_gate_types(
   p_lookup_type_tab out lookup_type_tab_t,
   p_db_office_id    in  varchar2 default null);

procedure set_lock_gate_type(
   p_lookup_type    in lookup_type_obj_t,
   p_fail_if_exists in varchar2 default 'T');

procedure set_lock_gate_types(
   p_lookup_type_tab in lookup_type_tab_t,
   p_fail_if_exists in varchar2 default 'T');

procedure remove_lock_gate_type(
   p_lookup_type in lookup_type_obj_t);

END CWMS_LOCK;
/
show errors;

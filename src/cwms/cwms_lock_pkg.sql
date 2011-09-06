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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">project_office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the project location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">project_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of project</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">db_office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">base_location_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The base location identifier of the lock</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">sub_location_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sub-location identifier, if any, of the lock</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">time_zone_name</td>
 *     <td style="border:1px solid black;">varchar2(28)</td>
 *     <td style="border:1px solid black;">The local time zone for the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">latitude</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The actual latitude of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">longitude</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The actual longitude of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">horizontal_datum</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The datum of the latitude and longitude</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">elevation</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The elevation of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">elev_unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The elvation unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">vertical_datum</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The datum of the elevation</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">public_name</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The public name of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">14</td>
 *     <td style="border:1px solid black;">long_name</td>
 *     <td style="border:1px solid black;">varchar2(80)</td>
 *     <td style="border:1px solid black;">The long name of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">15</td>
 *     <td style="border:1px solid black;">description</td>
 *     <td style="border:1px solid black;">varchar2(512)</td>
 *     <td style="border:1px solid black;">A description of the lock location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">16</td>
 *     <td style="border:1px solid black;">active_flag</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Specifies whether the lock location is active</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">p_delete_action</th>
 *     <th style="border:1px solid black;">Action</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_key</td>
 *     <td style="border:1px solid black;">deletes only the lock location, and then only if it has no data referencing it</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_data</td>
 *     <td style="border:1px solid black;">deletes data that references this lock location, if any</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_all</td>
 *     <td style="border:1px solid black;">deletes this lock location and all data referencing it</td>
 *   </tr>
 * </table>
 * @param p_db_office_id   The office that owns the lock.  If not specified or NULL, the session user's default office will be used.
 */
procedure delete_lock(
    p_lock_id       IN VARCHAR,                               
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, 
    p_db_office_id  IN VARCHAR2 DEFAULT NULL);                

END CWMS_LOCK;
/
show errors;

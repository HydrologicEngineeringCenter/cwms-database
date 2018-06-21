WHENEVER sqlerror EXIT sql.sqlcode
CREATE OR REPLACE
PACKAGE CWMS_EMBANK
/**
 * Routines for working with CWMS embankments
 *
 * @author Peter Morris
 *
 * @since CWMS 2.1
 */
AS
-- not documented
function get_embankment_code(
   p_office_id in varchar2,
   p_embankment_id  in varchar2)
   return number;
/**
 * Catalogs embankments stored in the database that for a specified CWMS project.
 *
 * @param p_embankment_cat A cursor containing all the embankments for the specified project
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
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">db_office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">base_location_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The base location identifier of the embankment</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">sub_location_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The sub-location identifier, if any, of the embankment</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">time_zone_name</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The local time zone for the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">latitude</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The actual latitude of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">longitude</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The actual longitude of the embankment location</td>
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
 *     <td class="descr">The elevation of the embankment location</td>
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
 *     <td class="descr">The public name of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">long_name</td>
 *     <td class="descr">varchar2(80)</td>
 *     <td class="descr">The long name of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">15</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(512)</td>
 *     <td class="descr">A description of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">16</td>
 *     <td class="descr">active_flag</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">Specifies whether the embankment location is active</td>
 *   </tr>
 * </table>
 *
 * @param p_project_id  The location identifier of the CWMS project
 *
 * @param p_db_office_id  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used.
 */
PROCEDURE cat_embankment(
    --described above.
    p_embankment_cat OUT sys_refcursor,
    -- the project id. if null, return all embankments for the office.
    p_project_id IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    -- the office id can use sql masks for retrieval of additional offices.
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
/**
 * Retrieves info for a specified embankment from the database
 *
 * @param p_embankment The retrieved embankment info
 * @param p_embankment_location_ref Identifies the embankment to retrieve
 */
PROCEDURE retrieve_embankment(
    --returns a filled in object including location data
    p_embankment OUT embankment_obj_t,
    -- a location ref that identifies the object we want to retrieve.
    -- includes the lock's location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_embankment_location_ref IN location_ref_t );
/**
 * Retrieves info for a all embankments for specified CWMS project
 *
 * @param p_embankments The retrieved embankment info
 * @param p_project_location_ref Identifies the project to retrieve embankments for
 */
PROCEDURE retrieve_embankments(
    --returns a filled set of objects including location data
    p_embankments OUT embankment_tab_t,
    -- a project location refs that identify the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t );
/**
 * Stores a single embankment to the database
 *
 * @param p_embankment The embankment to store (insert or update)
 * @param p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if the specified embankment already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified embankment already exists in the database
 */
PROCEDURE store_embankment(
    -- a populated embankment object type.
    p_embankment IN embankment_obj_t,
    -- a flag that will cause the procedure to fail if the lock already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Stores one or more embankments to the database
 *
 * @param p_embankments The embankments to store (insert or update)
 * @param p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if one of the specified embankments already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the specified embankments already exists in the database
 */
PROCEDURE store_embankments(
    -- a populated embankment object type.
    p_embankments IN embankment_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Renames an embankment in the database
 *
 * @param p_embankment_id_old The existing location identifier of the embankment
 * @param p_embankment_id_new The new location identifier of the embankment
 * @param p_db_office_id      The office that owns the embankment.  If not specified or NULL, the session user's default office will be used.
 */
PROCEDURE rename_embankment(
    p_embankment_id_old IN VARCHAR2,
    p_embankment_id_new IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
/**
 * Deletes an embankment from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_embankment_id_ The location identifier of the embankment to delete
 * @param p_delete_action  Specifies what to delete. Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the embankment location, and then only if it has no data referencing it</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes data that references this embankment location, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this embankment location and all data referencing it</td>
 *   </tr>
 * </table>
 * @param p_db_office_id   The office that owns the embankment.  If not specified or NULL, the session user's default office will be used.
 */
PROCEDURE delete_embankment(
    p_embankment_id IN VARCHAR, -- base location id + "-" + sub-loc id (if it exists)
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    p_db_office_id  IN VARCHAR2 DEFAULT NULL -- defaults to the connected user's office if null
  );
/**
 * Deletes an embankment from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_embankment_id The location identifier of the embankment
 *
 * @param p_delete_action Specifies what embankment elements to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only this embankment, and then only if it has no dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only dependent data of this embankment, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this embankment and dependent data, if any</td>
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
 * @param p_office_id The office that owns the embankment location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such embankment location exists
 */
procedure delete_embankment2(
   p_embankment_id          in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null);
/**
 * Retrieves the set of available structure types for an office
 *
 * @param p_lookup_type_tab The available lookup types for the specified (or default) office
 * @param p_db_office_id   The office to retrieve the structure types for. If not specified or NULL, the session user's default office is used.
 */
PROCEDURE get_structure_types(
    p_lookup_type_tab OUT lookup_type_tab_t,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
/**
 * Stores (inserts or updates) a collection of structure types
 *
 * @param p_lookup_type_tab The collection of structure types to store
 * @param p_fail_if_exists  A flag ('T' or 'F') specifying whether the routine should fail if one of the structure types already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the structure types already exists in the database
 */
PROCEDURE set_structure_types(
    p_lookup_type_tab IN lookup_type_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Stores (inserts or updates) a single structure type
 *
 * @param p_lookup_type     The structure type to store
 * @param p_fail_if_exists  A flag ('T' or 'F') specifying whether the routine should fail if the structure type already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the structure type already exists in the database
 */
PROCEDURE set_structure_type(
    p_lookup_type IN lookup_type_obj_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Deletes a single structure type
 *
 * @param p_lookup_type  The structure type to delete
 */
PROCEDURE remove_structure_type(
    p_lookup_type IN lookup_type_obj_t );
/**
 * Retrieves the set of available protection types for an office
 *
 * @param p_lookup_type_tab The available lookup types for the specified (or default) office
 * @param p_db_office_id   The office to retrieve the protection types for. If not specified or NULL, the session user's default office is used.
 */
PROCEDURE get_protection_types(
    p_lookup_type_tab OUT lookup_type_tab_t,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
/**
 * Stores (inserts or updates) a collection of protection types
 *
 * @param p_lookup_type_tab The collection of protection types to store
 * @param p_fail_if_exists  A flag ('T' or 'F') specifying whether the routine should fail if one of the protection types already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the protection types already exists in the database
 */
PROCEDURE set_protection_types(
    p_lookup_type_tab IN lookup_type_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Stores (inserts or updates) a single protection type
 *
 * @param p_lookup_type     The protection type to store
 * @param p_fail_if_exists  A flag ('T' or 'F') specifying whether the routine should fail if the protection type already exists in the database
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the protection type already exists in the database
 */
PROCEDURE set_protection_type(
    p_lookup_type IN lookup_type_obj_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Deletes a single protection type
 *
 * @param p_lookup_type  The protection type to delete
 */
PROCEDURE remove_protection_type(
    p_lookup_type IN lookup_type_obj_t );
END CWMS_EMBANK;
/
show errors;
GRANT EXECUTE ON CWMS_EMBANK TO CWMS_USER;
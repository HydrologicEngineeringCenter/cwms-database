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
/**
 * Catalogs embankments stored in the database that for a specified CWMS project.
 *
 * @param p_embankment_cat A cursor containing all the embankments for the specified project
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
 *     <td style="border:1px solid black;">The office that owns the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">base_location_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The base location identifier of the embankment</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">sub_location_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sub-location identifier, if any, of the embankment</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">time_zone_name</td>
 *     <td style="border:1px solid black;">varchar2(28)</td>
 *     <td style="border:1px solid black;">The local time zone for the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">latitude</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The actual latitude of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">longitude</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The actual longitude of the embankment location</td>
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
 *     <td style="border:1px solid black;">The elevation of the embankment location</td>
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
 *     <td style="border:1px solid black;">The public name of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">14</td>
 *     <td style="border:1px solid black;">long_name</td>
 *     <td style="border:1px solid black;">varchar2(80)</td>
 *     <td style="border:1px solid black;">The long name of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">15</td>
 *     <td style="border:1px solid black;">description</td>
 *     <td style="border:1px solid black;">varchar2(512)</td>
 *     <td style="border:1px solid black;">A description of the embankment location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">16</td>
 *     <td style="border:1px solid black;">active_flag</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Specifies whether the embankment location is active</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">p_delete_action</th>
 *     <th style="border:1px solid black;">Action</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_key</td>
 *     <td style="border:1px solid black;">deletes only the embankment location, and then only if it has no data referencing it</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_data</td>
 *     <td style="border:1px solid black;">deletes data that references this embankment location, if any</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_all</td>
 *     <td style="border:1px solid black;">deletes this embankment location and all data referencing it</td>
 *   </tr>
 * </table>
 * @param p_db_office_id   The office that owns the embankment.  If not specified or NULL, the session user's default office will be used.
 */
PROCEDURE delete_embankment(
    p_embankment_id IN VARCHAR, -- base location id + "-" + sub-loc id (if it exists)
    -- delete key will fail if there are references to the embankment.
    -- delete all will delete the referring children then the embankment.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    p_db_office_id  IN VARCHAR2 DEFAULT NULL -- defaults to the connected user's office if null
  );
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
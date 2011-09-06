create or replace PACKAGE CWMS_PROJECT
/**
 * Facilities for working with CWMS projects
 *
 * @author Peter Morris
 *
 * @since CWMS 2.1
 */
IS
/**
 * Retrieve information on all project locations owned by an office
 *
 * @param p_project_cat A cursor containing the project locations, ordered by
 * project location identifier.  The columns are:
--    db_office_id             varchar2(16)   owning office of location
--    base_location_id         varchar2(16)   base location id
--    sub_location_id          varchar2(32)   sub-location id, if any
--    time_zone_name           varchar2(28)   local time zone name for location
--    latitude                 number         location latitude
--    longitude                number         location longitude
--    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
--    elevation                number         location elevation
--    elev_unit_id             varchar2(16)   location elevation units
--    vertical_datum           varchar2(16)   veritcal datum of elevation
--    public_name              varchar2(32)   location public name
--    long_name                varchar2(80)   location long name
--    description              varchar2(512)  location description
--    active_flag              varchar2(1)    'T' if active, else 'F'
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
 *     <td style="border:1px solid black;">db_office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the project</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">base_location_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The base location identifier of the project</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">sub_location_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sub-location identifier of the project, if any</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">time_zone_name</td>
 *     <td style="border:1px solid black;">varchar2(28)</td>
 *     <td style="border:1px solid black;">The local time zone of the office</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">latitude</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The actual latitude of the project location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">longitude</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The actual longitude of the project location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">horizontal_datum</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The datum of the actual latitude and longitude</td>
 *   </tr>
--   1 db_office_id             varchar2(16)   owning office of location
--   2 base_location_id         varchar2(16)   base location id
--   3 sub_location_id          varchar2(32)   sub-location id, if any
--   4 time_zone_name           varchar2(28)   local time zone name for location
--   5 latitude                 number         location latitude
--   6 longitude                number         location longitude
--   7 horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
--   8 elevation                number         location elevation
--   9 elev_unit_id             varchar2(16)   location elevation units
--   0 vertical_datum           varchar2(16)   veritcal datum of elevation
--   1 public_name              varchar2(32)   location public name
--   2 long_name                varchar2(80)   location long name
--   3 description              varchar2(512)  location description
--   4 active_flag              varchar2(1)    'T' if active, else 'F'
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">elevation</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The elevation of the project location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">elev_unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The unit of elevation</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">vertical_datum</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The datum for the elevation</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">public_name</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The public name of the project location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">long_name</td>
 *     <td style="border:1px solid black;">varchar2(80)</td>
 *     <td style="border:1px solid black;">The long name of the project location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">description</td>
 *     <td style="border:1px solid black;">varchar2(512)</td>
 *     <td style="border:1px solid black;">A description of the project location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">14</td>
 *     <td style="border:1px solid black;">active_flag</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">A flag ('T' or 'F') that specifies whether the project location is marked as active</td>
 *   </tr>
 * </table>
 *
 * @param p_basin_cat Reserved for future use. Currently returns NULL
 *
 * @param p_db_office_id The office that owns the project locations
 */
PROCEDURE cat_project (
	--described above.
	p_project_cat		OUT		sys_refcursor,
  
	--described above.
	p_basin_cat		  OUT		sys_refcursor,
	
  -- defaults to the connected user's office if null
  -- the office id can use sql masks for retrieval of additional offices.
  p_db_office_id IN    VARCHAR2 DEFAULT NULL
                                                
);
/**
 * Retrieve information about a specified project
 *
 * @param p_project      The retrieved project information
 * @param p_project_id   The location identifier of the project to retrieve information for
 * @param p_db_office_id The office that owns the project. If not specified or NULL, the session user's default office will be used.
 */
PROCEDURE retrieve_project(
	--returns a filled in project object including location data
	p_project					OUT		project_obj_t,
	
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id				IN 		VARCHAR2, 
	
	-- defaults to the connected user's office if null
	p_db_office_id				IN		VARCHAR2 DEFAULT NULL 
	
);
/**
 * Stores (inserts or updates) a project to the database
 *
 * @param p_project        The project to be stored
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the routine should fail if the specified project already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified project already exists
 */
procedure store_project(
	-- a populated project object type.
	p_project					IN		project_obj_t,
  -- fail the store if the project already exists.
  p_fail_if_exists      IN       VARCHAR2 DEFAULT 'T'
);
/**
 * Renames a project in the database
 *
 * @param p_project_id_old The existing location identifier of the project
 * @param p_project_id_new The new location identifier of the project
 * @param p_db_office_id   The office that owns the project.  If not specified or NULL, the session user's default office will be used.
 */
procedure rename_project(
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id_old	IN	VARCHAR2,
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id_new	IN	VARCHAR2,
	-- defaults to the connected user's office if null
	p_db_office_id		IN	VARCHAR2 DEFAULT NULL
);
/**
 * Deletes a project location from the database
  *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
*
 * @param p_project_id The location identifier of the project to delete
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">p_delete_action</th>
 *     <th style="border:1px solid black;">Action</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_key</td>
 *     <td style="border:1px solid black;">deletes only the project location, and then only if it has no associated data</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_data</td>
 *     <td style="border:1px solid black;">deletes only data associated with the project, if any</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_all</td>
 *     <td style="border:1px solid black;">deletes the project and all associated data</td>
 *   </tr>
 * </table>
 * @param p_db_office_id The office that owns the project.  If not specified or NULL, the session user's default office will be used.
 */
procedure delete_project(
	-- base location id + "-" + sub-loc id (if it exists)
  p_project_id		IN   VARCHAR2,
  -- the cwms_util delete action for this delete, options are delete_key and delete_all.
  -- delete_key will fail if there are project children referencing this project, i.e. embankments, etc.
  -- delete_all will cascade delete this project and all children. 
  p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, 
	-- defaults to the connected user's office if null
  p_db_office_id    IN   VARCHAR2 DEFAULT NULL
);


-- procedure create_basin_group
-- creates a "Basin" category location group
-- security: can only be called by the dba group.
-- errors will be thrown as exceptions.
PROCEDURE create_basin_group (
      -- the basin name
      p_loc_group_id      IN   VARCHAR2,
      -- description of the basin
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

-- procedure rename_basin_group
-- renames an existing "Basin" category location group.
-- security: can only be called by the dba group.
-- errors will be thrown as exceptions.
PROCEDURE rename_basin_group (
      -- the old basin name
      p_loc_group_id_old   IN   VARCHAR2,
      -- the new basin name
      p_loc_group_id_new   IN   VARCHAR2,
      -- an updated description
      p_loc_group_desc     IN   VARCHAR2 DEFAULT NULL,
      -- if true, null args should not be processed.
      p_ignore_null        IN   VARCHAR2 DEFAULT 'T',
      -- defaults to the connected user's office if null
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   --delete_basin_group
   -- deletes a "Basin" category location group.
   -- 
  PROCEDURE delete_basin_group (
    -- the location group to delete.
		p_loc_group_id		IN VARCHAR2,
    -- delete_key will fail if there are assigned locations.
    -- delete_all will delete all location assignments, then delete the group.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, 
    -- defaults to the connected user's office if null
		p_db_office_id		IN VARCHAR2 DEFAULT NULL
  );
   
   -- Assign a location to a "Basin" category location group. The location id
   -- that is being assigned to the basin needs to be constrained to location_codes
   -- in the AT_PROJECT table.
   PROCEDURE assign_basin_group2 (
      -- the location group id.
      p_loc_group_id      IN   VARCHAR2,
      -- the project location id
      p_location_id       IN   VARCHAR2,
      -- the attribute for the project location.
      p_loc_attribute     IN   NUMBER   DEFAULT NULL,
      -- the alias for this project, this will most likely always be null.
      p_loc_alias_id      IN   VARCHAR2 DEFAULT NULL,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

  -- Assign a set of locations to the "Basin" category location group. The location id
   -- that is being assigned to the basin needs to be constrained to location_codes
   -- in the AT_PROJECT table.
   PROCEDURE assign_basin_groups2 (
     -- the basin location group id
      p_loc_group_id      IN   VARCHAR2,
      -- an array of the location ids and extra data to assign to the specified group.
      p_loc_alias_array   IN   loc_alias_array2,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );
   
   -- Removes a location from a "Basin" category location group.
   PROCEDURE unassign_basin_group (
      -- the basin location group id
      p_loc_group_id      IN   VARCHAR2,
      -- the location id to remove. 
      p_location_id       IN   VARCHAR2,
      -- if unassign is T then all assigned locs are removed from group. 
      -- p_location_id needs to be set to null when the arg is T.
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );
   
   -- Removes a set of location ids from a "Basin" category location group.
   PROCEDURE unassign_basin_groups (
      -- the basin location group id.
      p_loc_group_id      IN   VARCHAR2,
      -- the array of location ids to remove.
      p_location_array    IN   char_49_array_type,
      -- if T, then all assigned locs are removed from the group.
      -- p_location_array needs to be null when the arg is T.
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );   
   
END CWMS_PROJECT;

/
show errors;

GRANT EXECUTE ON CWMS_PROJECT to CWMS_USER;
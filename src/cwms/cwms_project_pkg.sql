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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">db_office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">base_location_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The base location identifier of the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">sub_location_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The sub-location identifier of the project, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">time_zone_name</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The local time zone of the office</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">latitude</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The actual latitude of the project location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">longitude</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The actual longitude of the project location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">horizontal_datum</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The datum of the actual latitude and longitude</td>
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
 *     <td class="descr-center">8</td>
 *     <td class="descr">elevation</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The elevation of the project location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">elev_unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of elevation</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">vertical_datum</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The datum for the elevation</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">public_name</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The public name of the project location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">long_name</td>
 *     <td class="descr">varchar2(80)</td>
 *     <td class="descr">The long name of the project location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(512)</td>
 *     <td class="descr">A description of the project location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">active_flag</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">A flag ('T' or 'F') that specifies whether the project location is marked as active</td>
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
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the project location, and then only if it has no associated data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only data associated with the project, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes the project and all associated data</td>
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
                                           
                                        
/**       
 * Generates and publishes a message on the office's STATUS queue that a project has been updated for a specified application.
 *
 * @param p_project_id      The location identifier of the project that has been updated.
 * @param p_application_id  A text string identifying the application for which the update applies.
 * @param p_source_id       An application-defined string of the instance and/or component that generated the message. If NULL or not specified, the generated message will not include this item.
 * @param p_time_series_id  A time series identifier of the time series associated with the update. If NULL or not specified, the generated message will not include this item.
 * @param p_start_time      The UTC start time of the updates to the time series, in Java milliseconds. If NULL or not specified, the generated message will not include this item.
 * @param p_end_time        The UTC end time of the updates to the time series, in Java milliseconds. If NULL or not specified, the generated message will not include this item.
 * @param p_office_id       The text identifier of the office generating the message (and owning the project). If NULL or not specified, the session user's default office is used.
 *
 * @return The UTC timestamp of the generated message, in Java milliseconds.
 */
function publish_status_update(
   p_project_id     in varchar2,
   p_application_id in varchar2,
   p_source_id      in varchar2 default null,
   p_time_series_id in varchar2 default null,
   p_start_time     in integer  default null,
   p_end_time       in integer  default null,     
   p_office_id      in varchar2 default null)
   return integer;

/**       
 * Requests a lock for a specified project and application. Lock revocation can be denied by the owner of the current lock. Lock revocation can only be performed by authorized users.
 *
 * @param p_project_id      The location identifier of the project to be locked.
 * @param p_application_id  A text string identifying the application for which the project is to be locked.
 * @param p_revoke_existing A flag ('T'/'F') specifying whether to revoke any existing lock on the project/application combination.
 * @param p_revoke_timeout  The number of seconds to wait for any revocation to be denied by the owner of the current lock on the project before revoking.
 * @param p_office_id       The text identifier of the office requesting the lock (and owning the project). If NULL or not specified, the session user's default office is used.
 *
 * @return A text identifier of the lock placed on the project for the application, or NULL if the project could not be locked.
 */
function request_lock(
   p_project_id      in varchar2,
   p_application_id  in varchar2,
   p_revoke_existing in varchar2 default 'F',
   p_revoke_timeout  in integer  default 30,
   p_office_id       in varchar2 default null)
   return varchar2;

/**       
 * Releases a project lock.
 *
 * @param p_lock_id The text identifier of the lock returned by request_lock.
 */
procedure release_lock(
   p_lock_id in varchar2);
   
/*
 * Not documented
 */   
function has_revoker_rights (
   p_project_id     in varchar2,
   p_application_id in varchar2,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null,
   p_office_code    in number   default null)
   return varchar2;

/**       
 * Revokes a lock on a specified project and application. Lock revocation can be denied by the owner of the current lock. Lock revocation can only be performed by authorized users.
 *
 * @param p_project_id      The location identifier of the project to be have its lock revoked.
 * @param p_application_id  A text string identifying the application for which the lock is to be revoked.
 * @param p_revoke_timeout  The number of seconds to wait for any revocation to be denied by the owner of the current lock on the project before revoking.
 * @param p_office_id       The text identifier of the office requesting the lock (and owning the project). If NULL or not specified, the session user's default office is used.
 */
procedure revoke_lock(
   p_project_id      in varchar2,
   p_application_id  in varchar2,
   p_revoke_timeout  in integer  default 30,
   p_office_id       in varchar2 default null);

/**       
 * Denies revocation of a project lock 
 *
 * @param p_lock_id The text identifier of the lock returned by request_lock
 */
procedure deny_lock_revocation(
   p_lock_id in varchar2);
         
/**       
 * Returns whether a project is currently locked for a specified application
 *
 * @param p_project_id      The location identifier of the project to be checked.
 * @param p_application_id  A text string identifying the application to be checked.
 * @param p_office_id       The text identifier of the office owning the project. If NULL or not specified, the session user's default office is used.
 *
 * @return A flag ('T'/'F') specifying whether the project is currently locked for the specified application
 */
function is_locked(
   p_project_id      in varchar2,
   p_application_id  in varchar2,
   p_office_id       in varchar2 default null)
   return varchar2; 
      
/**       
 * Returns catalog of current locks. Matching is
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
 *
 * @param p_project_id_mask      The location identifier mask for the project(s) to be cataloged. If not specified, locks for all projects will be cataloged.
 * @param p_application_id_mask  A text string identifying the application(s) to be cataloged. If not specified, locks for all applications will be cataloged.     
 * @param p_time_zone            The time zone in which to display the time the locks were acquired. If not specified, UTC will be used.
 * @param p_office_id_mask       The text identifier mask of the office(s) to be cataloged.  If NULL or not specified, the session user's default office is used.
 *
 * @return A cursor containing all matching locks.  The cursor contains
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
 *     <td class="descr">The office that owns the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">project_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the locked projects</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">application_id</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The application for which the project is locked</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">acquire_time</td>
 *     <td class="descr">varchar2(19)</td>
 *     <td class="descr">The time in the specified time zone that the lock was acquired</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">session_user</td>
 *     <td class="descr">varchar2(30)</td>
 *     <td class="descr">The database user name of the user that acquired the lock</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">os_user</td>
 *     <td class="descr">varchar2(30)</td>
 *     <td class="descr">The operating system user name of the user that acquired the lock</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">session_program</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The name of the program that acquired the lock</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">session_machine</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The name of the computer that acquired the lock</td>
 *   </tr>
 * </table>
 */
function cat_locks(
   p_project_id_mask     in varchar2 default '*',
   p_application_id_mask in varchar2 default '*',
   p_time_zone           in varchar2 default 'UTC',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor;

/**
 * Updates (creates, changes, or removes) lock revoker rights for a specified user and application. A user has revoker rights for a project if the project is matched in the user's ALLOWED project ids for
 * the application (if any) and is not in the users DISALLOWED project ids for the application (if any). The DISALLOWED project ids is evaluated after (has a higher priority than) the ALLOWED project ids.
 * Removing all of a user's lock revoker rights can be accomplished by specifying p_project_ids = '*' and specifying p_allow = 'F'.
 *
 * @param p_user_id        The user id to update the lock revoker rights for.
 * @param p_project_ids    A comma-separated list of project identifiers. The identifiers can include wildcards; '*' specifies all projects.
 * @param p_allow          A flag ('T'/'F') specifying whether the project ids are to be interpreted as the ALLOWED list ('T') or the DISALLOWED list ('F')
 * @param p_application_id The application to update the user's lock revoker rights for.
 * @param p_office_id       The text identifier of the office and owning the projects. If NULL or not specified, the session user's default office is used.
 */      
procedure update_lock_revoker_rights(
   p_user_id        in varchar2,
   p_project_ids    in varchar2,
   p_allow          in varchar2,
   p_application_id in varchar2,
   p_office_id      in varchar2 default null);
      
/**       
 * Returns catalog of current lock revoker rights. Matching is
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
 * @param p_project_id_mask      The location identifier mask for the project(s) to be cataloged. If not specified, locks for all projects will be cataloged.
 * @param p_application_id_mask  A text string identifying the application(s) to be cataloged. If not specified, locks for all applications will be cataloged.     
 * @param p_time_zone            The time zone in which to display the time the locks were acquired. If not specified, UTC will be used.
 * @param p_office_id_mask       The text identifier mask of the office(s) to be cataloged.  If NULL or not specified, the session user's default office is used.
 *
 * @return A cursor containing all matching locks.  The cursor contains
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
 *     <td class="descr">The office that owns the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">project_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the locked projects</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">application_id</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The application for which the project is locked</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">user_id</td>
 *     <td class="descr">varchar2(30)</td>
 *     <td class="descr">The user who owns the lock revoker rights for the project and application</td>
 *   </tr>
 * </table>
 */
function cat_lock_revoker_rights(      
   p_project_id_mask     in varchar2 default '*',
   p_application_id_mask in varchar2 default '*',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor;
                  
      
END CWMS_PROJECT;

/
show errors;

GRANT EXECUTE ON CWMS_PROJECT to CWMS_USER;
WHENEVER sqlerror EXIT sql.sqlcode
SET serveroutput ON
CREATE OR REPLACE
PACKAGE BODY CWMS_TURBINE
AS
  -------------------------------------------------------------------------------
  -- CWMS_TURBINE
  --
  -- These procedures and functions query and manipulate turbines and their supporting types
  -- in the CWMS/ROWCPS database.
  --
  -- An turbine will always have a parent project defined in AT_PROJECT.
  -- There can be zero to many turbines for a given project.
  --
  -- Outlets have an associative relationship with "Outlet" Category Location Groups.
  -- An turbine is not required to be in an "Outlet" Location Group.
  --
  -- Outlets are associated a row defined in the AT_TURBINE_CHARACTERISTICS table.
  -- There can be many turbines associated with one characteristic.
  --
  -- Note on DB_OFFICE_ID. DB_OFFICEID in addtion to location id is required to
  -- uniquely identify a location code, so it will be included in all of these calls.
  --
  -- The DB_OFFICE_ID defaults to the connected user's office if null.
  -- p_db_office_id  IN  VARCHAR2 DEFAULT NULL
  -- CWMS has a package proceudure that can be used to determine the office id for
  -- a given user.
  --
  --type definitions:
  -- from cwms_types.sql, location_obj_t and location_ref_t.
  -- from rowcps_types.sql, XXX.
  -- security:
  --
  -------------------------------------------------------------------------------
  --
  --
  
  -- Returns turbine data for a given turbine location id. Returned data is encapsulated
  -- in an turbine oracle type.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_turbine(
    --returns a filled in object including location data
    p_turbine OUT project_structure_obj_t,
    -- a location ref that identifies the object we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_turbine_location_ref IN location_ref_t )
AS
  l_proj_loc_code NUMBER;
  l_child_loc_code NUMBER;
  l_proj_loc_ref location_ref_t;
  l_child_location location_obj_t;
BEGIN
  IF p_turbine_location_ref IS NULL THEN
    --error, the contract is null.
    cwms_err.raise(
          'NULL_ARGUMENT',
          'Turbine Location Reference');
  END IF;   
  
  l_child_loc_code := p_turbine_location_ref.get_location_code;
  IF l_child_loc_code IS NULL THEN
    --error, the contract is null.
    cwms_err.raise(
          'NULL_ARGUMENT',
          'Turbine Location Code');
  END IF;   

  SELECT project_location_code      
  into l_proj_loc_code
  FROM at_turbine
  WHERE turbine_location_code = l_child_loc_code;

  l_child_location := cwms_loc.retrieve_location(l_child_loc_code);
  l_proj_loc_ref := new location_ref_t(l_proj_loc_code);
  p_turbine := project_structure_obj_t(
      l_proj_loc_ref,
      l_child_location,
      NULL);
END retrieve_turbine;
--
--
  
--
-- Returns a set of turbines for a given project. Returned data is encapsulated
-- in a table of turbine oracle types.
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued as a thrown exception
--
PROCEDURE retrieve_turbines(
    --returns a filled set of objects including location data
    p_turbines OUT project_structure_tab_t,
    -- a project location ref that identifies the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t )
AS
  l_child_location location_obj_t;
BEGIN
  IF p_project_location_ref IS NULL THEN
    --error, the contract is null.
    cwms_err.raise(
          'NULL_ARGUMENT',
          'Turbine Project Location Reference');
  END IF;    
  p_turbines := project_structure_tab_t();
  FOR rec IN (
    SELECT turbine_location_code      
    FROM at_turbine
    WHERE project_location_code = p_project_location_ref.get_location_code)
  loop
    p_turbines.EXTEND;
    l_child_location := cwms_loc.retrieve_location(rec.turbine_location_code);
    p_turbines(p_turbines.count) := project_structure_obj_t(
      p_project_location_ref,
      l_child_location,
      null);
  END loop;
END retrieve_turbines;
--
--
--
--
-- Stores the data contained within the set of turbine objects into the database schema.
--
-- security: can only be called by dba group.
--
-- This procedure performs both insert and update functionality.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE store_turbines(
    -- a table of populated turbine object types.
    p_turbines IN project_structure_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
AS
BEGIN
    --check inputs
    IF p_turbines IS NOT NULL THEN
      FOR i IN 1..p_turbines.count loop
         store_turbine(p_turbines(i), p_fail_if_exists);
      END loop;
    END IF;    
END store_turbines;

--
--
PROCEDURE store_turbine(
    -- a populated turbine object type.
    p_turbine IN project_structure_obj_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
AS
  l_proj_loc_code NUMBER;
  l_child_loc_code NUMBER;
  --  l_characteristic_ref_code NUMBER;
  
  l_rec_count NUMBER;
  l_rec at_outlet%rowtype;

BEGIN
    cwms_util.check_input(p_fail_if_exists);
    -- null checks.
    IF p_turbine IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Turbine');
    END IF;    
--    project_location_ref location_ref_t,           --The project this structure is a child of
--    structure_location location_obj_t,                  --The location for this structure
--    characteristic_ref characteristic_ref_t   -- the characteristic for this structure.    
    IF p_turbine.project_location_ref IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Turbine Project Location Reference');
    END IF;    
    IF p_turbine.structure_location IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Turbine Location');
    END IF;    
--    IF p_turbine.characteristic_ref IS NULL THEN
--      --error, the contract is null.
--      cwms_err.raise(
--            'NULL_ARGUMENT',
--            'Turbine Characteristic');
--    END IF;    
    
    --get codes
    -- do not create the project location.
    l_proj_loc_code := p_turbine.project_location_ref.get_location_code('F');
    if l_proj_loc_code IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Turbine Project Location Code');
    end if;
    --turb loc code
    l_child_loc_code := cwms_loc.store_location_f(p_turbine.structure_location,p_fail_if_exists);
    
    --characteristic will be managed in at_properties and at_loc_group

    --see if this record already exists
    select count(*) 
    into l_rec_count 
    from at_turbine
    WHERE project_location_code = l_proj_loc_code
    and turbine_location_code = l_child_loc_code;
    
    if l_rec_count = 0 then
      -- it doesnt exist, insert new rec.
      l_rec.project_location_code := l_proj_loc_code;
      l_rec.outlet_location_code := l_child_loc_code;
      insert into at_turbine
        values l_rec;
    end if;
    
END;
--
--
--
-- Renames an turbine from one id to a new id.
--
-- security: can only be called by dba group.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE rename_turbine(
    p_turbine_id_old IN VARCHAR2,
    p_turbine_id_new IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
    cwms_loc.rename_location(p_turbine_id_old,p_turbine_id_new,p_db_office_id);
END rename_turbine;
--
--
--
-- Performs a delete on an turbine.
--
-- security: can only be called by dba group.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE delete_turbine(
    p_turbine_id IN VARCHAR, -- base location id + "-" + sub-loc id (if it exists)
    -- delete key will fail if there are references to the turbine.
    -- delete all will delete the referring children then the turbine.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    p_db_office_id  IN VARCHAR2 DEFAULT NULL -- defaults to the connected user's office if null
  )
AS
    l_child_loc_code NUMBER;
BEGIN
  cwms_util.check_inputs(str_tab_t(p_turbine_id, p_delete_action,p_db_office_id));
  IF NOT p_delete_action IN (cwms_util.delete_key, cwms_util.delete_all ) THEN
    cwms_err.raise(
       'ERROR',
       'P_DELETE_ACTION must be '''
       || cwms_util.delete_key
       || ''' or '''
       || cwms_util.delete_all
       || '');
  END IF;
   
  l_child_loc_code := cwms_loc.get_location_code(p_db_office_id,p_turbine_id);
   
  IF p_delete_action = cwms_util.delete_all THEN
      -- delete settings
      DELETE
        FROM at_turbine_setting
       WHERE turbine_location_code = l_child_loc_code;
       
   END IF; -- delete all
   
   -- delete from at_turbine
   DELETE
     FROM at_turbine
    WHERE turbine_location_code = l_child_loc_code;
    
END delete_turbine;
--
--
--
-- stores a table of turbine settings.
--
-- start and end determines time window for delete.
-- start and end has to encompass the incoming time window defined in p_turbine_settings.
-- throw an error if it isnt.
--
-- inclusive determines if records at the start and end times are included in the delete.
-- the type of inclusive is borrowed from cwms_ts, but it could be setup as a 'T' 'F' 
-- if that makes more sense.
--
-- if rule isnt delete_insert then throw an error, initially ONLY delete insert
-- will be supported.
--
-- override_protection will not be implemented at this time, but is included for
-- future use.

procedure store_turbine_changes(
    p_turbine_changes in turbine_change_tab_t,
		-- store rule, only delete insert initially supported.
    p_store_rule		in varchar2 default null,
    -- start time of data to delete.
    p_start_time	  in		date default null,
    --end time of data to delete.
    p_end_time		  in		date default null,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive in varchar2 default 'T',
    -- if protection is to be ignored, not initially supported.
		p_override_prot	in varchar2 default 'F'
)
AS
BEGIN
  null;
END store_turbine_changes;

PROCEDURE retrieve_turbine_changes(
    -- the retrieved set of water user contract accountings
    p_turbine_changes out turbine_change_tab_t,
    -- the retrieved changes should be for this project.
    p_project_location in location_ref_t,
    -- the start date time for changes
    p_start_time in date,
    -- the end date time for changes
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive in varchar2 default 'T',
    -- determines the unit system that returned data is in.
    -- opening can be a variety of units across a given project, 
    -- so the return units are not parameterized.
    p_unit_system in varchar2 default null,
    
    -- a boolean flag indicating if the returned data should be the head or tail
    -- of the set, i.e. the first n values or last n values.
    p_ascending_flag IN VARCHAR2 DEFAULT 'T',
    
    -- a limit on the number of rows returned for each individual turbine
    -- i.e. if 20, then 20 records should be returned for KEYS-Turb1, 20 for KEYS-Turb2,
    -- 20 for KEYS-Turb3, etc.
    p_row_limit IN INTEGER DEFAULT NULL    
  )
AS
BEGIN
  null;
END retrieve_turbine_changes;
--
--
--
END CWMS_TURBINE;
/
show errors;
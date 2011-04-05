WHENEVER sqlerror EXIT sql.sqlcode
SET serveroutput ON
CREATE OR REPLACE
PACKAGE BODY CWMS_OUTLET
AS
  -------------------------------------------------------------------------------
  -- CWMS_OUTLET
  --
  -- These procedures and functions query and manipulate outlets and their supporting types
  -- in the CWMS/ROWCPS database.
  --
  -- An outlet will always have a parent project defined in AT_PROJECT.
  -- There can be zero to many outlets for a given project.
  --
  -- Outlets have an associative relationship with "Outlet" Category Location Groups.
  -- An outlet is not required to be in an "Outlet" Location Group.
  --
  -- Outlets are associated a row defined in the AT_OUTLET_CHARACTERISTICS table.
  -- There can be many outlets associated with one characteristic.
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
  
  -- Returns outlet data for a given outlet location id. Returned data is encapsulated
  -- in an outlet oracle type.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_outlet(
    --returns a filled in object including location data
    p_outlet OUT project_structure_obj_t,
    -- a location ref that identifies the object we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_outlet_location_ref IN location_ref_t )
AS
  l_proj_loc_code NUMBER;
  l_child_loc_code NUMBER;
  l_proj_loc_ref location_ref_t;
  l_child_location location_obj_t;
BEGIN
  IF p_outlet_location_ref IS NULL THEN
    --error, the contract is null.
    cwms_err.raise(
          'NULL_ARGUMENT',
          'Outlet Location Reference');
  END IF;   
  
  l_child_loc_code := p_outlet_location_ref.get_location_code;
  IF l_child_loc_code IS NULL THEN
    --error, the contract is null.
    cwms_err.raise(
          'NULL_ARGUMENT',
          'Outlet Location Code');
  END IF;   

  SELECT project_location_code      
  into l_proj_loc_code
  FROM at_outlet
  WHERE outlet_location_code = l_child_loc_code;

  l_child_location := cwms_loc.retrieve_location(l_child_loc_code);
  l_proj_loc_ref := new location_ref_t(l_proj_loc_code);
  p_outlet := project_structure_obj_t(
      l_proj_loc_ref,
      l_child_location,
      NULL);

END retrieve_outlet;
--
--
  
--
-- Returns a set of outlets for a given project. Returned data is encapsulated
-- in a table of outlet oracle types.
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued as a thrown exception
--
PROCEDURE retrieve_outlets(
    --returns a filled set of objects including location data
    p_outlets OUT project_structure_tab_t,
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
          'Outlet Project Location Reference');
  END IF;    
  p_outlets := project_structure_tab_t();
  FOR rec IN (
    SELECT outlet_location_code      
    FROM at_outlet
    WHERE project_location_code = p_project_location_ref.get_location_code)
  loop
    p_outlets.EXTEND;
    l_child_location := cwms_loc.retrieve_location(rec.outlet_location_code);
    p_outlets(p_outlets.count) := project_structure_obj_t(
      p_project_location_ref,
      l_child_location,
      null);
  END loop;
END retrieve_outlets;
--
--
--
--
-- Stores the data contained within the set of outlet objects into the database schema.
--
-- security: can only be called by dba group.
--
-- This procedure performs both insert and update functionality.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE store_outlets(
    -- a table of populated outlet object types.
    p_outlets IN project_structure_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
AS
BEGIN
    --check inputs
    IF p_outlets IS NOT NULL THEN
      FOR i IN 1..p_outlets.count loop
         store_outlet(p_outlets(i), p_fail_if_exists);
      END loop;
    END IF;    
END store_outlets;


PROCEDURE store_outlet(
    -- a populated outlet object type.
    p_outlet IN project_structure_obj_t,
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
    IF p_outlet IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Outlet');
    END IF;    
--    project_location_ref location_ref_t,           --The project this structure is a child of
--    structure_location location_obj_t,                  --The location for this structure
--    characteristic_ref characteristic_ref_t   -- the characteristic for this structure.    
    IF p_outlet.project_location_ref IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Outlet Project Location Reference');
    END IF;    
    IF p_outlet.structure_location IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Outlet Location');
    END IF;    
--    IF p_outlet.characteristic_ref IS NULL THEN
--      --error, the contract is null.
--      cwms_err.raise(
--            'NULL_ARGUMENT',
--            'Outlet Characteristic');
--    END IF;    
    
    --get codes
    -- do not create the project location.
    l_proj_loc_code := p_outlet.project_location_ref.get_location_code('F');
    if l_proj_loc_code IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Outlet Project Location Code');
    end if;
    --outlet loc code
    l_child_loc_code := cwms_loc.store_location_f(p_outlet.structure_location,p_fail_if_exists);
    
    --characteristic will be managed in at_properties and at_loc_group

    --see if this record already exists
    select count(*) 
    into l_rec_count 
    from at_outlet
    WHERE project_location_code = l_proj_loc_code
    and outlet_location_code = l_child_loc_code;
    
    if l_rec_count = 0 then
      -- it doesnt exist, insert new rec.
      l_rec.project_location_code := l_proj_loc_code;
      l_rec.outlet_location_code := l_child_loc_code;
      insert into at_outlet
        values l_rec;
    end if;
    
END;
--
--
--
-- Renames an outlet from one id to a new id.
--
-- security: can only be called by dba group.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE rename_outlet(
    p_outlet_id_old IN VARCHAR2,
    p_outlet_id_new IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  cwms_loc.rename_location(p_outlet_id_old,p_outlet_id_new,p_db_office_id);
END rename_outlet;
--
--
--
-- Performs a delete on an outlet.
--
-- security: can only be called by dba group.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE delete_outlet(
    p_outlet_id IN VARCHAR, -- base location id + "-" + sub-loc id (if it exists)
    -- delete key will fail if there are references to the outlet.
    -- delete all will delete the referring children then the outlet.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    p_db_office_id  IN VARCHAR2 DEFAULT NULL -- defaults to the connected user's office if null
  )
IS
  l_child_loc_code NUMBER;
BEGIN
  cwms_util.check_inputs(str_tab_t(p_outlet_id, p_delete_action,p_db_office_id));
  IF NOT p_delete_action IN (cwms_util.delete_key, cwms_util.delete_all ) THEN
    cwms_err.raise(
       'ERROR',
       'P_DELETE_ACTION must be '''
       || cwms_util.delete_key
       || ''' or '''
       || cwms_util.delete_all
       || '');
  END IF;
   
  l_child_loc_code := cwms_loc.get_location_code(p_db_office_id,p_outlet_id);
   
  IF p_delete_action = cwms_util.delete_all THEN
      -- delete settings
      DELETE
        FROM at_gate_setting
       WHERE outlet_location_code = l_child_loc_code;
       
   END IF; -- delete all
   
   -- delete from at_outlet
   DELETE
     FROM at_outlet
    WHERE outlet_location_code = l_child_loc_code;
    
END delete_outlet;
--
--
--
-- stores a table of gate settings.
--
-- start and end determines time window for delete.
-- start and end has to encompass the incoming time window defined in p_gate_settings.
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

procedure store_gate_changes(
    p_gate_changes in gate_change_tab_t,
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
END store_gate_changes;

PROCEDURE retrieve_gate_changes(
    -- the retrieved set of water user contract accountings
    p_gate_changes out gate_change_tab_t,
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
    p_end_inclusive IN VARCHAR2 DEFAULT 'T',
    
    -- determines the unit system that returned data is in.
    -- opening can be a variety of units across a given project, 
    -- so the return units are not parameterized.
    p_unit_system IN VARCHAR2 DEFAULT NULL,
    
    -- a boolean flag indicating if the returned data should be the head or tail
    -- of the set, i.e. the first n values or last n values.
    p_ascending_flag IN VARCHAR2 DEFAULT 'T',
    
    -- a limit on the number of rows returned for each individual outlet
    -- i.e. if 20, then 20 records should be returned for KEYS-TG1, 20 for KEYS-TG2,
    -- 20 for KEYS-SG1, etc.
    p_row_limit IN INTEGER DEFAULT NULL
  )
AS
BEGIN
  null;
END retrieve_gate_changes;
--
--
--
END CWMS_OUTLET;
/
show errors;
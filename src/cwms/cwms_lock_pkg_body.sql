CREATE OR REPLACE PACKAGE BODY CWMS_LOCK AS

-------------------------------------------------------------------------------
-- CWMS_LOCK
--
-- These procedures and functions query and manipulate locks in the CWMS/ROWCPS
-- database.


--
-- cat_project
--
-- security: can be called by user and dba group.
--
-- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
-- Changing them will end up breaking external code (so make any changes prior
-- to development).
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    db_office_id             varchar2(16)   owning office of location
--    project_location_id      varchar2(49)   the parent project's location id
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
--
-------------------------------------------------------------------------------
--type definitions:
--
-- 
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
-- errors will be issued as thrown exceptions.
--
PROCEDURE cat_lock (
   p_lock_cat     OUT sys_refcursor,         --described above.
   p_project_id   IN	 VARCHAR2 DEFAULT NULL, -- the project id. if null, return all locks for the office.
   p_db_office_id	IN	 VARCHAR2 DEFAULT NULL) -- defaults to the connected user's office if null
                                             -- the office id can use sql masks for retrieval of additional offices.
is
   l_office_id_mask varchar2(16) := cwms_util.normalize_wildcards(nvl(upper(p_db_office_id), cwms_util.user_office_id), true);
begin
   open p_lock_cat for
      select o.office_id as db_office_id,                    --    db_office_id             varchar2(16)   owning office of location         
             cwms_util.concat_base_sub_id(
               bl1.base_location_id, 
               pl1.sub_location_id) as project_location_id,  --    project_location_id      varchar2(49)   the parent project's location id  
             bl2.base_location_id,                           --    base_location_id         varchar2(16)   base location id                  
             pl2.sub_location_id,                            --    sub_location_id          varchar2(32)   sub-location id, if any           
             tz.time_zone_name,                              --    time_zone_name           varchar2(28)   local time zone name for location 
             pl2.latitude,                                   --    latitude                 number         location latitude                 
             pl2.longitude,                                  --    longitude                number         location longitude                
             pl2.horizontal_datum,                           --    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon      
             pl2.elevation,                                  --    elevation                number         location elevation                
             u.unit_id as elevation_unit_id,                 --    elev_unit_id             varchar2(16)   location elevation units          
             pl2.vertical_datum,                             --    vertical_datum           varchar2(16)   veritcal datum of elevation       
             pl2.public_name,                                --    public_name              varchar2(32)   location public name              
             pl2.long_name,                                  --    long_name                varchar2(80)   location long name                
             pl2.description,                                --    description              varchar2(512)  location description              
             pl2.active_flag                                 --    active_flag              varchar2(1)    'T' if active, else 'F'           
        from cwms_office o,
             at_project p,
             at_lock l,
             at_physical_location pl1, -- project location
             at_base_location bl1,     -- project location
             at_physical_location pl2, -- lock location
             at_base_location bl2,     -- lock location
             cwms_time_zone tz,
             cwms_base_parameter bp,
             cwms_unit u
       where o.office_id like l_office_id_mask
         and bl1.db_office_code = o.office_code
         and pl1.base_location_code = bl1.base_location_code
         and cwms_util.concat_base_sub_id(bl1.base_location_id, pl1.sub_location_id) 
             = nvl(p_project_id, cwms_util.concat_base_sub_id(bl1.base_location_id, pl1.sub_location_id))
         and p.project_location_code = pl1.location_code
         and l.project_location_code = p.project_location_code
         and pl2.location_code = l.lock_location_code
         and bl2.base_location_code = pl2.base_location_code
         and tz.time_zone_code = pl2.time_zone_code
         and bp.base_parameter_id = 'Elev'
         and u.unit_code = bp.unit_code;

end cat_lock;


PROCEDURE retrieve_lock(
   p_lock OUT lock_obj_t,                  --returns a filled in lock object including location data
   p_lock_location_ref IN location_ref_t)  -- a location ref that identifies the lock we want to retrieve.
                                           -- includes the lock's location id (base location + '-' + sublocation)
                                           -- the office id if null will default to the connected user's office
is
   l_lock_rec      at_lock%rowtype;
   l_lock_loc      location_obj_t;
   l_lock_loc_rec  at_physical_location%rowtype;
   l_lock_location_ref location_ref_t;
begin
   --------------------------------------------------------------
   -- set up a location ref that defaults to the user's office --
   --------------------------------------------------------------
   l_lock_location_ref := location_ref_t(
      p_lock_location_ref.office_id, 
      p_lock_location_ref.get_location_id);
   if l_lock_location_ref.office_id is null then
      l_lock_location_ref.office_id := cwms_util.user_office_id;
   end if;         
   --------------------------------------------------------------
   -- select rows from at_lock and at_physical location tables --
   --------------------------------------------------------------
   begin
      select *
        into l_lock_rec
        from at_lock
       where lock_location_code = l_lock_location_ref.get_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Lock location',
            l_lock_location_ref.office_id||'/'||l_lock_location_ref.get_location_id);
   end;
   begin
      select *
        into l_lock_loc_rec
        from at_physical_location
       where location_code = l_lock_rec.project_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Project for lock location',
            l_lock_location_ref.office_id||'/'||l_lock_location_ref.get_location_id);
   end;
   -------------------------------------        
   -- create the lock location object --
   -------------------------------------        
   l_lock_loc := location_obj_t(
      l_lock_location_ref,
      null, -- state_initial
      null, -- county_name
      null, -- time_zone_name
      l_lock_loc_rec.location_type,
      l_lock_loc_rec.latitude,
      l_lock_loc_rec.longitude,
      l_lock_loc_rec.horizontal_datum,
      l_lock_loc_rec.elevation,
      null, -- elev_unit_id
      l_lock_loc_rec.vertical_datum,
      l_lock_loc_rec.public_name,
      l_lock_loc_rec.long_name,
      l_lock_loc_rec.description,
      l_lock_loc_rec.active_flag,
      null, -- l_location_kind_id
      l_lock_loc_rec.map_label,
      l_lock_loc_rec.published_latitude,
      l_lock_loc_rec.published_longitude,
      null, -- l_bounding_office_id
      null, -- l_bounding_office_name
      null, -- l_nation_id
      l_lock_loc_rec.nearest_city);
   ------------------------------------------------------------------------------------    
   -- complete the lock location object from codes in the at_physical location table --
   ------------------------------------------------------------------------------------    
   select s.state_initial,
          c.county_name,
          tz.time_zone_name,
          u.unit_id,
          lk.location_kind_id,
          o.office_id,
          o.public_name,
          n.nation_id
     into l_lock_loc.state_initial,
          l_lock_loc.county_name,
          l_lock_loc.time_zone_name,
          l_lock_loc.elev_unit_id,
          l_lock_loc.location_kind_id,
          l_lock_loc.bounding_office_id,
          l_lock_loc.bounding_office_name,
          l_lock_loc.nation_id
     from cwms_county c,
          cwms_state s,
          cwms_time_zone tz,
          cwms_base_parameter bp,
          cwms_unit u,
          at_location_kind lk,
          at_base_location bl,
          cwms_office o,
          cwms_nation n
    where c.county_code = nvl(l_lock_loc_rec.county_code, 0)
      and s.state_code = c.state_code
      and tz.time_zone_code = nvl(l_lock_loc_rec.time_zone_code, 0)
      and bp.base_parameter_id = 'Elev'
      and u.unit_code = bp.unit_code
      and bl.base_location_code = l_lock_loc_rec.base_location_code
      and lk.office_code = bl.db_office_code
      and lk.location_kind_code = nvl(l_lock_loc_rec.location_kind, 1)
      and o.office_code = nvl(l_lock_loc_rec.office_code, 0)
      and n.nation_code = nvl(l_lock_loc_rec.nation_code, 'US');
   ----------------------------    
   -- create the lock object --
   ----------------------------    
   p_lock := lock_obj_t(
      location_ref_t(l_lock_rec.project_location_code),
      l_lock_loc,
      l_lock_rec.lock_width,
      l_lock_rec.lock_length,
      l_lock_rec.volume_per_lockage,
      l_lock_rec.minimum_draft,
      l_lock_rec.normal_lock_lift);

end retrieve_lock;

procedure store_lock(
   p_lock           IN lock_obj_t,           -- a populated lock object type.
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T') -- a flag that will cause the procedure to fail if the lock already exists
is
   l_lock_rec at_lock%rowtype;
   l_exists   boolean;
begin
   -------------------------------------
   -- retrieve the lock, if it exists --
   -------------------------------------
   begin
      select *
        into l_lock_rec
        from at_lock
       where lock_location_code = p_lock.lock_location.location_ref.get_location_code;
      l_exists := true;       
   exception 
      when no_data_found then
         l_exists := false;
   end;
   ----------------------------
   -- error out if necessary --
   ----------------------------
   if l_exists and cwms_util.return_true_or_false(p_fail_if_exists) then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Lock',
         p_lock.lock_location.location_ref.office_id||'/'||p_lock.lock_location.location_ref.get_location_id);
   end if;
   ------------------------------------------------------
   -- verify that the project location already exists, --
   -- we don't have enough info to create it           --
   ------------------------------------------------------
   begin
      l_lock_rec.project_location_code := p_lock.project_location_ref.get_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Project for lock location',
            p_lock.project_location_ref.office_id||'/'||p_lock.project_location_ref.get_location_id);
   end;
   ----------------------------------------------------------
   -- fill out the lock record, don't overwrite with nulls --
   ----------------------------------------------------------
   l_lock_rec.lock_width            := nvl(p_lock.lock_width,         l_lock_rec.lock_width);
   l_lock_rec.locK_length           := nvl(p_lock.lock_length,        l_lock_rec.lock_length);
   l_lock_rec.volume_per_lockage    := nvl(p_lock.volume_per_lockage, l_lock_rec.volume_per_lockage);
   l_lock_rec.minimum_draft         := nvl(p_lock.minimum_draft,      l_lock_rec.minimum_draft);
   l_lock_rec.normal_lock_lift      := nvl(p_lock.normal_lock_lift,   l_lock_rec.normal_lock_lift);
   ---------------------------------
   -- insert or update the record --
   ---------------------------------
   if l_exists then
      -------------
      -- update ---
      -------------
      update at_lock
         set row = l_lock_rec
       where lock_location_code = l_lock_rec.lock_location_code; 
   else
      ------------
      -- insert --
      ------------
      begin
         l_lock_rec.lock_location_code := p_lock.lock_location.location_ref.get_location_code;
      exception
         when no_data_found then
            --------------------------------------
            -- need to create the lock location --
            --------------------------------------
            cwms_loc.create_location2(
               p_lock.lock_location.location_ref.get_location_id, -- p_location_id         IN VARCHAR2,
               p_lock.lock_location.location_type,                -- p_location_type       IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.elevation,                    -- p_elevation           IN NUMBER   DEFAULT NULL,
               p_lock.lock_location.elev_unit_id,                 -- p_elev_unit_id        IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.vertical_datum,               -- p_vertical_datum      IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.latitude,                     -- p_latitude            IN NUMBER   DEFAULT NULL,
               p_lock.lock_location.longitude,                    -- p_longitude           IN NUMBER   DEFAULT NULL,
               p_lock.lock_location.horizontal_datum,             -- p_horizontal_datum    IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.public_name,                  -- p_public_name         IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.long_name,                    -- p_long_name           IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.description,                  -- p_description         IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.time_zone_name,               -- p_time_zone_id        IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.county_name,                  -- p_county_name         IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.state_initial,                -- p_state_initial       IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.active_flag,                  -- p_active              IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.location_kind_id,             -- p_location_kind_id    IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.map_label,                    -- p_map_label           IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.published_latitude,           -- p_published_latitude  IN NUMBER   DEFAULT NULL,
               p_lock.lock_location.published_longitude,          -- p_published_longitude IN NUMBER   DEFAULT NULL,
               p_lock.lock_location.bounding_office_id,           -- p_bounding_office_id  IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.nation_id,                    -- p_nation_id           IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.nearest_city,                 -- p_nearest_city        IN VARCHAR2 DEFAULT NULL,
               p_lock.lock_location.location_ref.office_id);      -- p_db_office_id        IN VARCHAR2 DEFAULT NULL
               
            l_lock_rec.lock_location_code := p_lock.lock_location.location_ref.get_location_code;
      end;
      insert
        into at_lock
      values l_lock_rec;
   end if;   
end store_lock;


procedure rename_lock(
   p_lock_id_old  IN VARCHAR2,              -- the old lock concatenated location id
   p_lock_id_new  IN VARCHAR2,              -- the new lock concatenated location id
   p_db_office_id IN VARCHAR2 DEFAULT NULL) -- defaults to the connected user's office if null	
is
begin
   cwms_loc.rename_location(p_lock_id_old, p_lock_id_new, p_db_office_id);
end rename_lock;


procedure delete_lock(
    p_lock_id       IN VARCHAR,                               -- base location id + "-" + sub-loc id (if it exists)
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, --
    p_db_office_id  IN VARCHAR2 DEFAULT NULL)                 -- defaults to the connected user's office if null	
is
   l_lock_location_code number(10) := cwms_loc.get_location_code(p_db_office_id, p_lock_id);
   -------------------------------------------------------------------------------
   -- declare a local procedure to handle deletion of non-timeseries child data --
   -------------------------------------------------------------------------------
   procedure del_non_ts_child_data(
      p_lock_location_code in number)
   is
   begin
      -- whenever there are lockage records or other child data of locks,
      -- put the code here to delete it. 
      null;
   end;
begin
   if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      del_non_ts_child_data(l_lock_location_code);
   end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      cwms_loc.delete_location(p_lock_id, p_delete_action, p_db_office_id);
   end if;
end delete_lock;

END CWMS_LOCK;

 
/
show errors;


CREATE OR REPLACE PACKAGE BODY CWMS_LOCK AS

-------------------------------------------------------------------------------
-- CWMS_LOCK
--
-- These procedures and functions query and manipulate locks in the CWMS/ROWCPS
-- database.

--------------------------------------------------------------------------------
-- function get_lock_code
--------------------------------------------------------------------------------
function get_lock_code(
   p_office_id     in varchar2,
   p_lock_id in varchar2)
   return number
is
   l_lock_code number(14);
   l_office_id varchar2(16);
begin
   if p_lock_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOCK_ID');
   end if;
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   begin
      l_lock_code := cwms_loc.get_location_code(l_office_id, p_lock_id);
      select lock_location_code
        into l_lock_code
        from at_lock
       where lock_location_code = l_lock_code;
   exception
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS lock identifier.',
            l_office_id
            ||'/'
            ||p_lock_id);
   end;
   return l_lock_code;
end get_lock_code;

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
--    project_location_id      varchar2(57)   the parent project's location id
--    base_location_id         varchar2(24)   base location id
--    sub_location_id          varchar2(32)   sub-location id, if any
--    time_zone_name           varchar2(28)   local time zone name for location
--    latitude                 number         location latitude
--    longitude                number         location longitude
--    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
--    elevation                number         location elevation
--    elev_unit_id             varchar2(16)   location elevation units
--    vertical_datum           varchar2(16)   veritcal datum of elevation
--    public_name              varchar2(57)   location public name
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
   p_project_id   IN  VARCHAR2 DEFAULT NULL, -- the project id. if null, return all locks for the office.
   p_db_office_id IN  VARCHAR2 DEFAULT NULL) -- defaults to the connected user's office if null
                                             -- the office id can use sql masks for retrieval of additional offices.
is
   l_office_id_mask varchar2(16) := cwms_util.normalize_wildcards(nvl(upper(p_db_office_id), cwms_util.user_office_id), true);
begin
   open p_lock_cat for
      select po.office_id as project_office_id,
             cwms_util.concat_base_sub_id(
               pbl.base_location_id,
               ppl.sub_location_id) as project_location_id,  --    project_location_id      varchar2(57)   the parent project's location id
             o.office_id as db_office_id,                    --    db_office_id             varchar2(16)   owning office of location
             bl.base_location_id,                           --    base_location_id         varchar2(24)   base location id
             pl.sub_location_id,                            --    sub_location_id          varchar2(32)   sub-location id, if any
             tz.time_zone_name,                              --    time_zone_name           varchar2(28)   local time zone name for location
             pl.latitude,                                   --    latitude                 number         location latitude
             pl.longitude,                                  --    longitude                number         location longitude
             pl.horizontal_datum,                           --    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
             pl.elevation,                                  --    elevation                number         location elevation
             u.unit_id as elevation_unit_id,                 --    elev_unit_id             varchar2(16)   location elevation units
             pl.vertical_datum,                             --    vertical_datum           varchar2(16)   veritcal datum of elevation
             pl.public_name,                                --    public_name              varchar2(57)   location public name
             pl.long_name,                                  --    long_name                varchar2(80)   location long name
             pl.description,                                --    description              varchar2(512)  location description
             pl.active_flag                                 --    active_flag              varchar2(1)    'T' if active, else 'F'
        from cwms_office o,
             cwms_office po,
             at_project p,
             at_lock l,
             at_physical_location ppl, -- project location
             at_base_location pbl,     -- project location
             at_physical_location pl, -- lock location
             at_base_location bl,     -- lock location
             cwms_time_zone tz,
             cwms_base_parameter bp,
             cwms_unit u
       where o.office_id like l_office_id_mask
         and po.office_code = pbl.db_office_code
         and o.office_code = bl.db_office_code
         and ppl.base_location_code = pbl.base_location_code
         and cwms_util.concat_base_sub_id(pbl.base_location_id, ppl.sub_location_id)
             = nvl(p_project_id, cwms_util.concat_base_sub_id(pbl.base_location_id, ppl.sub_location_id))
         and p.project_location_code = ppl.location_code
         and l.project_location_code = p.project_location_code
         and pl.location_code = l.lock_location_code
         and bl.base_location_code = pl.base_location_code
         --and tz.time_zone_code = pl.time_zone_code
         and tz.time_zone_code = nvl(
                  pl.time_zone_code,
                  (  select time_zone_code
                       from cwms_time_zone
                      where time_zone_name = 'UTC'
                  ))
         and bp.base_parameter_id = 'Elev'
         and u.unit_code = bp.unit_code;

end cat_lock;


PROCEDURE retrieve_lock_old(
   p_lock OUT lock_obj_t,                  --returns a filled in lock object including location data
   p_lock_location_ref IN location_ref_t)  -- a location ref that identifies the lock we want to retrieve.
                                           -- includes the lock's location id (base location + '-' + sublocation)
                                           -- the office id if null will default to the connected user's office
is
   l_lock_rec      at_lock%rowtype;
   l_lock_loc      location_obj_t;
   l_lock_loc_rec  at_physical_location%rowtype;
   l_lock_location_ref location_ref_t;
   l_cwms_office_code number;
begin
  -- get the cwms office code.
  l_cwms_office_code := cwms_util.get_office_code('CWMS');

   --------------------------------------------------------------
   -- set up a location ref that defaults to the user's office --
   --------------------------------------------------------------
   l_lock_location_ref := location_ref_t(
      p_lock_location_ref.get_location_id,p_lock_location_ref.office_id);
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
       where location_code = l_lock_location_ref.get_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Lock location',
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
   begin
      select s.state_initial,
             c.county_name,
             tz.time_zone_name,
             u.unit_id,
             lk.location_kind_id,
             o.office_id,
             o.public_name,
             n.long_name
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
             cwms_location_kind lk,
             at_base_location bl,
             cwms_office o,
             cwms_nation_sp n
       where c.county_code = nvl(l_lock_loc_rec.county_code, 0)
         and s.state_code = c.state_code
         and tz.time_zone_code = nvl(l_lock_loc_rec.time_zone_code, 0)
         and bp.base_parameter_id = 'Elev'
         and u.unit_code = bp.unit_code
         and bl.base_location_code = l_lock_loc_rec.base_location_code
         and lk.location_kind_code = nvl(l_lock_loc_rec.location_kind, 1)
         and o.office_code = nvl(l_lock_loc_rec.office_code, 0)
         -- and o.office_code = l_lock_loc_rec.office_code
         and n.fips_cntry = nvl(l_lock_loc_rec.nation_code, 'US');
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'The following dataset could not be found:'
            ||chr(10)||chr(9)||'cwms_count.county_code                = '||nvl(l_lock_loc_rec.county_code, -1)
            ||chr(10)||chr(9)||'cwms_state.state_code                 = cwms_count.state_code'
            ||chr(10)||chr(9)||'cwms_timee_zone.time_zone_code        = '||nvl(l_lock_loc_rec.time_zone_code, -1)
            ||chr(10)||chr(9)||'cwms_base_parameter.base_parameter_id = ''Elev'''
            ||chr(10)||chr(9)||'cwms_unit.unit_code                   = cwms_base_parameter.unit_code'
            ||chr(10)||chr(9)||'at_base_location.location_code        = '||l_lock_loc_rec.base_location_code
            ||chr(10)||chr(9)||'at_location_kind.office_code          = at_base_location.db_office_code'
            ||chr(10)||chr(9)||'at_location_kind.location_kind_code   = '||nvl(l_lock_loc_rec.location_kind, -1)
            ||chr(10)||chr(9)||'cwms_office.office_code               = '||nvl(l_lock_loc_rec.office_code, -1)
            ||chr(10)||chr(9)||'cwms_nation_sp.fips_cntry             = '||nvl(l_lock_loc_rec.nation_code, 'XX'));
   end;    
   ----------------------------    
   -- create the lock object --
   ----------------------------
   p_lock := lock_obj_t(
      location_ref_t(l_lock_rec.project_location_code),
      l_lock_loc,
      l_lock_rec.volume_per_lockage,
      null, -- volume units.
      l_lock_rec.lock_width,
      l_lock_rec.lock_length,
      l_lock_rec.minimum_draft,
      l_lock_rec.normal_lock_lift,
      null --  length units.
    );

end retrieve_lock_old;

PROCEDURE retrieve_lock(
   p_lock OUT lock_obj_t,                  --returns a filled in lock object including location data
   p_lock_location_ref IN location_ref_t)  -- a location ref that identifies the lock we want to retrieve.
                                           -- includes the lock's location id (base location + '-' + sublocation)
                                           -- the office id if null will default to the connected user's office
is
   l_lock_loc location_obj_t;
   l_unit                varchar2(16);
   l_factor              number;
begin
   p_lock := null;

  ----------------------------------------------------------------------------------
   -- use the cursor loop construct for convenience, there will only be one record --
   ----------------------------------------------------------------------------------
   for rec in
      (	select l.lock_location_code,
                l.project_location_code,
                l.volume_per_lockage,
                l.lock_width,
                l.lock_length,
                l.minimum_draft,
                l.normal_lock_lift
           from at_lock l
          where l.lock_location_code = p_lock_location_ref.get_location_code)
   loop
   ----------------------------
   -- create the lock object --
   ----------------------------
   p_lock := lock_obj_t(
      location_ref_t(rec.project_location_code),
      cwms_loc.retrieve_location(rec.lock_location_code),
      rec.volume_per_lockage,
      cwms_util.get_default_units('Volume'), -- volume units.
      rec.lock_width,
      rec.lock_length,
      rec.minimum_draft,
      rec.normal_lock_lift,
      cwms_util.get_default_units('Length') --  length units.
    );
   end loop;
end retrieve_lock;

procedure store_lock(
   p_lock           IN lock_obj_t,           -- a populated lock object type.
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T') -- a flag that will cause the procedure to fail if the lock already exists
is
   l_lock_rec         at_lock%rowtype;
   l_exists           boolean;
   l_length_factor    binary_double;
   l_length_offset    binary_double;
   l_volume_factor    binary_double;
   l_volume_offset    binary_double;
begin
   if p_lock is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOCK');
   end if;
   l_lock_rec.lock_location_code := cwms_loc.store_location_f(p_lock.lock_location, 'F');
   if not cwms_loc.can_store(l_lock_rec.lock_location_code, 'LOCK') then
      cwms_err.raise(
         'ERROR',
         'Cannot store LOCK information for location '
         ||p_lock.lock_location.location_ref.get_office_id
         ||'/'
         ||p_lock.lock_location.location_ref.get_location_id
         ||' (location kind = '
         ||cwms_loc.check_location_kind(l_lock_rec.lock_location_code)
         ||')');
   end if;
   -------------------------------------
   -- retrieve the lock, if it exists --
   -------------------------------------
   begin
      select *
        into l_lock_rec
        from at_lock
       where lock_location_code = l_lock_rec.lock_location_code;
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
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS Project',
            p_lock.project_location_ref.get_office_id
            ||'/'
            ||p_lock.project_location_ref.get_location_id);
   end;
   --------------------------------
   -- get the conversion factors --
   --------------------------------
   select factor,
          offset
     into l_length_factor,
          l_length_offset
     from cwms_unit_conversion uc,
          cwms_base_parameter bp
    where uc.from_unit_id = p_lock.units_id
      and bp.base_parameter_id = 'Length'
      and uc.to_unit_code = bp.unit_code;

   select factor,
          offset
     into l_volume_factor,
          l_volume_offset
     from cwms_unit_conversion uc,
          cwms_base_parameter bp
    where uc.from_unit_id = p_lock.volume_units_id
      and bp.base_parameter_id = 'Volume'
      and uc.to_unit_code = bp.unit_code;

   ----------------------------------------------------------
   -- fill out the lock record, don't overwrite with nulls --
   ----------------------------------------------------------
   l_lock_rec.lock_width :=
      case p_lock is null
         when true  then l_lock_rec.lock_width
         when false then p_lock.lock_width * l_length_factor + l_length_offset
      end;
   l_lock_rec.lock_length :=
      case p_lock is null
         when true  then l_lock_rec.lock_length
         when false then p_lock.lock_length * l_length_factor + l_length_offset
      end;
   l_lock_rec.volume_per_lockage :=
      case p_lock is null
         when true  then l_lock_rec.volume_per_lockage
         when false then p_lock.volume_per_lockage * l_volume_factor + l_volume_offset
      end;
   l_lock_rec.minimum_draft :=
      case p_lock is null
         when true  then l_lock_rec.minimum_draft
         when false then p_lock.minimum_draft * l_length_factor + l_length_offset
      end;
   l_lock_rec.normal_lock_lift :=
      case p_lock is null
         when true  then l_lock_rec.normal_lock_lift
         when false then p_lock.normal_lock_lift * l_length_factor + l_length_offset
      end;
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
      insert
        into at_lock
      values l_lock_rec;
   end if;
   ---------------------------
   -- set the location kind --
   ---------------------------
   cwms_loc.update_location_kind(l_lock_rec.lock_location_code, 'LOCK', 'A');
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
   p_lock_id in varchar,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_db_office_id  in varchar2 default null
)
is
begin
   delete_lock2(
      p_lock_id => p_lock_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_db_office_id);
end delete_lock;

procedure delete_lock2(
   p_lock_id                in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null)
is
   l_lock_code          number(14);
   l_delete_location    boolean;
   l_delete_action1     varchar2(16);
   l_delete_action2     varchar2(16);
   l_count              pls_integer;
   l_location_kind_id   cwms_location_kind.location_kind_id%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_lock_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_lock_ID');
   end if;
   l_delete_action1 := upper(substr(p_delete_action, 1, 16));
   if l_delete_action1 not in (
      cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
   then
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
   end if;
   l_delete_location := cwms_util.return_true_or_false(p_delete_location);
   if l_delete_location then
      l_delete_action2 := upper(substr(p_delete_location_action, 1, 16));
      if l_delete_action2 not in (
         cwms_util.delete_key,
         cwms_util.delete_data,
         cwms_util.delete_all)
      then
         cwms_err.raise(
            'ERROR',
            'Delete action must be one of '''
            ||cwms_util.delete_key
            ||''',  '''
            ||cwms_util.delete_data
            ||''', or '''
            ||cwms_util.delete_all
            ||'');
      end if;
   end if;
   l_lock_code := get_lock_code(p_office_id, p_lock_id);
   l_location_kind_id := cwms_loc.check_location_kind(l_lock_code);
   if l_location_kind_id != 'LOCK' then
      cwms_err.raise(
         'ERROR',
         'Cannot delete lock information from location '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_lock_id
         ||' (location kind = '
         ||l_location_kind_id
         ||')');
   end if;
   l_location_kind_id := cwms_loc.can_revert_loc_kind_to(p_lock_id, p_office_id);
   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
   if l_delete_action1 in (cwms_util.delete_data, cwms_util.delete_all) then
      delete
        from at_lockage
       where lockage_location_code = l_lock_code;
   end if;
   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
   if l_delete_action1 in (cwms_util.delete_key, cwms_util.delete_all) then
      delete from at_lock where lock_location_code = l_lock_code;
      cwms_loc.update_location_kind(l_lock_code, 'LOCK', 'D');
   end if;
   -------------------------------------
   -- delete the location if required --
   -------------------------------------
   if l_delete_location then
      cwms_loc.delete_location(p_lock_id, l_delete_action2, p_office_id);
   end if;
end delete_lock2;

END CWMS_LOCK;


/

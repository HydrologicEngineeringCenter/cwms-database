whenever sqlerror exit sql.sqlcode
set serveroutput on


create or replace
package body cwms_embank is


-------------------------------------------------------------------------------
-- CWMS_EMBANK
--
-- These procedures and functions query and manipulate embankments in the CWMS/ROWCPS
-- database. An embankment will always have a parent project defined in AT_PROJECT.
-- There can be zero to many embankments for a given project.

---Note
---Note on DB_OFFICE_ID. DB_OFFICEID in addtion to location id is required to 
-- uniquely identify a location code, so it will be included in all of these calls.
--
-- defaults to the connected user's office if null.
-- p_db_office_id		IN		VARCHAR2 DEFAULT NULL
-- CWMS has a package proceudure that can be used to determine the office id for
-- a given user.
--

--type definitions:
-- from cwms_types.sql, location_obj_t and location_ref_t.
-- from rowcps_types.sql, embankment_obj_t.

-- security:
-- 
-------------------------------------------------------------------------------





--------------------------------------------------------------------------------
-- function get_embankment_code
--------------------------------------------------------------------------------
function get_embankment_code(
   p_office_id     in varchar2,
   p_embankment_id in varchar2)
   return number
is
   l_embankment_code number(10);
   l_office_id       varchar2(16);
begin
   if p_embankment_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_EMBANKMENT_ID');
   end if;
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   begin
      l_embankment_code := cwms_loc.get_location_code(l_office_id, p_embankment_id);
      select embankment_location_code
        into l_embankment_code
        from at_embankment
       where embankment_location_code = l_embankment_code;
   exception
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS embankment identifier.',
            l_office_id
            ||'/'
            ||p_embankment_id);
   end;
   return l_embankment_code;   
end get_embankment_code;   

--
-- cat_embankment
-- returns a listing of embankments.
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
--    project_office_id        varchar2(16)  the office id of the parent project.
--    project_id	             varchar2(49)	the identification (id) of the parent project.
--    db_office_id             varchar2(16)  owning office of location
--    base_location_id         varchar2(16)  base location id
--    sub_location_id          varchar2(32)  sub-location id, if any
--    time_zone_name           varchar2(28)  local time zone name for location
--    latitude                 number        location latitude
--    longitude                number        location longitude
--    horizontal_datum         varchar2(16)  horizontal datrum of lat/lon
--    elevation                number        location elevation
--    elev_unit_id             varchar2(16)  location elevation units
--    vertical_datum           varchar2(16)  veritcal datum of elevation
--    public_name              varchar2(32)  location public name
--    long_name                varchar2(80)  location long name
--    description              varchar2(512) location description
--    active_flag              varchar2(1)   'T' if active, else 'F'
--
-------------------------------------------------------------------------------
-- errors will be issued as thrown exceptions.
--
-- p_embankment_cat   out      sys_refcursor,
--   described above.
-- p_project_id   in    varchar2 default null,  
--   the project id. if null, return all embankments for the office.
-- p_db_office_id in    varchar2 default null
--   defaults to the connected user's office if null
--   the office id can use sql masks for retrieval of additional offices.
procedure cat_embankment (
   p_embankment_cat out sys_refcursor,
   p_project_id     in  varchar2 default null,  
   p_db_office_id   in  varchar2 default null
)
is
   l_office_id_mask  varchar2(16);
   l_project_id_mask varchar2(49);
begin
   l_office_id_mask := cwms_util.normalize_wildcards(
      upper(nvl(p_db_office_id, cwms_util.user_office_id)), true);
   l_project_id_mask := cwms_util.normalize_wildcards(
      upper(nvl(p_project_id, '%')), true);
   open p_embankment_cat for
      select po.office_id as project_office_id,
             pbl.base_location_id
             ||substr('-', 1, length(ppl.sub_location_id))
             ||ppl.sub_location_id as project_id,
             o.office_id as db_office_id,
             bl.base_location_id,
             pl.sub_location_id,
             tz.time_zone_name,
             pl.latitude,
             pl.longitude,
             pl.horizontal_datum,
             pl.elevation * uc.factor + uc.offset as elevation,
             uc.to_unit_id as elev_unit_id,
             pl.vertical_datum,
             pl.public_name,
             pl.long_name,
             pl.description,
             pl.active_flag
        from at_embankment e,
             at_physical_location ppl,
             at_base_location pbl,
             cwms_office po,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o,
             cwms_time_zone tz,
             at_display_units du,
             cwms_unit_conversion uc,
             cwms_base_parameter bp
       where ppl.location_code = e.embankment_project_loc_code
         and pbl.base_location_code = ppl.base_location_code
         and pbl.base_location_id
             ||substr('-', 1, length(ppl.sub_location_id))
             ||ppl.sub_location_id like l_project_id_mask
         and po.office_code = pbl.db_office_code
         and pl.location_code = e.embankment_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code
         and o.office_id like l_office_id_mask
         and tz.time_zone_code = pl.time_zone_code
         and bp.base_parameter_id = 'Elev'
         and uc.from_unit_code = bp.unit_code
         and du.parameter_code = bp.base_parameter_code           
         and du.unit_system = 'EN'
         and uc.to_unit_code = du.display_unit_code;
end cat_embankment;


-- Returns embankment data for a given embankment id. Returned data is encapsulated
-- in a embankment oracle type. 
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued is a thrown exception
--
-- p_embankment
--    returns a filled in object including location data
-- p_embankment_location_ref
--    a location ref that identifies the object we want to retrieve.
--    includes the lock's location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
procedure retrieve_embankment(
   p_embankment              out embankment_obj_t,
   p_embankment_location_ref in  location_ref_t
)
is
   l_unit   varchar2(16);
   l_factor number;
begin
   p_embankment := null;
   ----------------------------------------------------------------------------------
   -- use the cursor loop construct for convenience, there will only be one record --
   ----------------------------------------------------------------------------------
   for rec in 
      (	select e.embankment_location_code,
                e.embankment_project_loc_code,
                e.structure_type_code,
                e.upstream_prot_type_code,
                e.upstream_sideslope, 
                e.downstream_prot_type_code,
                e.downstream_sideslope,
                e.height_max,
                e.structure_length,
                e.top_width,
                s.structure_type_display_value,
                s.structure_type_tooltip,
                s.structure_type_active,
                so.office_id as s_office_id, 
                up.protection_type_display_value as up_prot_type_display_value,
                up.protection_type_tooltip as up_prot_type_tooltip,
                up.protection_type_active as up_prot_type_active,
                upo.office_id as up_office_id, 
                dp.protection_type_display_value as dp_prot_type_display_value,
                dp.protection_type_tooltip as dp_prot_type_tooltip,
                dp.protection_type_active as dp_prot_type_active,
                dpo.office_id as dp_office_id 
           from at_embankment e
                inner join  at_embank_structure_type s on (s.structure_type_code = e.structure_type_code)
                inner join cwms_office so on (so.office_code = s.db_office_code)
                left outer join at_embank_protection_type up on (up.protection_type_code = e.upstream_prot_type_code)
                left outer join cwms_office upo on (upo.office_code = up.db_office_code)
                left outer join at_embank_protection_type dp on (dp.protection_type_code = e.downstream_prot_type_code)
                left outer join cwms_office dpo on (dpo.office_code = dp.db_office_code)
          where embankment_location_code = p_embankment_location_ref.get_location_code)
   loop
      --------------------------------------------------
      -- create the object with database length units --
      --------------------------------------------------
      p_embankment := embankment_obj_t(
         location_ref_t(rec.embankment_project_loc_code),
         cwms_loc.retrieve_location(rec.embankment_location_code),
         lookup_type_obj_t(rec.s_office_id, rec.structure_type_display_value, rec.structure_type_tooltip, rec.structure_type_active),
         lookup_type_obj_t(rec.up_office_id, rec.up_prot_type_display_value, rec.up_prot_type_tooltip, rec.up_prot_type_active),
         lookup_type_obj_t(rec.dp_office_id, rec.dp_prot_type_display_value, rec.dp_prot_type_tooltip, rec.dp_prot_type_active),
         rec.upstream_sideslope,
         rec.downstream_sideslope, 
         rec.structure_length, 
         rec.height_max, 
         rec.top_width,
         cwms_util.get_default_units('Length'));
      ------------------------------------------------------------         
      -- modify the object for the caller's Length display unit --
      ------------------------------------------------------------         
      cwms_util.user_display_unit(
         l_unit,
         l_factor,
         'Length',
         1.0,
         cwms_util.user_office_id,
         rec.s_office_id);
      if l_unit != p_embankment.units_id then
         p_embankment.structure_length := p_embankment.structure_length * l_factor; 
         p_embankment.height_max := p_embankment.height_max * l_factor; 
         p_embankment.top_width := p_embankment.top_width * l_factor;
         p_embankment.units_id := l_unit; 
      end if;         
   end loop;
end retrieve_embankment;

-- Returns a set of embankments for a given project. Returned data is encapsulated
-- in a table of embankment oracle types. 
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued is a thrown exception
--
-- p_embankments OUT embankment_tab_t,     
--    returns a filled set of objects including location data
-- p_project_location_refs IN location_ref_tab_t
--    a project location refs that identify the objects we want to retrieve.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
procedure retrieve_embankments(
   p_embankments           out embankment_tab_t,     
   p_project_location_ref  in  location_ref_t
) 
is
begin
   p_embankments := embankment_tab_t();
   for rec in
      (select embankment_location_code
         from at_embankment
        where embankment_project_loc_code = p_project_location_ref.get_location_code)
   loop
      p_embankments.extend;
      retrieve_embankment(
         p_embankments(p_embankments.count), 
         location_ref_t(rec.embankment_location_code));
   end loop;
end retrieve_embankments;

-- Stores the data contained within the embankment object into the database schema.
-- 
--
-- security: can only be called by dba group.
--
-- This procedure performs both insert and update functionality. 
--
--
-- errors will be issued is thrown exceptions.
--
-- p_embankment      IN      embankment_obj_t,
--    a populated embankment object type.
-- p_fail_if_exists IN VARCHAR2 DEFAULT 'T'
--    a flag that will cause the procedure to fail if the lock already exists
procedure store_embankment(
   p_embankment     in embankment_obj_t,
   p_fail_if_exists in varchar2 default 'T'
)
is
   l_embankment       at_embankment%rowtype; 
   l_factor           binary_double;
   l_offset           binary_double;
   l_code             integer;
   l_location_kind_id varchar2(32);
begin
   if p_embankment is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_EMBANKMENT');
   end if;
   begin
      l_code := p_embankment.embankment_location.location_ref.get_location_code;
   exception
      when no_data_found then null;
   end;
   if l_code is not null then
      l_location_kind_id := cwms_loc.check_location_kind(l_code);
      if l_location_kind_id not in ('EMBANKMENT', 'SITE', 'STREAMGAGE') then
         cwms_err.raise(
            'ERROR',
            'Cannot switch location '
            ||p_embankment.embankment_location.location_ref.office_id
            ||'/'
            ||p_embankment.embankment_location.location_ref.get_location_id
            ||' from type '
            ||l_location_kind_id
            ||' to type EMBANKMENT');
      end if;
      begin
         select *
           into l_embankment  
           from at_embankment
          where embankment_location_code = l_code;
      exception
         when no_data_found then null;
      end;
   end if;
   if l_embankment.embankment_location_code is not null then
      if cwms_util.is_true(p_fail_if_exists) then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Embankment',
            p_embankment.embankment_location.location_ref.get_office_id
            || '/'
            || p_embankment.embankment_location.location_ref.get_location_id);
            
      end if;
   end if;
   ------------------------------------
   -- get the unit conversion factor --
   ------------------------------------
   begin
      select factor,
             offset
        into l_factor,
             l_offset
        from cwms_unit_conversion
       where from_unit_id = cwms_util.get_default_units('Length')
         and to_unit_id = p_embankment.units_id;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_embankment.units_id,
            'unit identifier');
   end;                   
   ------------------------------------
   -- populate the embankment record --
   ------------------------------------
   begin
      l_embankment.embankment_project_loc_code := p_embankment.project_location_ref.get_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Specified project location ('
            || p_embankment.project_location_ref.get_location_id
            || ') does not exist for embankment location'
            || p_embankment.embankment_location.location_ref.get_office_id
            || '/'
            || p_embankment.embankment_location.location_ref.get_location_id);
   end;
   begin
      select structure_type_code
        into l_embankment.structure_type_code
        from at_embank_structure_type
       where db_office_code = cwms_util.get_office_code(p_embankment.structure_type.office_id) 
         and upper(structure_type_display_value) = upper(p_embankment.structure_type.display_value); 
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Specified structure type ('
            || p_embankment.structure_type.office_id
            || '/'
            || p_embankment.structure_type.display_value
            || ') does not exist for embankment location'
            || p_embankment.embankment_location.location_ref.get_office_id
            || '/'
            || p_embankment.embankment_location.location_ref.get_location_id);
   end;
   if p_embankment.upstream_prot_type is not null then
   begin
      select protection_type_code
        into l_embankment.upstream_prot_type_code
        from at_embank_protection_type
       where db_office_code = cwms_util.get_office_code(p_embankment.upstream_prot_type.office_id)
         and upper(protection_type_display_value) = upper(p_embankment.upstream_prot_type.display_value); 
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Specified upstream protection type ('
            || p_embankment.upstream_prot_type.office_id
            || '/'
            || p_embankment.upstream_prot_type.display_value
            || ') does not exist for embankment location'
            || p_embankment.embankment_location.location_ref.get_office_id
            || '/'
            || p_embankment.embankment_location.location_ref.get_location_id);
   end;
   end if;
   if p_embankment.downstream_prot_type is not null then
   begin
      select protection_type_code
        into l_embankment.downstream_prot_type_code
        from at_embank_protection_type
       where db_office_code = cwms_util.get_office_code(p_embankment.downstream_prot_type.office_id)
         and upper(protection_type_display_value) = upper(p_embankment.downstream_prot_type.display_value); 
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Specified downstream protection type ('
            || p_embankment.downstream_prot_type.office_id
            || '/'
            || p_embankment.downstream_prot_type.display_value
            || ') does not exist for embankment location'
            || p_embankment.embankment_location.location_ref.get_office_id
            || '/'
            || p_embankment.embankment_location.location_ref.get_location_id);
   end;
   end if;
   l_embankment.upstream_sideslope   := p_embankment.upstream_sideslope;
   l_embankment.downstream_sideslope := p_embankment.downstream_sideslope;
   l_embankment.structure_length     := p_embankment.structure_length * l_factor;
   l_embankment.height_max           := p_embankment.height_max * l_factor;
   l_embankment.top_width            := p_embankment.top_width * l_factor;
   cwms_loc.store_location(p_embankment.embankment_location,'F');
   -------------------------------------
   -- insert or update the embankment --
   -------------------------------------
   if l_embankment.embankment_location_code is null then
      l_embankment.embankment_location_code := cwms_loc.get_location_code(
         p_embankment.embankment_location.location_ref.get_office_id,
         p_embankment.embankment_location.location_ref.get_location_id);
      insert 
        into at_embankment 
      values l_embankment;
   else
      update at_embankment 
        set row = l_embankment 
      where embankment_location_code = l_embankment.embankment_location_code;
   end if;
   ---------------------------      
   -- set the location kind --
   ---------------------------
   update at_physical_location
      set location_kind = (select location_kind_code 
                             from cwms_location_kind 
                            where location_kind_id = 'EMBANKMENT'
                          )
    where location_code = l_embankment.embankment_location_code;                                 
end store_embankment;

-- Stores the data contained within the embankment object into the database schema.
-- 
--
-- security: can only be called by dba group.
--
-- This procedure performs both insert and update functionality. 
--
--
-- errors will be issued is thrown exceptions.
--
-- p_embankments      IN      embankment_tab_t,
--    a populated embankment object type.
-- p_fail_if_exists IN VARCHAR2 DEFAULT 'T'
--    a flag that will cause the procedure to fail if the object already exists
procedure store_embankments(
  p_embankments    in embankment_tab_t,
  p_fail_if_exists in varchar2 default 'T'
)
is
   l_error_msg varchar2(4000);
begin
   if p_embankments is not null then
      for i in 1..p_embankments.count loop
         if p_embankments(i) is not null then
            begin
               store_embankment(p_embankments(i), p_fail_if_exists);
            exception
               when others then
                  l_error_msg := l_error_msg || chr(10) || sqlerrm;
            end;
         end if;
      end loop;
   end if;
   if l_error_msg is not null then
      cwms_err.raise(
         'ERROR',
         'The following error(s) occurred:' || l_error_msg);
   end if;
end store_embankments;

-- Renames a embankment from one id to a new id.
--
-- security: can only be called by dba group.
--

--
-- errors will be issued is thrown exceptions.
--
-- p_embankment_id_old   IN   VARCHAR2,
-- p_embankment_id_new   IN   VARCHAR2,
-- p_db_office_id IN VARCHAR2 DEFAULT NULL
--    defaults to the connected user's office if null   
procedure rename_embankment(
   p_embankment_id_old	in	varchar2,
   p_embankment_id_new	in	varchar2,
   p_db_office_id in varchar2 default null
)
is
begin
   cwms_loc.rename_location(
      p_embankment_id_old, 
      p_embankment_id_new, 
      p_db_office_id);
end rename_embankment;

procedure delete_embankment(
   p_embankment_id in varchar,
   p_delete_action in varchar2 default cwms_util.delete_key, 
   p_db_office_id  in varchar2 default null
)
is
begin
   delete_embankment2(
      p_embankment_id => p_embankment_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_db_office_id);
end delete_embankment;

procedure delete_embankment2(
   p_embankment_id          in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null)
is
   l_embankment_code    number(10);
   l_delete_location    boolean;
   l_delete_action1     varchar2(16);
   l_delete_action2     varchar2(16);
   l_count              pls_integer;
   l_location_kind_code integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_embankment_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_EMBANKMENT_ID');
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
   l_embankment_code := get_embankment_code(p_office_id, p_embankment_id);
   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
   if l_delete_action1 in (cwms_util.delete_data, cwms_util.delete_all) then
      null;  -- currently no dependent data
   end if;
   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
   if l_delete_action1 in (cwms_util.delete_key, cwms_util.delete_all) then
      delete
        from at_embankment
       where embankment_location_code = l_embankment_code;
   end if; 
   -------------------------------------
   -- delete the location if required --
   -------------------------------------
   if l_delete_location then
      cwms_loc.delete_location(p_embankment_id, l_delete_action2, p_office_id);
   else
      select count(*)
        into l_count
        from at_stream_location
       where location_code = l_embankment_code;
      if l_count = 0 then
         select location_kind_code
           into l_location_kind_code
           from cwms_location_kind
          where location_kind_id = 'SITE'; 
      else
         select location_kind_code
           into l_location_kind_code
           from cwms_location_kind
          where location_kind_id = 'STREAMGAGE'; 
      end if;       
      update at_physical_location 
         set location_kind = l_location_kind_code 
       where location_code = l_embankment_code;   
   end if;
end delete_embankment2;   

--
-- manipulation of structure_type lookups
--

-- returns a listing of lookup objects.
-- p_lookup_type_tab out lookup_type_tab_t,
--    defaults to the connected user's office if null 
-- p_db_office_id  in varchar2 default null 
procedure get_structure_types(
   p_lookup_type_tab out lookup_type_tab_t,
   p_db_office_id    in  varchar2 default null 
)
is
   l_db_office_id varchar2(16) := nvl(p_db_office_id, cwms_util.user_office_id);
begin
   p_lookup_type_tab := lookup_type_tab_t();
   for rec in (
      select * 
        from at_embank_structure_type
       where db_office_code = cwms_util.get_office_code(l_db_office_id))
   loop
      p_lookup_type_tab.extend;
      p_lookup_type_tab(p_lookup_type_tab.count) := lookup_type_obj_t(
         l_db_office_id,
         rec.structure_type_display_value,
         rec.structure_type_tooltip,
         rec.structure_type_active);
   end loop;       
end get_structure_types;

-- inserts or updates a set of lookups.
-- if a lookup does not exist it will be inserted.
-- if a lookup already exists and p_fail_if_exists is false, the existing
-- lookup will be updated.
--
-- a failure will cause the whole set of lookups to not be stored.
-- p_lookup_type_tab in lookup_type_tab_t,
-- p_fail_if_exists in varchar2 default 'T'
--    a flag that will cause the procedure to fail if the objects already exist
procedure set_structure_types(
   p_lookup_type_tab in lookup_type_tab_t,
   p_fail_if_exists in varchar2 default 'T'
)
is
begin
   if p_lookup_type_tab is not null then
      for i in 1..p_lookup_type_tab.count loop
         set_structure_type(p_lookup_type_tab(i), p_fail_if_exists);
      end loop;
   end if;
end set_structure_types;

-- inserts or updates a lookup.
-- if the lookup does not exist it will be inserted.
-- if the lookup already exists and p_fail_if_exists is false, the existing
-- lookup will be updated.
-- p_lookup_type in lookup_type_obj_t,
-- p_fail_if_exists in varchar2 default 'T'
--    a flag that will cause the procedure to fail if the objects already exist
procedure set_structure_type(
   p_lookup_type    in lookup_type_obj_t,
   p_fail_if_exists in varchar2 default 'T'
)
is
   l_rec         at_embank_structure_type%rowtype;
   l_office_code number  := cwms_util.get_office_code(p_lookup_type.office_id);
   l_exists      boolean;
begin
   begin
      select *
        into l_rec
        from at_embank_structure_type
       where db_office_code = l_office_code
         and structure_type_display_value = p_lookup_type.display_value;
      if cwms_util.is_true(p_fail_if_exists) then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Embankment structure type',
            p_lookup_type.office_id||'/'||p_lookup_type.display_value);
      end if;
      l_exists := true;         
   exception
      when no_data_found then
         l_exists := false;         
   end;
   l_rec.structure_type_tooltip := p_lookup_type.tooltip;
   l_rec.structure_type_active  := p_lookup_type.active;         
   if not l_exists then
      l_rec.structure_type_code := cwms_seq.nextval;
      l_rec.db_office_code := l_office_code;
      l_rec.structure_type_display_value := p_lookup_type.display_value;
      insert
        into at_embank_structure_type
      values l_rec;
   else        
      update at_embank_structure_type
         set row = l_rec
       where structure_type_code = l_rec.structure_type_code;
   end if;
end set_structure_type;

-- removes a lookup.
procedure remove_structure_type(
   p_lookup_type in lookup_type_obj_t
)
is
begin
   delete 
     from at_embank_structure_type
    where db_office_code = cwms_util.get_office_code(p_lookup_type.office_id)
      and structure_type_display_value = p_lookup_type.display_value;
end remove_structure_type;

--
-- manipulation of protection_type lookups.
-- used for both upstream and downstream.
--

-- returns a listing of lookup objects.
-- p_lookup_type_tab out lookup_type_tab_t,
--    defaults to the connected user's office if null 
-- p_db_office_id  in varchar2 default null 
procedure get_protection_types(
   p_lookup_type_tab out lookup_type_tab_t,
   p_db_office_id    in  varchar2 default null 
)
is
   l_db_office_id varchar2(16) := nvl(p_db_office_id, cwms_util.user_office_id);
begin
   p_lookup_type_tab := lookup_type_tab_t();
   for rec in (
      select * 
        from at_embank_protection_type
       where db_office_code = cwms_util.get_office_code(l_db_office_id))
   loop
      p_lookup_type_tab.extend;
      p_lookup_type_tab(p_lookup_type_tab.count) := lookup_type_obj_t(
         l_db_office_id,
         rec.protection_type_display_value,
         rec.protection_type_tooltip,
         rec.protection_type_active);
   end loop;       
end get_protection_types;


-- inserts or updates a set of lookups.
-- if a lookup does not exist it will be inserted.
-- if a lookup already exists and p_fail_if_exists is false, the existing
-- lookup will be updated.
--
-- a failure will cause the whole set of lookups to not be stored.
-- p_lookup_type_tab in lookup_type_tab_t,
-- p_fail_if_exists in varchar2 default 'T'
--    a flag that will cause the procedure to fail if the objects already exist
procedure set_protection_types(
   p_lookup_type_tab in lookup_type_tab_t,
   p_fail_if_exists in varchar2 default 'T'
)
is
begin
   if p_lookup_type_tab is not null then
      for i in 1..p_lookup_type_tab.count loop
         set_protection_type(p_lookup_type_tab(i), p_fail_if_exists);
      end loop;
   end if;
end set_protection_types;

-- inserts or updates a lookup.
-- if the lookup does not exist it will be inserted.
-- if the lookup already exists and p_fail_if_exists is false, the existing
-- lookup will be updated.
-- p_lookup_type in lookup_type_obj_t,
-- p_fail_if_exists in varchar2 default 'T'
--    a flag that will cause the procedure to fail if the objects already exist
procedure set_protection_type(
   p_lookup_type    in lookup_type_obj_t,
   p_fail_if_exists in varchar2 default 'T'
)
is
   l_rec         at_embank_protection_type%rowtype;
   l_office_code number  := cwms_util.get_office_code(p_lookup_type.office_id);
   l_exists      boolean;
begin
   begin
      select *
        into l_rec
        from at_embank_protection_type
       where db_office_code = l_office_code
         and protection_type_display_value = p_lookup_type.display_value;
      if cwms_util.is_true(p_fail_if_exists) then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Embankment protection type',
            p_lookup_type.office_id||'/'||p_lookup_type.display_value);
      end if;
      l_exists := true;         
   exception
      when no_data_found then
         l_exists := false;         
   end;
   l_rec.protection_type_tooltip := p_lookup_type.tooltip;
   l_rec.protection_type_active  := p_lookup_type.active;         
   if not l_exists then
      l_rec.protection_type_code := cwms_seq.nextval;
      l_rec.db_office_code := l_office_code;
      l_rec.protection_type_display_value := p_lookup_type.display_value;
      insert
        into at_embank_protection_type
      values l_rec;
   else        
      update at_embank_protection_type
         set row = l_rec
       where protection_type_code = l_rec.protection_type_code;
   end if;
end set_protection_type;

-- removes a lookup.
procedure remove_protection_type(
   p_lookup_type in lookup_type_obj_t
)
is
begin
   delete 
     from at_embank_protection_type
    where db_office_code = cwms_util.get_office_code(p_lookup_type.office_id)
      and protection_type_display_value = p_lookup_type.display_value;
end remove_protection_type;


end cwms_embank;
 
/
show errors;
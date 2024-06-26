WHENEVER sqlerror exit sql.sqlcode
SET define on
SET serveroutput on

create or replace PACKAGE BODY CWMS_PROJECT
AS
--------------------------------------------------------------------------------
-- procedure get_project_code
--------------------------------------------------------------------------------
function get_project_code(
   p_office_id in varchar2,
   p_project_id in varchar2)
   return number
is
   l_location_code number(14);
begin
   begin
      l_location_code := cwms_loc.get_location_code(p_office_id, p_project_id);
      select project_location_code
        into l_location_code
        from at_project
       where project_location_code = l_location_code;
   exception
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS project identifier.',
            p_office_id
            ||'/'
            ||p_project_id);
   end;
   return l_location_code;
end get_project_code;

PROCEDURE cat_project (
   p_project_cat  out sys_refcursor,
   p_basin_cat  out sys_refcursor,
   p_db_office_id in  varchar2 default null
)
AS
   l_db_office_id   varchar2(16) := cwms_util.get_db_office_id(p_db_office_id);
   l_db_office_code number := cwms_util.get_db_office_code(p_db_office_id);
   l_factor         number;
   l_unit           varchar2(16);
BEGIN
   --
   -- get the display elevation unit and conversion factor
   --
   cwms_util.user_display_unit(
      l_unit,
      l_factor,
      'Elev',
      1.0,
      null,
      p_db_office_id);
   --
   -- open the cursor
   --
   open p_project_cat for
      select l_db_office_id          db_office_id,       -- db_office_id      varchar2(16)  owning office of location
             bl.base_location_id     base_location_id,   -- base_location_id  varchar2(24)  base location id
             pl.sub_location_id      sub_location_id,    -- sub_location_id   varchar2(32)  sub-location id, if any
             tz.time_zone_name       time_zone_name,     -- time_zone_name    varchar2(28)  local time zone name for location
             pl.latitude             latitude,           -- latitude          number        location latitude
             pl.longitude            longitude,          -- longitude         number        location longitude
             pl.horizontal_datum     horizontal_datum,   -- horizontal_datum  varchar2(16)  horizontal datrum of lat/lon
             pl.elevation * l_factor elevation,          -- elevation         number        location elevation
             l_unit                  elev_unit_id,       -- elev_unit_id      varchar2(16)  location elevation units
             pl.vertical_datum       vertical_datum,     -- vertical_datum    varchar2(16)  veritcal datum of elevation
             pl.public_name          public_name,        -- public_name       varchar2(57)  location public name
             pl.long_name            long_name,          -- long_name         varchar2(80)  location long name
             pl.description          description,        -- description       varchar2(512) location description
             pl.active_flag          active_flag         -- active_flag       varchar2(1)   'T' if active, else 'F'
        from at_project            p,
             at_physical_location  pl,
             at_base_location      bl,
             cwms_time_zone        tz,
             cwms_office           o
       where pl.location_code      = p.project_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code         = bl.db_office_code
         and o.office_code         = l_db_office_code
         and tz.time_zone_code = nvl(
                  pl.time_zone_code,
                  (  select time_zone_code
                       from cwms_time_zone
                      where time_zone_name = 'UTC'
                  ))
    order by bl.base_location_id,
             pl.sub_location_id;

    open p_basin_cat for select null from dual;

END cat_project;


PROCEDURE retrieve_project(
   p_project      out project_obj_t,
   p_project_id   in  varchar2,
   p_db_office_id in  varchar2 default null
)
AS
   l_db_office_code                 number := cwms_util.get_db_office_code(p_db_office_id);
   l_project_loc_code               number;
   l_project                        at_project%rowtype;
   l_project_location               location_obj_t := null;
   l_db_office_id                   varchar2(16);
   l_pumpback_location              location_obj_t := null;
   l_near_gage_location             location_obj_t := null;
   l_factor                         number;
   l_unit                           varchar2(16);
   l_temp_location_obj              location_obj_t := null;
   l_temp_location_ref              location_ref_t := null;
begin
   --
   -- get the location code
   --
   l_project_loc_code := cwms_loc.get_location_code(p_db_office_id, p_project_id);
   --
   -- get the project record
   --
   begin
      select *
        into l_project
        from at_project
       where project_location_code = l_project_loc_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS project location '
            ||cwms_util.get_db_office_id(p_db_office_id)
            ||'/'
            ||p_project_id);
   end;
   --
   -- get the display elevation unit and conversion factor
   --
   cwms_util.user_display_unit(
      l_unit,
      l_factor,
      'Elev',
      1.0,
      null,
      p_db_office_id);
   --
   -- populate the location objects
   --
   for rec in
      (  select l.location_code,
                l.base_location_id,
                l.sub_location_id,
                s.state_initial,
                s.county_name,
                tz.time_zone_name,
                l.location_type,
                l.latitude,
                l.longitude,
                l.horizontal_datum,
                l.elevation,
                l.vertical_datum,
                l.public_name,
                l.long_name,
                l.description,
                l.active_flag,
                lk.location_kind_id,
                l.map_label,
                l.published_latitude,
                l.published_longitude,
                o.office_id as bounding_office_id,
                o.public_name as bounding_office_name,
                n.long_name as nation_id,
                l.nearest_city
           from ( select pl.location_code,
                         bl.base_location_id,
                         pl.sub_location_id,
                         pl.time_zone_code,
                         pl.county_code,
                         pl.location_type,
                         pl.elevation,
                         pl.vertical_datum,
                         pl.longitude,
                         pl.latitude,
                         pl.horizontal_datum,
                         pl.public_name,
                         pl.long_name,
                         pl.description,
                         pl.active_flag,
                         pl.location_kind,
                         pl.map_label,
                         pl.published_latitude,
                         pl.published_longitude,
                         pl.office_code,
                         pl.nation_code,
                         pl.nearest_city
                    from at_physical_location pl,
                         at_base_location     bl
                   where bl.base_location_code = pl.base_location_code
                     and pl.location_code in (
                           l_project_loc_code,
                           l_project.pump_back_location_code,
                           l_project.near_gage_location_code)
                ) l
                left outer join
                ( select county_code,
                         county_name,
                         state_initial
                    from cwms_county,
                         cwms_state
                   where cwms_state.state_code = cwms_county.state_code
                ) s on s.county_code = l.county_code
                left outer join cwms_time_zone     tz on tz.time_zone_code = l.time_zone_code
                left outer join cwms_location_kind lk on lk.location_kind_code = l.location_kind
                left outer join cwms_office        o  on o.office_code = l.office_code
                left outer join cwms_nation_sp     n  on n.fips_cntry = l.nation_code
      )
   loop
      l_temp_location_ref := new location_ref_t (
            rec.base_location_id,
            rec.sub_location_id,
            p_db_office_id);
      l_temp_location_obj := new location_obj_t (
            l_temp_location_ref,
            rec.state_initial,
            rec.county_name,
            rec.time_zone_name,
            rec.location_type,
            rec.latitude,
            rec.longitude,
            rec.horizontal_datum,
            rec.elevation * l_factor,
            l_unit,
            rec.vertical_datum,
            rec.public_name,
            rec.long_name,
            rec.description,
            rec.active_flag,
            rec.location_kind_id,
            rec.map_label,
            rec.published_latitude,
            rec.published_longitude,
            rec.bounding_office_id,
            rec.bounding_office_name,
            rec.nation_id,
            rec.nearest_city);
      if rec.location_code = l_project_loc_code then
         l_project_location := l_temp_location_obj;
      elsif rec.location_code = l_project.pump_back_location_code then
         l_pumpback_location := l_temp_location_obj;
      elsif rec.location_code = l_project.near_gage_location_code then
         l_near_gage_location := l_temp_location_obj;
      end if;
   end loop;
   --
   -- create the project object
   --

   p_project := new project_obj_t(               -- TYPE project_obj_t AS OBJECT (
      l_project_location,                        --    project_location               cat_location2_obj_t,
      l_pumpback_location,                       --    pump_back_location           cat_location2_obj_t,
      l_near_gage_location,                      --    near_gage_location          cat_location2_obj_t,
      l_project.authorizing_law,                 --    authorizing_law                VARCHAR2(32),
      l_project.cost_year,                       --    cost_year                      DATE,
      l_project.federal_cost,                    --    federal_cost                   NUMBER,
      l_project.nonfederal_cost,                 --    nonfederal_cost                NUMBER,
      l_project.federal_om_cost,                 --    federal_om_cost                NUMBER,
      l_project.nonfederal_om_cost,              --    nonfederal_om_cost             NUMBER,
      l_project.project_remarks,                 --    remarks                        VARCHAR2(1000),
      l_project.project_owner,                   --    project_owner                  VARCHAR2(255),
      l_project.hydropower_description,          --    hydropower_description         VARCHAR2(255),
      l_project.sedimentation_description,       --    sedimentation_description      VARCHAR(255),
      l_project.downstream_urban_description,    --    downstream_urban_description   VARCHAR(255),
      l_project.bank_full_capacity_description,  --    bank_full_capacity_description VARCHAR(255),
      l_project.yield_time_frame_start,          --    yield_time_frame_start         DATE,
      l_project.yield_time_frame_end);           --    yield_time_frame_end           DATE
END retrieve_project;                            -- );


--stores the data contained within the project object into the database schema
--will this alter the referenced location types?
procedure store_project(
   p_project IN project_obj_t,
   p_fail_if_exists      IN       VARCHAR2 DEFAULT 'T'
)
as
   l_currency_unit           varchar2(16);
   l_project_location_code   number := null;
   l_pump_back_location_code number := null;
   l_near_gage_location_code number := null;
   l_rec                     at_project%rowtype;
   l_exists                  boolean;
BEGIN
   -------------------
   -- sanity checks --
   -------------------
   if p_project is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT');
   end if;
   if p_project.cost_units_id is not null then
      l_currency_unit := cwms_util.get_unit_id(p_project.cost_units_id);
      if l_currency_unit is null then
         cwms_err.raise('INVALID_ITEM', p_project.cost_units_id, 'CWMS unit id');
      end if;
   end if;
   begin
      select unit_id
        into l_currency_unit
        from cwms_unit
       where abstract_param_code = (select abstract_param_code
                                      from cwms_abstract_parameter
                                     where abstract_param_id = 'Currency'
                                   )
         and unit_id = nvl(l_currency_unit, '$');
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_project.cost_units_id, 'currency unit id');
   end;
   --
   -- get the location codes
   --
   l_project_location_code := cwms_loc.store_location_f(p_project.project_location,'F');
   if not cwms_loc.can_store(l_project_location_code, 'PROJECT') then
      cwms_err.raise(
         'ERROR',
         'Cannot store PROJECT information for location '
         ||cwms_util.get_db_office_id(p_project.project_location.location_ref.office_id)
         ||'/'
         ||p_project.project_location.location_ref.get_location_id
         ||' (location kind = '
         ||cwms_loc.check_location_kind(l_project_location_code)
         ||')');
   end if;
   if p_project.pump_back_location is not null then
      l_pump_back_location_code := cwms_loc.store_location_f(p_project.pump_back_location,'F');
   end if;
   if p_project.near_gage_location is not null then
      l_near_gage_location_code := cwms_loc.store_location_f(p_project.near_gage_location,'F');
   end if;

   --
   -- determine whether the project exists
   --
   begin
      select *
       into l_rec
       from at_project
      where project_location_code = l_project_location_code;
      l_exists := true;
   exception
      when no_data_found then
         l_exists := false;
   end;
   --
   -- set the project info
   --
   l_rec.project_location_code          := l_project_location_code;
   l_rec.pump_back_location_code        := l_pump_back_location_code;
   l_rec.near_gage_location_code        := l_near_gage_location_code;
   l_rec.yield_time_frame_start         := p_project.yield_time_frame_start;
   l_rec.yield_time_frame_end           := p_project.yield_time_frame_end;
   l_rec.federal_cost                   := p_project.federal_cost;
   l_rec.nonfederal_cost                := p_project.nonfederal_cost;
   l_rec.cost_year                      := p_project.cost_year;
   l_rec.federal_om_cost                := p_project.federal_om_cost;
   l_rec.nonfederal_om_cost             := p_project.nonfederal_om_cost;
   l_rec.authorizing_law                := p_project.authorizing_law;
   l_rec.project_owner                  := p_project.project_owner;
   l_rec.hydropower_description         := p_project.hydropower_description;
   l_rec.sedimentation_description      := p_project.sedimentation_description;
   l_rec.downstream_urban_description   := p_project.downstream_urban_description;
   l_rec.bank_full_capacity_description := p_project.bank_full_capacity_description;
   l_rec.project_remarks                := p_project.remarks;
   --
   -- store the project
   --
   if l_exists then
      update at_project
         set row = l_rec
       where project_location_code = l_rec.project_location_code;
   else
      insert
        into at_project
      values l_rec;
   end if;
   ---------------------------
   -- set the location kind --
   ---------------------------
   cwms_loc.update_location_kind(l_project_location_code, 'PROJECT', 'A');
END store_project;

-- renames a project from one id to a new one.
procedure rename_project(
   p_project_id_old  IN VARCHAR2,
   p_project_id_new  IN VARCHAR2,
   p_db_office_id    IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
   cwms_loc.rename_location(p_project_id_old, p_project_id_new, p_db_office_id);
END rename_project;
--------------------------------------------------------------------------------
-- procedure delete_project
--------------------------------------------------------------------------------
procedure delete_project(
   p_project_id    in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_db_office_id     in varchar2 default null)
is
begin
   delete_project2(
      p_project_id    => p_project_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_db_office_id);
end delete_project;
--------------------------------------------------------------------------------
-- procedure delete_project2
--------------------------------------------------------------------------------
procedure delete_project2(
   p_project_id               in varchar2,
   p_delete_action            in varchar2 default cwms_util.delete_key,
   p_delete_location          in varchar2 default 'F',
   p_delete_location_action   in varchar2 default cwms_util.delete_key,
   p_delete_assoc_locs        in varchar2 default 'F',
   p_delete_assoc_locs_action in varchar2 default cwms_util.delete_key,
   p_office_id                in varchar2 default null)
is
   l_project_code       number(14);
   l_delete_location    boolean;
   l_delete_assoc_locs  boolean;
   l_delete_action1     varchar2(16);
   l_delete_action2     varchar2(16);
   l_delete_action3     varchar2(16);
   l_project_loc_ref    location_ref_t;
   l_count              pls_integer;
   l_location_kind_id   cwms_location_kind.location_kind_id%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_project_ID');
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
   l_delete_assoc_locs := cwms_util.return_true_or_false(p_delete_assoc_locs);
   if l_delete_assoc_locs then
      l_delete_action3 := upper(substr(p_delete_assoc_locs_action, 1, 16));
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
   end if;
   l_project_code := get_project_code(p_office_id, p_project_id);
   l_location_kind_id := cwms_loc.check_location_kind(l_project_code);
   if l_location_kind_id != 'PROJECT' then
      cwms_err.raise(
         'ERROR',
         'Cannot delete project information from location '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_project_id
         ||' (location kind = '
         ||l_location_kind_id
         ||')');
   end if;
   l_location_kind_id := cwms_loc.can_revert_loc_kind_to(p_project_id, p_office_id); -- revert-to kind
   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
   if l_delete_action1 in (cwms_util.delete_data, cwms_util.delete_all) then
      -----------
      -- pools --
      -----------
      for rec in (select pool_code from at_pool where project_code = l_project_code) loop
         cwms_pool.delete_pool(rec.pool_code);
      end loop;
      -----------------
      -- embankments --
      -----------------
      for rec in
         (select v.db_office_id,
                 v.location_id
            from at_embankment t,
                 av_loc v
           where t.embankment_project_loc_code = l_project_code
             and v.location_code = t.embankment_location_code
             and unit_system = 'EN'
         )
      loop
         cwms_embank.delete_embankment2(
            p_embankment_id          => rec.location_id,
            p_delete_action          => cwms_util.delete_all,
            p_delete_location        => p_delete_assoc_locs,
            p_delete_location_action => l_delete_action3,
            p_office_id              => rec.db_office_id);      end loop;
      -----------
      -- locks --
      -----------
      for rec in
         (select v.db_office_id,
                 v.location_id
            from at_lock t,
                 av_loc v
           where t.project_location_code = l_project_code
             and v.location_code = t.lock_location_code
             and unit_system = 'EN'
         )
      loop
         cwms_lock.delete_lock2(
            p_lock_id                => rec.location_id,
            p_delete_action          => cwms_util.delete_all,
            p_delete_location        => p_delete_assoc_locs,
            p_delete_location_action => l_delete_action3,
            p_office_id              => rec.db_office_id);
      end loop;
      ---------------
      -- overflows --
      ---------------
      for rec in
         (select v.db_office_id,
                 v.location_id
            from at_outlet t1,
                 at_overflow t2,
                 av_loc v
           where t1.project_location_code = l_project_code
             and t2.overflow_location_code = t1.outlet_location_code
             and v.location_code = t1.outlet_location_code
             and unit_system = 'EN'
         )
      loop
         cwms_overflow.delete_overflow(
            p_location_id   => rec.location_id,
            p_delete_action => cwms_util.delete_all,
            p_office_id     => rec.db_office_id);
      end loop;
      -------------
      -- outlets --
      -------------
      for rec in
         (select v.db_office_id,
                 v.location_id
            from at_outlet t,
                 av_loc v
           where t.project_location_code = l_project_code
             and v.location_code = t.outlet_location_code
             and unit_system = 'EN'
         )
      loop
         cwms_outlet.delete_outlet2(
            p_outlet_id              => rec.location_id,
            p_delete_action          => cwms_util.delete_all,
            p_delete_location        => p_delete_assoc_locs,
            p_delete_location_action => l_delete_action3,
            p_office_id              => rec.db_office_id);
      end loop;
      --------------
      -- turbines --
      --------------
      for rec in
         (select v.db_office_id,
                 v.location_id
            from at_turbine t,
                 av_loc v
           where t.project_location_code = l_project_code
             and v.location_code = t.turbine_location_code
             and unit_system = 'EN'
         )
      loop
         cwms_turbine.delete_turbine2(
            p_turbine_id                => rec.location_id,
            p_delete_action          => cwms_util.delete_all,
            p_delete_location        => p_delete_assoc_locs,
            p_delete_location_action => l_delete_action3,
            p_office_id              => rec.db_office_id);
      end loop;
      ------------------
      -- gate changes --
      ------------------
      delete
        from at_gate_change
       where project_location_code = l_project_code;
      ---------------------
      -- turbine changes --
      ---------------------
      delete
        from at_turbine_change
       where project_location_code = l_project_code;
      ----------------------------
      -- construction histories --
      ----------------------------
      delete
        from at_construction_history
       where project_location_code = l_project_code;
      ------------------------
      -- project agreements --
      ------------------------
      delete
        from at_project_agreement
       where project_agreement_loc_code = l_project_code;
      -------------------------------------
      -- project congressional districts --
      -------------------------------------
      delete
        from at_project_congress_district
       where project_congress_location_code = l_project_code;
      ----------------------
      -- project purposes --
      ----------------------
      delete
        from at_project_purpose
       where project_location_code = l_project_code;
      -----------------
      -- water users --
      -----------------
      l_project_loc_ref := location_ref_t(l_project_code);
      for rec in
         (select entity_name
            from at_water_user
           where project_location_code = l_project_code
         )
      loop
         cwms_water_supply.delete_water_user(
            p_project_location_ref => l_project_loc_ref,
            p_entity_name          => rec.entity_name,
            p_delete_action        => cwms_util.delete_all);
      end loop;
   end if;
   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
   if l_delete_action1 in (cwms_util.delete_key, cwms_util.delete_all) then
      delete from at_project where project_location_code = l_project_code;
      cwms_loc.update_location_kind(l_project_code, 'PROJECT', 'D');
   end if;
   -------------------------------------
   -- delete the location if required --
   -------------------------------------
   if l_delete_location then
      cwms_loc.delete_location(p_project_id, l_delete_action2, p_office_id);
   end if;
end delete_project2;

PROCEDURE create_basin_group (
      -- the basin name
      p_loc_group_id      IN   VARCHAR2,
      -- description of the basin
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
AS
BEGIN
  NULL;
END create_basin_group;


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
   )
AS
BEGIN
  NULL;
END rename_basin_group;

  PROCEDURE delete_basin_group (
    -- the location group to delete.
      p_loc_group_id    IN VARCHAR2,
    -- delete_key will fail if there are assigned locations.
    -- delete_all will delete all location assignments, then delete the group.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    -- defaults to the connected user's office if null
      p_db_office_id    IN VARCHAR2 DEFAULT NULL
  )
AS
BEGIN
  NULL;
END delete_basin_group;

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
   )
AS
BEGIN
  NULL;
END assign_basin_group2;

      PROCEDURE assign_basin_groups2 (
     -- the basin location group id
      p_loc_group_id      IN   VARCHAR2,
      -- an array of the location ids and extra data to assign to the specified group.
      p_loc_alias_array   IN   loc_alias_array2,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
AS
BEGIN
  NULL;
END assign_basin_groups2;

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
   )
AS
BEGIN
  NULL;
END unassign_basin_group;

   PROCEDURE unassign_basin_groups (
      -- the basin location group id.
      p_loc_group_id      IN   VARCHAR2,
      -- the array of location ids to remove.
      p_location_array    IN   str_tab_t,
      -- if T, then all assigned locs are removed from the group.
      -- p_location_array needs to be null when the arg is T.
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
AS
BEGIN
  NULL;
END unassign_basin_groups;

function publish_status_update(
   p_project_id     in varchar2,
   p_application_id in varchar2,
   p_source_id      in varchar2 default null,
   p_time_series_id in varchar2 default null,
   p_start_time     in integer  default null,
   p_end_time       in integer  default null,
   p_office_id      in varchar2 default null)
   return integer
is
   l_office_id       varchar2(16);
   l_id              integer;
   l_queue_name      varchar2(61);
   l_text_msg        varchar2(32767);
begin
   ------------------------------
   -- publish the state change --
   ------------------------------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_queue_name  := l_office_id||'_'||'STATUS';
   l_text_msg := '
      <cwms_message type="Status">
         <property name="office"         type="String"> $office                  </property>
         <property name="project"        type="String"> $project                 </property>
         <property name="application"    type="String"> $application             </property>
         <property name="user"           type="String"> $user                    </property>';
   if p_source_id is not null then
      l_text_msg := l_text_msg || '
         <property name="source_id"      type="String"> '|| p_source_id ||'      </property>';
   end if;
   if p_time_series_id is not null then
      l_text_msg := l_text_msg || '
         <property name="time_series_id" type="String"> '|| p_time_series_id ||' </property>';
   end if;
   if p_start_time is not null then
      l_text_msg := l_text_msg || '
         <property name="start_time"     type="long">   '|| p_start_time ||'     </property>';
   end if;
   if p_end_time is not null then
      l_text_msg := l_text_msg || '
         <property name="end_time"       type="long">   '|| p_end_time ||'       </property>';
   end if;
   l_text_msg := l_text_msg || '
      </cwms_message>';
   l_text_msg := replace(l_text_msg, '$office',      l_office_id);
   l_text_msg := replace(l_text_msg, '$project',     dbms_xmlgen.convert(p_project_id));
   l_text_msg := replace(l_text_msg, '$application', dbms_xmlgen.convert(lower(p_application_id)));
   l_text_msg := replace(l_text_msg, '$user',        cwms_util.get_user_id);
   l_id := cwms_msg.publish_message(l_text_msg, l_queue_name, true);
   return cwms_util.to_millis(systimestamp at time zone 'UTC');
end publish_status_update;

function request_lock(
   p_project_id      in varchar2,
   p_application_id  in varchar2,
   p_revoke_existing in varchar2 default 'F',
   p_revoke_timeout  in integer  default 30,
   p_office_id       in varchar2 default null,
   p_username        in varchar2 default null,
   p_osuser          in varchar2 default null,
   p_program         in varchar2 default null,
   p_machine         in varchar2 default null)
   return varchar2
is
   revocation_denied exception;
   already_locked    exception;
   pragma            exception_init(revocation_denied, -20998);
   pragma            exception_init(already_locked,    -00001);
   pragma            autonomous_transaction;

   l_lock_id         varchar2(40);
   l_do_lock         boolean := true;
   l_username        varchar2(30);
   l_osuser          varchar2(30);
   l_program         varchar2(64);
   l_machine         varchar2(64);
   l_office_id       varchar2(16);
   l_already_locked  boolean := false;
   l_id              integer;
   l_queue_name      varchar2(61);
   l_text_msg        varchar2(32767);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_revoke_existing is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_revoke_existing');
   end if;
   if p_revoke_timeout is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_revoke_timeout');
   end if;
   -----------------
   -- do the work --
   -----------------
   if is_locked(p_project_id, p_application_id, p_office_id) = 'T' then
      if p_revoke_existing in ('T', 't') then
         begin
            revoke_lock(
               p_project_id,
               p_application_id,
               p_revoke_timeout,
               p_office_id);
         exception
            when revocation_denied then l_do_lock := false;
         end;
      else
         l_do_lock := false;
      end if;
   end if;
   if l_do_lock then
      l_lock_id := rawtohex(sys_guid());

      if p_username is null or p_osuser is null or p_program is null or p_machine is null then
         select username,
                osuser,
                program,
                machine
         into l_username,
            l_osuser,
            l_program,
            l_machine
         from v$session
         where sid = sys_context('userenv', 'sid');
      end if;

      l_username := nvl(p_username, l_username);
      l_osuser :=  nvl(p_osuser, l_osuser);
      l_program := nvl(p_program, l_program);
      l_machine := nvl(p_machine, l_machine);

      begin
         insert
           into at_project_lock
                ( lock_id,
                  project_code,
                  application_id,
                  acquire_time,
                  session_user,
                  os_user,
                  session_program,
                  session_machine
                )
         values ( l_lock_id,
                  cwms_loc.get_location_code(p_office_id, p_project_id),
                  lower(p_application_id),
                  systimestamp at time zone 'UTC',
                  l_username,
                  l_osuser,
                  l_program,
                  l_machine
                );
      exception
         when already_locked then
            ----------------------------------------------
            -- encountered a race condition and another --
            -- lock attempt beat us to the punch        --
            ----------------------------------------------
            l_already_locked := true;
      end;
      if l_already_locked then
         l_lock_id := null;
      else
         commit;
         ------------------------------
         -- publish the state change --
         ------------------------------
         l_office_id := cwms_util.get_db_office_id(p_office_id);
         l_queue_name  := l_office_id||'_'||'STATUS';
         l_text_msg := '
            <cwms_message type="State">
               <property name="new state"   type="String"> locked        </property>
               <property name="old state"   type="String"> unlocked      </property>
               <property name="action"      type="String"> lock acquired </property>
               <property name="office"      type="String"> $office       </property>
               <property name="project"     type="String"> $project      </property>
               <property name="application" type="String"> $application  </property>
               <property name="user"        type="String"> $user         </property>
            </cwms_message>';
         l_text_msg := replace(l_text_msg, '$office',      l_office_id);
         l_text_msg := replace(l_text_msg, '$project',     dbms_xmlgen.convert(p_project_id));
         l_text_msg := replace(l_text_msg, '$application', dbms_xmlgen.convert(lower(p_application_id)));
         l_text_msg := replace(l_text_msg, '$user',        cwms_util.get_user_id);
         l_id := cwms_msg.publish_message(l_text_msg, l_queue_name, true);
      end if;
   end if;
   return l_lock_id;
end request_lock;

procedure release_lock(
   p_lock_id in varchar2)
is
   pragma autonomous_transaction;
   l_text_msg   varchar2(32767);
   l_lock_rec   at_project_lock%rowtype;
   l_office_id  varchar2(16);
   l_project_id varchar2(16);
   l_id         integer;
   l_queue_name varchar2(61);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_lock_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_lock_id');
   end if;
   -----------------
   -- do the work --
   -----------------
   begin
      select *
        into l_lock_rec
        from at_project_lock
       where lock_id = p_lock_id;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_lock_id, 'CWMS Project lock identifier');
   end;
   delete
     from at_project_lock
    where lock_id = p_lock_id;
   commit;
   ------------------------------
   -- publish the state change --
   ------------------------------
   select o.office_id,
          cwms_loc.get_location_id(l_lock_rec.project_code)
     into l_office_id,
          l_project_id
     from at_physical_location pl,
          at_base_location bl,
          cwms_office o
    where pl.location_code = l_lock_rec.project_code
      and bl.base_location_code = pl.base_location_code
      and o.office_code = bl.db_office_code;
   l_queue_name  := l_office_id||'_'||'STATUS';
   l_text_msg := '
      <cwms_message type="State">
         <property name="new state"   type="String"> unlocked      </property>
         <property name="old state"   type="String"> locked        </property>
         <property name="action"      type="String"> lock released </property>
         <property name="office"      type="String"> $office       </property>
         <property name="project"     type="String"> $project      </property>
         <property name="application" type="String"> $application  </property>
         <property name="user"        type="String"> $user         </property>
      </cwms_message>';
   l_text_msg := replace(l_text_msg, '$office',      l_office_id);
   l_text_msg := replace(l_text_msg, '$project',     dbms_xmlgen.convert(l_project_id));
   l_text_msg := replace(l_text_msg, '$application', dbms_xmlgen.convert(l_lock_rec.application_id));
   l_text_msg := replace(l_text_msg, '$user',        cwms_util.get_user_id);
   l_id := cwms_msg.publish_message(l_text_msg, l_queue_name, true);
end release_lock;

function has_revoker_rights (
   p_project_id     in varchar2,
   p_application_id in varchar2,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null,
   p_office_code    in number   default null)
   return varchar2
is
   l_application_id     varchar2(64) := lower(p_application_id);
   l_user_id            varchar2(30) := lower(nvl(p_user_id, cwms_util.get_user_id));
   l_office_code        number(14)   := nvl(p_office_code, cwms_util.get_db_office_code(p_office_id));
   l_project_id         varchar2(57) := lower(cwms_loc.get_location_id(p_project_id, l_office_code));
   l_project_list       varchar2(256);
   l_parts              str_tab_t;
   l_has_revoker_rights varchar2(1) := 'F';
begin
   ------------------------------------
   -- compare against the ALLOW list --
   ------------------------------------
   begin
      select lower(project_list)
        into l_project_list
        from at_prj_lck_revoker_rights
       where user_id = l_user_id
         and office_code = l_office_code
         and application_id = lower(l_application_id)
         and allow_flag = 'T';

      l_parts := cwms_util.split_text(l_project_list, ',');
      for i in 1..l_parts.count loop
         if l_project_id like cwms_util.normalize_wildcards(trim(l_parts(i))) escape '\' then
            l_has_revoker_rights := 'T';
            exit;
         end if;
      end loop;
   exception
      when no_data_found then null;
   end;
   ---------------------------------------
   -- compare against the DISALLOW list --
   ---------------------------------------
   if l_has_revoker_rights = 'T' then
      begin
         select lower(project_list)
           into l_project_list
           from at_prj_lck_revoker_rights
          where user_id = l_user_id
            and office_code = l_office_code
            and application_id = lower(l_application_id)
            and allow_flag = 'F';

         l_parts := cwms_util.split_text(l_project_list, ',');
         for i in 1..l_parts.count loop
            if l_project_id like cwms_util.normalize_wildcards(trim(l_parts(i))) escape '\' then
               l_has_revoker_rights := 'F';
               exit;
            end if;
         end loop;
      exception
         when no_data_found then null;
      end;
   end if;

   return l_has_revoker_rights;
end has_revoker_rights;

procedure revoke_lock(
   p_project_id      in varchar2,
   p_application_id  in varchar2,
   p_revoke_timeout  in integer  default 30,
   p_office_id       in varchar2 default null)
is
   no_messages    exception;
   pragma         exception_init(no_messages, -25228);
   pragma         autonomous_transaction;
   l_office_id    varchar2(16);
   l_text_msg     varchar2(32767);
   l_id           integer;
   l_start_time   date;
   l_end_time     date;
   l_queue_name   varchar2(61);
   l_subscriber   varchar2(30) := dbms_random.string('l', 16);
   l_dequeue_opts dbms_aq.dequeue_options_t;
   l_msg_props    dbms_aq.message_properties_t;
   l_msg          sys.aq$_jms_map_message;
   l_msgid        raw(16);
   l_denied       boolean := false;
   l_released     boolean := false;

   function get_string(
      p_message   in out nocopy sys.aq$_jms_map_message,
      p_msgid     in integer,
      p_item_name in varchar2,
      p_max_len   in integer)
   return varchar2
   is
      l_clob clob;
      l_text varchar2(32767);
   begin
      begin
         p_message.get_string(p_msgid, p_item_name, l_clob);
         if l_clob is not null then
            l_text := dbms_lob.substr(l_clob, p_max_len, 1);
         end if;
      exception
         when others then null;
      end;
      return l_text;
   end;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_id');
   end if;
   if p_application_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_application_id');
   end if;
   if cwms_project.is_locked(p_project_id, p_application_id, p_office_id) = 'T' then
      if has_revoker_rights(
         p_project_id     => p_project_id,
         p_application_id => p_application_id,
         p_office_id      => p_office_id) = 'F'
      then
         cwms_err.raise(
            'ERROR',
            'User '
            ||cwms_util.get_user_id
            ||' does not have project lock revoker rights for project='
            ||p_project_id
            ||', application='
            ||p_application_id
            ||' at office '
            ||cwms_util.get_db_office_id(p_office_id));
      end if;
   end if;
   ---------------------------------
   -- publish the request message --
   ---------------------------------
   l_office_id   := cwms_util.get_db_office_id(p_office_id);
   l_queue_name  := l_office_id||'_'||'STATUS';
   l_start_time  := cast(systimestamp at time zone 'UTC' as date);
   l_end_time    := l_start_time + p_revoke_timeout / 86400;
   l_text_msg := '
      <cwms_message type="RequestAction">
         <property name="action"      type="String">unlock project</property>
         <property name="office"      type="String">$office       </property>
         <property name="project"     type="String">$project      </property>
         <property name="application" type="String">$application  </property>
         <property name="user"        type="String">$user         </property>
         <property name="force_time"  type="long">  $deadline     </property>
      </cwms_message>';
   l_text_msg := replace(l_text_msg, '$office',      l_office_id);
   l_text_msg := replace(l_text_msg, '$project',     dbms_xmlgen.convert(p_project_id));
   l_text_msg := replace(l_text_msg, '$application', dbms_xmlgen.convert(lower(p_application_id)));
   l_text_msg := replace(l_text_msg, '$user',        cwms_util.get_user_id);
   l_text_msg := replace(l_text_msg, '$deadline',    to_char(cwms_util.to_millis(l_end_time)));
   l_id := cwms_msg.publish_message(l_text_msg, l_queue_name, true);
   -------------------------------------------------------------
   -- wait for project to be unlocked or for a denial message --
   -------------------------------------------------------------
   l_queue_name := ' CWMS_20.'||l_queue_name;
   dbms_aqadm.add_subscriber(
      queue_name => l_queue_name,
      subscriber => sys.aq$_agent(l_subscriber, null, null));
   l_dequeue_opts.consumer_name := l_subscriber;
   l_dequeue_opts.navigation    := dbms_aq.first_message;
   l_dequeue_opts.visibility    := dbms_aq.immediate;
   l_dequeue_opts.wait          := dbms_aq.no_wait;
   loop
      loop
         l_msg := null;
         begin
            dbms_aq.dequeue(
               queue_name         => l_queue_name,
               dequeue_options    => l_dequeue_opts,
               message_properties => l_msg_props,
               payload            => l_msg,
               msgid              => l_msgid);
         exception
            when no_messages then null;
         end;
         exit when l_msg is null;
         l_id := l_msg.prepare(-1);
         if upper(get_string(l_msg, l_id, 'type',        32)) = 'ACKNOWLEDGEREQUEST'   and
            upper(get_string(l_msg, l_id, 'response',    32)) = 'REQUEST DENIED'       and
            upper(get_string(l_msg, l_id, 'office',      16)) = upper(l_office_id)     and
            upper(get_string(l_msg, l_id, 'project',     57)) = upper(p_project_id)    and
            upper(get_string(l_msg, l_id, 'application', 64)) = upper(p_application_id)
         then
            l_denied := true;
            exit;
         end if;
         l_msg.clean(l_id);
      end loop;
      l_released := is_locked(p_project_id, p_application_id, l_office_id) = 'F';
      exit when l_denied or l_released or cast(systimestamp at time zone 'UTC' as date) >= l_end_time;
      dbms_lock.sleep(1);
   end loop;
   dbms_aqadm.remove_subscriber(
      queue_name => l_queue_name,
      subscriber => sys.aq$_agent(l_subscriber, null, null));
   l_queue_name := substr(l_queue_name, instr(l_queue_name, '.') + 1);
   --------------------------------------------------------
   -- finally, revoke the lock if not denied or released --
   --------------------------------------------------------
   if l_denied then
      cwms_err.raise('ERROR', 'Revocation denied.');
   else
      if not l_released then
         begin
            delete
              from at_project_lock
             where project_code = cwms_loc.get_location_code(l_office_id, p_project_id)
               and application_id = lower(p_application_id);
            commit;
            l_text_msg := '
               <cwms_message type="State">
                  <property name="new state"   type="String"> unlocked      </property>
                  <property name="old state"   type="String"> locked        </property>
                  <property name="action"      type="String"> lock revoked  </property>
                  <property name="office"      type="String"> $office       </property>
                  <property name="project"     type="String"> $project      </property>
                  <property name="application" type="String"> $application  </property>
                  <property name="user"        type="String"> $user         </property>
               </cwms_message>';
            l_text_msg := replace(l_text_msg, '$office',      l_office_id);
            l_text_msg := replace(l_text_msg, '$project',     dbms_xmlgen.convert(p_project_id));
            l_text_msg := replace(l_text_msg, '$application', dbms_xmlgen.convert(lower(p_application_id)));
            l_text_msg := replace(l_text_msg, '$user',        cwms_util.get_user_id);
            l_id := cwms_msg.publish_message(l_text_msg, l_queue_name, true);
         exception
            when no_data_found then null; -- other user unlocked after our last check
         end;
      end if;
   end if;
end revoke_lock;

procedure deny_lock_revocation(
   p_lock_id in varchar2)
is
   l_lock_rec at_project_lock%rowtype;
   l_msg        varchar2(32767);
   l_office_id  varchar2(16);
   l_project_id varchar2(16);
   l_id         integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_lock_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_lock_id');
   end if;
   -----------------
   -- do the work --
   -----------------
   begin
      select *
        into l_lock_rec
        from at_project_lock
       where lock_id = p_lock_id;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_lock_id, 'CWMS Project lock identifier');
   end;
   select o.office_id,
          cwms_loc.get_location_id(l_lock_rec.project_code)
     into l_office_id,
          l_project_id
     from at_physical_location pl,
          at_base_location bl,
          cwms_office o
    where pl.location_code = l_lock_rec.project_code
      and bl.base_location_code = pl.base_location_code
      and o.office_code = bl.db_office_code;

   l_msg := '
      <cwms_message type="AcknowledgeRequest">
         <property name="action"      type="String">unlock project</property>
         <property name="response"    type="String">request denied</property>
         <property name="office"      type="String">$office       </property>
         <property name="project"     type="String">$project      </property>
         <property name="application" type="String">$application  </property>
         <property name="user"        type="String">$user         </property>
      </cwms_message>';
   l_msg := replace(l_msg, '$office',      l_office_id);
   l_msg := replace(l_msg, '$project',     dbms_xmlgen.convert(l_project_id));
   l_msg := replace(l_msg, '$application', dbms_xmlgen.convert(l_lock_rec.application_id));
   l_msg := replace(l_msg, '$user',        l_lock_rec.os_user);
   l_id := cwms_msg.publish_message(l_msg, l_office_id||'_'||'STATUS', true);

end deny_lock_revocation;

function is_locked(
   p_project_id      in varchar2,
   p_application_id  in varchar2,
   p_office_id       in varchar2 default null)
   return varchar2
is
   l_count pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_id');
   end if;
   if p_application_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_application_id');
   end if;
   -----------------
   -- do the work --
   -----------------
   select count(*)
     into l_count
     from at_project_lock
    where project_code = cwms_loc.get_location_code(p_office_id, p_project_id)
      and application_id = lower(p_application_id);

   return case l_count when 0 then 'F' else 'T' end;
end is_locked;

procedure cat_locks(
   p_cursor              out sys_refcursor,
   p_project_id_mask     in  varchar2 default '*',
   p_application_id_mask in  varchar2 default '*',
   p_time_zone           in  varchar2 default 'UTC',
   p_office_id_mask      in  varchar2 default null)
is
begin
   p_cursor := cat_locks_f(
      p_project_id_mask,
      p_application_id_mask,
      p_time_zone,
      p_office_id_mask);
end cat_locks;

function cat_locks_f(
   p_project_id_mask     in varchar2 default '*',
   p_application_id_mask in varchar2 default '*',
   p_time_zone           in varchar2 default 'UTC',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor
is
   l_cursor         sys_refcursor;
   l_office_id_mask varchar2(16);
begin
   l_office_id_mask := nvl(p_office_id_mask, cwms_util.user_office_id);
   open l_cursor for
      select o.office_id,
             cwms_loc.get_location_id(lck.project_code) as project_id,
             lck.application_id,
             cwms_util.get_xml_time(
                cwms_util.change_timezone(lck.acquire_time, 'UTC', p_time_zone),
                p_time_zone) as acquire_time,
             lck.session_user,
             lck.os_user,
             lck.session_program,
             lck.session_machine
        from at_project_lock lck,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where lower(cwms_loc.get_location_id(lck.project_code)) like cwms_util.normalize_wildcards(lower(p_project_id_mask)) escape '\'
         and lck.application_id like cwms_util.normalize_wildcards(lower(p_application_id_mask))  escape '\'
         and o.office_id like cwms_util.normalize_wildcards(upper(l_office_id_mask))  escape '\'
         and pl.location_code = lck.project_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
   return l_cursor;
end cat_locks_f;

procedure update_lock_revoker_rights(
   p_user_id        in varchar2,
   p_project_ids    in varchar2,
   p_allow          in varchar2,
   p_application_id in varchar2,
   p_office_id      in varchar2 default null)
is
   type l_user_t is table of boolean index by varchar2(30);
   l_cwms_users     l_user_t;
   l_user_id        varchar2(30);
   l_allow          varchar2(1);
   l_application_id varchar2(64);
   l_office_code    number(14);
   l_count          pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_user_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_user_id');
   else
      l_user_id := lower(p_user_id);
      for rec in (select lower(grantee) as cwms_user
                    from dba_role_privs
                   where granted_role = 'CWMS_USER'
                 )
      loop
         l_cwms_users(rec.cwms_user) := true;
      end loop;
      if not l_cwms_users.exists(l_user_id) then
         cwms_err.raise('ERROR', 'User '||p_user_id||' is not a CWMS user.');
      end if;
   end if;
   if p_project_ids is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_ids');
   end if;
   if p_allow is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_allow');
   elsif p_allow not in ('T','t','F','f') then
      cwms_err.raise('ERROR', 'Parameter p_allow must be ''T'' or ''F''');
   end if;
   if p_application_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_application_id');
   end if;
   -----------------
   -- do the work --
   -----------------
   l_allow          := upper(p_allow);
   l_application_id := lower(p_application_id);
   l_office_code    := cwms_util.get_db_office_code(p_office_id);

   if p_project_ids = '*' and l_allow = 'F' then
      begin
         delete
           from at_prj_lck_revoker_rights
          where user_id = l_user_id
            and office_code = l_office_code
            and application_id = l_application_id;
      exception
        when no_data_found then null;
      end;
   else
     select count(*)
       into l_count
       from at_prj_lck_revoker_rights
      where user_id        = l_user_id
        and office_code    = l_office_code
        and application_id = l_application_id
        and allow_flag     = l_allow;
      if l_count = 0 then
        insert
          into at_prj_lck_revoker_rights
               (user_id,
                office_code,
                application_id,
                allow_flag,
                project_list
               )
        values (l_user_id,
                l_office_code,
                l_application_id,
                l_allow,
                p_project_ids
               );
      else
         update at_prj_lck_revoker_rights
            set project_list   = p_project_ids
          where user_id        = l_user_id
            and office_code    = l_office_code
            and application_id = l_application_id
            and allow_flag     = l_allow;
      end if;
   end if;
end update_lock_revoker_rights;

procedure cat_lock_revoker_rights(
   p_cursor              out sys_refcursor,
   p_project_id_mask     in  varchar2 default '*',
   p_application_id_mask in  varchar2 default '*',
   p_office_id_mask      in  varchar2 default null)
is
begin
   p_cursor := cat_lock_revoker_rights_f(
      p_project_id_mask,
      p_application_id_mask,
      p_office_id_mask);
end cat_lock_revoker_rights;

function cat_lock_revoker_rights_f(
   p_project_id_mask     in varchar2 default '*',
   p_application_id_mask in varchar2 default '*',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor
is
   l_cursor              sys_refcursor;
   l_project_id_mask     varchar2(256) := lower(cwms_util.normalize_wildcards(p_project_id_mask));
   l_application_id_mask varchar2(64)  := lower(cwms_util.normalize_wildcards(p_application_id_mask));
   l_office_id_mask      varchar2(16)  := upper(nvl(cwms_util.normalize_wildcards(p_office_id_mask), cwms_util.get_db_office_id));
begin
   open l_cursor for
      select o.office_id,
             bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id as project_id,
             r.application_id,
             r.user_id
        from at_prj_lck_revoker_rights r,
             at_project p,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where lower(bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id) like l_project_id_mask escape '\'
         and r.application_id like l_application_id_mask escape '\'
         and o.office_id like l_office_id_mask escape '\'
         and r.allow_flag = 'T'
         and pl.location_code = p.project_location_code
         and bl.base_location_code = pl.base_location_code
         and bl.db_office_code = r.office_code
         and o.office_code = r.office_code
         and cwms_project.has_revoker_rights(
                p_project_id     => bl.base_location_id
                                    ||substr('-', 1, length(pl.sub_location_id))
                                    ||pl.sub_location_id,
                p_application_id => r.application_id,
                p_user_id        => r.user_id,
                p_office_code    => r.office_code) = 'T';
   return l_cursor;
end cat_lock_revoker_rights_f;

procedure store_project_purpose(
   p_project_code   in integer,
   p_purpose_code   in integer,
   p_purpose_type   in varchar2,
   p_notes          in varchar2 default null,
   p_fail_if_exists in varchar2 default 'T',
   p_ignore_nulls   in varchar2 default 'T')
is
   l_exists         boolean;
   l_fail_if_exists boolean := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls   boolean := cwms_util.is_true(p_ignore_nulls);
   l_rec at_project_purpose%rowtype;
   l_purpose        varchar2(25);
   l_office_id      varchar2(16);
   l_project_id     varchar2(57);
begin
   begin
      select *
        into l_rec
        from at_project_purpose
       where project_location_code = p_project_code
         and project_purpose_code  = p_purpose_code;

      l_exists := true;
   exception
      when no_data_found then l_exists := false;
   end;
   if l_exists then
      if l_fail_if_exists then
         select purpose_display_value
           into l_purpose
           from av_project_purposes
          where purpose_code = p_purpose_code;

         select db_office_id,
                location_id
           into l_office_id,
                l_project_id
           from av_loc
          where location_code = p_project_code;

         if l_fail_if_exists then
            cwms_err.raise(
               'ERROR',
               'Purpose '
               ||l_purpose
               ||' already exists for project '
               ||l_office_id||'/'||l_project_id);
         end if;
      end if;
      --------------------
      -- update purpose --
      --------------------
      if l_ignore_nulls then
         l_rec.purpose_type := nvl(l_purpose, l_rec.purpose_type);
         l_rec.additional_notes := nvl(p_notes, l_rec.additional_notes);
      else
         l_rec.purpose_type := upper(trim(p_purpose_type));
         l_rec.additional_notes := trim(p_notes);
      end if;
      update at_project_purpose
         set row = l_rec
       where project_location_code = l_rec.project_location_code
         and project_purpose_code  = l_rec.project_purpose_code;
   else
      --------------------
      -- insert purpose --
      --------------------
      l_rec.project_location_code := p_project_code;
      l_rec.project_purpose_code  := p_purpose_code;
      l_rec.purpose_type := upper(trim(p_purpose_type));
      l_rec.additional_notes := trim(p_notes);
      insert
        into at_project_purpose
      values l_rec;
   end if;
end store_project_purpose;

procedure store_project_purpose(
   p_project_id            in varchar2,
   p_purpose_display_value in varchar2,
   p_purpose_type          in varchar2,
   p_notes                 in varchar2 default null,
   p_fail_if_exists        in varchar2 default 'T',
   p_ignore_nulls          in varchar2 default 'T',
   p_office_id             in varchar2 default null)
is
   l_office_code  integer;
   l_project_code integer;
   l_purpose_code integer;
begin
   l_office_code  := cwms_util.get_office_code(p_office_id);
   l_project_code := cwms_loc.get_location_code(l_office_code, p_project_id);

   select purpose_code
     into l_purpose_code
     from at_project_purposes
    where upper(purpose_display_value) = upper(trim(p_purpose_display_value))
      and db_office_code in (l_office_code, cwms_util.db_office_code_all);

   store_project_purpose(
      l_project_code,
      l_purpose_code,
      p_purpose_type,
      p_notes,
      p_fail_if_exists,
      p_ignore_nulls);
end store_project_purpose;

procedure delete_project_purpose(
   p_project_code in integer,
   p_purpose_code in integer)
is
begin
   delete
     from at_project_purpose
    where project_location_code = p_project_code
      and project_purpose_code = p_purpose_code;
end delete_project_purpose;

procedure delete_project_purpose(
   p_project_id            in varchar2,
   p_purpose_display_value in varchar2,
   p_office_id             in varchar2 default null)
is
   l_office_code  integer;
   l_project_code integer;
   l_purpose_code integer;
begin
   l_office_code  := cwms_util.get_office_code(p_office_id);
   l_project_code := cwms_loc.get_location_code(l_office_code, p_project_id);

   select purpose_code
     into l_purpose_code
     from at_project_purposes
    where upper(purpose_display_value) = upper(trim(p_purpose_display_value))
      and db_office_code in (l_office_code, cwms_util.db_office_code_all);

   delete
     from at_project_purpose
    where project_location_code = l_project_code
      and project_purpose_code = l_purpose_code;
end delete_project_purpose;

END CWMS_PROJECT;

/
show errors;
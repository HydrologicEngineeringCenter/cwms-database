WHENEVER sqlerror exit sql.sqlcode
SET serveroutput on


create or replace
PACKAGE BODY CWMS_PROJECT AS

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
             bl.base_location_id     base_location_id,   -- base_location_id  varchar2(16)  base location id
             pl.sub_location_id      sub_location_id,    -- sub_location_id   varchar2(32)  sub-location id, if any
             tz.time_zone_name       time_zone_name,     -- time_zone_name    varchar2(28)  local time zone name for location
             pl.latitude             latitude,           -- latitude          number        location latitude
             pl.longitude            longitude,          -- longitude         number        location longitude
             pl.horizontal_datum     horizontal_datum,   -- horizontal_datum  varchar2(16)  horizontal datrum of lat/lon
             pl.elevation * l_factor elevation,          -- elevation         number        location elevation
             l_unit                  elev_unit_id,       -- elev_unit_id      varchar2(16)  location elevation units
             pl.vertical_datum       vertical_datum,     -- vertical_datum    varchar2(16)  veritcal datum of elevation
             pl.public_name          public_name,        -- public_name       varchar2(32)  location public name
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
         and pl.time_zone_code     = tz.time_zone_code
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
   l_parts                          str_tab_t;
   l_base_loc_id                    varchar2(16);
   l_sub_loc_id                     varchar2(32);
   l_project                        at_project%rowtype;
   l_project_location               location_obj_t := null;
   l_db_office_id                   varchar2(16);
   l_authorizing_law                varchar2(32);
   l_federal_cost                   number;
   l_nonfederal_cost                number;
   l_cost_year                      date;
   l_federal_om_cost                number;
   l_nonfederal_om_cost             number;
   l_remarks                        varchar2(1000);
   l_project_owner                  varchar2(255);
   l_hydropower_description         varchar2(255);
   l_pumpback_location              location_obj_t := null;
   l_near_gage_location             location_obj_t := null;
   l_sedimentation_description      varchar(255);
   l_downstream_urban_description   varchar(255);
   l_bank_full_capacity_descr       varchar(255);
   l_yield_time_frame_start         date;
   l_yield_time_frame_end           date;
   l_factor                         number;
   l_unit                           varchar2(16);
   l_temp_location_obj              location_obj_t := null;
   l_temp_location_ref              location_ref_t := null;
begin
   --
   -- get the location code
   --
   l_parts := cwms_util.split_text(p_project_id, '-', 1);
   l_base_loc_id := l_parts(1);
   l_sub_loc_id :=
      case l_parts.count = 1
         when true  then null
         when false then l_parts(2)
      end;
   begin
      select location_code
        into l_project_loc_code
        from at_physical_location pl,
             at_base_location bl
       where upper(bl.base_location_id) = upper(l_base_loc_id)
         and pl.base_location_code = bl.base_location_code
         and upper(nvl(pl.sub_location_id, '-')) = upper(nvl(l_sub_loc_id, '-'));
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_project_id, 'location id');
   end;
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
         cwms_err.raise('INVALID_ITEM', p_project_id, 'project id');
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
   for rec in (
      select pl.location_code                      location_code,
             bl.base_location_id                   base_location_id,
             pl.sub_location_id                    sub_location_id,
             case
               when pl.county_code is null then null
               else s.state_initial
             end                                   state_initial,
             case
               when pl.county_code is null then null
               else c.county_name
             end                                   county_name,
             case
               when tz.time_zone_code is null then null
               else tz.time_zone_name
             end                                   time_zone_name,
             pl.location_type                      location_type,
             pl.latitude                           latitude,
             pl.longitude                          longitude,
             pl.horizontal_datum                   horizontal_datum,
             pl.elevation                          elevation,
             pl.vertical_datum                     vertical_datum,
             pl.public_name                        public_name,
             pl.long_name                          long_name,
             pl.description                        description,
             pl.active_flag                        active_flag,
             case
               when pl.location_kind is null then null
               else lk.location_kind_id
             end                                   location_kind_id,
             pl.map_label                          map_label,
             pl.published_latitude                 published_latitude,
             pl.published_longitude                published_longitude,
             case
               when pl.office_code is null then null
               else o.office_id
             end                                   bounding_office_id,
          case
               when pl.office_code is null then null
               else o.public_name
             end                                   bounding_office_name,
             case
               when pl.nation_code is null then null
               else n.nation_id
             end                                   nation_id,
             pl.nearest_city                       nearest_city
        from at_physical_location pl,
             at_base_location     bl,
             at_location_kind     lk,
             cwms_time_zone       tz,
             cwms_county          c,
             cwms_state           s,
             cwms_nation          n,
             cwms_office          o
       where bl.base_location_code = pl.base_location_code
         and (
               pl.county_code is null or
               (
                 s.state_code = c.state_code and
                 c.county_code = pl.county_code
               )
             )
         and (
               pl.time_zone_code is null or
               tz.time_zone_code = pl.time_zone_code
             )
         and (
               pl.location_kind is null or
               lk.location_kind_code = pl.location_kind
             )
         and (
               pl.office_code is null or
               o.office_code = pl.office_code
             )
         and (
               pl.nation_code is null or
               n.nation_code = pl.nation_code
             )
         and pl.location_code in (
               l_project_loc_code,
               l_project.pump_back_location_code,
               l_project.near_gage_location_code))
   loop
      l_temp_location_ref := new location_ref_t (
            rec.base_location_id,
            rec.sub_location_id,
            p_db_office_id
     );
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
      null, -- cost units.
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
AS
   l_project_location_code   number := null;
   l_pump_back_location_code number := null;
   l_near_gage_location_code number := null;
   l_rec                     at_project%rowtype;
   l_exists                  boolean;
BEGIN
   --
   -- create or update the locations
   --
   -- note - the ignore_nulls parameter is set to 'T' on the following
   --        calls, so if you don't want to overwrite any location info
   --        just set everything exception location_id and db_office_id
   --       to null in the location objects
   --
   cwms_loc.store_location2(
      p_project.project_location.location_ref.get_location_id(),
      p_project.project_location.location_type,
      p_project.project_location.elevation,
      p_project.project_location.elev_unit_id,
      p_project.project_location.vertical_datum,
      p_project.project_location.latitude,
      p_project.project_location.longitude,
      p_project.project_location.horizontal_datum,
      p_project.project_location.public_name,
      p_project.project_location.long_name,
      p_project.project_location.description,
      p_project.project_location.time_zone_name,
      p_project.project_location.county_name,
      p_project.project_location.state_initial,
      p_project.project_location.active_flag,
      p_project.project_location.location_kind_id,
      p_project.project_location.map_label,
      p_project.project_location.published_latitude,
      p_project.project_location.published_longitude,
      p_project.project_location.bounding_office_id,
      p_project.project_location.nation_id,
      p_project.project_location.nearest_city,
      'T',
      p_project.project_location.location_ref.office_id);
   if p_project.pump_back_location is not null then
      cwms_loc.store_location2(
         p_project.pump_back_location.location_ref.get_location_id(),
         p_project.pump_back_location.location_type,
         p_project.pump_back_location.elevation,
         p_project.pump_back_location.elev_unit_id,
         p_project.pump_back_location.vertical_datum,
         p_project.pump_back_location.latitude,
         p_project.pump_back_location.longitude,
       p_project.pump_back_location.horizontal_datum,
       p_project.pump_back_location.public_name,
         p_project.pump_back_location.long_name,
         p_project.pump_back_location.description,
         p_project.pump_back_location.time_zone_name,
         p_project.pump_back_location.county_name,
         p_project.pump_back_location.state_initial,
         p_project.pump_back_location.active_flag,
         p_project.pump_back_location.location_kind_id,
         p_project.pump_back_location.map_label,
         p_project.pump_back_location.published_latitude,
         p_project.pump_back_location.published_longitude,
         p_project.pump_back_location.bounding_office_id,
         p_project.pump_back_location.nation_id,
         p_project.pump_back_location.nearest_city,
         'T',
         p_project.pump_back_location.location_ref.office_id);
   end if;
   if p_project.near_gage_location is not null then
      cwms_loc.store_location2(
         p_project.near_gage_location.location_ref.get_location_id(),
         p_project.near_gage_location.location_type,
         p_project.near_gage_location.elevation,
         p_project.near_gage_location.elev_unit_id,
         p_project.near_gage_location.vertical_datum,
         p_project.near_gage_location.latitude,
         p_project.near_gage_location.longitude,
         p_project.near_gage_location.horizontal_datum,
         p_project.near_gage_location.public_name,
         p_project.near_gage_location.long_name,
         p_project.near_gage_location.description,
         p_project.near_gage_location.time_zone_name,
         p_project.near_gage_location.county_name,
         p_project.near_gage_location.state_initial,
         p_project.near_gage_location.active_flag,
         p_project.near_gage_location.location_kind_id,
         p_project.near_gage_location.map_label,
         p_project.near_gage_location.published_latitude,
         p_project.near_gage_location.published_longitude,
         p_project.near_gage_location.bounding_office_id,
         p_project.near_gage_location.nation_id,
         p_project.near_gage_location.nearest_city,
         'T',
         p_project.near_gage_location.location_ref.office_id);
   end if;
   --
   -- get the location codes
   --
   l_project_location_code := cwms_loc.get_location_code(
      p_project.project_location.location_ref.office_id,
      p_project.project_location.location_ref.get_location_id());
   if p_project.pump_back_location is not null then
      l_pump_back_location_code := cwms_loc.get_location_code(
         p_project.pump_back_location.location_ref.office_id,
         p_project.pump_back_location.location_ref.get_location_id());
   end if;
   if p_project.near_gage_location is not null then
      l_near_gage_location_code := cwms_loc.get_location_code(
         p_project.near_gage_location.location_ref.office_id,
         p_project.near_gage_location.location_ref.get_location_id());
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

-- deletes a project, this does not affect any of the location code data.
procedure delete_project(
      p_project_id      IN VARCHAR2,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_key, 
      p_db_office_id    IN VARCHAR2 DEFAULT NULL
   )
AS
   type cat_rec_t is record(
      project_office_id  varchar2(16),
      project_id         varchar2(49),
      office_id          varchar2(16),
      base_location_id   varchar2(16),
      sub_location_id    varchar2(32),
      time_zone_id       varchar2(28),
      latitude           number,
      longitude          number,
      horizontal_datum   varchar2(16),
      elevation          number,
      elev_unit_id       varchar2(16),
      vertical_datum     varchar2(16),
      public_name        varchar2(32),
      long_name          varchar2(80),
      description        varchar2(1024),
      active_flag        varchar2(1));
      
   type cat_wu_rec_t is record(
      project_office_id  varchar2(16),
      project_id         varchar2(49),
      entity_name        varchar2(64),
      water_right        varchar2(255));
          
   l_proj_loc_code  number := cwms_loc.get_location_code(p_db_office_id, p_project_id);
   l_location_id    varchar2(49);
   l_cursor         sys_refcursor;
   l_rec            cat_rec_t;
   l_wu_rec         cat_wu_rec_t;
   l_location_ref   location_ref_t := location_ref_t(p_project_id, p_db_office_id);
   
   function make_location_id (
      p_base_location_id in varchar2,
      p_sub_location_id  in varchar2)
   return varchar2
   is
   begin
      return p_base_location_id
         ||substr('-', 1, length(p_sub_location_id))
         ||p_sub_location_id; 
   end;
BEGIN
   if p_delete_action in (cwms_util.delete_all, cwms_util.delete_data) then
      -------------------------------------------------
      -- delete all items that reference the project --
      -------------------------------------------------
      -----------------
      -- embankments --
      -----------------
      cwms_embank.cat_embankment(l_cursor, p_project_id, p_db_office_id);
      loop
         fetch l_cursor into l_rec;
         exit when l_cursor%notfound;
         cwms_embank.delete_embankment(
            make_location_id(l_rec.base_location_id, l_rec.sub_location_id),
            cwms_util.delete_all,
            p_db_office_id);               
      end loop;
      close l_cursor;
      -----------
      -- locks --
      -----------
      cwms_lock.cat_lock(l_cursor, p_project_id, p_db_office_id);
      loop
         fetch l_cursor into l_rec;
         exit when l_cursor%notfound;
         cwms_lock.delete_lock(
            make_location_id(l_rec.base_location_id, l_rec.sub_location_id),
            cwms_util.delete_all,
            p_db_office_id);               
      end loop;
      close l_cursor;
      -------------
      -- outlets --
      -------------
      null;
      --------------
      -- turbines --
      --------------
      null;
      ---------------------
      -- turbine changes --
      ---------------------
      null;
      ------------------
      -- gate changes --
      ------------------
      null;
      ----------------------------
      -- construction histories --
      ----------------------------
      null;
      ------------------------
      -- project agreements --
      ------------------------
      null;
      -------------------------------------
      -- project congressional districts --
      -------------------------------------
      null;
      ----------------------
      -- project purposes --
      ----------------------
      null;
      -----------------
      -- water users --
      -----------------
      cwms_water_supply.cat_water_user(l_cursor, p_project_id, p_db_office_id);
      loop
         fetch l_cursor into l_wu_rec;
         exit when l_cursor%notfound;
         cwms_water_supply.delete_water_user(
            l_location_ref, 
            l_wu_rec.entity_name, 
            cwms_util.delete_all);
      end loop;
   end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      -------------------------------
      -- delete the project itself --
      -------------------------------
      delete 
        from at_project 
       where project_location_code = l_proj_loc_code;
   end if;
END delete_project;

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
      p_location_array    IN   char_49_array_type,
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

END CWMS_PROJECT;
 
/
show errors;
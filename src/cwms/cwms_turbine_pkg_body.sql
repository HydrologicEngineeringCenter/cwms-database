create or replace package body cwms_turbine as
--------------------------------------------------------------------------------
-- function get_turbine_code
--------------------------------------------------------------------------------
function get_turbine_code(
   p_office_id  in varchar2,
   p_turbine_id in varchar2)
   return number
is
   l_turbine_code number(10);
   l_office_id       varchar2(16);
begin
   if p_turbine_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TURBINE_ID');
   end if;
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   begin
      l_turbine_code := cwms_loc.get_location_code(l_office_id, p_turbine_id);
      select turbine_location_code
        into l_turbine_code
        from at_turbine
       where turbine_location_code = l_turbine_code;
   exception
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS turbine identifier.',
            l_office_id
            ||'/'
            ||p_turbine_id);
   end;
   return l_turbine_code;   
end get_turbine_code;   
--------------------------------------------------------------------------------
-- procedure check_lookup
--------------------------------------------------------------------------------
procedure check_lookup(
   p_lookup in lookup_type_obj_t)
is
begin
   if p_lookup.display_value is null then
      cwms_err.raise(
         'ERROR',
         'The display_value member of a lookup_type_obj_t object cannot be null.');
   end if;       
end check_lookup;
--------------------------------------------------------------------------------
-- procedure check_location_ref
--------------------------------------------------------------------------------
procedure check_location_ref(
   p_location in location_ref_t)
is
begin
   if p_location.base_location_id is null then
      cwms_err.raise(
         'ERROR',
         'The base_location_id member of a location_ref_t object cannot be null.');
   end if;      
end check_location_ref;
--------------------------------------------------------------------------------
-- procedure check_location_obj
--------------------------------------------------------------------------------
procedure check_location_obj(
   p_location in location_obj_t)
is
begin
   if p_location.location_ref is null then
      cwms_err.raise(
         'ERROR',
         'The location_ref member of a location_obj_t object cannot be null.');
   end if;
   check_location_ref(p_location.location_ref);
end check_location_obj;
--------------------------------------------------------------------------------
-- procedure check_characteristic_ref
--------------------------------------------------------------------------------
procedure check_characteristic_ref(
   p_characteristic in characteristic_ref_t)
is
begin
   if p_characteristic.office_id is null then
      cwms_err.raise(
         'ERROR',
         'The office_id member of a characteristic_ref_t object cannot be null.');
   end if;
   if p_characteristic.characteristic_id is null then
      cwms_err.raise(
         'ERROR',
         'The characteristic_id member of a characteristic_ref_t object cannot be null.');
   end if;
end check_characteristic_ref;   
--------------------------------------------------------------------------------
-- procedure check_project_structure
--------------------------------------------------------------------------------
procedure check_project_structure(
   p_project_struct in project_structure_obj_t)
is
begin
   if p_project_struct.project_location_ref is null then
      cwms_err.raise(
         'ERROR',
         'The project_location_ref member of a p_project_struct object cannot be null.');
   end if;
   if p_project_struct.structure_location is null then
      cwms_err.raise(
         'ERROR',
         'The structure_location member of a p_project_struct object cannot be null.');
   end if;
   check_location_ref(p_project_struct.project_location_ref);
   check_location_obj(p_project_struct.structure_location);
   if p_project_struct.characteristic_ref is not null then
      check_characteristic_ref(p_project_struct.characteristic_ref);
   end if;
end check_project_structure;
--------------------------------------------------------------------------------
-- procedure check_turbine_setting
--------------------------------------------------------------------------------
procedure check_turbine_setting(
   p_turbine_setting in turbine_setting_obj_t)
is
begin
   check_location_ref(p_turbine_setting.turbine_location_ref);
   if p_turbine_setting.old_discharge is null then
      cwms_err.raise(
         'ERROR',
         'The old_flow member of a p_turbine_setting object cannot be null.');
   end if;
   if p_turbine_setting.new_discharge is null then
      cwms_err.raise(
         'ERROR',
         'The new_flow member of a p_turbine_setting object cannot be null.');
   end if;
end check_turbine_setting;   
--------------------------------------------------------------------------------
-- procedure check_turbine_change
--------------------------------------------------------------------------------
procedure check_turbine_change(
   p_turbine_change in turbine_change_obj_t)
is
begin
   check_location_ref(p_turbine_change.project_location_ref);
   check_lookup(p_turbine_change.discharge_computation);
   check_lookup(p_turbine_change.setting_reason);
   if p_turbine_change.settings is not null and p_turbine_change.settings.count > 0 then
      for i in 1..p_turbine_change.settings.count loop
         check_turbine_setting(p_turbine_change.settings(i));
      end loop;
   end if;
end check_turbine_change;
--------------------------------------------------------------------------------
-- procedure retrieve_turbine
--------------------------------------------------------------------------------
procedure retrieve_turbine(
   p_turbine          out project_structure_obj_t,
   p_turbine_location in  location_ref_t)
is
   l_rec at_turbine%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_location');
   end if;
   check_location_ref(p_turbine_location);
   ----------------------------
   -- get the turbine record --
   ----------------------------
   l_rec.turbine_location_code := p_turbine_location.get_location_code;
   begin
      select * 
        into l_rec
        from at_turbine
       where turbine_location_code = l_rec.turbine_location_code; 
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS turbine',
            p_turbine_location.get_office_id
            ||'/'
            ||p_turbine_location.get_location_id);
   end;
   ----------------------------
   -- build the out variable --
   ----------------------------
   p_turbine := project_structure_obj_t(
      location_ref_t(l_rec.project_location_code),
      location_obj_t(l_rec.turbine_location_code),
      null);
end retrieve_turbine;   
--------------------------------------------------------------------------------
-- function retrieve_turbine_f
--------------------------------------------------------------------------------
function retrieve_turbine_f(
   p_turbine_location in location_ref_t)
   return project_structure_obj_t
is
   l_turbine project_structure_obj_t;
begin
   retrieve_turbine(l_turbine, p_turbine_location);
   return l_turbine;
end retrieve_turbine_f;
--------------------------------------------------------------------------------
-- procedure retrieve_turbines
--------------------------------------------------------------------------------   
procedure retrieve_turbines(
   p_turbines         out project_structure_tab_t,
   p_project_location in  location_ref_t)
is
   type turbine_recs_t is table of at_turbine%rowtype;
   l_recs          turbine_recs_t;
   l_project_code  number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_location');
   end if;
   check_location_ref(p_project_location);
   -----------------------------
   -- get the turbine records --
   -----------------------------
   l_project_code := p_project_location.get_location_code;
   begin
      select project_location_code
        into l_project_code
        from at_project
       where project_location_code = l_project_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS project',
            p_project_location.get_office_id
            ||'/'
            ||p_project_location.get_location_id);
   end;
   begin
      select * bulk collect 
        into l_recs
        from at_turbine
       where project_location_code = l_project_code; 
   exception
      when no_data_found then
         null;
   end;
   ----------------------------
   -- build the out variable --
   ----------------------------
   if l_recs is not null and l_recs.count > 0 then
      p_turbines := project_structure_tab_t();
      p_turbines.extend(l_recs.count);
      for i in 1..l_recs.count loop
         p_turbines(i) := project_structure_obj_t(
            location_ref_t(l_recs(i).project_location_code),
            location_obj_t(l_recs(i).turbine_location_code),
            null);
      end loop;
   end if;
end retrieve_turbines;
--------------------------------------------------------------------------------
-- function retrieve_turbines_f
--------------------------------------------------------------------------------
function retrieve_turbines_f(
   p_project_location in location_ref_t)
   return project_structure_tab_t
is
   l_turbines project_structure_tab_t;
begin
   retrieve_turbines(l_turbines, p_project_location);
   return l_turbines;      
end retrieve_turbines_f;   
--------------------------------------------------------------------------------
-- procedure store_turbine
--------------------------------------------------------------------------------
procedure store_turbine(
   p_turbine        in project_structure_obj_t,
   p_fail_if_exists in varchar2 default 'T')
is
begin
   store_turbines(project_structure_tab_t(p_turbine), p_fail_if_exists);
end store_turbine;
--------------------------------------------------------------------------------
-- procedure store_turbines
--------------------------------------------------------------------------------
procedure store_turbines(
   p_turbines       in project_structure_tab_t,
   p_fail_if_exists in varchar2 default 'T')
is   
   l_fail_if_exists boolean;
   l_exists         boolean;
   l_rec            at_turbine%rowtype;
   l_rating_group   varchar2(65) ;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbines is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TURBINES') ;
   end if;
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists) ;
   for i in 1..p_turbines.count
   loop
      ------------------------
      -- more sanity checks --
      ------------------------
      l_rec.turbine_location_code := cwms_loc.store_location_f(p_turbines(i).structure_location, 'F');
      if not cwms_loc.can_store(l_rec.turbine_location_code, 'TURBINE') then
         cwms_err.raise(
            'ERROR',
            'Cannot store turbine information to location '
            ||cwms_util.get_db_office_id(p_turbines(i).structure_location.location_ref.office_id)
            ||'/'
            ||p_turbines(i).structure_location.location_ref.get_location_id
            ||' (location kind = '
            ||cwms_loc.check_location_kind(l_rec.turbine_location_code)
            ||')');
      end if;
      ------------------------------------------------
      -- see if the turbine location already exists --
      ------------------------------------------------
      begin
         select * into l_rec from at_turbine where turbine_location_code = l_rec.turbine_location_code;
         l_exists := true;
      exception
         when no_data_found then l_exists := false;
      end;
      if l_exists and l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS', 
            'CWMS turbine', 
            p_turbines(i).structure_location.location_ref.get_office_id
            ||'/' 
            ||p_turbines(i).structure_location.location_ref.get_location_id) ;
      end if;
      begin
         l_rec.project_location_code := p_turbines(i).project_location_ref.get_location_code;
      exception
         when others then 
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS Project',
               p_turbines(i).project_location_ref.get_office_id
               ||'/'
               ||p_turbines(i).project_location_ref.get_location_id);
      end;
      if cwms_loc.check_location_kind(l_rec.project_location_code) != 'PROJECT' then
         cwms_err.raise(
            'ERROR',
            'Turbine location '
            ||p_turbines(i).structure_location.location_ref.get_office_id
            ||'/'
            ||p_turbines(i).structure_location.location_ref.get_location_id
            ||' refers to project location that is not a PROJECT kind: '
            ||p_turbines(i).project_location_ref.get_office_id
            ||'/'
            ||p_turbines(i).project_location_ref.get_location_id);
      end if;
      ---------------------------------
      -- insert or update the record --
      ---------------------------------
      if l_exists then
          update at_turbine
             set row = l_rec
           where turbine_location_code = l_rec.turbine_location_code;
      else
          insert into at_turbine values l_rec;
      end if;
      ---------------------------
      -- set the location kind --
      ---------------------------
      cwms_loc.update_location_kind(l_rec.turbine_location_code, 'TURBINE', 'A');
   end loop;
end store_turbines;
--------------------------------------------------------------------------------
-- procedure rename_turbine
--------------------------------------------------------------------------------
procedure rename_turbine(
   p_turbine_id_old in varchar2,
   p_turbine_id_new in varchar2,
   p_office_id      in varchar2 default null)
is
   l_turbine project_structure_obj_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_id_old is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_id_old');
   end if;
   if p_turbine_id_new is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_id_new');
   end if;
   if p_office_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_office_id');
   end if;
   l_turbine := retrieve_turbine_f(location_ref_t(p_turbine_id_old, p_office_id));
   cwms_loc.rename_location(p_turbine_id_old, p_turbine_id_new, p_office_id);
end rename_turbine;
--------------------------------------------------------------------------------
-- procedure delete_turbine
--------------------------------------------------------------------------------
procedure delete_turbine(
   p_turbine_id     in varchar,
   p_delete_action in varchar2 default cwms_util.delete_key, 
   p_office_id  in varchar2 default null
)
is
begin
   delete_turbine2(
      p_turbine_id    => p_turbine_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_office_id);
end delete_turbine;
--------------------------------------------------------------------------------
-- procedure delete_turbine2
--------------------------------------------------------------------------------
procedure delete_turbine2(
   p_turbine_id             in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null)
is
   l_turbine_code         number(10);
   l_delete_location      boolean;
   l_delete_action1       varchar2(16);
   l_delete_action2       varchar2(16);
   l_turbine_change_codes number_tab_t;
   l_count                pls_integer;
   l_location_kind_id     cwms_location_kind.location_kind_id%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_turbine_ID');
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
   l_turbine_code := get_turbine_code(p_office_id, p_turbine_id);
   l_location_kind_id := cwms_loc.check_location_kind(l_turbine_code);
   if l_location_kind_id != 'TURBINE' then
      cwms_err.raise(
         'ERROR',
         'Cannot delete turbine information from location '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_turbine_id
         ||' (location kind = '
         ||l_location_kind_id
         ||')');
   end if;
   l_location_kind_id := cwms_loc.can_revert_loc_kind_to( p_turbine_id, p_office_id);
   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
   if l_delete_action1 in (cwms_util.delete_data, cwms_util.delete_all) then
      select turbine_change_code bulk collect
        into l_turbine_change_codes
        from at_turbine_change
       where turbine_change_code in
             ( select turbine_change_code
                 from at_turbine_setting
                where turbine_location_code = l_turbine_code 
             );
      delete
        from at_turbine_setting
       where turbine_change_code in (select * from table(l_turbine_change_codes));  
      delete
        from at_turbine_change
       where turbine_change_code in (select * from table(l_turbine_change_codes));  
   end if;
   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
   if l_delete_action1 in (cwms_util.delete_key, cwms_util.delete_all) then
      delete from at_turbine where turbine_location_code = l_turbine_code;
      cwms_loc.update_location_kind(l_turbine_code, 'TURBINE', 'D');
   end if; 
   -------------------------------------
   -- delete the location if required --
   -------------------------------------
   if l_delete_location then
      cwms_loc.delete_location(p_turbine_id, l_delete_action2, p_office_id);
   end if;
end delete_turbine2;   
--------------------------------------------------------------------------------
-- procedure store_turbine_changes
--------------------------------------------------------------------------------
procedure store_turbine_changes(
   p_turbine_changes      in turbine_change_tab_t,
   p_start_time           in date default null,
   p_end_time             in date default null,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F')
is
   l_proj_loc_code    number(10);
   l_office_code      number(10);
   l_office_id        varchar2(16);
   l_change_date      date;
   l_start_time       date;
   l_end_time         date;
   l_time_zone        varchar2(28);
   l_change_rec       at_turbine_change%rowtype;
   l_setting_rec      at_turbine_setting%rowtype;
   l_dates            date_table_type;
   l_existing         turbine_change_tab_t;
   l_new_change_date  date;
   l_turbine_codes    number_tab_t;
   l_count            pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_changes is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_changes');
   elsif p_turbine_changes.count = 0 then
      cwms_err.raise('ERROR', 'No turbine changes specified.');
   end if;
   for i in 1..p_turbine_changes.count loop
      check_turbine_change(p_turbine_changes(i));
   end loop;
   if p_override_protection not in ('T','F') then
      cwms_err.raise('ERROR', 
      'Parameter p_override_protection must be either ''T'' or ''F''');
   end if;      
   if p_start_time is null and not cwms_util.is_true(p_start_time_inclusive) then
      cwms_err.raise(
         'ERROR',
         'Cannot specify exclusive start time with implicit start time');
   end if;      
   if p_end_time is null and not cwms_util.is_true(p_end_time_inclusive) then
      cwms_err.raise(
         'ERROR',
         'Cannot specify exclusive end time with implicit end time');
   end if;      
   for i in 1..p_turbine_changes.count loop
      if i = 1 then
         l_proj_loc_code := p_turbine_changes(i).project_location_ref.get_location_code;
         l_office_id     := upper(trim(p_turbine_changes(i).project_location_ref.get_office_id));
         l_office_code   := p_turbine_changes(i).project_location_ref.get_office_code;
         l_change_date   := p_turbine_changes(i).change_date; 
      else
         if p_turbine_changes(i).project_location_ref.get_location_code != l_proj_loc_code then
            cwms_err.raise(
               'ERROR',
               'Multiple projects found in turbine changes.');
         end if;
         if p_turbine_changes(i).change_date <= l_change_date then
            cwms_err.raise(
               'ERROR',
               'Gate changes are not in ascending time order.');
         end if;
      end if;
      if upper(trim(p_turbine_changes(i).discharge_computation.office_id)) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'Turbine change for office '
            ||l_office_id
            ||' cannot reference discharge computation for office '
            ||upper(p_turbine_changes(i).discharge_computation.office_id));
      end if;   
      if upper(trim(p_turbine_changes(i).setting_reason.office_id)) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'Turbine change for office '
            ||l_office_id
            ||' cannot reference release reason for office '
            ||upper(p_turbine_changes(i).setting_reason.office_id));
      end if;
      begin
         select turbine_comp_code
           into l_change_rec.turbine_discharge_comp_code
           from at_turbine_computation_code
          where db_office_code in (cwms_util.db_office_code_all, l_office_code)
            and upper(turbine_comp_display_value) = upper(p_turbine_changes(i).discharge_computation.display_value)
            and upper(turbine_comp_tooltip) = upper(p_turbine_changes(i).discharge_computation.tooltip)
            and turbine_comp_active = upper(p_turbine_changes(i).discharge_computation.active); 
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS turbine change computation',
               l_office_id
               ||'/DISPLAY='
               ||p_turbine_changes(i).discharge_computation.display_value
               ||'/TOOLTIP='
               ||p_turbine_changes(i).discharge_computation.tooltip
               ||'/ACTIVE='
               ||p_turbine_changes(i).discharge_computation.active);
      end;         
      begin
         select turb_set_reason_code
           into l_change_rec.turbine_setting_reason_code
           from at_turbine_setting_reason
          where db_office_code in (cwms_util.db_office_code_all, l_office_code)
            and upper(turb_set_reason_display_value) = upper(p_turbine_changes(i).setting_reason.display_value)
            and upper(turb_set_reason_tooltip) = upper(p_turbine_changes(i).setting_reason.tooltip)
            and turb_set_reason_active = upper(p_turbine_changes(i).setting_reason.active); 
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS turbine release reason',
               l_office_id
               ||'/DISPLAY='
               ||p_turbine_changes(i).setting_reason.display_value
               ||'/TOOLTIP='
               ||p_turbine_changes(i).setting_reason.tooltip
               ||'/ACTIVE='
               ||p_turbine_changes(i).setting_reason.active);
      end;
   end loop;      
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_start_time := nvl(p_start_time, p_turbine_changes(1).change_date);
   l_end_time   := nvl(p_end_time,   p_turbine_changes(p_turbine_changes.count).change_date);
   l_time_zone  := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   if l_time_zone is not null then
      l_start_time := cwms_util.change_timezone(l_start_time, l_time_zone, 'UTC');
      l_end_time   := cwms_util.change_timezone(l_end_time,   l_time_zone, 'UTC');
   end if;
   -------------------------------------------------------------
   -- delete any existing turbine changes in the time window  --
   -- that doesn't have a corrsponding time in the input data --
   -------------------------------------------------------------
   select cwms_util.change_timezone(change_date, nvl(l_time_zone, 'UTC'), 'UTC')
     bulk collect
     into l_dates
     from table(p_turbine_changes);
     
   l_existing := retrieve_turbine_changes_f(
      p_project_location => p_turbine_changes(1).project_location_ref,
      p_start_time       => l_start_time,
      p_end_time         => l_end_time);
      
   for rec in 
      (select change_date
        from table(l_existing)
       where change_date not in (select * from table(l_dates))
      )
   loop
      delete_turbine_changes(
         p_project_location    => p_turbine_changes(1).project_location_ref,
         p_start_time          => rec.change_date,
         p_end_time            => rec.change_date,
         p_override_protection => p_override_protection);
   end loop;
   
   ---------------------------
   -- insert/update records --
   ---------------------------
   for i in 1..p_turbine_changes.count loop
      l_new_change_date := cwms_util.change_timezone(p_turbine_changes(i).change_date, nvl(l_time_zone, 'UTC'), 'UTC');
      -----------------------------------------
      -- retrieve any existing change record --
      -----------------------------------------
      begin
         select *
           into l_change_rec
           from at_turbine_change
          where project_location_code = l_proj_loc_code
            and turbine_change_datetime = l_new_change_date;
      exception
         when no_data_found then
            l_change_rec.turbine_change_code := null;
            l_change_rec.project_location_code := l_proj_loc_code;
            l_change_rec.turbine_change_datetime := l_new_change_date;
      end;
      --------------------------------
      -- populate the change record --
      --------------------------------
      l_change_rec.turbine_change_datetime := l_new_change_date;
      l_change_rec.elev_pool := cwms_util.convert_units(
         p_turbine_changes(i).elev_pool,
         p_turbine_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.elev_tailwater := cwms_util.convert_units(
         p_turbine_changes(i).elev_tailwater,
         p_turbine_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.old_total_discharge_override := cwms_util.convert_units(
         p_turbine_changes(i).old_total_discharge_override,
         p_turbine_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      l_change_rec.new_total_discharge_override := cwms_util.convert_units(
         p_turbine_changes(i).new_total_discharge_override,
         p_turbine_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      select turbine_comp_code
        into l_change_rec.turbine_discharge_comp_code
        from at_turbine_computation_code
       where db_office_code in (cwms_util.db_office_code_all, l_office_code)
         and upper(turbine_comp_display_value) = upper(p_turbine_changes(i).discharge_computation.display_value)
         and upper(turbine_comp_tooltip) = upper(p_turbine_changes(i).discharge_computation.tooltip)
         and turbine_comp_active = upper(p_turbine_changes(i).discharge_computation.active); 
      select turb_set_reason_code
        into l_change_rec.turbine_setting_reason_code
        from at_turbine_setting_reason
       where db_office_code in (cwms_util.db_office_code_all, l_office_code)
         and upper(turb_set_reason_display_value) = upper(p_turbine_changes(i).setting_reason.display_value)
         and upper(turb_set_reason_tooltip) = upper(p_turbine_changes(i).setting_reason.tooltip)
         and turb_set_reason_active = upper(p_turbine_changes(i).setting_reason.active); 
      l_change_rec.turbine_change_notes := p_turbine_changes(i).change_notes;
      l_change_rec.protected := upper(p_turbine_changes(i).protected);
      -------------------------------------
      -- insert/update the change record --
      -------------------------------------
      if l_change_rec.turbine_change_code is null then
         l_change_rec.turbine_change_code := cwms_seq.nextval;
         insert into at_turbine_change values l_change_rec;
      else
         update at_turbine_change 
            set row = l_change_rec
          where turbine_change_code = l_change_rec.turbine_change_code; 
      end if;
      ----------------------------------------------------------------------------
      -- collect the turbine location codes from the input data for this change --
      ----------------------------------------------------------------------------
      l_turbine_codes := number_tab_t();
      l_count := nvl(p_turbine_changes(i).settings, turbine_setting_tab_t()).count;
      l_turbine_codes.extend(l_count);
      for j in 1..l_count loop
         l_turbine_codes(j) := p_turbine_changes(i).settings(j).turbine_location_ref.get_location_code;
      end loop;
      ----------------------------------------------------------------------------------
      -- delete any existing turbine setting record not in input data for this change --
      ----------------------------------------------------------------------------------
      delete 
        from at_turbine_setting
       where turbine_change_code = l_change_rec.turbine_change_code
         and turbine_location_code not in (select * from table(l_turbine_codes));
      ------------------------------------
      -- insert/update turbine settings --
      ------------------------------------
      for j in 1..l_turbine_codes.count loop
         ------------------------------------------
         -- retrieve any existing setting record --
         ------------------------------------------
         begin
            select *
              into l_setting_rec
              from at_turbine_setting
             where turbine_change_code = l_change_rec.turbine_change_code
               and turbine_location_code = l_turbine_codes(j);
         exception
            when no_data_found then
               l_setting_rec.turbine_setting_code := null;
               l_setting_rec.turbine_change_code := l_change_rec.turbine_change_code;
               l_setting_rec.turbine_location_code := l_turbine_codes(j);
         end;
         ---------------------------------
         -- populate the setting record --
         ---------------------------------
         l_setting_rec.old_discharge := cwms_util.convert_units(
            p_turbine_changes(i).settings(j).old_discharge,
            p_turbine_changes(i).settings(j).discharge_units,
            cwms_util.get_default_units('Flow'));
         l_setting_rec.new_discharge := cwms_util.convert_units(
            p_turbine_changes(i).settings(j).new_discharge,
            p_turbine_changes(i).settings(j).discharge_units,
            cwms_util.get_default_units('Flow'));  
         l_setting_rec.scheduled_load := p_turbine_changes(i).settings(j).scheduled_load;                
         l_setting_rec.real_power := p_turbine_changes(i).settings(j).real_power;
         --------------------------------------
         -- insert/update the setting record --
         --------------------------------------
         if l_setting_rec.turbine_setting_code is null then
            l_setting_rec.turbine_setting_code := cwms_seq.nextval;
            insert into at_turbine_setting values l_setting_rec;               
         else
            update at_turbine_setting
               set row = l_setting_rec
             where turbine_setting_code = l_setting_rec.turbine_setting_code;  
         end if;
      end loop;         
   end loop;       
end store_turbine_changes;
--------------------------------------------------------------------------------
-- procedure retrieve_turbine_changes
--------------------------------------------------------------------------------
procedure retrieve_turbine_changes(
   p_turbine_changes      out turbine_change_tab_t,
   p_project_location     in  location_ref_t,
   p_start_time           in  date,
   p_end_time             in  date,
   p_time_zone            in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_start_time_inclusive in  varchar2 default 'T',
   p_end_time_inclusive   in  varchar2 default 'T',
   p_max_item_count       in  integer default null)
is
   type turbine_change_db_tab_t is table of at_turbine_change%rowtype;
   type turbine_setting_db_tab_t is table of at_turbine_setting%rowtype; 
   c_one_second       constant number := 1/86400;
   l_time_zone        varchar2(28);
   l_unit_system      varchar2(2);
   l_start_time       date;
   l_end_time         date;
   l_project          project_obj_t;
   l_proj_loc_code    number(10);
   l_turbine_changes  turbine_change_db_tab_t;
   l_turbine_settings turbine_setting_db_tab_t;
   l_flow_unit        varchar2(16);
   l_elev_unit        varchar2(16);
   l_db_flow_unit     varchar2(16);
   l_db_elev_unit     varchar2(16);
   l_db_power_unit    varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');    
   end if;
   if p_max_item_count = 0 then
      cwms_err.raise(
         'ERROR',
         'Max item count must not be zero. Use NULL for unlimited.');
   end if;
   if p_start_time > p_end_time then
      cwms_err.raise(
         'ERROR',
         'Start time must not be later than end time.');
   end if;
   check_location_ref(p_project_location);
   -- will barf if not a valid project
   cwms_project.retrieve_project(
      l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   -------------------------
   -- get the unit system --
   -------------------------      
   l_unit_system := 
      upper(
         substr(
            nvl(
               p_unit_system, 
               cwms_properties.get_property(
                  'Pref_User.'||cwms_util.get_user_id, 
                  'Unit_System', 
                  cwms_properties.get_property(
                     'Pref_Office',
                     'Unit_System',
                     'SI',
                     p_project_location.get_office_id), 
                  p_project_location.get_office_id)),
            1, 2));
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;            
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   l_start_time := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');
   if not cwms_util.is_true(p_start_time_inclusive) then
      l_start_time := l_start_time + c_one_second;
   end if;        
   if not cwms_util.is_true(p_end_time_inclusive) then
      l_end_time := l_end_time - c_one_second;
   end if;
   ----------------------------------------
   -- collect the turbine change records --
   ---------------------------------------
   if p_max_item_count is null then
      select * bulk collect
        into l_turbine_changes
        from at_turbine_change
       where project_location_code = l_proj_loc_code
         and turbine_change_datetime between l_start_time and l_end_time
    order by turbine_change_datetime;
       
   else
      if p_max_item_count < 0 then
         select *
           bulk collect
           into l_turbine_changes
           from ( select *
                    from at_turbine_change
                   where project_location_code = l_proj_loc_code
                     and turbine_change_datetime between l_start_time and l_end_time
                order by turbine_change_datetime desc
                ) 
          where rownum <= -p_max_item_count
          order by turbine_change_datetime; 
      else
         select *
           bulk collect
           into l_turbine_changes
           from ( select *
                    from at_turbine_change
                   where project_location_code = l_proj_loc_code
                     and turbine_change_datetime between l_start_time and l_end_time
                order by turbine_change_datetime
                ) 
          where rownum <= p_max_item_count
          order by turbine_change_datetime; 
      end if;
   end if;
   ----------------------------
   -- build the out variable --
   ----------------------------
   if l_turbine_changes is not null and l_turbine_changes.count > 0 then
      cwms_display.retrieve_unit(l_flow_unit, 'Flow', l_unit_system, p_project_location.get_office_id);
      cwms_display.retrieve_unit(l_elev_unit, 'Elev', l_unit_system, p_project_location.get_office_id);
      l_db_elev_unit := cwms_util.get_default_units('Elev');
      l_db_flow_unit := cwms_util.get_default_units('Flow');
      l_db_power_unit := cwms_util.get_default_units('Power');
      p_turbine_changes := turbine_change_tab_t();
      p_turbine_changes.extend(l_turbine_changes.count);
      for i in 1..l_turbine_changes.count loop
         ------------------------
         -- turbine change object --
         ------------------------
         p_turbine_changes(i) := turbine_change_obj_t(
            location_ref_t(l_turbine_changes(i).project_location_code),
            cwms_util.change_timezone(l_turbine_changes(i).turbine_change_datetime, 'UTC', l_time_zone),
            null, -- discharge_computation, set below
            null, -- setting_reason, set below
            null, -- settings, set below 
            cwms_util.convert_units(
               l_turbine_changes(i).elev_pool, 
               l_db_elev_unit, 
               l_elev_unit),
            cwms_util.convert_units(
               l_turbine_changes(i).elev_tailwater, 
               l_db_elev_unit, 
               l_elev_unit),   
            l_elev_unit,
            cwms_util.convert_units(
               l_turbine_changes(i).old_total_discharge_override, 
               l_db_flow_unit, 
               l_flow_unit),
            cwms_util.convert_units(
               l_turbine_changes(i).new_total_discharge_override, 
               l_db_flow_unit, 
               l_flow_unit),
            l_flow_unit,
            l_turbine_changes(i).turbine_change_notes,
            l_turbine_changes(i).protected);
         ---------------------------------
         -- discharge_computation field --
         ---------------------------------            
         select lookup_type_obj_t(
                   p_project_location.get_office_id, 
                   turbine_comp_display_value, 
                   turbine_comp_tooltip, 
                   turbine_comp_active)
           into p_turbine_changes(i).discharge_computation
           from at_turbine_computation_code
          where turbine_comp_code = l_turbine_changes(i).turbine_discharge_comp_code;
         --------------------------
         -- setting_reason field --
         --------------------------             
         select lookup_type_obj_t(
                   p_project_location.get_office_id, 
                   turb_set_reason_display_value, 
                   turb_set_reason_tooltip, 
                   turb_set_reason_active)
           into p_turbine_changes(i).setting_reason
           from at_turbine_setting_reason
          where turb_set_reason_code = l_turbine_changes(i).turbine_setting_reason_code;
          --------------------
          -- settings field --
          --------------------
         select * bulk collect
           into l_turbine_settings
           from at_turbine_setting
          where turbine_change_code = l_turbine_changes(i).turbine_change_code;
          
         if l_turbine_settings is not null and l_turbine_settings.count > 0 then
            p_turbine_changes(i).settings := turbine_setting_tab_t();
            p_turbine_changes(i).settings.extend(l_turbine_settings.count);
            for j in 1..l_turbine_settings.count loop
               p_turbine_changes(i).settings(j) := turbine_setting_obj_t(
                  location_ref_t(l_turbine_settings(j).turbine_location_code),
                  cwms_util.convert_units(
                     l_turbine_settings(j).old_discharge, 
                     l_db_flow_unit, 
                     l_flow_unit),
                  cwms_util.convert_units(
                     l_turbine_settings(j).new_discharge, 
                     l_db_flow_unit, 
                     l_flow_unit),
                  l_flow_unit,
                  l_turbine_settings(j).real_power,
                  l_turbine_settings(j).scheduled_load,
                  l_db_power_unit);                  
            end loop;
         end if;          
                                 
      end loop;
   end if;
end retrieve_turbine_changes;
--------------------------------------------------------------------------------
-- function retrieve_turbine_changes_f
--------------------------------------------------------------------------------
function retrieve_turbine_changes_f(
   p_project_location      in location_ref_t,
   p_start_time            in date,
   p_end_time              in date,
   p_time_zone             in varchar2 default null,
   p_unit_system           in varchar2 default null,
   p_start_time_inclusive  in varchar2 default 'T',
   p_end_time_inclusive    in varchar2 default 'T',
   p_max_item_count        in integer default null)
   return turbine_change_tab_t
is
   l_turbine_changes turbine_change_tab_t;
begin
   retrieve_turbine_changes(
      l_turbine_changes,
      p_project_location,
      p_start_time,
      p_end_time,
      p_time_zone,
      p_unit_system,
      p_start_time_inclusive,
      p_end_time_inclusive,
      p_max_item_count);
   return l_turbine_changes;                 
end retrieve_turbine_changes_f;   
--------------------------------------------------------------------------------
-- procedure delete_turbine_changes
--------------------------------------------------------------------------------
procedure delete_turbine_changes(
   p_project_location     in  location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F')
is
   c_one_second        constant number := 1/86400;
   l_time_zone         varchar2(28);
   l_start_time        date;
   l_end_time          date;
   l_proj_loc_code     number(10);
   l_project           project_obj_t;
   l_turbine_change_codes number_tab_t;
   l_protected_flags   str_tab_t;
   l_protected_count   pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');    
   end if;
   if p_start_time > p_end_time then
      cwms_err.raise(
         'ERROR',
         'Start time must not be later than end time.');
   end if;
   check_location_ref(p_project_location);
   if p_override_protection not in ('T','F') then
      cwms_err.raise('ERROR', 
      'Parameter p_override_protection must be either ''T'' or ''F''');
   end if;      
   -- will barf if not a valid project
   cwms_project.retrieve_project(
      l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;            
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   l_start_time := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');
   if not cwms_util.is_true(p_start_time_inclusive) then
      l_start_time := l_start_time + c_one_second;
   end if;        
   if not cwms_util.is_true(p_end_time_inclusive) then
      l_end_time := l_end_time - c_one_second;
   end if;
   -----------------------------------------------------------
   -- collect the turbine change codes  and protected flags --
   -----------------------------------------------------------
   select turbine_change_code,
          protected
     bulk collect
     into l_turbine_change_codes,
          l_protected_flags
     from at_turbine_change
    where project_location_code = l_proj_loc_code
      and turbine_change_datetime between l_start_time and l_end_time;
   -------------------------------------      
   -- check for protection violations --
   -------------------------------------      
   if not cwms_util.is_true(p_override_protection) then
      select count(*)
        into l_protected_count
        from table(l_protected_flags)
       where column_value = 'T';
      if l_protected_count > 0 then
         cwms_err.raise(
            'ERROR',
            'Cannot delete protected turbine change(s).');
      end if;        
   end if;      
   ------------------------
   -- delete the records --
   ------------------------
   delete
     from at_turbine_setting
    where turbine_change_code in (select * from table(l_turbine_change_codes));              
   delete
     from at_turbine_change
    where turbine_change_code in (select * from table(l_turbine_change_codes));              
end delete_turbine_changes;
--------------------------------------------------------------------------------
-- procedure set_turbine_change_protection
--------------------------------------------------------------------------------
procedure set_turbine_change_protection(
   p_project_location     in location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_protected            in varchar2,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T')
is
   c_one_second        constant number := 1/86400;
   l_time_zone         varchar2(28);
   l_start_time        date;
   l_end_time          date;
   l_proj_loc_code     number(10);
   l_project           project_obj_t;
   l_turbine_change_codes number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');    
   end if;
   if p_protected is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_protected');    
   end if;
   if p_start_time > p_end_time then
      cwms_err.raise(
         'ERROR',
         'Start time must not be later than end time.');
   end if;
   check_location_ref(p_project_location);
   if p_protected not in ('T','F') then
      cwms_err.raise('ERROR', 
      'Parameter p_protected must be either ''T'' or ''F''');
   end if;      
   -- will barf if not a valid project
   cwms_project.retrieve_project(
      l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;            
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   l_start_time := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');
   if not cwms_util.is_true(p_start_time_inclusive) then
      l_start_time := l_start_time + c_one_second;
   end if;        
   if not cwms_util.is_true(p_end_time_inclusive) then
      l_end_time := l_end_time - c_one_second;
   end if;
   ---------------------------
   -- update the protection --
   ---------------------------                                                 
   update at_turbine_change
      set protected = p_protected
    where project_location_code = l_proj_loc_code
      and turbine_change_datetime between l_start_time and l_end_time;
end set_turbine_change_protection;

end cwms_turbine;
/
show errors;
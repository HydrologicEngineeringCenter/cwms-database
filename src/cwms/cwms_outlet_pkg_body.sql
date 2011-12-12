create or replace package body cwms_outlet as
--------------------------------------------------------------------------------
-- procedure check_lookup
--------------------------------------------------------------------------------
procedure check_lookup(
   p_lookup in lookup_type_obj_t)
is
begin
   cwms_util.check_inputs(str_tab_t(
      p_lookup.office_id,
      p_lookup.display_value,
      p_lookup.tooltip,
      p_lookup.active));
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
   cwms_util.check_inputs(str_tab_t(
      p_location.base_location_id,
      p_location.sub_location_id,
      p_location.office_id));
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
   cwms_util.check_inputs(str_tab_t(
      p_location.state_initial,
      p_location.county_name,
      p_location.time_zone_name,
      p_location.location_type,
      p_location.horizontal_datum,
      p_location.elev_unit_id,
      p_location.vertical_datum,
      p_location.public_name,
      p_location.long_name,
      p_location.description,
      p_location.active_flag,
      p_location.location_kind_id,
      p_location.map_label,
      p_location.bounding_office_id,
      p_location.bounding_office_name,
      p_location.nation_id,
      p_location.nearest_city));
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
   cwms_util.check_inputs(str_tab_t(
      p_characteristic.office_id,
      p_characteristic.characteristic_id));
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
-- procedure check_gate_setting
--------------------------------------------------------------------------------
procedure check_gate_setting(
   p_gate_setting in gate_setting_obj_t)
is
begin
   check_location_ref(p_gate_setting.outlet_location_ref);
   cwms_util.check_input(p_gate_setting.opening_units);
end check_gate_setting;   
--------------------------------------------------------------------------------
-- procedure check_gate_change
--------------------------------------------------------------------------------
procedure check_gate_change(
   p_gate_change in gate_change_obj_t)
is
begin
   check_location_ref(p_gate_change.project_location_ref);
   check_lookup(p_gate_change.discharge_computation);
   check_lookup(p_gate_change.release_reason);
   if p_gate_change.settings is not null and p_gate_change.settings.count > 0 then
      for i in 1..p_gate_change.settings.count loop
         check_gate_setting(p_gate_change.settings(i));
      end loop;
   end if;
   cwms_util.check_inputs(str_tab_t(
      p_gate_change.elev_units,
      p_gate_change.discharge_units,
      p_gate_change.change_notes,
      p_gate_change.protected));
end check_gate_change;
--------------------------------------------------------------------------------
-- function get_office_from_outlet
--------------------------------------------------------------------------------
function get_office_from_outlet(
   p_outlet_location_code in number)
   return number
is
   l_office_code number(10);
begin
   select bl.db_office_code
     into l_office_code
     from at_physical_location pl,
          at_base_location bl
    where pl.location_code = p_outlet_location_code
      and bl.base_location_code = pl.base_location_code;
      
   return l_office_code;                 
end get_office_from_outlet;   
--------------------------------------------------------------------------------
-- function get_outlet_opening_param
--------------------------------------------------------------------------------
function get_outlet_opening_param(
   p_outlet_location_code in number)
   return varchar2
is
   l_ind_params str_tab_t;
   l_param       varchar2(16);
   l_alias       varchar2(256); -- shared alias id is rating spec
   l_office_code number(10) := get_office_from_outlet(p_outlet_location_code); 
begin
   ------------------------------------------
   -- get the rating spec for the location --
   ------------------------------------------
   begin
      select g.shared_loc_alias_id
        into l_alias
        from at_loc_category c,
             at_loc_group g,
             at_loc_group_assignment a
       where upper(c.loc_category_id) = 'RATING'
         and c.db_office_code = l_office_code
         and g.loc_category_code = c.loc_category_code
         and g.db_office_code = c.db_office_code
         and a.loc_group_code = g.loc_group_code
         and a.location_code = p_outlet_location_code;          
   exception
      when no_data_found then
         cwms_err.raise('ERROR', 'No rating is specified for outlet location');
   end;
   -------------------------------
   -- find the actual parameter --
   -------------------------------
   l_ind_params := cwms_util.split_text(
      cwms_util.split_text(
         cwms_util.split_text(
            l_alias, 
            2, 
            cwms_rating.separator1), 
         1, 
         cwms_rating.separator2),
      cwms_rating.separator3);
   for i in 1..l_ind_params.count loop
      l_param := cwms_util.split_text(l_ind_params(i), '-')(1);
      if l_param not in ('Count', 'Elev') then
         return l_param;
      end if;
   end loop;
   --------------------------------
   -- error : no parameter found --
   --------------------------------
   cwms_err.raise(      
      'ERROR',
      'No opening parameter found in '
      ||l_alias);
end get_outlet_opening_param;   
--------------------------------------------------------------------------------
-- function get_rating_spec
--------------------------------------------------------------------------------
function get_rating_spec(
   p_outlet_location_code  in number,
   p_project_location_code in number)
   return varchar2
is
   l_gate_type varchar2(32);
   l_rating_template_template varchar2(24);
   l_rating_spec varchar2(372); 
begin
   select sub_location_id
     into l_gate_type
     from at_physical_location
    where location_code = p_outlet_location_code;
            
   l_gate_type := upper(regexp_substr(l_gate_type, '^(\D+).?$', 1, 1, 'i', 1));
   case
      when l_gate_type = 'SG'                     then l_gate_type := 'Sluice';  
      when substr(l_gate_type, 1, 6) = 'SLUICE'   then l_gate_type := 'Sluice';  
      when l_gate_type = 'CG'                     then l_gate_type := 'Conduit';
      when substr(l_gate_type, 1, 7) = 'CONDUIT'  then l_gate_type := 'Conduit';
      when l_gate_type = 'TG'                     then l_gate_type := 'Spillway';
      when substr(l_gate_type, 1, 7) = 'TAINTER'  then l_gate_type := 'Spillway';
      when substr(l_gate_type, 1, 8) = 'SPILLWAY' then l_gate_type := 'Spillway';
      when l_gate_type = 'LF'                     then l_gate_type := 'Low_Flow';
      when substr(l_gate_type, 1, 8) = 'LOW_FLOW' then l_gate_type := 'Low_Flow';
      else null;
   end case;
   l_rating_template_template := replace(
      '%'
      ||cwms_rating.separator2
      ||'Flow-$_Gates'
      ||cwms_rating.separator1
      ||'%',
      '$', 
      l_gate_type);
   begin
      select rating_id
        into l_rating_spec 
        from cwms_v_rating_spec v,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o 
       where v.office_id = o.office_id
         and v.location_id = bl.base_location_id
                             ||substr('-', 1, length(pl.sub_location_id))
                             ||pl.sub_location_id
         and v.template_id like l_rating_template_template
         and pl.location_code = p_project_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
   exception
      when no_data_found then null;
   end;
   return l_rating_spec;               
end;
--------------------------------------------------------------------------------
-- procedure assign_to_rating_group
--------------------------------------------------------------------------------
procedure assign_to_rating_group(
   p_outlet_location_code  in number,
   p_project_location_code in number,
   p_rating_group_id       in varchar2)
is
   l_category_rec   at_loc_category%rowtype;
   l_group_rec      at_loc_group%rowtype;
   l_assignment_rec at_loc_group_assignment%rowtype;     
begin
   --------------------------------------------
   -- retrieve or create the rating category --
   --------------------------------------------
   l_category_rec.loc_category_id := 'Rating';
   l_category_rec.db_office_code  := get_office_from_outlet(p_outlet_location_code);
   begin
      select *
        into l_category_rec
        from at_loc_category
       where db_office_code = l_category_rec.db_office_code
         and upper(loc_category_id) = upper(l_category_rec.loc_category_id);
   exception
      when no_data_found then
         l_category_rec.loc_category_code := cwms_seq.nextval;
         l_category_rec.loc_category_desc := 'Contains groups the relate outlets to ratings';
         insert into at_loc_category values l_category_rec;
   end;
   --------------------------------------------------          
   -- retrieve or create the assigned rating group --
   --------------------------------------------------
   l_group_rec.loc_category_code := l_category_rec.loc_category_code;
   l_group_rec.db_office_code    := l_category_rec.db_office_code;
   l_group_rec.loc_group_id      := p_rating_group_id;
   begin
      select *
        into l_group_rec
        from at_loc_group
       where loc_category_code = l_group_rec.loc_category_code
         and db_office_code = l_group_rec.db_office_code
         and upper(loc_group_id) = upper(l_group_rec.loc_group_id);
      ------------------------------------------------------         
      -- verify we have the correct project location code --
      ------------------------------------------------------
      if l_group_rec.shared_loc_ref_code != p_project_location_code then
         cwms_err.raise(
            'ERROR',
            'Shared location references (project locations) do not match.');
      end if;         
   exception
      when no_data_found then
         l_group_rec.loc_group_code      := cwms_seq.nextval;
         l_group_rec.loc_group_desc      := 'Shared alias contains rating spec for assigned outlets.';
         l_group_rec.shared_loc_alias_id := get_rating_spec(p_outlet_location_code, p_project_location_code);
         l_group_rec.shared_loc_ref_code := p_project_location_code;
         insert into at_loc_group values l_group_rec;
   end;
   ---------------------------------------
   -- unassign from other rating groups --
   ---------------------------------------
   delete
     from at_loc_group_assignment
    where location_code = p_outlet_location_code
      and loc_group_code in
          ( select loc_group_code 
              from at_loc_group
             where loc_category_code = l_group_rec.loc_category_code
               and loc_group_code != l_group_rec.loc_group_code
          );
   ------------------------------------------------          
   -- assign the location to the specified group --
   ------------------------------------------------
   l_assignment_rec.location_code  := p_outlet_location_code;
   l_assignment_rec.loc_group_code := l_group_rec.loc_group_code;
   begin
      select *
        into l_assignment_rec
        from at_loc_group_assignment
       where location_code  = l_assignment_rec.location_code
         and loc_group_code = l_assignment_rec.loc_group_code;
   exception
      when no_data_found then
         insert into at_loc_group_assignment values l_assignment_rec;
   end;
end assign_to_rating_group;   
--------------------------------------------------------------------------------
-- procedure retrieve_outlet
--------------------------------------------------------------------------------
procedure retrieve_outlet(
   p_outlet          out project_structure_obj_t,
   p_outlet_location in  location_ref_t)
is
   l_rec at_outlet%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_outlet_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_location');
   end if;
   check_location_ref(p_outlet_location);
   ---------------------------
   -- get the outlet record --
   ---------------------------
   l_rec.outlet_location_code := p_outlet_location.get_location_code;
   begin
      select * 
        into l_rec
        from at_outlet
       where outlet_location_code = l_rec.outlet_location_code; 
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS outlet',
            p_outlet_location.get_office_id
            ||'/'
            ||p_outlet_location.get_location_id);
   end;
   ----------------------------
   -- build the out variable --
   ----------------------------
   p_outlet := project_structure_obj_t(
      location_ref_t(l_rec.project_location_code),
      location_obj_t(l_rec.outlet_location_code),
      null);
end retrieve_outlet;   
--------------------------------------------------------------------------------
-- function retrieve_outlet_f
--------------------------------------------------------------------------------
function retrieve_outlet_f(
   p_outlet_location in location_ref_t)
   return project_structure_obj_t
is
   l_outlet project_structure_obj_t;
begin
   retrieve_outlet(l_outlet, p_outlet_location);
   return l_outlet;
end retrieve_outlet_f;
--------------------------------------------------------------------------------
-- procedure retrieve_outlets
--------------------------------------------------------------------------------   
procedure retrieve_outlets(
   p_outlets          out project_structure_tab_t,
   p_project_location in  location_ref_t)
is
   type outlet_recs_t is table of at_outlet%rowtype;
   l_recs          outlet_recs_t;
   l_project_code  number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_location');
   end if;
   check_location_ref(p_project_location);
   ----------------------------
   -- get the outlet records --
   ----------------------------
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
        from at_outlet
       where project_location_code = l_project_code; 
   exception
      when no_data_found then
         null;
   end;
   ----------------------------
   -- build the out variable --
   ----------------------------
   if l_recs is not null and l_recs.count > 0 then
      p_outlets := project_structure_tab_t();
      p_outlets.extend(l_recs.count);
      for i in 1..l_recs.count loop
         p_outlets(i) := project_structure_obj_t(
            location_ref_t(l_recs(i).project_location_code),
            location_obj_t(l_recs(i).outlet_location_code),
            null);
      end loop;
   end if;
end retrieve_outlets;
--------------------------------------------------------------------------------
-- function retrieve_outlets_f
--------------------------------------------------------------------------------
function retrieve_outlets_f(
   p_project_location in location_ref_t)
   return project_structure_tab_t
is
   l_outlets project_structure_tab_t;
begin
   retrieve_outlets(l_outlets, p_project_location);
   return l_outlets;      
end retrieve_outlets_f;   
--------------------------------------------------------------------------------
-- procedure store_outlet
--------------------------------------------------------------------------------
procedure store_outlet(
   p_outlet         in project_structure_obj_t,
   p_rating_group   in varchar2 default null,
   p_fail_if_exists in varchar2 default 'T')
is
begin
   store_outlets(project_structure_tab_t(p_outlet), p_rating_group, p_fail_if_exists);
end store_outlet;
--------------------------------------------------------------------------------
-- procedure store_outlets
--------------------------------------------------------------------------------
procedure store_outlets(
   p_outlets        in project_structure_tab_t,
   p_rating_group   in varchar2 default null,
   p_fail_if_exists in varchar2 default 'T')
is
   l_fail_if_exists boolean;
   l_exists         boolean;
   l_project        project_obj_t;
   l_rec            at_outlet%rowtype;
   l_rating_group   varchar2(65);
   l_location_type  varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_outlets is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlets');
   end if;
   cwms_util.check_inputs(str_tab_t(p_rating_group, p_fail_if_exists));
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   for i in 1..p_outlets.count loop
      ------------------------
      -- more sanity checks --
      ------------------------
      check_project_structure(p_outlets(i));
      -- will raise an exception if project doesn't exist
      cwms_project.retrieve_project(
         l_project,
         p_outlets(i).project_location_ref.get_location_id,
         p_outlets(i).project_location_ref.get_office_id);
      -----------------------------------------------         
      -- create a rating group id if not specified --
      -----------------------------------------------
      if i = 1 then
         l_rating_group := nvl(p_rating_group, p_outlets(i).project_location_ref.get_location_id);  
      end if;         
      -----------------------------------------------
      -- see if the outlet location already exists --
      -----------------------------------------------
      begin          
         l_rec.outlet_location_code := p_outlets(i).structure_location.location_ref.get_location_code('F');
         l_exists := true;
         l_location_type := cwms_loc.get_location_type(l_rec.outlet_location_code);
         if l_location_type not in ('NONE', 'OUTLET') then
            cwms_err.raise(
               'ERROR',
               'CWMS location '             
               ||p_outlets(i).structure_location.location_ref.get_office_id
               ||'/'
               ||p_outlets(i).structure_location.location_ref.get_location_id
               ||' exists but is identified as type '||l_location_type);
         end if;
         if l_fail_if_exists then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'CWMS outlet',
               p_outlets(i).structure_location.location_ref.get_office_id
               ||'/'
               ||p_outlets(i).structure_location.location_ref.get_location_id);
         end if;
      exception
         when no_data_found then
            l_exists := false;
      end;
      -----------------------
      -- create the record --
      -----------------------
      cwms_loc.store_location(p_outlets(i).structure_location, 'F');
      if not l_exists then
         l_rec.outlet_location_code := p_outlets(i).structure_location.location_ref.get_location_code('T');
         l_rec.project_location_code := l_project.project_location.location_ref.get_location_code('F');
         insert into at_outlet values l_rec; 
      end if;
      -----------------------------------------------------
      -- assign the record to the specified rating group --
      -----------------------------------------------------
      assign_to_rating_group(
      l_rec.outlet_location_code,
      l_rec.project_location_code,
      l_rating_group);
   end loop;
end store_outlets;
--------------------------------------------------------------------------------
-- procedure rename_outlet
--------------------------------------------------------------------------------
procedure rename_outlet(
   p_outlet_id_old in varchar2,
   p_outlet_id_new in varchar2,
   p_office_id     in varchar2 default null)
is
   l_outlet project_structure_obj_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_outlet_id_old is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_id_old');
   end if;
   if p_outlet_id_new is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_id_new');
   end if;
   if p_office_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_office_id');
   end if;
   cwms_util.check_inputs(str_tab_t(p_outlet_id_old, p_outlet_id_new, p_office_id));
   l_outlet := retrieve_outlet_f(location_ref_t(p_outlet_id_old, p_office_id));
   cwms_loc.rename_location(p_outlet_id_old, p_outlet_id_new, p_office_id);
end rename_outlet;
--------------------------------------------------------------------------------
-- procedure delete_outlet
--------------------------------------------------------------------------------
procedure delete_outlet(
   p_outlet_id     in varchar,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_outlet               project_structure_obj_t;
   l_outlet_location_code number(10);
   l_gate_change_codes    number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_outlet_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_id');
   end if;
   if p_delete_action is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_delete_action');
   end if;
   if p_office_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_office_id');
   end if;
   cwms_util.check_inputs(str_tab_t(p_outlet_id, p_delete_action, p_office_id));
   l_outlet := retrieve_outlet_f(location_ref_t(p_outlet_id, p_office_id));
   if upper(p_delete_action) not in (
      cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all) 
   then
      cwms_err.raise('INVALID_DELETE_ACTION', p_delete_action);      
   end if;
   l_outlet_location_code := l_outlet.structure_location.location_ref.get_location_code;
   --------------------------------------------
   -- delete the dependent data if necessary --
   --------------------------------------------
   if upper(p_delete_action) in (
      cwms_util.delete_data,
      cwms_util.delete_all) 
   then
      select gate_change_code bulk collect
        into l_gate_change_codes
        from at_gate_change
       where gate_change_code in
             ( select gate_change_code
                 from at_gate_setting
                where outlet_location_code = l_outlet_location_code 
             );
      delete
        from at_gate_setting
       where gate_change_code in (select * from table(l_gate_change_codes));  
      delete
        from at_gate_change
       where gate_change_code in (select * from table(l_gate_change_codes));  
   end if;
   ---------------------------------------------
   -- delete the location record if necessary --
   ---------------------------------------------
   if upper(p_delete_action) in (
      cwms_util.delete_key,
      cwms_util.delete_all)
   then
      delete
        from at_outlet
       where outlet_location_code = l_outlet_location_code;
      cwms_loc.delete_location(
         l_outlet.structure_location.location_ref.get_location_id,
         p_delete_action,
         p_office_id);
   end if;       
end delete_outlet;
--------------------------------------------------------------------------------
-- procedure assign_to_rating_group
--------------------------------------------------------------------------------
procedure assign_to_rating_group(
   p_outlet         in project_structure_obj_t,
   p_rating_group   in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_outlet is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet');
   end if;
   assign_to_rating_group(project_structure_tab_t(p_outlet), p_rating_group);
end assign_to_rating_group;   
--------------------------------------------------------------------------------
-- procedure assign_to_rating_group
--------------------------------------------------------------------------------
procedure assign_to_rating_group(
   p_outlets        in project_structure_tab_t,
   p_rating_group   in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_outlets is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_outlets');
   end if;
   cwms_util.check_input(p_rating_group);
   for i in 1..p_outlets.count loop
      check_project_structure(p_outlets(i));
      assign_to_rating_group(
         p_outlets(i).structure_location.location_ref.get_location_code,
         p_outlets(i).project_location_ref.get_location_code,
         p_rating_group);
   end loop;
end assign_to_rating_group;   
--------------------------------------------------------------------------------
-- procedure store_gate_changes
--------------------------------------------------------------------------------
procedure store_gate_changes(
   p_gate_changes         in gate_change_tab_t,
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
   l_gate_change_date date;
   l_start_time       date;
   l_end_time         date;
   l_time_zone        varchar2(28);
   l_opening_param    varchar2(49);
   l_opening_unit     varchar2(16);
   l_change_rec       at_gate_change%rowtype;
   l_setting_rec      at_gate_setting%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_gate_changes is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_gate_changes');
   elsif p_gate_changes.count = 0 then
      cwms_err.raise('ERROR', 'No gate changes specified.');
   end if;
   for i in 1..p_gate_changes.count loop
      check_gate_change(p_gate_changes(i));
   end loop;
   cwms_util.check_inputs(str_tab_t(
      p_time_zone,
      p_start_time_inclusive,
      p_end_time_inclusive,
      p_override_protection));
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
   for i in 1..p_gate_changes.count loop
      if i = 1 then
         l_proj_loc_code    := p_gate_changes(i).project_location_ref.get_location_code;
         l_office_id        := upper(p_gate_changes(i).project_location_ref.get_office_id);
         l_office_code      := p_gate_changes(i).project_location_ref.get_office_code;
         l_gate_change_date := p_gate_changes(i).change_date; 
      else
         if p_gate_changes(i).project_location_ref.get_location_code != l_proj_loc_code then
            cwms_err.raise(
               'ERROR',
               'Multiple projects found in gate changes.');
         end if;
         if p_gate_changes(i).change_date <=l_gate_change_date then
            cwms_err.raise(
               'ERROR',
               'Gate changes are not in ascending time order.');
         end if;
      end if;
   end loop;      
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_start_time := nvl(p_start_time, p_gate_changes(1).change_date);
   l_end_time   := nvl(p_end_time,   p_gate_changes(p_gate_changes.count).change_date);
   l_time_zone  := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   l_start_time := cwms_util.change_timezone(l_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(l_end_time,   l_time_zone, 'UTC');
   ---------------------------------------------------------
   -- delete any existing gate changes in the time window --
   ---------------------------------------------------------
   delete_gate_changes(
      p_gate_changes(1).project_location_ref,
      l_start_time,
      l_end_time,
      'UTC',
      p_start_time_inclusive,
      p_end_time_inclusive,
      p_override_protection);
   ----------------------------
   -- insert the new records --
   ----------------------------
   for i in 1..p_gate_changes.count loop
      ------------------------
      -- more sanity checks --
      ------------------------
      if upper(p_gate_changes(i).discharge_computation.office_id) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'Gate change for office '
            ||l_office_id
            ||' cannot reference discharge computation for office '
            ||upper(p_gate_changes(i).discharge_computation.office_id));
      end if;   
      if upper(p_gate_changes(i).release_reason.office_id) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'Gate change for office '
            ||l_office_id
            ||' cannot reference release reason for office '
            ||upper(p_gate_changes(i).release_reason.office_id));
      end if;
      ---------------------------------------
      -- insert the new gate change record --
      ---------------------------------------   
      l_change_rec.gate_change_code := cwms_seq.nextval;
      l_change_rec.project_location_code := l_proj_loc_code;
      l_change_rec.gate_change_date := cwms_util.change_timezone(p_gate_changes(i).change_date, l_time_zone, 'UTC');
      l_change_rec.elev_pool := cwms_util.convert_units(
         p_gate_changes(i).elev_pool,
         p_gate_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.elev_pool := cwms_util.convert_units(
         p_gate_changes(i).elev_pool,
         p_gate_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.old_total_discharge_override := cwms_util.convert_units(
         p_gate_changes(i).old_total_discharge_override,
         p_gate_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      l_change_rec.new_total_discharge_override := cwms_util.convert_units(
         p_gate_changes(i).new_total_discharge_override,
         p_gate_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      begin
         select discharge_comp_code
           into l_change_rec.discharge_computation_code
           from at_gate_ch_computation_code
          where db_office_code = l_office_code
            and upper(discharge_comp_display_value) = upper(p_gate_changes(i).discharge_computation.display_value)
            and upper(discharge_comp_tooltip) = upper(p_gate_changes(i).discharge_computation.tooltip)
            and discharge_comp_active = upper(p_gate_changes(i).discharge_computation.active); 
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS gate change computation',
               l_office_id
               ||'/DISPLAY='
               ||p_gate_changes(i).discharge_computation.display_value
               ||'/TOOLTIP='
               ||p_gate_changes(i).discharge_computation.tooltip
               ||'/ACTIVE='
               ||p_gate_changes(i).discharge_computation.active);
      end;         
      begin
         select release_reason_code
           into l_change_rec.release_reason_code
           from at_gate_release_reason_code
          where db_office_code = l_office_code
            and upper(release_reason_display_value) = upper(p_gate_changes(i).release_reason.display_value)
            and upper(release_reason_tooltip) = upper(p_gate_changes(i).release_reason.tooltip)
            and release_reason_active = upper(p_gate_changes(i).release_reason.active); 
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS gate release reason',
               l_office_id
               ||'/DISPLAY='
               ||p_gate_changes(i).release_reason.display_value
               ||'/TOOLTIP='
               ||p_gate_changes(i).release_reason.tooltip
               ||'/ACTIVE='
               ||p_gate_changes(i).release_reason.active);
      end;
      l_change_rec.gate_change_notes := p_gate_changes(i).change_notes;
      l_change_rec.protected := upper(p_gate_changes(i).protected);
      insert into at_gate_change values l_change_rec;
      -------------------------------------
      -- insert new gate setting records --
      -------------------------------------
      if p_gate_changes(i).settings is not null and p_gate_changes(i).settings.count > 0 then
         for j in 1..p_gate_changes(i).settings.count loop
            l_setting_rec.gate_setting_code := cwms_seq.nextval;
            l_setting_rec.gate_change_code := l_change_rec.gate_change_code;
            l_setting_rec.outlet_location_code := p_gate_changes(i).settings(j).outlet_location_ref.get_location_code;
            l_opening_param := get_outlet_opening_param(l_setting_rec.outlet_location_code);
            l_setting_rec.gate_opening := cwms_util.convert_units(
               p_gate_changes(i).settings(j).opening,
               p_gate_changes(i).settings(j).opening_units,
               cwms_util.get_default_units(l_opening_param));
            insert into at_gate_setting values l_setting_rec;               
         end loop;         
      end if;
   end loop;       
end store_gate_changes;
--------------------------------------------------------------------------------
-- procedure retrieve_gate_changes
--------------------------------------------------------------------------------
procedure retrieve_gate_changes(
   p_gate_changes         out gate_change_tab_t,
   p_project_location     in  location_ref_t,
   p_start_time           in  date,
   p_end_time             in  date,
   p_time_zone            in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_start_time_inclusive in  varchar2 default 'T',
   p_end_time_inclusive   in  varchar2 default 'T',
   p_max_item_count       in  integer default null)
is
   type gate_change_db_tab_t is table of at_gate_change%rowtype;
   type gate_setting_db_tab_t is table of at_gate_setting%rowtype; 
   c_one_second    constant number := 1/86400;
   l_time_zone     varchar2(28);
   l_unit_system   varchar2(2);
   l_start_time    date;
   l_end_time      date;
   l_project       project_obj_t;
   l_proj_loc_code number(10);
   l_gate_changes  gate_change_db_tab_t;
   l_gate_settings gate_setting_db_tab_t;
   l_elev_unit     varchar2(16);
   l_flow_unit     varchar2(16);
   l_opening_param varchar2(49);
   l_opening_unit  varchar2(16);
   l_sql           varchar2(1024) := '
        select *
          from ( select *
                   from at_gate_change
                  where project_location_code = :project_location_code
                    and gate_change_date between :start_time and :end_time
               order by gate_change_date ~direction~
               ) 
         where rownum <= :max_items
      order by gate_change_date'; 
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
   cwms_util.check_inputs(str_tab_t(
      p_time_zone,
      p_start_time_inclusive,
      p_end_time_inclusive));
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
   -------------------------------------
   -- collect the gate change records --
   -------------------------------------
   if p_max_item_count is null then
      select * bulk collect
        into l_gate_changes
        from at_gate_change
       where project_location_code = l_proj_loc_code
         and gate_change_date between l_start_time and l_end_time
    order by gate_change_date;
       
   else
      if p_max_item_count < 0 then
         l_sql := replace(l_sql, '~direction~', 'desc');
      else
         l_sql := replace(l_sql, '~direction~', 'asc');
      end if;
      execute immediate l_sql bulk collect 
        into l_gate_changes 
       using l_proj_loc_code, 
             l_start_time, 
             l_end_time, 
             abs(p_max_item_count);
   end if;
   ----------------------------
   -- build the out variable --
   ----------------------------
   if l_gate_changes is not null and l_gate_changes.count > 0 then
      cwms_display.retrieve_unit(l_elev_unit, 'Elev', l_unit_system, p_project_location.get_office_id);
      cwms_display.retrieve_unit(l_flow_unit, 'Flow', l_unit_system, p_project_location.get_office_id);
      p_gate_changes := gate_change_tab_t();
      p_gate_changes.extend(l_gate_changes.count);
      for i in 1..l_gate_changes.count loop
         ------------------------
         -- gate change object --
         ------------------------
         p_gate_changes(i) := gate_change_obj_t(
            location_ref_t(l_gate_changes(i).project_location_code),
            cwms_util.change_timezone(l_gate_changes(i).gate_change_date, 'UTC', l_time_zone),
            cwms_util.convert_units(l_gate_changes(i).elev_pool, 'm', l_elev_unit),
            null, -- discharge_computation, set below
            null, -- release_reason, set below
            null, -- settings, set below 
            cwms_util.convert_units(l_gate_changes(i).elev_tailwater, 'm', l_elev_unit),
            l_elev_unit,
            cwms_util.convert_units(
               l_gate_changes(i).old_total_discharge_override, 
               'cms', 
               l_flow_unit),
            cwms_util.convert_units(
               l_gate_changes(i).new_total_discharge_override, 
               'cms', 
               l_flow_unit),
            l_flow_unit,
            l_gate_changes(i).gate_change_notes,
            l_gate_changes(i).protected);
         ---------------------------------
         -- discharge_computation field --
         ---------------------------------            
         select lookup_type_obj_t(
                   p_project_location.get_office_id, 
                   discharge_comp_display_value, 
                   discharge_comp_tooltip, 
                   discharge_comp_active)
           into p_gate_changes(i).discharge_computation
           from at_gate_ch_computation_code
          where discharge_comp_code = l_gate_changes(i).discharge_computation_code;
         --------------------------
         -- release_reason field --
         --------------------------             
         select lookup_type_obj_t(
                   p_project_location.get_office_id, 
                   release_reason_display_value, 
                   release_reason_tooltip, 
                   release_reason_active)
           into p_gate_changes(i).release_reason
           from at_gate_release_reason_code
          where release_reason_code = l_gate_changes(i).release_reason_code;
          --------------------
          -- settings field --
          --------------------
         select * bulk collect
           into l_gate_settings
           from at_gate_setting
          where gate_change_code = l_gate_changes(i).gate_change_code;
          
         if l_gate_settings is not null and l_gate_settings.count > 0 then
            p_gate_changes(i).settings := gate_setting_tab_t();
            p_gate_changes(i).settings.extend(l_gate_settings.count);
            for j in 1..l_gate_settings.count loop
               l_opening_param := get_outlet_opening_param(l_gate_settings(j).outlet_location_code);
               cwms_display.retrieve_unit(
                  l_opening_unit, 
                  l_opening_param, 
                  l_unit_system, 
                  p_project_location.get_office_id);
               p_gate_changes(i).settings(j) := gate_setting_obj_t(
                  location_ref_t(l_gate_settings(j).outlet_location_code),
                  cwms_util.convert_units(
                     l_gate_settings(j).gate_opening,
                     cwms_util.get_default_units(l_opening_param, 'SI'), 
                     l_opening_unit),
                  l_opening_param, 
                  l_opening_unit);                  
            end loop;
         end if;          
                                 
      end loop;
   end if;
end retrieve_gate_changes;
--------------------------------------------------------------------------------
-- function retrieve_gate_changes_f
--------------------------------------------------------------------------------
function retrieve_gate_changes_f(
   p_project_location      in location_ref_t,
   p_start_time            in date,
   p_end_time              in date,
   p_time_zone             in varchar2 default null,
   p_unit_system           in varchar2 default null,
   p_start_time_inclusive  in varchar2 default 'T',
   p_end_time_inclusive    in varchar2 default 'T',
   p_max_item_count        in integer default null)
   return gate_change_tab_t
is
   l_gate_changes gate_change_tab_t;
begin
   retrieve_gate_changes(
      l_gate_changes,
      p_project_location,
      p_start_time,
      p_end_time,
      p_time_zone,
      p_unit_system,
      p_start_time_inclusive,
      p_end_time_inclusive,
      p_max_item_count);
   return l_gate_changes;                 
end retrieve_gate_changes_f;   
--------------------------------------------------------------------------------
-- procedure delete_gate_changes
--------------------------------------------------------------------------------
procedure delete_gate_changes(
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
   l_gate_change_codes number_tab_t;
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
   cwms_util.check_inputs(str_tab_t(
      p_time_zone,
      p_start_time_inclusive,
      p_end_time_inclusive,
      p_override_protection));
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
   --------------------------------------------------------
   -- collect the gate change codes  and protected flags --
   --------------------------------------------------------
   select gate_change_code,
          protected
     bulk collect
     into l_gate_change_codes,
          l_protected_flags
     from at_gate_change
    where project_location_code = l_proj_loc_code
      and gate_change_date between l_start_time and l_end_time;
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
            'Cannot delete protected gate change(s).');
      end if;        
   end if;      
   ------------------------
   -- delete the records --
   ------------------------
   delete
     from at_gate_setting
    where gate_change_code in (select * from table(l_gate_change_codes));              
   delete
     from at_gate_change
    where gate_change_code in (select * from table(l_gate_change_codes));              
end delete_gate_changes;
--------------------------------------------------------------------------------
-- procedure set_gate_change_protection
--------------------------------------------------------------------------------
procedure set_gate_change_protection(
   p_project_location     in  location_ref_t,
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
   l_gate_change_codes number_tab_t;
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
   cwms_util.check_inputs(str_tab_t(
      p_protected,
      p_time_zone,
      p_start_time_inclusive,
      p_end_time_inclusive));
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
   update at_gate_change
      set protected = p_protected
    where project_location_code = l_proj_loc_code
      and gate_change_date between l_start_time and l_end_time;
end set_gate_change_protection;

end cwms_outlet;
/
show errors;
create or replace package body cwms_gate as

--------------------------------------------------------------------------------
-- PROCEDURE GET_RATING_GROUP_RECORD
function get_rating_group_record(
   p_rating_group_id in varchar2,
   p_office_id       in varchar2)
   return at_loc_group%rowtype
is
   l_rec         at_loc_group%rowtype;
   l_category_id at_loc_category.loc_category_id%type;
begin
   select *
     into l_rec
     from at_loc_group lg
    where lg.db_office_code = cwms_util.get_office_code(p_office_id)
      and upper(lg.loc_group_id) = upper(trim(p_rating_group_id));
      
   select loc_category_id
     into l_category_id
     from at_loc_category
    where loc_category_code = l_rec.loc_category_code; 

   if upper(l_category_id) != 'RATING' then
      cwms_err.raise(
         'ERROR',
         'Location group '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_rating_group_id
         ||' exists and does not belong to a ''RATING'' location category');
   end if;
      
   return l_rec;      
exception      
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Rating Group',
         cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||trim(p_rating_group_id));
         
end get_rating_group_record;

--------------------------------------------------------------------------------
-- PROCEDURE GET_GATE_GROUP_RECORD
function get_gate_group_record(
   p_gate_group_id in varchar2,
   p_office_id     in varchar2)
   return at_gate_group%rowtype
is
   l_loc_group_rec  at_loc_group%rowtype;
   l_gate_group_rec at_gate_group%rowtype;
begin
   l_loc_group_rec := get_rating_group_record(p_gate_group_id, p_office_id);
   select *
     into l_gate_group_rec
     from at_gate_group
    where loc_group_code = l_loc_group_rec.loc_group_code;
   return l_gate_group_rec;    
exception      
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Gate Group',
         cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||trim(p_gate_group_id));
         
end get_gate_group_record;
--------------------------------------------------------------------------------
-- PROCEDURE STORE_GATE_GROUP
procedure store_gate_group(
   p_gate_group_id          in varchar2,
   p_fail_if_exists         in varchar2,
   p_ignore_nulls           in varchar2,
   p_project_id             in varchar2 default null,
   p_rating_spec            in varchar2 default null,
   p_gate_type_id           in varchar2 default null,
   p_can_be_submerged       in varchar2 default null,
   p_always_submerged       in varchar2 default null,
   p_description            in varchar2 default null,
   p_office_id              in varchar2 default null)
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -20034);
   l_gate_group_rec   at_gate_group%rowtype;
   l_loc_group_rec    at_loc_group%rowtype;
   l_loc_category_rec at_loc_category%rowtype;
   l_office_code      integer;
   l_exists           boolean;
   l_update           boolean;
   l_rating_specs     rating_spec_tab_t;
   
   function get_gate_types return varchar2
   is
      ll_gate_types str_tab_t;
   begin
      select gate_type_id bulk collect into ll_gate_types from cwms_gate_type;
      return ''''||cwms_util.join_text(ll_gate_types, ''', ''')||'''';
   end get_gate_types;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_gate_group_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_Gate_Group');
   end if;
   if p_fail_if_exists is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_Fail_If_Exists');
   elsif p_fail_if_exists not in ('T', 'F') then
      cwms_err.raise('ERROR', 'Argument P_Fail_If_Exists must be ''T'' or ''F''');
   end if;
   if p_ignore_nulls is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_Ignore_Nulls');
   elsif p_ignore_nulls not in ('T', 'F') then
      cwms_err.raise('ERROR', 'Argument P_Ignore_Nulls must be ''T'' or ''F''');
   end if;
   if p_rating_spec is not null then
      l_rating_specs := cwms_rating.retrieve_specs_obj_f(
         p_spec_id_mask   => p_rating_spec,
         p_office_id_mask => p_office_id);
      if l_rating_specs.count = 0 then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Rating specification',
            p_rating_spec);
      end if;
   end if;
   ------------------------------
   -- get any existing records --
   ------------------------------
   begin
      l_gate_group_rec := get_gate_group_record(p_gate_group_id, p_office_id);
   exception
      when item_does_not_exist then null;
   end;
   begin
      l_loc_group_rec := get_rating_group_record(p_gate_group_id, p_office_id);
   exception
      when item_does_not_exist then null;
   end;
   if l_gate_group_rec.loc_group_code is not null and p_fail_if_exists = 'T' then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS', 
         'Gate group',
         cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_gate_group_id);
   end if;
   ------------------------------------
   -- populate and store the records --
   ------------------------------------
   l_office_code := cwms_util.get_office_code(p_office_id);
   if l_loc_group_rec.loc_group_code is null then
      -----------------------
      --  new rating group --
      -----------------------
      if p_rating_spec is null or p_project_id is null then
         cwms_err.raise(
            'ERROR',
            'Cannot create a rating location group without a project id and a rating specification');
      end if;
      begin
         select *
           into l_loc_category_rec
           from at_loc_category
          where upper(loc_category_id) = 'RATING'
            and db_office_code in (l_office_code, cwms_util.db_office_code_all);
      exception
         when no_data_found then
            l_loc_category_rec.loc_category_code := cwms_seq.nextval;
            l_loc_category_rec.loc_category_id   := 'Rating';
            l_loc_category_rec.db_office_code    := l_office_code;
            l_loc_category_rec.loc_category_desc := 'Category for rating groups';
            insert into at_loc_category values l_loc_category_rec;
      end;
      l_loc_group_rec.loc_group_code      := cwms_seq.nextval;
      l_loc_group_rec.loc_category_code   := l_loc_category_rec.loc_category_code;
      l_loc_group_rec.loc_group_id        := p_gate_group_id;
      l_loc_group_rec.loc_group_desc      := 'Rating group for outlets';
      l_loc_group_rec.db_office_code      := l_office_code;
      l_loc_group_rec.shared_loc_alias_id := p_rating_spec;
      l_loc_group_rec.shared_loc_ref_code := cwms_loc.get_location_code(l_office_code, p_project_id);
      insert into at_loc_group values l_loc_group_rec;
   else
      ---------------------------
      -- existing rating group --
      ---------------------------
      l_update := false;
      if p_rating_spec is not null and p_rating_spec != l_loc_group_rec.shared_loc_alias_id then
         l_loc_group_rec.shared_loc_alias_id := p_rating_spec;
         l_update := true;
      end if;
      if p_project_id  is not null and (l_loc_group_rec.shared_loc_ref_code is null or l_loc_group_rec.shared_loc_ref_code != cwms_loc.get_location_code(l_office_code, p_project_id)) then
         l_loc_group_rec.shared_loc_ref_code := cwms_loc.get_location_code(l_office_code, p_project_id);
         l_update := true;
      end if;
      if l_update then
         update at_loc_group set row = l_loc_group_rec where loc_group_code = l_loc_group_rec.loc_group_code;
      end if;
   end if;
   if  l_gate_group_rec.loc_group_code is null then
      --------------------
      -- new gate group --
      --------------------
      l_gate_group_rec.loc_group_code := l_loc_group_rec.loc_group_code;
      begin
         select gate_type_code
           into l_gate_group_rec.gate_type_code
           from cwms_gate_type
          where gate_type_id = upper(trim(p_gate_type_id));
      exception
         when no_data_found then
            cwms_err.raise(
               'ERROR',
               'Argument P_Gate_Type_Id ('
               ||nvl(p_gate_type_id, '<NULL>')
               ||') must be one of '
               ||get_gate_types
               ||' when creating a new gate group');
      end;
      if p_can_be_submerged not in ('T', 'F') then
         cwms_err.raise(
            'ERROR', 
            'Argument P_Can_Be_Submerged ('
            ||nvl(p_can_be_submerged, '<NULL>')
            ||') must be ''T'' or ''F'' when creating a new gate group');
      end if;
      l_gate_group_rec.can_be_submerged := p_can_be_submerged;      
      if p_always_submerged not in ('T', 'F') then
         cwms_err.raise(
            'ERROR', 
            'Argument P_Always_Submerged ('
            ||nvl(p_always_submerged, '<NULL>')
            ||') must be ''T'' or ''F'' when creating a new gate group');
      end if;
      l_gate_group_rec.always_submerged := p_always_submerged;
      l_gate_group_rec.description := p_description;
      insert into at_gate_group values l_gate_group_rec;
   else
      -------------------------
      -- existing gate group --
      -------------------------
      l_update := false;
      if p_gate_type_id is not null then
         begin
            select gate_type_code
              into l_gate_group_rec.gate_type_code
              from cwms_gate_type
             where gate_type_id = upper(trim(p_gate_type_id));
            l_update := true;             
         exception
            when no_data_found then
               cwms_err.raise(
                  'ERROR',
                  'Argument P_Gate_Type_Id ('
                  ||p_gate_type_id
                  ||') must be one of '
                  ||get_gate_types);
         end;
      end if;
      if p_can_be_submerged is not null then
         if p_can_be_submerged not in ('T', 'F') then
            cwms_err.raise(
               'ERROR', 
               'Argument P_Can_Be_Submerged ('
               ||p_can_be_submerged
               ||') must be NULL, ''T'' or ''F'' when updating an existing gate group');
         end if;
         l_gate_group_rec.can_be_submerged := p_can_be_submerged;
         l_update := true;
      end if;
      if p_always_submerged is not null then
         if p_always_submerged not in ('T', 'F') then
            cwms_err.raise(
               'ERROR', 
               'Argument P_Always_Submerged ('
               ||p_always_submerged
               ||') must be NULL, ''T'' or ''F'' when updating an existing gate group');
         end if;
         l_gate_group_rec.always_submerged := p_always_submerged;
         l_update := true;
      end if;
      if p_description is not null or p_ignore_nulls = 'F' then
         l_gate_group_rec.description := p_description;
         l_update := true;
      end if;
      if l_update then
         update at_gate_group set row = l_gate_group_rec where loc_group_code = l_gate_group_rec.loc_group_code;
      end if;
   end if;
   
end store_gate_group;
   
--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_GATE_GROUP
procedure retreive_gate_group(
   p_project_id             out varchar2,
   p_rating_spec            out varchar2,
   p_gate_type_id           out varchar2,
   p_can_be_submerged       out varchar2,
   p_always_submerged       out varchar2,
   p_description            out varchar2,
   p_gate_group_id          in  varchar2,
   p_office_id              in  varchar2 default null)
is
   l_gate_group_rec at_gate_group%rowtype;
   l_loc_group_rec  at_loc_group%rowtype;
begin
   l_gate_group_rec   := get_gate_group_record(p_gate_group_id, p_office_id);
   l_loc_group_rec    := get_rating_group_record(p_gate_group_id, p_office_id);
   p_project_id       := cwms_loc.get_location_id(l_loc_group_rec.shared_loc_ref_code);
   p_rating_spec      := l_loc_group_rec.shared_loc_alias_id;
   p_can_be_submerged := l_gate_group_rec.can_be_submerged;
   p_always_submerged := l_gate_group_rec.always_submerged;
   p_description      := l_gate_group_rec.description;
   select gate_type_id
     into p_gate_type_id
     from cwms_gate_type
    where gate_type_code = l_gate_group_rec.gate_type_code; 
end retreive_gate_group;
   
--------------------------------------------------------------------------------
-- PROCEDURE STORE_GATE
procedure store_gate(
   p_gate_group_id  in varchar2,
   p_fail_if_exists in varchar2,
   p_gate_location  in varchar2,
   p_sort_order     in number   default null,
   p_office_id      in varchar2 default null)
is
begin
   store_gates(
      p_gate_group_id,
      p_fail_if_exists,
      str_tab_t(p_gate_location),
      case when p_sort_order is null then null
           else number_tab_t(p_sort_order)
           end,
      case when p_sort_order is null then 'F'
           else 'T'
           end,
      p_office_id);
end store_gate;
   
--------------------------------------------------------------------------------
-- PROCEDURE STORE_GATES
procedure store_gates(
   p_gate_group_id  in varchar2,
   p_fail_if_exists in varchar2,
   p_gate_locations in varchar2,
   p_sort_order     in varchar2 default null,
   p_set_sort_order in varchar2 default 'F',
   p_office_id      in varchar2 default null)
is
   l_sort_order number_tab_t;
begin
   if p_sort_order is not null then
      select to_number(column_value)
        bulk collect
        into l_sort_order
        from table(cwms_util.split_text(regexp_replace(p_sort_order, '\s*,\s*', ','), ','));
   end if;
   store_gates(
      p_gate_group_id,
      p_fail_if_exists,
      cwms_util.split_text(regexp_replace(p_gate_locations, '\s*,\s*', ','), ','),
      l_sort_order,
      p_set_sort_order,
      p_office_id);
end store_gates;
   
--------------------------------------------------------------------------------
-- PROCEDURE STORE_GATES
procedure store_gates(
   p_gate_group_id  in varchar2,
   p_fail_if_exists in varchar2,
   p_gate_locations in str_tab_t,
   p_sort_order     in number_tab_t default null,
   p_set_sort_order in varchar2     default 'F',
   p_office_id      in varchar2     default null)
is
   location_id_not_found exception;
   pragma exception_init(location_id_not_found, -20025);
   l_gate_group_rec      at_gate_group%rowtype;
   l_loc_group_rec       at_loc_group%rowtype;
   l_loc_group_assgn_rec at_loc_group_assignment%rowtype;
   l_office_code         integer;
   l_count               pls_integer;
   l_base_location_code  integer;
   l_location_code       integer;
   l_project_id          varchar2(57);
   l_parts               str_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_gate_group_id  is null then cwms_err.raise('NULL_ARGUMENT', 'P_Gate_Group_Id');  end if;
   if p_fail_if_exists is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fail_If_Exists'); end if;
   if p_gate_locations is null then cwms_err.raise('NULL_ARGUMENT', 'P_Gate_Locations'); end if;
   if p_set_sort_order not in ('T', 'F') then
      cwms_err.raise('ERROR', 'Argument P_Set_Sort_Order must be ''T'' or ''F''');
   end if;
   if p_set_sort_order = 'T' and p_sort_order is not null and p_sort_order.count != p_gate_locations.count then
      cwms_err.raise('ERROR', 'Arguments P_Gate_Locations and P_Sort_Order have different lengths');
   end if;
   -----------
   -- setup --
   -----------
   l_gate_group_rec := get_gate_group_record(p_gate_group_id, p_office_id);
   l_loc_group_rec  := get_rating_group_record(p_gate_group_id, p_office_id);
   l_project_id     := cwms_loc.get_location_id(l_loc_group_rec.shared_loc_ref_code);
   l_office_code    := cwms_util.get_office_code(p_office_id);
   ---------------------------
   -- process each location --
   ---------------------------
   for i in 1..p_gate_locations.count loop
      -------------------------------------
      -- retrieve or create the location --
      -------------------------------------
      begin
         l_location_code := cwms_loc.get_location_code(l_office_code, p_gate_locations(i));
         select count(*)
           into l_count
           from at_loc_category lc,
                at_loc_group lg,
                at_loc_group_assignment lga
          where lga.location_code = l_location_code
            and lg.loc_group_code = lga.loc_group_code
            and lc.loc_category_code = lg.loc_category_code
            and upper(lc.loc_category_id) = 'RATING';
         if l_count > 0 and cwms_util.is_true(p_fail_if_exists) then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'CWMS gate or outlet location '
               ||cwms_util.get_db_office_id(p_office_id)
               ||'/'
               ||p_gate_locations(i));
         end if;
      exception
         when location_id_not_found then
            l_parts := cwms_util.split_text(p_gate_locations(i), '-', 1);
            if l_parts.count != 2 or upper(l_parts(1)) != upper(l_project_id) then
               cwms_err.raise(
                  'ERROR',
                  'Cannot create a location that isn''t a sub-location of the group''s project location');
            end if;
            -----------------------------
            -- create the sub-location --
            -----------------------------
            cwms_loc.create_location_raw2(
               p_base_location_code => l_base_location_code,
               p_location_code      => l_location_code,
               p_base_location_id   => l_parts(1),
               p_sub_location_id    => l_parts(2),
               p_db_office_code     => l_office_code);
      end;
      --------------------------------------
      -- make the rating group assignment --
      --------------------------------------
      begin
         l_loc_group_assgn_rec.location_code := null;
         select *
           into l_loc_group_assgn_rec
           from at_loc_group_assignment
          where location_code = l_location_code
            and loc_group_code = l_loc_group_rec.loc_group_code;
      exception
         when no_data_found then null;
      end;
      if l_loc_group_assgn_rec.location_code is null then
         --------------------
         -- new assignment --
         --------------------
         l_loc_group_assgn_rec.location_code  := l_location_code;
         l_loc_group_assgn_rec.loc_group_code := l_loc_group_rec.loc_group_code;
         l_loc_group_assgn_rec.office_code    := l_office_code;
         if p_set_sort_order = 'T' then
            if p_sort_order is null then
               l_loc_group_assgn_rec.loc_attribute := i;
            else
               l_loc_group_assgn_rec.loc_attribute := p_sort_order(i);
            end if;
         end if;
         insert into at_loc_group_assignment values l_loc_group_assgn_rec;
      else
         ------------------------
         -- updated assignment --
         ------------------------
         if p_set_sort_order = 'T' then
            if p_sort_order is null then
               update at_loc_group_assignment 
                  set loc_attribute = i 
                where location_code = l_location_code
                  and loc_group_code = l_loc_group_rec.loc_group_code;
            else
               update at_loc_group_assignment 
                  set loc_attribute = p_sort_order(i) 
                where location_code = l_location_code
                  and loc_group_code = l_loc_group_rec.loc_group_code;
            end if;
         end if;
      end if;
      if not cwms_loc.can_store(l_location_code, 'GATE') then
         if cwms_loc.can_store(l_location_code, 'OUTLET') then
            cwms_outlet.store_outlet(
               project_structure_obj_t(
                  location_ref_t(
                     l_project_id, 
                     p_office_id),
                  location_obj_t(
                     location_ref_t(
                        p_gate_locations(i), 
                        p_office_id)),
                  null),
               p_gate_group_id,
               'F');
         else
            cwms_err.raise(
               'ERROR',
               'Cannot store gate information to location '
               ||cwms_util.get_db_office_id(p_office_id)
               ||'/'
               ||p_gate_locations(i)
               ||' (location kind = '
               ||cwms_loc.check_location_kind(l_location_code)
               ||')');
         end if;
      end if;
      cwms_loc.update_location_kind(l_location_code, 'GATE', 'A');
   end loop;
end store_gates;
   
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_GATE_GROUP
procedure delete_gate_group(
   p_gate_group_id         in varchar2,
   p_delete_rating_group   in varchar2 default 'F',
   p_delete_gate_locations in varchar2 default 'F',
   p_delete_gates_action   in varchar2 default 'DELETE KEY',
   p_office_id             in varchar2 default null)
is
   l_gate_group_rec at_gate_group%rowtype;
   l_loc_group_rec  at_loc_group%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_gate_group_id is null then 
      cwms_err.raise('NULL_ARGUMENT', 'P_Gate_Group_Id'); 
   end if;
   if p_delete_rating_group not in ('T', 'F') then
      cwms_err.raise('ERROR', 'Argument P_Delete_Rating_Group must be ''T'' or ''F''');
   end if;
   if p_delete_gate_locations not in ('T', 'F') then
      cwms_err.raise('ERROR', 'Argument P_Delete_Gate_Locations must be ''T'' or ''F''');
   end if;
   if p_delete_gates_action not in (cwms_util.delete_key, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'Argument P_Delete_Gates_Action must be one of '''
         ||cwms_util.delete_key
         ||''', or '
         ||cwms_util.delete_all
         ||'''');
   end if;
   -----------
   -- setup --
   -----------
   l_gate_group_rec := get_gate_group_record(p_gate_group_id, p_office_id);
   l_loc_group_rec  := get_rating_group_record(p_gate_group_id, p_office_id);
   -----------------
   -- do the work --
   -----------------
   delete from at_gate_group where loc_group_code = l_gate_group_rec.loc_group_code;
   if p_delete_gate_locations = 'T' then
      delete_gates(
         get_gates_f(p_gate_group_id, p_office_id),
         p_delete_gates_action,
         p_office_id);
   end if;
   if p_delete_rating_group = 'T' then
      delete from at_loc_group_assignment where loc_group_code = l_loc_group_rec.loc_group_code;
      delete from at_loc_group where loc_group_code = l_loc_group_rec.loc_group_code;
   end if;
end delete_gate_group;
   
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_GATE
procedure delete_gate(
   p_gate_location in varchar2,
   p_delete_action in varchar2,
   p_office_id     in varchar2 default null)
is
begin
   delete_gates(
      str_tab_t(p_gate_location),
      p_delete_action,
      p_office_id);
end delete_gate;
   
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_GATES
procedure delete_gates(
   p_gate_locations in varchar2,
   p_delete_action  in varchar2,
   p_office_id      in varchar2 default null)
is
begin
   delete_gates(
      cwms_util.split_text(regexp_replace(p_gate_locations, '\s*,\s*', ','), ','),
      p_delete_action,
      p_office_id);
end delete_gates;
   
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_GATES
procedure delete_gates(
   p_gate_locations in str_tab_t,
   p_delete_action  in varchar2,
   p_office_id      in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_gate_locations is null then cwms_err.raise('NULL_ARGUMENT', 'P_Gate_Locations'); end if;
   if p_delete_action not in (cwms_util.delete_key, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'Argument P_Delete_Action must be one of '''
         ||cwms_util.delete_key
         ||''', or '
         ||cwms_util.delete_all
         ||'''');
   end if;
   -----------------
   -- do the work --
   -----------------
   for i in 1..p_gate_locations.count loop
      if p_delete_action = cwms_util.delete_all then
         cwms_loc.delete_location(p_gate_locations(i), p_delete_action, p_office_id);
      else
         cwms_loc.update_location_kind(
            cwms_loc.get_location_code(p_office_id, p_gate_locations(i)),
            'GATE',
            'D');
      end if;
   end loop;
end delete_gates;
   
--------------------------------------------------------------------------------
-- PROCEDURE RENAME_GATE_GROUP
procedure rename_gate_group(
   p_old_gate_group_id in varchar2,
   p_new_gate_group_id in varchar2,
   p_office_id         in varchar2 default null)
is
begin
   cwms_loc.rename_loc_group(
      p_loc_category_id	 => 'Rating',
      p_loc_group_id_old => p_old_gate_group_id,
      p_loc_group_id_new => p_new_gate_group_id,
      p_db_office_id	    => p_office_id);
end rename_gate_group;
   
--------------------------------------------------------------------------------
-- PROCEDURE GET_GATES
procedure get_gates(
   p_gate_locations out str_tab_t,
   p_gate_group_id  in  varchar2,
   p_office_id      in  varchar2 default null)
is
   l_office_code integer;
begin
   l_office_code := cwms_util.get_office_code(p_office_id);
   select cwms_loc.get_location_id(lga.location_code)
     bulk collect
     into p_gate_locations
     from at_loc_group_assignment lga,
          at_loc_group lg,
          at_loc_category lc
    where upper(lc.loc_category_id) = 'RATING'
      and lc.db_office_code in (l_office_code, cwms_util.db_office_code_all)
      and lg.loc_category_code = lc.loc_category_code
      and lg.db_office_code = l_office_code 
      and upper(lg.loc_group_id) = upper(p_gate_group_id)
      and lga.loc_group_code = lg.loc_group_code;
end get_gates;
   
--------------------------------------------------------------------------------
-- FUNCTION GET_GATES_F
function get_gates_f(
   p_gate_group_id  in varchar2,
   p_office_id      in varchar2 default null)
   return str_tab_t
is
   l_gate_locations str_tab_t;
begin
   get_gates(
      l_gate_locations,
      p_gate_group_id,
      p_office_id);
      
   return l_gate_locations;      
end get_gates_f;
   
end cwms_gate;
/

show errors;
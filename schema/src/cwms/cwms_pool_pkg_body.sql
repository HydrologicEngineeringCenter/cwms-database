create or replace package body cwms_pool
as
--------------------------------------------------------------------------------
-- private procedure store_pool_name
--------------------------------------------------------------------------------
procedure store_pool_name(
   p_pool_name_code out integer,
   p_pool_name      in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null)
is
   l_exists         boolean;
   l_fail_if_exists boolean;
   l_office_id      varchar2(16);
   l_rec            at_pool_name%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   -----------
   -- setup --
   -----------
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   ---------------------------
   -- see if already exists --
   ---------------------------
   begin
      select *
        into l_rec
        from at_pool_name
       where office_code in (cwms_util.db_office_code_all, cwms_util.get_db_office_code(l_office_id))
         and upper(pool_name) = upper(p_pool_name);
      l_exists := true;
   exception
      when no_data_found then l_exists := false;
   end;
   if l_exists then
      if l_fail_if_exists then
         ---------------
         -- error out --
         ---------------
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Pool name',
            l_office_id
            ||'/'
            ||p_pool_name);
      elsif l_rec.office_code != cwms_util.user_office_code and
            cwms_util.user_office_code != cwms_util.db_office_code_all
      then
         -----------------------------
         -- insufficient permission --
         -----------------------------
         cwms_err.raise(
            'ERROR',
            'Cannot store '
            ||cwms_util.get_db_office_id_from_code(l_rec.office_code)
            ||'-owned pool name from office '
            ||cwms_util.user_office_id);
      end if;
      ----------------------------------------------------
      -- update the existing record (only changes case) --
      ----------------------------------------------------
      update at_pool_name
         set pool_name = p_pool_name
       where pool_name_code = l_rec.pool_name_code;
   else
      -------------------------
      -- insert a new record --
      -------------------------
      insert
        into at_pool_name
      values (cwms_seq.nextval,
              cwms_util.get_db_office_code(l_office_id),
              p_pool_name
             )
   returning pool_name_code
        into l_rec.pool_name_code;
   end if;
   p_pool_name_code := l_rec.pool_name_code;
end store_pool_name;
--------------------------------------------------------------------------------
-- procedure store_pool_name
--------------------------------------------------------------------------------
procedure store_pool_name(
   p_pool_name      in varchar2,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null)
is
   l_pool_name_code integer;
begin
   store_pool_name(l_pool_name_code, p_pool_name, p_fail_if_exists, p_office_id);
end store_pool_name;
--------------------------------------------------------------------------------
-- procedure rename_pool
--------------------------------------------------------------------------------
procedure rename_pool(
   p_old_name  in varchar2,
   p_new_name  in varchar2,
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16);
   l_rec       at_pool_name%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_old_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_OLD_NAME');
   end if;
   if p_new_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_NEW_NAME');
   end if;
   -----------
   -- setup --
   -----------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   begin
      select *
        into l_rec
        from at_pool_name
       where office_code in (cwms_util.get_db_office_code(l_office_id), cwms_util.db_office_code_all)
      and upper(pool_name) = upper(p_old_name);
   exception
      when no_data_found then
         cwms_err.raise('ITEM DOES NOT EXIST', 'Pool name', l_office_id||'/'||p_old_name);
   end;
   if l_rec.office_code != cwms_util.user_office_code and
      cwms_util.user_office_code != cwms_util.db_office_code_all
   then
      -----------------------------
      -- insufficient permission --
      -----------------------------
      cwms_err.raise(
         'ERROR',
         'Cannot delete '
         ||l_office_id
         ||'-owned pool name from office '
         ||cwms_util.user_office_id);
   end if;
   ---------------------
   -- rename the pool --
   ---------------------
   update at_pool_name
      set pool_name = p_new_name
    where pool_name_code = l_rec.pool_name_code;
end rename_pool;
--------------------------------------------------------------------------------
-- procedure delete_pool_name
--------------------------------------------------------------------------------
procedure delete_pool_name(
   p_pool_name     in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_office_id varchar2(16);
   l_rec       at_pool_name%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_delete_action not in (cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be one of '''
         ||cwms_util.delete_key
         ||''', '''
         ||cwms_util.delete_data
         ||''', '''
         ||cwms_util.delete_all
         ||'''');
   end if;
   -----------
   -- setup --
   -----------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   begin
      select *
        into l_rec
        from at_pool_name
       where office_code in (cwms_util.get_db_office_code(l_office_id), cwms_util.db_office_code_all)
      and upper(pool_name) = upper(p_pool_name);
   exception
      when no_data_found then
         cwms_err.raise('ITEM DOES NOT EXIST', 'Pool name', l_office_id||'/'||p_pool_name);
   end;
   if l_rec.office_code != cwms_util.user_office_code and
      cwms_util.user_office_code != cwms_util.db_office_code_all
   then
      -----------------------------
      -- insufficient permission --
      -----------------------------
      cwms_err.raise(
         'ERROR',
         'Cannot delete '
         ||l_office_id
         ||'-owned pool name from office '
         ||cwms_util.user_office_id);
   end if;
   if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      -----------------------------
      -- delete associated pools --
      -----------------------------
      for rec in (select pool_code from at_pool where pool_name_code = l_rec.pool_name_code) loop
         delete_pool(rec.pool_code);
      end loop;
   end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      -----------------------
      -- delete the record --
      -----------------------
      delete
        from at_pool_name
       where office_code = cwms_util.get_db_office_code(l_office_id)
         and upper(pool_name) = upper(p_pool_name);
   end if;
end delete_pool_name;
--------------------------------------------------------------------------------
-- procedure cat_pool_names
--------------------------------------------------------------------------------
procedure cat_pool_names(
   p_cat_cursor     out sys_refcursor,
   p_pool_name_mask in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null)
is
   l_pool_name_mask  varchar2(32);
   l_office_id_regex varchar2(32);
begin
   l_pool_name_mask := cwms_util.normalize_wildcards(upper(nvl(p_pool_name_mask, '*')));
   if p_office_id_mask is null then
      l_office_id_regex := cwms_util.user_office_id;
      if l_office_id_regex = 'CWMS' then
         l_office_id_regex := '.+';
      else
         l_office_id_regex := l_office_id_regex||'|CWMS';
      end if;
   else
      l_office_id_regex := replace(replace(upper(p_office_id_mask), '*', '.*'), '?', '.?');
   end if;
   open p_cat_cursor for
      select o.office_id,
             p.pool_name
        from at_pool_name p,
             cwms_office o
       where upper(p.pool_name) like l_pool_name_mask escape '\'
         and o.office_code = p.office_code
         and regexp_like(o.office_id, l_office_id_regex);
end cat_pool_names;
--------------------------------------------------------------------------------
-- function cat_pool_names_f
--------------------------------------------------------------------------------
function cat_pool_names_f(
   p_pool_name_mask in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
   cat_pool_names(
      l_cat_cursor,
      p_pool_name_mask,
      p_office_id_mask);

   return l_cat_cursor;
end cat_pool_names_f;
--------------------------------------------------------------------------------
-- procedure store_pool
--------------------------------------------------------------------------------
procedure store_pool(
   p_project_id       in varchar2,
   p_pool_name        in varchar2,
   p_bottom_level_id  in varchar2,
   p_top_level_id     in varchar2,
   p_fail_if_exists   in varchar2 default 'T',
   p_create_pool_name in varchar2 default 'F',
   p_office_id        in varchar2 default null)
is
   l_clob_code integer;
begin
   l_clob_code := store_pool2_f(
      p_project_id,
      p_pool_name,
      p_bottom_level_id,
      p_top_level_id,
      null,
      null,
      null,
      p_fail_if_exists,
      p_create_pool_name,
      p_office_id);
end store_pool;
--------------------------------------------------------------------------------
-- procedure store_pool2
--------------------------------------------------------------------------------
procedure store_pool2(
   p_project_id       in varchar2,
   p_pool_name        in varchar2,
   p_bottom_level_id  in varchar2,
   p_top_level_id     in varchar2,
   p_attribute        in number   default null,
   p_description      in varchar2 default null,
   p_clob_text        in clob     default null,
   p_fail_if_exists   in varchar2 default 'T',
   p_create_pool_name in varchar2 default 'F',
   p_office_id        in varchar2 default null)
is
   l_clob_code integer;
begin
   l_clob_code := store_pool2_f(
      p_project_id,
      p_pool_name,
      p_bottom_level_id,
      p_top_level_id,
      p_attribute,
      p_description,
      p_clob_text,
      p_fail_if_exists,
      p_create_pool_name,
      p_office_id);
end store_pool2;
--------------------------------------------------------------------------------
-- function store_pool2_f
--------------------------------------------------------------------------------
function store_pool2_f(
   p_project_id       in varchar2,
   p_pool_name        in varchar2,
   p_bottom_level_id  in varchar2,
   p_top_level_id     in varchar2,
   p_attribute        in number   default null,
   p_description      in varchar2 default null,
   p_clob_text        in clob     default null,
   p_fail_if_exists   in varchar2 default 'T',
   p_create_pool_name in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return integer
is
   l_project          project_obj_t;
   l_location_id      varchar2(57);
   l_office_id        varchar2(16);
   l_bottom_level_id  varchar2(256);
   l_top_level_id     varchar2(256);
   l_exists           boolean;
   l_fail_if_exists   boolean;
   l_create_pool_name boolean;
   l_pool_name_exists boolean;
   l_rec              at_pool%rowtype;
   l_office_code      integer;
   l_location_code    integer;
   l_pool_name_code   integer;
   l_parts            str_tab_t;
   l_location_level   location_level_t;
begin
   l_office_code      := cwms_util.get_db_office_code(p_office_id);
   l_office_id        := cwms_util.get_db_office_id_from_code(l_office_code);
   l_fail_if_exists   := cwms_util.is_true(p_fail_if_exists);
   l_create_pool_name := cwms_util.is_true(p_create_pool_name);
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_bottom_level_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_BOTTOM_LEVEL_ID');
   end if;
   if p_top_level_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TOP_LEVEL_ID');
   end if;
   if l_office_code != cwms_util.user_office_code and cwms_util.user_office_code != cwms_util.db_office_code_all then
      -----------------------------
      -- insufficient privileges --
      -----------------------------
      cwms_err.raise(
         'ERROR',
         'Cannot store '
         ||l_office_id
         ||'-owned pool while office is '
         ||cwms_util.user_office_id);
   end if;
   cwms_project.retrieve_project(l_project, p_project_id, p_office_id); -- will barf if doesn't exist
   l_location_id   := l_project.project_location.location_ref.get_location_id;
   l_location_code := l_project.project_location.location_ref.get_location_code;
   ---------------------------------------
   -- validate bottom location level id --
   ---------------------------------------
   l_parts := cwms_util.split_text(p_bottom_level_id, '.');
   select cast(multiset(select initcap(column_value) from table(l_parts)) as str_tab_t)
     into l_parts
     from dual;
   case
   when l_parts.count = 4 then
      if l_parts(1) != 'Elev' or
         l_parts(2) != 'Inst' or
         l_parts(3) != '0'
      then
         cwms_err.raise(
            'ERROR',
            'Bottom location level ID is not Elev.Inst.0.<specified_level>');
      end if;
      l_bottom_level_id := cwms_util.join_text(l_parts, '.');
   when l_parts.count = 5 then
      if l_parts(2) != 'Elev' or
         l_parts(3) != 'Inst' or
         l_parts(4) != '0'
      then
         cwms_err.raise(
            'ERROR',
            'Bottom location level ID is not <location>.Elev.Inst.0.<specified_level>');
      end if;
      l_bottom_level_id := cwms_util.join_text(cwms_util.sub_table(l_parts, 2), '.');
   else
      cwms_err.raise('INVALID_ITEM', p_bottom_level_id, 'location level ID');
   end case;
   l_location_level := cwms_level.retrieve_location_level(
      p_location_level_id => l_location_id||'.'||l_bottom_level_id,
      p_level_units       => 'ft',
      p_date              => sysdate,
      p_office_id         => p_office_id);
   if l_location_level is null then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level',
         cwms_util.get_db_office_id_from_code(l_office_code)
         ||'/'
         || l_location_id||'.'||l_bottom_level_id);
   end if;
   ------------------------------------
   -- validate top location level id --
   ------------------------------------
   l_parts := cwms_util.split_text(p_top_level_id, '.');
   select cast(multiset(select initcap(column_value) from table(l_parts)) as str_tab_t)
     into l_parts
     from dual;
   case
   when l_parts.count = 4 then
      if l_parts(1) != 'Elev' or
         l_parts(2) != 'Inst' or
         l_parts(3) != '0'
      then
         cwms_err.raise(
            'ERROR',
            'Top location level ID is not Elev.Inst.0.<specified_level>');
      end if;
      l_top_level_id := cwms_util.join_text(l_parts, '.');
   when l_parts.count = 5 then
      if l_parts(2) != 'Elev' or
         l_parts(3) != 'Inst' or
         l_parts(4) != '0'
      then
         cwms_err.raise(
            'ERROR',
            'Top location level ID is not <location>.Elev.Inst.0.<specified_level>');
      end if;
      l_top_level_id := cwms_util.join_text(cwms_util.sub_table(l_parts, 2), '.');
   else
      cwms_err.raise('INVALID_ITEM', p_top_level_id, 'location level ID');
   end case;
   l_location_level := cwms_level.retrieve_location_level(
      p_location_level_id => l_location_id||'.'||l_top_level_id,
      p_level_units       => 'ft',
      p_date              => sysdate,
      p_office_id         => p_office_id);
   if l_location_level is null then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level',
         cwms_util.get_db_office_id_from_code(l_office_code)
         ||'/'
         || l_location_id||'.'||l_top_level_id);
   end if;
   -----------------------------------------------------
   -- deterimine whether the pool name already exists --
   -----------------------------------------------------
   begin
      select pool_name_code
        into l_pool_name_code
        from at_pool_name
       where upper(pool_name) = upper(p_pool_name)
         and office_code in (l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         if l_create_pool_name then
            --------------------------
            -- create the pool name --
            --------------------------
            store_pool_name(
               l_pool_name_code,
               p_pool_name,
               'T',
               cwms_util.get_db_office_id_from_code(l_office_code));
         else
            ---------------
            -- error out --
            ---------------
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Pool name',
               cwms_util.get_db_office_id_from_code(l_office_code)
               ||'/'
               || p_pool_name);
         end if;
   end;
   ------------------------------------------------------
   -- determine whether pool definition already exists --
   ------------------------------------------------------
   begin
      select *
        into l_rec
        from at_pool
       where pool_name_code = l_pool_name_code
         and project_code = l_location_code;
      l_exists := true;
   exception
      when no_data_found then l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      ---------------
      -- error out --
      ---------------
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Pool',
         cwms_util.get_db_office_id_from_code(l_office_code)
         ||'/'
         ||l_location_id
         ||' : '
         ||p_pool_name);
   end if;
   ----------------------------------
   -- finish populating the record --
   ----------------------------------
   l_rec.pool_name_code := l_pool_name_code;
   l_rec.project_code   := l_location_code;
   l_rec.bottom_level   := l_bottom_level_id;
   l_rec.top_level      := l_top_level_id;
   l_rec.attribute      := p_attribute;
   l_rec.description    := p_description;
   if p_clob_text is not null and dbms_lob.getlength(p_clob_text) > 0 then
      l_rec.clob_code := cwms_text.store_text(
         p_text           => p_clob_text,
         p_id             => '/POOL/'||upper(p_project_id)||'/'||upper(p_pool_name),
         p_description    => p_description,
         p_fail_if_exists => 'F',
         p_office_id      => cwms_util.get_db_office_id_from_code(l_office_code));
   end if;
   ---------------------------------
   -- insert or update the record --
   ---------------------------------
   if l_exists then
      update at_pool set row = l_rec where pool_code = l_rec.pool_code;
   else
      l_rec.pool_code := cwms_seq.nextval;
      insert into at_pool values l_rec;
   end if;
   return l_rec.clob_code;
end store_pool2_f;
--------------------------------------------------------------------------------
-- procedure retrieve_pool
--------------------------------------------------------------------------------
procedure retrieve_pool(
   p_bottom_level_id  out varchar2,
   p_top_level_id     out varchar2,
   p_project_id       in  varchar2,
   p_pool_name        in  varchar2,
   p_office_id        in  varchar2 default null)
is
   l_attribute   number;
   l_description varchar2(128);
   l_clob_text   clob;
begin
   retrieve_pool2(
      p_bottom_level_id,
      p_top_level_id,
      l_attribute,
      l_description,
      l_clob_text,
      p_project_id,
      p_pool_name,
      p_office_id);
end retrieve_pool;
--------------------------------------------------------------------------------
-- function retrieve_pool_f
--------------------------------------------------------------------------------
function retrieve_pool_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_office_id  in  varchar2 default null)
   return str_tab_t
is
   l_bottom_level varchar2(256);
   l_top_level    varchar2(256);
begin
   retrieve_pool(
      l_bottom_level,
      l_top_level,
      p_project_id,
      p_pool_name,
      p_office_id);

   return str_tab_t(l_bottom_level, l_top_level);
end retrieve_pool_f;
--------------------------------------------------------------------------------
-- procedure retrieve_pool2
--------------------------------------------------------------------------------
procedure retrieve_pool2(
   p_bottom_level_id  out varchar2,
   p_top_level_id     out varchar2,
   p_attribute        out number,
   p_description      out varchar2,
   p_clob_text        out clob,
   p_project_id       in  varchar2,
   p_pool_name        in  varchar2,
   p_office_id        in  varchar2 default null)
is
   l_rec         at_pool%rowtype;
   l_office_code integer;
   l_office_id   varchar2(16);
begin
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   l_office_id   := cwms_util.get_db_office_id_from_code(l_office_code);
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   begin
      ----------------------------
      -- look for explicit pool --
      ----------------------------
      select *
        into l_rec
        from at_pool
       where project_code = cwms_loc.get_location_code(l_office_code, p_project_id)
         and pool_name_code = (select pool_name_code
                                 from at_pool_name
                                where upper(pool_name) = upper(p_pool_name)
                                  and at_pool_name.office_code in (l_office_code, cwms_util.db_office_code_all)
                              );
   exception
      when no_data_found then
         ----------------------------
         -- look for implicit pool --
         ----------------------------
         begin
            select replace(top_level, 'Top of ', 'Bottom of '),
                   top_level
              into l_rec.bottom_level,
                   l_rec.top_level
              from (select bp.base_parameter_id
                           ||'.'||pt.parameter_type_id
                           ||'.'||d.duration_id
                           ||'.'||sp.specified_level_id as top_level,
                           max(ll.location_level_date) -- instead of select distinct
                      from at_location_level ll,
                           at_project pr,
                           at_physical_location pl,
                           at_base_location bl,
                           cwms_office o,
                           at_parameter p,
                           cwms_base_parameter bp,
                           cwms_parameter_type pt,
                           cwms_duration d,
                           at_specified_level sp
                     where o.office_id = upper(p_office_id)
                       and bl.base_location_id
                           ||substr('.', 1, length(pl.sub_location_id))
                           ||pl.sub_location_id = upper(p_project_id)
                       and upper(trim(substr(specified_level_id, 8))) = upper(p_pool_name)
                       and pr.project_location_code = ll.location_code
                       and pl.location_code = pr.project_location_code
                       and bl.base_location_code = pl.base_location_code
                       and o.office_code = bl.db_office_code
                       and p.parameter_code = ll.parameter_code
                       and p.sub_parameter_id is null
                       and bp.base_parameter_code = p.base_parameter_code
                       and bp.base_parameter_id = 'Elev'
                       and pt.parameter_type_code = ll.parameter_type_code
                       and pt.parameter_type_id = 'Inst'
                       and d.duration_code = ll.duration_code
                       and d.duration_id = '0'
                       and sp.specified_level_code = ll.specified_level_code
                       and instr(sp.specified_level_id, 'Top of ') = 1
                       and attribute_value is null
                       and exists (select pool_name
                                     from at_pool_name
                                    where upper(pool_name) = upper(trim(substr(specified_level_id, 8)))
                                      and office_code in (o.office_code, 53)
                                  )
                       and exists (select ll2.location_code,
                                          ll2.parameter_code,
                                          ll2.parameter_type_code,
                                          ll2.duration_code,
                                          sp2.specified_level_code
                                     from at_location_level ll2,
                                          at_specified_level sp2
                                    where ll2.location_code = ll.location_code
                                      and ll2.parameter_code = ll.parameter_code
                                      and ll2.parameter_type_code = ll.parameter_type_code
                                      and ll2.duration_code = ll.duration_code
                                      and ll2.attribute_value is null
                                      and sp2.specified_level_code = ll2.specified_level_code
                                      and sp2.specified_level_id = replace(sp.specified_level_id, 'Top of ', 'Bottom of ')
                                  )
                     group by bp.base_parameter_id||'.'||pt.parameter_type_id||'.'||d.duration_id||'.'||sp.specified_level_id
                   );
         exception
            when no_data_found then
               ---------------
               -- error out --
               ---------------
               cwms_err.raise(
                  'ITEM_DOES_NOT_EXIST',
                  'Pool',
                  l_office_id
                  ||'/'
                  ||p_project_id
                  ||' : '
                  ||p_pool_name);
         end;
   end;
   p_bottom_level_id := l_rec.bottom_level;
   p_top_level_id    := l_rec.top_level;
   p_attribute       := l_rec.attribute;
   p_description     := l_rec.description;
   if l_rec.clob_code is not null then
      select value into p_clob_text from at_clob where clob_code = l_rec.clob_code;
   end if;
end retrieve_pool2;
--------------------------------------------------------------------------------
-- procedure delete_pool
--------------------------------------------------------------------------------
procedure delete_pool(
   p_pool_code in integer)
is
   l_rec       at_pool%rowtype;
   l_office_id varchar2(16);
begin
   begin
      select *
        into l_rec
        from at_pool
       where pool_code = p_pool_code;
   exception
      when no_data_found then
         ---------------
         -- error out --
         ---------------
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Pool',
            p_pool_code);
   end;
   select o.office_id
     into l_office_id
     from at_physical_location pl,
          at_base_location bl,
          cwms_office o
    where pl.location_code = l_rec.project_code
      and bl.base_location_code = pl.base_location_code
      and o.office_code = bl.db_office_code;

   if cwms_util.user_office_id not in (l_office_id, 'CWMS', 'SYS') then
      -----------------------------
      -- insufficient privileges --
      -----------------------------
      cwms_err.raise(
         'ERROR',
         'Cannot delete '
         ||l_office_id
         ||'-owned pool while office is '
         ||cwms_util.user_office_id);
   end if;
   ------------------------------------
   -- delete the record and children --
   ------------------------------------
   delete from at_pool where pool_code = l_rec.pool_code;
   if l_rec.clob_code is not null then
      delete from at_clob where clob_code = l_rec.clob_code;
   end if;
end delete_pool;
--------------------------------------------------------------------------------
-- procedure delete_pool
--------------------------------------------------------------------------------
procedure delete_pool(
   p_project_id in varchar2,
   p_pool_name  in varchar2,
   p_office_id  in varchar2 default null)
is
   l_pool_code   integer;
   l_office_code integer;
   l_office_id   varchar2(16);
begin
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   l_office_id   := cwms_util.get_db_office_id_from_code(l_office_code);
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   begin
      select pool_code
        into l_pool_code
        from at_pool
       where pool_name_code = (select pool_name_code from at_pool_name where upper(pool_name) = upper(p_pool_name))
         and project_code = cwms_loc.get_location_code(l_office_code, p_project_id);
   exception
      when no_data_found then
         ---------------
         -- error out --
         ---------------
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Pool',
            l_office_id
            ||'/'
            ||p_project_id
            ||' : '
            ||p_pool_name);
   end;
   -----------------------
   -- delete the record --
   -----------------------
   delete_pool(l_pool_code);
end delete_pool;
--------------------------------------------------------------------------------
-- procedure cat_pools
--------------------------------------------------------------------------------
procedure cat_pools(
    p_cat_cursor        out sys_refcursor,
    p_project_id_mask   in  varchar2 default '*',
    p_pool_name_mask    in  varchar2 default '*',
    p_bottom_level_mask in  varchar2 default '*',
    p_top_level_mask    in  varchar2 default '*',
    p_include_explicit  in  varchar2 default 'T',
    p_include_implicit  in  varchar2 default 'T',
    p_office_id_mask    in  varchar2 default null)
    is
    l_include_explicit  boolean;
    l_include_implicit  boolean;
    l_project_id_mask   varchar2(57);
    l_pool_name_mask    varchar2(32);
    l_bottom_level_mask varchar2(256);
    l_top_level_mask    varchar2(256);
    l_office_id_mask    varchar2(16);
    l_implicit_query    varchar2(32767);
    l_explicit_query    varchar2(32767);
    l_query             varchar2(32767);
begin
    l_project_id_mask   := cwms_util.normalize_wildcards(upper(nvl(p_project_id_mask, '*')));
    l_pool_name_mask    := cwms_util.normalize_wildcards(upper(nvl(p_pool_name_mask, '*')));
    l_bottom_level_mask := cwms_util.normalize_wildcards(upper(nvl(p_bottom_level_mask, '*')));
    l_top_level_mask    := cwms_util.normalize_wildcards(upper(nvl(p_top_level_mask, '*')));
    l_office_id_mask    := cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.user_office_id)));
    l_include_explicit  := cwms_util.return_true_or_false(p_include_explicit);
    l_include_implicit  := cwms_util.return_true_or_false(p_include_implicit);

    l_explicit_query := '
      select office_id,
             project_id,
             pool_name,
             bottom_level_id,
             top_level_id,
             attribute,
             description,
             q1.clob_code,
             q2.value as clob_text
        from (select o.office_id,
                     bl.base_location_id||substr(''.'', 1, length(pl.sub_location_id))||pl.sub_location_id as project_id,
                     pn.pool_name,
                     po.bottom_level as bottom_level_id,
                     po.top_level as top_level_id,
                     po.attribute,
                     po.description,
                     po.clob_code
                from at_pool po,
                     at_pool_name pn,
                     cwms_office o,
                     at_project pr,
                     at_physical_location pl,
                     at_base_location bl
               where pr.project_location_code = po.project_code
                 and pl.location_code = pr.project_location_code
                 and bl.base_location_code = pl.base_location_code
                 and o.office_code = bl.db_office_code
                 and pn.pool_name_code = po.pool_name_code
             ) q1
             left outer join
             (select clob_code,
                     value
                from at_clob
             ) q2 on q2.clob_code = q1.clob_code
   ';

    l_implicit_query := '
      select office_id,
             project_id,
             pool_name,
             ''Elev.Inst.0.''||bottom_level_id as bottom_level_id,
             ''Elev.Inst.0.''||top_level_id as top_level_id,
             null as attribute,
             null as description,
             null as clob_code,
             null as clob_text
        from (select distinct
                     o.office_id,
                     bl.base_location_id||substr(''.'', 1, length(pl.sub_location_id))||pl.sub_location_id as project_id,
                     trim(replace(specified_level_id, ''Bottom of '', null)) as pool_name,
                     specified_level_id as bottom_level_id,
                     replace(specified_level_id, ''Bottom of '', ''Top of '') as top_level_id
                from at_specified_level sl,
                     at_location_level ll,
                     at_project pr,
                     at_physical_location pl,
                     at_base_location bl,
                     cwms_office o
               where pr.project_location_code = ll.location_code
                 and pl.location_code = pr.project_location_code
                 and bl.base_location_code = pl.base_location_code
                 and o.office_code = bl.db_office_code
                 and ll.parameter_code = (select base_parameter_code from cwms_base_parameter where base_parameter_id = ''Elev'')
                 and ll.parameter_type_code = (select parameter_type_code from cwms_parameter_type where parameter_type_id = ''Inst'')
                 and ll.duration_code = (select duration_code from cwms_duration where duration_id = ''0'')
                 and sl.specified_level_code = ll.specified_level_code
                 and sl.specified_level_id like ''Bottom of %''
                 and exists (select specified_level_id
                               from at_specified_level
                              where office_code = sl.office_code
                                and specified_level_id = replace(sl.specified_level_id, ''Bottom of'', ''Top of'')
                            )
                 and not exists (select project_code,
                                        bottom_level,
                                        top_level
                                   from at_pool
                                  where project_code = pr.project_location_code
                                    and upper(bottom_level) = upper(''Elev.Inst.0.''||sl.specified_level_id)
                                    and upper(top_level)    = upper(''Elev.Inst.0.''||replace(sl.specified_level_id, ''Bottom of '', ''Top of ''))
                                )
             )
   ';

    if l_include_explicit or l_include_implicit then
        l_query := '
         select office_id,
                project_id,
                pool_name,
                bottom_level_id as bottom_level,
                top_level_id as top_level,
                attribute,
                description,
                clob_code,
                clob_text
           from (';
        if l_include_explicit then
            if l_include_implicit then
                ---------------------------
                -- explicit and implicit --
                ---------------------------
                l_query := l_query||l_explicit_query||chr(10)||'union all'||chr(10)||l_implicit_query;
            else
                -------------------
                -- explicit only --
                -------------------
                l_query := l_query||l_explicit_query;
            end if;
        elsif l_include_implicit then
            -------------------
            -- implicit only --
            -------------------
            l_query := l_query||l_implicit_query;
        end if;
        l_query := l_query||')'
            ||chr(10)||'where upper(office_id) like upper(:office_id_mask) escape ''\'''
            ||chr(10)||'  and upper(project_id) like upper(:project_id_mask) escape ''\'''
            ||chr(10)||'  and upper(pool_name) like upper(:pool_name_mask) escape ''\'''
            ||chr(10)||'  and upper(project_id || ''.'' || bottom_level_id) like upper(:bottom_level_mask) escape ''\'''
            ||chr(10)||'  and upper(project_id || ''.'' || top_level_id) like upper(:top_level_mask) escape ''\'''
            ||chr(10)||'order by 1, 2, 6, 3';

        open p_cat_cursor for l_query using l_office_id_mask, l_project_id_mask, l_pool_name_mask, l_bottom_level_mask, l_top_level_mask;
    else
        -----------------------------------
        -- neither implicit nor explicit --
        -----------------------------------
        open p_cat_cursor for select null from dual where 1 = 2;
    end if;
end cat_pools;
--------------------------------------------------------------------------------
-- function cat_pools_f
--------------------------------------------------------------------------------
function cat_pools_f(
   p_project_id_mask   in varchar2 default '*',
   p_pool_name_mask    in varchar2 default '*',
   p_bottom_level_mask in varchar2 default '*',
   p_top_level_mask    in varchar2 default '*',
   p_include_explicit  in varchar2 default 'T',
   p_include_implicit  in varchar2 default 'T',
   p_office_id_mask    in varchar2 default null)
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
   cat_pools(
      l_cat_cursor,
      p_project_id_mask,
      p_pool_name_mask,
      p_bottom_level_mask,
      p_top_level_mask,
      p_include_explicit,
      p_include_implicit,
      p_office_id_mask);

   return l_cat_cursor;
end cat_pools_f;
--------------------------------------------------------------------------------
-- procedure in_pool
--------------------------------------------------------------------------------
procedure in_pool(
   p_in_pool    out varchar2,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_elevation  in  number,
   p_unit       in  varchar2,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
is
begin
   p_in_pool := in_pool_f(
      p_project_id,
      p_elevation,
      p_unit,
      p_datetime,
      p_timezone,
      p_office_id);
end in_pool;
--------------------------------------------------------------------------------
-- function in_pool_f
--------------------------------------------------------------------------------
function in_pool_f(
   p_project_id in varchar2,
   p_pool_name  in varchar2,
   p_elevation  in number,
   p_unit       in varchar2,
   p_datetime   in date default null,
   p_timezone   in varchar2 default null,
   p_office_id  in varchar2 default null)
   return varchar2
is
   l_top_elev  number;
   l_bot_elev  number;
begin
   get_pool_limit_elevs(
      p_bottom_elev => l_bot_elev,
      p_top_elev    => l_top_elev,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_unit        => p_unit,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);

   return case
          when p_elevation > l_bot_elev and p_elevation <= l_top_elev then 'T'
          else 'F'
          end;
end in_pool_f;
--------------------------------------------------------------------------------
-- procedure cat_containing_pool_names
--------------------------------------------------------------------------------
procedure cat_containing_pool_names(
   p_pool_names out sys_refcursor,
   p_project_id in  varchar2,
   p_elevation  in  number,
   p_unit       in  varchar2,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
is
   type rec_t is record(
      office_id       varchar2(16),
      project_id      varchar2(191),
      pool_name       varchar2(32),
      bottom_level_id varchar2(256),
      top_level_id    varchar2(256));
   l_office_id varchar2(16);
   l_matched   str_tab_t;
   l_rec       rec_t;
   l_top_elev  number;
   l_bot_elev  number;
   c           sys_refcursor;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_elevation is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_ELEVATION');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;

   l_matched := str_tab_t();
   cat_pools(
      p_cat_cursor        => c,
      p_project_id_mask   => p_project_id,
      p_pool_name_mask    => '*',
      p_bottom_level_mask => '*',
      p_top_level_mask    => '*',
      p_include_explicit  => 'T',
      p_include_implicit  => 'T',
      p_office_id_mask    => l_office_id);
   loop
      fetch c into l_rec;
      exit when c%notfound;
      get_pool_limit_elevs(
         p_bottom_elev => l_bot_elev,
         p_top_elev    => l_top_elev,
         p_project_id  => p_project_id,
         p_pool_name   => l_rec.pool_name,
         p_unit        => p_unit,
         p_datetime    => p_datetime,
         p_timezone    => p_timezone,
         p_office_id   => l_office_id);
      if p_elevation > l_bot_elev and p_elevation <= l_top_elev then
         l_matched.extend;
         l_matched(l_matched.count) := l_rec.pool_name;
      end if;
   end loop;
   close c;
   open p_pool_names for select column_value as pool_name from table(l_matched);
end cat_containing_pool_names;
--------------------------------------------------------------------------------
-- function cat_containing_pool_names_f
--------------------------------------------------------------------------------
function cat_containing_pool_names_f(
   p_project_id in varchar2,
   p_elevation  in number,
   p_unit       in varchar2,
   p_datetime   in date default null,
   p_timezone   in varchar2 default null,
   p_office_id  in varchar2 default null)
   return sys_refcursor
is
   l_pool_names sys_refcursor;
begin
   cat_containing_pool_names(
      l_pool_names,
      p_project_id,
      p_elevation,
      p_unit,
      p_datetime,
      p_timezone,
      p_office_id);

   return l_pool_names;
end cat_containing_pool_names_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elev
--------------------------------------------------------------------------------
procedure get_pool_limit_elev(
   p_limit_elev out number,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_datetime   in  date     default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
is
   l_office_id    varchar2(16);
   l_datetime     date;
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
   l_level_id     varchar2(256);
   l_limit_is_top boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   case
   when instr('TOP',    upper(p_limit)) = 1 then l_limit_is_top := true;
   when instr('BOTTOM', upper(p_limit)) = 1 then l_limit_is_top := false;
   else cwms_err.raise('ERROR', 'P_LMIT must be ''TOP'' or ''BOTTOM'', or an initial substring of either');
   end case;

   ---------------------------------
   -- set up info from parameters --
   ---------------------------------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   if p_datetime is null then
      l_datetime := sysdate;
   else
      l_datetime := cwms_util.change_timezone(
         p_datetime,
         'UTC',
         nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id)));
   end if;
   -----------------------
   -- get the pool info --
   -----------------------
   retrieve_pool(
      l_bot_level_id,
      l_top_level_id,
      p_project_id,
      p_pool_name,
      l_office_id);
   l_level_id := p_project_id
                 ||'.'
                 ||case
                   when l_limit_is_top then l_top_level_id
                   else l_bot_level_id
                   end;
   -----------------------------------------------------------------
   -- get the location level value at the specified time and unit --
   -----------------------------------------------------------------
   p_limit_elev := cwms_rounding.round_nn_f(
      cwms_level.retrieve_location_level_value (
         p_location_level_id => l_level_id,
         p_level_units       => p_unit,
         p_date              => l_datetime,
         p_office_id         => l_office_id),
      '7777777777');
end get_pool_limit_elev;
--------------------------------------------------------------------------------
-- function get_pool_limit_elev_f
--------------------------------------------------------------------------------
function get_pool_limit_elev_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_datetime   in  date     default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number
is
   l_limit_elev number;
begin
	get_pool_limit_elev(
      p_limit_elev => l_limit_elev,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => p_limit,
      p_unit       => p_unit,
      p_datetime   => p_datetime,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

   return l_limit_elev;
end get_pool_limit_elev_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elevs
--------------------------------------------------------------------------------
procedure get_pool_limit_elevs(
   p_bottom_elev out number,
   p_top_elev    out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_unit        in  varchar2,
   p_datetime    in  date     default null,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_office_id    varchar2(16);
   l_datetime     date;
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   ---------------------------------
   -- set up info from parameters --
   ---------------------------------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   if p_datetime is null then
      l_datetime := sysdate;
   else
      l_datetime := cwms_util.change_timezone(
         p_datetime,
         'UTC',
         nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id)));
   end if;
   -----------------------
   -- get the pool info --
   -----------------------
   retrieve_pool(
      l_bot_level_id,
      l_top_level_id,
      p_project_id,
      p_pool_name,
      l_office_id);

   l_bot_level_id := p_project_id||'.'||l_bot_level_id;
   l_top_level_id := p_project_id||'.'||l_top_level_id;
   ------------------------------------------------------------------
   -- get the location levels value at the specified time and unit --
   ------------------------------------------------------------------
   p_bottom_elev := cwms_rounding.round_nn_f(
      cwms_level.retrieve_location_level_value (
         p_location_level_id => l_bot_level_id,
         p_level_units       => p_unit,
         p_date              => l_datetime,
         p_office_id         => l_office_id),
      '7777777777');

   p_top_elev := cwms_rounding.round_nn_f(
      cwms_level.retrieve_location_level_value (
         p_location_level_id => l_top_level_id,
         p_level_units       => p_unit,
         p_date              => l_datetime,
         p_office_id         => l_office_id),
      '7777777777');
end get_pool_limit_elevs;
--------------------------------------------------------------------------------
-- function get_pool_limit_elevs_f
--------------------------------------------------------------------------------
function get_pool_limit_elevs_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_datetime       in  date     default null,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
   return number_tab_t
is
   l_bottom_elev number;
   l_top_elev    number;
begin
   get_pool_limit_elevs(
      l_bottom_elev,
      l_top_elev,
      p_project_id,
      p_pool_name,
      p_unit,
      p_datetime,
      p_timezone,
      p_office_id);

   return number_tab_t(l_bottom_elev, l_top_elev);
end get_pool_limit_elevs_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elevs
--------------------------------------------------------------------------------
procedure get_pool_limit_elevs(
   p_limit_elevs out number_tab_t,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_office_id    varchar2(16);
   l_limit_elevs  number_tab_t;
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
   l_level_id     varchar2(256);
   l_limit_is_top boolean;
   l_timezone     varchar2(28);
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_timezone  := nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id));
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   case
   when instr('TOP',    upper(p_limit)) = 1 then l_limit_is_top := true;
   when instr('BOTTOM', upper(p_limit)) = 1 then l_limit_is_top := false;
   else cwms_err.raise('ERROR', 'P_LMIT must be ''TOP'' or ''BOTTOM'', or an initial substring of either');
   end case;
   -----------------------
   -- get the pool info --
   -----------------------
   retrieve_pool(
      l_bot_level_id,
      l_top_level_id,
      p_project_id,
      p_pool_name,
      l_office_id);
   l_level_id := p_project_id
                 ||'.'
                 ||case
                   when l_limit_is_top then l_top_level_id
                   else l_bot_level_id
                   end;
   -------------------------------------------------------------------
   -- get the location level value2 at the specified time2 and unit --
   -------------------------------------------------------------------
   l_limit_elevs := number_tab_t();
   l_limit_elevs.extend(p_datetimes.count);
   for i in 1..p_datetimes.count loop
      l_limit_elevs(i) := cwms_rounding.round_nn_f(
         cwms_level.retrieve_location_level_value (
            p_location_level_id => l_level_id,
            p_level_units       => p_unit,
            p_date              => cwms_util.change_timezone(p_datetimes(i),'UTC', l_timezone),
            p_office_id         => l_office_id),
         '7777777777');
   end loop;
   p_limit_elevs := l_limit_elevs;
end get_pool_limit_elevs;
--------------------------------------------------------------------------------
-- function get_pool_limit_elevs_f
--------------------------------------------------------------------------------
function get_pool_limit_elevs_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_datetimes  in  date_table_type,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number_tab_t
is
   l_limit_elevs  number_tab_t;
begin
   get_pool_limit_elevs(
      p_limit_elevs => l_limit_elevs,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_datetimes   => p_datetimes,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);
	return l_limit_elevs;
end get_pool_limit_elevs_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elevs
--------------------------------------------------------------------------------
procedure get_pool_limit_elevs(
   p_bottom_elevs out number_tab_t,
   p_top_elevs    out number_tab_t,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   l_office_id    varchar2(16);
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
   l_timezone     varchar2(28);
   l_datetime     date;
   l_bottom_elevs number_tab_t;
   l_top_elevs    number_tab_t;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_timezone := nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id));
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   -----------------------
   -- get the pool info --
   -----------------------
   retrieve_pool(
      l_bot_level_id,
      l_top_level_id,
      p_project_id,
      p_pool_name,
      l_office_id);

   l_bot_level_id := p_project_id||'.'||l_bot_level_id;
   l_top_level_id := p_project_id||'.'||l_top_level_id;
   ------------------------------------------------------------------
   -- get the location levels value at the specified time and unit --
   ------------------------------------------------------------------
   l_bottom_elevs := number_tab_t();
   l_bottom_elevs.extend(p_datetimes.count);
   l_top_elevs := number_tab_t();
   l_top_elevs.extend(p_datetimes.count);
   for i in 1..p_datetimes.count loop
      l_datetime := cwms_util.change_timezone(p_datetimes(i), 'UTC', l_timezone);
      l_bottom_elevs(i) := cwms_rounding.round_nn_f(
         cwms_level.retrieve_location_level_value (
            p_location_level_id => l_bot_level_id,
            p_level_units       => p_unit,
            p_date              => l_datetime,
            p_office_id         => l_office_id),
         '7777777777');

      l_top_elevs(i) := cwms_rounding.round_nn_f(
         cwms_level.retrieve_location_level_value (
            p_location_level_id => l_top_level_id,
            p_level_units       => p_unit,
            p_date              => l_datetime,
            p_office_id         => l_office_id),
         '7777777777');
   end loop;
   p_bottom_elevs := l_bottom_elevs;
   p_top_elevs    := l_top_elevs;
end get_pool_limit_elevs;
--------------------------------------------------------------------------------
-- function get_pool_limit_elevs_f
--------------------------------------------------------------------------------
function get_pool_limit_elevs_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_datetimes      in  date_table_type,
   p_timezone       in  varchar2 default null,
   p_datetime_axis  in  varchar2 default 'ROW',
   p_office_id      in  varchar2 default null)
   return number_tab_tab_t
is
   l_bottom_elevs number_tab_t;
   l_top_elevs    number_tab_t;
   l_results      number_tab_tab_t;
   l_row_axis     boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;
   get_pool_limit_elevs(
      p_bottom_elevs => l_bottom_elevs,
      p_top_elevs    => l_top_elevs,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_datetimes    => p_datetimes,
      p_timezone     => p_timezone,
      p_office_id    => p_office_id);

   if l_row_axis then
      l_results := number_tab_tab_t();
      l_results.extend(p_datetimes.count);
      for i in 1..p_datetimes.count loop
         l_results(i) := number_tab_t(l_bottom_elevs(i), l_top_elevs(i));
      end loop;
   else
      l_results := number_tab_tab_t(l_bottom_elevs, l_top_elevs);
   end if;
	return l_results;
end get_pool_limit_elevs_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elevs
--------------------------------------------------------------------------------
procedure get_pool_limit_elevs(
   p_limit_elevs out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_timeseries  in  ztsv_array,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_elevs       number_tab_t;
   l_datetimes   date_table_type;
   l_limit_ts    ztsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

	select date_time
	  bulk collect
	  into l_datetimes
	  from table(p_timeseries);
	
   get_pool_limit_elevs(
      p_limit_elevs => l_elevs,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_datetimes   => l_datetimes,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);

   l_limit_ts := ztsv_array();
   l_limit_ts.extend(p_timeseries.count);
   for i in 1..p_timeseries.count loop
      l_limit_ts(i) := ztsv_type(p_timeseries(i).date_time, l_elevs(i), 0);
   end loop;
   p_limit_elevs := l_limit_ts;
end get_pool_limit_elevs;
--------------------------------------------------------------------------------
-- function get_pool_limit_elevs_f
--------------------------------------------------------------------------------
function get_pool_limit_elevs_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_timeseries in  ztsv_array,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array
is
   l_limit_elevs ztsv_array;
begin
   get_pool_limit_elevs(
      p_limit_elevs => l_limit_elevs,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_timeseries  => p_timeseries,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);

	return l_limit_elevs;
end get_pool_limit_elevs_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elevs
--------------------------------------------------------------------------------
procedure get_pool_limit_elevs(
   p_bottom_elevs out ztsv_array,
   p_top_elevs    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   l_top_elevs    number_tab_t;
   l_bottom_elevs number_tab_t;
   l_datetimes    date_table_type;
   l_bottom_ts    ztsv_array;
   l_top_ts       ztsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

	select date_time
	  bulk collect
	  into l_datetimes
	  from table(p_timeseries);
	
   get_pool_limit_elevs(
      p_bottom_elevs => l_bottom_elevs,
      p_top_elevs    => l_top_elevs,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_datetimes    => l_datetimes,
      p_timezone     => p_timezone,
      p_office_id    => p_office_id);

   l_bottom_ts := ztsv_array();
   l_bottom_ts.extend(p_timeseries.count);
   l_top_ts := ztsv_array();
   l_top_ts.extend(p_timeseries.count);
   for i in 1..p_timeseries.count loop
      l_bottom_ts(i) := ztsv_type(p_timeseries(i).date_time, l_bottom_elevs(i), 0);
      l_top_ts(i)    := ztsv_type(p_timeseries(i).date_time, l_top_elevs(i), 0);
   end loop;
   p_bottom_elevs := l_bottom_ts;
   p_top_elevs    := l_top_ts;
end get_pool_limit_elevs;
--------------------------------------------------------------------------------
-- function get_pool_limit_elevs_f
--------------------------------------------------------------------------------
function get_pool_limit_elevs_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_timeseries     in  ztsv_array,
   p_timezone       in  varchar2 default null,
   p_datetime_axis  in  varchar2 default 'ROW',
   p_office_id      in  varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_ts ztsv_array;
   l_top_ts    ztsv_array;
   l_results   ztsv_array_tab;
   l_row_axis  boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;
   get_pool_limit_elevs(
      p_bottom_elevs => l_bottom_ts,
      p_top_elevs    => l_top_ts,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_timeseries   => p_timeseries,
      p_timezone     => p_timezone,
      p_office_id    => p_office_id);

   if l_row_axis then
      l_results := ztsv_array_tab();
      l_results.extend(l_bottom_ts.count);
      for i in 1..l_bottom_ts.count loop
         l_results(i) := ztsv_array(l_bottom_ts(i), l_top_ts(i));
      end loop;
   else
      l_results := ztsv_array_tab(l_bottom_ts, l_top_ts);
   end if;
	return l_results;
end get_pool_limit_elevs_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elevs
--------------------------------------------------------------------------------
procedure get_pool_limit_elevs(
   p_limit_elevs out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_tsid        in  varchar2,
   p_start_time  in  date,
   p_end_time    in  date,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id != 'Elev' then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not an elevation time series');
   end if;
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  p_unit,
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_pool_limit_elevs(
      p_limit_elevs => p_limit_elevs,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_timeseries  => l_ts2,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);

end get_pool_limit_elevs;
--------------------------------------------------------------------------------
-- function get_pool_limit_elevs_f
--------------------------------------------------------------------------------
function get_pool_limit_elevs_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_tsid       in  varchar2,
   p_start_time in  date,
   p_end_time   in  date,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array
is
   l_limit_elevs ztsv_array;
begin
   get_pool_limit_elevs(
      p_limit_elevs => l_limit_elevs,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_tsid        => p_tsid,
      p_start_time  => p_start_time,
      p_end_time    => p_end_time,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);

	return l_limit_elevs;
end get_pool_limit_elevs_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_elevs
--------------------------------------------------------------------------------
procedure get_pool_limit_elevs(
   p_bottom_elevs out ztsv_array,
   p_top_elevs    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id != 'Elev' then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not an elevation time series');
   end if;
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  p_unit,
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_pool_limit_elevs(
      p_bottom_elevs => p_bottom_elevs,
      p_top_elevs    => p_top_elevs,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_timeseries   => l_ts2,
      p_timezone     => p_timezone,
      p_office_id    => p_office_id);

end get_pool_limit_elevs;
--------------------------------------------------------------------------------
-- function get_pool_limit_elevs_f
--------------------------------------------------------------------------------
function get_pool_limit_elevs_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_tsid          in  varchar2,
   p_start_time    in  date,
   p_end_time      in  date,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_elevs ztsv_array;
   l_top_elevs    ztsv_array;
   l_results      ztsv_array_tab;
   l_row_axis     boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;
   get_pool_limit_elevs(
      p_bottom_elevs => l_bottom_elevs,
      p_top_elevs    => l_top_elevs,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_tsid         => p_tsid,
      p_start_time   => p_start_time,
      p_end_time     => p_end_time,
      p_timezone     => p_timezone,
      p_office_id    => p_office_id);

   if l_row_axis then
      l_results := ztsv_array_tab();
      l_results.extend(l_bottom_elevs.count);
      for i in 1..l_bottom_elevs.count loop
         l_results(i) := ztsv_array(l_bottom_elevs(i), l_top_elevs(i));
      end loop;
   else
      l_results := ztsv_array_tab(l_bottom_elevs, l_top_elevs);
   end if;
	return l_results;
end get_pool_limit_elevs_f;
--------------------------------------------------------------------------------
-- private function get_elev_stor_rating
--------------------------------------------------------------------------------
function get_elev_stor_rating(
   p_project_id in varchar2,
   p_office_id  in varchar2 default null)
   return varchar2
is
   l_office_id varchar2(16);
   l_rating_id varchar2(512);
begin
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   select bl.base_location_id
          ||substr('-', 1, length(pl.sub_location_id))
          ||pl.sub_location_id
          ||'.'||rt.parameters_id
          ||'.'||rt.version
          ||'.'||rs.version
     into l_rating_id
     from at_physical_location pl,
          at_base_location bl,
          cwms_office o,
          at_rating_spec rs,
          at_rating_template rt
    where bl.db_office_code = o.office_code
      and pl.base_location_code = bl.base_location_code
      and rs.location_code = pl.location_code
      and rt.template_code = rs.template_code
      and rt.parameters_id = 'Elev;Stor'
      and o.office_id = l_office_id
      and upper(bl.base_location_id
                ||substr('-', 1, length(pl.sub_location_id))
                ||pl.sub_location_id
               ) = upper(p_project_id)
      and rt.version in ('Linear','Log','Custom','Standard')
      and rs.version in ('Step','Distributed','Custom','Production');

   return l_rating_id;
exception
   when no_data_found or too_many_rows then
      cwms_err.raise(
         'ERROR',
         'Could''t determine Elev->Stor rating to use for '
         ||l_office_id
         ||'/'
         ||p_project_id);
end get_elev_stor_rating;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stor
--------------------------------------------------------------------------------
procedure get_pool_limit_stor(
   p_limit_stor  out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_datetime    in  date     default null,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -34);
   l_office_id    varchar2(16);
   l_datetime     date;
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
   l_level_id     varchar2(256);
   l_limit_is_top boolean;
   l_rating_spec  varchar2(256);
   l_limit_stor   number;
   l_always_rate  boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   case
   when instr('TOP',    upper(p_limit)) = 1 then l_limit_is_top := true;
   when instr('BOTTOM', upper(p_limit)) = 1 then l_limit_is_top := false;
   else cwms_err.raise('ERROR', 'P_LMIT must be ''TOP'' or ''BOTTOM'', or an initial substring of either');
   end case;
   ---------------------------------
   -- set up info from parameters --
   ---------------------------------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_always_rate := cwms_util.is_true(p_always_rate);
   if p_datetime is null then
      l_datetime := sysdate;
   else
      l_datetime := cwms_util.change_timezone(
         p_datetime,
         'UTC',
         nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id)));
   end if;
   if not l_always_rate then
      ------------------------------------
      -- try to use Stor location level --
      ------------------------------------
      -----------------------
      -- get the pool info --
      -----------------------
      retrieve_pool(
         l_bot_level_id,
         l_top_level_id,
         p_project_id,
         p_pool_name,
         l_office_id);
      l_level_id := case
                    when l_limit_is_top then l_top_level_id
                    else l_bot_level_id
                    end;
     l_level_id := p_project_id||'.'||l_level_id;
      -----------------------------------------------------------------
      -- get the location level value at the specified time and unit --
      -----------------------------------------------------------------
      begin
         l_limit_stor := cwms_level.retrieve_location_level_value (
            p_location_level_id => replace(l_level_id, '.Elev.', '.Stor.'),
            p_level_units       => p_unit,
            p_date              => l_datetime,
            p_office_id         => l_office_id);
      exception
         when item_does_not_exist then null;
      end;
   end if;
   if l_always_rate or l_limit_stor is null then
      ------------------------------------------------------------------
      -- either we're always rating or the Stor location level failed --
      ------------------------------------------------------------------
      l_rating_spec := case
                       when p_rating_spec is not null then p_rating_spec
                       else get_elev_stor_rating(p_project_id, l_office_id)
                       end;
      l_limit_stor := cwms_rating.rate_f(
         l_rating_spec,
         get_pool_limit_elev_f(p_project_id, p_pool_name, p_limit, 'ft', l_datetime, 'UTC', l_office_id),
         str_tab_t('ft', p_unit),
         'F',
         l_datetime,
         null,
         'UTC',
         l_office_id);
   end if;
   p_limit_stor := cwms_rounding.round_nn_f(l_limit_stor, '4444444564');
end get_pool_limit_stor;
--------------------------------------------------------------------------------
-- function get_pool_limit_stor_f
--------------------------------------------------------------------------------
function get_pool_limit_stor_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_datetime    in date     default null,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return number
is
   l_limit_stor number;
begin
   get_pool_limit_stor(
      p_limit_stor  => l_limit_stor,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

	return l_limit_stor;
end get_pool_limit_stor_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stors
--------------------------------------------------------------------------------
procedure get_pool_limit_stors(
   p_bottom_stor out number,
   p_top_stor    out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_unit        in  varchar2,
   p_datetime    in  date     default null,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -34);
   l_office_id    varchar2(16);
   l_datetime     date;
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
   l_rating_spec  varchar2(256);
   l_bottom_stor  number;
   l_top_stor     number;
   l_always_rate  boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   ---------------------------------
   -- set up info from parameters --
   ---------------------------------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_always_rate := cwms_util.is_true(p_always_rate);
   if p_datetime is null then
      l_datetime := sysdate;
   else
      l_datetime := cwms_util.change_timezone(
         p_datetime,
         'UTC',
         nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id)));
   end if;
   if not l_always_rate then
      ------------------------------------
      -- try to use Stor location level --
      ------------------------------------
      -----------------------
      -- get the pool info --
      -----------------------
      retrieve_pool(
         l_bot_level_id,
         l_top_level_id,
         p_project_id,
         p_pool_name,
         l_office_id);

      l_bot_level_id := p_project_id||'.'||l_bot_level_id;
      l_top_level_id := p_project_id||'.'||l_top_level_id;
      ------------------------------------------------------------------
      -- get the location level values at the specified time and unit --
      ------------------------------------------------------------------
      begin
         l_bottom_stor := cwms_level.retrieve_location_level_value (
            p_location_level_id => replace(l_bot_level_id, '.Elev.', '.Stor.'),
            p_level_units       => p_unit,
            p_date              => l_datetime,
            p_office_id         => l_office_id);
         l_top_stor := cwms_level.retrieve_location_level_value (
            p_location_level_id => replace(l_top_level_id, '.Elev.', '.Stor.'),
            p_level_units       => p_unit,
            p_date              => l_datetime,
            p_office_id         => l_office_id);
      exception
         when item_does_not_exist then null;
      end;
   end if;
   if l_always_rate or l_bottom_stor is null or l_top_stor is null then
      ------------------------------------------------------------------
      -- either we're always rating or the Stor location level failed --
      ------------------------------------------------------------------
      l_rating_spec := case
                       when p_rating_spec is not null then p_rating_spec
                       else get_elev_stor_rating(p_project_id, l_office_id)
                       end;
      l_bottom_stor := cwms_rating.rate_f(
         l_rating_spec,
         get_pool_limit_elev_f(p_project_id, p_pool_name, 'BOTTOM', 'ft', l_datetime, 'UTC', l_office_id),
         str_tab_t('ft', p_unit),
         'F',
         l_datetime,
         null,
         'UTC',
         l_office_id);
      l_top_stor := cwms_rating.rate_f(
         l_rating_spec,
         get_pool_limit_elev_f(p_project_id, p_pool_name, 'TOP', 'ft', l_datetime, 'UTC', l_office_id),
         str_tab_t('ft', p_unit),
         'F',
         l_datetime,
         null,
         'UTC',
         l_office_id);
   end if;
   p_bottom_stor := cwms_rounding.round_nn_f(l_bottom_stor, '4444444564');
   p_top_stor    := cwms_rounding.round_nn_f(l_top_stor,    '4444444564');
end get_pool_limit_stors;
--------------------------------------------------------------------------------
-- function get_pool_limit_stors_f
--------------------------------------------------------------------------------
function get_pool_limit_stors_f(
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_datetime       in  date     default null,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null)
   return number_tab_t
is
   l_bottom_stor number;
   l_top_stor    number;
begin
	get_pool_limit_stors(
      p_bottom_stor => l_bottom_stor,
      p_top_stor    => l_top_stor,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_unit        => p_unit,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   return number_tab_t(l_bottom_stor, l_top_stor);
end get_pool_limit_stors_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stors
--------------------------------------------------------------------------------
procedure get_pool_limit_stors(
   p_limit_stors out number_tab_t,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -34);
   l_office_id    varchar2(16);
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
   l_level_id     varchar2(256);
   l_limit_is_top boolean;
   l_rating_spec  varchar2(256);
   l_timezone     varchar2(28);
   l_limit_stors  number_tab_t;
   l_always_rate  boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   case
   when instr('TOP',    upper(p_limit)) = 1 then l_limit_is_top := true;
   when instr('BOTTOM', upper(p_limit)) = 1 then l_limit_is_top := false;
   else cwms_err.raise('ERROR', 'P_LMIT must be ''TOP'' or ''BOTTOM'', or an initial substring of either');
   end case;
   ---------------------------------
   -- set up info from parameters --
   ---------------------------------
   l_office_id   := cwms_util.get_db_office_id(p_office_id);
   l_always_rate := cwms_util.is_true(p_always_rate);
   l_timezone    := nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id));
   if not l_always_rate then
      ------------------------------------
      -- try to use Stor location level --
      ------------------------------------
      -----------------------
      -- get the pool info --
      -----------------------
      retrieve_pool(
         l_bot_level_id,
         l_top_level_id,
         p_project_id,
         p_pool_name,
         l_office_id);
      l_level_id := case
                    when l_limit_is_top then l_top_level_id
                    else l_bot_level_id
                    end;
      -----------------------------------------------------------------
      -- get the location level value at the specified time and unit --
      -----------------------------------------------------------------
      begin
         l_limit_stors := number_tab_t();
         l_limit_stors.extend(p_datetimes.count);
         for i in 1..p_datetimes.count loop
            l_limit_stors(i) := cwms_level.retrieve_location_level_value(
               p_location_level_id => replace(l_level_id, '.Elev.', '.Stor.'),
               p_level_units       => p_unit,
               p_date              => p_datetimes(i),
               p_timezone_id       => l_timezone,
               p_office_id         => l_office_id);
         end loop;
      exception
         when item_does_not_exist then l_limit_stors := null;
      end;
   end if;
   if l_always_rate or l_limit_stors is null then
      ------------------------------------------------------------------
      -- either we're always rating or the Stor location level failed --
      ------------------------------------------------------------------
      l_rating_spec := case
                       when p_rating_spec is not null then p_rating_spec
                       else get_elev_stor_rating(p_project_id, l_office_id)
                       end;
      l_limit_stors := number_tab_t();
      l_limit_stors.extend(p_datetimes.count);
      for i in 1..p_datetimes.count loop
         l_limit_stors(i) := cwms_rounding.round_nn_f(
            cwms_rating.rate_f(
               l_rating_spec,
               get_pool_limit_elev_f(p_project_id, p_pool_name, p_limit, 'ft', p_datetimes(i), l_timezone, l_office_id),
               str_tab_t('ft', p_unit),
               'F',
               p_datetimes(i),
               null,
               l_timezone,
               l_office_id),
            '4444444564');
      end loop;
   end if;
   p_limit_stors := l_limit_stors;
end get_pool_limit_stors;
--------------------------------------------------------------------------------
-- function get_pool_limit_stors_f
--------------------------------------------------------------------------------
function get_pool_limit_stors_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_datetimes   in date_table_type,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return number_tab_t
is
   l_limit_stors number_tab_t;
begin
   get_pool_limit_stors(
      p_limit_stors => l_limit_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_datetimes   => p_datetimes,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

	return l_limit_stors;
end get_pool_limit_stors_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stors
--------------------------------------------------------------------------------
procedure get_pool_limit_stors(
   p_bottom_stors out number_tab_t,
   p_top_stors    out number_tab_t,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -34);
   l_office_id    varchar2(16);
   l_bot_level_id varchar2(256);
   l_top_level_id varchar2(256);
   l_rating_spec  varchar2(256);
   l_timezone     varchar2(28);
   l_bottom_stors number_tab_t;
   l_top_stors    number_tab_t;
   l_always_rate  boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   ---------------------------------
   -- set up info from parameters --
   ---------------------------------
   l_office_id   := cwms_util.get_db_office_id(p_office_id);
   l_always_rate := cwms_util.is_true(p_always_rate);
   l_timezone    := nvl(p_timezone, cwms_loc.get_local_timezone(p_project_id, l_office_id));
   if not l_always_rate then
      ------------------------------------
      -- try to use Stor location level --
      ------------------------------------
      -----------------------
      -- get the pool info --
      -----------------------
      retrieve_pool(
         l_bot_level_id,
         l_top_level_id,
         p_project_id,
         p_pool_name,
         l_office_id);
      l_bot_level_id := p_project_id||'.'||l_bot_level_id;
      l_top_level_id := p_project_id||'.'||l_top_level_id;
      -------------------------------------------------------------------
      -- get the location level values at the specified times and unit --
      -------------------------------------------------------------------
      begin
         l_bottom_stors := number_tab_t();
         l_bottom_stors.extend(p_datetimes.count);
         l_top_stors := number_tab_t();
         l_top_stors.extend(p_datetimes.count);
         for i in 1..p_datetimes.count loop
            l_bottom_stors(i) := cwms_level.retrieve_location_level_value(
               p_location_level_id => replace(l_bot_level_id, '.Elev.', '.Stor.'),
               p_level_units       => p_unit,
               p_date              => p_datetimes(i),
               p_timezone_id       => l_timezone,
               p_office_id         => l_office_id);

            l_top_stors(i) := cwms_level.retrieve_location_level_value(
               p_location_level_id => replace(l_top_level_id, '.Elev.', '.Stor.'),
               p_level_units       => p_unit,
               p_date              => p_datetimes(i),
               p_timezone_id       => l_timezone,
               p_office_id         => l_office_id);
         end loop;
      exception
         when item_does_not_exist then
            l_bottom_stors := null;
            l_top_stors := null;
      end;
   end if;
   if l_always_rate or l_bottom_stors is null or l_top_stors is null then
      ------------------------------------------------------------------
      -- either we're always rating or the Stor location level failed --
      ------------------------------------------------------------------
      l_rating_spec := case
                       when p_rating_spec is not null then p_rating_spec
                       else get_elev_stor_rating(p_project_id, l_office_id)
                       end;
      l_bottom_stors := number_tab_t();
      l_bottom_stors.extend(p_datetimes.count);
      l_top_stors := number_tab_t();
      l_top_stors.extend(p_datetimes.count);
      for i in 1..p_datetimes.count loop
         l_bottom_stors(i) := cwms_rounding.round_nn_f(
            cwms_rating.rate_f(
               l_rating_spec,
               get_pool_limit_elev_f(p_project_id, p_pool_name, 'BOTTOM', 'ft', p_datetimes(i), l_timezone, l_office_id),
               str_tab_t('ft', p_unit),
               'F',
               p_datetimes(i),
               null,
               l_timezone,
               l_office_id),
            '4444444564');
         l_top_stors(i) := cwms_rounding.round_nn_f(
            cwms_rating.rate_f(
               l_rating_spec,
               get_pool_limit_elev_f(p_project_id, p_pool_name, 'TOP', 'ft', p_datetimes(i), l_timezone, l_office_id),
               str_tab_t('ft', p_unit),
               'F',
               p_datetimes(i),
               null,
               l_timezone,
               l_office_id),
            '4444444564');
      end loop;
   end if;
   p_bottom_stors := l_bottom_stors;
   p_top_stors    := l_top_stors;
end get_pool_limit_stors;
--------------------------------------------------------------------------------
-- function get_pool_limit_stors_f
--------------------------------------------------------------------------------
function get_pool_limit_stors_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_datetimes     in date_table_type,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return number_tab_tab_t
is
   l_bottom_stors number_tab_t;
   l_top_stors    number_tab_t;
   l_results      number_tab_tab_t;
   l_row_axis     boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;
	get_pool_limit_stors(
      p_bottom_stors => l_bottom_stors,
      p_top_stors    => l_top_stors,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_datetimes    => p_datetimes,
      p_timezone     => p_timezone,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

   if l_row_axis then
      l_results := number_tab_tab_t();
      l_results.extend(p_datetimes.count);
      for i in 1..p_datetimes.count loop
         l_results(i) := number_tab_t(l_bottom_stors(i), l_top_stors(i));
      end loop;
   else
      l_results := number_tab_tab_t(l_bottom_stors, l_top_stors);
   end if;
   return l_results;
end get_pool_limit_stors_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stors
--------------------------------------------------------------------------------
procedure get_pool_limit_stors(
   p_limit_stors out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_timeseries  in  ztsv_array,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_datetimes   date_table_type;
   l_limit_stors number_tab_t;
   l_limit_ts    ztsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

	select date_time
	  bulk collect
	  into l_datetimes
	  from table(p_timeseries);
	
   get_pool_limit_stors(
      p_limit_stors => l_limit_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_datetimes   => l_datetimes,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   l_limit_ts := ztsv_array();
   l_limit_ts.extend(p_timeseries.count);
   for i in 1..p_timeseries.count loop
      l_limit_ts(i) := ztsv_type(l_datetimes(i), l_limit_stors(i), 0);
   end loop;
   p_limit_stors := l_limit_ts;
end get_pool_limit_stors;
--------------------------------------------------------------------------------
-- function get_pool_limit_stors_f
--------------------------------------------------------------------------------
function get_pool_limit_stors_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_timeseries  in ztsv_array,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array
is
   l_limit_stors ztsv_array;
begin
   get_pool_limit_stors(
      p_limit_stors => l_limit_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_timeseries  => p_timeseries,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

	return l_limit_stors;
end get_pool_limit_stors_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stors
--------------------------------------------------------------------------------
procedure get_pool_limit_stors(
   p_bottom_stors out ztsv_array,
   p_top_stors    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   l_datetimes    date_table_type;
   l_bottom_stors number_tab_t;
   l_top_stors    number_tab_t;
   l_bottom_ts    ztsv_array;
   l_top_ts       ztsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

	select date_time
	  bulk collect
	  into l_datetimes
	  from table(p_timeseries);
	
   get_pool_limit_stors(
      p_limit_stors => l_bottom_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => 'BOTTOM',
      p_unit        => p_unit,
      p_datetimes   => l_datetimes,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);
	
   get_pool_limit_stors(
      p_limit_stors => l_top_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => 'TOP',
      p_unit        => p_unit,
      p_datetimes   => l_datetimes,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   l_bottom_ts := ztsv_array();
   l_bottom_ts.extend(p_timeseries.count);
   l_top_ts := ztsv_array();
   l_top_ts.extend(p_timeseries.count);
   for i in 1..p_timeseries.count loop
      l_bottom_ts(i) := ztsv_type(l_datetimes(i), l_bottom_stors(i), 0);
      l_top_ts(i)    := ztsv_type(l_datetimes(i), l_top_stors(i),    0);
   end loop;
   p_bottom_stors := l_bottom_ts;
   p_top_stors    := l_top_ts;
end get_pool_limit_stors;
--------------------------------------------------------------------------------
-- function get_pool_limit_stors_f
--------------------------------------------------------------------------------
function get_pool_limit_stors_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_timeseries    in ztsv_array,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_stors ztsv_array;
   l_top_stors    ztsv_array;
   l_results      ztsv_array_tab;
   l_row_axis     boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;
    get_pool_limit_stors(
      p_bottom_stors => l_bottom_stors,
      p_top_stors    => l_top_stors,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_timeseries   => p_timeseries,
      p_timezone     => p_timezone,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

   if l_row_axis then
     l_results := ztsv_array_tab();
     l_results.extend(l_bottom_stors.count);
     for i in 1..l_bottom_stors.count loop
      l_results(i) := ztsv_array(l_bottom_stors(i), l_top_stors(i));
     end loop;
   else
      l_results := ztsv_array_tab(l_bottom_stors, l_top_stors);
   end if;
	return l_results;
end get_pool_limit_stors_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stors
--------------------------------------------------------------------------------
procedure get_pool_limit_stors(
   p_limit_stors out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_tsid        in  varchar2,
   p_start_time  in  date,
   p_end_time    in  date,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id != 'Elev' then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not an elevation time series');
   end if;
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  'm',
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_pool_limit_stors(
      p_limit_stors => p_limit_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_timeseries  => l_ts2,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);

end get_pool_limit_stors;
--------------------------------------------------------------------------------
-- function get_pool_limit_stors_f
--------------------------------------------------------------------------------
function get_pool_limit_stors_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_tsid        in varchar2,
   p_start_time  in date,
   p_end_time    in date,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array
is
   l_limit_stors ztsv_array;
begin
   get_pool_limit_stors(
      p_limit_stors => l_limit_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_tsid        => p_tsid,
      p_start_time  => p_start_time,
      p_end_time    => p_end_time,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

	return l_limit_stors;
end get_pool_limit_stors_f;
--------------------------------------------------------------------------------
-- procedure get_pool_limit_stors
--------------------------------------------------------------------------------
procedure get_pool_limit_stors(
   p_bottom_stors out ztsv_array,
   p_top_stors    out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
	l_bottom_ts ztsv_array;
	l_top_ts    ztsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;

   get_pool_limit_stors(
      p_limit_stors => l_bottom_ts,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => 'BOTTOM',
      p_unit        => p_unit,
      p_tsid        => p_tsid,
      p_start_time  => p_start_time,
      p_end_time    => p_end_time,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   get_pool_limit_stors(
      p_limit_stors => l_top_ts,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => 'TOP',
      p_unit        => p_unit,
      p_tsid        => p_tsid,
      p_start_time  => p_start_time,
      p_end_time    => p_end_time,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   p_bottom_stors := l_bottom_ts;
   p_top_stors    := l_top_ts;
end get_pool_limit_stors;
--------------------------------------------------------------------------------
-- function get_pool_limit_stors_f
--------------------------------------------------------------------------------
function get_pool_limit_stors_f(
   p_project_id     in varchar2,
   p_pool_name      in varchar2,
   p_unit           in varchar2,
   p_tsid           in varchar2,
   p_start_time     in date,
   p_end_time       in date,
   p_timezone       in varchar2 default null,
   p_always_rate    in varchar2 default 'T',
   p_rating_spec    in varchar2 default null,
   p_datetime_axis  in varchar2 default 'ROW',
   p_office_id      in varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_ts ztsv_array;
   l_top_ts    ztsv_array;
   l_results    ztsv_array_tab;
   l_row_axis     boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;
   get_pool_limit_stors(
      p_bottom_stors => l_bottom_ts,
      p_top_stors    => l_top_ts,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_tsid         => p_tsid,
      p_start_time   => p_start_time,
      p_end_time     => p_end_time,
      p_timezone     => p_timezone,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

   if l_row_axis then
      l_results := ztsv_array_tab();
      l_results.extend(l_bottom_ts.count);
      for i in 1..l_bottom_ts.count loop
         l_results(i) := ztsv_array(l_bottom_ts(i), l_top_ts(i));
      end loop;
   else
      l_results := ztsv_array_tab(l_bottom_ts, l_top_ts);
   end if;
	return l_results;
end get_pool_limit_stors_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offset
--------------------------------------------------------------------------------
procedure get_elev_offset(
   p_offset     out number,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevation  in  number,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
is
   l_limit_elev number;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;

	get_pool_limit_elev(
      p_limit_elev => l_limit_elev,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => p_limit,
      p_unit       => p_unit,
      p_datetime   => p_datetime,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

   p_offset := cwms_rounding.round_nn_f(p_elevation - l_limit_elev, '7777777777');
end get_elev_offset;
--------------------------------------------------------------------------------
-- function get_elev_offset_f
--------------------------------------------------------------------------------
function get_elev_offset_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevation  in  number,
   p_datetime   in  date default null,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number
is
   l_offset number;
begin
   get_elev_offset(
      p_offset     => l_offset,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => p_limit,
      p_unit       => p_unit,
      p_elevation  => p_elevation,
      p_datetime   => p_datetime,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

   return l_offset;
end get_elev_offset_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offsets
--------------------------------------------------------------------------------
procedure get_elev_offsets(
   p_bottom_offset out number,
   p_top_offset    out number,
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_elevation     in  number,
   p_datetime      in  date default null,
   p_timezone      in  varchar2 default null,
   p_office_id     in  varchar2 default null)
is
   l_bottom_offset number;
   l_top_offset    number;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_elevation is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_ELEVATION');
   end if;

   get_elev_offset(
      p_offset     => l_bottom_offset,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => 'BOTTOM',
      p_unit       => p_unit,
      p_elevation  => p_elevation,
      p_datetime   => p_datetime,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

   get_elev_offset(
      p_offset     => l_top_offset,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => 'TOP',
      p_unit       => p_unit,
      p_elevation  => p_elevation,
      p_datetime   => p_datetime,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

   p_bottom_offset := l_bottom_offset;
   p_top_offset    := l_top_offset;
end get_elev_offsets;
--------------------------------------------------------------------------------
-- function get_elev_offsets_f
--------------------------------------------------------------------------------
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_elevation     in  number,
   p_datetime      in  date default null,
   p_timezone      in  varchar2 default null,
   p_office_id     in  varchar2 default null)
   return number_tab_t
is
   l_bottom_offset number;
   l_top_offset    number;
begin
   get_elev_offsets(
      p_bottom_offset => l_bottom_offset,
      p_top_offset    => l_top_offset,
      p_project_id    => p_project_id,
      p_pool_name     => p_pool_name,
      p_unit          => p_unit,
      p_elevation     => p_elevation,
      p_datetime      => p_datetime,
      p_timezone      => p_timezone,
      p_office_id     => p_office_id);

	return number_tab_t(l_bottom_offset, l_top_offset);
end get_elev_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offsets
--------------------------------------------------------------------------------
procedure get_elev_offsets(
   p_offsets    out number_tab_t,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevations in  number_tab_t,
   p_datetimes  in  date_table_type,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
is
   l_offsets number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_elevations is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_ELEVATIONS');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   if p_elevations.count != p_datetimes.count then
      cwms_err.raise('ERROR', 'P_ELEVATIONS and P_DATETIMES must be of same length');
   end if;

   l_offsets := number_tab_t();
   l_offsets.extend(p_datetimes.count);
   for i in 1..p_datetimes.count loop
      get_elev_offset(
         p_offset     => l_offsets(i),
         p_project_id => p_project_id,
         p_pool_name  => p_pool_name,
         p_limit      => p_limit,
         p_unit       => p_unit,
         p_elevation  => p_elevations(i),
         p_datetime   => p_datetimes(i),
         p_timezone   => p_timezone,
         p_office_id  => p_office_id);
   end loop;
	p_offsets := l_offsets;
end get_elev_offsets;
--------------------------------------------------------------------------------
-- function get_elev_offsets_f
--------------------------------------------------------------------------------
function get_elev_offsets_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_elevations in  number_tab_t,
   p_datetimes  in  date_table_type,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return number_tab_t
is
   l_offsets number_tab_t;
begin
   get_elev_offsets(
      p_offsets    => l_offsets,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => p_limit,
      p_unit       => p_unit,
      p_elevations => p_elevations,
      p_datetimes  => p_datetimes,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

	return l_offsets;
end get_elev_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offsets
--------------------------------------------------------------------------------
procedure get_elev_offsets(
   p_bottom_offsets out number_tab_t,
   p_top_offsets    out number_tab_t,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_elevations     in  number_tab_t,
   p_datetimes      in  date_table_type,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   l_bottom_offsets number_tab_t;
   l_top_offsets    number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_elevations is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_ELEVATIONS');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   if p_elevations.count != p_datetimes.count then
      cwms_err.raise('ERROR', 'P_ELEVATIONS and P_DATETIMES must be of same length');
   end if;

   l_bottom_offsets := number_tab_t();
   l_bottom_offsets.extend(p_elevations.count);
   l_top_offsets := number_tab_t();
   l_top_offsets.extend(p_elevations.count);

   for i in 1..p_elevations.count loop
      get_elev_offsets(
         p_bottom_offset => l_bottom_offsets(i),
         p_top_offset    => l_top_offsets(i),
         p_project_id    => p_project_id,
         p_pool_name     => p_pool_name,
         p_unit          => p_unit,
         p_elevation     => p_elevations(i),
         p_datetime      => p_datetimes(i),
         p_timezone      => p_timezone,
         p_office_id     => p_office_id);
   end loop;

   p_bottom_offsets := l_bottom_offsets;
   p_top_offsets    := l_top_offsets;
end get_elev_offsets;
--------------------------------------------------------------------------------
-- function get_elev_offsets_f
--------------------------------------------------------------------------------
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_elevations    in  number_tab_t,
   p_datetimes     in  date_table_type,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return number_tab_tab_t
is
   l_results        number_tab_tab_t;
   l_bottom_offsets number_tab_t;
   l_top_offsets    number_tab_t;
   l_row_axis       boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_elevations is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_ELEVATIONS');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   if p_elevations.count != p_datetimes.count then
      cwms_err.raise('ERROR', 'P_ELEVATIONS and P_DATETIMES must be of same length');
   end if;
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;

   l_bottom_offsets := number_tab_t();
   l_bottom_offsets.extend(p_elevations.count);
   l_top_offsets := number_tab_t();
   l_top_offsets.extend(p_elevations.count);

   for i in 1..p_elevations.count loop
      get_elev_offsets(
         p_bottom_offset => l_bottom_offsets(i),
         p_top_offset    => l_top_offsets(i),
         p_project_id    => p_project_id,
         p_pool_name     => p_pool_name,
         p_unit          => p_unit,
         p_elevation     => p_elevations(i),
         p_datetime      => p_datetimes(i),
         p_timezone      => p_timezone,
         p_office_id     => p_office_id);
   end loop;

   if l_row_axis then
      l_results := number_tab_tab_t();
      l_results.extend(p_elevations.count);
      for i in 1..p_elevations.count loop
         l_results(i) := number_tab_t(l_bottom_offsets(i), l_top_offsets(i));
      end loop;
   else
      l_results := number_tab_tab_t(l_bottom_offsets, l_top_offsets);
   end if;
	return l_results;
end get_elev_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offsets
--------------------------------------------------------------------------------
procedure get_elev_offsets(
   p_offsets    out ztsv_array,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_timeseries in  ztsv_array,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
is
   l_ts         ztsv_array;
   l_offsets    number_tab_t;
   l_elevations number_tab_t;
   l_datetimes  date_table_type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

   select date_time,
          to_number(value)
     bulk collect
     into l_datetimes,
          l_elevations
     from table(p_timeseries);

   get_elev_offsets(
      p_offsets    => l_offsets,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => p_limit,
      p_unit       => p_unit,
      p_elevations => l_elevations,
      p_datetimes  => l_datetimes,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

   l_ts := ztsv_array();
   l_ts.extend(p_timeseries.count);
   for i in 1..p_timeseries.count loop
      l_ts(i) := ztsv_type(l_datetimes(i), l_offsets(i), 0);
   end loop;
   p_offsets := l_ts;

end get_elev_offsets;
--------------------------------------------------------------------------------
-- function get_elev_offsets_f
--------------------------------------------------------------------------------
function get_elev_offsets_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_timeseries in  ztsv_array,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array
is
   l_offsets ztsv_array;
begin
   get_elev_offsets(
      p_offsets    => l_offsets,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => p_limit,
      p_unit       => p_unit,
      p_timeseries => p_timeseries,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);
	return l_offsets;
end get_elev_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offsets
--------------------------------------------------------------------------------
procedure get_elev_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_timeseries     in  ztsv_array,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   l_bottom_ts      ztsv_array;
   l_top_ts         ztsv_array;
   l_bottom_offsets number_tab_t;
   l_top_offsets    number_tab_t;
   l_elevations     number_tab_t;
   l_datetimes      date_table_type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

   select date_time,
          to_number(value)
     bulk collect
     into l_datetimes,
          l_elevations
     from table(p_timeseries);

   get_elev_offsets(
      p_bottom_offsets => l_bottom_offsets,
      p_top_offsets    => l_top_offsets,
      p_project_id     => p_project_id,
      p_pool_name      => p_pool_name,
      p_unit           => p_unit,
      p_elevations     => l_elevations,
      p_datetimes      => l_datetimes,
      p_timezone       => p_timezone,
      p_office_id      => p_office_id);

   l_bottom_ts := ztsv_array();
   l_bottom_ts.extend(p_timeseries.count);
   l_top_ts := ztsv_array();
   l_top_ts.extend(p_timeseries.count);

   for i in 1..p_timeseries.count loop
      l_bottom_ts(i) := ztsv_type(l_datetimes(i), l_bottom_offsets(i), 0);
      l_top_ts(i)    := ztsv_type(l_datetimes(i), l_top_offsets(i), 0);
   end loop;
   p_bottom_offsets := l_bottom_ts;
   p_top_offsets    := l_top_ts;

end get_elev_offsets;
--------------------------------------------------------------------------------
-- function get_elev_offsets_f
--------------------------------------------------------------------------------
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_timeseries    in  ztsv_array,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_ts ztsv_array;
   l_top_ts    ztsv_array;
   l_results   ztsv_array_tab;
   l_row_axis  boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;

   get_elev_offsets(
      p_bottom_offsets => l_bottom_ts,
      p_top_offsets    => l_top_ts,
      p_project_id     => p_project_id,
      p_pool_name      => p_pool_name,
      p_unit           => p_unit,
      p_timeseries     => p_timeseries,
      p_timezone       => p_timezone,
      p_office_id      => p_office_id);

   if l_row_axis then
      l_results := ztsv_array_tab();
      l_results.extend(p_timeseries.count);
      for i in 1..p_timeseries.count loop
         l_results(i) := ztsv_array(l_bottom_ts(i), l_top_ts(i));
      end loop;
   else
      l_results := ztsv_array_tab(l_bottom_ts, l_top_ts);
   end if;
	return l_results;
end get_elev_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offsets
--------------------------------------------------------------------------------
procedure get_elev_offsets(
   p_offsets    out ztsv_array,
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_tsid       in  varchar2,
   p_start_time in  date,
   p_end_time   in  date,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_limit_elevs       ztsv_array;
   l_offsets           ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id != 'Elev' then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not an elevation time series');
   end if;
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  p_unit,
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_pool_limit_elevs(
      p_limit_elevs => l_limit_elevs,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_timeseries  => l_ts2,
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);

   l_offsets := ztsv_array();
   l_offsets.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_offsets(i) := ztsv_type(
         l_ts2(i).date_time,
         cwms_rounding.round_nn_f(l_ts2(i).value - l_limit_elevs(i).value, '7777777777'),
         0);
   end loop;
   p_offsets := l_offsets;
end get_elev_offsets;
--------------------------------------------------------------------------------
-- function get_elev_offsets_f
--------------------------------------------------------------------------------
function get_elev_offsets_f(
   p_project_id in  varchar2,
   p_pool_name  in  varchar2,
   p_limit      in  varchar2,
   p_unit       in  varchar2,
   p_tsid       in  varchar2,
   p_start_time in  date,
   p_end_time   in  date,
   p_timezone   in  varchar2 default null,
   p_office_id  in  varchar2 default null)
   return ztsv_array
is
   l_offsets ztsv_array;
begin
   get_elev_offsets(
      p_offsets    => l_offsets,
      p_project_id => p_project_id,
      p_pool_name  => p_pool_name,
      p_limit      => p_limit,
      p_unit       => p_unit,
      p_tsid       => p_tsid,
      p_start_time => p_start_time,
      p_end_time   => p_end_time,
      p_timezone   => p_timezone,
      p_office_id  => p_office_id);

	return l_offsets;
end get_elev_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_elev_offsets
--------------------------------------------------------------------------------
procedure get_elev_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_tsid           in  varchar2,
   p_start_time     in  date,
   p_end_time       in  date,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_bottom_elevs      ztsv_array;
   l_top_elevs         ztsv_array;
   l_bottom_offsets    ztsv_array;
   l_top_offsets       ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
   l_value             number;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id != 'Elev' then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not an elevation time series');
   end if;
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  p_unit,
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_pool_limit_elevs(
      p_bottom_elevs => l_bottom_elevs,
      p_top_elevs    => l_top_elevs,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_timeseries   => l_ts2,
      p_timezone     => p_timezone,
      p_office_id    => p_office_id);

   l_bottom_offsets := ztsv_array();
   l_bottom_offsets.extend(l_ts1.count);
   l_top_offsets := ztsv_array();
   l_top_offsets.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_value := cwms_rounding.round_nn_f(l_ts2(i).value, '7777777777');
      l_bottom_offsets(i) := ztsv_type(
         l_ts2(i).date_time,
         l_value - cwms_rounding.round_nn_f(l_bottom_elevs(i).value, '7777777777'),
         0);
      l_top_offsets(i) := ztsv_type(
         l_ts2(i).date_time,
         l_value - cwms_rounding.round_nn_f(l_top_elevs(i).value, '7777777777'),
         0);
   end loop;
   p_bottom_offsets := l_bottom_offsets;
   p_top_offsets    := l_top_offsets;
end get_elev_offsets;
--------------------------------------------------------------------------------
-- function get_elev_offsets_f
--------------------------------------------------------------------------------
function get_elev_offsets_f(
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_tsid          in  varchar2,
   p_start_time    in  date,
   p_end_time      in  date,
   p_timezone      in  varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in  varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_offsets ztsv_array;
   l_top_offsets    ztsv_array;
   l_results        ztsv_array_tab;
   l_row_axis       boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;

   get_elev_offsets(
      p_bottom_offsets => l_bottom_offsets,
      p_top_offsets    => l_top_offsets,
      p_project_id     => p_project_id,
      p_pool_name      => p_pool_name,
      p_unit           => p_unit,
      p_tsid           => p_tsid,
      p_start_time     => p_start_time,
      p_end_time       => p_end_time,
      p_timezone       => p_timezone,
      p_office_id      => p_office_id);

   if l_row_axis then
      l_results := ztsv_array_tab();
      l_results.extend(l_top_offsets.count);
      for i in 1..l_top_offsets.count loop
         l_results(i) := ztsv_array(l_bottom_offsets(i), l_top_offsets(i));
      end loop;
   else
      l_results := ztsv_array_tab(l_bottom_offsets, l_top_offsets);
   end if;
	return l_results;
end get_elev_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offset
--------------------------------------------------------------------------------
procedure get_stor_offset(
   p_offset      out number,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_storage     in  number,
   p_datetime    in  date default null,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_limit_stor number;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;

	get_pool_limit_stor(
      p_limit_stor  => l_limit_stor,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   p_offset := cwms_rounding.round_nn_f(p_storage - l_limit_stor, '4444444564');
end get_stor_offset;
--------------------------------------------------------------------------------
-- function get_stor_offset_f
--------------------------------------------------------------------------------
function get_stor_offset_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_storage     in number,
   p_datetime    in date default null,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return number
is
   l_offset number;
begin
   get_stor_offset(
      p_offset      => l_offset,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_storage     => p_storage,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);
	return l_offset;
end get_stor_offset_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offsets
--------------------------------------------------------------------------------
procedure get_stor_offsets(
   p_bottom_offset out number,
   p_top_offset    out number,
   p_project_id    in  varchar2,
   p_pool_name     in  varchar2,
   p_unit          in  varchar2,
   p_storage       in  number,
   p_datetime      in  date default null,
   p_timezone      in  varchar2 default null,
   p_always_rate   in  varchar2 default 'T',
   p_rating_spec   in  varchar2 default null,
   p_office_id     in  varchar2 default null)
is
   l_bottom_offset number;
   l_top_offset    number;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_storage is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_STORAGE');
   end if;

   get_stor_offset(
      p_offset      => l_bottom_offset,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => 'BOTTOM',
      p_unit        => p_unit,
      p_storage     => p_storage,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   get_stor_offset(
      p_offset      => l_top_offset,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => 'TOP',
      p_unit        => p_unit,
      p_storage     => p_storage,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   p_bottom_offset := l_bottom_offset;
   p_top_offset    := l_top_offset;
end get_stor_offsets;
--------------------------------------------------------------------------------
-- function get_stor_offsets_f
--------------------------------------------------------------------------------
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_storage       in number,
   p_datetime      in date default null,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_office_id     in varchar2 default null)
   return number_tab_t
is
   l_bottom_offset number;
   l_top_offset    number;
begin
   get_stor_offsets(
      p_bottom_offset => l_bottom_offset,
      p_top_offset    => l_top_offset,
      p_project_id    => p_project_id,
      p_pool_name     => p_pool_name,
      p_unit          => p_unit,
      p_storage       => p_storage,
      p_datetime      => p_datetime,
      p_timezone      => p_timezone,
      p_always_rate   => p_always_rate,
      p_rating_spec   => p_rating_spec,
      p_office_id     => p_office_id);


	return number_tab_t(l_bottom_offset, l_top_offset);
end get_stor_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offsets
--------------------------------------------------------------------------------
procedure get_stor_offsets(
   p_offsets     out number_tab_t,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_storages    in  number_tab_t,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_offsets number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_storages is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_STORAGES');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   if p_storages.count != p_datetimes.count then
      cwms_err.raise('ERROR', 'P_STORAGES and P_DATETIMES must be of same length');
   end if;

   l_offsets := number_tab_t();
   l_offsets.extend(p_datetimes.count);
   for i in 1..p_datetimes.count loop
      get_stor_offset(
         p_offset      => l_offsets(i),
         p_project_id  => p_project_id,
         p_pool_name   => p_pool_name,
         p_limit       => p_limit,
         p_unit        => p_unit,
         p_storage     => p_storages(i),
         p_datetime    => p_datetimes(i),
         p_timezone    => p_timezone,
         p_always_rate => p_always_rate,
         p_rating_spec => p_rating_spec,
         p_office_id   => p_office_id);
   end loop;
	p_offsets := l_offsets;
end get_stor_offsets;
--------------------------------------------------------------------------------
-- function get_stor_offsets_f
--------------------------------------------------------------------------------
function get_stor_offsets_f(
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_storages    in  number_tab_t,
   p_datetimes   in  date_table_type,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
   return number_tab_t
is
   l_offsets number_tab_t;
begin
   get_stor_offsets(
      p_offsets     => l_offsets,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_storages    => p_storages,
      p_datetimes   => p_datetimes,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);
	return l_offsets;
end get_stor_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offsets
--------------------------------------------------------------------------------
procedure get_stor_offsets(
   p_bottom_offsets out number_tab_t,
   p_top_offsets    out number_tab_t,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_storages       in  number_tab_t,
   p_datetimes      in  date_table_type,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   l_bottom_offsets number_tab_t;
   l_top_offsets    number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_storages is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_STORAGES');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   if p_storages.count != p_datetimes.count then
      cwms_err.raise('ERROR', 'P_STORAGES and P_DATETIMES must be of same length');
   end if;

   l_bottom_offsets := number_tab_t();
   l_bottom_offsets.extend(p_storages.count);
   l_top_offsets := number_tab_t();
   l_top_offsets.extend(p_storages.count);

   for i in 1..p_storages.count loop
      get_stor_offsets(
         p_bottom_offset => l_bottom_offsets(i),
         p_top_offset    => l_top_offsets(i),
         p_project_id    => p_project_id,
         p_pool_name     => p_pool_name,
         p_unit          => p_unit,
         p_storage       => p_storages(i),
         p_datetime      => p_datetimes(i),
         p_timezone      => p_timezone,
         p_always_rate   => p_always_rate,
         p_rating_spec   => p_rating_spec,
         p_office_id     => p_office_id);
   end loop;

   p_bottom_offsets := l_bottom_offsets;
   p_top_offsets    := l_top_offsets;
end get_stor_offsets;
--------------------------------------------------------------------------------
-- function get_stor_offsets_f
--------------------------------------------------------------------------------
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_storages      in number_tab_t,
   p_datetimes     in date_table_type,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return number_tab_tab_t
is
   l_results        number_tab_tab_t;
   l_bottom_offsets number_tab_t;
   l_top_offsets    number_tab_t;
   l_row_axis       boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_storages is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_STORAGES');
   end if;
   if p_datetimes is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DATETIMES');
   end if;
   if p_storages.count != p_datetimes.count then
      cwms_err.raise('ERROR', 'P_STORAGES and P_DATETIMES must be of same length');
   end if;
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;

   l_bottom_offsets := number_tab_t();
   l_bottom_offsets.extend(p_storages.count);
   l_top_offsets := number_tab_t();
   l_top_offsets.extend(p_storages.count);

   for i in 1..p_storages.count loop
      get_stor_offsets(
         p_bottom_offset => l_bottom_offsets(i),
         p_top_offset    => l_top_offsets(i),
         p_project_id    => p_project_id,
         p_pool_name     => p_pool_name,
         p_unit          => p_unit,
         p_storage       => p_storages(i),
         p_datetime      => p_datetimes(i),
         p_timezone      => p_timezone,
         p_always_rate   => p_always_rate,
         p_rating_spec   => p_rating_spec,
         p_office_id     => p_office_id);
   end loop;

   if l_row_axis then
      l_results := number_tab_tab_t();
      l_results.extend(p_storages.count);
      for i in 1..p_storages.count loop
         l_results(i) := number_tab_t(l_bottom_offsets(i), l_top_offsets(i));
      end loop;
   else
      l_results := number_tab_tab_t(l_bottom_offsets, l_top_offsets);
   end if;
	return l_results;
end get_stor_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offsets
--------------------------------------------------------------------------------
procedure get_stor_offsets(
   p_offsets     out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_timeseries  in  ztsv_array,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_ts         ztsv_array;
   l_offsets    number_tab_t;
   l_storages number_tab_t;
   l_datetimes  date_table_type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

   select date_time,
          to_number(value)
     bulk collect
     into l_datetimes,
          l_storages
     from table(p_timeseries);

   get_stor_offsets(
      p_offsets     => l_offsets,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_storages    => l_storages,
      p_datetimes   => l_datetimes,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   l_ts := ztsv_array();
   l_ts.extend(p_timeseries.count);
   for i in 1..p_timeseries.count loop
      l_ts(i) := ztsv_type(l_datetimes(i), l_offsets(i), 0);
   end loop;
   p_offsets := l_ts;

end get_stor_offsets;
--------------------------------------------------------------------------------
-- function get_stor_offsets_f
--------------------------------------------------------------------------------
function get_stor_offsets_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_timeseries  in ztsv_array,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array
is
   l_offsets ztsv_array;
begin
   get_stor_offsets(
      p_offsets     => l_offsets,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_timeseries  => p_timeseries,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);
	return l_offsets;
end get_stor_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offsets
--------------------------------------------------------------------------------
procedure get_stor_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_timeseries     in  ztsv_array,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   l_bottom_ts      ztsv_array;
   l_top_ts         ztsv_array;
   l_bottom_offsets number_tab_t;
   l_top_offsets    number_tab_t;
   l_storages     number_tab_t;
   l_datetimes      date_table_type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

   select date_time,
          to_number(value)
     bulk collect
     into l_datetimes,
          l_storages
     from table(p_timeseries);

   get_stor_offsets(
      p_bottom_offsets => l_bottom_offsets,
      p_top_offsets    => l_top_offsets,
      p_project_id     => p_project_id,
      p_pool_name      => p_pool_name,
      p_unit           => p_unit,
      p_storages       => l_storages,
      p_datetimes      => l_datetimes,
      p_timezone       => p_timezone,
      p_always_rate    => p_always_rate,
      p_rating_spec    => p_rating_spec,
      p_office_id      => p_office_id);

   l_bottom_ts := ztsv_array();
   l_bottom_ts.extend(p_timeseries.count);
   l_top_ts := ztsv_array();
   l_top_ts.extend(p_timeseries.count);

   for i in 1..p_timeseries.count loop
      l_bottom_ts(i) := ztsv_type(l_datetimes(i), l_bottom_offsets(i), 0);
      l_top_ts(i)    := ztsv_type(l_datetimes(i), l_top_offsets(i), 0);
   end loop;
   p_bottom_offsets := l_bottom_ts;
   p_top_offsets    := l_top_ts;

end get_stor_offsets;
--------------------------------------------------------------------------------
-- function get_stor_offsets_f
--------------------------------------------------------------------------------
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_timeseries    in ztsv_array,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_ts ztsv_array;
   l_top_ts    ztsv_array;
   l_results   ztsv_array_tab;
   l_row_axis  boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;

   get_stor_offsets(
      p_bottom_offsets => l_bottom_ts,
      p_top_offsets    => l_top_ts,
      p_project_id     => p_project_id,
      p_pool_name      => p_pool_name,
      p_unit           => p_unit,
      p_timeseries     => p_timeseries,
      p_timezone       => p_timezone,
      p_always_rate    => p_always_rate,
      p_rating_spec    => p_rating_spec,
      p_office_id      => p_office_id);

   if l_row_axis then
      l_results := ztsv_array_tab();
      l_results.extend(p_timeseries.count);
      for i in 1..p_timeseries.count loop
         l_results(i) := ztsv_array(l_bottom_ts(i), l_top_ts(i));
      end loop;
   else
      l_results := ztsv_array_tab(l_bottom_ts, l_top_ts);
   end if;
	return l_results;
end get_stor_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offsets
--------------------------------------------------------------------------------
procedure get_stor_offsets(
   p_offsets     out ztsv_array,
   p_project_id  in  varchar2,
   p_pool_name   in  varchar2,
   p_limit       in  varchar2,
   p_unit        in  varchar2,
   p_tsid        in  varchar2,
   p_start_time  in  date,
   p_end_time    in  date,
   p_timezone    in  varchar2 default null,
   p_always_rate in  varchar2 default 'T',
   p_rating_spec in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_limit_stors       ztsv_array;
   l_offsets           ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_limit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LIMIT');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id != 'Stor' then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not a storage time series');
   end if;
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  p_unit,
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_pool_limit_stors(
      p_limit_stors => l_limit_stors,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_timeseries  => l_ts2,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

   l_offsets := ztsv_array();
   l_offsets.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_offsets(i) := ztsv_type(
         l_ts2(i).date_time,
         cwms_rounding.round_nn_f(l_ts2(i).value - l_limit_stors(i).value, '4444444564'),
         0);
   end loop;
   p_offsets := l_offsets;
end get_stor_offsets;
--------------------------------------------------------------------------------
-- function get_stor_offsets_f
--------------------------------------------------------------------------------
function get_stor_offsets_f(
   p_project_id  in varchar2,
   p_pool_name   in varchar2,
   p_limit       in varchar2,
   p_unit        in varchar2,
   p_tsid        in varchar2,
   p_start_time  in date,
   p_end_time    in date,
   p_timezone    in varchar2 default null,
   p_always_rate in varchar2 default 'T',
   p_rating_spec in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array
is
   l_offsets ztsv_array;
begin
   get_stor_offsets(
      p_offsets     => l_offsets,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_limit       => p_limit,
      p_unit        => p_unit,
      p_tsid        => p_tsid,
      p_start_time  => p_start_time,
      p_end_time    => p_end_time,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => p_rating_spec,
      p_office_id   => p_office_id);

	return l_offsets;
end get_stor_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_stor_offsets
--------------------------------------------------------------------------------
procedure get_stor_offsets(
   p_bottom_offsets out ztsv_array,
   p_top_offsets    out ztsv_array,
   p_project_id     in  varchar2,
   p_pool_name      in  varchar2,
   p_unit           in  varchar2,
   p_tsid           in  varchar2,
   p_start_time     in  date,
   p_end_time       in  date,
   p_timezone       in  varchar2 default null,
   p_always_rate    in  varchar2 default 'T',
   p_rating_spec    in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_bottom_stors      ztsv_array;
   l_top_stors         ztsv_array;
   l_bottom_offsets    ztsv_array;
   l_top_offsets       ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id != 'Stor' then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not a storage time series');
   end if;
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  p_unit,
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_pool_limit_stors(
      p_bottom_stors => l_bottom_stors,
      p_top_stors    => l_top_stors,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_timeseries   => l_ts2,
      p_timezone     => p_timezone,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

   l_bottom_offsets := ztsv_array();
   l_bottom_offsets.extend(l_ts1.count);
   l_top_offsets := ztsv_array();
   l_top_offsets.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_bottom_offsets(i) := ztsv_type(
         l_ts2(i).date_time,
         cwms_rounding.round_nn_f(l_ts2(i).value - l_bottom_stors(i).value, '4444444564'),
         0);
      l_top_offsets(i) := ztsv_type(
         l_ts2(i).date_time,
         cwms_rounding.round_nn_f(l_ts2(i).value - l_top_stors(i).value, '4444444564'),
         0);
   end loop;
   p_bottom_offsets := l_bottom_offsets;
   p_top_offsets    := l_top_offsets;
end get_stor_offsets;
--------------------------------------------------------------------------------
-- function get_stor_offsets_f
--------------------------------------------------------------------------------
function get_stor_offsets_f(
   p_project_id    in varchar2,
   p_pool_name     in varchar2,
   p_unit          in varchar2,
   p_tsid          in varchar2,
   p_start_time    in date,
   p_end_time      in date,
   p_timezone      in varchar2 default null,
   p_always_rate   in varchar2 default 'T',
   p_rating_spec   in varchar2 default null,
   p_datetime_axis in  varchar2 default 'ROW',
   p_office_id     in varchar2 default null)
   return ztsv_array_tab
is
   l_bottom_offsets ztsv_array;
   l_top_offsets    ztsv_array;
   l_results        ztsv_array_tab;
   l_row_axis       boolean;
begin
   case
   when instr('ROW',    upper(p_datetime_axis)) = 1 then l_row_axis := true;
   when instr('COLUMN', upper(p_datetime_axis)) = 1 then l_row_axis := false;
   else cwms_err.raise('ERROR', 'P_DATETIME_AXIS must be either ''ROW'' or ''COLUMN''');
   end case;

   get_stor_offsets(
      p_bottom_offsets => l_bottom_offsets,
      p_top_offsets    => l_top_offsets,
      p_project_id     => p_project_id,
      p_pool_name      => p_pool_name,
      p_unit           => p_unit,
      p_tsid           => p_tsid,
      p_start_time     => p_start_time,
      p_end_time       => p_end_time,
      p_timezone       => p_timezone,
      p_office_id      => p_office_id);

   if l_row_axis then
      l_results := ztsv_array_tab();
      l_results.extend(l_top_offsets.count);
      for i in 1..l_top_offsets.count loop
         l_results(i) := ztsv_array(l_bottom_offsets(i), l_top_offsets(i));
      end loop;
   else
      l_results := ztsv_array_tab(l_bottom_offsets, l_top_offsets);
   end if;
	return l_results;
end get_stor_offsets_f;
--------------------------------------------------------------------------------
-- procedure get_percent_full
--------------------------------------------------------------------------------
procedure get_percent_full(
   p_percent_full out number,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_value        in  number,
   p_datetime     in  date default null,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   l_value        number;
   l_bottom_stor  number;
   l_top_stor     number;
   l_percent_full number;
   l_unit         varchar2(32);
   l_office_id    varchar2(16);
   l_rating_spec  varchar2(256);
   l_count        pls_integer;
   l_is_storage   boolean;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_value is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   select count(*)
     into l_count
     from av_unit
    where upper(unit_id) = upper(p_unit)
      and abstract_param_id = 'Volume';
   if l_count > 0 then
      l_is_storage := true;
   else
      select count(*)
        into l_count
        from av_unit
       where upper(unit_id) = upper(p_unit)
         and abstract_param_id = 'Length';
      if l_count > 0 then
         l_is_storage := false;
      else
         cwms_err.raise(
         'ERROR',
         'Unit '
         ||p_unit
         ||' must be a unit for either elevation or storage');
      end if;
   end if;
   ---------------------------------------
   -- make sure we have a storage value --
   ---------------------------------------
   if l_is_storage then
      -------------------
      -- use specified --
      -------------------
      l_unit  := p_unit;
      l_value := p_value;
   else
      --------------------
      -- rate elevation --
      --------------------
      l_rating_spec := case
                       when p_rating_spec is not null then p_rating_spec
                       else get_elev_stor_rating(p_project_id, l_office_id)
                       end;
      l_unit := 'ac-ft';
      l_value := cwms_rating.rate_f(
         l_rating_spec,
         p_value,
         str_tab_t(p_unit, l_unit),
         'F',
         p_datetime,
         null,
         p_timezone,
         l_office_id);
   end if;
   --------------------------------------
   -- retrieve the pool storage limits --
   --------------------------------------
   get_pool_limit_stors(
      p_bottom_stor => l_bottom_stor,
      p_top_stor    => l_top_stor,
      p_project_id  => p_project_id,
      p_pool_name   => p_pool_name,
      p_unit        => l_unit,
      p_datetime    => p_datetime,
      p_timezone    => p_timezone,
      p_always_rate => p_always_rate,
      p_rating_spec => l_rating_spec,
      p_office_id   => l_office_id);
   ------------------------------
   -- compute the percent full --
   ------------------------------
   l_percent_full := 100 * (l_value - l_bottom_stor) / (l_top_stor - l_bottom_stor);
   if cwms_util.is_true(p_0_to_100) then
      l_percent_full := least(greatest(0, l_percent_full), 100);
   end if;
   p_percent_full := cwms_rounding.round_nn_f(l_percent_full, '3333333332');
end get_percent_full;
--------------------------------------------------------------------------------
-- function get_percent_full_f
--------------------------------------------------------------------------------
function get_percent_full_f(
   p_project_id   in varchar2,
   p_pool_name    in varchar2,
   p_unit         in varchar2,
   p_value        in number,
   p_datetime     in date default null,
   p_timezone     in varchar2 default null,
   p_0_to_100     in varchar2 default 'F',
   p_always_rate  in varchar2 default 'T',
   p_rating_spec  in varchar2 default null,
   p_office_id    in varchar2 default null)
   return number
is
   l_percent_full number;
begin
   get_percent_full(
      p_percent_full => l_percent_full,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_value        => p_value,
      p_datetime     => p_datetime,
      p_timezone     => p_timezone,
      p_0_to_100     => p_0_to_100,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

   return l_percent_full;
end get_percent_full_f;
--------------------------------------------------------------------------------
-- procedure get_percent_full
--------------------------------------------------------------------------------
procedure get_percent_full(
   p_percent_full out number_tab_t,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_values       in  number_tab_t,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   l_values       number_tab_t;
   l_bottom_stors number_tab_t;
   l_top_stors    number_tab_t;
   l_percent_full number_tab_t;
   l_doubles      double_tab_t;
   l_unit         varchar2(32);
   l_office_id    varchar2(16);
   l_rating_spec  varchar2(256);
   l_count        pls_integer;
   l_is_storage   boolean;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_values is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_VALUES');
   end if;
   select count(*)
     into l_count
     from av_unit
    where upper(unit_id) = upper(p_unit)
      and abstract_param_id = 'Volume';
   if l_count > 0 then
      l_is_storage := true;
   else
      select count(*)
        into l_count
        from av_unit
       where upper(unit_id) = upper(p_unit)
         and abstract_param_id = 'Length';
      if l_count > 0 then
         l_is_storage := false;
      else
         cwms_err.raise(
         'ERROR',
         'Unit '
         ||p_unit
         ||' must be a unit for either elevation or storage');
      end if;
   end if;
   ---------------------------------------
   -- make sure we have a storage value --
   ---------------------------------------
   if l_is_storage then
      -------------------
      -- use specified --
      -------------------
      l_unit   := p_unit;
      l_values := p_values;
   else
      --------------------
      -- rate elevation --
      --------------------
      l_rating_spec := case
                       when p_rating_spec is not null then p_rating_spec
                       else get_elev_stor_rating(p_project_id, l_office_id)
                       end;
      l_unit := 'ac-ft';
      select to_binary_double(column_value) bulk collect into l_doubles from table(p_values);
      l_doubles := cwms_rating.rate_f(
         l_rating_spec,
         double_tab_tab_t(l_doubles),
         str_tab_t(p_unit, l_unit),
         'F',
         p_datetimes,
         null,
         p_timezone,
         l_office_id);
      select to_number(column_value) bulk collect into l_values from table(l_doubles);
   end if;
   --------------------------------------
   -- retrieve the pool storage limits --
   --------------------------------------
   get_pool_limit_stors(
      p_bottom_stors => l_bottom_stors,
      p_top_stors    => l_top_stors,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => l_unit,
      p_datetimes    => p_datetimes,
      p_timezone     => p_timezone,
      p_always_rate  => p_always_rate,
      p_rating_spec  => l_rating_spec,
      p_office_id    => l_office_id);
   ------------------------------
   -- compute the percent full --
   ------------------------------
   l_percent_full := number_tab_t();
   l_percent_full.extend(p_datetimes.count);
   for i in 1..p_datetimes.count loop
      l_percent_full(i) := 100 * (l_values(i) - l_bottom_stors(i)) / (l_top_stors(i) - l_bottom_stors(i));
      if cwms_util.is_true(p_0_to_100) then
         l_percent_full(i) := least(greatest(0, l_percent_full(i)), 100);
      end if;
   end loop;
   select cwms_rounding.round_nn_f(column_value, '3333333332')
     bulk collect
     into p_percent_full
     from table(l_percent_full);
end get_percent_full;
--------------------------------------------------------------------------------
-- function get_percent_full_f
--------------------------------------------------------------------------------
function get_percent_full_f(
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_values       in  number_tab_t,
   p_datetimes    in  date_table_type,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
   return number_tab_t
is
   l_percent_full number_tab_t;
begin
   get_percent_full(
      p_percent_full => l_percent_full,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_values       => p_values,
      p_datetimes    => p_datetimes,
      p_timezone     => p_timezone,
      p_0_to_100     => p_0_to_100,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

   return l_percent_full;
end get_percent_full_f;
--------------------------------------------------------------------------------
-- procedure get_percent_full
--------------------------------------------------------------------------------
procedure get_percent_full(
   p_percent_full out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   l_values       number_tab_t;
   l_percent_full ztsv_array;
   l_datetimes    date_table_type;
   l_office_id    varchar2(16);
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_unit is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_UNIT');
   end if;
   if p_timeseries is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TIMESERIES');
   end if;

   select date_time,
          value
     bulk collect
     into l_datetimes,
          l_values
     from table(p_timeseries);

   get_percent_full(
      p_percent_full => l_values,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_values       => l_values,
      p_datetimes    => l_datetimes,
      p_timezone     => p_timezone,
      p_0_to_100     => p_0_to_100,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

   l_percent_full := ztsv_array();
   l_percent_full.extend(l_values.count);
   for i in 1..l_values.count loop
      l_percent_full(i) := ztsv_type(l_datetimes(i), l_values(i), 0);
   end loop;
   p_percent_full := l_percent_full;

end get_percent_full;
--------------------------------------------------------------------------------
-- function get_percent_full_f
--------------------------------------------------------------------------------
function get_percent_full_f(
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_unit         in  varchar2,
   p_timeseries   in  ztsv_array,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
   return ztsv_array
is
   l_percent_full ztsv_array;
begin
   get_percent_full(
      p_percent_full => l_percent_full,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => p_unit,
      p_timeseries   => p_timeseries,
      p_timezone     => p_timezone,
      p_0_to_100     => p_0_to_100,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

	return l_percent_full;
end get_percent_full_f;
--------------------------------------------------------------------------------
-- procedure get_percent_full
--------------------------------------------------------------------------------
procedure get_percent_full(
   p_percent_full out ztsv_array,
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   c_ts                sys_refcursor;
   l_ts1               cwms_ts.zts_tab_t;
   l_ts2               ztsv_array;
   l_base_location_id  varchar2(24);
   l_sub_location_id   varchar2(32);
   l_base_parameter_id varchar2(16);
   l_sub_parameter_id  varchar2(32);
   l_parameter_type_id varchar2(16);
   l_interval_id       varchar2(16);
   l_duration_id       varchar2(16);
   l_version_id        varchar2(32);
   l_unit              varchar2(32);
   l_percent_full      ztsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_PROJECT_ID');
   end if;
   if p_pool_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_POOL_NAME');
   end if;
   if p_tsid is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME');
   end if;
   cwms_ts.parse_ts(
      p_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   if upper(l_base_location_id) != upper(cwms_util.get_base_id(p_project_id)) then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not for specified project '
         ||p_project_id);
   elsif l_base_parameter_id not in ('Elev', 'Stor') then
      cwms_err.raise(
         'ERROR',
         'Time series '
         ||p_tsid
         ||' is not an elevation or storage time series');
   end if;
   l_unit := cwms_util.get_default_units(l_base_parameter_id);
   cwms_ts.retrieve_ts(
      p_at_tsv_rc         =>  c_ts,
      p_cwms_ts_id        =>  p_tsid,
      p_units             =>  l_unit,
      p_start_time        =>  p_start_time,
      p_end_time          =>  p_end_time,
      p_time_zone         =>  p_timezone,
      p_trim              =>  'T',
      p_start_inclusive   =>  'T',
      p_end_inclusive     =>  'T',
      p_previous          =>  'F',
      p_next              =>  'F',
      p_version_date      =>  null,
      p_max_version       =>  'T',
      p_office_id         =>  p_office_id);

   fetch c_ts bulk collect into l_ts1;
   close c_ts;
   l_ts2 := ztsv_array();
   l_ts2.extend(l_ts1.count);
   for i in 1..l_ts1.count loop
      l_ts2(i) := ztsv_type(l_ts1(i).date_time, l_ts1(i).value, 0);
   end loop;

   get_percent_full(
      p_percent_full => p_percent_full,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_unit         => l_unit,
      p_timeseries   => l_ts2,
      p_timezone     => p_timezone,
      p_0_to_100     => p_0_to_100,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

end get_percent_full;
--------------------------------------------------------------------------------
-- function get_percent_full_f
--------------------------------------------------------------------------------
function get_percent_full_f(
   p_project_id   in  varchar2,
   p_pool_name    in  varchar2,
   p_tsid         in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_timezone     in  varchar2 default null,
   p_0_to_100     in  varchar2 default 'F',
   p_always_rate  in  varchar2 default 'T',
   p_rating_spec  in  varchar2 default null,
   p_office_id    in  varchar2 default null)
   return ztsv_array
is
   l_percent_full ztsv_array;
begin
   get_percent_full(
      p_percent_full => l_percent_full,
      p_project_id   => p_project_id,
      p_pool_name    => p_pool_name,
      p_tsid         => p_tsid,
      p_start_time   => p_start_time,
      p_end_time     => p_end_time,
      p_timezone     => p_timezone,
      p_0_to_100     => p_0_to_100,
      p_always_rate  => p_always_rate,
      p_rating_spec  => p_rating_spec,
      p_office_id    => p_office_id);

	return l_percent_full;
end get_percent_full_f;

end cwms_pool;
/
show errors

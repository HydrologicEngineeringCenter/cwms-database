create or replace package body cwms_entity as
--------------------------------------------------------------------------------
-- PROCEDURE STORE_ENTITY
procedure store_entity (
   p_entity_id        in varchar2,
   p_entity_name      in varchar2,
   p_parent_entity_id in varchar2 default null,
   p_category_id      in varchar2 default null,
   p_fail_if_exists   in varchar2 default 'T',
   p_ignore_nulls     in varchar2 default 'T',
   p_office_id        in varchar2 default null)
is
   l_rec              at_entity%rowtype;
   l_exists           boolean;
   l_fail_if_exists   boolean;
   l_ignore_nulls     boolean;
   l_modified         boolean;
   l_office_id        cwms_office.office_id%type;
   l_office_code      cwms_office.office_code%type;
begin
   l_modified       := false;
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.return_true_or_false(p_ignore_nulls);
   l_office_id      := nvl(upper(trim(p_office_id)), cwms_util.user_office_id);
   l_office_code    := cwms_util.get_office_code(l_office_id);
   --------------------------------------
   -- see if the entity already exists --
   --------------------------------------
   begin
      select *
        into l_rec
        from at_entity
       where upper(entity_id) = upper(trim(p_entity_id))
         and office_code in (cwms_util.db_office_code_all, l_office_code);
      l_exists := true;
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists then
      ---------------------------
      -- entity already exists --
      ---------------------------
      if l_fail_if_exists then
         cwms_err.raise('ITEM_ALREADY_EXISTS', 'Entity', p_entity_id);
      end if;
      if l_rec.office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
         cwms_err.raise('ERROR', 'Cannot update a CWMS-owned entity');
      end if;
      if not (l_ignore_nulls and p_entity_name is null) then
         l_rec.entity_name := trim(p_entity_name);
         l_modified := true;
      end if;
      if not (l_ignore_nulls and p_parent_entity_id is null) then
         l_modified := (p_parent_entity_id is null) != (l_rec.parent_code is null);
         if p_parent_entity_id is null then
            l_rec.parent_code := null;
         else
            l_rec.parent_code := get_entity_code(p_parent_entity_id, l_office_id);
         end if;
      end if;
      if not (l_ignore_nulls and p_category_id is null) then
         l_rec.category_id := upper(trim(p_category_id));
         l_modified := true;
      end if;
      if l_modified then
         update at_entity set row = l_rec where entity_code = l_rec.entity_code;
      end if;
   else
      ---------------------------
      -- entity does not exist --
      ---------------------------
      l_rec.entity_code := cwms_seq.nextval;
      if p_parent_entity_id is not null then
         l_rec.parent_code := get_entity_code(p_parent_entity_id, l_office_id);
      end if;
      l_rec.office_code := l_office_code;
      l_rec.category_id := upper(trim(p_category_id));
      l_rec.entity_id   := trim(p_entity_id);
      l_rec.entity_name := trim(p_entity_name);
      insert into at_entity values l_rec;
   end if;
end store_entity;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_ENTITY
procedure retrieve_entity (
   p_entity_code      in out nocopy integer,
   p_office_id_out    in out nocopy varchar2,
   p_parent_entity_id in out nocopy varchar2,
   p_category_id      in out nocopy varchar2,
   p_entity_name      in out nocopy varchar2,
   p_entity_id        in varchar2,
   p_office_id        in varchar2 default null)
is
   l_rec         at_entity%rowtype;
   l_office_code cwms_office.office_code%type;
begin
   l_office_code := cwms_util.get_office_code(p_office_id);

   select *
     into l_rec
     from at_entity
    where upper(entity_id) = upper(trim(p_entity_id))
      and office_code in (cwms_util.db_office_code_all, l_office_code);

   p_entity_code := l_rec.entity_code;
   select office_id into p_office_id_out from cwms_office where office_code = l_rec.office_code;
   if l_rec.parent_code is null then
      p_parent_entity_id := null;
   else
      select entity_id into p_parent_entity_id from at_entity where entity_code = l_rec.parent_code;
   end if;
   p_category_id := l_rec.category_id;
   p_entity_name := l_rec.entity_name;
exception
   when no_data_found then
      cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Entity', p_entity_id);
end retrieve_entity;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_ENTITY
procedure retrieve_entity (
   p_entity_id        in out nocopy varchar2,
   p_office_id        in out nocopy varchar2,
   p_parent_entity_id in out nocopy varchar2,
   p_category_id      in out nocopy varchar2,
   p_entity_name      in out nocopy varchar2,
   p_entity_code      in integer)
is
   l_rec at_entity%rowtype;
begin
   select *
     into l_rec
     from at_entity
    where entity_code = p_entity_code;

   p_entity_id := l_rec.entity_id;
   select office_id into p_office_id from cwms_office where office_code = l_rec.office_code;
   if l_rec.parent_code is null then
      p_parent_entity_id := null;
   else
      select entity_id into p_parent_entity_id from at_entity where entity_code = l_rec.parent_code;
   end if;
   p_category_id := l_rec.category_id;
   p_entity_name := l_rec.entity_name;
exception
   when no_data_found then
      cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Entity', p_entity_code);
end retrieve_entity;

--------------------------------------------------------------------------------
-- FUNCTION GET_ENTITY_CODE
function get_entity_code (
   p_entity_id in varchar2,
   p_office_id in varchar2 default null)
   return integer
is
   l_entity_code integer;
begin
   select entity_code
     into l_entity_code
     from at_entity
    where upper(entity_id) = upper(trim(p_entity_id))
      and office_code in (cwms_util.get_office_code(p_office_id), cwms_util.db_office_code_all);

   return l_entity_code;
exception
   when no_data_found then
      cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Entity', p_entity_id);
end get_entity_code;

--------------------------------------------------------------------------------
-- FUNCTION GET_ENTITY_ID
function get_entity_id (
   p_entity_code in integer)
   return varchar2
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -20034);
   l_entity_id        at_entity.entity_id%type;
   l_office_id        cwms_office.office_id%type;
   l_parent_entity_id at_entity.entity_id%type;
   l_category_id      at_entity.category_id%type;
   l_entity_name      at_entity.entity_name%type;
begin
   begin
      retrieve_entity (
         p_entity_id        => l_entity_id,
         p_office_id        => l_office_id,
         p_parent_entity_id => l_parent_entity_id,
         p_category_id      => l_category_id,
         p_entity_name      => l_entity_name,
         p_entity_code      => p_entity_code);
   exception
      when item_does_not_exist then null;
   end;

   return l_entity_id;
end get_entity_id;


--------------------------------------------------------------------------------
-- PRIVATE FUNCTION MAKE_ENTITY
function make_entity(
   p_entity_code in integer)
   return entity_t
is
   l_entity entity_t := entity_t(null, null, null, null);
begin
   select o.office_id,
          e.category_id,
          e.entity_id,
          e.entity_name
     into l_entity.office_id,
          l_entity.category_id,
          l_entity.entity_id,
          l_entity.entity_name
     from at_entity e,
          cwms_office o
    where e.entity_code = p_entity_code
      and o.office_code = e.office_code;

   return l_entity;
end make_entity;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_DESCENDANTS
procedure retrieve_descendants(
   p_descendants  out entity_tab_t,
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null)
is
begin
   p_descendants := retrieve_descendants_f(
      p_entity_id    => p_entity_id,
      p_direct_only  => p_direct_only,
      p_include_self => p_include_self,
      p_office_id    => p_office_id);
end retrieve_descendants;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_DESCENDANTS_F
function retrieve_descendants_f(
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null)
   return entity_tab_t
is
begin
   return retrieve_descendants_f(
      p_entity_code  => get_entity_code(p_entity_id, p_office_id),
      p_direct_only  => p_direct_only,
      p_include_self => p_include_self);
end retrieve_descendants_f;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_DESCENDANTS
procedure retrieve_descendants(
   p_descendants  out entity_tab_t,
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2)
is
begin
   p_descendants := retrieve_descendants_f(
      p_entity_code  => p_entity_code,
      p_direct_only  => p_direct_only,
      p_include_self => p_include_self);
end retrieve_descendants;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_DESCENDANTS_F
function retrieve_descendants_f(
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2)
   return entity_tab_t
is
   l_direct_only  boolean;
   l_include_self boolean;
   l_entity_codes number_tab_t;
   l_parent_codes number_tab_t;
   l_descendants  entity_tab_t;
begin
   l_direct_only  := cwms_util.return_true_or_false(p_direct_only);
   l_include_self := cwms_util.return_true_or_false(p_include_self);

   if l_direct_only then
      select entity_code
        bulk collect
        into l_entity_codes
        from at_entity
       where parent_code = p_entity_code;
   else
      select parent_code,
             entity_code
        bulk collect
        into l_parent_codes,
             l_entity_codes
        from at_entity
       where entity_code != p_entity_code
        start with entity_code = p_entity_code
      connect by prior entity_code = parent_code;
   end if;
   l_descendants := entity_tab_t();
   if l_include_self then
      l_descendants.extend;
      l_descendants(1) := make_entity(p_entity_code);
   end if;
   l_descendants.extend(l_entity_codes.count);
   for i in 1..l_entity_codes.count loop
      l_descendants(case l_include_self when true then i+1 else i end) := make_entity(l_entity_codes(i));
   end loop;

   return l_descendants;
end retrieve_descendants_f;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_ANCESTORS
procedure retrieve_ancestors(
   p_ancestors    out entity_tab_t,
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null)
is
begin
   p_ancestors := retrieve_ancestors_f(
      p_entity_id    => p_entity_id,
      p_direct_only  => p_direct_only,
      p_include_self => p_include_self,
      p_office_id    => p_office_id);
end retrieve_ancestors;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_ANCESTORS_F
function retrieve_ancestors_f(
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null)
   return entity_tab_t
is
begin
   return retrieve_ancestors_f(
      p_entity_code  => cwms_entity.get_entity_code(p_entity_id, p_office_id),
      p_direct_only  => p_direct_only,
      p_include_self => p_include_self);
end retrieve_ancestors_f;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_ANCESTORS
procedure retrieve_ancestors(
   p_ancestors    out entity_tab_t,
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2)
is
begin
   p_ancestors := retrieve_ancestors_f(
      p_entity_code  => p_entity_code,
      p_direct_only  => p_direct_only,
      p_include_self => p_include_self);
end retrieve_ancestors;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_ANCESTORS_F
function retrieve_ancestors_f(
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2)
   return entity_tab_t
is
   l_direct_only  boolean;
   l_include_self boolean;
   l_rec          at_entity%rowtype;
   l_entity_codes number_tab_t;
   l_parent_codes number_tab_t;
   l_ancestors    entity_tab_t;
begin
   l_direct_only  := cwms_util.return_true_or_false(p_direct_only);
   l_include_self := cwms_util.return_true_or_false(p_include_self);
   l_ancestors    := entity_tab_t();

   if l_include_self then
      l_ancestors.extend;
      l_ancestors(1) := make_entity(p_entity_code);
   end if;
   if l_direct_only then
      select *
        into l_rec
        from at_entity
       where entity_code = p_entity_code;
      if l_rec.parent_code is not null then
         l_ancestors.extend;
         l_ancestors(l_ancestors.count) := make_entity(l_rec.parent_code);
      end if;
   else
      select parent_code,
             entity_code
        bulk collect
        into l_parent_codes,
             l_entity_codes
        from at_entity
        start with entity_code = p_entity_code
      connect by prior parent_code = entity_code;

      l_ancestors.extend(l_parent_codes.count);
      for i in 1..l_parent_codes.count loop
         if l_parent_codes(i) is null then
            l_ancestors.trim(l_parent_codes.count - i + 1);
            exit;
         end if;
         l_ancestors(case l_include_self when true then i+1 else i end) := make_entity(l_parent_codes(i));
      end loop;
   end if;

   return l_ancestors;
end retrieve_ancestors_f;

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_ENTITY
procedure delete_entity (
   p_entity_code           in integer,
   p_delete_child_entities in varchar default 'F')
is
   l_office_code        integer;
   l_entity_office_code integer;
   l_entity_codes       number_tab_t;
begin
   select office_code into l_entity_office_code from at_entity where entity_code = p_entity_code;
   if l_entity_office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
      cwms_err.raise('ERROR', 'Cannot delete a CWMS-owned entity');
   end if;
   if cwms_util.is_true(p_delete_child_entities) then
      select get_entity_code(entity_id, office_id)
        bulk collect
        into l_entity_codes
        from table(retrieve_descendants_f(
                      p_entity_code  => p_entity_code,
                      p_direct_only  => 'F',
                      p_include_self => 'F'));

      for i in reverse 1..l_entity_codes.count loop
         delete from at_entity where entity_code = l_entity_codes(i);
      end loop;
   end if;
   delete from at_entity where entity_code = p_entity_code;
end delete_entity;

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_ENTITY
procedure delete_entity (
   p_entity_id             in varchar2,
   p_delete_child_entities in varchar default 'F',
   p_office_id             in varchar2 default null)
is
begin
   delete_entity(
      get_entity_code(p_entity_id, p_office_id),
      p_delete_child_entities);
end delete_entity;

--------------------------------------------------------------------------------
-- PROCEDURE CAT_ENTITIES
procedure cat_entities (
   p_entity_cursor         out sys_refcursor,
   p_entity_id_mask        in varchar2 default '*',
   p_parent_entity_id_mask in varchar2 default '*',
   p_match_null_parents    in varchar2 default 'T',
   p_category_id_mask      in varchar2 default '*',
   p_entity_name_mask      in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
is
begin
   p_entity_cursor := cat_entities_f(
      p_entity_id_mask        => p_entity_id_mask,
      p_parent_entity_id_mask => p_parent_entity_id_mask,
      p_match_null_parents    => p_match_null_parents,
      p_category_id_mask      => p_category_id_mask,
      p_entity_name_mask      => p_entity_name_mask,
      p_office_id_mask        => p_office_id_mask);
end cat_entities;

--------------------------------------------------------------------------------
-- FUNCTION CAT_ENTITIES_F
function cat_entities_f (
   p_entity_id_mask        in varchar2 default '*',
   p_parent_entity_id_mask in varchar2 default '*',
   p_match_null_parents    in varchar2 default 'T',
   p_category_id_mask      in varchar2 default '*',
   p_entity_name_mask      in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor
is
   l_entity_id_mask        at_entity.entity_id%type;
   l_parent_entity_id_mask at_entity.entity_id%type;
   l_category_id_mask      at_entity.category_id%type;
   l_entity_name_mask      at_entity.entity_name%type;
   l_office_id_mask        cwms_office.office_id%type;
   l_match_null_parents    pls_integer;
   l_cursor                sys_refcursor;
begin
   l_entity_id_mask        := cwms_util.normalize_wildcards(upper(trim(p_entity_id_mask)));
   l_parent_entity_id_mask := cwms_util.normalize_wildcards(upper(trim(p_parent_entity_id_mask)));
   l_category_id_mask      := cwms_util.normalize_wildcards(upper(trim(p_category_id_mask)));
   l_entity_name_mask      := cwms_util.normalize_wildcards(upper(trim(p_entity_name_mask)));
   l_office_id_mask        := cwms_util.normalize_wildcards(upper(trim(p_office_id_mask)));
   l_match_null_parents    := case cwms_util.return_true_or_false(p_match_null_parents) when true then 1 else 0 end;
   open l_cursor for
      select o.office_id,
             e.entity_id,
             get_entity_id(e.parent_code) as parent_entity_id,
             e.category_id,
             e.entity_name,
             e.entity_code,
             e.parent_code
        from at_entity e,
             cwms_office o
       where case
             when l_office_id_mask is null and o.office_id in (cwms_util.user_office_id, 'CWMS') then 1
             when l_office_id_mask is not null and o.office_id like l_office_id_mask escape '\' then 1
             else 0
             end = 1
         and e.office_code = o.office_code
         and upper(e.entity_id) like l_entity_id_mask escape '\'
         and case
             when l_match_null_parents = 0 and get_entity_id(e.parent_code) like l_parent_entity_id_mask escape '\' then 1
             when l_match_null_parents = 1 and (e.parent_code is null or get_entity_id(e.parent_code) like l_parent_entity_id_mask escape '\') then 1
             else 0
             end = 1
         and e.category_id like l_category_id_mask escape '\'
         and upper(e.entity_name) like l_entity_name_mask escape '\';

   return l_cursor;
end cat_entities_f;

--------------------------------------------------------------------------------
-- PROCEDURE STORE_ENTITY_LOCATION
procedure store_entity_location(
   p_location_code  in integer,
   p_entity_code    in integer,
   p_comments       in varchar2,
   p_fail_if_exists in varchar2)
is
   l_rec       at_entity_location%rowtype;
   l_exists    boolean;
   l_office_id cwms_office.office_id%type;
begin
   l_rec.location_code := p_location_code;
   begin
      select *
        into l_rec
        from at_entity_location
       where location_code = l_rec.location_code;
      l_exists := true;
   exception
      when no_data_found then l_exists := false;
   end;
   if l_exists and cwms_util.return_true_or_false(p_fail_if_exists) then
      select o.office_id
        into l_office_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Entity location',
         l_office_id||'/'||cwms_loc.get_location_id(p_location_code));
   end if;
   l_rec.entity_code := p_entity_code;
   l_rec.comments := nvl(p_comments, l_rec.comments);

   if l_exists then
      update at_entity_location
         set row = l_rec
       where location_code = l_rec.location_code;
   else
      insert into at_entity_location values l_rec;
      cwms_loc.update_location_kind(l_rec.location_code, 'ENTITY', 'A');
   end if;
end store_entity_location;

--------------------------------------------------------------------------------
-- PROCEDURE STORE_ENTITY_LOCATION
procedure store_entity_location(
   p_location_id    in varchar2,
   p_entity_id      in varchar2,
   p_comments       in varchar2,
   p_fail_if_exists in varchar2,
   p_office_id      in varchar2 default null)
is
begin
   store_entity_location(
      cwms_loc.get_location_code(p_office_id, p_location_id),
      get_entity_code(p_entity_id, p_office_id),
      p_comments,
      p_fail_if_exists);
end store_entity_location;

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_ENTITY_LOCATION
procedure delete_entity_location(
   p_location_code       in integer,
   p_delete_location     in varchar2 default 'F',
   p_delete_entity       in varchar2 default 'F',
   p_del_location_action in varchar2 default 'DELETE KEY',
   p_del_child_entities  in varchar2 default 'F')
is
   l_entity_code integer;
   l_office_id   cwms_office.office_id%type;
begin
   begin
      select entity_code
        into l_entity_code
        from at_entity_location
       where location_code = p_location_code;
   exception
      when no_data_found then
         select o.office_id
           into l_office_id
           from at_physical_location pl,
                at_base_location bl,
                cwms_office o
          where pl.location_code = p_location_code
            and bl.base_location_code = pl.base_location_code
            and o.office_code = bl.db_office_code;
         cwms_err.raise(
            'ERROR',
            'No entity is associated with location ',
            l_office_id||'/'||cwms_loc.get_location_id(p_location_code));
   end;
   delete from at_entity_location where location_code = p_location_code;
   cwms_loc.update_location_kind(p_location_code, 'ENTITY', 'D');
   if cwms_util.return_true_or_false(p_delete_location) then
      cwms_loc.delete_location(p_location_code, p_del_location_action);
   end if;
   if cwms_util.return_true_or_false(p_delete_entity) then
      delete_entity(l_entity_code, p_del_child_entities);
   end if;
end delete_entity_location;

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_ENTITY_LOCATION
procedure delete_entity_location(
   p_location_id         in varchar2,
   p_delete_location     in varchar2 default 'F',
   p_delete_entity       in varchar2 default 'F',
   p_del_location_action in varchar2 default 'DELETE KEY',
   p_del_child_entities  in varchar2 default 'F',
   p_office_id           in varchar2 default null)
is
begin
   delete_entity_location(
      cwms_loc.get_location_code(p_office_id, p_location_id),
      p_delete_location,
      p_delete_entity,
      p_del_location_action,
      p_del_child_entities);
end delete_entity_location;

end cwms_entity;
/

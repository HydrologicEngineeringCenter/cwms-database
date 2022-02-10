create or replace package body cwms_configuration as
--------------------------------------------------------------------------------
-- PROCEDURE STORE_CONFIGURATION
procedure store_configuration (
   p_configuration_id        in varchar2,
   p_configuration_name      in varchar2,
   p_parent_configuration_id in varchar2 default null,
   p_category_id             in varchar2 default null,
   p_fail_if_exists          in varchar2 default 'T',
   p_ignore_nulls            in varchar2 default 'T',
   p_office_id               in varchar2 default null)
is
   l_rec              at_configuration%rowtype;
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
   ---------------------------------------------
   -- see if the configuration already exists --
   ---------------------------------------------
   begin
      select *
        into l_rec
        from at_configuration
       where upper(configuration_id) = upper(trim(p_configuration_id))
         and office_code in (cwms_util.db_office_code_all, l_office_code);
      l_exists := true;
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists then
      ----------------------------------
      -- configuration already exists --
      ----------------------------------
      if l_fail_if_exists then
         cwms_err.raise('ITEM_ALREADY_EXISTS', 'Configuration', p_configuration_id);
      end if;
      if l_rec.office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
         cwms_err.raise('ERROR', 'Cannot update a CWMS-owned configuration');
      end if;
      if not (l_ignore_nulls and p_configuration_name is null) then
         l_rec.configuration_name := trim(p_configuration_name);
         l_modified := true;
      end if;
      if not (l_ignore_nulls and p_parent_configuration_id is null) then
         l_modified := (p_parent_configuration_id is null) != (l_rec.parent_code is null);
         if p_parent_configuration_id is null then
            l_rec.parent_code := null;
         else
            l_rec.parent_code := get_configuration_code(p_parent_configuration_id, l_office_id);
         end if;
      end if;
      if not (l_ignore_nulls and p_category_id is null) then
         l_rec.category_id := upper(trim(p_category_id));
         l_modified := true;
      end if;
      if l_modified then
         update at_configuration set row = l_rec where configuration_code = l_rec.configuration_code;
      end if;
   else
      ----------------------------------
      -- configuration does not exist --
      ----------------------------------
      l_rec.configuration_code := cwms_seq.nextval;
      if p_parent_configuration_id is not null then
         l_rec.parent_code := get_configuration_code(p_parent_configuration_id, l_office_id);
      end if;
      l_rec.office_code := l_office_code;
      l_rec.category_id := upper(trim(p_category_id));
      l_rec.configuration_id   := trim(p_configuration_id);
      l_rec.configuration_name := trim(p_configuration_name);
      insert into at_configuration values l_rec;
   end if;
end store_configuration;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_CONFIGURATION
procedure retrieve_configuration (
   p_configuration_code      in out nocopy integer,
   p_office_id_out           in out nocopy varchar2,
   p_parent_configuration_id in out nocopy varchar2,
   p_category_id             in out nocopy varchar2,
   p_configuration_name      in out nocopy varchar2,
   p_configuration_id        in varchar2,
   p_office_id               in varchar2 default null)
is
   l_rec         at_configuration%rowtype;
   l_office_code cwms_office.office_code%type;
begin
   l_office_code := cwms_util.get_office_code(p_office_id);

   select *
     into l_rec
     from at_configuration
    where upper(configuration_id) = upper(trim(p_configuration_id))
      and office_code in (cwms_util.db_office_code_all, l_office_code);

   p_configuration_code := l_rec.configuration_code;
   select office_id into p_office_id_out from cwms_office where office_code = l_rec.office_code;
   if l_rec.parent_code is null then
      p_parent_configuration_id := null;
   else
      select configuration_id into p_parent_configuration_id from at_configuration where configuration_code = l_rec.parent_code;
   end if;
   p_category_id := l_rec.category_id;
   p_configuration_name := l_rec.configuration_name;
exception
   when no_data_found then
      cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Configuration', p_configuration_id);
end retrieve_configuration;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_CONFIGURATION
procedure retrieve_configuration (
   p_configuration_id        in out nocopy varchar2,
   p_office_id               in out nocopy varchar2,
   p_parent_configuration_id in out nocopy varchar2,
   p_category_id             in out nocopy varchar2,
   p_configuration_name      in out nocopy varchar2,
   p_configuration_code      in integer)
is
   l_rec at_configuration%rowtype;
begin
   select *
     into l_rec
     from at_configuration
    where configuration_code = p_configuration_code;

   p_configuration_id := l_rec.configuration_id;
   select office_id into p_office_id from cwms_office where office_code = l_rec.office_code;
   if l_rec.parent_code is null then
      p_parent_configuration_id := null;
   else
      select configuration_id into p_parent_configuration_id from at_configuration where configuration_code = l_rec.parent_code;
   end if;
   p_category_id := l_rec.category_id;
   p_configuration_name := l_rec.configuration_name;
exception
   when no_data_found then
      cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Configuration', p_configuration_code);
end retrieve_configuration;

--------------------------------------------------------------------------------
-- FUNCTION GET_CONFIGURATION_CODE
function get_configuration_code (
   p_configuration_id in varchar2,
   p_office_id        in varchar2 default null)
   return integer
is
   l_configuration_code integer;
begin
   select configuration_code
     into l_configuration_code
     from at_configuration
    where upper(configuration_id) = upper(trim(p_configuration_id))
      and office_code in (cwms_util.get_office_code(p_office_id), cwms_util.db_office_code_all);

   return l_configuration_code;
exception
   when no_data_found then
      cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Configuration', p_configuration_id);
end get_configuration_code;

--------------------------------------------------------------------------------
-- FUNCTION GET_CONFIGURATION_ID
function get_configuration_id (
   p_configuration_code in integer)
   return varchar2
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -20034);
   l_configuration_id        at_configuration.configuration_id%type;
   l_office_id               cwms_office.office_id%type;
   l_parent_configuration_id at_configuration.configuration_id%type;
   l_category_id             at_configuration.category_id%type;
   l_configuration_name      at_configuration.configuration_name%type;
begin
   begin
      retrieve_configuration (
         p_configuration_id        => l_configuration_id,
         p_office_id        => l_office_id,
         p_parent_configuration_id => l_parent_configuration_id,
         p_category_id      => l_category_id,
         p_configuration_name      => l_configuration_name,
         p_configuration_code      => p_configuration_code);
   exception
      when item_does_not_exist then null;
   end;

   return l_configuration_id;
end get_configuration_id;


--------------------------------------------------------------------------------
-- PRIVATE FUNCTION MAKE_CONFIGURATION
function make_configuration(
   p_configuration_code in integer)
   return configuration_t
is
   l_configuration configuration_t := configuration_t(null, null, null, null);
begin
   select o.office_id,
          e.category_id,
          e.configuration_id,
          e.configuration_name
     into l_configuration.office_id,
          l_configuration.category_id,
          l_configuration.configuration_id,
          l_configuration.configuration_name
     from at_configuration e,
          cwms_office o
    where e.configuration_code = p_configuration_code
      and o.office_code = e.office_code;

   return l_configuration;
end make_configuration;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_DESCENDANTS
procedure retrieve_descendants(
   p_descendants         out configuration_tab_t,
   p_configuration_id    in  varchar2,
   p_direct_only         in  varchar2,
   p_include_self        in  varchar2,
   p_office_id           in  varchar2 default null)
is
begin
   p_descendants := retrieve_descendants_f(
      p_configuration_id => p_configuration_id,
      p_direct_only      => p_direct_only,
      p_include_self     => p_include_self,
      p_office_id        => p_office_id);
end retrieve_descendants;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_DESCENDANTS_F
function retrieve_descendants_f(
   p_configuration_id in  varchar2,
   p_direct_only      in  varchar2,
   p_include_self     in  varchar2,
   p_office_id        in  varchar2 default null)
   return configuration_tab_t
is
begin
   return retrieve_descendants_f(
      p_configuration_code => get_configuration_code(p_configuration_id, p_office_id),
      p_direct_only        => p_direct_only,
      p_include_self       => p_include_self);
end retrieve_descendants_f;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_DESCENDANTS
procedure retrieve_descendants(
   p_descendants        out configuration_tab_t,
   p_configuration_code in  integer,
   p_direct_only        in  varchar2,
   p_include_self       in  varchar2)
is
begin
   p_descendants := retrieve_descendants_f(
      p_configuration_code => p_configuration_code,
      p_direct_only        => p_direct_only,
      p_include_self       => p_include_self);
end retrieve_descendants;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_DESCENDANTS_F
function retrieve_descendants_f(
   p_configuration_code in  integer,
   p_direct_only        in  varchar2,
   p_include_self       in  varchar2)
   return configuration_tab_t
is
   l_direct_only         boolean;
   l_include_self        boolean;
   l_configuration_codes number_tab_t;
   l_parent_codes        number_tab_t;
   l_descendants         configuration_tab_t;
begin
   l_direct_only  := cwms_util.return_true_or_false(p_direct_only);
   l_include_self := cwms_util.return_true_or_false(p_include_self);

   if l_direct_only then
      select configuration_code
        bulk collect
        into l_configuration_codes
        from at_configuration
       where parent_code = p_configuration_code;
   else
      select parent_code,
             configuration_code
        bulk collect
        into l_parent_codes,
             l_configuration_codes
        from at_configuration
       where configuration_code != p_configuration_code
        start with configuration_code = p_configuration_code
      connect by prior configuration_code = parent_code;
   end if;
   l_descendants := configuration_tab_t();
   if l_include_self then
      l_descendants.extend;
      l_descendants(1) := make_configuration(p_configuration_code);
   end if;
   l_descendants.extend(l_configuration_codes.count);
   for i in 1..l_configuration_codes.count loop
      l_descendants(case l_include_self when true then i+1 else i end) := make_configuration(l_configuration_codes(i));
   end loop;

   return l_descendants;
end retrieve_descendants_f;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_ANCESTORS
procedure retrieve_ancestors(
   p_ancestors        out configuration_tab_t,
   p_configuration_id in  varchar2,
   p_direct_only      in  varchar2,
   p_include_self     in  varchar2,
   p_office_id        in  varchar2 default null)
is
begin
   p_ancestors := retrieve_ancestors_f(
      p_configuration_id => p_configuration_id,
      p_direct_only      => p_direct_only,
      p_include_self     => p_include_self,
      p_office_id        => p_office_id);
end retrieve_ancestors;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_ANCESTORS_F
function retrieve_ancestors_f(
   p_configuration_id in  varchar2,
   p_direct_only      in  varchar2,
   p_include_self     in  varchar2,
   p_office_id        in  varchar2 default null)
   return configuration_tab_t
is
begin
   return retrieve_ancestors_f(
      p_configuration_code => cwms_configuration.get_configuration_code(p_configuration_id, p_office_id),
      p_direct_only        => p_direct_only,
      p_include_self       => p_include_self);
end retrieve_ancestors_f;

--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_ANCESTORS
procedure retrieve_ancestors(
   p_ancestors          out configuration_tab_t,
   p_configuration_code in  integer,
   p_direct_only        in  varchar2,
   p_include_self       in  varchar2)
is
begin
   p_ancestors := retrieve_ancestors_f(
      p_configuration_code => p_configuration_code,
      p_direct_only        => p_direct_only,
      p_include_self       => p_include_self);
end retrieve_ancestors;

--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_ANCESTORS_F
function retrieve_ancestors_f(
   p_configuration_code in integer,
   p_direct_only        in varchar2,
   p_include_self       in varchar2)
   return configuration_tab_t
is
   l_direct_only  boolean;
   l_include_self boolean;
   l_rec          at_configuration%rowtype;
   l_configuration_codes number_tab_t;
   l_parent_codes number_tab_t;
   l_ancestors    configuration_tab_t;
begin
   l_direct_only  := cwms_util.return_true_or_false(p_direct_only);
   l_include_self := cwms_util.return_true_or_false(p_include_self);
   l_ancestors    := configuration_tab_t();

   if l_include_self then
      l_ancestors.extend;
      l_ancestors(1) := make_configuration(p_configuration_code);
   end if;
   if l_direct_only then
      select *
        into l_rec
        from at_configuration
       where configuration_code = p_configuration_code;
      if l_rec.parent_code is not null then
         l_ancestors.extend;
         l_ancestors(l_ancestors.count) := make_configuration(l_rec.parent_code);
      end if;
   else
      select parent_code,
             configuration_code
        bulk collect
        into l_parent_codes,
             l_configuration_codes
        from at_configuration
        start with configuration_code = p_configuration_code
      connect by prior parent_code = configuration_code;

      l_ancestors.extend(l_parent_codes.count);
      for i in 1..l_parent_codes.count loop
         if l_parent_codes(i) is null then
            l_ancestors.trim(l_parent_codes.count - i + 1);
            exit;
         end if;
         l_ancestors(case l_include_self when true then i+1 else i end) := make_configuration(l_parent_codes(i));
      end loop;
   end if;

   return l_ancestors;
end retrieve_ancestors_f;

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_CONFIGURATION
procedure delete_configuration (
   p_configuration_id            in varchar2,
   p_delete_child_configurations in varchar default 'F',
   p_office_id                   in varchar2 default null)
is
   l_configuration_code        integer;
   l_office_code               integer;
   l_configuration_office_code integer;
   l_configuration_codes       number_tab_t;
begin
   l_configuration_code := get_configuration_code(p_configuration_id, p_office_id);
   l_office_code := cwms_util.get_office_code(p_office_id);
   select office_code into l_configuration_office_code from at_configuration where configuration_code = l_configuration_code;
   if l_configuration_office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
      cwms_err.raise('ERROR', 'Cannot delete a CWMS-owned configuration');
   end if;
   if cwms_util.is_true(p_delete_child_configurations) then
      select get_configuration_code(configuration_id, office_id)
        bulk collect
        into l_configuration_codes
        from table(retrieve_descendants_f(
                      p_configuration_code  => get_configuration_code(p_configuration_id, p_office_id),
                      p_direct_only         => 'F',
                      p_include_self        => 'F'));

      for i in reverse 1..l_configuration_codes.count loop
         delete from at_configuration where configuration_code = l_configuration_codes(i);
      end loop;
   end if;
   delete from at_configuration where configuration_code = l_configuration_code;
end delete_configuration;

--------------------------------------------------------------------------------
-- PROCEDURE CAT_CONFIGURATIONS
procedure cat_configurations (
   p_configuration_cursor         out sys_refcursor,
   p_configuration_id_mask        in varchar2 default '*',
   p_parent_configuration_id_mask in varchar2 default '*',
   p_match_null_parents           in varchar2 default 'T',
   p_category_id_mask             in varchar2 default '*',
   p_configuration_name_mask      in varchar2 default '*',
   p_office_id_mask               in varchar2 default null)
is
begin
   p_configuration_cursor := cat_configurations_f(
      p_configuration_id_mask        => p_configuration_id_mask,
      p_parent_configuration_id_mask => p_parent_configuration_id_mask,
      p_match_null_parents           => p_match_null_parents,
      p_category_id_mask             => p_category_id_mask,
      p_configuration_name_mask      => p_configuration_name_mask,
      p_office_id_mask               => p_office_id_mask);
end cat_configurations;

--------------------------------------------------------------------------------
-- FUNCTION CAT_CONFIGURATIONS_F
function cat_configurations_f (
   p_configuration_id_mask        in varchar2 default '*',
   p_parent_configuration_id_mask in varchar2 default '*',
   p_match_null_parents           in varchar2 default 'T',
   p_category_id_mask             in varchar2 default '*',
   p_configuration_name_mask      in varchar2 default '*',
   p_office_id_mask               in varchar2 default null)
   return sys_refcursor
is
   l_configuration_id_mask        at_configuration.configuration_id%type;
   l_parent_configuration_id_mask at_configuration.configuration_id%type;
   l_category_id_mask             at_configuration.category_id%type;
   l_configuration_name_mask      at_configuration.configuration_name%type;
   l_office_id_mask               cwms_office.office_id%type;
   l_match_null_parents           pls_integer;
   l_cursor                       sys_refcursor;
begin
   l_configuration_id_mask        := cwms_util.normalize_wildcards(upper(trim(p_configuration_id_mask)));
   l_parent_configuration_id_mask := cwms_util.normalize_wildcards(upper(trim(p_parent_configuration_id_mask)));
   l_category_id_mask             := cwms_util.normalize_wildcards(upper(trim(p_category_id_mask)));
   l_configuration_name_mask      := cwms_util.normalize_wildcards(upper(trim(p_configuration_name_mask)));
   l_office_id_mask               := cwms_util.normalize_wildcards(upper(trim(p_office_id_mask)));
   l_match_null_parents           := case cwms_util.return_true_or_false(p_match_null_parents) when true then 1 else 0 end;
   open l_cursor for
      select o.office_id,
             e.configuration_id,
             get_configuration_id(e.parent_code) as parent_configuration_id,
             e.category_id,
             e.configuration_name,
             e.configuration_code,
             e.parent_code
        from at_configuration e,
             cwms_office o
       where case
             when l_office_id_mask is null and o.office_id in (cwms_util.user_office_id, 'CWMS') then 1
             when l_office_id_mask is not null and o.office_id like l_office_id_mask escape '\' then 1
             else 0
             end = 1
         and e.office_code = o.office_code
         and upper(e.configuration_id) like l_configuration_id_mask escape '\'
         and case
             when l_match_null_parents = 0 and get_configuration_id(e.parent_code) like l_parent_configuration_id_mask escape '\' then 1
             when l_match_null_parents = 1 and (e.parent_code is null or get_configuration_id(e.parent_code) like l_parent_configuration_id_mask escape '\') then 1
             else 0
             end = 1
         and e.category_id like l_category_id_mask escape '\'
         and upper(e.configuration_name) like l_configuration_name_mask escape '\';

   return l_cursor;
end cat_configurations_f;

end cwms_configuration;
/

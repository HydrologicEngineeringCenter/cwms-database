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
   l_ignore_nulls   := cwms_util.return_true_or_false(p_fail_if_exists);
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
         l_rec.parent_code := get_entity_code(p_parent_entity_id, l_office_id);
         l_modified := true;
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
      
   if p_entity_code is not null then
      p_entity_code := l_rec.entity_code;
   end if;
   if p_office_id_out is not null then
      select office_id into p_office_id_out from cwms_office where office_code = l_rec.office_code; 
   end if;
   if p_parent_entity_id is not null then
      if l_rec.parent_code is null then
         p_parent_entity_id := null;
      else
         select entity_id into p_parent_entity_id from at_entity where entity_code = l_rec.parent_code;
      end if;
   end if;
   if p_category_id is not null then
      p_category_id := l_rec.category_id;
   end if;
   if p_entity_name is not null then
      p_entity_name := l_rec.entity_name;
   end if;
exception
   when no_data_found then
      cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Entity', p_entity_id);
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
   l_entity_id at_entity.entity_id%type;
begin
   if p_entity_code is not null then
      select entity_id into l_entity_id from at_entity where entity_code = p_entity_code;
   end if;
   return l_entity_id;
end get_entity_id;   

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_ENTITY
procedure delete_entity (
   p_entity_id             in varchar2,
   p_delete_child_entities in varchar default 'F',
   p_office_id             in varchar2 default null)
is
   l_entity_code        integer;
   l_office_code        integer;
   l_entity_office_code integer;
   l_entity_codes       number_tab_t;
begin
   l_entity_code := get_entity_code(p_entity_id, p_office_id);
   l_office_code := cwms_util.get_office_code(p_office_id);
   select office_code into l_entity_office_code from at_entity where entity_code = l_entity_code;
   if l_entity_office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
      cwms_err.raise('ERROR', 'Cannot delete a CWMS-owned entity');
   end if;
   if cwms_util.return_true_or_false(p_delete_child_entities) then
      select entity_code
        bulk collect
        into l_entity_codes
        from (select entity_code
                from (select parent_code, 
                             entity_code
                        from at_entity 
                             start with entity_code = l_entity_code 
                             connect by prior entity_code = parent_code
                     )
               where parent_code = l_entity_code
              union all
              select entity_code
                from (select parent_code, 
                             entity_code
                        from at_entity 
                             start with entity_code = l_entity_code 
                             connect by prior entity_code = parent_code
                     )
               where parent_code != l_entity_code
             );
             
      for i in reverse 1..l_entity_codes.count loop
         delete from at_entity where entity_code = l_entity_codes(i);
      end loop;
   else
      delete from at_entity where entity_code = l_entity_code;
   end if;
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

end cwms_entity;
/

show errors

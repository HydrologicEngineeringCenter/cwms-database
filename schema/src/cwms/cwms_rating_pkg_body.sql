create or replace package body cwms_rating
as

function get_rating_method_code(
   p_rating_method_id in varchar2)
   return number
is
   l_code number(14);
   l_cache_key cwms_rating_method.rating_method_id%type;
begin
   l_cache_key := upper(p_rating_method_id);
   l_code := cwms_cache.get(g_method_code_cache, l_cache_key);
   if l_code is null then
      select rating_method_code
        into l_code
        from cwms_rating_method
       where rating_method_id = l_cache_key;

       cwms_cache.put(g_method_code_cache, l_cache_key, l_code);
   end if;

   return l_code;
end get_rating_method_code;

procedure delete_rating(
   p_rating_code in number)
is
   l_crsr sys_refcursor;
   l_ind1 number_tab_t;
   l_ind2 number_tab_t;
   l_dep  number_tab_t;
begin
   --------------------
   -- simple ratings --
   --------------------
   for j in 1..1 loop
      ----------------------------
      -- first the rating table --
      ----------------------------
      -------------------
      -- rating values --
      -------------------
      open l_crsr for
         select distinct
                   rating_ind_param_code,
                   dep_rating_ind_param_code
              from (select distinct
                           v.rating_ind_param_code,
                           v.dep_rating_ind_param_code
                      from at_rating_value v,at_rating_ind_parameter p
                       where v.RATING_IND_PARAM_CODE=p.RATING_IND_PARAM_CODE
                       and p.rating_code  = p_rating_code
                   )
           connect by prior dep_rating_ind_param_code = rating_ind_param_code;
      fetch l_crsr bulk collect into l_ind1, l_dep;
      close l_crsr;
      delete from at_rating_value where rating_ind_param_code in (select * from table(l_ind1));
      delete from at_rating_ind_param_spec where ind_param_spec_code in (select * from table(l_ind1));
      ----------------------
      -- extension values --
      ----------------------
      open l_crsr for
         select distinct
                   rating_ind_param_code,
                   dep_rating_ind_param_code
              from (select distinct
                           rating_ind_param_code,
                           dep_rating_ind_param_code
                      from at_rating_extension_value
                     where rating_ind_param_code in
                           (select rating_ind_param_code
                              from at_rating_ind_parameter
                             where rating_code  = p_rating_code
                           )
                   )
           connect by prior dep_rating_ind_param_code = rating_ind_param_code;
      fetch l_crsr bulk collect into l_ind2, l_dep;
      close l_crsr;
      delete from at_rating_extension_value where rating_ind_param_code in (select * from table(l_ind2));
      delete from at_rating_ind_param_spec where ind_param_spec_code in (select * from table(l_ind2));
      ------------------------
      -- rating + extension --
      ------------------------
      delete from at_rating_ind_parameter where rating_ind_param_code in(select * from table(l_ind1) union select * from table(l_ind2));
      ----------------------------------------------
      -- then any child ratings (shifts, offsets) --
      ----------------------------------------------
      for rec in
         (  select rating_code
              from at_rating
             where ref_rating_code = p_rating_code
         )
      loop
         delete_rating(rec.rating_code);
      end loop;
      -------------------------------
      -- finally the record itself --
      -------------------------------
      for k in 1..2 loop
         begin
      delete
        from at_rating
       where rating_code = p_rating_code;
            exit;
         exception
            when others then
               if k = 1 then
                  ----------------------------------------------------------------------------
                  -- won't have been deleted if shifts or offsets existed but had no values --
                  ----------------------------------------------------------------------------
                  delete from at_rating_ind_parameter where rating_code = p_rating_code;
               else
                  cwms_err.raise('ERROR', 'Deleting rating code '||p_rating_code||chr(10)||dbms_utility.format_error_backtrace);
               end if;
         end;
      end loop;
   end loop;
   --------------------------
   -- transitional ratings --
   --------------------------
   delete
     from at_transitional_rating_sel
    where transitional_rating_code = p_rating_code;

   delete
     from at_transitional_rating_src
    where transitional_rating_code = p_rating_code;

   delete
     from at_transitional_rating
    where transitional_rating_code = p_rating_code;
   ---------------------
   -- virtual ratings --
   ---------------------
   delete from at_virtual_rating_unit
    where virtual_rating_element_code in (select virtual_rating_element_code
                                            from at_virtual_rating_element
                                           where virtual_rating_code = p_rating_code
                                         );
   delete from at_virtual_rating_element
    where virtual_rating_code = p_rating_code;

   delete from at_virtual_rating
    where virtual_rating_code = p_rating_code;
   -----------------------
   -- remove from cache --
   -----------------------
   cwms_cache.remove_by_value(g_rating_code_cache, p_rating_code);

end delete_rating;

procedure delete_rating_spec(
   p_rating_spec_code in number,
   p_delete_action    in varchar2 default cwms_util.delete_key)
is
begin
   if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      for rec in
         (  select rating_code
             from at_rating
            where rating_spec_code = p_rating_spec_code
            union all
           select transitional_rating_code
             from at_transitional_rating
            where rating_spec_code = p_rating_spec_code
            union all
           select virtual_rating_code
             from at_virtual_rating
            where rating_spec_code = p_rating_spec_code
            union
           select transitional_rating_code
             from at_transitional_rating_src
            where rating_spec_code = p_rating_spec_code
            union
           select virtual_rating_code
             from at_virtual_rating_element
            where rating_spec_code = p_rating_spec_code
         )
      loop
         delete_rating(rec.rating_code);
      end loop;
   end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      --------------------
      -- rounding specs --
      --------------------
      delete
        from at_rating_ind_rounding
       where rating_spec_code = p_rating_spec_code;
      ----------------------------
      -- USGS rating hash codes --
      ----------------------------
      delete
        from at_usgs_rating_hash
       where rating_spec_code = p_rating_spec_code;
      ------------------
      -- rating specs --
      ------------------
      delete
        from at_rating_spec
       where rating_spec_code = p_rating_spec_code;
      -----------------------
      -- remove from cache --
      -----------------------
      cwms_cache.remove_by_value(g_spec_code_cache, p_rating_spec_code);
   end if;
end delete_rating_spec;

procedure delete_rating_template(
   p_rating_template_code in number,
   p_delete_action    in varchar2 default cwms_util.delete_key)
is
begin
   if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      for rec in
         (  select rating_spec_code
             from at_rating_spec
            where template_code = p_rating_template_code
         )
      loop
         delete_rating_spec(rec.rating_spec_code, cwms_util.delete_all);
      end loop;
   end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      delete
        from at_rating_ind_param_spec
       where template_code = p_rating_template_code;
      delete
        from at_rating_template
       where template_code = p_rating_template_code;
      -----------------------
      -- remove from cache --
      -----------------------
      cwms_cache.remove_by_value(g_template_code_cache, p_rating_template_code);
   end if;

end delete_rating_template;

--------------------------------------------------------------------------------
-- STORE TEMPLATES
--
procedure store_templates(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_node     xmltype;
   l_template rating_template_t;
begin
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(p_xml, '//rating-template['||i||']');
      exit when l_node is null;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         'Storing rating template '
         ||cwms_util.get_xml_text(l_node, '/rating-template/@office-id')
         ||'/'||regexp_replace(cwms_util.get_xml_text(l_node, '/rating-template/parameters-id'), '\s', '', 1, 0)
         ||separator1||regexp_replace(cwms_util.get_xml_text(l_node, '/rating-template/version'), '\s', '', 1, 0));
      l_template := rating_template_t(l_node);
      l_template.store(p_fail_if_exists);
   end loop;
end store_templates;

--------------------------------------------------------------------------------
-- STORE TEMPLATES
--
procedure store_templates(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2)
is
begin
   store_templates(xmltype(p_xml), p_fail_if_exists);
end store_templates;

--------------------------------------------------------------------------------
-- STORE TEMPLATES
--
procedure store_templates(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
begin
   store_templates(xmltype(p_xml), p_fail_if_exists);
end store_templates;

--------------------------------------------------------------------------------
-- STORE TEMPLATES
--
procedure store_templates(
   p_templates      in rating_template_tab_t,
   p_fail_if_exists in varchar2)
is
   l_templates rating_template_tab_t := p_templates;
begin
   if l_templates is not null then
      for i in 1..l_templates.count loop
         l_templates(i).store(p_fail_if_exists);
      end loop;
   end if;
end store_templates;

--------------------------------------------------------------------------------
-- CAT_TEMPLATE_IDS
--
procedure cat_template_ids(
   p_cat_cursor       out sys_refcursor,
   p_template_id_mask in  varchar2 default '*',
   p_office_id_mask   in  varchar2 default null)
is
   l_parts              str_tab_t;
   l_parameters_id_mask varchar2(256);
   l_version_mask       varchar2(32);
   l_office_id_mask     varchar2(16);
begin
   l_parts := cwms_util.split_text(p_template_id_mask, separator1);
   case l_parts.count
      when 1 then
         l_parameters_id_mask := l_parts(1);
         l_version_mask       := '*';
      when 2 then
         l_parameters_id_mask := l_parts(1);
         l_version_mask       := l_parts(2);
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id_mask,
            'rating template id mask');
   end case;
   l_parameters_id_mask := cwms_util.normalize_wildcards(l_parameters_id_mask, false);
   l_version_mask       := cwms_util.normalize_wildcards(l_version_mask, false);
   l_office_id_mask     := cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id));
   open p_cat_cursor for
      select o.office_id,
             rt.parameters_id
             ||separator1||rt.version as template_id,
             rt.parameters_id,
             rt.version
        from at_rating_template rt,
             cwms_office o
       where o.office_id like upper(l_office_id_mask) escape '\'
         and rt.office_code = o.office_code
         and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
         and upper(rt.version) like upper (l_version_mask) escape '\'
    order by o.office_id,
             rt.parameters_id,
             rt.version;
end cat_template_ids;

--------------------------------------------------------------------------------
-- CAT_TEMPLATE_IDS_F
--
function cat_template_ids_f(
   p_template_id_mask in  varchar2 default '*',
   p_office_id_mask          in  varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_template_ids(
      l_cursor,
      p_template_id_mask,
      p_office_id_mask);

   return l_cursor;
end cat_template_ids_f;

--------------------------------------------------------------------------------
-- RETRIEVE_TEMPLATES_OBJ
--
procedure retrieve_templates_obj(
   p_templates        out rating_template_tab_t,
   p_template_id_mask in  varchar2 default '*',
   p_office_id_mask   in  varchar2 default null)
is
   l_parts              str_tab_t;
   l_parameters_id_mask varchar2(256);
   l_version_mask       varchar2(32);
   l_office_id_mask     varchar2(16);
begin
   l_parts := cwms_util.split_text(p_template_id_mask, separator1);
   case l_parts.count
      when 1 then
         l_parameters_id_mask := l_parts(1);
         l_version_mask       := '*';
      when 2 then
         l_parameters_id_mask := l_parts(1);
         l_version_mask       := l_parts(2);
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id_mask,
            'rating template id mask');
   end case;
   l_parameters_id_mask := cwms_util.normalize_wildcards(l_parameters_id_mask, false);
   l_version_mask       := cwms_util.normalize_wildcards(l_version_mask, false);
   l_office_id_mask     := cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id));
   p_templates   := rating_template_tab_t();
   for rec in
      (  select rt.template_code
           from at_rating_template rt,
                cwms_office o
          where o.office_id like upper(l_office_id_mask) escape '\'
            and rt.office_code = o.office_code
            and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
            and upper(rt.version) like upper (l_version_mask) escape '\'
       order by o.office_id,
                rt.parameters_id,
                rt.version
      )
   loop
      p_templates.extend;
      p_templates(p_templates.count) := rating_template_t(rec.template_code);
   end loop;
end retrieve_templates_obj;

--------------------------------------------------------------------------------
-- RETRIEVE_TEMPLATES_OBJ_F
--
function retrieve_templates_obj_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return rating_template_tab_t
is
   l_templates rating_template_tab_t;
begin
   retrieve_templates_obj(
      l_templates,
      p_template_id_mask,
      p_office_id_mask);

   return l_templates;
end retrieve_templates_obj_f;

--------------------------------------------------------------------------------
-- RETRIEVE_TEMPLATES_XML
--
procedure retrieve_templates_xml(
   p_templates        out clob,
   p_template_id_mask in  varchar2 default '*',
   p_office_id_mask   in  varchar2 default null)
is
   l_text      clob;
   l_templates rating_template_tab_t;
begin
   retrieve_templates_obj(
      l_templates,
      p_template_id_mask,
      p_office_id_mask);
   dbms_lob.createtemporary(l_text, true);
   dbms_lob.open(l_text, dbms_lob.lob_readwrite);
   cwms_util.append(
      l_text,
      '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      ||'xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
   for i in 1..l_templates.count loop
      cwms_util.append(l_text, l_templates(i).to_clob);
   end loop;
   cwms_util.append(l_text, '</ratings>');
   dbms_lob.close(l_text);
   dbms_lob.createtemporary(p_templates, true);
   dbms_lob.open(p_templates, dbms_lob.lob_readwrite);
   cwms_util.append(p_templates, '<?xml version="1.0" encoding="utf-8"?>'||chr(10));
   cwms_util.append(p_templates, xmltype(l_text).extract('/node()').getclobval);
   dbms_lob.close(p_templates);
end retrieve_templates_xml;

--------------------------------------------------------------------------------
-- RETRIEVE_TEMPLATE_OBJ_F
--
function retrieve_templates_xml_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return clob
is
   l_clob clob;
begin
   retrieve_templates_xml(
      l_clob,
      p_template_id_mask,
      p_office_id_mask);

   return l_clob;
end retrieve_templates_xml_f;

--------------------------------------------------------------------------------
-- DELETE_TEMPLATES
--
procedure delete_templates(
   p_template_id_mask in varchar2 default '*',
   p_delete_action    in varchar2 default cwms_util.delete_key,
   p_office_id_mask   in varchar2 default null)
is
   l_templates     rating_template_tab_t;
   l_template_code number(14);
begin
   l_templates := retrieve_templates_obj_f(
      p_template_id_mask,
      p_office_id_mask);
   for i in 1..l_templates.count loop
      l_template_code := rating_template_t.get_template_code(
         l_templates(i).parameters_id,
         l_templates(i).version,
         l_templates(i).office_id);
      delete_rating_template(l_template_code, p_delete_action);
   end loop;
end delete_templates;

--------------------------------------------------------------------------------
-- GET_OPENING_PARAMETER
--
procedure get_opening_parameter(
   p_parameter out varchar2,
   p_position  out integer,
   p_template  in  varchar2)
is
   l_params str_tab_t;
begin
   l_params := cwms_util.split_text(cwms_util.split_text(p_template, 1, separator2, 1), separator3);
   for i in 1..l_params.count loop
      if cwms_util.get_base_id(l_params(i)) not in ('Count', 'Elev', 'Stage') then
         p_position  := i;
         p_parameter := l_params(i);
         return;
      end if;
   end loop;
   cwms_err.raise(
      'ERROR',
      '"Opening" parameter not found in rating template: '||p_template);
end get_opening_parameter;

--------------------------------------------------------------------------------
-- GET_OPENING_PARAMETER
--    returns the "opening" parameter of the rating template
--
-- p_template
--    the template text
--
function get_opening_parameter(
   p_template in varchar2)
   return varchar2
is
   l_param varchar2(49);
   l_pos   integer;
begin
   get_opening_parameter(l_param, l_pos, p_template);
   return l_param;
end get_opening_parameter;

--------------------------------------------------------------------------------
-- GET_OPENING_PARAMETER_POSITION
--    returns indepenent parameter position of the "opening" parameter of the
--    rating template
--
-- p_template
--    the template text
--
function get_opening_parameter_position(
   p_template in varchar2)
   return integer
is
   l_param varchar2(49);
   l_pos   integer;
begin
   get_opening_parameter(l_param, l_pos, p_template);
   return l_pos;
end get_opening_parameter_position;

--------------------------------------------------------------------------------
-- GET_OPENING_UNIT
--    returns the default "opening" unit of the rating template in the
--    specified unit system
--
-- p_template
--    the template text
--
-- p_unit_system
--    the desired unit system of the opening
--
function get_opening_unit(
   p_template    in varchar2,
   p_unit_system in varchar2 default 'SI')
   return varchar2
is
begin
   return cwms_util.get_default_units(get_opening_parameter(p_template), p_unit_system);
exception
   when others then
      return null;
end get_opening_unit;

--------------------------------------------------------------------------------
-- STORE_SPECS
--
procedure store_specs(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_node xmltype;
   l_spec rating_spec_t;
begin
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(p_xml, '//rating-spec['||i||']');
      exit when l_node is null;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         'Storing rating specification '
         ||cwms_util.get_xml_text(l_node, '/rating-spec/@office-id')
         ||'/'||regexp_replace(cwms_util.get_xml_text(l_node, '/rating-spec/rating-spec-id'), '\s', '', 1, 0));
      l_spec := rating_spec_t(l_node);
      l_spec.store(p_fail_if_exists);
   end loop;
end store_specs;

--------------------------------------------------------------------------------
-- STORE_SPECS
--
procedure store_specs(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2)
is
begin
   store_specs(xmltype(p_xml), p_fail_if_exists);
end store_specs;

--------------------------------------------------------------------------------
-- STORE_SPECS
--
procedure store_specs(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
begin
   store_specs(xmltype(p_xml), p_fail_if_exists);
end store_specs;

--------------------------------------------------------------------------------
-- STORE_SPECS
--
procedure store_specs(
   p_specs          in rating_spec_tab_t,
   p_fail_if_exists in varchar2)
is
   l_specs rating_spec_tab_t := p_specs;
begin
   if l_specs is not null then
      for i in 1.. l_specs.count loop
         l_specs(i).store(p_fail_if_exists);
      end loop;
   end if;
end store_specs;

--------------------------------------------------------------------------------
-- CAT_SPEC_IDS
--
procedure cat_spec_ids(
   p_cat_cursor     out sys_refcursor,
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null)
is
   l_parts str_tab_t;
   l_location_id_mask      varchar2(57);
   l_parameters_id_mask    varchar2(256);
   l_template_version_mask varchar2(32);
   l_spec_version_mask     varchar2(32);
   l_office_id_mask        varchar2(16) := nvl(p_office_id_mask, cwms_util.user_office_id);
begin
   l_parts := cwms_util.split_text(p_spec_id_mask, separator1);
   case l_parts.count
      when 1 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := '*';
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 2 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 3 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := '*';
      when 4 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := l_parts(4);
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_spec_id_mask,
            'rating specification id mask');
   end case;
   l_location_id_mask      := cwms_util.normalize_wildcards(l_location_id_mask);
   l_parameters_id_mask    := cwms_util.normalize_wildcards(l_parameters_id_mask);
   l_template_version_mask := cwms_util.normalize_wildcards(l_template_version_mask);
   l_spec_version_mask     := cwms_util.normalize_wildcards(l_spec_version_mask);

   open p_cat_cursor for
      select o.office_id,
             bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id
             ||separator1||rt.parameters_id
             ||separator1||rt.version
             ||separator1||rs.version as specification_id,
             bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id as location_id,
             rt.parameters_id
             ||separator1||rt.version as template_id,
             rs.version
        from at_rating_spec rs,
             at_rating_template rt,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id like upper(l_office_id_mask) escape '\'
         and rt.office_code = o.office_code
         and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
         and upper(rt.version) like upper(l_template_version_mask) escape '\'
         and rs.template_code = rt.template_code
         and upper(rs.version) like upper(l_spec_version_mask) escape '\'
         and pl.location_code = rs.location_code
         and bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id) like upper(l_location_id_mask) escape '\'
    order by o.office_id,
             bl.base_location_id,
             pl.sub_location_id,
             rt.parameters_id,
             rt.version,
             rs.version nulls first;
end cat_spec_ids;

--------------------------------------------------------------------------------
-- CAT_SPEC_IDS_F
--
function cat_spec_ids_f(
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_spec_ids(
      l_cursor,
      p_spec_id_mask,
      p_office_id_mask);

   return l_cursor;
end cat_spec_ids_f;

--------------------------------------------------------------------------------
-- RETRIEVE_SPECS_OBJ
--
procedure retrieve_specs_obj(
   p_specs          out rating_spec_tab_t,
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null)
is
   type codes_t is table of boolean index by varchar2(14);
   l_codes                 codes_t;
   l_parts                 str_tab_t;
   l_location_id_mask      varchar2(57);
   l_parameters_id_mask    varchar2(256);
   l_template_version_mask varchar2(32);
   l_spec_version_mask     varchar2(32);
   l_office_id_mask        varchar2(16) := nvl(p_office_id_mask, cwms_util.user_office_id);
begin
   l_parts := cwms_util.split_text(p_spec_id_mask, separator1);
   case l_parts.count
      when 1 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := '*';
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 2 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 3 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := '*';
      when 4 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := l_parts(4);
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_spec_id_mask,
            'rating specification id mask');
   end case;
   l_location_id_mask      := cwms_util.normalize_wildcards(l_location_id_mask);
   l_parameters_id_mask    := cwms_util.normalize_wildcards(l_parameters_id_mask);
   l_template_version_mask := cwms_util.normalize_wildcards(l_template_version_mask);
   l_spec_version_mask     := cwms_util.normalize_wildcards(l_spec_version_mask);

   p_specs := rating_spec_tab_t();
   for rec in
      (  select distinct
                location_id,
                rating_spec_code
           from ((select rs.location_code,
                        rs.rating_spec_code
                   from at_rating_spec rs,
                        at_rating_template rt,
                        cwms_office o
                   where o.office_id like upper(l_office_id_mask) escape '\'
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                  ) a
                  join
                  (select pl.location_code,
                          bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id as location_id
                     from at_base_location bl,
                          at_physical_location pl
                    where bl.base_location_code = pl.base_location_code
                      and upper(bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id) like upper(l_location_id_mask) escape '\'
                   union all
                   select location_code,
                          loc_alias_id as location_id
                     from at_loc_group_assignment
                    where upper(loc_alias_id) like upper(l_location_id_mask)
                  ) b on b.location_code = a.location_code
                )
      )
   loop
      if not l_codes.exists(to_char(rec.rating_spec_code)) then
         l_codes(to_char(rec.rating_spec_code)) := true;
         p_specs.extend;
         p_specs(p_specs.count) := rating_spec_t(rec.rating_spec_code);
         p_specs(p_specs.count).location_id := rec.location_id;
      end if;
   end loop;
end retrieve_specs_obj;

--------------------------------------------------------------------------------
-- RETRIEVE_SPECS_OBJ_F
--
function retrieve_specs_obj_f(
   p_spec_id_mask   in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return rating_spec_tab_t
is
   l_specs rating_spec_tab_t;
begin
   retrieve_specs_obj(
      l_specs,
      p_spec_id_mask,
      p_office_id_mask);

   return l_specs;
end retrieve_specs_obj_f;

--------------------------------------------------------------------------------
-- RETRIEVE_SPECS_XML
--
procedure retrieve_specs_xml(
   p_specs          out clob,
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null)
is
   l_text clob;
   l_specs rating_spec_tab_t;
begin
   retrieve_specs_obj(
      l_specs,
      p_spec_id_mask,
      p_office_id_mask);
   dbms_lob.createtemporary(l_text, true);
   dbms_lob.open(l_text, dbms_lob.lob_readwrite);
   cwms_util.append(
      l_text,
      '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      ||'xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
   for i in 1..l_specs.count loop
      cwms_util.append(l_text, l_specs(i).to_clob);
   end loop;
   cwms_util.append(l_text, '</ratings>');
   dbms_lob.close(l_text);
   dbms_lob.createtemporary(p_specs, true);
   dbms_lob.open(p_specs, dbms_lob.lob_readwrite);
   cwms_util.append(p_specs, '<?xml version="1.0" encoding="utf-8"?>'||chr(10));
   cwms_util.append(p_specs, xmltype(l_text).extract('/node()').getclobval);
   dbms_lob.close(p_specs);
end retrieve_specs_xml;
--------------------------------------------------------------------------------
-- RETRIEVE_SPECS_XML_F
--
function retrieve_specs_xml_f(
   p_spec_id_mask   in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return clob
is
   l_text clob;
begin
   retrieve_specs_xml(
      l_text,
      p_spec_id_mask,
      p_office_id_mask);

   return l_text;
end retrieve_specs_xml_f;

--------------------------------------------------------------------------------
-- DELETE_SPECS
--
procedure delete_specs(
   p_spec_id_mask   in varchar2 default '*',
   p_delete_action  in varchar2 default cwms_util.delete_key,
   p_office_id_mask in varchar2 default null)
is
   l_specs     rating_spec_tab_t;
   l_spec_code number(14);
begin
   l_specs := retrieve_specs_obj_f(
      p_spec_id_mask,
      p_office_id_mask);
   for i in 1..l_specs.count loop
      l_spec_code := rating_spec_t.get_rating_spec_code(
         l_specs(i).location_id,
         l_specs(i).template_id,
         l_specs(i).version,
         l_specs(i).office_id);
      delete_rating_spec(l_spec_code, p_delete_action);
   end loop;
end delete_specs;

--------------------------------------------------------------------------------
-- GET_TEMPLATE
--    returns the template portion of a rating specification identifer
--
-- p_spec_id
--    the rating spec text
--
function get_template(
   p_spec_id in varchar2)
   return varchar2
is
begin
   return cwms_util.split_text(p_spec_id, 2, separator1);
end get_template;

--------------------------------------------------------------------------------
-- STORE RATINGS
--
procedure store_ratings(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F')
is
   l_rating        rating_t;
   l_stream_rating stream_rating_t;
   l_node          xmltype;
begin
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(p_xml, '(//rating|//simple-rating|//virtual-rating|//transitional-rating|//usgs-stream-rating)['||i||']');
      exit when l_node is null;
      begin
         if l_node.existsnode('/usgs-stream-rating') = 1 then
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               'Storing '
               ||l_node.getrootelement
               ||' '
               ||cwms_util.get_xml_text(l_node, '/*/@office-id')
               ||'/'||regexp_replace(cwms_util.get_xml_text(l_node, '/*/rating-spec-id'), '\s', '', 1, 0)
               ||' ('
               ||regexp_replace(cwms_util.get_xml_text(l_node, '/*/effective-date'), '\s', '', 1, 0)
               ||')');
            l_stream_rating := stream_rating_t(l_node);
            l_stream_rating.store(p_fail_if_exists, p_replace_base);
         elsif l_node.existsnode('/rating|/simple-rating|/virtual-rating|/transitional-rating') = 1 then
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               'Storing '
               ||l_node.getrootelement
               ||' '
               ||cwms_util.get_xml_text(l_node, '/*/@office-id')
               ||'/'||regexp_replace(cwms_util.get_xml_text(l_node, '/*/rating-spec-id'), '\s', '', 1, 0)
               ||case l_node.existsnode('/rating|/simple-rating')
                 when 1 then ' ('
                             ||regexp_replace(cwms_util.get_xml_text(l_node, '/*/effective-date'), '\s', '', 1, 0)
                             ||')'
                 else null
                 end);
            l_rating := rating_t(l_node);
            l_rating.store(p_fail_if_exists);
         else
            cwms_err.raise(
               'ERROR',
               'XML cannot be parsed as valid rating_t or stream_rating_t object');
         end if;
      exception
         when others then
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            cwms_msg.log_db_message(cwms_msg.msg_level_normal, sqlerrm);
      end;
   end loop;
end store_ratings;

--------------------------------------------------------------------------------
-- STORE RATINGS
--
procedure store_ratings(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F')
is
begin
   store_ratings(xmltype(p_xml), p_fail_if_exists, p_replace_base);
end store_ratings;

--------------------------------------------------------------------------------
-- STORE RATINGS
--
procedure store_ratings(
   p_xml            in clob,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F')
is
begin
   store_ratings(xmltype(p_xml), p_fail_if_exists, p_replace_base);
end store_ratings;

--------------------------------------------------------------------------------
-- STORE RATINGS
--
procedure store_ratings(
   p_ratings        in rating_tab_t,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F')
is
   l_ratings       rating_tab_t := p_ratings;
   l_rating        rating_t;
   l_stream_rating stream_rating_t;
begin
   if l_ratings is not null then
      for i in 1..l_ratings.count loop
         if l_ratings(i) is of (stream_rating_t) then
            l_stream_rating := treat(l_ratings(i) as stream_rating_t);
            l_stream_rating.store(p_fail_if_exists, p_replace_base);
         else
            l_rating := treat(l_ratings(i) as rating_t);
            l_rating.store(p_fail_if_exists);
         end if;
      end loop;
   end if;
end store_ratings;

--------------------------------------------------------------------------------
-- GET_RATING
--
function get_rating(
   p_rating_code    in number,
   p_include_points in varchar2 default 'T')
   return rating_t
is
   l_dependent_count pls_integer;
   l_rating          rating_t;
   l_parts           str_tab_t;
   l_elev_pos        number_tab_t;
   l_location_id     varchar2(256);
   l_vertical_datum  varchar2(32);
begin
   select count(*)
     into l_dependent_count
     from at_rating
    where ref_rating_code = p_rating_code;

   if l_dependent_count = 0 then
      ------------------------------------
      -- not a USGS-style stream rating --
      ------------------------------------
      l_rating := rating_t(p_rating_code, p_include_points);
   else
      ------------------------------
      -- USGS-style stream rating --
      ------------------------------
      l_rating := stream_rating_t(p_rating_code, p_include_points);
   end if;
   ----------------------------------------------------------
   -- add vertical datum info if appropriate and available --
   ----------------------------------------------------------
   if l_rating.rating_info is not null or l_rating.formula is not null then
      --------------------------------------------------
      -- concrete rating, not virtual or transitional --
      --------------------------------------------------
      l_parts := cwms_util.split_text(l_rating.rating_spec_id, '.');
      if instr(upper(l_parts(2)), 'ELEV') > 0 then
         l_location_id := l_parts(1);
         l_parts := cwms_util.split_text(replace(l_parts(2), ';', ','), ',');
         l_elev_pos := number_tab_t();
         for i in 1..l_parts.count loop
            if instr(l_parts(i), 'Elev') = 1 then
               l_elev_pos.extend;
               l_elev_pos(l_elev_pos.count) := case when i = l_parts.count then -1 else i end;
            end if;
         end loop;
         if l_elev_pos.count > 0 then
            select pl.vertical_datum
              into l_vertical_datum
              from at_physical_location pl,
                   at_rating_spec rs,
                   at_rating r
             where r.rating_code = p_rating_code
               and rs.rating_spec_code = r.rating_spec_code
               and pl.location_code = rs.location_code;
            if l_vertical_datum is not null then
               begin
                  if l_rating is of (stream_rating_t) then
                     l_rating := vdatum_stream_rating_t(treat(l_rating as stream_rating_t), l_vertical_datum);
                  else
                     l_rating := vdatum_rating_t(l_rating, l_vertical_datum, l_elev_pos);
                  end if;
               exception
                  when others then null;
               end;
            end if;
         end if;
      end if;
   end if;
   return l_rating;
end get_rating;

--------------------------------------------------------------------------------
-- CAT_RATINGS_EX
--
function cat_ratings_ex(
   p_effective_tw         in varchar2,
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
   type rat_rec_t is record(
      rating_spec_code integer,
      rating_code      integer,
      effective_date   date,
      timezone         varchar2(28),
      in_range         varchar2(32),
      out_range_low    varchar2(32),
      out_range_high   varchar2(32));
   type date_tab_t is table of date;
   type int_tab_t is table of integer;
   type rat_rec_t2 is record(
      in_range         varchar2(32),
      out_range_high   varchar2(32),
      out_range_low    varchar2(32),
      timezone         varchar2(28),
      rating_codes     int_tab_t,
      effective_dates  date_tab_t);
   type rat_tab_t is table of rat_rec_t;
   type rat_tab_t2 is table of rat_rec_t2 index by varchar2(16);

   c_default_start_date constant date := date '1700-01-01';
   c_default_end_date   constant date := date '2300-01-01';

   l_crsr                  sys_refcursor;
   l_effective_tw          boolean;
   l_parts                 str_tab_t;
   l_location_id_mask      varchar2(57);
   l_parameters_id_mask    varchar2(256);
   l_template_version_mask varchar2(32);
   l_spec_version_mask     varchar2(32);
   l_office_id_mask        varchar2(16);
   l_ratings               rat_tab_t;
   l_ratings2              rat_tab_t2;
   l_code                  integer;
   l_code_str              varchar2(16);
   l_codes                 number_tab_t;
   l_start_date            date;
   l_end_date              date;
   l_utc_code              integer;
begin
   l_office_id_mask := nvl(cwms_util.normalize_wildcards(upper(p_office_id_mask)), cwms_util.user_office_id);
   l_effective_tw := cwms_util.return_true_or_false(p_effective_tw);
   l_parts := cwms_util.split_text(p_spec_id_mask, separator1);
   case l_parts.count
      when 1 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := '*';
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 2 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 3 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := '*';
      when 4 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := l_parts(4);
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_spec_id_mask,
            'rating specification id mask');
   end case;
   l_location_id_mask      := cwms_util.normalize_wildcards(l_location_id_mask);
   l_parameters_id_mask    := cwms_util.normalize_wildcards(l_parameters_id_mask);
   l_template_version_mask := cwms_util.normalize_wildcards(l_template_version_mask);
   l_spec_version_mask     := cwms_util.normalize_wildcards(l_spec_version_mask);

   select time_zone_code
     into l_utc_code
     from cwms_time_zone
    where time_zone_name = 'UTC';

   if l_effective_tw then
      -------------------------------------------------
      -- time window is for ratings effective within --
      -------------------------------------------------
      -------------------------------------------------------------
      -- get ALL ratings matching office and specification masks --
      -------------------------------------------------------------
   open l_crsr for
         select q2.rating_spec_code,
                q2.rating_code,
                q2.effective_date,
                q2.time_zone_name,
                q2.in_range_method,
                q2.out_range_low_method,
                q2.out_range_high_method
           from (select distinct
                        location_code,
                        location_id
                   from av_loc2
                ) q1,
                (select rs.location_code,
                        rs.rating_spec_code,
                        r.rating_code,
                        cwms_util.change_timezone(r.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                        tz2.time_zone_name,
                        rm1.rating_method_id as in_range_method,
                        rm2.rating_method_id as out_range_low_method,
                        rm3.rating_method_id as out_range_high_method
                   from at_rating r,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2,
                        cwms_rating_method rm1,
                        cwms_rating_method rm2,
                        cwms_rating_method rm3
                  where o.office_id like upper(l_office_id_mask) escape '\'
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                    and r.rating_spec_code = rs.rating_spec_code
                    and r.ref_rating_code is null
                    and pl.location_code = rs.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                    and tz2.time_zone_name = case
                                             when p_time_zone is null then tz1.time_zone_name
                                             else p_time_zone
                                             end
                    and rm1.rating_method_code = rs.in_range_rating_method
                    and rm2.rating_method_code = rs.out_range_low_rating_method
                    and rm3.rating_method_code = rs.out_range_high_rating_method
                 union all
                 select rs.location_code,
                        rs.rating_spec_code,
                        tr.transitional_rating_code as rating_code,
                        cwms_util.change_timezone(tr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                        tz2.time_zone_name,
                        rm1.rating_method_id as in_range_method,
                        rm2.rating_method_id as out_range_low_method,
                        rm3.rating_method_id as out_range_high_method
                   from at_transitional_rating tr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2,
                        cwms_rating_method rm1,
                        cwms_rating_method rm2,
                        cwms_rating_method rm3
                  where o.office_id like upper(l_office_id_mask) escape '\'
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                    and tr.rating_spec_code = rs.rating_spec_code
                    and pl.location_code = rs.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                    and tz2.time_zone_name = case
                                             when p_time_zone is null then tz1.time_zone_name
                                             else p_time_zone
                                             end
                    and rm1.rating_method_code = rs.in_range_rating_method
                    and rm2.rating_method_code = rs.out_range_low_rating_method
                    and rm3.rating_method_code = rs.out_range_high_rating_method
                 union all
                 select rs.location_code,
                        rs.rating_spec_code,
                        vr.virtual_rating_code as rating_code,
                        cwms_util.change_timezone(vr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                        tz2.time_zone_name,
                        rm1.rating_method_id as in_range_method,
                        rm2.rating_method_id as out_range_low_method,
                        rm3.rating_method_id as out_range_high_method
                   from at_virtual_rating vr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2,
                        cwms_rating_method rm1,
                        cwms_rating_method rm2,
                        cwms_rating_method rm3
                  where o.office_id like upper(l_office_id_mask) escape '\'
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                    and vr.rating_spec_code = rs.rating_spec_code
                    and pl.location_code = rs.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                    and tz2.time_zone_name = case
                                             when p_time_zone is null then tz1.time_zone_name
                                             else p_time_zone
                                             end
                    and rm1.rating_method_code = rs.in_range_rating_method
                    and rm2.rating_method_code = rs.out_range_low_rating_method
                    and rm3.rating_method_code = rs.out_range_high_rating_method
                ) q2
          where q1.location_code = q2.location_code
            and upper(q1.location_id) like upper(l_location_id_mask) escape '\'
       order by q2.rating_spec_code,
                q2.effective_date;

      fetch l_crsr bulk collect into l_ratings;
      close l_crsr;
      -----------------------------------------------------------------------------
      -- determine wich of the ratings is effective in the specified time window --
      -----------------------------------------------------------------------------
      for i in 1..l_ratings.count loop
         l_code_str := l_ratings(i).rating_spec_code;
         if not l_ratings2.exists(l_code_str) then
            l_ratings2(l_code_str).rating_codes := int_tab_t();
            l_ratings2(l_code_str).effective_dates := date_tab_t();
            l_ratings2(l_code_str).timezone := l_ratings(i).timezone;
            l_ratings2(l_code_str).in_range := l_ratings(i).in_range;
            l_ratings2(l_code_str).out_range_low := l_ratings(i).out_range_low;
            l_ratings2(l_code_str).out_range_high := l_ratings(i).out_range_high;
         end if;
         l_ratings2(l_code_str).rating_codes.extend;
         l_ratings2(l_code_str).rating_codes(l_ratings2(l_code_str).rating_codes.count) := l_ratings(i).rating_code;
         l_ratings2(l_code_str).effective_dates.extend;
         l_ratings2(l_code_str).effective_dates(l_ratings2(l_code_str).effective_dates.count) := l_ratings(i).effective_date;
      end loop;

      l_codes := number_tab_t();
      l_code_str := l_ratings2.first;
      loop
         exit when l_code_str is null;
         l_start_date := case p_start_date is null
                         when true then c_default_start_date
                         else case p_time_zone is null
                              when true then p_start_date
                              else cwms_util.change_timezone(p_start_date, 'UTC', l_ratings2(l_code_str).timezone)
                              end
                         end;
         l_end_date  := case p_end_date is null
                         when true then c_default_end_date
                         else case p_time_zone is null
                              when true then p_end_date
                              else cwms_util.change_timezone(p_end_date, 'UTC', l_ratings2(l_code_str).timezone)
                              end
                         end;

         for i in 1..l_ratings2(l_code_str).effective_dates.count loop
            case
            when l_ratings2(l_code_str).effective_dates(i) between l_start_date and l_end_date then
               -----------------------------------
               -- effective date in time window --
               -----------------------------------
               l_codes.extend;
               l_codes(l_codes.count) := l_ratings2(l_code_str).rating_codes(i);
            when l_ratings2(l_code_str).effective_dates(i) < l_start_date then
               ------------------------------------------
               -- effective date is before time window --
               ------------------------------------------
               if i = l_ratings2(l_code_str).effective_dates.count then
                  if l_ratings2(l_code_str).out_range_high in ('PREVIOUS', 'NEAREST') then
                     l_codes.extend;
                     l_codes(l_codes.count) := l_ratings2(l_code_str).rating_codes(i);
                  end if;
               else
                  if l_ratings2(l_code_str).effective_dates(i+1) > l_start_date then
                     if l_ratings2(l_code_str).in_range not in ('NULL', 'ERROR') then
                        l_codes.extend;
                        l_codes(l_codes.count) := l_ratings2(l_code_str).rating_codes(i);
                     end if;
                  end if;
               end if;
            when l_ratings2(l_code_str).effective_dates(i) > l_end_date then
               -----------------------------------------
               -- effective date is after time window --
               -----------------------------------------
               if i = 1 and l_ratings2(l_code_str).out_range_low in ('NEXT', 'NEAREST') then
                  l_codes.extend;
                  l_codes(l_codes.count) := l_ratings2(l_code_str).rating_codes(i);
               end if;
            end case;
         end loop;
         l_code_str := l_ratings2.next(l_code_str);
      end loop;
      --------------------------------------------------------------------
      -- finally, catalog ratings from those that met preivous criteria --
      --------------------------------------------------------------------
      open l_crsr for
         select q2.office_id,
                q1.location_id||'.'||q2.spec as specification_id,
                q2.effective_date,
                q2.create_date
           from (select distinct
                        location_code,
                        location_id
                   from av_loc2
                ) q1,
                (select o.office_id,
                        rs.location_code,
                        rt.parameters_id
                        ||separator1||rt.version
                        ||separator1||rs.version as spec,
                        cwms_util.change_timezone(r.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                        cwms_util.change_timezone(r.create_date, 'UTC', tz2.time_zone_name) as create_date
                   from at_rating r,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2
                  where r.rating_code in (select column_value from table(l_codes))
                    and rs.rating_spec_code = r.rating_spec_code
                    and rt.template_code = rs.template_code
                    and pl.location_code = rs.location_code
                    and bl.base_location_code = pl.base_location_code
                    and o.office_code = bl.db_office_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                    and tz2.time_zone_name = case
                                             when p_time_zone is null then tz1.time_zone_name
                                             else p_time_zone
                                             end
                 union all
                 select o.office_id,
                        rs.location_code,
                        rt.parameters_id
                        ||separator1||rt.version
                        ||separator1||rs.version as spec,
                        cwms_util.change_timezone(tr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                        cwms_util.change_timezone(tr.create_date, 'UTC', tz2.time_zone_name) as create_date
                   from at_transitional_rating tr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2
                  where tr.transitional_rating_code in (select column_value from table(l_codes))
                    and rs.rating_spec_code = tr.rating_spec_code
                    and rt.template_code = rs.template_code
                    and pl.location_code = rs.location_code
                    and bl.base_location_code = pl.base_location_code
                    and o.office_code = bl.db_office_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                    and tz2.time_zone_name = case
                                             when p_time_zone is null then tz1.time_zone_name
                                             else p_time_zone
                                             end
                 union all
                 select o.office_id,
                        rs.location_code,
                        rt.parameters_id
                        ||separator1||rt.version
                        ||separator1||rs.version as spec,
                        cwms_util.change_timezone(vr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                        cwms_util.change_timezone(vr.create_date, 'UTC', tz2.time_zone_name) as create_date
                   from at_virtual_rating vr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2
                  where vr.virtual_rating_code in (select column_value from table(l_codes))
                    and rs.rating_spec_code = vr.rating_spec_code
                    and rt.template_code = rs.template_code
                    and pl.location_code = rs.location_code
                    and bl.base_location_code = pl.base_location_code
                    and o.office_code = bl.db_office_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                    and tz2.time_zone_name = case
                                             when p_time_zone is null then tz1.time_zone_name
                                             else p_time_zone
                                             end
                ) q2
          where q1.location_code = q2.location_code
            and upper(q1.location_id) like upper(l_location_id_mask) escape '\'
       order by q2.office_id,
                q1.location_id,
                q2.spec,
                q2.effective_date;

   else
      ----------------------------------------
      -- time window is for effective dates --
      ----------------------------------------
      open l_crsr for
      select q2.office_id,
             q1.location_id||'.'||q2.spec as specification_id,
             q2.effective_date,
             q2.create_date
        from (select distinct
                     location_code,
                     location_id
                from av_loc2
             ) q1,
             (select o.office_id,
                     rs.location_code,
                     rt.parameters_id
                     ||separator1||rt.version
                     ||separator1||rs.version as spec,
                     cwms_util.change_timezone(r.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                     cwms_util.change_timezone(r.create_date, 'UTC', tz2.time_zone_name) as create_date
                from at_rating r,
                     at_rating_spec rs,
                     at_rating_template rt,
                     at_physical_location pl,
                     cwms_office o,
                     cwms_time_zone tz1,
                     cwms_time_zone tz2
                  where o.office_id like l_office_id_mask escape '\'
                 and rt.office_code = o.office_code
                 and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                 and upper(rt.version) like upper(l_template_version_mask) escape '\'
                 and rs.template_code = rt.template_code
                 and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                 and r.rating_spec_code = rs.rating_spec_code
                 and r.ref_rating_code is null
                 and pl.location_code = rs.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                 and tz2.time_zone_name = case
                                          when p_time_zone is null then tz1.time_zone_name
                                          else p_time_zone
                                          end
                    and r.effective_date  >= case
                                          when p_start_date is null then c_default_start_date
                                          else cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC')
                                          end
                    and r.effective_date  <= case
                                          when p_end_date is null then c_default_end_date
                                          else cwms_util.change_timezone(p_end_date, tz2.time_zone_name, 'UTC')
                                          end
              union all
              select o.office_id,
                     rs.location_code,
                     rt.parameters_id
                     ||separator1||rt.version
                     ||separator1||rs.version as spec,
                     cwms_util.change_timezone(tr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                     cwms_util.change_timezone(tr.create_date, 'UTC', tz2.time_zone_name) as create_date
                from at_transitional_rating tr,
                     at_rating_spec rs,
                     at_rating_template rt,
                     at_physical_location pl,
                     cwms_office o,
                     cwms_time_zone tz1,
                     cwms_time_zone tz2
                  where o.office_id like l_office_id_mask escape '\'
                 and rt.office_code = o.office_code
                 and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                 and upper(rt.version) like upper(l_template_version_mask) escape '\'
                 and rs.template_code = rt.template_code
                 and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                 and tr.rating_spec_code = rs.rating_spec_code
                 and pl.location_code = rs.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                 and tz2.time_zone_name = case
                                          when p_time_zone is null then tz1.time_zone_name
                                          else p_time_zone
                                          end
                    and tr.effective_date >= case
                                          when p_start_date is null then c_default_start_date
                                          else cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC')
                                          end
                    and tr.effective_date <= case
                                          when p_end_date is null then c_default_end_date
                                          else cwms_util.change_timezone(p_end_date, tz2.time_zone_name, 'UTC')
                                          end
              union all
              select o.office_id,
                     rs.location_code,
                     rt.parameters_id
                     ||separator1||rt.version
                     ||separator1||rs.version as spec,
                     cwms_util.change_timezone(vr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                     cwms_util.change_timezone(vr.create_date, 'UTC', tz2.time_zone_name) as create_date
                from at_virtual_rating vr,
                     at_rating_spec rs,
                     at_rating_template rt,
                     at_physical_location pl,
                     cwms_office o,
                     cwms_time_zone tz1,
                     cwms_time_zone tz2
                  where o.office_id like l_office_id_mask escape '\'
                 and rt.office_code = o.office_code
                 and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                 and upper(rt.version) like upper(l_template_version_mask) escape '\'
                 and rs.template_code = rt.template_code
                 and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                 and vr.rating_spec_code = rs.rating_spec_code
                 and pl.location_code = rs.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                 and tz2.time_zone_name = case
                                          when p_time_zone is null then tz1.time_zone_name
                                          else p_time_zone
                                          end
                    and vr.effective_date >= case
                                          when p_start_date is null then c_default_start_date
                                          else cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC')
                                          end
                    and vr.effective_date <= case
                                          when p_end_date is null then c_default_end_date
                                          else cwms_util.change_timezone(p_end_date, tz2.time_zone_name, 'UTC')
                                          end
             ) q2
       where q1.location_code = q2.location_code
         and upper(q1.location_id) like upper(l_location_id_mask) escape '\'
    order by q2.office_id,
             q1.location_id,
             q2.spec,
                q2.effective_date;
   end if;

   return l_crsr;
end cat_ratings_ex;

--------------------------------------------------------------------------------
-- CAT_RATINGS2_EX
--
function cat_ratings2_ex(
   p_effective_tw         in varchar2,
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
   type rat_rec_t is record(
      rating_spec_code integer,
      rating_code      integer,
      effective_date   date,
      timezone         varchar2(28),
      in_range         varchar2(32),
      out_range_low    varchar2(32),
      out_range_high   varchar2(32));
   type date_tab_t is table of date;
   type int_tab_t is table of integer;
   type rat_rec_t2 is record(
      in_range         varchar2(32),
      out_range_high   varchar2(32),
      out_range_low    varchar2(32),
      timezone         varchar2(28),
      rating_codes     int_tab_t,
      effective_dates  date_tab_t);
   type rat_tab_t is table of rat_rec_t;
   type rat_tab_t2 is table of rat_rec_t2 index by varchar2(16);

   c_default_start_date constant date := date '1700-01-01';
   c_default_end_date   constant date := date '2300-01-01';

   l_crsr                  sys_refcursor;
   l_effective_tw          varchar2(1);
   l_parts                 str_tab_t;
   l_location_id_mask      varchar2(57);
   l_parameters_id_mask    varchar2(256);
   l_template_version_mask varchar2(32);
   l_spec_version_mask     varchar2(32);
   l_office_id_mask        varchar2(16);
   l_utc_code              integer;
begin
   l_office_id_mask := nvl(cwms_util.normalize_wildcards(upper(p_office_id_mask)), cwms_util.user_office_id);
   l_effective_tw := case
                     when p_start_date is not null and cwms_util.return_true_or_false(p_effective_tw) then 'T'
                     else 'F'
                     end;
   l_parts := cwms_util.split_text(p_spec_id_mask, separator1);
   case l_parts.count
      when 1 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := '*';
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 2 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := '*';
         l_spec_version_mask     := '*';
      when 3 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := '*';
      when 4 then
         l_location_id_mask      := l_parts(1);
         l_parameters_id_mask    := l_parts(2);
         l_template_version_mask := l_parts(3);
         l_spec_version_mask     := l_parts(4);
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_spec_id_mask,
            'rating specification id mask');
   end case;
   l_location_id_mask      := cwms_util.normalize_wildcards(l_location_id_mask);
   l_parameters_id_mask    := cwms_util.normalize_wildcards(l_parameters_id_mask);
   l_template_version_mask := cwms_util.normalize_wildcards(l_template_version_mask);
   l_spec_version_mask     := cwms_util.normalize_wildcards(l_spec_version_mask);

   select time_zone_code
     into l_utc_code
     from cwms_time_zone
    where time_zone_name = 'UTC';

   open l_crsr for
      select q2.office_id,
             q1.location_id||'.'||q2.spec as specification_id,
             q2.effective_date,
             q2.create_date,
             q2.parent_rating_code,
             case
             when q2.parent_spec is null then null
             else q1.location_id||'.'||q2.parent_spec
             end as parent_specification_id,
             case
             when q2.parent_spec is null then null
             else q2.parent_effective_date
             end as parent_effective_date,
             case
             when q2.parent_spec is null then null
             else q2.parent_create_date
             end as parent_create_date
        from (select distinct
                     location_code,
                     location_id
                from (select pl.location_code,
                             bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id as location_id
                        from cwms_office o,
                             at_base_location bl,
                             at_physical_location pl
                       where o.office_id like l_office_id_mask escape '\'
                         and bl.db_office_code = o.office_code
                         and pl.base_location_code = bl.base_location_code
                         and upper(bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id) like upper(l_location_id_mask) escape '\'
                      union all
                      select lga.location_code,
                             lga.loc_alias_id as location_id
                        from cwms_office o,
                             at_loc_group_assignment lga
                       where o.office_id like l_office_id_mask escape '\'
                         and lga.office_code = o.office_code
                         and upper(lga.loc_alias_id) like upper(l_location_id_mask) escape '\'
                     )
             ) q1,
             (select q2a.office_id,
                     q2a.location_code,
                     q2a.spec,
                     q2a.effective_date,
                     q2a.create_date,
                     q2a.parent_rating_code,
                     q2b.spec as parent_spec,
                     q2b.effective_date as parent_effective_date,
                     q2b.create_date as parent_create_date
                from (select o.office_id,
                             rs.location_code,
                             rt.parameters_id
                             ||separator1||rt.version
                             ||separator1||rs.version as spec,
                             cwms_util.change_timezone(r.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                             cwms_util.change_timezone(r.create_date, 'UTC', tz2.time_zone_name) as create_date,
                             r.ref_rating_code as parent_rating_code
                        from at_rating r,
                             at_rating_spec rs,
                             at_rating_template rt,
                             at_physical_location pl,
                             cwms_office o,
                             cwms_time_zone tz1,
                             cwms_time_zone tz2
                       where o.office_id like l_office_id_mask escape '\'
                         and rt.office_code = o.office_code
                         and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                         and upper(rt.version) like upper(l_template_version_mask) escape '\'
                         and rs.template_code = rt.template_code
                         and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                         and r.rating_spec_code = rs.rating_spec_code
                         -- and r.ref_rating_code is null
                         and pl.location_code = rs.location_code
                         and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                         and tz2.time_zone_name = case
                                                  when p_time_zone is null then tz1.time_zone_name
                                                  else p_time_zone
                                                  end
                         and r.effective_date  >= case
                                                  when l_effective_tw = 'F' then
                                                     case
                                                     when p_start_date is null then c_default_start_date
                                                     else cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC')
                                                     end
                                                  else (select max(effective_date)
                                                         from at_rating
                                                        where rating_spec_code = rs.rating_spec_code
                                                          and effective_date <= cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC'))
                                                  end
                         and r.effective_date  <= case
                                                  when p_end_date is null then c_default_end_date
                                                  else cwms_util.change_timezone(p_end_date, tz2.time_zone_name, 'UTC')
                                                  end
                     ) q2a
                     left outer join
                     (select r.rating_code,
                             rt.parameters_id
                             ||separator1||rt.version
                             ||separator1||rs.version as spec,
                             r.effective_date,
                             r.create_date
                        from at_rating r,
                             at_rating_spec rs,
                             at_rating_template rt
                       where rs.template_code = rt.template_code
                         and r.rating_spec_code = rs.rating_spec_code
                     ) q2b on q2b.rating_code = q2a.parent_rating_code
              union all
              select o.office_id,
                     rs.location_code,
                     rt.parameters_id
                     ||separator1||rt.version
                     ||separator1||rs.version as spec,
                     cwms_util.change_timezone(tr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                     cwms_util.change_timezone(tr.create_date, 'UTC', tz2.time_zone_name) as create_date,
                     null as parent_rating_code,
                     null as parent_spec,
                     null as parent_effective_date,
                     null as parent_create_date
                from at_transitional_rating tr,
                     at_rating_spec rs,
                     at_rating_template rt,
                     at_physical_location pl,
                     cwms_office o,
                     cwms_time_zone tz1,
                     cwms_time_zone tz2
               where o.office_id like l_office_id_mask escape '\'
                 and rt.office_code = o.office_code
                 and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                 and upper(rt.version) like upper(l_template_version_mask) escape '\'
                 and rs.template_code = rt.template_code
                 and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                 and tr.rating_spec_code = rs.rating_spec_code
                 and pl.location_code = rs.location_code
                 and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                 and tz2.time_zone_name = case
                                          when p_time_zone is null then tz1.time_zone_name
                                          else p_time_zone
                                          end
                 and tr.effective_date  >= case
                                           when l_effective_tw = 'F' then
                                              case
                                              when p_start_date is null then c_default_start_date
                                              else cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC')
                                              end
                                           else (select max(effective_date)
                                                  from at_rating
                                                 where rating_spec_code = rs.rating_spec_code
                                                   and effective_date <= cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC'))
                                           end
                 and tr.effective_date <= case
                                          when p_end_date is null then c_default_end_date
                                          else cwms_util.change_timezone(p_end_date, tz2.time_zone_name, 'UTC')
                                          end
              union all
              select o.office_id,
                     rs.location_code,
                     rt.parameters_id
                     ||separator1||rt.version
                     ||separator1||rs.version as spec,
                     cwms_util.change_timezone(vr.effective_date, 'UTC', tz2.time_zone_name) as effective_date,
                     cwms_util.change_timezone(vr.create_date, 'UTC', tz2.time_zone_name) as create_date,
                     null as parent_rating_code,
                     null as parent_spec,
                     null as parent_effective_date,
                     null as parent_create_date
                from at_virtual_rating vr,
                     at_rating_spec rs,
                     at_rating_template rt,
                     at_physical_location pl,
                     cwms_office o,
                     cwms_time_zone tz1,
                     cwms_time_zone tz2
               where o.office_id like l_office_id_mask escape '\'
                 and rt.office_code = o.office_code
                 and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                 and upper(rt.version) like upper(l_template_version_mask) escape '\'
                 and rs.template_code = rt.template_code
                 and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                 and vr.rating_spec_code = rs.rating_spec_code
                 and pl.location_code = rs.location_code
                 and tz1.time_zone_code = nvl(pl.time_zone_code, l_utc_code)
                 and tz2.time_zone_name = case
                                          when p_time_zone is null then tz1.time_zone_name
                                          else p_time_zone
                                          end
                 and vr.effective_date  >= case
                                           when l_effective_tw = 'F' then
                                              case
                                              when p_start_date is null then c_default_start_date
                                              else cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC')
                                              end
                                           else (select max(effective_date)
                                                  from at_rating
                                                 where rating_spec_code = rs.rating_spec_code
                                                   and effective_date <= cwms_util.change_timezone(p_start_date, tz2.time_zone_name, 'UTC'))
                                           end
                 and vr.effective_date <= case
                                          when p_end_date is null then c_default_end_date
                                          else cwms_util.change_timezone(p_end_date, tz2.time_zone_name, 'UTC')
                                          end
             ) q2
       where q2.location_code = q1.location_code
    order by q2.office_id,
             q1.location_id,
             q2.spec,
             q2.effective_date;

   return l_crsr;
end cat_ratings2_ex;

--------------------------------------------------------------------------------
-- cat_ratings
--
procedure cat_ratings(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_cat_cursor := cat_ratings_ex(
      p_effective_tw   => 'F',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_effective_date_start,
      p_end_date       => p_effective_date_end,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_ratings;

--------------------------------------------------------------------------------
-- cat_ratings_f
--
function cat_ratings_f(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
begin
   return cat_ratings_ex(
      p_effective_tw   => 'F',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_effective_date_start,
      p_end_date       => p_effective_date_end,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_ratings_f;

--------------------------------------------------------------------------------
-- cat_eff_ratings
--
procedure cat_eff_ratings(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_cat_cursor := cat_ratings_ex(
      p_effective_tw   => 'T',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_start_date,
      p_end_date       => p_end_date,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_eff_ratings;

--------------------------------------------------------------------------------
-- cat_eff_ratings_F
--
function cat_eff_ratings_f(
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
begin
   return cat_ratings_ex(
      p_effective_tw   => 'T',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_start_date,
      p_end_date       => p_end_date,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_eff_ratings_f;

--------------------------------------------------------------------------------
-- cat_ratings2
--
procedure cat_ratings2(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_cat_cursor := cat_ratings2_ex(
      p_effective_tw   => 'F',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_effective_date_start,
      p_end_date       => p_effective_date_end,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_ratings2;

--------------------------------------------------------------------------------
-- cat_ratings2_f
--
function cat_ratings2_f(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
begin
   return cat_ratings2_ex(
      p_effective_tw   => 'F',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_effective_date_start,
      p_end_date       => p_effective_date_end,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_ratings2_f;

--------------------------------------------------------------------------------
-- cat_eff_ratings2
--
procedure cat_eff_ratings2(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_cat_cursor := cat_ratings2_ex(
      p_effective_tw   => 'T',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_start_date,
      p_end_date       => p_end_date,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_eff_ratings2;

--------------------------------------------------------------------------------
-- cat_eff_ratings2_F
--
function cat_eff_ratings2_f(
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
begin
   return cat_ratings2_ex(
      p_effective_tw   => 'T',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_start_date,
      p_end_date       => p_end_date,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end cat_eff_ratings2_f;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_OBJ_EX
--
procedure retrieve_ratings_obj_ex(
   p_ratings        out rating_tab_t,
   p_effective_tw   in  varchar2,
   p_spec_id_mask   in  varchar2 default '*',
   p_start_date     in  date     default null,
   p_end_date       in  date     default null,
   p_time_zone      in  varchar2 default null,
   p_include_points in  varchar2 default 'T',
   p_office_id_mask in  varchar2 default null)
is
   type used_codes_t is table of boolean index by varchar2(20);
   type cat_rec_t is record(office varchar2(16), rating_spec varchar2(512), effective_date date, create_date date);
   type cat_tab_t is table of cat_rec_t;
   l_cat_cursor     sys_refcursor;
   l_cat_records    cat_tab_t;
   l_code           integer;
   l_used_codes     used_codes_t;
begin
   l_cat_cursor := cat_ratings_ex(
      p_effective_tw   => p_effective_tw,
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_start_date,
      p_end_date       => p_end_date,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);

   fetch l_cat_cursor bulk collect into l_cat_records;
   close l_cat_cursor;

   for i in 1..l_cat_records.count loop
      l_code := rating_t.get_rating_code(
         p_rating_spec_id => l_cat_records(i).rating_spec,
         p_effective_date => l_cat_records(i).effective_date,
         p_match_date     => 'T',
         p_time_zone      => p_time_zone,
         p_office_id      => l_cat_records(i).office);
      if not l_used_codes.exists(to_char(l_code)) then
         l_used_codes(to_char(l_code)) := true;
      end if;
   end loop;

   p_ratings := rating_tab_t();
   l_code := l_used_codes.first;
   while l_code is not null loop
      p_ratings.extend;
      p_ratings(p_ratings.count) := get_rating(l_code, p_include_points);
      l_code := l_used_codes.next(l_code);
   end loop;

end retrieve_ratings_obj_ex;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_OBJ
--
procedure retrieve_ratings_obj(
   p_ratings              out rating_tab_t,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   retrieve_ratings_obj_ex(
      p_ratings        => p_ratings,
      p_effective_tw   => 'F',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_effective_date_start,
      p_end_date       => p_effective_date_end,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
end retrieve_ratings_obj;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_OBJ
--
procedure retrieve_eff_ratings_obj(
   p_ratings              out rating_tab_t,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   retrieve_ratings_obj_ex(
      p_ratings        => p_ratings,
      p_effective_tw   => 'T',
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_start_date,
      p_end_date       => p_end_date,
      p_time_zone      => p_time_zone,
      p_office_id_mask => p_office_id_mask);
END retrieve_eff_ratings_obj;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_OBJ_F
--
function retrieve_ratings_obj_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return rating_tab_t
is
   l_ratings rating_tab_t;
begin
   retrieve_ratings_obj(
      l_ratings,
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_ratings_obj_f;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_OBJ_F
--
function retrieve_eff_ratings_obj_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return rating_tab_t
is
   l_ratings rating_tab_t;
BEGIN
   retrieve_eff_ratings_obj(
      l_ratings,
      p_spec_id_mask,
      p_start_date,
      p_end_date,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_eff_ratings_obj_f;

--------------------------------------------------------------------------------
-- RETREIVE_RATINGS_XML_DATA
--
procedure retreive_ratings_xml_data(
   p_templates            in out nocopy clob,
   p_specs                in out nocopy clob,
   p_ratings              in out nocopy clob,
   p_effective_tw         in  varchar2,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_recurse              in  boolean  default true,
   p_include_points       in  varchar2 default 'T',
   p_office_id_mask       in  varchar2 default null)
is
   l_ratings       rating_tab_t;
   l_spec_id_mask  varchar2(1024);
   l_template_clob clob;
   l_spec_clob     clob;
   l_rating_clob   clob;
   l_parts         str_tab_t;
   l_spec          rating_spec_t;
   l_template      rating_template_t;
begin
   retrieve_ratings_obj_ex(
      p_ratings        => l_ratings,
      p_effective_tw   => p_effective_tw,
      p_spec_id_mask   => p_spec_id_mask,
      p_start_date     => p_start_date,
      p_end_date       => p_end_date,
      p_time_zone      => p_time_zone,
      p_include_points => p_include_points,
      p_office_id_mask => p_office_id_mask);
   l_spec_id_mask := cwms_util.normalize_wildcards(p_spec_id_mask);

   for i in 1..l_ratings.count loop
      if p_templates is not null or p_specs is not null then
         l_parts    := cwms_util.split_text(l_ratings(i).rating_spec_id, '.');
         if p_templates is not null then
            l_template := retrieve_templates_obj_f(l_parts(2)||'.'||l_parts(3), l_ratings(i).office_id)(1);
            cwms_util.append(p_templates, l_template.to_clob);
         end if;
         if p_specs is not null then
            l_spec     := retrieve_specs_obj_f(l_ratings(i).rating_spec_id, l_ratings(i).office_id)(1);
            cwms_util.append(p_specs, l_spec.to_clob);
         end if;
      end if ;
      if p_ratings is not null then
         cwms_util.append(p_ratings, l_ratings(i).to_clob(p_time_zone));
      end if;

      if p_recurse and l_ratings(i).source_ratings is not null then
         for j in 1..l_ratings(i).source_ratings.count loop
            l_spec_id_mask :=trim(cwms_util.split_text(l_ratings(i).source_ratings(j), 1, '{'));
            begin
               l_spec := rating_spec_t(l_spec_id_mask, l_ratings(i).office_id);
            exception
               when others then
                  continue when instr(sqlerrm, 'not a valid rating specification') > 0;
            end;
            if p_templates is not null then
               dbms_lob.createtemporary(l_template_clob, true);
               dbms_lob.open(l_template_clob, dbms_lob.lob_readwrite);
            end if;
            if p_specs is not null then
               dbms_lob.createtemporary(l_spec_clob, true);
               dbms_lob.open(l_spec_clob, dbms_lob.lob_readwrite);
            end if;
            if p_ratings is not null then
               dbms_lob.createtemporary(l_rating_clob, true);
               dbms_lob.open(l_rating_clob, dbms_lob.lob_readwrite);
            end if;
            retreive_ratings_xml_data(
               l_template_clob,
               l_spec_clob,
               l_rating_clob,
               p_effective_tw,
               l_spec_id_mask,
               p_start_date,
               p_end_date,
               p_time_zone,
               p_recurse,
               p_include_points,
               l_ratings(i).office_id);
            if p_templates is not null then
               cwms_util.append(p_templates, l_template_clob);
               dbms_lob.close(l_template_clob);
            end if;
            if p_specs is not null then
               cwms_util.append(p_specs, l_spec_clob);
               dbms_lob.close(l_spec_clob);
            end if;
            if p_ratings is not null then
               cwms_util.append(p_ratings, l_rating_clob);
               dbms_lob.close(l_rating_clob);
            end if;
         end loop;
      end if;
   end loop;
end retreive_ratings_xml_data;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML_DATA
--
function retrieve_ratings_xml_data(
   p_effective_tw         in varchar2,
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_retrieve_templates   in boolean  default true,
   p_retrieve_specs       in boolean  default true,
   p_retrieve_ratings     in boolean  default true,
   p_recurse              in boolean  default true,
   p_include_points       in varchar2 default 'T',
   p_office_id_mask       in varchar2 default null)
   return clob
is
   type id_tab_t is table of boolean index by varchar2(32767);
   l_id                varchar2(32767);
   l_ids               id_tab_t;
   l_template_clob     clob;
   l_spec_clob         clob;
   l_rating_clob       clob;
   l_ratings           clob;
   l_template_xml      xmltype;
   l_spec_xml          xmltype;
   l_rating_xml        xmltype;
   l_has_source_rating boolean;
   l_xml_tab           xml_tab_t;
begin
   if p_retrieve_templates then
      dbms_lob.createtemporary(l_template_clob, true);
      dbms_lob.open(l_template_clob, dbms_lob.lob_readwrite);
   end if;
   if p_retrieve_specs then
      dbms_lob.createtemporary(l_spec_clob, true);
      dbms_lob.open(l_spec_clob, dbms_lob.lob_readwrite);
   end if;
   if p_retrieve_ratings then
      dbms_lob.createtemporary(l_rating_clob, true);
      dbms_lob.open(l_rating_clob, dbms_lob.lob_readwrite);
   end if;

   retreive_ratings_xml_data(
      l_template_clob,
      l_spec_clob,
      l_rating_clob,
      p_effective_tw,
      p_spec_id_mask,
      p_start_date,
      p_end_date,
      p_time_zone,
      p_recurse,
      p_include_points,
      p_office_id_mask);

   if p_retrieve_templates then
      dbms_lob.close(l_template_clob);
   end if;
   if p_retrieve_specs then
      dbms_lob.close(l_spec_clob);
   end if;
   if p_retrieve_ratings then
      dbms_lob.close(l_rating_clob);
      l_has_source_rating := instr(l_rating_clob, '<source-ratings>') > 0;
   end if;

   if p_retrieve_templates then
      dbms_lob.createtemporary(l_ratings, true);
      dbms_lob.open(l_ratings, dbms_lob.lob_readwrite);
      cwms_util.append(l_ratings, '<ratings>');
      cwms_util.append(l_ratings, l_template_clob);
      cwms_util.append(l_ratings, '</ratings>');
      dbms_lob.close(l_ratings);
      l_template_xml := xmltype(l_ratings);
   end if;
   if p_retrieve_specs then
      dbms_lob.createtemporary(l_ratings, true);
      dbms_lob.open(l_ratings, dbms_lob.lob_readwrite);
      cwms_util.append(l_ratings, '<ratings>');
      cwms_util.append(l_ratings, l_spec_clob);
      cwms_util.append(l_ratings, '</ratings>');
      dbms_lob.close(l_ratings);
      l_spec_xml := xmltype(l_ratings);
   end if;
   if p_retrieve_ratings and l_has_source_rating then
      dbms_lob.createtemporary(l_ratings, true);
      dbms_lob.open(l_ratings, dbms_lob.lob_readwrite);
      cwms_util.append(l_ratings, '<ratings>');
      cwms_util.append(l_ratings, l_rating_clob);
      cwms_util.append(l_ratings, '</ratings>');
      dbms_lob.close(l_ratings);
      l_rating_xml := xmltype(l_ratings);
   end if;
   dbms_lob.createtemporary(l_ratings, true);
   dbms_lob.open(l_ratings, dbms_lob.lob_readwrite);
   cwms_util.append(l_ratings, '<?xml version="1.0" encoding="utf-8"?>');
   cwms_util.append(l_ratings, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
   if p_retrieve_templates then
      l_xml_tab := cwms_util.get_xml_nodes(l_template_xml,  '/ratings/rating-template');
      for i in 1..l_xml_tab.count loop
         l_id := cwms_util.get_xml_text(l_xml_tab(i), '/rating-template/@office-id')
                 ||'/'
                 ||cwms_util.get_xml_text(l_xml_tab(i), '/rating-template/parameters-id')
                 ||'.'
                 ||cwms_util.get_xml_text(l_xml_tab(i), '/rating-template/version');
         if not l_ids.exists(l_id) then
            l_ids(l_id) := true;
            cwms_util.append(l_ratings, l_xml_tab(i).getclobval);
         end if;
      end loop;
   end if;
   if p_retrieve_specs then
      l_xml_tab := cwms_util.get_xml_nodes(l_spec_xml,  '/ratings/rating-spec');
      for i in 1..l_xml_tab.count loop
         l_id := cwms_util.get_xml_text(l_xml_tab(i), '/rating-spec/@office-id')
                 ||'/'
                 ||cwms_util.get_xml_text(l_xml_tab(i), '/rating-spec/rating-spec-id');
         if not l_ids.exists(l_id) then
            l_ids(l_id) := true;
            cwms_util.append(l_ratings, l_xml_tab(i).getclobval);
         end if;
      end loop;
   end if;
   if p_retrieve_ratings then
      if l_rating_xml is null then
         cwms_util.append(l_ratings, l_rating_clob);
      else
         l_xml_tab := cwms_util.get_xml_nodes(l_rating_xml,  '/ratings/rating|/ratings/simple-rating|/ratings/usgs-stream-rating|/ratings/virtual-rating|/ratings/transitional-rating');
         for i in 1..l_xml_tab.count loop
            l_id := cwms_util.get_xml_text(l_xml_tab(i), '/*/@office-id')
                    ||'/'
                    ||cwms_util.get_xml_text(l_xml_tab(i), '/*/rating-spec-id')
                    ||'('
                    ||cwms_util.get_xml_text(l_xml_tab(i), '/*/effective-date')
                    ||')';
            if not l_ids.exists(l_id) then
               l_ids(l_id) := true;
               cwms_util.append(l_ratings, l_xml_tab(i).getclobval);
            end if;
         end loop;
      end if;
   end if;
   cwms_util.append(l_ratings, '</ratings>');
   dbms_lob.close(l_ratings);
   select xmlserialize(content xmltype(l_ratings) indent size=2) into l_ratings from dual;
   return l_ratings;
end retrieve_ratings_xml_data;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML
--
procedure retrieve_ratings_xml(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_ratings := retrieve_ratings_xml_data(
      p_effective_tw         => 'F',
      p_spec_id_mask         => p_spec_id_mask,
      p_start_date           => p_effective_date_start,
      p_end_date             => p_effective_date_end,
      p_time_zone            => p_time_zone,
      p_retrieve_templates   => false,
      p_retrieve_specs       => false,
      p_retrieve_ratings     => true,
      p_recurse              => false,
      p_include_points       => 'T',
      p_office_id_mask       => p_office_id_mask);
end retrieve_ratings_xml;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_XML
--
procedure retrieve_eff_ratings_xml(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_ratings := retrieve_ratings_xml_data(
      p_effective_tw         => 'T',
      p_spec_id_mask         => p_spec_id_mask,
      p_start_date           => p_start_date,
      p_end_date             => p_end_date,
      p_time_zone            => p_time_zone,
      p_retrieve_templates   => false,
      p_retrieve_specs       => false,
      p_retrieve_ratings     => true,
      p_recurse              => false,
      p_include_points       => 'T',
      p_office_id_mask       => p_office_id_mask);
end retrieve_eff_ratings_xml;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML2
--
procedure retrieve_ratings_xml2(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_ratings := retrieve_ratings_xml_data(
      p_effective_tw         => 'F',
      p_spec_id_mask         => p_spec_id_mask,
      p_start_date           => p_effective_date_start,
      p_end_date             => p_effective_date_end,
      p_time_zone            => p_time_zone,
      p_retrieve_templates   => true,
      p_retrieve_specs       => true,
      p_retrieve_ratings     => true,
      p_recurse              => false,
      p_include_points       => 'T',
      p_office_id_mask       => p_office_id_mask);
end retrieve_ratings_xml2;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_XML2
--
procedure retrieve_eff_ratings_xml2(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_ratings := retrieve_ratings_xml_data(
      p_effective_tw         => 'T',
      p_spec_id_mask         => p_spec_id_mask,
      p_start_date           => p_start_date,
      p_end_date             => p_end_date,
      p_time_zone            => p_time_zone,
      p_retrieve_templates   => true,
      p_retrieve_specs       => true,
      p_retrieve_ratings     => true,
      p_recurse              => false,
      p_include_points       => 'T',
      p_office_id_mask       => p_office_id_mask);
end retrieve_eff_ratings_xml2;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML3
--
procedure retrieve_ratings_xml3(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_ratings := retrieve_ratings_xml_data(
      p_effective_tw         => 'F',
      p_spec_id_mask         => p_spec_id_mask,
      p_start_date           => p_effective_date_start,
      p_end_date             => p_effective_date_end,
      p_time_zone            => p_time_zone,
      p_retrieve_templates   => true,
      p_retrieve_specs       => true,
      p_retrieve_ratings     => true,
      p_recurse              => true,
      p_include_points       => 'T',
      p_office_id_mask       => p_office_id_mask);
end retrieve_ratings_xml3;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_XML3
--
procedure retrieve_eff_ratings_xml3(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
begin
   p_ratings := retrieve_ratings_xml_data(
      p_effective_tw         => 'T',
      p_spec_id_mask         => p_spec_id_mask,
      p_start_date           => p_start_date,
      p_end_date             => p_end_date,
      p_time_zone            => p_time_zone,
      p_retrieve_templates   => true,
      p_retrieve_specs       => true,
      p_retrieve_ratings     => true,
      p_recurse              => true,
      p_include_points       => 'T',
      p_office_id_mask       => p_office_id_mask);
end retrieve_eff_ratings_xml3;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML_F
--
function retrieve_ratings_xml_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob
is
   l_ratings clob;
begin
   retrieve_ratings_xml(
      l_ratings,
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_ratings_xml_f;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_XML_F
--
function retrieve_eff_ratings_xml_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob
is
   l_ratings clob;
begin
   retrieve_eff_ratings_xml(
      l_ratings,
      p_spec_id_mask,
      p_start_date,
      p_end_date,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_eff_ratings_xml_f;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML2_F
--
function retrieve_ratings_xml2_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob
is
   l_ratings clob;
begin
   retrieve_ratings_xml2(
      l_ratings,
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_ratings_xml2_f;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_XML2_F
--
function retrieve_eff_ratings_xml2_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob
is
   l_ratings clob;
begin
   retrieve_eff_ratings_xml2(
      l_ratings,
      p_spec_id_mask,
      p_start_date,
      p_end_date,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_eff_ratings_xml2_f;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML3_F
--
function retrieve_ratings_xml3_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob
is
   l_ratings clob;
begin
   retrieve_ratings_xml3(
      l_ratings,
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_ratings_xml3_f;

--------------------------------------------------------------------------------
-- RETRIEVE_EFF_RATINGS_XML3_F
--
function retrieve_eff_ratings_xml3_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob
is
   l_ratings clob;
begin
   retrieve_eff_ratings_xml3(
      l_ratings,
      p_spec_id_mask,
      p_start_date,
      p_end_date,
      p_time_zone,
      p_office_id_mask);

   return l_ratings;
end retrieve_eff_ratings_xml3_f;

--------------------------------------------------------------------------------
-- DELETE_RATINGS
--
procedure delete_ratings(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
is
   l_spec_id_mask    varchar2(512);
   l_time_zone       varchar2(28);
   l_office_id_mask  varchar2(16);
   l_effective_start date;
   l_effective_end   date;
begin
   l_spec_id_mask    := cwms_util.normalize_wildcards(p_spec_id_mask);
   l_office_id_mask  := cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id));
   l_time_zone       := nvl(p_time_zone, 'UTC');
   l_effective_start := cwms_util.change_timezone(p_effective_date_start, l_time_zone, 'UTC');
   l_effective_end   := cwms_util.change_timezone(p_effective_date_end, l_time_zone, 'UTC');
   for rec in
      (  select distinct
                rating_code
           from av_rating
          where upper(rating_id) like upper(l_spec_id_mask) escape '\'
            and office_id like upper(l_office_id_mask) escape '\'
            and effective_date >= nvl(l_effective_start, effective_date)
            and effective_date <= nvl(l_effective_end, effective_date)
          union all
         select transitional_rating_code
           from av_transitional_rating
          where (upper(rating_spec) like upper(l_spec_id_mask) escape '\' or
                 upper(source_rating_spec) like upper(l_spec_id_mask) escape '\'
                )
            and office_id like upper(l_office_id_mask) escape '\'
            and effective_date >= nvl(l_effective_start, effective_date)
            and effective_date <= nvl(l_effective_end, effective_date)
          union all
         select virtual_rating_code
           from av_virtual_rating
          where (upper(rating_spec) like upper(l_spec_id_mask) escape '\' or
                 upper(source_rating) like upper(l_spec_id_mask) escape '\'
                )
            and source_rating_spec_code is not null
            and office_id like upper(l_office_id_mask) escape '\'
            and effective_date >= nvl(l_effective_start, effective_date)
            and effective_date <= nvl(l_effective_end, effective_date)
      )
   loop
      delete_rating(rec.rating_code);
   end loop;
end delete_ratings;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_errors         out clob,
   p_xml            in  xmltype,
   p_fail_if_exists in  varchar2,
   p_replace_base   in  varchar2 default 'F')
is
   l_xml             xmltype;
   l_node            xmltype;
   l_rating          rating_t;
   l_id              varchar2(32);
   l_crsr            sys_refcursor;
   l_ts              timestamp(6);
   l_msg_txt         varchar2(4000);
   l_prev_txt        varchar2(4000);
   l_first           boolean := true;
   l_call_stack      str_tab_t;
   l_fail_if_exists  varchar2(1);
   l_error_if_exists boolean;

   function is_error(p_msg_txt in varchar2, p_error_if_exists in boolean) return boolean
   is
   begin
      if p_error_if_exists  then
         return instr(p_msg_txt, 'ERROR:') > 0
             or instr(p_msg_txt, 'ORA-') > 0;
      else
      return instr(p_msg_txt, 'ERROR:') > 0
          or (instr(p_msg_txt, 'ORA-') > 0 and instr(p_msg_txt, 'ITEM_ALREADY_EXISTS') = 0);
      end if;
   end;
begin
   ------------------
   -- sanity check --
   ------------------
   l_xml := cwms_util.get_xml_node(p_xml, '/ratings');
   if l_xml is null then
      cwms_err.raise('ERROR', 'XML does not have <ratings> root element');
   end if;
   l_fail_if_exists  := substr(p_fail_if_exists, 1, 1);
   if length(p_fail_if_exists) > 1 then
      l_error_if_exists := cwms_util.return_true_or_false(substr(p_fail_if_exists, 2));
   else
      l_error_if_exists := false;
   end if;
   --------------------------------
   -- log about process starting --
   --------------------------------
   l_id := cwms_msg.get_msg_id;
   set_package_log_property_text(l_id);
   cwms_msg.log_db_message(cwms_msg.msg_level_verbose, 'Processing ratings XML');
   -------------------------
   -- store any templates --
   -------------------------
   for i in 1..999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/rating-template['||i||']');
      exit when l_node is null;
      begin
         store_templates(l_node, l_fail_if_exists);
      exception
         when others then cwms_msg.log_db_message(cwms_msg.msg_level_normal, sqlerrm);
      end;
   end loop;
   commit;
   ------------------------------
   -- store any specifications --
   ------------------------------
   for i in 1..999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/rating-spec['||i||']');
      exit when l_node is null;
      begin
         store_specs(l_node, l_fail_if_exists);
      exception
         when others then cwms_msg.log_db_message(cwms_msg.msg_level_normal, sqlerrm);
      end;
   end loop;
   commit;
   -----------------------
   -- store any ratings --
   -----------------------
   for i in 1..999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '(/ratings/rating|/ratings/simple-rating|/ratings/virtual-rating|/ratings/transitional-rating|/ratings/usgs-stream-rating)['||i||']');
      exit when l_node is null;
      begin
         store_ratings(l_node, l_fail_if_exists, p_replace_base);
      exception
         when others then cwms_msg.log_db_message(cwms_msg.msg_level_normal, sqlerrm);
      end;
   end loop;
   commit;
   ------------------------------
   -- log about process ending --
   ------------------------------
   cwms_msg.log_db_message( cwms_msg.msg_level_verbose, 'Done processing ratings XML');
   set_package_log_property_text(null);
   ----------------------------------------------
   -- retrieve log messages and extract errors --
   ----------------------------------------------
   cwms_msg.retrieve_log_messages(
      p_log_crsr   => l_crsr,
      p_min_msg_id => l_id,
      p_properties => str_tab_tab_t(str_tab_t('cwms_rating', l_id, 'globi')));
   loop
      fetch l_crsr into l_id, l_ts, l_msg_txt;
      exit when l_crsr%notfound;
      if is_error(l_msg_txt, l_error_if_exists) then
         select prop_text
           bulk collect
           into l_call_stack
           from at_log_message_properties
          where msg_id = l_id
            and prop_name like 'call stack[%'
          order by prop_name;
         if p_errors is null then
            dbms_lob.createtemporary(p_errors, true);
         end if;
         if not is_error(l_prev_txt, l_error_if_exists) then
            if l_first then
               cwms_util.append(p_errors, l_prev_txt||chr(10));
               l_first := false;
            else
               cwms_util.append(p_errors, chr(10)||l_prev_txt||chr(10));
            end if;
         end if;
         cwms_util.append(p_errors, l_msg_txt||chr(10));
         for i in 1..l_call_stack.count loop
            cwms_util.append(p_errors, '   '||l_call_stack(i)||chr(10));
         end loop;
      end if;
      l_prev_txt := l_msg_txt;
   end loop;
   close l_crsr;
end store_ratings_xml;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_errors         out clob,
   p_xml            in  varchar2,
   p_fail_if_exists in  varchar2,
   p_replace_base   in  varchar2 default 'F')
is
begin
   store_ratings_xml(p_errors, xmltype(p_xml), p_fail_if_exists, p_replace_base);
end store_ratings_xml;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_errors         out clob,
   p_xml            in  clob,
   p_fail_if_exists in  varchar2,
   p_replace_base   in  varchar2 default 'F')
is
begin
   store_ratings_xml(p_errors, xmltype(p_xml), p_fail_if_exists, p_replace_base);
end store_ratings_xml;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F')
is
   l_errors clob;
begin
   store_ratings_xml(l_errors, p_xml, p_fail_if_exists, p_replace_base);
end store_ratings_xml;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F')
is
   l_errors clob;
begin
   store_ratings_xml(l_errors, xmltype(p_xml), p_fail_if_exists, p_replace_base);
end store_ratings_xml;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_xml            in clob,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F')
is
   l_errors clob;
begin
   store_ratings_xml(l_errors, xmltype(p_xml), p_fail_if_exists, p_replace_base);
end store_ratings_xml;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_results     out double_tab_t,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in  date_table_type default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   type integer_tab_t is table of pls_integer;
   c_base_date               constant date := date '1800-01-01';
   l_office_id               varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_time_zone               varchar2(28);
   l_parts                   str_tab_t;
   l_ratings                 rating_tab_t;
   l_rating_codes            number_tab_t;
   l_value_times             date_table_type;
   l_rating_time             date;
   l_date_offsets            double_tab_t;
   l_date_offset             binary_double;
   l_date_offset_2           binary_double;
   l_date_ratings            integer_tab_t;
   l_results                 double_tab_t;
   l_hi_index                pls_integer;
   l_hi_value                binary_double;
   l_lo_value                binary_double;
   l_ratio                   binary_double;
   l_min_date                date;
   l_max_date                date;
   l_values_count            pls_integer;
   l_in_range_behavior       pls_integer;
   l_out_range_low_behavior  pls_integer;
   l_out_range_high_behavior pls_integer;
   date_properties           cwms_lookup.sequence_properties_t;
   l_ind_set                 double_tab_t;
   l_ind_set_2               double_tab_t;
   l_rating_spec             rating_spec_t;
   l_independent_log         boolean;
   l_dependent_log           boolean;
   l_rating_units            str_tab_tab_t;
   l_stream_rating           stream_rating_t;
   l_round                   boolean := cwms_util.is_true(p_round);
   l_rating                  rating_t;
   l_code                    integer;

   function tabify(p_input in double_tab_t) return double_tab_tab_t
   is
      l_results double_tab_tab_t;
   begin
      select double_tab_t(column_value)
        bulk collect
        into l_results
        from table(p_input);
      return l_results;
   end tabify;
begin
   -------------------
   -- sanity checks --
   -------------------
   if regexp_instr(p_rating_spec, '\*|\?') != 0 then
      cwms_err.raise(
         'ERROR',
         'Cannot use a wildcard mask for rating specification');
   end if;
   if regexp_instr(p_office_id, '\*|\?') != 0 then
      cwms_err.raise(
         'ERROR',
         'Cannot use a wildcard mask for office id');
   end if;
   if p_values is null or p_values.count = 0 then
      return;
   else
      for i in 1..p_values.count loop
         if i = 1 then
            l_values_count := p_values(i).count;
         else
            if p_values(i).count != l_values_count then
               cwms_err.raise(
                  'ERROR',
                  'Input values must have consistent lengths');
            end if;
         end if;
      end loop;
      if p_value_times is not null then
         if p_value_times.count != l_values_count then
            cwms_err.raise(
               'ERROR',
               'Input times ('||p_value_times.count||') must have same length as input parameters ('||l_values_count||')');
         end if;
      end if;
   end if;
   if p_units is null or p_units.count != p_values.count + 1 then
      cwms_err.raise(
         'ERROR',
         'Units are NULL or inconsistent with input values');
   end if;
   ------------------------------------------------------------------------
   -- get the location, parameters, template version, and rating version --
   ------------------------------------------------------------------------
   l_parts := cwms_util.split_text(p_rating_spec, separator1);
   if l_parts.count != 4 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_rating_spec,
         'rating specification');
   end if;
   begin
      select rs.rating_spec_code
        into l_code
        from at_rating_spec rs,
             at_rating_template rt,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = l_office_id
         and bl.db_office_code = o.office_code
         and pl.base_location_code = bl.base_location_code
         and upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id) = upper(l_parts(1))
         and rt.office_code = o.office_code
         and upper(rt.parameters_id) = upper(l_parts(2))
         and upper(rt.version) = upper(l_parts(3))
         and rs.location_code = pl.location_code
         and rs.template_code = rt.template_code
         and upper(rs.version) = upper(l_parts(4));
   exception
      when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Rating specification',
         l_office_id||'/'||p_rating_spec);
   end;
   -------------------------------
   -- get the working time zone --
   -------------------------------
   if p_time_zone is null then
      ---------------------------------
      -- set to location's time zone --
      ---------------------------------
      select tz.time_zone_name
        into l_time_zone
        from at_physical_location pl,
             at_base_location bl,
             cwms_time_zone tz
       where upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
         and bl.db_office_code = cwms_util.get_db_office_code(l_office_id)
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, separator1) = nvl(cwms_util.get_sub_id(l_parts(1)), separator1)
         and tz.time_zone_code = nvl(pl.time_zone_code, 0);

      if l_time_zone = 'Unknown or Not Applicable' then
         l_time_zone := 'UTC';
      end if;
   else
      -----------------------------
      -- use specified time zone --
      -----------------------------
      l_time_zone := p_time_zone;
   end if;
   -------------------------
   -- get the rating time --
   -------------------------
   if p_rating_time is null then
      l_rating_time := cast(systimestamp at time zone 'UTC' as date);
   else
      if l_time_zone = 'UTC' then
         l_rating_time := p_rating_time;
      else
         l_rating_time := cwms_util.change_timezone(p_rating_time, l_time_zone, 'UTC');
      end if;
   end if;
   ---------------------
   -- get time window --
   ---------------------
   if p_value_times is not null and p_value_times.count > 0 then
      l_value_times := date_table_type();
      l_value_times.extend(p_value_times.count);
      for i in 1..l_value_times.count loop
         l_value_times(i) := p_value_times(i);
         if l_min_date is null or l_value_times(i) < l_min_date then
            l_min_date := l_value_times(i);
         end if;
         if l_max_date is null or l_value_times(i) > l_max_date then
            l_max_date := l_value_times(i);
         end if;
      end loop;
      if l_time_zone != 'UTC' then
         l_min_date := cwms_util.change_timezone(l_min_date, l_time_zone, 'UTC');
         l_max_date := cwms_util.change_timezone(l_max_date, l_time_zone, 'UTC');
         for i in 1..l_value_times.count loop
            l_value_times(i) := cwms_util.change_timezone(l_value_times(i), l_time_zone, 'UTC');
         end loop;
      end if;
   end if;
   --------------------------------
   -- get rating codes and dates --
   --------------------------------
   for rec in
      (  select rating_code,
                effective_date,
                transition_date,
                lag (effective_date, 1, null) over (order by effective_date) as prev_effective_date
           from (--------------------------------------------------
                 -- simple ratings and usgs-style stream ratings --
                 --------------------------------------------------
                 select r.rating_code,
                        r.effective_date,
                        r.transition_date
                   from at_rating r,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o
                  where o.office_id = l_office_id
                    and bl.db_office_code = o.office_code
                    and upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
                    and pl.base_location_code = bl.base_location_code
                    and nvl(upper(pl.sub_location_id), '-') = nvl(upper(cwms_util.get_sub_id(l_parts(1))), '-')
                    and rs.location_code = pl.location_code
                    and rs.active_flag = 'T'
                    and upper(rs.version) = upper(l_parts(4))
                    and rt.template_code = rs.template_code
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) = upper(l_parts(2))
                    and upper(rt.version) = upper(l_parts(3))
                    and r.rating_spec_code = rs.rating_spec_code
                    and r.active_flag = 'T'
                    and r.create_date <= l_rating_time
                 --------------------------
                 -- transitional ratings --
                 --------------------------
                  union all
                 select tr.transitional_rating_code as rating_code,
                        tr.effective_date,
                        tr.transition_date
                   from at_transitional_rating tr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o
                  where o.office_id = l_office_id
                    and bl.db_office_code = o.office_code
                    and upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
                    and pl.base_location_code = bl.base_location_code
                    and nvl(upper(pl.sub_location_id), '-') = nvl(upper(cwms_util.get_sub_id(l_parts(1))), '-')
                    and rs.location_code = pl.location_code
                    and rs.active_flag = 'T'
                    and upper(rs.version) = upper(l_parts(4))
                    and rt.template_code = rs.template_code
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) = upper(l_parts(2))
                    and upper(rt.version) = upper(l_parts(3))
                    and tr.rating_spec_code = rs.rating_spec_code
                    and tr.active_flag = 'T'
                    and tr.create_date <= l_rating_time
                 ---------------------
                 -- virtual ratings --
                 ---------------------
                  union all
                 select vr.virtual_rating_code as rating_code,
                        vr.effective_date,
                        vr.transition_date
                   from at_virtual_rating vr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o
                  where o.office_id = l_office_id
                    and bl.db_office_code = o.office_code
                    and upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
                    and pl.base_location_code = bl.base_location_code
                    and nvl(upper(pl.sub_location_id), '-') = nvl(upper(cwms_util.get_sub_id(l_parts(1))), '-')
                    and rs.location_code = pl.location_code
                    and rs.active_flag = 'T'
                    and upper(rs.version) = upper(l_parts(4))
                    and rt.template_code = rs.template_code
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) = upper(l_parts(2))
                    and upper(rt.version) = upper(l_parts(3))
                    and vr.rating_spec_code = rs.rating_spec_code
                    and vr.active_flag = 'T'
                    and vr.create_date <= l_rating_time
                )
          order by effective_date
      )
   loop
      if l_ratings is null then
         l_ratings      := rating_tab_t();
         l_rating_codes := number_tab_t();
         l_date_offsets := double_tab_t();
         l_date_ratings := integer_tab_t();
         l_rating_units := str_tab_tab_t();
      end if;
      if rec.transition_date between rec.prev_effective_date and rec.effective_date then -- if any is null then test is false
         l_date_offsets.extend;
         l_date_ratings.extend;
         l_date_offsets(l_date_offsets.count) := rec.transition_date - c_base_date;
         l_date_ratings(l_date_ratings.count) := l_ratings.count;
      end if;
      l_ratings.extend;
      l_rating_codes.extend;
      l_date_offsets.extend;
      l_date_ratings.extend;
      l_rating_units.extend;
      l_rating_codes(l_rating_codes.count) := rec.rating_code;
      l_date_offsets(l_date_offsets.count) := rec.effective_date - c_base_date;
      l_date_ratings(l_date_ratings.count) := l_ratings.count;
   end loop;
   if l_ratings is null then
      cwms_err.raise(
         'ERROR',
         'No active ratings for '
         ||l_office_id
         ||'/'
         ||p_rating_spec);
   elsif l_ratings.count = 1 then
      ---------------------------------------------------------------
      -- create a duplicate so the lookup procedures don't blow up --
      ---------------------------------------------------------------
      l_ratings.extend;
      l_rating_codes.extend;
      l_date_offsets.extend;
      l_date_ratings.extend;
      l_rating_units.extend;
      l_rating_codes(2) := l_rating_codes(1); -- same rating
      l_date_offsets(2) := l_date_offsets(1) + 1. / 86400.; -- 1 second later
      l_date_ratings(l_date_ratings.count) := l_date_ratings(l_date_ratings.count-1); -- index to same rating
   end if;
   -----------------------------------------------------
   -- generate lookup behaviors from rating behaviors --
   -----------------------------------------------------
   l_rating_spec := rating_spec_t(p_rating_spec, l_office_id);
   if cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method) = cwms_lookup.method_lin_log then
      l_in_range_behavior := cwms_lookup.method_linear;
   elsif cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method) = cwms_lookup.method_log_lin then
      l_in_range_behavior := cwms_lookup.method_logarithmic;
   else
      l_in_range_behavior := cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method);
   end if;
   if cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method) = cwms_lookup.method_lin_log then
      l_out_range_low_behavior := cwms_lookup.method_linear;
   elsif cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method) = cwms_lookup.method_log_lin then
      l_out_range_low_behavior := cwms_lookup.method_logarithmic;
   else
      l_out_range_low_behavior := cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method);
   end if;
   if cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method) = cwms_lookup.method_lin_log then
      l_out_range_high_behavior := cwms_lookup.method_linear;
   elsif cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method) = cwms_lookup.method_log_lin then
      l_out_range_high_behavior := cwms_lookup.method_logarithmic;
   else
      l_out_range_high_behavior := cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method);
   end if;
   --------------------
   -- do the ratings --
   --------------------
   date_properties := cwms_lookup.analyze_sequence(l_date_offsets);
   l_ind_set := double_tab_t();
   p_results := double_tab_t();
   p_results.extend(l_values_count);
   for j in 1..l_values_count loop
      if l_ind_set.count > 0 then
         l_ind_set.trim(l_ind_set.count);
      end if;
      l_ind_set.extend(p_values.count);
      for i in 1..p_values.count loop
         l_ind_set(i) := p_values(i)(j);
      end loop;
      l_date_offset := case l_value_times is null
                          when true  then cast(systimestamp at time zone 'UTC' as date) - c_base_date
                          when false then l_value_times(j) - c_base_date
                       end;
      ---------------------------------------------------------
      -- find the high index for interpolation/extrapolation --
      ---------------------------------------------------------
      l_hi_index := cwms_lookup.find_high_index(
         l_date_offset,
         l_date_offsets,
         date_properties);
      -----------------------------------------------------
      -- find the ratio for interpolation/extrapoloation --
      -----------------------------------------------------
      l_ratio := cwms_lookup.find_ratio(
         l_independent_log,
         l_date_offset,
         l_date_offsets,
         l_hi_index,
         date_properties.increasing_range,
         l_in_range_behavior,
         l_out_range_low_behavior,
         l_out_range_high_behavior);
      if l_ratio is not null then
         ------------------------------------------
         -- set log properties on dependent axis --
         ------------------------------------------
         if l_ratio <= 0. then
            l_dependent_log := cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method)
                               in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
            if l_dependent_log then
               if cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method)
                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin)
                  and not l_independent_log
               then
                  ---------------------------------------
                  -- fall back from LOG-LoG to LIN-LIN --
                  ---------------------------------------
                  l_dependent_log := false;
               end if;
            end if;
         elsif l_ratio > 1. then
            l_dependent_log := cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method)
                               in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
            if l_dependent_log then
               if cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method)
                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin)
                  and not l_independent_log
               then
                  ---------------------------------------
                  -- fall back from LOG-LoG to LIN-LIN --
                  ---------------------------------------
                  l_dependent_log := false;
               end if;
            end if;
         else
            l_dependent_log := cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method)
                               in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
            if l_dependent_log then
               if cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method)
                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin)
                  and not l_independent_log
               then
                  ---------------------------------------
                  -- fall back from LOG-LoG to LIN-LIN --
                  ---------------------------------------
                  l_dependent_log := false;
               end if;
            end if;
         end if;
         ---------------------------------------------------
         -- get the values from individual rating objects --
         ---------------------------------------------------
         if l_ratio != 0. then
            if l_ratings(l_date_ratings(l_hi_index)) is null then
               l_ratings(l_date_ratings(l_hi_index)) := get_rating(l_rating_codes(l_date_ratings(l_hi_index)));
               l_rating := treat(l_ratings(l_date_ratings(l_hi_index)) as rating_t);
               l_rating_units(l_date_ratings(l_hi_index)) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_date_ratings(l_hi_index)).count != p_units.count then
                  cwms_err.raise(
                     'ERROR',
                     'Wrong number of units supplied for rating '
                     ||l_rating.office_id
                     ||'/'
                     ||l_rating.rating_spec_id);
               end if;
               if l_rating is of (stream_rating_t) then
                  l_stream_rating := treat(l_rating as stream_rating_t);
                  if l_hi_index < l_date_offsets.count then
                     ---------------------------------------------------------
                     -- chop any shifts that are after the next rating date --
                     ---------------------------------------------------------
                     l_stream_rating.trim_to_effective_date(c_base_date + l_date_offsets(l_hi_index+1));
                     l_stream_rating.trim_to_create_date(l_rating_time);
                  end if;
                     l_rating := l_stream_rating;
               else
                  l_stream_rating := null;
               end if;
                  l_rating.convert_to_native_units;
                  l_ratings(l_date_ratings(l_hi_index)) := l_rating;
            else
               l_rating := l_ratings(l_date_ratings(l_hi_index));
            end if;
            l_ind_set_2 := double_tab_t();
            l_ind_set_2.extend(l_ind_set.count);
            for i in 1..l_ind_set.count loop
               l_ind_set_2(i) := cwms_util.convert_units(l_ind_set(i), p_units(i), l_rating_units(l_date_ratings(l_hi_index))(i));
            end loop;
            case
            when l_rating.connections is not null then
               --------------------
               -- virtual rating --
               --------------------
               l_hi_value := l_rating.rate(
                  tabify(l_ind_set_2),
                  cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3),
                  'F',
                  date_table_type(sysdate),
                  l_rating_time,
                  'UTC')(1);
            when l_rating.evaluations is not null then
               -------------------------
               -- transitional rating --
               -------------------------
               l_hi_value := l_rating.rate(
                  tabify(l_ind_set_2),
                  date_table_type(l_value_times(j)),
                  l_rating_time)(1);
            else
               ------------------------------------------
               -- non-virtual, non-transitional rating --
               ------------------------------------------
               if l_stream_rating is null or l_value_times is null then
                  l_hi_value := l_rating.rate_one(l_ind_set_2);
               else
                  l_hi_value := l_rating.rate(ztsv_type(l_value_times(j), l_ind_set_2(1), 0)).value;
               end if;
            end case;
            l_hi_value := cwms_util.convert_units(l_hi_value, l_rating_units(l_date_ratings(l_hi_index))(p_units.count), p_units(p_units.count));
         end if;
         if l_ratio != 1. then
            if l_ratings(l_date_ratings(l_hi_index-1)) is null then
               l_ratings(l_date_ratings(l_hi_index-1)) := get_rating(l_rating_codes(l_date_ratings(l_hi_index-1)));
               l_rating := treat(l_ratings(l_date_ratings(l_hi_index-1)) as rating_t);
               l_rating_units(l_date_ratings(l_hi_index-1)) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_date_ratings(l_hi_index-1)).count != p_units.count then
                  cwms_err.raise(
                     'ERROR',
                     'Wrong number of units supplied for rating '
                     ||l_rating.office_id
                     ||'/'
                     ||l_rating.rating_spec_id);
               end if;
               if l_rating is of (stream_rating_t) then
                  l_stream_rating := treat(l_rating as stream_rating_t);
                  if l_ratio != 0 and l_date_ratings(l_hi_index-1) != l_date_ratings(l_hi_index) and l_hi_index-1 < l_date_offsets.count then
                     ---------------------------------------------------------
                     -- chop any shifts that are after the next rating date --
                     ---------------------------------------------------------
                     l_stream_rating.trim_to_effective_date(c_base_date + l_date_offsets(l_hi_index));
                     l_stream_rating.trim_to_create_date(l_rating_time);
                  end if;
                     l_rating := l_stream_rating;
               else
                  l_stream_rating := null;
               end if;
                  l_rating.convert_to_native_units;
                  l_ratings(l_date_ratings(l_hi_index-1)) := l_rating;
            else
               l_rating := l_ratings(l_date_ratings(l_hi_index-1));
            end if;
            l_ind_set_2 := double_tab_t();
            l_ind_set_2.extend(l_ind_set.count);
            for i in 1..l_ind_set.count loop
               l_ind_set_2(i) := cwms_util.convert_units(l_ind_set(i), p_units(i), l_rating_units(l_date_ratings(l_hi_index-1))(i));
            end loop;
            case
            when l_rating.connections is not null then
               --------------------
               -- virtual rating --
               --------------------
               l_lo_value := l_rating.rate(
                  tabify(l_ind_set_2),
                  cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3),
                  'F',
                  date_table_type(sysdate),
                  l_rating_time,
                  'UTC')(1);
            when l_rating.evaluations is not null then
               -------------------------
               -- transitional rating --
               -------------------------
               l_lo_value := l_rating.rate(
                  tabify(l_ind_set_2),
                  date_table_type(l_value_times(j)),
                  l_rating_time)(1);
            else
               ------------------------------------------
               -- non-virtual, non-transitional rating --
               ------------------------------------------
               if l_stream_rating is null or l_value_times is null then
                  l_lo_value := l_rating.rate_one(l_ind_set_2);
               else
                  l_lo_value := l_rating.rate(ztsv_type(l_value_times(j), l_ind_set_2(1), 0)).value;
               end if;
            end case;
            l_lo_value := cwms_util.convert_units(l_lo_value, l_rating_units(l_date_ratings(l_hi_index-1))(p_units.count), p_units(p_units.count));
         end if;
         -----------------------------------------
         -- re-compute ratio for stream ratings --
         -----------------------------------------
         if l_ratings(l_date_ratings(l_hi_index-1)) is of (stream_rating_t)
            and l_ratio > 0.
            and l_ratio < 1.
            and treat(l_ratings(l_date_ratings(l_hi_index-1)) as stream_rating_t).latest_shift_date is not null
            and l_ratings(l_date_ratings(l_hi_index)).transition_date is null -- ratio is already correct if next rating has transition date
         then
            l_date_offset_2 := treat(l_ratings(l_date_ratings(l_hi_index-1)) as stream_rating_t).latest_shift_date - c_base_date;
            if l_date_offset_2 >= l_date_offset then
               l_ratio := 0.;
            else
               if l_independent_log then
                  l_ratio := (log(10, l_date_offset) - log(10, l_date_offset_2))
                           / (log(10, l_date_offsets(l_hi_index)) - log(10, l_date_offset_2));
                  if l_ratio is nan or l_ratio is infinite then
                     l_independent_log := false;
                     l_ratio := (l_date_offset - l_date_offset_2)
                              / (l_date_offsets(l_hi_index) - l_date_offset_2);
                  end if;
               else
                  l_ratio := (l_date_offset - l_date_offset_2)
                           / (l_date_offsets(l_hi_index) - l_date_offset_2);
               end if;
            end if;
         end if;
         -------------------------------------------------------------------------------
         -- generate the rated value from the values returned from the rating objects --
         -------------------------------------------------------------------------------
         case l_ratio
            when 0. then
               p_results(j) := l_lo_value;
            when 1. then
               p_results(j) := l_hi_value;
            else
               ------------------------------------------------------------------
               -- handle log interpolation/extrapolation on dependent sequence --
               ------------------------------------------------------------------
               if l_dependent_log then
                  declare
                     l_log_hi_val binary_double;
                     l_log_lo_val binary_double;
                  begin
                     l_log_hi_val := log(10, l_hi_value);
                     l_log_lo_val := log(10, l_lo_value);
                     if l_log_hi_val is NaN or l_log_hi_val is Infinite or
                        l_log_lo_val is NaN or l_log_lo_val is Infinite
                     then
                        l_dependent_log := false;
                        if l_independent_log then
                           ---------------------------------------
                           -- fall back from LOG-LoG to LIN-LIN --
                           ---------------------------------------
                           l_independent_log := false;
                           if l_ratings(l_date_ratings(l_hi_index-1)) is of (stream_rating_t) and l_ratio > 0. and l_ratio < 1.
                           then
                              l_ratio := (l_date_offset - l_date_offset_2)
                                       / (l_date_offsets(l_hi_index) - l_date_offset_2);
                           else
                              l_ratio := cwms_lookup.find_ratio(
                                 l_independent_log,
                                 l_date_offset,
                                 l_date_offsets,
                                 l_hi_index,
                                 date_properties.increasing_range,
                                 cwms_lookup.method_linear,
                                 cwms_lookup.method_linear,
                                 cwms_lookup.method_linear);
                           end if;
                        end if;
                     end if;
                     if l_dependent_log then
                        l_hi_value := l_log_hi_val;
                        l_lo_value := l_log_lo_val;
                     end if;
                  end;
               end if;
               -------------------------------
               -- interpolate / extrapolate --
               -------------------------------
               p_results(j) := l_lo_value + l_ratio * (l_hi_value - l_lo_value);
               --------------------------------------------------------------------
               -- apply anti-log if log interpolation/extrapolation of dependent --
               --------------------------------------------------------------------
               if l_dependent_log then
                  p_results(j) := power(10, p_results(j));
               end if;
         end case;
      end if;
   end loop;
   if l_round then
      cwms_rounding.round_d_tab(p_results, l_rating_spec.dep_rounding_spec);
   end if;
end rate;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_results     out double_tab_t,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in  date_table_type default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_values double_tab_tab_t;
begin
   if p_values is not null then
      l_values := double_tab_tab_t();
      l_values.extend(p_values.count);
      for i in 1..p_values.count loop
         l_values(i) := double_tab_t(p_values(i));
      end loop;
   end if;
   rate(
      p_results,
      p_rating_spec,
      l_values,
      p_units,
      p_round,
      p_value_times,
      p_rating_time,
      p_time_zone,
      p_office_id);
end rate;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_result      out binary_double,
   p_rating_spec in  varchar2,
   p_value       in  binary_double,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_time  in  date default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
begin
   rate_one(
      p_result,
      p_rating_spec,
      double_tab_t(p_value),
      p_units,
      p_round,
      p_value_time,
      p_rating_time,
      p_time_zone,
      p_office_id);
end;

--------------------------------------------------------------------------------
-- RATE_ONE
--
procedure rate_one(
   p_result      out binary_double,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_time  in  date default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_values  double_tab_tab_t := double_tab_tab_t();
   l_results double_tab_t;
begin
   l_values.extend(p_values.count);
   for i in 1..p_values.count loop
      l_values(i) := double_tab_t(p_values(i));
   end loop;
   rate(
      l_results,
      p_rating_spec,
      l_values,
      p_units,
      p_round,
      case p_value_time is null
         when true then null
         else date_table_type(p_value_time)
      end,
      p_rating_time,
      p_time_zone,
      p_office_id);

   p_result := l_results(1);
end rate_one;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_results     out tsv_array,
   p_rating_spec in  varchar2,
   p_values      in  tsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_values      double_tab_t;
   l_results     double_tab_t;
   l_value_times date_table_type;
   l_rating_time date;
begin
   if p_values is not null then
      l_values := double_tab_t();
      l_values.extend(p_values.count);
      l_value_times := date_table_type();
      l_value_times.extend(p_values.count);
      for i in 1..p_values.count loop
         l_values(i) := case cwms_ts.quality_is_missing(p_values(i)) or
                             cwms_ts.quality_is_rejected(p_values(i))
                           when true  then null
                           when false then p_values(i).value
                        end;
         l_value_times(i) := cast(p_values(i).date_time at time zone 'UTC' as date);
      end loop;
      l_rating_time := cwms_util.change_timezone(
         p_rating_time,
         nvl(p_time_zone, 'UTC'),
         'UTC');
      rate(
         l_results,
         p_rating_spec,
         l_values,
         p_units,
         p_round,
         l_value_times,
         l_rating_time,
         'UTC',
         p_office_id);
      p_results := tsv_array();
      for i in 1..p_values.count loop
         p_results(i).date_time := p_values(i).date_time;
         p_results(i).value := l_results(i);
         p_results(i).quality_code := case l_results(i) is null
                                         when true  then 5
                                         when false then 0
                                      end;
      end loop;
   end if;
end rate;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_results     out ztsv_array,
   p_rating_spec in  varchar2,
   p_values      in  ztsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_values      double_tab_t;
   l_results     double_tab_t;
   l_value_times date_table_type;
begin
   if p_values is not null then
      l_values := double_tab_t();
      l_values.extend(p_values.count);
      l_value_times := date_table_type();
      l_value_times.extend(p_values.count);
      for i in 1..p_values.count loop
         l_values(i) := case cwms_ts.quality_is_missing(p_values(i)) or
                             cwms_ts.quality_is_rejected(p_values(i))
                           when true  then null
                           when false then p_values(i).value
                        end;
         l_value_times(i) := p_values(i).date_time;
      end loop;
      rate(
         l_results,
         p_rating_spec,
         double_tab_tab_t(l_values),
         p_units,
         p_round,
         l_value_times,
         p_rating_time,
         p_time_zone,
         p_office_id);
      p_results := ztsv_array();
      p_results.extend(p_values.count);
      for i in 1..p_values.count loop
         p_results(i) := ztsv_type(
            p_values(i).date_time,
            l_results(i),
            case l_results(i) is null
               when true  then 5
               when false then 0
            end);
      end loop;
   end if;
end rate;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_result      out tsv_type,
   p_rating_spec in  varchar2,
   p_value       in  tsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_values  tsv_array;
   l_results tsv_array;
begin
   l_values := tsv_array(p_value);
   rate(
      l_results,
      p_rating_spec,
      l_values,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   p_result := l_results(1);
end rate;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_result      out ztsv_type,
   p_rating_spec in  varchar2,
   p_value       in  ztsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_values  ztsv_array;
   l_results ztsv_array;
begin
   l_values := ztsv_array(p_value);
   rate(
      l_results,
      p_rating_spec,
      l_values,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   p_result := l_results(1);
end rate;
--------------------------------------------------------------------------------
-- RATE_F
--
function rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_tab_t,
   p_units       in str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t
is
   l_results double_tab_t;
begin
   rate(
      l_results,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_value_times,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results;
end rate_f;

--------------------------------------------------------------------------------
-- RATE_F
--
function rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_t,
   p_units       in str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t
is
   l_values double_tab_t;
begin
   rate(
      l_values,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_value_times,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_values;
end rate_f;

--------------------------------------------------------------------------------
-- RATE_F
--
function rate_f(
   p_rating_spec in varchar2,
   p_value       in binary_double,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return binary_double
is
   l_result binary_double;
begin
   rate(
      l_result,
      p_rating_spec,
      p_value,
      p_units,
      p_round,
      p_value_times,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_result;
end rate_f;

--------------------------------------------------------------------------------
-- RATE_ONE_F
--
function rate_one_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_time  in date default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return binary_double
is
   l_result binary_double;
begin
   rate_one(
      l_result,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_value_time,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_result;
end rate_one_f;

--------------------------------------------------------------------------------
-- RATE_F
--
function rate_f(
   p_rating_spec in varchar2,
   p_values      in tsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_array
is
   l_results tsv_array;
begin
   rate(
      l_results,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results;
end rate_f;

--------------------------------------------------------------------------------
-- RATE_F
--
function rate_f(
   p_rating_spec in varchar2,
   p_values      in ztsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array
is
   l_results ztsv_array;
begin
   rate(
      l_results,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results;
end rate_f;

--------------------------------------------------------------------------------
-- RATE_F
--
function rate_f(
   p_rating_spec in varchar2,
   p_value       in tsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_type
is
   l_result tsv_type;
begin
   rate(
      l_result,
      p_rating_spec,
      p_value,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_result;
end rate_f;

--------------------------------------------------------------------------------
-- RATE_F
--
function rate_f(
   p_rating_spec in varchar2,
   p_value       in ztsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_type
is
   l_result ztsv_type;
begin
   rate(
      l_result,
      p_rating_spec,
      p_value,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_result;
end rate_f;

--------------------------------------------------------------------------------
-- REVERSE_RATE
--
procedure reverse_rate(
   p_results     out double_tab_t,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in  date_table_type default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   type integer_tab_t is table of pls_integer;
   c_base_date               constant date := date '1800-01-01';
   l_office_id               varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_time_zone               varchar2(28);
   l_parts                   str_tab_t;
   l_ratings                 rating_tab_t;
   l_rating_codes            number_tab_t;
   l_value_times             date_table_type;
   l_rating_time             date;
   l_date_offsets            double_tab_t;
   l_date_offset             binary_double;
   l_date_offset_2           binary_double;
   l_date_ratings            integer_tab_t;
   l_results                 double_tab_t;
   l_hi_index                pls_integer;
   l_hi_value                binary_double;
   l_lo_value                binary_double;
   l_ratio                   binary_double;
   l_min_date                date;
   l_max_date                date;
   l_values_count            pls_integer;
   l_in_range_behavior       pls_integer;
   l_out_range_low_behavior  pls_integer;
   l_out_range_high_behavior pls_integer;
   date_properties           cwms_lookup.sequence_properties_t;
   l_rating_spec             rating_spec_t;
   l_independent_log         boolean;
   l_dependent_log           boolean;
   l_rating_units            str_tab_tab_t;
   l_stream_rating           stream_rating_t;
   l_round                   boolean := cwms_util.is_true(p_round);
   l_rating                  rating_t;
   l_code                    integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if regexp_instr(p_rating_spec, '\*|\?') != 0 then
      cwms_err.raise(
         'ERROR',
         'Cannot use a wildcard mask for rating specification');
   end if;
   if regexp_instr(p_office_id, '\*|\?') != 0 then
      cwms_err.raise(
         'ERROR',
         'Cannot use a wildcard mask for office id');
   end if;
   if p_values is null or p_values.count = 0 then
      return;
   else
      l_values_count := p_values.count;
   end if;
   if p_units is null or p_units.count != 2 then
      cwms_err.raise(
         'ERROR',
         'Units are NULL or inconsistent with input values');
   end if;
   ------------------------------------------------------------------------
   -- get the location, parameters, template version, and rating version --
   ------------------------------------------------------------------------
   l_parts := cwms_util.split_text(p_rating_spec, separator1);
   if l_parts.count != 4 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_rating_spec,
         'rating specification');
   end if;
   begin
      select rs.rating_spec_code
        into l_code
        from at_rating_spec rs,
             at_rating_template rt,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = l_office_id
         and bl.db_office_code = o.office_code
         and pl.base_location_code = bl.base_location_code
         and upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id) = upper(l_parts(1))
         and rt.office_code = o.office_code
         and upper(rt.parameters_id) = upper(l_parts(2))
         and upper(rt.version) = upper(l_parts(3))
         and rs.location_code = pl.location_code
         and rs.template_code = rt.template_code
         and upper(rs.version) = upper(l_parts(4));
   exception
      when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Rating specification',
         l_office_id||'/'||p_rating_spec);
   end;
   -------------------------------
   -- get the working time zone --
   -------------------------------
   if p_time_zone is null then
      ---------------------------------
      -- set to location's time zone --
      ---------------------------------
      select tz.time_zone_name
        into l_time_zone
        from at_physical_location pl,
             at_base_location bl,
             cwms_time_zone tz
       where upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
         and bl.db_office_code = cwms_util.get_db_office_code(l_office_id)
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, separator1) = nvl(cwms_util.get_sub_id(l_parts(1)), separator1)
         and tz.time_zone_code = nvl(pl.time_zone_code, 0);

      if l_time_zone = 'Unknown or Not Applicable' then
         l_time_zone := 'UTC';
      end if;
   else
      -----------------------------
      -- use specified time zone --
      -----------------------------
      l_time_zone := p_time_zone;
   end if;
   -------------------------
   -- get the rating time --
   -------------------------
   if p_rating_time is null then
      l_rating_time := cast(systimestamp at time zone 'UTC' as date);
   else
      if l_time_zone = 'UTC' then
         l_rating_time := p_rating_time;
      else
         l_rating_time := cwms_util.change_timezone(p_rating_time, l_time_zone, 'UTC');
      end if;
   end if;
   ---------------------
   -- get time window --
   ---------------------
   if p_value_times is not null and p_value_times.count > 0 then
      l_value_times := date_table_type();
      l_value_times.extend(p_value_times.count);
      for i in 1..l_value_times.count loop
         l_value_times(i) := p_value_times(i);
         if l_min_date is null or l_value_times(i) < l_min_date then
            l_min_date := l_value_times(i);
         end if;
         if l_max_date is null or l_value_times(i) > l_max_date then
            l_max_date := l_value_times(i);
         end if;
      end loop;
      if l_time_zone != 'UTC' then
         l_min_date := cwms_util.change_timezone(l_min_date, l_time_zone, 'UTC');
         l_max_date := cwms_util.change_timezone(l_max_date, l_time_zone, 'UTC');
         for i in 1..l_value_times.count loop
            l_value_times(i) := cwms_util.change_timezone(l_value_times(i), l_time_zone, 'UTC');
         end loop;
      end if;
   end if;
   --------------------------------
   -- get rating codes and dates --
   --------------------------------
   for rec in
      (  select rating_code,
                effective_date,
                transition_date,
                lag (effective_date, 1, null) over (order by effective_date) as prev_effective_date
           from (--------------------------------------------------
                 -- simple ratings and usgs-style stream ratings --
                 --------------------------------------------------
                 select r.rating_code,
                        r.effective_date,
                        r.transition_date
                   from at_rating r,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o
                  where o.office_id = l_office_id
                    and bl.db_office_code = o.office_code
                    and upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
                    and pl.base_location_code = bl.base_location_code
                    and nvl(upper(pl.sub_location_id), '-') = nvl(upper(cwms_util.get_sub_id(l_parts(1))), '-')
                    and rs.location_code = pl.location_code
                    and rs.active_flag = 'T'
                    and upper(rs.version) = upper(l_parts(4))
                    and rt.template_code = rs.template_code
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) = upper(l_parts(2))
                    and upper(rt.version) = upper(l_parts(3))
                    and r.rating_spec_code = rs.rating_spec_code
                    and r.active_flag = 'T'
                    and r.create_date <= l_rating_time
                 --------------------------
                 -- transitional ratings --
                 --------------------------
                  union all
                 select tr.transitional_rating_code as rating_code,
                        tr.effective_date,
                        tr.transition_date
                   from at_transitional_rating tr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o
                  where o.office_id = l_office_id
                    and bl.db_office_code = o.office_code
                    and upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
                    and pl.base_location_code = bl.base_location_code
                    and nvl(upper(pl.sub_location_id), '-') = nvl(upper(cwms_util.get_sub_id(l_parts(1))), '-')
                    and rs.location_code = pl.location_code
                    and rs.active_flag = 'T'
                    and upper(rs.version) = upper(l_parts(4))
                    and rt.template_code = rs.template_code
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) = upper(l_parts(2))
                    and upper(rt.version) = upper(l_parts(3))
                    and tr.rating_spec_code = rs.rating_spec_code
                    and tr.active_flag = 'T'
                    and tr.create_date <= l_rating_time
                 ---------------------
                 -- virtual ratings --
                 ---------------------
                  union all
                 select vr.virtual_rating_code as rating_code,
                        vr.effective_date,
                        vr.transition_date
                   from at_virtual_rating vr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o
                  where o.office_id = l_office_id
                    and bl.db_office_code = o.office_code
                    and upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
                    and pl.base_location_code = bl.base_location_code
                    and nvl(upper(pl.sub_location_id), '-') = nvl(upper(cwms_util.get_sub_id(l_parts(1))), '-')
                    and rs.location_code = pl.location_code
                    and rs.active_flag = 'T'
                    and upper(rs.version) = upper(l_parts(4))
                    and rt.template_code = rs.template_code
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) = upper(l_parts(2))
                    and upper(rt.version) = upper(l_parts(3))
                    and vr.rating_spec_code = rs.rating_spec_code
                    and vr.active_flag = 'T'
                    and vr.create_date <= l_rating_time
                )
          order by effective_date
      )
   loop
      if l_ratings is null then
         l_ratings      := rating_tab_t();
         l_rating_codes := number_tab_t();
         l_date_offsets := double_tab_t();
         l_date_ratings := integer_tab_t();
         l_rating_units := str_tab_tab_t();
      end if;
      if rec.transition_date between rec.prev_effective_date and rec.effective_date then -- if any is null then test is false
         l_date_offsets.extend;
         l_date_ratings.extend;
         l_date_offsets(l_date_offsets.count) := rec.transition_date - c_base_date;
         l_date_ratings(l_date_ratings.count) := l_ratings.count;
      end if;
      l_ratings.extend;
      l_rating_codes.extend;
      l_date_offsets.extend;
      l_date_ratings.extend;
      l_rating_units.extend;
      l_rating_codes(l_rating_codes.count) := rec.rating_code;
      l_date_offsets(l_date_offsets.count) := rec.effective_date - c_base_date;
      l_date_ratings(l_date_ratings.count) := l_ratings.count;
   end loop;
   if l_ratings is null then
      cwms_err.raise(
         'ERROR',
         'No active ratings for '
         ||l_office_id
         ||'/'
         ||p_rating_spec);
   elsif l_ratings.count = 1 then
      ---------------------------------------------------------------
      -- create a duplicate so the lookup procedures don't blow up --
      ---------------------------------------------------------------
      l_ratings.extend;
      l_date_ratings.extend;
      l_rating_codes.extend;
      l_date_offsets.extend;
      l_rating_units.extend;
      l_ratings(2)      := l_ratings(1);                    -- same rating
      l_date_ratings(2) := l_date_ratings(1) + 1;           -- next index
      l_rating_codes(2) := l_rating_codes(1);               -- same rating
      l_date_offsets(2) := l_date_offsets(1) + 1. / 86400.; -- 1 second later
   end if;
   -----------------------------------------------------
   -- generate lookup behaviors from rating behaviors --
   -----------------------------------------------------
   l_rating_spec := rating_spec_t(p_rating_spec, l_office_id);
   if cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method) = cwms_lookup.method_lin_log then
      l_in_range_behavior := cwms_lookup.method_linear;
   elsif cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method) = cwms_lookup.method_log_lin then
      l_in_range_behavior := cwms_lookup.method_logarithmic;
   else
      l_in_range_behavior := cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method);
   end if;
   if cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method) = cwms_lookup.method_lin_log then
      l_out_range_low_behavior := cwms_lookup.method_linear;
   elsif cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method) = cwms_lookup.method_log_lin then
      l_out_range_low_behavior := cwms_lookup.method_logarithmic;
   else
      l_out_range_low_behavior := cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method);
   end if;
   if cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method) = cwms_lookup.method_lin_log then
      l_out_range_high_behavior := cwms_lookup.method_linear;
   elsif cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method) = cwms_lookup.method_log_lin then
      l_out_range_high_behavior := cwms_lookup.method_logarithmic;
   else
      l_out_range_high_behavior := cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method);
   end if;
   --------------------
   -- do the ratings --
   --------------------
   date_properties := cwms_lookup.analyze_sequence(l_date_offsets);
   p_results := double_tab_t();
   p_results.extend(l_values_count);
   for i in 1..l_values_count loop
      l_date_offset := case l_value_times is null or l_value_times(i) is null
                          when true  then cast(systimestamp at time zone 'UTC' as date) - c_base_date
                          when false then l_value_times(i) - c_base_date
                       end;
      ---------------------------------------------------------
      -- find the high index for interpolation/extrapolation --
      ---------------------------------------------------------
      l_hi_index := cwms_lookup.find_high_index(
         l_date_offset,
         l_date_offsets,
         date_properties);
      -----------------------------------------------------
      -- find the ratio for interpolation/extrapoloation --
      -----------------------------------------------------
      l_ratio := cwms_lookup.find_ratio(
         l_independent_log,
         l_date_offset,
         l_date_offsets,
         l_hi_index,
         date_properties.increasing_range,
         l_in_range_behavior,
         l_out_range_low_behavior,
         l_out_range_high_behavior);
      if l_ratio is not null then
         ------------------------------------------
         -- set log properties on dependent axis --
         ------------------------------------------
         if l_ratio <= 0. then
            l_dependent_log := cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method)
                               in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
            if l_dependent_log then
               if cwms_lookup.method_by_name(l_rating_spec.out_range_low_rating_method)
                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin)
                  and not l_independent_log
               then
                  ---------------------------------------
                  -- fall back from LOG-LoG to LIN-LIN --
                  ---------------------------------------
                  l_dependent_log := false;
               end if;
            end if;
         elsif l_ratio > 1. then
            l_dependent_log := cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method)
                               in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
            if l_dependent_log then
               if cwms_lookup.method_by_name(l_rating_spec.out_range_high_rating_method)
                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin)
                  and not l_independent_log
               then
                  ---------------------------------------
                  -- fall back from LOG-LoG to LIN-LIN --
                  ---------------------------------------
                  l_dependent_log := false;
               end if;
            end if;
         else
            l_dependent_log := cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method)
                               in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
            if l_dependent_log then
               if cwms_lookup.method_by_name(l_rating_spec.in_range_rating_method)
                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin)
                  and not l_independent_log
               then
                  ---------------------------------------
                  -- fall back from LOG-LoG to LIN-LIN --
                  ---------------------------------------
                  l_dependent_log := false;
               end if;
            end if;
         end if;
         ---------------------------------------------------
         -- get the values from individual rating objects --
         ---------------------------------------------------
         if l_ratio != 0. then
            if l_ratings(l_date_ratings(l_hi_index)) is null then
               l_ratings(l_date_ratings(l_hi_index)) := get_rating(l_rating_codes(l_date_ratings(l_hi_index)));
               l_rating := treat(l_ratings(l_date_ratings(l_hi_index)) as rating_t);
               if l_rating.evaluations is not null then
                  cwms_err.raise('ERROR', 'Cannot reverse rate through a transitional rating.');
               end if;
               l_rating.convert_to_native_units;
               l_ratings(l_date_ratings(l_hi_index)) := l_rating;
               l_rating_units(l_date_ratings(l_hi_index)) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_date_ratings(l_hi_index)).count != p_units.count then
                  cwms_err.raise(
                     'ERROR',
                     'Wrong number of units supplied for rating '
                     ||l_rating.office_id
                     ||'/'
                     ||l_rating.rating_spec_id);
               end if;
               if l_rating is of (stream_rating_t) then
                  if l_hi_index < l_date_offsets.count then
                     ---------------------------------------------------------
                     -- chop any shifts that are after the next rating date --
                     ---------------------------------------------------------
                     l_stream_rating := treat(l_rating as stream_rating_t);
                     l_stream_rating.trim_to_effective_date(c_base_date + l_date_offsets(l_hi_index+1));
                     l_stream_rating.trim_to_create_date(l_rating_time);
                  end if;
               end if;
            end if;
            if l_rating.connections is null then
               --------------------------
               -- not a virtual rating --
               --------------------------
               l_hi_value := cwms_util.convert_units(
                  l_rating.reverse_rate(
                     cwms_util.convert_units(
                        p_values(i),
                        p_units(2),
                        l_rating_units(l_date_ratings(l_hi_index))(2))),
                  l_rating_units(l_date_ratings(l_hi_index))(1),
                  p_units(1));
            else
               --------------------
               -- virtual rating --
               --------------------
               l_hi_value := cwms_util.convert_units(
                  l_rating.reverse_rate(
                     double_tab_t(cwms_util.convert_units(p_values(i), p_units(2), l_rating_units(l_date_ratings(l_hi_index))(2))),
                     cwms_util.split_text(l_rating.native_units, separator2),
                     'F',
                     null,
                     sysdate,
                     'UTC')(1),
                  l_rating_units(l_date_ratings(l_hi_index))(1),
                  p_units(1));
            end if;
         end if;
         if l_ratio != 1. then
            if l_ratings(l_date_ratings(l_hi_index-1)) is null then
               l_ratings(l_date_ratings(l_hi_index-1)) := get_rating(l_rating_codes(l_date_ratings(l_hi_index-1)));
               l_rating := treat(l_ratings(l_date_ratings(l_hi_index-1)) as rating_t);
               if l_rating.evaluations is not null then
                  cwms_err.raise('ERROR', 'Cannot reverse rate through a transitional rating.');
               end if;
               l_rating.convert_to_native_units;
               l_ratings(l_date_ratings(l_hi_index-1)) := l_rating;
               l_rating_units(l_date_ratings(l_hi_index-1)) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_date_ratings(l_hi_index-1)).count != p_units.count then
                  cwms_err.raise(
                     'ERROR',
                     'Wrong number of units supplied for rating '
                     ||l_rating.office_id
                     ||'/'
                     ||l_rating.rating_spec_id);
               end if;
               if l_rating is of (stream_rating_t) then
                  if l_hi_index-1 < l_date_offsets.count then
                     ---------------------------------------------------------
                     -- chop any shifts that are after the next rating date --
                     ---------------------------------------------------------
                     l_stream_rating := treat(l_rating as stream_rating_t);
                     l_stream_rating.trim_to_effective_date(c_base_date + l_date_offsets(l_hi_index-1+1));
                     l_stream_rating.trim_to_create_date(l_rating_time);
                  end if;
               end if;
            end if;
            if l_rating.connections is null then
               --------------------------
               -- not a virtual rating --
               --------------------------
               l_lo_value := cwms_util.convert_units(
                  l_rating.reverse_rate(
                     cwms_util.convert_units(
                        p_values(i),
                        p_units(1),
                        l_rating_units(l_date_ratings(l_hi_index-1))(1))),
                  l_rating_units(l_date_ratings(l_hi_index-1))(2),
                  p_units(2));
            else
               --------------------
               -- virtual rating --
               --------------------
               l_lo_value := cwms_util.convert_units(
                  l_rating.reverse_rate(
                     double_tab_t(cwms_util.convert_units(p_values(i), p_units(1), l_rating_units(l_date_ratings(l_hi_index-1))(1))),
                     cwms_util.split_text(l_rating.native_units, separator2),
                     'F',
                     null,
                     sysdate,
                     'UTC')(1),
                  l_rating_units(l_date_ratings(l_hi_index-1))(2),
                  p_units(2));
            end if;
         end if;
         -----------------------------------------
         -- re-compute ratio for stream ratings --
         -----------------------------------------
         if l_ratings(l_date_ratings(l_hi_index-1)) is of (stream_rating_t)
            and l_ratio > 0.
            and l_ratio < 1.
            and treat(l_ratings(l_date_ratings(l_hi_index-1)) as stream_rating_t).latest_shift_date is not null
         then
            l_date_offset_2 := treat(l_ratings(l_date_ratings(l_hi_index-1)) as stream_rating_t).latest_shift_date - c_base_date;
            if l_date_offset_2 >= l_date_offset then
               l_ratio := 0.;
            else
               if l_independent_log then
                  l_ratio := (log(10, l_date_offset) - log(10, l_date_offset_2))
                           / (log(10, l_date_offsets(l_hi_index)) - log(10, l_date_offset_2));
                  if l_ratio is NaN or l_ratio is Infinite then
                     l_independent_log := false;
                     l_ratio := (l_date_offset - l_date_offset_2)
                              / (l_date_offsets(l_hi_index) - l_date_offset_2);
                  end if;
               else
                  l_ratio := (l_date_offset - l_date_offset_2)
                           / (l_date_offsets(l_hi_index) - l_date_offset_2);
               end if;
            end if;
         end if;
         -------------------------------------------------------------------------------
         -- generate the rated value from the values returned from the rating objects --
         -------------------------------------------------------------------------------
         case l_ratio
            when 0. then
               p_results(i) := l_lo_value;
            when 1. then
               p_results(i) := l_hi_value;
            else
               ------------------------------------------------------------------
               -- handle log interpolation/extrapolation on dependent sequence --
               ------------------------------------------------------------------
               if l_dependent_log then
                  declare
                     l_log_hi_val binary_double;
                     l_log_lo_val binary_double;
                  begin
                     l_log_hi_val := log(10, l_hi_value);
                     l_log_lo_val := log(10, l_lo_value);
                     if l_log_hi_val is NaN or l_log_hi_val is Infinite or
                        l_log_lo_val is NaN or l_log_lo_val is Infinite
                     then
                        l_dependent_log := false;
                        if l_independent_log then
                           ---------------------------------------
                           -- fall back from LOG-LoG to LIN-LIN --
                           ---------------------------------------
                           l_independent_log := false;
                           if l_ratings(l_date_ratings(l_hi_index-1)) is of (stream_rating_t) and l_ratio > 0. and l_ratio < 1.
                           then
                              l_ratio := (l_date_offset - l_date_offset_2)
                                       / (l_date_offsets(l_hi_index) - l_date_offset_2);
                           else
                              l_ratio := cwms_lookup.find_ratio(
                                 l_independent_log,
                                 l_date_offset,
                                 l_date_offsets,
                                 l_hi_index,
                                 date_properties.increasing_range,
                                 cwms_lookup.method_linear,
                                 cwms_lookup.method_linear,
                                 cwms_lookup.method_linear);
                           end if;
                        end if;
                     end if;
                     if l_dependent_log then
                        l_hi_value := l_log_hi_val;
                        l_lo_value := l_log_lo_val;
                     end if;
                  end;
               end if;
               -------------------------------
               -- interpolate / extrapolate --
               -------------------------------
               p_results(i) := l_lo_value + l_ratio * (l_hi_value - l_lo_value);
               --------------------------------------------------------------------
               -- apply anti-log if log interpolation/extrapolation of dependent --
               --------------------------------------------------------------------
               if l_dependent_log then
                  p_results(i) := power(10, p_results(i));
               end if;
         end case;
      end if;
   end loop;
   if l_round then
      cwms_rounding.round_d_tab(p_results, l_rating_spec.ind_rounding_specs(1));
   end if;
end reverse_rate;

--------------------------------------------------------------------------------
-- REVERSE_RATE
--
procedure reverse_rate(
   p_result      out binary_double,
   p_rating_spec in  varchar2,
   p_value       in  binary_double,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_time  in  date default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_results double_tab_t;
begin
   reverse_rate(
      l_results,
      p_rating_spec,
      double_tab_t(p_value),
      p_units,
      p_round,
      date_table_type(p_value_time),
      p_rating_time,
      p_time_zone,
      p_office_id);

   p_result := l_results(1);
end reverse_rate;

--------------------------------------------------------------------------------
-- REVERSE_RATE
--
procedure reverse_rate(
   p_results     out tsv_array,
   p_rating_spec in  varchar2,
   p_values      in  tsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_parts      str_tab_t;
   l_values     double_tab_t;
   l_values_out double_tab_t;
   l_times      date_table_type;
   l_time_zone  varchar2(28);
begin
   if p_values is not null then
      ---------------------------
      -- set up the parameters --
      ---------------------------
      if p_time_zone is null then
         l_parts := cwms_util.split_text(p_rating_spec, separator1);
         select tz.time_zone_name
           into l_time_zone
           from at_physical_location pl,
                at_base_location bl,
                cwms_time_zone tz
          where upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_parts(1)))
            and bl.db_office_code = cwms_util.get_db_office_code(p_office_id)
            and pl.base_location_code = bl.base_location_code
            and upper(pl.sub_location_id) = upper(cwms_util.get_sub_id(l_parts(1)))
            and tz.time_zone_code = nvl(tz.time_zone_code, '0');

         if l_time_zone = 'Unknown or Not Applicable' then
            l_time_zone := 'UTC';
         end if;
      else
         l_time_zone := p_time_zone;
      end if;
      l_values := double_tab_t();
      l_values.extend(p_values.count);
      l_times := date_table_type();
      l_times.extend(p_values.count);
      for i in 1..p_values.count loop
         l_values(i) := case cwms_ts.quality_is_missing(p_values(i)) or
                             cwms_ts.quality_is_rejected(p_values(i))
                           when true  then null
                           when false then p_values(i).value
                        end;
         l_times(i) := cast(p_values(i).date_time at time zone l_time_zone as date);
      end loop;
      ------------------------
      -- perform the rating --
      ------------------------
      reverse_rate(
         l_values_out,
         p_rating_spec,
         l_values,
         p_units,
         p_round,
         l_times,
         p_rating_time,
         l_time_zone,
         p_office_id);
      -------------------------------
      -- process the return values --
      -------------------------------
      p_results := tsv_array();
      p_results.extend(p_values.count);
      for i in 1..p_values.count loop
         p_results(i).date_time := p_values(i).date_time;
         p_results(i).value := l_values_out(i);
         p_results(i).quality_code := case l_values_out(i) is null
                                         when true  then 5
                                         when false then 0
                                      end;
      end loop;
   end if;
end reverse_rate;

--------------------------------------------------------------------------------
-- REVERSE_RATE
--
procedure reverse_rate(
   p_results     out ztsv_array,
   p_rating_spec in  varchar2,
   p_values      in  ztsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_values     double_tab_t;
   l_values_out double_tab_t;
   l_times      date_table_type;
begin
   if p_values is not null then
      ---------------------------
      -- set up the parameters --
      ---------------------------
      l_values := double_tab_t();
      l_values.extend(p_values.count);
      l_times := date_table_type();
      l_times.extend(p_values.count);
      for i in 1..p_values.count loop
         l_values(i) := case cwms_ts.quality_is_missing(p_values(i)) or
                             cwms_ts.quality_is_rejected(p_values(i))
                           when true  then null
                           when false then p_values(i).value
                        end;
         l_times(i) := p_values(i).date_time;
      end loop;
      ------------------------
      -- perform the rating --
      ------------------------
      reverse_rate(
         l_values_out,
         p_rating_spec,
         l_values,
         p_units,
         p_round,
         l_times,
         p_rating_time,
         p_time_zone,
         p_office_id);
      -------------------------------
      -- process the return values --
      -------------------------------
      p_results := ztsv_array();
      p_results.extend(p_values.count);
      for i in 1..p_values.count loop
         p_results(i).date_time := p_values(i).date_time;
         p_results(i).value := l_values_out(i);
         p_results(i).quality_code := case l_values_out(i) is null
                                         when true  then 5
                                         when false then 0
                                      end;
      end loop;
   end if;
end reverse_rate;

--------------------------------------------------------------------------------
-- REVERSE_RATE
--
procedure reverse_rate(
   p_result      out tsv_type,
   p_rating_spec in  varchar2,
   p_value       in  tsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_results tsv_array;
begin
   reverse_rate(
      l_results,
      p_rating_spec,
      tsv_array(p_value),
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   p_result := l_results(1);
end reverse_rate;

--------------------------------------------------------------------------------
-- REVERSE_RATE
--
procedure reverse_rate(
   p_result      out ztsv_type,
   p_rating_spec in  varchar2,
   p_value       in  ztsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null)
is
   l_results ztsv_array;
begin
   reverse_rate(
      l_results,
      p_rating_spec,
      ztsv_array(p_value),
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   p_result := l_results(1);
end reverse_rate;

--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t
is
   l_results double_tab_t;
begin
   reverse_rate(
      l_results,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_value_times,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results;
end reverse_rate_f;

--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in binary_double,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return binary_double
is
   l_result binary_double;
begin
   reverse_rate(
      l_result,
      p_rating_spec,
      p_value,
      p_units,
      p_round,
      p_value_times,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_result;
end reverse_rate_f;

--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in tsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_array
is
   l_results tsv_array;
begin
   reverse_rate(
      l_results,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results;
end reverse_rate_f;

--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in ztsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array
is
   l_results ztsv_array;
begin
   reverse_rate(
      l_results,
      p_rating_spec,
      p_values,
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results;
end reverse_rate_f;

--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in tsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_type
is
   l_results tsv_array;
begin
   l_results := reverse_rate_f(
      p_rating_spec,
      tsv_array(p_value),
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results(1);
end reverse_rate_f;

--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in ztsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_type
is
   l_results ztsv_array;
begin
   l_results := reverse_rate_f(
      p_rating_spec,
      ztsv_array(p_value),
      p_units,
      p_round,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_results(1);
end reverse_rate_f;

--------------------------------------------------------------------------------
-- RETRIEVE_RATED_TS
--
function retrieve_rated_ts(
   p_independent_ids  in str_tab_t,
   p_rating_id        in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_round            in varchar2 default 'F',
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
   return ztsv_array
is
   l_ind_values   double_tab_tab_t;
   l_dep_values   double_tab_t;
   l_times        date_table_type;
   l_results      ztsv_array;
   l_parts        str_tab_t;
   l_location     varchar2(57); -- from first independent id
   l_time_zone    varchar2(28);
   l_interval     varchar2(16);
   l_units        str_tab_t;
   l_cursor       sys_refcursor;
   l_date_time    date;
   l_value        binary_double;
   l_quality_code integer;
   l_first_valid  pls_integer;
   l_last_valid   pls_integer;
   j              pls_integer;
begin
   if p_independent_ids is not null and p_independent_ids.count > 0 then
      -------------------
      -- sanity checks --
      -------------------
      l_parts := cwms_util.split_text(p_rating_id, separator1);
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'CWMS rating identifier');
      end if;
      l_units := cwms_util.split_text(replace(l_parts(2), separator2, separator3), separator3);
      if l_units.count != p_independent_ids.count + 1 then
         cwms_err.raise(
            'ERROR',
            'Rating ('
            ||p_rating_id
            ||') requires '
            ||(l_units.count - 1)
            ||' independent parameters, '
            ||p_independent_ids.count
            ||' specified');
      end if;
      for i in 1..l_units.count-1 loop
         l_units(i) := cwms_util.get_default_units(l_units(i));
      end loop;
      l_units(l_units.count) := p_units;
      for i in 1..p_independent_ids.count loop
         l_parts := cwms_util.split_text(p_independent_ids(i), separator1);
         if l_parts.count != 6 then
            cwms_err.raise(
               'INVALID_ITEM',
               p_independent_ids(i),
               'CWMS time series identifier');
         end if;
         if i = 1 then
            l_location := l_parts(1);
            l_interval := l_parts(4);
         else
            if l_parts(4) != l_interval then
               cwms_err.raise(
                  'ERROR',
                  'Intervals of input time series must be the same');
            end if;
         end if;
      end loop;
      -------------------------------
      -- get the working time zone --
      -------------------------------
      if p_time_zone is null then
         ---------------------------------
         -- set to location's time zone --
         ---------------------------------
         select tz.time_zone_name
           into l_time_zone
           from at_physical_location pl,
                at_base_location bl,
                cwms_time_zone tz
          where upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_location))
            and bl.db_office_code = cwms_util.get_db_office_code(p_ts_office_id)
            and pl.base_location_code = bl.base_location_code
            and nvl(pl.sub_location_id, separator1) = nvl(cwms_util.get_sub_id(l_location), separator1)
            and tz.time_zone_code = nvl(pl.time_zone_code, 0);

         if l_time_zone = 'Unknown or Not Applicable' then
            l_time_zone := 'UTC';
         end if;
      else
         -----------------------------
         -- use specified time zone --
         -----------------------------
         l_time_zone := p_time_zone;
      end if;
      -------------------------------------
      -- retrieve the independent values --
      -------------------------------------
      l_ind_values := double_tab_tab_t();
      l_ind_values.extend(p_independent_ids.count);
      l_times := date_table_type();
      for i in 1..p_independent_ids.count loop
         cwms_ts.retrieve_ts(
            l_cursor,
            p_independent_ids(i),
            l_units(i),
            p_start_time,
            p_end_time,
            p_time_zone,
            'F', -- don't trim independent values
            p_start_inclusive,
            p_end_inclusive,
            p_previous,
            p_next,
            p_version_date,
            p_max_version,
            p_ts_office_id);
         l_ind_values(i) := double_tab_t();
         j := 0;
         loop
            fetch l_cursor
             into l_date_time,
                  l_value,
                  l_quality_code;
            exit when l_cursor%notfound;
            j := j + 1;
            l_ind_values(i).extend;
            l_ind_values(i)(j) := l_value;
            if i = 1 then
               l_times.extend;
               l_times(j) := l_date_time;
            elsif l_date_time != l_times(j) then
               close l_cursor;
               cwms_err.raise(
                  'ERROR',
                  'Independent variable times do not match.');
            end if;
         end loop;
         close l_cursor;
      end loop;
      ------------------------
      -- perform the rating --
      ------------------------
      l_dep_values := rate_f(
         p_rating_id,
         l_ind_values,
         l_units,
         p_round,
         l_times,
         p_rating_time,
         p_time_zone,
         p_rating_office_id);
      --------------------------------
      -- construct the return value --
      --------------------------------
      l_results := ztsv_array();
      if cwms_util.is_true(p_trim) then
         for i in 1..l_times.count loop
            if l_dep_values(i) is not null then
               l_first_valid := i;
               exit;
            end if;
         end loop;
      else
         l_first_valid := 1;
      end if;
      if l_first_valid is not null then
         if cwms_util.is_true(p_trim) then
            for i in reverse 1..l_times.count loop
               if l_dep_values(i) is not null then
                  l_last_valid := i;
                  exit;
               end if;
            end loop;
         else
            l_last_valid := l_times.count;
         end if;
         for i in l_first_valid..l_last_valid loop
            l_results.extend;
            l_results(i) := ztsv_type(
               l_times(i),
               l_dep_values(i),
               case l_dep_values(i) is null
                  when true  then 5 -- missing
                  when false then 0 -- unscreened
               end);
         end loop;
      end if;
   end if;
   return l_results;
end retrieve_rated_ts;

--------------------------------------------------------------------------------
-- RETRIEVE_RATED_TS
--
function retrieve_rated_ts(
   p_independent_id   in varchar2,
   p_rating_id        in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_round            in varchar2 default 'F',
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
   return ztsv_array
is
begin
   return retrieve_rated_ts(
      str_tab_t(p_independent_id),
      p_rating_id,
      p_units,
      p_start_time,
      p_end_time,
      p_rating_time,
      p_time_zone,
      p_round,
      p_trim,
      p_start_inclusive,
      p_end_inclusive,
      p_previous,
      p_next,
      p_version_date,
      p_max_version,
      p_ts_office_id,
      p_rating_office_id);
end retrieve_rated_ts;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_independent_ids  in str_tab_t,
   p_dependent_id     in varchar2,
   p_rating_id        in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
is
   l_dep_ts   ztsv_array;
   l_dep_unit varchar2(16);
   l_parts    str_tab_t;
   l_interval varchar2(16);
begin
   if p_independent_ids is not null and p_independent_ids.count > 0 then
      -------------------
      -- sanity checks --
      -------------------
      l_parts := cwms_util.split_text(p_independent_ids(1), separator1);
      if l_parts.count != 6 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_independent_ids(1),
            'CWMS time series identifier');
      end if;
      l_interval := l_parts(4);
      l_parts := cwms_util.split_text(p_dependent_id, separator1);
      if l_parts.count != 6 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_dependent_id,
            'CWMS time series identifier');
      end if;
      if l_parts(4) != l_interval then
         cwms_err.raise(
            'ERROR',
            'Dependent interval differs from independent interval');
      end if;
      --------------------------------------------------------
      -- get the database units for the dependent parameter --
      --------------------------------------------------------
      select u.unit_id
        into l_dep_unit
        from cwms_base_parameter bp,
             cwms_unit u
       where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(l_parts(2)))
         and u.unit_code = bp.unit_code;
      ------------------------------------
      -- retrieve the rated time series --
      ------------------------------------
      l_dep_ts := retrieve_rated_ts(
         p_independent_ids,
         p_rating_id,
         l_dep_unit,
         p_start_time,
         p_end_time,
         p_rating_time,
         p_time_zone,
         'F',
         p_trim,
         p_start_inclusive,
         p_end_inclusive,
         p_previous,
         p_next,
         p_version_date,
         p_max_version,
         p_ts_office_id,
         p_rating_office_id);
      ---------------------------------
      -- store the rated time series --
      ---------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => p_dependent_id,
         p_units           => l_dep_unit,
         p_timeseries_data => l_dep_ts,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => p_version_date,
         p_office_id       => p_ts_office_id);
   end if;
end rate;

--------------------------------------------------------------------------------
-- RATE
--
procedure rate(
   p_independent_id   in varchar2,
   p_dependent_id     in varchar2,
   p_rating_id        in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
is
begin
   rate(
      str_tab_t(p_independent_id),
      p_dependent_id,
      p_rating_id,
      p_start_time,
      p_end_time,
      p_rating_time,
      p_time_zone,
      p_trim,
      p_start_inclusive,
      p_end_inclusive,
      p_previous,
      p_next,
      p_version_date,
      p_max_version,
      p_ts_office_id,
      p_rating_office_id);
end rate;

--------------------------------------------------------------------------------
-- RETRIEVE_REVERSE_RATED_TS
--
function retrieve_reverse_rated_ts(
   p_input_id         in varchar2,
   p_rating_id        in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_round            in varchar2 default 'F',
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
   return ztsv_array
is
   l_dep_values   double_tab_t;
   l_ind_values   double_tab_t;
   l_times        date_table_type;
   l_results      ztsv_array;
   l_parts        str_tab_t;
   l_interval     varchar2(16);
   l_location     varchar2(57); -- from dependent id
   l_time_zone    varchar2(28);
   l_units        str_tab_t;
   l_cursor       sys_refcursor;
   l_date_time    date;
   l_value        binary_double;
   l_quality_code integer;
   l_first_valid  pls_integer;
   l_last_valid   pls_integer;
   j              pls_integer;
begin
   if p_input_id is not null then
      -------------------
      -- sanity checks --
      -------------------
      l_parts := cwms_util.split_text(p_rating_id, separator1);
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'CWMS rating identifier');
      end if;
      l_units := cwms_util.split_text(replace(l_parts(1), separator2, separator3), separator3);
      if l_units.count != 2 then
         cwms_err.raise(
            'ERROR',
            'Rating ('
            ||p_rating_id
            ||') requires '
            ||l_units.count - 1
            ||' independent parameters, 2 specified');
      end if;
      l_units(l_units.count) := p_units;
      l_parts := cwms_util.split_text(p_input_id, separator1);
      if l_parts.count != 6 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_input_id,
            'CWMS time series identifier');
      end if;
      l_location := l_parts(1);
      l_interval := l_parts(4);
      -------------------------------
      -- get the working time zone --
      -------------------------------
      if p_time_zone is null then
         ---------------------------------
         -- set to location's time zone --
         ---------------------------------
         select tz.time_zone_name
           into l_time_zone
           from at_physical_location pl,
                at_base_location bl,
                cwms_time_zone tz
          where upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_location))
            and bl.db_office_code = cwms_util.get_db_office_code(p_ts_office_id)
            and pl.base_location_code = bl.base_location_code
            and nvl(pl.sub_location_id, separator1) = nvl(cwms_util.get_sub_id(l_location), separator1)
            and tz.time_zone_code = nvl(pl.time_zone_code, 0);

         if l_time_zone = 'Unknown or Not Applicable' then
            l_time_zone := 'UTC';
         end if;
      else
         -----------------------------
         -- use specified time zone --
         -----------------------------
         l_time_zone := p_time_zone;
      end if;
      -------------------------------------
      -- retrieve the independent values --
      -------------------------------------
      l_dep_values := double_tab_t();
      l_times := date_table_type();
      cwms_ts.retrieve_ts(
         l_cursor,
         p_input_id,
         l_units(1),
         p_start_time,
         p_end_time,
         p_time_zone,
         'F', -- don't trim independent values
         p_start_inclusive,
         p_end_inclusive,
         p_previous,
         p_next,
         p_version_date,
         p_max_version,
         p_ts_office_id);
      j := 0;
      loop
         fetch l_cursor
          into l_date_time,
               l_value,
               l_quality_code;
         exit when l_cursor%notfound;
         j := j + 1;
         l_dep_values.extend;
         l_dep_values(j) := l_value;
         l_times.extend;
         l_times(j) := l_date_time;
      end loop;
      close l_cursor;
      ------------------------
      -- perform the rating --
      ------------------------
      l_ind_values := reverse_rate_f(
         p_rating_id,
         l_dep_values,
         l_units,
         p_round,
         l_times,
         p_rating_time,
         p_time_zone,
         p_rating_office_id);
      --------------------------------
      -- construct the return value --
      --------------------------------
      l_results := ztsv_array();
      if cwms_util.is_true(p_trim) then
         for i in 1..l_times.count loop
            if l_ind_values(i) is not null then
               l_first_valid := i;
               exit;
            end if;
         end loop;
      else
         l_first_valid := 1;
      end if;
      if l_first_valid is not null then
         if cwms_util.is_true(p_trim) then
            for i in reverse 1..l_times.count loop
               if l_ind_values(i) is not null then
                  l_last_valid := i;
                  exit;
               end if;
            end loop;
         else
            l_last_valid := l_times.count;
         end if;
         for i in l_first_valid..l_last_valid loop
            l_results.extend;
            l_results(i) := ztsv_type(
               l_times(i),
               l_ind_values(i),
               case l_ind_values(i) is null
                  when true  then 5 -- missing
                  when false then 0 -- unscreened
               end);
         end loop;
      end if;
   end if;
   return l_results;
end retrieve_reverse_rated_ts;

--------------------------------------------------------------------------------
-- REVERSE_RATE
--
procedure reverse_rate(
   p_input_id         in varchar2,
   p_output_id        in varchar2,
   p_rating_id        in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
is
   l_dep_ts   ztsv_array;
   l_dep_unit varchar2(16);
   l_parts    str_tab_t;
   l_interval varchar2(16);
begin
   if p_input_id is not null then
      -------------------
      -- sanity checks --
      -------------------
      l_parts := cwms_util.split_text(p_input_id, separator1);
      if l_parts.count != 6 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_input_id,
            'CWMS time series identifier');
      end if;
      l_interval := l_parts(4);
      l_parts := cwms_util.split_text(p_output_id, separator1);
      if l_parts.count != 6 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_output_id,
            'CWMS time series identifier');
      end if;
      if l_parts(4) = l_interval then
         cwms_err.raise(
            'ERROR',
            'Dependent interval differs from independent interval');
      end if;
      --------------------------------------------------------
      -- get the database units for the dependent parameter --
      --------------------------------------------------------
      select u.unit_id
        into l_dep_unit
        from cwms_base_parameter bp,
             cwms_unit u
       where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(l_parts(2)))
         and u.unit_code = bp.unit_code;
      ------------------------------------
      -- retrieve the rated time series --
      ------------------------------------
      l_dep_ts := retrieve_reverse_rated_ts(
         p_input_id,
         p_rating_id,
         l_dep_unit,
         p_start_time,
         p_end_time,
         p_rating_time,
         p_time_zone,
         p_trim,
         p_start_inclusive,
         p_end_inclusive,
         p_previous,
         p_next,
         p_version_date,
         p_max_version,
         p_ts_office_id,
         p_rating_office_id);
      ---------------------------------
      -- store the rated time series --
      ---------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => p_output_id,
         p_units            => l_dep_unit,
         p_timeseries_data => l_dep_ts,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => p_version_date,
         p_office_id       => p_ts_office_id);
   end if;
end reverse_rate;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_independent(
   p_independent in out nocopy double_tab_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_rating_spec     rating_spec_t;
   l_ind_param_count pls_integer;
   l_parts           str_tab_t;
begin
   if p_independent is not null then
      l_rating_spec := rating_spec_t(p_rating_id, cwms_util.get_db_office_id(p_office_id));
      l_parts := cwms_util.split_text(l_rating_spec.template_id, separator1);
      l_parts := cwms_util.split_text(l_parts(1), separator2);
      l_parts := cwms_util.split_text(l_parts(1), separator3);
      l_ind_param_count := l_parts.count;
      if l_ind_param_count != p_independent.count then
         cwms_err.raise(
            'ERROR',
            'Rating speicification ('
            ||p_rating_id
            ||') takes '
            ||l_ind_param_count
            ||' independnet parameters, '
            ||p_independent.count
            ||' specified');
      end if;
      for i in 1..l_ind_param_count loop
         cwms_rounding.round_d_tab(p_independent(i), l_rating_spec.ind_rounding_specs(i));
      end loop;
   end if;
end round_independent;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_independent(
   p_independent in out nocopy double_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_values double_tab_tab_t;
begin
   if p_independent is not null then
      l_values := double_tab_tab_t(p_independent);
      round_independent(
         l_values,
         p_rating_id,
         p_office_id);
      p_independent := l_values(1);
   end if;
end round_independent;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_independent(
   p_independent in out nocopy tsv_array,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_values double_tab_t;
begin
   if p_independent is not null then
      l_values := double_tab_t();
      l_values.extend(p_independent.count);
      for i in 1..p_independent.count loop
         l_values(i) := p_independent(i).value;
      end loop;
      round_independent(l_values, p_rating_id, p_office_id);
      for i in 1..p_independent.count loop
         p_independent(i).value := l_values(i);
      end loop;
   end if;
end round_independent;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_independent(
   p_independent in out nocopy ztsv_array,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_values double_tab_t;
begin
   if p_independent is not null then
      l_values := double_tab_t();
      l_values.extend(p_independent.count);
      for i in 1..p_independent.count loop
         l_values(i) := p_independent(i).value;
      end loop;
      round_independent(l_values, p_rating_id, p_office_id);
      for i in 1..p_independent.count loop
         p_independent(i).value := l_values(i);
      end loop;
   end if;
end round_independent;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_one_independent(
   p_independent in out nocopy double_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_values double_tab_tab_t;
begin
   if p_independent is not null then
      l_values := double_tab_tab_t();
      l_values.extend(p_independent.count);
      for i in 1..p_independent.count loop
         l_values(i) := double_tab_t(p_independent(i));
      end loop;
      round_independent(
         l_values,
         p_rating_id,
         p_office_id);
      for i in 1..p_independent.count loop
         p_independent(i) := l_values(i)(1);
      end loop;
   end if;
end round_one_independent;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_independent(
   p_independent in out nocopy binary_double,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_values double_tab_tab_t;
begin
   if p_independent is not null then
      l_values := double_tab_tab_t(double_tab_t(p_independent));
      round_independent(l_values, p_rating_id, p_office_id);
      p_independent := l_values(1)(1);
   end if;
end round_independent;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_independent(
   p_independent in out nocopy tsv_type,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_values double_tab_tab_t;
begin
   if p_independent is not null then
      l_values := double_tab_tab_t(double_tab_t(p_independent.value));
      round_independent(l_values, p_rating_id, p_office_id);
      p_independent.value := l_values(1)(1);
   end if;
end round_independent;

--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
procedure round_independent(
   p_independent in out nocopy ztsv_type,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null)
is
   l_values double_tab_tab_t;
begin
   if p_independent is not null then
      l_values := double_tab_tab_t(double_tab_t(p_independent.value));
      round_independent(l_values, p_rating_id, p_office_id);
      p_independent.value := l_values(1)(1);
   end if;
end round_independent;


--------------------------------------------------------------------------------
-- GET_RATING_EXTENTS
--
-- Gets the min and max of each independent and depentent parameter for the
-- specified rating
--
-- p_values
--    The min and max values for each parameter.  The outer (first) dimension
--    will be 2, with the first containing min values and the second containing
--    max values.  The inner (second) dimension will be the number of independent
--    parameters for the rating plus one.  The first value will be the extent
--    for the first independent parameter, and the last value will be the extent
--    for the dependent parameter.
--
-- p_parameters
--    The names for each parameter.  The  dimension will be the number of
--    independent parameters for the rating plus one.  The first name is for the
--    first independent parameter, and the last name is for the dependent parameter.
--
-- p_units
--    The units for each parameter.  The  dimension will be the number of
--    independent parameters for the rating plus one.  The first unit is for the
--    first independent parameter, and the last unit is for the dependent parameter.
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_native_units
--    'T' to get values in units native to rating, 'F' to get database units
--
-- p_rating_time
--    The time to use in determining the rating from the rating spec - defaults
--    to the current time
--
-- p_time_zone
--    The time zone to use if p_rating_time is specified - defaults to UTC
--
-- p_office_id
--    The office id to use in determining the rating from the rating spec -
--    defaults to the session user's office
--
procedure get_rating_extents(
   p_values       out double_tab_tab_t,
   p_parameters   out str_tab_t,
   p_units        out str_tab_t,
   p_rating_id    in  varchar2,
   p_native_units in  varchar2 default 'T',
   p_rating_time  in  date     default null,
   p_time_zone    in  varchar2 default 'UTC',
   p_office_id    in  varchar2 default null)
is
   l_native_units    boolean;
   l_office_id       varchar2(16);
   l_rating_time_utc date;
   l_rating_code     number(14);
   l_effective_date  date;
   l_db_unit_code    number(14);
begin
   -----------
   -- setup --
   -----------
   l_native_units := cwms_util.is_true(p_native_units);
   if p_rating_time is null then
      l_rating_time_utc := cast(systimestamp at time zone 'UTC' as date);
   else
      l_rating_time_utc := cwms_util.change_timezone(p_rating_time, p_time_zone, 'UTC');
   end if;
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   -------------------------
   -- get the rating code --
   -------------------------
   select distinct
          rating_code,
          effective_date
     into l_rating_code,
          l_effective_date
     from cwms_v_rating
    where office_id = upper(l_office_id)
      and upper(rating_id) = upper(p_rating_id)
      and effective_date = (select max(effective_date)
                              from cwms_v_rating
                             where office_id = upper(l_office_id)
                               and upper(rating_id) = upper(p_rating_id)
                               and effective_date <= l_rating_time_utc
                           );
   ---------------------------------------
   -- get the parameter names and units --
   ---------------------------------------
   p_parameters := cwms_util.split_text(
      replace(
         cwms_util.split_text(p_rating_id, 2, separator1),
         separator2,
         separator3),
      separator3);
   if l_native_units then
      declare
         l_units varchar2(256);
      begin
         select distinct
                native_units
           into l_units
           from cwms_v_rating
          where rating_code = l_rating_code;
         p_units := cwms_util.split_text(replace(l_units, separator2, separator3), separator3);
      end;
   else
      p_units := str_tab_t();
      p_units.extend(p_parameters.count);
      for i in 1..p_parameters.count loop
         select unit_id
           into p_units(i)
           from cwms_unit
          where unit_code = cwms_util.get_db_unit_code(p_parameters(i));
      end loop;
   end if;
   ----------------------------
   -- get the rating extents --
   ----------------------------
   p_values := double_tab_tab_t();
   p_values.extend(2);
   for i in 1..2 loop
      p_values(i) := double_tab_t();
      p_values(i).extend(p_parameters.count);
   end loop;
   --------------------------
   -- get the extents info --
   --------------------------
   for rec1 in (select rips.parameter_position as pos,
                       rips.parameter_code,
                       rip.rating_ind_param_code
                  from at_rating_ind_parameter rip,
                       at_rating_ind_param_spec rips
                 where rip.rating_code = l_rating_code
                   and rips.ind_param_spec_code = rip.ind_param_spec_code
                 order by rips.parameter_position
               )
   loop
      for rec2 in (select min(ind_value) as min_ind,
                          max(ind_value) as max_ind,
                          min(dep_value) as min_dep,
                          max(dep_value) as max_dep
                    from at_rating_value
                   where rating_ind_param_code = rec1.rating_ind_param_code
                  )
      loop -- use loop for convenience, will execute only once
         if l_native_units then
            l_db_unit_code := cwms_util.get_db_unit_code(p_parameters(rec1.pos));
            p_values(1)(rec1.pos) := cwms_util.convert_units(rec2.min_ind, l_db_unit_code, p_units(rec1.pos));
            p_values(2)(rec1.pos) := cwms_util.convert_units(rec2.max_ind, l_db_unit_code, p_units(rec1.pos));
         else
            p_values(1)(rec1.pos) := rec2.min_ind;
            p_values(2)(rec1.pos) := rec2.max_ind;
         end if;
         if rec2.min_dep is not null then
            if l_native_units then
               l_db_unit_code := cwms_util.get_db_unit_code(p_parameters(rec1.pos+1));
               p_values(1)(rec1.pos+1) := cwms_util.convert_units(rec2.min_dep, l_db_unit_code, p_units(rec1.pos+1));
               p_values(2)(rec1.pos+1) := cwms_util.convert_units(rec2.max_dep, l_db_unit_code, p_units(rec1.pos+1));
            else
               p_values(1)(rec1.pos+1) := rec2.min_dep;
               p_values(2)(rec1.pos+1) := rec2.max_dep;
            end if;
         end if;
      end loop;
   end loop;

end get_rating_extents;

--------------------------------------------------------------------------------
-- GET_MIN_OPENING
--
-- Gets the minmum value of the "opening" parameter for the specified rating
-- in the specified unit.
--
-- p_rating_id
--    The rating specification to use
--
-- p_unit
--    The unit to retrieve the minimum "opening" in - defaults to the native
--    "opening" unit of the rating
--
-- p_rating_time
--    The time to use in determining the rating from the rating spec - defaults
--    to the current time
--
-- p_time_zone
--    The time zone to use if p_rating_time is specified - defaults to UTC
--
-- p_office_id
--    The office id to use in determining the rating from the rating spec -
--    defaults to the session user's office
--
function get_min_opening(
   p_rating_id   in varchar2,
   p_unit        in varchar2  default null,
   p_rating_time in  date     default null,
   p_time_zone   in  varchar2 default 'UTC',
   p_office_id   in  varchar2 default null)
   return binary_double
is
   l_values        double_tab_tab_t;
   l_parameters    str_tab_t;
   l_units         str_tab_t;
   l_opening_pos   pls_integer;
   l_min_opening   binary_double;
begin
   ----------------------------
   -- get the rating extents --
   ----------------------------
   get_rating_extents(
      l_values,
      l_parameters,
      l_units,
      p_rating_id,
      case p_unit is null
         when true  then 'T'
         when false then 'F'
      end,
      p_rating_time,
      p_time_zone,
      p_office_id);
   ------------------------------------------------------------
   -- get the minimum opening and convert units if necessary --
   ------------------------------------------------------------
   l_opening_pos := get_opening_parameter_position(cwms_util.split_text(p_rating_id, 2, separator1));
   l_min_opening := l_values(1)(l_opening_pos);
   if p_unit is not null then
      l_min_opening := cwms_util.convert_units(l_min_opening, l_units(l_opening_pos), p_unit);
   end if;
   return l_min_opening;
end get_min_opening;

--------------------------------------------------------------------------------
-- GET_MIN_OPENING2
--
-- Gets the minmum value of the "opening" parameter for the specified rating
-- in the specified unit.  The value is returned as the single element in a
-- double_tab_t table.
--
-- p_rating_id
--    The rating specification to use
--
-- p_unit
--    The unit to retrieve the minimum "opening" in - defaults to the native
--    "opening" unit of the rating
--
-- p_rating_time
--    The time to use in determining the rating from the rating spec - defaults
--    to the current time
--
-- p_time_zone
--    The time zone to use if p_rating_time is specified - defaults to UTC
--
-- p_office_id
--    The office id to use in determining the rating from the rating spec -
--    defaults to the session user's office
--
function get_min_opening2(
   p_rating_id   in varchar2,
   p_unit        in varchar2  default null,
   p_rating_time in  date     default null,
   p_time_zone   in  varchar2 default 'UTC',
   p_office_id   in  varchar2 default null)
   return double_tab_t
is
   l_result double_tab_t := double_tab_t();
begin
   l_result(1) := get_min_opening(
      p_rating_id,
      p_unit,
      p_rating_time,
      p_time_zone,
      p_office_id);

   return l_result;
end get_min_opening2;

function get_parameters_id(
   p_id in varchar2)
   return varchar
is
   l_parts str_tab_t;
   l_index integer;
begin
   l_parts := cwms_util.split_text(p_id, separator1);
   l_index := case l_parts.count
                 when 4 then 2 -- rating id
                 else 1        -- template id, or parameters id
              end;
   return l_parts(l_index);
end get_parameters_id;

function get_database_units(
   p_id in varchar2)
   return varchar2
is
   l_parts str_tab_t;
   l_pos   integer;
   l_units varchar2(128);
begin
   l_parts := cwms_util.split_text(replace(get_parameters_id(p_id), separator2, separator3), separator3);
   if l_parts.count < 2 then
      cwms_err.raise('INVALID_ITEM', p_id, 'rating specification, rating template, or parameters id');
   end if;
   for i in 1..l_parts.count loop
      begin
         l_parts(i) := cwms_util.get_default_units(l_parts(i), 'SI');
      exception
         when others then cwms_err.raise('INVALID_ITEM', l_parts(i), 'parameter');
      end;
   end loop;
   l_units := cwms_util.join_text(l_parts, separator3);
   l_pos   := instr(l_units, separator3, -1, 1);
   l_units := substr(l_units, 1, l_pos-1)||separator2||substr(l_units, l_pos+1);
   return l_units;
end get_database_units;


function get_ind_parameter_count(
   p_id in varchar2)
   return integer
is
   l_parts str_tab_t;
begin
   l_parts := cwms_util.split_text(get_parameters_id(p_id), separator2);
   if l_parts.count != 2 then
      cwms_err.raise('INVALID_ITEM', p_id, 'rating specification, rating template, or parameters id');
   end if;
   l_parts := cwms_util.split_text(l_parts(1), separator3);
   return l_parts.count;
end get_ind_parameter_count;

function get_ind_parameters(
   p_id in varchar2)
   return varchar2
is
   l_parts str_tab_t;
begin
   l_parts := cwms_util.split_text(get_parameters_id(p_id), separator2);
   if l_parts.count != 2 then
      cwms_err.raise('INVALID_ITEM', p_id, 'rating specification, rating template, or parameters id');
   end if;
   return l_parts(1);
end get_ind_parameters;

function get_ind_parameter(
   p_id       in varchar2,
   p_position in integer)
   return varchar2
is
   l_parts str_tab_t;
begin
   l_parts := cwms_util.split_text(get_parameters_id(p_id), separator2);
   if l_parts.count != 2 then
      cwms_err.raise('INVALID_ITEM', p_id, 'rating specification, rating template, or parameters id');
   end if;
   l_parts := cwms_util.split_text(l_parts(1), separator3);
   if p_position is null or p_position not between 1 and l_parts.count then
      cwms_err.raise(
         'ERROR',
         'Position '
         ||nvl(p_position, 'NULL')
         ||' is not in required range 1..'
         ||l_parts.count
         ||' for independent parameters '
         ||cwms_util.join_text(l_parts, separator3));
   end if;
   return l_parts(p_position);
end get_ind_parameter;

function get_dep_parameter(
   p_id in varchar2)
   return varchar2
is
   l_parts str_tab_t;
begin
   l_parts := cwms_util.split_text(get_parameters_id(p_id), separator2);
   if l_parts.count != 2 then
      cwms_err.raise('INVALID_ITEM', p_id, 'rating specification, rating template, or parameters id');
   end if;
   return l_parts(2);
end get_dep_parameter;


function get_elevation_positions(
   p_rating_template_id in varchar2)
   return number_tab_t

is
   l_elev_code      number(14);
   l_params         str_tab_t;
   l_elev_positions number_tab_t := number_tab_t();
begin
      select base_parameter_code
        into l_elev_code
        from cwms_base_parameter
       where base_parameter_id = 'Elev';

      l_params := cwms_util.split_text(
         cwms_util.split_text(
            replace(p_rating_template_id, separator2, separator3),
            1,
            separator1),
         separator3);
      for i in 1..l_params.count loop
         if cwms_util.get_base_param_code(l_params(i), 'T') = l_elev_code then
            l_elev_positions.extend;
            if i = l_params.count then
               l_elev_positions(l_elev_positions.count) := -1;
            else
               l_elev_positions(l_elev_positions.count) := i;
            end if;
         end if;
      end loop;
      return l_elev_positions;
end get_elevation_positions;

function get_rating_template_code(
   p_rating_template in varchar,
   p_office_id       in varchar2 default null)
   return integer
is
   l_office_code   integer;
   l_template_code integer;
   l_parts         str_tab_t;
begin
   l_parts := cwms_util.split_text(p_rating_template, '.');
   if l_parts.count != 2 then
      cwms_err.raise('INVALID_ITEM', p_rating_template, 'CWMS rating template');
   end if;
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   begin
      select template_code
        into l_template_code
        from at_rating_template
       where office_code = l_office_code
         and upper(parameters_id) = upper(l_parts(1))
         and upper(version) = upper(l_parts(2));
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS rating template',
            cwms_util.get_db_office_id(p_office_id)||'/'||l_parts(2)||'.'||l_parts(3));
   end;
end get_rating_template_code;

procedure get_spec_flags(
   p_active_flag           out varchar,
   p_auto_update_flag      out varchar,
   p_auto_activate_flag    out varchar,
   p_auto_migrate_ext_flag out varchar,
   p_rating_spec           in  varchar,
   p_office_id             in  varchar2 default null)
is
begin
      select active_flag,
             auto_update_flag,
             auto_activate_flag,
             auto_migrate_ext_flag
        into p_active_flag,
             p_auto_update_flag,
             p_auto_activate_flag,
             p_auto_migrate_ext_flag
        from at_rating_spec
       where rating_spec_code = rating_spec_t.get_rating_spec_code(p_rating_spec, p_office_id);
end get_spec_flags;

function is_spec_active(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   return l_active_flag;
end is_spec_active;

function is_auto_update(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   return l_auto_update_flag;
end is_auto_update;

function is_auto_activate(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   return l_auto_activate_flag;
end is_auto_activate;

function is_auto_migrate_ext(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   return l_auto_migrate_ext_flag;
end is_auto_migrate_ext;


procedure set_spec_flags(
   p_rating_spec           in varchar,
   p_active_flag           in varchar,
   p_auto_update_flag      in varchar,
   p_auto_activate_flag    in varchar,
   p_auto_migrate_ext_flag in varchar,
   p_office_id             in varchar2 default null)
is
   l_rating_spec_code integer;
begin
   l_rating_spec_code := rating_spec_t.get_rating_spec_code(p_rating_spec, p_office_id);
   update at_rating_spec
      set active_flag = p_active_flag,
          auto_update_flag = p_auto_update_flag,
          auto_activate_flag = p_auto_activate_flag,
          auto_migrate_ext_flag = p_auto_migrate_ext_flag
    where rating_spec_code = l_rating_spec_code;
end set_spec_flags;

procedure set_spec_active(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null)
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   if l_active_flag != upper(p_flag) then
      l_active_flag := upper(p_flag);
      set_spec_flags(
         p_rating_spec,
         l_active_flag,
         l_auto_update_flag,
         l_auto_activate_flag,
         l_auto_migrate_ext_flag,
         p_office_id);
   end if;
end set_spec_active;

procedure set_auto_update(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null)
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   if l_auto_update_flag != upper(p_flag) then
      l_auto_update_flag := upper(p_flag);
      set_spec_flags(
         p_rating_spec,
         l_active_flag,
         l_auto_update_flag,
         l_auto_activate_flag,
         l_auto_migrate_ext_flag,
         p_office_id);
   end if;
end set_auto_update;

procedure set_auto_activate(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null)
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   if l_auto_activate_flag != upper(p_flag) then
      l_auto_activate_flag := upper(p_flag);
      set_spec_flags(
         p_rating_spec,
         l_active_flag,
         l_auto_update_flag,
         l_auto_activate_flag,
         l_auto_migrate_ext_flag,
         p_office_id);
   end if;
end set_auto_activate;

procedure set_auto_migrate_ext(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null)
is
   l_active_flag           varchar2(1);
   l_auto_update_flag      varchar2(1);
   l_auto_activate_flag    varchar2(1);
   l_auto_migrate_ext_flag varchar2(1);
begin
   get_spec_flags(
      l_active_flag,
      l_auto_update_flag,
      l_auto_activate_flag,
      l_auto_migrate_ext_flag,
      p_rating_spec,
      p_office_id);

   if l_auto_migrate_ext_flag != upper(p_flag) then
      l_auto_migrate_ext_flag := upper(p_flag);
      set_spec_flags(
         p_rating_spec,
         l_active_flag,
         l_auto_update_flag,
         l_auto_activate_flag,
         l_auto_migrate_ext_flag,
         p_office_id);
   end if;
end set_auto_migrate_ext;

function is_rating_active(
   p_rating_spec    in varchar2,
   p_effective_date in date,
   p_time_zone      in varchar2,
   p_office_id      in varchar2 default null)
   return varchar2
is
   l_active_flag varchar2(1);
   l_time_zone   varchar2(28);
begin
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(cwms_util.split_text(p_rating_spec, 1, '.'), p_office_id));
   select active_flag
     into l_active_flag
     from at_rating
    where rating_spec_code = rating_spec_t.get_rating_spec_code(p_rating_spec, p_office_id)
      and effective_date = cwms_util.change_timezone(p_effective_date, l_time_zone);

   return l_active_flag;
exception
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'CWMS rating',
         '"'
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_rating_spec
         ||'@'
         ||to_char(p_effective_date, 'yyyy-mm-dd hh24:mi')
         ||l_time_zone
         ||'"');
end is_rating_active;

procedure set_rating_active(
   p_rating_spec    in varchar2,
   p_effective_date in date,
   p_time_zone      in varchar2,
   p_active_flag    in varchar2,
   p_office_id      in varchar2 default null)
is
   l_time_zone   varchar2(28);
begin
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(cwms_util.split_text(p_rating_spec, 1, '.'), p_office_id));
   update at_rating
      set active_flag = upper(p_active_flag)
    where rating_spec_code = rating_spec_t.get_rating_spec_code(p_rating_spec, p_office_id)
      and effective_date = cwms_util.change_timezone(p_effective_date, l_time_zone);
exception
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'CWMS rating',
         '"'
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_rating_spec
         ||'@'
         ||to_char(p_effective_date, 'yyyy-mm-dd hh24:mi')
         ||l_time_zone
         ||'"');
end set_rating_active;

procedure retrieve_ratings(
   p_results        out clob,
   p_date_time      out date,
   p_query_time     out integer,
   p_format_time    out integer,
   p_template_count out integer,
   p_spec_count     out integer,
   p_rating_count   out integer,
   p_names          in  varchar2,
   p_format         in  varchar2,
   p_units          in  varchar2 default null,
   p_datums         in  varchar2 default null,
   p_start          in  varchar2 default null,
   p_end            in  varchar2 default null,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   type bool_tab_t is table of boolean index by varchar(32767);
   type alts_by_spec_t is table of str_tab_t index by varchar2(32767);
   type rating_tab_tab_t is table of rating_tab_t;
   type index_rec_t is record(i integer, j integer);
   type index_tab_t is table of index_rec_t index by varchar2(32767);
   l_data                clob;
   l_format              varchar2(16);
   l_names               str_tab_t;
   l_normalized_names    str_tab_t;
   l_units               str_tab_t;
   l_datums              str_tab_t;
   l_codes               number_tab_t;
   l_start               date;
   l_start_utc           date;
   l_end                 date;
   l_end_utc             date;
   l_timezone            varchar2(28);
   l_office_id           varchar2(16);
   l_parts               str_tab_t;
   l_unit                varchar2(16);
   l_datum               varchar2(32);
   l_count               pls_integer;
   l_spec_count          pls_integer := 0;
   l_unique_spec_count   pls_integer := 0;
   l_rating_count        pls_integer := 0;
   l_unique_rating_count pls_integer := 0;
   l_rating              rating_t;
   l_templates_used      bool_tab_t;
   l_specs_used          bool_tab_t;
   l_ratings_used        bool_tab_t;
   l_ids_used            bool_tab_t;
   l_specs               rating_spec_tab_t;
   l_templates           rating_template_tab_t := rating_template_tab_t();
   l_name                varchar2(512);
   l_value               varchar2(16);
   l_xml                 xmltype;
   l_ts1                 timestamp;
   l_ts2                 timestamp;
   l_elapsed_query       interval day (0) to second (6);
   l_elapsed_format      interval day (0) to second (6);
   l_query_time          date;
   l_offices             str_tab_t;
   l_ids                 str_tab_t;
   l_descriptions        str_tab_t;
   l_alts_by_spec        alts_by_spec_t;
   l_text                varchar2(32767);
   l_crsr                sys_refcursor;
   l_indexes             index_tab_t;
   l_ratings             rating_tab_tab_t;
   l_max_size            integer;
   l_max_time            interval day (0) to second (3);
   l_max_size_msg        varchar2(17) := 'MAX SIZE EXCEEDED';
   l_max_time_msg        varchar2(17) := 'MAX TIME EXCEEDED';
   exc_null_object       exception;
   pragma exception_init(exc_null_object, -30625);

   function iso_duration(
      p_intvl in dsinterval_unconstrained)
      return varchar2
   is
      l_hours   integer := extract(hour   from p_intvl);
      l_minutes integer := extract(minute from p_intvl);
      l_seconds number  := extract(second from p_intvl);
      l_iso     varchar2(17) := 'PT';
   begin
      if l_hours > 0 then
         l_iso := l_iso || l_hours || 'H';
      end if;
      if l_minutes > 0 then
         l_iso := l_iso || l_minutes || 'M';
      end if;
      if l_seconds > 0 then
         l_iso := l_iso || trim(to_char(l_seconds, '90.999')) || 'S';
      end if;
      if l_iso = 'PT' then
         l_iso := l_iso || '0S';
      end if;
      return l_iso;
   end;

   function gather_alternate_specs(
      p_rating_spec_codes in number_tab_t)
      return alts_by_spec_t
   is
      l_names      str_tab_t := str_tab_t();
      l_alternates str_tab_t;
      l_last_code  integer := 0;
      l_specs      alts_by_spec_t;
   begin
      for rec in (
         select distinct
                office_id||'/'||rating_id as rating_id,
                rating_spec_code
           from av_rating_spec
          where rating_spec_code in (select distinct * from table(p_rating_spec_codes))
          order by rating_spec_code
                 )
      loop
         if rec.rating_spec_code != l_last_code then
            if l_last_code != 0 then
               for i in 1..l_names.count loop
                  select cwms_util.split_text(column_value, 2, '/')
                    bulk collect
                    into l_alternates
                    from table(l_names)
                   where column_value != l_names(i);
                  l_specs(l_names(i)) := l_alternates;
               end loop;
            end if;
            l_names.delete;
         end if;
         l_names.extend;
         l_names(l_names.count) := rec.rating_id;
         l_last_code := rec.rating_spec_code;
      end loop;
      return l_specs;
   end;

begin
   l_query_time := cast(systimestamp at time zone 'UTC' as date);

   l_max_size := to_number(cwms_properties.get_property('CWMS-RADAR', 'results.max-size', '5242880', 'CWMS')); -- 5 MB default
   l_max_time := to_dsinterval(cwms_properties.get_property('CWMS-RADAR', 'query.max-time', '00 00:00:30', 'CWMS')); -- 30 sec default
   ----------------------------
   -- process the parameters --
   ----------------------------
   -----------
   -- names --
   -----------
   if p_names is not null then
      l_names := cwms_util.split_text(p_names, '|');
      l_normalized_names := str_tab_t();
      l_normalized_names.extend(l_names.count);
      for i in 1..l_names.count loop
         l_names(i) := trim(l_names(i));
         l_normalized_names(i) := cwms_util.normalize_wildcards(upper(l_names(i)));
      end loop;
   end if;
   ------------
   -- format --
   ------------
   if p_format is null then
      l_format := 'TAB';
   else
      l_format := upper(trim(p_format));
      if l_format not in ('TAB','CSV','XML','JSON') then
         cwms_err.raise('INVALID_ITEM', l_format, 'rating response format');
      end if;
   end if;
   ------------
   -- office --
   ------------
   if p_office_id is null then
      l_office_id := '*';
   else
      begin
         l_office_id := upper(trim(p_office_id));
         select office_id into l_office_id from cwms_office where office_id = l_office_id;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_OFFICE_ID', l_office_id);
      end;
   end if;
   if l_names is not null then
      -----------
      -- units --
      -----------
      if p_units is null then
         l_units := str_tab_t();
         l_units.extend(l_names.count);
         for i in 1..l_units.count loop
            l_units(i) := 'NATIVE';
         end loop;
      else
         l_units := cwms_util.split_text(p_units, '|');
         for i in 1..l_units.count loop
            l_units(i) := upper(trim(l_units(i)));
            if l_units(i) not in  ('NATIVE', 'EN', 'SI') then
               cwms_err.raise('ERROR', 'Expected unit specification of NATIVE, EN, or SI, got '||l_units(i));
            end if;
         end loop;
         l_count := l_units.count - l_names.count;
         if l_count > 0 then
            l_units.trim(l_count);
         elsif l_count < 0 then
            l_unit := l_units(l_units.count);
            l_count := -l_count;
            l_units.extend(l_count);
            for i in 1..l_count loop
               l_units(l_units.count - i + 1) := l_unit;
            end loop;
         end if;
      end if;
      ------------
      -- datums --
      ------------
      if p_datums is null then
         l_datums := str_tab_t();
         l_datums.extend(l_names.count);
         for i in 1..l_datums.count loop
            l_datums(i) := 'NATIVE';
         end loop;
      else
         l_datums := cwms_util.split_text(p_datums, '|');
         for i in 1..l_datums.count loop
            l_datums(i) := trim(l_datums(i));
            if upper(l_datums(i)) in ('NATIVE', 'NAVD88', 'NGVD29') then
               l_datums(i) := upper(l_datums(i));
            else
               cwms_err.raise('INVALID_ITEM', l_datums(i), 'rating response datum');
            end if;
         end loop;
         l_count := l_datums.count - l_names.count;
         if l_count > 0 then
            l_datums.trim(l_count);
         elsif l_count < 0 then
            l_datum := l_datums(l_datums.count);
            l_count := -l_count;
            l_datums.extend(l_count);
            for i in 1..l_count loop
               l_datums(l_datums.count - i + 1) := l_datum;
            end loop;
         end if;
      end if;
   end if;
   -----------------
   -- time window --
   -----------------
   if p_timezone is null then
      l_timezone := 'UTC';
   else
         l_timezone := cwms_util.get_time_zone_name(trim(p_timezone));
         if l_timezone is null then
            cwms_err.raise('INVALID_ITEM', p_timezone, 'CWMS time zone name');
         end if;
      end if;
      if p_end is null then
      l_end_utc := sysdate;
      l_end     := cwms_util.change_timezone(l_end_utc, 'UTC', l_timezone);
      else
      l_end     := cast(from_tz(cwms_util.to_timestamp(p_end), l_timezone) as date);
      l_end_utc := cwms_util.change_timezone(l_end, l_timezone, 'UTC');
      end if;
      if p_start is null then
         l_start := l_end - 1;
      l_start_utc := l_end_utc - 1;
      else
      l_start     := cast(from_tz(cwms_util.to_timestamp(p_start), l_timezone) as date);
      l_start_utc := cwms_util.change_timezone(l_start, l_timezone, 'UTC');
   end if;

   begin
      if l_names is null then
         ----------------------------------
         -- retrieve rating spec catalog --
         ----------------------------------
         l_ts1 := systimestamp;

         select distinct
                rs.office_id,
                rs.rating_id,
                rs.description,
                rs.rating_spec_code
           bulk collect
           into l_offices,
                l_ids,
                l_descriptions,
                l_codes
           from av_rating_spec rs,
                av_rating r,
                at_rating_spec trs,
                at_physical_location pl,
                at_base_location bl
          where rs.office_id = case when l_office_id = '*' then rs.office_id else l_office_id end
            and trs.rating_spec_code = rs.rating_spec_code
            and pl.location_code = trs.rating_spec_code
            and pl.active_flag = 'T'
            and bl.base_location_code = pl.base_location_code
            and bl.active_flag = 'T'
            and rs.active_flag = 'T'
            and r.rating_spec_code = rs.rating_spec_code
            and r.active_flag = 'T'
            and r.parent_rating_code is null
            and (r.effective_date >= l_start_utc
                 or rs.date_methods like '%,NEXT'
                 or rs.date_methods like '%,NEAREST'
                )
            and (r.effective_date <= l_end_utc
                 or rs.date_methods like '%,PREVIOUS'
                 or rs.date_methods like '%,NEAREST'
                )
           order by rs.office_id, rs.rating_id;

         l_spec_count := l_ids.count;

         select count(distinct column_value)
           into l_unique_spec_count
           from table(l_codes);

         l_alts_by_spec := gather_alternate_specs(l_codes);

         l_ts2 := systimestamp;
         l_elapsed_query := l_ts2 - l_ts1;
         if l_elapsed_query > l_max_time then
            cwms_err.raise('ERROR', l_max_time_msg);
         end if;
         l_ts1 := systimestamp;

         dbms_lob.createtemporary(l_data, true);
         case
         -----------------
         -- XML catalog --
         -----------------
         when l_format = 'XML' then
            cwms_util.append(
               l_data,
               '<?xml version="1.0" encoding="windows-1252"?><ratings-catalog><!-- Catalog of ratings that are effective at some point between '
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||' and '
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||' -->');
            for i in 1..l_ids.count loop
               cwms_util.append(
                  l_data,
                  '<rating><office>'
                  ||l_offices(i)
                  ||'</office><name>'
                  ||dbms_xmlgen.convert(l_ids(i), dbms_xmlgen.entity_encode)
                  ||'</name>');
               l_text := l_offices(i)||'/'||l_ids(i);
               if l_alts_by_spec.exists(l_text) and l_alts_by_spec(l_text).count > 0 then
                  cwms_util.append(l_data, '<alternate-names>');
                  for j in 1..l_alts_by_spec(l_text).count loop
                     cwms_util.append(
                        l_data,
                        '<name>'
                        ||dbms_xmlgen.convert(l_alts_by_spec(l_text)(j), dbms_xmlgen.entity_encode)
                        ||'</name>');
                  end loop;
                  cwms_util.append(l_data, '</alternate-names>');
               end if;
               cwms_util.append(
                  l_data,
                  '<description>'
                  ||dbms_xmlgen.convert(l_descriptions(i), dbms_xmlgen.entity_encode)
                  ||'</description></rating>');
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
            cwms_util.append(l_data, '</ratings-catalog>');
         when l_format = 'JSON' then
            ------------------
            -- JSON catalog --
            ------------------
            cwms_util.append(
            l_data,
            '{"ratings-catalog":{"comment":"Catalog of ratings that are effective at some point between '
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||' and '
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||'","ratings":[');
            for i in 1..l_ids.count loop
               cwms_util.append(
                  l_data,
                  case i when 1 then '{"office":"' else ',{"office":"' end
                  ||l_offices(i)
                  ||'","name":"'
                  ||l_ids(i)
                  ||'"');
               l_text := l_offices(i)||'/'||l_ids(i);
               if l_alts_by_spec.exists(l_text) and l_alts_by_spec(l_text).count > 0 then
                  cwms_util.append(l_data, ',"alternate-names":[');
                  for j in 1..l_alts_by_spec(l_text).count loop
                     cwms_util.append(
                        l_data,
                        case when j = 1 then '"' else ',"' end
                        ||l_alts_by_spec(l_text)(j)
                        ||'"');
                  end loop;
                  cwms_util.append(l_data, ']');
               end if;
               cwms_util.append(
                  l_data,
                  ',"description":"'
                  ||replace(l_descriptions(i), '"', '\"')
                  ||'"}');
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
               end loop;
            cwms_util.append(l_data, ']}}');
         when l_format in ('TAB', 'CSV') then
            ------------------------
            -- TAB or CSV catalog --
            ------------------------
            cwms_util.append(l_data, '#Catalog of ratings that are effective at some point between '||l_start||' and '||l_end||' '||l_timezone||chr(10));
            cwms_util.append(l_data, '#Office'||chr(9)||'Name'||chr(9)||'Description'||chr(9)||'Alternate Names'||chr(10));
            for i in 1..l_ids.count loop
               cwms_util.append(l_data, l_offices(i)||chr(9)||l_ids(i)||chr(9)||l_descriptions(i));
               l_text := l_offices(i)||'/'||l_ids(i);
               if l_alts_by_spec.exists(l_text) and l_alts_by_spec(l_text).count > 0 then
                  cwms_util.append(l_data, chr(9)||cwms_util.join_text(l_alts_by_spec(l_text), chr(9)));
               end if;
               cwms_util.append(l_data, chr(10));
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
         end case;

         p_template_count := 0;
         p_spec_count     := l_spec_count;
         p_rating_count   := 0;
      else
         --------------------------------
         -- retrieve specified ratings --
         --------------------------------
         l_ts1 := systimestamp;
         ----------------------
         -- retrieve ratings --
         ----------------------
         l_ratings := rating_tab_tab_t();
         l_ratings.extend(l_names.count);
         l_codes := number_tab_t();
         l_codes.extend(3);
         for i in 1..l_names.count loop
            l_name := l_names(i);
            l_ratings(i) := retrieve_eff_ratings_obj_f(l_names(i), l_start_utc, l_end_utc, 'UTC', l_office_id);
            l_rating_count := l_rating_count + l_ratings(i).count;
            for j in 1..l_ratings(i).count loop
               begin
                  select distinct
                         r.rating_code,
                         r.rating_spec_code,
                         r.template_code
                    into l_codes(1),
                         l_codes(2),
                         l_codes(3)
                    from av_rating r,
                         at_rating_spec rs,
                         at_physical_location pl,
                         at_base_location bl
                   where r.office_id = l_ratings(i)(j).office_id
                     and r.rating_id = l_ratings(i)(j).rating_spec_id
                     and r.effective_date = l_ratings(i)(j).effective_date
                     and r.active_flag = 'T'
                     and rs.rating_spec_code = r.rating_spec_code
                     and rs.active_flag = 'T'
                     and pl.location_code = rs.location_code
                     and pl.active_flag = 'T'
                     and bl.base_location_code = pl.base_location_code
                     and bl.active_flag = 'T';
               exception
                  when no_data_found then
                     begin
                        select distinct
                               tr.transitional_rating_code,
                               tr.rating_spec_code,
                               rt.template_code
                          into l_codes(1),
                               l_codes(2),
                               l_codes(3)
                          from av_loc2 l,
                               at_transitional_rating tr,
                               at_rating_spec rs,
                               at_rating_template rt
                         where l.db_office_id = l_ratings(i)(j).office_id
                           and l.active_flag = 'T'
                           and l.base_loc_active_flag = 'T'
                           and rs.location_code = l.location_code
                           and rs.active_flag = 'T'
                           and rt.template_code = rs.template_code
                           and tr.rating_spec_code = rs.rating_spec_code
                           and tr.active_flag = 'T'
                           and l.location_id||'.'||rt.parameters_id||'.'||rt.version||'.'||rs.version = l_ratings(i)(j).rating_spec_id
                           and tr.effective_date = l_ratings(i)(j).effective_date;
                     exception
                        when no_data_found then
                           begin
                              select distinct
                                     vr.virtual_rating_code,
                                     vr.rating_spec_code,
                                     rt.template_code
                                into l_codes(1),
                                     l_codes(2),
                                     l_codes(3)
                                from av_loc2 l,
                                     at_virtual_rating vr,
                                     at_rating_spec rs,
                                     at_rating_template rt
                               where l.db_office_id = l_ratings(i)(j).office_id
                                 and l.active_flag = 'T'
                                 and l.base_loc_active_flag = 'T'
                                 and rs.location_code = l.location_code
                                 and rs.active_flag = 'T'
                                 and rt.template_code = rs.template_code
                                 and vr.rating_spec_code = rs.rating_spec_code
                                 and vr.active_flag = 'T'
                                 and l.location_id||'.'||rt.parameters_id||'.'||rt.version||'.'||rs.version = l_ratings(i)(j).rating_spec_id
                                 and vr.effective_date = l_ratings(i)(j).effective_date;
                           exception
                              when no_data_found then continue;
                           end;
                     end;
               end;
               l_ratings_used(l_codes(1)) := true;
               l_specs_used(l_codes(2)) := true;
               l_templates_used(l_codes(3)) := true;
               l_text :=
                  l_ratings(i)(j).office_id
                  ||'/'
                  ||l_ratings(i)(j).rating_spec_id
                  ||'/'
                  ||to_char(l_ratings(i)(j).effective_date, 'yyyy-mm-dd"T"hh24:mi');
               l_indexes(l_text).i := i;
               l_indexes(l_text).j := j;
            end loop;
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
         end loop;
         l_unique_rating_count := l_ratings_used.count;

         -----------------------------
         -- retrieve specifications --
         -----------------------------
         l_codes := number_tab_t();
         l_codes.extend(l_specs_used.count);
         for i in 1..l_codes.count loop
            l_codes(i) := case i when 1 then l_specs_used.first else l_specs_used.next(l_codes(i-1)) end;
         end loop;
         l_ids_used.delete;
         for i in 1..l_names.count loop
            select office_id||'/'||rating_id
              bulk collect
              into l_ids
              from av_rating_spec
             where rating_spec_code in (select * from table(l_codes))
               and upper(rating_id) like l_normalized_names(i) escape '\';
            for j in 1..l_ids.count loop
               l_ids_used(l_ids(j)) := true;
            end loop;
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
         end loop;

         l_specs := rating_spec_tab_t();
         l_specs.extend(l_ids_used.count);
         for i in 1..l_ids_used.count loop
            l_text := case i when 1 then l_ids_used.first else l_ids_used.next(l_text) end;
            l_parts := cwms_util.split_text(l_text, '/');
            l_specs(i) := cwms_rating.retrieve_specs_obj_f(l_parts(2), l_parts(1))(1);
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
         end loop;
         l_spec_count := l_specs.count;
         l_unique_spec_count := l_specs_used.count;
         l_alts_by_spec := gather_alternate_specs(l_codes);

         ----------------------------
         -- retrieve the templates --
         ----------------------------
         l_codes := number_tab_t();
         l_codes.extend(l_templates_used.count);
         for i in 1..l_codes.count loop
            l_codes(i) := case i when 1 then l_templates_used.first else l_templates_used.next(l_codes(i-1)) end;
         end loop;
         l_ids_used.delete;
         for i in 1..l_names.count loop
            select office_id||'/'||template_id
              bulk collect
              into l_ids
              from av_rating_spec
             where template_code in (select * from table(l_codes))
               and upper(rating_id) like l_normalized_names(i) escape '\';

            for j in 1..l_ids.count loop
               l_ids_used(l_ids(j)) := true;
            end loop;
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
         end loop;

         l_templates := rating_template_tab_t();
         l_templates.extend(l_ids_used.count);
         for i in 1..l_ids_used.count loop
            l_text := case i when 1 then l_ids_used.first else l_ids_used.next(l_text) end;
            l_parts := cwms_util.split_text(l_text, '/');
            l_templates(i) := cwms_rating.retrieve_templates_obj_f(l_parts(2), l_parts(1))(1);
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
         end loop;

         l_ts2 := systimestamp;
         l_elapsed_query := l_ts2 - l_ts1;

         l_ts1 := systimestamp;
         -----------------------------------
         -- format the ratings for output --
         -----------------------------------
         dbms_lob.createtemporary(l_data, true);
         cwms_util.append(l_data, '<ratings>');
         for i in 1..l_templates.count loop
            cwms_util.append(l_data, l_templates(i).to_clob);
         end loop;
         for i in 1..l_specs.count loop
            cwms_util.append(l_data, l_specs(i).to_clob);
         end loop;
         l_text := l_indexes.first;
         loop
            exit when l_text is null;
               cwms_util.append(
                  l_data,
                  l_ratings(l_indexes(l_text).i)(l_indexes(l_text).j).to_clob(
                     p_timezone   => l_timezone,
                     p_units      => l_units(l_indexes(l_text).i),
                     p_vert_datum => l_datums(l_indexes(l_text).i)));
            l_text := l_indexes.next(l_text);
            if dbms_lob.getlength(l_data) > l_max_size then
               cwms_err.raise('ERROR', l_max_size_msg);
            end if;
         end loop;

         cwms_util.append(l_data, '</ratings>');
         l_xml := xmltype(l_data);
         dbms_lob.createtemporary(l_data, true);
         case
         when l_format = 'XML' then
            --------------
            -- XML data --
            --------------
            select xmlserialize(content l_xml.transform(xmltype(cwms_text.retrieve_text('/XSLT/RATINGS_V1_TO_RADAR_XML', 'CWMS'))) no indent) into l_data from dual;
            if l_data = '<ratings/>' then
               l_data := '<ratings></ratings>'; -- give a place for the query info
            end if;
         when l_format = 'JSON' then
            ---------------
            -- JSON data --
            ---------------
            begin
               l_data := l_xml.transform(xmltype(cwms_text.retrieve_text('/XSLT/RATINGS_V1_TO_RADAR_JSON', 'CWMS'))).extract('/ratings/text()').getclobval;
               l_data := dbms_xmlgen.convert(l_data, dbms_xmlgen.entity_decode);
               l_data := replace(l_data, '{,', '{');
               l_data := replace(l_data, '[,', '[');
               l_data := replace(l_data, '""', 'null');
            exception
               when exc_null_object then
                  l_data := '{"ratings":{"rating-templates":[],"rating-specs":[],"ratings":[]}}';
            end;
         when l_format in ('TAB', 'CSV') then
            ---------------------
            -- TAB or CSV data --
            ---------------------
            begin
               l_data := l_xml.transform(xmltype(cwms_text.retrieve_text('/XSLT/RATINGS_V1_TO_RADAR_TAB', 'CWMS'))).extract('/ratings/text()').getclobval;
               l_data := dbms_xmlgen.convert(l_data, dbms_xmlgen.entity_decode);
            exception
               when exc_null_object then
                  l_data := chr(10)||chr(10);
            end;
            if l_format = 'CSV' then
               l_data := cwms_util.tab_to_csv(l_data);
            end if;
         end case;
         if dbms_lob.getlength(l_data) > l_max_size then
            cwms_err.raise('ERROR', l_max_size_msg);
         end if;
         p_template_count := cwms_util.get_xml_nodes(l_xml, '/ratings/rating-template').count;
         p_spec_count     := cwms_util.get_xml_nodes(l_xml, '/ratings/rating-spec').count;
         p_rating_count   := cwms_util.get_xml_nodes(l_xml, 'ratings/*', 'contains(name(.), "-rating")').count;
      end if;

      l_ts2 := systimestamp;
      l_elapsed_format := l_ts2 - l_ts1;
   exception
      when others then
         case
         when instr(sqlerrm, l_max_time_msg) > 0 then
            dbms_lob.createtemporary(l_data, true);
            case l_format
            when  'XML' then
               cwms_util.append(l_data, '<ratings><error>Query exceeded maximum time of '||l_max_time||'</error></ratings>');
            when 'JSON' then
               cwms_util.append(l_data, '{"ratings":{"error":"Query exceeded maximum time of '||l_max_time||'"}}');
            when 'TAB' then
               cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum time of '||l_max_time||chr(10));
            when 'CSV' then
               cwms_util.append(l_data, 'ERROR,Query exceeded maximum time of '||l_max_time||chr(10));
            end case;
         when instr(sqlerrm, l_max_size_msg) > 0 then
            dbms_lob.createtemporary(l_data, true);
            case l_format
            when  'XML' then
               cwms_util.append(l_data, '<ratings><error>Query exceeded maximum size of '||l_max_size||' characters</error></ratings>');
            when 'JSON' then
               cwms_util.append(l_data, '{"ratings":{"error":"Query exceeded maximum size of '||l_max_size||' characters"}}');
            when 'TAB' then
               cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
            when 'CSV' then
               cwms_util.append(l_data, 'ERROR,Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
            end case;
         else
            dbms_lob.createtemporary(l_data, true);
            case l_format
            when  'XML' then
               cwms_util.append(l_data, '<ratings><error>['||l_name||'] '||sqlerrm||'</error></ratings>');
            when 'JSON' then
               cwms_util.append(l_data, '{"ratings":{"error":"['||l_name||'] '||sqlerrm||'"}}');
            when 'TAB' then
               cwms_util.append(l_data, 'ERROR'||chr(9)||'['||l_name||'] '||dbms_utility.format_error_backtrace||chr(10));
            when 'CSV' then
               cwms_util.append(l_data, 'ERROR,"||['||l_name||'] '||sqlerrm||'"'||chr(10));
            end case;
         end case;
   end;

   declare
      l_data2 clob;
   begin
      dbms_lob.createtemporary(l_data2, true);
      l_name := cwms_util.get_db_name;
   case
   when l_format = 'XML' then
      cwms_util.append(
         l_data2,
         '<query-info><time-of-query>'
         ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
         ||'Z</time-of-query><process-query>'
         ||iso_duration(l_elapsed_query)
         ||'</process-query><format-output>'
         ||iso_duration(l_elapsed_format)
         ||'</format-output><requested-format>'
         ||l_format
         ||'</requested-format><requested-office>'
         ||l_office_id
         ||'</requested-office><requested-start-time>'
         ||cwms_util.get_xml_time(l_start, l_timezone)
         ||'</requested-start-time><requested-end-time>'
         ||cwms_util.get_xml_time(l_end, l_timezone)
         ||'</requested-end-time>');
         if l_names is null then
            cwms_util.append(
               l_data2,
               '<total-specifications-catloged>'
               ||l_spec_count
               ||'</total-specifications-catloged><unique-specifications-catloged>'
               ||l_unique_spec_count
               ||'</unique-specifications-catloged></query-info>');
         else
            for i in 1..l_names.count loop
               cwms_util.append(
                  l_data2,
                  '<requested-item><name>'
                  ||l_names(i)
                  ||'</name><unit>'
                  ||l_units(i)
                  ||'</unit><datum>'
                  ||l_datums(i)
                  ||'</datum></requested-item>');
            end loop;
            cwms_util.append(
               l_data2,
               '<templates-retrieved>'
               ||l_templates.count
               ||'</templates-retrieved><total-specifications-retrieved>'
               ||l_spec_count
               ||'</total-specifications-retrieved><unique-specifications-retrieved>'
               ||l_unique_spec_count
               ||'</unique-specifications-retrieved><total-ratings-retrieved>'
               ||l_rating_count
               ||'</total-ratings-retrieved><unique-ratings-retrieved>'
               ||l_unique_rating_count
               ||'</unique-ratings-retrieved></query-info>');
         end if;
      l_data := regexp_replace(l_data, '^((<\?xml .+?\?>)?(<ratings.*?>))', '\1'||l_data2, 1, 1);
      p_results := l_data;
   when l_format = 'JSON' then
      cwms_util.append(
         l_data2,
         '{"query-info":{"time-of-query":"'
         ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
         ||'Z","process-query":"'
         ||iso_duration(l_elapsed_query)
         ||'","format-output":"'
         ||iso_duration(l_elapsed_format)
         ||'","requested-format":"'
         ||l_format
         ||'","requested-office":"'
         ||l_office_id
         ||'","requested-start-time":"'
         ||cwms_util.get_xml_time(l_start, l_timezone)
         ||'","requested-end-time":"'
         ||cwms_util.get_xml_time(l_end, l_timezone)
         ||'"');
      if l_names is null then
         cwms_util.append(
            l_data2,
            ',"total-specifications-cataloged":'
            ||l_spec_count
            ||',"unique-specifications-cataloged":'
            ||l_unique_spec_count
            ||'},');
      else
         cwms_util.append(l_data2, ',"requested-items":[');
         for i in 1..l_names.count loop
            cwms_util.append(
               l_data2,
               case
               when i = 1 then '{"name":"'
               else ',{"name":"'
               end
               ||l_names(i)
               ||'","unit":"'
               ||l_units(i)
               ||'","datum":"'
               ||l_datums(i)
               ||'"}');
         end loop;
         cwms_util.append(
            l_data2,
            '],"templates-retrieved":'
            ||l_templates.count
            ||',"total-specifications-retrieved":'
            ||l_spec_count
            ||',"unique-specifications-retrieved":'
            ||l_unique_spec_count
            ||',"total-ratings-retrieved":'
            ||l_rating_count
            ||',"unique-ratings-retrieved":'
            ||l_unique_rating_count
            ||'},');
      end if;
      l_data := regexp_replace(l_data, '^({"rating.*?":){', '\1'||l_data2, 1, 1);
      p_results := l_data;
   when l_format in ('TAB', 'CSV') then
      cwms_util.append(l_data2, '#Processed At'||chr(9)||utl_inaddr.get_host_name ||':'||l_name||chr(10));
      cwms_util.append(l_data2, '#Time Of Query'||chr(9)||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||chr(10));
      cwms_util.append(l_data2, '#Process Query'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' milliseconds'||chr(10));
      cwms_util.append(l_data2, '#Format Output'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' milliseconds'||chr(10));
      cwms_util.append(l_data2, '#Requested Format'||chr(9)||l_format||chr(10));
      cwms_util.append(l_data2, '#Requested Office'||chr(9)||l_office_id||chr(10));
      cwms_util.append(l_data2, '#Requested Start Time'||chr(9)||to_char(l_start, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
      cwms_util.append(l_data2, '#Requested End Time'||chr(9)||to_char(l_end, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
      if l_names is null then
         cwms_util.append(l_data2, '#Total Specifications Cataloged'||chr(9)||l_spec_count||chr(10));
         cwms_util.append(l_data2, '#Unique Specifications Cataloged'||chr(9)||l_unique_spec_count||chr(10)||chr(10));
      else
         cwms_util.append(l_data2, '#Requested Names'    ||chr(9)||cwms_util.join_text(l_names, chr(9))||chr(10));
         cwms_util.append(l_data2, '#Requested Units'    ||chr(9)||cwms_util.join_text(l_units, chr(9))||chr(10));
         cwms_util.append(l_data2, '#Requested Datums'   ||chr(9)||cwms_util.join_text(l_datums, chr(9))||chr(10));
         cwms_util.append(l_data2, '#Templates Retrieved'||chr(9)||l_templates.count||chr(10));
         cwms_util.append(l_data2, '#Total Specifications Retrieved'||chr(9)||l_spec_count||chr(10));
         cwms_util.append(l_data2, '#Unique Specifications Retrieved'||chr(9)||l_unique_spec_count||chr(10));
         cwms_util.append(l_data2, '#Total Ratings Retrieved'||chr(9)||l_rating_count||chr(10));
         cwms_util.append(l_data2, '#Unique Ratings Retrieved'||chr(9)||l_unique_rating_count||chr(10));
      end if;
      if l_format = 'CSV' then
         l_data2 := cwms_util.tab_to_csv(l_data2);
      end if;
      cwms_util.append(l_data2, l_data);
      p_results := l_data2;
   end case;
   end;

   p_date_time      := l_query_time;
   p_query_time     := trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)));
   p_format_time    := trunc(1000 * (extract(minute from l_elapsed_format) *60 +  extract(second from l_elapsed_format)));
end retrieve_ratings;




function retrieve_ratings_f(
   p_names     in varchar2,
   p_format    in varchar2,
   p_units     in varchar2 default null,
   p_datums    in varchar2 default null,
   p_start     in varchar2 default null,
   p_end       in varchar2 default null,
   p_timezone  in varchar2 default null,
   p_office_id in varchar2 default null)
   return clob
is
   l_results        clob;
   l_date_time      date;
   l_query_time     integer;
   l_format_time    integer;
   l_template_count integer;
   l_spec_count     integer;
   l_rating_count   integer;
begin
   retrieve_ratings(
      l_results,
      l_date_time,
      l_query_time,
      l_format_time,
      l_template_count,
      l_spec_count,
      l_rating_count,
      p_names,
      p_format,
      p_units,
      p_datums,
      p_start,
      p_end,
      p_timezone,
      p_office_id);

   return l_results;
end retrieve_ratings_f;

function package_log_property_text
   return varchar2
is
begin
   return v_package_log_prop_text;
end package_log_property_text;

procedure set_package_log_property_text(
   p_text in varchar2 default null)
is
begin
   v_package_log_prop_text := nvl(p_text, sys_context('userenv', 'sid'));
end set_package_log_property_text;

end cwms_rating;
/
show errors;

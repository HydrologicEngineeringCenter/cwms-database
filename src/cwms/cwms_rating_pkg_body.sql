create or replace package body cwms_rating
as


function get_rating_method_code(
   p_rating_method_id in varchar2)
   return number result_cache
is
   l_code number(10);
begin
   select rating_method_code
     into l_code
     from cwms_rating_method
    where rating_method_id = upper(p_rating_method_id);

   return l_code;
end get_rating_method_code;

procedure delete_rating_ind_parameter(
   p_rating_ind_param_code in number)
is
begin
   -----------------------------
   -- first the rating values --
   -----------------------------
   for rec in
      (  select dep_rating_ind_param_code,
                note_code
           from at_rating_value
          where rating_ind_param_code = p_rating_ind_param_code
            and (note_code is not null or dep_rating_ind_param_code is not null)
      )
   loop
      if rec.note_code is not null then
         delete
           from at_rating_value_note
          where note_code = rec.note_code;
      end if;
      if rec.dep_rating_ind_param_code is not null then
         delete_rating_ind_parameter(rec.dep_rating_ind_param_code);
      end if;
   end loop;
   delete
     from at_rating_value
    where rating_ind_param_code = p_rating_ind_param_code
       or dep_rating_ind_param_code = p_rating_ind_param_code;
   --------------------------------------
   -- then the rating extension values --
   --------------------------------------
   for rec in
      (  select dep_rating_ind_param_code,
                note_code
           from at_rating_extension_value
          where rating_ind_param_code = p_rating_ind_param_code
            and (note_code is not null or dep_rating_ind_param_code is not null)
      )
   loop
      if rec.note_code is not null then
         delete
           from at_rating_value_note
          where note_code = rec.note_code;
      end if;
      if rec.dep_rating_ind_param_code is not null then
         delete_rating_ind_parameter(rec.dep_rating_ind_param_code);
      end if;
      delete_rating_ind_parameter(rec.dep_rating_ind_param_code);
   end loop;
   delete
     from at_rating_extension_value
    where rating_ind_param_code = p_rating_ind_param_code
       or dep_rating_ind_param_code = p_rating_ind_param_code;
   -------------------------------
   -- finally the record itself --
   -------------------------------
   delete
     from at_rating_ind_parameter
    where rating_ind_param_code = p_rating_ind_param_code;
end delete_rating_ind_parameter;

procedure delete_rating(
   p_rating_code in number)
is
begin
   --------------------
   -- simple ratings --
   --------------------
   for i in 1..1 loop
      ----------------------------
      -- first the rating table --
      ----------------------------
      for rec in
         (  select rating_ind_param_code
              from at_rating_ind_parameter
             where rating_code = p_rating_code
         )
      loop
         delete_rating_ind_parameter(rec.rating_ind_param_code);
      end loop;
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
      delete
        from at_rating
       where rating_code = p_rating_code;
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
       
end delete_rating;

procedure delete_rating_spec(
   p_rating_spec_code in number,
   p_delete_action    in varchar2 default cwms_util.delete_key)
is
begin
   dbms_output.put_line(p_delete_action);
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
         dbms_output.put_line('deleting rating '||rec.rating_code||' for spec '||p_rating_spec_code);
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
      ------------------ 
      -- rating specs --
      ------------------ 
      dbms_output.put_line('deleting rating spec'||p_rating_spec_code);
      delete
        from at_rating_spec
       where rating_spec_code = p_rating_spec_code;
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
         'cwms_rating.store_templates',
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
      ||'xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
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
   l_template_code number(10);
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
         'cwms_rating.store_specs',
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
   l_location_id_mask      varchar2(49);
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
   type codes_t is table of boolean index by pls_integer;
   l_codes                 codes_t;
   l_parts                 str_tab_t;
   l_location_id_mask      varchar2(49);
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
           from (select v.location_id,
                        rs.rating_spec_code
                   from at_rating_spec rs,
                        at_rating_template rt,
                        av_loc2 v,
                        cwms_office o
                  where v.db_office_id like upper(l_office_id_mask) escape '\'
                    and o.office_id = v.db_office_id
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                    and v.location_code = rs.location_code
                    and upper(v.location_id) like upper(l_location_id_mask) escape '\'
                    and v.unit_system = 'SI'
                  order by v.db_office_id,
                        v.location_id,
                        rt.parameters_id,
                        rt.version,
                        rs.version
                )
      )
   loop
      if not l_codes.exists(rec.rating_spec_code) then
         l_codes(rec.rating_spec_code) := true;
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
      ||'xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
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
   l_spec_code number(10);
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
   p_fail_if_exists in varchar2)
is
   l_rating        rating_t;
   l_stream_rating stream_rating_t;
   l_node          xmltype;
begin
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(p_xml, '(//rating|//simple-rating|//virtual-rating|//transitional-rating|//usgs-stream-rating)['||i||']');
      exit when l_node is null;
      if l_node.existsnode('/usgs-stream-rating') = 1 then
         cwms_msg.log_db_message(
            'cwms_rating.store_ratings',
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
         l_stream_rating.store(p_fail_if_exists);
      elsif l_node.existsnode('/rating|/simple-rating|/virtual-rating|/transitional-rating') = 1 then
         cwms_msg.log_db_message(
            'cwms_rating.store_ratings',
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
   end loop;
end store_ratings;

--------------------------------------------------------------------------------
-- STORE RATINGS
--
procedure store_ratings(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2)
is
begin
   store_ratings(xmltype(p_xml), p_fail_if_exists);
end store_ratings;

--------------------------------------------------------------------------------
-- STORE RATINGS
--
procedure store_ratings(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
begin
   store_ratings(xmltype(p_xml), p_fail_if_exists);
end store_ratings;

--------------------------------------------------------------------------------
-- STORE RATINGS
--
procedure store_ratings(
   p_ratings        in rating_tab_t,
   p_fail_if_exists in varchar2)
is
   l_ratings rating_tab_t := p_ratings;
   l_rating  rating_t;
begin
   if l_ratings is not null then
      for i in 1..l_ratings.count loop
         l_rating := treat(l_ratings(i) as rating_t);
         l_rating.store(p_fail_if_exists);
      end loop;
   end if;
end store_ratings;

--------------------------------------------------------------------------------
-- CAT_RATINGS
--
procedure cat_ratings(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
   c_default_start_date constant date := date '1700-01-01';
   c_default_end_date   constant date := cast(systimestamp at time zone 'UTC' as date);

   l_parts str_tab_t;
   l_location_id_mask      varchar2(49);
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
       where o.office_id like upper(l_office_id_mask) escape '\'
         and rt.office_code = o.office_code
         and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
         and upper(rt.version) like upper(l_template_version_mask) escape '\'
         and rs.template_code = rt.template_code
         and upper(rs.version) like upper(l_spec_version_mask) escape '\'
         and r.rating_spec_code = rs.rating_spec_code
         and pl.location_code = rs.location_code
         and bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id) like upper(l_location_id_mask) escape '\'
         and tz1.time_zone_code = nvl(pl.time_zone_code, 0)
         and tz2.time_zone_name = case
                                     when p_time_zone is null then
                                        tz1.time_zone_name
                                     else
                                        p_time_zone
                                  end
         and r.effective_date >= case
                                    when p_effective_date_start is null then
                                       c_default_start_date
                                    else
                                       cwms_util.change_timezone(p_effective_date_start, tz2.time_zone_name, 'UTC')
                                 end
         and r.effective_date <= case
                                    when p_effective_date_end is null then
                                       c_default_end_date
                                    else
                                       cwms_util.change_timezone(p_effective_date_end, tz2.time_zone_name, 'UTC')
                                 end
    order by o.office_id,
             bl.base_location_id,
             pl.sub_location_id,
             rt.parameters_id,
             rt.version,
             rs.version,
             r.effective_date nulls first;
end cat_ratings;

--------------------------------------------------------------------------------
-- CAT_RATINGS_F
--
function cat_ratings_f(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_ratings(
      l_cursor,
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);

   return l_cursor;
end cat_ratings_f;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS
--
procedure retrieve_ratings_obj(
   p_ratings              out rating_tab_t,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
   c_default_start_date constant date := date '1700-01-01';
   c_default_end_date   constant date := cast(systimestamp at time zone 'UTC' as date);

   l_parts str_tab_t;
   l_location_id_mask      varchar2(49);
   l_parameters_id_mask    varchar2(256);
   l_template_version_mask varchar2(32);
   l_spec_version_mask     varchar2(32);
   l_office_id_mask        varchar2(16) := nvl(p_office_id_mask, cwms_util.user_office_id);
   l_location_id           varchar2(49);
   l_count                 simple_integer := 0;
   l_rating                rating_t;
   l_stream_rating         stream_rating_t;
   l_elev_positions        number_tab_t;
   l_local_datum           varchar2(16);
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
   l_office_id_mask        := cwms_util.normalize_wildcards(l_office_id_mask);

   p_ratings := rating_tab_t();
   for rec in
      ( (select distinct
                location_id,
                rating_code
           from (select v.location_id,
                        r.rating_code
                   from at_rating r,
                        at_rating_spec rs,
                        at_rating_template rt,
                        av_loc2 v,
                        at_physical_location pl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2
                  where v.db_office_id like upper(l_office_id_mask) escape '\'
                    and o.office_id = v.db_office_id
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                    and r.rating_spec_code = rs.rating_spec_code
                    and v.location_code = rs.location_code
                    and upper(v.location_id) like upper(l_location_id_mask) escape '\'
                    and v.unit_system = 'SI'
                    and pl.location_code = v.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, 0)
                    and tz2.time_zone_name = case
                                                when p_time_zone is null then
                                                   tz1.time_zone_name
                                                else
                                                   p_time_zone
                                             end
                    and r.effective_date >= case
                                               when p_effective_date_start is null then
                                                  c_default_start_date
                                               else
                                                  cwms_util.change_timezone(p_effective_date_start, tz2.time_zone_name, 'UTC')
                                            end
                    and r.effective_date <= case
                                               when p_effective_date_end is null then
                                                  c_default_end_date
                                               else
                                                  cwms_util.change_timezone(p_effective_date_end, tz2.time_zone_name, 'UTC')
                                            end
                    and r.ref_rating_code is null -- don't pick up stream rating shifts and offsets
                  order by v.db_office_id,
                        v.location_id,
                        rt.parameters_id,
                        rt.version,
                        rs.version,
                        r.effective_date nulls first)
         union all               
        (select distinct
                location_id,
                rating_code
           from (select v.location_id,
                        vr.virtual_rating_code as rating_code
                   from at_virtual_rating vr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        av_loc2 v,
                        at_physical_location pl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2
                  where v.db_office_id like upper(l_office_id_mask) escape '\'
                    and o.office_id = v.db_office_id
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                    and vr.rating_spec_code = rs.rating_spec_code
                    and v.location_code = rs.location_code
                    and upper(v.location_id) like upper(l_location_id_mask) escape '\'
                    and v.unit_system = 'SI'
                    and pl.location_code = v.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, 0)
                    and tz2.time_zone_name = case
                                                when p_time_zone is null then
                                                   tz1.time_zone_name
                                                else
                                                   p_time_zone
                                             end
                    and vr.effective_date >= case
                                               when p_effective_date_start is null then
                                                  c_default_start_date
                                               else
                                                  cwms_util.change_timezone(p_effective_date_start, tz2.time_zone_name, 'UTC')
                                            end
                    and vr.effective_date <= case
                                               when p_effective_date_end is null then
                                                  c_default_end_date
                                               else
                                                  cwms_util.change_timezone(p_effective_date_end, tz2.time_zone_name, 'UTC')
                                            end
                  order by v.db_office_id,
                        v.location_id,
                        rt.parameters_id,
                        rt.version,
                        rs.version,
                        vr.effective_date nulls first))
         union all               
        (select distinct
                location_id,
                rating_code
           from (select v.location_id,
                        tr.transitional_rating_code as rating_code
                   from at_transitional_rating tr,
                        at_rating_spec rs,
                        at_rating_template rt,
                        av_loc2 v,
                        at_physical_location pl,
                        cwms_office o,
                        cwms_time_zone tz1,
                        cwms_time_zone tz2
                  where v.db_office_id like upper(l_office_id_mask) escape '\'
                    and o.office_id = v.db_office_id
                    and rt.office_code = o.office_code
                    and upper(rt.parameters_id) like upper(l_parameters_id_mask) escape '\'
                    and upper(rt.version) like upper(l_template_version_mask) escape '\'
                    and rs.template_code = rt.template_code
                    and upper(rs.version) like upper(l_spec_version_mask) escape '\'
                    and tr.rating_spec_code = rs.rating_spec_code
                    and v.location_code = rs.location_code
                    and upper(v.location_id) like upper(l_location_id_mask) escape '\'
                    and v.unit_system = 'SI'
                    and pl.location_code = v.location_code
                    and tz1.time_zone_code = nvl(pl.time_zone_code, 0)
                    and tz2.time_zone_name = case
                                                when p_time_zone is null then
                                                   tz1.time_zone_name
                                                else
                                                   p_time_zone
                                             end
                    and tr.effective_date >= case
                                               when p_effective_date_start is null then
                                                  c_default_start_date
                                               else
                                                  cwms_util.change_timezone(p_effective_date_start, tz2.time_zone_name, 'UTC')
                                            end
                    and tr.effective_date <= case
                                               when p_effective_date_end is null then
                                                  c_default_end_date
                                               else
                                                  cwms_util.change_timezone(p_effective_date_end, tz2.time_zone_name, 'UTC')
                                            end
                  order by v.db_office_id,
                        v.location_id,
                        rt.parameters_id,
                        rt.version,
                        rs.version,
                        tr.effective_date nulls first))
                )
      )
   loop
      p_ratings.extend;
      select count(*)
        into l_count
        from at_rating
       where ref_rating_code = rec.rating_code;
      if l_count = 0 then
         l_rating := rating_t(rec.rating_code);
         l_parts  := cwms_util.split_text(l_rating.rating_spec_id, separator1);
         l_location_id := l_parts(1);
         l_parts(1) := rec.location_id;
         l_elev_positions := get_elevation_positions(l_parts(2));
         if l_elev_positions is null then
            p_ratings(p_ratings.count) := l_rating;
         else
            l_local_datum := cwms_loc.get_location_vertical_datum(l_location_id, l_rating.office_id);
            if l_local_datum is null then
               p_ratings(p_ratings.count) := l_rating;
            else
               p_ratings(p_ratings.count) := vdatum_rating_t(l_rating, l_local_datum, l_elev_positions);
            end if;
         end if;
      else
         l_stream_rating := stream_rating_t(rec.rating_code);
         l_parts  := cwms_util.split_text(l_stream_rating.rating_spec_id, separator1);
         l_location_id := l_parts(1);
         l_parts(1) := rec.location_id;
         l_elev_positions := get_elevation_positions(l_parts(2));
         if l_elev_positions is null then
            p_ratings(p_ratings.count) := l_stream_rating;
         else
            if l_elev_positions = number_tab_t(1) then
               null;
            else
               cwms_err.raise(
                  'ERROR',
                  l_stream_rating.office_id
                  ||'/'
                  ||l_stream_rating.rating_spec_id
                  ||' doesn''t have ind parameter 1 as the first and only elevation parameter');
            end if;
            l_local_datum := cwms_loc.get_location_vertical_datum(l_location_id, l_stream_rating.office_id);
            if l_local_datum is null then
               p_ratings(p_ratings.count) := l_stream_rating;
            else
               p_ratings(p_ratings.count) := vdatum_stream_rating_t(l_stream_rating, l_local_datum);
            end if;
         end if;
      end if;
      p_ratings(p_ratings.count).rating_spec_id := cwms_util.join_text(l_parts, separator1);
   end loop;
end retrieve_ratings_obj;

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

procedure retreive_ratings_xml_data(
   p_templates            in out nocopy clob,
   p_specs                in out nocopy clob,
   p_ratings              in out nocopy clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_recurse              in  boolean  default true,
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
   l_spec_id_mask := cwms_util.normalize_wildcards(p_spec_id_mask);
   retrieve_ratings_obj(
      l_ratings,
      l_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);
      
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
         cwms_util.append(p_ratings, l_ratings(i).to_clob);
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
               l_spec_id_mask,
               p_effective_date_start,
               p_effective_date_end,
               p_time_zone, 
               p_recurse,
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
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_retrieve_templates   in boolean  default true,
   p_retrieve_specs       in boolean  default true,
   p_retrieve_ratings     in boolean  default true, 
   p_recurse              in boolean  default true,
   p_office_id_mask       in varchar2 default null)
   return clob
is
   type id_tab_t is table of boolean index by varchar2(32767);
   l_id            varchar2(32767);
   l_ids           id_tab_t;
   l_template_clob clob;
   l_spec_clob     clob;
   l_rating_clob   clob;  
   l_ratings       clob;
   l_xml           xmltype;
   l_xml_tab       xml_tab_t;
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
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_recurse,
      p_office_id_mask);
      
   if p_retrieve_templates then
      dbms_lob.close(l_template_clob);
   end if;
   if p_retrieve_specs then
      dbms_lob.close(l_spec_clob);
   end if;
   if p_retrieve_ratings then
      dbms_lob.close(l_rating_clob);
   end if;
   
   dbms_lob.createtemporary(l_ratings, true);
   dbms_lob.open(l_ratings, dbms_lob.lob_readwrite);
   cwms_util.append(l_ratings, '<ratings>');
   if p_retrieve_templates then
      cwms_util.append(l_ratings, l_template_clob);
   end if;
   if p_retrieve_specs then
      cwms_util.append(l_ratings, l_spec_clob);
   end if;
   if p_retrieve_ratings then
      cwms_util.append(l_ratings, l_rating_clob);
   end if;
   cwms_util.append(l_ratings, '</ratings>');
   dbms_lob.close(l_ratings);
   l_xml := xmltype(l_ratings);
   dbms_lob.createtemporary(l_ratings, true);
   dbms_lob.open(l_ratings, dbms_lob.lob_readwrite);
   cwms_util.append(l_ratings, '<?xml version="1.0" encoding="utf-8"?>');
   cwms_util.append(l_ratings, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
   if p_retrieve_templates then
      l_xml_tab := cwms_util.get_xml_nodes(l_xml,  '/ratings/rating-template');
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
      l_xml_tab := cwms_util.get_xml_nodes(l_xml,  '/ratings/rating-spec');
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
      l_xml_tab := cwms_util.get_xml_nodes(l_xml,  '/ratings/rating|/ratings/simple-rating|/ratings/usgs-stream-rating|/ratings/virtual-rating|/ratings/transitional-rating');
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
      p_spec_id_mask         => p_spec_id_mask, 
      p_effective_date_start => p_effective_date_start, 
      p_effective_date_end   => p_effective_date_end, 
      p_time_zone            => p_time_zone, 
      p_retrieve_templates   => false,
      p_retrieve_specs       => false,
      p_retrieve_ratings     => true, 
      p_recurse              => false, 
      p_office_id_mask       => p_office_id_mask);
end retrieve_ratings_xml;
   
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
      p_spec_id_mask         => p_spec_id_mask, 
      p_effective_date_start => p_effective_date_start, 
      p_effective_date_end   => p_effective_date_end, 
      p_time_zone            => p_time_zone, 
      p_retrieve_templates   => true,
      p_retrieve_specs       => true,
      p_retrieve_ratings     => true, 
      p_recurse              => false, 
      p_office_id_mask       => p_office_id_mask);
end retrieve_ratings_xml2;

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
      p_spec_id_mask         => p_spec_id_mask, 
      p_effective_date_start => p_effective_date_start, 
      p_effective_date_end   => p_effective_date_end, 
      p_time_zone            => p_time_zone, 
      p_retrieve_templates   => true,
      p_retrieve_specs       => true,
      p_retrieve_ratings     => true, 
      p_recurse              => true, 
      p_office_id_mask       => p_office_id_mask);
end retrieve_ratings_xml3;

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
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_xml     xmltype;
   l_node    xmltype;
   l_rating  rating_t;
begin
   l_xml := cwms_util.get_xml_node(p_xml, '/ratings');
   if l_xml is null then
      cwms_err.raise('ERROR', 'XML does not have <ratings> root element');
   end if;
   cwms_msg.log_db_message(
      'cwms_rating.store_ratings_xml',
      cwms_msg.msg_level_verbose,
      'Processing ratings XML');
   for i in 1..999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/rating-template['||i||']');
      exit when l_node is null;                   
      begin
         store_templates(l_node, p_fail_if_exists);
      exception
         when others then
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_normal,
               sqlerrm);
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);
      end;
   end loop;
   commit;
   for i in 1..999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/rating-spec['||i||']');
      exit when l_node is null;                   
      begin
         store_specs(l_node, p_fail_if_exists);
      exception
         when others then
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_normal,
               sqlerrm);
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);
      end;
   end loop;
   commit;
   for i in 1..999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '(/ratings/rating|/ratings/simple-rating|/ratings/virtual-rating|/ratings/transitional-rating|/ratings/usgs-stream-rating)['||i||']');
      exit when l_node is null;                   
      begin
         store_ratings(l_node, p_fail_if_exists);
      exception
         when others then
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_normal,
               sqlerrm);
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);
      end;
   end loop;
   commit;
end store_ratings_xml;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2)
is
begin
   store_ratings_xml(xmltype(p_xml), p_fail_if_exists);
end store_ratings_xml;

--------------------------------------------------------------------------------
-- STORE_RATINGS_XML
--
procedure store_ratings_xml(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
begin
   store_ratings_xml(xmltype(p_xml), p_fail_if_exists);
end store_ratings_xml;

--------------------------------------------------------------------------------
-- GET_RATING
--
function get_rating(
   p_rating_code in number)
   return rating_t
is
   l_dependent_count pls_integer;
   l_rating          rating_t;
begin
   dbms_output.put_line('getting rating for code '||p_rating_code);
   select count(*)
     into l_dependent_count
     from at_rating
    where ref_rating_code = p_rating_code;

   if l_dependent_count = 0 then
      l_rating := rating_t(p_rating_code);
   else
      l_rating := stream_rating_t(p_rating_code);
   end if;                    
   return l_rating;
end get_rating;

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
               'Input times must have same length as input parameters');
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
                effective_date
           from (--------------------------------------------------
                 -- simple ratings and usgs-style stream ratings --
                 -------------------------------------------------- 
                 select r.rating_code,
                        r.effective_date
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
                        tr.effective_date
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
                        vr.effective_date
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
         l_rating_units := str_tab_tab_t();
      end if;
      l_ratings.extend;
      l_rating_codes.extend;
      l_date_offsets.extend;
      l_rating_units.extend;
      l_rating_codes(l_rating_codes.count) := rec.rating_code;
      l_date_offsets(l_date_offsets.count) := rec.effective_date - c_base_date;
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
      l_rating_units.extend;
      l_rating_codes(2) := l_rating_codes(1); -- same rating
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
            if l_ratings(l_hi_index) is null then
               l_ratings(l_hi_index) := get_rating(l_rating_codes(l_hi_index)); 
               l_rating := treat(l_ratings(l_hi_index) as rating_t);
               l_rating_units(l_hi_index) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_hi_index).count != p_units.count then
                  cwms_err.raise(
                     'ERROR',
                     'Wrong number of units supplied for rating '
                     ||l_rating.office_id
                     ||'/'
                     ||l_rating.rating_spec_id);
               end if;
               if l_rating is of (stream_rating_t) then
                  l_stream_rating := treat(l_rating as stream_rating_t);
                  l_stream_rating.convert_to_native_units;
                  if l_hi_index < l_date_offsets.count then
                     ---------------------------------------------------------
                     -- chop any shifts that are after the next rating date --
                     ---------------------------------------------------------
                     l_stream_rating.trim_to_effective_date(c_base_date + l_date_offsets(l_hi_index+1));
                     l_stream_rating.trim_to_create_date(l_rating_time);
                  end if;
                     l_rating := l_stream_rating;
               else 
                  l_rating := treat(l_rating as rating_t);
                  l_rating.convert_to_native_units;
                  l_ratings(l_hi_index) := l_rating;
               end if;
            end if;
            l_ind_set_2 := double_tab_t();
            l_ind_set_2.extend(l_ind_set.count);
            for i in 1..l_ind_set.count loop
               l_ind_set_2(i) := cwms_util.convert_units(l_ind_set(i), p_units(i), l_rating_units(l_hi_index)(i));
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
               l_hi_value := l_rating.rate_one(l_ind_set_2);
            end case;
            l_hi_value := cwms_util.convert_units(l_hi_value, l_rating_units(l_hi_index)(p_units.count), p_units(p_units.count));
         end if;
         if l_ratio != 1. then
            if l_ratings(l_hi_index-1) is null then
               l_ratings(l_hi_index-1) := get_rating(l_rating_codes(l_hi_index-1)); 
               l_rating := treat(l_ratings(l_hi_index-1) as rating_t);
               l_rating_units(l_hi_index-1) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_hi_index-1).count != p_units.count then
                  cwms_err.raise(
                     'ERROR',
                     'Wrong number of units supplied for rating '
                     ||l_rating.office_id
                     ||'/'
                     ||l_rating.rating_spec_id);
               end if;
               if l_rating is of (stream_rating_t) then
                  l_stream_rating := treat(l_rating as stream_rating_t);
                  l_stream_rating.convert_to_native_units;
                  if l_hi_index-1 < l_date_offsets.count then
                     ---------------------------------------------------------
                     -- chop any shifts that are after the next rating date --
                     ---------------------------------------------------------
                     l_stream_rating.trim_to_effective_date(c_base_date + l_date_offsets(l_hi_index-1+1));
                     l_stream_rating.trim_to_create_date(l_rating_time);
                  end if;
                     l_rating := l_stream_rating;
               else 
                  l_rating := treat(l_rating as rating_t);
                  l_rating.convert_to_native_units;
                  l_ratings(l_hi_index-1) := l_rating;
               end if;
            end if;
            l_ind_set_2 := double_tab_t();
            l_ind_set_2.extend(l_ind_set.count);
            for i in 1..l_ind_set.count loop
               l_ind_set_2(i) := cwms_util.convert_units(l_ind_set(i), p_units(i), l_rating_units(l_hi_index-1)(i));
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
               l_lo_value := l_rating.rate_one(l_ind_set_2);
            end case;
            l_lo_value := cwms_util.convert_units(l_lo_value, l_rating_units(l_hi_index-1)(p_units.count), p_units(p_units.count));
         end if;
         -----------------------------------------
         -- re-compute ratio for stream ratings --
         -----------------------------------------
         if l_ratings(l_hi_index-1) is of (stream_rating_t)
            and l_ratio > 0.
            and l_ratio < 1.
            and treat(l_ratings(l_hi_index-1) as stream_rating_t).latest_shift_date is not null
         then
            l_date_offset_2 := treat(l_ratings(l_hi_index-1) as stream_rating_t).latest_shift_date - c_base_date;
            if l_date_offset_2 >= l_date_offset then
               l_ratio := 0.;
            else
               if l_independent_log then
                  l_ratio := (log(10, l_date_offset) - log(10, l_date_offset_2))
                           / (log(10, l_date_offsets(l_hi_index)) - log(10, l_date_offset_2));
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
                     begin
                        l_log_hi_val := log(10, l_hi_value);
                        l_log_lo_val := log(10, l_lo_value);
                     exception
                        when others then
                           l_dependent_log := false;
                           if l_independent_log then
                              ---------------------------------------
                              -- fall back from LOG-LoG to LIN-LIN --
                              ---------------------------------------
                              l_independent_log := false;
                              if l_ratings(l_hi_index-1) is of (stream_rating_t) and l_ratio > 0. and l_ratio < 1.
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
                     end;
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
         and upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id)||pl.sub_location_id)) = upper(l_parts(1))
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
                effective_date
           from (--------------------------------------------------
                 -- simple ratings and usgs-style stream ratings --
                 -------------------------------------------------- 
                 select r.rating_code,
                        r.effective_date
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
                        tr.effective_date
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
                        vr.effective_date
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
         l_rating_units := str_tab_tab_t();
      end if;
      l_ratings.extend;
      l_rating_codes.extend;
      l_date_offsets.extend;
      l_rating_units.extend;
      l_rating_codes(l_rating_codes.count) := rec.rating_code;
      l_date_offsets(l_date_offsets.count) := rec.effective_date - c_base_date;
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
      l_rating_units.extend;
      l_rating_codes(2) := l_rating_codes(1); -- same rating
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
            if l_ratings(l_hi_index) is null then
               l_ratings(l_hi_index) := get_rating(l_rating_codes(l_hi_index));
               l_rating := treat(l_ratings(l_hi_index) as rating_t);
               if l_rating.evaluations is not null then
                  cwms_err.raise('ERROR', 'Cannot reverse rate through a transitional rating.');
               end if;
               l_rating.convert_to_native_units;
               l_ratings(l_hi_index) := l_rating;
               l_rating_units(l_hi_index) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_hi_index).count != p_units.count then
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
                        p_units(1),
                        l_rating_units(l_hi_index)(1))),
                  l_rating_units(l_hi_index)(2),
                  p_units(2));
            else
               --------------------
               -- virtual rating --
               --------------------
               l_hi_value := cwms_util.convert_units(
                  l_rating.reverse_rate(
                     double_tab_t(cwms_util.convert_units(p_values(i), p_units(1), l_rating_units(l_hi_index)(1))),
                     cwms_util.split_text(l_rating.native_units, separator2),
                     'F',
                     null,
                     sysdate,
                     'UTC')(1),
                  l_rating_units(l_hi_index)(2),
                  p_units(2));
            end if;
         end if;
         if l_ratio != 1. then
            if l_ratings(l_hi_index-1) is null then
               l_ratings(l_hi_index-1) := get_rating(l_rating_codes(l_hi_index-1));
               l_rating := treat(l_ratings(l_hi_index-1) as rating_t);
               if l_rating.evaluations is not null then
                  cwms_err.raise('ERROR', 'Cannot reverse rate through a transitional rating.');
               end if;
               l_rating.convert_to_native_units;
               l_ratings(l_hi_index-1) := l_rating;
               l_rating_units(l_hi_index-1) := cwms_util.split_text(replace(l_rating.native_units, separator2, separator3), separator3);
               if l_rating_units(l_hi_index-1).count != p_units.count then
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
                        l_rating_units(l_hi_index-1)(1))),
                  l_rating_units(l_hi_index-1)(2),
                  p_units(2));
            else
               --------------------
               -- virtual rating --
               --------------------
               l_lo_value := cwms_util.convert_units(
                  l_rating.reverse_rate(
                     double_tab_t(cwms_util.convert_units(p_values(i), p_units(1), l_rating_units(l_hi_index-1)(1))),
                     cwms_util.split_text(l_rating.native_units, separator2),
                     'F',
                     null,
                     sysdate,
                     'UTC')(1),
                  l_rating_units(l_hi_index-1)(2),
                  p_units(2));
            end if;
         end if;
         -----------------------------------------
         -- re-compute ratio for stream ratings --
         -----------------------------------------
         if l_ratings(l_hi_index-1) is of (stream_rating_t)
            and l_ratio > 0.
            and l_ratio < 1.
            and treat(l_ratings(l_hi_index-1) as stream_rating_t).latest_shift_date is not null
         then
            l_date_offset_2 := treat(l_ratings(l_hi_index-1) as stream_rating_t).latest_shift_date - c_base_date;
            if l_date_offset_2 >= l_date_offset then
               l_ratio := 0.;
            else
               if l_independent_log then
                  l_ratio := (log(10, l_date_offset) - log(10, l_date_offset_2))
                           / (log(10, l_date_offsets(l_hi_index)) - log(10, l_date_offset_2));
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
                     begin
                        l_log_hi_val := log(10, l_hi_value);
                        l_log_lo_val := log(10, l_lo_value);
                     exception
                        when others then
                           l_dependent_log := false;
                           if l_independent_log then
                              ---------------------------------------
                              -- fall back from LOG-LoG to LIN-LIN --
                              ---------------------------------------
                              l_independent_log := false;
                              if l_ratings(l_hi_index-1) is of (stream_rating_t) and l_ratio > 0. and l_ratio < 1.
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
                     end;
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
   l_location     varchar2(49); -- from first independent id
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
   l_location     varchar2(49); -- from dependent id
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
   l_rating_code     number(10);
   l_effective_date  date;
   l_view_name       varchar2(30)  := 'av_rating_values';
   l_column_name     varchar2(30);
   l_sql constant    varchar2(256) :=
      'select min(column_name),
              max(column_name)
         into :min_value,
              :max_value
         from view_name
        where rating_code = :rating_code';

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
          last_value(effective_date) over (order by effective_date)
     into l_rating_code,
          l_effective_date
     from cwms_v_rating
    where office_id = upper(l_office_id)
      and upper(rating_id) = upper(p_rating_id)
      and effective_date <= l_rating_time_utc;
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
   if l_native_units then
      l_view_name := l_view_name || '_native';
   end if;
   for i in 1..p_parameters.count loop
      l_column_name := case i = p_parameters.count
                          when true  then 'dep_value'
                          when false then 'ind_value_'||i
                       end;
      execute immediate
         replace(replace(l_sql, 'column_name', l_column_name), 'view_name', l_view_name)
         into p_values(1)(i),
              p_values(2)(i)
         using l_rating_code;
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
   l_opening_index pls_integer;
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
   l_elev_code      number(10);
   l_params         str_tab_t;
   l_elev_positions number_tab_t;
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
            if l_elev_positions is null then
               l_elev_positions := number_tab_t();
            end if;
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

end;
/
show errors;

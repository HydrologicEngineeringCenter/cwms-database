create or replace package body cwms_rating
as
--------------------------------------------------------------------------------
-- STORE TEMPLATES
--
-- p_xml
--    contains zero or more <rating-template> elements
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
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
      l_template := rating_template_t(l_node);
      cwms_msg.log_db_message(
         'cwms_rating.store_templates', 
         cwms_msg.msg_level_detailed,
         'Storing rating template '
         ||l_template.office_id
         ||'/'||l_template.parameters_id
         ||'.'||l_template.version);
      l_template.store(p_fail_if_exists);
   end loop;
end store_templates;   

--------------------------------------------------------------------------------
-- STORE TEMPLATES
--
-- p_xml
--    contains zero or more <rating-template> elements
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
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
-- p_xml
--    contains zero or more <rating-template> elements
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
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
-- p_templates
--    contains zero or more rating_template_t objects
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
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
-- REMOVED FROM INTERFACE, KEPT ONLY TO BE ABLE TO RE-INSTATE
--------------------------------------------------------------------------------
-- -- STORE_TEMPLATE
-- --
-- -- p_template_id
-- --    ind-param[,ind-param[...]];dep-param.version
-- --
-- -- p_methods
-- --    out-range-low/in-range/out-range-high[,...] for each ind parameter
-- --       valid methods are
-- --          NULL        : return a NULL unless on rating point                             
-- --          ERROR       : raise an exception unless on rating point                   
-- --          LINEAR      : lin interp between ind and dep values                     
-- --          LOGARITHMIC : log interp between ind and dep values                     
-- --          LIN-LOG     : lin interp between ind, log interp between dep
-- --          LOG-LIN     : log interp between ind, lin interp between dep                    
-- --          CONIC       : conic interp (for elev-area-capacity ratings)               
-- --          PREVIOUS    : return dep value of rating point with ind value previous in sequence to the rated ind value                        
-- --          NEXT        : return dep value of rating point with ind value next in sequence to the rated ind value
-- --          NEAREST     : return dep value of rating point with ind value nearest in sequence to the rated ind value (extrapolation)                     
-- --          LOWER       : return dep value of rating point with ind value nearest to and less than rated ind value                    
-- --          HIGHER      : return dep value of rating point with ind value nearest to and greater than rated ind value                    
-- --          CLOSEST     : return dep value of rating point with ind value nearest to rated ind value
-- --
-- procedure store_template(
--    p_template_id    in varchar2,
--    p_methods        in varchar2,
--    p_description    in varchar2,
--    p_fail_if_exists in varchar2,
--    p_office_id      in varchar2 default null)   
-- is
--    l_parts       str_tab_t;
--    l_ind_params  str_tab_t;
--    l_methods     str_tab_t;
--    l_params_id   varchar2(256);
--    l_version     varchar2(32);
--    l_dep_param   varchar2(49);
--    l_param_specs rating_ind_param_spec_tab_t := rating_ind_param_spec_tab_t();  
--    l_template    rating_template_t;
-- begin
--    l_parts      := cwms_util.split_text(p_template_id, '.');
--    l_params_id  := l_parts(1);
--    l_version    := l_parts(2);
--    l_parts      := cwms_util.split_text(l_parts(1), ';');
--    l_dep_param  := l_parts(2);
--    l_ind_params := cwms_util.split_text(l_parts(1), ',');
--    l_methods    := cwms_util.split_text(p_methods, ',');
--    if l_methods.count != l_ind_params.count then
--       cwms_err.raise(
--          'ERROR', 
--          'Number of rating methods must match number of indepenedent parameters');
--    end if;
--    l_param_specs.extend(l_ind_params.count);
--    for i in 1..l_ind_params.count loop
--       l_parts := cwms_util.split_text(l_methods(i), '/');
--       if l_parts.count != 3 then
--          cwms_err.raise(
--             'ERROR', 
--             'Rating methods must be in out-range-low/in-range/out-range-high format');
--       end if;
--       l_param_specs(i) := rating_ind_param_spec_t(
--          i,
--          l_ind_params(i),
--          l_parts(2),
--          l_parts(1),
--          l_parts(3));   
--    end loop;
--    l_template := rating_template_t(
--       nvl(p_office_id, cwms_util.user_office_id),
--       l_params_id,
--       l_version,
--       l_param_specs,
--       l_dep_param,
--       p_description);
--    l_template.store(p_fail_if_exists);      
-- end store_template;   
--    
--------------------------------------------------------------------------------
-- CAT_TEMPLATE_IDS
--
-- p_cat_cursor
--    cursor containing all matched rating templates in the following fields,
--    sorted ascending in the following order:
--       office_id     varchar2(16)  office id
--       template_id   varchar2(289) full rating template id
--       parameters_id varchar2(256) parameters portion of template id
--       version       varchar2(32)  version portion of template id
--
-- p_template_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_office_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
   l_parts := cwms_util.split_text(p_template_id_mask, '.');
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
             ||'.'||rt.version as template_id,
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
-- same as above except that cursor is returned from function
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
-- p_templates
--    a rating_template_tab_t object containing the rating_template_t
--    objects that match the input parameters
--
-- p_template_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_office_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
   l_parts := cwms_util.split_text(p_template_id_mask, '.');
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
-- same as above except that rating_template_tab_t object returned from function
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
-- p_templates
--    a clob containing the xml of the matching rating templates
--
-- p_template_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_office_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
-- same as above except that rating_template_tab_t object returned from function
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
-- REMOVED FROM INTERFACE, KEPT ONLY TO BE ABLE TO RE-INSTATE
--------------------------------------------------------------------------------
-- -- RETRIEVE_TEMPLATE
-- --
-- -- p_template_id (in and out)
-- --    ind-param[,ind-param[...]];dep-param.version
-- --
-- -- p_methods
-- --    out-range-low/in-range/out-range-high[,...] for each ind parameter
-- --
-- procedure retrieve_template(
--    p_template_id_out out varchar2,
--    p_methods         out varchar2,
--    p_description     out varchar2,
--    p_template_id     in  varchar2,
--    p_office_id       in  varchar2 default null)
-- is
--    l_templates rating_template_tab_t;
-- begin
--    retrieve_templates_obj(
--       l_templates,
--       p_template_id,
--       p_office_id);
--    case l_templates.count
--       when 0 then
--          cwms_err.raise(
--             'ITEM_DOES_NOT_EXIST',
--             'Rating template ',
--             p_office_id||'/'||p_template_id);
--       when 1 then
--          p_template_id_out := l_templates(1).parameters_id || l_templates(1).version;
--          for i in 1..l_templates(1).ind_parameters.count loop
--             p_methods := p_methods
--                ||l_templates(1).ind_parameters(i).out_range_low_rating_method
--                ||'/'||l_templates(1).ind_parameters(i).in_range_rating_method
--                ||'/'||l_templates(1).ind_parameters(i).out_range_high_rating_method;
--             if i < l_templates(i).ind_parameters.count then
--                p_methods := p_methods || ',';
--             end if;
--          end loop;
--          p_description := l_templates(1).description;
--       else
--          cwms_err.raise(
--             'ERROR',
--             'Too many items match input specifications');
--    end case;      
-- end retrieve_template;
   
--------------------------------------------------------------------------------
-- DELETE_TEMPLATES
--
-- p_template_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_delete_action
--    cwms_util.delete_key
--       deletes only the templates, and only then if they are not referenced
--       by any rating specifications
--    cwms_util.delete_data
--       deletes only the specifications that reference the templates
--    cwms_util.delete_all
--       deletes the templates and the specifications that reference them
--
-- p_office_id_mask
--    wildcard pattern to match for rating template id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
      if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
         -----------------------
         -- delete child data --
         -----------------------
         delete
           from at_rating_ind_rounding
          where rating_spec_code in
                ( select rating_spec_code
                    from at_rating_spec
                   where template_code = l_template_code
                );
         delete
           from at_rating_spec
          where template_code = l_template_code;
      end if;         
      if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
         ---------------------
         -- delete template --
         ---------------------
         delete
           from at_rating_ind_param_spec
          where template_code = l_template_code;
         delete
           from at_rating_template
          where template_code = l_template_code;
      end if;         
   end loop;       
end delete_templates;    
     
--------------------------------------------------------------------------------
-- STORE_SPECS
--
-- p_xml
--    contains zero or more <rating-specification> elements
--
-- p_fail_if_exists
--    'T' to fail if specification with same office_id and speicification_id exists
--    'F' to update existing specification if exists
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
      l_spec := rating_spec_t(l_node);
      cwms_msg.log_db_message(
         'cwms_rating.store_specs', 
         cwms_msg.msg_level_detailed,
         'Storing rating specification '
         ||l_spec.office_id
         ||'/'||l_spec.location_id
         ||'.'||l_spec.template_id
         ||'.'||l_spec.version);
      l_spec.store(p_fail_if_exists);
   end loop;
end store_specs;   

--------------------------------------------------------------------------------
-- STORE_SPECS
--
-- p_xml
--    contains zero or more <rating-specification> elements
--
-- p_fail_if_exists
--    'T' to fail if specification with same office_id and speicification_id exists
--    'F' to update existing specification if exists
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
-- p_xml
--    contains zero or more <rating-specification> elements
--
-- p_fail_if_exists
--    'T' to fail if specification with same office_id and speicification_id exists
--    'F' to update existing specification if exists
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
-- p_xml
--    contains zero or more rating_spec_t objects
--
-- p_fail_if_exists
--    'T' to fail if specification with same office_id and speicification_id exists
--    'F' to update existing specification if exists
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
-- REMOVED FROM INTERFACE, KEPT ONLY TO BE ABLE TO RE-INSTATE
--------------------------------------------------------------------------------
-- -- STORE_SPEC
-- --
-- -- p_spec_id
-- --    location-id.template-id.spec-version
-- --
-- -- p_date_methods
-- --    out-range-before-first/in-range/out-range-after-last
-- --       valid methods are
-- --          NULL        : return a NULL unless on actual rating date                             
-- --          ERROR       : raise an exception unless on rating date                  
-- --          LINEAR      : lin interp between dates and rated values                     
-- --          LOGARITHMIC : log interp between dates and rated values                     
-- --          LIN-LOG     : lin interp between dates, log interp between rated values
-- --          LOG-LIN     : log interp between dates, lin interp between rated values                    
-- --          PREVIOUS    : return rated value of using rating with latest date prior to ind value(s) date                        
-- --          NEXT        : return rated value of using rating with earliest date after ind value(s) date
-- --          NEAREST     : return rated value of using rating with date closest to ind value(s) date                     
-- --          LOWER       : same as PREVIOUS                    
-- --          HIGHER      : same as NEXT                    
-- --          CLOSEST     : same as NEAREST
-- --
-- -- p_description
-- --    text description of rating specification
-- --
-- -- p_active_flag
-- --    'T' for ratings using this specification to be marked active
-- --       individual ratings may still be marked inactive
-- --    'F' for all ratings using this specification to be marked inactive
-- --
-- -- p_auto_update_flag
-- --    'T' to automatically load new ratings when available
-- --    'F' otherwise
-- --
-- -- p_auto_activate_flag
-- --    'T' to mark automatically loaded ratings as active
-- --    'F' to mark automatically loaded ratings as inactive
-- --
-- -- p_auto_migrate_ext_flag
-- --    'T' to automatically migrate existing rating extensions to newly loaded rating
-- --    'F' otherwise
-- --
-- -- p_rounding_specs
-- --    USGS-style 10-digit rounding specifications for ind and dep parameters
-- --       ind and dep rounding specs are separated by ';'
-- --       multiple ind rounding specs are separated by ','
-- --       one rounding spec is required for each ind and dep parameter
-- --       if parameter is null, all rounding specs default to '4444444444'
-- --
-- -- p_source_agency_id
-- --    loc_group_id of agency that generates ratings for this specification
-- --
-- -- p_office_id   
-- --    identifier of owning office
-- --
-- procedure store_spec(
--    p_spec_id               in varchar2,
--    p_date_methods          in varchar2,
--    p_fail_if_exists        in varchar2,
--    p_description           in varchar2 default null,
--    p_active_flag           in varchar2 default 'T',
--    p_auto_update_flag      in varchar2 default 'F',
--    p_auto_activate_flag    in varchar2 default 'F',
--    p_auto_migrate_ext_flag in varchar2 default 'F',
--    p_rounding_specs        in varchar2 default null,
--    p_source_agency_id      in varchar2 default null,
--    p_office_id             in varchar2 default null)
-- is
--    l_parts          str_tab_t;
--    l_location_id    varchar2(16);
--    l_template_id    varchar2(32);
--    l_version        varchar2(32);
--    l_spec           rating_spec_t;
--    l_ind_count      simple_integer := 0;
--    l_date_methods   str_tab_t;
--    l_rounding_specs varchar2(256) := p_rounding_specs;
--    l_ind_rounding   str_tab_t;
--    l_dep_rounding   varchar2(10);
-- begin
--    l_date_methods := cwms_util.split_text(p_date_methods, '/');
--    if l_date_methods.count != 3 then
--       cwms_err.raise(
--          'ERROR',
--          'Date methods must be of format out-range-before-first/in-range/out-range-after-last');
--    end if;
--    l_parts := cwms_util.split_text(p_spec_id, '.');
--    if l_parts.count != 4 then
--       cwms_err.raise(
--          'INVALID_ITEM',
--          p_spec_id,
--          'rating specification id');
--    end if;
--    l_location_id := l_parts(1);
--    l_template_id := l_parts(2)||'.'||l_parts(3);
--    l_version     := l_parts(4);
--    l_ind_count   := cwms_util.split_text(cwms_util.split_text(l_parts(2), ';')(1), ',').count;
--    if l_rounding_specs is null then
--       for i in 1..l_ind_count loop
--          l_rounding_specs := l_rounding_specs || ',4444444444';
--       end loop;
--       l_rounding_specs := substr(l_rounding_specs, 1) || ';4444444444';
--    end if;
--    l_parts := cwms_util.split_text(l_rounding_specs, ';');
--    l_dep_rounding := l_parts(2);
--    l_ind_rounding := cwms_util.split_text(l_parts(1), ',');
--    l_spec := rating_spec_t(
--       nvl(p_office_id, cwms_util.user_office_id),
--       l_location_id,
--       l_template_id,
--       l_version,
--       p_source_agency_id,
--       l_date_methods(2),
--       l_date_methods(1),
--       l_date_methods(3),
--       p_active_flag,
--       p_auto_update_flag,
--       p_auto_activate_flag,
--       p_auto_migrate_ext_flag,
--       l_ind_rounding,
--       l_dep_rounding,
--       p_description);
--       
--    l_spec.store(p_fail_if_exists);         
-- end store_spec;      
--       
--------------------------------------------------------------------------------
-- CAT_SPEC_IDS
--
-- p_cat_cursor
--    cursor containing all matched rating specifications in the following fields,
--    sorted ascending in the following order:
--       office_id        varchar2(16)  office id
--       specification_id varchar2(372) rating spec id
--       location_id      varchar2(49)  location portion of spec id
--       template_id      varchar2(289) template id portion of spec id
--       version          varchar2(32)  version portion of spec id
--
-- p_spec_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
   l_parts := cwms_util.split_text(p_spec_id_mask, '.');
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
             ||'.'||rt.parameters_id
             ||'.'||rt.version
             ||'.'||rs.version as specification_id,
             bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id as location_id,
             rt.parameters_id
             ||'.'||rt.version as template_id,
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
-- same as above except that cursor is returned from the function
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
-- p_specs
--    a rating_spec_tab_t object containing the rating_spec_t
--    objects that match the input parameters
--
-- p_spec_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
--
procedure retrieve_specs_obj(
   p_specs          out rating_spec_tab_t,
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
   l_parts := cwms_util.split_text(p_spec_id_mask, '.');
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
      (  select rs.rating_spec_code
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
                rs.version
      )
   loop
      p_specs.extend;
      p_specs(p_specs.count) := rating_spec_t(rec.rating_spec_code);
   end loop;   
end retrieve_specs_obj;        
   
--------------------------------------------------------------------------------
-- RETRIEVE_SPECS_OBJ_F
--
-- same as above except that rating_spec_tab_t object is returned from the
-- function
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
-- p_specs
--    a clob containing the xml of the matching rating specifications
--
-- p_spec_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
-- same as above except that clob is returned from the function
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
-- REMOVED FROM INTERFACE, KEPT ONLY TO BE ABLE TO RE-INSTATE
--------------------------------------------------------------------------------
-- -- RETRIEVE_SPEC
-- --
-- -- p_spec_id_out
-- --    location-id.template-id.spec-version, case-corrected on output
-- --
-- -- p_date_methods
-- --    out-range-before-first/in-range/out-range-after-last
-- --
-- -- p_description
-- --    text description of rating specification
-- --
-- -- p_active_flag
-- --    'T' for ratings using this specification to be marked active
-- --       individual ratings may still be marked inactive
-- --    'F' for all ratings using this specification to be marked inactive
-- --
-- -- p_auto_update_flag
-- --    'T' to automatically load new ratings when available
-- --    'F' otherwise
-- --
-- -- p_auto_activate_flag
-- --    'T' to mark automatically loaded ratings as active
-- --    'F' to mark automatically loaded ratings as inactive
-- --
-- -- p_auto_migrate_ext_flag
-- --    'T' to automatically migrate existing rating extensions to newly loaded rating
-- --    'F' otherwise
-- --
-- -- p_rounding_specs
-- --    USGS-style 10-digit rounding specifications for ind and dep parameters
-- --       ind and dep rounding specs are separated by ';'
-- --       multiple ind rounding specs are separated by ','
-- --       one rounding spec is required for each ind and dep parameter
-- --       if parameter is null, all rounding specs default to '4444444444'
-- --
-- -- p_source_agency_id
-- --    loc_group_id of agency that generates ratings for this specification
-- --
-- -- p_spec_id
-- --    location-id.template-id.spec-version
-- --
-- -- p_office_id   
-- --    identifier of owning office
-- --
-- procedure retrieve_spec(
--    p_spec_id_out           out varchar2,
--    p_date_methods          out varchar2,
--    p_description           out varchar2,
--    p_active_flag           out varchar2,
--    p_auto_update_flag      out varchar2,
--    p_auto_activate_flag    out varchar2,
--    p_auto_migrate_ext_flag out varchar2,
--    p_rounding_specs        out varchar2,
--    p_source_agency_id      out varchar2,
--    p_spec_id               in  varchar2,
--    p_office_id             in  varchar2 default null)
-- is
--    l_specs rating_spec_tab_t;
-- begin
--    retrieve_specs_obj(
--       l_specs,
--       p_spec_id,
--       p_office_id);
--    case l_specs.count
--       when 0 then
--          cwms_err.raise(
--             'ITEM_DOES_NOT_EXIST',
--             'Rating spec ',
--             p_office_id||'/'||p_spec_id);
--       when 1 then
--          p_spec_id_out := l_specs(1).location_id
--             ||'.'||l_specs(1).template_id
--             ||'.'||l_specs(1).version;
--          p_date_methods := l_specs(1).out_range_low_rating_method
--             ||'/'||l_specs(1).in_range_rating_method
--             ||'/'||l_specs(1).out_range_high_rating_method;
--          p_description           := l_specs(1).description;
--          p_active_flag           := l_specs(1).active_flag;             
--          p_auto_update_flag      := l_specs(1).auto_update_flag;             
--          p_auto_activate_flag    := l_specs(1).auto_activate_flag;             
--          p_auto_migrate_ext_flag := l_specs(1).auto_migrate_ext_flag;
--          p_source_agency_id      := l_specs(1).source_agency_id;
--          p_rounding_specs := 
--             cwms_util.join_text(
--                str_tab_t(
--                   cwms_util.join_text(l_specs(1).ind_rounding_specs, ','), 
--                   l_specs(1).dep_rounding_spec), 
--                ';');             
--       else
--          cwms_err.raise(
--             'ERROR',
--             'Too many items match input specifications');
--    end case;      
-- end retrieve_spec;   
   
--------------------------------------------------------------------------------
-- DELETE_SPECS
--
-- p_spec_id_mask
--    wildcard pattern to match for rating specification id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_delete_action
--    cwms_util.delete_key
--       deletes only the specs, and only then if they are not referenced
--       by any rating ratings
--    cwms_util.delete_data
--       deletes only the ratings that reference the specs
--    cwms_util.delete_all
--       deletes the specs and the ratings that reference them
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
      if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
         -----------------------
         -- delete child data --
         -----------------------
         for rec in 
            (  select rating_code
                 from at_rating
                where rating_spec_code = l_spec_code
            )
         loop
            for rec2 in
               (  select rating_ind_param_code
                    from at_rating_ind_parameter
                   where rating_code = rec.rating_code
               )
            loop
               delete
                 from at_rating_value
                where rating_ind_param_code = rec2.rating_ind_param_code;
               delete
                 from at_rating_extension_value
                where rating_ind_param_code = rec2.rating_ind_param_code;
            end loop;
            delete
              from at_rating_ind_parameter
             where rating_code = rec.rating_code;
         end loop;
         delete
           from at_rating
          where rating_spec_code = l_spec_code;
      end if;
      if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
         ---------------------
         -- delete the spec --
         ---------------------
         delete
           from at_rating_ind_rounding
          where rating_spec_code = l_spec_code;
         delete
           from at_rating_spec
          where rating_spec_code = l_spec_code;
      end if;
   end loop;      
end delete_specs;   

--------------------------------------------------------------------------------
-- STORE RATINGS
--
-- p_xml
--    contains zero or more <rating> or <usgs-stream-rating> elements
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
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
      l_node := cwms_util.get_xml_node(p_xml, '(//rating | //usgs-stream-rating)['||i||']');
      exit when l_node is null;
      if l_node.existsnode('/rating') = 1 then
         l_rating := rating_t(l_node);
         cwms_msg.log_db_message(
            'cwms_rating.store_ratings', 
            cwms_msg.msg_level_detailed,
            'Storing rating '
            ||l_rating.rating_spec_id
            ||' ('
            ||to_char(l_rating.effective_date, 'yyyy/mm/dd hh24mi')
            ||')');
         l_rating.store(p_fail_if_exists);
      elsif l_node.existsnode('/usgs-stream-rating') = 1 then
         l_stream_rating := stream_rating_t(l_node);
         cwms_msg.log_db_message(
            'cwms_rating.store_ratings', 
            cwms_msg.msg_level_detailed,
            'Storing rating '
            ||l_stream_rating.rating_spec_id
            ||' ('
            ||to_char(l_stream_rating.effective_date, 'yyyy/mm/dd hh24mi')
            ||')');
         l_stream_rating.store(p_fail_if_exists);
         l_stream_rating.store(p_fail_if_exists);
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
-- p_xml
--    contains zero or more <rating> or <usgs-stream-rating> elements
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
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
-- p_xml
--    contains zero or more <rating> or <usgs-stream-rating> elements
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
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
-- p_ratings
--    contains zero or more rating_t (possibly stream_rating_t) objects
--
-- p_fail_if_exists
--    'T' to fail if template with same office_id and template_id exists
--    'F' to update existing template if exists
--
procedure store_ratings(
   p_ratings        in rating_tab_t,
   p_fail_if_exists in varchar2)
is
   l_ratings rating_tab_t := p_ratings;
begin
   if l_ratings is not null then
      for i in 1..9999999 loop
         l_ratings(i).store(p_fail_if_exists);
      end loop;
   end if;
end store_ratings;      
      
--------------------------------------------------------------------------------
-- CAT_RATINGS
--
-- p_cat_cursor
--    cursor containing all matched rating specifications in the following fields,
--    sorted ascending in the following order:
--       office_id        varchar2(16)  office id
--       specification_id varchar2(372) rating spec id
--       effective_date   date
--       create_date      date
--
-- p_spec_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_effective_date_start
--    start of time window for matching ratings (in specified time zone)
--
-- p_effective_date_end
--    end of time window for matching ratings (in specified time zone)
--
-- p_time_zone
--    time zone to use for interpreting time window and for outputting dates
--    null specifies to default to location's time zone
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
   c_default_end_date   constant date := sysdate;
   
   l_parts str_tab_t;
   l_location_id_mask      varchar2(49);
   l_parameters_id_mask    varchar2(256);
   l_template_version_mask varchar2(32);
   l_spec_version_mask     varchar2(32);
   l_office_id_mask        varchar2(16) := nvl(p_office_id_mask, cwms_util.user_office_id);
begin
   l_parts := cwms_util.split_text(p_spec_id_mask, '.');
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
             ||'.'||rt.parameters_id
             ||'.'||rt.version
             ||'.'||rs.version as specification_id,
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
-- same as above except that cursor is returned from the function
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
-- p_ratings
--    rating_tab_t object that contains rating_t objects (possibly including
--    stream_rating_t objects) that match the input parameters
--
-- p_spec_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_effective_date_start
--    start of time window for matching ratings (in specified time zone)
--
-- p_effective_date_end
--    end of time window for matching ratings (in specified time zone)
--
-- p_time_zone
--    time zone to use for interpreting time window and for outputting dates
--    null specifies to default to location's time zone
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
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
   c_default_end_date   constant date := sysdate;
   
   l_parts str_tab_t;
   l_location_id_mask      varchar2(49);
   l_parameters_id_mask    varchar2(256);
   l_template_version_mask varchar2(32);
   l_spec_version_mask     varchar2(32);
   l_office_id_mask        varchar2(16) := nvl(p_office_id_mask, cwms_util.user_office_id);
   l_count                 simple_integer := 0;
begin
   l_parts := cwms_util.split_text(p_spec_id_mask, '.');
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
   
   p_ratings := rating_tab_t();
   for rec in
      (  select r.rating_code
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
            and r.ref_rating_code is null -- don't pick up stream rating shifts and offsets 
       order by o.office_id,
                bl.base_location_id,
                pl.sub_location_id,
                rt.parameters_id,
                rt.version,
                rs.version,
                r.effective_date nulls first                           
      )
   loop
      p_ratings.extend;
      select count(*)
        into l_count
        from at_rating
       where ref_rating_code = rec.rating_code;
      if l_count = 0 then
         p_ratings(p_ratings.count) := rating_t(rec.rating_code);
      else
         p_ratings(p_ratings.count) := stream_rating_t(rec.rating_code);
      end if;       
   end loop;
end retrieve_ratings_obj;   
   
--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_OBJ_F
--
-- same as above except that cursor is returned from the function
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
-- RETRIEVE_RATINGS_XML
--
-- p_ratings
--    a clob that contains the xml for ratings (possibly including stream
--    ratings) that match the input parameters
--
-- p_spec_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_effective_date_start
--    start of time window for matching ratings (in specified time zone)
--
-- p_effective_date_end
--    end of time window for matching ratings (in specified time zone)
--
-- p_time_zone
--    time zone to use for interpreting time window and for outputting dates
--    null specifies to default to location's time zone
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
--
procedure retrieve_ratings_xml(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
is
   l_ratings rating_tab_t;
   l_text    clob;
begin
   retrieve_ratings_obj(
      l_ratings,
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);
   dbms_lob.createtemporary(l_text, true);
   dbms_lob.open(l_text, dbms_lob.lob_readwrite);
   cwms_util.append(
      l_text, 
      '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      ||'xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
   for i in 1..l_ratings.count loop
      cwms_util.append(l_text, l_ratings(i).to_clob);
   end loop; 
   cwms_util.append(l_text, '</ratings>');     
   dbms_lob.close(l_text);      
   dbms_lob.createtemporary(p_ratings, true);
   dbms_lob.open(p_ratings, dbms_lob.lob_readwrite);
   cwms_util.append(p_ratings, '<?xml version="1.0" encoding="utf-8"?>'||chr(10));
   cwms_util.append(p_ratings, xmltype(l_text).extract('/node()').getclobval);
   dbms_lob.close(p_ratings);
end retrieve_ratings_xml;   
   
--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_XML_F
--
-- same as above except that cursor is returned from the function
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
-- DELETE_RATINGS
--
-- p_spec_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_effective_date_start
--    start of time window for matching ratings (in specified time zone)
--
-- p_effective_date_end
--    end of time window for matching ratings (in specified time zone)
--
-- p_time_zone
--    time zone to use for interpreting time window and for outputting dates
--    null specifies to default to location's time zone
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id 
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
--
procedure delete_ratings(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
is
   l_ratings     rating_tab_t;
   l_rating_code number(10);
begin
   l_ratings := retrieve_ratings_obj_f(
      p_spec_id_mask,
      p_effective_date_start,
      p_effective_date_end,
      p_time_zone,
      p_office_id_mask);
   for i in 1..l_ratings.count loop
      l_ratings(i).convert_to_database_time;
      dbms_output.put_line('deleting '||l_ratings(i).rating_spec_id||' ('||to_char(l_ratings(i).effective_date, 'yyyy/mm/dd hh24mi')||')');
      l_rating_code := rating_t.get_rating_code(
         l_ratings(i).rating_spec_id,
         l_ratings(i).effective_date,
         'T',
         'UTC',
         l_ratings(i).office_id);
      for rec in
         (  select rating_code
              from at_rating
             where ref_rating_code = l_rating_code
         )
      loop
         for rec2 in
            (  select rating_ind_param_code
                 from at_rating_ind_parameter
                where rating_code = rec.rating_code
            )
         loop
            delete
              from at_rating_value
             where rating_ind_param_code = rec2.rating_ind_param_code;
            delete
              from at_rating_extension_value
             where rating_ind_param_code = rec2.rating_ind_param_code;
         end loop;
         delete
           from at_rating_ind_parameter
          where rating_code = rec.rating_code;
         delete
           from at_rating
          where rating_code = rec.rating_code;
      end loop;         
      for rec in
         (  select rating_ind_param_code
              from at_rating_ind_parameter
             where rating_code = l_rating_code
         )
      loop
         delete
           from at_rating_value
          where rating_ind_param_code = rec.rating_ind_param_code;
         delete
           from at_rating_extension_value
          where rating_ind_param_code = rec.rating_ind_param_code;
      end loop;
      delete
        from at_rating_ind_parameter
       where rating_code = l_rating_code;
      delete
        from at_rating
       where rating_code = l_rating_code;
   end loop;      
end delete_ratings;   
   
--------------------------------------------------------------------------------
-- MULTIPLE TEMPLATES/SPECIFICATIONS/RATINGS 
--
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_xml  xmltype;
   l_node xmltype;
   l_rating rating_t;
begin
   l_xml := cwms_util.get_xml_node(p_xml, '/ratings');
   if l_xml is null then
      cwms_err.raise('ERROR', 'XML does not have <ratings> root element');
   end if;
   cwms_msg.log_db_message(
      'cwms_rating.store_ratings_xml',
      cwms_msg.msg_level_verbose,
      'Processing ratings XML');
   for i in 1..9999999 loop
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
   for i in 1..9999999 loop
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
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '(/ratings/rating | /ratings/usgs-stream-rating)['||i||']');
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

end;
/
show errors;

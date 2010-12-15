create or replace package cwms_rating
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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);
                         
--------------------------------------------------------------------------------
-- STORE_TEMPLATE
--
-- p_template_id
--    ind-param[,ind-param[...]];dep-param.version
--
-- p_methods
--    out-range-low/in-range/out-range-high[,...] for each ind parameter
--       valid methods are
--          NULL        : return a NULL unless on rating point                             
--          ERROR       : raise an exception unless on rating point                   
--          LINEAR      : lin interp between ind and dep values                     
--          LOGARITHMIC : log interp between ind and dep values                     
--          LIN-LOG     : lin interp between ind, log interp between dep
--          LOG-LIN     : log interp between ind, lin interp between dep                    
--          CONIC       : conic interp (for elev-area-capacity ratings)               
--          PREVIOUS    : return dep value of rating point with ind value previous in sequence to the rated ind value                        
--          NEXT        : return dep value of rating point with ind value next in sequence to the rated ind value
--          NEAREST     : return dep value of rating point with ind value nearest in sequence to the rated ind value (extrapolation)                     
--          LOWER       : return dep value of rating point with ind value nearest to and less than rated ind value                    
--          HIGHER      : return dep value of rating point with ind value nearest to and greater than rated ind value                    
--          CLOSEST     : return dep value of rating point with ind value nearest to rated ind value
--
-- p_office_id
--    identifier of owning office
--
procedure store_template(
   p_template_id    in varchar2,
   p_methods        in varchar2,
   p_description    in varchar2,
   p_fail_if_exists in varchar2,
   p_office_id      in varchar2 default null);
   
--------------------------------------------------------------------------------
-- CAT_TEMPLATE_IDS
--
-- p_cat_cursor
--    cursor containing all matched rating templates in the following fields:
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
   p_office_id_mask   in  varchar2 default null);      

--------------------------------------------------------------------------------
-- CAT_TEMPLATE_IDS_F
--
-- same as above except that cursor is returned from the function
--
function cat_template_ids_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return sys_refcursor;      
   
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
   p_office_id_mask   in  varchar2 default null);      
   
--------------------------------------------------------------------------------
-- RETRIEVE_TEMPLATES_OBJ_F
--
-- same as above except that rating_template_tab_t object is returned from the
-- function
--
function retrieve_templates_obj_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return rating_template_tab_t;      
   
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
   p_office_id_mask   in  varchar2 default null);      
   
--------------------------------------------------------------------------------
-- RETRIEVE_TEMPLATES_XML_F
--
-- same as above except that clob is returned from the function
--
function retrieve_templates_xml_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return clob;
         
--------------------------------------------------------------------------------
-- RETRIEVE_TEMPLATE
--
-- p_template_id (in and out)
--    ind-param[,ind-param[...]];dep-param.version
--
-- p_methods
--    out-range-low/in-range/out-range-high[,...] for each ind parameter
--
procedure retrieve_template(
   p_template_id_out out varchar2,
   p_methods         out varchar2,
   p_description     out varchar2,
   p_template_id     in  varchar2,
   p_office_id       in  varchar2 default null);

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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);
   
--------------------------------------------------------------------------------
-- STORE_SPEC
--
-- p_spec_id
--    location-id.template-id.spec-version
--
-- p_date_methods
--    out-range-before-first/in-range/out-range-after-last
--       valid methods are
--          NULL        : return a NULL unless on actual rating date                             
--          ERROR       : raise an exception unless on rating date                  
--          LINEAR      : lin interp between dates and rated values                     
--          LOGARITHMIC : log interp between dates and rated values                     
--          LIN-LOG     : lin interp between dates, log interp between rated values
--          LOG-LIN     : log interp between dates, lin interp between rated values                    
--          PREVIOUS    : return rated value of using rating with latest date prior to ind value(s) date                        
--          NEXT        : return rated value of using rating with earliest date after ind value(s) date
--          NEAREST     : return rated value of using rating with date closest to ind value(s) date                     
--          LOWER       : same as PREVIOUS                    
--          HIGHER      : same as NEXT                    
--          CLOSEST     : same as NEARESTT
--
-- p_description
--    text description of rating specification
--
-- p_active_flag
--    'T' for ratings using this specification to be marked active
--       individual ratings may still be marked inactive
--    'F' for all ratings using this specification to be marked inactive
--
-- p_auto_update_flag
--    'T' to automatically load new ratings when available
--    'F' otherwise
--
-- p_auto_activate_flag
--    'T' to mark automatically loaded ratings as active
--    'F' to mark automatically loaded ratings as inactive
--
-- p_auto_migrate_ext_flag
--    'T' to automatically migrate existing rating extensions to newly loaded rating
--    'F' otherwise
--
-- p_rounding_specs
--    USGS-style 10-digit rounding specifications for ind and dep parameters
--       ind and dep rounding specs are separated by ';'
--       multiple ind rounding specs are separated by ','
--       one rounding spec is required for each ind and dep parameter
--       if parameter is null, all rounding specs default to '4444444444'
--
-- p_source_agency_id
--    loc_group_id of agency that generates ratings for this specification
--
-- p_office_id   
--    identifier of owning office
--
procedure store_spec(
   p_spec_id               in varchar2,
   p_date_methods          in varchar2,
   p_fail_if_exists        in varchar2,
   p_description           in varchar2 default null,
   p_active_flag           in varchar2 default 'T',
   p_auto_update_flag      in varchar2 default 'F',
   p_auto_activate_flag    in varchar2 default 'F',
   p_auto_migrate_ext_flag in varchar2 default 'F',
   p_rounding_specs        in varchar2 default null,
   p_source_agency_id      in varchar2 default null,
   p_office_id             in varchar2 default null);
      
--------------------------------------------------------------------------------
-- CAT_SPEC_IDS
--
-- p_cat_cursor
--    cursor containing all matched rating specifications in the following fields:
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
   p_office_id_mask in  varchar2 default null);

--------------------------------------------------------------------------------
-- CAT_SPEC_IDS_F
--
-- same as above except that cursor is returned from the function
--
function cat_spec_ids_f(
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor;      
   
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
   p_office_id_mask in  varchar2 default null);      
   
--------------------------------------------------------------------------------
-- RETRIEVE_SPECS_OBJ_F
--
-- same as above except that rating_spec_tab_t object is returned from the
-- function
--
function retrieve_specs_obj_f(
   p_spec_id_mask   in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return rating_spec_tab_t;      
   
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
   p_office_id_mask in  varchar2 default null);      
   
--------------------------------------------------------------------------------
-- RETRIEVE_SPECS_XML_F
--
-- same as above except that clob is returned from the function
--
function retrieve_specs_xml_f(
   p_spec_id_mask   in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return clob;
   
--------------------------------------------------------------------------------
-- RETRIEVE_SPEC
--
-- p_spec_id_out
--    location-id.template-id.spec-version, case-corrected on output
--
-- p_date_methods
--    out-range-before-first/in-range/out-range-after-last
--
-- p_description
--    text description of rating specification
--
-- p_active_flag
--    'T' for ratings using this specification to be marked active
--       individual ratings may still be marked inactive
--    'F' for all ratings using this specification to be marked inactive
--
-- p_auto_update_flag
--    'T' to automatically load new ratings when available
--    'F' otherwise
--
-- p_auto_activate_flag
--    'T' to mark automatically loaded ratings as active
--    'F' to mark automatically loaded ratings as inactive
--
-- p_auto_migrate_ext_flag
--    'T' to automatically migrate existing rating extensions to newly loaded rating
--    'F' otherwise
--
-- p_rounding_specs
--    USGS-style 10-digit rounding specifications for ind and dep parameters
--       ind and dep rounding specs are separated by ';'
--       multiple ind rounding specs are separated by ','
--       one rounding spec is required for each ind and dep parameter
--       if parameter is null, all rounding specs default to '4444444444'
--
-- p_source_agency_id
--    loc_group_id of agency that generates ratings for this specification
--
-- p_spec_id
--    location-id.template-id.spec-version
--
-- p_office_id   
--    identifier of owning office
--
procedure retrieve_spec(
   p_spec_id_out           out varchar2,
   p_date_methods          out varchar2,
   p_description           out varchar2,
   p_active_flag           out varchar2,
   p_auto_update_flag      out varchar2,
   p_auto_activate_flag    out varchar2,
   p_auto_migrate_ext_flag out varchar2,
   p_rounding_specs        out varchar2,
   p_source_agency_id      out varchar2,
   p_spec_id               in  varchar2,
   p_office_id             in  varchar2 default null);
         
--------------------------------------------------------------------------------
-- INDIVIDUAL RATINGS
--
procedure store_rating(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);

procedure store_rating(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2);

procedure store_rating(
   p_xml            in clob,
   p_fail_if_exists in varchar2);
   
procedure store_rating(
   p_rating         in rating_t,
   p_fail_if_exists in varchar2);   
   
procedure store_rating(
   p_rating         in stream_rating_t,
   p_fail_if_exists in varchar2);   
   
--------------------------------------------------------------------------------
-- MULTIPLE TEMPLATES/SPECIFICATIONS/RATINGS 
--
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);
   
end;
/
show errors;

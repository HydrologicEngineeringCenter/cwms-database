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
   p_office_id_mask   in varchar2 default null);

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
   p_office_id_mask in varchar2 default null);
         
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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);

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
   p_fail_if_exists in varchar2);
   
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
   p_fail_if_exists in varchar2);   
      
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
   p_office_id_mask       in  varchar2 default null);
   
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
   return sys_refcursor;

--------------------------------------------------------------------------------
-- RETRIEVE_RATINGS_OBJ
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
   p_office_id_mask       in  varchar2 default null);
   
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
   return rating_tab_t;
   
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
   p_office_id_mask       in  varchar2 default null);
   
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
   return clob;
   
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
   p_office_id_mask       in varchar2 default null);
   
--------------------------------------------------------------------------------
-- MULTIPLE TEMPLATES/SPECIFICATIONS/RATINGS 
--
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);
   
end;
/
show errors;

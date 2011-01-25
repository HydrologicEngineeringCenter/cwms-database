create or replace package cwms_rating
as

--------------------------------------------------------------------------------
-- STORE TEMPLATES
--
-- p_xml
--    contains zero or more <rating-template> elements
--
-- p_fail_if_exists
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
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
-- STORE_RATINGS_XML 
--
-- Stores rating templates, rating specifications, and ratings from an single
-- XML instance
--
-- p_xml
--    contains zero or more <rating> or <usgs-stream-rating> elements
--
-- p_fail_if_exists
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
--
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);  
   
--------------------------------------------------------------------------------
-- STORE_RATINGS_XML 
--
-- Stores rating templates, rating specifications, and ratings from an single
-- XML instance
--
-- p_xml
--    contains zero or more <rating> or <usgs-stream-rating> elements
--
-- p_fail_if_exists
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
--
procedure store_ratings_xml(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2);  
   
--------------------------------------------------------------------------------
-- STORE_RATINGS_XML 
--
-- Stores rating templates, rating specifications, and ratings from an single
-- XML instance
--
-- p_xml
--    contains zero or more <rating> or <usgs-stream-rating> elements
--
-- p_fail_if_exists
--    'T' to fail if item to be stored already exists
--    'F' to update existing item if it already exists
--
procedure store_ratings_xml(
   p_xml            in clob,
   p_fail_if_exists in varchar2);  
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates input values with ratings stored in database.
--
-- p_results
--    The output values of the ratings
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameters as a table of tables of values.  Each
--    item of the table is a table of one of the input parameters.  Each item
--    must be the same length, with the 1st value of each of the items
--    comprising the 1st set of inputs, the 2nd value of each comprising the 2nd
--    set of inputs, etc... 
--
-- p_units
--    The units for the input (independent) parameters and output (dependent)
--    parameter, as a table of varchar2(16).  The length of the table must be
--    one greater than the length of the p_values table.  The 1st value is the
--    unit of the 1st, indpendent parameter, etc....  The last value is the unit
--    of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_value_times
--    The times corresponding to the parameters.  If specified, it must be as a
--    table of date types, of the same length as each item of the p_values
--    parameter.  The 1st value in the table specifies the time of the first 
--    value of each of the independent parameters, as well as the time of the
--    first dependent parameter.  If null, all times are assumed to be the 
--    current time.  Times are interpreted according to the p_time_zone
--    parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates input values of one parameter with ratings stored in database.
--
-- p_results
--    The output values of the ratings
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of values. Each item of the 
--    table specifies a value for the one and only input parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_value_times
--    The times corresponding to the parameters. If specified, it must be as a 
--    table of date types, of the same length as the p_values parameter. The 
--    1st value in the table specifies the time of the first value of each of 
--    the independent and dependent parameters. If null, all times are assumed 
--    to be the current time. Times are interpreted according to the 
--    p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates a single input value of one parameter with ratings stored in database.
--
-- p_result
--    The output value of the rating
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned value according to the rounding
--    specification contained in the rating specification.
--
-- p_value_time
--    The time of the parameters. If specified, it must be as a date type. The 
--    If null, the time is assumed to be the current time. Time is interpreted 
--    according to the p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- RATE_ONE
--
-- Rates a single input value of more than one parameter with ratings 
-- stored in database.
--
-- p_result
--    The output value of the rating
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameters a table of values.  Each item in the 
--    table specifies one of the independent parameters.
--
-- p_units
--    The units for the input (independent) parameters and output (dependent)
--    parameter, as a table of varchar2(16).  The length of the table must be
--    one greater than the length of the p_values table.  The 1st value is the
--    unit of the 1st, indpendent parameter, etc....  The last value is the unit
--    of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned value according to the rounding
--    specification contained in the rating specification.
--
-- p_value_time
--    The time of the parameters. If specified, it must be as a date type. The 
--    If null, the time is assumed to be the current time. Time is interpreted 
--    according to the p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates input values of one parameter with ratings stored in database.
--
-- p_results
--    The output values of the ratings. The date_time component of each item 
--    in the table will be the same as for the corresponding input value. The 
--    quality_code component of each item in the table will be set to 0 
--    (unscreened) unless the value component is null, at which time it will 
--    be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of tsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table includes
--    its own time zone information, so it is not interpreted according to the 
--    p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.  The date_time component of each item in the p_values parameter
--    already has a time zone associated with it, so this parameter is not used to
--    interpret those times 
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure rate(
   p_results     out tsv_array,
   p_rating_spec in  varchar2,
   p_values      in  tsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates input values of one parameter with ratings stored in database.
--
-- p_results
--    The output values of the ratings. The date_time component of each item 
--    in the table will be the same as for the corresponding input value. The 
--    quality_code component of each item in the table will be set to 0 
--    (unscreened) unless the value component is null, at which time it will 
--    be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of ztsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table 
--    is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    items in the p_values table and the p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure rate(
   p_results     out ztsv_array,
   p_rating_spec in  varchar2,
   p_values      in  ztsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates a single input value of one parameter with ratings stored in database.
--
-- p_result
--    The output value of the ratings. The date_time component of the value 
--    will be the same as that of input value. The quality_code component will 
--    be set to 0 (unscreened) unless the value component is null, at which 
--    time it will be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a tsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component includes its own time zone information, so it is not 
--    interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used. The date_time component of the p_value parameter 
--    already has a time zone associated with it, so this parameter is not 
--    used to interpret that time
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure rate(
   p_result      out tsv_type,
   p_rating_spec in  varchar2,
   p_value       in  tsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates a single input value of one parameter with ratings stored in database.
--
-- p_result
--    The output value of the ratings. The date_time component will be the 
--    same as for the input value. The quality_code component will be set to 0 
--    (unscreened) unless the value component is null, at which time it will 
--    be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a ztsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    p_value parameter and the p_rating_time parameter. If null, the time 
--    zone associated with the location in the p_rating_spec parameter will be 
--    used. If no time zone is associated with the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure rate(
   p_result      out ztsv_type,
   p_rating_spec in  varchar2,
   p_value       in  ztsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- RATE_F
--
-- Rates input values with ratings stored in database, returning the results.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameters as a table of tables of values.  Each
--    item of the table is a table of one of the input parameters.  Each item
--    must be the same length, with the 1st value of each of the items
--    comprising the 1st set of inputs, the 2nd value of each comprising the 2nd
--    set of inputs, etc... 
--
-- p_units
--    The units for the input (independent) parameters and output (dependent)
--    parameter, as a table of varchar2(16).  The length of the table must be
--    one greater than the length of the p_values table.  The 1st value is the
--    unit of the 1st, indpendent parameter, etc....  The last value is the unit
--    of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_value_times
--    The times corresponding to the parameters.  If specified, it must be as a
--    table of date types, of the same length as each item of the p_values
--    parameter.  The 1st value in the table specifies the time of the first 
--    value of each of the independent parameters, as well as the time of the
--    first dependent parameter.  If null, all times are assumed to be the 
--    current time.  Times are interpreted according to the p_time_zone
--    parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t;   

--------------------------------------------------------------------------------
-- RATE_F
--
-- Rates input values of one parameter with ratings stored in database,
-- returning the results
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of values. Each item of the 
--    table specifies a value for the one and only input parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_value_times
--    The times corresponding to the parameters. If specified, it must be as a 
--    table of date types, of the same length as the p_values parameter. The 
--    1st value in the table specifies the time of the first value of each of 
--    the independent and dependent parameters. If null, all times are assumed 
--    to be the current time. Times are interpreted according to the 
--    p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t;   
   
--------------------------------------------------------------------------------
-- RATE_F
--
-- Rates a single input value of one parameter with ratings stored in database,
-- returning the result.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned value according to the rounding
--    specification contained in the rating specification.
--
-- p_value_time
--    The time of the parameters. If specified, it must be as a date type. The 
--    If null, the time is assumed to be the current time. Time is interpreted 
--    according to the p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   return binary_double;   
   
--------------------------------------------------------------------------------
-- RATE_ONE_F
--
-- Rates a single input value of more than one parameter with ratings 
-- stored in database, returning the result.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameters a table of values.  Each item in the 
--    table specifies one of the independent parameters.
--
-- p_units
--    The units for the input (independent) parameters and output (dependent)
--    parameter, as a table of varchar2(16).  The length of the table must be
--    one greater than the length of the p_values table.  The 1st value is the
--    unit of the 1st, indpendent parameter, etc....  The last value is the unit
--    of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned value according to the rounding
--    specification contained in the rating specification.
--
-- p_value_time
--    The time of the parameters. If specified, it must be as a date type. The 
--    If null, the time is assumed to be the current time. Time is interpreted 
--    according to the p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   return binary_double;   
   
--------------------------------------------------------------------------------
-- RATE_F
--
-- Rates input values of one parameter with ratings stored in database,
-- returning the results
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of tsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table includes
--    its own time zone information, so it is not interpreted according to the 
--    p_time_zone parameter
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.  The date_time component of each item in the p_values parameter
--    already has a time zone associated with it, so this parameter is not used to
--    interpret those times 
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function rate_f(
   p_rating_spec in varchar2,
   p_values      in tsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_array;   
   
--------------------------------------------------------------------------------
-- RATE_F
--
-- Rates input values of one parameter with ratings stored in database,
-- returning the results.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of ztsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table 
--    is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    items in the p_values table and the p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function rate_f(
   p_rating_spec in varchar2,
   p_values      in ztsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;   
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates a single input value of one parameter with ratings stored in database,
-- returning the result.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a tsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component includes its own time zone information, so it is not 
--    interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned value according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used. The date_time component of the p_value parameter 
--    already has a time zone associated with it, so this parameter is not 
--    used to interpret that time
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function rate_f(
   p_rating_spec in varchar2,
   p_value       in tsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_type;   
   
--------------------------------------------------------------------------------
-- RATE_F
--
-- Rates a single input value of one parameter with ratings stored in database,
-- returning the result.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a ztsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    p_value parameter and the p_rating_time parameter. If null, the time 
--    zone associated with the location in the p_rating_spec parameter will be 
--    used. If no time zone is associated with the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function rate_f(
   p_rating_spec in varchar2,
   p_value       in ztsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_type;   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE
--
-- Reverse rates input values of one parameter with ratings stored in database.
--
-- p_results
--    The output values of the ratings
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of values. Each item of the 
--    table specifies a value for the one and only input parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_value_times
--    The times corresponding to the parameters. If specified, it must be as a 
--    table of date types, of the same length as the p_values parameter. The 
--    1st value in the table specifies the time of the first value of each of 
--    the independent and dependent parameters. If null, all times are assumed 
--    to be the current time. Times are interpreted according to the 
--    p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE
--
-- Reverse rates a single input value of one parameter with ratings stored in 
-- database.
--
-- p_result
--    The output value of the rating
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned value according to the rounding
--    specification contained in the rating specification.
--
-- p_value_time
--    The time of the parameters. If specified, it must be as a date type. The 
--    If null, the time is assumed to be the current time. Time is interpreted 
--    according to the p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE
--
-- Reverse rates input values of one parameter with ratings stored in database.
--
-- p_results
--    The output values of the ratings. The date_time component of each item 
--    in the table will be the same as for the corresponding input value. The 
--    quality_code component of each item in the table will be set to 0 
--    (unscreened) unless the value component is null, at which time it will 
--    be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of tsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table includes
--    its own time zone information, so it is not interpreted according to the 
--    p_time_zone parameter
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.  The date_time component of each item in the p_values parameter
--    already has a time zone associated with it, so this parameter is not used to
--    interpret those times 
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure reverse_rate(
   p_results     out tsv_array,
   p_rating_spec in  varchar2,
   p_values      in  tsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE
--
-- Reverse rates input values of one parameter with ratings stored in database.
--
-- p_results
--    The output values of the ratings. The date_time component of each item 
--    in the table will be the same as for the corresponding input value. The 
--    quality_code component of each item in the table will be set to 0 
--    (unscreened) unless the value component is null, at which time it will 
--    be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of ztsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table 
--    is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    items in the p_values table and the p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure reverse_rate(
   p_results     out ztsv_array,
   p_rating_spec in  varchar2,
   p_values      in  ztsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE
--
-- Reverse rates a single input value of one parameter with ratings stored in database.
--
-- p_result
--    The output value of the ratings. The date_time component of the value 
--    will be the same as that of input value. The quality_code component will 
--    be set to 0 (unscreened) unless the value component is null, at which 
--    time it will be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a tsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component includes its own time zone information, so it is not 
--    interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used. The date_time component of the p_value parameter 
--    already has a time zone associated with it, so this parameter is not 
--    used to interpret that time
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure reverse_rate(
   p_result      out tsv_type,
   p_rating_spec in  varchar2,
   p_value       in  tsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE
--
-- Reverse rates a single input value of one parameter with ratings stored in database.
--
-- p_result
--    The output value of the ratings. The date_time component will be the 
--    same as for the input value. The quality_code component will be set to 0 
--    (unscreened) unless the value component is null, at which time it will 
--    be set set to 5 (screened, missing)
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a ztsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    p_value parameter and the p_rating_time parameter. If null, the time 
--    zone associated with the location in the p_rating_spec parameter will be 
--    used. If no time zone is associated with the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
procedure reverse_rate(
   p_result      out ztsv_type,
   p_rating_spec in  varchar2,
   p_value       in  ztsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
-- Reverse rates input values of one parameter with ratings stored in database,
-- returning the results
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of values. Each item of the 
--    table specifies a value for the one and only input parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_value_times
--    The times corresponding to the parameters. If specified, it must be as a 
--    table of date types, of the same length as the p_values parameter. The 
--    1st value in the table specifies the time of the first value of each of 
--    the independent and dependent parameters. If null, all times are assumed 
--    to be the current time. Times are interpreted according to the 
--    p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   return double_tab_t;   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
-- Reverse rates a single input value of one parameter with ratings stored in 
-- database,
-- returning the result.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter.
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_value_time
--    The time of the parameters. If specified, it must be as a date type. The 
--    If null, the time is assumed to be the current time. Time is interpreted 
--    according to the p_time_zone parameter.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the p_value_times and p_rating_time
--    parameters.  If null, the time zone associated with the location in the
--    p_rating_spec parameter will be used.  If no time zone is associated with
--    the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
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
   return binary_double;   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
-- Reverse rates input values of one parameter with ratings stored in database,
-- returning the results
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of tsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table includes
--    its own time zone information, so it is not interpreted according to the 
--    p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.  The date_time component of each item in the p_values parameter
--    already has a time zone associated with it, so this parameter is not used to
--    interpret those times 
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in tsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_array;   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
-- Reverse rates input values of one parameter with ratings stored in database,
-- returning the results.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_values
--    The input (independent) parameter as a table of ztsv_type. The value 
--    component of each item of the table specifies the value for the one and 
--    only input parameter. The date_time component of each item in the table 
--    is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    items in the p_values table and the p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in ztsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
--    Reverse rates a single input value of one parameter with ratings stored 
--    in database, returning the result.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a tsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component includes its own time zone information, so it is not 
--    interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret p_rating_time parameter. If null, 
--    the time zone associated with the location in the p_rating_spec 
--    parameter will be used. If no time zone is associated with the location, 
--    UTC will be used. The date_time component of the p_value parameter 
--    already has a time zone associated with it, so this parameter is not 
--    used to interpret that time
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in tsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_type;   
   
--------------------------------------------------------------------------------
-- REVERSE_RATE_F
--
--    Reverse rates a single input value of one parameter with ratings stored 
--    in database, returning the result.
--
-- p_rating_spec
--    The rating specification to use.  Rating specifications have four parts
--    separated by the period (.) character.  The parts are:
--       Location ID
--       Rating Template Parameters
--       Rating Template Version
--       Rating Version
--    The rating template parameters are specified as a comma (,) separated list
--    of independent parameters separated from the dependent parameter by a 
--    semi-colon (;)
--
-- p_value
--    The input (independent) parameter as a ztsv_type. The value component 
--    specifies the value for the one and only input parameter. The date_time 
--    component is interpreted according to the p_time_zone parameter
--
-- p_units
--    The units for the input (independent) parameter and output (dependent) 
--    parameter, as a table of varchar2(16). The length of the table must be 
--    2. The 1st value is the unit of the indpendent parameter; the 2nd value 
--    is the unit of the dependent parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret the date_time component of the 
--    p_value parameter and the p_rating_time parameter. If null, the time 
--    zone associated with the location in the p_rating_spec parameter will be 
--    used. If no time zone is associated with the location, UTC will be used.
--
-- p_office_id
--    The office that owns the rating specified in the p_rating_spec parameter.
--    If null, the office of current session user us used.
--   
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in ztsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_type;   
   
--------------------------------------------------------------------------------
-- RETRIEVE_RATED_TS
--
-- Retrieves a time series that is the result of rating the specified time 
-- series with the specified rating.
--
-- p_independent_ids
--    The independent time series to be rated with the specified rating
--
-- p_rating_id
--    The rating to use
--
-- p_units
--    The unit in which to return the rated time series
--
-- p_start_time
--    The beginning of time window for the time series
--
-- p_end_time
--    The end of time window for the time series
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret all date parameters, and in which 
--    to return the data times. If null, the time zone associated with the 
--    location in the p_rating_spec parameter will be used. If no time zone is 
--    associated with the location, UTC will be used. The location is taken 
--    from the first item in the p_independent_ids parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_trim
--    Specifies whether to trim null values from the beginning and end of the
--    returned time series.  'T' = true, 'F' = false.
--
-- p_start_inclusive
--    Specifies whether p_start_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_end_inclusive
--    Specifies whether p_end_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_previous
--    Specifies whether to retrieve the latest value before the beginning of
--    the time window.  'T' = true, 'F' = false.
--
-- p_next
--    Specifies whether to retrieve the earliest value after the end of
--    the time window.  'T' = true, 'F' = false.
--
-- p_version_date
--    If not null, specifies the version date for versioned data. If null, the 
--    earliest or latest version date is used depending on the value of the 
--    p_max_version parameter.
--
-- p_max_version
--    Used only if the p_version_date parameter is null.  'T' = use the latest
--    version date for versioned data.  'F' = use the earliest version date
--    for versioned data.  Retrieving non-versioned data is not affected by
--    this parameter.
--
-- p_ts_office_id
--    The office id to be used with the time series identifiers. If null, the 
--    current session user is used.
--
-- p_rating_office_id
--    The office id to be used with the rating identifier. If null, the 
--    current session user is used.
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
   return ztsv_array;
   
--------------------------------------------------------------------------------
-- RETRIEVE_RATED_TS
--
-- Retrieves a time series that is the result of rating the specified time 
-- series with the specified rating.
--
-- p_independent_id
--    The independent time series to be rated with the specified rating
--
-- p_rating_id
--    The rating to use
--
-- p_units
--    The unit in which to return the rated time series
--
-- p_start_time
--    The beginning of time window for the time series
--
-- p_end_time
--    The end of time window for the time series
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret all date parameters, and in which 
--    to return the data times. If null, the time zone associated with the 
--    location in the p_rating_spec parameter will be used. If no time zone is 
--    associated with the location, UTC will be used. The location is taken 
--    from the p_independent_id parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_trim
--    Specifies whether to trim null values from the beginning and end of the
--    returned time series.  'T' = true, 'F' = false.
--
-- p_start_inclusive
--    Specifies whether p_start_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_end_inclusive
--    Specifies whether p_end_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_previous
--    Specifies whether to retrieve the latest value before the beginning of
--    the time window.  'T' = true, 'F' = false.
--
-- p_next
--    Specifies whether to retrieve the earliest value after the end of
--    the time window.  'T' = true, 'F' = false.
--
-- p_version_date
--    If not null, specifies the version date for versioned data. If null, the 
--    earliest or latest version date is used depending on the value of the 
--    p_max_version parameter.
--
-- p_max_version
--    Used only if the p_version_date parameter is null.  'T' = use the latest
--    version date for versioned data.  'F' = use the earliest version date
--    for versioned data.  Retrieving non-versioned data is not affected by
--    this parameter.
--
-- p_ts_office_id
--    The office id to be used with the time series identifier. If null, the 
--    current session user is used.
--
-- p_rating_office_id
--    The office id to be used with the rating identifier. If null, the 
--    current session user is used.
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
   return ztsv_array;
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates the specified independent time series with the specified rating 
-- and stores the results in the specified dependent time series.
--
-- p_independent_ids
--    The independent time series to be rated with the specified rating
--
-- p_dependent_id
--    The dependent (rated) time series to be stored 
--
-- p_rating_id
--    The rating to use
--
-- p_start_time
--    The beginning of time window for the time series
--
-- p_end_time
--    The end of time window for the time series
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret all date parameters. If null, the 
--    time zone associated with the location in the p_rating_spec parameter 
--    will be used. If no time zone is associated with the location, UTC will 
--    be used. The location is taken from the first item in the 
--    p_independent_ids parameter.
--
-- p_trim
--    Specifies whether to trim null values from the beginning and end of the
--    rated time series.  'T' = true, 'F' = false.
--
-- p_start_inclusive
--    Specifies whether p_start_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_end_inclusive
--    Specifies whether p_end_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_previous
--    Specifies whether to retrieve the latest value before the beginning of
--    the time window.  'T' = true, 'F' = false.
--
-- p_next
--    Specifies whether to retrieve the earliest value after the end of
--    the time window.  'T' = true, 'F' = false.
--
-- p_version_date
--    If not null, specifies the version date for versioned data. If null, the 
--    earliest or latest version date is used depending on the value of the 
--    p_max_version parameter.
--
-- p_max_version
--    Used only if the p_version_date parameter is null.  'T' = use the latest
--    version date for versioned data.  'F' = use the earliest version date
--    for versioned data.  Retrieving non-versioned data is not affected by
--    this parameter.
--
-- p_ts_office_id
--    The office id to be used with the time series identifiers. If null, the 
--    current session user is used.
--
-- p_rating_office_id
--    The office id to be used with the rating identifier. If null, the 
--    current session user is used.
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
   p_rating_office_id in varchar2 default null);
   
--------------------------------------------------------------------------------
-- RATE
--
-- Rates the specified independent time series with the specified rating 
-- and stores the results in the specified dependent time series.
--
-- p_independent_id
--    The independent time series to be rated with the specified rating
--
-- p_dependent_id
--    The dependent (rated) time series to be stored 
--
-- p_rating_id
--    The rating to use
--
-- p_start_time
--    The beginning of time window for the time series
--
-- p_end_time
--    The end of time window for the time series
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret all date parameters. If null, the 
--    time zone associated with the location in the p_rating_spec parameter 
--    will be used. If no time zone is associated with the location, UTC will 
--    be used. The location is taken from the p_independent_id parameter.
--
-- p_trim
--    Specifies whether to trim null values from the beginning and end of the
--    rated time series.  'T' = true, 'F' = false.
--
-- p_start_inclusive
--    Specifies whether p_start_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_end_inclusive
--    Specifies whether p_end_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_previous
--    Specifies whether to retrieve the latest value before the beginning of
--    the time window.  'T' = true, 'F' = false.
--
-- p_next
--    Specifies whether to retrieve the earliest value after the end of
--    the time window.  'T' = true, 'F' = false.
--
-- p_version_date
--    If not null, specifies the version date for versioned data. If null, the 
--    earliest or latest version date is used depending on the value of the 
--    p_max_version parameter.
--
-- p_max_version
--    Used only if the p_version_date parameter is null.  'T' = use the latest
--    version date for versioned data.  'F' = use the earliest version date
--    for versioned data.  Retrieving non-versioned data is not affected by
--    this parameter.
--
-- p_ts_office_id
--    The office id to be used with the time series identifiers. If null, the 
--    current session user is used.
--
-- p_rating_office_id
--    The office id to be used with the rating identifier. If null, the 
--    current session user is used.
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
   p_rating_office_id in varchar2 default null);

--------------------------------------------------------------------------------
-- RETRIEVE_REVERSE_RATED_TS
--
-- Retrieves a time series that is the result of reverse rating the 
-- specified time series with the specified rating.
--
-- p_dependent_id
--    The dependent time series to be reverse rated with the specified 
--    rating.
--
-- p_rating_id
--    The rating to use
--
-- p_units
--    The unit in which to return the rated time series
--
-- p_start_time
--    The beginning of time window for the time series
--
-- p_end_time
--    The end of time window for the time series
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret all date parameters, and in which 
--    to return the data times. If null, the time zone associated with the 
--    location in the p_rating_spec parameter will be used. If no time zone is 
--    associated with the location, UTC will be used. The location is taken 
--    from the p_independent_id parameter.
--
-- p_round
--    Specifies whether to round the returned values according to the rounding
--    specification contained in the rating specification.
--
-- p_trim
--    Specifies whether to trim null values from the beginning and end of the
--    returned time series.  'T' = true, 'F' = false.
--
-- p_start_inclusive
--    Specifies whether p_start_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_end_inclusive
--    Specifies whether p_end_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_previous
--    Specifies whether to retrieve the latest value before the beginning of
--    the time window.  'T' = true, 'F' = false.
--
-- p_next
--    Specifies whether to retrieve the earliest value after the end of
--    the time window.  'T' = true, 'F' = false.
--
-- p_version_date
--    If not null, specifies the version date for versioned data. If null, the 
--    earliest or latest version date is used depending on the value of the 
--    p_max_version parameter.
--
-- p_max_version
--    Used only if the p_version_date parameter is null.  'T' = use the latest
--    version date for versioned data.  'F' = use the earliest version date
--    for versioned data.  Retrieving non-versioned data is not affected by
--    this parameter.
--
-- p_ts_office_id
--    The office id to be used with the time series identifier. If null, the 
--    current session user is used.
--
-- p_rating_office_id
--    The office id to be used with the rating identifier. If null, the 
--    current session user is used.
--
--
function retrieve_reverse_rated_ts(
   p_dependent_id     in varchar2,
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
   return ztsv_array;
   
--------------------------------------------------------------------------------
-- REVERSE_RATE
--
-- Reverse rates the specified dependent time series with the specified 
-- rating and stores the results in the specified independent time series.
--
-- p_independent_id
--    The independent time series to be reverse rated with the specified 
--    rating and stored.
--
-- p_dependent_id
--    The dependent time series to be reverse rated 
--
-- p_rating_id
--    The rating to use
--
-- p_start_time
--    The beginning of time window for the time series
--
-- p_end_time
--    The end of time window for the time series
--
-- p_rating_time
--    The "current time" of the rating operation.  If specified, this is the
--    historical time at which to perform the rating operation.  No ratings with
--    a creation date later than this time will be used so that ratings can be
--    performed according only to information that was known at the time.  If 
--    null, the current time is used. 
--
-- p_time_zone
--    The time zone with which to interpret all date parameters. If null, the 
--    time zone associated with the location in the p_rating_spec parameter 
--    will be used. If no time zone is associated with the location, UTC will 
--    be used. The location is taken from the p_independent_ids parameter.
--
-- p_trim
--    Specifies whether to trim null values from the beginning and end of the
--    rated time series.  'T' = true, 'F' = false.
--
-- p_start_inclusive
--    Specifies whether p_start_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_end_inclusive
--    Specifies whether p_end_time is included in the time_window. 'T' = true,
--    'F' = false
--
-- p_previous
--    Specifies whether to retrieve the latest value before the beginning of
--    the time window.  'T' = true, 'F' = false.
--
-- p_next
--    Specifies whether to retrieve the earliest value after the end of
--    the time window.  'T' = true, 'F' = false.
--
-- p_version_date
--    If not null, specifies the version date for versioned data. If null, the 
--    earliest or latest version date is used depending on the value of the 
--    p_max_version parameter.
--
-- p_max_version
--    Used only if the p_version_date parameter is null.  'T' = use the latest
--    version date for versioned data.  'F' = use the earliest version date
--    for versioned data.  Retrieving non-versioned data is not affected by
--    this parameter.
--
-- p_ts_office_id
--    The office id to be used with the time series identifiers. If null, the 
--    current session user is used.
--
-- p_rating_office_id
--    The office id to be used with the rating identifier. If null, the 
--    current session user is used.
--
procedure reverse_rate(
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
   p_rating_office_id in varchar2 default null);
    
--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The values to round: one or more values of one or more independent 
--    parameters
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_independent(
   p_independent in out nocopy double_tab_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);   
    
--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The values to round: one or more values of a single independent parameter
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_independent(
   p_independent in out nocopy double_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);   
    
--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The values to round: one or more values of a single independent parameter
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_independent(
   p_independent in out nocopy tsv_array,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);   
    
--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The values to round: one or more values of a single independent parameter
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_independent(
   p_independent in out nocopy ztsv_array,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);   
    
--------------------------------------------------------------------------------
-- ROUND_ONE_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The values to round: a single set of values for one or more independent
--    parameters
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_one_independent(
   p_independent in out nocopy double_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
    
--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The value to round: a single value for a single independent parameter
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_independent(
   p_independent in out nocopy binary_double,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);   
    
--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The value to round: a single value for a single independent parameter
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_independent(
   p_independent in out nocopy tsv_type,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);   
    
--------------------------------------------------------------------------------
-- ROUND_INDEPENDENT
--
-- Rounds independent values accoring to the rounding specifications contained
-- in the rating specification
--
-- p_independent
--    The value to round: a single value for a single independent parameter
--
-- p_rating_id
--    The rating id of the rating specification to use
--
-- p_office_id
--    The owning office of the rating specification to use.  If null, then the
--    current session user is used.
--
procedure round_independent(
   p_independent in out nocopy ztsv_type,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);   
      
end;
/                                                       
show errors;

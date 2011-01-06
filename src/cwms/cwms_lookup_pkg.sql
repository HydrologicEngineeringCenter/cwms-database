create or replace package cwms_lookup
as

--------------------------------------------------------------------------------
-- TYPES
--------------------------------------------------------------------------------
type sequence_properties_t is record(
   null_value       boolean,
   increasing_range boolean,
   decreasing_range boolean,
   constant_range   boolean);
   
type method_array_t is table of pls_integer index by varchar2(32);
   
--------------------------------------------------------------------------------
-- PACKAGE VARIABLES (SET AT THE BOTTOM OF THE PACKAGE BODY)
--------------------------------------------------------------------------------
method_null        pls_integer;  -- Return null if between values or outside range                                             
method_error       pls_integer;  -- Raise an exception if between values or outside range                                      
method_linear      pls_integer;  -- Linear interpolation or extrapolation of independent and dependent values                  
method_logarithmic pls_integer;  -- Logarithmic interpolation or extrapolation of independent and dependent values             
method_lin_log     pls_integer;  -- Linear interpolation/extrapoloation of independent values, Logarithmic of dependent values 
method_log_lin     pls_integer;  -- Logarithmic interpolation/extrapoloation of independent values, Linear of dependent values 
method_conic       pls_integer;  -- Conic interpolation or extrapolation                                                       
method_previous    pls_integer;  -- Return the value that is lower in position                                                 
method_next        pls_integer;  -- Return the value that is higher in position                                                
method_nearest     pls_integer;  -- Return the value that is nearest in position                                               
method_lower       pls_integer;  -- Return the value that is lower in magnitude                                                
method_higher      pls_integer;  -- Return the value that is higher in magnitude                                               
method_closest     pls_integer;  -- Return the value that is closest in magnitude

method_by_name method_array_t;                                               

--------------------------------------------------------------------------------
-- FUNCTION analyze_sequence
--------------------------------------------------------------------------------
function analyze_sequence(
   p_sequence in number_tab_t)
   return sequence_properties_t;

function analyze_sequence(
   p_sequence in double_tab_t)
   return sequence_properties_t;

--------------------------------------------------------------------------------
-- FUNCTION find_high_index
--------------------------------------------------------------------------------
function find_high_index(
   p_value           in number,
   p_sequence        in number_tab_t,
   p_properties      in sequence_properties_t default null)
   return pls_integer;
   
--------------------------------------------------------------------------------
-- FUNCTION find_high_index
--------------------------------------------------------------------------------
function find_high_index(
   p_value           in binary_double,
   p_sequence        in double_tab_t,
   p_properties      in sequence_properties_t default null)
   return pls_integer;
   
--------------------------------------------------------------------------------
-- FUNCTION find_ratio
--------------------------------------------------------------------------------
function find_ratio(
   p_log_used                out boolean,
   p_value                   in  number,
   p_sequence                in  number_tab_t,
   p_high_index              in  pls_integer,
   p_increasing              in  boolean,
   p_in_range_behavior       in  pls_integer default method_linear,
   p_out_range_low_behavior  in  pls_integer default method_null,
   p_out_range_high_behavior in  pls_integer default method_null)
   return number;

--------------------------------------------------------------------------------
-- FUNCTION find_ratio
--------------------------------------------------------------------------------
function find_ratio(
   p_log_used                out boolean,
   p_value                   in  binary_double,
   p_sequence                in  double_tab_t,
   p_high_index              in  pls_integer,
   p_increasing              in  boolean,
   p_in_range_behavior       in  pls_integer default method_linear,
   p_out_range_low_behavior  in  pls_integer default method_null,
   p_out_range_high_behavior in  pls_integer default method_null)
   return binary_double;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_value                   in number,
   p_independent             in number_tab_t,
   p_dependent               in number_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return number;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_value                   in binary_double,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return binary_double;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_values                  in number_tab_t,
   p_independent             in number_tab_t,
   p_dependent               in number_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return number_tab_t;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_values                  in double_tab_t,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return double_tab_t;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_array                   in tsv_array,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return tsv_array;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_array                   in ztsv_array,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return ztsv_array;

end cwms_lookup;
/
commit;
show errors;
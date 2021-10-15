create or replace package cwms_lookup
/**
 * Provides facilities for
 * <ul>
 * <li>looking up the position of a value within and ordered sequence of values</li>
 * <li>looking up dependent values corresponding to independent values in the context
 *     of a function specified by independent and dependent sequences of values</li>
 * </ul>
 * 
 * @author Mike Perryman
 * @since CWMS 2.1    
 */
as

--------------------------------------------------------------------------------
-- TYPES
--------------------------------------------------------------------------------
/**
 * Holds important properties about an ordered sequence of values. 
 *
 * @member null_value Specifies whether the sequence contains any <big><code>NULL</code></big>
 *         elememts
 * @member increasing_range Specifies whether the sequence has any adjacent elements
 *         in which the one with the greater position also a greater value
 * @member increasing_range Specifies whether the sequence has any adjacent elements
 *         in which the one with the greater position has a lesser value
 * @member increasing_range Specifies whether the sequence has any adjacent elements
 *         of the same value
 */
type sequence_properties_t is record(
   null_value       boolean,
   increasing_range boolean,
   decreasing_range boolean,
   constant_range   boolean);
   
/**
 * Provides for accessing a method number by its name.
 */   
type method_array_t is table of pls_integer index by varchar2(32);
   
--------------------------------------------------------------------------------
-- PACKAGE VARIABLES (SET AT THE BOTTOM OF THE PACKAGE BODY)
--------------------------------------------------------------------------------
/**
 * Return null if between values or outside range
 */
method_null        pls_integer;                                               
/**
 * Raise an exception if between values or outside range
 */
method_error       pls_integer;                                        
/**
 * Linear interpolation or extrapolation of independent and dependent values 
 */
method_linear      pls_integer;                    
/**
 * Logarithmic interpolation or extrapolation of independent and dependent values 
 */
method_logarithmic pls_integer;               
/**
 * Linear interpolation/extrapoloation of independent values, Logarithmic of dependent values 
 */
method_lin_log     pls_integer;   
/**
 * Logarithmic interpolation/extrapoloation of independent values, Linear of dependent values 
 */
method_log_lin     pls_integer;   
/**
 * Return the value that is lower in position 
 */
method_previous    pls_integer;                                                   
/**
 * Return the value that is higher in position 
 */
method_next        pls_integer;                                                  
/**
 * Return the value that is nearest in position 
 */
method_nearest     pls_integer;                                                 
/**
 * Return the value that is lower in magnitude 
 */
method_lower       pls_integer;                                                  
/**
 * Return the value that is higher in magnitude 
 */
method_higher      pls_integer;                                                 
/**
 * Return the value that is closest in magnitude 
 */
method_closest     pls_integer;  

/**
 * Holds method numbers by name 
 */
method_by_name method_array_t;                                               

--------------------------------------------------------------------------------
-- ROUTINES
--------------------------------------------------------------------------------
/**
 * Analyzes the properties of an ordered sequence of values
 * 
 * @param p_sequence The ordered sequence of values
 * @return The sequece properties   
 */ 
function analyze_sequence(
   p_sequence in number_tab_t)
   return sequence_properties_t;
/**
 * Analyzes the properties of an ordered sequence of values
 * 
 * @param p_sequence The ordered sequence of values
 * @return The sequece properties   
 */ 
function analyze_sequence(
   p_sequence in double_tab_t)
   return sequence_properties_t;
/**
 * Finds the larger of the two sequence positions to be used for interpolate
 * or extrapolation.
 * 
 * @param p_value the value to be interpolated or extrapolated for
 * @param p_sequece the sequence of values to be interpolated or extrapolated
 * @param p_properties the sequence properties. If <code>NULL</code> the sequence
 *        will be analyzed for properties
 * @return the larger of the two sequence positions to be used for interpolation
 * or extrapolation.                 
 */    
function find_high_index(
   p_value           in number,
   p_sequence        in number_tab_t,
   p_properties      in sequence_properties_t default null)
   return pls_integer;
/**
 * Finds the larger of the two sequence positions to be used for interpolate
 * or extrapolation.
 * 
 * @param p_value the value to be interpolated or extrapolated for
 * @param p_sequece the sequence of values to be interpolated or extrapolated
 * @param p_properties the sequence properties. If <code>NULL</code> the sequence
 *        will be analyzed for properties
 * @return the larger of the two sequence positions to be used for interpolation
 * or extrapolation.                 
 */    
function find_high_index(
   p_value           in binary_double,
   p_sequence        in double_tab_t,
   p_properties      in sequence_properties_t default null)
   return pls_integer;
/**
 * Finds the ratio of a value between bounding values in an ordered sequence of
 * values. For interpolation 0 <= ratio <= 1. For extrapolation ratio < 0 or 
 * ratio > 1.
 * @param p_log_used specifies whether logarthmic interpolation was used.
 * @param p_value the value for which to find the ratio
 * @param p_sequence the sequence of values in which to find the ratio
 * @param p_high_index the larger of the two sequence positions to be used for 
 *        interpolation or extrapolation
 * @param p_increasing specifies whether the values of the sequence increase
 *        with increasing position
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return the interpolation or extrapolation ratio                              
 */    
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
/**
 * Finds the ratio of a value between bounding values in an ordered sequence of
 * values. For interpolation 0 <= ratio <= 1. For extrapolation ratio < 0 or 
 * ratio > 1.
 * @param p_log_used specifies whether logarthmic interpolation was used.
 * @param p_value the value for which to find the ratio
 * @param p_sequence the sequence of values in which to find the ratio
 * @param p_high_index the larger of the two sequence positions to be used for 
 *        interpolation or extrapolation
 * @param p_increasing specifies whether the values of the sequence increase
 *        with increasing position
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return the interpolation or extrapolation ratio                              
 */    
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
/**
 * Looks up the dependent value corresponding to a specified independent value
 * in the context of a function specified by independent and dependent sequences 
 *  
 * @param p_value the independent value for which to look up a dependent value
 * @param p_independent values for the  function domain  
 * @param p_dependent values for the function range
 * @param p_independent_properties the independent sequence properties. If 
 *        <code>NULL</code> the sequence will be analyzed for properties
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return dependent value corresponding to the specified independent value                              
 */    
function lookup(
   p_value                   in number,
   p_independent             in number_tab_t,
   p_dependent               in number_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return number;
/**
 * Looks up the dependent value corresponding to a specified independent value
 * in the context of a function specified by independent and dependent sequences 
 *  
 * @param p_value the independent value for which to look up a dependent value
 * @param p_independent values for the  function domain  
 * @param p_dependent values for the function range
 * @param p_independent_properties the independent sequence properties. If 
 *        <code>NULL</code> the sequence will be analyzed for properties
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return dependent value corresponding to the specified independent value                              
 */    
function lookup(
   p_value                   in binary_double,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return binary_double;
/**
 * Looks up the dependent values corresponding to a specified set of independent values
 * in the context of a function specified by independent and dependent sequences 
 *  
 * @param p_value the independent value for which to look up a dependent value
 * @param p_independent values for the  function domain  
 * @param p_dependent values for the function range
 * @param p_independent_properties the independent sequence properties. If 
 *        <code>NULL</code> the sequence will be analyzed for properties
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return dependent values corresponding to the specified independent values                              
 */    
function lookup(
   p_values                  in number_tab_t,
   p_independent             in number_tab_t,
   p_dependent               in number_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return number_tab_t;
/**
 * Looks up the dependent values corresponding to a specified set of independent values
 * in the context of a function specified by independent and dependent sequences 
 *  
 * @param p_value the independent value for which to look up a dependent value
 * @param p_independent values for the  function domain  
 * @param p_dependent values for the function range
 * @param p_independent_properties the independent sequence properties. If 
 *        <code>NULL</code> the sequence will be analyzed for properties
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return dependent values corresponding to the specified independent values                              
 */    
function lookup(
   p_values                  in double_tab_t,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return double_tab_t;
/**
 * Looks up the dependent values corresponding to a specified set of independent values
 * in the context of a function specified by independent and dependent sequences 
 *  
 * @param p_value the independent value for which to look up a dependent value
 * @param p_independent values for the  function domain  
 * @param p_dependent values for the function range
 * @param p_independent_properties the independent sequence properties. If 
 *        <code>NULL</code> the sequence will be analyzed for properties
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return dependent values corresponding to the specified independent values                              
 */    
function lookup(
   p_array                   in tsv_array,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return tsv_array;
/**
 * Looks up the dependent values corresponding to a specified set of independent values
 * in the context of a function specified by independent and dependent sequences 
 *  
 * @param p_value the independent value for which to look up a dependent value
 * @param p_independent values for the  function domain  
 * @param p_dependent values for the function range
 * @param p_independent_properties the independent sequence properties. If 
 *        <code>NULL</code> the sequence will be analyzed for properties
 * @param p_in_range_behavior the behavior to use if the value is able to be
 *        interpolated
 * @param p_out_range_low_behavior the behavior to use if the value is below
 *        the least value in the sequence                     
 * @param p_out_range_high_behavior the behavior to use if the value is avove
 *        the greatest value in the sequence
 * @return dependent values corresponding to the specified independent values                              
 */    
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
create or replace package cwms_rounding
/**
 * Facilities for numerical rounding based on magnitude of number.<p>
 * This package
 * uses USGS-style rounding arrays (called rounding specifications in this package)
 * to specify the number of significant digits to display for various magnitudes
 * of numbers. The full description of using rounding arrays can be found in
 * Section 3.5 (Data Rounding Convention) of the <a href="http://pubs.usgs.gov/of/2003/ofr03123/">ADAPS Section
 * of the National Water Information System User's Manual</a>.
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.1
 */
as
/**
 * Returns a number rounded to a specified number of significant digits.  This differs
 * from the SQL round function in that it specifies the number of significant digits
 * instead of the number of decimal places.
 *
 * @param p_value      The number to round as an Oracle NUMBER type
 * @param p_sig_digits The number of significant digits to keep in the rounded number
 *
 * @return The rounded number as an Oracle NUMBER type
 */
function round_f(
   p_value         in number,
   p_sig_digits    in integer,
   p_round_to_even in varchar2 default 'T')
return number deterministic;
/**
 * Returns a number rounded to a specified number of significant digits.  This differs
 * from the SQL round function in that it specifies the number of significant digits
 * instead of the number of decimal places.
 *
 * @param p_value      The number to round as an Oracle BINARY_DOUBLE type
 * @param p_sig_digits The number of significant digits to keep in the rounded number
 *
 * @return The rounded number as an Oracle BINARY_DOUBLE type
 */
function round_f(
   p_value         in binary_double,
   p_sig_digits    in integer,
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_nn_f(
   p_value         in number,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return number deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_nd_f(
   p_value         in number,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_nt_f(
   p_value         in number,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return varchar2 deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_dd_f(
   p_value         in binary_double,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_dn_f(
   p_value         in binary_double,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return number deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_dt_f(
   p_value         in binary_double,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return varchar2 deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_td_f(
   p_value         in varchar2,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_tn_f(
   p_value         in varchar2,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return number deterministic;
/**
 * Returns a number rounded according to a rounding specification.
 *
 * @param p_value         The value to be rounded
 * @param p_rounding_spec The USGS-style rounding specification
 *
 * @return The rounded value
 */
function round_tt_f(
   p_value         in varchar2,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return varchar2 deterministic;
/**
 * Rounds a collection of values according to a rounding specification
 *
 * @param p_values        The values. On input the values to be rounded. On output the rounded values.
 * @param p_rounding_spec The USGS-style rounding specification
 */
procedure round_n_tab(
   p_values        in out nocopy number_tab_t,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T');
/**
 * Rounds a collection of values according to a rounding specification
 *
 * @param p_values        The values. On input the values to be rounded. On output the rounded values.
 * @param p_rounding_spec The USGS-style rounding specification
 */
procedure round_d_tab(
   p_values        in out nocopy double_tab_t,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T');
/**
 * Rounds a collection of values according to a rounding specification
 *
 * @param p_values        The values. On input the values to be rounded. On output the rounded values.
 * @param p_rounding_spec The USGS-style rounding specification
 */
procedure round_t_tab(
   p_values        in out nocopy str_tab_t,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T');
/**
 * Rounds values of a time series according to a rounding specification
 *
 * @param p_values        The time series. On input the values to be rounded. On output the rounded values.
 * @param p_rounding_spec The USGS-style rounding specification
 */
procedure round_tsv_array(
   p_values        in out nocopy tsv_array,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T');
/**
 * Rounds values of a time series according to a rounding specification
 *
 * @param p_values        The time series. On input the values to be rounded. On output the rounded values.
 * @param p_rounding_spec The USGS-style rounding specification
 */
procedure round_ztsv_array(
   p_values        in out nocopy ztsv_array,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T');

end cwms_rounding;
/

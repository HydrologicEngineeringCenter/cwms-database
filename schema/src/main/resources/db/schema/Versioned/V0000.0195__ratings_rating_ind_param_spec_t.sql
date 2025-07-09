create type rating_ind_param_spec_t
/**
 * Holds information about an independent parameter for ratings
 *
 * @see cwms_lookup.method_null
 * @see cwms_lookup.method_error
 * @see cwms_lookup.method_linear
 * @see cwms_lookup.method_logarithmic
 * @see cwms_lookup.method_lin_log
 * @see cwms_lookup.method_log_lin
 * @see cwms_lookup.method_previous
 * @see cwms_lookup.method_next
 * @see cwms_lookup.method_nearest
 * @see cwms_lookup.method_lower
 * @see cwms_lookup.method_higher
 * @see cwms_lookup.method_closest
 * @see type rating_ind_param_spec_tab_t
 *
 * @member parameter_position           The parameter position for this independent parameter. 1 specifies the first (or only) independent parameter, etc...
 * @member parameter_id                 The CWMS parameter identifier for this independent parameter
 * @member in_range_rating_method       The rating behavior when a table of values for this independent parameter encompasses the value to be looked up
 * @member out_range_low_rating_method  The rating behavior when the least value in a table of values for this independent parameter is greater than the value to be looked up
 * @member out_range_high_rating_method The rating behavior when the greatest value in a table of values for this independent parameter is less than the value to be looked up
 */
as object(
   parameter_position           number(1),
   parameter_id                 varchar2(49),
   in_range_rating_method       varchar2(32),
   out_range_low_rating_method  varchar2(32),
   out_range_high_rating_method varchar2(32),
   
   /**
    * Constructs a rating_ind_param_spec_t object from a record in the AT_RATING_IND_PARAM_SPEC table
    *
    * @param p_ind_param_spec_code The primary key for the record
    */
   constructor function rating_ind_param_spec_t(
      p_ind_param_spec_code in number)
   return self as result,
   /**
    * Constructs a rating_ind_param_spec_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_ind_param_spec_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure validate_obj,
   /**
    * Retrieves the CWMS parameter code for this independent parameter
    *
    * @param p_office_id Specifies the office for which to retrieve the parameter code
    */
   member function get_parameter_code(
      p_office_id in varchar2)
   return number,
   -- not documented
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
   -- not documented
   member function get_in_range_rating_code
   return number,
   -- not documented
   member function get_out_range_low_rating_code
   return number,
   -- not documented
   member function get_out_range_high_rating_code
   return number,
   -- not documented
   member procedure store(
      p_template_code  in number,
      p_fail_if_exists in varchar2),
   -- not documented
   member function to_xml
   return xmltype,      
   -- not documented
   member function to_clob
   return clob      
);
/


create or replace public synonym cwms_t_rating_ind_param_spec for rating_ind_param_spec_t;


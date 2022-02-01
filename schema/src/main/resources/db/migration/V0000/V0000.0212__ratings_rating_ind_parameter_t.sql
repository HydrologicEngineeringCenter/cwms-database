create type rating_ind_parameter_t
/**
 * Holds rating lookup values and optionally extension lookup values for an independent parameter
 *
 * @member rating_values    The rating lookup values that apply to this independent parameter
 * @member extension_values The rating extension, if any, that applies to this independent parameter
 */
under abs_rating_ind_param_t(
   rating_values      rating_value_tab_t,
   extension_values   rating_value_tab_t,
   /**
    * Zero-parameter constructor.  Constructs a rating_ind_parameter_t object with all fields NULL
    */
   constructor function rating_ind_parameter_t
   return self as result,
   /**
    * Constructs a rating_ind_parameter_t object from a record in the AT_RATING_IND_PARAMETER table.
    * The object will be for the lowest-position (or only) independent parameter for the
    * specified rating code.
    *
    * @param p_rating_code.  The CWMS rating code for which to create the object.
    */
   constructor function rating_ind_parameter_t(
      p_rating_code in number)
   return self as result,
   /**
    * Constructs a rating_ind_parameter_t object from a record in the AT_RATING_IND_PARAMETER table.
    * The object will be for the independent parameter position that is one greater than the
    * length of the p_other_ind parameter and will be for the specific independent parameter
    * values specified in the p_other_ind paramter
    *
    * @param p_rating_code The CWMS rating code for which to create the object.
    * @param p_other_ind   The lower-position independent paramter values for which to construct the object
    */
   constructor function rating_ind_parameter_t(
      p_rating_code in number,
      p_other_ind   in double_tab_t)
   return self as result,
   -- not documented
   constructor function rating_ind_parameter_t(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t,
      p_additional_ind            in binary_double)
   return self as result,
   -- not documented
   constructor function rating_ind_parameter_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   overriding member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t),
   -- not documented
   overriding member procedure validate_obj(
      p_parameter_position in number),
   -- not documented
   overriding member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   -- not documented
   overriding member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   -- not documented
   overriding member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   -- not documented
   overriding member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   overriding member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob,
   -- not documented
   overriding member function to_xml
   return xmltype,
   -- not documented
   overriding member procedure add_offset(
      p_offset in binary_double,
      p_depth  in pls_integer),    
   -- not documented
   overriding member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double,
   -- not documented
   static function get_rating_ind_parameter_code(
      p_rating_code in number)
   return number      
);
/


create or replace public synonym cwms_t_rating_ind_parameter for rating_ind_parameter_t;


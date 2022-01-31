create type abs_rating_ind_param_t
/**
 * Abstract base type for type rating_ind_parameter_t.  This type is necessary to
 * allow ratings to rating_ind_parameter_t objects to have recursive self references
 * through the rating_value_tab_t and rating_value_t types.
 *
 * @see type rating_value_t
 * @see type rating_ind_parameter_t
 *
 * @member constructed A flag ('T' or 'F') specifying whether the construction of
 *         the object has been completed
 */
as object(
   constructed varchar2(1),
   -- not documented
   member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t),
   -- not documented
   member procedure validate_obj(
      p_parameter_position in number),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob,
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function to_xml
   return xmltype,
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure add_offset(
      p_offset in binary_double,
      p_depth  in pls_integer),    
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double
      
) not final
  not instantiable;
/


create or replace public synonym cwms_t_abs_rating_ind_param for abs_rating_ind_param_t;


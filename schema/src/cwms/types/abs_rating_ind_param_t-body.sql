create or replace type body abs_rating_ind_param_t
as

   member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t)
   is begin null; end;      
      
   member procedure validate_obj(
      p_parameter_position in number)
   is begin null; end;

   member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2)
   is begin null; end;

   member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2)
   is begin null; end;
               
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2)
   is begin null; end;
      
   member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2)
   is begin null; end;
      
   member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob
   is begin null; end;
   
   member function to_xml
   return xmltype
   is begin null; end;      
   
   member procedure add_offset(
      p_offset in binary_double,
      p_depth  in pls_integer)
   is begin null; end;    
   
   member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double
   is begin null; end;      
   
end;
/   
show errors;

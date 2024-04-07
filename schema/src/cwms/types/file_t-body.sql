create or replace type body file_t as
   
   map member function to_string
      return varchar2
   is
   begin
      cwms_err.raise('ERROR', 'Validate procedure cannot be called on abstract type');
   end to_string;
   
   member procedure validate_obj
   is
   begin
      cwms_err.raise('ERROR', 'Validate procedure cannot be called on abstract type');
   end validate_obj;

end;
/

show errors;
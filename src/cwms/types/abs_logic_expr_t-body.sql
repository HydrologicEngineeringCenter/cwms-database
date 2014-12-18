create type body abs_logic_expr_t
as
   member function evaluate(
      p_args   in double_tab_t,
      p_args_offset in integer default 0)
      return boolean
   is
   begin
      cwms_err.raise('ERROR', 'Evaluate function cannot be called on abstract type');
   end evaluate;
   
   member procedure print(
      p_level in integer default 0)
   is
   begin
      cwms_err.raise('ERROR', 'Print procedure cannot be called on abstract type');
   end print;
      
   member function to_algebraic( 
      self in out nocopy abs_logic_expr_t)
      return varchar2
   is
   begin
      cwms_err.raise('ERROR', 'To_algebraic function cannot be called on abstract type');
   end to_algebraic;      
   
   member procedure to_algebraic(
      p_expr in out nocopy varchar2)
   is
   begin
      cwms_err.raise('ERROR', 'To_algebraic procedure cannot be called on abstract type');
   end to_algebraic;
   
   member function to_rpn( 
      self in out nocopy abs_logic_expr_t)
      return varchar2
   is
   begin
      cwms_err.raise('ERROR', 'To_rpn function cannot be called on abstract type');
   end to_rpn;      
   
   member procedure to_rpn(
      p_expr in out nocopy varchar2)
   is
   begin
      cwms_err.raise('ERROR', 'To_rpn procedure cannot be called on abstract type');
   end to_rpn;                           
   
   member function to_xml_text return varchar2
   is
   begin
      cwms_err.raise('ERROR', 'to_xml_text function cannot be called on abstract type');
   end to_xml_text;      
end;
/
show errors;
commit;


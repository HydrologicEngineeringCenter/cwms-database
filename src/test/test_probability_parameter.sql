create or replace package test_probability_parameter as

--%suite(Test schema for presence of Probability Base Parameter)

--%rollback(manual)

--%test(Test for Probability Base Parameter)
procedure test_for_parameter;
end test_probability_parameter;
/
create or replace package body test_probability_parameter as
procedure test_for_parameter
is
   l_base_parameter_code cwms_base_parameter.base_parameter_code%type;
begin
   begin
      select base_parameter_code
        into l_base_parameter_code
        from cwms_base_parameter
       where base_parameter_id = 'Probability';
   exception
      when no_data_found then null;
   end;   
    
   ut.expect(l_base_parameter_code).to_equal(48);    
end test_for_parameter;

end test_probability_parameter;
/

grant execute on test_probability_parameter to cwms_user;
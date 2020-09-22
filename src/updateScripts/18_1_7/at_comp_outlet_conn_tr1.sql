create or replace trigger at_comp_outlet_conn_tr1
   before insert
   on at_comp_outlet_conn
   referencing new as new old as old
   for each row
declare
   l_proj_code1 number(14);
   l_proj_code2 number(14);
begin
   select project_location_code
     into l_proj_code1
     from at_comp_outlet
    where compound_outlet_code = :new.compound_outlet_code;

   select project_location_code
     into l_proj_code2
     from at_outlet
    where outlet_location_code = :new.outlet_location_code;

   if l_proj_code1 != l_proj_code2 then
      cwms_err.raise('ERROR', 'Cannot assign outlet from one project to a compound outlet from another project');
   end if;

   if :new.next_outlet_code is not null then
      select project_location_code
        into l_proj_code2
        from at_outlet
       where outlet_location_code = :new.next_outlet_code;

      if l_proj_code1 != l_proj_code2 then
         cwms_err.raise('ERROR', 'Cannot assign outlet from one project to a compound outlet from another project');
      end if;
   end if;
end at_comp_outlet_conn_tr1;
/


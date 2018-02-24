declare
   l_matching_code    integer;
   l_cwms_office_code integer;
   l_host_office_code integer;
begin
   --------------------------
   -- get the office codes --
   --------------------------
   l_cwms_office_code := cwms_util.db_office_code_all;
   begin
      select office_code
        into l_host_office_code
        from cwms_office
       where eroc = (select substr(db_unique_name, 1, 2) from v$database);
   exception
      when no_data_found then null;
   end;
   -------------------------------
   -- insert the common records --
   -------------------------------
   insert into at_turbine_computation_code values(1, l_cwms_office_code, 'C', 'Calculated from turbine load-nethead curves', 'T');
   insert into at_turbine_computation_code values(2, l_cwms_office_code, 'T', 'Calculated from tailwater curve',             'T');
   insert into at_turbine_computation_code values(3, l_cwms_office_code, 'R', 'Reported by powerhouse',                      'T');
   insert into at_turbine_computation_code values(4, l_cwms_office_code, 'A', 'Adjusted by an automated method',             'T');

   if l_host_office_code is not null then
      ----------------------------------------------------------------------
      -- delete any local records that are replaced by the common records --
      ----------------------------------------------------------------------
      for rec in (select * 
                    from at_turbine_computation_code
                   where db_office_code = l_cwms_office_code 
                   order by turbine_comp_code
                 )                                         
      loop
         -------------------------------
         -- get the local record code --                                            
         -------------------------------
         select turbine_comp_code
           into l_matching_code
           from at_turbine_computation_code
          where turbine_comp_display_value = rec.turbine_comp_display_value
            and db_office_code = l_host_office_code;
         ----------------------------------------------------------
         -- update values foreign keyed to the local record code --
         ----------------------------------------------------------
         update at_turbine_change
            set turbine_discharge_comp_code = rec.turbine_comp_code
          where turbine_discharge_comp_code = l_matching_code;  
         -----------------------------
         -- delete the local record --
         -----------------------------
         delete
           from at_turbine_computation_code
          where turbine_comp_code = l_matching_code; 
      end loop;
   end if;
end;   
/

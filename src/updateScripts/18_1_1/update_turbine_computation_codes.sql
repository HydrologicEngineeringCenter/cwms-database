-------------------------------
-- insert the common records --
-------------------------------
insert into at_turbine_computation_code values(1, 53, 'C', 'Calculated from turbine load-nethead curves', 'T');
insert into at_turbine_computation_code values(2, 53, 'T', 'Calculated from tailwater curve',             'T');
insert into at_turbine_computation_code values(3, 53, 'R', 'Reported by powerhouse',                      'T');
insert into at_turbine_computation_code values(4, 53, 'A', 'Adjusted by an automated method',             'T');
commit;
declare
   l_matching_code    integer;
begin
   ----------------------------------------------------------------------
   -- delete any local records that are replaced by the common records --
   ----------------------------------------------------------------------
   for rec in (select *
                 from at_turbine_computation_code
                where db_office_code = cwms_util.db_office_code_all
                order by turbine_comp_code
              )
   loop
      -------------------------------
      -- get the local record code --
      -------------------------------
      begin
         select turbine_comp_code
           into l_matching_code
           from at_turbine_computation_code
          where turbine_comp_display_value = rec.turbine_comp_display_value
            and db_office_code != cwms_util.db_office_code_all;
      exception
         when no_data_found then continue;
      end;
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
end;
/

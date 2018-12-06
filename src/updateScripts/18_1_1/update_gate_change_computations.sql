declare
   l_matching_code    integer;
begin
   -------------------------------
   -- insert the common records --
   -------------------------------
   insert into at_gate_ch_computation_code values(1, cwms_util.db_office_code_all, 'C', 'Calculated from gate opening-elev curves', 'T');
   insert into at_gate_ch_computation_code values(2, cwms_util.db_office_code_all, 'T', 'Calculated from tailwater curve',          'T');
   insert into at_gate_ch_computation_code values(3, cwms_util.db_office_code_all, 'E', 'Estimated by user',                        'T');
   insert into at_gate_ch_computation_code values(4, cwms_util.db_office_code_all, 'A', 'Adjusted by an automated method',          'T');

   ----------------------------------------------------------------------
   -- delete any local records that are replaced by the common records --
   ----------------------------------------------------------------------
   for rec in (select * 
                 from at_gate_ch_computation_code
                where db_office_code = cwms_util.db_office_code_all 
                order by discharge_comp_code
              )
   loop
      -------------------------------
      -- get the local record code --
      -------------------------------
      begin
         select discharge_comp_code
           into l_matching_code
           from at_gate_ch_computation_code
          where discharge_comp_display_value = rec.discharge_comp_display_value
            and db_office_code != cwms_util.db_office_code_all;
      exception
         when no_data_found then continue;
      end;   
      ----------------------------------------------------------
      -- update values foreign keyed to the local record code --
      ----------------------------------------------------------
      update at_gate_change
         set discharge_computation_code = rec.discharge_comp_code
       where discharge_computation_code = l_matching_code;  
      -----------------------------
      -- delete the local record --
      -----------------------------
      delete
        from at_gate_ch_computation_code
       where discharge_comp_code = l_matching_code; 
   end loop;
end;   
/

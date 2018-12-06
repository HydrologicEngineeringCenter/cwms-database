declare
   l_matching_code    integer;
begin
   -------------------------------
   -- insert the common records --
   -------------------------------
   insert into at_gate_release_reason_code values(1, cwms_util.db_office_code_all, 'F', 'Flood control release', 'T');
   insert into at_gate_release_reason_code values(2, cwms_util.db_office_code_all, 'W', 'Water supply release',  'T');
   insert into at_gate_release_reason_code values(3, cwms_util.db_office_code_all, 'Q', 'Water quality release', 'T');
   insert into at_gate_release_reason_code values(4, cwms_util.db_office_code_all, 'H', 'Hydropower release',    'T');
   insert into at_gate_release_reason_code values(5, cwms_util.db_office_code_all, 'O', 'Other release',         'T');
         
   ----------------------------------------------------------------------
   -- delete any local records that are replaced by the common records --
   ----------------------------------------------------------------------
   for rec in (select * 
                 from at_gate_release_reason_code
                where db_office_code = cwms_util.db_office_code_all 
                order by release_reason_code
              )
   loop
      -------------------------------
      -- get the local record code --
      -------------------------------
      begin
         select release_reason_code
           into l_matching_code
           from at_gate_release_reason_code
          where release_reason_display_value = rec.release_reason_display_value
            and db_office_code != cwms_util.db_office_code_all;
      exception
         when no_data_found then continue;
      end;   
      ----------------------------------------------------------
      -- update values foreign keyed to the local record code --
      ----------------------------------------------------------
      update at_gate_change 
         set release_reason_code = rec.release_reason_code
       where release_reason_code = l_matching_code;  
      -----------------------------
      -- delete the local record --
      -----------------------------
      delete
        from at_gate_release_reason_code
       where release_reason_code = l_matching_code; 
   end loop;
end;   
/

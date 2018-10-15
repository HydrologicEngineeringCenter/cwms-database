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
   insert into at_gate_release_reason_code values(1, l_cwms_office_code, 'F', 'Flood control release', 'T');
   insert into at_gate_release_reason_code values(2, l_cwms_office_code, 'W', 'Water supply release',  'T');
   insert into at_gate_release_reason_code values(3, l_cwms_office_code, 'Q', 'Water quality release', 'T');
   insert into at_gate_release_reason_code values(4, l_cwms_office_code, 'H', 'Hydropower release',    'T');
   insert into at_gate_release_reason_code values(5, l_cwms_office_code, 'O', 'Other release',         'T');
         
   if l_host_office_code is not null then
      ----------------------------------------------------------------------
      -- delete any local records that are replaced by the common records --
      ----------------------------------------------------------------------
      for rec in (select * 
                    from at_gate_release_reason_code
                   where db_office_code = l_cwms_office_code 
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
               and db_office_code = l_host_office_code;
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
   end if;
end;   
/

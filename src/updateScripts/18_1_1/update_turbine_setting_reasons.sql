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
   insert into at_turbine_setting_reason values(1, l_cwms_office_code, 'S', 'Scheduled release to meet loads', 'T'); 
   insert into at_turbine_setting_reason values(2, l_cwms_office_code, 'F', 'Flood control release',           'T'); 
   insert into at_turbine_setting_reason values(3, l_cwms_office_code, 'W', 'Water supply release',            'T'); 
   insert into at_turbine_setting_reason values(4, l_cwms_office_code, 'Q', 'Water quality release',           'T'); 
   insert into at_turbine_setting_reason values(5, l_cwms_office_code, 'H', 'Hydropower release',              'T');
   insert into at_turbine_setting_reason values(6, l_cwms_office_code, 'O', 'Other release',                   'T');
         
   if l_host_office_code is not null then
      ----------------------------------------------------------------------
      -- delete any local records that are replaced by the common records --
      ----------------------------------------------------------------------
      for rec in (select * 
                    from at_turbine_setting_reason
                   where db_office_code = l_cwms_office_code 
                   order by turb_set_reason_code
                 )
      loop                                                                        
         -------------------------------
         -- get the local record code --
         -------------------------------
         select turb_set_reason_code
           into l_matching_code                                       
           from at_turbine_setting_reason
          where turb_set_reason_display_value = rec.turb_set_reason_display_value
            and db_office_code = l_host_office_code;
         ----------------------------------------------------------
         -- update values foreign keyed to the local record code --
         ----------------------------------------------------------
         update at_turbine_change 
            set turbine_setting_reason_code = rec.turb_set_reason_code
          where turbine_setting_reason_code = l_matching_code;  
         -----------------------------
         -- delete the local record --                            
         -----------------------------
         delete
           from at_turbine_setting_reason
          where turb_set_reason_code = l_matching_code; 
      end loop;
   end if;
end;   
/

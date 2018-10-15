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
   insert into at_ws_contract_type values(1, cwms_util.db_office_code_all, 'Storage',            'Storage contract',       'T');
   insert into at_ws_contract_type values(2, cwms_util.db_office_code_all, 'Irrigation',         'Irrigation contract',    'T');
   insert into at_ws_contract_type values(3, cwms_util.db_office_code_all, 'Surplus',            'Surplus contract',       'T');
   insert into at_ws_contract_type values(4, cwms_util.db_office_code_all, 'Conduit',            'Conduit contract',       'T');
   insert into at_ws_contract_type values(5, cwms_util.db_office_code_all, 'Conveyance',         'Conveyance contract',    'T');
   insert into at_ws_contract_type values(6, cwms_util.db_office_code_all, 'Interim Irrigation', 'Interim use irrigation', 'T');

   if l_host_office_code is not null then
      ----------------------------------------------------------------------
      -- delete any local records that are replaced by the common records --
      ----------------------------------------------------------------------
      for rec in (select * 
                    from at_ws_contract_type                                                              
                   where db_office_code = l_cwms_office_code 
                   order by ws_contract_type_code                                                                      
                 )
      loop
         -------------------------------
         -- get the local record code --
         -------------------------------
         begin
            select ws_contract_type_code
              into l_matching_code
              from at_ws_contract_type
             where ws_contract_type_display_value = rec.ws_contract_type_display_value
               and db_office_code = l_host_office_code;
         exception
            when no_data_found then continue;
         end;   
         ----------------------------------------------------------
         -- update values foreign keyed to the local record code --
         ----------------------------------------------------------
         update at_water_user_contract
            set water_supply_contract_type = rec.ws_contract_type_code
          where water_supply_contract_type = l_matching_code;  
         -----------------------------
         -- delete the local record --
         -----------------------------
         delete
           from at_ws_contract_type
          where ws_contract_type_code = l_matching_code; 
      end loop;
   end if;
end;   
/

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
   insert into at_physical_transfer_type values(1, l_cwms_office_code, 'Pipeline', 'Transfer through a pipeline',  'T');
   insert into at_physical_transfer_type values(2, l_cwms_office_code, 'Canal',    'Transfer by canal',            'T');
   insert into at_physical_transfer_type values(3, l_cwms_office_code, 'Stream',   'Transfer by flow in a stream', 'T');
   insert into at_physical_transfer_type values(4, l_cwms_office_code, 'River',    'Transfer by flow in a river',  'T');
   insert into at_physical_transfer_type values(5, l_cwms_office_code, 'Siphon',   'Transfer by siphon',           'T');
   insert into at_physical_transfer_type values(6, l_cwms_office_code, 'Aqueduct', 'Transfer by aqueduct',         'T');
   insert into at_physical_transfer_type values(7, l_cwms_office_code, 'Conduit',  'Transfer by conduit',          'T');

   if l_host_office_code is not null then
      ----------------------------------------------------------------------
      -- delete any local records that are replaced by the common records --
      ----------------------------------------------------------------------
      for rec in (select * 
                    from at_physical_transfer_type
                   where db_office_code = l_cwms_office_code 
                   order by phys_trans_type_code                                                                      
                 )
      loop
         -------------------------------
         -- get the local record code --
         -------------------------------
         begin
            select phys_trans_type_code
              into l_matching_code
              from at_physical_transfer_type
             where phys_trans_type_display_value = rec.phys_trans_type_display_value
               and db_office_code = l_host_office_code;
         exception
            when no_data_found then continue;
         end;   
         ----------------------------------------------------------
         -- update values foreign keyed to the local record code --
         ----------------------------------------------------------
         update at_wat_usr_contract_accounting
            set phys_trans_type_code = rec.phys_trans_type_code
          where phys_trans_type_code = l_matching_code;  
         -----------------------------
         -- delete the local record --
         -----------------------------
         delete
           from at_physical_transfer_type
          where phys_trans_type_code = l_matching_code; 
      end loop;
   end if;
end;   
/

declare
   l_matching_code    integer;
begin
   -------------------------------
   -- insert the common records --                        
   -------------------------------
   insert into at_physical_transfer_type values(1, cwms_util.db_office_code_all, 'Pipeline', 'Transfer through a pipeline',  'T');
   insert into at_physical_transfer_type values(2, cwms_util.db_office_code_all, 'Canal',    'Transfer by canal',            'T');
   insert into at_physical_transfer_type values(3, cwms_util.db_office_code_all, 'Stream',   'Transfer by flow in a stream', 'T');
   insert into at_physical_transfer_type values(4, cwms_util.db_office_code_all, 'River',    'Transfer by flow in a river',  'T');
   insert into at_physical_transfer_type values(5, cwms_util.db_office_code_all, 'Siphon',   'Transfer by siphon',           'T');
   insert into at_physical_transfer_type values(6, cwms_util.db_office_code_all, 'Aqueduct', 'Transfer by aqueduct',         'T');
   insert into at_physical_transfer_type values(7, cwms_util.db_office_code_all, 'Conduit',  'Transfer by conduit',          'T');

   ----------------------------------------------------------------------
   -- delete any local records that are replaced by the common records --
   ----------------------------------------------------------------------
   for rec in (select * 
                 from at_physical_transfer_type
                where db_office_code = cwms_util.db_office_code_all 
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
            and db_office_code != cwms_util.db_office_code_all;
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
end;   
/

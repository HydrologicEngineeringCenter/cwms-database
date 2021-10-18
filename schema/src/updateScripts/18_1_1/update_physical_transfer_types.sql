-------------------------------
-- insert the common records --
-------------------------------
insert into at_physical_transfer_type values(1, 53, 'Pipeline', 'Transfer through a pipeline',  'T');
insert into at_physical_transfer_type values(2, 53, 'Canal',    'Transfer by canal',            'T');
insert into at_physical_transfer_type values(3, 53, 'Stream',   'Transfer by flow in a stream', 'T');
insert into at_physical_transfer_type values(4, 53, 'River',    'Transfer by flow in a river',  'T');
insert into at_physical_transfer_type values(5, 53, 'Siphon',   'Transfer by siphon',           'T');
insert into at_physical_transfer_type values(6, 53, 'Aqueduct', 'Transfer by aqueduct',         'T');
insert into at_physical_transfer_type values(7, 53, 'Conduit',  'Transfer by conduit',          'T');
commit;
declare
   l_matching_code    integer;
begin
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

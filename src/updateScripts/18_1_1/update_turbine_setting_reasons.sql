-------------------------------
-- insert the common records --
-------------------------------
insert into at_turbine_setting_reason values(1, 53, 'S', 'Scheduled release to meet loads', 'T');
insert into at_turbine_setting_reason values(2, 53, 'F', 'Flood control release',           'T');
insert into at_turbine_setting_reason values(3, 53, 'W', 'Water supply release',            'T');
insert into at_turbine_setting_reason values(4, 53, 'Q', 'Water quality release',           'T');
insert into at_turbine_setting_reason values(5, 53, 'H', 'Hydropower release',              'T');
insert into at_turbine_setting_reason values(6, 53, 'O', 'Other release',                   'T');
commit;
declare
   l_matching_code    integer;
begin
   ----------------------------------------------------------------------
   -- delete any local records that are replaced by the common records --
   ----------------------------------------------------------------------
   for rec in (select *
                 from at_turbine_setting_reason
                where db_office_code = cwms_util.db_office_code_all
                order by turb_set_reason_code
              )
   loop
      -------------------------------
      -- get the local record code --
      -------------------------------
      begin
         select turb_set_reason_code
           into l_matching_code
           from at_turbine_setting_reason
          where turb_set_reason_display_value = rec.turb_set_reason_display_value
            and db_office_code != cwms_util.db_office_code_all;
      exception
         when no_data_found then continue;
      end;
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
end;
/

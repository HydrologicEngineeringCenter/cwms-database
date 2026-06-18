create or replace trigger at_fcst_time_series_trig
   after insert or update on at_fcst_time_series
   for each row
begin
   if not cwms_fcst.g_defer_validation then
      cwms_fcst.validate_fcst_spec(:new.fcst_spec_code);
   end if;
end;
/

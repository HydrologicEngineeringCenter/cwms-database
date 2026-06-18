create or replace trigger at_fcst_location_trig
   after delete on at_fcst_location
   for each row
begin
   cwms_fcst.validate_fcst_spec(:old.fcst_spec_code);
end;
/

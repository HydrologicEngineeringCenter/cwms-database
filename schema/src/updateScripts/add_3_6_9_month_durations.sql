
define cwms_schema = CWMS_20
set define on
set verify off

declare
   l_count number;
begin
   select count(*)
   into l_count
   from all_tables
   where table_name = 'CWMS_DURATION';

   if l_count != 1 then
      cwms_err.raise('ERROR', 'Expected CWMS_DURATION table to exist.');
   end if;

   -- insert new records
   INSERT INTO CWMS_DURATION VALUES (63, '3Month', 129600, 'Measurement applies over 3 months, time stamped at period end');
   INSERT INTO CWMS_DURATION VALUES (64, '6Month', 259200, 'Measurement applies over 6 months, time stamped at period end');
   INSERT INTO CWMS_DURATION VALUES (65, '9Month', 388800, 'Measurement applies over 9 months, time stamped at period end');
   commit;
end;
/
create or replace trigger at_ts_profile_parser_t01
   before insert or update
   of time_field, time_in_two_fields, time_col_start, time_col_end
   on at_ts_profile_parser
   for each row
declare
begin
   if (:new.time_field is null) = (:new.time_col_start is null) then
      cwms_err.raise('ERROR', 'One and only one of TIME_FIELD and TIME_COL_START can be NULL');
   end if;
   if (:new.time_field is null) != (:new.time_in_two_fields is null) then
      cwms_err.raise('ERROR', 'TIME_FIELD and TIME_IN_TWO_FIELDS must both or neither be NULL');
   end if;
   if (:new.time_col_start is null) != (:new.time_col_end is null) then
      cwms_err.raise('ERROR', 'TIME_COL_START and TIME_COL_END must both or neither be NULL');
   end if;
   if :new.time_field is not null and :new.time_in_two_fields not in ('T', 'F') then
      cwms_err.raise('ERROR', 'TIME_IN_TWO_FIELDS must be ''T'' or ''F'' for delimited parsers');
   end if;
end at_ts_profile_parser;
/

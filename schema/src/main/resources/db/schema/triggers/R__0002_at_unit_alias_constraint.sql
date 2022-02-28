-----------------------------
-- at_unit_alias trigger (depends on at_xchg_dss_ts_mappings)
--
create or replace trigger at_unit_alias_constraint
before delete or update
of alias_id
on "${CWMS_SCHEMA}"."AT_UNIT_ALIAS"
referencing new as new old as old
for each row
declare
   l_count number;
begin
   if deleting or (updating and :new.alias_id != :old.alias_id) then
      select count(unit_id)
        into l_count
        from at_xchg_dss_ts_mappings m,
             at_cwms_ts_spec         ts,
             at_physical_location    pl,
             at_base_location        bl,
             cwms_office             o
       where m.unit_id = :old.alias_id
         and ts.ts_code = m.cwms_ts_code
         and pl.location_code = ts.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code
         and o.office_code = :old.db_office_code;
      if l_count > 0 then
         cwms_err.raise(
            'cannot_delete_unit_1',
            :old.alias_id,
            ''|| l_count || 'dss time series specification(s)');
      end if;
   end if;
end at_unit_alias_constraint;
/

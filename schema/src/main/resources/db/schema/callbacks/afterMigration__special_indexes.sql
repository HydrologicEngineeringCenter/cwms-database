declare
already_exists exception;
   pragma exception_init(already_exists, -955);
begin
    execute immediate 'create unique index at_fcst_spec_idx2 on at_fcst_spec (cwms_util.get_db_office_id_from_code(office_code), fcst_spec_id, fcst_designator)';
exception
when already_exists then null;
end;
/
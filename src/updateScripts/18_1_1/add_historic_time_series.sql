drop trigger at_cwms_ts_spec_t01;
alter table at_cwms_ts_spec add historic_flag varchar2(1) default 'F';
alter table at_cwms_ts_spec add constraint at_cwms_ts_spec_ck_6 check (historic_flag = 'T' or historic_flag = 'F');
alter table at_cwms_ts_id add historic_flag varchar2(1) default 'F';
   
create trigger at_cwms_ts_spec_t01
    AFTER INSERT OR UPDATE OR DELETE
    ON AT_CWMS_TS_SPEC     REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
    l_cwms_ts_spec   at_cwms_ts_spec%ROWTYPE;
BEGIN
    IF INSERTING OR UPDATING
    THEN
        l_cwms_ts_spec.ts_code := :new.ts_code;
        l_cwms_ts_spec.location_code := :new.location_code;
        l_cwms_ts_spec.parameter_code := :new.parameter_code;
        l_cwms_ts_spec.parameter_type_code := :new.parameter_type_code;
        l_cwms_ts_spec.interval_code := :new.interval_code;
        l_cwms_ts_spec.duration_code := :new.duration_code;
        l_cwms_ts_spec.version := :new.version;
        l_cwms_ts_spec.description := :new.description;
        l_cwms_ts_spec.interval_utc_offset := :new.interval_utc_offset;
        l_cwms_ts_spec.interval_forward := :new.interval_forward;
        l_cwms_ts_spec.interval_backward := :new.interval_backward;
        l_cwms_ts_spec.interval_offset_id := :new.interval_offset_id;
        l_cwms_ts_spec.time_zone_code := :new.time_zone_code;
        l_cwms_ts_spec.version_flag := :new.version_flag;
        l_cwms_ts_spec.migrate_ver_flag := :new.migrate_ver_flag;
        l_cwms_ts_spec.active_flag := :new.active_flag;
        l_cwms_ts_spec.delete_date := :new.delete_date;
        l_cwms_ts_spec.data_source := :new.data_source;
        l_cwms_ts_spec.historic_flag := :new.historic_flag;
        --
        cwms_ts_id.touched_acts (l_cwms_ts_spec);
    END IF;

    IF DELETING
    THEN
        cwms_ts_id.delete_from_at_cwms_ts_id (:old.ts_code);
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_cwms_ts_spec_t01;
/


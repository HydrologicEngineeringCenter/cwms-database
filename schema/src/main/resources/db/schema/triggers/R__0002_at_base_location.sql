--
-- AT_BASE_LOCATION_T01  (Trigger)
--
--  Dependencies:
--   STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_BASE_LOCATION (Table)
--
CREATE OR REPLACE TRIGGER at_base_location_t01
    AFTER UPDATE OF active_flag, base_location_id
    ON at_base_location
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
BEGIN
    cwms_ts_id.touched_abl (:new.db_office_code,
                                    :new.base_location_code,
                                    :new.active_flag,
                                    :new.base_location_id
                                  );
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_base_location_t01;
/
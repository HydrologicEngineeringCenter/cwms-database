/*
 * Copyright (c) 2024
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */
DROP TABLE cwms_lock_elev_buffer
/
CREATE TABLE cwms_lock_elev_buffer
(
    office_code                     NUMBER(14)        NOT NULL,
    nav_elev_warning_trigger_buffer BINARY_DOUBLE DEFAULT 0.6096 NOT NULL,
    unit_id                         VARCHAR2(16 BYTE) DEFAULT 'm' NOT NULL
)
    LOGGING
    NOCOMPRESS
    NOCACHE
    NOPARALLEL
    MONITORING
/
COMMENT ON COLUMN cwms_lock_elev_buffer.office_code IS 'Office code associated with the warning buffer.';
COMMENT ON COLUMN cwms_lock_elev_buffer.nav_elev_warning_trigger_buffer IS 'The buffer between lock elevation that would trigger a warning. Default is 0.6096m (2ft)';
COMMENT ON COLUMN cwms_lock_elev_buffer.unit_id IS 'The unit if the elevation warning trigger buffer. Default is "m"';

CREATE UNIQUE INDEX cwms_lock_elev_buffer_idx_1 ON cwms_lock_elev_buffer
    (office_code)
    LOGGING
    NOPARALLEL
/

ALTER TABLE cwms_lock_elev_buffer
    ADD (CONSTRAINT cwms_lock_elev_buffer_idx_1
        PRIMARY KEY (office_code)
            USING INDEX cwms_lock_elev_buffer_idx_1
            ENABLE VALIDATE)
/

ALTER TABLE cwms_lock_elev_buffer
    ADD (
        CONSTRAINT cwms_lock_elev_buffer_fk1
            FOREIGN KEY (office_code)
                REFERENCES cwms_office (office_code))
/

show errors

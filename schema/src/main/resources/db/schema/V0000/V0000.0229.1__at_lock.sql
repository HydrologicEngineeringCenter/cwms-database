/*
 * Copyright (c) 2024
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */
-- DROP TABLE CWMS_20.AT_LOCK
/
CREATE TABLE at_lock
(
    lock_location_code                 NUMBER(14) NOT NULL,
    project_location_code              NUMBER(14) NOT NULL,
    lock_width                         BINARY_DOUBLE,
    lock_length                        BINARY_DOUBLE,
    volume_per_lockage                 BINARY_DOUBLE,
    minimum_draft                      BINARY_DOUBLE,
    normal_lock_lift                   BINARY_DOUBLE,
    maximum_lock_lift                  binary_double,
    elev_closure_high_water_upper_pool binary_double,
    elev_closure_high_water_lower_pool binary_double,
    elev_closer_low_water_upper_pool   binary_double,
    elev_closure_low_water_lower_pool  binary_double,
    chamber_location_description       VARCHAR2(55)
)
    TABLESPACE cwms_20at_data
    PCTUSED 0
    PCTFREE 10
    INITRANS 1
    MAXTRANS 255
    STORAGE
(
    INITIAL
    504 k
    MINEXTENTS
    1
    MAXEXTENTS
    2147483645
    PCTINCREASE
    0
    BUFFER_POOL
    DEFAULT
)
    LOGGING
    NOCOMPRESS
    NOCACHE
    NOPARALLEL
    MONITORING
/
COMMENT ON COLUMN at_lock.lock_location_code IS 'Unique record identifier for this lock, also in at_physical_location';
COMMENT ON COLUMN at_lock.project_location_code IS 'The project that this lock is part of';
COMMENT ON COLUMN at_lock.lock_width IS 'The width of the lock chamber';
COMMENT ON COLUMN at_lock.lock_length IS 'The length of the lock chamber';
COMMENT ON COLUMN at_lock.volume_per_lockage IS 'The volume of water discharged for one lockage at normal headwater and tailwater elevations.  This volume includes any flushing water.';
COMMENT ON COLUMN at_lock.minimum_draft IS 'The minimum depth of water that is maintained for vessels for this particular lock';
COMMENT ON COLUMN at_lock.maximum_lock_lift IS 'The maximum lift the lock can support';
COMMENT ON COLUMN at_lock.elev_closure_high_water_upper_pool IS 'The elevation that a lock closes due to high water in the upper pool';
COMMENT ON COLUMN at_lock.elev_closure_high_water_lower_pool IS 'The elevation that a lock closes due to high water in the lower pool';
COMMENT ON COLUMN at_lock.elev_closer_low_water_upper_pool IS 'The elevation that a lock closes due to lower water in the upper pool';
COMMENT ON COLUMN at_lock.elev_closure_low_water_lower_pool IS 'The elevation that a lock closes due to low water in the lower pool';
COMMENT ON COLUMN at_lock.chamber_location_description IS 'A single chamber, land side main, land side aux, river side main, river side aux.';

CREATE UNIQUE INDEX at_lock_idx_1 ON at_lock
    (lock_location_code, project_location_code)
/

ALTER TABLE at_lock
    ADD (
        CONSTRAINT at_lock_pk
            PRIMARY KEY
                (lock_location_code)
                USING INDEX
                    TABLESPACE cwms_20at_data
                    PCTFREE 10
                    INITRANS 2
                    MAXTRANS 255
                    STORAGE (
                    INITIAL 64 k
                    MINEXTENTS 1
                    MAXEXTENTS 2147483645
                    PCTINCREASE 0
                    ))
/

ALTER TABLE at_lock
    ADD (
        CONSTRAINT at_lock_fk1
            FOREIGN KEY (lock_location_code)
                REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_lock
    ADD (
        CONSTRAINT at_lock_fk2
            FOREIGN KEY (project_location_code)
                REFERENCES at_project (project_location_code))
/

show errors

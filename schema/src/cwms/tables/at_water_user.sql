CREATE TABLE at_water_user
(
   water_user_code       NUMBER(14)        NOT NULL,
   project_location_code NUMBER(14)        NOT NULL,
   entity_name           VARCHAR2(64 BYTE) NOT NULL,
   water_right           VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON COLUMN at_water_user.water_user_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_water_user.project_location_code IS 'The project that this user obtains water from. (This user may obtain water from more than one project.';
COMMENT ON COLUMN at_water_user.water_right IS 'A description of the water right of this user.  This may include a citation of the legal document that bestowed this right.';
COMMENT ON COLUMN at_water_user.entity_name IS 'The entity name associated with this user';

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_pk
 PRIMARY KEY
 (water_user_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

CREATE UNIQUE INDEX at_water_user_idx1 ON at_water_user
(project_location_code,upper(entity_name))
LOGGING
tablespace cwms_20at_data
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

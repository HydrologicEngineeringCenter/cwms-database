CREATE TABLE at_embankment
(
  embankment_location_code    NUMBER(14)                NOT NULL,
  embankment_project_loc_code         NUMBER(14)      NOT NULL,
  structure_type_code     NUMBER(14)      NOT NULL,
  structure_length      BINARY_DOUBLE,
  upstream_prot_type_code   NUMBER(14),
  upstream_sideslope      BINARY_DOUBLE,
  downstream_prot_type_code   NUMBER(14),
  downstream_sideslope      BINARY_DOUBLE,
  height_max          BINARY_DOUBLE,
  top_width           BINARY_DOUBLE
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
COMMENT ON COLUMN at_embankment.embankment_location_code IS 'The physical location code for this embankment structure';
COMMENT ON COLUMN at_embankment.embankment_project_loc_code IS 'The project location_code this embankment is a child of';
COMMENT ON COLUMN at_embankment.structure_type_code IS 'The lookup code for the type of the embankment structure';
COMMENT ON COLUMN at_embankment.structure_length IS 'The overall length of the embankment structure';
COMMENT ON COLUMN at_embankment.upstream_prot_type_code IS 'The upstream protection type code for the embankment structure';
COMMENT ON COLUMN at_embankment.upstream_sideslope IS 'The upstream side slope of the embankment structure';
COMMENT ON COLUMN at_embankment.downstream_prot_type_code IS 'The downstream protection type code for the embankment structure';
COMMENT ON COLUMN at_embankment.downstream_sideslope IS 'The downstream side slope of the embankment structure';
COMMENT ON COLUMN at_embankment.height_max IS 'The maximum height of the embankment structure';
COMMENT ON COLUMN at_embankment.top_width IS 'The width at the top of the embankment structure';

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_pk
 PRIMARY KEY
 (embankment_location_code)
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



ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk1
 FOREIGN KEY (embankment_location_code)
 REFERENCES at_physical_location (location_code))
/
ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk2
 FOREIGN KEY (embankment_project_loc_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk3
 FOREIGN KEY (structure_type_code)
 REFERENCES at_embank_structure_type (structure_type_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk4
 FOREIGN KEY (upstream_prot_type_code)
 REFERENCES at_embank_protection_type (protection_type_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk5
 FOREIGN KEY (downstream_prot_type_code)
 REFERENCES at_embank_protection_type (protection_type_code))
/

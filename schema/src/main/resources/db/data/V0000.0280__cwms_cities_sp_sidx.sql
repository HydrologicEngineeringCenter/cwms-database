--
--
--prompt INSERT sdo geom metatdata for CWMS_CITIES_SP
--
--
INSERT INTO user_sdo_geom_metadata (TABLE_NAME,
                                    COLUMN_NAME,
                                    DIMINFO,
                                    SRID)
     VALUES ('CWMS_CITIES_SP',
             'shape',
             sdo_dim_array (sdo_dim_element ('X',
                                             -180,
                                             180,
                                             0.005),
                            sdo_dim_element ('Y',
                                             -90,
                                             90,
                                             0.005)),
             8265);

--
--
--prompt CREATE CWMS_CITIES_SP_SIDX
--
--
CREATE INDEX CWMS_CITIES_SP_SIDX ON CWMS_CITIES_SP
(SHAPE)
INDEXTYPE IS MDSYS.SPATIAL_INDEX
NOPARALLEL;

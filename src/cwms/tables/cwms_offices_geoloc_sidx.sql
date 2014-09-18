--
-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
prompt INSERT sdo geom metatdata for CWMS_OFFICES_GEOLOC
---------------------------------------------------
-- Must be run as the CWMS_20 user-----------------
INSERT INTO user_sdo_geom_metadata (TABLE_NAME,
                                    COLUMN_NAME,
                                    DIMINFO,
                                    SRID)
     VALUES ('CWMS_OFFICES_GEOLOC',
             'SHAPE',
             sdo_dim_array (sdo_dim_element (NULL,
                                             -180,
                                             180,
                                             0.001),
                            sdo_dim_element (NULL,
                                             -90,
                                             90,
                                             0.001)),
             8265                                                      -- SRID
                 );

-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
prompt CREATE CWMS_OFFICES_GEOLOC_SIDX
---------------------------------------------------
--
CREATE INDEX CWMS_OFFICES_GEOLOC_SIDX ON CWMS_OFFICES_GEOLOC
(SHAPE)
INDEXTYPE IS MDSYS.SPATIAL_INDEX
NOPARALLEL;

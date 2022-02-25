--
-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
--prompt INSERT sdo geom metatdata for CWMS_AGG_DISTRICT
---------------------------------------------------
-- Must be run as the CWMS_20 user-----------------

INSERT INTO user_sdo_geom_metadata (TABLE_NAME,
                                    COLUMN_NAME,
                                    DIMINFO,
                                    SRID)
     VALUES ('CWMS_AGG_DISTRICT',
             'SHAPE',
             sdo_dim_array (sdo_dim_element ('latitude',
                                             -180,
                                             180,
                                             0.0005),
                            sdo_dim_element ('longitude',
                                             -90,
                                             90,
                                             0.0005)),
             8265                                                      -- SRID
                 );
-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
--prompt CREATE CWMS_AGG_DISTRICT_SIDX
---------------------------------------------------
--
CREATE INDEX CWMS_AGG_DISTRICT_SIDX ON CWMS_AGG_DISTRICT
(SHAPE)
INDEXTYPE IS MDSYS.SPATIAL_INDEX
NOPARALLEL;

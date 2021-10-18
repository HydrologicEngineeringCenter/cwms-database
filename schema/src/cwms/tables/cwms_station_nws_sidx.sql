--
-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
prompt INSERT sdo geom metatdata for CWMS_STATION_NWS_SP
---------------------------------------------------
-- Must be run as the CWMS_20 user-----------------
INSERT INTO user_sdo_geom_metadata (TABLE_NAME,
                                    COLUMN_NAME,
                                    DIMINFO,
                                    SRID)
     VALUES ('CWMS_STATION_NWS',
             'shape',
             sdo_dim_array (sdo_dim_element ('Longitude',
                                             -180,
                                             180,
                                             0.005),
                            sdo_dim_element ('Latitude',
                                             -90,
                                             90,
                                             0.005)),
             8307);
-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
prompt CREATE CWMS_STATION_NWS_SP_SIDX
---------------------------------------------------
--
CREATE INDEX CWMS_STATION_NWS_SIDX
   ON CWMS_STATION_NWS ("SHAPE")
   INDEXTYPE IS "MDSYS"."SPATIAL_INDEX";

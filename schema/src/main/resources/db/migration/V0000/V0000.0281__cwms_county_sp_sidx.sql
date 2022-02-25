--
-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
--prompt INSERT sdo geom metatdata for CWMS_COUNTY_SP
---------------------------------------------------
-- Must be run as the CWMS_20 user-----------------
INSERT INTO user_sdo_geom_metadata (TABLE_NAME,
                                    COLUMN_NAME,
                                    DIMINFO,
                                    SRID)
     VALUES ('CWMS_COUNTY_SP',
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
-- indexes_for_spatial_data.sql -------------------
---------------------------------------------------
--prompt CREATE CWMS_COUNTY_SP_SIDX
---------------------------------------------------
--
CREATE INDEX CWMS_COUNTY_SP_SIDX
   ON CWMS_COUNTY_SP ("SHAPE")
   INDEXTYPE IS "MDSYS"."SPATIAL_INDEX";

declare 
    duplicate_entry EXCEPTION;
    idx_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(duplicate_entry,-13223);
    PRAGMA EXCEPTION_INIT(idx_exists,-00955);
begin
    begin
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
    exception   
        when duplicate_entry then null; -- duplicate entry
    end;
    
    execute immediate 'CREATE INDEX CWMS_AGG_DISTRICT_SIDX ON CWMS_AGG_DISTRICT(SHAPE) INDEXTYPE IS MDSYS.SPATIAL_INDEX NOPARALLEL';    
exception
  when idx_exists then null; -- index already created
end;
/
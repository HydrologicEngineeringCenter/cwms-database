declare 
    duplicate_entry EXCEPTION;
    idx_exists EXCEPTION;
    v_sql varchar(512);
    PRAGMA EXCEPTION_INIT(duplicate_entry,-13223);
    PRAGMA EXCEPTION_INIT(idx_exists,-00955);
    procedure generate_geo_index( p_index_name varchar2, p_table_name varchar2, p_column_name varchar2)
    is
    begin
        begin
            INSERT INTO user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
                VALUES (p_table_name, p_column_name,
                        sdo_dim_array (sdo_dim_element ('latitude', -180, 180, 0.0005),
                                        sdo_dim_element ('longitude', -90, 90, 0.0005)),
                                        8265   -- SRID
                        );
        exception   
            when duplicate_entry then null; -- duplicate entry
        end;

        v_sql := 'CREATE INDEX '|| p_index_name || ' ON ' || p_table_name || '(' || p_column_name || ') INDEXTYPE IS MDSYS.SPATIAL_INDEX NOPARALLEL'; 
        
        execute immediate v_sql;
    exception
        when idx_exists then null; -- index already created
    end;
begin
    generate_geo_index('CWMS_AGG_DISTRICT_SIDX','CWMS_AGG_DISTRICT','SHAPE');
    generate_geo_index('CWMS_CITIES_SP_SIDX','CWMS_CITIES_SP','SHAPE');
    generate_geo_index('CWMS_COUNTY_SP_SIDX','CWMS_COUNTY_SP','SHAPE');
    generate_geo_index('CWMS_NATION_SP_SIDX','CWMS_NATION_SP','SHAPE');
    generate_geo_index('CWMS_OFFICES_GEOLOC_SIDX','CWMS_OFFICES_GEOLOC','SHAPE');
    generate_geo_index('CWMS_NID_SIDX','CWMS_NID','SHAPE');
    generate_geo_index('CWMS_STATE_SP_SIDX','CWMS_STATE_SP','SHAPE');
    generate_geo_index('CWMS_STATION_NWS_SIDX','CWMS_STATION_NWS','SHAPE');
    generate_geo_index('CWMS_STATION_USGS_SIDX','CWMS_STATION_USGS','SHAPE');
    generate_geo_index('CWMS_TIME_ZONE_SP_SIDX','CWMS_TIME_ZONE_SP','SHAPE');
    generate_geo_index('CWMS_USACE_DAM_SIDX','CWMS_USACE_DAM','SHAPE');
end;
/
SET SERVEROUTPUT ON
SET DEFINE ON
@@defines.sql
----------------------------------------------------
-- drop if they exist --
----------------------------------------------------

DECLARE
	TYPE id_array_t IS TABLE OF VARCHAR2 (32);

	table_names   id_array_t
		:= id_array_t ('at_a2w_ts_codes_by_loc',
                               'at_cma_error_log',
                               'at_data_dissem',
                               'at_pool',
                               'at_pool_purposes',
                               'at_pool_type',
                               'cwms_cities_sp',
                               'cwms_county_sp',
                               'cwms_nation_sp',
                               'cwms_nid',
                               'cwms_state_sp',
                               'cwms_station_nws',
                               'cwms_station_usgs',
                               'cwms_time_zone_sp',
                               'cwms_usace_dam_state',
                               'cwms_usace_dam_county',
                               'cwms_usace_dam'

						  );

	view_names   id_array_t
		:= id_array_t ('av_a2w_ts_codes_by_loc',
                               'av_base_parameter_units',
                               'av_base_param_display_units',
                               'av_cities_sp',
                               'av_county_sp',
                               'av_lock',
                               'av_specified_level_order',
                               'av_state_sp',
                               'av_station_usgs',
                               'av_station_nws',
                               'av_time_zone_sp',
                               'av_nation_sp',
                               'av_nid',
                               'av_office_sp',
                               'av_pool',
                               'av_pool_purposes',
                               'av_pool_type',
                               'av_usace_dam',
                               'av_usace_dam_state',
                               'av_usace_dam_county'
						  );
BEGIN
	FOR i IN view_names.FIRST .. view_names.LAST
	LOOP
		BEGIN
			EXECUTE IMMEDIATE
				'drop view ' || view_names (i);

			DBMS_OUTPUT.put_line ('Dropped view ' || table_names (i));
		EXCEPTION
			WHEN OTHERS
			THEN
				NULL;
		END;
	END LOOP;
        --
	FOR i IN table_names.FIRST .. table_names.LAST
	LOOP
		BEGIN
			EXECUTE IMMEDIATE
				'drop table ' || table_names (i) || ' cascade constraints';

			DBMS_OUTPUT.put_line ('Dropped table ' || table_names (i));
		EXCEPTION
			WHEN OTHERS
			THEN
				NULL;
		END;
	END LOOP;
END;
/

--
-- Create Tables
--
prompt create table at_a2w_ts_codes_by_loc
@@cwms/tables/at_a2w_ts_codes_by_loc.sql
--
prompt create table at_cma_error_log
@@cwms/tables/at_cma_error_log.sql
--
prompt create table at_data_dissem
@@cwms/tables/at_data_dissem.sql
--
prompt create table cwms_agg_district
@@cwms/tables/cwms_agg_district.sql
--
prompt create table cwms_cities_sp
@@cwms/tables/cwms_cities_sp.sql
--
prompt create table cwms_county_sp
@@cwms/tables/cwms_county_sp.sql
--
prompt create table cwms_nation_sp
@@cwms/tables/cwms_nation_sp.sql
--
prompt create table cwms_nid
@@cwms/tables/cwms_nid.sql
--
prompt create table cwms_offices_geoloc
@@cwms/tables/cwms_offices_geoloc.sql
--
prompt create table cwms_state_sp
@@cwms/tables/cwms_state_sp.sql
--
prompt create table cwms_station_nws
@@cwms/tables/cwms_station_nws.sql
--
prompt create table cwms_station_usgs
@@cwms/tables/cwms_station_usgs.sql
--
prompt create table cwms_time_zone_sp
@@cwms/tables/cwms_time_zone_sp.sql
--
prompt create table cwms_usace_dam_state
@@cwms/tables/cwms_usace_dam_state.sql
--
prompt create table cwms_usace_dam_county
@@cwms/tables/cwms_usace_dam_county.sql
--
prompt create table cwms_usace_dam
@@cwms/tables/cwms_usace_dam.sql

prompt create table at_pool
@@cwms/tables/at_pool.sql

prompt create table at_pool_type
@@cwms/tables/at_pool_type.sql

prompt create table at_pool_purposes
@@cwms/tables/at_pool_purposes.sql

--
-- Create Views
--
prompt create view av_a2w_ts_codes_by_loc
@@cwms/views/av_a2w_ts_codes_by_loc.sql
prompt create view av_a2w_ts_codes_by_loc2
@@cwms/views/av_a2w_ts_codes_by_loc2.sql
--
prompt create view av_base_parameter_units
@@cwms/views/av_base_parameter_units.sql
--
prompt create view av_base_param_display_units
@@cwms/views/av_base_parm_display_units.sql
--
prompt create view av_cities_sp
@@cwms/views/av_cities_sp.sql
--
prompt create view av_county_sp
@@cwms/views/av_county_sp.sql
--
prompt create view av_lock
@@cwms/views/av_lock.sql
--
prompt create view av_usace_dam
@@cwms/views/av_usace_dam.sql
--
prompt create view av_usace_dam_state
@@cwms/views/av_usace_dam_state.sql
--
prompt create view av_usace_dam_county
@@cwms/views/av_usace_dam_county.sql
--
prompt create view av_specified_level_order
@@cwms/views/av_specified_level_order.sql
--
prompt create view av_state_sp
@@cwms/views/av_state_sp.sql
--
prompt create view av_station_usgs
@@cwms/views/av_station_usgs.sql
--
prompt create view av_station_nws
@@cwms/views/av_station_nws.sql
--
prompt create view av_time_zone_sp
@@cwms/views/av_time_zone_sp.sql
--
prompt create view av_nid
@@cwms/views/av_nid.sql
--
prompt create view av_nation_sp
@@cwms/views/av_nation_sp.sql
--
prompt create view av_office_sp
@@cwms/views/av_office_sp.sql
--
--
-- Insert Data
--
prompt Inserting rows into at_specified_level_order
@@cwms/tables/at_specified_level_order_INSERT.sql



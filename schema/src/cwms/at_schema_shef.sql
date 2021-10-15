SET SERVEROUTPUT ON
SET DEFINE ON
@@defines.sql
----------------------------------------------------
-- drop if they exist --
----------------------------------------------------

DECLARE
	TYPE id_array_t IS TABLE OF VARCHAR2 (32);

	table_names   id_array_t
		:= id_array_t ('cwms_shef_time_zone',
							'cwms_shef_pe_codes',
							'cwms_shef_extremum_codes',
							'at_shef_crit_file_rec',
                            'at_shef_spec_mapping_update',
                            'at_data_stream_properties',
                            'at_data_stream_id',
                            'at_data_feed_id',
							'at_shef_ignore',
                            'at_shef_decode_spec',
                            'at_shef_decode',
							'at_shef_pe_codes'
						  );
BEGIN
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


@@cwms/tables/cwms_shef_time_zone.sql
@@cwms/tables/cwms_shef_pe_codes.sql
@@cwms/tables/cwms_shef_extremum_codes.sql
@@cwms/tables/at_data_stream_id.sql
@@cwms/tables/at_data_stream_properties.sql
@@cwms/tables/at_shef_spec_mapping_update.sql
@@cwms/tables/at_data_feed_id.sql
@@cwms/tables/at_shef_crit_file_rec.sql
-- @@cwms/tables/at_shef_crit_file.sql
@@cwms/tables/at_shef_ignore.sql
@@cwms/tables/at_shef_decode.sql
@@cwms/tables/at_shef_decode_spec.sql
@@cwms/tables/at_shef_pe_codes.sql

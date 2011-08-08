/* Formatted on 6/16/2011 3:17:24 PM (QP5 v5.163.1008.3004) */
/* CWMS Version 2.0 --
This script should be run by the cwms schema owner.
*/
SET SERVEROUTPUT ON
----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------

DECLARE
	TYPE id_array_t IS TABLE OF VARCHAR2 (32);

	view_names	 id_array_t
		:= id_array_t ('av_active_flag',
							'av_loc',          -- av_loc is created in at_schema_2...
							'av_cwms_ts_id',
							'av_loc_alias',
							'av_loc_cat_grp',
							'av_loc_level',
							'av_parameter',
							'av_screened_ts_ids',
							'av_screening_assignments',
							'av_screening_criteria',
							'av_screening_dur_mag',
							'av_screening_id',
							'av_shef_decode_spec',
							'av_shef_pe_codes',
							'av_state',
							'av_unit',
							'av_storage_unit',
							'av_log_message',               -- located in at_schema_2
							'av_dataexchange_job',
							'av_display_units',
							'av_rating_template',
							'av_rating_spec',
							'av_rating',
							'av_rating_local',
							'av_rating_values',
							'av_rating_values_native',
							'av_ts_association',
							'av_stream_types'
						  );
BEGIN
	FOR i IN view_names.FIRST .. view_names.LAST
	LOOP
		BEGIN
			EXECUTE IMMEDIATE 'drop view' || view_names (i);

			DBMS_OUTPUT.put_line ('Dropped view ' || view_names (i));
		EXCEPTION
			WHEN OTHERS
			THEN
				NULL;
		END;
	END LOOP;
END;
/

---------------------------------------------------------
@@cwms/views/zv_current_crit_file_code.sql
@@cwms/views/zav_cwms_ts_id.sql

@@cwms/views/av_shef_pe_codes.sql
@@cwms/views/av_active_flag.sql
@@cwms/views/av_loc_alias.sql
@@cwms/views/av_loc_grp_assgn.sql
@@cwms/views/av_loc_cat_grp.sql
@@cwms/views/av_parameter.sql
@@cwms/views/av_screened_ts_ids.sql
@@cwms/views/av_screening_assignments.sql
@@cwms/views/av_screening_criteria.sql
@@cwms/views/av_screening_dur_mag.sql
@@cwms/views/av_screening_id.sql
@@cwms/views/av_cwms_ts_id.sql
@@cwms/views/av_unit.sql
@@cwms/views/av_storage_unit.sql
@@cwms/views/av_dataexchange_job.sql
@@cwms/views/av_location_level.sql
@@cwms/views/av_loc_lvl_indicator.sql
@@cwms/views/av_loc_lvl_indicator_2.sql
@@cwms/views/av_display_units.sql
@@cwms/views/av_rating_template.sql
@@cwms/views/av_rating_spec.sql
@@cwms/views/av_rating.sql
@@cwms/views/av_rating_local.sql
@@cwms/views/av_rating_values.sql
@@cwms/views/av_rating_values_native.sql
@@cwms/views/av_ts_association.sql
@@cwms/views/av_stream_types.sql

@@cwms/views/av_data_streams.sql
@@cwms/views/av_data_streams_current.sql
@@cwms/views/av_state.sql

@@cwms/views/mv_data_q_changed.sql
@@cwms/views/mv_data_q_protection.sql
@@cwms/views/mv_data_q_range.sql
@@cwms/views/mv_data_q_repl_cause.sql
@@cwms/views/mv_data_q_repl_method.sql
@@cwms/views/mv_data_q_screened.sql
@@cwms/views/mv_data_q_test_failed.sql
@@cwms/views/mv_data_q_validity.sql
@@cwms/views/mv_data_quality.sql

--------------------------------------------------------------------------------
SHOW ERRORS;
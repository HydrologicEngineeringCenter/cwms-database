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
		:= id_array_t ('av_current_map_data',
			       'av_active_flag',
			       'av_basin',                  -- created in at_schema_2...
			       'av_clob',
			       'av_compound_outlet',
			       'av_cwms_media',
                   'av_db_change_log',
			       'av_document',
			       'av_document_type',
			       'av_embank_protection_type', -- created in at_schema_2...
			       'av_embank_structure_type',  -- created in at_schema_2...
			       'av_embankment',             -- created in at_schema_2...
			       'av_entity',
			       'av_entity_location',
                'av_gage', 
                'av_gage_method',
                'av_gage_sensor',
                'av_gage_type', 
                'av_gate',
			       'av_gate_change',
			       'av_gate_setting',
			       'av_loc',                    -- created in at_schema_2...
			       'av_loc2',                   -- created in at_schema_2...
			       'av_county',
			       'av_cwms_ts_id',
			       'av_cwms_ts_id2',
			       'av_loc_alias',
			       'av_loc_cat_grp',
			       'av_loc_level',
			       'av_nation',
			       'av_office',
			       'av_outlet',
			       'av_parameter',
			       'av_project',
			       'av_project_purpose',
			       'av_project_purposes',
			       'av_project_purposes_ui',
                'av_queue_subscriber_name',
			       'av_screened_ts_ids',
			       'av_screening_assignments',
			       'av_screening_control',
			       'av_screening_criteria',
			       'av_screening_dur_mag',
			       'av_screening_id',
			       'av_shef_decode_spec',
			       'av_shef_pe_codes',
			       'av_specified_level',
			       'av_specified_level_ui',
			       'av_state',
                'av_std_text',
			       'av_stream',                    -- located in at_schema_2
			       'av_stream_location',           -- located in at_schema_2
			       'av_streamflow_meas',
			       'av_turbine',
			       'av_turbine_change',
			       'av_turbine_setting',
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
			       'av_transitional_rating',
			       'av_virtual_rating',
			       'av_ts_association',
--			       'av_stream_types',
			       'av_store_rule',
			       'av_store_rule_ui',
			       'av_text_filter',
			       'av_text_filter_element',
			       'av_usgs_parameter',
			       'av_usgs_parameter_all',
			       'av_usgs_rating',
			       'av_loc_ts_id_count',
			       'av_property',
			       'av_vert_datum_offset',
                'av_water_user_contract',       -- located in at_schema_2
                'av_water_user_contract2'       -- located in at_schema_2
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
@@cwms/views/av_clob.sql
@@cwms/views/av_cwms_media_type.sql
@@cwms/views/av_db_change_log.sql
@@cwms/views/av_document.sql
@@cwms/views/av_document_type.sql
@@cwms/views/av_location_kind.sql
@@cwms/views/av_loc_alias.sql
@@cwms/views/av_loc_grp_assgn.sql
@@cwms/views/av_loc_cat_grp.sql
@@cwms/views/av_loc_ts_id_count.sql
@@cwms/views/av_parameter.sql
@@cwms/views/av_project_purpose.sql
@@cwms/views/av_project_purposes.sql
@@cwms/views/av_project_purposes_ui.sql
@@cwms/views/av_screened_ts_ids.sql
@@cwms/views/av_screening_assignments.sql
@@cwms/views/av_screening_control.sql
@@cwms/views/av_screening_criteria.sql
@@cwms/views/av_screening_dur_mag.sql
@@cwms/views/av_screening_id.sql
@@cwms/views/av_text_filter.sql
@@cwms/views/av_text_filter_element.sql
@@cwms/views/av_usgs_parameter.sql
@@cwms/views/av_usgs_parameter_all.sql
@@cwms/views/av_usgs_rating.sql
@@cwms/views/av_cwms_ts_id.sql
@@cwms/views/av_cwms_ts_id2.sql
@@cwms/views/av_unit.sql
@@cwms/views/av_specified_level.sql
@@cwms/views/av_specified_level_ui.sql
@@cwms/views/av_storage_unit.sql
@@cwms/views/av_store_rule.sql
@@cwms/views/av_store_rule_ui.sql
@@cwms/views/av_dataexchange_job.sql
@@cwms/views/av_location_level.sql
@@cwms/views/av_location_type.sql
@@cwms/views/av_loc_lvl_indicator.sql
@@cwms/views/av_loc_lvl_indicator_2.sql
@@cwms/views/av_display_units.sql
@@cwms/views/av_rating_template.sql
@@cwms/views/av_rating_spec.sql
@@cwms/views/av_rating.sql
@@cwms/views/av_rating_local.sql
@@cwms/views/av_rating_values.sql
@@cwms/views/av_rating_values_native.sql
@@cwms/views/av_transitional_rating.sql
@@cwms/views/av_virtual_rating.sql
@@cwms/views/av_ts_association.sql
--@@cwms/views/av_stream_types.sql
@@cwms/views/av_data_q_changed.sql
@@cwms/views/av_data_q_protection.sql
@@cwms/views/av_data_q_range.sql
@@cwms/views/av_data_q_repl_cause.sql
@@cwms/views/av_data_q_repl_method.sql
@@cwms/views/av_data_q_screened.sql
@@cwms/views/av_data_q_test_failed.sql
@@cwms/views/av_data_q_validity.sql
@@cwms/views/av_data_quality.sql
@@cwms/views/av_current_map_data.sql

@@cwms/views/av_data_streams.sql
@@cwms/views/av_data_streams_current.sql
@@cwms/views/av_state.sql
@@cwms/views/av_county.sql
@@cwms/views/av_nation.sql
@@cwms/views/av_property.sql
@@cwms/views/av_vert_datum_offset.sql
@@cwms/views/av_office.sql
@@cwms/views/av_entity.sql
@@cwms/views/av_entity_location.sql
@@cwms/views/av_configuration.sql
@@cwms/views/av_configuration_category.sql
@@cwms/views/av_gate.sql
@@cwms/views/av_overflow.sql
@@cwms/views/av_pump.sql

@@cwms/views/av_outlet.sql
@@cwms/views/av_compound_outlet.sql
@@cwms/views/av_gate_change.sql
@@cwms/views/av_gate_setting.sql
@@cwms/views/av_turbine.sql
@@cwms/views/av_turbine_change.sql
@@cwms/views/av_turbine_setting.sql
@@cwms/views/av_project.sql

@@cwms/views/av_gage_method.sql
@@cwms/views/av_gage_type.sql
@@cwms/views/av_gage.sql
@@cwms/views/av_gage_sensor.sql

@@cwms/views/av_streamflow_meas.sql
@@cwms/views/av_std_text.sql
@@cwms/views/av_queue_subscriber_name


--------------------------------------------------------------------------------
SHOW ERRORS;

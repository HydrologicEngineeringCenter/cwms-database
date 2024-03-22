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

	view_names id_array_t := id_array_t (
	   'av_application_login',      -- created in at_schema_2
	   'av_application_session',    -- created in at_schema_2
      'av_auth_sched_entries',
      'av_db_change_log',
      'av_active_flag',
      'av_basin',                  -- created in at_schema_2
      'av_clob',
      'av_compound_outlet',
      'av_county',
      'av_current_map_data',
      'av_cwms_media',
      'av_cwms_ts_id',
      'av_cwms_ts_id2',
      'av_cwms_user',              -- created in at_schema_2
      'av_dataexchange_job',
      'av_deleted_ts_id',
      'av_display_units',
      'av_document',
      'av_document_type',
      'av_embank_protection_type', -- created in at_schema_2
      'av_embank_structure_type',  -- created in at_schema_2
      'av_embankment',             -- created in at_schema_2
      'av_entity',
      'av_entity_location',
      'av_entity_category',
      'av_forecast',              -- created in at_schema_2
      'av_forecast_ex',           -- created in at_schema_2
      'av_forecast_spec',         -- created in at_schema_2
      'av_gage',
      'av_gage_method',
      'av_gage_sensor',
      'av_gage_type',
      'av_gate',
      'av_gate_change',
      'av_gate_setting',
      'av_loc',                    -- created in at_schema_2
      'av_loc2',                   -- created in at_schema_2
      'av_loc_alias',
      'av_loc_cat_grp',
      'av_loc_level',
      'av_loc_lvl_label',
      'av_loc_lvl_source',
      'av_loc_ts_id_count',
      'av_location_level',
      'av_location_level_curval',
      'av_location_level2',        -- created in at_schema_2
      'av_log_message',            -- created in at_schema_2
      'av_nation',
      'av_office',
      'av_outlet',
      'av_parameter',
      'av_parameter_type',
      'av_project',
      'av_project_purpose',
      'av_project_purposes',
      'av_project_purposes_ui',
      'av_property',
      'av_queue_subscriber_name',
      'av_rating',
      'av_rating_local',
      'av_rating_spec',
      'av_rating_template',
      'av_rating_values',
      'av_rating_values_native',
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
      'av_storage_unit',
      'av_store_rule',
      'av_store_rule_ui',
      'av_stream',                 -- created in at_schema_2
      'av_stream_location',        -- created in at_schema_2
      'av_streamflow_meas',
      'av_text_filter',
      'av_text_filter_element',
      'av_transitional_rating',
      'av_ts_association',
      'av_ts_extents_local',
      'av_ts_extents_utc',
      'av_ts_msg_archive',
      'av_ts_profile',             -- created in at_schema_2
      'av_ts_profile_parser',      -- created in at_schema_2
      'av_ts_profile_parser_param',-- created in at_schema_2
      'av_ts_profile_inst',        -- created in at_schema_2
      'av_ts_profile_inst_ts',     -- created in at_schema_2
      'av_ts_profile_inst_tsv',    -- created in buildCWMS_DB
      'av_ts_profile_inst_tsv2',   -- created in buildCWMS_DB
      'av_ts_profile_inst_elev',   -- created in buildCWMS_DB
      'av_ts_profile_inst_sp',     -- created in buildCWMS_DB
      'av_ts_txt',
      'av_turbine',
      'av_turbine_change',
      'av_turbine_setting',
      'av_unauth_sched_entries',
      'av_unit',
      'av_usgs_parameter',
      'av_usgs_parameter_all',
      'av_usgs_rating',
      'av_vert_datum_offset',
      'av_vloc_lvl_constituent',   -- created in at_schema_2
      'av_virtual_location_level', -- created in at_schema_2
      'av_virtual_rating',
      'av_water_user_contract',    -- created in at_schema_2
      'av_water_user_contract2',    -- created in at_schema_2
      'stats'
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
@@cwms/views/av_active_flag
@@cwms/views/av_auth_sched_entries
@@cwms/views/av_clob
@@cwms/views/av_compound_outlet
@@cwms/views/av_configuration
@@cwms/views/av_configuration_category
@@cwms/views/av_county
@@cwms/views/av_current_map_data
@@cwms/views/av_cwms_media_type
@@cwms/views/av_cwms_ts_id
@@cwms/views/av_cwms_ts_id2
@@cwms/views/av_data_q_changed
@@cwms/views/av_data_q_protection
@@cwms/views/av_data_q_range
@@cwms/views/av_data_q_repl_cause
@@cwms/views/av_data_q_repl_method
@@cwms/views/av_data_q_screened
@@cwms/views/av_data_q_test_failed
@@cwms/views/av_data_q_validity
@@cwms/views/av_data_quality
@@cwms/views/av_data_streams
@@cwms/views/av_data_streams_current
@@cwms/views/av_dataexchange_job
@@cwms/views/av_db_change_log
@@cwms/views/av_deleted_ts_id
@@cwms/views/av_display_units
@@cwms/views/av_document
@@cwms/views/av_document_type
@@cwms/views/av_entity
@@cwms/views/av_entity_location
@@cwms/views/av_entity_category
@@cwms/views/av_gage
@@cwms/views/av_gage_method
@@cwms/views/av_gage_sensor
@@cwms/views/av_gage_type
@@cwms/views/av_gate
@@cwms/views/av_gate_change
@@cwms/views/av_gate_setting
@@cwms/views/av_loc_alias
@@cwms/views/av_loc_cat_grp
@@cwms/views/av_loc_grp_assgn
@@cwms/views/av_loc_lvl_indicator
@@cwms/views/av_loc_lvl_indicator_2
@@cwms/views/av_loc_lvl_label
@@cwms/views/av_loc_lvl_source
@@cwms/views/av_loc_ts_id_count
@@cwms/views/av_location_kind
@@cwms/views/av_location_level
@@cwms/views/av_location_level_curval
@@cwms/views/av_location_type
@@cwms/views/av_nation
@@cwms/views/av_office
@@cwms/views/av_outlet
@@cwms/views/av_overflow
@@cwms/views/av_parameter
@@cwms/views/av_parameter_type
@@cwms/views/av_pool
@@cwms/views/av_pool_name
@@cwms/views/av_project
@@cwms/views/av_project_purpose
@@cwms/views/av_project_purposes
@@cwms/views/av_project_purposes_ui
@@cwms/views/av_property
@@cwms/views/av_pump
@@cwms/views/av_queue_subscriber_name
@@cwms/views/av_rating
@@cwms/views/av_rating_local
@@cwms/views/av_rating_spec
@@cwms/views/av_rating_template
@@cwms/views/av_rating_values
@@cwms/views/av_rating_values_native
@@cwms/views/av_screened_ts_ids
@@cwms/views/av_screening_assignments
@@cwms/views/av_screening_control
@@cwms/views/av_screening_criteria
@@cwms/views/av_screening_dur_mag
@@cwms/views/av_screening_id
@@cwms/views/av_shef_pe_codes
@@cwms/views/av_specified_level
@@cwms/views/av_specified_level_ui
@@cwms/views/av_state
@@cwms/views/av_std_text
@@cwms/views/av_storage_unit
@@cwms/views/av_store_rule
@@cwms/views/av_store_rule_ui
@@cwms/views/av_streamflow_meas
@@cwms/views/av_text_filter
@@cwms/views/av_text_filter_element
@@cwms/views/av_transitional_rating
@@cwms/views/av_ts_association
@@cwms/views/av_ts_extents_local
@@cwms/views/av_ts_extents_utc
@@cwms/views/av_ts_msg_archive
@@cwms/views/av_ts_text
@@cwms/views/av_tsv_count_minute
@@cwms/views/av_tsv_count_day
@@cwms/views/av_turbine
@@cwms/views/av_turbine_change
@@cwms/views/av_turbine_setting
@@cwms/views/av_unauth_sched_entries
@@cwms/views/av_unit
@@cwms/views/av_usgs_parameter
@@cwms/views/av_usgs_parameter_all
@@cwms/views/av_usgs_rating
@@cwms/views/av_vert_datum_offset
@@cwms/views/av_virtual_rating
@@cwms/views/zav_cwms_ts_id
@@cwms/views/zv_current_crit_file_code
@@cwms/views/stats

--------------------------------------------------------------------------------
SHOW ERRORS;

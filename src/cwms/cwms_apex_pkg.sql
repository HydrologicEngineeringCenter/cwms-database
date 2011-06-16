/* Formatted on 6/16/2011 12:31:38 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE cwms_apex
AS
	c_app_logic_yes	VARCHAR2 (1) DEFAULT 'T';
	c_app_logic_no 	VARCHAR2 (1) DEFAULT 'F';


	FUNCTION get_steps_per_status_update (p_count IN NUMBER)
		RETURN NUMBER;

	FUNCTION calc_seasonal_mn_offset (f_005 IN VARCHAR2)
		RETURN NUMBER;

	FUNCTION get_unit_code_from_code_id (
		f_unit_id	IN cwms_unit.unit_id%TYPE,
		p_file_id	IN NUMBER
	)
		RETURN cwms_unit.unit_code%TYPE								 --RETURN VARCHAR2
												 ;

	FUNCTION get_headers_for_apex_rpt (f_import_type IN NUMBER)
		RETURN VARCHAR2;

	FUNCTION get_header_by_column_num (
		f_column_number	IN apex_collections.c001%TYPE,
		f_import_type		IN NUMBER
	)
		RETURN VARCHAR2;

	FUNCTION get_location_level_id_param (f_location_level_id	IN VARCHAR2,
													  f_loc_num 				IN NUMBER
													 )
		RETURN VARCHAR2;

	FUNCTION strip_for_stragg (f_string IN VARCHAR2)
		RETURN VARCHAR2;

	FUNCTION str2tbl (p_str IN VARCHAR2, p_delim IN VARCHAR2 DEFAULT ',')
		RETURN str_tab_t
		PIPELINED;

	FUNCTION valid_csv_header (f_file_type 	IN NUMBER,
										f_header_loc	IN NUMBER,
										f_header_val	IN VARCHAR2
									  )
		RETURN VARCHAR2;

	-- 16JUN2010 - JDK - Function to get the upload CSV to work for eGIS Metadata work
	--this function is based on one by Connor McDonald
	--http://www.jlcomp.demon.co.uk/faq/base_convert.html
	FUNCTION hex_to_decimal (p_hex_str IN VARCHAR2)
		RETURN NUMBER;



	-- Utility functions --{{{
	--{{{
	-- Parse a HTML textarea element into the specified HTML DB collection
	-- The c001 element from the collection is used
	-- The parser splits the text into tokens delimited by newlines, spaces
	-- and commas
	PROCEDURE parse_textarea (p_textarea			 IN VARCHAR2,
									  p_collection_name	 IN VARCHAR2
									 );

	--}}}

	--{{{
	-- Generic procedure to parse an uploaded CSV file into the...
	-- specified collection. The first line in the file is expected...
	-- to contain the column headings, these are set in session state...
	-- for the specified headings item.

	PROCEDURE parse_file (
		p_file_name 				  IN		VARCHAR2,
		p_collection_name 		  IN		VARCHAR2,
		p_error_collection_name   IN		VARCHAR2,
		p_headings_item			  IN		VARCHAR2,
		p_columns_item 			  IN		VARCHAR2,
		p_ddl_item					  IN		VARCHAR2,
		p_number_of_records			  OUT NUMBER,
		p_number_of_columns			  OUT NUMBER,
		p_is_csv 					  IN		VARCHAR2 DEFAULT 'T',
		p_db_office_id 			  IN		VARCHAR2,
		p_process_id				  IN		VARCHAR2
	);


	FUNCTION get_equal_predicate (p_column_id 		  IN VARCHAR2,
											p_expr_string		  IN VARCHAR2,
											p_expr_value		  IN VARCHAR2,
											p_expr_value_test   IN VARCHAR2
										  )
		RETURN VARCHAR2;

	FUNCTION get_primary_db_office_id
		RETURN VARCHAR2;


	PROCEDURE store_parsed_crit_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_loc_group_id 					IN VARCHAR2,
		p_data_stream_id					IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	);

	PROCEDURE store_parsed_crit_csv_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_loc_group_id 					IN VARCHAR2,
		p_data_stream_id					IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	);


	PROCEDURE aa1 (p_string IN VARCHAR2);

	PROCEDURE store_parsed_loc_short_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	);

	PROCEDURE store_parsed_loc_full_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	);

	PROCEDURE store_parsed_loc_alias_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	);

	PROCEDURE store_parsed_screen_base_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	);

	PROCEDURE check_parsed_crit_file (p_collection_name IN VARCHAR2);

	PROCEDURE download_file (p_file_id IN uploaded_xls_files_t.id%TYPE);

	PROCEDURE load_ll (
		p_collection_name   IN VARCHAR2,
		p_fail_if_exists	  IN c_app_logic_no%TYPE DEFAULT c_app_logic_no
	);

	PROCEDURE load_lli (
		p_file_name 		  IN apex_application_files.filename%TYPE,
		p_user_id			  IN uploaded_xls_files_t.user_id_uploaded%TYPE,
		p_old_file_id		  IN uploaded_xls_files_t.id%TYPE DEFAULT NULL,
		p_reload_xls_file   IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no,
		p_debug_yn			  IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
	);

	PROCEDURE load_lli_2 (
		p_attr_id						IN VARCHAR2,
		p_attr_value					IN NUMBER,
		p_attr_unit 					IN VARCHAR2,
		p_conditions					IN loc_lvl_ind_cond_tab_t := loc_lvl_ind_cond_tab_t (),
		p_file_id						IN uploaded_xls_files_t.id%TYPE,
		p_indicator 					IN loc_lvl_indicator_t,
		p_location_level_id			IN VARCHAR2,
		p_maximum_age					IN at_loc_lvl_indicator.maximum_age%TYPE,
		p_minimum_duration			IN at_loc_lvl_indicator.minimum_duration%TYPE,
		p_office_id 					IN VARCHAR2,
		p_ref_specified_level_id	IN VARCHAR2,
		p_ref_attr_value				IN NUMBER,
		p_debug_yn						IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
	);

	PROCEDURE load_lli_hardcoded;

	PROCEDURE load_lli_hardcoded_2 (
		p_conditions					IN loc_lvl_ind_cond_tab_t := loc_lvl_ind_cond_tab_t (),
		p_location_level_id			IN VARCHAR2,
		p_maximum_age					IN at_loc_lvl_indicator.maximum_age%TYPE,
		p_minimum_duration			IN at_loc_lvl_indicator.minimum_duration%TYPE,
		p_office_id 					IN VARCHAR2,
		p_ref_specified_level_id	IN VARCHAR2,
		p_ref_attr_value				IN NUMBER
	);


	/* PROCEDURE parse_crit_file ( --{{{
	  p_file_name IN VARCHAR2,
	  p_collection_name IN VARCHAR2,
	  p_error_collection_name IN VARCHAR2,
	  p_headings_item   IN VARCHAR2,
	  p_columns_item IN VARCHAR2,
	  p_ddl_item IN  VARCHAR2,
	  p_number_of_records OUT NUMBER,
	  p_number_of_columns OUT NUMBER,
	  p_is_csv IN VARCHAR2 DEFAULT 'T',
	  p_db_office_id IN VARCHAR2,
	  p_process_id  IN VARCHAR2
	 );

	 PROCEDURE error_check_crit_data (
	  p_db_store_rule  IN VARCHAR2,
	  p_data_stream_id  IN VARCHAR2,
	  p_db_office_id IN VARCHAR2 DEFAULT NULL
	 );
	*/

	PROCEDURE store_parsed_loc_egis_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	);

	PROCEDURE set_log_row (
		p_error_text	 IN uploaded_xls_file_rows_t.error_code_original%TYPE,
		p_file_id		 IN uploaded_xls_file_rows_t.file_id%TYPE,
		p_pl_sql_text	 IN uploaded_xls_file_rows_t.pl_sql_call%TYPE
	);

	-- Utility to take a CSV string, parse it into a PL/SQL table
	-- Note that it takes care of some elements optionally enclosed
	-- by double-quotes.
	--{{{
	PROCEDURE csv_to_array (p_csv_string	IN 	 VARCHAR2,
									p_array				OUT wwv_flow_global.vc_arr2,
									p_separator 	IN 	 VARCHAR2 := ','
								  );
END cwms_apex;
/
/* Formatted on 3/24/2009 6:35:27 AM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE cwms_20.cwms_apex
AS
	/******************************************************************************
		  NAME:		  cwms_apex
		  PURPOSE:

		  REVISIONS:
			Ver		  Date		  Author 			 Description
		 ---------	----------	---------------  ------------------------------------
			 1.0			3/23/2007				 1. Created this package.
	 ******************************************************************************/




	-- Utility functions --{{{
	--{{{
	-- Parse a HTML textarea element into the specified HTML DB collection
	-- The c001 element from the collection is used
	-- The parser splits the text into tokens delimited by newlines, spaces
	-- and commas
	PROCEDURE parse_textarea (p_textarea	  IN VARCHAR2,
									  p_collection_name IN VARCHAR2
									 );

	--}}}

	--{{{
	-- Generic procedure to parse an uploaded CSV file into the...
	-- specified collection. The first line in the file is expected...
	-- to contain the column headings, these are set in session state...
	-- for the specified headings item.

	PROCEDURE parse_file (p_file_name	 IN	  VARCHAR2,
								 p_collection_name IN  VARCHAR2,
								 p_error_collection_name IN VARCHAR2,
								 p_headings_item IN	  VARCHAR2,
								 p_columns_item IN	  VARCHAR2,
								 p_ddl_item 	 IN	  VARCHAR2,
								 p_number_of_records   OUT NUMBER,
								 p_number_of_columns   OUT NUMBER,
								 p_is_csv		 IN	  VARCHAR2 DEFAULT 'T' ,
								 p_db_office_id IN	  VARCHAR2,
								 p_process_id	 IN	  VARCHAR2
								);


	FUNCTION get_equal_predicate (p_column_id 	IN VARCHAR2,
											p_expr_string	IN VARCHAR2,
											p_expr_value	IN VARCHAR2,
											p_expr_value_test IN VARCHAR2
										  )
		RETURN VARCHAR2;

	FUNCTION get_primary_db_office_id
		RETURN VARCHAR2;


	PROCEDURE store_parsed_crit_file (
		p_parsed_collection_name IN VARCHAR2,
		p_store_err_collection_name IN VARCHAR2,
		p_loc_group_id IN VARCHAR2,
		p_data_stream_id IN VARCHAR2,
		p_db_office_id IN VARCHAR2 DEFAULT NULL ,
		p_unique_process_id IN VARCHAR2
	);

	PROCEDURE store_parsed_crit_csv_file (
		p_parsed_collection_name IN VARCHAR2,
		p_store_err_collection_name IN VARCHAR2,
		p_loc_group_id IN VARCHAR2,
		p_data_stream_id IN VARCHAR2,
		p_db_office_id IN VARCHAR2 DEFAULT NULL ,
		p_unique_process_id IN VARCHAR2
	);


	PROCEDURE aa1 (p_string IN VARCHAR2);

	PROCEDURE store_parsed_loc_short_file (
		p_parsed_collection_name IN VARCHAR2,
		p_store_err_collection_name IN VARCHAR2,
		p_db_office_id IN VARCHAR2 DEFAULT NULL ,
		p_unique_process_id IN VARCHAR2
	);

	PROCEDURE store_parsed_loc_full_file (
		p_parsed_collection_name IN VARCHAR2,
		p_store_err_collection_name IN VARCHAR2,
		p_db_office_id IN VARCHAR2 DEFAULT NULL ,
		p_unique_process_id IN VARCHAR2
	);

	PROCEDURE store_parsed_loc_alias_file (
		p_parsed_collection_name IN VARCHAR2,
		p_store_err_collection_name IN VARCHAR2,
		p_db_office_id IN VARCHAR2 DEFAULT NULL ,
		p_unique_process_id IN VARCHAR2
	);

	PROCEDURE store_parsed_screen_base_file (
		p_parsed_collection_name IN VARCHAR2,
		p_store_err_collection_name IN VARCHAR2,
		p_db_office_id IN VARCHAR2 DEFAULT NULL ,
		p_unique_process_id IN VARCHAR2
	);

	PROCEDURE check_parsed_crit_file (p_collection_name IN VARCHAR2);

	PROCEDURE parse_crit_file (														 --{{{
										p_file_name 	IN 	 VARCHAR2,
										p_collection_name IN  VARCHAR2,
										p_error_collection_name IN VARCHAR2,
										p_headings_item IN	 VARCHAR2,
										p_columns_item IN 	 VARCHAR2,
										p_ddl_item		IN 	 VARCHAR2,
										p_number_of_records	 OUT NUMBER,
										p_number_of_columns	 OUT NUMBER,
										p_is_csv 		IN 	 VARCHAR2 DEFAULT 'T' ,
										p_db_office_id IN 	 VARCHAR2,
										p_process_id	IN 	 VARCHAR2
									  );

	PROCEDURE error_check_crit_data (p_db_store_rule IN VARCHAR2,
												p_data_stream_id IN VARCHAR2,
												p_db_office_id IN VARCHAR2 DEFAULT NULL
											  );
END cwms_apex;
/
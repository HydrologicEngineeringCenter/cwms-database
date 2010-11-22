/* Formatted on 3/29/2010 3:04:35 PM (QP5 v5.139.911.3011) */
CREATE OR REPLACE PACKAGE cwms_util
AS
	/******************************************************************************
	 *   Name:		  CWMS_UTL
	*	 Purpose:	 Miscellaneous CWMS Procedures
	*
	  *	Revisions:
	 *   Ver 		 Date 		 Author		 Descriptio
	  *	---------  ----------  ----------  ----------------------------------------
	  *	1.1		  9/07/2005   Portin 	  create_view: at_ts_table_properties start and end dates
	  *												  changed to DATE datatype
	*	 1.0			8/29/2005	Portin		Original
	 ******************************************************************************/
	l_epoch CONSTANT DATE
			:= TO_DATE ('01Jan1970 00:00', 'ddmonyyyy hh24:mi') ;
	l_epoch_wk_dy_1 CONSTANT DATE
			:= TO_DATE ('04Jan1970 00:00', 'ddmonyyyy hh24:mi') ;
	-- Sunday.
	-- Constants for Storage Business Rules
	replace_all CONSTANT 							VARCHAR2 (16) := 'REPLACE ALL';
	do_not_replace CONSTANT 						VARCHAR2 (16) := 'DO NOT REPLACE';
	replace_missing_values_only CONSTANT VARCHAR2 (32)
			:= 'REPLACE MISSING VALUES ONLY' ;
	replace_with_non_missing CONSTANT VARCHAR2 (32)
			:= 'REPLACE WITH NON MISSING' ;
	delete_insert CONSTANT							VARCHAR2 (16) := 'DELETE INSERT';

	delete_key CONSTANT								VARCHAR2 (16) := 'DELETE KEY';
	delete_data CONSTANT 							VARCHAR2 (22) := 'DELETE DATA';
	delete_all CONSTANT								VARCHAR2 (16) := 'DELETE ALL';

	delete_ts_id CONSTANT							VARCHAR2 (22) := 'DELETE TS ID';
	delete_loc CONSTANT								VARCHAR2 (22) := 'DELETE LOC';
	delete_ts_data CONSTANT 						VARCHAR2 (22) := 'DELETE TS DATA';
	delete_ts_cascade CONSTANT 					VARCHAR2 (22) := 'DELETE TS CASCADE';
	delete_loc_cascade CONSTANT					VARCHAR2 (22) := 'DELETE LOC CASCADE';
	--
	-- non_versioned is the default version_date for non-versioned timeseries
	non_versioned CONSTANT							DATE := DATE '1111-11-11';
	utc_offset_irregular CONSTANT 				NUMBER := -2147483648;
	utc_offset_undefined CONSTANT 				NUMBER := 2147483647;
	true_num CONSTANT 								NUMBER := 1;
	false_num CONSTANT								NUMBER := 0;
	max_base_id_length CONSTANT					NUMBER := 16;
	max_sub_id_length CONSTANT 					NUMBER := 32;
	max_full_id_length CONSTANT NUMBER
			:= max_base_id_length + max_sub_id_length + 1 ;
	--
	db_office_code_all CONSTANT					NUMBER := 53;
	--
	irregular_interval_code CONSTANT 			NUMBER := 29;
	--
	field_separator CONSTANT						VARCHAR2 (1) := CHR (29);
	record_separator CONSTANT						VARCHAR2 (1) := CHR (30);
	escape_char CONSTANT 							VARCHAR2 (1) := '\';
	mv_cwms_ts_id_refresh_interval CONSTANT	NUMBER := 5;
	-- minutes
   odbc_ts_fmt constant varchar2(50) := '"{ts ''"yyyy-mm-dd hh24:mi:ss"''}"';
   odbc_d_fmt  constant varchar2(50) := '"{d ''"yyyy-mm-dd"''}"';
	-- CWMS_PRIVILEGES...
	read_privilege CONSTANT 						NUMBER := 4;
	write_privilege CONSTANT						NUMBER := 2;
	--
	-- CWMS SPECIAL USER GROUPS...
	dba_users CONSTANT								NUMBER := 1;
	dbi_users CONSTANT								NUMBER := 2;
	data_exchange_mgr CONSTANT 					NUMBER := 4;
	data_acquisition_mgr CONSTANT 				NUMBER := 8;
	ts_creator CONSTANT								NUMBER := 16;
	vt_mgr CONSTANT									NUMBER := 32;
	all_users CONSTANT								NUMBER := 64;
	epoch CONSTANT timestamp
			:= STANDARD.TO_TIMESTAMP ('1970/01/01/ 00:00:00',
											  'yyyy/mm/dd hh24:mi:ss'
											 ) ;

	-- table of rows with string fields
	TYPE cat_unit_rec_t IS RECORD (unit_id VARCHAR2 (16));

	TYPE cat_unit_tab_t IS TABLE OF cat_unit_rec_t;



	--------------------------------------------------------------------------------
	-- Splits string into a table of strings using the specified delimiter.
	-- If no delmiter is specified, the string is split around whitespace.
	--
	-- Sequential delimiters in the source string result in null fields in the table,
	-- except that if no delimiter is supplied, sequential whitespace characters are
	-- treated as a single delimiter.
	--
	FUNCTION split_text (p_text		  IN VARCHAR2,
								p_separator   IN VARCHAR2 DEFAULT NULL ,
								p_max_split   IN INTEGER DEFAULT NULL
							  )
		RETURN str_tab_t;

	--------------------------------------------------------------------------------
	-- Splits string into a table of strings using the specified delimiter.
	-- If no delmiter is specified, the string is split around whitespace.
	--
	-- Sequential delimiters in the source string result in null fields in the table,
	-- except that if no delimiter is supplied, sequential whitespace characters are
	-- treated as a single delimiter.
	--
	FUNCTION split_text (p_text		  IN CLOB,
								p_separator   IN VARCHAR2 DEFAULT NULL ,
								p_max_split   IN INTEGER DEFAULT NULL
							  )
		RETURN str_tab_t;

	--------------------------------------------------------------------------------
	-- Joins a table of strings into a single string using the specified delimiter.
	-- If no delimiter is supplied, the table fields are simply concatenated together.
	--
	-- Null fields in the table result in sequential delimiters in the returned string.
	--
	FUNCTION join_text (p_text_tab	 IN str_tab_t,
							  p_separator	 IN VARCHAR2 DEFAULT NULL
							 )
		RETURN VARCHAR2;

	--------------------------------------------------------------------------------
	-- Formats the XML in the CLOB to have one element tag per line, indented by
	-- the specified string.
	--
	PROCEDURE format_xml (p_xml_clob   IN OUT NOCOPY CLOB,
								 p_indent	  IN				 VARCHAR2 DEFAULT CHR (9)
								);

	--------------------------------------------------------------------------------
	-- Parses a CLOB into a table of tables of strings.
	--
	-- Records are delimited by the record_separator character defined above.
	-- Fields are delmited by the field_separator character defined above.
	--
	FUNCTION parse_clob_recordset (p_clob IN CLOB)
		RETURN str_tab_tab_t;

	--------------------------------------------------------------------------------
	-- Parses a string into a table of tables of strings.
	--
	-- Records are delimited by the record_separator character defined above.
	-- Fields are delmited by the field_separator character defined above.
	--
	FUNCTION parse_string_recordset (p_string IN VARCHAR2)
		RETURN str_tab_tab_t;

	TYPE ts_list
	IS
		TABLE OF VARCHAR2 (200)
			INDEX BY BINARY_INTEGER;

	--
	FUNCTION min_dms (p_decimal_degrees IN NUMBER)
		RETURN NUMBER;

	--
	FUNCTION sec_dms (p_decimal_degrees IN NUMBER)
		RETURN NUMBER;

	--
	FUNCTION min_dm (p_decimal_degrees IN NUMBER)
		RETURN NUMBER;

	--
	-- return the p_in_date which is in p_in_tz as a date in UTC
	FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
		RETURN DATE;

   --
   -- return the input date in a different time zone
   FUNCTION change_timezone (
      p_in_date IN DATE, 
      p_from_tz IN VARCHAR2, 
      p_to_tz   IN VARCHAR2 default 'UTC')
      RETURN DATE result_cache;

	--
	-- Retruns TRUE if p_true_false is T or True.
	FUNCTION is_true (p_true_false IN VARCHAR2)
		RETURN BOOLEAN result_cache;

	--
	-- Retruns TRUE if p_true_false is F or False.
	FUNCTION is_false (p_true_false IN VARCHAR2)
		RETURN BOOLEAN result_cache;

	--
	-- Retruns TRUE if p_true_false is T or True
	-- Returns FALSE if p_true_false is F or False.
	FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
		RETURN BOOLEAN result_cache;

	FUNCTION return_t_or_f_flag (p_true_false IN VARCHAR2)
		RETURN VARCHAR2 result_cache;

	FUNCTION get_base_id (p_full_id IN VARCHAR2)
		RETURN VARCHAR2;

	FUNCTION get_sub_id (p_full_id IN VARCHAR2)
		RETURN VARCHAR2;

	FUNCTION get_ts_interval (p_cwms_ts_code IN NUMBER)
		RETURN NUMBER;

	FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
		RETURN VARCHAR2;

	FUNCTION concat_ts_id (p_base_location_id 	IN VARCHAR2,
								  p_sub_location_id		IN VARCHAR2,
								  p_base_parameter_id	IN VARCHAR2,
								  p_sub_parameter_id 	IN VARCHAR2,
								  p_parameter_type_id	IN VARCHAR2,
								  p_interval_id			IN VARCHAR2,
								  p_duration_id			IN VARCHAR2,
								  p_version_id 			IN VARCHAR2
								 )
		RETURN VARCHAR2;

	--------------------------------------------------------
	-- Return the current session user's primary office id
	--
	FUNCTION user_office_id
		RETURN VARCHAR2;

	--------------------------------------------------------
	-- return the current session user's primary office code
	--
	FUNCTION user_office_code
		RETURN NUMBER;

	--------------------------------------------------------
	-- Return the office code for the specified office id,
	-- or the user's primary office if the office id is null
	--
	FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN NUMBER;

	FUNCTION get_db_office_id (p_db_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN VARCHAR2;

   FUNCTION get_location_id (
      p_location_code  IN NUMBER,
      p_prepend_office IN VARCHAR2 DEFAULT 'F')
      RETURN VARCHAR2;
      
	FUNCTION get_parameter_id (p_parameter_code IN NUMBER)
		RETURN VARCHAR2;

	--------------------------------------------------------------------------------
	-- function get_time_zone_code
	--
	FUNCTION get_time_zone_code (p_time_zone_name IN VARCHAR2)
		RETURN NUMBER;

	--------------------------------------------------------------------------------
	-- function get_tz_usage_code
	--
	FUNCTION get_tz_usage_code (p_tz_usage_id IN VARCHAR2)
		RETURN NUMBER;

	--------------------------------------------------------------------------------
	-- function get_real_name
	--
	FUNCTION get_real_name (p_synonym IN VARCHAR2)
		RETURN VARCHAR2;

	--------------------------------------------------------
	-- Return the db host office code for the specified office id,
	-- or the user's primary office if the office id is null
	--
	FUNCTION get_db_office_code (p_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN NUMBER;

	--------------------------------------------------------
	-- Replace filename wildcard chars (?,*) with SQL ones
	-- (_,%), using '\' as an escape character.
	--
	--  A null input generates a result of '%'.
	--
	-- +--------------+-------------------------------------------------------------------------+
	-- |				  |									  Output String										 |
	-- |				  +------------------------------------------------------------+------------+
	-- |				  |									 Recognize SQL 						|				 |
	-- |				  |									  Wildcards?							|				 |
	-- |				  +------+---------------------------+-----+-------------------+				 |
	-- | Input String | No	: comments						 | Yes : comments 			| Different? |
	-- +--------------+------+---------------------------+-----+-------------------+------------+
	-- | %			  | \%	: literal '%'               | %   : multi-wildcard    | Yes        |
	-- | _			  | \_	: literal '_'               | _   : single-wildcard   | Yes        |
	-- | *			  | % 	: multi-wildcard				 | %	 : multi-wildcard 	| No			 |
	-- | ?			  | _ 	: single-wildcard 			 | _	 : single-wildcard	| No			 |
	-- | \%			  |		: not allowed					 | \%  : literal '%'       | Yes        |
	-- | \_			  |		: not allowed					 | \_  : literal '_'       | Yes        |
	-- | \*			  | * 	: literal '*'               | *   : literal '*'       | No         |
	-- | \?			  | ? 	: literal '?'               | ?   : literal '?'       | No         |
	-- | \\% 		  | \\\% : literal '\' + literal '%' | \\% : literal '\' + mwc | Yes        |
	-- | \\_ 		  | \\\_ : literal '\' + literal '\' | \\_ : literal '\' + swc | Yes        |
	-- | \\* 		  | \\%	: literal '\' + mwc         | \\% : literal '\' + mwc | No         |
	-- | \\? 		  | \\_	: literal '\' + swc         | \\_ : literal '\' + swc | No         |
	-- +--------------+------+---------------------------+-----+-------------------+------------+
	FUNCTION normalize_wildcards (p_string 			IN VARCHAR2,
											p_recognize_sql		BOOLEAN DEFAULT FALSE
										  )
		RETURN VARCHAR2;

	FUNCTION denormalize_wildcards (p_string IN VARCHAR2)
		RETURN VARCHAR2;

	PROCEDURE parse_ts_id (p_base_location_id 		OUT VARCHAR2,
								  p_sub_location_id			OUT VARCHAR2,
								  p_base_parameter_id		OUT VARCHAR2,
								  p_sub_parameter_id 		OUT VARCHAR2,
								  p_parameter_type_id		OUT VARCHAR2,
								  p_interval_id				OUT VARCHAR2,
								  p_duration_id				OUT VARCHAR2,
								  p_version_id 				OUT VARCHAR2,
								  p_cwms_ts_id 			IN 	 VARCHAR2
								 );

	--------------------------------------------------------------------
	-- Returns an AND/OR predicate string for a multi-element search set.
	--
	FUNCTION parse_search_string (p_search_patterns   IN VARCHAR2,
											p_search_column	  IN VARCHAR2,
											p_use_upper 		  IN BOOLEAN DEFAULT TRUE
										  )
		RETURN VARCHAR2;

	--------------------------------------------------------------------
	-- Return a string with all leading and trailing whitespace removed.
	--
	FUNCTION strip (p_text IN VARCHAR2)
		RETURN VARCHAR2;

	--------------------------------------------------------------------
	-- Return UTC timestamp for specified ISO 8601 string
	--
	FUNCTION TO_TIMESTAMP (p_iso_str IN VARCHAR2)
		RETURN timestamp;

	--------------------------------------------------------------------
	-- Return UTC timestamp for specified Java milliseconds
	--
	FUNCTION TO_TIMESTAMP (p_millis IN NUMBER)
		RETURN timestamp;

	--------------------------------------------------------------------
	-- Return Java milliseconds for a specified UTC timestamp.
	--
	FUNCTION to_millis (p_timestamp IN timestamp)
		RETURN NUMBER;

	--------------------------------------------------------------------
	-- Return Java milliseconds for current time.
	--
	FUNCTION current_millis
		RETURN NUMBER;

	--------------------------------------------------------------------
	PROCEDURE test;

	-- Dump (put_line) a character string p_str in chunks of length p_len
	PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80 );

	-- Create the partitioned timeseries table view
	PROCEDURE create_view;

	PROCEDURE get_user_office_data (p_office_id			  OUT VARCHAR2,
											  p_office_long_name   OUT VARCHAR2
											 );

	PROCEDURE get_valid_units (p_valid_units		  OUT sys_refcursor,
										p_parameter_id   IN		VARCHAR2 DEFAULT NULL
									  );

	PROCEDURE start_mv_cwms_ts_id_job;

	PROCEDURE stop_mv_cwms_ts_id_job;

	PROCEDURE refresh_mv_cwms_ts_id;
    FUNCTION get_valid_unit_id (p_unit_id            IN VARCHAR2,
                                     p_parameter_id    IN VARCHAR2 DEFAULT NULL
                                    )
    RETURN VARCHAR2;

	FUNCTION get_valid_units_tab (p_parameter_id IN VARCHAR2 DEFAULT NULL )
		RETURN cat_unit_tab_t
		PIPELINED;

	FUNCTION get_unit_code (p_unit_id				 IN VARCHAR2,
									p_abstract_param_id	 IN VARCHAR2 DEFAULT NULL ,
									p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
								  )
		RETURN NUMBER;

	FUNCTION get_loc_group_code (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_db_office_code	 IN NUMBER
										 )
		RETURN NUMBER;

	FUNCTION get_loc_group_code (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_db_office_id		 IN VARCHAR2
										 )
		RETURN NUMBER;

	FUNCTION get_user_id
		RETURN VARCHAR2;

   procedure user_display_unit(
      p_unit_id      out varchar2,
      p_value_out    out number,
      p_parameter_id in  varchar2,
      p_value_in     in  number   default null,
      p_user_id      in  varchar2 default null,
      p_office_id    in  varchar2 default null);
      
	FUNCTION get_interval_string (p_interval IN NUMBER)
		RETURN VARCHAR2;

   function get_user_display_unit(
      p_parameter_id in varchar2,
      p_user_id      in varchar2 default null,
      p_office_id    in varchar2 default null)
   return varchar2;
   
	FUNCTION get_default_units (p_parameter_id	IN VARCHAR2,
										 p_unit_system 	IN VARCHAR2 DEFAULT 'SI'
										)
		RETURN VARCHAR2;

	--
	-- sign-extends 32-bit integers so they can be retrieved by
	-- java int type
	--
	FUNCTION sign_extend (p_int IN INTEGER)
		RETURN INTEGER;
		
   function months_to_yminterval(
      p_months in integer) 
      return interval year to month;
   
   function minutes_to_dsinterval(
      p_minutes in integer) 
      return interval day to second;
   
   function yminterval_to_months(
      p_intvl in interval year to month) 
      return integer;
   
   function dsinterval_to_minutes(
      p_intvl in interval day to second) 
      return integer;
      
   function parse_odbc_ts_string(
      p_odbc_str in varchar2)
      return date;

   function parse_odbc_d_string(
      p_odbc_str in varchar2)
      return date;

   function parse_odbc_ts_or_d_string(
      p_odbc_str in varchar2)
      return date;
   
   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_algebraic
   -- 
   -- Returns a table of RPN tokens for a specified algebraic expression
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   -----------------------------------------------------------------------------
   function tokenize_algebraic(
      p_algebraic_expr in varchar2)
      return str_tab_t result_cache;
   
   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_RPN
   -- 
   -- Returns a table of RPN tokens for a specified delimited RPN expression
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- All numbers, arguments and operators must be separated by whitespace
   -----------------------------------------------------------------------------
   function tokenize_RPN(
      p_RPN_expr  in varchar2)
      return str_tab_t result_cache;
      
   -----------------------------------------------------------------------------
   -- FUNCTION eval_tokenized_expression
   -- 
   -- Returns the result of evaluating RPN tokens against specified arguments
   --
   -- The tokens are not case sensitive
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------
   function eval_tokenized_expression(
      p_RPN_tokens in str_tab_t,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return number;      
      
   -----------------------------------------------------------------------------
   -- FUNCTION eval_algebraic_expression
   -- 
   -- Returns the result of evaluating an algebraic expression against specified 
   -- arguments
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------
   function eval_algebraic_expression(
      p_algebraic_expr in varchar2,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return number;      
      
   -----------------------------------------------------------------------------
   -- FUNCTION eval_RPN_expression
   -- 
   -- Returns the result of evaluating a delimited RPN expression against
   -- specified arguments
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- All numbers, arguments and operators must be separated by whitespace
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------
   function eval_RPN_expression(
      p_RPN_expr    in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return number;      

   -----------------------------
   -- check for SQL injection --
   -----------------------------
   procedure check_inputs(
      p_input in str_tab_t
   );
   procedure check_input(
      p_input in varchar2
   );
   
   ---------------------
   -- Append routines --
   ---------------------
   procedure append(
      p_dst in out nocopy clob,
      p_src in            clob);
      
   procedure append(
      p_dst in out nocopy clob,
      p_src in            varchar2);
      
   procedure append(
      p_dst in out nocopy clob,
      p_src in            xmltype);

   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            clob);
      
   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            varchar2);
      
   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            xmltype);
   
END cwms_util;
/

SHOW errors;

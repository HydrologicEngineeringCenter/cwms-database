set escape `;
CREATE OR REPLACE PACKAGE cwms_util
/**
 Miscellaneous constants and procedures.
 
 @author Various
 @since CWMS 2.0
 */
AS
   /**
    * Beginning of Unix epoch (01Jan1970 00:00:00 UTC) as a <code><big>DATE</big></code>.
    */
   l_epoch CONSTANT DATE
         := TO_DATE ('01Jan1970 00:00', 'ddmonyyyy hh24:mi') ;
   /**
    * Beginning of Sunday of the first full week of the Unix epoch (04Jan1970 00:00:00 UTC)
    * as a <code><big>DATE</big></code>.
    */
   l_epoch_wk_dy_1 CONSTANT DATE
         := TO_DATE ('04Jan1970 00:00', 'ddmonyyyy hh24:mi') ;
   /**
    * Store rule to replace any/all existing values, but do not insert values that 
    * don't already exits.
    */
   replace_all CONSTANT                      VARCHAR2 (16) := 'REPLACE ALL';
   /**
    * Store rule to only insert values that don't already exist.
    */
   do_not_replace CONSTANT                   VARCHAR2 (16) := 'DO NOT REPLACE';
   /**
    * Store rule to only replace missing values
    */
   replace_missing_values_only CONSTANT VARCHAR2 (32)
         := 'REPLACE MISSING VALUES ONLY' ;
   /**
    * Store rule to any values with non-missing values.
    */
   replace_with_non_missing CONSTANT VARCHAR2 (32)
         := 'REPLACE WITH NON MISSING' ;
   /**
    * Store rule to remove all values in time window before storing new values.
    */
   delete_insert CONSTANT                    VARCHAR2 (16) := 'DELETE INSERT';
   /**
    * Delete action that specifies deletion of the specified identifier only; not
    * data dependent on the identifier is to be deleted.
    */
   delete_key CONSTANT                       VARCHAR2 (16) := 'DELETE KEY';
   /**
    * Delete action that specifies deletion of data dependent on the specified 
    * identifier only; the identifier itself is not to be deleted.
    */
   delete_data CONSTANT                      VARCHAR2 (22) := 'DELETE DATA';
   /**
    * Delete action that specifies deletion of specified identifier and all data
    * dependent on the specified identifier. 
    */
   delete_all CONSTANT                       VARCHAR2 (16) := 'DELETE ALL';
   /**
    * Delete action for time series equivalent to <code><big>delete_key</big></code>
    */       
   delete_ts_id CONSTANT                     VARCHAR2 (22) := 'DELETE TS ID';
   /**
    * Delete action for locations equivalent to <code><big>delete_key</big></code>
    */       
   delete_loc CONSTANT                       VARCHAR2 (22) := 'DELETE LOC';
   /**
    * Delete action for time series equivalent to <code><big>delete_data</big></code>
    */       
   delete_ts_data CONSTANT                   VARCHAR2 (22) := 'DELETE TS DATA';
   /**
    * Delete action for time series equivalent to <code><big>delete_all</big></code>
    */       
   delete_ts_cascade CONSTANT                VARCHAR2 (22) := 'DELETE TS CASCADE';
   /**
    * Delete action for locations equivalent to <code><big>delete_all</big></code>
    */       
   delete_loc_cascade CONSTANT               VARCHAR2 (22) := 'DELETE LOC CASCADE';
   /**
    * Cookie for specifying version date of non-versioned time series
    */       
   non_versioned CONSTANT                    DATE := DATE '1111-11-11';
   /** 
    * Cookie for specifying UTC Interval Offset for irregular time series
    */       
   utc_offset_irregular CONSTANT             NUMBER := -2147483648;
   /**
    * Cookie for specifying as-yet undefined UTC Interval Offset for regular time series 
    */       
   utc_offset_undefined CONSTANT             NUMBER := 2147483647;
   /**
    * Value indicating <code><big>TRUE</big></code> for routines that take numerical
    * representation of boolean values     
    */       
   true_num CONSTANT                         NUMBER := 1;
   /**
    * Value indicating <code><big>FALSE</big></code> for routines that take numerical
    * representation of boolean values     
    */       
   false_num CONSTANT                        NUMBER := 0;
   /**
    * Maximum length of the base portion of certain CWMS identifiers (location, parameter, etc...) 
    */       
   max_base_id_length CONSTANT               NUMBER := 16;
   /**
    * Maximum length of the sub portion of certain CWMS identifiers (location, parameter, etc...) 
    */       
   max_sub_id_length CONSTANT                NUMBER := 32;
   /**
    * Maximum total length of certain CWMS identifiers (location, parameter, etc...) 
    */       
   max_full_id_length CONSTANT NUMBER
         := max_base_id_length + max_sub_id_length + 1 ;
   /**
    * Code in CWMS_OFFICE table that represents the "CWMS" office (all offices) 
    */       
   db_office_code_all CONSTANT               NUMBER := 53;
   /**
    * Code in CWMS_INTERVAL table that represents irregular intervals 
    */       
   irregular_interval_code CONSTANT          NUMBER := 29;
   /**
    * Field separator used in text recordset representation (ASCII GS char)
    */       
   field_separator CONSTANT                  VARCHAR2 (1) := CHR (29);
   /**
    * Record separator used in text recordset representation (ASCII RS char)
    */       
   record_separator CONSTANT                 VARCHAR2 (1) := CHR (30);
   /**
    * Default escape character
    */       
   escape_char CONSTANT                      VARCHAR2 (1) := '\';
   mv_cwms_ts_id_refresh_interval CONSTANT   NUMBER := 30;
   /**
    * ODBC-style timestamp format for PL/SQL 
    */       
   odbc_ts_fmt constant varchar2(50) := '"{ts ''"yyyy-mm-dd hh24:mi:ss"''}"';
   /**
    * ODBC-style date format for PL/SQL 
    */       
   odbc_d_fmt  constant varchar2(50) := '"{d ''"yyyy-mm-dd"''}"';
   /**
    * Database privilige for retrieving data
    */       
   read_privilege CONSTANT                   NUMBER := 4;
   /**
    * Database privilege for storing data
    */       
   write_privilege CONSTANT                  NUMBER := 2;
   dba_users CONSTANT                        NUMBER := 1;
   dbi_users CONSTANT                        NUMBER := 2;
   data_exchange_mgr CONSTANT                NUMBER := 4;
   data_acquisition_mgr CONSTANT             NUMBER := 8;
   ts_creator CONSTANT                       NUMBER := 16;
   vt_mgr CONSTANT                           NUMBER := 32;
   all_users CONSTANT                        NUMBER := 64;
   /**
    * Beginning of Unix epoch (01Jan1970 00:00:00 UTC) as a <code><big>TIMESTAMP</big></code>.
    */
   epoch CONSTANT timestamp
         := STANDARD.TO_TIMESTAMP ('1970/01/01/ 00:00:00',
                                   'yyyy/mm/dd hh24:mi:ss');
   /**
    * Contains names of all constants that can be used with expression evaluation.
    */                                                             
   expression_constants str_tab_t := str_tab_t('E','PI');
   /**
    * Contains all mathematical operators that can be used with expression evaluation.
    */                                                             
   expression_operators str_tab_t := str_tab_t('+','-','*','/','//','%','^');
   /**
    * Contains names of all functions that can be used with expression evaluation.
    */                                                             
   expression_functions str_tab_t := str_tab_t(
      'ABS','ACOS','ASIN','ATAN','CEIL','COS','EXP','FLOOR',
      'INV','LN','LOG','NEG','ROUND','SIGN','SIN','SQRT','TAN','TRUNC');
   /**
    * Record type contained in <code><big>cat_unit_tab_t</big></code>, which is
    * returned by <code><big>get_valid_units_tab</big></code>    
    */             
   TYPE cat_unit_rec_t IS RECORD (unit_id VARCHAR2 (16));
   /**
    * Table type returned by <code><big>get_valid_units_tab</big></code>    
    */             
   TYPE cat_unit_tab_t IS TABLE OF cat_unit_rec_t;
   /**
      Retrieves the nth delimited string.
      <br>
      Sequential delimiters in the source string result in null fields in the table,
      except that if no delimiter is supplied, sequential whitespace characters are
      treated as a single delimiter.
      <br>
      If no string can be found to satisfy the input parameters, the function return
      <code><big>NULL</big></code>. 
      
      @param p_text The text to be split.
      
      @param p_return_index Specifies 'n' (which delimited string to return).
      
      @param p_separator The separator string on which to split the text. If not
        specified or specified as <code><big>NULL</big></code>, the input text will be split
        on all whitespace occurrences.
        
      @param p_max_split Specifies the maximum number of splits to perform.  The 
        maximum number of items returned will be one greater than this number. If
        not specified or specified as <code><big>NULL</big></code>, no maximum will be imposed
        and the input text will be split on every occurrence of the specified
        separator.
        
      @return The nth delimited string in the input string or <code><big>NULL</big></code>
        if no such string exists.        
   */
   function split_text (p_text        in varchar2,
                p_return_index in integer ,
                        p_separator   IN VARCHAR2 DEFAULT NULL ,
                        p_max_split   in integer default null
                       )
      RETURN VARCHAR2;
   /**
      Splits string into a table of strings using the specified delimiter.
      If no delmiter is specified, the string is split around whitespace.
      <br>
      Sequential delimiters in the source string result in null fields in the table,
      except that if no delimiter is supplied, sequential whitespace characters are
      treated as a single delimiter.
      
      @param p_text The text to be split.
      
      @param p_separator The separator string on which to split the text. If not
        specified or specified as <code><big>NULL</big></code>, the input text will be split
        on all whitespace occurrences.
        
      @param p_max_split Specifies the maximum number of splits to perform.  The 
        maximum number of items returned will be one greater than this number. If
        not specified or specified as <code><big>NULL</big></code>, no maximum will be imposed
        and the input text will be split on every occurrence of the specified
        separator.
        
      @return A table of strings.        
   */
   FUNCTION split_text (p_text        IN VARCHAR2,
                        p_separator   IN VARCHAR2 DEFAULT NULL ,
                        p_max_split   IN INTEGER DEFAULT NULL
                       )
      RETURN str_tab_t result_cache;
   /**
      Splits string into a table of strings using the specified delimiter.
      If no delmiter is specified, the string is split around whitespace.
      <br>
      Sequential delimiters in the source string result in null fields in the table,
      except that if no delimiter is supplied, sequential whitespace characters are
      treated as a single delimiter.
      
      @param p_text The text to be split.
      
      @param p_separator The separator string on which to split the text. If not
        specified or specified as <code><big>NULL</big></code>, the input text will be split
        on all whitespace occurrences.
        
      @param p_max_split Specifies the maximum number of splits to perform.  The 
        maximum number of items returned will be one greater than this number. If
        not specified or specified as <code><big>NULL</big></code>, no maximum will be imposed
        and the input text will be split on every occurrence of the specified
        separator.
        
      @return A table of strings.        
   */
   FUNCTION split_text (p_text        IN CLOB,
                        p_separator   IN VARCHAR2 DEFAULT NULL ,
                        p_max_split   IN INTEGER DEFAULT NULL
                       )
      RETURN str_tab_t;
   /**
      Joins a table of strings into a single string using the specified delimiter.
      If no delimiter is supplied or is specified as <code><big>NULL</big></code>, the input 
      strings are simply concatenated together.
      <p>
      Null strings in the table result in adjacent delimiters in the returned string.
      
      @param p_text_tab A table of strings to be joined
      
      @param p_separator The string to insert between the strings in <code><big>p_tab_text</big></code>
      
      @return The joined string
    */
   FUNCTION join_text (p_text_tab    IN str_tab_t,
                       p_separator   IN VARCHAR2 DEFAULT NULL
                      )
      RETURN VARCHAR2;
   /**
      Formats the XML in the CLOB to have one element tag per line, indented by
      the specified string.  The input is overwritten with the output.
      
      @param p_xml_clob <code><big>input: </big></code> The XML instance to be formatted<br> 
                        <code><big>output:</big></code> The formatted XML instance
      @param p_indent The string to use for indentation                         
    */
   PROCEDURE format_xml (p_xml_clob   IN OUT NOCOPY CLOB,
                         p_indent     IN            VARCHAR2 DEFAULT CHR (9)
                        );
   /**
    * Parses a text recordset into a table of tables of strings. Records are delimited by the 
    * <code><big>record_separator</big></code> character. Fields are delmited by the 
    * <code><big>field_separator</big></code> character.
    * 
    * @param p_clob the delimeted recordset to parse
    * @return a table of tables of strings. Each record in the recordset becomes one
    *         outer row (table of fields) in the retured table, with fields within that 
    *         record becoming rows of the inner table.
    *         
    * @see record_separator
    * @see field_separator                                  
    */
   FUNCTION parse_clob_recordset (p_clob IN CLOB)
      RETURN str_tab_tab_t;
   /**
    * Parses a text recordset into a table of tables of strings. Records are delimited by the 
    * <code><big>record_separator</big></code> character. Fields are delmited by the 
    * <code><big>field_separator</big></code> character.
    * 
    * @param p_clob the delimeted recordset to parse
    * @return a table of tables of strings. Each record in the recordset becomes one
    *         outer row (table of fields) in the retured table, with fields within that 
    *         record becoming rows of the inner table.
    *         
    * @see record_separator
    * @see field_separator                                  
    */
   FUNCTION parse_string_recordset (p_string IN VARCHAR2)
      RETURN str_tab_tab_t;
   TYPE ts_list
   IS
      TABLE OF VARCHAR2 (200)
         INDEX BY BINARY_INTEGER;
   /**
    * Retrieves the dms minutes portion of an angle specified in decimal degrees.
    * 
    * @param p_decimal_degrees the input angle
    *     
    * @return the minutes portion of the angle. Will always be an integer            
    */       
   FUNCTION min_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER;
   /**
    * Retrieves the dms seconds portion of an angle specified in decimal degrees.
    * 
    * @param p_decimal_degrees the input angle        
    *     
    * @return the seconds portion of the angle. May have fractional portion            
    */       
   FUNCTION sec_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER;
   /**
    * Retrieves the dm minutes portion of an angle specified in decimal degrees.
    * 
    * @param p_decimal_degrees the input angle        
    *     
    * @return the minutes portion of the angle. May have fractional portion            
    */       
   FUNCTION min_dm (p_decimal_degrees IN NUMBER)
      RETURN NUMBER;
   /**
    * Retrieves a time zone equivalent to the specified time zone.  This is used
    * specifically to filter out PST and CST time zones, which are defined DST,
    * which is unexpected for these zones.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_timezone</th>
    *     <th class="descr">return value</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">'PST'</td>
    *     <td class="descr">'Etc/GMT+8'</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'CST'</td>
    *     <td class="descr">'Etc/GMT+6'</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">other</td>
    *     <td class="descr">p_timezone, corrected for case</td>
    *   </tr>
    * </table>
    * @param p_timezone the specified time zone
    *
    * @return An equivalent time zone. Except for PST and CST this is just a
    *         case-corrected version of p_timezone.
    */
   FUNCTION get_timezone (p_timezone IN VARCHAR2)
      RETURN VARCHAR2;
   /**
    * Converts a specified<code><big>DATE</big></code> from a specified time zone
    * to UTC
    * 
    * @param p_in_date the date to convert to UTC
    * @param p_in_tz the time zone
    * 
    * @return an equivalent <code><big>DATE</big></code> in UTC                         
    */       
   FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
      RETURN DATE;
   /**
    * Converts a specified<code><big>DATE</big></code> from one time zone to another
    *         
    * @param p_in_date the date to convert to UTC
    * @param p_from_tz the original time zone                
    * @param p_to_tz the desired time zone                
    * 
    * @return an equivalent <code><big>DATE</big></code> in the desired time zone                         
    */       
   FUNCTION change_timezone (
      p_in_date IN DATE, 
      p_from_tz IN VARCHAR2, 
      p_to_tz   IN VARCHAR2 default 'UTC')
      RETURN DATE result_cache;
   /**
    * Returns whether the upper case of the input is <code><big>'T'</big></code>
    * or <code><big>'TRUE'</big></code>
    *         
    * @param p_true_false 'Boolean' text input    
    */       
   FUNCTION is_true (p_true_false IN VARCHAR2)
      RETURN BOOLEAN result_cache;
   /**
    * Returns whether the upper case of the input is <code><big>'F'</big></code>
    * or <code><big>'FALSE'</big></code>    
    *         
    * @param p_true_false 'Boolean' text input
    * 
    * @return <code><big>TRUE</big></code> or <code><big>FALSE</big></code>            
    */       
   FUNCTION is_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN result_cache;
   /**
    * Returns a Boolean based on the input.
    * <ul>
    * <li><code><big>'T'    </big></code> - returns <code><big>TRUE</big></code></li>             
    * <li><code><big>'TRUE' </big></code> - returns <code><big>TRUE</big></code></li>             
    * <li><code><big>'F'    </big></code> - returns <code><big>FALSE</big></code></li>             
    * <li><code><big>'FALSE'</big></code> - returns <code><big>FALSE</big></code></li>
    * </ul>
    * 
    * @param p_true_false 'Boolean' text input    
    * @throws INVALID_T_F_FLAG if input is other than listed above.                         
    * 
    * @return <code><big>TRUE</big></code> or <code><big>FALSE</big></code>            
    */       
   FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN result_cache;
   /**
    * Returns <code><big>'T'</big></code> or <code><big>'F'</big></code> text based on the input.
    * <ul>
    * <li><code><big>'T'    </big></code> - returns <code><big>'T'</big></code></li>             
    * <li><code><big>'TRUE' </big></code> - returns <code><big>'T'</big></code></li>             
    * <li><code><big>'F'    </big></code> - returns <code><big>'F'</big></code></li>             
    * <li><code><big>'FALSE'</big></code> - returns <code><big>'F'</big></code></li>
    * </ul>
    * 
    * @param p_true_false 'Boolean' text input    
    * @throws INVALID_T_F_FLAG if input is other than listed above.                         
    * 
    * @return <code><big>'T'</big></code> or <code><big>'F'</big></code>            
    */       
   FUNCTION return_t_or_f_flag (p_true_false IN VARCHAR2)
      RETURN VARCHAR2 result_cache;
   /**
    * Retrieves the base portion of a base-sub identifier
    * 
    * @param p_full_id the identifier to parse for the base portion
    *     
    * @return the base portion of the identifier            
    */       
   FUNCTION get_base_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2 result_cache;
   /**
    * Retrieves the (possibly null) sub portion of a base-sub identifier
    * 
    * @param p_full_id the identifier to parse for the sub portion        
    *     
    * @return the (possibly null) sub portion of the identifier            
    */       
   FUNCTION get_sub_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2 result_cache;
   /**
    * Retrieves the base parameter code of a full parameter identifier
    * 
    * @param p_param_id the identifier for which to return the base parameter code
    * @param p_is_full_id flag specifying whether <code><big>p_param_id</big></code> is a full id or base id
    *     
    * @return the base parameter code            
    */       
   FUNCTION get_base_param_code (
      p_param_id   IN VARCHAR2, 
      p_is_full_id IN VARCHAR2 DEFAULT 'F')
      return number result_cache;
   /**
    * Retrieves the interval minutes of a time series
    * 
    * @param p_cwms_ts_code the code of the time series as presented in TS_CODE
    *        column of the CWMS_V_TS_ID view
    *        
    * @return the interval minutes of the time series                    
    */       
   FUNCTION get_ts_interval (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER result_cache;
   /**
    * Creates a full identifier from base and sub identifier portions
    * 
    * @param p_base_id the base portion of the identifier
    * @param p_sub_id the (possibly null) portion of the identifier
    * 
    * @return the full identifier. If the sub portion of the identifier is <code><big>NULL</big></code>
    *         the full identifier will be the same as the base portion.  Otherwise
    *         the full identifier will be the base portion followed by a hyphen character
    *         ('-') followed by the sub portion.                                
    */       
   FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
      RETURN VARCHAR2 result_cache;
   /**
    * Creates a fill time series identifier from the portions. The base parameter,
    * parameter type, interval, and duration portions are verified in the process.
    * 
    * @param p_base_location_id the base portion of the location portion
    * @param p_sub_location_id the sub portion of the location portion                
    * @param p_base_parameter_id the base portion of the parameter portion. This portion is verified
    * @param p_sub_parameter_id the sub portion of the parameter portion
    * @param p_parameter_type_id the parameter type portion. This portion is verified
    * @param p_interval_id the interval portion. This portion is verified
    * @param p_duration_id the duration portion. This portion is verified
    * @param p_version_id the version portion                                
    * 
    * @return the full time series identifier
    * 
    * @throws NO_DATA_FOUND if any of the verified portions are invalid
    * @throws ERROR if the parameter type portion is "Inst" and the duration portion
    *         is not "0"                        
    */       
   FUNCTION concat_ts_id (p_base_location_id    IN VARCHAR2,
                          p_sub_location_id     IN VARCHAR2,
                          p_base_parameter_id   IN VARCHAR2,
                          p_sub_parameter_id    IN VARCHAR2,
                          p_parameter_type_id   IN VARCHAR2,
                          p_interval_id         IN VARCHAR2,
                          p_duration_id         IN VARCHAR2,
                          p_version_id          IN VARCHAR2
                         )
      RETURN VARCHAR2;
   /**
    * Returns the primary office id of user calling the function
    */       
   FUNCTION user_office_id
      RETURN VARCHAR2;
   /**
    * Returns the primary office code of user calling the function
    */       
   FUNCTION user_office_code
      RETURN NUMBER;
   /**
    * Returns the office code of specified or default office identifier
    * 
    * @param p_office_id the office identifier for which to find the code. If
    *        <code><big>NULL</big></code> the calling user's office is used
    *        
    * @return the office code of the specified or default office identifier
    *
    * @throws INVALID_OFFICE_ID if the specified office identifier is invalid                             
    */       
   FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL )
      RETURN NUMBER result_cache;
   /**
    * Returns the specified or default office identifier
    * 
    * @param p_office_id the office identifier. If <code><big>NULL</big></code>
    *        the calling user's office identifier is returned. Otherwise this 
    *        parameter is returned                
    *
    * @throws INVALID_OFFICE_ID if the specified office identifier is invalid
    */       
   FUNCTION get_db_office_id (p_db_office_id IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2;
   /**
    * Retrieves the location identifier base on a location code.
    * 
    * @param p_location_code the location code for which to retrieve the location
    *        identifier
    * @param p_prepend_office specifies whether the location identifer will be
    *        prepended with the location's office identifier and '/'
    *        <ul>
    *        <li><code><big>'T'</big></code> - format = `&lt;office_id`&gt;/`&lt;location_id`&gt;</li>        
    *        <li><code><big>'F'</big></code> - format = `&lt;location_id`&gt;</li>
    *        </ul>            
    *        
    * @return the location identifier with or without the office identifier prepended.
    */       
   FUNCTION get_location_id (
      p_location_code  IN NUMBER,
      p_prepend_office IN VARCHAR2 DEFAULT 'F')
      RETURN VARCHAR2;
   /**
    * Retrieves a parameter identifier based on a parameter code
    * 
    * @param p_parameter_code the parameter code for which to find the identifier
    * 
    * @return the paramter identifier associated with the specified code                
    */       
   FUNCTION get_parameter_id (p_parameter_code IN NUMBER)
      RETURN VARCHAR2 result_cache;
   /**
    * Retrieves a time zone code based on a time zone name
    * 
    * @param p_time_zone_name the time zone name for which to find the code
    * 
    * @return the time zone code associated with the time zone name                
    */       
   FUNCTION get_time_zone_code (p_time_zone_name IN VARCHAR2)
      RETURN NUMBER;
   /**
    * Retrieves a proper time zone name based on a time zone name or alias
    *
    * @param p_time_zone_name the time zone name or alias for which to find the proper name
    *
    * @return the proper time zone name associated with the time zone name or alias
    */
   FUNCTION get_time_zone_name (p_time_zone_name IN VARCHAR2)
      RETURN VARCHAR2;
   --------------------------------------------------------------------------------
   -- function get_tz_usage_code
   --
   FUNCTION get_tz_usage_code (p_tz_usage_id IN VARCHAR2)
      RETURN NUMBER;
   /**
    * Retrieves the schema item name. If the input is an actual schema item name
    * it will be returned.  If the input is a public synonym, the associated
    * schema item name will be returned         
    * 
    * @param p_synonym a public synonym or schema item name
    * 
    * @return the schema item name                
    */       
   FUNCTION get_real_name (p_synonym IN VARCHAR2)
      RETURN VARCHAR2;
   /**
    * Returns the office code of specified or default office identifier
    * 
    * @param p_office_id the office identifier for which to find the code. If
    *        <code><big>NULL</big></code> the calling user's office is used
    *        
    * @return the office code of the specified or default office identifier
    *
    * @throws INVALID_OFFICE_ID if the specified office identifier is invalid                             
    */       
   FUNCTION get_db_office_code (p_office_id IN VARCHAR2 DEFAULT NULL )
      RETURN NUMBER;
   /**
    * Replace glob wildcard chars (?,*) with SQL ones (_,%), using '\\' as an
    * escape character.
    * 
    * @param p_string the glob wildcarded string to convert a SQL LIKE string. If
    *        <code><big>NULL</big></code> the furnction returns '%'    
    * @param p_recognize_sql specifies whether SQL wildcars in the input will be
    *        recognized as wildcards                
    * <ul>
    * <li><code><big>TRUE </big></code> - SQL wildcards are retained as wildcards in the returned string</li>             
    * <li><code><big>FALSE</big></code> - SQL wildcards become literal characters in the returned string</li>
    * </ul>
    * <code>
    * <table border="1" cellspacing="0" cellpadding="5">
    *   <tr><td rowspan="3" align="center">Input String</td><td colspan="5" align="center">Output String</td></tr>
    *   <tr><td colspan="4" align="center">Recognize SQL Wildcards?</td><td rowspan="2">Different?</td></tr>
    *   <tr><td>No     </td><td>Comments </td><td>Yes</td><td>Comments</td></tr>            
    *   <tr><td>%      </td><td>\\%    </td><td>literal '%'                </td><td>%      </td><td>multi-wildcard    </td><td>Yes</td></tr>
    *   <tr><td>_      </td><td>\\_    </td><td>literal '_'                </td><td>_      </td><td>single-wildcard   </td><td>Yes</td></tr>
    *   <tr><td>*      </td><td>%      </td><td>multi-wildcard             </td><td>%      </td><td>multi-wildcard    </td><td>No </td></tr>
    *   <tr><td>?      </td><td>_      </td><td>single-wildcard            </td><td>_      </td><td>single-wildcard   </td><td>No </td></tr>
    *   <tr><td>\\%    </td><td>       </td><td>not allowed                </td><td>\\%    </td><td>literal '%'       </td><td>Yes</td></tr>
    *   <tr><td>\\_    </td><td>       </td><td>not allowed                </td><td>\\_    </td><td>literal '_'       </td><td>Yes</td></tr>
    *   <tr><td>\\*    </td><td>*      </td><td>literal '*'                </td><td>*      </td><td>literal '*'       </td><td>No </td></tr>
    *   <tr><td>\\?    </td><td>?      </td><td>literal '?'                </td><td>?      </td><td>literal '?'       </td><td>No </td></tr>
    *   <tr><td>\\\\\\%</td><td>\\\\\\%</td><td>literal '\\' + literal '%' </td><td>\\\\\\%</td><td>literal '\\' + mwc</td><td>Yes</td></tr>
    *   <tr><td>\\\\\\_</td><td>\\\\\\_</td><td>literal '\\' + literal '\\'</td><td>\\\\\\_</td><td>literal '\\' + swc</td><td>Yes</td></tr>
    *   <tr><td>\\\\\\*</td><td>\\\\\\%</td><td>literal '\\' + mwc         </td><td>\\\\\\%</td><td>literal '\\' + mwc</td><td>No </td></tr>
    *   <tr><td>\\\\\\?</td><td>\\\\\\_</td><td>literal '\\' + swc         </td><td>\\\\\\_</td><td>literal '\\' + swc</td><td>No </td></tr>
    * </table>        
    * </code>
    *           
    * @return a SQL LIKE string       
    * 
    * @throws ERROR if the input string ends in an odd number of '\\' characters
    * @throws ERROR if the input string contains '\\%' or '\\_' and <code><big>p_recognize_sql</big></code>
    *               is <code><big>FALSE</big></code>                       
    */       
   FUNCTION normalize_wildcards (p_string          IN VARCHAR2,
                                 p_recognize_sql      BOOLEAN DEFAULT FALSE
                                )
      RETURN VARCHAR2;
   /**
    * Replace SQL wildcard chars (_,%) with glob ones (?,*), using '\\' as an
    * escape character.
    * 
    * @param p_string the SQL wildcarded string to convert a glob pattern string. If
    *        <code><big>NULL</big></code> the furnction returns '*'    
    *           
    * @return a glob pattern string
    * 
    * @throws ERROR if the input string ends in an odd number of '\\' characters               
    */       
   FUNCTION denormalize_wildcards (p_string IN VARCHAR2)
      RETURN VARCHAR2;
   /**
    * Parses a time series identifier into its various parts.
    * 
    * @param p_base_location_id the base portion of the location portion
    * @param p_sub_location_id the sub portion of the location portion                
    * @param p_base_parameter_id the base portion of the parameter portion
    * @param p_sub_parameter_id the sub portion of the parameter portion
    * @param p_parameter_type_id the parameter type portion
    * @param p_interval_id the interval portion
    * @param p_duration_id the duration portion
    * @param p_version_id the version portion
    * @param p_cwms_ts_id the full time series identifier                                    
    */       
   PROCEDURE parse_ts_id (p_base_location_id       OUT VARCHAR2,
                          p_sub_location_id        OUT VARCHAR2,
                          p_base_parameter_id      OUT VARCHAR2,
                          p_sub_parameter_id       OUT VARCHAR2,
                          p_parameter_type_id      OUT VARCHAR2,
                          p_interval_id            OUT VARCHAR2,
                          p_duration_id            OUT VARCHAR2,
                          p_version_id             OUT VARCHAR2,
                          p_cwms_ts_id          IN     VARCHAR2
                         );
   /**
    * Generates a multipart predicate of LIKE clauses for a single column.  The
    * input is a shorthand notation of the predicate, the name of the column, and
    * whether to use uppercase matches.
    * <p>
    * <b>Patterns</b>    
    * This routine uses glob wildcard characters and not SQL wildcard characters
    * <ul>
    *   <li><code><big><b>*</b></big></code> - matches zero or more occurences of any character</li>                
    *   <li><code><big><b>?</b></big></code> - matches zero or one occurence of any character</li>
    * </ul>
    * To indicate a literal '*' or '?' in the pattern, precede it immediately with
    * the backslash character ('\\') to escape it (e.g., \\*  \\?)        
    * <p>
    * The shorthand input is comprised of one or more glob patterns separated by 
    * logical operators (AND, OR, NOT) and  If one of the patterns includes blank spaces, 
    * that pattern must be enclosed in double quotes (e.g. "*some pattern?"). To indicate
    * a literal '"' in the pattern, escape it as mentioned above (e.g., 'some\\"pattern')    
    * <p>                                        
    * <b>Logical Operators</b>
    * Logical operators may be specified as follows:
    * <ul>
    *   <li><code><big><b>AND</b></big></code>
    *     <ul>
    *       <li>may be specified explicitly by the word <code><big>'AND'</big></code></li>    
    *       <li>may be specified implicitly by the absence of the word <code><big>'OR'</big></code></li>    
    *     </ul>        
    *   </li>     
    *   <li><code><big><b>OR</b></big></code>
    *     <ul>
    *       <li>must be specified explicitly by the word <code><big>'OR'</big></code></li>    
    *     </ul>        
    *   </li>     
    *   <li><code><big><b>NOT</b></big></code>
    *     <ul>
    *       <li>may be specified explicitly by the word <code><big>'NOT'</big></code></li>    
    *       <li>may be specified explicitly by prepending the minus character ('-') to a pattern</li>    
    *     </ul>        
    *   </li>     
    * </ul>         
    * <p>                                        
    * <b>Examples</b>
    * <p>    
    * <code><table border="1" cellspacing="0" cellpadding="5">
    *   <tr><td colspan="2" align="center">p_search_column='COL', p_use_upper=TRUE</td></tr>     
    *   <tr><td>*abc* AND *123*</td><td>UPPER(COL) LIKE %ABC% AND UPPER(COL) LIKE %123%</td></tr>     
    *   <tr><td>*abc* AND NOT *123*</td><td>UPPER(COL) LIKE %ABC% AND UPPER(COL) NOT LIKE %123%</td></tr>     
    *   <tr><td>*abc* *123*</td><td>UPPER(COL) LIKE %ABC% AND UPPER(COL) LIKE %123%</td></tr>     
    *   <tr><td>*abc* -*123*</td><td>UPPER(COL) LIKE %ABC% AND UPPER(COL) NOT LIKE %123%</td></tr>     
    *   <tr><td>*abc* OR *123\\*</td><td>UPPER(COL) LIKE %ABC% OR UPPER(COL) LIKE %123*</td></tr>     
    *   <tr><td>*abc* OR -*123\\*</td><td>UPPER(COL) LIKE %ABC% OR UPPER(COL) NOT LIKE %123*</td></tr>     
    *   <tr><td>*abc* OR NOT *123\\*</td><td>UPPER(COL) LIKE %ABC% OR UPPER(COL) NOT LIKE %123*</td></tr>     
    * </table></code>
    * <p>            
    * <code><table border="1" cellspacing="0" cellpadding="5">
    *   <tr><td colspan="2" align="center">p_search_column='COL', p_use_upper=FALSE</td></tr>     
    *   <tr><td>*abc* AND *123*</td><td>COL LIKE %abc% AND COL LIKE %123%</td></tr>     
    *   <tr><td>*abc* AND NOT *123*</td><td>COL LIKE %abc% AND COL NOT LIKE %123%</td></tr>     
    *   <tr><td>*abc* *123*</td><td>COL LIKE %abc% AND COL LIKE %123%</td></tr>     
    *   <tr><td>*abc* -*123*</td><td>COL LIKE %abc% AND COL NOT LIKE %123%</td></tr>     
    *   <tr><td>*abc* OR *123\\*</td><td>COL LIKE %abc% OR COL LIKE %123*</td></tr>     
    *   <tr><td>*abc* OR -*123\\*</td><td>COL LIKE %abc% OR COL NOT LIKE %123*</td></tr>     
    *   <tr><td>*abc* OR NOT *123\\*</td><td>COL LIKE %abc% OR COL NOT LIKE %123*</td></tr>     
    * </table></code>        
    *          
    * @param p_search_patterns the shorthand notation as described above.  If <code><big>NULL</big></code>
    *        the generated predicate is COLUMN_NAME LIKE %
    * @param p_search_column the column name to use in the generated predicate
    * @param p_use_upper specifies whether the matching should be performed on
    *        uppercase versions of the input and column (specifies case insensitve
    *        matching)                                
    *
    * @return the generated predicate         
    */       
   FUNCTION parse_search_string (p_search_patterns   IN VARCHAR2,
                                 p_search_column     IN VARCHAR2,
                                 p_use_upper         IN BOOLEAN DEFAULT TRUE
                                )
      RETURN VARCHAR2;
   /**
    * Strips all leading and trailing whitespace from a string.
    * 
    * @param p_text the string to strip
    * 
    * @return the input string with all leading and trailing whitespace removed                
    */          
   FUNCTION strip (p_text IN VARCHAR2)
      RETURN VARCHAR2;
   /**
    * Parses an ISO 8601 formatted time string into a <code><big>TIMESTAMP</big></code>
    * 
    * @param p_iso_str the time formatted according to ISO 8601 format. This is
    *        also essentially the W3C dateTime format used in XML
    *        
    * @return the <code><big>TIMESTAMP</big></code> equivalent of the input string                     
    */             
   FUNCTION TO_TIMESTAMP (p_iso_str IN VARCHAR2)
      RETURN timestamp;
   /**
    * Genrates the <code><big>TIMESTAMP</big></code> equivalent of a Java millisecond
    * value.  The Java millisecond value specifies the number of milliseconds since
    * the beginning of the UNIX epoch (01 Jan 1970 00:00:00 UTC)        
    * 
    * @param p_millis the Java millisecond value
    *        
    * @return the <code><big>TIMESTAMP</big></code> equivalent of the input value
    */             
   FUNCTION TO_TIMESTAMP (p_millis IN NUMBER)
      RETURN timestamp;
   /**
    * Genrates the Java millisecond equivalent of a <code><big>TIMESTAMP</big></code> 
    * value.  The Java millisecond value specifies the number of milliseconds since
    * the beginning of the UNIX epoch (01 Jan 1970 00:00:00 UTC)        
    * 
    * @param p_timestamp the <code><big>TIMESTAMP</big></code> value to convert
    *        
    * @return the Java millsecond value equivalent of the input
    */             
   FUNCTION to_millis (p_timestamp IN timestamp)
      RETURN NUMBER;
   /**
    * Genrates the Java millisecond value for the current time. The Java millisecond 
    * value specifies the number of milliseconds since the beginning of the UNIX epoch
    * (01 Jan 1970 00:00:00 UTC)        
    * 
    * @return the Java millsecond value representing the current time
    */             
   FUNCTION current_millis
      RETURN NUMBER;
   /**
    * Outputs a test string verifying that the call succeeded. Uses <code><big>dbms_output.put_line</big></code>
    * to output the test string
    */             
   PROCEDURE test;
   /**
    * Output a string with a maximum line length. Uses <code><big>dbms_output.put_line</big></code>
    * to output the lines
    * 
    * @param p_str the string to output
    * @param p_len the maximum line length. If <code><big>p_str</big></code> is 
    *        longer than this it will be broken into multiple lines                     
    */       
   PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80 );
   /**
    * Creates the partitioned timeseries table view
    */       
   PROCEDURE create_view;
   /**
    * Retrieves the office identifier and office long name for the current user
    * 
    * @param p_office_id the office identifier of the current user
    * @param p_office_long_name the office long name of the current user             
    */       
   PROCEDURE get_user_office_data (p_office_id          OUT VARCHAR2,
                                   p_office_long_name   OUT VARCHAR2);
   /**
    * Retrieves the actual unit identifier for a specified unit alias (or actual
    * unit) and office.
    * 
    * @param p_unit_or_alias an actual unit identifier or a unit alias for the 
    *        specified office.  If it is an actual unit identifier then this
    *        identifier is also returned.    
    * @param p_office_id the office for which to resolve the alias to an actual
    *        unit id.  If <code><big>NULL</big></code> the current user's office
    *        is used.
    *        
    * @return the actual unit identifier corresponding to the input                                            
    */       
   function get_unit_id(
      p_unit_or_alias in varchar2,
      p_office_id     in varchar2 default null)
      return varchar2 result_cache;
      
   /**
    * Retrieves the unit identifier for a specified unit code
    * 
    * @param p_unit_code the unit code to retrieve the identifier for    
    *        
    * @return the unit identifier corresponding to the input                                            
    */       
   function get_unit_id2(
      p_unit_code in varchar2)
      return varchar2 result_cache;
      
   /**
    * Retrieves a cursor of all valid units in the database for an optionally
    * specified parameter.  The cursor has a single column named 'UNIT_ID'.
    * 
    * @param p_valid_units the cursor of valid units
    * @param p_parameter_id the parameter for which to return the set of valid
    *        units.  If <code><big>NULL</big></code> the cursor will contain all
    *        valid units in the database for any parameter.                     
    */       
   PROCEDURE get_valid_units (p_valid_units       OUT sys_refcursor,
                              p_parameter_id   IN     VARCHAR2 DEFAULT NULL
                             );

   PROCEDURE start_mv_cwms_ts_id_job;

   PROCEDURE stop_mv_cwms_ts_id_job;

   PROCEDURE refresh_mv_cwms_ts_id;
   /**
    * Retrieves a case-corrected unit identifier
    * 
    * @param p_unit_id the unit identifier to case correct
    * @param p_parameter_id the parameter for the unit.  If <code><big>NULL</big></code>
    *        then units for all parameters are considered.
    *            
    * @return the case corrected unit                             
    */       
    FUNCTION get_valid_unit_id (p_unit_id            IN VARCHAR2,
                                     p_parameter_id    IN VARCHAR2 DEFAULT NULL
                                    )
    RETURN VARCHAR2;
   /**
    * Retrieves a table of all valid units in the database for an optionally
    * specified parameter
    * 
    * @param p_parameter_id the parameter for which to return the set of valid
    *        units.  If <code><big>NULL</big></code> the cursor will contain all
    *        valid units in the database for any parameter.
    * @return a table of valid units. The table has a single column named 'UNIT_ID'                                 
    */       
   FUNCTION get_valid_units_tab (p_parameter_id IN VARCHAR2 DEFAULT NULL )
      RETURN cat_unit_tab_t
      PIPELINED;
   /**
    * Retrieves a unit code from a actual unit identifier or unit alias
    * 
    * @param p_unit_id the actual unit identifier or alias to retrieve the code for
    * @param p_abstract_param_id an abstract parameter identifier to use to narrow
    *        the search.  If <code><big>NULL</big></code> all units for all abstract
    *        parameters are searched.  CWMS abstract parameters are:
    *        <ul>
    *          <li>Angle                           </li>
    *          <li>Angular Speed                   </li>
    *          <li>Area                            </li>
    *          <li>Areal Volume Rate               </li>
    *          <li>Conductance                     </li>
    *          <li>Conductivity                    </li>
    *          <li>Count                           </li>
    *          <li>Currency                        </li>
    *          <li>Elapsed Time                    </li>
    *          <li>Electromotive Potential         </li>
    *          <li>Energy                          </li>
    *          <li>Force                           </li>
    *          <li>Hydrogen Ion Concentration Index</li>
    *          <li>Irradiance                      </li>
    *          <li>Irradiation                     </li>
    *          <li>Length                          </li>
    *          <li>Linear Speed                    </li>
    *          <li>Mass Concentration              </li>
    *          <li>None                            </li>
    *          <li>Phase Change Rate Index         </li>
    *          <li>Power                           </li>
    *          <li>Pressure                        </li>
    *          <li>Temperature                     </li>
    *          <li>Turbidity                       </li>
    *          <li>Volume                          </li>
    *          <li>Volume Rate                     </li>
    *        </ul>
    * @param p_db_office_id the office to use for searching for unit aliases.  If
    *        <code><big>NULL</big></code> the current user's office is used.
    *        
    * @return the unit code corresponding to the inputs
    * 
    * @throws INVALID_ITEM if no unit code can be found
    * @throws ERROR if the inputs match more than one unit code                                        
    */       
   FUNCTION get_unit_code (p_unit_id             IN VARCHAR2,
                           p_abstract_param_id   IN VARCHAR2 DEFAULT NULL ,
                           p_db_office_id        IN VARCHAR2 DEFAULT NULL
                          )
      RETURN NUMBER;
        /**
    * Retrieves the timeseries group code for a specified timeseries group
    *
    * @param p_ts_category_id the timeseries category identifier that the timeseries
    *        group belongs to
    * @param p_ts_group_id the timeseries group identifier
    * @param p_db_office_code the office to locate the group code for
    *
    * @return the timeseries group code for the inputs
    *
    * @throws ERROR if no timeseries group matches the inputs
    */
   FUNCTION get_ts_group_code (p_ts_category_id   IN VARCHAR2,
                                p_ts_group_id      IN VARCHAR2,
                                p_db_office_code    IN NUMBER
                               )
      RETURN NUMBER;
   /**
    * Retrieves the location group code for a specified location group
    * 
    * @param p_loc_category_id the location category identifier that the location
    *        group belongs to
    * @param p_loc_group_id the location group identifier
    * @param p_db_office_code the office to locate the group code for
    * 
    * @return the location group code for the inputs
    * 
    * @throws ERROR if no location group matches the inputs                                            
    */       
   FUNCTION get_loc_group_code (p_loc_category_id   IN VARCHAR2,
                                p_loc_group_id      IN VARCHAR2,
                                p_db_office_code    IN NUMBER
                               )
      RETURN NUMBER;
   /**
    * Retrieves the location group code for a specified location group
    * 
    * @param p_loc_category_id the location category identifier that the location
    *        group belongs to
    * @param p_loc_group_id the location group identifier
    * @param p_db_office_id the office to locate the group code for
    * 
    * @return the location group code for the inputs
    * 
    * @throws ERROR if no location group matches the inputs                                            
    */       
   FUNCTION get_loc_group_code (p_loc_category_id   IN VARCHAR2,
                                p_loc_group_id      IN VARCHAR2,
                                p_db_office_id      IN VARCHAR2
                               )
      RETURN NUMBER;
   /**
    * Returns the name of the current user
    * 
    * @return the name of the current user        
    */       
   FUNCTION get_user_id
      RETURN VARCHAR2;
   /**
    * Retrieve a unit in the preferred unit system and optionally convert a value
    * to that unit. The preferred unit system is determed by the first non-null
    * value encountered in the following list:    
    * <ol>
    * <li>database property:
    *     <dl>
    *     <dt><b>office id:</b></dt>
    *     <dd><code><big>'`&lt;<em>p_office_id</em>`&gt;'</big></code></dd>   
    *     <dt><b>category :</b></dt>
    *     <dd><code><big>'Pref_User.`&lt;<em>p_user_id</em>`&gt;'</big></code></dd>   
    *     <dt><b>identifier :</b></dt>
    *     <dd><code><big>'Unit_System'</big></code></dd>
    *     </dl>    
    * <li>database property:
    *     <dl>
    *     <dt><b>office id:</b></dt>
    *     <dd><code><big>'`&lt;<em>p_office_id</em>`&gt;'</big></code></dd>   
    *     <dt><b>category :</b></dt>
    *     <dd><code><big>'Pref_Office'</big></code></dd>   
    *     <dt><b>identifier :</b></dt>
    *     <dd><code><big>'Unit_System'</big></code></dd>
    *     </dl>                 
    * <li><code><big>'SI'</big></code>
    * </ol>
    * 
    * @param p_unit_id the unit in the preferred unit system
    * @param p_value_out the value converted from database storage units to the
    *        output unit
    * @param p_parameter_id the parameter identifier for which to find the unit
    * @param p_value_in a value to convert from database storage units to the 
    *        output uni
    * @param p_user_id the user for whom to determine the preferred unit system.
    *        If <code><big>NULL</big></code> the current user is used
    * @param p_office_id the office for which to determine the preferred unit system.
    *        If <code><big>NULL</big></code> the user's primary office is used                                                                            
    */        
   procedure user_display_unit(
      p_unit_id      out varchar2,
      p_value_out    out number,
      p_parameter_id in  varchar2,
      p_value_in     in  number   default null,
      p_user_id      in  varchar2 default null,
      p_office_id    in  varchar2 default null);
      
   FUNCTION get_interval_string (p_interval IN NUMBER)
      RETURN VARCHAR2;
   /**
    * Returns the default units of a parameter in the specified unit system
    * 
    * @param p_parameter_id the parameter to get the default unit for
    * @param p_unit_system the unit system to get the default unit for. If <code><big>NULL</big></code>
    *        then the SI unit system is assumed.
    *        
    * @return the default unit of the specified parameter and unit system                        
    */             
   FUNCTION get_default_units (p_parameter_id   IN VARCHAR2,
                               p_unit_system    IN VARCHAR2 DEFAULT 'SI'
                              )
      RETURN VARCHAR2;
   /**
    * Returns the database storage unit code of the specified parameter
    * 
    * @param p_paramter_id the parameter to get the database storage unit code for
    * 
    * @return the database storage unit code for the specified parameter                
    */       
   function get_db_unit_code(
      p_parameter_id in varchar2)
      return number;
   /**
    * Returns the database storage unit code of the specified parameter
    * 
    * @param p_parameter_code the parameter to get the database storage unit code for
    * 
    * @return the database storage unit code for the specified parameter                
    */       
   function get_db_unit_code(
      p_parameter_code in number)
      return number;
   /**
    * Converts a value to database storage unit
    * 
    * @param p_value the value to conver
    * @param p_parameter_id the parameter identifier of the value
    * @param p_unit_id the incoming unit of the value
    * 
    * @return the incoming value converted to the database storage unit                        
    */                   
   function convert_to_db_units(
      p_value        in binary_double,
      p_parameter_id in varchar2,
      p_unit_id      in varchar2)
   return binary_double;
   /**
    * Converts a value from one unit to another
    * 
    * @param p_value the value to convert
    * @param p_from_unit_id the unit to convert from
    * @param p_to_unit_id the unit to convert to                
    */             
   function convert_units(
      p_value        in binary_double,
      p_from_unit_id in varchar2,
      p_to_unit_id   in varchar2)
   return binary_double result_cache;   
   /**
    * Converts a value from one unit to another
    * 
    * @param p_value the value to convert
    * @param p_from_unit_code the unit to convert from
    * @param p_to_unit_code the unit to convert to                
    */             
   function convert_units(
      p_value          in binary_double,
      p_from_unit_code in number,
      p_to_unit_code   in number)
   return binary_double result_cache;   
   /**
    * Converts a value from one unit to another
    * 
    * @param p_value the value to convert
    * @param p_from_unit_code the unit to convert from
    * @param p_to_unit_id the unit to convert to                
    */             
   function convert_units(
      p_value          in binary_double,
      p_from_unit_code in number,
      p_to_unit_id     in varchar2)
   return binary_double result_cache;   
   /**
    * Converts a value from one unit to another
    * 
    * @param p_value the value to convert
    * @param p_from_unit_id the unit to convert from
    * @param p_to_unit_code the unit to convert to                
    */             
   function convert_units(
      p_value        in binary_double,
      p_from_unit_id in varchar2,
      p_to_unit_code in number)
   return binary_double result_cache;
   /**
    * Sign-extends 32-bit integers. Enables Java clients to use int values for 32-bit 
    * data quality values and retain the sign of the 32-bit value
    * 
    * @param p_int the integer value to sign-extend
    * 
    * @return the sign-extended integer                     
    */          
   FUNCTION sign_extend (p_int IN INTEGER)
      RETURN INTEGER;
   /**
    * Converts an integer number of months to an equivalent <code><big>INTERVAL YEAR TO MONTH</big></code>
    * 
    * @param p_months the interval to convert
    * 
    * @return an equivalent <code><big>INTERVAL YEAR TO MONTH</big></code>                
    */       
   function months_to_yminterval(
      p_months in integer) 
      return interval year to month;
   /**
    * Converts an integer number of minutes to an equivalent <code><big>INTERVAL DAY TO SECOND</big></code>
    * 
    * @param p_minutes the interval to convert
    * 
    * @return an equivalent <code><big>INTERVAL DAY TO SECOND</big></code>                
    */       
   function minutes_to_dsinterval(
      p_minutes in integer) 
      return interval day to second;
   /**
    * Converts an <code><big>INTERVAL YEAR TO MONTH</big></code> to an equivalent number of months 
    * 
    * @param p_intvl the interval to convert
    * 
    * @return an equivalent number of months                
    */       
   function yminterval_to_months(
      p_intvl in interval year to month) 
      return integer;
   /**
    * Converts an <code><big>INTERVAL DAY TO SECOND</big></code> to an equivalent number of minutes 
    * 
    * @param p_intvl the interval to convert
    * 
    * @return an equivalent number of minutes                
    */       
   function dsinterval_to_minutes(
      p_intvl in interval day to second) 
      return integer;
   /**
    * Converts an ODBC timestamp string to an equivalent <code><big>DATE</big></code>
    * 
    * @param p_odbc_str the ODBC string to convert
    * 
    * @return a <code><big>DATE</big></code> equivalent to the input                 
    */             
   function parse_odbc_ts_string(
      p_odbc_str in varchar2)
      return date;
   /**
    * Converts an ODBC date string to an equivalent <code><big>DATE</big></code>
    * 
    * @param p_odbc_str the ODBC string to convert
    * 
    * @return a <code><big>DATE</big></code> equivalent to the input                 
    */             
   function parse_odbc_d_string(
      p_odbc_str in varchar2)
      return date;
   /**
    * Converts an ODBC timestamp or date string to an equivalent <code><big>DATE</big></code>
    * 
    * @param p_odbc_str the ODBC string to convert
    * 
    * @return a <code><big>DATE</big></code> equivalent to the input                 
    */             
   function parse_odbc_ts_or_d_string(
      p_odbc_str in varchar2)
      return date;
   /**
    * Determines whether a specified token is a constant that can be used in 
    * expression evaluation
    * 
    * @param p_token the token to analyze
    * 
    * @return whether the specified token is in the list of valid expression
    *         evaluation constants
    *         
    * @see expression_constants                                
    */       
   function is_expression_constant(p_token in varchar2) return boolean;   
   /**
    * Determines whether a specified token is a operator that can be used in 
    * expression evaluation
    * 
    * @param p_token the token to analyze
    * 
    * @return whether the specified token is in the list of valid expression
    *         evaluation operators                        
    *         
    * @see expression_operators                                
    */       
   function is_expression_operator(p_token in varchar2) return boolean;   
   /**
    * Determines whether a specified token is a function that can be used in 
    * expression evaluation
    * 
    * @param p_token the token to analyze
    * 
    * @return whether the specified token is in the list of valid expression
    *         evaluation functions                        
    *         
    * @see expression_functions                                
    */       
   function is_expression_function(p_token in varchar2) return boolean;
   /**
    * Generates a table of RPN tokens from an algebraic expression.
    * 
    * @param p_algebraic_expr a mathematical expression in infix (algebraic) notation.
    *        Standard algebraic operator precedence (order of operations) applies
    *        and can be overridden by parentheses.  All tokens in the expression 
    *        (numbers, variables, operators, constants, functions) must be separated
    *        from adjacent tokens by whitespace. No whitespace is required before
    *        or after parentheses. Variables are specified as arg1, arg2, ... argN.
    *        Negated variables (e.g., -argN) are accepted.                        
    * 
    * @return a table of tokens in postfix (reverse Polish) notation (RPN)                
    */             
   function tokenize_algebraic(
      p_algebraic_expr in varchar2)
      return str_tab_t result_cache;
   /**
    * Generates a table of RPN tokens from an RPN expression.
    * 
    * @param p_RPN_expr a mathematical expression in postfix (reverse Polish) notation (RPN).
    *        All tokens in the expression (numbers, variables, operators, constants, 
    *        functions) must be separated from adjacent tokens by whitespace. Parentheses
    *        are not used in RPN notation. Variables are specified as arg1, arg2, ... argN.
    *        Negated variables (e.g., -argN) are accepted.                        
    * 
    * @return a table of tokens in postfix (reverse Polish) notation (RPN)                
    */             
   function tokenize_RPN(
      p_RPN_expr  in varchar2)
      return str_tab_t result_cache;
   /**
    * Generates a table of RPN tokens from an algebraic expression.
    * 
    * @param p_expr a mathematical expression in infix (algebraic) notation or
    *        in postfix (reverse Polish) notation (RPN). Standard algebraic operator
    *        precedence (order of operations) applies for infix notation and can be
    *        overridden by parentheses.  All tokens in the expression (numbers, 
    *        variables, operators, constants, functions) must be separated from
    *        adjacent tokens by whitespace. No whitespace is required before or
    *        after parentheses. Parentheses are not used in RPN notation. Variables 
    *        are specified as arg1, arg2, ... argN. Negated variables (e.g., -argN)
    *        are accepted.                    
    * 
    * @return a table of tokens in postfix (reverse Polish) notation (RPN)                
    */             
   function tokenize_expression(      
      p_expr in varchar2)
      return str_tab_t result_cache;
   /**
    * Computes a value from tokens in postfix (reverse Polish) notation (RPN) and
    * specified values for variables
    * 
    * @param p_RPN_tokens the tokens representing the mathematical expression to
    *        evaluate. Variables are named arg1, arg2, ... argN.  Negated variables
    *        of the form -argN are accepted.    
    * @param p_args the actual values to use for arg1...argN. Values are assigned 
    *        positionally beginning with the specified or default offset
    * @param p_args_offset the offset into <code><big>p_args</big></code> from which
    *        to start assigning values.  If 0 (default) then the arg1 will be assigned
    *        the first value, etc...        
    *                                                   
    * @return the result of the compuatation      
    */             
   function eval_tokenized_expression(
      p_RPN_tokens in str_tab_t,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return number;      
   /**
    * Evaluates an arithmetic expression in infix (algebraic) notation and computes
    * a value based on specified variables.
    *
    * @see expression_constants
    * @see expression_operators
    * @see expression_function
    * 
    * @param p_algebraic_expr a mathematical expression in infix (algebraic) notation.
    *        Standard algebraic operator precedence (order of operations) applies
    *        and can be overridden by parentheses.  All tokens in the expression 
    *        (numbers, variables, operators, constants, functions) must be separated
    *        from adjacent tokens by whitespace. No whitespace is required before
    *        or after parentheses. Variables are specified as arg1, arg2, ... argN.
    *        Negated variables (e.g., -argN) are accepted.                        
    * @param p_args the actual values to use for arg1...argN. Values are assigned 
    *        positionally beginning with the specified or default offset
    * @param p_args_offset the offset into <code><big>p_args</big></code> from which
    *        to start assigning values.  If 0 (default) then the arg1 will be assigned
    *        the first value, etc...        
    *                                                   
    * @return the result of the compuatation      
    */             
   function eval_algebraic_expression(
      p_algebraic_expr in varchar2,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return number;      
   /**
    * Evaluates an arithmetic expression in postfix (reverse Polish) notation (RPN)
    * and computes a value based on specified variables.    
    *
    * @see expression_constants
    * @see expression_operators
    * @see expression_function
    *
    * @param p_RPN_expr a mathematical expression in postfix (reverse Polish) notation (RPN).
    *        All tokens in the expression (numbers, variables, operators, constants, 
    *        functions) must be separated from adjacent tokens by whitespace. Parentheses
    *        are not used in RPN notation. Variables are specified as arg1, arg2, ... argN.
    *        Negated variables (e.g., -argN) are accepted.                        
    * @param p_args the actual values to use for arg1...argN. Values are assigned 
    *        positionally beginning with the specified or default offset
    * @param p_args_offset the offset into <code><big>p_args</big></code> from which
    *        to start assigning values.  If 0 (default) then the arg1 will be assigned
    *        the first value, etc...        
    *                                                   
    * @return the result of the compuatation      
    */             
   function eval_RPN_expression(
      p_RPN_expr    in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return number;      
   /**
    * Evaluates an arithmetic expression in infix (algebraic) notation or in postfix 
    * (reverse Polish) notation (RPN) and computes a value based on specified variables.    
    *
    * @see expression_constants
    * @see expression_operators
    * @see expression_functions
    *
    * @param p_expr a mathematical expression in infix (algebraic) notation or
    *        in postfix (reverse Polish) notation (RPN). Standard algebraic operator
    *        precedence (order of operations) applies for infix notation and can be
    *        overridden by parentheses.  All tokens in the expression (numbers, 
    *        variables, operators, constants, functions) must be separated from
    *        adjacent tokens by whitespace. No whitespace is required before or
    *        after parentheses. Parentheses are not used in RPN notation. Variables 
    *        are specified as arg1, arg2, ... argN. Negated variables (e.g., -argN)
    *        are accepted.                    
    * @param p_args the actual values to use for arg1...argN. Values are assigned 
    *        positionally beginning with the specified or default offset
    * @param p_args_offset the offset into <code><big>p_args</big></code> from which
    *        to start assigning values.  If 0 (default) then the arg1 will be assigned
    *        the first value, etc...        
    *                                                   
    * @return the result of the compuatation      
    */             
   function eval_expression(
      p_expr        in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return number;
   /**
    * Checks mulitple input strings for common SQL injection exploits
    * 
    * @param p_input the strings to check
    * 
    * @throws ERROR if a common SQL injection exploit is detected                
    */                
   procedure check_inputs(
      p_input in str_tab_t
   );
   /**
    * Checks a single input string for common SQL injection exploits
    * 
    * @param p_input the strings to check
    * 
    * @throws ERROR if a common SQL injection exploit is detected                
    */                
   procedure check_input(
      p_input in varchar2
   );
   /**
    * Checks a single input string for common SQL injection exploits
    * 
    * @param p_input the strings to check
    * 
    * @return the input string        
    * 
    * @throws ERROR if a common SQL injection exploit is detected                
    */                
   function check_input_f(
      p_input in varchar2
   ) return varchar2;
   /**
    * Appends text to a <code><big>CLOB</big></code>
    * 
    * @param p_dst the <code><big>CLOB</big></code> to append to
    * @param p_src the text to append             
    */       
   procedure append(
      p_dst in out nocopy clob,
      p_src in            clob);
   /**
    * Appends text to a <code><big>CLOB</big></code>
    * 
    * @param p_dst the <code><big>CLOB</big></code> to append to
    * @param p_src the text to append             
    */       
   procedure append(
      p_dst in out nocopy clob,
      p_src in            varchar2);
   /**
    * Appends text to a <code><big>CLOB</big></code>
    * 
    * @param p_dst the <code><big>CLOB</big></code> to append to
    * @param p_src the text to append             
    */       
   procedure append(
      p_dst in out nocopy clob,
      p_src in            xmltype);
   /**
    * Appends text to an <code><big>XMLTYPE</big></code>
    * 
    * @param p_dst the <code><big>XMLTYPE</big></code> to append to
    * @param p_src the text to append             
    */       
   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            clob);
   /**
    * Appends text to an <code><big>XMLTYPE</big></code>
    * 
    * @param p_dst the <code><big>XMLTYPE</big></code> to append to
    * @param p_src the text to append             
    */       
   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            varchar2);
   /**
    * Appends text to an <code><big>XMLTYPE</big></code>
    * 
    * @param p_dst the <code><big>XMLTYPE</big></code> to append to
    * @param p_src the text to append             
    */       
   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            xmltype);
   /**
    * Retrieves a specified XML element from an <code><big>XMLTYPE</big></code>
    * 
    * @param p_xml the <code><big>XMLTYPE</big></code> to retrieve from 
    * @param p_path the element to retrieve, in XPath format
    * 
    * @return the specified element                      
    */       
   function get_xml_node(
      p_xml  in xmltype,
      p_path in varchar)
   return xmltype;
   /**
    * Retrieves the text contained in a specified XML element from an <code><big>XMLTYPE</big></code>
    * 
    * @param p_xml the <code><big>XMLTYPE</big></code> to retrieve from 
    * @param p_path the element from which to retrieve the text, in XPath format
    * 
    * @return the text contained in the specified element                      
    */       
   function get_xml_text(
      p_xml  in xmltype,
      p_path in varchar)
   return varchar2;
   /**
    * Retrieves the numeric value contained in a specified XML element from an <code><big>XMLTYPE</big></code>
    * 
    * @param p_xml the <code><big>XMLTYPE</big></code> to retrieve from 
    * @param p_path the element from which to retrieve the numeric value, in XPath format
    * 
    * @return the numeric value contained in the specified element                      
    */       
   FUNCTION get_xml_number (p_xml IN XMLTYPE, p_path IN VARCHAR)
      RETURN NUMBER;
   /**
    * Parses a delmited string and removes all tokens present in a second delimited 
    * string.  Equivalent to using the SQL MINUS operator where the selections are
    * tokens from the delimited strings.    
    * 
    * @param p_list_1 the delimited string to parse
    * @param p_list_2 the delimited string containing the tokens to remove
    * @param p_separator the delimiter for both strings
    * 
    * @return a copy of <code><big>p_list_1</big></code> with all the tokens in
    *         <code><big>p_list_2</big></code> removed
    */          
   FUNCTION x_minus_y (p_list_1      IN VARCHAR2,
                       p_list_2      IN VARCHAR2,
                       p_separator   IN VARCHAR2 DEFAULT NULL
                      )
      RETURN VARCHAR2;
END cwms_util;
/

SHOW ERRORS;
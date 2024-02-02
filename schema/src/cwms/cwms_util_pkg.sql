set escape `
CREATE OR REPLACE PACKAGE cwms_util
/**
 * Miscellaneous constants and procedures.
 *
 * @author Various
 * @since CWMS 2.0
 */
AS
   g_timezone_cache            cwms_cache.str_str_cache_t;
   g_time_zone_name_cache      cwms_cache.str_str_cache_t;
   g_time_zone_code_cache      cwms_cache.str_str_cache_t;
   g_parameter_id_cache        cwms_cache.str_str_cache_t;
   g_base_parameter_code_cache cwms_cache.str_str_cache_t;
   g_unit_conversion_info_cache cwms_cache.str_str_cache_t;
   g_office_id_cache           cwms_cache.str_str_cache_t;
   g_office_code_cache         cwms_cache.str_str_cache_t;
   /*
    * Not documented. Package-specific and session-specific logging properties
    */
   v_package_log_prop_text varchar2(30);
   function package_log_property_text return varchar2;

   /**
    * Sets text value of package logging property
    *
    * @param p_text The text of the package logging property. If unspecified or NULL, the current session identifier is used.
    */
   procedure set_package_log_property_text(
      p_text in varchar2 default null);

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
    * Store rule: Insert values at new times and replace any values at existing times, even
    * if incoming values are specified as missing
    */
   replace_all CONSTANT                      VARCHAR2 (16) := 'REPLACE ALL';
   /**
    * Store rule: Insert values at new times but do not replace any values at existing times
    */
   do_not_replace CONSTANT                   VARCHAR2 (16) := 'DO NOT REPLACE';
   /**
    * Store rule: Insert values at new times but do not replace any values at existing times
    * unless the existing values are specified as missing
    */
   replace_missing_values_only CONSTANT VARCHAR2 (32)
         := 'REPLACE MISSING VALUES ONLY' ;
   /**
    * Store rule: Insert values at new times and replace any values at existing times, unless
    * the incoming values are specified as missing
    */
   replace_with_non_missing CONSTANT VARCHAR2 (32)
         := 'REPLACE WITH NON MISSING' ;
   /**
    * Store rule: Delete all existing values in time window of incoming data and then
    * insert incoming data
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
    * Cookie for specifying all versions of a time series
    */
   all_version_dates CONSTANT                DATE := DATE '1010-10-10';
   /**
    * Cookie for specifying time series values
    */
   ts_values CONSTANT                        BINARY_INTEGER :=  1;
   /**
    * Cookie for specifying time series standard text
    */
   ts_std_text CONSTANT                      BINARY_INTEGER :=  2;
   /**
    * Cookie for specifying time series non-standard text
    */
   ts_text CONSTANT                          BINARY_INTEGER :=  4;
   /**
    * Cookie for specifying time series standard and non-standard text
    */
   ts_all_text CONSTANT                      BINARY_INTEGER :=  6;
   /**
    * Cookie for specifying time series binary objects
    */
   ts_binary CONSTANT                        BINARY_INTEGER :=  8;
   /**
    * Cookie for specifying all time series items except values
    */
   ts_all_non_values CONSTANT                BINARY_INTEGER := -2;
   /**
    * Cookie for specifying all time series items
    */
   ts_all CONSTANT                           BINARY_INTEGER := -1;
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
    * Commented out. User is_irregular_code function
    */
   --irregular_interval_code CONSTANT          NUMBER := 29;
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
   function get_expression_constants return str_tab_t;
   /**
    * Contains all mathematical operators that can be used with expression evaluation.
    */
   expression_operators str_tab_t := str_tab_t('+','-','*','/','//','%','^');
   function get_expression_operators return str_tab_t;
   /**
    * Contains names of all functions that can be used with expression evaluation.
    */
   expression_functions str_tab_t := str_tab_t(
      'ABS','ACOS','ASIN','ATAN','AVG','CEIL','COS','COUNT','EXP','FLOOR','FMOD','INV','LN','LOG',
      'LOG10','LOGN','MAX','MIN','MEAN','NEG','PROD','ROUND','SIGN','SIN','SQRT','SUM','TAN','TRUNC');
   function get_expression_functions return str_tab_t;
   /**
    * Contains all valid logical comparision operators
    */
   comparitors str_tab_t := str_tab_t('=','!=','<>','>','>=','<','<=','EQ','NE','GT','GE','LT','LE');
   /**
    * Contains all valid logical combination operators
    */
   combinators str_tab_t := str_tab_t('AND', 'OR', 'XOR', 'NOT');
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
     * Retrieves the nth delimited string.
     * <br>
     * Sequential delimiters in the source string result in null fields in the table,
     * except that if no delimiter is supplied, sequential whitespace characters are
     * treated as a single delimiter.
     * <br>
     * If no string can be found to satisfy the input parameters, the function return
     * <code><big>NULL</big></code>.
     *
     * @param p_text The text to be split.
     *
     * @param p_return_index Specifies 'n' (which delimited string to return).
     *
     * @param p_separator The separator string on which to split the text. If not
     *   specified or specified as <code><big>NULL</big></code>, the input text will be split
     *   on all whitespace occurrences.
     *
     * @param p_max_split Specifies the maximum number of splits to perform.  The
     *   maximum number of items returned will be one greater than this number. If
     *   not specified or specified as <code><big>NULL</big></code>, no maximum will be imposed
     *   and the input text will be split on every occurrence of the specified
     *   separator.
     *
     * @return The nth delimited string in the input string or <code><big>NULL</big></code>
     *   if no such string exists. If p_max_split is non-NULL and p_return_index > p_max_split+1,
     *   the function returns NULL.
     */
   function split_text (p_text        in varchar2,
                p_return_index in integer ,
                        p_separator   IN VARCHAR2 DEFAULT NULL ,
                        p_max_split   in integer default null
                       )
      RETURN VARCHAR2;
   /**
     * Retrieves the nth delimited string.
     * <br>
     * Sequential delimiters in the source string result in null fields in the table,
     * except that if no delimiter is supplied, sequential whitespace characters are
     * treated as a single delimiter.
     * <br>
     * If no string can be found to satisfy the input parameters, the function return
     * <code><big>NULL</big></code>.
     *
     * @param p_text The text to be split.
     *
     * @param p_return_index Specifies 'n' (which delimited string to return).
     *
     * @param p_separator The separator string on which to split the text. If not
     *   specified or specified as <code><big>NULL</big></code>, the input text will be split
     *   on all whitespace occurrences.
     *
     * @param p_max_split Specifies the maximum number of splits to perform.  The
     *   maximum number of items returned will be one greater than this number. If
     *   not specified or specified as <code><big>NULL</big></code>, no maximum will be imposed
     *   and the input text will be split on every occurrence of the specified
     *   separator.
     *
     * @return The nth delimited string in the input string or <code><big>NULL</big></code>
     *   if no such string exists. If p_max_split is non-NULL and p_return_index > p_max_split+1,
     *   the function returns NULL.
     */
   function split_text (p_text         in clob,
                        p_return_index in integer ,
                        p_separator    in varchar2 default null ,
                        p_max_split    in integer default null
                       )
      return varchar2;
   /**
     * Splits string into a table of strings using the specified delimiter.
     * If no delmiter is specified, the string is split around whitespace.
     * <br>
     * Sequential delimiters in the source string result in null fields in the table,
     * except that if no delimiter is supplied, sequential whitespace characters are
     * treated as a single delimiter.
     *
     * @param p_text The text to be split.
     *
     * @param p_separator The separator string on which to split the text. If not
     *   specified or specified as <code><big>NULL</big></code>, the input text will be split
     *   on all whitespace occurrences.
     *
     * @param p_max_split Specifies the maximum number of splits to perform.  The
     *   maximum number of items returned will be one greater than this number. If
     *   not specified or specified as <code><big>NULL</big></code>, no maximum will be imposed
     *   and the input text will be split on every occurrence of the specified
     *   separator.
     *
     * @return A table of strings.
     */
   FUNCTION split_text (p_text        IN VARCHAR2,
                        p_separator   IN VARCHAR2 DEFAULT NULL ,
                        p_max_split   IN INTEGER DEFAULT NULL
                       )
      RETURN str_tab_t;
   /**
     * Splits string into a table of strings using the specified delimiter.
     * If no delmiter is specified, the string is split around whitespace.
     * <br>
     * Sequential delimiters in the source string result in null fields in the table,
     * except that if no delimiter is supplied, sequential whitespace characters are
     * treated as a single delimiter.
     *
     * @param p_text The text to be split.
     *
     * @param p_separator The separator string on which to split the text. If not
     *   specified or specified as <code><big>NULL</big></code>, the input text will be split
     *   on all whitespace occurrences.
     *
     * @param p_max_split Specifies the maximum number of splits to perform.  The
     *   maximum number of items returned will be one greater than this number. If
     *   not specified or specified as <code><big>NULL</big></code>, no maximum will be imposed
     *   and the input text will be split on every occurrence of the specified
     *   separator.
     *
     * @return A table of strings.
     */
   FUNCTION split_text (p_text        IN CLOB,
                        p_separator   IN VARCHAR2 DEFAULT NULL ,
                        p_max_split   IN INTEGER DEFAULT NULL
                       )
      return str_tab_t;
   /**
     * Splits VARCHAR2 text into a table of strings based on a regular expression delimiter
     *
     * @param p_text               The text to split
     * @param p_separator          The regular expression delimiter
     * @param p_include_separators A flag ('T'/'F') that specifies whether to include the delimiters in the returned table. If not specified, no delimiters will be included.
     * @param p_match_parameter    A string that specifies how to use the regular expression. See documentation for the Oracle function REGEXP_COUNT for more information.
     *                             If not specified, 'c' (case sensitive, text is treated as a sinle line, period does not match newline characters, whitespace characters in the regular expression are significant) is used.
     * @param p_max_split          The maximum number of splits to perform. The number of rows in the resulting table will be one more than this number (one more than twice this number if p_include_separators is 'T'),
     *                             and the last row in the table will include all of the text beyond the 'nth' delimiter where 'n' is the same as p_max_split.
     *                             If specified, and greater than the number of time that p_text can be split otherwise, the returned table will have zero rows.
     *                             If not specified, no maximum number of splits is used.
     *
     * @return The table of strings resulting in splitting p_text using the specified parameters.
     */
   function split_text_regexp(
      p_text               in varchar2,
      p_separator          in varchar2,
      p_include_separators in varchar2 default 'F',
      p_match_parameter    in varchar2 default 'c',
      p_max_split          in integer default null)
      return str_tab_t;
   /**
     * Splits CLOB text into a table of strings based on a regular expression delimiter
     *
     * @param p_text               The text to split
     * @param p_separator          The regular expression delimiter
     * @param p_include_separators A flag ('T'/'F') that specifies whether to include the delimiters in the returned table. If not specified, no delimiters will be included.
     * @param p_match_parameter    A string that specifies how to use the regular expression. See documentation for the Oracle function REGEXP_COUNT for more information.
     *                             If not specified, 'c' (case sensitive, text is treated as a sinle line, period does not match newline characters, whitespace characters in the regular expression are significant) is used.
     * @param p_max_split          The maximum number of splits to perform. The number of rows in the resulting table will be one more than this number (one more than twice this number if p_include_separators is 'T'),
     *                             and the last row in the table will include all of the text beyond the 'nth' delimiter where 'n' is the same as p_max_split.
     *                             If specified, and greater than the number of time that p_text can be split otherwise, the returned table will have zero rows.
     *                             If not specified, no maximum number of splits is used.
     *
     * @return The table of strings resulting in splitting p_text using the specified parameters.
     */
   function split_text_regexp(
      p_text               in clob,
      p_separator          in varchar2,
      p_include_separators in varchar2 default 'F',
      p_match_parameter    in varchar2 default 'c',
      p_max_split          in integer default null)
      return str_tab_t;
   /**
     * Splits text into a table of strings based on a delimiter
     *
     * @param p_text               The text to split
     * @param p_delimiter          The delimiter to use for splitting the text
     * @param p_is_regex           A flag ('T'/'F') that specifies whether to use the delimiter as a regular expression ('T') or a text literal ('F')
     * @param p_regex_flags        A string that specifies how to use the regular expression if p_is_regex is 'T'. See documentation for the Oracle function REGEXP_COUNT for more information.
     *                             If not specified, the Oracle default (case sensitive, text is treated as a sinle line, period does not match newline characters, whitespace characters in the regular expression are significant) is used.
     * @param p_include_delimiters A flag ('T'/'F') that specifies whether to include the delimiters in the returned table. If not specified, no delimiters will be included.
     * @param p_return_index       If specifed and not NULL, only the 'nth' delimited string is retuned in the only row in the table. If not specified or NULL, the table will include all delimited strings (subject to p_max_split).
     * @param p_max_split          The maximum number of splits to perform. The number of rows in the resulting table will be one more than this number (one more than twice this number if p_include_delimiters is 'T'),
     *                             and the last row in the table will include all of the text beyond the 'nth' delimiter where 'n' is the same as p_max_split.
     *                             If specified, and greater than the number of time that p_text can be split otherwise, the returned table will have zero rows.
     *                             If not specified, no maximum number of splits is used.
     *
     * @return The table of strings resulting in splitting p_text using the specified parameters.
     */
   function split_text_ex(
      p_text               in clob,
      p_delimiter          in varchar2,
      p_is_regex           in varchar2,
      p_regex_flags        in varchar2 default null,
      p_include_delimiters in varchar2 default 'F',
      p_return_index       in integer  default null,
      p_max_split          in integer  default null)
      return str_tab_t;
   /**
     * Joins a table of strings into a single string using the specified delimiter.
     * If no delimiter is supplied or is specified as <code><big>NULL</big></code>, the input
     * strings are simply concatenated together.
     * <p>
     * Null strings in the table result in adjacent delimiters in the returned string.
     *
     * @param p_text_tab A table of strings to be joined
     *
     * @param p_separator The string to insert between the strings in <code><big>p_tab_text</big></code>
     *
     * @return The joined string
     */
   FUNCTION join_text (p_text_tab    IN str_tab_t,
                       p_separator   IN VARCHAR2 DEFAULT NULL
                      )
      RETURN VARCHAR2;
   /**
     * Formats the XML in the CLOB to have one element tag per line, indented by
     * the specified string.  The input is overwritten with the output.
     *
     * @param p_xml_clob <code><big>input: </big></code> The XML instance to be formatted<br>
     *                   <code><big>output:</big></code> The formatted XML instance
     * @param p_indent The string to use for indentation
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
    * @param p_string the delimeted recordset to parse
    * @return a table of tables of strings. Each record in the recordset becomes one
    *         outer row (table of fields) in the retured table, with fields within that
    *         record becoming rows of the inner table.
    *
    * @see record_separator
    * @see field_separator
    */
   FUNCTION parse_string_recordset (p_string IN VARCHAR2)
      RETURN str_tab_tab_t;
   /**
    * Parses a delimited text value into a table of tables of strings.
    *
    * @param p_text             The delimited text to parse.<p>
    *                           If the field delimiter or record delimiter occurs in a field value, the delimiter can be escaped by preceding it with an
    *                           escape character, or the delimiter (or entire field) may bet quoted with single or double quotes.<p>
    *                           If the single or double quote character occurs in a field value, the quote character can be escaped by preceding it with an
    *                           escape character, or the delimiter (or entire field) may bet quoted with the other quote character.<p>
    *                           If both the single and double quote characters occurs in a field value, the escape character must be used for at least
    *                           one of the quote characters. The other quote character may be escaped or the it (or entire field) may be quoted
    *                           with the escaped quote character.
    * @param p_field_delimiter  The field delimiter. Can be longer than 1 character. If not specified, the comma character is used.
    * @param p_keep_quotes      A flag (T/F) specifying whether to retain the quote characters of quoted fields. If not specified, quote characters are not retained.
    * @param p_escape_char      An optional 1-character string that can be used to allow inclusion of delimiters and quote characters in field values
    *                           by immediately preceding the delimiter or quote character in the text. There is no special meaning assigned to the character
    *                           following the escape character as there is programming languages such as C, Java, and Python (e.g., '\t' will be interpreted
    *                           as the character 't' if the escapce character is '\', and not as the tab character (character 9).
    * @param p_record_delimiter The record delimiter. Can be longer than 1 character. If not specified the newline character (character 10) will be used.
    *
    * @return A table of tables of strings. Each record in the text becomes one
    *         outer row (table of fields) in the retured table, with fields within that
    *         record becoming rows of the inner table.
    */
   function parse_delimited_text(
      p_text             in clob,
      p_field_delimiter  in varchar2 default ',',
      p_keep_quotes      in varchar2 default 'F',
      p_escape_char      in varchar2 default null,
      p_record_delimiter in varchar2 default chr(10))
      return str_tab_tab_t;
   /**
    * Parses a text value of fixed with fields into a table of table of strings.
    *
    * @param p_text             The text to parse
    * @param p_field_columns    The start and end columns of each field. The inner tables each contain the start and end columns (1-based) for each field.
    * @param p_trim             A flag (T/F) specifying whether to trim whitespace from the beginning and end of each field
    * @param p_record_delimiter The record delimiter. If not specified the newline character will be used.
    *
    * @return A table of tables of strings. Each record in the text becomes one
    *         outer row (table of fields) in the retured table, with fields within that
    *         record becoming rows of the inner table.
    */
   function parse_fixed_width_text(
      p_text             in clob,
      p_field_columns    in number_tab_tab_t,
      p_trim             in varchar2 default 'F',
      p_record_delimiter in varchar2 default chr(10))
      return str_tab_tab_t;

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
    * specifically to filter out PST and CST time zones, which define DST,
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
     * Formats a date/time for use in XML
     *
     * @param p_local_time
     * @param p_local_tz
     *
     * @return the XML-formatted date/time
     *
     */
   FUNCTION get_xml_time(
      p_local_time in date,
      p_local_tz   in varchar2)
      RETURN VARCHAR2;

   /**
    * Corrects times withing daylight savings time in time zones PST and CST.  These
    * time zones are not expected to observer DST, but erroneously do.  This function
    * corrects the affected times.
    *
    * @param p_time The input time that may need correction
    *
    * @return The time which has been corrected if necessary
    */
   FUNCTION fixup_timezone (p_time IN TIMESTAMP WITH TIME ZONE)
      RETURN TIMESTAMP WITH TIME ZONE;
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
      RETURN DATE;
   /**
    * Converts a specified<code><big>TIMESTAMP</big></code> from one time zone to another
    *
    * @param p_in_date the date to convert to UTC
    * @param p_from_tz the original time zone
    * @param p_to_tz the desired time zone
    *
    * @return an equivalent <code><big>DATE</big></code> in the desired time zone
    */
   FUNCTION change_timezone (
      p_in_date IN TIMESTAMP,
      p_from_tz IN VARCHAR2,
      p_to_tz   IN VARCHAR2 default 'UTC')
      RETURN TIMESTAMP;
   /**
    * Returns whether the upper case of the input is <code><big>'T'</big></code>
    * or <code><big>'TRUE'</big></code>
    *
    * @param p_true_false 'Boolean' text input
    */
   FUNCTION is_true (p_true_false IN VARCHAR2)
      RETURN BOOLEAN;
   /**
    * Returns whether the upper case of the input is <code><big>'F'</big></code>
    * or <code><big>'FALSE'</big></code>
    *
    * @param p_true_false 'Boolean' text input
    *
    * @return <code><big>TRUE</big></code> or <code><big>FALSE</big></code>
    */
   FUNCTION is_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN;
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
      RETURN BOOLEAN;
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
      RETURN VARCHAR2;
   /**
    * Retrieves the base portion of a base-sub identifier
    *
    * @param p_full_id the identifier to parse for the base portion
    *
    * @return the base portion of the identifier
    */
   FUNCTION get_base_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2;
   /**
    * Retrieves the (possibly null) sub portion of a base-sub identifier
    *
    * @param p_full_id the identifier to parse for the sub portion
    *
    * @return the (possibly null) sub portion of the identifier
    */
   FUNCTION get_sub_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2;
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
      return number;
   /**
    * Retrieves the parameter code of a full parameter identifier
    *
    * @param p_param_id the identifier for which to return the base parameter code
    * @param p_office_id the office identifier for which to find the code. If
    *        <code><big>NULL</big></code> the calling user's office is used
    *
    * @return the base parameter code
    */
   FUNCTION get_parameter_code (
      p_param_id  in varchar2,
      p_office_id in varchar2 default null)
      return number;
   /**
    * Creates a parameter (maybe) and returns the parameter code
    *
    * @param p_param_id       The text identifier parameter of the parameter to create and/or retrieve the code for
    * @param p_fail_if_exists A flag (T/F) specifying whether to fail if the parameter already exists.
    *                         If F, then the code of the existing parameter is returned
    * @param p_office_id      The office to create/retrieve the parameter code for. If unspecified or NULL the current session's default office is used.
    */
   FUNCTION create_parameter_code(
      p_param_id       in varchar2,
      p_fail_if_exists in varchar2 default 'F',
      p_office_id      in varchar2 default null)
      return number;
   /**
    * Retrieves the interval minutes of a time series
    *
    * @param p_cwms_ts_code the code of the time series as presented in TS_CODE
    *        column of the CWMS_V_TS_ID view
    *
    * @return the interval minutes of the time series
    */
   FUNCTION get_ts_interval (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;
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
      RETURN VARCHAR2;
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
      RETURN NUMBER;
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
      RETURN VARCHAR2;
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
   function get_time_zone_name (p_time_zone_name in varchar2)
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
    * Returns the office id of specified office code
    *
    * @param p_db_office_code  the office code for which to find the id.
    *
    * @return the office id of the specified code
    *
    */
   FUNCTION get_db_office_id_from_code (p_db_office_code IN NUMBER)
      RETURN VARCHAR2;
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
    * Strips all leading and trailing whitespace and non-printable chars from a string.
    *
    * @param p_text the string to strip
    *
    * @return the input string with all leading and trailing whitespace non-printable chars removed
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
    * Genrates the Java microsecond equivalent of a <code><big>TIMESTAMP</big></code>
    * value.  The Java microsecond value specifies the number of microseconds since
    * the beginning of the UNIX epoch (01 Jan 1970 00:00:00 UTC)
    *
    * @param p_timestamp the <code><big>TIMESTAMP</big></code> value to convert
    *
    * @return the Java millsecond value equivalent of the input
    */
   FUNCTION to_micros (p_timestamp IN timestamp)
      RETURN NUMBER;
   /**
    * Genrates the Java microsecond value for the current time. The Java microsecond
    * value specifies the number of microseconds since the beginning of the UNIX epoch
    * (01 Jan 1970 00:00:00 UTC)
    *
    * @return the Java millsecond value representing the current time
    */
   FUNCTION current_micros
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
      return varchar2;

   /**
    * Retrieves the unit identifier for a specified unit code
    *
    * @param p_unit_code the unit code to retrieve the identifier for
    *
    * @return the unit identifier corresponding to the input
    */
   function get_unit_id2(
      p_unit_code in varchar2)
      return varchar2;

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
   /**
    * Converts a number of minutes into a string representation showing the
    * the number of years, months, days, hours, and minutes.
    *
    * @param p_interval is the number of minutes to convert into a string
    *        representation.
    *
    * @return the string representation as nnyrnnmonndynnhrnnmi
    */
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
   return binary_double;
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
   return binary_double;
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
   return binary_double;
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
   return binary_double;
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
      p_intvl in yminterval_unconstrained)
      return integer;
   /**
    * Converts an <code><big>INTERVAL DAY TO SECOND</big></code> to an equivalent number of minutes
    *
    * @param p_intvl the interval to convert
    *
    * @return an equivalent number of minutes
    */
   function dsinterval_to_minutes(
      p_intvl in dsinterval_unconstrained)
      return integer;
   /**
    * Converts an integer number of minutes to an equivalent ISO 8601 Duration string
    *
    * @param p_minutes the duration to convert
    *
    * @return an equivalent ISO 8601 Duration string
    */
   function minutes_to_duration (
      p_minutes in integer)
      return varchar2;
   /**
    * Converts an ISO 8601 Duration string to an equivalent number of minutes
    *
    * @param p_duration the duration to convert
    *
    * @return an equivalent number of minutes
    */
   function duration_to_minutes(
      p_duration in varchar2)
      return integer;
   /**
    * Converts an ISO 8601 Duration string to equivalent interval
    *
    * @param p_ym_interval the interval year to month portion of the equivalent interval
    * @param p_ds_interval the interval day to second portion of the equivalent interval
    * @param p_duration the duration to convert
    */
   procedure duration_to_interval(
      p_ym_interval out yminterval_unconstrained,
      p_ds_interval out dsinterval_unconstrained,
      p_duration    in  varchar2);
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
    * Determines whether a specified token is the name of a variadic function
    * (takes a variable number of arguments)
    *
    * @param p_token the functio name to analyze
    *
    * @return whether the specified token is the name of a variadic function
    *
    * @see expression_functions
    */
   function is_variadic_function(p_token in varchar2) return boolean;
   /**
    * Determines whether a specified token is a comparison operator that can be used in
    * logic expression evaluation
    *
    * @param p_token the token to analyze
    *
    * @return whether the specified token is in the list of valid logic expression
    *         comparison operators
    *
    * @see comparitors
    */
   function is_comparison_operator(p_token in varchar2) return boolean;
   /**
    * Determines whether a specified token is a combination operator that can be used in
    * logic expression evaluation
    *
    * @param p_token the token to analyze
    *
    * @return whether the specified token is in the list of valid logic expression
    *         combination operators
    *
    * @see combinators
    */
   function is_combination_operator(p_token in varchar2) return boolean;
   /**
    * Determines whether a specified token is a an operator that can be used in
    * logic expression evaluation
    *
    * @param p_token the token to analyze
    *
    * @return whether the specified token is in the list of valid logic expression
    *         comparison or combination operators
    *
    * @see comparitors
    * @see combinators
    */
   function is_logic_operator(p_token in varchar2) return boolean;
   /**
    * Parses an algebraic expression and returns a normalized version.
    *
    * @param p_algebraic_expr a mathematical expression in infix (algebraic) notation.
    *        All tokens in the normalized expression (numbers, variables, operators,
    *        constants, functions) will be separated from adjacent tokens by whitespace.
    *        No whitespace is inserted before or after parentheses. Variables are specified
    *        as arg1, arg2, ... argN. Negated variables (e.g., -argN) are accepted.
    *
    * @return a normalized version of the infix (algebraic) expression
    */
   function normalize_algebraic(
      p_algebraic_expr in varchar2)
      return varchar2;
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
      return str_tab_t;
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
      return str_tab_t;
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
      return str_tab_t;
   /**
    * Generates a stack of RPN expressions that can each be evaluated.
    *
    * @param p_expr one or more mathematical expressions in infix (algebraic) notation or
    *        in postfix (reverse Polish) notation (RPN). Standard algebraic operator
    *        precedence (order of operations) applies for infix notation and can be
    *        overridden by parentheses.  All tokens in the expression (numbers,
    *        variables, operators, constants, functions) must be separated from
    *        adjacent tokens by whitespace. No whitespace is required before or
    *        after parentheses. Parentheses are not used in RPN notation. Variables
    *        are specified as arg1, arg2, ... argN. Negated variables (e.g., -argN)
    *        are accepted.
    *
    * @param p_is_rpn A flag (T/F) specifying whether the expression is known to be in postfix notation.
    *
    * @return a stack of RPN expressions in postfix (reverse Polish) notation (RPN). The first value is the top of the stack
    */
   function tokenize_expression2(
      p_expr   in varchar2,
      p_is_rpn in varchar2 default 'F')
      return str_tab_t;
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
    * Returns a stack of values from tokens in postfix (reverse Polish) notation (RPN) and
    * specified values for variables.  The first value is the top of the stack.
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
    * @return the stack of values
    */
   function eval_tokenized_expression2(
      p_RPN_tokens in str_tab_t,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return double_tab_t;
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
    * Evaluates an arithmetic expression in infix (algebraic) notation and return
    * a stack of vlues based on specified variables.  The first value is the top of the stack.
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
    * @return the stack of values
    */
   function eval_algebraic_expression2(
      p_algebraic_expr in varchar2,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return double_tab_t;
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
    * Evaluates an arithmetic expression in postfix (reverse Polish) notation (RPN)
    * and return  a stack of values based on specified variables. The first value is the top of the stack.
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
    * @return the stack of values
    */
   function eval_RPN_expression2(
      p_RPN_expr    in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return double_tab_t;
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
    * Evaluates an arithmetic expression in infix (algebraic) notation or in postfix
    * (reverse Polish) notation (RPN) and returns a stack of values based on specified variables.
    * The first value is the top of the stack.
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
    * @return the stack of values
    */
   function eval_expression2(
      p_expr        in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return double_tab_t;
   /**
    * Tokenizes a comparison expression in infix or postfix notation and returns the
    * tokens in a table of length 3.  The first two rows of the table are the tokenized arithmetic
    * expressions.  The last row contains a table of length 1 which contains the comparison operator.
    *
    * @param p_comparison_expression. The comparison expression in infix or postfix notation.
    *        The expression must be comprised of two arithmetic expressions and one comparison operator.
    *        Valid comparison operators are:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">operators</th>
    *     <th class="descr">meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">'='</td>
    *     <td class="descr">The expressions are equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'!=', '`&lt;`&gt;', 'NE'</td>
    *     <td class="descr">The expressions are not equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;', 'LT'</td>
    *     <td class="descr">The first expression is less than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;=', 'LE'</td>
    *     <td class="descr">The first expression is less than or equal to the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;', 'GT'</td>
    *     <td class="descr">The first expression is greater than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;=', 'GE'</td>
    *     <td class="descr">The first expression is greater than or equal to the second</td>
    *   </tr>
    * </table>
    *
    * @return a table of tokens.
    */
   function tokenize_comparison_expression(
      p_comparison_expression in varchar2)
      return str_tab_tab_t;
   /**
    * Tokenizes a logic expression in infix or postfix notation and returns the
    * tokens in a table ready for evaluation.
    *
    * @param p_expr. The logic expression in infix or postfix notation.
    *        The expression must be comprised of one or more comparison expressions (two arithmetic expressions and one comparison operator)
    *        separated by logic operators
    *        Valid comparison operators are:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">operators</th>
    *     <th class="descr">meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">'='</td>
    *     <td class="descr">The expressions are equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'!=', '`&lt;`&gt;', 'NE'</td>
    *     <td class="descr">The expressions are not equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;', 'LT'</td>
    *     <td class="descr">The first expression is less than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;=', 'LE'</td>
    *     <td class="descr">The first expression is less than or equal to the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;', 'GT'</td>
    *     <td class="descr">The first expression is greater than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;=', 'GE'</td>
    *     <td class="descr">The first expression is greater than or equal to the second</td>
    *   </tr>
    * </table>
    *
    *Valid logic operators are: (all operators evaluated left to right)
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">operators</th>
    *     <th class="descr">precedence (higher evaluated earlier)</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">AND</td>
    *     <td class="descr">3</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">OR</td>
    *     <td class="descr">1</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">XOR</td>
    *     <td class="descr">2</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">NOT</td>
    *     <td class="descr">4</td>
    *   </tr>
    * </table>
    *
    * @return a table of tokens.
    */
   function tokenize_logic_expression(
      p_expr in varchar2)
      return str_tab_tab_t;
   /**
    * Replaces top-level parenthetical sub-expressions in a specifed expression. The replaced sub-expressions are in positions 1..count-1 in the returned table
    * and the expression with the sub-expressions replaced is returned in position count in the returned table.  The sub-expressions are replaced with the
    * string '$n' where n is the position of the replaced sub-expression in the table.
    *
    * @param p_expr The expression whose top-level parenthetical expressions will be replaced
    *
    * @return A table of length n+1 where n is the number of top-level parenthetical expressions replaced
    */
   function replace_parentheticals(
      p_expr in varchar2)
      return str_tab_t;
   /**
    * Evaluates a tokenized comparison expression and return the the result of the comparison as a boolean (true or false)
    *
    * @param p_tokens The tokenized comparison expression
    *
    * @return true or false
    */
   function eval_tokenized_comparison(
      p_tokens      in str_tab_tab_t,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return boolean;
   /**
    * Evaluates a tokenized comparison expression and return the the result of the comparison as a varchar2(1) ('T' or 'F')
    *
    * @param p_tokens The tokenized comparison expression
    *
    * @return 'T' or 'F'
    */
   function eval_tokenized_comparison2(
      p_tokens      in str_tab_tab_t,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return varchar2;
   /**
    * Evaluates a comparison expression in infix or postfix notation and returns the result of the comparison as a boolean (true or false).
    *
    * @param p_comparison_expression. The comparison expression in infix or postfix notation.
    *        The expression must be comprised of two arithmetic expressions and one comparison operator.
    *        Valid comparison operators are:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">operators</th>
    *     <th class="descr">meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">'='</td>
    *     <td class="descr">The expressions are equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'!=', '`&lt;`&gt;', 'NE'</td>
    *     <td class="descr">The expressions are not equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;', 'LT'</td>
    *     <td class="descr">The first expression is less than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;=', 'LE'</td>
    *     <td class="descr">The first expression is less than or equal to the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;', 'GT'</td>
    *     <td class="descr">The first expression is greater than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;=', 'GE'</td>
    *     <td class="descr">The first expression is greater than or equal to the second</td>
    *   </tr>
    * </table>
    *
    * @return true or false.
    */
   function eval_comparison_expression(
      p_expr        in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return boolean;
   /**
    * Evaluates a comparison expression in infix or postfix notation and returns the result of the comparison as a varchar2(1) ('T' or 'F')
    *
    * @param p_comparison_expression. The comparison expression in infix or postfix notation.
    *        The expression must be comprised of two arithmetic expressions and one comparison operator.
    *        Valid comparison operators are:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">operators</th>
    *     <th class="descr">meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">'='</td>
    *     <td class="descr">The expressions are equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'!=', '`&lt;`&gt;', 'NE'</td>
    *     <td class="descr">The expressions are not equal</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;', 'LT'</td>
    *     <td class="descr">The first expression is less than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&lt;=', 'LE'</td>
    *     <td class="descr">The first expression is less than or equal to the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;', 'GT'</td>
    *     <td class="descr">The first expression is greater than the second</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'`&gt;=', 'GE'</td>
    *     <td class="descr">The first expression is greater than or equal to the second</td>
    *   </tr>
    * </table>
    *
    * @return The result of the comparison as 'T' or 'F'
    */
   function eval_comparison_expression2(
      p_expr        in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return varchar2;
   /**
    * Retrieves the expression depth (levels of enclosing parentheses) for a specified position in an expression.
    *
    * @param p_position The position in the expression.  Must be in range 1..lenth(expression).
    * @param p_expr     The expression to evaluate
    *
    * @return The expression depth at the specified postion
    *
    */
   function get_expression_depth_at(
      p_position in integer,
      p_expr     in varchar2)
      return integer;
   /**
    * Reformats a mathematical expression in infix (algebraic) notation
    *
    * @param p_expression The mathematical expression to reformat. It may be specified in infix (algebraic) or postfix (RPN) notation.
    *
    * @return The mathematical expression in infix (algebraic) notation.  The expression will not include any parentheses that are not necessary for correct order of operations.
    */
   function to_algebraic(
      p_expr in varchar2)
      return varchar2;
   /**
    * Formats a tokenized mathematical expression in infix (algebraic) notation
    *
    * @param p_tokens The mathematical expression to format as postfix ordered tokens.
    *
    * @return The mathematical expression in infix (algebraic) notation.  The expression will not include any parentheses that are not necessary for correct order of operations.
    */
   function to_algebraic(
      p_tokens in str_tab_t)
      return varchar2;
   /**
    * Reformats a logic expression in infix (algebraic) notation
    *
    * @param p_expression The logic expression to reformat. It may be specified in infix (algebraic) or postfix (RPN) notation.
    *
    * @return The logic expression in infix (algebraic) notation.  The expression will not include any parentheses that are not necessary for correct order of operations.
    */
   function to_algebraic_logic(
      p_expr in varchar2)
      return varchar2;
   /**
    * Reformats a mathematical expression in postfix (RPN) notation
    *
    * @param p_expression The mathematical expression to reformat. It may be specified in infix (algebraic) or postfix (RPN) notation.
    *
    * @return The mathematical expression in postfix (RPN) notation.
    */
   function to_rpn(
      p_expr in varchar2)
      return varchar2;
   /**
    * Formats a mathematical expression in postfix (RPN) notation
    *
    * @param p_tokens The mathematical expression to format as postfix ordered tokens.
    *
    * @return The mathematical expression in postfix (RPN) notation.
    */
   function to_rpn(
      p_tokens in str_tab_t)
      return varchar2;
   /**
    * Reformats a logic expression in postfix (RPN) notation
    *
    * @param p_expression The logic expression to reformat. It may be specified in infix (algebraic) or postfix (RPN) notation.
    *
    * @return The logic expression in postfix (RPN) notation.
    */
   function to_rpn_logic(
      p_expr in varchar2)
      return varchar2;
   /**
    * Returns the symbolic representation of a comparison operator
    *
    * @param p_operator The comparison operator in text or symbolic from
    *
    * @return the comparison operator in symbolic form
    */
   function get_comparison_op_symbol(
      p_operator in varchar2)
      return varchar2;
   /**
    * Returns the text representation of a comparison operator
    *
    * @param p_operator The comparison operator in text or symbolic from
    *
    * @return the comparison operator in text form
    */
   function get_comparison_op_text(
      p_operator in varchar2)
      return varchar2;
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
    * @param p_xml The xml document or fragment to retrieve from
    * @param p_path The element to retrieve, in XPath format
    *
    * @return the specified element
    */
   function get_xml_node(
      p_xml  in xmltype,
      p_path in varchar)
   return xmltype;
   /**
    * Retrieves matching XML element from an <code><big>XMLTYPE</big></code>
    *
    * @param p_xml        The xml document or fragment to retrieve from
    * @param p_path       The elements to retrieve, in XPath format
    * @param p_condition  An optional condition by which to filter the elements, in XPath format. If specified, the path in this condition must be relative to the root of the xml document or fragment
    * @param p_order_by   An optional path by which to order the elements, in XPath format. If specified, the path must be relative to the the root of the xml document or fragment.
    * @param p_descending A flag ('T'/'F') specifying if the ordering should be in descending order. If unspecified, any ordering will be in ascending order. This parameter is meaningful only in conjunction with p_order_by parameter.
    *
    * @return The elements that match the input path and condition (if any), in the specified order (if any).
    */
   function get_xml_nodes(
      p_xml        in xmltype,
      p_path       in varchar2,
      p_condition  in varchar2 default null,
      p_order_by   in varchar2 default null,
      p_descending in varchar2 default 'F')
   return xml_tab_t;
   /**
    * Retrieves a specified XML attributes from an <code><big>XMLTYPE</big></code>
    *
    * @param p_xml The xml document or fragment to retrieve from
    * @param p_path The element to retrieve, in XPath format
    *
    * @return the attributes of specified element, if any, in name=value format
    */
   function get_xml_attributes(
      p_xml  in xmltype,
      p_path in varchar2)
      return str_tab_t;
   /**
    * Retrieves the text contained in a specified XML element from an <code><big>XMLTYPE</big></code>
    *
    * @param p_xml The xml document or fragment to retrieve from
    * @param p_path The element to retrieve, in XPath format
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
    * @param p_xml The xml document or fragment to retrieve from
    * @param p_path The element to retrieve, in XPath format
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

   --
   -- Routines for dealing with AT_BOOLEAN_STATE table
   --
   procedure set_boolean_state(
      p_name  in varchar2,
      p_state in boolean);

   procedure set_boolean_state(
      p_name  in varchar2,
      p_state in char);

   function get_boolean_state(
      p_name in varchar2)
      return boolean;

   function get_boolean_state_char(
      p_name in varchar2)
      return char;
   --
   -- Routines for dealing with AT_SESSION_INFO table
   --
   /**
    * Sets session-specific information
    *
    * @param p_item_name the name of the session info to set
    * @param p_txt_value the text value of the session info
    * @param p_num_value the numeric value of the session info
    */
   procedure set_session_info(
      p_item_name in varchar2,
      p_txt_value in varchar2,
      p_num_value in number);
   /**
    * Sets session-specific information
    *
    * @param p_item_name the name of the session info to set
    * @param p_txt_value the text value of the session info
    */
   procedure set_session_info(
      p_item_name in varchar2,
      p_txt_value in varchar2);
   /**
    * Sets session-specific information
    *
    * @param p_item_name the name of the session info to set
    * @param p_num_value the numeric value of the session info
    */
   procedure set_session_info(
      p_item_name in varchar2,
      p_num_value in number);
   /**
    * Retrieves session-specific information
    *
    * @param p_txt_value the text value of the session info
    * @param p_num_value the numeric value of the session info
    * @param p_item_name the name of the session info to retrieve
    */
   procedure get_session_info(
      p_txt_value out varchar2,
      p_num_value out number,
      p_item_name in  varchar2);
   /**
    * Retrieves session-specific text information
    *
    * @param p_item_name the name of the session info to retrieve
    *
    * @return the text value of the session info
    */
   function get_session_info_txt(
      p_item_name in varchar2)
      return varchar2;
   /**
    * Retrieves session-specific numeric information
    *
    * @param p_item_name the name of the session info to retrieve
    *
    * @return the numeric value of the session info
    */
   function get_session_info_num(
      p_item_name in varchar2)
      return number;
   /**
    * Resets (unsets, deletes) session-specific information
    *
    * @param p_item_name the name of the session info to reset
    */
   procedure reset_session_info(
      p_item_name in varchar2);
   /**
    * Returns 'T' if a number is a NaN, otherwise 'F'. The clause "Is_Nan(<val>) = 'F'"
    * can be used in place of "<val> Is Not Nan" to correctly identify NULL values as
    * not NaN values..
    *
    * @param p_value The value to check for not-NaN status.
    *
    * @return 'T' if p_value is a NaN, 'F' otherwise.
    */
   function is_nan(
      p_value in binary_double)
      return varchar2;
   /**
    * Returns a subset of a table
    *
    * @param p_table The table to return the subset of
    * @param p_first The index of the first element to include
    * @param p_last  The index of the last element to include.  If NULL or greater than the table length, the last index of the input table will be used.
    *
    * @return A subset of the input table, from p_first to p_last.
    */
   function sub_table(
      p_table in str_tab_t,
      p_first in integer,
      p_last  in integer default null)
      return str_tab_t;
   /**
    * Returns a subset of a table
    *
    * @param p_table The table to return the subset of
    * @param p_first The index of the first element to include
    * @param p_last  The index of the last element to include.  If NULL or greater than the table length, the last index of the input table will be used.
    *
    * @return A subset of the input table, from p_first to p_last.
    */
   function sub_table(
      p_table in number_tab_t,
      p_first in integer,
      p_last  in integer default null)
      return number_tab_t;
   /**
    * Returns a subset of a table
    *
    * @param p_table The table to return the subset of
    * @param p_first The index of the first element to include
    * @param p_last  The index of the last element to include.  If NULL or greater than the table length, the last index of the input table will be used.
    *
    * @return A subset of the input table, from p_first to p_last.
    */
   function sub_table(
      p_table in double_tab_t,
      p_first in integer,
      p_last  in integer default null)
      return double_tab_t;


    FUNCTION str2tbl (p_str IN VARCHAR2, p_delim IN VARCHAR2 DEFAULT ',')
       RETURN str2tblType
       PIPELINED;

    FUNCTION stragg (input VARCHAR2)
       RETURN VARCHAR2
       PARALLEL_ENABLE
       AGGREGATE USING string_agg_type;

   /**
    * Returns the value associated with a specified key in a unit specification string in the form of <code>x=abc|y=def|z=ghi</code> or NULL if the specified key is not present in the string.
    * The characters <code>x</code>, <code>y</code>, and <code>z</code> are keys and <code>abc</code>, <code>def</code>, <code>ghi</code> are the values associated with the keys.
    *
    * @param p_unit_spec The unit specification string to parse
    * @param p_key       The key (not case sensitive) whose value is to be returned.
    *
    * @return The value associated with the specified key, or NULL if the key is not present in the string.
    */
   function parse_unit_spec(
      p_unit_spec in varchar2,
      p_key       in varchar2)
      return varchar2;
   /**
    * Returns the unit from a unit specification string.  The unit is the entire string unless the string is format <code>x=abc|y=def|z=ghi</code>, in
    * which case the value associated with the key <code>U</code> is the unit.
    *
    * @param p_unit_spec The unit specification string
    * @return The unit specified in the string or NULL if the string does not contain a unit.
    * @see parse_unit_spec
    */
   function parse_unit(
      p_unit_spec in varchar2)
      return varchar2;
   /**
    * Returns the vertical datum (associated with the key <code>V</code>) in a unit specification string of the format <code>x=abc|y=def|z=ghi</code>.
    * If a non-NULL default vertical datum is to be overriden by a NULL specified vertical datum, the specified vertical datum must be coded as <code>V=NULL</code>
    *
    * @param p_unit_spec The unit specification string
    * @return The associated vertical datum or NULL if the key <code>V</code> is not in the string.
    * @see parse_unit_spec
    */
   function parse_vertical_datum(
      p_unit_spec in varchar2)
      return varchar2;
   /**
    * Returns the effective vertical datum. If a vertical datum is encoded into the unit specification string, it is returned. Otherwise the default vertical datum for the session is returned.
    *
    * @param p_unit_spec The unit specification string, which may contain an encoded vertical datum
    * @return The effective vertical datum
    * @see parse_unit
    */
   function get_effective_vertical_datum(
      p_unit_spec in varchar2)
      return varchar2;
   -- not documented
   procedure check_dynamic_sql(
      p_sql in varchar2);
   /**
    * Retrieves data from a URL
    *
    * @param p_url The URL to retrieve data from
    * @param p_timeout The session timeout in seconds for this request
    *
    * @return The URL data as a CLOB
    */
   function get_url(
      p_url     in varchar2,
      p_timeout in integer default 60)
      return clob;
   /**
    * Returns a column of data from a table of rows of data. All rows should be of the same length.
    *
    * @param p_table  The table of data
    * @param p_column The column (1-based) to return
    *
    * @return the column of data as a double_tab_t
    * @exception if p_column is greater than the length of the first row
    */
   function get_column(
      p_table  in double_tab_tab_t,
      p_column in pls_integer)
      return double_tab_t;
   /**
    * Returns a column of data from a table of rows of data. All rows should be of the same length.
    *
    * @param p_table  The table of data
    * @param p_column The column (1-based) to return
    *
    * @return the column of data as a str_tab_t
    * @exception if p_column is greater than the length of the first row
    */
   function get_column(
      p_table  in str_tab_tab_t,
      p_column in pls_integer)
      return str_tab_t;
   /**
    * Converts an XML document fragment into the equivalent JSON object
    *
    * @param p_xml the XML to convert
    * @return the equivalen JSON object
    */
   function to_json(
      p_xml in xmltype)
      return clob;
   /**
    * Returns true if the interval code is irregular otherwise return false
    *
    * @param p_interval_code  interval code
    *
    * @return Returns true if the interval code is irregular otherwise return false
    * @exception if p_interval_code is an invalid code
    */
   function is_irregular_code(
      p_interval_code  in CWMS_INTERVAL.INTERVAL_CODE%TYPE)
      return boolean;
   /**
    * Checks whether the current user has permissions for the specified office
    *
    * @param p_office_id the office to check for permissions for the current user
    * @param p_user_group_id if specified, the specific user permission to check - otherwise the 'All Users' permission is checked
    * @exception if the user does not have the permission for the specified office
    */
   procedure check_office_permission(
      p_office_id     in varchar2,
      p_user_group_id in varchar2 default null);
   /**
    * Retrieves catalog of scheduled jobs
    *
    * @param p_job_name_mask A mask specifying which job names to catalog.  If not specified, all jobs are cataloged.
    * Matching is accomplished with glob-style wildcards, as shown below.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @return a cursor containing the following columns, ordered by job_name
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">job_name</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">The name of the scheduled job</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">repeat_interval</td>
    *     <td class="descr">varchar2(4000)</td>
    *     <td class="descr">How often the job is executed</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">run_count</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The number of times the job has executed since being started</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">failure_count</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The number of times the job has failed since being started</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">state</td>
    *     <td class="descr">varchar2(15)</td>
    *     <td class="descr">The current state of the job</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">last_start_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The last time the job was executed</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">last_run_duration</td>
    *     <td class="descr">ds_interval_unconstrained</td>
    *     <td class="descr">The amount of elapsed time for the last job execution</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">next_start_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The next time that the job is scheduled to execute</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">status</td>
    *     <td class="descr">varchar2(30)</td>
    *     <td class="descr">The status of the last job execution</td>
    *   </tr>
    * </table>
    */
   function cat_scheduled_jobs(
      p_job_name_mask in varchar2 default '*')
      return sys_refcursor;
   /**
    * Retrieves catalog of the run history for a scheduled job
    *
    * @param p_job_name Specifies which job names to return the history for.
    *
    * @return a cursor containing the following columns, ordered by start_time
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">start_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The time the job was executed</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">run_duration</td>
    *     <td class="descr">ds_interval_unconstrained</td>
    *     <td class="descr">The elapsed time of the job execution</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">status</td>
    *     <td class="descr">varchar2(30)</td>
    *     <td class="descr">The status time of the job execution</td>
    *   </tr>
    * </table>
    */
   function cat_scheduled_job_history(
      p_job_name in varchar2)
      return sys_refcursor;
   /**
    * Converts a tab-separated-value string into a comma-separated-value string
    *
    * @param p_tab The string to convert
    * @return The converted string, with any values containing commas quoted
    */
   function tab_to_csv(
      p_tab in clob)
      return clob;
   /**
    * Converts a tab-separated-value string into a comma-separated-value string
    *
    * @param p_tab The string to convert
    * @return The converted string, with any values containing commas quoted
    */
   function tab_to_csv(
      p_tab in varchar2)
      return varchar2;
   /**
    * Returns the call stack for the current process
    *
    * @return A table, each row containing table of name, routine, line_number, all as varchar2;
    *
    */
   function get_call_stack
      return str_tab_tab_t;
   /**
    * Retrieves information about the specified application instance
    *
    * @param p_office_id     The office of the user running the application
    * @param p_user_name     The name of the user running the application
    * @param p_app_name      The application name
    * @param p_host_name     The name of the system the user is running the application on
    * @param p_login_time    The login time of the application, in Java milliseconds
    * @param p_logout_time   The logout time of the application, or time the application was found to be disconnected, in Java milliseconds
    * @param p_normal_logout A flag (T/F) specifying whether the application logged off normally (T), or was disconnected before logging off (F)
    * @param p_login_server  The URL of the login server that handled the application's login
    * @param p_uuid          The unique identifier of the application instance
    */
   procedure get_application_login(
      p_office_id     out varchar2,
      p_user_name     out varchar2,
      p_app_name      out varchar2,
      p_host_name     out varchar2,
      p_login_time    out integer,
      p_logout_time   out integer,
      p_normal_logout out integer,
      p_login_server  out varchar2,
      p_uuid          in  varchar2);
   /**
    * Retrieves information about the application instance associated with the specified database session. The database session must be currently connected and the application currently logged in.
    *
    * @param p_office_id    The office of the user running the application
    * @param p_user_name    The name of the user running the application
    * @param p_app_name     The application name
    * @param p_host_name    The name of the system the user is running the application on
    * @param p_login_time   The login time of the application, in Java milliseconds
    * @param p_login_server The URL of the login server that handled the application's login
    * @param p_session_id   The AUDSID of the session to retrieve information for. If unspecified (or zero) the current session's AUDSID is used
    */
   procedure get_application_login(
      p_office_id     out varchar2,
      p_user_name     out varchar2,
      p_app_name      out varchar2,
      p_host_name     out varchar2,
      p_login_time    out integer,
      p_login_server  out varchar2,
      p_session_id    in  integer default 0);
   /**
    * Retrieves information about application instances. This routine uses glob-style wildcard patterns and not SQL-style wildcard patterns
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    * <p>
    * @param P_User_Name_Mask    The literal or wildcard pattern specifying which user name(s) to match. If NULL or unspecified, all user names are matched.
    * @param P_App_Name_Mask     The literal or wildcard pattern specifying which app name(s) to match. If NULL or unspecified, all app names are matched.
    * @param P_Host_Name_Mask    The literal or wildcard pattern specifying which host name(s) to match. If NULL or unspecified, all host names are matched.
    * @param P_Login_Server_Mask The literal or wildcard pattern specifying which login server(s) to match. If NULL or unspecified, all login servers are matched.
    * @param P_Start_Time        The earliest login time to match, in Java millseconds. If NULL or unspecified, no earliest limit will be used.
    * @param P_End_Time          The latest login time to match, in Java millseconds. If NULL or unspecified, no latest limit will be used.
    * @param P_Max_Count         The maximum number of matches to retrieve. A non-negative number indicates the first P_Max_Count matches in the time window will be retrieved. A negative number indicates the last -P_Max_Count matches in the time window will be retrieved. If NULL or unspecified, no maximum count will be enforced.
    * @param P_Office_Id_Mask    The literal or wildcard pattern specifying which office id(s) to match. If NULL or unspecified, the current session user's default office is used.
    *
    * @return A cursor with the following fields, ordered by login_time (column 2)
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">uuid</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The unique application instance identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">login_time</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The login time for the application, in Java milliseconds</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">logout_time</td>
    *     <td class="descr">varchar2(191)</td>
    *     <td class="descr">The logout time for the application or time the application was found to be disconnected, in Java milliseconds</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office of the user running the application</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">user_name</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The user running the application</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">app_name</td>
    *     <td class="descr">varchar2(64)</td>
    *     <td class="descr">The application name</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">host_name</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The name of the system the user is running the application on</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">normal_logout</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag (T/F) that specifies whether the application logged out normally (T) or was disconnected before logging off (F)</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">login_server</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">The URL of the login server that processed the application's login</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">session_ids</td>
    *     <td class="descr">varchar(256)</td>
    *     <td class="descr">A comma-separated list of currently-connected session ids for the application    </td>
    *   </tr>
    *</table>
    */
   function get_application_login_f(
      p_user_name_mask    in varchar2 default null,
      p_app_name_mask     in varchar2 default null,
      p_host_name_mask    in varchar2 default null,
      p_login_server_mask in varchar2 default null,
      p_start_time        in integer  default null,
      p_end_time          in integer  default null,
      p_max_count         in integer  default null,
      p_office_id_mask    in varchar2 default null)
      return sys_refcursor;
   /**
    * Sets the login info for a new application instance, returning the previous login and logout times for the same user and application. The application login time is set to the current time.
    *
    * @param p_uuid             The UUID (session key) that uniquely identifies the application instance
    * @param p_last_login_time  The most recent login time for the same user and application in this database
    * @param p_last_logout_time The most recent logout time for the same user and application in this database. This may be for a different instance than the one for p_last_login time if the application is logged in multiple times simultaneously
    * @param p_user_name        The name of the user running the application
    * @param p_app_name         The name of the application
    * @param p_host_name        The name of the system the user is running the application on
    * @param p_login_server     The URL of the login server handling the login
    * @param p_office_id        The office of the user running the application
    */
   procedure set_application_login(
      p_uuid             out varchar2,
      p_last_login_time  out integer,
      p_last_logout_time out integer,
      p_user_name        in  varchar2,
      p_app_name         in  varchar2,
      p_host_name        in  varchar2,
      p_login_server     in  varchar2,
      p_office_id        in  varchar2);
   /**
    * Sets the login info for a new application instance, returning the previous login and logout times for the same user and application. The application login time is set to the current time.
    *
    * @param p_uuid             The UUID (session key) that uniquely identifies the application instance
    * @param p_user_name        The name of the user running the application
    * @param p_last_login_time  The most recent login time for the same user and application in this database
    * @param p_last_logout_time The most recent logout time for the same user and application in this database. This may be for a different instance than the one for p_last_login time if the application is logged in multiple times simultaneously
    * @param p_edipi            The DoD Electronic Data Interchange Personal Identifier from the user's CAC
    * @param p_user_name        The name of the user running the application
    * @param p_app_name         The name of the application
    * @param p_host_name        The name of the system the user is running the application on
    * @param p_login_server     The URL of the login server handling the login
    * @param p_office_id        The office of the user running the application
    */
   procedure set_application_login(
      p_uuid             out varchar2,
      p_username         out varchar2,
      p_last_login_time  out integer,
      p_last_logout_time out integer,
      p_edipi            in  integer,
      p_app_name         in  varchar2,
      p_host_name        in  varchar2,
      p_login_server     in  varchar2,
      p_office_id        in  varchar2);
   /**
    * Sets the logout time for an application instance, returning the instance's login time and the previous instance's logout time
    *
    * @param p_last_login_time  The login time for the specified application instance
    * @param p_last_logout_time The last logout time for a previous application instance for the same user and application in this database
    * @param p_uuid             The unique application instance identifier
    */
   procedure set_application_logout(
      p_last_login_time  out integer,
      p_last_logout_time out integer,
      p_uuid             in  varchar2);
   /**
    * Retrieves the currently-connected database sessions for the specifed application instance
    *
    * @param p_uuid The unique application instance identifier
    */
   function get_application_sessions(
      p_uuid in varchar2)
      return varchar2;
   /**
    * Marks the current database session to be associated with the specified application instance. Can be called from multiple sessions for the same application instance.
    *
    * @param p_uuid        The unique application instance identifier
    * @param p_session_key The session key for the CAC login session. For username/password logins the session key must be NULL.
    */
   procedure set_application_session(
      p_uuid        in varchar2,
      p_session_key in varchar2 default null);
   /**
    * Marks applications as logged all application instances whose sessions have all been disconnected withtout logging out. Sets logout_time to current time and normal_logout to 'F'
    */
   procedure logout_dead_app_logins;
   -- not documented
   function current_session_ids
      return number_tab_t;
   /**
    * @return a suitable name for identifying this database, regardless of whether it is a container database
    */
   function get_db_name
      return varchar2;
   /**
    * @return the host address or name for identifying this database. If the host address is detected to be ::1 or localhost, then the host name will be returned
    */
   function get_db_host
      return varchar2;
   /**
    * Sets the property CWMS/CWMSDB/logging.debug.dbms_output to 'T' or 'F' depending on p_state. The property can be used directly 
    * or via the output_debug_info function to determine whether debugging information should be output via dbms_output.
    *
    * @param p_state Whether debugging information should be output via dbms_output
    */
   procedure set_output_debug_info(
      p_state in boolean);
   /**
    * Test the property CWMS/CWMSDB/logging.debug.dbms_output to determine whether debugging information should be output via dbms_output
    * @return whether debugging information should be output via dbms_output
    */
   function output_debug_info
      return boolean;
END cwms_util;
/
set escape off
SHOW ERRORS;

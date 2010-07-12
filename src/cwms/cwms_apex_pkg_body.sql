SET define on
@@defines.sql
--define cwms_schema=CWMS_20
/* Formatted on 4/21/2009 11:15:31 AM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY cwms_apex
AS
    TYPE varchar2_t
    IS
        TABLE OF VARCHAR2 (32767)
            INDEX BY BINARY_INTEGER;




 function hex_to_decimal
--this function is based on one by Connor McDonald
--http://www.jlcomp.demon.co.uk/faq/base_convert.html
( p_hex_str in varchar2 ) return number
is
v_dec   number;
v_hex   varchar2(16) := '0123456789ABCDEF';
begin
v_dec := 0;
for indx in 1 .. length(p_hex_str)
loop
v_dec := v_dec * 16 + instr(v_hex,upper(substr(p_hex_str,indx,1)))-1;
end loop;
return v_dec;
end hex_to_decimal;



    PROCEDURE aa1 (p_string IN VARCHAR2)
    IS
    BEGIN
--        INSERT INTO aa1 (stringstuff)
--          VALUES   (p_string
--                      );
--
--        COMMIT;
        NULL;
    END;

    -- Private functions --{{{
    PROCEDURE delete_collection (                                                      --{{{
                                          -- Delete the collection if it exists
                                          p_collection_name IN VARCHAR2)
    IS
    BEGIN
        IF (apex_collection.collection_exists (p_collection_name))
        THEN
            apex_collection.delete_collection (p_collection_name);
        END IF;
    END delete_collection;                                                                 --}}}

    --
    --
    PROCEDURE csv_to_array (                                                             --{{{
                                    -- Utility to take a CSV string, parse it into a PL/SQL table
                                    -- Note that it takes care of some elements optionally enclosed
                                    -- by double-quotes.
                                    p_csv_string     IN      VARCHAR2,
                                    p_array                 OUT wwv_flow_global.vc_arr2,
                                    p_separator      IN      VARCHAR2:= ','
                                  )
    IS
        l_start_separator                 PLS_INTEGER := 0;
        l_stop_separator                    PLS_INTEGER := 0;
        l_length                             PLS_INTEGER := 0;
        l_idx                                 BINARY_INTEGER := 0;
        l_quote_enclosed                    BOOLEAN := FALSE;
        l_offset                             PLS_INTEGER := 1;
        l_cwms_id                            VARCHAR2 (183);
    --   csv   p_array
    --   shef_id ........... 1   2
    --   shef_pe_code ...... 2   3
    --   shef_tse_code ..... 3   4
    --   shef_duration_code   4  5
    --   cwms_ts_id ........ 5-10   1
    --   unit_sys .......... 11  7
    --   units ............. 12  6
    --   tz ................ 13  8
    --   dltime ............ 14  9
    --   offset ............ 15  10
    --   snap forw ......... 16  12
    --   snap back ......... 17  11


    BEGIN
        cwms_apex.aa1 (
            '>>cwms_apex.csv_to_array<< p_csv_string: ' || p_csv_string
        );
        l_length := NVL (LENGTH (p_csv_string), 0);

        IF (l_length <= 0)
        THEN
            RETURN;
        END IF;

        LOOP
            l_idx := l_idx + 1;

            cwms_apex.aa1 ('>>cwms_apex.csv_to_array<< l_idx: ' || l_idx);

            l_quote_enclosed := FALSE;

            IF SUBSTR (p_csv_string, l_start_separator + 1, 1) = '"'
            THEN
                l_quote_enclosed := TRUE;
                l_offset := 2;
                l_stop_separator :=
                    INSTR (p_csv_string, '"', l_start_separator + l_offset, 1);
            ELSE
                l_offset := 1;
                l_stop_separator :=
                    INSTR (p_csv_string,
                             p_separator,
                             l_start_separator + l_offset,
                             1
                            );
            END IF;

            IF l_stop_separator = 0
            THEN
                l_stop_separator := l_length + 1;
            END IF;

            ------
            -------
            --------




            p_array (l_idx) :=
                (SUBSTR (p_csv_string,
                            l_start_separator + l_offset,
                            (l_stop_separator - l_start_separator - l_offset)
                          ));


            ---------
            --------
            ------
            --   p_array (l_idx)   :=
            --   (SUBSTR (p_csv_string,
            --   l_start_separator + l_offset,
            --   (l_stop_separator - l_start_separator - l_offset)
            --   ));
            EXIT WHEN l_stop_separator >= l_length;

            IF l_quote_enclosed
            THEN
                l_stop_separator := l_stop_separator + 1;
            END IF;

            l_start_separator := l_stop_separator;
        END LOOP;
    END csv_to_array;                                                                      --}}}


    ---
    -- Utility to take a criteria file string, parse it into a PL/SQL table
    --
    PROCEDURE crit_to_array (
        p_criteria_record   IN        VARCHAR2,
        p_comment                  OUT VARCHAR2,
        p_array                      OUT wwv_flow_global.vc_arr2
    )
    IS
    BEGIN
        BEGIN
            cwms_shef.parse_criteria_record (
                p_shef_id                  => p_array (2),
                p_shef_pe_code           => p_array (3),
                p_shef_tse_code          => p_array (4),
                p_shef_duration_code   => p_array (5),
                p_units                      => p_array (6),
                p_unit_sys                  => p_array (7),
                p_tz                          => p_array (8),
                p_dltime                   => p_array (9),
                p_int_offset              => p_array (10),
                p_int_backward           => p_array (11),
                p_int_forward              => p_array (12),
                p_cwms_ts_id              => p_array (1),
                p_comment                  => p_comment,
                p_criteria_record       => p_criteria_record
            );
        EXCEPTION
            WHEN OTHERS
            THEN
                p_comment :=
                    'ERROR: Format not recognized, cannot parse this line';
        END;
    END;

    --
    PROCEDURE get_records (p_blob IN BLOB, p_records OUT varchar2_t)         --{{{
    IS
        l_record_separator                VARCHAR2 (2) := CHR (13) || CHR (10);
        l_last                                INTEGER;
        l_current                            INTEGER;
    BEGIN
        -- Sigh, stupid DOS/Unix newline stuff. If HTMLDB has generated the file,
        -- it will be a Unix text file. If user has manually created the file, it
        -- will have DOS newlines.
        -- If the file has a DOS newline (cr+lf), use that
        -- If the file does not have a DOS newline, use a Unix newline (lf)
        IF (NVL (
                 DBMS_LOB.INSTR (p_blob,
                                      UTL_RAW.cast_to_raw (l_record_separator),
                                      1,
                                      1
                                     ),
                 0
             ) = 0)
        THEN
            l_record_separator := CHR (10);
        END IF;

        l_last := 1;

        LOOP
            l_current :=
                DBMS_LOB.INSTR (p_blob,
                                     UTL_RAW.cast_to_raw (l_record_separator),
                                     l_last,
                                     1
                                    );
            EXIT WHEN (NVL (l_current, 0) = 0);
            p_records (p_records.COUNT + 1) :=
                UTL_RAW.cast_to_varchar2 (
                    DBMS_LOB.SUBSTR (p_blob, l_current - l_last, l_last)
                );
            l_last := l_current + LENGTH (l_record_separator);
        END LOOP;
    END get_records;                                                                         --}}}

    --}}}
    -- Utility functions --{{{
    PROCEDURE parse_textarea (                                                          --{{{
                                      p_textarea             IN VARCHAR2,
                                      p_collection_name     IN VARCHAR2
                                     )
    IS
        l_index                                INTEGER;
        l_string                             VARCHAR2 (32767)
                := TRANSLATE (p_textarea, CHR (10) || CHR (13) || ' ,', '@@@@') ;
        l_element                            VARCHAR2 (100);
    BEGIN
        l_string := l_string || '@';
        htmldb_collection.create_or_truncate_collection (p_collection_name);

        LOOP
            l_index := INSTR (l_string, '@');
            EXIT WHEN NVL (l_index, 0) = 0;
            l_element := SUBSTR (l_string, 1, l_index - 1);

            IF (TRIM (l_element) IS NOT NULL)
            THEN
                apex_collection.add_member (p_collection_name, l_element);
            END IF;

            l_string := SUBSTR (l_string, l_index + 1);
        END LOOP;
    END parse_textarea;                                                                     --}}}

    --------------------------------------------------------------------------------
    PROCEDURE check_parsed_crit_file (p_collection_name IN VARCHAR2)
    IS
        l_count                                NUMBER;
    BEGIN
        cwms_apex.aa1 ('>>check_parsed_crit_file<< starting');

        --   INSERT INTO at_shef_decodes_gtemp
        --   SELECT   UPPER (c003 || '.' || c004 || '.' || c005 || '.' || c006) shef_spec, UPPER (c002) cwms_ts_id, c001 line_no,
        --   c003 shef_loc_id, c004 shef_pe_code, c005 shef_tse_code,
        --   c006 shef_dur_numeric, c007 shef_units, c009 shef_tz,
        --   c010 shef_dlt, c011 interval_utc_offset, c012 snap_backward,
        --   c013 snap_forward
        --   FROM apex_collections
        --   WHERE collection_name = p_collection_name;

        --   SELECT   COUNT ( * )
        --   INTO l_count
        --   FROM at_shef_decodes_gtemp;

        --   cwms_apex.aa1('>>check_parsed_crit_file<< at_shef_decodes_gtemp has '
        --   || l_count
        --   || ' rows.');
        cwms_apex.aa1 ('>>check_parsed_crit_file<< ending');
    END;

    --=============================================================================
    --=============================================================================
    --=============================================================================
    --------------------------------------------------------------------------------
    PROCEDURE parse_file (                                                                 --{{{
        p_file_name                   IN        VARCHAR2,
        p_collection_name           IN        VARCHAR2,
        p_error_collection_name   IN        VARCHAR2,
        p_headings_item              IN        VARCHAR2,
        p_columns_item               IN        VARCHAR2,
        p_ddl_item                      IN        VARCHAR2,
        p_number_of_records              OUT NUMBER,
        p_number_of_columns              OUT NUMBER,
        p_is_csv                       IN        VARCHAR2 DEFAULT 'T' ,
        p_db_office_id               IN        VARCHAR2,
        p_process_id                  IN        VARCHAR2
    )
    IS
        l_blob                                BLOB;
        l_records                            varchar2_t;
        l_record                             wwv_flow_global.vc_arr2;
        l_datatypes                         wwv_flow_global.vc_arr2;
        l_headings                            VARCHAR2 (4000);
        l_columns                            VARCHAR2 (4000);
        l_seq_id                             NUMBER;
        l_num_columns                        INTEGER;
        l_ddl                                 VARCHAR2 (4000);
        l_is_csv                             BOOLEAN;
        l_is_crit_file                     BOOLEAN;
        l_tmp                                 NUMBER;
        l_comment                            VARCHAR2 (128) := NULL;
        l_datastream                        VARCHAR2 (16);
        l_cwms_seq                            NUMBER;
        l_len                                 NUMBER;
        --
        l_rc                                    sys_refcursor;
        l_cwms_id_dup                        VARCHAR2 (183);
        l_shef_id_dup                        VARCHAR2 (183);
        --
        l_rc_rows                            sys_refcursor;
        l_row_num                            NUMBER;
        l_rows_msg                            VARCHAR2 (1000);
        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
    BEGIN
        IF cwms_util.is_true (NVL (p_is_csv, 'T'))
        THEN
            l_is_csv := TRUE;
            l_is_crit_file := FALSE;
        ELSE
            l_is_csv := FALSE;
            l_is_crit_file := TRUE;
        END IF;

        aa1 ('parse collection name: ' || p_collection_name);
        l_steps_per_commit :=
            TO_NUMBER (
                SUBSTR (p_process_id, (INSTR (p_process_id, '.', 1, 5) + 1))
            );
        l_cmt :=
                'ST='
            || LOCALTIMESTAMP
            || ';FILE='
            || p_file_name
            || ';STEPS='
            || l_steps_per_commit
            || ';CT=';
        cwms_properties.set_property ('PROCESS_STATUS',
                                                p_process_id,
                                                'Initiated',
                                                l_cmt || LOCALTIMESTAMP,
                                                p_db_office_id
                                              );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;

        --   IF (p_table_name IS NOT NULL)
        --   THEN
        --   BEGIN
        --   EXECUTE IMMEDIATE 'drop table ' || p_table_name;
        --   EXCEPTION
        --   WHEN OTHERS
        --   THEN
        --   NULL;
        --   END;

        --   l_ddl := 'create table ' || p_table_name || ' ' || v (p_ddl_item);
        --   apex_util.set_session_state ('P149_DEBUG', l_ddl);

        --   EXECUTE IMMEDIATE l_ddl;

        --   l_ddl :=
        --   'insert into '
        --   || p_table_name
        --   || ' '
        --   || 'select '
        --   || v (p_columns_item)
        --   || ' '
        --   || 'from htmldb_collections '
        --   || 'where seq_id > 1 and collection_name='''
        --   || p_collection_name
        --   || '''';
        --   apex_util.set_session_state ('P149_DEBUG',
        --   v ('P149_DEBUG') || '/' || l_ddl
        --   );

        --   EXECUTE IMMEDIATE l_ddl;

        --   RETURN;
        --   END IF;
        BEGIN
            SELECT    blob_content
              INTO    l_blob
              FROM    wwv_flow_files
             WHERE    name = p_file_name;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                raise_application_error (-20000,
                                                 'File not found, id=' || p_file_name
                                                );
        END;

        get_records (l_blob, l_records);

        IF (l_records.COUNT < 2)
        THEN
            raise_application_error (
                -20000,
                'File must have at least 2 ROWS, id=' || p_file_name
            );
        END IF;

        -- Initialize collection
        apex_collection.create_or_truncate_collection (p_collection_name);
        apex_collection.create_or_truncate_collection (p_error_collection_name);

        -- Get column headings and datatypes
        IF l_is_crit_file
        THEN
            cwms_apex.aa1 ('Get column headings and datatypes');
            l_record (1) := 'Line No.';
            l_datatypes (1) := 'number';
            l_record (2) := 'cwms_ts_id';
            l_datatypes (2) := 'varchar2(183)';
            l_record (3) := 'shef_id';
            l_datatypes (3) := 'varchar2(32)';
            l_record (4) := 'pe_code';
            l_datatypes (4) := 'varchar2(32)';
            l_record (5) := 'tse_code';
            l_datatypes (5) := 'varchar2(32)';
            l_record (6) := 'dur_code';
            l_datatypes (6) := 'varchar2(32)';
            l_record (7) := 'units';
            l_datatypes (7) := 'varchar2(32)';
            l_record (8) := 'unit_system';
            l_datatypes (8) := 'varchar2(32)';
            l_record (9) := 'tz';
            l_datatypes (9) := 'varchar2(32)';
            l_record (10) := 'dltime';
            l_datatypes (10) := 'varchar2(32)';
            l_record (11) := 'int_offset';
            l_datatypes (11) := 'varchar2(32)';
            l_record (12) := 'int_backward';
            l_datatypes (12) := 'varchar2(32)';
            l_record (13) := 'int_forward';
            l_datatypes (13) := 'varchar2(32)';
        ELSE
            csv_to_array (l_records (1), l_record);
            csv_to_array (l_records (2), l_datatypes);
        END IF;

        l_num_columns := l_record.COUNT;

        IF (l_num_columns > 50)
        THEN
            raise_application_error (
                -20000,
                'Max. of 50 columns allowed, id=' || p_file_name
            );
        END IF;

        p_number_of_columns := l_num_columns;

        -- Get column headings and names
        FOR i IN 1 .. l_record.COUNT
        LOOP
            l_headings := l_headings || ':' || l_record (i);
            l_columns := l_columns || ',c' || LPAD (i, 3, '0');
        END LOOP;

        l_headings := LTRIM (l_headings, ':');
        l_columns := LTRIM (l_columns, ',');
        apex_util.set_session_state (p_headings_item, l_headings);
        apex_util.set_session_state (p_columns_item, l_columns);

        -- Get datatypes
        FOR i IN 1 .. l_record.COUNT
        LOOP
            l_ddl := l_ddl || ',' || l_record (i) || ' ' || l_datatypes (i);
        END LOOP;

        l_ddl := '(' || LTRIM (l_ddl, ',') || ')';
        apex_util.set_session_state (p_ddl_item, l_ddl);
        -- Save data into specified collection
        p_number_of_records := l_records.COUNT;

        FOR i IN 1 .. p_number_of_records
        LOOP
            aa1 (l_records (i));

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.set_property (
                        'PROCESS_STATUS',
                        p_process_id,
                        'Processing: ' || i || ' of ' || p_number_of_records,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;

            IF l_is_crit_file
            THEN
                crit_to_array (l_records (i), l_comment, l_record);
            ELSE
                csv_to_array (l_records (i), l_record);
            END IF;

            IF INSTR (l_comment, 'ERROR') = 1
            THEN
                l_seq_id :=
                    apex_collection.add_member (p_error_collection_name, 'dummy');
                apex_collection.update_member_attribute (
                    p_collection_name   => p_error_collection_name,
                    p_seq                   => l_seq_id,
                    p_attr_number          => 1,
                    p_attr_value          => i
                );
                apex_collection.update_member_attribute (
                    p_collection_name   => p_error_collection_name,
                    p_seq                   => l_seq_id,
                    p_attr_number          => 2,
                    p_attr_value          => l_comment
                );
                apex_collection.update_member_attribute (
                    p_collection_name   => p_error_collection_name,
                    p_seq                   => l_seq_id,
                    p_attr_number          => 3,
                    p_attr_value          => l_records (i)
                );
            ELSIF INSTR (l_comment, 'COMMENT') = 1
            THEN
                NULL;                                              -- comment, so throw away.
            ELSE
                l_seq_id :=
                    apex_collection.add_member (p_collection_name, 'dummy');
                apex_collection.update_member_attribute (
                    p_collection_name   => p_collection_name,
                    p_seq                   => l_seq_id,
                    p_attr_number          => 1,
                    p_attr_value          => i
                );

                FOR j IN 1 .. l_record.COUNT
                LOOP
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => j + 1,
                        p_attr_value          => l_record (j)
                    );
                END LOOP;
            END IF;
        END LOOP;

        IF l_is_crit_file
        THEN
            BEGIN
                OPEN l_rc FOR
                    SELECT    cwms_id
                      FROM    (    SELECT    UPPER (c002) cwms_id,
                                                COUNT (UPPER (c002)) count_id
                                      FROM    apex_collections
                                     WHERE    collection_name = UPPER (p_collection_name)
                                 GROUP BY    UPPER (c002))
                     WHERE    count_id > 1;
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_tmp := 3;
            END;

            IF l_tmp != 3
            THEN
                LOOP
                    FETCH l_rc INTO                                  l_cwms_id_dup;

                    EXIT WHEN l_rc%NOTFOUND;

                    OPEN l_rc_rows FOR
                        SELECT    c001
                          FROM    apex_collections
                         WHERE    collection_name = UPPER (p_collection_name)
                                    AND UPPER (c002) = l_cwms_id_dup;

                    l_rows_msg := NULL;
                    l_tmp := 0;

                    LOOP
                        FETCH l_rc_rows INTO                                  l_row_num;

                        EXIT WHEN l_rc_rows%NOTFOUND;

                        IF l_tmp = 1
                        THEN
                            l_rows_msg := l_rows_msg || ', ';
                        END IF;

                        l_rows_msg := l_rows_msg || TO_CHAR (l_row_num);
                        l_tmp := 1;
                    END LOOP;

                    l_seq_id :=
                        apex_collection.add_member (p_error_collection_name,
                                                             'dummy'
                                                            );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 1,
                        p_attr_value          => l_rows_msg
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 2,
                        p_attr_value          => 'ERROR: cwms ts id is defined on multiple lines.'
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 3,
                        p_attr_value          => l_cwms_id_dup
                    );
                END LOOP;

                --
                --
                CLOSE l_rc;

                CLOSE l_rc_rows;

                OPEN l_rc FOR
                    SELECT    shef_id
                      FROM    (    SELECT    UPPER(    c003
                                                        || '.'
                                                        || c004
                                                        || '.'
                                                        || c005
                                                        || '.'
                                                        || c006)
                                                    shef_id,
                                                COUNT(UPPER(    c003
                                                                || '.'
                                                                || c004
                                                                || '.'
                                                                || c005
                                                                || '.'
                                                                || c006))
                                                    count_id
                                      FROM    apex_collections
                                     WHERE    collection_name = UPPER (p_collection_name)
                                 GROUP BY    UPPER(    c003
                                                        || '.'
                                                        || c004
                                                        || '.'
                                                        || c005
                                                        || '.'
                                                        || c006))
                     WHERE    count_id > 1;

                LOOP
                    FETCH l_rc INTO                                  l_shef_id_dup;

                    EXIT WHEN l_rc%NOTFOUND;

                    OPEN l_rc_rows FOR
                        SELECT    c001
                          FROM    apex_collections
                         WHERE    collection_name = UPPER (p_collection_name)
                                    AND UPPER(     c003
                                                 || '.'
                                                 || c004
                                                 || '.'
                                                 || c005
                                                 || '.'
                                                 || c006) = l_shef_id_dup;

                    l_rows_msg := NULL;
                    l_tmp := 0;

                    LOOP
                        FETCH l_rc_rows INTO                                  l_row_num;

                        EXIT WHEN l_rc_rows%NOTFOUND;

                        IF l_tmp = 1
                        THEN
                            l_rows_msg := l_rows_msg || ', ';
                        END IF;

                        l_rows_msg := l_rows_msg || l_row_num;
                        l_tmp := 1;
                    END LOOP;

                    l_seq_id :=
                        apex_collection.add_member (p_error_collection_name,
                                                             'dummy'
                                                            );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 1,
                        p_attr_value          => l_rows_msg
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 2,
                        p_attr_value          => 'ERROR: SHEF id is defined on multiple lines.'
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 3,
                        p_attr_value          => l_shef_id_dup
                    );
                END LOOP;
            END IF;
        END IF;

        --   IF l_is_crit_file
        --   THEN
        --   cwms_shef.delete_data_stream (l_datastream, 'T', 'CWMS');
        --   END IF;

        --   DELETE FROM wwv_flow_files
        --   WHERE NAME = p_file_name;
        SELECT    COUNT ( * )
          INTO    l_seq_id
          FROM    apex_collections
         WHERE    collection_name = p_collection_name;

        cwms_properties.set_property (
            'PROCESS_STATUS',
            p_process_id,
            'Completed ' || p_number_of_records || ' records',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );

        aa1(     'parse collection name: '
             || p_collection_name
             || ' Row count: '
             || l_seq_id);
    END;

    --=============================================================================
    --=============================================================================
    --=============================================================================

    --
    --  example:..
    --   desired result is either:
    --   if p_expr_value is equal to the p_expr_value_test  -
    --   then the string:      -
    --   ' 1 = 1 '   is returned                                       -
    --   else the string returned is...
    --   ' p_column_id = p_expr_string '                            -
    --
    --   For exmple:
    --   get_equal_predicate('sub_parameter_id', ':P535_SUB_PARM', :P535_SUB_PARM, '%');   -
    --   if :P535_SUB_PARM is '%' then....
    --   " 1=1 "  is returned.
    --
    --   if :P535_SUB_PARM is not '%' then...
    --   " sub_parameter_id = :P535_SUB_PARM " is returned.
    --   NOTE: quotes are not part of the string - there is a leading and trailing space character.
    --
    FUNCTION get_equal_predicate (p_column_id           IN VARCHAR2,
                                            p_expr_string          IN VARCHAR2,
                                            p_expr_value          IN VARCHAR2,
                                            p_expr_value_test   IN VARCHAR2
                                          )
        RETURN VARCHAR2
    IS
        l_return_predicate                VARCHAR2 (100) := ' 1=1 ';
        l_column_id                         VARCHAR2 (31) := TRIM (p_column_id);
    BEGIN
        IF p_expr_value != p_expr_value_test
        THEN
            l_return_predicate :=
                ' ' || l_column_id || ' = ''' || TRIM (p_expr_value) || ''' ';
        ELSIF p_expr_value IS NULL
        THEN
            l_return_predicate := ' ' || l_column_id || ' IS NULL ';
        END IF;

        RETURN l_return_predicate;
    END;

    FUNCTION get_primary_db_office_id
        RETURN VARCHAR2
    IS
    BEGIN
        RETURN cwms_util.user_office_id;
    END get_primary_db_office_id;



    --=============================================================================
    --=============================================================================
    --=============================================================================

    PROCEDURE store_parsed_crit_file (
        p_parsed_collection_name        IN VARCHAR2,
        p_store_err_collection_name    IN VARCHAR2,
        p_loc_group_id                     IN VARCHAR2,
        p_data_stream_id                    IN VARCHAR2,
        p_db_office_id                     IN VARCHAR2 DEFAULT NULL ,
        p_unique_process_id                IN VARCHAR2
    )
    IS
        l_parsed_rows                        NUMBER;
        l_shef_duration_code             VARCHAR2 (5);
        l_line_no                            VARCHAR2 (32);
        l_cwms_ts_id                        VARCHAR2 (200);
        l_shef_id                            VARCHAR2 (32);
        l_pe_code                            VARCHAR2 (32);
        l_tse_code                            VARCHAR2 (32);
        l_dur_code                            VARCHAR2 (32);
        l_units                                VARCHAR2 (32);
        l_unit_system                        VARCHAR2 (32);
        l_tz                                    VARCHAR2 (32);
        l_dltime                             VARCHAR2 (32);
        l_int_offset                        VARCHAR2 (32);
        l_int_backward                     VARCHAR2 (32);
        l_int_forward                        VARCHAR2 (32);
        l_min                                 NUMBER;
        l_max                                 NUMBER;
        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
    BEGIN
        aa1('store_parsed_crit_file - collection name: '
             || p_parsed_collection_name);

        SELECT    COUNT ( * ), MIN (seq_id), MAX (seq_id)
          INTO    l_parsed_rows, l_min, l_max
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name;

        aa1(     'l_parsed_rows = '
             || l_parsed_rows
             || ' min '
             || l_min
             || ' max '
             || l_max);

        l_steps_per_commit :=
            TO_NUMBER(SUBSTR (p_unique_process_id,
                                    (INSTR (p_unique_process_id, '.', 1, 5) + 1)
                                  ));
        l_cmt :=
            'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
        cwms_properties.set_property ('PROCESS_STATUS',
                                                p_unique_process_id,
                                                'Initiated',
                                                l_cmt || LOCALTIMESTAMP,
                                                p_db_office_id
                                              );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;

        FOR i IN 1 .. l_parsed_rows
        LOOP
            aa1 ('looping: ' || i);

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.set_property (
                        'PROCESS_STATUS',
                        p_unique_process_id,
                        'Processing: ' || i || ' of ' || l_parsed_rows,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;


            SELECT    c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
                        c011, c012, c013
              INTO    l_line_no, l_cwms_ts_id, l_shef_id, l_pe_code, l_tse_code,
                        l_dur_code, l_units, l_unit_system, l_tz, l_dltime,
                        l_int_offset, l_int_backward, l_int_forward
              FROM    apex_collections
             WHERE    collection_name = p_parsed_collection_name AND seq_id = i;

            -- convert duration numeric to duration code
            BEGIN
                SELECT    shef_duration_code || shef_duration_numeric
                  INTO    l_shef_duration_code
                  FROM    cwms_shef_duration
                 WHERE    shef_duration_numeric = l_dur_code;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_shef_duration_code := 'V' || TRIM (l_dur_code);
            END;

            -- confert dltime to t or f
            IF l_dltime IS NOT NULL
            THEN
                IF l_dltime = 'false'
                THEN
                    l_dltime := 'F';
                ELSIF l_dltime = 'true'
                THEN
                    l_dltime := 'T';
                END IF;
            END IF;

            aa1(     'storing spec: '
                 || l_cwms_ts_id
                 || ' --datastream->'
                 || p_data_stream_id
                 || ' --shef id->'
                 || l_shef_id);
            --
            aa1(     'l_int_offset = '
                 || l_int_offset
                 || ' l_int_forward '
                 || l_int_forward
                 || ' l_int_backward '
                 || l_int_backward);
            --
            aa1 ('Calling cwms_shef.store_shef_spec');
            cwms_shef.store_shef_spec (
                p_cwms_ts_id                  => l_cwms_ts_id,
                p_data_stream_id              => p_data_stream_id,
                p_loc_group_id               => p_loc_group_id,
                p_shef_loc_id                  => l_shef_id,
                -- normally use loc_group_id
                p_shef_pe_code               => l_pe_code,
                p_shef_tse_code              => l_tse_code,
                p_shef_duration_code       => l_shef_duration_code,
                p_shef_unit_id               => l_units,
                p_time_zone_id               => l_tz,
                p_daylight_savings          => l_dltime,
                -- psuedo boolean.
                p_interval_utc_offset      => TO_NUMBER (l_int_offset),
                -- in minutes.
                p_snap_forward_minutes      => TO_NUMBER (l_int_forward),
                p_snap_backward_minutes   => TO_NUMBER (l_int_backward),
                p_ts_active_flag              => NULL,
                p_db_office_id               => p_db_office_id
            );
        END LOOP;

        cwms_properties.set_property (
            'PROCESS_STATUS',
            p_unique_process_id,
            'Completed ' || l_parsed_rows || ' records',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );
    END;

    --=============================================================================
    --=============================================================================
    --=============================================================================


    PROCEDURE store_parsed_crit_csv_file (
        p_parsed_collection_name        IN VARCHAR2,
        p_store_err_collection_name    IN VARCHAR2,
        p_loc_group_id                     IN VARCHAR2,
        p_data_stream_id                    IN VARCHAR2,
        p_db_office_id                     IN VARCHAR2 DEFAULT NULL ,
        p_unique_process_id                IN VARCHAR2
    )
    IS
        l_parsed_rows                        NUMBER;
        l_shef_duration_code             VARCHAR2 (5);
        l_line_no                            VARCHAR2 (32);
        l_cwms_ts_id                        VARCHAR2 (200);
        l_shef_id                            VARCHAR2 (32);
        l_pe_code                            VARCHAR2 (32);
        l_tse_code                            VARCHAR2 (32);
        l_dur_code                            VARCHAR2 (32);
        l_location_id                        VARCHAR2 (32);
        l_parameter_id                     VARCHAR2 (32);
        l_type_id                            VARCHAR2 (32);
        l_interval_id                        VARCHAR2 (32);
        l_duration_id                        VARCHAR2 (32);
        l_version_id                        VARCHAR2 (32);
        l_units                                VARCHAR2 (32);
        l_unit_system                        VARCHAR2 (32);
        l_tz                                    VARCHAR2 (32);
        l_dltime                             VARCHAR2 (32);
        l_int_offset                        VARCHAR2 (32);
        l_int_backward                     VARCHAR2 (32);
        l_int_forward                        VARCHAR2 (32);
        l_active                             VARCHAR2 (32);
        l_office                             VARCHAR2 (32);
        l_min                                 NUMBER;
        l_max                                 NUMBER;
        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
    BEGIN
        aa1('store_parsed_crit_csv_file - collection name: '
             || p_parsed_collection_name);

        SELECT    COUNT ( * ), MIN (seq_id), MAX (seq_id)
          INTO    l_parsed_rows, l_min, l_max
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name;

        aa1(     'l_parsed_rows = '
             || l_parsed_rows
             || ' min '
             || l_min
             || ' max '
             || l_max);

        l_steps_per_commit :=
            TO_NUMBER(SUBSTR (p_unique_process_id,
                                    (INSTR (p_unique_process_id, '.', 1, 5) + 1)
                                  ));
        l_cmt :=
            'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
        cwms_properties.set_property ('PROCESS_STATUS',
                                                p_unique_process_id,
                                                'Initiated',
                                                l_cmt || LOCALTIMESTAMP,
                                                p_db_office_id
                                              );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;

        --=======  Start at 2 to skip Heading
        FOR i IN 2 .. l_parsed_rows
        LOOP
            aa1 ('looping: ' || i);

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.set_property (
                        'PROCESS_STATUS',
                        p_unique_process_id,
                        'Processing: ' || i || ' of ' || l_parsed_rows,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;


            SELECT    c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
                        c011, c012, c013, c014, c015, c016, c017, c018, c019
              INTO    l_line_no, l_shef_id, l_pe_code, l_tse_code, l_dur_code,
                        l_location_id, l_parameter_id, l_type_id, l_interval_id,
                        l_duration_id, l_version_id, l_tz, l_dltime, l_units,
                        l_int_offset, l_int_forward, l_int_backward, l_active,
                        l_office
              FROM    apex_collections
             WHERE    collection_name = p_parsed_collection_name AND seq_id = i;

            -- convert duration numeric to duration code
            BEGIN
                SELECT    shef_duration_code || shef_duration_numeric
                  INTO    l_shef_duration_code
                  FROM    cwms_shef_duration
                 WHERE    shef_duration_numeric = l_dur_code;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_shef_duration_code := 'V' || TRIM (l_dur_code);
            END;

            -- confert dltime to t or f
            IF l_dltime IS NOT NULL
            THEN
                IF l_dltime = 'false'
                THEN
                    l_dltime := 'F';
                ELSIF l_dltime = 'true'
                THEN
                    l_dltime := 'T';
                END IF;
            END IF;

            -- pack up cwms ts id  =======================================================
            l_cwms_ts_id :=
                    l_location_id
                || '.'
                || l_parameter_id
                || '.'
                || l_type_id
                || '.'
                || l_interval_id
                || '.'
                || l_duration_id
                || '.'
                || l_version_id;

            aa1(     'storing spec: '
                 || l_cwms_ts_id
                 || ' --datastream->'
                 || p_data_stream_id
                 || ' --shef id->'
                 || l_shef_id);
            --
            aa1(     'l_int_offset = '
                 || l_int_offset
                 || ' l_int_forward '
                 || l_int_forward
                 || ' l_int_backward '
                 || l_int_backward);

            --
            IF (l_int_offset = 'N/A')
            THEN
                l_int_offset := NULL;
            END IF;

            IF (l_int_offset = 'Undefined')
            THEN
                l_int_offset := NULL;
            END IF;

            aa1 ('Calling cwms_shef.store_shef_spec');
            cwms_shef.store_shef_spec (
                p_cwms_ts_id                  => l_cwms_ts_id,
                p_data_stream_id              => p_data_stream_id,
                p_loc_group_id               => p_loc_group_id,
                p_shef_loc_id                  => l_shef_id,
                -- normally use loc_group_id
                p_shef_pe_code               => l_pe_code,
                p_shef_tse_code              => l_tse_code,
                p_shef_duration_code       => l_shef_duration_code,
                p_shef_unit_id               => l_units,
                p_time_zone_id               => l_tz,
                p_daylight_savings          => l_dltime,
                -- psuedo boolean.
                p_interval_utc_offset      => TO_NUMBER (TRIM (l_int_offset)),
                -- in minutes.
                p_snap_forward_minutes      => TO_NUMBER (TRIM (l_int_forward)),
                p_snap_backward_minutes   => TO_NUMBER (TRIM (l_int_backward)),
                p_ts_active_flag              => l_active,
                p_db_office_id               => p_db_office_id
            );
        END LOOP;

        cwms_properties.set_property (
            'PROCESS_STATUS',
            p_unique_process_id,
            'Completed ' || l_parsed_rows || ' records',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );
    END;

    --=============================================================================
    --=============================================================================
    --=============================================================================

    PROCEDURE store_parsed_loc_short_file (
        p_parsed_collection_name        IN VARCHAR2,
        p_store_err_collection_name    IN VARCHAR2,
        p_db_office_id                     IN VARCHAR2 DEFAULT NULL ,
        p_unique_process_id                IN VARCHAR2
    )
    IS
        l_location_id                        VARCHAR2 (200);
        l_public_name                        VARCHAR2 (200);
        l_county_name                        VARCHAR2 (200);
        l_state_initial                    VARCHAR2 (20);
        l_active                             VARCHAR2 (10);
        l_ignorenulls                        VARCHAR2 (1);
        l_parsed_rows                        NUMBER;
        l_line_no                            VARCHAR2 (32);
        l_min                                 NUMBER;
        l_max                                 NUMBER;
        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
    BEGIN
        aa1('store_parsed_loc_short_file - collection name: '
             || p_parsed_collection_name);

        l_steps_per_commit :=
            TO_NUMBER(SUBSTR (p_unique_process_id,
                                    (INSTR (p_unique_process_id, '.', 1, 5) + 1)
                                  ));
        l_cmt :=
            'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
        cwms_properties.set_property ('PROCESS_STATUS',
                                                p_unique_process_id,
                                                'Initiated',
                                                l_cmt || LOCALTIMESTAMP,
                                                p_db_office_id
                                              );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;

        SELECT    COUNT ( * ), MIN (seq_id), MAX (seq_id)
          INTO    l_parsed_rows, l_min, l_max
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name;

        aa1(     'l_parsed_rows = '
             || l_parsed_rows
             || ' min '
             || l_min
             || ' max '
             || l_max);

        -- Start at 2 to skip first line of column titles
        FOR i IN 2 .. l_parsed_rows
        LOOP
            aa1 ('looping: ' || i);

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.set_property (
                        'PROCESS_STATUS',
                        p_unique_process_id,
                        'Processing: ' || i || ' of ' || l_parsed_rows,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;


            SELECT    c001, c002, c003, c004, c005, c006
              INTO    l_line_no, l_location_id, l_public_name, l_county_name,
                        l_state_initial, l_active
              FROM    apex_collections
             WHERE    collection_name = p_parsed_collection_name AND seq_id = i;

            aa1 ('storing locs: ' || l_location_id);
            --
            cwms_loc.store_location (p_location_id      => l_location_id,
                                             p_public_name      => l_public_name,
                                             p_county_name      => l_county_name,
                                             p_state_initial     => l_state_initial,
                                             p_active             => l_active,
                                             p_ignorenulls      => 'T',
                                             p_db_office_id     => p_db_office_id
                                            );
        END LOOP;

        cwms_properties.set_property (
            'PROCESS_STATUS',
            p_unique_process_id,
            'Completed ' || l_parsed_rows || ' records',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );
    END;

    --=============================================================================
    --=============================================================================
    --=============================================================================
    PROCEDURE store_parsed_loc_full_file (
        p_parsed_collection_name        IN VARCHAR2,
        p_store_err_collection_name    IN VARCHAR2,
        p_db_office_id                     IN VARCHAR2 DEFAULT NULL ,
        p_unique_process_id                IN VARCHAR2
    )
    IS
        l_location_id                        VARCHAR2 (200);
        l_location_type                    VARCHAR2 (200);
        l_elevation                         NUMBER;
        l_elev_unit_id                     VARCHAR2 (200);
        l_vertical_datum                    VARCHAR2 (200);
        l_latitude                            NUMBER;
        l_lat_mins                            NUMBER;
        l_lat_secs                            NUMBER;
        l_longitude                         NUMBER;
        l_long_mins                         NUMBER;
        l_long_secs                         NUMBER;
        l_horizontal_datum                VARCHAR2 (200);
        l_public_name                        VARCHAR2 (200);
        l_long_name                         VARCHAR2 (200);
        l_description                        VARCHAR2 (200);
        l_time_zone_id                     VARCHAR2 (200);
        l_county_name                        VARCHAR2 (200);
        l_state_initial                    VARCHAR2 (200);
        l_active                             VARCHAR2 (200);
        l_ignorenulls                        VARCHAR2 (1);
        l_parsed_rows                        NUMBER;
        l_line_no                            VARCHAR2 (32);
        l_min                                 NUMBER;
        l_max                                 NUMBER;
        l_loc_id                             VARCHAR2 (32);
        l_location_kind_id        VARCHAR2 (32);
        l_map_label                 VARCHAR2 (50);
        l_published_latitude     NUMBER;
        l_published_longitude    NUMBER;
        l_bounding_office_id     VARCHAR2 (16);
        l_nation_id                 VARCHAR (48);
        l_nearest_city             VARCHAR2 (50);
        l_office_id_24             VARCHAR2 (32);
        l_office_id_26             VARCHAR2 (32);
        l_office_id_28             VARCHAR2 (32);
        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
    BEGIN
        aa1 (
            'store_parsed_loc_full_file - collection name: '
            || p_parsed_collection_name
        );
        l_steps_per_commit :=
            TO_NUMBER (
                SUBSTR (p_unique_process_id,
                                    (INSTR (p_unique_process_id, '.', 1, 5) + 1)
                         )
            );
        l_cmt :=
            'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
        cwms_properties.
        set_property ('PROCESS_STATUS',
                                                p_unique_process_id,
                                                'Initiated',
                                                l_cmt || LOCALTIMESTAMP,
                                                p_db_office_id
                                              );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;

        SELECT    COUNT ( * ), MIN (seq_id), MAX (seq_id)
          INTO    l_parsed_rows, l_min, l_max
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name;

        SELECT    c002, c024, c026, c028
          INTO    l_loc_id, l_office_id_24, l_office_id_26, l_office_id_28
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name AND seq_id = 1;

        aa1 (
                'l_parsed_rows = '
             || l_parsed_rows
             || ' min '
             || l_min
             || ' max '
            || l_max
        );

        --   Start at 2, Skip first line in file to bypass column headings
        FOR i IN 2 .. l_parsed_rows
        LOOP
            aa1 ('looping: ' || i);

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.
                    set_property ('PROCESS_STATUS',
                        p_unique_process_id,
                        'Processing: ' || i || ' of ' || l_parsed_rows,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;

            l_latitude := 0;
            l_longitude := 0;
            l_lat_mins := 0;
            l_long_mins := 0;
            l_lat_secs := 0;
            l_long_secs := 0;

            IF (TRIM (NVL (l_loc_id, 'XXX')) = 'Location ID'
                 AND TRIM (NVL (l_office_id_24, 'XXX')) = 'Office')
            THEN
                SELECT    c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
                            c011, c012, c013, c014, c015, c016, c017, c018, c019, c020,
                            c021, c022, c023
                  INTO    l_line_no, l_location_id, l_public_name, l_county_name,
                            l_state_initial, l_active, l_location_type,
                            l_vertical_datum, l_elevation, l_elev_unit_id,
                            l_horizontal_datum, l_latitude, l_longitude, l_time_zone_id,
                            l_long_name, l_description, l_location_kind_id, l_map_label,
                            l_published_latitude, l_published_longitude,
                            l_bounding_office_id, l_nation_id, l_nearest_city
                  FROM    apex_collections
                 WHERE    collection_name = p_parsed_collection_name AND seq_id = i;
            ELSIF (TRIM (NVL (l_loc_id, 'XXX')) = 'Location ID'
                     AND TRIM (NVL (l_office_id_26, 'XXX')) = 'Office')
            THEN
                SELECT    c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
                            c011, c012, c013, c014, c015, c016, c017, c018, c019, c020,
                            c021, c022, c023, c024, c025
                  INTO    l_line_no, l_location_id, l_public_name, l_county_name,
                            l_state_initial, l_active, l_location_type,
                            l_vertical_datum, l_elevation, l_elev_unit_id,
                            l_horizontal_datum, l_latitude, l_lat_mins, l_longitude,
                            l_long_mins, l_time_zone_id, l_long_name, l_description,
                            l_location_kind_id, l_map_label, l_published_latitude,
                            l_published_longitude, l_bounding_office_id, l_nation_id,
                            l_nearest_city
                  FROM    apex_collections
                 WHERE    collection_name = p_parsed_collection_name AND seq_id = i;
            ELSIF (TRIM (NVL (l_loc_id, 'XXX')) = 'Location ID'
                     AND TRIM (NVL (l_office_id_28, 'XXX')) = 'Office')
            THEN
                SELECT    c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
                            c011, c012, c013, c014, c015, c016, c017, c018, c019, c020,
                            c021, c022, c023, c024, c025, c026, c027
                  INTO    l_line_no, l_location_id, l_public_name, l_county_name,
                            l_state_initial, l_active, l_location_type,
                            l_vertical_datum, l_elevation, l_elev_unit_id,
                            l_horizontal_datum, l_latitude, l_lat_mins, l_lat_secs,
                            l_longitude, l_long_mins, l_long_secs, l_time_zone_id,
                            l_long_name, l_description, l_location_kind_id, l_map_label,
                            l_published_latitude, l_published_longitude,
                            l_bounding_office_id, l_nation_id, l_nearest_city
                  FROM    apex_collections
                 WHERE    collection_name = p_parsed_collection_name AND seq_id = i;
            ELSE
                cwms_err.raise ('ERROR', 'Unable to parse data!');
            END IF;

            l_latitude :=
                (ABS (l_latitude) + l_lat_mins / 60 + l_lat_secs / 3600)
                * SIGN (l_latitude);
            l_longitude :=
                (ABS (l_longitude) + l_long_mins / 60 + l_long_secs / 3600)
                * SIGN (l_longitude);
            aa1 ('storing locs: ' || l_location_id);
            --
            cwms_loc.
            store_location2 (l_location_id,
                                              l_location_type,
                                              l_elevation,
                                              l_elev_unit_id,
                                              l_vertical_datum,
                                              l_latitude,
                                              l_longitude,
                                              l_horizontal_datum,
                                              l_public_name,
                                              l_long_name,
                                              l_description,
                                              l_time_zone_id,
                                              l_county_name,
                                              l_state_initial,
                                              l_active,
                                  l_location_kind_id,
                                  l_map_label,
                                  l_published_latitude,
                                  l_published_longitude,
                                  l_bounding_office_id,
                                  l_nation_id,
                                  l_nearest_city,
                                              'F',
                                              p_db_office_id
                                             );
        END LOOP;

        cwms_properties.
        set_property ('PROCESS_STATUS',
            p_unique_process_id,
            'Completed ' || l_parsed_rows || ' records',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );
    END;
    --=============================================================================
    --=============================================================================
    --=============================================================================

    PROCEDURE store_parsed_loc_alias_file (
        p_parsed_collection_name        IN VARCHAR2,
        p_store_err_collection_name    IN VARCHAR2,
        p_db_office_id                     IN VARCHAR2 DEFAULT NULL ,
        p_unique_process_id                IN VARCHAR2
    )
    IS
        l_location_id                        VARCHAR2 (200);
        l_alias                                VARCHAR2 (200);
        l_group                                VARCHAR2 (200);
        l_ignorenulls                        VARCHAR2 (1);
        l_parsed_rows                        NUMBER;
        l_line_no                            VARCHAR2 (32);
        l_min                                 NUMBER;
        l_max                                 NUMBER;
        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
    BEGIN
        aa1('store_parsed_loc_alias_file - collection name: '
             || p_parsed_collection_name);

        l_steps_per_commit :=
            TO_NUMBER(SUBSTR (p_unique_process_id,
                                    (INSTR (p_unique_process_id, '.', 1, 5) + 1)
                                  ));
        l_cmt :=
            'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
        cwms_properties.set_property ('PROCESS_STATUS',
                                                p_unique_process_id,
                                                'Initiated',
                                                l_cmt || LOCALTIMESTAMP,
                                                p_db_office_id
                                              );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;


        SELECT    COUNT ( * ), MIN (seq_id), MAX (seq_id)
          INTO    l_parsed_rows, l_min, l_max
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name;

        aa1(     'l_parsed_rows = '
             || l_parsed_rows
             || ' min '
             || l_min
             || ' max '
             || l_max);

        -- Start at 2 to skip first line of column titles
        FOR i IN 2 .. l_parsed_rows
        LOOP
            aa1 ('looping: ' || i);

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.set_property (
                        'PROCESS_STATUS',
                        p_unique_process_id,
                        'Processing: ' || i || ' of ' || l_parsed_rows,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;


            SELECT    c001, c002, c003, c004
              INTO    l_line_no, l_location_id, l_alias, l_group
              FROM    apex_collections
             WHERE    collection_name = p_parsed_collection_name AND seq_id = i;

            aa1 ('storing locaa: ' || l_location_id);
            --
            cwms_loc.assign_loc_group (p_loc_category_id   => 'Agency Aliases',
                                                p_loc_group_id       => l_group,
                                                p_location_id          => l_location_id,
                                                p_loc_alias_id       => l_alias,
                                                p_db_office_id       => p_db_office_id
                                              );
        END LOOP;

        cwms_properties.set_property (
            'PROCESS_STATUS',
            p_unique_process_id,
            'Completed ' || l_parsed_rows || ' records',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );
    END;

    --=============================================================================
    --=============================================================================
    --=============================================================================

    PROCEDURE store_parsed_screen_base_file (
        p_parsed_collection_name        IN VARCHAR2,
        p_store_err_collection_name    IN VARCHAR2,
        p_db_office_id                     IN VARCHAR2 DEFAULT NULL ,
        p_unique_process_id                IN VARCHAR2
    )
    IS
        l_line_no                            VARCHAR2 (32);
        l_screening_id                     VARCHAR2 (32);
        l_screening_id_desc                VARCHAR2 (256);
        l_parameter_id                     VARCHAR2 (32);
        l_parameter_type_id                VARCHAR2 (32);
        l_duration_id                        VARCHAR2 (32);
        l_unit_id                            VARCHAR2 (32);
        l_range_active_flag                VARCHAR2 (10);
        l_range_active_flag_char        VARCHAR2 (1);
        l_range_reject_lo                 VARCHAR2 (32);
        l_range_question_lo                VARCHAR2 (32);
        l_range_question_hi                VARCHAR2 (32);
        l_range_reject_hi                 VARCHAR2 (32);
        l_db_office_id                     VARCHAR2 (32);

        l_ignorenulls                        VARCHAR2 (1);
        l_parsed_rows                        NUMBER;
        --l_line_no   VARCHAR2 (32);
        l_min                                 NUMBER;
        l_max                                 NUMBER;

        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
--        l_scrn_data                         "&cwms_schema"."SCREEN_CRIT_ARRAY" 

        l_scrn_data                         "&cwms_schema"."SCREEN_CRIT_ARRAY" 
                := screen_crit_array () ;
        l_d_m_data                            "&cwms_schema"."SCREEN_DUR_MAG_ARRAY"
                := screen_dur_mag_array () ;
        l_scn_cntl                            "&cwms_schema"."SCREENING_CONTROL_T";
        i_num                                 NUMBER;
        j_num                                 NUMBER;
    BEGIN
        aa1('store_parsed_loc_short_file - collection name: '
             || p_parsed_collection_name);

        l_steps_per_commit :=
            TO_NUMBER(SUBSTR (p_unique_process_id,
                                    (INSTR (p_unique_process_id, '.', 1, 5) + 1)
                                  ));
        l_cmt :=
            'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
        cwms_properties.set_property ('PROCESS_STATUS',
                                                p_unique_process_id,
                                                'Initiated',
                                                l_cmt || LOCALTIMESTAMP,
                                                p_db_office_id
                                              );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;

        SELECT    COUNT ( * ), MIN (seq_id), MAX (seq_id)
          INTO    l_parsed_rows, l_min, l_max
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name;

        aa1(     'l_parsed_rows = '
             || l_parsed_rows
             || ' min '
             || l_min
             || ' max '
             || l_max);

        -- Start at 2 to skip first line of column titles
        FOR i IN 2 .. l_parsed_rows
        LOOP
            aa1 ('looping: ' || i);

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.set_property (
                        'PROCESS_STATUS',
                        p_unique_process_id,
                        'Processing: ' || i || ' of ' || l_parsed_rows,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;


            SELECT    c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
                        c011, c012, c013
              INTO    l_line_no, l_screening_id, l_screening_id_desc,
                        l_parameter_id, l_parameter_type_id, l_duration_id,
                        l_unit_id, l_range_active_flag, l_range_reject_lo,
                        l_range_question_lo, l_range_question_hi, l_range_reject_hi,
                        l_db_office_id
              FROM    apex_collections
             WHERE    collection_name = p_parsed_collection_name AND seq_id = i;

            aa1 ('storing locs: ' || l_screening_id);

            --===================================================================================================
            BEGIN
                i_num := 1;
                j_num := 5;

                FOR i IN 1 .. i_num
                LOOP
                    FOR j IN 1 .. j_num
                    LOOP
                        l_d_m_data.EXTEND;
                    END LOOP;

                    --   l_d_m_data(1) := screen_dur_mag_type ('1Hour', 0,
                    --   :P1535_R_DUR_MAG_1H, 0, :P1535_Q_DUR_MAG_1H);
                    --   l_d_m_data(2) := screen_dur_mag_type ('3Hours', 0,
                    --   :P1535_R_DUR_MAG_3H, 0, :P1535_Q_DUR_MAG_3H);
                    --   l_d_m_data(3) := screen_dur_mag_type ('6Hours', 0,
                    --   :P1535_R_DUR_MAG_6H, 0, :P1535_Q_DUR_MAG_6H);
                    --   l_d_m_data(4) := screen_dur_mag_type ('12Hours', 0,
                    --   :P1535_R_DUR_MAG_12H, 0, :P1535_Q_DUR_MAG_12H);
                    --   l_d_m_data(5) := screen_dur_mag_type ('1Day', 0,
                    --   :P1535_R_DUR_MAG_24H, 0, :P1535_Q_DUR_MAG_24H);

                    l_d_m_data (1) :=
                        screen_dur_mag_type ('1Hour', 0, NULL, 0, NULL);
                    l_d_m_data (2) :=
                        screen_dur_mag_type ('3Hours', 0, NULL, 0, NULL);
                    l_d_m_data (3) :=
                        screen_dur_mag_type ('6Hours', 0, NULL, 0, NULL);
                    l_d_m_data (4) :=
                        screen_dur_mag_type ('12Hours', 0, NULL, 0, NULL);
                    l_d_m_data (5) :=
                        screen_dur_mag_type ('1Day', 0, NULL, 0, NULL);


                    l_scrn_data.EXTEND;
                    l_scrn_data (i) :=
                        screen_crit_type (1,
                                                1,
                                                l_range_reject_lo,
                                                l_range_reject_hi,
                                                l_range_question_lo,
                                                l_range_question_hi,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                l_d_m_data
                                              );
                --   :P1535_RATE_CHANGE_REJECT_RISE,
                --   :P1535_RATE_CHANGE_REJECT_FALL,
                --   :P1535_RATE_CHANGE_QUEST_RISE,
                --   :P1535_RATE_CHANGE_QUEST_FALL,
                --   :P1535_CONST_REJECT_DURATION,
                --   :P1535_CONST_REJECT_MIN,
                --   :P1535_CONST_REJECT_TOLERANCE,
                --   :P1535_CONST_REJECT_N_MISS,
                --   :P1535_CONST_QUEST_DURATION,
                --   :P1535_CONST_QUEST_MIN,
                --   :P1535_CONST_QUEST_TOLERANCE,
                --   :P1535_CONST_QUEST_N_MISS,

                END LOOP;

                -- decode(RANGE_ACTIVE_FLAG, ''T'', ''Active'', ''F'', ''In-active'', ''N'', ''Not Used'', '''', ''Not Used'')
                IF (l_range_active_flag = 'Active')
                THEN
                    l_range_active_flag_char := 'T';
                ELSIF (l_range_active_flag = 'In-active')
                THEN
                    l_range_active_flag_char := 'F';
                ELSIF (l_range_active_flag = 'Not Used')
                THEN
                    l_range_active_flag_char := 'N';
                ELSE
                    l_range_active_flag_char := NULL;
                END IF;

                l_scn_cntl :=
                    screening_control_t (l_range_active_flag_char, 'N', 'N', 'N');
                --   :P1535_STATUS_RATE_OF_CHANGE,
                --   :P1535_STATUS_CONSTANT_VALUE,
                --   :P1535_STATUS_DUR_MAG);

                cwms_vt.store_screening_criteria (
                    p_screening_id                         => l_screening_id,
                    p_unit_id                                => l_unit_id,
                    p_screen_crit_array                    => l_scrn_data,
                    p_rate_change_disp_interval_id    => NULL,
                    p_screening_control                    => l_scn_cntl,
                    p_store_rule                            => 'DELETE INSERT',
                    p_ignore_nulls                         => 'T',
                    p_db_office_id                         => l_db_office_id
                );
            END;
        --====================================================================================================

        END LOOP;

        cwms_properties.set_property (
            'PROCESS_STATUS',
            p_unique_process_id,
            'Completed ' || l_parsed_rows || ' records',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );
    END;

    --=============================================================================
    --=============================================================================
    --=============================================================================
    PROCEDURE parse_crit_file (                                                         --{{{
        p_file_name                   IN        VARCHAR2,
        p_collection_name           IN        VARCHAR2,
        p_error_collection_name   IN        VARCHAR2,
        p_headings_item              IN        VARCHAR2,
        p_columns_item               IN        VARCHAR2,
        p_ddl_item                      IN        VARCHAR2,
        p_number_of_records              OUT NUMBER,
        p_number_of_columns              OUT NUMBER,
        p_is_csv                       IN        VARCHAR2 DEFAULT 'T' ,
        p_db_office_id               IN        VARCHAR2,
        p_process_id                  IN        VARCHAR2
    )
    IS
        l_blob                                BLOB;
        l_records                            varchar2_t;
        l_record                             wwv_flow_global.vc_arr2;
        l_idx                                 NUMBER := 1;
        l_datatypes                         wwv_flow_global.vc_arr2;
        l_headings                            VARCHAR2 (4000);
        l_columns                            VARCHAR2 (4000);
        l_seq_id                             NUMBER;
        l_num_columns                        INTEGER;
        l_ddl                                 VARCHAR2 (4000);
        l_is_csv                             BOOLEAN;
        l_error_message                    VARCHAR2 (512);

        l_tmp                                 NUMBER;
        l_comment                            VARCHAR2 (128) := NULL;
        l_datastream                        VARCHAR2 (16);
        l_cwms_seq                            NUMBER;
        l_len                                 NUMBER;
        l_first_record                     NUMBER := 2;
        --
        l_rc                                    sys_refcursor;
        l_cwms_id_dup                        VARCHAR2 (183);
        l_shef_id_dup                        VARCHAR2 (183);
        --
        l_rc_rows                            sys_refcursor;
        l_row_num                            NUMBER;
        l_rows_msg                            VARCHAR2 (1000);
        l_cmt                                 VARCHAR2 (256);
        l_steps_per_commit                NUMBER;
        l_cwms_ts_id                        VARCHAR2 (183);
        l_cwms_ts_code                     NUMBER;

        l_unit_code                         NUMBER;
        l_base_parameter_code            NUMBER;
        l_base_parameter_id                VARCHAR2 (50);
        l_parameter_type_code            NUMBER;
        l_interval_code                    NUMBER;
        l_duration_code                    NUMBER;
        l_db_office_id                     VARCHAR2 (16)
                := cwms_util.get_db_office_id (p_db_office_id) ;
        l_abstract_param_id                VARCHAR2 (16);
        l_abstract_param_code            NUMBER;
        l_abstract_param_code_user     NUMBER;
        l_unit_code_en                     NUMBER;
        l_unit_code_si                     NUMBER;
        l_unit_id_en                        VARCHAR2 (16);
        l_unit_id_si                        VARCHAR2 (16);
    BEGIN
        DELETE FROM   gt_shef_decodes;

        IF cwms_util.is_true (NVL (p_is_csv, 'T'))
        THEN
            l_is_csv := TRUE;
        ELSE
            l_is_csv := FALSE;
            l_first_record := 1;
        END IF;

        aa1 ('>>parse_crit_file<< parse collection name: ' || p_collection_name
             );

        BEGIN
            SELECT    blob_content
              INTO    l_blob
              FROM    wwv_flow_files
             WHERE    name = p_file_name;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                raise_application_error (-20000,
                                                 'File not found, id=' || p_file_name
                                                );
        END;

        aa1 ('>>parse_crit_file<< blob w/filename read: ' || p_file_name);
        get_records (l_blob, l_records);

        p_number_of_records := l_records.COUNT;
        aa1('>>parse_crit_file<< number of records read in: '
             || p_number_of_records);

        IF (l_is_csv AND p_number_of_records < 2)
        THEN
            raise_application_error (
                -20000,
                'Your csv crit file contains less than two rows. 
                      A valid csv file must consist of a header row and
                      at least one crit line. File read: '
                || p_file_name
            );
        ELSIF (p_number_of_records < 1)
        THEN
            raise_application_error (
                -20000,
                'Your crit file appears to be empty. File read: ' || p_file_name
            );
        END IF;


        -- Get column headings and datatypes
        IF NOT l_is_csv
        THEN
            cwms_apex.aa1 ('Get column headings and datatypes');
            l_record (1) := 'Line No.';
            l_record (2) := 'cwms_ts_id';
            l_record (3) := 'shef_id';
            l_record (4) := 'pe_code';
            l_record (5) := 'tse_code';
            l_record (6) := 'dur_code';
            l_record (7) := 'units';
            l_record (8) := 'unit_system';
            l_record (9) := 'tz';
            l_record (10) := 'dltime';
            l_record (11) := 'int_offset';
            l_record (12) := 'int_backward';
            l_record (13) := 'int_forward';
        ELSE
            csv_to_array (l_records (1), l_record);
        END IF;

        l_num_columns := l_record.COUNT;
        aa1 ('>>parse_crit_file<< number of columns read in: ' || l_num_columns
             );

        IF (l_num_columns > 50)
        THEN
            raise_application_error (
                -20000,
                'Max. of 50 columns allowed, id=' || p_file_name
            );
        END IF;

        p_number_of_columns := l_num_columns;

        -- Get column headings and names
        FOR i IN 1 .. l_record.COUNT
        LOOP
            l_headings := l_headings || ':' || l_record (i);
            l_columns := l_columns || ',c' || LPAD (i, 3, '0');
        END LOOP;

        l_headings := LTRIM (l_headings, ':');
        l_columns := LTRIM (l_columns, ',');
        apex_util.set_session_state (p_headings_item, l_headings);
        apex_util.set_session_state (p_columns_item, l_columns);


        aa1 ('>>parse_crit_file<< entering grand loop');

        FOR i IN 2 .. p_number_of_records
        LOOP
            aa1 ('>>parse_crit_file<< l_records: ' || l_records (i));
            l_error_message := NULL;
            l_idx := l_idx + 1;

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.set_property (
                        'PROCESS_STATUS',
                        p_process_id,
                        'Processing: ' || i || ' of ' || p_number_of_records,
                        l_cmt || LOCALTIMESTAMP,
                        p_db_office_id
                    );
                    COMMIT;
                END IF;
            END IF;

            IF l_is_csv
            THEN
                csv_to_array (l_records (l_idx), l_record);
            ELSE
                crit_to_array (l_records (l_idx), l_comment, l_record);
            END IF;

            IF INSTR (l_comment, 'ERROR') = 1
            THEN
                l_seq_id :=
                    apex_collection.add_member (p_error_collection_name, 'dummy');
                apex_collection.update_member_attribute (
                    p_collection_name   => p_error_collection_name,
                    p_seq                   => l_seq_id,
                    p_attr_number          => 1,
                    p_attr_value          => i
                );
                apex_collection.update_member_attribute (
                    p_collection_name   => p_error_collection_name,
                    p_seq                   => l_seq_id,
                    p_attr_number          => 2,
                    p_attr_value          => l_comment
                );
                apex_collection.update_member_attribute (
                    p_collection_name   => p_error_collection_name,
                    p_seq                   => l_seq_id,
                    p_attr_number          => 3,
                    p_attr_value          => l_records (l_idx)
                );
            ELSIF INSTR (l_comment, 'COMMENT') = 1
            THEN
                NULL;                                              -- comment, so throw away.
            ELSE
                --   l_seq_id :=
                --   apex_collection.add_member (p_collection_name, 'dummy');
                --   apex_collection.update_member_attribute (
                --   p_collection_name => p_collection_name,
                --   p_seq => l_seq_id,
                --   p_attr_number  => 1,
                --   p_attr_value   => i
                --   );

                --   FOR j IN 1 .. l_record.COUNT
                --   LOOP
                --   apex_collection.update_member_attribute (
                --   p_collection_name => p_collection_name,
                --   p_seq => l_seq_id,
                --   p_attr_number  => j + 1,
                --   p_attr_value   => l_record (j)
                --   );
                --   END LOOP;
                l_cwms_ts_id :=
                        l_record (5)
                    || '.'
                    || l_record (6)
                    || '.'
                    || l_record (7)
                    || '.'
                    || l_record (8)
                    || '.'
                    || l_record (9)
                    || '.'
                    || l_record (10);

                BEGIN
                    l_cwms_ts_code :=
                        cwms_ts.get_ts_code (
                            p_cwms_ts_id => l_cwms_ts_id,
                            p_db_office_code => cwms_util.get_db_office_code (p_db_office_id)
                        );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_cwms_ts_code := NULL;
                END;

                --
                ---
                ---- Is the unit_id valid?...
                --
                BEGIN
                    l_unit_code := cwms_util.get_unit_code (l_record (12), NULL);

                    SELECT    a.abstract_param_code
                      INTO    l_abstract_param_code_user
                      FROM    cwms_unit a
                     WHERE    a.unit_code = l_unit_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_error_message :=
                                l_error_message
                            || ' **ERROR: Unrecognized Unit Id: '
                            || l_record (12);
                END;

                --
                ---
                ---- Is the base parameter valid?...
                --
                BEGIN
                    l_base_parameter_id := cwms_util.get_base_id (l_record (6));
                    l_base_parameter_code :=
                        cwms_ts.get_parameter_code (l_base_parameter_id,
                                                             NULL,
                                                             p_db_office_id,
                                                             'F'
                                                            );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_error_message :=
                            l_error_message
                            || ' **ERROR: The Parameter Id''s Base Parameter is not Recognized: '
                            || l_base_parameter_id;
                END;

                --
                ---
                ---- Is the parameter type valid?...
                BEGIN
                    l_parameter_type_code :=
                        cwms_ts.get_parameter_type_code (l_record (7));
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_error_message :=
                                l_error_message
                            || ' **ERROR: The Parameter Type Id is not Recognized: '
                            || l_record (7);
                END;

                --
                ---
                ---- Is the interval_id valid?"...
                BEGIN
                    SELECT    interval_code
                      INTO    l_interval_code
                      FROM    cwms_interval a
                     WHERE    UPPER (a.interval_id) = UPPER (TRIM (l_record (8)));
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        l_error_message :=
                                l_error_message
                            || ' **ERROR: The Interval Id is not Recognized: '
                            || l_record (8);
                END;


                --
                ---
                ---- Is the PE Code valid?...
                BEGIN
                    SELECT    abstract_param_code, abstract_param_id, unit_code_en,
                                unit_code_si, unit_id_en, unit_id_si
                      INTO    l_abstract_param_code, l_abstract_param_id,
                                l_unit_code_en, l_unit_code_si, l_unit_id_en,
                                l_unit_id_si
                      FROM    av_shef_pe_codes a
                     WHERE    shef_pe_code = UPPER (TRIM (l_record (4)))
                                AND db_office_id IN (l_db_office_id, 'CWMS');

                    IF l_abstract_param_code != l_abstract_param_code_user
                    THEN
                        l_error_message :=
                                l_error_message
                            || ' **ERROR: The unit you specified: '
                            || l_record (12)
                            || ' needs to be a unit of type '
                            || l_abstract_param_id
                            || '. Default units for this SHEF PE Code are either: '
                            || l_unit_id_en
                            || ' or '
                            || l_unit_id_si
                            || '.';
                    ELSIF l_unit_code NOT IN (l_unit_code_en, l_unit_code_si)
                    THEN
                        l_error_message :=
                                l_error_message
                            || ' **WARNING: The unit you specified: '
                            || l_record (12)
                            || ' is not a default unit for this SHEF PE Code, namely: '
                            || l_unit_id_en
                            || ' or '
                            || l_unit_id_si
                            || '. Please be sure your data is being recieved with this non-standard unit.';
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        l_error_message :=
                                l_error_message
                            || ' **ERROR: The SHEF PE Code:
        '
                            || l_record (4)
                            || ' is not Recognized';
                END;

                --
                ---
                ---- Is the duration_id valid?...
                BEGIN
                    SELECT    duration_code
                      INTO    l_duration_code
                      FROM    cwms_duration a
                     WHERE    UPPER (a.duration_id) = UPPER (TRIM (l_record (9)));
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        l_error_message :=
                            l_error_message
                            || '                       **ERROR: The Duration Id is not Recognized:
  '
                            || l_record (9);
                END;

                --
                ---
                ---- Is the shef_loc_id of proper length?"...
                l_len := LENGTH (l_record (1));

                IF l_len < 3 OR l_len > 8
                THEN
                    l_error_message :=
                        l_error_message
                        || '                     **ERROR: The SHEF Location Id is
        '
                        || l_len
                        || '                    characters long. It must be between 3 and 8 characters in
        length.
  ';
                END IF;

                BEGIN
                    INSERT INTO gt_shef_decodes (
                                                              line_number,
                                                              shef_loc_id,
                                                              shef_pe_code,
                                                              shef_tse_code,
                                                              shef_dur_numeric,
                                                              shef_spec,
                                                              location_id,
                                                              parameter_id,
                                                              base_parameter_code,
                                                              parameter_type_id,
                                                              parameter_type_code,
                                                              interval_id,
                                                              interval_code,
                                                              duration_id,
                                                              duration_code,
                                                              version,
                                                              cwms_ts_id,
                                                              cwms_ts_code,
                                                              --unit_system,
                                                              units,
                                                              unit_code,
                                                              shef_tz,
                                                              shef_dl_time,
                                                              interva_utc_offset,
                                                              interval_forward,
                                                              interval_backward,
                                                              active_flag,
                                                              unparsed_line
                                  )
                      VALUES   (
                                        l_idx,
                                        l_record (1),                      -- shef_location_id
                                        l_record (2),                            -- shef_pe_code
                                        l_record (3),                          -- shef_tse_code
                                        l_record (4),                      -- shef_dur_numeric
                                        UPPER(    l_record (1)
                                                || '.'
                                                || l_record (2)
                                                || '.'
                                                || l_record (3)
                                                || '.'
                                                || l_record (4)),                 -- shef_spec
                                        l_record (5),                             -- location_id
                                        l_record (6),                            -- parameter_id
                                        l_base_parameter_code,      -- base_parameter_code
                                        l_record (7),                     -- parameter_type_id
                                        l_parameter_type_code,      -- parameter_type_code
                                        l_record (8),                             -- interval_id
                                        l_interval_code,                      -- interval_code
                                        l_record (9),                             -- duration_id
                                        l_duration_code,                      -- duration_code
                                        l_record (10),                               -- version
                                        l_cwms_ts_id,                              -- cwms_ts_id
                                        l_cwms_ts_code,                        -- cwms_ts_code
                                        l_record (11),                          -- unit_system
                                        l_unit_code,                                -- unit_code
                                        l_record (12),                               -- unit_id
                                        l_record (13),                               -- shef_tz
                                        l_record (14),                   -- shef_dl_time T/F
                                        l_record (15),               -- interval_utc_offset
                                        l_record (16),                   -- interval_forward
                                        l_record (17),                  -- interval_backward
--                                        l_record (18),                          -- active_flag
                                        l_records (l_idx)                   -- unparsed line
                                  );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        aa1('                      >>parse_crit_file<< failed to store:
  '
                             || l_records (l_idx));
                        aa1('                        >>parse_crit_file<<
  '
                             || SQLERRM);
                        l_error_message := SQLERRM;

                        INSERT INTO gt_shef_decodes (
                                                                  line_number,
                                                                  unparsed_line,
                                                                  error_msg
                                      )
                          VALUES   (l_idx, l_records (l_idx),          -- unparsed line
                                                                         l_error_message
                                      );
                --   INSERT INTO gt_parse_errors (
                --                                      line_number,
                --                                      error_msg,
                --                                      unparsed_line
                --         )
                --   VALUES   (l_idx, l_error_message, l_records (l_idx)
                --         );
                END;
            END IF;
        END LOOP;

        SELECT    COUNT ( * )
          INTO    l_idx
          FROM    gt_shef_decodes;

        aa1(     '                >>parse_crit_file<< gt_shef_decodes has: '
             || l_idx
             || ' rows.
  ');

        IF NOT l_is_csv
        THEN
            BEGIN
                OPEN l_rc FOR
                    SELECT    cwms_id
                      FROM    (    SELECT    UPPER (c002) cwms_id,
                                                COUNT (UPPER (c002)) count_id
                                      FROM    apex_collections
                                     WHERE    collection_name = UPPER (p_collection_name)
                                 GROUP BY    UPPER (c002))
                     WHERE    count_id > 1;
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_tmp := 3;
            END;

            IF l_tmp != 3
            THEN
                LOOP
                    FETCH l_rc INTO                                  l_cwms_id_dup;

                    EXIT WHEN l_rc%NOTFOUND;

                    OPEN l_rc_rows FOR
                        SELECT    c001
                          FROM    apex_collections
                         WHERE    collection_name = UPPER (p_collection_name)
                                    AND UPPER (c002) = l_cwms_id_dup;

                    l_rows_msg := NULL;
                    l_tmp := 0;

                    LOOP
                        FETCH l_rc_rows INTO                                  l_row_num;

                        EXIT WHEN l_rc_rows%NOTFOUND;

                        IF l_tmp = 1
                        THEN
                            l_rows_msg :=
                                l_rows_msg
                                || '                                                                        ,
  ';
                        END IF;

                        l_rows_msg := l_rows_msg || TO_CHAR (l_row_num);
                        l_tmp := 1;
                    END LOOP;

                    l_seq_id :=
                        apex_collection.add_member (
                            p_error_collection_name,
                            '                                  dummy
  '
                        );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 1,
                        p_attr_value          => l_rows_msg
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 2,
                        p_attr_value          => '                                                    ERROR: cwms ts id is
        defined on multiple lines.
  '
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 3,
                        p_attr_value          => l_cwms_id_dup
                    );
                END LOOP;

                --
                --
                CLOSE l_rc;

                CLOSE l_rc_rows;

                OPEN l_rc FOR
                    SELECT    shef_id
                      FROM    (    SELECT    UPPER(c003
                                                        || '                                    .
        '
                                                        || c004
                                                        || '                                    .
        '
                                                        || c005
                                                        || '                                    .
  '
                                                        || c006)
                                                    shef_id,
                                                COUNT(UPPER(c003
                                                                || '                                        .
        '
                                                                || c004
                                                                || '                                        .
        '
                                                                || c005
                                                                || '                                        .
  '
                                                                || c006))
                                                    count_id
                                      FROM    apex_collections
                                     WHERE    collection_name = UPPER (p_collection_name)
                                 GROUP BY    UPPER(c003
                                                        || '                                    .
        '
                                                        || c004
                                                        || '                                    .
        '
                                                        || c005
                                                        || '                                    .
  '
                                                        || c006))
                     WHERE    count_id > 1;

                LOOP
                    FETCH l_rc INTO                                  l_shef_id_dup;

                    EXIT WHEN l_rc%NOTFOUND;

                    OPEN l_rc_rows FOR
                        SELECT    c001
                          FROM    apex_collections
                         WHERE    collection_name = UPPER (p_collection_name)
                                    AND UPPER(     c003
                                                 || '                                  .'
                                                 || c004
                                                 || '                                  .'
                                                 || c005
                                                 || '                                  .
  '
                                                 || c006) = l_shef_id_dup;

                    l_rows_msg := NULL;
                    l_tmp := 0;

                    LOOP
                        FETCH l_rc_rows INTO                                  l_row_num;

                        EXIT WHEN l_rc_rows%NOTFOUND;

                        IF l_tmp = 1
                        THEN
                            l_rows_msg :=
                                l_rows_msg
                                || '                                                                        ,
  ';
                        END IF;

                        l_rows_msg := l_rows_msg || l_row_num;
                        l_tmp := 1;
                    END LOOP;

                    l_seq_id :=
                        apex_collection.add_member (
                            p_error_collection_name,
                            '                                  dummy
  '
                        );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 1,
                        p_attr_value          => l_rows_msg
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 2,
                        p_attr_value          => '                                                    ERROR: SHEF id is defined
        on multiple lines.
  '
                    );
                    apex_collection.update_member_attribute (
                        p_collection_name   => p_error_collection_name,
                        p_seq                   => l_seq_id,
                        p_attr_number          => 3,
                        p_attr_value          => l_shef_id_dup
                    );
                END LOOP;
            END IF;
        END IF;

        --   IF l_is_crit_file
        --   THEN
        --   cwms_shef.delete_data_stream (l_datastream, '                                                                                                       T
        --  ', 'CWMS  ');
        --   END IF;

        --   DELETE FROM wwv_flow_files
        --   WHERE NAME = p_file_name;
        SELECT    COUNT ( * )
          INTO    l_seq_id
          FROM    apex_collections
         WHERE    collection_name = p_collection_name;

        cwms_properties.set_property (
            '        PROCESS_STATUS',
            p_process_id,
            '        Completed ' || p_number_of_records || ' records
  ',
            l_cmt || LOCALTIMESTAMP,
            p_db_office_id
        );

        aa1(     '                  parse collection name: '
             || p_collection_name
             || '                 Row count:
  '
             || l_seq_id);
    END;

    PROCEDURE error_check_crit_data (
        p_db_store_rule     IN VARCHAR2,
        p_data_stream_id     IN VARCHAR2,
        p_db_office_id      IN VARCHAR2 DEFAULT NULL
    )
    AS
    BEGIN
        IF (p_db_store_rule =
                 '                                                  ADD
  ')
        THEN
            INSERT INTO gt_shef_decodes (shef_loc_id, shef_pe_code, shef_tse_code, shef_dur_numeric, shef_spec, location_id, parameter_id, base_parameter_code, parameter_type_id, parameter_type_code, interval_id, interval_code, duration_id, duration_code, version, cwms_ts_id, cwms_ts_code, unit_system, units, unit_code, shef_tz, shef_dl_time, interva_utc_offset, interval_forward, interval_backward, active_flag, unparsed_line
                                                 )
                SELECT    shef_loc_id, shef_pe_code, shef_tse_code,
                            shef_duration_numeric, shef_spec, location_id,
                            parameter_id, 11, parameter_type_id, 11, interval_id, 11,
                            duration_id, 11, version_id, cwms_ts_id, ts_code,
                            unit_system, unit_id, 11, shef_time_zone_id, dl_time,
                            interval_utc_offset, interval_forward, interval_backward,
                            active_flag,
                            '                                          This SHEF Spec is currently defined
        in DB
  '
                  FROM    av_shef_decode_spec
                 WHERE    data_stream_id = p_data_stream_id
                            AND db_office_id = p_db_office_id;
        END IF;
    END;

         --=============================================================================
         --====Begin==store_parsed_loc_egis_file========================================
         --=============================================================================
    PROCEDURE store_parsed_loc_egis_file (
        p_parsed_collection_name        IN VARCHAR2,
        p_store_err_collection_name    IN VARCHAR2,
        p_db_office_id                     IN VARCHAR2 DEFAULT NULL,
        p_unique_process_id                IN VARCHAR2
    )
    IS
        l_location_id             VARCHAR2 (48);
        l_base_location_id2     VARCHAR2 (48);
        l_base_location_id     VARCHAR2 (16);
        l_sub_location_id      VARCHAR2 (32);
        l_county_name             VARCHAR2 (40);
        l_state_initial         VARCHAR2 (2);
        --===================
        l_latitude                 NUMBER;
        l_longitude              NUMBER;
        l_horizontal_datum     VARCHAR2 (16);
        l_elevation              NUMBER;
        l_unit_id                 VARCHAR2 (16);
        l_vertical_datum         VARCHAR2 (16);

        l_time_zone_name         VARCHAR2 (28);
        l_long_name              VARCHAR2 (80);
        l_description             VARCHAR2 (1024);
        l_db_office_id          VARCHAR2 (16);

        --====================
        l_ignorenulls             VARCHAR2 (1);
        l_parsed_rows             NUMBER;
        l_line_no                 VARCHAR2 (32);
        l_line_no2                 VARCHAR2 (32);
        l_min                      NUMBER;
        l_max                      NUMBER;
        l_cmt                      VARCHAR2 (256);
        l_steps_per_commit     NUMBER;
    BEGIN
        aa1 (
            'store_parsed_loc_egis_file - collection name: '
            || p_parsed_collection_name
        );
        --============  Create Error Collection  ====  'P613_STORE_ERROR_COLLECTION' ====== 
        APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION(p_store_err_collection_name);


        l_steps_per_commit :=
            TO_NUMBER (
                SUBSTR (p_unique_process_id,
                          (INSTR (p_unique_process_id, '.', 1, 5) + 1)
                         )
            );
        l_cmt :=
            'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
        cwms_properties.
        set_property ('PROCESS_STATUS',
                          p_unique_process_id,
                          'Initiated',
                          l_cmt || LOCALTIMESTAMP,
                          p_db_office_id
                         );

        IF (l_steps_per_commit > 0)
        THEN
            COMMIT;
        END IF;

        SELECT    COUNT (*), MIN (seq_id), MAX (seq_id)
          INTO    l_parsed_rows, l_min, l_max
          FROM    apex_collections
         WHERE    collection_name = p_parsed_collection_name;

        aa1 (
                'l_parsed_rows = '
            || l_parsed_rows
            || ' min '
            || l_min
            || ' max '
            || l_max
        );

        -- Start at 2 to skip first line of column titles
        FOR i IN 2 .. l_parsed_rows
        LOOP
            aa1 ('looping: ' || i);

            IF (l_steps_per_commit > 0)
            THEN
                IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
                THEN
                    cwms_properties.
                    set_property ('PROCESS_STATUS',
                                      p_unique_process_id,
                                      'Processing: ' || i || ' of ' || l_parsed_rows,
                                      l_cmt || LOCALTIMESTAMP,
                                      p_db_office_id
                                     );
                    COMMIT;
                END IF;
            END IF;

            BEGIN --===============   Trap errors in select and store  =================================
                SELECT    c001, c002
                  INTO    l_line_no2, l_base_location_id2
                  FROM    apex_collections
                 WHERE    collection_name = p_parsed_collection_name AND seq_id = i;

                SELECT    c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
                            c011, c012, c013, c014, c015
                  INTO    l_line_no, l_base_location_id, l_sub_location_id,
                            l_latitude, l_longitude, l_horizontal_datum, l_elevation,
                            l_unit_id, l_vertical_datum, l_county_name, l_state_initial,
                            l_time_zone_name, l_long_name, l_description,
                            l_db_office_id
                  FROM    apex_collections
                 WHERE    collection_name = p_parsed_collection_name AND seq_id = i;

                l_location_id :=
                    cwms_util.
                    concat_base_sub_id (l_base_location_id, l_sub_location_id);

                aa1 ('storing locs-egis: ' || l_base_location_id);
                --
                cwms_loc.
                store_location (p_location_id          => l_location_id,
                                     p_county_name          => l_county_name,
                                     p_state_initial         => l_state_initial,
                                     p_latitude              => l_latitude,
                                     p_longitude             => l_longitude,
                                     p_horizontal_datum     => l_horizontal_datum,
                                     p_elevation             => l_elevation,
                                     p_elev_unit_id         => l_unit_id,
                                     p_vertical_datum      => l_vertical_datum,
                                     p_time_zone_id         => l_time_zone_name,
                                     p_long_name             => l_long_name,
                                     p_description          => l_description,
                                     p_ignorenulls          => 'T',
                                     p_db_office_id         => l_db_office_id
                                    );
            EXCEPTION
                WHEN OTHERS
                THEN
                    DECLARE
                        l_i            NUMBER := INSTR (SQLERRM, ':', 1, 1);
                        l_err_num    VARCHAR2 (256) := SUBSTR (SQLERRM, 1, l_i);
                        l_err_msg    VARCHAR2 (512)
                                            := SUBSTR (
                                                    SQLERRM,
                                                    l_i + 1,
                                                    (INSTR (SQLERRM, 'ORA-', 1, 2) - l_i - 1)
                                                );
                    BEGIN
                        IF (LENGTH (l_err_msg) <= 5 OR l_err_msg IS NULL)
                        THEN
                            l_err_msg := SQLERRM;
                        END IF;

                        apex_collection.
                        add_member (p_store_err_collection_name,
                                        'Line # ' || i,
                                        l_err_num,
                                        l_err_msg,
                                        l_line_no2 || ':' || l_base_location_id2
                                      );
                    END;
            END; --==================    Trap Errors  ==========================================
        END LOOP;

        cwms_properties.
        set_property ('PROCESS_STATUS',
                          p_unique_process_id,
                          'Completed ' || l_parsed_rows || ' records',
                          l_cmt || LOCALTIMESTAMP,
                          p_db_office_id
                         );
    END;
    --=============================================================================
    --====End==store_parsed_loc_egis_file==========================================
    --=============================================================================
  END cwms_apex;
/
show errors;

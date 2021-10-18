CREATE OR REPLACE PROCEDURE move_data_from_inf_to_yearly
AS
    l_cmd   VARCHAR2 (512);
BEGIN
    --cwms_sec.confirm_cwms_schema_user;

    FOR c IN (SELECT table_name
                FROM at_ts_table_properties
               WHERE table_name <> 'AT_TSV_INF_AND_BEYOND')
    LOOP
        EXECUTE IMMEDIATE   'lock table '
                         || c.table_name
                         || ' in exclusive mode';

        l_cmd :=
               'insert into '
            || c.table_name
            || ' select * from at_tsv_inf_and_beyond where date_time >= (select start_date from at_ts_table_properties where table_name = '''
            || c.table_name
            || ''') and date_time < (select end_date from at_ts_table_properties where table_name='''
            || c.table_name
            || ''')';
        DBMS_OUTPUT.put_line (l_cmd);

        EXECUTE IMMEDIATE l_cmd;

        l_cmd :=
               'delete from at_tsv_inf_and_beyond where date_time >= (select start_date from at_ts_table_properties where table_name = '''
            || c.table_name
            || ''') and date_time < (select end_date from at_ts_table_properties where table_name='''
            || c.table_name
            || ''')';
        DBMS_OUTPUT.put_line (l_cmd);

        EXECUTE IMMEDIATE l_cmd;

        COMMIT;
    END LOOP;
END;
/

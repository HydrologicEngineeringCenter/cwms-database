/* Formatted on 6/16/2011 2:47:24 PM (QP5 v5.163.1008.3004) */
@@defines.sql

DECLARE
	TYPE id_array_t IS TABLE OF VARCHAR2 (32);

	table_names   id_array_t := id_array_t ('at_cwms_ts_id');
   view_names    id_array_t := id_array_t('mv_data_quality',
                                       	'mv_data_q_changed',
                                       	'mv_data_q_protection',
                                       	'mv_data_q_range',
                                       	'mv_data_q_repl_cause',
                                       	'mv_data_q_repl_method',
                                       	'mv_data_q_screened',
                                       	'mv_data_q_test_failed',
                                       	'mv_data_q_validity');

BEGIN
	FOR i IN table_names.FIRST .. table_names.LAST
	LOOP
		BEGIN
			EXECUTE IMMEDIATE 'drop table ' || table_names (i);

			DBMS_OUTPUT.put_line ('Dropped table ' || table_names (i));
		EXCEPTION
			WHEN OTHERS
			THEN
				NULL;
		END;
	END LOOP;
   for i in 1..view_names.count loop
      begin
         dbms_output.put('Dropping materialized view '||view_names(i)||'...');
         execute immediate 'drop materialized view '||view_names(i);
         dbms_output.put_line('done');
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
   end loop;
END;
/

@@cwms/tables/at_cwms_ts_id.sql

@@cwms/views/mv_data_q_changed.sql
@@cwms/views/mv_data_q_protection.sql
@@cwms/views/mv_data_q_range.sql
@@cwms/views/mv_data_q_repl_cause.sql
@@cwms/views/mv_data_q_repl_method.sql
@@cwms/views/mv_data_q_screened.sql
@@cwms/views/mv_data_q_test_failed.sql
@@cwms/views/mv_data_q_validity.sql
@@cwms/views/mv_data_quality.sql

/* Formatted on 6/16/2011 2:47:24 PM (QP5 v5.163.1008.3004) */
@@defines.sql

DECLARE
	TYPE id_array_t IS TABLE OF VARCHAR2 (32);

	table_names   id_array_t := id_array_t ();
   view_names    id_array_t := id_array_t('mv_rating_values',
                                       	'mv_rating_values_native');

BEGIN
   for i in 1..table_names.count loop
      begin
         dbms_output.put('Dropping table '||table_names(i)||'...');
         execute immediate 'drop table '||table_names(i);
         dbms_output.put_line('done');
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
	end loop;
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

@@cwms/views/mv_rating_values.sql
@@cwms/views/mv_rating_values_native.sql

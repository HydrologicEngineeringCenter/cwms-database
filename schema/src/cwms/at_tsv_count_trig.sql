DECLARE
   l_cmd   VARCHAR2 (1024);
BEGIN
   FOR c IN (SELECT table_name
               FROM at_ts_table_properties)
   LOOP
      l_cmd :=
            ' CREATE OR REPLACE TRIGGER '
         || c.table_name
         || '_AIUDR
        AFTER INSERT OR UPDATE OR DELETE ON '
         || c.table_name
         || ' FOR EACH ROW
        DECLARE
                l_dml number;
        BEGIN
        -- count inserts, updates and deletes using the cwms_tsv package

                l_dml := 0;
        
                if INSERTING then
                        l_dml := 1;
                elsif UPDATING then
                        l_dml := 2;
                elsif DELETING then
                        l_dml := 3;
                end if;

        cwms_tsv.count(l_dml, sys_extract_utc(systimestamp));

        EXCEPTION
        -- silently fail
        WHEN OTHERS THEN NULL;
    END;';
   execute immediate l_cmd;
   END LOOP;
END;
/

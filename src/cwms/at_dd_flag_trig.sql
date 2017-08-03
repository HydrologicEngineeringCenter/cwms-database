DECLARE
   l_cmd   VARCHAR2 (1024);
BEGIN
   FOR c IN (SELECT table_name
               FROM at_ts_table_properties)
   LOOP
      l_cmd :=
            ' CREATE OR REPLACE TRIGGER '
         || c.table_name
         || '_DDF
        BEFORE INSERT OR UPDATE ON '
         || c.table_name
         || ' FOR EACH ROW
        BEGIN
                if INSERTING OR UPDATING then
                        :new.dest_flag := CWMS_DATA_DISSEM.GET_DEST(:new.ts_code);
                end if;

        EXCEPTION
        -- silently fail
        WHEN OTHERS THEN NULL;
    END;';
   execute immediate l_cmd;
   END LOOP;
END;
/

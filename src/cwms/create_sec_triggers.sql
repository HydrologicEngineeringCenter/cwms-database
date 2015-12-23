DECLARE
   l_cmd   VARCHAR2 (1024);
   l_trig VARCHAR2(64);
BEGIN
   FOR c IN (SELECT table_name
               FROM user_tables
              WHERE table_name LIKE 'AT_%' AND TEMPORARY = 'N' AND table_name <> 'AT_PROPERTIES')
   LOOP
      l_trig := replace(c.table_name,'AT_','ST_');
      l_cmd :=
            'CREATE OR REPLACE TRIGGER '
         || l_trig
         || ' BEFORE DELETE OR INSERT OR UPDATE
              ON '
         || c.table_name
         || ' REFERENCING NEW AS NEW OLD AS OLD

             DECLARE
    
             l_priv   VARCHAR2 (16);
             BEGIN
             SELECT SYS_CONTEXT (''CWMS_ENV'', ''CWMS_PRIVILEGE'') INTO l_priv FROM DUAL;
             IF ((l_priv is NULL OR l_priv <> ''CAN_WRITE'') AND user<>UPPER(''&cwms_schema''))
             THEN
     
               CWMS_20.CWMS_ERR.RAISE(''NO_WRITE_PRIVILEGE'');
     
             END IF;
           END;';
   DBMS_OUTPUT.PUT_LINE(l_cmd);
   execute immediate l_cmd;
   END LOOP;
END;
/

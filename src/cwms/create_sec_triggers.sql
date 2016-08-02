DECLARE
   l_cmd   VARCHAR2 (1024);
   l_trig VARCHAR2(64);
   l_upass VARCHAR2(128) := '';
BEGIN
   FOR c IN (SELECT table_name
               FROM user_tables
              WHERE table_name LIKE 'AT_%' AND TEMPORARY = 'N' AND table_name <> 'AT_PROPERTIES')
   LOOP
      l_trig := replace(c.table_name,'AT_','ST_');
      if(c.table_name = 'AT_SEC_USERS' OR c.table_name='AT_SEC_LOCKED_USERS' OR c.table_name='AT_SEC_USER_OFFICE' OR
	c.table_name = 'AT_LOG_MESSAGE' or c.table_name='AT_LOG_MESSAGE_PROPERTIES' or c.table_name = 'AT_SEC_CWMS_USERS')
      THEN
	l_upass := ' AND user <>  UPPER(CWMS_PROPERTIES.GET_PROPERTY(''CWMSDB'',''sec.upass.id'',''UPASSADM'',''CWMS''))';
      ELSE
	l_upass := '';
      END IF;
      DBMS_OUTPUT.PUT_LINE(c.table_name || ':' || l_upass);
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
             IF ((l_priv is NULL OR l_priv <> ''CAN_WRITE'') AND user NOT IN (''SYS'', ''&cwms_schema'')'
          || l_upass 
          || ')
             THEN
     
               CWMS_20.CWMS_ERR.RAISE(''NO_WRITE_PRIVILEGE'');
     
             END IF;
           END;';
   DBMS_OUTPUT.PUT_LINE(l_cmd);
   execute immediate l_cmd;
   END LOOP;
END;
/

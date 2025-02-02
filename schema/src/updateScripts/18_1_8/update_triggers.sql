DECLARE
   l_cmd   VARCHAR2 (1024);
   l_trig VARCHAR2(64);
   l_upass VARCHAR2(128) := '';
BEGIN
   FOR c IN (SELECT table_name
               FROM user_tables
              WHERE table_name LIKE 'AT_%' AND TEMPORARY = 'N' AND table_name not in ( 'AT_PROPERTIES','AT_LOG_MESSAGE','AT_LOG_MESSAGE_PROPERTIES','AT_APPLICATION_LOGIN','AT_APPLICATION_SESSION'))
   LOOP
      l_trig := replace(c.table_name,'AT_','ST_');
      if(c.table_name = 'AT_SEC_USERS' OR c.table_name='AT_SEC_LOCKED_USERS' OR c.table_name='AT_SEC_USER_OFFICE' OR
	 c.table_name = 'AT_SEC_CWMS_USERS')
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

CREATE OR REPLACE TRIGGER at_pool_t01
   before insert or update
   of bottom_level, top_level
   on at_pool
   for each row
declare
   l_rec  at_location_level%rowtype;
   l_text varchar2(64);
begin
   -----------------------------
   -- assert different levels --
   -----------------------------
   if :new.bottom_level = :new.top_level then
      cwms_err.raise('ERROR', 'Top and bottom levels cannot be the same');
   end if;
   -----------------------------------------------
   -- validate bottom level is 'Elev.Inst.0...' --
   -----------------------------------------------
   if instr(:new.bottom_level, 'Elev.Inst.0.') != 1 then
      cwms_err.raise('ERROR', 'Bottom location level ID must start with ''Elev.Inst.0''');
   end if;
   --------------------------------------------
   -- validate top level is 'Elev.Inst.0...' --
   --------------------------------------------
   if instr(:new.top_level, 'Elev.Inst.0.') != 1 then
      cwms_err.raise('ERROR', 'Top location level ID must start with ''Elev.Inst.0''');
   end if;
end at_pool_t01;
/
/


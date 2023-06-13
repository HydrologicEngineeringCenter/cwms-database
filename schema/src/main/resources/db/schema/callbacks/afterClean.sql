
begin
   execute immediate 'DROP PROFILE cwms_prof cascade';
   exception
     when others then null;

end;
/

begin
   execute immediate 'drop role cwms_user';
   exception
     when others then null;
end;
/

begin
   execute immediate 'drop role web_user';
   exception
     when others then null;
end;
/

begin
   for rec in (select object_name
                 from dba_objects
                where owner = '${CWMS_SCHEMA}'
                  and object_type = 'TYPE'
                  and object_name not like 'SYS\_%' escape '\'
             order by object_name)
   loop
      dbms_output.put_line('Dropping type '||rec.object_name);
      execute immediate 'drop type '||rec.object_name||' force';
   end loop;
end;
/

-- flush out all the meta data
delete from user_sdo_geom_metadata; 
----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------

DECLARE
   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   table_names       id_array_t
      := id_array_t ('AT_CONSTRUCTION_HISTORY',
           'AT_DOCUMENT',
           'AT_EMBANKMENT',
           'AT_GATE_SETTING',
           'AT_LOCK',
           'AT_LOCKAGE',
           'AT_GATE_CHANGE',
           'AT_TURBINE_CHANGE',
           'AT_OUTLET',
           'AT_PROJECT',
           'AT_PROJECT_AGREEMENT',
           'AT_PROJECT_CONGRESS_DISTRICT',
           'AT_PROJECT_LOCK',
           'AT_PROJECT_PURPOSES',
           'AT_PRJ_LCK_REVOKER_RIGHTS',
           'AT_TURBINE',
           'AT_TURBINE_SETTING',
           'AT_WAT_USR_CONTRACT_ACCOUNTING',
           'AT_WATER_USER_CONTRACT',
           'AT_WATER_USER',
           'AT_XREF_WAT_USR_CONTRACT_DOCS',
           'AT_DOCUMENT_TYPE',
           'AT_EMBANK_PROTECTION_TYPE',
           'AT_EMBANK_STRUCTURE_TYPE',
           'AT_GATE_CH_COMPUTATION_CODE',
           'AT_GATE_RELEASE_REASON_CODE',
           'AT_PHYSICAL_TRANSFER_TYPE',
           'AT_PROJECT_PURPOSE',
           'AT_TURBINE_SETTING_REASON',
           'AT_TURBINE_COMPUTATION_CODE',
           'AT_WS_CONTRACT_TYPE',
           'AT_OPERATIONAL_STATUS_CODE',
           'AT_OUTLET_CHARACTERISTIC',
           'AT_TURBINE_CHARACTERISTIC'
                    );
   mview_log_names   id_array_t
      := id_array_t (' '
                    );
BEGIN
   FOR i IN table_names.FIRST .. table_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop table '
                           || table_names (i)
                           || ' cascade constraints purge';

         DBMS_OUTPUT.put_line ('Dropped table ' || table_names (i));
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;

   FOR i IN mview_log_names.FIRST .. mview_log_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop materialized view log on '
                           || mview_log_names (i);

         DBMS_OUTPUT.put_line (   'Dropped materialized view log on '
                               || mview_log_names (i)
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;
/


-- drop user ${CWMS_OFFICE_EROC}cwmspd cascade;

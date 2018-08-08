CREATE OR REPLACE FUNCTION APEX_040200.wwv_flow_epg_include_mod_local (
   procedure_name IN VARCHAR2)
   RETURN BOOLEAN
IS
BEGIN
   --START
   --Added by Gerhard on 12/03/2013
   --modified by JDK on 22JAN2015 to include CPC conditional processing 
   -- for Upward reporting D1-3 and D2 DBs
   IF (   UPPER (procedure_name) LIKE 'CWMS_20.DOWNLOAD_FILE'
       OR UPPER (procedure_name) LIKE 'CWMS_20.P_CHART_BY_TS_CODE'
       OR (
           --This code will allow stored procedures related to 
      -- Upward Reporting to execute ONLY on CPC DB 2 (Production) and CPC CWMS DB 3 (development)
           UPPER(sys_context('USERENV','SERVER_HOST') IN ('CPC-CWMSDB2','CPC-CWMSDB3')
            AND
            INSTR('CWMS_CRREL.') > 0
           )

 
       )

   THEN
      RETURN TRUE;
   ELSE
      RETURN FALSE;
   END IF;
--END 
END wwv_flow_epg_include_mod_local;
/


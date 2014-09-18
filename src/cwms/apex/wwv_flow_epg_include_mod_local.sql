CREATE OR REPLACE FUNCTION APEX_040200.wwv_flow_epg_include_mod_local (
   procedure_name IN VARCHAR2)
   RETURN BOOLEAN
IS
BEGIN
   --START
   --Added by Gerhard on 12/03/2013
   IF (   UPPER (procedure_name) LIKE 'CWMS_20.DOWNLOAD_FILE'
       OR UPPER (procedure_name) LIKE 'CWMS_20.P_CHART_BY_TS_CODE')
   THEN
      RETURN TRUE;
   ELSE
      RETURN FALSE;
   END IF;
--END 
END wwv_flow_epg_include_mod_local;
/


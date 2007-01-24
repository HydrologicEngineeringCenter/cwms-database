create or replace package cwms_xchg as

iso_8601_timestamp_format constant varchar2(32) := 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"';
iso_8601_date_format      constant varchar2(32) := 'YYYY-MM-DD"T"HH24:MI:SS"Z"';

exc_no_subscribers exception; pragma exception_init(exc_no_subscribers, -24033);
exc_time_value     exception; pragma exception_init(exc_time_value,     -20006); 

-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(TIMESTAMP)
--
function use_first_table(
   p_timestamp in timestamp default null)
   return         boolean;
      
-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(VARCHAR2)
--
function use_first_table(
   p_timestamp in varchar2) 
   return         boolean;
   
-------------------------------------------------------------------------------
-- PROCEDURE CONTROL_UPDATED()
--
procedure control_updated;
   
-------------------------------------------------------------------------------
-- PROCEDURE TIME_SERIES_UPDATED(...)
--
procedure time_series_updated(
   p_ts_code         in number, 
   p_office_id       in varchar2, 
   p_timeseries_desc in varchar2,
   p_store_rule      in varchar2, 
   p_units           in varchar2,
   p_override_prot   in boolean, 
   p_timeseries_data in tsv_array);
   
-------------------------------------------------------------------------------
-- SYS_REFCURSOR FUNCTION GET_TS(...)
--
function get_ts(
   p_xchg_code           in  number,
   p_timestamp           in  timestamp,
   p_store_rule          out varchar2,
   p_override_protection out char, 
   p_units               out varchar2)
   return                    sys_refcursor;
      
-------------------------------------------------------------------------------
-- SYS_REFCURSOR FUNCTION GET_TS_RECORDS_SINCE(...)
--
function get_ts_records_since(
   p_beginning_time in  timestamp,
   p_ts_code_list   in  varchar2)
   return               sys_refcursor;
   
end;
show errors;

SPOOL OFF
SET ECHO OFF
SET TIME OFF


create or replace package cwms_xchg as

-------------------------------------------------------------------------------
-- PROCEDURE XCHG_CONFIG_UPDATED
--
procedure xchg_config_updated;
   
-------------------------------------------------------------------------------
-- PROCEDURE TIME_SERIES_UPDATED(...)
--
procedure time_series_updated(
   p_ts_code    in integer,
   p_ts_id      in varchar2, 
   p_first_time in timestamp with time zone,
   p_last_time  in timestamp with time zone);

-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_component   in varchar2,
   p_host        in varchar2,
   p_port        in integer,
   p_xchg_code   in integer,
   p_update_time in integer);

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REPLAY_DATA_MESSAGES(...)
--
function replay_data_messages(
   p_xchg_code  in integer,
   p_start_time in integer  default null,
   p_end_time   in integer  default null,
   p_request_id in varchar2 default null)
   return varchar2;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION RESTART_REALTIME(...)
--
function restart_realtime(
   p_xchg_code in integer)
   return varchar2;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION RESTART_REALTIME(...)
--
function restart_realtime(
   p_engine_url in varchar2)
   return varchar2;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REQUEST_BATCH_EXCHANGE(...)
--
function request_batch_exchange(
   p_component  in varchar2,
   p_host       in varchar2,
   p_set_id     in varchar2,
   p_to_dss     in varchar2,
   p_start_time in integer,
   p_end_time   in integer default null)
   return varchar2;

end cwms_xchg;
/
commit;
show errors;


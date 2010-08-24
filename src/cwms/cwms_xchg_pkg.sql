create or replace package cwms_xchg as

--------------------------------------------------------------------------------
--
-- In the CREATE_XXX functions and procedures below, the p_fail_if_exists input
-- parameter specifies whether the routine should return the code of the existing
-- object or raise an exception if the object to create already exists in the
-- database.  The default is to return the code of the existing object.
--

--------------------------------------------------------------------------------
-- PROCEDURE GET_QUEUE_NAMES
--
   procedure get_queue_names(
      p_status_queue_name   out nocopy varchar2,
      p_realtime_queue_name out nocopy varchar2,
      p_office_id           in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION DB_DATASTORE_ID()
--
   function db_datastore_id
      return varchar2;
   
--------------------------------------------------------------------------------
-- PROCEDURE PARSE_DSS_PATHNAME(...)
--
   procedure parse_dss_pathname(
      p_a_pathname_part out nocopy varchar2,
      p_b_pathname_part out nocopy varchar2,
      p_c_pathname_part out nocopy varchar2,
      p_d_pathname_part out nocopy varchar2,
      p_e_pathname_part out nocopy varchar2,
      p_f_pathname_part out nocopy varchar2,
      p_pathname        in  varchar2);

--------------------------------------------------------------------------------
-- BOOLEAN FUNCTION IS_REALTIME_EXPORT(...)
--
function is_realtime_export(
   p_ts_code in integer)
   return boolean;
   
--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_PATHNAME(...)
--
   function make_dss_pathname(
      p_a_pathname_part   in   varchar2,
      p_b_pathname_part   in   varchar2,
      p_c_pathname_part   in   varchar2,
      p_d_pathname_part   in   varchar2,
      p_e_pathname_part   in   varchar2,
      p_f_pathname_part   in   varchar2)
      return varchar2;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_TS_ID(...)
--
   function make_dss_ts_id(
      p_pathname          in   varchar2,
      p_parameter_type    in   varchar2 default null,
      p_units             in   varchar2 default null,
      p_time_zone         in   varchar2 default null,
      p_tz_usage          in   varchar2 default null)
      return varchar2;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_TS_ID(...)
--
   function make_dss_ts_id(
      p_a_pathname_part   in   varchar2,
      p_b_pathname_part   in   varchar2,
      p_c_pathname_part   in   varchar2,
      p_d_pathname_part   in   varchar2,
      p_e_pathname_part   in   varchar2,
      p_f_pathname_part   in   varchar2,
      p_parameter_type    in   varchar2 default null,
      p_units             in   varchar2 default null,
      p_time_zone         in   varchar2 default null,
      p_tz_usage          in   varchar2 default null)
      return varchar2;
   
-------------------------------------------------------------------------------
-- PROCEDURE DELETE_DSS_XCHG_SET(...)
--
   procedure delete_dss_xchg_set(
      p_dss_xchg_set_id   in   varchar2,
      p_office_id         in   varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE RENAME_DSS_XCHG_SET
--
   procedure rename_dss_xchg_set(
      p_old_xchg_set_id       in   varchar2,
      p_new_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE DUPLICATE_DSS_XCHG_SET(...)
--
   procedure duplicate_dss_xchg_set(
      p_old_xchg_set_id   in   varchar2,
      p_new_xchg_set_id   in   varchar2,
      p_office_id         in   varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE UPDATE_DSS_XCHG_SET_TIME(...)
--
   procedure update_dss_xchg_set_time(
      p_xchg_set_code    in  number,
      p_last_update          in  timestamp);

--------------------------------------------------------------------------------
-- CLOB FUNCTION GET_DSS_XCHG_SETS(...)
--
-- Calling this function with no parameters will return all exchange sets for
-- the calling user's office.   
--
--
   function get_dss_xchg_sets(
      p_dss_filemgr_url in varchar2 default null,
      p_dss_file_name   in varchar2 default null,
      p_dss_xchg_set_id in varchar2 default null,
      p_office_id       in varchar2 default null)
      return clob;

   procedure store_dataexchange_conf(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_dx_config         in  clob,
      p_store_rule        in  varchar2 default 'MERGE');

--------------------------------------------------------------------------------
-- PROCEDURE DEL_UNUSED_DSS_XCHG_INFO(...)
--
   procedure del_unused_dss_xchg_info(
      p_office_id in varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE XCHG_CONFIG_UPDATED
--
procedure xchg_config_updated(
   p_urls_affected in varchar2);
   
-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_engine_url  in varchar2,
   p_xchg_code   in integer,
   p_update_time in integer);

-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_engine_url   in varchar2,
   p_xchg_set_id  in varchar2,
   p_update_time  in integer,
   p_office_id    in varchar2 default null);

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REPLAY_DATA_MESSAGES(...)
--
function replay_data_messages(
   p_component   in varchar2,
   p_host        in varchar2,
   p_xchg_set_id in varchar2,
   p_start_time  in integer  default null,
   p_end_time    in integer  default null,
   p_request_id  in varchar2 default null,
   p_office_id   in varchar2 default null)
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
   p_component        in varchar2,
   p_host             in varchar2,
   p_set_id           in varchar2,
   p_dst_datastore_id in varchar2,
   p_start_time       in integer,
   p_end_time         in integer  default null,
   p_office_id        in varchar2 default null)
   return varchar2;

-------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_DSS_DATASTORE(...)
--
procedure retrieve_dss_datastore(
   p_datastore_code  out number,                            
   p_dss_filemgr_url out nocopy varchar2,
   p_dss_file_name   out nocopy varchar2,
   p_description     out nocopy varchar2,
   p_datastore_id    in  varchar2,                                
   p_office_id       in  varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE STORE_DSS_DATASTORE(...)
--
procedure store_dss_datastore(
   p_datastore_code  out number,                            
   p_datastore_id    in  varchar2,                                
   p_dss_filemgr_url in  varchar2,
   p_dss_file_name   in  varchar2,
   p_description     in  varchar2 default null,
   p_fail_if_exists  in  varchar2 default 'T',
   p_office_id       in  varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_XCHG_SET(...)
--
procedure retrieve_xchg_set(
   p_xchg_set_code out number,
   p_datastore_id  out nocopy varchar2,
   p_description   out nocopy varchar2,
   p_start_time    out nocopy varchar2,
   p_end_time      out nocopy varchar2,
   p_interp_count  out number,
   p_interp_units  out nocopy varchar2,
   p_realtime_dir  out nocopy varchar2,
   p_last_update   out timestamp,
   p_xchg_set_id   in  varchar2,
   p_office_id     in  varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE STORE_XCHG_SET(...)
--
procedure store_xchg_set(
   p_xchg_set_code  out number,
   p_xchg_set_id    in  varchar2,
   p_datastore_id   in  varchar2,
   p_description    in  varchar2 default null,
   p_start_time     in  varchar2 default null,
   p_end_time       in  varchar2 default null,
   p_interp_count   in  integer  default null,
   p_interp_units   in  varchar2 default null, -- Intervals or Minutes
   p_realtime_dir   in  varchar2 default null, -- DssToOracle or OracleToDss
   p_fail_if_exists in  varchar2 default 'T',  -- T or F
   p_office_id      in  varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_XCHG_DSS_TS_MAPPING(...)
--
procedure retrieve_xchg_dss_ts_mapping(
   p_mapping_code    out number,
   p_a_pathname_part out nocopy varchar2,
   p_b_pathname_part out nocopy varchar2,
   p_c_pathname_part out nocopy varchar2,
   p_e_pathname_part out nocopy varchar2,
   p_f_pathname_part out nocopy varchar2,
   p_parameter_type  out nocopy varchar2,
   p_units           out nocopy varchar2,
   p_time_zone       out nocopy varchar2,
   p_tz_usage        out nocopy varchar2,
   p_xchg_set_code   in  number,
   p_cwms_ts_code    in  number);

-------------------------------------------------------------------------------
-- PROCEDURE STORE_XCHG_DSS_TS_MAPPING(...)
--
procedure store_xchg_dss_ts_mapping(
   p_mapping_code    out number,
   p_xchg_set_code   in  number,
   p_cwms_ts_code    in  number,
   p_a_pathname_part in  varchar2,
   p_b_pathname_part in  varchar2,
   p_c_pathname_part in  varchar2,
   p_e_pathname_part in  varchar2,
   p_f_pathname_part in  varchar2,
   p_parameter_type  in  varchar2,
   p_units           in  varchar2,
   p_time_zone       in  varchar2 default 'UTC',
   p_tz_usage        in  varchar2 default 'Standard',
   p_fail_if_exists  in  varchar2 default 'T');

end cwms_xchg;
/
commit;
show errors;

create or replace package cwms_xchg as

--------------------------------------------------------------------------------
--
-- In the CREATE_XXX functions and procedures below, the p_fail_if_exists input
-- parameter specifies whether the routine should return the code of the existing
-- object or raise an exception if the object to create already exists in the
-- database.  The default is to return the code of the existing object.
--

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION DB_DATASTORE_ID()
--
   function db_datastore_id
      return varchar2;
   
--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION DSS_DATASTORE_ID(...)
--
   function dss_datastore_id(
      p_dss_filemgr_url in varchar2,
      p_dss_file_name   in varchar2)
      return varchar2;
   
--------------------------------------------------------------------------------
-- NUMBER FUNCTION CREATE_DSS_XCHG_SET(...)
--
   function create_dss_xchg_set(
      p_dss_xchg_set_id   in   varchar2,
      p_description       in   varchar2,
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_start_time        in   varchar2 default null,
      p_end_time          in   varchar2 default null,
      p_realtime          in   varchar2 default null,
      p_fail_if_exists    in   number default cwms_util.false_num,
      p_office_id         in   varchar2 default null)
      return number;

--------------------------------------------------------------------------------
-- PROCEDURE CREATE_DSS_XCHG_SET(...)
--
   procedure create_dss_xchg_set(
      p_dss_xchg_set_code   out      number,
      p_dss_xchg_set_id     in       varchar2,
      p_description         in       varchar2,
      p_dss_filemgr_url     in       varchar2,
      p_dss_file_name       in       varchar2,
      p_start_time          in       varchar2 default null,
      p_end_time            in       varchar2 default null,
      p_realtime            in       varchar2 default null,
      p_fail_if_exists      in       number default cwms_util.false_num,
      p_office_id           in       varchar2 default null);

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
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null);

-------------------------------------------------------------------------------
-- PROCEDURE DUPLICATE_DSS_XCHG_SET(...)
--
   procedure duplicate_dss_xchg_set(
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION UPDATE_DSS_XCHG_SET(...)
--
   function update_dss_xchg_set(
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,                        
      p_last_update          in   timestamp,
      p_ignore_nulls         in   varchar2 default 'T',
      p_office_id            in   varchar2 default null)
      return number;

--------------------------------------------------------------------------------
-- PROCEDURE UPDATE_DSS_XCHG_SET(...)
--
   procedure update_dss_xchg_set(
      p_dss_xchg_set_code    out  number,
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,
      p_last_update          in   timestamp,
      p_ignore_nulls         in   varchar2 default 'T',
      p_office_id            in   varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE UPDATE_DSS_XCHG_SET_TIME(...)
--
   procedure update_dss_xchg_set_time(
      p_dss_xchg_set_code    in  number,
      p_last_update          in  timestamp);

--------------------------------------------------------------------------------
-- PROCEDURE MAP_TS_IN_XCHG_SET(...)
--
   procedure map_ts_in_xchg_set(
      p_dss_xchg_set_code    in   number,
      p_cwms_ts_id           in   varchar2,
      p_dss_pathname         in   varchar2,
      p_dss_parameter_type   in   varchar2 default null,
      p_units                in   varchar2 default null,
      p_time_zone            in   varchar2 default null,
      p_tz_usage             in   varchar2 default null,
      p_office_id            in   varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE UNMAP_TS_IN_XCHG_SET(...) 
--
   procedure unmap_ts_in_xchg_set(
      p_dss_xchg_set_code    in   number,
      p_cwms_ts_code         in   number,
      p_office_id            in   varchar2 default null);
   
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

   procedure retrieve_dataexchange_conf(
      p_dx_config       out xchg_dataexchange_conf_t,
      p_dss_filemgr_url in  varchar2 default null,
      p_dss_file_name   in  varchar2 default null,
      p_dss_xchg_set_id in  varchar2 default null,
      p_office_id       in  varchar2 default null);
                                              
   procedure retrieve_dataexchange_conf(
      p_dx_config       in out nocopy clob,
      p_dss_filemgr_url in varchar2 default null,
      p_dss_file_name   in varchar2 default null,
      p_dss_xchg_set_id in varchar2 default null,
      p_office_id       in varchar2 default null);

   procedure store_dataexchange_conf(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_dx_config         in  xchg_dataexchange_conf_t,
      p_store_rule        in  varchar2 default 'MERGE');
   
   procedure store_dataexchange_conf(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_dx_config         in  clob,
      p_store_rule        in  varchar2 default 'MERGE');

--------------------------------------------------------------------------------
-- PROCEDURE PUT_DSS_XCHG_SETS(...)
--
-- p_xml_clob must be a CLOB containing an XML instance of the same format as
-- output by the get_dss_xchg_sets function (corresponds to the XML schema
-- specified in dataexchangeschma.xsd).   
--   
-- p_store_rule must be one of - or an initial substring of - the following:
--   
--   INSERT  - For each existing data exchange set specfied in the input, add
--             any mappings that don't already exist.  No existing mappings
--             will be modified, even if they differ from the mappings
--             specified in the input. New data exchange sets specified in
--             the input will be created. No existing data exchange sets will
--             be updated.   
--   
--   UPDATE  - For each existing data exchange set specified in the input,
--             update all existing mappings that differ from the specified
--             mappings. No mappings will be added to existing exchange sets.
--             No new data exchange sets will be created.  Existing data
--             exchange sets will be updated if necessary.   
--   
--   MERGE   - INSERT + UPDATE. For each exisint data exchange set specified
--             in the input, update existing mappings that differ from the
--             specified mappings and add specified mappings that don't already
--             exist. New data exchange sets specified in the input will be 
--             created and existing sets will be updated if necessary.
--   
--   REPLACE - For each existing data exchange set specified in the input,
--             delete all existing mappings and replace them with the specified
--             mappings. New data exchange sets specified in the input will be
--             created. Existing data exchange sets will be updated if
--             necessary.
--   
--   Under no circumstances will exsiting data exchange sets be deleted by this
--   procedure.
--   
--   Existing data exchange sets are identified by the set id (name).  Items
--   that can be updated are:
--     Description
--     Realtime exchange direction
--     HEC-DSS filemanager URL
--     HEC-DSS file name
--   
--   Existing mappings are identified by the combination of the CWMS timeseries
--   identifier and the HEC-DSS pathname.  Items that can be updated are:
--     HEC-DSS timeseries data type
--     HEC-DSS data units
--     HEC-DSS timezone
--     HEC-DSS timezone-usage
--   
   procedure put_dss_xchg_sets(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_xml_clob          in out nocopy clob,
      p_store_rule        in  varchar2 default 'MERGE');
      
--------------------------------------------------------------------------------
-- PROCEDURE UNMAP_ALL_TS_IN_XCHG_SET(...)
--
   procedure unmap_all_ts_in_xchg_set(
      p_dss_xchg_set_code   in   number);

--------------------------------------------------------------------------------
-- PROCEDURE DEL_UNUSED_DSS_XCHG_INFO(...)
--
   procedure del_unused_dss_xchg_info(
      p_office_id in varchar2 default null);

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
   p_engine_url  in varchar2,
   p_xchg_code   in integer,
   p_update_time in integer);

-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_engine_url      in varchar2,
   p_dss_xchg_set_id in varchar2,
   p_update_time     in integer,
   p_office_id       in varchar2 default null);

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REPLAY_DATA_MESSAGES(...)
--
function replay_data_messages(
   p_component       in varchar2,
   p_host            in varchar2,
   p_dss_xchg_set_id in varchar2,
   p_start_time      in integer  default null,
   p_end_time        in integer  default null,
   p_request_id      in varchar2 default null,
   p_office_id       in varchar2 default null)
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

end cwms_xchg;
/
commit;
show errors;


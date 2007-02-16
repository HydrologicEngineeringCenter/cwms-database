/* Formatted on 2006/05/09 18:31 (Formatter Plus v4.8.7) */
create or replace package cwms_dss
is
--------------------------------------------------------------------------------
--
-- In the create_xxx functions and procedures below, the p_fail_if_exists input
-- parameter specifies whether the routine should return the code of the existing
-- object or raise an exception if the object to create already exists in the
-- database.  The default is to return the code of the existing object.
--
--------------------------------------------------------------------------------
-- function create_dss_xchg_set
--
   function create_dss_xchg_set(
      p_dss_xchg_set_id   in   varchar2,
      p_description       in   varchar2,
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_realtime          in   varchar2 default null,
      p_fail_if_exists    in   number default cwms_util.false_num,
      p_office_id         in   varchar2 default null)
      return number;

--------------------------------------------------------------------------------
-- procedure create_dss_xchg_set
--
   procedure create_dss_xchg_set(
      p_dss_xchg_set_code   out      number,
      p_dss_xchg_set_id     in       varchar2,
      p_description         in       varchar2,
      p_dss_filemgr_url     in       varchar2,
      p_dss_file_name       in       varchar2,
      p_realtime            in       varchar2 default null,
      p_fail_if_exists      in       number default cwms_util.false_num,
      p_office_id           in       varchar2 default null);

-------------------------------------------------------------------------------
-- procedure delete_dss_xchg_set
--
   procedure delete_dss_xchg_set(
      p_dss_xchg_set_id   in   varchar2,
      p_office_id         in   varchar2 default null);

-------------------------------------------------------------------------------
-- procedure rename_dss_xchg_set
--
   procedure rename_dss_xchg_set(
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null);

-------------------------------------------------------------------------------
-- procedure duplicate_dss_xchg_set
--
   procedure duplicate_dss_xchg_set(
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null);

--------------------------------------------------------------------------------
-- function update_dss_xchg_set
--
   function update_dss_xchg_set(
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,                        
      p_last_update          in   timestamp,
      p_update_description   in   number default cwms_util.true_num,
      p_update_filemgr_url   in   number default cwms_util.true_num,
      p_update_file_name     in   number default cwms_util.true_num,
      p_update_realtime      in   number default cwms_util.true_num,
      p_update_last_update   in   number default cwms_util.true_num,
      p_office_id            in   varchar2 default null)
      return number;

--------------------------------------------------------------------------------
-- procedure update_dss_xchg_set
--
   procedure update_dss_xchg_set(
      p_dss_xchg_set_code    out  number,
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,
      p_last_update          in   timestamp,
      p_update_description   in   number default cwms_util.true_num,
      p_update_filemgr_url   in   number default cwms_util.true_num,
      p_update_file_name     in   number default cwms_util.true_num,
      p_update_realtime      in   number default cwms_util.true_num,
      p_update_last_update   in   number default cwms_util.true_num,
      p_office_id            in   varchar2 default null);

--------------------------------------------------------------------------------
-- procedure update_dss_xchg_set_time
--
   procedure update_dss_xchg_set_time(
      p_dss_xchg_set_code    in  number,
      p_last_update          in  timestamp);

--------------------------------------------------------------------------------
-- procedure map_ts_in_xchg_set
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
-- procedure unmap_ts_in_xchg_set(...)
--
   procedure unmap_ts_in_xchg_set(
      p_dss_xchg_set_code    in   number,
      p_cwms_ts_code         in   number,
      p_office_id            in   varchar2 default null);
   
--------------------------------------------------------------------------------
-- function get_dss_xchg_sets
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
   
--------------------------------------------------------------------------------
-- procedure put_dss_xchg_sets
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
-- procedure unmap_all_ts_in_xchg_set
--
   procedure unmap_all_ts_in_xchg_set(
      p_dss_xchg_set_code   in   number);

--------------------------------------------------------------------------------
-- procedure del_unused_dss_xchg_info
--
   procedure del_unused_dss_xchg_info(
      p_office_id in varchar2 default null);
end cwms_dss;
/

show errors;
commit ;

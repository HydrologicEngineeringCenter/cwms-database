/* Formatted on 2006/05/09 18:31 (Formatter Plus v4.8.7) */
create or replace package cwms_dss authid current_user
is
   true_num    constant number := 1;
   false_num   constant number := 0;

--------------------------------------------------------------------------------
--
-- In the create_xxx functions and procedures below, the p_fail_if_exists input
-- parameter specifies whether the routine should return the code of the existing
-- object or raise an exception if the object to create already exists in the
-- database.  The default is to return the code of the existing object.
--
--------------------------------------------------------------------------------
-- function create_dss_xchg_set(...)
--
   function create_dss_xchg_set(
      p_office_id         in   varchar2,
      p_dss_xchg_set_id   in   varchar2,
      p_description       in   varchar2,
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_realtime          in   varchar2 default null,
      p_fail_if_exists    in   number default false_num)
      return number;

--------------------------------------------------------------------------------
-- procedure create_dss_xchg_set(...)
--
   procedure create_dss_xchg_set(
      p_dss_xchg_set_code   out      number,
      p_office_id           in       varchar2,
      p_dss_xchg_set_id     in       varchar2,
      p_description         in       varchar2,
      p_dss_filemgr_url     in       varchar2,
      p_dss_file_name       in       varchar2,
      p_realtime            in       varchar2 default null,
      p_fail_if_exists      in       number default false_num);

-------------------------------------------------------------------------------
-- procedure delete_dss_xchg_set(...)
--
   procedure delete_dss_xchg_set(
      p_office_id         in   varchar2,
      p_dss_xchg_set_id   in   varchar2);

-------------------------------------------------------------------------------
-- procedure rename_dss_xchg_set(...)
--
   procedure rename_dss_xchg_set(
      p_office_id             in   varchar2,
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2);

-------------------------------------------------------------------------------
-- procedure duplicate_dss_xchg_set(...)
--
   procedure duplicate_dss_xchg_set(
      p_office_id             in   varchar2,
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2);

--------------------------------------------------------------------------------
-- function update_dss_xchg_set(...)
--
   function update_dss_xchg_set(
      p_office_id            in   varchar2,
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,
      p_update_description   in   number default true_num,
      p_update_filemgr_url   in   number default true_num,
      p_update_file_name     in   number default true_num,
      p_update_realtime      in   number default true_num)
      return number;

--------------------------------------------------------------------------------
-- procedure update_dss_xchg_set(...)
--
   procedure update_dss_xchg_set(
      p_dss_xchg_set_code    out      number,
      p_office_id            in       varchar2,
      p_dss_xchg_set_id      in       varchar2,
      p_description          in       varchar2,
      p_dss_filemgr_url      in       varchar2,
      p_dss_file_name        in       varchar2,
      p_realtime             in       varchar2,
      p_update_description   in       number default true_num,
      p_update_filemgr_url   in       number default true_num,
      p_update_file_name     in       number default true_num,
      p_update_realtime      in       number default true_num);

--------------------------------------------------------------------------------
-- procedure map_ts_in_xchg_set(...)
--
   procedure map_ts_in_xchg_set(
      p_dss_xchg_set_code    in   number,
      p_office_id            in   varchar2,
      p_cwms_ts_id           in   varchar2,
      p_dss_pathname         in   varchar2,
      p_dss_parameter_type   in   varchar2 default null,
      p_units                in   varchar2 default null,
      p_timezone             in   varchar2 default null,
      p_tz_usage             in   varchar2 default null);

--------------------------------------------------------------------------------
-- procedure unmap_all_ts_in_xchg_set(...)
--
   procedure unmap_all_ts_in_xchg_set(
      p_dss_xchg_set_code   in   number);

--------------------------------------------------------------------------------
-- procedure del_unused_dss_xchg_info(...)
--
   procedure del_unused_dss_xchg_info;
end cwms_dss;
/

show errors;
grant execute on cwms_dss to wcviewer;
commit ;

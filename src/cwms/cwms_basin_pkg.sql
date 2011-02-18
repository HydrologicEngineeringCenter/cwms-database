create or replace package cwms_basin as
--------------------------------------------------------------------------------
-- function get_basin_code
--------------------------------------------------------------------------------
function get_basin_code(
   p_basin_id  in varchar2,
   p_office_id in varchar2 default null)
   return number;
      
--------------------------------------------------------------------------------
-- procedure store_basin
--------------------------------------------------------------------------------
procedure store_basin(
   p_basin_id                   in varchar2,
   p_fail_if_exists             in varchar2,
   p_ignore_nulls               in varchar2,
   p_parent_basin_id            in varchar2 default null,
   p_sort_order                 in binary_double default null,
   p_primary_stream_id          in varchar2 default null,
   p_total_drainage_area        in binary_double default null,
   p_contributing_drainage_area in binary_double default null,
   p_area_unit                  in varchar2 default null,
   p_office_id                  in varchar2 default null);
      
--------------------------------------------------------------------------------
-- procedure retrieve_basin
--------------------------------------------------------------------------------
procedure retrieve_basin(
   p_parent_basin_id            out varchar2,
   p_sort_order                 out binary_double,
   p_primary_stream_id          out varchar2,
   p_total_drainage_area        out binary_double,
   p_contributing_drainage_area out binary_double,
   p_basin_id                   in  varchar2,
   p_area_unit                  in  varchar2,
   p_office_id                  in  varchar2 default null);
      
--------------------------------------------------------------------------------
-- procedure delete_basin
--------------------------------------------------------------------------------
procedure delete_basin(
   p_basin_id      in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
      
--------------------------------------------------------------------------------
-- procedure rename_basin
--------------------------------------------------------------------------------
procedure rename_basin(
   p_old_basin_id in varchar2,
   p_new_basin_id in varchar2,
   p_office_id    in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure cat_basins
--
-- the catalog contains the following fields, sorted by the first 4
--
--    office_id                  varchar2(16)
--    basin_id                   varchar2(49)
--    parent_basin_id            varchar2(49)
--    sort_order                 binary_double
--    primary_stream_id          varchar2(49)
--    total_drainage_area        binary_double
--    contributing_drainage_area binary_double
--    area_unit                  varchar2(16)
--
--------------------------------------------------------------------------------
procedure cat_basins(
   p_basins_catalog         out sys_refcursor,
   p_basin_id_mask          in  varchar2 default '*',
   p_parent_basin_id_mask   in  varchar2 default '*',
   p_primary_stream_id_mask in  varchar2 default '*',
   p_area_unit              in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null);

--------------------------------------------------------------------------------
-- function cat_basins_f
--
-- the catalog contains the following fields, sorted by the first 4
--
--    office_id                  varchar2(16)
--    basin_id                   varchar2(49)
--    parent_basin_id            varchar2(49)
--    sort_order                 binary_double
--    primary_stream_id          varchar2(49)
--    total_drainage_area        binary_double
--    contributing_drainage_area binary_double
--    area_unit                  varchar2(16)
--
--------------------------------------------------------------------------------
function cat_basins_f(
   p_basin_id_mask          in varchar2 default '*',
   p_parent_basin_id_mask   in varchar2 default '*',
   p_primary_stream_id_mask in varchar2 default '*',
   p_area_unit              in varchar2 default null,
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- procedure get_runoff_volume
--------------------------------------------------------------------------------
procedure get_runoff_volume(
   p_runoff_volume       out binary_double,
   p_basin_id            in  varchar2,
   p_precip_excess_depth in  binary_double,
   p_precip_unit         in  varchar2,
   p_volume_unit         in  varchar2,
   p_office_id           in  varchar2 default null);

--------------------------------------------------------------------------------
-- function get_runoff_volume_f
--------------------------------------------------------------------------------
function get_runoff_volume_f(
   p_basin_id            in varchar2,
   p_precip_excess_depth in binary_double,
   p_precip_unit         in varchar2,
   p_volume_unit         in varchar2,
   p_office_id           in varchar2 default null)
   return binary_double;
         
end cwms_basin;
/
show errors;
create or replace package cwms_stream
as
   
--------------------------------------------------------------------------------
-- procedure get_stream_code
--------------------------------------------------------------------------------
function get_stream_code(
   p_office_id in varchar2,
   p_stream_id in varchar2)
   return number;

--------------------------------------------------------------------------------
-- procedure store_stream
--------------------------------------------------------------------------------
procedure store_stream(
   p_stream_id            in varchar2,
   p_fail_if_exists       in varchar2,
   p_ignore_nulls         in varchar2,
   p_station_units        in varchar2 default null,
   p_stationing_starts_ds in varchar2 default null,
   p_flows_into_stream    in varchar2 default null,
   p_flows_into_station   in binary_double default null,
   p_flows_into_bank      in varchar2 default null,
   p_diverts_from_stream  in varchar2 default null,
   p_diverts_from_station in binary_double default null,
   p_diverts_from_bank    in varchar2 default null,
   p_length               in binary_double default null,
   p_average_slope        in binary_double default null,
   p_comments             in varchar2 default null,
   p_office_id            in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure retrieve_stream
--------------------------------------------------------------------------------
procedure retrieve_stream(
   p_stationing_starts_ds out varchar2,
   p_flows_into_stream    out varchar2,
   p_flows_into_station   out binary_double,
   p_flows_into_bank      out varchar2,
   p_diverts_from_stream  out varchar2,
   p_diverts_from_station out binary_double,
   p_diverts_from_bank    out varchar2,
   p_length               out binary_double,
   p_average_slope        out binary_double,
   p_comments             out varchar2 ,
   p_stream_id            in  varchar2,
   p_station_units        in  varchar2,
   p_office_id            in  varchar2 default null);

--------------------------------------------------------------------------------
-- procedure delete_stream
--------------------------------------------------------------------------------
procedure delete_stream(
   p_stream_id     in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure rename_stream
--------------------------------------------------------------------------------
procedure rename_stream(
   p_old_stream_id in varchar2,
   p_new_stream_id in varchar2,
   p_office_id     in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure cat_streams
--
-- catalog has the following fields, sorted ascending by office_id and stream_id
--
--    office_id            varchar2(16)
--    stream_id            varchar2(49)
--    stationing_starts_ds varchar2(1)
--    flows_into_stream    varchar2(49)
--    flows_into_station   binary_double
--    flows_into_bank      varchar2(1) 
--    diverts_from_stream  varchar2(49)
--    diverts_from_station binary_double
--    diverts_from_bank    varchar2(1)
--    stream_length        binary_double
--    average_slope        binary_double
--    comments             varchar2(256) 
--
--------------------------------------------------------------------------------
procedure cat_streams(          
   p_stream_catalog              out sys_refcursor,
   p_stream_id_mask              in  varchar2 default '*',
   p_station_units               in  varchar2 default 'km',
   p_stationing_starts_ds_mask   in  varchar2 default '*',
   p_flows_into_stream_id_mask   in  varchar2 default '*',
   p_flows_into_station_min      in  binary_double default null,
   p_flows_into_station_max      in  binary_double default null,
   p_flows_into_bank_mask        in  varchar2 default '*',
   p_diverts_from_stream_id_mask in  varchar2 default '*',
   p_diverts_from_station_min    in  binary_double default null,
   p_diverts_from_station_max    in  binary_double default null,
   p_diverts_from_bank_mask      in  varchar2 default '*',
   p_length_min                  in  binary_double default null,
   p_length_max                  in  binary_double default null,
   p_average_slope_min           in  binary_double default null,
   p_average_slope_max           in  binary_double default null,
   p_comments_mask               in  varchar2 default '*',
   p_office_id_mask              in  varchar2 default null);

--------------------------------------------------------------------------------
-- function cat_streams_f
--
-- catalog has the following fields, sorted ascending by office_id and stream_id
--
--    office_id            varchar2(16)
--    stream_id            varchar2(49)
--    stationing_starts_ds varchar2(1)
--    flows_into_stream    varchar2(49)
--    flows_into_station   binary_double
--    flows_into_bank      varchar2(1) 
--    diverts_from_stream  varchar2(49)
--    diverts_from_station binary_double
--    diverts_from_bank    varchar2(1)
--    stream_length        binary_double
--    average_slope        binary_double
--    comments             varchar2(256) 
--
--------------------------------------------------------------------------------
function cat_streams_f(          
   p_stream_id_mask              in varchar2 default '*',
   p_station_units               in varchar2 default 'km',
   p_stationing_starts_ds_mask   in varchar2 default '*',
   p_flows_into_stream_id_mask   in varchar2 default '*',
   p_flows_into_station_min      in binary_double default null,
   p_flows_into_station_max      in binary_double default null,
   p_flows_into_bank_mask        in varchar2 default '*',
   p_diverts_from_stream_id_mask in varchar2 default '*',
   p_diverts_from_station_min    in binary_double default null,
   p_diverts_from_station_max    in binary_double default null,
   p_diverts_from_bank_mask      in varchar2 default '*',
   p_length_min                  in binary_double default null,
   p_length_max                  in binary_double default null,
   p_average_slope_min           in binary_double default null,
   p_average_slope_max           in binary_double default null,
   p_comments_mask               in varchar2 default '*',
   p_office_id_mask              in varchar2 default null)
   return sys_refcursor;
   
--------------------------------------------------------------------------------
-- procedure store_stream_reach
--------------------------------------------------------------------------------
procedure store_stream_reach(
   p_stream_id          in varchar2,
   p_reach_id           in varchar2,
   p_fail_if_exists     in varchar2,
   p_ignore_nulls       in varchar2,
   p_upstream_station   in binary_double,
   p_downstream_station in binary_double,
   p_stream_type_id     in varchar2 default null,
   p_comments           in varchar2 default null,
   p_office_id          in varchar2 default null);
   
--------------------------------------------------------------------------------
-- procedure retrieve_stream_reach
--------------------------------------------------------------------------------
procedure retrieve_stream_reach(
   p_upstream_station   out binary_double,
   p_downstream_station out binary_double,
   p_stream_type_id     out varchar2,
   p_comments           out varchar2,
   p_stream_id          in  varchar2,
   p_reach_id           in  varchar2,
   p_office_id          in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- procedure delete_stream_reach
--------------------------------------------------------------------------------
procedure delete_stream_reach(
   p_stream_id in varchar2,
   p_reach_id  in varchar2,
   p_office_id in varchar2 default null);
   
--------------------------------------------------------------------------------
-- procedure rename_stream_reach
--------------------------------------------------------------------------------
procedure rename_stream_reach(
   p_stream_id    in varchar2,
   p_old_reach_id in varchar2,
   p_new_reach_id in varchar2,
   p_office_id    in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure cat_stream_reaches
--
-- catalog has the following fields, sorted by first 3 fields
--
--    office_id            varchar2(16)
--    stream_id            varchar2(49)
--    stream_reach_id      varchar2(64)
--    upstream_station     binary_double
--    downstream_station   binary_double
--    stream_type_id       varchar2(4)
--    comments             varchar2(256)
--------------------------------------------------------------------------------
procedure cat_stream_reaches(
   p_reach_catalog       out sys_refcursor,
   p_stream_id_mask      in  varchar2 default '*',
   p_reach_id_mask       in  varchar2 default '*',
   p_stream_type_id_mask in  varchar2 default '*',
   p_comments_mask       in  varchar2 default '*',
   p_office_id_mask      in  varchar2 default null);

--------------------------------------------------------------------------------
-- function cat_stream_reaches_f
--
-- catalog has the following fields, sorted by first 3 fields
--
--    office_id            varchar2(16)
--    stream_id            varchar2(49)
--    stream_reach_id      varchar2(64)
--    upstream_station     binary_double
--    downstream_station   binary_double
--    stream_type_id       varchar2(4)
--    comments             varchar2(256)
--------------------------------------------------------------------------------
function cat_stream_reaches_f(
   p_stream_id_mask      in varchar2 default '*',
   p_reach_id_mask       in varchar2 default '*',
   p_stream_type_id_mask in varchar2 default '*',
   p_comments_mask       in varchar2 default '*',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor;
   
--------------------------------------------------------------------------------
-- procedure store_stream_location   
--------------------------------------------------------------------------------
procedure store_stream_location(
   p_location_id             in varchar2,
   p_stream_id               in varchar2,
   p_fail_if_exists          in varchar2,
   p_ignore_nulls            in varchar2,
   p_station                 in binary_double,
   p_station_unit            in varchar2,
   p_published_station       in binary_double default null,
   p_navigation_station      in binary_double default null,
   p_bank                    in varchar2 default null,
   p_lowest_measurable_stage in binary_double default null,
   p_stage_unit              in varchar2 default null,
   p_drainage_area           in binary_double default null,
   p_ungaged_drainage_area   in binary_double default null,
   p_area_unit               in varchar2 default null,
   p_office_id               in varchar2 default null);
   
--------------------------------------------------------------------------------
-- procedure retrieve_stream_location   
--------------------------------------------------------------------------------
procedure retrieve_stream_location(
   p_station                 out binary_double,
   p_published_station       out binary_double,
   p_navigation_station      out binary_double,
   p_bank                    out varchar2,
   p_lowest_measurable_stage out binary_double,
   p_drainage_area           out binary_double,
   p_ungaged_drainage_area   out binary_double,
   p_location_id             in  varchar2,
   p_stream_id               in  varchar2,
   p_station_unit            in  varchar2,
   p_stage_unit              in  varchar2,
   p_area_unit               in  varchar2,
   p_office_id               in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- procedure delete_stream_location   
--------------------------------------------------------------------------------
procedure delete_stream_location(
   p_location_id in  varchar2,
   p_stream_id   in  varchar2,
   p_office_id   in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- procedure cat_stream_locations
--
-- catalog includes, sorted by office_id, stream_id, station, location_id
--
--    office_id               varchar2(16)
--    stream_id               varchar2(49)
--    location_id             varchar2(49)
--    station                 binary_double
--    published_station       binary_double
--    navigation_station      binary_double
--    bank                    varchar2(1)
--    lowest_measurable_stage binary_double
--    drainage_area           binary_double
--    ungaged_area            binary_double
--    station_unit            varchar2(16)
--    stage_unit              varchar2(16)
--    area_unit               varchar2(16)
--
--------------------------------------------------------------------------------
procedure cat_stream_locations(
   p_stream_location_catalog out sys_refcursor,
   p_stream_id_mask          in  varchar2 default '*',
   p_location_id_mask        in  varchar2 default '*',
   p_station_unit            in  varchar2 default null,
   p_stage_unit              in  varchar2 default null,
   p_area_unit               in  varchar2 default null,
   p_office_id_mask          in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- function cat_stream_locations_f   
--
-- catalog includes, sorted by office_id, stream_id, station, location_id
--
--    office_id               varchar2(16)
--    stream_id               varchar2(49)
--    location_id             varchar2(49)
--    station                 binary_double
--    published_station       binary_double
--    navigation_station      binary_double
--    bank                    varchar2(1)
--    lowest_measurable_stage binary_double
--    drainage_area           binary_double
--    ungaged_area            binary_double
--    station_unit            varchar2(16)
--    stage_unit              varchar2(16)
--    area_unit               varchar2(16)
--
--------------------------------------------------------------------------------
function cat_stream_locations_f(
   p_stream_id_mask   in  varchar2 default '*',
   p_location_id_mask in  varchar2 default '*',
   p_station_unit     in  varchar2 default null,
   p_stage_unit       in  varchar2 default null,
   p_area_unit        in  varchar2 default null,
   p_office_id_mask   in  varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- procedure get_us_locations 
--------------------------------------------------------------------------------
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);

--------------------------------------------------------------------------------
-- funtion get_us_locations_f 
--------------------------------------------------------------------------------
function get_us_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;

--------------------------------------------------------------------------------
-- procedure get_ds_locations 
--------------------------------------------------------------------------------
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);

--------------------------------------------------------------------------------
-- funtion get_ds_locations_f 
--------------------------------------------------------------------------------
function get_ds_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;

--------------------------------------------------------------------------------
-- procedure get_us_locations 
--------------------------------------------------------------------------------
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_location_id      in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);

--------------------------------------------------------------------------------
-- funtion get_us_locations_f 
--------------------------------------------------------------------------------
function get_us_locations_f(
   p_stream_id        in varchar2,
   p_location_id      in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;

--------------------------------------------------------------------------------
-- procedure get_ds_locations 
--------------------------------------------------------------------------------
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_location_id      in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);

--------------------------------------------------------------------------------
-- funtion get_ds_locations_f 
--------------------------------------------------------------------------------
function get_ds_locations_f(
   p_stream_id        in varchar2,
   p_location_id      in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;

end cwms_stream;
/
show errors;
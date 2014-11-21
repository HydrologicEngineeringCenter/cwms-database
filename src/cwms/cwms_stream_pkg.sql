set define off
create or replace package cwms_stream
/**
 * Facilities for working with streams, stream reaches, and stream locations
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.1
 */
as
-- not documented
function get_stream_code(
   p_office_id in varchar2,
   p_stream_id in varchar2)
   return number;
/**
 * Stores a stream to the database
 *
 * @param p_stream_id            The stream location identifier
 * @param p_fail_if_exists       A flag ('T' or 'F') that specifies whether the routine should fail if the specified stream already exists in the database
 * @param p_ignore_nulls         A flag ('T' or 'F') that specifies whether to ignore NULL values when updating. If 'T' no data will be overwritten with a NULL
 * @param p_station_units        The unit for stream stationing
 * @param p_stationing_starts_ds A flag ('T' or 'F') that specifies if the zero station is at the downstream-most point. If 'F' stationing starts upstream instead
 * @param p_flows_into_stream    The location identifier of the receiving stream this stream flows into, if any
 * @param p_flows_into_station   The station on the receiving stream, if any, of the confluence with this stream
 * @param p_flows_into_bank      The bank ('L' or 'R') on the receiving stream, if any, of the confluence with this steream
 * @param p_diverts_from_stream  The location identifier of the source stream this stream diverts from, if any
 * @param p_diverts_from_station The station on the source stream, if any, of the diversion into this stream
 * @param p_diverts_from_bank    The bank ('L' or 'R') on the source stream, if any, of the diversion into this stream
 * @param p_length               The length of the stream, in station unit
 * @param p_average_slope        The average slope of the stream
 * @param p_comments             Any comments about the stream
 * @param p_office_id            The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified stream already exists in the database
 */
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
/**
 * Retrieves a stream from the database
 *
 * @param p_stationing_starts_ds A flag ('T' or 'F') that specifies if the zero station is at the downstream-most point. If 'F' stationing starts upstream instead
 * @param p_flows_into_stream    The location identifier of the receiving stream this stream flows into, if any
 * @param p_flows_into_station   The station on the receiving stream, if any, of the confluence with this stream
 * @param p_flows_into_bank      The bank ('L' or 'R') on the receiving stream, if any, of the confluence with this steream
 * @param p_diverts_from_stream  The location identifier of the source stream this stream diverts from, if any
 * @param p_diverts_from_station The station on the source stream, if any, of the diversion into this stream
 * @param p_diverts_from_bank    The bank ('L' or 'R') on the source stream, if any, of the diversion into this stream
 * @param p_length               The length of the stream, in station unit
 * @param p_average_slope        The average slope of the stream
 * @param p_comments             Any comments about the stream
 * @param p_stream_id            The stream location identifier
 * @param p_station_units        The unit for stream stationing
 * @param p_office_id            The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
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
/**
 * Deletes a stream from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_stream_id      The stream location identifier
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only this stream, and then only if it has no referring data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only data that refers to this stream, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this stream and all data that refers to it</td>
 *   </tr>
 * </table>
 * @param p_office_id      The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
procedure delete_stream(
   p_stream_id      in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Deletes a stream from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_stream_id The location identifier of the stream
 *
 * @param p_delete_action Specifies what stream elements to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only this stream, and then only if it has no dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only dependent data of this stream, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes this stream and its dependent data, if any</td>
 *   </tr>
 * </table>
 * @param p_delete_location A flag (T/F) that indicates whether the underlying location should be deleted.
 * @param p_delete_location_action Specifies what location elements to delete.  Actions are as follows (only if p_delete_location is 'T'):
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the location, does not delete any dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only dependent data but does not delete the actual location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">delete the location and all dependent data</td>
 *   </tr>
 * </table>
 * @param p_office_id The office that owns the stream location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such stream location exists
 */
procedure delete_stream2(
   p_stream_id              in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null);
/**
 * Renames a stream in the database
 *
 * @param old_p_stream_id  The existing stream location identifier
 * @param new_p_stream_id  The new stream location identifier
 * @param p_office_id      The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
procedure rename_stream(
   p_old_stream_id in varchar2,
   p_new_stream_id in varchar2,
   p_office_id     in varchar2 default null);
/**
 * Catalogs streams in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">stationing_starts_ds</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">Specifies whether the zero station is at the downstream most end</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">flows_into_stream</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the receiving stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">flows_into_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The station on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">flows_into_bank</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The bank on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">diverts_from_stream</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the diverting stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">diverts_from_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The station on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">diverts_from_bank</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The bank on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">stream_length</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The length of this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">average_slope</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The average slope of this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">comments</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">Any comments for this stream</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_station_units The units for stations and length
 *
 * @param p_stationing_starts_ds_mask  The stream location pattern to match. Use 'T', 'F', or '*'
 *
 * @param p_flows_into_stream_id_mask  The receiving stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_flows_into_station_min The minimum station on the receiving stream, if any, to match
 *
 * @param p_flows_into_station_max The maximum station on the receiving stream, if any, to match
 *
 * @param p_flows_into_bank_mask The bank on the receiving stream, if any, to match. Use 'L', 'R', or '*'
 *
 * @param p_diverts_from_stream_id_mask  The diverting stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_diverts_from_station_min The minimum station on the diverting stream, if any, to match
 *
 * @param p_diverts_from_station_max The maximum station on the diverting stream, if any, to match
 *
 * @param p_diverts_from_bank_mask The bank on the diverting stream, if any, to match. Use 'L', 'R', or '*'
 *
 * @param p_length_min The minimum stream length to match
 *
 * @param p_length_max The maximum stream length to match
 *
 * @param p_average_slope_min The minimum average slope to match
 *
 * @param p_average_slope_max The maximum average slope to match
 *
 * @param p_comments_mask  The comments pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
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
/**
 * Catalogs streams in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_station_units The units for stations and length
 *
 * @param p_stationing_starts_ds_mask  The stream location pattern to match. Use 'T', 'F', or '*'
 *
 * @param p_flows_into_stream_id_mask  The receiving stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_flows_into_station_min The minimum station on the receiving stream, if any, to match
 *
 * @param p_flows_into_station_max The maximum station on the receiving stream, if any, to match
 *
 * @param p_flows_into_bank_mask The bank on the receiving stream, if any, to match. Use 'L', 'R', or '*'
 *
 * @param p_diverts_from_stream_id_mask  The diverting stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_diverts_from_station_min The minimum station on the diverting stream, if any, to match
 *
 * @param p_diverts_from_station_max The maximum station on the diverting stream, if any, to match
 *
 * @param p_diverts_from_bank_mask The bank on the diverting stream, if any, to match. Use 'L', 'R', or '*'
 *
 * @param p_length_min The minimum stream length to match
 *
 * @param p_length_max The maximum stream length to match
 *
 * @param p_average_slope_min The minimum average slope to match
 *
 * @param p_average_slope_max The maximum average slope to match
 *
 * @param p_comments_mask  The comments pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">stationing_starts_ds</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">Specifies whether the zero station is at the downstream most end</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">flows_into_stream</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the receiving stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">flows_into_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The station on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">flows_into_bank</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The bank on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">diverts_from_stream</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the diverting stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">diverts_from_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The station on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">diverts_from_bank</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The bank on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">stream_length</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The length of this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">average_slope</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The average slope of this stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">comments</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">Any comments for this stream</td>
 *   </tr>
 * </table>
 */
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
/**
 * Stores a stream reach to the database
 *
 * @param p_stream_id          The stream location identifier
 * @param p_reach_id           The stream reach identifier (unique per stream)
 * @param p_fail_if_exists     A flag ('T' or 'F') that specifies whether the routine should fail if the specified stream reach already exists in the database
 * @param p_ignore_nulls       A flag ('T' or 'F') that specifies whether to ignore NULL values when updating. If 'T' no data will be overwritten with a NULL
 * @param p_upstream_station   The upstream station of the stream reach
 * @param p_downstream_station The downstream station of the stream reach
 * @param p_stream_type_id     The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> for this reach
 * @param p_comments           Any comments for the stream reach
 * @param p_office_id          The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
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
/**
 * Retrieves a stream reach from the database
 *
 * @param p_upstream_station   The upstream station of the stream reach
 * @param p_downstream_station The downstream station of the stream reach
 * @param p_stream_type_id     The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> for this reach
 * @param p_comments           Any comments for the stream reach
 * @param p_stream_id          The stream location identifier
 * @param p_reach_id           The stream reach identifier
 * @param p_office_id          The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_stream_reach(
   p_upstream_station   out binary_double,
   p_downstream_station out binary_double,
   p_stream_type_id     out varchar2,
   p_comments           out varchar2,
   p_stream_id          in  varchar2,
   p_reach_id           in  varchar2,
   p_office_id          in  varchar2 default null);
/**
 * Deletes a stream reach from the database
 *
 * @param p_stream_id          The stream location identifier
 * @param p_reach_id           The stream reach identifier
 * @param p_office_id          The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
procedure delete_stream_reach(
   p_stream_id in varchar2,
   p_reach_id  in varchar2,
   p_office_id in varchar2 default null);
/**
 * Renames a stream reach in database
 *
 * @param p_stream_id          The stream location identifier
 * @param p_old_reach_id       The existing stream reach identifier
 * @param p_new_reach_id       The new stream reach identifier
 * @param p_office_id          The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
procedure rename_stream_reach(
   p_stream_id    in varchar2,
   p_old_reach_id in varchar2,
   p_new_reach_id in varchar2,
   p_office_id    in varchar2 default null);
/**
 * Catalogs stream reaches in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_reach_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">stream_reach_id</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The stream reach identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">upstream_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The upstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">downstream_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The downstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">stream_type_id</td>
 *     <td class="descr">varchar2(4)</td>
 *     <td class="descr">The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> of the reach</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">comments</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">Any comments for this stream</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_reach_id_mask  The stream reach pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_reach_id_mask  The stream type pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
  * @param p_comments_mask  The comments pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_stream_reaches(
   p_reach_catalog       out sys_refcursor,
   p_stream_id_mask      in  varchar2 default '*',
   p_reach_id_mask       in  varchar2 default '*',
   p_stream_type_id_mask in  varchar2 default '*',
   p_comments_mask       in  varchar2 default '*',
   p_office_id_mask      in  varchar2 default null);
/**
 * Catalogs stream reaches in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_reach_id_mask  The stream reach pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_reach_id_mask  The stream type pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_comments_mask  The comments pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_reach_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">stream_reach_id</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The stream reach identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">upstream_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The upstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">downstream_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The downstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">stream_type_id</td>
 *     <td class="descr">varchar2(4)</td>
 *     <td class="descr">The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> of the reach</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">comments</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">Any comments for this stream</td>
 *   </tr>
 * </table>
 */
function cat_stream_reaches_f(
   p_stream_id_mask      in varchar2 default '*',
   p_reach_id_mask       in varchar2 default '*',
   p_stream_type_id_mask in varchar2 default '*',
   p_comments_mask       in varchar2 default '*',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor;
/**
 * Stores information about a location on a stream
 *
 * @param p_location_id             The identifier of the location on the stream
 * @param p_stream_id               The identifier of the stream
 * @param p_fail_if_exists          A flag ('T' or 'F') that specifies whether the routine should fail if the specified stream location already exists in the database
 * @param p_ignore_nulls            A flag ('T' or 'F') that specifies whether to ignore NULL values when updating. If 'T' no data will be overwritten with a NULL
 * @param p_station                 The actual station on the stream of the location
 * @param p_station_unit            The station unit
 * @param p_published_station       The published station on the stream of the locaton, if different from the actual station
 * @param p_navigation_station      The navigation station on the stream of the locaton, if different from the actual station
 * @param p_bank                    The stream bank ('L' or 'R') of the location on the stream, if applicable
 * @param p_lowest_measurable_stage The lowest stage of the stream that is measurable at the stream location
 * @param p_stage_unit              The stage unit
 * @param p_drainage_area           The total drainage area above the stream location
 * @param p_ungaged_drainage_area   The drainage area above the stream location that is ungaged
 * @param p_area_unit               The area unit
 * @param p_office_id               The office that owns the stream and location. If not specified or NULL, the session user's default office is used.
 */
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
/**
 * Retrieves information about a location on a stream
 *
 * @param p_station                 The actual station on the stream of the location
 * @param p_published_station       The published station on the stream of the locaton, if different from the actual station
 * @param p_navigation_station      The navigation station on the stream of the locaton, if different from the actual station
 * @param p_bank                    The stream bank ('L' or 'R') of the location on the stream, if applicable
 * @param p_lowest_measurable_stage The lowest stage of the stream that is measurable at the stream location
 * @param p_drainage_area           The total drainage area above the stream location
 * @param p_ungaged_drainage_area   The drainage area above the stream location that is ungaged
 * @param p_location_id             The identifier of the location on the stream
 * @param p_stream_id               The identifier of the stream
 * @param p_station_unit            The station unit
 * @param p_stage_unit              The stage unit
 * @param p_area_unit               The area unit
 * @param p_office_id               The office that owns the stream and location. If not specified or NULL, the session user's default office is used.
 */
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
/**
 * Deletes information about a location on a stream
 *
 * @param p_location_id  The identifier of the location on the stream
 * @param p_stream_id    Unused. Since a location is allowed to be on only one stream (and storing with a different stream updates instead of inserts) this is not needed.
 *                       It also allows a delete action (also unused since there is no dependent data) to be specified in keeping with the format of delete_stream.
 * @param p_office_id    The office that owns the stream and location. If not specified or NULL, the session user's default office is used.
 */
procedure delete_stream_location(
   p_location_id in  varchar2,
   p_stream_id   in  varchar2,
   p_office_id   in  varchar2 default null);
/**
 * Deletes a stream location from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_location_id The location identifier of the location
 *
 * @param p_delete_action Specifies what stream elements to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only this stream location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">does nothing since stream locations have no dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">same as cwms_util.delete_key</td>
 *   </tr>
 * </table>
 * @param p_delete_location A flag (T/F) that indicates whether the underlying location should be deleted.
 * @param p_delete_location_action Specifies what location elements to delete.  Actions are as follows (only if p_delete_location is 'T'):
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the location, does not delete any dependent data</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only dependent data but does not delete the actual location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">delete the location and all dependent data</td>
 *   </tr>
 * </table>
 * @param p_office_id The office that owns the stream location
 *
 * @exception ITEM_DOES_NOT_EXIST if no such stream location exists
 */
procedure delete_stream_location2(
   p_location_id            in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null);
/**
 * Catalogs streams in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_location_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the stream and location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the location on the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The actual stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">published_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The published stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">navigation_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The navigation stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">bank</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The stream bank of the location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">lowest_measurable_stage</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The lowest stream stage at this location that can be measured</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The total drainage area above this location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">ungaged_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The drainage area above this location that is ungaged</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">station_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The station unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">stage_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The stage unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">area_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The area unit</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_id_mask  The stream pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_location_id_mask The location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_station_unit The units for stations
 *
 * @param p_stage_unit The units for stage
 *
 * @param p_area_unit The units for area
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_stream_locations(
   p_stream_location_catalog out sys_refcursor,
   p_stream_id_mask          in  varchar2 default '*',
   p_location_id_mask        in  varchar2 default '*',
   p_station_unit            in  varchar2 default null,
   p_stage_unit              in  varchar2 default null,
   p_area_unit               in  varchar2 default null,
   p_office_id_mask          in  varchar2 default null);
/**
 * Catalogs streams in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_id_mask  The stream pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_location_id_mask The location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_station_unit The units for stations
 *
 * @param p_stage_unit The units for stage
 *
 * @param p_area_unit The units for area
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the stream and location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the location on the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The actual stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">published_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The published stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">navigation_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The navigation stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">bank</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The stream bank of the location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">lowest_measurable_stage</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The lowest stream stage at this location that can be measured</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The total drainage area above this location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">ungaged_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The drainage area above this location that is ungaged</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">station_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The station unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">stage_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The stage unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">area_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The area unit</td>
 *   </tr>
 * </table>
 */
function cat_stream_locations_f(
   p_stream_id_mask   in  varchar2 default '*',
   p_location_id_mask in  varchar2 default '*',
   p_station_unit     in  varchar2 default null,
   p_stage_unit       in  varchar2 default null,
   p_area_unit        in  varchar2 default null,
   p_office_id_mask   in  varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves the next or all stream location(s) upstream from a stream station
 *
 * @param p_us_locations     A collection containing the upstream location(s)
 * @param p_stream_id        The stream identifier
 * @param p_station          The station on the stream to retrieve location(s) upstream from
 * @param p_station_unit     The station unit
 * @param p_all_us_locations A flag ('T' or 'F') specifying whether to retrieve only the next upstream location ('F') or all upstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 */
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);
/**
 * Retrieves the next or all stream location(s) upstream from a stream station
 *
 * @param p_stream_id        The stream identifier
 * @param p_station          The station on the stream to retrieve location(s) upstream from
 * @param p_station_unit     The station unit
 * @param p_all_us_locations A flag ('T' or 'F') specifying whether to retrieve only the next upstream location ('F') or all upstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 *
 * @return A collection containing the upstream location(s)
 */
function get_us_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;
/**
 * Retrieves the next or all stream location(s) downstream from a stream station
 *
 * @param p_us_locations     A collection containing the downstream location(s)
 * @param p_stream_id        The stream identifier
 * @param p_station          The station on the stream to retrieve location(s) downstream from
 * @param p_station_unit     The station unit
 * @param p_all_ds_locations A flag ('T' or 'F') specifying whether to retrieve only the next downstream location ('F') or all downstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 */
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);
/**
 * Retrieves the next or all stream location(s) downstream from a stream station
 *
 * @param p_stream_id        The stream identifier
 * @param p_station          The station on the stream to retrieve location(s) downstream from
 * @param p_station_unit     The station unit
 * @param p_all_ds_locations A flag ('T' or 'F') specifying whether to retrieve only the next downstream location ('F') or all downstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 *
 * @return A collection containing the downstream location(s)
 */
function get_ds_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;
/**
 * Retrieves the next or all stream location(s) upstream from a stream location
 *
 * @param p_us_locations     A collection containing the upstream location(s)
 * @param p_stream_id        The stream identifier
 * @param p_location_id      The location on the stream to retrieve location(s) upstream from
 * @param p_all_us_locations A flag ('T' or 'F') specifying whether to retrieve only the next upstream location ('F') or all upstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 */
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_location_id      in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);
/**
 * Retrieves the next or all stream location(s) upstream from a stream location
 *
 * @param p_stream_id        The stream identifier
 * @param p_location_id      The location on the stream to retrieve location(s) upstream from
 * @param p_all_us_locations A flag ('T' or 'F') specifying whether to retrieve only the next upstream location ('F') or all upstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 *
 * @return A collection containing the upstream location(s)
 */
function get_us_locations_f(
   p_stream_id        in varchar2,
   p_location_id      in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;
/**
 * Retrieves the next or all stream location(s) downstream from a stream location
 *
 * @param p_us_locations     A collection containing the downstream location(s)
 * @param p_stream_id        The stream identifier
 * @param p_location_id      The location on the stream to retrieve location(s) downstream from
 * @param p_all_ds_locations A flag ('T' or 'F') specifying whether to retrieve only the next downstream location ('F') or all downstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 */
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_location_id      in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null);
/**
 * Retrieves the next or all stream location(s) downstream from a stream location
 *
 * @param p_stream_id        The stream identifier
 * @param p_location_id      The location on the stream to retrieve location(s) downstream from
 * @param p_all_ds_locations A flag ('T' or 'F') specifying whether to retrieve only the next downstream location ('F') or all downstream locations ('T')
 * @param p_office_id        The office owning the stream. If not specified or NULL, the session user's default office is used.
 *
 * @return A collection containing the downstream location(s)
 */
function get_ds_locations_f(
   p_stream_id        in varchar2,
   p_location_id      in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t;
/**
 * Stores one or more stream flow measurements specified in an XML document
 *
 * @param p_xml The XML document. This can be single measurement with the root element of &lt;stream-flow-measurement%gt; with the format shown below. To store more than one measurement, include multiple measurement XML elements inside a document with the root element of &lt;stream-flow-measurements%gt; (plural)<p>
 * <pre><big>
 * &lt;stream-flow-measurement office-id="SWT" height-unit="ft" flow-unit="cfs" used="true"&gt;
 *   &lt;location&gt;TULA&lt;/location&gt;
 *   &lt;number&gt;1737&lt;/number&gt;
 *   &lt;date&gt;2014-01-14T17:08:30Z&lt;/date&gt;
 *   &lt;agency&gt;USGS&lt;/agency&gt;
 *   &lt;party&gt;WZM/JEP&lt;/party&gt;                                                        
 *   &lt;gage-height&gt;.81&lt;/gage-height&gt;
 *   &lt;flow&gt;221&lt;/flow&gt;
 *   &lt;current-rating&gt;19.0&lt;/current-rating&gt;
 *   &lt;shift-used&gt;.88&lt;/shift-used&gt;
 *   &lt;percent-difference&gt;61.3&lt;/percent-difference&gt;
 *   &lt;quality&gt;Fair&lt;/quality&gt;
 *   &lt;delta-height&gt;-.02&lt;/delta-height&gt;
 *   &lt;delta-time&gt;1.07&lt;/delta-time&gt;
 *   &lt;control-condition&gt;CLER&lt;/control-condition&gt;
 *   &lt;flow-adjustment&gt;MEAS&lt;/flow-adjustment&gt;
 *   &lt;remarks/&gt;
 * &lt;/stream-flow-measurement&gt;
 * </big></pre>
 * @param p_fail_if_exists A flag (T/F) that specifies whether to fail if any of the specified measurements already exist in the database
 */
procedure store_streamflow_meas_xml(
   p_xml            in clob,
   p_fail_if_exists in varchar2);
/**
 * Retrieves stream flow measurements that match input criteria as a table of streamflow_meas_t objects
 *
 * @param p_location_id_mask A wildcard-enabled string used to match the location(s) to retrieve measurements for.  Matching is
 *                           accomplished with glob-style wildcards, as shown below, instead of sql-style wildcards
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 * @param p_unit_system      The unit system (EN/SI) to return the measurements in. If not specified, the measurements will be returned in English units 
 * @param p_min_date         The earliest date to return measurements for, in the time zone indicated by the p_time_zone parameters. If not specified, no earliest date will be used
 * @param p_max_date         The latest date to return measurements for, in the time zone indicated by the p_time_zone parameters. If not specified, no latest date will be used
 * @param p_min_height       The minimum gage height to return measurements for. If not specified, no minimum gage height will be used
 * @param p_max_height       The maximum gage height to return measurements for. If not specified, no maximum gage height will be used
 * @param p_min_flow         The minimum flow to return measurements for. If not specified, no minimum flow will be used
 * @param p_max_flow         The maximum flow to return measurements for. If not specified, no maximum flow will be used
 * @param p_min_num          The minimum measurement number to return measurements for. If not specified, no minimum measurement number will be used
 * @param p_max_num          The maximum measurement number to return measurements for. If not specified, no maximum measurement number will be used
 * @param p_agencies         The measuring agencies to return measurements for, as a comma-separated list. If not specified, measurements from any agency will be returned
 * @param p_qualities        The measurement qualities to return measurements for, as a comma-separated list. If not specified, measurements of any will be returned 
 * @param p_time_zone        The time zone for the p_min_date and p_max_date parameters. If not specified, the local time zone for each location will be used
 * @param p_office_id mask   A wildcard-enabled string used to match the location(s) to retrieve measurements for.  Matching is
 *                           accomplished with glob-style wildcards, as shown above, instead of sql-style wildcards. If not specified, the session user's default office is used. To
 *                           retrieve from all offices, use '*'
 *
 * @return The matching stream flow measurements
 */
function retrieve_streamflow_meas_objs(
   p_location_id_mask in varchar2,
   p_unit_system      in varchar2 default 'EN',
   p_min_date         in date default null,
   p_max_date         in date default null,
   p_min_height       in number default null,
   p_max_height       in number default null,
   p_min_flow         in number default null,
   p_max_flow         in number default null,
   p_min_num          in integer default null,
   p_max_num          in integer default null,
   p_agencies         in varchar2 default null,
   p_qualities        in varchar2 default null,
   p_time_zone        in varchar2 default null,
   p_office_id_mask   in varchar2 default null)
   return streamflow_meas_tab_t;
/**
 * Retrieves stream flow measurements that match input criteria as an XML document
 *
 * @param p_location_id_mask A wildcard-enabled string used to match the location(s) to retrieve measurements for.  Matching is
 *                           accomplished with glob-style wildcards, as shown below, instead of sql-style wildcards
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 * @param p_unit_system      The unit system (EN/SI) to return the measurements in.  If EN, height and flow must be specified in ft and cfs, otherwise they must be specified in m and cms. If not specified, the English unit system is used 
 * @param p_min_date         The earliest date to return measurements for, in the time zone indicated by the p_time_zone parameters. If not specified, no earliest date will be used
 * @param p_max_date         The latest date to return measurements for, in the time zone indicated by the p_time_zone parameters. If not specified, no latest date will be used
 * @param p_min_height       The minimum gage height to return measurements for. If not specified, no minimum gage height will be used
 * @param p_max_height       The maximum gage height to return measurements for. If not specified, no maximum gage height will be used
 * @param p_min_flow         The minimum flow to return measurements for. If not specified, no minimum flow will be used
 * @param p_max_flow         The maximum flow to return measurements for. If not specified, no maximum flow will be used
 * @param p_min_num          The minimum measurement number to return measurements for. If not specified, no minimum measurement number will be used
 * @param p_max_num          The maximum measurement number to return measurements for. If not specified, no maximum measurement number will be used
 * @param p_agencies         The measuring agencies to return measurements for, as a comma-separated list. If not specified, measurements from any agency will be returned
 * @param p_qualities        The measurement qualities to return measurements for, as a comma-separated list. If not specified, measurements of any will be returned 
 * @param p_time_zone        The time zone for the p_min_date and p_max_date parameters. If not specified, the local time zone for each location will be used
 * @param p_office_id mask   A wildcard-enabled string used to match the location(s) to retrieve measurements for.  Matching is
 *                           accomplished with glob-style wildcards, as shown above, instead of sql-style wildcards. If not specified, the session user's default office is used. To
 *                           retrieve from all offices, use '*'
 *
 * @return The matching stream flow measurements
 */
function retrieve_streamflow_meas_xml(
   p_location_id_mask in varchar2,
   p_unit_system      in varchar2 default 'EN',
   p_min_date         in date default null,
   p_max_date         in date default null,
   p_min_height       in number default null,
   p_max_height       in number default null,
   p_min_flow         in number default null,
   p_max_flow         in number default null,
   p_min_num          in integer default null,
   p_max_num          in integer default null,
   p_agencies         in varchar2 default null,
   p_qualities        in varchar2 default null,
   p_time_zone        in varchar2 default null,
   p_office_id_mask   in varchar2 default null)
   return clob;
/**
 * Deletes stream flow measurements that match input criteria
 *
 * @param p_location_id_mask A wildcard-enabled string used to match the location(s) to delete measurements for.  Matching is
 *                           accomplished with glob-style wildcards, as shown below, instead of sql-style wildcards
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 * @param p_unit_system      The unit system (EN/SI) to for for the height and flow boundaries. If EN, height and flow must be specified in ft and cfs, otherwise they must be specified in m and cms. If not specified, the English unit system is used 
 * @param p_min_date         The earliest date to delete measurements for, in the time zone indicated by the p_time_zone parameters. If not specified, no earliest date will be used
 * @param p_max_date         The latest date to delete measurements for, in the time zone indicated by the p_time_zone parameters. If not specified, no latest date will be used
 * @param p_min_height       The minimum gage height to delete measurements for. If not specified, no minimum gage height will be used
 * @param p_max_height       The maximum gage height to delete measurements for. If not specified, no maximum gage height will be used
 * @param p_min_flow         The minimum flow to delete measurements for. If not specified, no minimum flow will be used
 * @param p_max_flow         The maximum flow to delete measurements for. If not specified, no maximum flow will be used
 * @param p_min_num          The minimum measurement number to delete measurements for. If not specified, no minimum measurement number will be used
 * @param p_max_num          The maximum measurement number to delete measurements for. If not specified, no maximum measurement number will be used
 * @param p_agencies         The measuring agencies to delete measurements for, as a comma-separated list. If not specified, measurements from any agency will be deleteed
 * @param p_qualities        The measurement qualities to delete measurements for, as a comma-separated list. If not specified, measurements of any will be deleteed 
 * @param p_time_zone        The time zone for the p_min_date and p_max_date parameters. If not specified, the local time zone for each location will be used
 * @param p_office_id mask   A wildcard-enabled string used to match the location(s) to delete measurements for.  Matching is
 *                           accomplished with glob-style wildcards, as shown above, instead of sql-style wildcards. If not specified, the session user's default office is used. To
 *                           delete from all offices, use '*'
 */
procedure delete_streamflow_meas(
   p_location_id_mask in varchar2,
   p_unit_system      in varchar2 default 'EN',
   p_min_date         in date default null,
   p_max_date         in date default null,
   p_min_height       in number default null,
   p_max_height       in number default null,
   p_min_flow         in number default null,
   p_max_flow         in number default null,
   p_min_num          in integer default null,
   p_max_num          in integer default null,
   p_agencies         in varchar2 default null,
   p_qualities        in varchar2 default null,
   p_time_zone        in varchar2 default null,
   p_office_id_mask   in varchar2 default null);
   
end cwms_stream;
/
show errors;
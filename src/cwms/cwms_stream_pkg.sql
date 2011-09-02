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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">p_delete_action</th>
 *     <th style="border:1px solid black;">Action</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_key</td>
 *     <td style="border:1px solid black;">deletes only this stream, and then only if it has no referring data</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_data</td>
 *     <td style="border:1px solid black;">deletes only data that refers to this stream, if any</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_all</td>
 *     <td style="border:1px solid black;">deletes this stream and all data that refers to it</td>
 *   </tr>
 * </table>
 * @param p_office_id      The office that owns the stream location. If not specified or NULL, the session user's default office is used.
 */
procedure delete_stream(
   p_stream_id     in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">stream_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">stationing_starts_ds</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Specifies whether the zero station is at the downstream most end</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">flows_into_stream</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the receiving stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">flows_into_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The station on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">flows_into_bank</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The bank on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">diverts_from_stream</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the diverting stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">diverts_from_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The station on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">diverts_from_bank</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The bank on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">stream_length</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The length of this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">average_slope</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The average slope of this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comments for this stream</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">stream_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">stationing_starts_ds</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Specifies whether the zero station is at the downstream most end</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">flows_into_stream</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the receiving stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">flows_into_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The station on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">flows_into_bank</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The bank on the receiving stream of the confluence with this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">diverts_from_stream</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the diverting stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">diverts_from_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The station on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">diverts_from_bank</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The bank on the diverting stream of the diversion into this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">stream_length</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The length of this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">average_slope</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The average slope of this stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comments for this stream</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_reach_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">stream_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">stream_reach_id</td>
 *     <td style="border:1px solid black;">varchar2(64)</td>
 *     <td style="border:1px solid black;">The stream reach identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">upstream_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The upstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">downstream_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The downstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">stream_type_id</td>
 *     <td style="border:1px solid black;">varchar2(4)</td>
 *     <td style="border:1px solid black;">The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> of the reach</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comments for this stream</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the stream location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">stream_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">stream_reach_id</td>
 *     <td style="border:1px solid black;">varchar2(64)</td>
 *     <td style="border:1px solid black;">The stream reach identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">upstream_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The upstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">downstream_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The downstream station of the reach</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">stream_type_id</td>
 *     <td style="border:1px solid black;">varchar2(4)</td>
 *     <td style="border:1px solid black;">The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> of the reach</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comments for this stream</td>
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
 * @param p_stream_id    The identifier of the stream
 * @param p_office_id    The office that owns the stream and location. If not specified or NULL, the session user's default office is used.
 */
procedure delete_stream_location(
   p_location_id in  varchar2,
   p_stream_id   in  varchar2,
   p_office_id   in  varchar2 default null);
/**
 * Catalogs streams in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_location_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the stream and location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">stream_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the location on the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The actual stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">published_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The published stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">navigation_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The navigation stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">bank</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The stream bank of the location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">lowest_measurable_stage</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The lowest stream stage at this location that can be measured</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">drainage_area</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The total drainage area above this location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">ungaged_drainage_area</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The drainage area above this location that is ungaged</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">station_unit</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The station unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">stage_unit</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The stage unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">area_unit</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The area unit</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
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
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the stream and location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">stream_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the location on the stream</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The actual stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">published_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The published stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">navigation_station</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The navigation stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">bank</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The stream bank of the location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">lowest_measurable_stage</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The lowest stream stage at this location that can be measured</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">drainage_area</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The total drainage area above this location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">ungaged_drainage_area</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The drainage area above this location that is ungaged</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">station_unit</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The station unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">stage_unit</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The stage unit</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">area_unit</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The area unit</td>
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

end cwms_stream;
/
show errors;
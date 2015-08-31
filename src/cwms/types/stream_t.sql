create type stream_t
/**
 * Holds information about a stream
 *
 * @member office_id            The office that owns the stream
 * @member name                 The name of the stream
 * @member unit                 The unit used in this object for stationing and length
 * @member stationing_starts_ds A flag (T/F) specifying whether stationing increases upstream
 * @member flows_into_stream    The name of the stream that this stream flows into
 * @member flows_into_station   The station on the receiving stream where this stream joins
 * @member flows_into_bank      The bank on the receiving stream where this stream joins
 * @member diverts_from_stream  The name of the stream that this stream diverts from
 * @member diverts_from_station The station on the source stream where this stream diverts
 * @member diverts_from_bank    The bank on the source stream that this stream diverts from
 * @member length               The length of this stream
 * @member average_slope        The average slope in percent of this stream
 * @member comments             Additional comments for this stream
 */
as object(
   office_id            varchar2(16),
   name                 varchar2(49),
   unit                 varchar2(16),
   stationing_starts_ds varchar2(1),
   flows_into_stream    varchar2(49),
   flows_into_station   binary_double,
   flows_into_bank      varchar2(1),
   diverts_from_stream  varchar2(49),
   diverts_from_station binary_double,
   diverts_from_bank    varchar2(1),
   length               binary_double,
   average_slope        binary_double,
   comments             varchar2(256),
   /**
    * Zero-parameter constructor
    * @return A new stream_t object with all fields set to NULL.
    */
   constructor function stream_t
   return self as result,
   /**
    * Constructor from database using location code
    * 
    * @param p_stream_location_code The stream's location code in the database
    * @return A new stream_t object populated from the database
    */
   constructor function stream_t(
      p_stream_location_code in number)
   return self as result,
   /**
    * Constructor from database using location identifier
    *
    * @param p_stream_location_id The stream's location identifier in the database
    * @param p_office_id          The office that owns the stream in the database. If not specified or NULL, the current session user's default office will be used.  
    * @return A new stream_t object populated from the database
    */
   constructor function stream_t(
      p_stream_location_id in varchar2,
      p_office_id          in varchar2 default null)
   return self as result,
   /**
    * Constructor from members. Used for backward compatibility when additional members are added
    *
    * @param p_office_id            The office that owns the stream
    * @param p_name                 The name of the stream
    * @param p_unit                 The unit used in this object for stationing and length
    * @param p_stationing_starts_ds A flag (T/F) specifying whether stationing increases upstream
    * @param p_flows_into_stream    The name of the stream that this stream flows into
    * @param p_flows_into_station   The station on the receiving stream where this stream joins
    * @param p_flows_into_bank      The bank on the receiving stream where this stream joins
    * @param p_diverts_from_stream  The name of the stream that this stream diverts from
    * @param p_diverts_from_station The station on the source stream where this stream diverts
    * @param p_diverts_from_bank    The bank on the source stream that this stream diverts from
    * @param p_length               The length of this stream
    * @param p_average_slope        The average slope in percent of this stream
    * @param p_comments             Additional comments for this stream
    * @return A new stream_t object populated from the parameters
    */
   constructor function stream_t(
      p_office_id            in varchar2,
      p_name                 in varchar2,
      p_unit                 in varchar2,
      p_stationing_starts_ds in varchar2,
      p_flows_into_stream    in varchar2,
      p_flows_into_station   in binary_double,
      p_flows_into_bank      in varchar2,
      p_diverts_from_stream  in varchar2,
      p_diverts_from_station in binary_double,
      p_diverts_from_bank    in varchar2,
      p_length               in binary_double,
      p_average_slope        in binary_double,
      p_comments             in varchar2)
   return self as result,
   /**
    * Converts object from current station/length unit to specified station/length unit
    *
    * @param p_unit The station/length unit to convert to.
    */
   member procedure convert_to_unit(
      p_unit in varchar2),
   /**
    * Stores a stream object to the database
    *
    * @param p_fail_if_exists A flag (T/F) specifying whether to fail if a stream with the same office and name already exists in the database.  Specifying 'F' forces updating any such stream.
    * @param p_ignore_nulls   A flag (T/F) specifying whether to ignore any NULL members in the object when updating an existing object in the database. Specifying 'F' forces any NULL values in the object to overwrite any non-NULL values in the database.
    */
   member procedure store(
      p_fail_if_exists in varchar2,
      p_ignore_nulls   in varchar2)
);
/

create or replace public synonym cwms_t_stream for stream_t;

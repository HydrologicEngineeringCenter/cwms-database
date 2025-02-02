create type SHEF_SPEC_TYPE
/**
 * Object type representing SHEF processing for a CWMS time series
 *
 * @member cwms_ts_id the CWMS time series identifier
 * @member shef_location_id the SHEF location identifier
 * @member shef_pe_code the SHEF physical element identifier
 * @member shef_tse_code the SHEF identifiers for type, source, and extremum
 * @member shef_duration the SHEF duration identifier
 * @member shef_incoming_units the unit of the incoming data. This is necessary
 *         in case incoming data is not in the SHEF standard unit.
 * @member shef_time_zone_id the time zone of the incoming data. This is necessary
 *         in case incoming data is not in UTC.
 * @member daylight_savings specifies whether the <code><big>shef_time_zone_id</big></code>
 *         observes daylight savings.
 *         <ul>
 *         <li><code><big>'T'</big></code> - specifies daylight savings is observed
 *         <li><code><big>'F'</big></code> - specifies daylight savings is not observed
 *         </ul>
 * @member interval_utc_offset data offset from start of UTC interval, in minutes.
 *         Valid only for regular time series.
 *         <ul>
 *         <li><code><big><a href="cwms_util#const=utc_offset_irregular">cwms_util.utc_offset_irregular</a></big></code> - value used for irregular time series
 *         <li><code><big><a href="cwms_util#const=utc_offset_undefined">cwms_util.utc_offset_undefined</a></big></code> - value indicating offset has not yet been defined for regular time sereies
 *         </ul>
 * @member snap_forward_minutes number of minutes before the expected time to accept a regular time series value.
 *         The value specifies the number of minutes before the <code><big>interval_utc_offset</big></code>
 *         within which to accept data as being at the specified offset.
 * @member snap_backward_minutes number of minutes after the expected time to accept a regular time series value.
 *         The value specifies the number of minutes after the <code><big>interval_utc_offset</big></code>
 *         within which to accept data as being at the specified offset.
 * @member ts_active_flag flag specifying whether to process the indicated time series.
 *         Allows turning the processing of a specific time series on and off.
 *         <ul>
 *         <li><code><big>'T'</big></code> - specifies the time series is to be processed
 *         <li><code><big>'F'</big></code> - specifies the time series is not to be processed
 *         </ul>
 * @see constant cwms_util.utc_offset_irregular
 * @see constant cwms_util.utc_offset_undefined
 */
AS
   OBJECT (
      cwms_ts_id VARCHAR2 (191),
      shef_location_id VARCHAR2 (8),
      shef_pe_code VARCHAR2 (2),
      shef_tse_code VARCHAR2 (3),
      shef_duration VARCHAR2 (4),
      shef_incoming_units VARCHAR2 (16),
      shef_time_zone_id VARCHAR2 (3),
      daylight_savings VARCHAR2 (1),      -- T or F psuedo boolean.
      interval_utc_offset NUMBER,         -- in minutes.
      snap_forward_minutes NUMBER,
      snap_backward_minutes NUMBER,
      ts_active_flag VARCHAR2 (1)         -- T or F psuedo boolean.
   );
/


create or replace public synonym cwms_t_shef_spec for shef_spec_type;


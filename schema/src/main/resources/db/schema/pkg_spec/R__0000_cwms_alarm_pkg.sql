create or replace package cwms_alarm
/**
 * Routines for working with alarms in CWMS
 * @author Mike Perryman
 * @since CWMS 2.2
 */
AS
/**
 * Value for p_alarm_state parameter of notify_datastream_alarm_state procedure that indicates that data is being recieved and validated by the data stream
 */
data_stream_ok constant integer := 0;
/**
 * Value for p_alarm_state parameter of notify_datastream_alarm_state procedure that indicates that data is being received but not validated by the data stream
 */
data_stream_valid_data_missing  constant integer := 1;
/**
 * Value for p_alarm_state parameter of notify_datastream_alarm_state procedure that indicates that data is not being received or validated by the data stream
 */
data_stream_raw_data_missing  constant integer := 2;
/**
 * Value for p_state parameter of notify_loc_lvl_ind_state procedure that indicates no indicator conditions cannot be computed because the time series data fails the minimum duration or maximum age test
 */
state_condition_error    constant integer := -1;
/**
 * Value for p_state parameter of notify_loc_lvl_ind_state procedure that indicates no indicator conditions are set
 */
state_no_condition_set constant integer :=  0;
/**
 * Value for p_operation parameter of notify_loc_lvl_ind_state procedure that indicates the reported value is the most recent max condition value in the time window
 */
operation_most_recent constant integer := 1;
/**
 * Value for p_operation parameter of notify_loc_lvl_ind_state procedure that indicates the reported value is the maximum of all max indicator condition values in the time window
 */
operation_minimum constant integer := 2;
/**
 * Value for p_operation parameter of notify_loc_lvl_ind_state procedure that indicates the reported value is the minimum of all max indicator condition values in the time window
 */
operation_maximum constant integer := 3;
/**
 * Value for p_operation parameter of notify_loc_lvl_ind_state procedure that indicates the reported value is the arithmetic mean of all max indicator condition values in the time window
 */
operation_mean constant integer := 4;
/**
 * Value for p_operation parameter of notify_loc_lvl_ind_state procedure that indicates the reported value is the median of all max indicator condition values in the time window
 */
operation_median constant integer := 5;
/**
 * Value for p_operation parameter of notify_loc_lvl_ind_state procedure that indicates the reported value is the mode (most common) of all indicator values in the time window
 */
operation_mode constant integer := 6;

/**
 * Enqueues a message about the alarm state of a data stream
 *
 * @param p_data_stream_name The name of the data stream whose alarm_state is being reported
 * @param p_host             The name or network address of the computer processing the data stream
 * @param p_alarm_state      The reported alarm state value. Must be one of the following:
 * <p>
 * <table class="descr" border="1">
 *   <tr><th class="descr">Value</th><th class="descr">Description</th></tr>
 *   <tr><td class="descr"><a href=#data_stream_ok>0 = cwms_alarm.data_stream_ok</a></td><td class="descr">Data is being recieved and validated by the data stream</td></tr>
 *   <tr><td class="descr"><a href=#data_stream_valid_data_missing>1 = cwms_alarm.data_stream_valid_data_missing</a></td><td class="descr">Data is being recieved but not validated by the data stream</td></tr>
 *   <tr><td class="descr"><a href=#data_stream_raw_data_missing>2 = cwms_alarm.data_stream_raw_data_missing</a></td><td class="descr">Data is not being recieved or validated by the data stream</td></tr>
 * </table>
 * @param p_raw_time_utc     The date of the most recent raw data in the data stream, in UTC
 * @param p_valid_time_utc   The date of the most recent validated data in the data stream, in UTC
 * @param p_raw_age          The age of the latest raw data in the data stream
 * @param p_raw_age_max      The maximum age of the most recent raw data for the data stream raw data to be considered current
 * @param p_valid_age        The age of the latest validated data in the data stream
 * @param p_valid_age_max    The maximum age of the most recent validated data for the data stream validated data to be considered current
 * @param p_office_id        The office that owns the data stream
 *
 * @see constant data_stream_ok
 * @see constant data_stream_raw_data_missing
 * @see constant data_stream_valid_data_missing
 */
procedure notify_datastream_alarm_state(
   p_data_stream_name in varchar2,
   p_host             in varchar2,
   p_alarm_state      in integer,
   p_raw_time_utc     in date,
   p_valid_time_utc   in date,
   p_raw_age          in interval day to second default null,
   p_raw_age_max      in interval day to second default null,
   p_valid_age        in interval day to second default null,
   p_valid_age_max    in interval day to second default null,
   p_office_id        in varchar2 default null);
/**
 * Enqueues a message about the state of a location level indicator.  The state is defined as maximum condition that is set for the location level indicator.
 *
 * @param p_loc_lvd_ind_code The numeric code identifying the location level indicator whose state is being reported
 * @param p_state          The reported state value. Must be in the range. Must be one of the following:
 * <p>
 * <table class="descr" border="1">
 *   <tr><th class="descr">Value</th><th class="descr">Description</th></tr>
 *   <tr><td class="descr">-1 = <a href=#state_max_age_error>cwms_alarm.state_max_age_error</a></td><td class="descr">No state value can be computed becuase the time series fails the minimum duration or maximum age test</td></tr>
 *   <tr><td class="descr">0 = <a href=#state_no_condition_set>cwms_alarm.state_no_condition_set</a></td><td class="descr">No location level indicator conditions are set</td></tr>
 *   <tr><td class="descr">1</td><td class="descr">The location level indicator condition 1 is set</td></tr>
 *   <tr><td class="descr">2</td><td class="descr">The location level indicator condition 2 is set</td></tr>
 *   <tr><td class="descr">3</td><td class="descr">The location level indicator condition 3 is set</td></tr>
 *   <tr><td class="descr">4</td><td class="descr">The location level indicator condition 4 is set</td></tr>
 *   <tr><td class="descr">5</td><td class="descr">The location level indicator condition 5 is set</td></tr>
 * </table>
 * @param p_state_time The time of the reported state value. This should be the latest time in the time window that value is represented by p_state.
 * @param p_duration   The duration of the anlysis time window, in minutes
 * @param p_time_zone  The time zone of p_state_time. If not specified or <code>NULL</code>, the local time zone of the location represented by the indicator
 * @param p_operation  The operation across p_duration that was used to compute the value of p_state. Must be one of the following:
 * <p>
 * <table class="descr" border="1">
 *   <tr><th class="descr">Value</th><th class="descr">Description</th></tr>
 *   <tr><td class="descr"><a href=#operation_most_recent>cwms_alarm.operation_most_recent</a></td><td class="descr">P_state represents the most recent value of the location level indicator max condition</td></tr>
 *   <tr><td class="descr"><a href=#operation_minimum>cwms_alarm.operation_minimum</a></td><td class="descr">P_state represents the minimum of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_maximum>cwms_alarm.operation_maximum</a></td><td class="descr">P_state represents the maximum of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_mean>cwms_alarm.operation_mean</a></td><td class="descr">P_state represents the arithmetic mean of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_median>cwms_alarm.operation_median</a></td><td class="descr">P_state represents the median of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_mode>cwms_alarm.operation_mode</a></td><td class="descr">P_state represents the mode (most common) of the location level indicator max condition values in the time window. If the data are multimodal, greatest mode should be reported</td></tr>
 * </table>
 * @param p_ts_id_used     The numeric code identifying the time series, if any, that was used to generate the location level indicator condition value
 *
 * @see constant state_condition_error
 * @see constant state_no_condition_set
 * @see constant operation_most_recent
 * @see constant operation_minimum
 * @see constant operation_maximum
 * @see constant operation_mean
 * @see constant operation_median
 * @see constant operation_mode
 */
procedure notify_loc_lvl_ind_state(
   p_loc_lvl_ind_code in varchar2,
   p_state            in number,
   p_state_time       in date,
   p_duration         in integer,
   p_operation        in integer,
   p_time_zone        in varchar2 default null,
   p_ts_code_used     in number   default null);
/**
 * Analyzes a location level indicator based on a specified time series and enqueues a message about the state of the location level indicator. The state is defined as maximum condition that is set for the location level indicator.
 *
 * @param p_ts_id              The time series used to generate the location level indicator condition value
 * @param p_specified_level_id The specified level identifier to enqueue the state for
 * @param p_level_indicator_id The location level indicator identifier to enqueue the state for
 * @param p_attribute_id       The location level attribute identifier. If not specified or <code>NULL</code>, no location level attribute will be used
 * @param p_attribute_value    The location level attribute value. Valid only if p_attribute_id is not <code>NULL</code>
 * @param p_attribute_number   The unit of the location level attribute value. Valid only if p_attribute_id is not <code>NULL</code>
 * @param p_duration           The duration of the anlysis time window, in minutes. If not specified or <code>NULL</code>, the duration will be the location level indicator's minimum duration plus its maximum age.
 * @param p_min_state_notify   The minimum value that will generate a notification. No notification will occur if the location level indicator max value is below this. If not specified, 0 is used.
 * @param p_max_state_notify   The maximum value that will generate a notification. No notification will occur if the location level indicator max value is above this. If not specified, 5 is used.
 * @param p_notify_state_err   A flag ('T'/'F') that specifies whether to generate a notification if the location level indicator max value cannot be computed. If not specified, 'T' is used.
 * @param p_operation          The operation across p_duration to use to compute the value to report for the state of the location level indicator.  Must be one of the following:
 * <p>
 * <table class="descr" border="1">
 *   <tr><th class="descr">Value</th><th class="descr">Description</th></tr>
 *   <tr><td class="descr"><a href=#operation_most_recent>cwms_alarm.operation_most_recent</a></td><td class="descr">Report the most recent value of the location level indicator max condition</td></tr>
 *   <tr><td class="descr"><a href=#operation_minimum>cwms_alarm.operation_minimum</a></td><td class="descr">Report the minimum of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_maximum>cwms_alarm.operation_maximum</a></td><td class="descr">Report the maximum of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_mean>cwms_alarm.operation_mean</a></td><td class="descr">Report the arithmetic mean of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_median>cwms_alarm.operation_median</a></td><td class="descr">Report the median of the location level indicator max condition values in the time window</td></tr>
 *   <tr><td class="descr"><a href=#operation_mode>cwms_alarm.operation_mode</a></td><td class="descr">Report the mode (most common) of the location level indicator max condition values in the time window. If the values are multimodal, the largest mode is reported</td></tr>
 * </table>
 * <p> For each of the operations, the state time (time associated with the state value) is the most recent time that the max location level indicator condition matches the state value, with the following exceptions:
 * <p>
 * <table class="descr" border="1">
 *   <tr><th class="descr">Operation</th><th class="descr">State Time</th></tr>
 *   <tr><td class="descr"><a href=#operation_mean>cwms_alarm.operation_mean</a></td><td class="descr">No state time is reported</td></tr>
 *   <tr><td class="descr"><a href=#operation_median>cwms_alarm.operation_median</a></td><td class="descr">If the median lies between two actual values, the state time reported is the most recent time that the max location level is either of the bounding values</td></tr>
 * </table>
 * @param p_office_id The office that owns the time series
 *
 * @see constant operation_most_recent
 * @see constant operation_minimum
 * @see constant operation_maximum
 * @see constant operation_mean
 * @see constant operation_median
 * @see constant operation_mode
 */
procedure notify_loc_lvl_ind_state(
   p_ts_id              in varchar2,
   p_specified_level_id in varchar2,
   p_level_indicator_id in varchar2,
   p_attribute_id       in varchar2 default null,
   p_attribute_value    in number   default null,
   p_attribute_unit     in varchar2 default null,
   p_duration           in integer  default null,
   p_operation          in integer  default operation_most_recent,
   p_min_state_notify   in integer  default 0,
   p_max_state_notify   in integer  default 5,
   p_notify_state_err   in varchar2 default 'T',
   p_office_id          in varchar2 default null);
END cwms_alarm;

/

grant execute on cwms_alarm to cwms_user;
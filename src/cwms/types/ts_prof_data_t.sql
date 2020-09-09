create type ts_prof_data_t
/**
 * Holds data for a time series profile
 *
 * @param location_code The unique numeric identifier for the location of the profile
 * @param key_parameter The 1-based index into the records(n).parameters table of the key parameter of the profile
 * @param time_zone     The time zone of the data records(n).date_time values
 * @param units         A table of units of the records(n).parameters(m).value values
 * @param values        The profile times and parameter values/quality codes
 *
 * @since CWMS schema 18.1.6
 * @see type ts_prof_data_tab_t
 */
as object(
   location_code integer,
   key_parameter integer,
   time_zone     varchar2(28),
   units         str_tab_t,
   records       ts_prof_data_tab_t);
/
grant execute on ts_prof_data_t to cwms_user;
create or replace public synonym cwms_t_ts_prof_data for ts_prof_data_t;


create type ts_prof_data_rec_t
/**
 * Holds an undated value and quality code for a specified parameter
 *
 * @member key_parameter A The date/time, value, and quality code of the key parameter in a time series profile.
 * @member assoc_params  A table of parameter values and quality codes associated with the date/time and key parameter value
 *
 * @since CWMS schema 18.1.6
 * @see type pvq_tab_t
 * @see type ts_prof_data_tab_t
 */
as object(
   date_time  date,
   parameters pvq_tab_t);
/
grant execute on ts_prof_data_rec_t to cwms_user;
create or replace public synonym cwms_t_ts_prof_data_rec for ts_prof_data_rec_t;


create type ts_prof_data_tab_t
/**
 * Holds a table of ts_prof_data_rec_t objects
 *
 * @since CWMS schema 18.1.6
 * @see type ts_prof_data_rec_t
 */
as table of ts_prof_data_rec_t;
/
grant execute on ts_prof_data_tab_t to cwms_user;
create or replace public synonym cwms_t_ts_prof_data_tab for ts_prof_data_tab_t;


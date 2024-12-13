create or replace type fcst_file_tab_t
/**
 * Holds a table of forecast files
 *
 * @see type fcst_file_t
 */
as table of fcst_file_t;
/

create or replace public synonym cwms_t_fcst_file_tab for fcst_file_tab_t;

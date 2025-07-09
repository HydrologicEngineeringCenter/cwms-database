create type tstz_tab_t
/**
 * Type suitable for holding multiple timestamp with time zone values
 */
as table of timestamp with time zone;
/


create or replace public synonym cwms_t_tstz_tab for tstz_tab_t;


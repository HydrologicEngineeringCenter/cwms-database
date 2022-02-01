create type date2_t
/**
 * Holds a pair of dates
 *
 * @see type date2_tab_t
 *
 * @member date_1 The first date
 * @member date_2 The second date
 */
as object(
   date_1 date,
   date_2 date);
/


create or replace public synonym cwms_t_date2 for date2_t;


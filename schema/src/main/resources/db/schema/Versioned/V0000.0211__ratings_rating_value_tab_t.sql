create type rating_value_tab_t
/**
 * Holds a collection of rating lookup values
 *
 * @see type rating_value_t
 */
as table of rating_value_t;
/


create or replace public synonym cwms_t_rating_value_tab for rating_value_tab_t;


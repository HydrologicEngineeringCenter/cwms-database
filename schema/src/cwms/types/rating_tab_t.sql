create type rating_tab_t
/**
 * Holds a collection of ratings
 *
 * @see type rating_t
 */
as table of rating_t;
/


create or replace public synonym cwms_t_rating_tab for rating_tab_t;


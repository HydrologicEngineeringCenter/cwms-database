create type rating_spec_tab_t
/**
 * Holds a collection of rating specifications
 *
 * @see type rating_spec_t
 */
as table of rating_spec_t;
/


create or replace public synonym cwms_t_rating_spec_tab for rating_spec_tab_t;


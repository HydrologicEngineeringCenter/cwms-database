create type rating_template_tab_t
/**
 * Holds a collection of rating templates
 *
 * @see type rating_template_t
 */
as table of rating_template_t;
/


create or replace public synonym cwms_t_rating_template_tab for rating_template_tab_t;


create type rating_ind_param_tab_t
/**
 * Holds a collection of rating_ind_parameter_t objects
 *
 * @see type rating_ind_parameter_t
 */
as table of rating_ind_parameter_t;
/


create or replace public synonym cwms_t_rating_ind_param_tab for rating_ind_param_tab_t;


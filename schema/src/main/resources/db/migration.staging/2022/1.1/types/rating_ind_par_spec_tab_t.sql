create type rating_ind_par_spec_tab_t
/**
 * Holds information about the independent parameters for a rating
 *
 * @see type rating_ind_param_spec
 */
as table of rating_ind_param_spec_t;
/


create or replace public synonym cwms_t_rating_ind_par_spec_tab for rating_ind_par_spec_tab_t;


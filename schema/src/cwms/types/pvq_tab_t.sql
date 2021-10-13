create type pvq_tab_t
/**
 * Holds a table of pvq_t objects
 *
 * @since CWMS schema 18.1.6
 * @see type pvq_t
 */
as table of pvq_t;
/
grant execute on pvq_tab_t to cwms_user;
create or replace public synonym cwms_t_pvq_tab for pvq_tab_t;


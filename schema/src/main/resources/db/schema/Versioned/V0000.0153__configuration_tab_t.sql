create type configuration_tab_t
/**
 * Holds a collection of configurations
 */
as table of configuration_t;
/

create or replace public synonym cwms_t_configuration_tab for configuration_tab_t;

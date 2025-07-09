create type property_info_tab_t
/**
 * Holds a collection of property keys
 *
 * @see type property_info_t
 * @see type property_info2_tab_t
 */
as table of property_info_t;
/


create or replace public synonym cwms_t_property_info_tab for property_info_tab_t;


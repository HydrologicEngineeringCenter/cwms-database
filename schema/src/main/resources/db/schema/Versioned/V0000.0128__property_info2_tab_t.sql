create type property_info2_tab_t
/**
 * Holds a collection of properties
 *
 * @see type property_info2_t
 * @see type property_info_tab_t
 */
as table of property_info2_t;
/


create or replace public synonym cwms_t_property_info2_tab for property_info2_tab_t;


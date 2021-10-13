create type property_info_t
/**
 * Holds information about a property key
 *
 * @see type property_info2_t
 * @see type property_info_tab_t
 *
 * @member office_id     The office that owns the property
 * @member prop_category The property category. Analogous to the file name of a properties file
 * @member prop_id       The property identifier.  Analogous to the property key in a properties file
 */
as object (
   office_id     varchar2 (16),
   prop_category varchar2 (256),
   prop_id       varchar2 (256));
/


create or replace public synonym cwms_t_property_info for property_info_t;


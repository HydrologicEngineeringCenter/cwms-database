create type property_info2_t
/**
 * Holds information about a property
 *
 * @see type property_info_t
 * @see type property_info2_tab_t
 *
 * @member office_id     The office that owns the property
 * @member prop_category The property category. Analogous to the file name of a properties file
 * @member prop_id       The property identifier.  Analogous to the property key in a properties file
 * @member prop_value    The property value. Analogous to the property value in a properties file
 * @member prop_comment  A comment about the property. No analog in a properties file except a comment line before the property
 */
as object (
   office_id     varchar2 (16),
   prop_category varchar2 (256),
   prop_id       varchar2 (256),
   prop_value    varchar2 (256),
   prop_comment  varchar2 (256));
/


create or replace public synonym cwms_t_property_info2 for property_info2_t;


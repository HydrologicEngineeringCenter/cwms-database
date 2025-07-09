create type xml_tab_t
/**
 * Holds a collection of xmltype objects
 */
is table of xmltype;
/

create or replace public synonym cwms_t_xml_tab for xml_tab_t;

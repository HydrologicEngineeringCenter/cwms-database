CREATE TYPE anydata_tab_t
/**
 * Holds a collection of anydata objects
 *
 */
IS
  TABLE OF anydata;
/


create or replace public synonym cwms_t_anydata_tab for anydata_tab_t;


CREATE TYPE loc_ref_time_window_tab_t
/**
 * Holds a collection of location time windows
 */
IS
  TABLE OF loc_ref_time_window_obj_t;
/


create or replace public synonym cwms_t_loc_ref_time_window_tab for loc_ref_time_window_tab_t;


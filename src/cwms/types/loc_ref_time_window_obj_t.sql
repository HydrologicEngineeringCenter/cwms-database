CREATE type loc_ref_time_window_obj_t
/**
 * Holds a time window for a location
 *
 * @see type loc_ref_time_window_tab_t
 *
 * @member location_ref Identifies the location
 * @member start_date   The beginning of the time window
 * @member end_dete     The end of the time window
 */
AS
  object
  (
    location_ref location_ref_t, 
    start_date DATE,
    end_date DATE
    );
/


create or replace public synonym cwms_t_loc_ref_time_window_obj for loc_ref_time_window_obj_t;


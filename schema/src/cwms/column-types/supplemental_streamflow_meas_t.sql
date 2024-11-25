create or replace type supp_streamflow_meas_t
/**
 * Object type representing a location reference.
 *
 * @member base_location_id specifies the base location portion
 *
 * @member sub_location_id specifies the sub-location portion
 *
 * @member office_id specifies the office which owns the referenced location
 *
 * @see type location_obj_t
 * @see type supp_streamflow_meas_tab_t
 */
is object(
    channel_flow           binary_double,
    overbank_flow          binary_double,
    overbank_max_depth     binary_double,
    channel_max_depth      binary_double,
    avg_velocity           binary_double,
    surface_velocity       binary_double,
    max_velocity           binary_double,
    effective_flow_area    binary_double,
    cross_sectional_area   binary_double,
    mean_gage              binary_double,
    top_width              binary_double,
    main_channel_area      binary_double,
    overbank_area          binary_double
);
/


create or replace public synonym cwms_t_supp_streamflow_meas for supp_streamflow_meas_t;


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
    overbank_area          binary_double,

    constructor function supp_streamflow_meas_t(p_xml in xmltype) return self as result,

    -- Method to convert to XML
    member function to_xml return varchar2,

    -- New method to get error message string for logging
    member function get_error_message return varchar2

);
/


create or replace public synonym cwms_t_supp_streamflow_meas for supp_streamflow_meas_t;
/

-- function to convert parameters to xml
create or replace function supp_streamflow_params_to_xml(
        p_channel_flow           in binary_double,
        p_overbank_flow          in binary_double,
        p_overbank_max_depth     in binary_double,
        p_channel_max_depth      in binary_double,
        p_avg_velocity           in binary_double,
        p_surface_velocity       in binary_double,
        p_max_velocity           in binary_double,
        p_effective_flow_area    in binary_double,
        p_cross_sectional_area  in binary_double,
        p_mean_gage              in binary_double,
        p_top_width              in binary_double,
        p_main_channel_area      in binary_double,
        p_overbank_area          in binary_double
    ) return varchar2 is
        l_text varchar2(32767);

    function make_elem(p_tag in varchar2, p_data in varchar2) return varchar2 is
            l_elem varchar2(32767);
    begin
        if p_data is null then
            l_elem := '<'||p_tag||'/>';
        else
            l_elem := '<'||p_tag||'>'||p_data||'</'||p_tag||'>';
        end if;
        return l_elem;
    end make_elem;

begin
    l_text := '<supplemental-stream-flow-measurement>'
        || make_elem('channel-flow', cwms_rounding.round_dt_f(p_channel_flow, '9999999999'))
        || make_elem('overbank-flow', cwms_rounding.round_dt_f(p_overbank_flow, '9999999999'))
        || make_elem('overbank-max-depth', cwms_rounding.round_dt_f(p_overbank_max_depth, '9999999999'))
        || make_elem('channel-max-depth', cwms_rounding.round_dt_f(p_channel_max_depth, '9999999999'))
        || make_elem('avg-velocity', cwms_rounding.round_dt_f(p_avg_velocity, '9999999999'))
        || make_elem('surface-velocity', cwms_rounding.round_dt_f(p_surface_velocity, '9999999999'))
        || make_elem('max-velocity', cwms_rounding.round_dt_f(p_max_velocity, '9999999999'))
        || make_elem('effective-flow-area', cwms_rounding.round_dt_f(p_effective_flow_area, '9999999999'))
        || make_elem('cross-sectional-area', cwms_rounding.round_dt_f(p_cross_sectional_area, '9999999999'))
        || make_elem('mean-gage', cwms_rounding.round_dt_f(p_mean_gage, '9999999999'))
        || make_elem('top-width', cwms_rounding.round_dt_f(p_top_width, '9999999999'))
        || make_elem('main-channel-area', cwms_rounding.round_dt_f(p_main_channel_area, '9999999999'))
        || make_elem('overbank-area', cwms_rounding.round_dt_f(p_overbank_area, '9999999999'))
        || '</supplemental-stream-flow-measurement>';

    return l_text;
end supp_streamflow_params_to_xml;
/


-- declare
--     val varchar2(200);
-- begin
--     select type_name into val from all_types where owner = '${flyway:defaultSchema}' type_name='SUPP_STREAMFLOW_MEAS_T';
-- exception
--when no_data_found then
begin
    execute immediate 'create type if not exists ${flyway:defaultSchema}.supp_streamflow_meas_t as object(' ||
        'channel_flow           binary_double,' ||
        'overbank_flow          binary_double,' ||
        'overbank_max_depth     binary_double,' ||
        'channel_max_depth      binary_double,' ||
        'avg_velocity           binary_double,' ||
        'surface_velocity       binary_double,' ||
        'max_velocity           binary_double,' ||
        'effective_flow_area    binary_double,' ||
        'cross_sectional_area   binary_double,' ||
        'mean_gage              binary_double,' ||
        'top_width              binary_double,' ||
        'main_channel_area      binary_double,' ||
        'overbank_area          binary_double)';
end;
/

create or replace public synonym cwms_t_supp_streamflow_meas for supp_streamflow_meas_t;

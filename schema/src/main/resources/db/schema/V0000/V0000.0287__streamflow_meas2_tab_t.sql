create type streamflow_meas2_tab_t
is table of streamflow_meas2_t;
/

create or replace public synonym cwms_t_streamflow_meas2_tab for streamflow_meas2_tab_t;



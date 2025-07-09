create type streamflow_meas_tab_t
is table of streamflow_meas_t;
/

create or replace public synonym cwms_t_streamflow_meas_tab for streamflow_meas_tab_t;



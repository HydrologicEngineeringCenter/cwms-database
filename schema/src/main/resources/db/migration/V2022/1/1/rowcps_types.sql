WHENEVER sqlerror EXIT sql.sqlcode
SET define ON
@@cwms/defines.sql
SET serveroutput ON
--
--
--
--location objects are defined in cwms_types.
--location_ref_t and location_obj_t.
@@cwms/types/lookup_type_obj_t
@@cwms/types/lookup_type_tab_t
@@cwms/types/document_obj_t
@@cwms/types/document_tab_t
@@cwms/types/project_obj_t
@@cwms/types/project_obj_t-body
@@cwms/types/embankment_obj_t
@@cwms/types/embankment_tab_t
@@cwms/types/water_user_obj_t
@@cwms/types/water_user_tab_t
@@cwms/types/water_user_contract_ref_t
@@cwms/types/water_user_contract_obj_t
@@cwms/types/water_user_contract_tab_t
@@cwms/types/wat_usr_contract_acct_obj_t
@@cwms/types/wat_usr_contract_acct_tab_t
@@cwms/types/loc_ref_time_window_obj_t
@@cwms/types/loc_ref_time_window_tab_t
@@cwms/types/lock_obj_t
@@cwms/types/characteristic_ref_t
@@cwms/types/project_structure_obj_t
@@cwms/types/project_structure_tab_t
@@cwms/types/characteristic_obj_t
@@cwms/types/characteristic_tab_t
@@cwms/types/gate_setting_obj_t
@@cwms/types/gate_setting_tab_t
@@cwms/types/gate_change_obj_t
@@cwms/types/gate_change_tab_t
@@cwms/types/turbine_setting_obj_t
@@cwms/types/turbine_setting_tab_t
@@cwms/types/turbine_change_obj_t
@@cwms/types/turbine_change_tab_t

set verify off
create or replace package &&cwms_schema..test_cwms_water_supply as
--%suite(Test cwms units conversions for water supply accounting)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

procedure setup;
procedure teardown;

--%test(Roundtrip store/retrieve of pump accounting with per-record units)
procedure test_roundtrip_pump_accounting_units;

end test_cwms_water_supply;
/
show errors;

create or replace package body &&cwms_schema..test_cwms_water_supply as

   c_office_id         varchar2(16) := '&&office_id';
   c_project_loc_id    varchar2(57) := 'WSUnitsProj';
   c_pump_loc_id       varchar2(57) := 'WSUnitsPump';
   c_water_user_name   varchar2(64) := 'WS Units User';
   c_contract_name     varchar2(64) := 'WS Units Contract';
   -- Reuse a single water_user object across setup, test, and teardown
   c_water_user        water_user_obj_t;

procedure setup
is
begin
   -- Create needed locations
   cwms_loc.store_location(
      p_location_id    => c_project_loc_id,
      p_time_zone_id   => 'UTC',
      p_vertical_datum => null,
      p_db_office_id   => c_office_id);

   cwms_loc.store_location(
      p_location_id    => c_pump_loc_id,
      p_time_zone_id   => 'UTC',
      p_vertical_datum => null,
      p_db_office_id   => c_office_id);

   -- Initialize reusable water user reference
   c_water_user := water_user_obj_t(
         location_ref_t(c_project_loc_id, c_office_id),
         c_water_user_name,
         'TEST RIGHT');

   -- Ensure the project exists (AT_PROJECT parent row) for the project location.
   -- AT_WATER_USER.project_location_code has an FK to AT_PROJECT (AT_WATER_USER_FK1),
   -- so we must create a Project prior to storing a water user/contract.
   cwms_project.store_project(project_obj_t(
      p_project_location             => location_obj_t(location_ref_t(c_project_loc_id, c_office_id)),
      p_pump_back_location           => null,
      p_near_gage_location           => null,
      p_authorizing_law              => null,
      p_cost_year                    => null,
      p_federal_cost                 => null,
      p_nonfederal_cost              => null,
      p_federal_om_cost              => null,
      p_nonfederal_om_cost           => null,
      p_remarks                      => null,
      p_project_owner                => null,
      p_hydropower_description       => null,
      p_sedimentation_description    => null,
      p_downstream_urban_description => null,
      p_bank_full_capacity_descript  => null,
      p_yield_time_frame_start       => null,
      p_yield_time_frame_end         => null),
      'F');

   -- Pre-clean any existing artifacts for deterministic setup.
   -- Intentionally continue on any exception so that one failure
   -- does not prevent subsequent cleanup operations or setup.
   begin
      begin
         cwms_water_supply.delete_contract(
            p_contract_ref => water_user_contract_ref_t(
               c_water_user,
               c_contract_name),
            p_delete_action => cwms_util.delete_all);
      exception when others then null; end;

      begin
         cwms_water_supply.delete_water_user(
            p_project_location_ref => location_ref_t(c_project_loc_id, c_office_id),
            p_entity_name => c_water_user_name,
            p_delete_action => cwms_util.delete_all);
      exception when others then null; end;
   exception when others then null; end;

   -- Create water user
   cwms_water_supply.store_water_user(
      p_water_user => c_water_user,
      p_fail_if_exists => 'F');

   -- Create a simple contract
   cwms_water_supply.store_contracts(
      p_contracts => water_user_contract_tab_t(
         water_user_contract_obj_t(
            water_user_contract_ref_t(
               c_water_user,
               c_contract_name),
            lookup_type_obj_t('CWMS','Storage','', 'T'),
            null, -- effective
            null, -- expiration
            0,    -- contracted_storage
            0,    -- initial_use_allocation
            0,    -- future_use_allocation
            'ac-ft', -- storage units
            null, -- future_use_percent_activated
            null, -- total_alloc_percent_activated
            location_obj_t(location_ref_t(c_pump_loc_id, c_office_id)), -- pump_out_location must be location_obj_t
            null, -- pump_out_below_location
            null  -- pump_in_location
         )
      ),
      p_fail_if_exists => 'F');

   commit;
end setup;

procedure teardown
is
begin
   begin
      cwms_water_supply.delete_contract(
         p_contract_ref => water_user_contract_ref_t(
            c_water_user,
            c_contract_name),
         p_delete_action => cwms_util.delete_all);
   exception when others then null; end;
   begin
      cwms_water_supply.delete_water_user(
         p_project_location_ref => location_ref_t(c_project_loc_id, c_office_id),
         p_entity_name => c_water_user_name,
         p_delete_action => cwms_util.delete_all);
   exception when others then null; end;
   begin
      -- Remove the project created during setup to clean AT_PROJECT and children
      cwms_project.delete_project(
         p_project_id    => c_project_loc_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   exception when others then null; end;
   begin
      cwms_loc.delete_location(c_pump_loc_id, cwms_util.delete_all, c_office_id);
   exception when others then null; end;
   begin
      cwms_loc.delete_location(c_project_loc_id, cwms_util.delete_all, c_office_id);
   exception when others then null; end;
   commit;
end teardown;

procedure test_roundtrip_pump_accounting_units
is
   l_contract_ref   water_user_contract_ref_t := water_user_contract_ref_t(
      c_water_user,
      c_contract_name);
   l_tz             varchar2(28) := 'UTC';
   l_start_time     date := to_date('2025-01-01 00:00','yyyy-mm-dd hh24:mi');
   l_end_time       date := to_date('2025-01-01 01:00','yyyy-mm-dd hh24:mi');
   l_flow_cfs       binary_double := 100;
   l_expected_cms   binary_double;
   l_set            wat_usr_contract_acct_tab_t;
begin
   -- Compute expected cms via database conversion logic to avoid hard-coding factors
   l_expected_cms := cwms_util.convert_units(l_flow_cfs, 'cfs', 'cms');

   -- Store one accounting record with cfs unit
   cwms_water_supply.store_accounting_set(
      p_accounting_tab => wat_usr_contract_acct_tab_t(
         wat_usr_contract_acct_obj_t(
            l_contract_ref,
            location_ref_t(c_pump_loc_id, c_office_id),
            lookup_type_obj_t('CWMS','Pipeline','', 'T'),
            l_flow_cfs,
            'cfs',
            l_start_time,
            'Roundtrip units test')
      ),
      p_contract_ref => l_contract_ref,
      p_pump_time_window_tab => loc_ref_time_window_tab_t(
         loc_ref_time_window_obj_t(location_ref_t(c_pump_loc_id, c_office_id), l_start_time, l_end_time)
      ),
      p_time_zone => l_tz,
      p_flow_unit_id => null,
      p_store_rule => null,
      p_override_prot => 'F');

   -- Retrieve in cfs and validate
   cwms_water_supply.retrieve_accounting_set(
      p_accounting_set => l_set,
      p_contract_ref => l_contract_ref,
      p_units => 'cfs',
      p_start_time => l_start_time,
      p_end_time => l_end_time,
      p_time_zone => l_tz,
      p_start_inclusive => 'T',
      p_end_inclusive => 'T',
      p_ascending_flag => 'T',
      p_row_limit => 10,
      p_transfer_type => null);

   ut.expect(l_set.count).to_equal(1);
   ut.expect(abs(l_set(1).pump_flow - l_flow_cfs) < 1e-6).to_be_true();
   ut.expect(upper(l_set(1).pump_flow_unit)).to_equal('CFS');

   -- Retrieve in cms and validate conversion
   cwms_water_supply.retrieve_accounting_set(
      p_accounting_set => l_set,
      p_contract_ref => l_contract_ref,
      p_units => 'cms',
      p_start_time => l_start_time,
      p_end_time => l_end_time,
      p_time_zone => l_tz,
      p_start_inclusive => 'T',
      p_end_inclusive => 'T',
      p_ascending_flag => 'T',
      p_row_limit => 10,
      p_transfer_type => null);

   ut.expect(l_set.count).to_equal(1);
   ut.expect(abs(l_set(1).pump_flow - l_expected_cms) < 1e-6).to_be_true();
   ut.expect(upper(l_set(1).pump_flow_unit)).to_equal('CMS');

end test_roundtrip_pump_accounting_units;

end test_cwms_water_supply;
/
show errors;

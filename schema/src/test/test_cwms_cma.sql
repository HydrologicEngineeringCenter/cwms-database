/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

--------------------------------------------------------------------------------
-- Covers only the A2W-related procedures of CWMS_CMA that were rewritten to read/
-- write AT_A2W_ATTRIBUTES / AT_PUBLISHED_TS / AT_PUBLISHED_RATING instead of the
-- retired wide AT_A2W_TS_CODES_BY_LOC columns: p_load_a2w_by_location,
-- p_clear_a2w_ts_code, p_set_a2w_num_tsids, p_add_missing_a2w_rows.
-- p_refresh_a2w_ts_codes is untested here - its body is fully commented out
-- (a no-op) and was not touched by the refactor.
--------------------------------------------------------------------------------
create or replace package test_cwms_cma as
   --%suite(Test schema for cwms_cma A2W procedures)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Test that p_load_a2w_by_location creates AT_A2W_ATTRIBUTES/AT_PUBLISHED_TS/AT_PUBLISHED_RATING rows, and that a second call replaces them)
   procedure load_creates_and_updates_mappings;
   --%test(Test that p_load_a2w_by_location does not insert TS_CODE_OPENING into AT_PUBLISHED_TS when OPENING_SOURCE_OBJ = 'OBJ')
   procedure load_skips_obj_sourced_opening;
   --%test(Test that p_load_a2w_by_location reports a base-parameter mismatch via p_error_msg instead of raising)
   procedure load_reports_base_parameter_mismatch;
   --%test(Test that p_clear_a2w_ts_code removes a ts_code from every location/published_id it was mapped under)
   procedure clear_ts_code_removes_all_mappings;
   --%test(Test that p_set_a2w_num_tsids sets display_flag to F and notes a location with no published TS codes)
   procedure set_num_tsids_flips_flag_when_empty;
   --%test(Test that p_set_a2w_num_tsids leaves display_flag alone when published TS codes are present)
   procedure set_num_tsids_leaves_flag_when_present;
   --%test(Test that p_add_missing_a2w_rows creates exactly one AT_A2W_ATTRIBUTES row per location, even if called twice)
   procedure add_missing_rows_is_idempotent;

   procedure teardown;

   c_office_id       constant varchar2(3)  := '&&office_id';

   -- shared pool: a single location that owns the TS IDs / rating spec reused (by ts_code /
   -- rating_spec_code, not by their own location) across the separate per-scenario
   -- "target" locations below.
   c_shared_loc      constant varchar2(30) := 'TESTCMASHARED';
   c_ts_id_elev      constant varchar2(60) := 'TESTCMASHARED.Elev.Inst.1Hour.0.Test';
   c_ts_id_stage     constant varchar2(60) := 'TESTCMASHARED.Stage.Inst.1Hour.0.Test';
   c_ts_id_inflow    constant varchar2(60) := 'TESTCMASHARED.Flow.Inst.1Hour.0.Test';
   c_template_id     constant varchar2(60)  := 'Elev;Stor.Test-CMA-Linear';
   c_rating_spec_id  constant varchar2(120) := 'TESTCMASHARED.Elev;Stor.Test-CMA-Linear.Test';

   -- one dedicated target location per scenario, so tests don't depend on run order
   c_loc_load             constant varchar2(30) := 'TESTCMALOAD';
   c_loc_opening           constant varchar2(30) := 'TESTCMAOPEN';
   c_loc_mismatch          constant varchar2(30) := 'TESTCMAMISMATCH';
   c_loc_clear1            constant varchar2(30) := 'TESTCMACLEAR1';
   c_loc_clear2            constant varchar2(30) := 'TESTCMACLEAR2';
   c_loc_numtsids_empty    constant varchar2(30) := 'TESTCMANUM0';
   c_loc_numtsids_present  constant varchar2(30) := 'TESTCMANUM1';
   c_loc_missing           constant varchar2(30) := 'TESTCMAMISSING';
end test_cwms_cma;
/

show errors;

grant execute on test_cwms_cma to cwms_user;
create or replace package body test_cwms_cma as
   --------------------------------------------------------------------------------
   -- procedure call_load
   -- Thin wrapper around cwms_cma.p_load_a2w_by_location that fills in NULL/default
   -- for the ~30 fields a given test doesn't care about, so each test only has to
   -- name the handful of parameters it's actually exercising.
   --------------------------------------------------------------------------------
   procedure call_load (
      p_location_id           in varchar2,
      p_display_flag          in varchar2,
      p_notes                 in varchar2,
      p_ts_code_elev          in number default null,
      p_ts_code_stage         in number default null,
      p_ts_code_inflow        in number default null,
      p_ts_code_opening       in number default null,
      p_opening_source_obj    in varchar2 default null,
      p_rating_code_elev_stor in number default null,
      p_error_msg             out varchar2)
   is
   begin
      cwms_cma.p_load_a2w_by_location(
         p_db_office_id            => c_office_id,
         p_location_id             => p_location_id,
         p_display_flag            => p_display_flag,
         p_notes                   => p_notes,
         p_num_ts_codes            => 0,
         p_ts_code_elev            => p_ts_code_elev,
         p_ts_code_inflow          => p_ts_code_inflow,
         p_ts_code_outflow         => null,
         p_ts_code_sur_release     => null,
         p_ts_code_precip          => null,
         p_ts_code_stage           => p_ts_code_stage,
         p_ts_code_stor_drought    => null,
         p_ts_code_stor_Flood      => null,
         p_ts_code_elev_tw         => null,
         p_ts_code_stage_tw        => null,
         p_ts_code_rule_Curve_elev => null,
         p_ts_code_power_Gen       => null,
         p_ts_code_temp_air        => null,
         p_ts_code_temp_water      => null,
         p_ts_code_do              => null,
         p_ts_code_ph              => null,
         p_ts_code_cond            => null,
         p_ts_code_wind_dir        => null,
         p_ts_code_wind_speed      => null,
         p_ts_code_volt            => null,
         p_ts_code_pct_flood       => null,
         p_ts_code_pct_con         => null,
         p_ts_code_irrad           => null,
         p_ts_code_evap            => null,
         p_rating_code_elev_stor   => p_rating_code_elev_stor,
         p_rating_code_elev_area   => null,
         p_rating_code_outlet_Flow => null,
         p_ts_code_opening         => p_ts_code_opening,
         p_opening_source_obj      => p_opening_source_obj,
         p_lake_summary_tf         => 'F',
         p_error_msg               => p_error_msg);
   end call_load;
   --------------------------------------------------------------------------------
   -- procedure teardown
   --------------------------------------------------------------------------------
   procedure teardown
      is
      procedure drop_target_loc (p_location_id in varchar2)
         is
         l_location_code number;
      begin
         begin
            select location_code into l_location_code
              from cwms_v_loc
             where db_office_id = c_office_id and location_id = p_location_id and rownum = 1;

            delete from at_published_ts where location_code = l_location_code;
            delete from at_published_rating where location_code = l_location_code;
            delete from at_a2w_attributes where location_code = l_location_code;
         exception
            when no_data_found then null;
         end;

         cwms_loc.delete_location(
            p_location_id    => p_location_id,
            p_delete_action  => cwms_util.delete_all,
            p_db_office_id   => c_office_id);
      exception
         when others then null;
      end drop_target_loc;
   begin
      drop_target_loc(c_loc_load);
      drop_target_loc(c_loc_opening);
      drop_target_loc(c_loc_mismatch);
      drop_target_loc(c_loc_clear1);
      drop_target_loc(c_loc_clear2);
      drop_target_loc(c_loc_numtsids_empty);
      drop_target_loc(c_loc_numtsids_present);
      drop_target_loc(c_loc_missing);

      begin
         cwms_rating.delete_specs(
            p_spec_id_mask   => c_rating_spec_id,
            p_delete_action  => cwms_util.delete_all,
            p_office_id_mask => c_office_id);
      exception
         when others then null;
      end;
      begin
         cwms_rating.delete_templates(
            p_template_id_mask => c_template_id,
            p_delete_action    => cwms_util.delete_all,
            p_office_id_mask   => c_office_id);
      exception
         when others then null;
      end;

      cwms_ts.delete_ts(c_ts_id_elev, cwms_util.delete_all, c_office_id);
      cwms_ts.delete_ts(c_ts_id_stage, cwms_util.delete_all, c_office_id);
      cwms_ts.delete_ts(c_ts_id_inflow, cwms_util.delete_all, c_office_id);

      cwms_loc.delete_location(
         p_location_id    => c_shared_loc,
         p_delete_action  => cwms_util.delete_all,
         p_db_office_id   => c_office_id);
      commit;
   exception
      when others then null;
   end teardown;
   --------------------------------------------------------------------------------
   -- procedure setup
   --------------------------------------------------------------------------------
   procedure setup
      is
      l_errors clob;
      l_xml clob := '
<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
  <rating-template office-id="$office-id">
    <parameters-id>Elev;Stor</parameters-id>
    <version>Test-CMA-Linear</version>
    <ind-parameter-specs>
      <ind-parameter-spec position="1">
        <parameter>Elev</parameter>
        <in-range-method>LINEAR</in-range-method>
        <out-range-low-method>LINEAR</out-range-low-method>
        <out-range-high-method>LINEAR</out-range-high-method>
      </ind-parameter-spec>
    </ind-parameter-specs>
    <dep-parameter>Stor</dep-parameter>
    <description>Elevation-Storage rating for unit tests</description>
  </rating-template>
  <rating-spec office-id="$office-id">
    <rating-spec-id>$rating-spec-id</rating-spec-id>
    <template-id>Elev;Stor.Test-CMA-Linear</template-id>
    <location-id>$location-id</location-id>
    <version>Test</version>
    <source-agency/>
    <in-range-method>LINEAR</in-range-method>
    <out-range-low-method>LINEAR</out-range-low-method>
    <out-range-high-method>LINEAR</out-range-high-method>
    <active>true</active>
    <auto-update>false</auto-update>
    <auto-activate>false</auto-activate>
    <auto-migrate-extension>false</auto-migrate-extension>
    <description>Unit test rating spec</description>
  </rating-spec>
</ratings>';
   begin
      teardown;

      -- shared pool location + TS IDs + rating spec
      cwms_loc.store_location(
         p_location_id    => c_shared_loc,
         p_active         => 'T',
         p_db_office_id   => c_office_id);

      cwms_ts.create_ts(c_office_id, c_ts_id_elev);
      cwms_ts.create_ts(c_office_id, c_ts_id_stage);
      cwms_ts.create_ts(c_office_id, c_ts_id_inflow);

      l_xml := replace(l_xml, '$office-id', c_office_id);
      l_xml := replace(l_xml, '$location-id', c_shared_loc);
      l_xml := replace(l_xml, '$rating-spec-id', c_rating_spec_id);

      cwms_rating.store_ratings_xml(
         p_errors         => l_errors,
         p_xml            => l_xml,
         p_fail_if_exists => 'F',
         p_replace_base   => 'T');
      ut.expect(l_errors).to_be_null;

      -- one bare target location per scenario (no TS IDs of their own - AT_PUBLISHED_TS
      -- only requires the ts_code to exist somewhere, not that it belongs to this location)
      cwms_loc.store_location(p_location_id => c_loc_load, p_active => 'T', p_db_office_id => c_office_id);
      cwms_loc.store_location(p_location_id => c_loc_opening, p_active => 'T', p_db_office_id => c_office_id);
      cwms_loc.store_location(p_location_id => c_loc_mismatch, p_active => 'T', p_db_office_id => c_office_id);
      cwms_loc.store_location(p_location_id => c_loc_clear1, p_active => 'T', p_db_office_id => c_office_id);
      cwms_loc.store_location(p_location_id => c_loc_clear2, p_active => 'T', p_db_office_id => c_office_id);
      cwms_loc.store_location(p_location_id => c_loc_numtsids_empty, p_active => 'T', p_db_office_id => c_office_id);
      cwms_loc.store_location(p_location_id => c_loc_numtsids_present, p_active => 'T', p_db_office_id => c_office_id);
      cwms_loc.store_location(p_location_id => c_loc_missing, p_active => 'T', p_db_office_id => c_office_id);

      commit;
   end setup;
   --------------------------------------------------------------------------------
   -- procedure load_creates_and_updates_mappings
   --------------------------------------------------------------------------------
   procedure load_creates_and_updates_mappings
      is
      l_error_msg         varchar2(4000);
      l_location_code     number;
      l_ts_code_elev      number;
      l_ts_code_stage     number;
      l_rating_spec_code  number;
      l_notes             varchar2(4000);
      l_display_flag      varchar2(1);
      l_mapped_code       number;
      l_count             integer;
   begin
      l_location_code := cwms_loc.get_location_code(c_office_id, c_loc_load);
      l_ts_code_elev := cwms_ts.get_ts_code(c_ts_id_elev, c_office_id);
      l_ts_code_stage := cwms_ts.get_ts_code(c_ts_id_stage, c_office_id);

      select rating_spec_code into l_rating_spec_code
        from av_rating_spec
       where rating_id = c_rating_spec_id and office_id = c_office_id;

      ------------------------------------------------------------------
      -- phase 1: initial save - elev TS + elev-stor rating
      ------------------------------------------------------------------
      call_load(
         p_location_id           => c_loc_load,
         p_display_flag          => 'T',
         p_notes                 => 'initial notes',
         p_ts_code_elev          => l_ts_code_elev,
         p_rating_code_elev_stor => l_rating_spec_code,
         p_error_msg             => l_error_msg);
      commit;

      ut.expect(l_error_msg).to_be_null;

      select notes, display_flag into l_notes, l_display_flag
        from at_a2w_attributes where location_code = l_location_code;
      ut.expect(l_notes).to_equal('initial notes');
      ut.expect(l_display_flag).to_equal('T');

      select ts_code into l_mapped_code
        from at_published_ts where location_code = l_location_code and published_id = 'TS_ELEV';
      ut.expect(l_mapped_code).to_equal(l_ts_code_elev);

      select rating_spec_code into l_mapped_code
        from at_published_rating where location_code = l_location_code and published_id = 'RATING_ELEV_STOR';
      ut.expect(l_mapped_code).to_equal(l_rating_spec_code);

      ------------------------------------------------------------------
      -- phase 2: re-save - elev TS cleared, stage TS set instead, rating cleared.
      -- proves the delete-then-insert-if-not-null pattern replaces old mappings
      -- rather than leaving stale rows behind.
      ------------------------------------------------------------------
      call_load(
         p_location_id  => c_loc_load,
         p_display_flag => 'F',
         p_notes        => 'updated notes',
         p_ts_code_stage => l_ts_code_stage,
         p_error_msg    => l_error_msg);
      commit;

      ut.expect(l_error_msg).to_be_null;

      select notes, display_flag into l_notes, l_display_flag
        from at_a2w_attributes where location_code = l_location_code;
      ut.expect(l_notes).to_equal('updated notes');
      ut.expect(l_display_flag).to_equal('F');

      select count(*) into l_count
        from at_published_ts where location_code = l_location_code and published_id = 'TS_ELEV';
      ut.expect(l_count).to_equal(0);

      select ts_code into l_mapped_code
        from at_published_ts where location_code = l_location_code and published_id = 'TS_STAGE';
      ut.expect(l_mapped_code).to_equal(l_ts_code_stage);

      select count(*) into l_count
        from at_published_rating where location_code = l_location_code and published_id = 'RATING_ELEV_STOR';
      ut.expect(l_count).to_equal(0);
   end load_creates_and_updates_mappings;
   --------------------------------------------------------------------------------
   -- procedure load_skips_obj_sourced_opening
   --------------------------------------------------------------------------------
   procedure load_skips_obj_sourced_opening
      is
      l_error_msg          varchar2(4000);
      l_location_code      number;
      l_count              integer;
      l_opening_source_obj varchar2(5);
   begin
      l_location_code := cwms_loc.get_location_code(c_office_id, c_loc_opening);

      call_load(
         p_location_id        => c_loc_opening,
         p_display_flag       => 'T',
         p_notes              => null,
         p_ts_code_opening    => 999999999,
         p_opening_source_obj => 'OBJ',
         p_error_msg          => l_error_msg);
      commit;

      ut.expect(l_error_msg).to_be_null;

      select count(*) into l_count
        from at_published_ts where location_code = l_location_code and published_id = 'TS_OPENING';
      ut.expect(l_count).to_equal(0);

      select opening_source_obj into l_opening_source_obj
        from at_a2w_attributes where location_code = l_location_code;
      ut.expect(l_opening_source_obj).to_equal('OBJ');
   end load_skips_obj_sourced_opening;
   --------------------------------------------------------------------------------
   -- procedure load_reports_base_parameter_mismatch
   --------------------------------------------------------------------------------
   procedure load_reports_base_parameter_mismatch
      is
      l_error_msg varchar2(4000);
   begin
      -- TS_ELEV's published base parameter is 'Elev', but this passes a 'Stage' ts_code -
      -- AT_PUBLISHED_TS_T01 should reject it, and p_load_a2w_by_location's WHEN OTHERS
      -- handler should turn that into an error message rather than an unhandled exception.
      call_load(
         p_location_id  => c_loc_mismatch,
         p_display_flag => 'T',
         p_notes        => null,
         p_ts_code_elev => cwms_ts.get_ts_code(c_ts_id_stage, c_office_id),
         p_error_msg    => l_error_msg);
      commit;

      ut.expect(l_error_msg).to_be_not_null;
   end load_reports_base_parameter_mismatch;
   --------------------------------------------------------------------------------
   -- procedure clear_ts_code_removes_all_mappings
   --------------------------------------------------------------------------------
   procedure clear_ts_code_removes_all_mappings
      is
      l_ts_code number;
      l_count   integer;
   begin
      l_ts_code := cwms_ts.get_ts_code(c_ts_id_inflow, c_office_id);

      insert into at_published_ts (location_code, published_id, ts_code)
      values (cwms_loc.get_location_code(c_office_id, c_loc_clear1), 'TS_INFLOW', l_ts_code);

      insert into at_published_ts (location_code, published_id, ts_code)
      values (cwms_loc.get_location_code(c_office_id, c_loc_clear2), 'TS_OUTFLOW', l_ts_code);
      commit;

      cwms_cma.p_clear_a2w_ts_code(l_ts_code);
      commit;

      select count(*) into l_count from at_published_ts where ts_code = l_ts_code;
      ut.expect(l_count).to_equal(0);
   end clear_ts_code_removes_all_mappings;
   --------------------------------------------------------------------------------
   -- procedure set_num_tsids_flips_flag_when_empty
   --------------------------------------------------------------------------------
   procedure set_num_tsids_flips_flag_when_empty
      is
      l_location_code number;
      l_notes         varchar2(4000);
      l_display_flag  varchar2(1);
   begin
      l_location_code := cwms_loc.get_location_code(c_office_id, c_loc_numtsids_empty);

      insert into at_a2w_attributes (location_code, date_refreshed, notes, display_flag)
      values (l_location_code, trunc(sysdate), 'before', 'T');
      commit;

      cwms_cma.p_set_a2w_num_tsids(
         p_db_office_id  => c_office_id,
         p_location_code => l_location_code,
         p_user_id       => 'UNIT_TEST');
      commit;

      select notes, display_flag into l_notes, l_display_flag
        from at_a2w_attributes where location_code = l_location_code;

      ut.expect(l_display_flag).to_equal('F');
      ut.expect(l_notes).to_be_like('%no TS IDs selected%');
   end set_num_tsids_flips_flag_when_empty;
   --------------------------------------------------------------------------------
   -- procedure set_num_tsids_leaves_flag_when_present
   --------------------------------------------------------------------------------
   procedure set_num_tsids_leaves_flag_when_present
      is
      l_location_code number;
      l_display_flag  varchar2(1);
      l_notes         varchar2(4000);
   begin
      l_location_code := cwms_loc.get_location_code(c_office_id, c_loc_numtsids_present);

      insert into at_a2w_attributes (location_code, date_refreshed, notes, display_flag)
      values (l_location_code, trunc(sysdate), 'before', 'T');

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_ELEV', cwms_ts.get_ts_code(c_ts_id_elev, c_office_id));
      commit;

      cwms_cma.p_set_a2w_num_tsids(
         p_db_office_id  => c_office_id,
         p_location_code => l_location_code,
         p_user_id       => 'UNIT_TEST');
      commit;

      select display_flag, notes into l_display_flag, l_notes
        from at_a2w_attributes where location_code = l_location_code;

      ut.expect(l_display_flag).to_equal('T');
      ut.expect(l_notes).to_be_like('%updated via CMA on%');
   end set_num_tsids_leaves_flag_when_present;
   --------------------------------------------------------------------------------
   -- procedure add_missing_rows_is_idempotent
   --------------------------------------------------------------------------------
   procedure add_missing_rows_is_idempotent
      is
      l_location_code number;
      l_count         integer;
   begin
      l_location_code := cwms_loc.get_location_code(c_office_id, c_loc_missing);

      select count(*) into l_count from at_a2w_attributes where location_code = l_location_code;
      ut.expect(l_count).to_equal(0);

      cwms_cma.p_add_missing_a2w_rows(
         p_db_office_id  => c_office_id,
         p_location_code => l_location_code,
         p_user_id       => 'UNIT_TEST');
      commit;

      select count(*) into l_count from at_a2w_attributes where location_code = l_location_code;
      ut.expect(l_count).to_equal(1);

      -- calling again for the same, now-registered location must not error or duplicate
      cwms_cma.p_add_missing_a2w_rows(
         p_db_office_id  => c_office_id,
         p_location_code => l_location_code,
         p_user_id       => 'UNIT_TEST');
      commit;

      select count(*) into l_count from at_a2w_attributes where location_code = l_location_code;
      ut.expect(l_count).to_equal(1);
   end add_missing_rows_is_idempotent;

end test_cwms_cma;
/

show errors;

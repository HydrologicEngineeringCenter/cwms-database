/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

create or replace package test_av_a2w_ts_codes_by_loc as
   --%suite(Test schema for av_a2w_ts_codes_by_loc)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Test that published TS codes are pivoted back into the correct wide columns)
   procedure pivots_ts_codes_to_columns;
   --%test(Test that published rating codes are pivoted back into the correct wide columns)
   procedure pivots_rating_codes_to_columns;
   --%test(Test that NUM_TS_CODES counts only AT_PUBLISHED_TS rows, not ratings)
   procedure counts_ts_codes_only;
   --%test(Test that attributes (notes/display_flag/lake_summary_tf/opening_source_obj) come from AT_A2W_ATTRIBUTES)
   procedure shows_attributes;
   --%test(Test that a slot with no published mapping is NULL rather than missing the row)
   procedure unset_slots_are_null;

   procedure teardown;

   c_office_id       constant varchar2(3)  := '&&office_id';
   c_location_id     constant varchar2(30) := 'TESTA2WWIDE';
   c_ts_id_elev      constant varchar2(60) := 'TESTA2WWIDE.Elev.Inst.1Hour.0.Test';
   c_ts_id_stage     constant varchar2(60) := 'TESTA2WWIDE.Stage.Inst.1Hour.0.Test';
   c_ts_id_inflow    constant varchar2(60) := 'TESTA2WWIDE.Flow.Inst.1Hour.0.Test-In';
   c_template_id     constant varchar2(60)  := 'Elev;Stor.Test-A2W-Linear';
   c_rating_spec_id  constant varchar2(120) := 'TESTA2WWIDE.Elev;Stor.Test-A2W-Linear.Test';
end test_av_a2w_ts_codes_by_loc;
/

show errors;

grant execute on test_av_a2w_ts_codes_by_loc to cwms_user;
create or replace package body test_av_a2w_ts_codes_by_loc as
   --------------------------------------------------------------------------------
   -- procedure teardown
   --------------------------------------------------------------------------------
   procedure teardown
      is
      l_location_code number;
      l_errors        clob;
   begin
      begin
         select location_code into l_location_code
           from cwms_v_loc
          where db_office_id = c_office_id
            and location_id = c_location_id
            and rownum = 1;

         delete from at_published_ts where location_code = l_location_code;
         delete from at_published_rating where location_code = l_location_code;
         delete from at_a2w_attributes where location_code = l_location_code;
      exception
         when no_data_found then null;
      end;

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
         p_location_id    => c_location_id,
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
      l_location_code number;
      l_rating_spec_code number;
      l_errors clob;
      l_xml clob := '
<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
  <rating-template office-id="$office-id">
    <parameters-id>Elev;Stor</parameters-id>
    <version>Test-A2W-Linear</version>
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
    <template-id>Elev;Stor.Test-A2W-Linear</template-id>
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

      cwms_loc.store_location(
         p_location_id    => c_location_id,
         p_active         => 'T',
         p_db_office_id   => c_office_id);

      cwms_ts.create_ts(c_office_id, c_ts_id_elev);
      cwms_ts.create_ts(c_office_id, c_ts_id_stage);
      cwms_ts.create_ts(c_office_id, c_ts_id_inflow);

      l_xml := replace(l_xml, '$office-id', c_office_id);
      l_xml := replace(l_xml, '$location-id', c_location_id);
      l_xml := replace(l_xml, '$rating-spec-id', c_rating_spec_id);

      cwms_rating.store_ratings_xml(
         p_errors         => l_errors,
         p_xml            => l_xml,
         p_fail_if_exists => 'F',
         p_replace_base   => 'T');
      ut.expect(l_errors).to_be_null;

      l_location_code := cwms_loc.get_location_code(c_office_id, c_location_id);

      select rating_spec_code
        into l_rating_spec_code
        from av_rating_spec
       where rating_id = c_rating_spec_id
         and office_id = c_office_id;

      insert into at_a2w_attributes (location_code, date_refreshed, notes, display_flag, lake_summary_tf, opening_source_obj)
      values (l_location_code, trunc(sysdate), 'unit test notes', 'T', 'F', 'TS');

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_ELEV', cwms_ts.get_ts_code(c_ts_id_elev, c_office_id));

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_STAGE', cwms_ts.get_ts_code(c_ts_id_stage, c_office_id));

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_INFLOW', cwms_ts.get_ts_code(c_ts_id_inflow, c_office_id));

      insert into at_published_rating (location_code, published_id, rating_spec_code)
      values (l_location_code, 'RATING_ELEV_STOR', l_rating_spec_code);

      commit;
   end setup;
   --------------------------------------------------------------------------------
   -- procedure pivots_ts_codes_to_columns
   --------------------------------------------------------------------------------
   procedure pivots_ts_codes_to_columns
      is
      l_ts_code_elev   number;
      l_ts_code_stage  number;
      l_ts_code_inflow number;
      l_ts_code_outflow number;
   begin
      select ts_code_elev, ts_code_stage, ts_code_inflow, ts_code_outflow
        into l_ts_code_elev, l_ts_code_stage, l_ts_code_inflow, l_ts_code_outflow
        from av_a2w_ts_codes_by_loc
       where location_id = c_location_id
         and db_office_id = c_office_id;

      ut.expect(l_ts_code_elev).to_equal(cwms_ts.get_ts_code(c_ts_id_elev, c_office_id));
      ut.expect(l_ts_code_stage).to_equal(cwms_ts.get_ts_code(c_ts_id_stage, c_office_id));
      ut.expect(l_ts_code_inflow).to_equal(cwms_ts.get_ts_code(c_ts_id_inflow, c_office_id));
      ut.expect(l_ts_code_outflow).to_be_null;
   end pivots_ts_codes_to_columns;
   --------------------------------------------------------------------------------
   -- procedure pivots_rating_codes_to_columns
   --------------------------------------------------------------------------------
   procedure pivots_rating_codes_to_columns
      is
      l_rating_code_elev_stor   number;
      l_rating_code_elev_area   number;
      l_rating_code_outlet_flow number;
      l_expected_rating_spec_code number;
   begin
      select rating_spec_code
        into l_expected_rating_spec_code
        from av_rating_spec
       where rating_id = c_rating_spec_id
         and office_id = c_office_id;

      select rating_code_elev_stor, rating_code_elev_area, rating_code_outlet_flow
        into l_rating_code_elev_stor, l_rating_code_elev_area, l_rating_code_outlet_flow
        from av_a2w_ts_codes_by_loc
       where location_id = c_location_id
         and db_office_id = c_office_id;

      ut.expect(l_rating_code_elev_stor).to_equal(l_expected_rating_spec_code);
      ut.expect(l_rating_code_elev_area).to_be_null;
      ut.expect(l_rating_code_outlet_flow).to_be_null;
   end pivots_rating_codes_to_columns;
   --------------------------------------------------------------------------------
   -- procedure counts_ts_codes_only
   --------------------------------------------------------------------------------
   procedure counts_ts_codes_only
      is
      l_num_ts_codes number;
   begin
      -- 3 AT_PUBLISHED_TS rows were set up (elev, stage, inflow); the 1 AT_PUBLISHED_RATING
      -- row must not be included in NUM_TS_CODES.
      select num_ts_codes
        into l_num_ts_codes
        from av_a2w_ts_codes_by_loc
       where location_id = c_location_id
         and db_office_id = c_office_id;

      ut.expect(l_num_ts_codes).to_equal(3);
   end counts_ts_codes_only;
   --------------------------------------------------------------------------------
   -- procedure shows_attributes
   --------------------------------------------------------------------------------
   procedure shows_attributes
      is
      l_notes           varchar2(4000);
      l_display_flag    varchar2(1);
      l_lake_summary_tf varchar2(1);
      l_opening_source_obj varchar2(5);
   begin
      select notes, display_flag, lake_summary_tf, opening_source_obj
        into l_notes, l_display_flag, l_lake_summary_tf, l_opening_source_obj
        from av_a2w_ts_codes_by_loc
       where location_id = c_location_id
         and db_office_id = c_office_id;

      ut.expect(l_notes).to_equal('unit test notes');
      ut.expect(l_display_flag).to_equal('T');
      ut.expect(l_lake_summary_tf).to_equal('F');
      ut.expect(l_opening_source_obj).to_equal('TS');
   end shows_attributes;
   --------------------------------------------------------------------------------
   -- procedure unset_slots_are_null
   --------------------------------------------------------------------------------
   procedure unset_slots_are_null
      is
      l_ts_code_power_gen number;
      l_ts_code_opening    number;
      l_ts_code_evap       number;
   begin
      select ts_code_power_gen, ts_code_opening, ts_code_evap
        into l_ts_code_power_gen, l_ts_code_opening, l_ts_code_evap
        from av_a2w_ts_codes_by_loc
       where location_id = c_location_id
         and db_office_id = c_office_id;

      ut.expect(l_ts_code_power_gen).to_be_null;
      ut.expect(l_ts_code_opening).to_be_null;
      ut.expect(l_ts_code_evap).to_be_null;
   end unset_slots_are_null;

end test_av_a2w_ts_codes_by_loc;
/

show errors;

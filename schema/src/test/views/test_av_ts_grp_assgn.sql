/*
 * Copyright (c) 2024
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

create or replace package test_av_ts_grp_assgn as
   --%suite(Test schema for AV_TS_GRP_ASSGN)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Test that the view shows assigned time series for CWMS owned categories and groups)
   procedure cwms_owned_cat_and_group;
   --%test(Test that the view shows assigned time series for CWMS owned categories and district owned groups)
   procedure cwms_owned_cat_district_owned_group;
   --%test(Test that the view shows assigned time series for district owned categories and district owned groups)
   procedure district_owned_cat_district_owned_group;
   --%test(Test that view shows rows with null extra metadata such as reference, shared tsids, attributes, and alias ids)
   procedure null_extra_metadata;
   --%test(Test that view shows rows with non-null extra metadata such as reference, shared tsids, attributes, and alias ids)
   procedure non_null_extra_metadata;
   procedure teardown;
   c_district_office_id constant varchar2(3) := '&&office_id';
   c_location_id constant varchar2(30) := 'AARK';
   c_temp_air constant varchar2(60) := 'Temp-Air';
   c_rdl_aliases constant varchar2(60) := 'RDL_Aliases';
   c_reporting constant varchar2(60) := 'Reporting';
   c_assigned_ts_id constant varchar2(60) := c_location_id || '.Temp-Air.Inst.6Hours.0.Raw-Mesonet';
   c_shared_ref_ts_id constant varchar2(60) := c_location_id || '.Temp-Air.Inst.1Hour.0.Raw-Mesonet';
end test_av_ts_grp_assgn;
show errors
/
show errors
grant execute on test_av_ts_grp_assgn to cwms_user;
create or replace package body test_av_ts_grp_assgn as
   --------------------------------------------------------------------------------
-- procedure clear_caches
--------------------------------------------------------------------------------
   procedure clear_caches
      is
   begin
      cwms_ts.clear_all_caches;
      cwms_loc.clear_all_caches;
   end clear_caches;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
   procedure teardown
      is
   begin
      clear_caches;
      cwms_ts.delete_ts_group('Default', c_location_id, c_district_office_id);
      cwms_ts.delete_ts_group(c_temp_air, c_location_id, c_district_office_id);
      cwms_ts.delete_ts_group(c_rdl_aliases, c_reporting, c_district_office_id);
      cwms_ts.delete_ts_category(c_temp_air, 'T', c_district_office_id);
      cwms_ts.delete_ts_category(c_rdl_aliases, 'T', c_district_office_id);
      cwms_loc.delete_location(
         p_location_id => c_location_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id => c_district_office_id);
      commit;
      clear_caches;
   exception
         when others then null;
   end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
   procedure setup
      is
      l_ts_code          NUMBER;
   begin
      ------------------------------
      -- start with a clean slate --
      ------------------------------
--       cwms_env.set_session_office_id(c_district_office_id);
      teardown;
      cwms_loc.store_location2(
         p_location_id => c_location_id,
         p_location_type => null,
         p_elevation => null,
         p_elev_unit_id => null,
         p_vertical_datum => null,
         p_latitude => null,
         p_longitude => null,
         p_horizontal_datum => null,
         p_public_name => null,
         p_long_name => null,
         p_description => null,
         p_time_zone_id => 'CST6CDT',
         p_county_name => null,
         p_state_initial => null,
         p_active => null,
         p_location_kind_id => null,
         p_map_label => null,
         p_published_latitude => null,
         p_published_longitude => null,
         p_bounding_office_id => null,
         p_nation_id => null,
         p_nearest_city => null,
         p_ignorenulls => 'T',
         p_db_office_id => c_district_office_id);
      cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_cwms_ts_id => c_shared_ref_ts_id, p_office_id => c_district_office_id, p_fail_if_exists => 'F');
      cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_cwms_ts_id => c_assigned_ts_id, p_office_id => c_district_office_id, p_fail_if_exists => 'F');
      cwms_ts.store_ts_category(c_temp_air,
                                'usage for unit testing only',
                                'F',
                                'T',
                                c_district_office_id);
      cwms_ts.store_ts_group('Default',
                             c_location_id,
                             'usage for unit testing only',
                             'F',
                             'T',
                             'Temp-Air',
                             c_shared_ref_ts_id,
                             c_district_office_id);
      cwms_ts.assign_ts_group('Default', c_location_id, c_assigned_ts_id, null, null, null, c_district_office_id);
      cwms_ts.store_ts_group(c_temp_air,
                             c_location_id,
                             'usage for unit testing only',
                             'F',
                             'T',
                             'Temp-Air',
                             c_shared_ref_ts_id,
                             c_district_office_id);
      cwms_ts.assign_ts_group(c_temp_air, c_location_id, c_assigned_ts_id, 0,
                              '6Hours-Historical', c_shared_ref_ts_id, c_district_office_id);
      cwms_ts.assign_ts_group('Default', 'Default', c_assigned_ts_id, null, null, null, c_district_office_id);
      cwms_ts.store_ts_group(c_rdl_aliases,
                             c_reporting,
                             'usage for unit testing only',
                             'F',
                             'T',
                             null,
                             null,
                             c_district_office_id);
      cwms_ts.assign_ts_group(c_rdl_aliases, c_reporting, c_shared_ref_ts_id, null,
                              null, null, c_district_office_id);
   end setup;
   --------------------------------------------------------------------------------
   -- procedure cat_profile_parser
   --------------------------------------------------------------------------------
   procedure cwms_owned_cat_and_group
      is
      l_expected_count INTEGER := 1;
      l_actual_count   INTEGER;
      cursor l_expected_data is
         select 'Default' AS category_id,
                'Default' AS group_id,
                cwms_ts.get_ts_code(c_assigned_ts_id, c_district_office_id) as ts_code,
                c_district_office_id as db_office_id,
                c_assigned_ts_id as ts_id,
                'CWMS' as category_office_id,
                'CWMS' as group_office_id
         from dual;
   begin
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_ts_grp_assgn v
            WHERE v.category_id = r_expected.category_id
              AND v.group_id = r_expected.group_id
              AND v.ts_code = r_expected.ts_code
              AND v.ts_id = r_expected.ts_id
              AND v.category_office_id = r_expected.category_office_id
              AND v.group_office_id = r_expected.group_office_id;

         END LOOP;
      ut.expect(l_actual_count).to_equal(l_expected_count);
   end cwms_owned_cat_and_group;

   procedure cwms_owned_cat_district_owned_group
      is
      l_expected_count INTEGER := 1;
      l_actual_count   INTEGER;
      cursor l_expected_data is
         select 'Default' AS category_id,
                c_location_id AS group_id,
                cwms_ts.get_ts_code(c_assigned_ts_id, c_district_office_id) as ts_code,
                c_district_office_id as db_office_id,
                c_assigned_ts_id as ts_id,
                'CWMS' as category_office_id,
                c_district_office_id as group_office_id
         from dual;
   begin
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_ts_grp_assgn v
            WHERE v.category_id = r_expected.category_id
              AND v.group_id = r_expected.group_id
              AND v.ts_code = r_expected.ts_code
              AND v.ts_id = r_expected.ts_id
              AND v.category_office_id = r_expected.category_office_id
              AND v.group_office_id = r_expected.group_office_id;

         END LOOP;
      ut.expect(l_actual_count).to_equal(l_expected_count);
   end cwms_owned_cat_district_owned_group;

   procedure district_owned_cat_district_owned_group
      is
      l_expected_count INTEGER := 1;
      l_actual_count   INTEGER;
      cursor l_expected_data is
         select c_temp_air AS category_id,
                c_location_id AS group_id,
                cwms_ts.get_ts_code(c_assigned_ts_id, c_district_office_id) as ts_code,
                c_district_office_id as db_office_id,
                c_assigned_ts_id as ts_id,
                c_district_office_id as category_office_id,
                c_district_office_id as group_office_id
         from dual;
   begin
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_ts_grp_assgn v
            WHERE v.category_id = r_expected.category_id
              AND v.group_id = r_expected.group_id
              AND v.ts_code = r_expected.ts_code
              AND v.ts_id = r_expected.ts_id
              AND v.category_office_id = r_expected.category_office_id
              AND v.group_office_id = r_expected.group_office_id;

         END LOOP;
      ut.expect(l_actual_count).to_equal(l_expected_count);
   end district_owned_cat_district_owned_group;

   procedure null_extra_metadata
      is
      l_expected_count INTEGER := 1;
      l_actual_count   INTEGER;
      cursor l_expected_data is
         select c_rdl_aliases AS category_id,
                c_reporting AS group_id,
                cwms_ts.get_ts_code(c_shared_ref_ts_id, c_district_office_id) as ts_code,
                c_district_office_id as db_office_id,
                c_shared_ref_ts_id as ts_id,
                c_district_office_id as category_office_id,
                c_district_office_id as group_office_id
         from dual;
   begin
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_ts_grp_assgn v
            WHERE v.category_id = r_expected.category_id
              AND v.group_id = r_expected.group_id
              AND v.ts_code = r_expected.ts_code
              AND v.ts_id = r_expected.ts_id
              AND v.category_office_id = r_expected.category_office_id
              AND v.group_office_id = r_expected.group_office_id
              AND v.alias_id is null
              AND v.ref_ts_id is null
              AND v.shared_alias_id is null
              AND v.attribute is null
              AND v.shared_ref_ts_id is null;

         END LOOP;
      ut.expect(l_actual_count).to_equal(l_expected_count);
   end null_extra_metadata;

   procedure non_null_extra_metadata
      is
      l_expected_count INTEGER := 1;
      l_actual_count   INTEGER;
      cursor l_expected_data is
         select c_temp_air AS category_id,
                c_location_id AS group_id,
                cwms_ts.get_ts_code(c_assigned_ts_id, c_district_office_id) as ts_code,
                c_district_office_id as db_office_id,
                c_assigned_ts_id as ts_id,
                c_district_office_id as category_office_id,
                c_district_office_id as group_office_id,
                '6Hours-Historical'  as alias_id,
                c_shared_ref_ts_id as ref_ts_id,
                'Temp-Air'           as shared_alias_id,
                0                    as attribute,
                c_shared_ref_ts_id   as shared_ref_ts_id
         from dual;
   begin
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_ts_grp_assgn v
            WHERE v.category_id = r_expected.category_id
              AND v.group_id = r_expected.group_id
              AND v.ts_code = r_expected.ts_code
              AND v.ts_id = r_expected.ts_id
              AND v.category_office_id = r_expected.category_office_id
              AND v.group_office_id = r_expected.group_office_id
              AND v.alias_id = r_expected.alias_id
              AND v.ref_ts_id = r_expected.ref_ts_id
              AND v.shared_alias_id = r_expected.shared_alias_id
              AND v.attribute = r_expected.attribute
              AND v.shared_ref_ts_id = r_expected.shared_ref_ts_id;

         END LOOP;
      ut.expect(l_actual_count).to_equal(l_expected_count);
   end non_null_extra_metadata;

end test_av_ts_grp_assgn;
/

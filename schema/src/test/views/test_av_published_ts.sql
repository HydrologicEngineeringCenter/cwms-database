/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

create or replace package test_av_published_ts as
   --%suite(Test schema for av_published_ts)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Test that an AT_PUBLISHED_TS row joins through to CWMS_PUBLISHED_ID and CWMS_V_TS_ID)
   procedure shows_published_ts_mapping;
   --%test(Test that PUBLISHED_ID distinguishes two published slots that share a base parameter)
   procedure distinguishes_same_base_parameter;
   --%test(Test that CWMS_PUBLISHED_ID is seeded with all 28 A2W published IDs and the right base parameters)
   procedure seeds_all_published_ids;

   procedure teardown;

   c_office_id      constant varchar2(3)  := '&&office_id';
   c_location_id    constant varchar2(30) := 'TESTPUBTS';
   c_ts_id_elev     constant varchar2(60) := 'TESTPUBTS.Elev.Inst.1Hour.0.Test';
   c_ts_id_elev_tw  constant varchar2(60) := 'TESTPUBTS.Elev.Inst.1Hour.0.Test-TW';
end test_av_published_ts;
/

show errors;

grant execute on test_av_published_ts to cwms_user;
create or replace package body test_av_published_ts as
   --------------------------------------------------------------------------------
   -- procedure teardown
   --------------------------------------------------------------------------------
   procedure teardown
      is
      l_location_code number;
   begin
      begin
         select location_code into l_location_code
           from cwms_v_loc
          where db_office_id = c_office_id
            and location_id = c_location_id
            and rownum = 1;

         delete from at_published_ts where location_code = l_location_code;
      exception
         when no_data_found then null;
      end;

      cwms_ts.delete_ts(
         p_cwms_ts_id      => c_ts_id_elev,
         p_delete_action   => cwms_util.delete_all,
         p_db_office_id    => c_office_id);
      cwms_ts.delete_ts(
         p_cwms_ts_id      => c_ts_id_elev_tw,
         p_delete_action   => cwms_util.delete_all,
         p_db_office_id    => c_office_id);

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
   begin
      teardown;

      cwms_loc.store_location(
         p_location_id    => c_location_id,
         p_active         => 'T',
         p_db_office_id   => c_office_id);

      cwms_ts.create_ts(c_office_id, c_ts_id_elev);
      cwms_ts.create_ts(c_office_id, c_ts_id_elev_tw);

      l_location_code := cwms_loc.get_location_code(c_office_id, c_location_id);

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_ELEV', cwms_ts.get_ts_code(c_ts_id_elev, c_office_id));

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_ELEV_TW', cwms_ts.get_ts_code(c_ts_id_elev_tw, c_office_id));

      commit;
   end setup;
   --------------------------------------------------------------------------------
   -- procedure shows_published_ts_mapping
   --------------------------------------------------------------------------------
   procedure shows_published_ts_mapping
      is
      l_namespace          varchar2(32);
      l_public_name        varchar2(128);
      l_base_parameter_code number;
      l_cwms_ts_id         varchar2(191);
      l_elev_base_param_code number;
   begin
      select base_parameter_code
        into l_elev_base_param_code
        from cwms_base_parameter
       where base_parameter_id = 'Elev';

      select namespace, public_name, base_parameter_code, cwms_ts_id
        into l_namespace, l_public_name, l_base_parameter_code, l_cwms_ts_id
        from av_published_ts
       where office_id = c_office_id
         and location_id = c_location_id
         and published_id = 'TS_ELEV';

      ut.expect(l_namespace).to_equal('PUBLISHED');
      ut.expect(l_public_name).to_equal('Elevation Time Series');
      ut.expect(upper(l_cwms_ts_id)).to_equal(upper(c_ts_id_elev));
      ut.expect(l_base_parameter_code).to_equal(l_elev_base_param_code);
   end shows_published_ts_mapping;
   --------------------------------------------------------------------------------
   -- procedure distinguishes_same_base_parameter
   --------------------------------------------------------------------------------
   procedure distinguishes_same_base_parameter
      is
      l_count integer;
      l_elev_ts_code    number;
      l_elev_tw_ts_code number;
   begin
      -- TS_ELEV and TS_ELEV_TW both have base parameter 'Elev', but are two distinct
      -- published slots for the same location - PARAMETER_ID alone can't tell them apart,
      -- which is exactly the bug this view previously had.
      select count(*)
        into l_count
        from av_published_ts
       where office_id = c_office_id
         and location_id = c_location_id;

      ut.expect(l_count).to_equal(2);

      select ts_code into l_elev_ts_code
        from av_published_ts
       where office_id = c_office_id and location_id = c_location_id and published_id = 'TS_ELEV';

      select ts_code into l_elev_tw_ts_code
        from av_published_ts
       where office_id = c_office_id and location_id = c_location_id and published_id = 'TS_ELEV_TW';

      ut.expect(l_elev_ts_code).not_to_equal(l_elev_tw_ts_code);
   end distinguishes_same_base_parameter;
   --------------------------------------------------------------------------------
   -- procedure expect_base_parameter (helper, not a test)
   --------------------------------------------------------------------------------
   procedure expect_base_parameter (
      p_published_id      in varchar2,
      p_base_parameter_id in varchar2)
      is
      l_base_parameter_id cwms_base_parameter.base_parameter_id%type;
   begin
      select b.base_parameter_id
        into l_base_parameter_id
        from cwms_published_id p
        join cwms_base_parameter b on b.base_parameter_code = p.base_parameter_code
       where p.published_id = p_published_id;

      -- compare "ID=param" strings so a failure names the published ID
      ut.expect(p_published_id || '=' || l_base_parameter_id).to_equal(p_published_id || '=' || p_base_parameter_id);
   exception
      when no_data_found then
         ut.fail(p_published_id || ' is missing from CWMS_PUBLISHED_ID');
   end expect_base_parameter;
   --------------------------------------------------------------------------------
   -- procedure seeds_all_published_ids
   --------------------------------------------------------------------------------
   procedure seeds_all_published_ids
      is
   begin
      -- every published ID that CWMS_A2W and the A2W views rely on
      expect_base_parameter('TS_ELEV',            'Elev');
      expect_base_parameter('TS_PRECIP',          'Precip');
      expect_base_parameter('TS_STAGE',           'Stage');
      expect_base_parameter('TS_INFLOW',          'Flow');
      expect_base_parameter('TS_OUTFLOW',         'Flow');
      expect_base_parameter('TS_STOR_FLOOD',      'Stor');
      expect_base_parameter('TS_STOR_DROUGHT',    'Stor');
      expect_base_parameter('TS_SUR_RELEASE',     'Flow');
      expect_base_parameter('TS_ELEV_TW',         'Elev');
      expect_base_parameter('TS_STAGE_TW',        'Stage');
      expect_base_parameter('TS_RULE_CURVE_ELEV', 'Elev');
      expect_base_parameter('TS_POWER_GEN',       'Power');
      -- these three are sub-parameters (Temp-Air, Temp-Water, Conc-DO), so the
      -- published ID must carry the base parameter
      expect_base_parameter('TS_TEMP_AIR',        'Temp');
      expect_base_parameter('TS_TEMP_WATER',      'Temp');
      expect_base_parameter('TS_DO',              'Conc');
      expect_base_parameter('TS_COND',            'Cond');
      expect_base_parameter('TS_PH',              'pH');
      expect_base_parameter('TS_OPENING',         'Opening');
      expect_base_parameter('TS_WIND_DIR',        'Dir');
      expect_base_parameter('TS_WIND_SPEED',      'Speed');
      expect_base_parameter('TS_VOLT',            'Volt');
      expect_base_parameter('TS_PCT_FLOOD',       '%');
      expect_base_parameter('TS_PCT_CON',         '%');
      expect_base_parameter('TS_IRRAD',           'Irrad');
      expect_base_parameter('TS_EVAP',            'Evap');
      expect_base_parameter('RATING_ELEV_STOR',   'Stor');
      expect_base_parameter('RATING_ELEV_AREA',   'Area');
      expect_base_parameter('RATING_OUTLET_FLOW', 'Flow');
   end seeds_all_published_ids;

end test_av_published_ts;
/

show errors;

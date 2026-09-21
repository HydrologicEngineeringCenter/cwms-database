/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

create or replace package test_av_a2w_ts_codes_by_loc2 as
   --%suite(Test schema for av_a2w_ts_codes_by_loc2)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Test that PUBLISHED_ID is mapped back to its legacy TS_TYPE label, e.g. TS_SUR_RELEASE -> SURCHARGE RELEASE)
   procedure maps_published_id_to_legacy_ts_type;
   --%test(Test that rows are only shown when AT_A2W_ATTRIBUTES.DISPLAY_FLAG = 'T')
   procedure filters_on_display_flag;
   --%test(Test that CWMS_TS_ID/UNIT_ID/BASE_PARAMETER_ID come from CWMS_V_TS_ID for the EN unit system)
   procedure joins_ts_identifier_details;

   procedure teardown;

   c_office_id     constant varchar2(3)  := '&&office_id';
   c_location_id   constant varchar2(30) := 'TESTA2WLOC2';
   c_ts_id_elev    constant varchar2(60) := 'TESTA2WLOC2.Elev.Inst.1Hour.0.Test';
   c_ts_id_sur_rel constant varchar2(60) := 'TESTA2WLOC2.Flow.Inst.1Hour.0.Test-SurRelease';
end test_av_a2w_ts_codes_by_loc2;
/

show errors;

grant execute on test_av_a2w_ts_codes_by_loc2 to cwms_user;
create or replace package body test_av_a2w_ts_codes_by_loc2 as
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
         delete from at_a2w_attributes where location_code = l_location_code;
      exception
         when no_data_found then null;
      end;

      cwms_ts.delete_ts(c_ts_id_elev, cwms_util.delete_all, c_office_id);
      cwms_ts.delete_ts(c_ts_id_sur_rel, cwms_util.delete_all, c_office_id);

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
      cwms_ts.create_ts(c_office_id, c_ts_id_sur_rel);

      l_location_code := cwms_loc.get_location_code(c_office_id, c_location_id);

      insert into at_a2w_attributes (location_code, date_refreshed, display_flag)
      values (l_location_code, trunc(sysdate), 'T');

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_ELEV', cwms_ts.get_ts_code(c_ts_id_elev, c_office_id));

      insert into at_published_ts (location_code, published_id, ts_code)
      values (l_location_code, 'TS_SUR_RELEASE', cwms_ts.get_ts_code(c_ts_id_sur_rel, c_office_id));

      commit;
   end setup;
   --------------------------------------------------------------------------------
   -- procedure maps_published_id_to_legacy_ts_type
   --------------------------------------------------------------------------------
   procedure maps_published_id_to_legacy_ts_type
      is
      l_ts_type varchar2(30);
   begin
      select ts_type
        into l_ts_type
        from av_a2w_ts_codes_by_loc2
       where location_id = c_location_id
         and cwms_ts_id = c_ts_id_sur_rel;

      ut.expect(l_ts_type).to_equal('SURCHARGE RELEASE');

      select ts_type
        into l_ts_type
        from av_a2w_ts_codes_by_loc2
       where location_id = c_location_id
         and cwms_ts_id = c_ts_id_elev;

      ut.expect(l_ts_type).to_equal('ELEV');
   end maps_published_id_to_legacy_ts_type;
   --------------------------------------------------------------------------------
   -- procedure filters_on_display_flag
   --------------------------------------------------------------------------------
   procedure filters_on_display_flag
      is
      l_count integer;
   begin
      select count(*)
        into l_count
        from av_a2w_ts_codes_by_loc2
       where location_id = c_location_id;

      ut.expect(l_count).to_equal(2);

      update at_a2w_attributes
         set display_flag = 'F'
       where location_code = cwms_loc.get_location_code(c_office_id, c_location_id);
      commit;

      select count(*)
        into l_count
        from av_a2w_ts_codes_by_loc2
       where location_id = c_location_id;

      ut.expect(l_count).to_equal(0);
   end filters_on_display_flag;
   --------------------------------------------------------------------------------
   -- procedure joins_ts_identifier_details
   --------------------------------------------------------------------------------
   procedure joins_ts_identifier_details
      is
      l_base_parameter_id varchar2(49);
      l_db_office_id      varchar2(16);
   begin
      select base_parameter_id, db_office_id
        into l_base_parameter_id, l_db_office_id
        from av_a2w_ts_codes_by_loc2
       where location_id = c_location_id
         and cwms_ts_id = c_ts_id_elev;

      ut.expect(l_base_parameter_id).to_equal('Elev');
      ut.expect(l_db_office_id).to_equal(c_office_id);
   end joins_ts_identifier_details;

end test_av_a2w_ts_codes_by_loc2;
/

show errors;

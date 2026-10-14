/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

create or replace package test_av_a2w_attributes as
   --%suite(Test schema for av_a2w_attributes)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Test that a row in AT_A2W_ATTRIBUTES is visible through the view joined to its location)
   procedure shows_attributes_row;
   --%test(Test that NOTES/DISPLAY_FLAG/LAKE_SUMMARY_TF/OPENING_SOURCE_OBJ come from AT_A2W_ATTRIBUTES, not the wide table)
   procedure reflects_current_values;
   --%test(Test that a location with no AT_A2W_ATTRIBUTES row is absent from the view)
   procedure hides_locations_without_attributes;

   procedure teardown;

   c_office_id     constant varchar2(3)  := '&&office_id';
   c_location_id   constant varchar2(30) := 'TESTA2WATTR';
   c_location_id2  constant varchar2(30) := 'TESTA2WATTR2';
end test_av_a2w_attributes;
/

show errors;

grant execute on test_av_a2w_attributes to cwms_user;
create or replace package body test_av_a2w_attributes as
   --------------------------------------------------------------------------------
   -- procedure teardown
   --------------------------------------------------------------------------------
   procedure teardown
      is
   begin
      delete from at_a2w_attributes
       where location_code in (cwms_loc.get_location_code(c_office_id, c_location_id),
                                cwms_loc.get_location_code(c_office_id, c_location_id2));

      cwms_loc.delete_location(
         p_location_id    => c_location_id,
         p_delete_action  => cwms_util.delete_all,
         p_db_office_id   => c_office_id);
      cwms_loc.delete_location(
         p_location_id    => c_location_id2,
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
   begin
      teardown;

      cwms_loc.store_location(
         p_location_id    => c_location_id,
         p_active         => 'T',
         p_db_office_id   => c_office_id);
      cwms_loc.store_location(
         p_location_id    => c_location_id2,
         p_active         => 'T',
         p_db_office_id   => c_office_id);

      insert into at_a2w_attributes (location_code, date_refreshed, notes, display_flag, lake_summary_tf, opening_source_obj)
      values (cwms_loc.get_location_code(c_office_id, c_location_id),
              trunc(sysdate), 'unit test notes', 'T', 'T', 'TS');
      commit;
   end setup;
   --------------------------------------------------------------------------------
   -- procedure shows_attributes_row
   --------------------------------------------------------------------------------
   procedure shows_attributes_row
      is
      l_count integer;
   begin
      select count(*)
        into l_count
        from av_a2w_attributes
       where office_id = c_office_id
         and location_id = c_location_id
         and location_code = cwms_loc.get_location_code(c_office_id, c_location_id);

      ut.expect(l_count).to_equal(1);
   end shows_attributes_row;
   --------------------------------------------------------------------------------
   -- procedure reflects_current_values
   --------------------------------------------------------------------------------
   procedure reflects_current_values
      is
      l_notes              varchar2(4000);
      l_display_flag       varchar2(1);
      l_lake_summary_tf    varchar2(1);
      l_opening_source_obj varchar2(5);
   begin
      select notes, display_flag, lake_summary_tf, opening_source_obj
        into l_notes, l_display_flag, l_lake_summary_tf, l_opening_source_obj
        from av_a2w_attributes
       where office_id = c_office_id
         and location_id = c_location_id;

      ut.expect(l_notes).to_equal('unit test notes');
      ut.expect(l_display_flag).to_equal('T');
      ut.expect(l_lake_summary_tf).to_equal('T');
      ut.expect(l_opening_source_obj).to_equal('TS');

      update at_a2w_attributes
         set notes = 'updated unit test notes',
             display_flag = 'F'
       where location_code = cwms_loc.get_location_code(c_office_id, c_location_id);
      commit;

      select notes, display_flag
        into l_notes, l_display_flag
        from av_a2w_attributes
       where office_id = c_office_id
         and location_id = c_location_id;

      ut.expect(l_notes).to_equal('updated unit test notes');
      ut.expect(l_display_flag).to_equal('F');
   end reflects_current_values;
   --------------------------------------------------------------------------------
   -- procedure hides_locations_without_attributes
   --------------------------------------------------------------------------------
   procedure hides_locations_without_attributes
      is
      l_count integer;
   begin
      select count(*)
        into l_count
        from av_a2w_attributes
       where office_id = c_office_id
         and location_id = c_location_id2;

      ut.expect(l_count).to_equal(0);
   end hides_locations_without_attributes;

end test_av_a2w_attributes;
/

show errors;

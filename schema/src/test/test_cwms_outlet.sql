set verify off;
create or replace package test_cwms_outlet as
   --%suite(Test schema for outlet functionality)

   --%beforeall(setup)
   --%afterall(teardown)
   --%rollback(manual)

   procedure teardown;
   procedure setup;


   --%test(Store and retrieve compound outlet and ensure location ids are correct)
   procedure test_compound_outlet_with_sublocations;

   c_office_id constant varchar2(3) := '&&office_id';
   c_project_location_id varchar2(57) := 'ProjWithOutlet';
   c_base_outlet_id varchar2(57) := 'OutletAsBase';
   c_base_outlet_id_with_sub varchar2(57) := 'OutletAsBase-WithSub';
   c_compound_outlet_id varchar2(57) := c_project_location_id || '-CompoundOutlet';
   c_location_ids constant str_tab_t := str_tab_t(c_project_location_id, c_base_outlet_id, c_base_outlet_id_with_sub,
                                                  c_compound_outlet_id);
   c_timezone_id varchar2(28) := 'America/Los_Angeles';
end test_cwms_outlet;
/
show errors;
show errors;
create or replace package body test_cwms_outlet as
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
      exc_location_id_not_found exception;
      pragma exception_init (exc_location_id_not_found, -20025);
   begin
      clear_caches;
      begin
         cwms_loc.delete_location(
            p_location_id => c_base_outlet_id_with_sub,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id => c_office_id);
         cwms_loc.delete_location(
            p_location_id => c_base_outlet_id,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id => c_office_id);
         cwms_loc.delete_location(
            p_location_id => c_compound_outlet_id,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id => c_office_id);
         cwms_loc.delete_location(
            p_location_id => c_project_location_id,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id => c_office_id);
      exception
         when exc_location_id_not_found then null;
      end;
      commit;
      clear_caches;
   end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
   procedure setup
      is
      l_outlet               project_structure_obj_t;
      l_project_location_ref location_ref_t;
      l_location_ref         location_ref_t;
      l_location             location_obj_t;
      l_project_obj          project_obj_t;
   begin
      ------------------------------
      -- start with a clean slate --
      ------------------------------
      cwms_env.set_session_office_id(c_office_id);
--       teardown;
      cwms_util.set_output_debug_info(false);
      -----------------------
      -- for each location --
      -----------------------
      for i in 1..c_location_ids.count
         loop
         -------------------------
         -- create the location --
         -------------------------
            cwms_loc.store_location2(
               p_location_id => c_location_ids(i),
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
               p_time_zone_id => c_timezone_id,
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
               p_db_office_id => c_office_id);
         end loop;
      l_location_ref := location_ref_t(c_project_location_id, c_office_id);
      l_location := location_obj_t(l_location_ref);
      l_project_obj := project_obj_t(l_location, null, null, null,
                                     null, null, null, null, null, null,
                                     null, null, null, null, null, null, null);
      cwms_project.store_project(l_project_obj, 'F');
      l_project_location_ref := location_ref_t(c_project_location_id, c_office_id);
      l_location_ref := location_ref_t(c_base_outlet_id, c_office_id);
      l_location := location_obj_t(l_location_ref);
      l_outlet := project_structure_obj_t(l_project_location_ref, l_location, null);
      cwms_outlet.store_outlet(l_outlet, null, 'F');
      l_location_ref := location_ref_t(c_base_outlet_id_with_sub, c_office_id);
      l_location := location_obj_t(l_location_ref);
      l_outlet := project_structure_obj_t(l_project_location_ref, l_location, null);
      cwms_outlet.store_outlet(l_outlet, null, 'F');
      commit;
   end setup;

   function sort_tab_t(input_tab str_tab_t) return str_tab_t is
      sorted_tab str_tab_t := str_tab_t();
   begin
      select column_value bulk collect
      into sorted_tab
      from table (input_tab)
      order by column_value;

      return sorted_tab;
   end sort_tab_t;

   procedure test_compound_outlet_with_sublocations
      is
      l_compound_outlets_in       str_tab_tab_t;
      l_compound_outlets_out      str_tab_tab_t;
      l_compound_outlet_inner_in  str_tab_t;
      l_compound_outlet_inner_out str_tab_t;
   begin
      l_compound_outlets_in := str_tab_tab_t(str_tab_t(c_base_outlet_id_with_sub, c_base_outlet_id));
      cwms_outlet.store_compound_outlet(c_project_location_id, c_compound_outlet_id, l_compound_outlets_in, 'F',
                                        c_office_id);
      l_compound_outlets_out := cwms_outlet.retrieve_compound_outlet_f(c_compound_outlet_id,
                                                                       c_project_location_id,
                                                                       c_office_id);
      ut.expect(l_compound_outlets_out.count()).to_equal(l_compound_outlets_in.count());
      for i in 1..l_compound_outlets_in.count()
         loop
            l_compound_outlet_inner_in := sort_tab_t(l_compound_outlets_in(i));
            l_compound_outlet_inner_out := sort_tab_t(l_compound_outlets_out(i));
            ut.expect(l_compound_outlet_inner_out.count()).to_equal(l_compound_outlet_inner_in.count());
            for j in 1..l_compound_outlet_inner_in.count()
               loop
                  ut.expect(l_compound_outlet_inner_out(j)).to_equal(l_compound_outlet_inner_in(j));
               end loop;
         end loop;

   end test_compound_outlet_with_sublocations;

end test_cwms_outlet;
/

grant execute on test_cwms_outlet to cwms_user;

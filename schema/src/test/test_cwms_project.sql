CREATE OR REPLACE package &&cwms_schema..test_cwms_project as

--%suite(Test cwms_project package code)
--%afterall(teardown)
--%beforeall (setup)
--%rollback(manual)

--%test(Test request lock with defaults and non-defaults)
procedure test_request_lock;

procedure setup;
procedure teardown;

c_office_id      constant varchar2(16)  := '&&office_id';
c_location_id1   constant varchar2(16)  := 'ReqLock1';
c_location_id2   constant varchar2(16)  := 'ReqLock2';
c_time_zone      constant varchar2(16)  := 'US/Central';
c_username       constant varchar2(16)  := 'TestUser1';

end test_cwms_project;
/

CREATE OR REPLACE PACKAGE BODY &&cwms_schema..test_cwms_project
AS
    --------------------------------------------------------------------------------
    -- procedure setup
    --------------------------------------------------------------------------------
    PROCEDURE setup
    IS

    BEGIN
       cwms_env.set_session_office_id(c_office_id);
       DELETE FROM AT_PROJECT_LOCK WHERE project_code = cwms_loc.GET_LOCATION_CODE(c_office_id, c_location_id1);
       DELETE FROM AT_PROJECT_LOCK WHERE project_code = cwms_loc.GET_LOCATION_CODE(c_office_id, c_location_id2);
       CWMS_SEC.ADD_CWMS_USER (
          c_username,
          cwms_20.char_32_array_type ('CWMS Users','TS ID Creator', 'Viewer Users'),
          c_office_id);
    END setup;


    PROCEDURE teardown
    IS
    BEGIN
       cwms_sec.delete_user(c_username);
    END teardown;

--------------------------------------------------------------------------------
-- test_cat_ts_id_with_create
--------------------------------------------------------------------------------
   procedure test_request_lock
   is
      l_prj_mask  varchar2(16)  := 'ReqLock*';
      l_username  varchar2(30);
      l_osuser    varchar2(30);
      l_program   varchar2(48);
      l_machine   varchar2(64);
      l_osuser2   varchar2(30) := 'for_osuser';
      l_program2  varchar2(48) := 'for_program';
      l_machine2  varchar2(64) := 'for_machine';
      l_app_id    varchar2(16) := 'REGI';
      l_lock1_id  varchar2(32);
      l_lock2_id  varchar2(32);
      l_crsr           sys_refcursor;
      l_office_ids     cwms_t_str_tab;
      l_project_ids    cwms_t_str_tab;
      l_app_ids        cwms_t_str_tab;
      l_acq_times      cwms_t_str_tab;
      l_ses_users      cwms_t_str_tab;
      l_os_users       cwms_t_str_tab;
      l_ses_programs   cwms_t_str_tab;
      l_ses_machines   cwms_t_str_tab;
      l_count          pls_integer;

   begin

      -------------------------------------
      -- store the locations where we are going to create projects --
      -------------------------------------
      cwms_loc.store_location (
              p_location_id  => c_location_id1,
              p_time_zone_id => c_time_zone,
              p_db_office_id => c_office_id);
      cwms_loc.store_location (
              p_location_id  => c_location_id2,
              p_time_zone_id => c_time_zone,
              p_db_office_id => c_office_id);

      -------------------------------------
      -- store two projects at locations --
      -------------------------------------
      cwms_project.store_project(project_obj_t(
              p_project_location             => cwms_t_location_obj(cwms_t_location_ref(c_location_id1, c_office_id)),
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
              p_yield_time_frame_end         => null));

      cwms_project.store_project(project_obj_t(
              p_project_location             => cwms_t_location_obj(cwms_t_location_ref(c_location_id2, c_office_id)),
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
              p_yield_time_frame_end         => null));

      -------------------------------------
      -- get the session info --
      -------------------------------------

      select username,
             osuser,
             program,
             machine
      into l_username,
         l_osuser,
         l_program,
         l_machine
      from v$session
      where sid = sys_context('userenv', 'sid');

      -------------------------------------
      -- update the lock revoker rights so that we will be able to request locks --
      -------------------------------------
      cwms_project.update_lock_revoker_rights(l_username, c_location_id1, 'T', l_app_id, c_office_id);
      cwms_project.update_lock_revoker_rights(c_username, c_location_id2, 'T', l_app_id, c_office_id);

      -------------------------------------
      -- request a lock at each location:
      --   one uses default values for username, osuser, program, machine
      --   one passes in values
      -------------------------------------
      l_lock1_id := cwms_project.request_lock(c_location_id1, l_app_id, 'F', 30, c_office_id);
      l_lock2_id := cwms_project.request_lock(c_location_id2, l_app_id, 'F', 30, c_office_id, c_username, l_osuser2, l_program2, l_machine2);

      -------------------------------------
      -- get the locks --
      -------------------------------------
      cwms_project.cat_locks(l_crsr, l_prj_mask, l_app_id, c_time_zone, c_office_id);

      fetch l_crsr
         bulk collect
         into l_office_ids,
         l_project_ids,
         l_app_ids,
         l_acq_times,
         l_ses_users,
         l_os_users,
         l_ses_programs,
         l_ses_machines;
      close l_crsr;

      -------------------------------------
      -- check the locks --
      -------------------------------------
      ut.expect(l_project_ids.count).to_equal(2);

      -- should have one at loc1 and one at loc2
      select count(*) into l_count from table(l_project_ids) where column_value = c_location_id1;
      ut.expect(l_count).to_equal(1);
      select count(*) into l_count from table(l_project_ids) where column_value = c_location_id2;
      ut.expect(l_count).to_equal(1);

      -- should have one with session username and one with passed in username
      select count(*) into l_count from table(l_ses_users) where column_value = l_username;
      ut.expect(l_count).to_equal(1);
      select count(*) into l_count from table(l_ses_users) where column_value = c_username;
      ut.expect(l_count).to_equal(1);

      -- should have one with session osuser and one with passed in osuser
      select count(*) into l_count from table(l_os_users) where column_value = l_osuser;
      ut.expect(l_count).to_equal(1);
      select count(*) into l_count from table(l_os_users) where column_value = l_osuser2;
      ut.expect(l_count).to_equal(1);

      -- should have one with session program and one with passed in program
      select count(*) into l_count from table(l_ses_programs) where column_value = l_program;
      ut.expect(l_count).to_equal(1);
      select count(*) into l_count from table(l_ses_programs) where column_value = l_program2;
      ut.expect(l_count).to_equal(1);

      -- should have one with session machine and one with passed in machine
      select count(*) into l_count from table(l_ses_machines) where column_value = l_machine;
      ut.expect(l_count).to_equal(1);
      select count(*) into l_count from table(l_ses_machines) where column_value = l_machine2;
      ut.expect(l_count).to_equal(1);

      cwms_project.release_lock(l_lock1_id);
      cwms_project.release_lock(l_lock2_id);

   end test_request_lock;


END test_cwms_project;
/

show errors;
grant execute on test_cwms_project to cwms_user;
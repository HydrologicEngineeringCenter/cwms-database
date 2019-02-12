set define on
create table location_tz_changes as 
   select co.office_id,
          cwms_loc.get_location_id(pl.location_code) as location_id,
          tz.time_zone_name
     from at_physical_location pl,
          at_base_location bl,
          cwms_office co,
          cwms_time_zone tz
    where tz.time_zone_name in ('CST', 'PST')
      and pl.time_zone_code = tz.time_zone_code
      and bl.base_location_code = pl.base_location_code
      and co.office_code = bl.db_office_code
    order by 1, 2; 
create table xchg_set_tz_changes as 
   select ts.db_office_id as office_id,
          xs.xchg_set_id,
          ts.cwms_ts_id as ts_id,
          '/'||xm.a_pathname_part||
          '/'||xm.b_pathname_part||
          '/'||xm.c_pathname_part||'/'||
          '/'||xm.e_pathname_part||
          '/'||xm.f_pathname_part||'/' as dss_pathname,
          tz.time_zone_name
    from at_xchg_dss_ts_mappings xm,
         at_xchg_set xs, 
         at_cwms_ts_id ts,
         cwms_time_zone tz
    where tz.time_zone_name in ('CST', 'PST')
      and xm.time_zone_code = tz.time_zone_code
      and xs.xchg_set_code = xm.xchg_set_code
      and ts.ts_code = xm.cwms_ts_code
    order by 1, 2, 3;
declare
   l_tables str_tab_t := str_tab_t('CWMS_TIME_ZONE', 'CWMS_TIME_ZONE_ALIAS');
   c_cst_old_code integer := 210;
   c_cst_new_code integer := 380;
   c_pst_old_code integer := 344;
   c_pst_new_code integer := 387;
begin
   -------------------------------------------------------------------
   -- first remove policy from CWMS_TIME_ZONE, CWMS_TIME_ZONE_ALIAS --
   -------------------------------------------------------------------
   for i in 1..l_tables.count loop
      begin
         dbms_rls.drop_policy(
            object_schema => '&cwms_schema',
            object_name   => l_tables(i),
            policy_name   => 'SERVICE_USER_POLICY');
      exception
         when others then null;
      end;
   end loop;
   ------------------------------------------------------------------
   -- re-assign any data from CST to US/Central, PST to US/Pacific --
   ------------------------------------------------------------------
   update at_physical_location
      set time_zone_code = c_cst_new_code
    where time_zone_code = c_cst_old_code;  

   update at_physical_location
      set time_zone_code = c_pst_new_code
    where time_zone_code = c_pst_old_code;  

   update at_xchg_dss_ts_mappings
      set time_zone_code = c_cst_new_code
    where time_zone_code = c_cst_old_code;  

   update at_xchg_dss_ts_mappings
      set time_zone_code = c_pst_new_code
    where time_zone_code = c_pst_old_code;  
   -----------------------------------------------------
   -- now delete the time zones and rebuild the mview --
   -----------------------------------------------------
   delete from cwms_time_zone where time_zone_name in ('CST', 'PST');
   dbms_snapshot.refresh( '&cwms_schema..MV_TIME_ZONE', 'C');
   -----------------------------------------------
   -- finally add the policy back to the tables --
   -----------------------------------------------
   for i in 1..l_tables.count loop
      begin
         dbms_rls.add_policy (
            object_schema    => '&cwms_schema',
            object_name      => l_tables(i),
            policy_name      => 'SERVICE_USER_POLICY',
            function_schema  => '&cwms_schema',
            policy_function  => 'CHECK_SESSION_USER',
            policy_type      => dbms_rls.shared_context_sensitive,
            statement_types  => 'select');
      end;
   end loop;
end;
/

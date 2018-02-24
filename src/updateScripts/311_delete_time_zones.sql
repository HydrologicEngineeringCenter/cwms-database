declare
   l_tables str_tab_t := str_tab_t('CWMS_TIME_ZONE', 'CWMS_TIME_ZONE_ALIAS');
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


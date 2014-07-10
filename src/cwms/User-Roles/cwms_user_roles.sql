--
-- ignore errors
--
whenever sqlerror continue
   
drop role cwms_user;

--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

create role cwms_user not identified;
grant create session to cwms_user;
grant aq_user_role to cwms_user;
grant aq_administrator_role to cwms_user;
grant select on dba_scheduler_jobs to cwms_user;
grant select on dba_scheduler_job_log to cwms_user;
grant select on dba_scheduler_job_run_details to cwms_user;

-- execute on packages granted later
-- select on views granted later


begin
   --
   -- grant network address resolve privileges (new in Oracle 11)
   --
   begin
      dbms_network_acl_admin.drop_acl('resolve.xml');
   exception
      when others then null;
   end;
   dbms_network_acl_admin.create_acl(
      acl         => 'resolve.xml',
      description => 'resolve acl', 
      principal   => 'CWMS_USER', 
      is_grant    => true, 
      privilege   => 'resolve');
   dbms_network_acl_admin.assign_acl(
      acl         => 'resolve.xml', 
      host        => '*');
end;
/


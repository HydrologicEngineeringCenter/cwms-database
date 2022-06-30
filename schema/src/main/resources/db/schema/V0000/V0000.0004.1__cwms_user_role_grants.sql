grant create session to cwms_user;
--grant aq_user_role to cwms_user;
--grant aq_administrator_role to cwms_user;
--grant select on dba_scheduler_jobs to cwms_user;
--grant select on dba_scheduler_job_log to cwms_user;
--grant select on dba_scheduler_job_run_details to cwms_user;

-- execute on packages granted later
-- select on views granted later

declare
   privilege_not_granted exception;
   pragma exception_init(privilege_not_granted, -1927);

begin
   --
   -- grant network address resolve privileges (new in Oracle 12)
   --
     ----------------------------------------
      -- remove existing ACEs if they exist --
      ----------------------------------------
      begin
         dbms_network_acl_admin.remove_host_ace(
            host => '*',
            ace  => xs$ace_type(
               privilege_list   => xs$name_list('resolve'),
               granted          => true,
               principal_name   => 'CWMS_USER',
               principal_type   => xs_acl.ptype_db),
            remove_empty_acl => true);
      exception
         when privilege_not_granted then null;
      end;
     commit;
     ----------------------------------
      -- grant 'resolve' to CWMS_USER --
      ----------------------------------
      dbms_network_acl_admin.append_host_ace(
         host => '*',
         ace  => xs$ace_type(
            privilege_list  => xs$name_list('resolve'),
            granted         => true,
            principal_name  => 'CWMS_USER',
            principal_type  => xs_acl.ptype_db));
     commit;
end;
/

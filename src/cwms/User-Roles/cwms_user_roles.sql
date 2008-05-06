--
-- ignore errors
--
whenever sqlerror continue
   
drop role cwms_dev;
drop role cwms_user;

--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

create role cwms_user not identified;
grant create session to cwms_user;
grant aq_user_role to cwms_user;
grant aq_administrator_role to cwms_user;

-- execute on packages granted later

create role cwms_dev not identified;
grant cwms_user to cwms_dev;

-- select on views granted later


begin
   --
   -- grant network address resolve privileges (new in Oracle 11)
   --
   $if dbms_db_version.version > 10 $then
      --
      -- compile only on Oracle 11 or above
      --
      dbms_network_acl_admin.drop_acl('resolve.xml');
      dbms_network_acl_admin.create_acl(
         acl         => 'resolve.xml',
         description => 'resolve acl', 
         principal   => 'CWMS_USER', 
         is_grant    => true, 
         privilege   => 'resolve');
      dbms_network_acl_admin.assign_acl(
         acl         => 'resolve.xml', 
         host        => '*');
   $else
      dbms_output.put_line('Skipping network acl setup on pre-11 database.');
   $end
end;
/


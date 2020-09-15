declare
   privilege_not_granted exception;
   pragma exception_init(privilege_not_granted, -1927);

   l_acl_name    varchar2(30) := 'root.xml'; -- applies to root domain, e.g., '*'
   l_wallet_path varchar2(64) := '/oradata/M5CWMSP1';
begin
   $if dbms_db_version.version > 11 $then
      -- ===============
      -- == ORACLE 12 ==
      -- ===============
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
      begin
         dbms_network_acl_admin.remove_host_ace(
            host => '*',
            ace  => xs$ace_type(
               privilege_list   => xs$name_list('resolve','connect','http','smtp'),
               granted          => true,
               principal_name   => 'CWMS_20',
               principal_type   => xs_acl.ptype_db),
            remove_empty_acl => true);
      exception
         when privilege_not_granted then null;
      end;
      begin
         dbms_network_acl_admin.remove_wallet_ace(
            wallet_path => 'file:'||l_wallet_path,
            ace         => xs$ace_type(
               privilege_list => xs$name_list('use_client_certificates'),
               principal_name => 'CWMS_20',
               principal_type  => xs_acl.ptype_db));
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
      ---------------------------------------------------------------
      -- grant 'resolve', 'connect', 'http', and 'smpt' to CWMS_20 --
      ---------------------------------------------------------------
      dbms_network_acl_admin.append_host_ace(
         host => '*',
         ace  => xs$ace_type(
            privilege_list => xs$name_list('resolve','connect','http','smtp'),
            granted        => true,
            principal_name => 'CWMS_20',
            principal_type  => xs_acl.ptype_db));
      ------------------------------------------
      -- set wallet path for SSL certificates --
      ------------------------------------------
      dbms_network_acl_admin.append_wallet_ace(
         wallet_path => 'file:'||l_wallet_path,
         ace         => xs$ace_type(
            privilege_list => xs$name_list('use_client_certificates'),
            principal_name => 'CWMS_20',
            principal_type  => xs_acl.ptype_db));
      commit;
   $else
      -- ===============
      -- == ORACLE 11 ==
      -- ===============
      ------------------------------------------
      -- drop any ACL assigned to root domain --
      ------------------------------------------
      for rec in (select acl from dba_network_acls where host = '*') loop
         dbms_network_acl_admin.drop_acl(substr(rec.acl, instr(rec.acl, '/', -1) + 1));
      end loop;
      commit;
      ------------------------------------------------------------------------------------
      -- create new ACL for root domain with 'resolve' granted to CWMS_USER and CWMS_20 --
      ------------------------------------------------------------------------------------
      dbms_network_acl_admin.create_acl(
         acl         => l_acl_name,
         description => 'Root domain network ACL',
         principal   => 'CWMS_USER',
         is_grant    => true,
         privilege   => 'resolve');
      dbms_network_acl_admin.assign_acl(
         acl         => l_acl_name,
         host        => '*');
      dbms_network_acl_admin.add_privilege(
         acl         => l_acl_name,
         principal   => 'CWMS_20',
         is_grant    => true,
         privilege   => 'resolve');
      -------------------------------------------
      -- assign 'connect' to CWMS_20 user only --
      -------------------------------------------
      dbms_network_acl_admin.add_privilege(
         acl         => l_acl_name,
         principal   => 'CWMS_20',
         is_grant    => true,
         privilege   => 'connect');
      commit;
      ----------------------------------------------------------------------------------------------
      -- As per https://support.oracle.com/knowledge/Oracle%20Database%20Products/1074843_1.html, --
      -- item 9, ACLs don't work when granted through roles on 11.2.0.3 and above                 --
      ----------------------------------------------------------------------------------------------
      for rec in (select grantee as username from dba_role_privs where granted_role = 'CWMS_USER') loop
         dbms_network_acl_admin.add_privilege(
            acl       => l_acl_name,
            principal => rec.username,
            is_grant  => true,
            privilege => 'resolve');
      end loop;
      commit;
   $end
end;
/

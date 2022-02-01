
alter user ${CWMS_SCHEMA} ${CWMS_SCHEMA_AUTH};
alter user ${CWMS_SCHEMA} account unlock;
alter user ${CWMS_SCHEMA} profile cwms_prof;
alter user ${CWMS_SCHEMA} default tablespace CWMS_20DATA;
alter user ${CWMS_SCHEMA} quota unlimited on CWMS_20_TSV;
alter user ${CWMS_SCHEMA} quota unlimited on CWMS_20AT_DATA;
alter user ${CWMS_SCHEMA} quota unlimited on CWMS_20DATA;
alter user ${CWMS_SCHEMA} quota unlimited on CWMS_AQ;
alter user ${CWMS_SCHEMA} quota unlimited on CWMS_AQ_EX;

--grant aq_administrator_role to ${CWMS_SCHEMA};
--grant aq_user_role to ${CWMS_SCHEMA};

grant create role to ${CWMS_SCHEMA};
--grant javauserpriv to ${CWMS_SCHEMA};
grant alter any index to ${CWMS_SCHEMA};
grant alter any indextype to ${CWMS_SCHEMA};
grant alter any materialized view to ${CWMS_SCHEMA};
grant alter any procedure to ${CWMS_SCHEMA};
grant alter any sequence to ${CWMS_SCHEMA};
grant alter any table to ${CWMS_SCHEMA};
grant alter any trigger to ${CWMS_SCHEMA};
grant alter any type to ${CWMS_SCHEMA};
grant alter resource cost to ${CWMS_SCHEMA};
grant alter tablespace to ${CWMS_SCHEMA};
grant analyze any dictionary to ${CWMS_SCHEMA};
grant analyze any to ${CWMS_SCHEMA};
grant become user to ${CWMS_SCHEMA};
grant comment any table to ${CWMS_SCHEMA};
grant create any context to ${CWMS_SCHEMA};
grant create any index to ${CWMS_SCHEMA};
grant create any indextype to ${CWMS_SCHEMA};
grant create any job to ${CWMS_SCHEMA};
grant create any library to ${CWMS_SCHEMA};
grant create any materialized view to ${CWMS_SCHEMA};
grant create any procedure to ${CWMS_SCHEMA};
grant create any sequence to ${CWMS_SCHEMA};
grant create any synonym to ${CWMS_SCHEMA};
grant create any table to ${CWMS_SCHEMA};
grant create any trigger to ${CWMS_SCHEMA};
grant create any type to ${CWMS_SCHEMA};
grant create any view to ${CWMS_SCHEMA};
grant create cluster to ${CWMS_SCHEMA};
grant create database link to ${CWMS_SCHEMA};
grant create dimension to ${CWMS_SCHEMA};
grant create indextype to ${CWMS_SCHEMA};
grant create job to ${CWMS_SCHEMA};
grant create library to ${CWMS_SCHEMA};
grant create materialized view to ${CWMS_SCHEMA};
grant create operator to ${CWMS_SCHEMA};
grant create procedure to ${CWMS_SCHEMA};
grant create public synonym to ${CWMS_SCHEMA};
grant create sequence to ${CWMS_SCHEMA};
grant create session to ${CWMS_SCHEMA};
grant create synonym to ${CWMS_SCHEMA};
grant create table to ${CWMS_SCHEMA};
grant create tablespace to ${CWMS_SCHEMA};
grant create trigger to ${CWMS_SCHEMA};
grant create type to ${CWMS_SCHEMA};
grant create view to ${CWMS_SCHEMA};
grant debug any procedure to ${CWMS_SCHEMA};
grant debug connect session to ${CWMS_SCHEMA};
grant delete any table to ${CWMS_SCHEMA};
grant drop any index to ${CWMS_SCHEMA};
grant drop any indextype to ${CWMS_SCHEMA};
grant drop any materialized view to ${CWMS_SCHEMA};
grant drop any procedure to ${CWMS_SCHEMA};
grant drop any sequence to ${CWMS_SCHEMA};
grant drop any table to ${CWMS_SCHEMA};
grant drop any trigger to ${CWMS_SCHEMA};
grant drop any type to ${CWMS_SCHEMA};
grant drop any view to ${CWMS_SCHEMA};
grant drop public synonym to ${CWMS_SCHEMA};
grant drop tablespace to ${CWMS_SCHEMA};
grant execute any class to ${CWMS_SCHEMA};
grant execute any indextype to ${CWMS_SCHEMA};
grant execute any procedure to ${CWMS_SCHEMA} with admin option;
grant execute any type to ${CWMS_SCHEMA};
grant execute on  ctxsys.ctx_ddl to ${CWMS_SCHEMA};
grant execute on  ctxsys.ctx_doc to ${CWMS_SCHEMA};
grant execute on  dbms_crypto to ${CWMS_SCHEMA};
grant execute on  sys.dbms_aq to ${CWMS_SCHEMA};
grant execute on  sys.dbms_aq_bqview to ${CWMS_SCHEMA};
grant execute on  sys.dbms_aqadm to ${CWMS_SCHEMA};
grant execute on  sys.dbms_lock to ${CWMS_SCHEMA};
grant execute on  sys.dbms_rls to ${CWMS_SCHEMA};
grant execute on  sys.utl_recomp to ${CWMS_SCHEMA};
grant export full database to ${CWMS_SCHEMA};
grant import full database to ${CWMS_SCHEMA};
grant insert any table to ${CWMS_SCHEMA};
grant manage scheduler to ${CWMS_SCHEMA};
grant manage tablespace to ${CWMS_SCHEMA};
grant select any dictionary to ${CWMS_SCHEMA};
grant select any sequence to ${CWMS_SCHEMA};
grant select any table to ${CWMS_SCHEMA};
grant select on  sys.v_$latch to ${CWMS_SCHEMA};
grant select on  sys.v_$mystat to ${CWMS_SCHEMA};
grant select on  sys.v_$statname to ${CWMS_SCHEMA};
--grant select on  sys.v_$timer to ${CWMS_SCHEMA};
grant update any table to ${CWMS_SCHEMA};

-- These privileges are added as they are dervied from 'PUBLIC' user before.
-- These grants will be revoked from 'PUBLIC' to confirm to STIG requirements
grant execute on dbms_lob to ${CWMS_SCHEMA};
grant execute on dbms_random to ${CWMS_SCHEMA};
grant execute on utl_smtp to ${CWMS_SCHEMA};
grant execute on utl_http to ${CWMS_SCHEMA};

begin
   --
   -- grant queue privileges
   --
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'enqueue_any',
      grantee      => '${CWMS_SCHEMA}',
      admin_option => false);
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'dequeue_any',
      grantee      => '${CWMS_SCHEMA}',
      admin_option => false);
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'manage_any',
      grantee      => '${CWMS_SCHEMA}',
      admin_option => false);
   --
   -- grant network address lookup privilege
   --
   /*dbms_network_acl_admin.add_privilege(
      acl         => 'resolve.xml',
      principal   => upper('${CWMS_SCHEMA}'),
      is_grant    => true,
      privilege   => 'resolve');*/
end;
/
declare
   privilege_not_granted exception;
   pragma exception_init(privilege_not_granted, -1927);

begin
   --
   -- grant network privilege
   --
     ----------------------------------------
      -- remove existing ACEs if they exist --
      ----------------------------------------
      begin
         dbms_network_acl_admin.remove_host_ace(
            host => '*',
            ace  => xs$ace_type(
               privilege_list   => xs$name_list('resolve','connect','http','smtp'),
               granted          => true,
               principal_name   => '${CWMS_SCHEMA}',
               principal_type   => xs_acl.ptype_db),
            remove_empty_acl => true);
      exception
         when privilege_not_granted then null;
      end;
      commit;
     ---------------------------------------------------------------
      -- grant 'resolve', 'connect', 'http', and 'smpt' to CWMS_20 --
      ---------------------------------------------------------------
      dbms_network_acl_admin.append_host_ace(
         host => '*',
         ace  => xs$ace_type(
            privilege_list => xs$name_list('resolve','connect','http','smtp'),
            granted        => true,
            principal_name => '${CWMS_SCHEMA}',
            principal_type  => xs_acl.ptype_db));
       commit;

end;
/

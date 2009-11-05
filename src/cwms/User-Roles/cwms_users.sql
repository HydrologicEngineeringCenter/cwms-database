SET define on
create user &cwms_schema
  identified by &cwms_passwd
  default tablespace CWMS_20DATA
  temporary tablespace temp
  profile cwms_prof
  account unlock;

  
alter user &cwms_schema quota unlimited on CWMS_20_TSV;
alter user &cwms_schema quota unlimited on CWMS_20AT_DATA;
alter user &cwms_schema quota unlimited on CWMS_20DATA;

grant aq_administrator_role to &cwms_schema;
grant aq_user_role to &cwms_schema;

grant javauserpriv to &cwms_schema;
grant alter any index to &cwms_schema;
grant alter any indextype to &cwms_schema;
grant alter any materialized view to &cwms_schema;
grant alter any procedure to &cwms_schema;
grant alter any sequence to &cwms_schema;
grant alter any table to &cwms_schema;
grant alter any trigger to &cwms_schema;
grant alter any type to &cwms_schema;
grant alter database to &cwms_schema;
grant alter resource cost to &cwms_schema;
grant alter tablespace to &cwms_schema;
grant analyze any dictionary to &cwms_schema;
grant analyze any to &cwms_schema;
grant become user to &cwms_schema;
grant comment any table to &cwms_schema;
grant create any context to &cwms_schema;
grant create any directory to &cwms_schema;
grant create any index to &cwms_schema;
grant create any indextype to &cwms_schema;
grant create any job to &cwms_schema;
grant create any library to &cwms_schema;
grant create any materialized view to &cwms_schema;
grant create any procedure to &cwms_schema;
grant create any sequence to &cwms_schema;
grant create any synonym to &cwms_schema;
grant create any table to &cwms_schema;
grant create any trigger to &cwms_schema;
grant create any type to &cwms_schema;
grant create any view to &cwms_schema;
grant create cluster to &cwms_schema;
grant create database link to &cwms_schema;
grant create dimension to &cwms_schema;
grant create external job to &cwms_schema;
grant create indextype to &cwms_schema;
grant create job to &cwms_schema;
grant create library to &cwms_schema;
grant create materialized view to &cwms_schema;
grant create operator to &cwms_schema;
grant create procedure to &cwms_schema;
grant create public synonym to &cwms_schema;
grant create sequence to &cwms_schema;
grant create session to &cwms_schema;
grant create synonym to &cwms_schema;
grant create table to &cwms_schema;
grant create tablespace to &cwms_schema;
grant create trigger to &cwms_schema;
grant create type to &cwms_schema;
grant create view to &cwms_schema;
grant debug any procedure to &cwms_schema;
grant debug connect session to &cwms_schema;
grant delete any table to &cwms_schema;
grant drop any index to &cwms_schema;
grant drop any indextype to &cwms_schema;
grant drop any materialized view to &cwms_schema;
grant drop any procedure to &cwms_schema;
grant drop any sequence to &cwms_schema;
grant drop any table to &cwms_schema;
grant drop any trigger to &cwms_schema;
grant drop any type to &cwms_schema;
grant drop any view to &cwms_schema;
grant drop public synonym to &cwms_schema;
grant drop tablespace to &cwms_schema;
grant execute any class to &cwms_schema;
grant execute any indextype to &cwms_schema;
grant execute any procedure to &cwms_schema with admin option;
grant execute any type to &cwms_schema;
grant execute on  ctxsys.ctx_ddl to &cwms_schema;
grant execute on  ctxsys.ctx_doc to &cwms_schema;
grant execute on  dbms_crypto to &cwms_schema;
grant execute on  sys.dbms_aq to &cwms_schema;
grant execute on  sys.dbms_aq_bqview to &cwms_schema;
grant execute on  sys.dbms_lock to &cwms_schema;
grant execute on  sys.dbms_rls to &cwms_schema;
grant execute on  utl_recomp to &cwms_schema;
grant export full database to &cwms_schema;
grant import full database to &cwms_schema;
grant insert any table to &cwms_schema;
grant manage scheduler to &cwms_schema;
grant manage tablespace to &cwms_schema;
grant select any dictionary to &cwms_schema;
grant select any sequence to &cwms_schema;
grant select any table to &cwms_schema;
grant select on  sys.v_$latch to &cwms_schema;
grant select on  sys.v_$mystat to &cwms_schema;
grant select on  sys.v_$statname to &cwms_schema;
grant select on  sys.v_$timer to &cwms_schema;
grant update any table to &cwms_schema;

begin
   --
   -- grant queue privileges
   --
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'enqueue_any',
      grantee      => '&cwms_schema',
      admin_option => false);
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'dequeue_any',
      grantee      => '&cwms_schema',
      admin_option => false);
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'manage_any',
      grantee      => '&cwms_schema',
      admin_option => false);
   
   $if dbms_db_version.version > 10 $then
      --
      -- compile only on Oracle 11 or above
      --
      dbms_network_acl_admin.add_privilege(
         acl         => 'resolve.xml',
         principal   => upper('&cwms_schema'), 
         is_grant    => true, 
         privilege   => 'resolve');
   $end
end;
/




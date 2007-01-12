--
-- ignore errors
--
whenever sqlerror continue

drop user cwms_20 cascade;
drop user &eroc.cwmspd;
drop user &eroc.cwmsdbi;

--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

create user &eroc.cwmsdbi
   identified by &dbi_passwd
   default tablespace cwms_20data
   temporary tablespace temp
   profile default
   account unlock;

grant create session to &eroc.cwmsdbi;

create user &eroc.cwmspd
   identified by &eroc.cwmspd
   password expire
   default tablespace cwms_20data
   temporary tablespace temp
   profile default
   account unlock;

grant cwms_user to &eroc.cwmspd;
alter user &eroc.cwmspd default role cwms_user;
alter user &eroc.cwmspd grant connect through &eroc.cwmsdbi with role cwms_user;

create user cwms_20
  identified by &cwms_passwd
  default tablespace cwms_20data
  temporary tablespace temp
  profile default
  account unlock;
  
alter user cwms_20 quota unlimited on cwms_20_tsv;
alter user cwms_20 quota unlimited on cwms_20at_data;
alter user cwms_20 quota unlimited on cwms_20data;

grant aq_administrator_role to cwms_20;
grant aq_user_role to cwms_20;

grant alter any index to cwms_20;
grant alter any indextype to cwms_20;
grant alter any materialized view to cwms_20;
grant alter any procedure to cwms_20;
grant alter any sequence to cwms_20;
grant alter any table to cwms_20;
grant alter any trigger to cwms_20;
grant alter any type to cwms_20;
grant alter database to cwms_20;
grant alter resource cost to cwms_20;
grant alter tablespace to cwms_20;
grant analyze any dictionary to cwms_20;
grant analyze any to cwms_20;
grant become user to cwms_20;
grant comment any table to cwms_20;
grant create any context to cwms_20;
grant create any directory to cwms_20;
grant create any index to cwms_20;
grant create any indextype to cwms_20;
grant create any job to cwms_20;
grant create any library to cwms_20;
grant create any materialized view to cwms_20;
grant create any procedure to cwms_20;
grant create any sequence to cwms_20;
grant create any synonym to cwms_20;
grant create any table to cwms_20;
grant create any trigger to cwms_20;
grant create any type to cwms_20;
grant create any view to cwms_20;
grant create cluster to cwms_20;
grant create database link to cwms_20;
grant create dimension to cwms_20;
grant create external job to cwms_20;
grant create indextype to cwms_20;
grant create job to cwms_20;
grant create library to cwms_20;
grant create materialized view to cwms_20;
grant create operator to cwms_20;
grant create procedure to cwms_20;
grant create public synonym to cwms_20;
grant create sequence to cwms_20;
grant create session to cwms_20;
grant create synonym to cwms_20;
grant create table to cwms_20;
grant create tablespace to cwms_20;
grant create trigger to cwms_20;
grant create type to cwms_20;
grant create view to cwms_20;
grant debug any procedure to cwms_20;
grant debug connect session to cwms_20;
grant delete any table to cwms_20;
grant drop any index to cwms_20;
grant drop any indextype to cwms_20;
grant drop any materialized view to cwms_20;
grant drop any procedure to cwms_20;
grant drop any sequence to cwms_20;
grant drop any table to cwms_20;
grant drop any trigger to cwms_20;
grant drop any type to cwms_20;
grant drop any view to cwms_20;
grant drop public synonym to cwms_20;
grant drop tablespace to cwms_20;
grant execute any class to cwms_20;
grant execute any indextype to cwms_20;
grant execute any procedure to cwms_20 with admin option;
grant execute any type to cwms_20;
grant execute on  ctxsys.ctx_ddl to cwms_20;
grant execute on  ctxsys.ctx_doc to cwms_20;
grant execute on  sys.dbms_aq to cwms_20;
grant execute on  sys.dbms_aq_bqview to cwms_20;
grant execute on  sys.dbms_lock to cwms_20;
grant execute on  sys.dbms_rls to cwms_20;
grant export full database to cwms_20;
grant import full database to cwms_20;
grant insert any table to cwms_20;
grant manage scheduler to cwms_20;
grant manage tablespace to cwms_20;
grant select any dictionary to cwms_20;
grant select any sequence to cwms_20;
grant select any table to cwms_20;
grant select on  sys.v_$latch to cwms_20;
grant select on  sys.v_$mystat to cwms_20;
grant select on  sys.v_$statname to cwms_20;
grant select on  sys.v_$timer to cwms_20;
grant update any table to cwms_20;

begin
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'enqueue_any',
      grantee      => 'cwms_20',
      admin_option => false);
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'dequeue_any',
      grantee      => 'cwms_20',
      admin_option => false);
   sys.dbms_aqadm.grant_system_privilege (
      privilege    => 'manage_any',
      grantee      => 'cwms_20',
      admin_option => false);
end;
/




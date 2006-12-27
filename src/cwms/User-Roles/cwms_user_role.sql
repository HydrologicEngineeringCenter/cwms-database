begin
   execute immediate 'drop role cwms_user';
exception
   when others then null;
end;
/
begin
   execute immediate 'create role cwms_user not identified';
   execute immediate 'grant lock any table to cwms_user';
   execute immediate 'grant select any table to cwms_user';
   execute immediate 'grant insert any table to cwms_user';
   execute immediate 'grant update any table to cwms_user';
   execute immediate 'grant delete any table to cwms_user';
   execute immediate 'grant execute any operator to cwms_user';
   execute immediate 'grant execute any procedure to cwms_user';
   execute immediate 'grant execute any type to cwms_user';
   execute immediate 'grant execute any indextype to cwms_user';
   execute immediate 'grant select any sequence to cwms_user';
   execute immediate 'grant alter any materialized view to cwms_user';
   execute immediate 'grant create session to cwms_user';
   execute immediate 'grant aq_user_role to cwms_user';
   commit;
end;
/


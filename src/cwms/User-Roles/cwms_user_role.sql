begin
   execute immediate 'drop role cwms_user';
exception
   when others then null;
end;
/
begin
   execute immediate 'create role cwms_user not identified';
   execute immediate 'grant create session to cwms_user';
   execute immediate 'grant aq_user_role to cwms_user';
   commit;
end;
/


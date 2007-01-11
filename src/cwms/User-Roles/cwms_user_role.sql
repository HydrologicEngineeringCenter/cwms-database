begin
   execute immediate 'drop role cwms_user';
exception
   when others then null;
end;
/
create role cwms_user not identified;
grant create session to cwms_user;
grant aq_user_role to cwms_user;
commit;

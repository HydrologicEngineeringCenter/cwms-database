begin
   execute immediate 'drop user &eroc.cwmspd';
exception
   when others then null;
end;
/
begin
   execute immediate 'drop user &eroc.xxxyyy';
exception
   when others then null;
end;
/

create user &eroc.cwmspd
   identified by &pd_passwd
   default tablespace cwms_20data
   temporary tablespace temp
   profile default
   account unlock;

grant cwms_user to &eroc.cwmspd;
alter user &eroc.cwmspd default role all;
alter user &eroc.cwmspd quota unlimited on cwms_20data;

create user &eroc.xxxyyy
   identified by &eroc.xxxyyy
   default tablespace cwms_20data
   temporary tablespace temp
   profile default
   password expire
   account unlock;

grant cwms_user to &eroc.xxxyyy;
alter user &eroc.xxxyyy default role all;
alter user &eroc.xxxyyy quota unlimited on cwms_20data;
alter user &eroc.xxxyyy grant connect through &eroc.cwmspd with role cwms_user;


begin
   execute immediate 'drop user '||'&eroc'||'cwmspd';
exception
   when others then null;
end;
/
begin
   execute immediate 'create user '||'&eroc'||'cwmspd
      identified by '||'&eroc'||'cwmspd
      default tablespace cwms_20data
      temporary tablespace temp
      profile default
      password expire
      account unlock';
   execute immediate 'grant cwms_user to '||'&eroc'||'cwmspd';
   execute immediate 'alter user '||'&eroc'||'cwmspd default role all';
   execute immediate 'alter user '||'&eroc'||'cwmspd quota unlimited on cwms_20data';
   execute immediate 'alter user '||'&eroc'||'cwmspd
      grant connect through cwms_20
      with role cwms_user';
end;
/


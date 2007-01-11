begin
   execute immediate 'drop user '||'&eroc'||'cwmspd';
exception
   when others then null;
end;
/
begin
   execute immediate 'drop user '||'&eroc'||'xxxyyy';
exception
   when others then null;
end;
/
begin
   execute immediate 'create user '||'&eroc'||'cwmspd
      identified by values ''4DE998837F27F59E''
      default tablespace cwms_20data
      temporary tablespace temp
      profile default
      account unlock';
   execute immediate 'grant cwms_user to '||'&eroc'||'cwmspd';
   execute immediate 'alter user '||'&eroc'||'cwmspd default role all';
   execute immediate 'alter user '||'&eroc'||'cwmspd quota unlimited on cwms_20data';
   execute immediate 'alter user '||'&eroc'||'cwmspd
      grant connect through cwms_20
      with role cwms_user';

   execute immediate 'create user '||'&eroc'||'xxxyyy
      identified by '||'&eroc'||'xxxyyy
      default tablespace cwms_20data
      temporary tablespace temp
      profile default
      password expire
      account unlock';
   execute immediate 'grant cwms_user to '||'&eroc'||'xxxyyy';
   execute immediate 'alter user '||'&eroc'||'xxxyyy default role all';
   execute immediate 'alter user '||'&eroc'||'xxxyyy quota unlimited on cwms_20data';
   execute immediate 'alter user '||'&eroc'||'xxxyyy
      grant connect through '||'&eroc'||'cwmspd
      with role cwms_user';
end;
/


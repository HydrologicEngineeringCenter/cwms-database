create table at_api_keys(
    userid varchar2(32) not null references at_sec_cwms_users(USERID),
    key_name varchar2(64) not null,
    apikey varchar2(256) not null unique,    
    created date default current_timestamp not null,
    expires date default current_timestamp+1,
    primary key(userid,key_name)
);

comment on column at_api_keys.apikey  is 
        'While randomly generated, these still have to be unique. Applications generating them should check and provide a different value';

create or replace trigger cwms_20.st_api_key_readonly
    before update on cwms_20.at_api_keys
    for each row
begin
    if(    :new.userid <> :old.userid
        OR :new.key_name <> :old.key_name
        OR :new.apikey <> :old.apikey
        OR :new.created <> :old.created
    ) then
        raise_application_error(-20001,'API Key table is unmodifiabled except to update expiration or by deletion.');
    end if;
end;
/

show errors;

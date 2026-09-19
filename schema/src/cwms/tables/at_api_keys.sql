create table at_api_keys(
    key_id raw(16) not null,
    userid varchar2(128) not null references at_sec_cwms_users(USERID),
    key_name varchar2(64) not null,
    secret_hash varchar2(512) not null,
    created timestamp default current_timestamp not null,
    expires timestamp default current_timestamp+1,
    constraint at_api_keys_pk primary key (key_id),
    constraint at_api_keys_u1 unique (userid, key_name)
);

create or replace trigger cwms_20.st_api_key_readonly
    before update on cwms_20.at_api_keys
    for each row
begin
    if(    (:new.userid <> :old.userid
        OR :new.key_name <> :old.key_name
        OR :new.secret_hash <> :old.secret_hash
        OR :new.created <> :old.created
        OR :new.key_id <> :old.key_id)
        AND :new.expires < :old.expires
    ) then
        raise_application_error(-20001,'Only EXPIRES may be updated; all other columns are immutable.');
    end if;
end;
/

show errors;

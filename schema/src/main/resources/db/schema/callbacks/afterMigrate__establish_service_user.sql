-- manually migrated from buildCWMS_DB.sql
declare
    user_exists exception;
    pragma exception_init(user_exists, -1920);
begin
    begin
    execute immediate 'create user ' || cwms_sec.cac_service_user || ' PROFILE CWMS_PROF IDENTIFIED BY values ''FEDCBA9876543210'' ';

    -- Replace connect to role with create session/set container for RDS compatibility
    execute immediate 'grant create session to ' || cwms_sec.cac_service_user;

    execute immediate 'grant cwms_user to ' || cwms_sec.cac_service_user;
    exception
        when user_exists then null;
    end;



end;
/

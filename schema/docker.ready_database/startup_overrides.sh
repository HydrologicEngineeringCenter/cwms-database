#!/bin/bash

# reset the sys password
echo "Changing the system password"
resetPassword ${ORACLE_PASSWORD}



# reset the CWMS_20 password
cat <<EOF > /tmp/update_userpassword.sql
ALTER SESSION SET CONTAINER=FREEPDB1;
alter user cwms_20 identified by "${CWMS_PASSWORD}";
begin
    for l_user in (select username from dba_users where lower(username) like 's0%')
    loop
        execute immediate 'alter user ' || l_user.username || ' identified by "${CWMS_PASSWORD}"';
    end loop;
end;
/
exit
EOF

echo "Updating the CWMS_20 password"
sqlplus / as sysdba @/tmp/update_userpassword

# create users based on provided setting

cat <<EOF > /tmp/create_cwms_users.sql
DECLARE
    eroc varchar2(4) := '${OFFICE_EROC}';
    test_passwd  VARCHAR2 (50) := '${CWMS_PASSWORD}';
    group_list   "CWMS_20"."CHAR_32_ARRAY_TYPE";
    stmt varchar2(4000);
BEGIN
    -- hectest
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest', group_list, '${OFFICE_ID}');
    --
    -- hectest_ro
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS Users', 'Viewer Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_ro', group_list, '${OFFICE_ID}');
    --
    -- hectest_dba
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS DBA Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_db', group_list, '${OFFICE_ID}');
    --
    -- hectest_ua
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'TS ID Creator', 'Viewer Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_ua', group_list, '${OFFICE_ID}');
    --
    -- hectest_pu
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'CWMS PD Users','TS ID Creator', 'Viewer Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_pu', group_list, '${OFFICE_ID}');
    --
    -- hectest_dx
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('Data Exchange Mgr', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_dx', group_list, '${OFFICE_ID}');
    --
    -- hectest_da
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_da', group_list, '${OFFICE_ID}');
    --
    -- hectest_vt
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('VT Mgr', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_vt', group_list, '${OFFICE_ID}');
    --
    -- hectest_dv
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'VT Mgr', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_dv', group_list, '${OFFICE_ID}');
    --
    -- hectest_ccp_p
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Proc', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_ccp_p', group_list, '${OFFICE_ID}');
    --
    -- hectest_ccp_m
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Mgr', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_ccp_m', group_list, '${OFFICE_ID}');
    --
    -- hectest_ccp_r
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Reviewer', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_ccp_r', group_list, '${OFFICE_ID}');

    -- hectest_rdl_r
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'RDL Reviewer', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_rdl_r', group_list, '${OFFICE_ID}');
    -- hectest_rdl_m
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'RDL Mgr', 'TS ID Creator', 'CWMS Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'hectest_rdl_m', group_list, '${OFFICE_ID}');

    -- webtest
    group_list := "CWMS_20"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'CWMS PD Users','TS ID Creator', 'Viewer Users');
    "CWMS_20"."CWMS_SEC"."ADD_CWMS_USER" (eroc || 'webtest', group_list, '${OFFICE_ID}');
    execute immediate 'grant web_user to ' || eroc || 'webtest';
END;
/
exit  
EOF

cat <<EOF > /tmp/create_oracle_users.sql
DECLARE
    eroc varchar2(4) := '${OFFICE_EROC}';
    test_passwd  VARCHAR2 (50) := '${CWMS_PASSWORD}';
begin
    execute immediate 'create user ' || eroc || 'hectest identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_ro identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_db identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_ua identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_pu identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_dx identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_da identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_vt identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_dv identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_ccp_p identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_ccp_m identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_ccp_r identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_rdl_r identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'hectest_rdl_m identified by "${CWMS_PASSWORD}"';
    execute immediate 'create user ' || eroc || 'webtest identified by "${CWMS_PASSWORD}"';
END;
/
exit
EOF

echo "Creating users for Office ${OFFICE_ID} with EROC ${OFFICE_EROC}"
sqlplus sys/${ORACLE_PASSWORD}@//localhost:1521/FREEPDB1 as sysdba @/tmp/create_oracle_users.sql
echo "Setting CWMS Permissions for those users."
sqlplus CWMS_20/${CWMS_PASSWORD}@//localhost:1521/FREEPDB1 @/tmp/create_cwms_users.sql

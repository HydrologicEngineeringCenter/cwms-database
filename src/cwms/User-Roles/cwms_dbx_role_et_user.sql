/*
  cwms_dbx user and role are used for the crrel corpsmap initiative.
*/

whenever sqlerror continue

DROP role cwms_dbx_role;
DROP user cwms_dbx;

--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

--
-- Create the cwms_dbx_role...
--
create role CWMS_DBX_ROLE not identified;
grant select on CWMS_20.AT_BASE_LOCATION to CWMS_DBX_ROLE;
grant select on CWMS_20.AT_PHYSICAL_LOCATION to CWMS_DBX_ROLE;
grant select on CWMS_20.AV_TSV to CWMS_DBX_ROLE;
grant select on CWMS_20.CWMS_COUNTY to CWMS_DBX_ROLE;
grant select on CWMS_20.CWMS_OFFICE to CWMS_DBX_ROLE;
grant select on CWMS_20.CWMS_STATE to CWMS_DBX_ROLE;
grant select on CWMS_20.CWMS_TIME_ZONE to CWMS_DBX_ROLE;
grant select on CWMS_20.MV_CWMS_TS_ID to CWMS_DBX_ROLE;
grant create session to CWMS_DBX_ROLE;


--
-- CWMS_DBX  (User) 
--
CREATE USER CWMS_DBX
  IDENTIFIED BY values 'FEDCCA9876543210'
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  PROFILE CWMS_PROF
  ACCOUNT UNLOCK
/
  -- 1 Role for CWMS_DBX 
  GRANT CWMS_DBX_ROLE TO CWMS_DBX
/
  ALTER USER CWMS_DBX DEFAULT ROLE ALL
/

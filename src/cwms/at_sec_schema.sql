--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE AT_SEC_USERS
(
  DB_OFFICE_CODE   NUMBER,
  USERNAME         VARCHAR2(31 BYTE),
  USER_GROUP_CODE  NUMBER
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


CREATE UNIQUE INDEX AT_SEC_USERS_PK ON AT_SEC_USERS
(DB_OFFICE_CODE, USERNAME, USER_GROUP_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SEC_USERS ADD (
  CONSTRAINT AT_SEC_USERS_PK
 PRIMARY KEY
 (DB_OFFICE_CODE, USERNAME, USER_GROUP_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_SEC_USERS ADD (
  CONSTRAINT AT_SEC_USERS_R01 
 FOREIGN KEY (DB_OFFICE_CODE, USER_GROUP_CODE) 
 REFERENCES AT_SEC_USER_GROUPS (DB_OFFICE_CODE,USER_GROUP_CODE) DISABLE)
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE AT_SEC_USER_GROUPS
(
  DB_OFFICE_CODE   NUMBER,
  USER_GROUP_CODE  NUMBER,
  USER_GROUP_ID    VARCHAR2(32 BYTE),
  USER_GROUP_DESC  VARCHAR2(256 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


CREATE UNIQUE INDEX AT_SEC_USER_GROUPS_PK ON AT_SEC_USER_GROUPS
(DB_OFFICE_CODE, USER_GROUP_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SEC_USER_GROUPS ADD (
  CONSTRAINT AT_SEC_USER_GROUPS_PK
 PRIMARY KEY
 (DB_OFFICE_CODE, USER_GROUP_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
CREATE TABLE AT_SEC_TS_GROUP_MASKS
(
  DB_OFFICE_CODE  NUMBER,
  TS_GROUP_CODE   NUMBER,
  TS_GROUP_MASK   VARCHAR2(183 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


CREATE UNIQUE INDEX AT_SEC_TS_GROUP_MASKS_PK ON AT_SEC_TS_GROUP_MASKS
(DB_OFFICE_CODE, TS_GROUP_CODE, TS_GROUP_MASK)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SEC_TS_GROUP_MASKS ADD (
  CONSTRAINT AT_SEC_TS_GROUP_MASKS_PK
 PRIMARY KEY
 (DB_OFFICE_CODE, TS_GROUP_CODE, TS_GROUP_MASK)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_SEC_TS_GROUP_MASKS ADD (
  CONSTRAINT AT_SEC_TS_GROUP_MASKS_R01 
 FOREIGN KEY (TS_GROUP_CODE, DB_OFFICE_CODE) 
 REFERENCES AT_SEC_TS_GROUPS (TS_GROUP_CODE,DB_OFFICE_CODE))
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE AT_SEC_TS_GROUPS
(
  DB_OFFICE_CODE  NUMBER,
  TS_GROUP_CODE   NUMBER,
  TS_GROUP_ID     VARCHAR2(32 BYTE),
  TS_GROUP_DESC   VARCHAR2(256 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


CREATE UNIQUE INDEX AT_SEC_TS_GROUPS_PK ON AT_SEC_TS_GROUPS
(TS_GROUP_CODE, DB_OFFICE_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SEC_TS_GROUPS ADD (
  CONSTRAINT AT_SEC_TS_GROUPS_PK
 PRIMARY KEY
 (TS_GROUP_CODE, DB_OFFICE_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE AT_SEC_ALLOW
(
  DB_OFFICE_CODE   NUMBER,
  TS_GROUP_CODE    NUMBER,
  USER_GROUP_CODE  NUMBER,
  PRIVILEGE_CODE   NUMBER
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


CREATE UNIQUE INDEX AT_SEC_ALLOW_PK ON AT_SEC_ALLOW
(DB_OFFICE_CODE, TS_GROUP_CODE, USER_GROUP_CODE, PRIVILEGE_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SEC_ALLOW ADD (
  CONSTRAINT AT_SEC_ALLOW_PK
 PRIMARY KEY
 (DB_OFFICE_CODE, TS_GROUP_CODE, USER_GROUP_CODE, PRIVILEGE_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_SEC_ALLOW ADD (
  CONSTRAINT AT_SEC_ALLOW_R01 
 FOREIGN KEY (TS_GROUP_CODE, DB_OFFICE_CODE) 
 REFERENCES AT_SEC_TS_GROUPS (TS_GROUP_CODE,DB_OFFICE_CODE))
/

ALTER TABLE AT_SEC_ALLOW ADD (
  CONSTRAINT AT_SEC_ALLOW_R02 
 FOREIGN KEY (DB_OFFICE_CODE, USER_GROUP_CODE) 
 REFERENCES AT_SEC_USER_GROUPS (DB_OFFICE_CODE,USER_GROUP_CODE))
/

ALTER TABLE AT_SEC_ALLOW ADD (
  CONSTRAINT AT_SEC_ALLOW_R03 
 FOREIGN KEY (PRIVILEGE_CODE) 
 REFERENCES CWMS_PRIVILEGES (PRIVILEGE_CODE))
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON at_sec_users WITH SEQUENCE, ROWID
(db_office_code, username, user_group_code)
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_sec_users
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
   SELECT   asu.db_office_code, asu.username,
            SUM (asu.user_group_code) net_user_group_code, COUNT(asu.user_group_code) count_user_group_code
       FROM at_sec_users asu
   GROUP BY asu.db_office_code, asu.username
/
--------------------------------------------------------------------------------
CREATE UNIQUE INDEX mv_sec_users_u01 ON mv_sec_users
(db_office_code, username)
LOGGING
TABLESPACE cwms_20data
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON at_sec_ts_group_masks WITH SEQUENCE, ROWID
(db_office_code, ts_group_code, ts_group_mask)
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON mv_cwms_ts_id
WITH ROWID (db_office_code, db_office_id, ts_code, cwms_ts_id)
INCLUDING NEW VALUES;
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_sec_ts_spec
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
SELECT   mcti.db_office_code, mcti.db_office_id, mcti.ts_code,
         mcti.cwms_ts_id, SUM (astgm.ts_group_code) net_ts_group_code,
         COUNT (astgm.ts_group_code) count_ts_group_code
    FROM mv_cwms_ts_id mcti, at_sec_ts_group_masks astgm
   WHERE astgm.db_office_code = mcti.db_office_code
     AND UPPER (mcti.cwms_ts_id) LIKE UPPER (astgm.ts_group_mask)
GROUP BY mcti.db_office_code, mcti.db_office_id, mcti.ts_code, mcti.cwms_ts_id
/
--------------------------------------------------------------------------------
CREATE UNIQUE INDEX mv_sec_ts_spec_u01 ON mv_sec_ts_spec
(db_office_code, ts_code)
LOGGING
TABLESPACE cwms_20data
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON at_sec_allow WITH SEQUENCE, ROWID
(  db_office_code,
  ts_group_code,
  user_group_code,
  privilege_code )
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_sec_allow
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS

   SELECT   asa.db_office_code, asa.ts_group_code, asa.user_group_code,
            SUM (asa.privilege_code) net_privilege_code, COUNT (asa.privilege_code) count_privilege_code
       FROM at_sec_allow asa
   GROUP BY db_office_code, ts_group_code, user_group_code
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_sec_ts_privileges (username,
                                             db_office_code,
                                             ts_code,
                                             cwms_ts_id,
                                             net_privilege_code
                                            )
AS
   SELECT av_su.username, av_sts.db_office_code, av_sts.ts_code,
          av_sts.cwms_ts_id, av_sa.net_privilege_code
     FROM mv_sec_allow av_sa, mv_sec_ts_spec av_sts, mv_sec_users av_su
    WHERE av_sts.db_office_code = av_sa.db_office_code
      AND BITAND (av_sts.net_ts_group_code, av_sa.ts_group_code) =
                                                           av_sa.ts_group_code
      AND av_su.db_office_code = av_sa.db_office_code
      AND BITAND (av_su.net_user_group_code, av_sa.user_group_code) =
                                                         av_sa.user_group_code
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

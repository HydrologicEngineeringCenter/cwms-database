/* Formatted on 2007/05/04 19:46 (Formatter Plus v4.8.8) */
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE CWMS_SEC_PRIVILEGES
(
  PRIVILEGE_BIT  NUMBER,
  PRIVILEGE_ID   VARCHAR2(16 BYTE)
)
TABLESPACE CWMS_20AT_DATA
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


CREATE UNIQUE INDEX CWMS_SEC_PRIVILEGES_PK ON CWMS_SEC_PRIVILEGES
(PRIVILEGE_BIT)
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


ALTER TABLE CWMS_SEC_PRIVILEGES ADD (
  CONSTRAINT CWMS_SEC_PRIVILEGES_PK
 PRIMARY KEY
 (PRIVILEGE_BIT)
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
SET DEFINE OFF;
Insert into CWMS_SEC_PRIVILEGES
   (PRIVILEGE_BIT, PRIVILEGE_ID)
 Values
   (2, 'Write');
Insert into CWMS_SEC_PRIVILEGES
   (PRIVILEGE_BIT, PRIVILEGE_ID)
 Values
   (4, 'Read');
COMMIT;
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE AT_SEC_USERS
(
  DB_OFFICE_CODE   NUMBER,
  USER_ID          VARCHAR2(31 BYTE),
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
(DB_OFFICE_CODE, USER_ID, USER_GROUP_CODE)
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
 (DB_OFFICE_CODE, USER_ID, USER_GROUP_CODE)
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
  CONSTRAINT AT_SEC_USERS_R02 
 FOREIGN KEY (USER_ID) 
 REFERENCES AT_SEC_USER_OFFICE (USER_ID))
/

ALTER TABLE AT_SEC_USERS ADD (
  CONSTRAINT AT_SEC_USERS_R01 
 FOREIGN KEY (DB_OFFICE_CODE, USER_GROUP_CODE) 
 REFERENCES AT_SEC_USER_GROUPS (DB_OFFICE_CODE,USER_GROUP_CODE))
/
--
--=============================================================================
--=============================================================================
-- 
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
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE AT_SEC_USERS
(
  DB_OFFICE_CODE   NUMBER,
  USER_ID          VARCHAR2(31 BYTE),
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
(DB_OFFICE_CODE, USER_ID, USER_GROUP_CODE)
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
 (DB_OFFICE_CODE, USER_ID, USER_GROUP_CODE)
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
  CONSTRAINT AT_SEC_USERS_R02 
 FOREIGN KEY (USER_ID) 
 REFERENCES AT_SEC_USER_OFFICE (USER_ID))
/

ALTER TABLE AT_SEC_USERS ADD (
  CONSTRAINT AT_SEC_USERS_R01 
 FOREIGN KEY (DB_OFFICE_CODE, USER_GROUP_CODE) 
 REFERENCES AT_SEC_USER_GROUPS (DB_OFFICE_CODE,USER_GROUP_CODE))
/
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE AT_SEC_TS_GROUPS
(
  DB_OFFICE_CODE  NUMBER                        NOT NULL,
  TS_GROUP_CODE   NUMBER                        NOT NULL,
  TS_GROUP_ID     VARCHAR2(32 BYTE)             NOT NULL,
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
(DB_OFFICE_CODE, TS_GROUP_CODE)
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


CREATE UNIQUE INDEX AT_SEC_TS_GROUPS_U01 ON AT_SEC_TS_GROUPS
(DB_OFFICE_CODE, UPPER("TS_GROUP_ID"))
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
 (DB_OFFICE_CODE, TS_GROUP_CODE)
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
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE AT_SEC_TS_GROUP_MASKS
(
  DB_OFFICE_CODE  NUMBER,
  TS_GROUP_CODE   NUMBER,
  TS_GROUP_MASK   VARCHAR2(256 BYTE)
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


CREATE OR REPLACE TRIGGER at_sec_ts_group_masks_trig
BEFORE INSERT OR UPDATE
OF TS_GROUP_MASK
ON AT_SEC_TS_GROUP_MASKS 
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE

BEGIN
   :new.ts_group_mask := upper(:new.ts_group_mask);
END ;
/
SHOW ERRORS;



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
 FOREIGN KEY (DB_OFFICE_CODE, TS_GROUP_CODE) 
 REFERENCES AT_SEC_TS_GROUPS (DB_OFFICE_CODE,TS_GROUP_CODE))
/
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE AT_SEC_ALLOW
(
  DB_OFFICE_CODE   NUMBER,
  TS_GROUP_CODE    NUMBER,
  USER_GROUP_CODE  NUMBER,
  PRIVILEGE_BIT    NUMBER
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
(DB_OFFICE_CODE, TS_GROUP_CODE, USER_GROUP_CODE, PRIVILEGE_BIT)
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
 (DB_OFFICE_CODE, TS_GROUP_CODE, USER_GROUP_CODE, PRIVILEGE_BIT)
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
 FOREIGN KEY (DB_OFFICE_CODE, TS_GROUP_CODE) 
 REFERENCES AT_SEC_TS_GROUPS (DB_OFFICE_CODE,TS_GROUP_CODE))
/

ALTER TABLE AT_SEC_ALLOW ADD (
  CONSTRAINT AT_SEC_ALLOW_R02 
 FOREIGN KEY (DB_OFFICE_CODE, USER_GROUP_CODE) 
 REFERENCES AT_SEC_USER_GROUPS (DB_OFFICE_CODE,USER_GROUP_CODE))
/

ALTER TABLE AT_SEC_ALLOW ADD (
  CONSTRAINT AT_SEC_ALLOW_R03 
 FOREIGN KEY (PRIVILEGE_BIT) 
 REFERENCES CWMS_SEC_PRIVILEGES (PRIVILEGE_BIT))
/
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE cwms_sec_user_groups
(
  user_group_code  NUMBER,
  user_group_id    VARCHAR2(32 BYTE)            NOT NULL,
  user_group_desc  VARCHAR2(256 BYTE)           NOT NULL
)
TABLESPACE cwms_20data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
CREATE UNIQUE INDEX cwms_sec_user_groups_pk ON cwms_sec_user_groups
(user_group_code)
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
ALTER TABLE cwms_sec_user_groups ADD (
  CONSTRAINT cwms_sec_user_groups_pk
 PRIMARY KEY
 (user_group_code)
    USING INDEX
    TABLESPACE cwms_20data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
SET DEFINE OFF;
INSERT INTO cwms_sec_user_groups
            (user_group_code, user_group_id,
             user_group_desc
            )
     VALUES (0, 'CWMS DBA Users',
             'Super CWMS Users - able to assign privileges and read/write to all objects in the database.'
            );
INSERT INTO cwms_sec_user_groups
            (user_group_code, user_group_id,
             user_group_desc
            )
     VALUES (1, 'CWMS System User',
             'Users that can write to all objects in the database.'
            );
INSERT INTO cwms_sec_user_groups
            (user_group_code, user_group_id,
             user_group_desc
            )
     VALUES (2, 'Data Exchange Mgr',
             ' Users that will be editing/adding data exchange sets.'
            );
INSERT INTO cwms_sec_user_groups
            (user_group_code, user_group_id,
             user_group_desc
            )
     VALUES (3, 'Data Acquisition Mgr',
             ' Users that will be editing/changing/managing data streams and time series identifiers.'
            );
INSERT INTO cwms_sec_user_groups
            (user_group_code, user_group_id,
             user_group_desc
            )
     VALUES (4, 'TS ID Creator',
             'Users that can add a time series identifier. Note that this privilege does not automatically give the user to read and/or write to the newly created time series id.'
            );
INSERT INTO cwms_sec_user_groups
            (user_group_code, user_group_id,
             user_group_desc
            )
     VALUES (5, 'VT Mgr',
             ' Users that will manage the validation/alarms/transformation of data.'
            );
INSERT INTO cwms_sec_user_groups
            (user_group_code, user_group_id, user_group_desc
            )
     VALUES (6, 'All Users', ' General CWMS Users.'
            );
COMMIT ;
--
--=============================================================================
--=============================================================================
-- 
-- Load at_sec_user_groups table.

DECLARE
BEGIN
   INSERT INTO at_sec_user_groups
      SELECT a.office_code, b.user_group_code, b.user_group_id,
             b.user_group_desc
        FROM cwms_office a, cwms_sec_user_groups b;
END;

--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE cwms_sec_ts_groups
(
  ts_group_code  NUMBER                         NOT NULL,
  ts_group_id    VARCHAR2(32 BYTE)              NOT NULL,
  ts_group_desc  VARCHAR2(256 BYTE)             NOT NULL,
  ts_group_mask  VARCHAR2(183 BYTE)             NOT NULL
)
TABLESPACE cwms_20data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
CREATE UNIQUE INDEX cwms_sec_ts_groups_pk ON cwms_sec_ts_groups
(ts_group_code)
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
ALTER TABLE cwms_sec_ts_groups ADD (
  CONSTRAINT cwms_sec_ts_groups_pk
 PRIMARY KEY
 (ts_group_code)
    USING INDEX
    TABLESPACE cwms_20data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
SET DEFINE OFF;
INSERT INTO cwms_sec_ts_groups
            (ts_group_code, ts_group_id, ts_group_desc, ts_group_mask
            )
     VALUES (0, 'All TS Ids', 'All Time Series Ids', '%'
            );
INSERT INTO cwms_sec_ts_groups
            (ts_group_code, ts_group_id, ts_group_desc, ts_group_mask
            )
     VALUES (1, 'All Raw TS Ids', 'All Raw Time Series Ids', '%-raw'
            );
INSERT INTO cwms_sec_ts_groups
            (ts_group_code, ts_group_id, ts_group_desc, ts_group_mask
            )
     VALUES (2, 'All Rev TS Ids', 'All Revised Time Series Ids', '%-rev'
            );
COMMIT ;
--
--=============================================================================
--=============================================================================
-- 
-- Load at_sec_ts_group tables.

DECLARE
BEGIN
   INSERT INTO at_sec_ts_groups
      SELECT a.office_code, b.ts_group_code, b.ts_group_id, b.ts_group_desc
        FROM cwms_office a, cwms_sec_ts_groups b;

   INSERT INTO at_sec_ts_group_masks
      SELECT a.db_office_code, a.ts_group_code, b.ts_group_mask
        FROM at_sec_ts_groups a, cwms_sec_ts_groups b
       WHERE a.ts_group_code = b.ts_group_code;
END;

--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON mv_cwms_ts_id
WITH SEQUENCE, ROWID (db_office_code, ts_code, cwms_ts_id)
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON at_sec_ts_group_masks WITH SEQUENCE, ROWID
(db_office_code, ts_group_code, ts_group_mask)
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW mv_sec_ts_group_masks
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
SELECT   mcti.db_office_code, mcti.ts_code,
         SUM (POWER (2, astg.ts_group_code)) net_ts_group_bit,
         COUNT (astg.ts_group_code) count_ts_group_code, COUNT (*) cnt
    FROM mv_cwms_ts_id mcti, at_sec_ts_group_masks astg
   WHERE astg.db_office_code = mcti.db_office_code
     AND UPPER (mcti.cwms_ts_id) LIKE UPPER (astg.ts_group_mask)
GROUP BY mcti.db_office_code, mcti.ts_code
/
--
--=============================================================================
--=============================================================================
-- 
CREATE UNIQUE INDEX mv_sec_ts_group_masks_u01 ON mv_sec_ts_group_masks
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
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON at_sec_users WITH SEQUENCE, ROWID
(db_office_code, user_id, user_group_code)
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW mv_sec_users
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
   SELECT   asu.db_office_code, asu.user_id,
            SUM (POWER(2,asu.user_group_code)) net_user_group_bit,
            COUNT(asu.user_group_code) count_user_group_code,
            COUNT(*) cnt
       FROM at_sec_users asu
   GROUP BY asu.db_office_code, asu.user_id
/
--
--=============================================================================
--=============================================================================
-- 
CREATE UNIQUE INDEX mv_sec_users_u01 ON mv_sec_users
(db_office_code, user_id)
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
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON at_sec_allow WITH SEQUENCE, ROWID
(  db_office_code,
  ts_group_code,
  user_group_code,
  privilege_bit )
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW mv_sec_allow
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
   SELECT   asa.db_office_code, asa.ts_group_code, asa.user_group_code,
            SUM (asa.privilege_bit) net_privilege_bit, 
            COUNT (asa.privilege_bit) count_privilege_bit, COUNT(*) cnt
       FROM at_sec_allow asa
   GROUP BY db_office_code, ts_group_code, user_group_code
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON mv_sec_allow WITH SEQUENCE, ROWID
(  db_office_code,
  ts_group_code,
  user_group_code,
  net_privilege_bit )
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON mv_sec_users WITH SEQUENCE, ROWID
(db_office_code, user_id, net_user_group_bit)
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON mv_sec_ts_group_masks WITH SEQUENCE, ROWID
(db_office_code,
 ts_code,
 net_ts_group_bit,
 count_ts_group_code,
 cnt)
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW mv_sec_ts_priv
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
SELECT mv_su.user_id, mv_sts.db_office_code, mv_sts.ts_code,
       mv_sa.net_privilege_bit, mv_sa.ROWID mv_sa_rowid,
       mv_sts.ROWID mv_sts_rowid, mv_su.ROWID mv_su_rowid
  FROM mv_sec_allow mv_sa, mv_sec_ts_group_masks mv_sts, mv_sec_users mv_su
 WHERE mv_sts.db_office_code = mv_sa.db_office_code
   AND BITAND (mv_sts.net_ts_group_bit, POWER (2, mv_sa.ts_group_code)) =
                                                POWER (2, mv_sa.ts_group_code)
   AND mv_su.db_office_code = mv_sa.db_office_code
   AND BITAND (mv_su.net_user_group_bit, POWER (2, mv_sa.user_group_code)) =
                                              POWER (2, mv_sa.user_group_code)
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW LOG ON mv_sec_ts_priv WITH ROWID
(user_id,
 db_office_code,
 ts_code,
 net_privilege_bit)
INCLUDING NEW VALUES
/
--
--=============================================================================
--=============================================================================
-- 
CREATE MATERIALIZED VIEW mv_sec_ts_privileges
REFRESH FAST ON COMMIT
WITH PRIMARY KEY
AS
SELECT   user_id, db_office_code, ts_code,
         MAX (net_privilege_bit) net_privilege_bit,
         COUNT (net_privilege_bit) count_privilege_bit, COUNT (*) cnt
    FROM mv_sec_ts_priv
GROUP BY user_id, db_office_code, ts_code
/
--
--=============================================================================
--=============================================================================
-- 
CREATE INDEX mv_sec_ts_privileges_i01 ON mv_sec_ts_privileges
(user_id)
LOGGING
TABLESPACE cwms_20at_data
NOPARALLEL
/

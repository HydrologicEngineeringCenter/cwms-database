/* Formatted on 2007/05/05 12:16 (Formatter Plus v4.8.8) */
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE cwms_sec_privileges
(
  privilege_bit  NUMBER,
  privilege_id   VARCHAR2(16 BYTE)
)
TABLESPACE cwms_20at_data
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

CREATE UNIQUE INDEX cwms_sec_privileges_pk ON cwms_sec_privileges
(privilege_bit)
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

ALTER TABLE cwms_sec_privileges ADD (
  CONSTRAINT cwms_sec_privileges_pk
 PRIMARY KEY
 (privilege_bit)
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
INSERT INTO cwms_sec_privileges
            (privilege_bit, privilege_id
            )
     VALUES (2, 'Write'
            );
INSERT INTO cwms_sec_privileges
            (privilege_bit, privilege_id
            )
     VALUES (4, 'Read'
            );
COMMIT ;
--
--=============================================================================
--=============================================================================
-- 

CREATE TABLE AT_SEC_USER_OFFICE
(
  USER_ID              VARCHAR2(31 BYTE),
  USER_DB_OFFICE_CODE  NUMBER                   NOT NULL
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


CREATE UNIQUE INDEX AT_SEC_USER_OFFICE_PK ON AT_SEC_USER_OFFICE
(USER_ID)
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


ALTER TABLE AT_SEC_USER_OFFICE ADD (
  CONSTRAINT AT_SEC_USER_OFFICE_PK
 PRIMARY KEY
 (USER_ID)
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


ALTER TABLE AT_SEC_USER_OFFICE ADD (
  CONSTRAINT AT_SEC_USER_OFFICE_R01 
 FOREIGN KEY (USER_DB_OFFICE_CODE) 
 REFERENCES CWMS_OFFICE (OFFICE_CODE))
/
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE at_sec_user_groups
(
  db_office_code   NUMBER,
  user_group_code  NUMBER,
  user_group_id    VARCHAR2(32 BYTE),
  user_group_desc  VARCHAR2(256 BYTE)
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

CREATE UNIQUE INDEX at_sec_user_groups_pk ON at_sec_user_groups
(db_office_code, user_group_code)
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

ALTER TABLE at_sec_user_groups ADD (
  CONSTRAINT at_sec_user_groups_pk
 PRIMARY KEY
 (db_office_code, user_group_code)
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
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE at_sec_users
(
  db_office_code   NUMBER,
  user_group_code  NUMBER,
    user_id          VARCHAR2(31 BYTE)

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

CREATE UNIQUE INDEX at_sec_users_pk ON at_sec_users
(db_office_code, user_group_code, user_id)
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

ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_pk
 PRIMARY KEY
 (db_office_code, user_group_code, user_id)
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

ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_r02
 FOREIGN KEY (user_id)
 REFERENCES at_sec_user_office (user_id))
/
ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_r01
 FOREIGN KEY (db_office_code, user_group_code)
 REFERENCES at_sec_user_groups (db_office_code,user_group_code))
/
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE at_sec_ts_groups
(
  db_office_code  NUMBER                        NOT NULL,
  ts_group_code   NUMBER                        NOT NULL,
  ts_group_id     VARCHAR2(32 BYTE)             NOT NULL,
  ts_group_desc   VARCHAR2(256 BYTE)
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

CREATE UNIQUE INDEX at_sec_ts_groups_pk ON at_sec_ts_groups
(db_office_code, ts_group_code)
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

CREATE UNIQUE INDEX at_sec_ts_groups_u01 ON at_sec_ts_groups
(db_office_code, UPPER("TS_GROUP_ID"))
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

ALTER TABLE at_sec_ts_groups ADD (
  CONSTRAINT at_sec_ts_groups_pk
 PRIMARY KEY
 (db_office_code, ts_group_code)
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
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE at_sec_ts_group_masks
(
  db_office_code  NUMBER,
  ts_group_code   NUMBER,
  ts_group_mask   VARCHAR2(256 BYTE)
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

CREATE UNIQUE INDEX at_sec_ts_group_masks_pk ON at_sec_ts_group_masks
(db_office_code, ts_group_code, ts_group_mask)
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

CREATE OR REPLACE TRIGGER at_sec_ts_group_masks_trig
   BEFORE INSERT OR UPDATE OF ts_group_mask
   ON at_sec_ts_group_masks
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
BEGIN
   :NEW.ts_group_mask := UPPER (:NEW.ts_group_mask);
END;
/
SHOW ERRORS;



ALTER TABLE at_sec_ts_group_masks ADD (
  CONSTRAINT at_sec_ts_group_masks_pk
 PRIMARY KEY
 (db_office_code, ts_group_code, ts_group_mask)
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

ALTER TABLE at_sec_ts_group_masks ADD (
  CONSTRAINT at_sec_ts_group_masks_r01
 FOREIGN KEY (db_office_code, ts_group_code)
 REFERENCES at_sec_ts_groups (db_office_code,ts_group_code))
/
--
--=============================================================================
--=============================================================================
-- 
CREATE TABLE at_sec_allow
(
  db_office_code   NUMBER,
  ts_group_code    NUMBER,
  user_group_code  NUMBER,
  privilege_bit    NUMBER
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

CREATE UNIQUE INDEX at_sec_allow_pk ON at_sec_allow
(db_office_code, ts_group_code, user_group_code, privilege_bit)
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

ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_pk
 PRIMARY KEY
 (db_office_code, ts_group_code, user_group_code, privilege_bit)
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

ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r01
 FOREIGN KEY (db_office_code, ts_group_code)
 REFERENCES at_sec_ts_groups (db_office_code,ts_group_code))
/
ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r02
 FOREIGN KEY (db_office_code, user_group_code)
 REFERENCES at_sec_user_groups (db_office_code,user_group_code))
/
ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r03
 FOREIGN KEY (privilege_bit)
 REFERENCES cwms_sec_privileges (privilege_bit))
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
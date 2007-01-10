/* Formatted on 2007/01/08 12:46 (Formatter Plus v4.8.8) */
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE cwms_privileges
(
  privilege_code  NUMBER,
  privilege_id    VARCHAR2(16 BYTE)
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
CREATE UNIQUE INDEX cwms_privileges_pk ON cwms_privileges
(privilege_code)
LOGGING
TABLESPACE cwms_20at_data
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
ALTER TABLE cwms_privileges ADD (
  CONSTRAINT cwms_privileges_pk
 PRIMARY KEY
 (privilege_code)
    USING INDEX
    TABLESPACE cwms_20at_data
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
INSERT INTO cwms_privileges
            (privilege_code, privilege_id
            )
     VALUES (2, 'Write'
            );
INSERT INTO cwms_privileges
            (privilege_code, privilege_id
            )
     VALUES (4, 'Read'
            );
COMMIT ;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE at_sec_user_office
(
  user_id            VARCHAR2(32 BYTE)          NOT NULL,
  primary_office_id  VARCHAR2(16 BYTE)          NOT NULL
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
COMMENT ON TABLE at_sec_user_office IS 'Primary office IDs for CWMS Users'
/
COMMENT ON COLUMN at_sec_user_office.user_id IS 'CWMS User ID'
/
COMMENT ON COLUMN at_sec_user_office.primary_office_id IS 'Primary Office ID for CWMS User'
/
CREATE UNIQUE INDEX at_sec_user_office_pk ON at_sec_user_office
(user_id, primary_office_id)
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
CREATE OR REPLACE TRIGGER at_sec_user_office_constraint
   BEFORE INSERT OR UPDATE OF user_id, primary_office_id
   ON at_sec_user_office
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
BEGIN
   :NEW.user_id := UPPER (:NEW.user_id);
   :NEW.primary_office_id := UPPER (:NEW.primary_office_id);
END at_sec_user_office_constraint;
/
SHOW ERRORS;



ALTER TABLE at_sec_user_office ADD (
  CONSTRAINT at_sec_user_office_fk1
 FOREIGN KEY (primary_office_id)
 REFERENCES cwms_office (office_id))
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE at_sec_users
(
  db_office_code   NUMBER,
  user_id         VARCHAR2(31 BYTE),
  user_group_code  NUMBER
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
(db_office_code, user_id, user_group_code)
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
 (db_office_code, user_id, user_group_code)
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
  CONSTRAINT at_sec_users_r01
 FOREIGN KEY (db_office_code, user_group_code)
 REFERENCES at_sec_user_groups (db_office_code,user_group_code) DISABLE)
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE at_sec_ts_groups
(
  db_office_code  NUMBER,
  ts_group_code   NUMBER,
  ts_group_id     VARCHAR2(32 BYTE),
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
(ts_group_code, db_office_code)
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
 (ts_group_code, db_office_code)
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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE at_sec_ts_group_masks
(
  db_office_code  NUMBER,
  ts_group_code   NUMBER,
  ts_group_mask   VARCHAR2(183 BYTE)
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
 FOREIGN KEY (ts_group_code, db_office_code)
 REFERENCES at_sec_ts_groups (ts_group_code,db_office_code))
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE at_sec_allow
(
  db_office_code   NUMBER,
  ts_group_code    NUMBER,
  user_group_code  NUMBER,
  privilege_code   NUMBER
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
(db_office_code, ts_group_code, user_group_code, privilege_code)
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
 (db_office_code, ts_group_code, user_group_code, privilege_code)
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
 FOREIGN KEY (ts_group_code, db_office_code)
 REFERENCES at_sec_ts_groups (ts_group_code,db_office_code))
/
ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r02
 FOREIGN KEY (db_office_code, user_group_code)
 REFERENCES at_sec_user_groups (db_office_code,user_group_code))
/
ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r03
 FOREIGN KEY (privilege_code)
 REFERENCES cwms_privileges (privilege_code))
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON at_sec_users WITH SEQUENCE, ROWID
(db_office_code, user_id, user_group_code)
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_sec_users
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
   SELECT   asu.db_office_code, asu.user_id,
            SUM (asu.user_group_code) net_user_group_code,
            COUNT(asu.user_group_code) count_user_group_code,
            COUNT(*) cnt
       FROM at_sec_users asu
   GROUP BY asu.db_office_code, asu.user_id
/
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON at_sec_ts_group_masks WITH SEQUENCE, ROWID
(db_office_code, ts_group_code, ts_group_mask)
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON mv_cwms_ts_id
WITH SEQUENCE, ROWID (db_office_code, ts_code, cwms_ts_id)
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_sec_ts_group_masks
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
SELECT   mcti.db_office_code, mcti.ts_code, SUM (astgm.ts_group_code) net_ts_group_code,
         COUNT (astgm.ts_group_code) count_ts_group_code, COUNT(*) cnt
    FROM mv_cwms_ts_id mcti, at_sec_ts_group_masks astgm
   WHERE astgm.db_office_code = mcti.db_office_code
     AND UPPER (mcti.cwms_ts_id) LIKE UPPER (astgm.ts_group_mask)
GROUP BY mcti.db_office_code, mcti.ts_code
/
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON at_sec_allow WITH SEQUENCE, ROWID
(  db_office_code,
  ts_group_code,
  user_group_code,
  privilege_code )
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_sec_allow
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS

   SELECT   asa.db_office_code, asa.ts_group_code, asa.user_group_code,
            SUM (asa.privilege_code) net_privilege_code, COUNT (asa.privilege_code) count_privilege_code, COUNT(*) cnt
       FROM at_sec_allow asa
   GROUP BY db_office_code, ts_group_code, user_group_code
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_sec_ts_privileges (user_id,
                                             db_office_code,
                                             ts_code,
                                             net_privilege_code,
                                             read_privilege,
                                             write_privilege,
                                             count_privilege_code
                                            )
AS
   SELECT   mv_su.user_id, mv_sts.db_office_code, mv_sts.ts_code,
            MAX (mv_sa.net_privilege_code) net_privilege_code,
            CASE
               WHEN BITAND (MAX (mv_sa.net_privilege_code), 4) =
                                                             4
                  THEN 4
               ELSE NULL
            END read_privilege,
            CASE
               WHEN BITAND (MAX (mv_sa.net_privilege_code),
                            2) = 2
                  THEN 2
               ELSE NULL
            END write_privilege,
            COUNT (mv_sa.net_privilege_code) count_privilege_code
       FROM mv_sec_allow mv_sa, mv_sec_ts_group_masks mv_sts, mv_sec_users mv_su
      WHERE mv_sts.db_office_code = mv_sa.db_office_code
        AND BITAND (mv_sts.net_ts_group_code, mv_sa.ts_group_code) =
                                                           mv_sa.ts_group_code
        AND mv_su.db_office_code = mv_sa.db_office_code
        AND BITAND (mv_su.net_user_group_code, mv_sa.user_group_code) =
                                                         mv_sa.user_group_code
   GROUP BY mv_su.user_id,
            mv_sts.db_office_code,
            mv_sts.ts_code
/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON mv_sec_allow WITH SEQUENCE, ROWID
(  db_office_code,
  ts_group_code,
  user_group_code,
  net_privilege_code )
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON mv_sec_users WITH SEQUENCE, ROWID
(db_office_code, user_id, net_user_group_code)
INCLUDING NEW VALUES
/

--------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON mv_sec_ts_group_masks WITH SEQUENCE, ROWID
(db_office_code, 
 ts_code, 
 net_ts_group_code, 
 count_ts_group_code, 
 cnt)
INCLUDING NEW VALUES
/

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE MATERIALIZED VIEW mv_sec_ts_priv
PARALLEL
BUILD IMMEDIATE
REFRESH FAST ON COMMIT AS
SELECT      mv_su.user_id,
            mv_sts.db_office_code,
            mv_sts.ts_code,
            mv_sa.net_privilege_code,
            mv_sa.rowid mv_sa_rowid,
            mv_sts.rowid mv_sts_rowid,
            mv_su.rowid mv_su_rowid
       FROM mv_sec_allow mv_sa, mv_sec_ts_group_masks mv_sts, mv_sec_users mv_su
      WHERE mv_sts.db_office_code = mv_sa.db_office_code
        AND BITAND (mv_sts.net_ts_group_code, mv_sa.ts_group_code) =
                                                           mv_sa.ts_group_code
        AND mv_su.db_office_code = mv_sa.db_office_code
        AND BITAND (mv_su.net_user_group_code, mv_sa.user_group_code) =
                                                         mv_sa.user_group_code
/
--------------------------------------------------------------------------------

CREATE MATERIALIZED VIEW LOG ON mv_sec_ts_priv WITH ROWID
(user_id,
 db_office_code,
 ts_code,
 net_privilege_code)
INCLUDING NEW VALUES
/
--------------------------------------------------------------------------------

/* Formatted on 2007/01/09 07:58 (Formatter Plus v4.8.8) */
CREATE MATERIALIZED VIEW mv_sec_ts_privileges
REFRESH FAST ON COMMIT
WITH PRIMARY KEY
AS
SELECT   user_id, db_office_code, ts_code,
         MAX (net_privilege_code) net_privilege_code,
         COUNT (net_privilege_code) count_privilege_code, COUNT (*) cnt
    FROM mv_sec_ts_priv
GROUP BY user_id, db_office_code, ts_code
/
COMMENT ON MATERIALIZED VIEW MV_SEC_TS_PRIV1 IS 'snapshot table for snapshot CWMS_20.MV_SEC_TS_PRIVILEGES'
/

CREATE INDEX mv_sec_ts_privileges_i01 ON mv_sec_ts_privileges
(user_id)
LOGGING
TABLESPACE cwms_20at_data
NOPARALLEL
/     

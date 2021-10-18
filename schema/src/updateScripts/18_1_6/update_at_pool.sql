/* Formatted on 1/5/2021 3:12:31 PM (QP5 v5.362) */
set serveroutput on
DECLARE
    l_count   NUMBER;
BEGIN
    SELECT COUNT (*) INTO l_count FROM user_tab_columns where table_name='AT_POOL';

    DBMS_OUTPUT.PUT_LINE ('Number of columns in at pool ' || l_count);

    IF (l_count < 8)
    THEN
        EXECUTE IMMEDIATE 'create table   at_pool_backup               as (  select       *  from     at_pool)';

        EXECUTE IMMEDIATE 'drop  table at_pool';

        EXECUTE IMMEDIATE 'create table   at_pool (pool_code integer,
               pool_name_code integer not null,
               project_code integer not null,
               clob_code integer,
               attribute number,
               bottom_level varchar2 ( 256) not   null    ,
  top_level               varchar2        ( 256   )  not    null    ,
  description               varchar2        ( 128   ) ,
  constraint           at_pool_pk            primary        key    ( pool_code         ) ,
  constraint           at_pool_fk1            foreign        key    ( pool_name_code              )  references           at_pool_name             ( pool_name_code              ) ,
  constraint           at_pool_fk2            foreign        key    ( project_code            )  references           at_project           ( project_location_code                     ) ,
  constraint           at_pool_fk3            foreign        key    ( clob_code         )  references           at_clob        ( clob_code         )
 ) tablespace           cwms_20at_data              ';

        EXECUTE IMMEDIATE 'comment on table at_pool                       is   ''Holds pool definitions for projects''';

        EXECUTE IMMEDIATE 'comment on column at_pool.pool_code             is   ''Synthetic key''';

        EXECUTE IMMEDIATE 'comment on column at_pool.pool_name_code        is   ''Reference to pool name''';

        EXECUTE IMMEDIATE 'comment on column at_pool.project_code          is   ''Reference to project''';

        EXECUTE IMMEDIATE 'comment on column at_pool.clob_code             is   ''Reference to CLOB containing more (possibly structured) information''';

        EXECUTE IMMEDIATE 'comment on column at_pool.attribute             is   ''Numeric attribute, most likely used for sorting''';

        EXECUTE IMMEDIATE 'comment on column at_pool.bottom_level          is   ''Location level ID for bottom of pool (minus location portion)''';

        EXECUTE IMMEDIATE 'comment on column at_pool.top_level             is   ''Location level ID for top of pool (minus location portion)''';

        EXECUTE IMMEDIATE 'comment on column at_pool.description           is   ''Text description of pool''';

        EXECUTE IMMEDIATE 'create unique    index      at_pool_idx1             on   at_pool (project_code, pool_name_code)';

        EXECUTE IMMEDIATE 'create unique    index      at_pool_idx2             on   at_pool (pool_name_code, project_code)';

        EXECUTE IMMEDIATE 'create index          at_pool_idx3             on   at_pool (project_code, UPPER (bottom_level))';

        EXECUTE IMMEDIATE 'create index          at_pool_idx4             on   at_pool (UPPER (bottom_level), project_code)';

        EXECUTE IMMEDIATE 'create index          at_pool_idx5             on   at_pool (project_code, UPPER (top_level))';

        EXECUTE IMMEDIATE 'create index          at_pool_idx6             on   at_pool (UPPER (top_level), project_code)';

        EXECUTE IMMEDIATE 'create index          at_pool_idx7             on   at_pool (project_code, NVL (attribute, -1e125))';

        EXECUTE IMMEDIATE 'INSERT INTO at_pool (pool_code,
                             pool_name_code,
                             project_code,
                             bottom_level,
                             top_level)
            (SELECT pool_code,
                    pool_name_code,
                    project_code,
                    bottom_level,
                    top_level
               FROM at_pool_backup)';

        COMMIT;

        EXECUTE IMMEDIATE 'drop table at_pool_backup';
    END IF;
END;
/

PROMPT CREATING at_pool_t01

CREATE OR REPLACE TRIGGER at_pool_t01
    BEFORE INSERT OR UPDATE OF bottom_level, top_level
    ON at_pool
    FOR EACH ROW
DECLARE
    l_rec    at_location_level%ROWTYPE;
    l_text   VARCHAR2 (64);
BEGIN
    -----------------------------
    -- assert different levels --
    -----------------------------
    IF :new.bottom_level = :new.top_level
    THEN
        cwms_err.raise ('ERROR', 'Top and bottom levels cannot be the same');
    END IF;

    -----------------------------------------------
    -- validate bottom level is 'Elev.Inst.0...' --
    -----------------------------------------------
    IF INSTR (:new.bottom_level, 'Elev.Inst.0.') != 1
    THEN
        cwms_err.raise (
            'ERROR',
            'Bottom location level ID must start with ''Elev.Inst.0''');
    END IF;

    --------------------------------------------
    -- validate top level is 'Elev.Inst.0...' --
    --------------------------------------------
    IF INSTR (:new.top_level, 'Elev.Inst.0.') != 1
    THEN
        cwms_err.raise (
            'ERROR',
            'Top location level ID must start with ''Elev.Inst.0''');
    END IF;
END at_pool_t01;
/
PROMPT CREATING ST_POOL

CREATE OR REPLACE TRIGGER st_pool
    BEFORE DELETE OR INSERT OR UPDATE
    ON at_pool
    REFERENCING NEW AS new OLD AS old
DECLARE
    l_priv   VARCHAR2 (16);
BEGIN
    SELECT SYS_CONTEXT ('CWMS_ENV', 'CWMS_PRIVILEGE') INTO l_priv FROM DUAL;

    IF (    (l_priv IS NULL OR l_priv <> 'CAN_WRITE')
        AND USER NOT IN ('SYS', 'CWMS_20'))
    THEN
        cwms_20.cwms_err.raise ('NO_WRITE_PRIVILEGE');
    END IF;
END;
/

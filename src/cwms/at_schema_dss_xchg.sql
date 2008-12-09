-------------------------------
-- START OF DSS XCHG SECTION --
-------------------------------
-----------------------------
-- AT_DSS_FILE table
--
CREATE TABLE AT_DSS_FILE
   (
       DSS_FILE_CODE    NUMBER(10)    NOT NULL,
       OFFICE_CODE      NUMBER(10)    NOT NULL,
       DSS_FILEMGR_URL  VARCHAR2(255) NOT NULL,
       DSS_FILE_NAME    VARCHAR2(255) NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_FILE comments
--
COMMENT ON TABLE AT_DSS_FILE IS 'Contains location information for HEC-DSS files';
COMMENT ON COLUMN AT_DSS_FILE.DSS_FILE_CODE   IS 'Primary key used to relate file to other entities';
COMMENT ON COLUMN AT_DSS_FILE.OFFICE_CODE     IS 'Reference to owning office';
COMMENT ON COLUMN AT_DSS_FILE.DSS_FILEMGR_URL IS 'URL For DSSFileManager instance for HEC-DSS file';
COMMENT ON COLUMN AT_DSS_FILE.DSS_FILE_NAME   IS 'Operating system path name for file';
-----------------------------
-- AT_DSS_FILE constraints
--
ALTER TABLE AT_DSS_FILE ADD CONSTRAINT AT_DSS_FILE_FK FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE(OFFICE_CODE);
ALTER TABLE AT_DSS_FILE ADD CONSTRAINT AT_DSS_FILE_UK UNIQUE (DSS_FILE_CODE, DSS_FILEMGR_URL, DSS_FILE_NAME);
ALTER TABLE AT_DSS_FILE ADD CONSTRAINT AT_DSS_FILE_PK PRIMARY KEY (DSS_FILE_CODE) 
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
                BUFFER_POOL      DEFAULT
               );


SHOW ERRORS;
COMMIT;

-----------------------------
-- AT_DSS_TS_SPEC table
--
CREATE TABLE AT_DSS_TS_SPEC
   (
       DSS_TS_CODE             NUMBER(10)   NOT NULL,
       OFFICE_CODE             NUMBER(10)   NOT NULL,
       A_PATHNAME_PART         VARCHAR2(64),
       B_PATHNAME_PART         VARCHAR2(64) NOT NULL,
       C_PATHNAME_PART         VARCHAR2(64) NOT NULL,
       E_PATHNAME_PART         VARCHAR2(64) NOT NULL,
       F_PATHNAME_PART         VARCHAR2(64),
       DSS_PARAMETER_TYPE_CODE NUMBER(10)   NOT NULL,
       UNIT_ID                 VARCHAR2(16) NOT NULL,
       TIME_ZONE_CODE          NUMBER(10)   NOT NULL,
       TZ_USAGE_CODE           NUMBER(10)   NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_TS_SPEC comments
--
COMMENT ON TABLE  AT_DSS_TS_SPEC                         IS 'Complete specification of time series data set in HEC-DSS file';
COMMENT ON COLUMN AT_DSS_TS_SPEC.DSS_TS_CODE             IS 'Primary key used to relate specification to other entities';
COMMENT ON COLUMN AT_DSS_TS_SPEC.OFFICE_CODE             IS 'Reference to owning office';
COMMENT ON COLUMN AT_DSS_TS_SPEC.A_PATHNAME_PART         IS 'HEC-DSS pathname A-part (watershed)';
COMMENT ON COLUMN AT_DSS_TS_SPEC.B_PATHNAME_PART         IS 'HEC-DSS pathname B-part (location)';
COMMENT ON COLUMN AT_DSS_TS_SPEC.C_PATHNAME_PART         IS 'HEC-DSS pathname C-part (parameter)';
COMMENT ON COLUMN AT_DSS_TS_SPEC.E_PATHNAME_PART         IS 'HEC-DSS pathname E-part (interval)';
COMMENT ON COLUMN AT_DSS_TS_SPEC.F_PATHNAME_PART         IS 'HEC-DSS pathname F-part (version)';
COMMENT ON COLUMN AT_DSS_TS_SPEC.DSS_PARAMETER_TYPE_CODE IS 'Reference to HEC-DSS parameter type';
COMMENT ON COLUMN AT_DSS_TS_SPEC.UNIT_ID                 IS 'Units for HEC-DSS data set';
COMMENT ON COLUMN AT_DSS_TS_SPEC.TIME_ZONE_CODE          IS 'Reference to time zone for HEC-DSS data set';
COMMENT ON COLUMN AT_DSS_TS_SPEC.TZ_USAGE_CODE           IS 'Reference to time zone useage for HEC-DSS data set';
-----------------------------
-- AT_DSS_TS_SPEC constraints
--
ALTER TABLE AT_DSS_TS_SPEC ADD CONSTRAINT AT_DSS_TS_SPEC_FK1  FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE(OFFICE_CODE);
ALTER TABLE AT_DSS_TS_SPEC ADD CONSTRAINT AT_DSS_TS_SPEC_FK2  FOREIGN KEY (DSS_PARAMETER_TYPE_CODE) REFERENCES CWMS_DSS_PARAMETER_TYPE(DSS_PARAMETER_TYPE_CODE);
ALTER TABLE AT_DSS_TS_SPEC ADD CONSTRAINT AT_DSS_TS_SPEC_FK3  FOREIGN KEY (TIME_ZONE_CODE) REFERENCES CWMS_TIME_ZONE(TIME_ZONE_CODE);
ALTER TABLE AT_DSS_TS_SPEC ADD CONSTRAINT AT_DSS_TS_SPEC_FK4  FOREIGN KEY (TZ_USAGE_CODE) REFERENCES CWMS_TZ_USAGE(TZ_USAGE_CODE);
ALTER TABLE AT_DSS_TS_SPEC ADD CONSTRAINT AT_DSS_TS_SPEC_PK   PRIMARY KEY (DSS_TS_CODE)
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
                BUFFER_POOL      DEFAULT
               );
-----------------------------
-- AT_DSS_TS_SPEC indicies
--
CREATE UNIQUE INDEX AT_DSS_TS_SPEC_PATHNAME ON AT_DSS_TS_SPEC
   (
       OFFICE_CODE,
       UPPER(NVL(A_PATHNAME_PART, '@')),
       UPPER(B_PATHNAME_PART),
       UPPER(C_PATHNAME_PART),
       UPPER(E_PATHNAME_PART),
       UPPER(NVL(F_PATHNAME_PART, '@')),
       DSS_PARAMETER_TYPE_CODE,
       UNIT_ID,
       TIME_ZONE_CODE,
       TZ_USAGE_CODE
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE cwms_20at_data
       STORAGE 
       ( 
          INITIAL 20k
          NEXT 20k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_UNIT_ALIAS trigger (depends on AT_DSS_TS_SPEC)
--
create or replace trigger at_unit_alias_constraint
before delete or update
of alias_id
on cwms_20.at_unit_alias 
referencing new as new old as old
for each row
declare
   l_count number;   
begin
   if deleting or (updating and :new.alias_id != :old.alias_id) then
      select count(unit_id) 
        into l_count 
        from at_dss_ts_spec ts,
             cwms_office o
       where unit_id = :old.alias_id
         and o.office_code = ts.office_code
         and o.db_host_office_code = :old.db_office_code;
      if l_count > 0 then
         cwms_err.raise(
            'CANNOT_DELETE_UNIT_1',
            :old.alias_id,
            ''|| l_count || 'DSS time series specification(s)');
      end if;
   end if;
end at_unit_alias_constraint;
/
show errors;
commit;

-----------------------------
-- AT_DSS_TS_XCHG_SPEC table
--
CREATE TABLE AT_DSS_TS_XCHG_SPEC
   (
       DSS_TS_XCHG_CODE NUMBER(10)   NOT NULL,
       TS_CODE          NUMBER(10)   NOT NULL,
       DSS_TS_CODE      NUMBER(10)   NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_TS_XCHG_SPEC comments
--
COMMENT ON TABLE  AT_DSS_TS_XCHG_SPEC                  IS 'Oracle/HEC-DSS time series data set exchange specification';
COMMENT ON COLUMN AT_DSS_TS_XCHG_SPEC.DSS_TS_XCHG_CODE IS 'Primary key used to relate specification to other entities';
COMMENT ON COLUMN AT_DSS_TS_XCHG_SPEC.TS_CODE          IS 'Reference to time series data in database';
COMMENT ON COLUMN AT_DSS_TS_XCHG_SPEC.DSS_TS_CODE      IS 'Reference to time series data in HEC-DSS file';
-----------------------------
-- AT_DSS_TS_XCHG_SPEC constraints
--
ALTER TABLE AT_DSS_TS_XCHG_SPEC ADD CONSTRAINT AT_DSS_TS_XCHG_SPEC_FK1  FOREIGN KEY (TS_CODE) REFERENCES AT_CWMS_TS_SPEC(TS_CODE);
ALTER TABLE AT_DSS_TS_XCHG_SPEC ADD CONSTRAINT AT_DSS_TS_XCHG_SPEC_FK2  FOREIGN KEY (DSS_TS_CODE) REFERENCES AT_DSS_TS_SPEC(DSS_TS_CODE);
ALTER TABLE AT_DSS_TS_XCHG_SPEC ADD CONSTRAINT AT_DSS_TS_XCHG_SPEC_PK   PRIMARY KEY (DSS_TS_XCHG_CODE) 
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
                BUFFER_POOL      DEFAULT
               );

/*
-----------------------------
-- AT_DSS_RATING_SPEC table
--
CREATE TABLE AT_DSS_RATING_SPEC
   (
       DSS_RATING_CODE  NUMBER(10)    NOT NULL,
       A_PATHNAME_PART  VARCHAR2(64),
       B_PATHNAME_PART  VARCHAR2(64)  NOT NULL,
       C_PATHNAME_PART  VARCHAR2(64)  NOT NULL,
       F_PATHNAME_PART  VARCHAR2(64),
       MEAS1_UNIT_CODE  NUMBER(10)    NOT NULL,
       MEAS2_UNIT_CODE  NUMBER(10)    NOT NULL,
       RATED_UNIT_CODE  NUMBER(10)    NOT NULL,
       TIMEZONE_CODE    NUMBER(10)    NOT NULL,
       TZ_USAGE_CODE    NUMBER(10)    NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_RATING_SPEC comments
--
COMMENT ON TABLE  AT_DSS_RATING_SPEC                 IS 'Complete specification of rating data set in HEC-DSS file';
COMMENT ON COLUMN AT_DSS_RATING_SPEC.A_PATHNAME_PART IS 'HEC-DSS pathname A-part (watershed)';
COMMENT ON COLUMN AT_DSS_RATING_SPEC.B_PATHNAME_PART IS 'HEC-DSS pathname B-part (location)';
COMMENT ON COLUMN AT_DSS_RATING_SPEC.C_PATHNAME_PART IS 'HEC-DSS pathname C-part (parameters)';
COMMENT ON COLUMN AT_DSS_RATING_SPEC.F_PATHNAME_PART IS 'HEC-DSS pathname F-part (version)';
COMMENT ON COLUMN AT_DSS_RATING_SPEC.TIMEZONE_CODE   IS 'Reference to time zone for HEC-DSS data set';
COMMENT ON COLUMN AT_DSS_RATING_SPEC.TZ_USAGE_CODE   IS 'Reference to time zone useage for HEC-DSS data set';
COMMENT ON COLUMN AT_DSS_RATING_SPEC.DSS_RATING_CODE IS 'Primary key used to relate specification to other entities';
-----------------------------
-- AT_DSS_RATING_SPEC constraints
--
ALTER TABLE AT_DSS_RATING_SPEC ADD CONSTRAINT PK_AT_DSS_RATING_SPEC   PRIMARY KEY (DSS_RATING_CODE);
ALTER TABLE AT_DSS_RATING_SPEC ADD CONSTRAINT FK_AT_DSS_RATING_SPEC_1 FOREIGN KEY (MEAS1_UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE);
ALTER TABLE AT_DSS_RATING_SPEC ADD CONSTRAINT FK_AT_DSS_RATING_SPEC_2 FOREIGN KEY (MEAS2_UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE);
ALTER TABLE AT_DSS_RATING_SPEC ADD CONSTRAINT FK_AT_DSS_RATING_SPEC_3 FOREIGN KEY (RATED_UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE);
ALTER TABLE AT_DSS_RATING_SPEC ADD CONSTRAINT FK_AT_DSS_RATING_SPEC_4 FOREIGN KEY (TIMEZONE_CODE)   REFERENCES CWMS_TIME_ZONE (TIME_ZONE_CODE);
ALTER TABLE AT_DSS_RATING_SPEC ADD CONSTRAINT FK_AT_DSS_RATING_SPEC_5 FOREIGN KEY (TZ_USAGE_CODE)   REFERENCES CWMS_TZ_USAGE (TZ_USAGE_CODE);
-----------------------------
-- AT_DSS_RATING_SPEC indicies
--
CREATE UNIQUE INDEX AT_DSS_RATING_SPEC_UI ON AT_DSS_RATING_SPEC
   (
       UPPER(NVL(A_PATHNAME_PART, '@')),
       UPPER(B_PATHNAME_PART),
       UPPER(C_PATHNAME_PART),
       UPPER(NVL(F_PATHNAME_PART, '@'))
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE cwms_20at_data
       STORAGE 
       ( 
          INITIAL 20k
          NEXT 20k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
SHOW ERRORS;
COMMIT;

-----------------------------
-- AT_DSS_RATING_XCHG_SPEC table
--
CREATE TABLE AT_DSS_RATING_XCHG_SPEC
   (
       DSS_RATING_XCHG_CODE  NUMBER(10)              NOT NULL,
       RATING_CODE           NUMBER(10)              NOT NULL,
       DSS_RATING_CODE       NUMBER(10)              NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_RATING_XCHG_SPEC comments
--
COMMENT ON TABLE  AT_DSS_RATING_XCHG_SPEC                      IS 'Oracle/HEC-DSS rating data set exchange specification';
COMMENT ON COLUMN AT_DSS_RATING_XCHG_SPEC.DSS_RATING_XCHG_CODE IS 'Primary key used to relate specification to other entities';
COMMENT ON COLUMN AT_DSS_RATING_XCHG_SPEC.RATING_CODE          IS 'Reference to rating data in database';
COMMENT ON COLUMN AT_DSS_RATING_XCHG_SPEC.DSS_RATING_CODE      IS 'Reference to rating data in HEC-DSS file';
-----------------------------
-- AT_DSS_RATING_XCHG_SPEC constraints
--
ALTER TABLE AT_DSS_RATING_XCHG_SPEC ADD CONSTRAINT PK_AT_DSS_RATING_XCHG_SPEC   PRIMARY KEY (DSS_RATING_XCHG_CODE);
-- ALTER TABLE AT_DSS_RATING_XCHG_SPEC ADD CONSTRAINT FK_AT_DSS_RATING_XCHG_SPEC_1 FOREIGN KEY (RATING_CODE)     REFERENCES AT_RATING_SPEC (RATING_CODE);
ALTER TABLE AT_DSS_RATING_XCHG_SPEC ADD CONSTRAINT FK_AT_DSS_RATING_XCHG_SPEC_2 FOREIGN KEY (DSS_RATING_CODE) REFERENCES AT_DSS_RATING_SPEC (DSS_RATING_CODE);
*/
-----------------------------
-- AT_DSS_XCHG_SET table
--
CREATE TABLE AT_DSS_XCHG_SET
   (
       DSS_XCHG_SET_CODE NUMBER(10)   NOT NULL,
       OFFICE_CODE       NUMBER(10)   NOT NULL,
       DSS_FILE_CODE     NUMBER(10)   NOT NULL,
       DSS_XCHG_SET_ID   VARCHAR2(32) NOT NULL,
       DESCRIPTION       VARCHAR2(80),
       START_TIME        VARCHAR2(32),
       END_TIME          VARCHAR2(32),
       INTERPOLATE_COUNT NUMBER(10)   DEFAULT 0,
       INTERPOLATE_UNITS NUMBER(1)    DEFAULT 1,
       REALTIME          NUMBER,
       LAST_UPDATE       TIMESTAMP(6)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_XCHG_SET comments
--
COMMENT ON TABLE  AT_DSS_XCHG_SET                   IS 'Oracle/HEC-DSS exchange set specification';
COMMENT ON COLUMN AT_DSS_XCHG_SET.DSS_XCHG_SET_CODE IS 'Primary key used to relate specification to other entities';
COMMENT ON COLUMN AT_DSS_XCHG_SET.DSS_FILE_CODE     IS 'Reference to location of HEC-DSS file';
COMMENT ON COLUMN AT_DSS_XCHG_SET.OFFICE_CODE       IS 'Reference to CWMS office';
COMMENT ON COLUMN AT_DSS_XCHG_SET.DSS_XCHG_SET_ID   IS 'Text identifier of exchange set';
COMMENT ON COLUMN AT_DSS_XCHG_SET.DESCRIPTION       IS 'Text description of exchange set';
COMMENT ON COLUMN AT_DSS_XCHG_SET.INTERPOLATE_COUNT IS 'Maximum number over which to interpolate on exchange';
COMMENT ON COLUMN AT_DSS_XCHG_SET.INTERPOLATE_UNITS IS 'Units of interpolation';
COMMENT ON COLUMN AT_DSS_XCHG_SET.REALTIME          IS 'Reference to realtime exchange direction or NULL if not realtime';
COMMENT ON COLUMN AT_DSS_XCHG_SET.LAST_UPDATE       IS 'Timestamp of last realtime exchange';
-----------------------------
-- AT_DSS_XCHG_SET constraints
--
ALTER TABLE AT_DSS_XCHG_SET ADD CONSTRAINT AT_DSS_XCHG_SET_FK1  FOREIGN KEY (DSS_FILE_CODE) REFERENCES AT_DSS_FILE(DSS_FILE_CODE);
ALTER TABLE AT_DSS_XCHG_SET ADD CONSTRAINT AT_DSS_XCHG_SET_FK2  FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE(OFFICE_CODE);
ALTER TABLE AT_DSS_XCHG_SET ADD CONSTRAINT AT_DSS_XCHG_SET_FK3  FOREIGN KEY (REALTIME) REFERENCES CWMS_DSS_XCHG_DIRECTION(DSS_XCHG_DIRECTION_CODE);
ALTER TABLE AT_DSS_XCHG_SET ADD CONSTRAINT AT_DSS_XCHG_SET_FK4  FOREIGN KEY (INTERPOLATE_UNITS) REFERENCES CWMS_INTERPOLATE_UNITS(INTERPOLATE_UNITS_CODE);
ALTER TABLE AT_DSS_XCHG_SET ADD CONSTRAINT AT_DSS_XCHG_SET_CK1  CHECK (INTERPOLATE_COUNT >= 0);
ALTER TABLE AT_DSS_XCHG_SET ADD CONSTRAINT AT_DSS_XCHG_SET_PK   PRIMARY KEY (DSS_XCHG_SET_CODE) 
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
                BUFFER_POOL      DEFAULT
               );
-----------------------------
-- AT_DSS_XCHG_SET indicies
--
CREATE UNIQUE INDEX AT_DSS_XCHG_SET_UI ON AT_DSS_XCHG_SET
   (  
       OFFICE_CODE,
       UPPER(DSS_XCHG_SET_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
SHOW ERRORS;
COMMIT;

-----------------------------
-- AT_DSS_XCHG_SET_RULES_1 trigger
--
create or replace trigger at_dss_xchg_set_rules_1
before insert or update
of start_time
  ,end_time
on at_dss_xchg_set
referencing new as new old as old
for each row
declare
   --
   -- this trigger ensures that ny timewindows specified are valid.
   --
   l_iso_pattern     varchar2(80) := '-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}([.]\d+)?)?([-+]\d{2}:\d{2}|Z)?';
   l_lookback_text   varchar2(80) := '$lookback-time';
   l_start_text      varchar2(80) := '$start-time';
   l_forecast_text   varchar2(80) := '$forecast-time';
   l_simulation_text varchar2(80) := '$simulation-time';
   l_end_text        varchar2(80) := '$end-time';
   l_explicit_start  boolean      := false;
   l_explicit_end    boolean      := false;

begin
   if :new.start_time is not null then
      if :new.end_time is null then
         cwms_err.raise('ERROR', 'Incomplete time window specified (missing end time)');
      end if;
      for once in 1..1 loop
         exit when :new.start_time = l_lookback_text;
         exit when :new.start_time = l_start_text;
         exit when :new.start_time = l_forecast_text;
         exit when :new.start_time = l_simulation_text;
         l_explicit_start := true;
         exit when regexp_instr(:new.start_time, l_iso_pattern) = 1
               and regexp_instr(:new.start_time, l_iso_pattern, 1, 1, 1) = length(:new.start_time) + 1;
         cwms_err.raise('INVALID_ITEM', :new.start_time, 'time window start time.');
      end loop;
   end if;
   if :new.end_time is not null then
      if :new.start_time is null then
         cwms_err.raise('ERROR', 'Incomplete time window specified (missing start time)');
      end if;
      for once in 1..1 loop
         exit when :new.end_time = l_start_text;
         exit when :new.end_time = l_forecast_text;
         exit when :new.end_time = l_simulation_text;
         exit when :new.end_time = l_end_text;
         l_explicit_end := true;
         exit when regexp_instr(:new.end_time, l_iso_pattern) = 1
               and regexp_instr(:new.end_time, l_iso_pattern, 1, 1, 1) = length(:new.end_time) + 1;
         cwms_err.raise('INVALID_ITEM', :new.start_time, 'time window start time.');
      end loop;
   end if;
   if l_explicit_start and l_explicit_end then
      if cwms_util.to_timestamp(:new.end_time) <= cwms_util.to_timestamp(:new.start_time) then
         cwms_err.raise('ERROR', 'Time window end time (' || :new.end_time || ') is not later that start time (' || :new.start_time || ').');
      end if;
   elsif not l_explicit_start and not l_explicit_end then
      if :new.start_time = l_start_text or :new.start_time = l_forecast_text or :new.start_time = l_simulation_text then
         if :new.end_time = l_start_text or :new.end_time = l_forecast_text or :new.end_time = l_simulation_text then
            cwms_err.raise('ERROR', 'Time window end time (' || :new.end_time || ') is not later that start time (' || :new.start_time || ').');
         end if;
      end if;
   end if;
end;
/
show errors;
commit;

-----------------------------
-- AT_DSS_XCHG_SET_RULES_2 trigger
--
create or replace trigger at_dss_xchg_set_rules_2
before insert or update of realtime
on at_dss_xchg_set
referencing new as new old as old
declare
   --
   -- this trigger ensures that, if individual data sets are included in
   -- multiple real-time exchange sets, all sets exchange data in the
   -- same direction
   --
   type cursor_rec is record(
      ts_code   number(10),
      ts_id     varchar2(183)
   );

   cursor l_conflicts_cur
   is
      select xspec1.ts_code       ts_code, 
             set1.dss_xchg_set_id id_1, 
             set2.dss_xchg_set_id id_2, 
             v.cwms_ts_id         ts_id
        from at_dss_xchg_set set1,
             at_dss_xchg_set set2,
             at_dss_ts_xchg_map map1,
             at_dss_ts_xchg_map map2,
             at_dss_ts_xchg_spec xspec1,
             at_dss_ts_xchg_spec xspec2,
             mv_cwms_ts_id v
      where  xspec1.ts_code = xspec2.ts_code
         and map1.dss_ts_xchg_code = xspec1.dss_ts_xchg_code
         and map2.dss_ts_xchg_code = xspec2.dss_ts_xchg_code
         and map1.dss_xchg_set_code = set1.dss_xchg_set_code
         and map2.dss_xchg_set_code = set2.dss_xchg_set_code
         and set1.realtime is not null
         and set2.realtime is not null
         and set1.realtime != set2.realtime
         and v.ts_code = xspec1.ts_code;
begin
   for rec in l_conflicts_cur loop
      cwms_err.raise('XCHG_TS_ERROR', rec.ts_id, rec.id_2, rec.id_1);
   end loop;
end;
/
show errors;
commit;


-----------------------------
-- AT_DSS_TS_XCHG_MAP table
--
CREATE TABLE AT_DSS_TS_XCHG_MAP
   (
       DSS_TS_XCHG_MAP_CODE NUMBER(10) NOT NULL,
       DSS_XCHG_SET_CODE  NUMBER(10)   NOT NULL,
       DSS_TS_XCHG_CODE   NUMBER(10)   NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_TS_XCHG_MAP comments
--
COMMENT ON TABLE  AT_DSS_TS_XCHG_MAP                      IS 'Maps exchange sets and TS specs in many-to-many relationship';
COMMENT ON COLUMN AT_DSS_TS_XCHG_MAP.DSS_TS_XCHG_MAP_CODE IS 'Primary key used to relate specification to other entities';
COMMENT ON COLUMN AT_DSS_TS_XCHG_MAP.DSS_XCHG_SET_CODE    IS 'Reference to Oracle/HEC-DSS exchange set';
COMMENT ON COLUMN AT_DSS_TS_XCHG_MAP.DSS_TS_XCHG_CODE     IS 'Reference to Oracle/HEC-DSS time series exchange spec';
-----------------------------
-- AT_DSS_TS_XCHG_MAP constraints
--
ALTER TABLE AT_DSS_TS_XCHG_MAP ADD CONSTRAINT AT_DSS_TS_XCHG_MAP_UK   UNIQUE      (DSS_XCHG_SET_CODE, DSS_TS_XCHG_CODE);
ALTER TABLE AT_DSS_TS_XCHG_MAP ADD CONSTRAINT AT_DSS_TS_XCHG_MAP_FK1  FOREIGN KEY (DSS_XCHG_SET_CODE) REFERENCES AT_DSS_XCHG_SET (DSS_XCHG_SET_CODE);
ALTER TABLE AT_DSS_TS_XCHG_MAP ADD CONSTRAINT AT_DSS_TS_XCHG_MAP_FK2  FOREIGN KEY (DSS_TS_XCHG_CODE)  REFERENCES AT_DSS_TS_XCHG_SPEC (DSS_TS_XCHG_CODE);
ALTER TABLE AT_DSS_TS_XCHG_MAP ADD CONSTRAINT AT_DSS_TS_XCHG_MAP_PK   PRIMARY KEY (DSS_TS_XCHG_MAP_CODE) 
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
                BUFFER_POOL      DEFAULT
               );

-----------------------------
-- AT_DSS_TS_XCHG_MAP_RULES trigger
--
create or replace trigger at_dss_ts_xchg_map_rules
before insert or update
of dss_xchg_set_code
  ,dss_ts_xchg_code
on at_dss_ts_xchg_map
referencing new as new old as old
for each row
declare
   -- 
   -- this trigger ensures 1), that if individual data sets are included in 
   -- multiple real-time exchange sets, all sets exchange data in the 
   -- same direction, and 2), that all DSS pathnames assigned to the same
   -- file have the same parameter type, units, time zone and tz usage 
   -- 
   pkval                     number;
   l_ts_xchg_spec            at_dss_ts_xchg_spec%rowtype;
   l_xchg_set                at_dss_xchg_set%rowtype;
   l_dss_ts_spec             at_dss_ts_spec%rowtype;
   l_ts_code                 at_dss_ts_xchg_spec.ts_code%type;
   l_realtime                at_dss_xchg_set.realtime%type;
   l_set_id                  at_dss_xchg_set.dss_xchg_set_id%type;
   l_ts_id                   mv_cwms_ts_id.cwms_ts_id%type;
   l_a_pathname_part         at_dss_ts_spec.a_pathname_part%type;
   l_b_pathname_part         at_dss_ts_spec.b_pathname_part%type;
   l_c_pathname_part         at_dss_ts_spec.c_pathname_part%type;
   l_e_pathname_part         at_dss_ts_spec.e_pathname_part%type;
   l_f_pathname_part         at_dss_ts_spec.f_pathname_part%type;
   l_dss_parameter_type_code at_dss_ts_spec.dss_parameter_type_code%type;
   l_unit_id                 at_dss_ts_spec.unit_id%type;
   l_time_zone_code          at_dss_ts_spec.time_zone_code%type;
   l_tz_usage_code           at_dss_ts_spec.tz_usage_code%type;
   l_dss_parameter_type_id   cwms_dss_parameter_type.dss_parameter_type_id%type;
   l_time_zone_id            cwms_time_zone.time_zone_name%type;
   l_tz_usage_id             cwms_tz_usage.tz_usage_id%type;
   l_empty_dss_ts            boolean := false;
   l_empty_cwms_ts           boolean := false;

   --
   -- all at_dss_ts_xchg_set records that are mapped to at_dss_ts_xchg_spec
   -- records that contain a specified ts_code
   --
   cursor l_xchg_set_cur is
      select xset.*
        from at_dss_xchg_set xset, at_dss_ts_xchg_map xmap, at_dss_ts_xchg_spec xspec
       where xspec.ts_code = l_ts_code
         and xmap.dss_ts_xchg_code = xspec.dss_ts_xchg_code
         and xset.dss_xchg_set_code = xmap.dss_xchg_set_code;
         
   --
   -- all at_dss_ts_spec records that are mapped to the same at_dss_file as
   -- the one specified in :new.dss_xchg_set_code and have the same pathname
   --         
   cursor l_dss_ts_spec_cur is
      select *
        from at_dss_ts_spec
       where nvl(a_pathname_part, '@') = nvl(l_a_pathname_part, '@')
         and b_pathname_part = l_b_pathname_part
         and c_pathname_part = l_c_pathname_part
         and e_pathname_part = l_e_pathname_part
         and nvl(f_pathname_part, '@')  = nvl(l_f_pathname_part, '@')
         and dss_ts_code in (
               select dss_ts_code
                 from at_dss_ts_xchg_spec
                where dss_ts_xchg_code in (
                        select dss_ts_xchg_code
                          from at_dss_ts_xchg_map
                         where dss_ts_xchg_map_code in (
                                 select dss_ts_xchg_map_code
                                   from at_dss_ts_xchg_map
                                  where dss_xchg_set_code in (
                                          select dss_xchg_set_code
                                            from at_dss_xchg_set
                                           where dss_file_code = (
                                                   select dss_file_code
                                                     from at_dss_xchg_set
                                                    where dss_xchg_set_code = :new.dss_xchg_set_code)))));
         
begin
   --
   -- get the dss pathname and non-pathname parameters from the new dss ts xchg spec
   --
   begin
      select *
        into l_dss_ts_spec
        from at_dss_ts_spec
       where dss_ts_code = (
               select dss_ts_code
                 from at_dss_ts_xchg_spec
                where dss_ts_xchg_code = :new.dss_ts_xchg_code);
   exception
      when no_data_found then
         l_empty_dss_ts := true;
   end;
             
   l_a_pathname_part         := l_dss_ts_spec.a_pathname_part;
   l_b_pathname_part         := l_dss_ts_spec.b_pathname_part;
   l_c_pathname_part         := l_dss_ts_spec.c_pathname_part;
   l_e_pathname_part         := l_dss_ts_spec.e_pathname_part;
   l_f_pathname_part         := l_dss_ts_spec.f_pathname_part;
   l_dss_parameter_type_code := l_dss_ts_spec.dss_parameter_type_code;
   l_unit_id                 := l_dss_ts_spec.unit_id;
   l_time_zone_code          := l_dss_ts_spec.time_zone_code;
   l_tz_usage_code           := l_dss_ts_spec.tz_usage_code;
   
   begin                      
      select dss_parameter_type_id
        into l_dss_parameter_type_id
        from cwms_dss_parameter_type
       where dss_parameter_type_code = l_dss_ts_spec.dss_parameter_type_code;
             
      select time_zone_name
        into l_time_zone_id
        from cwms_time_zone
       where time_zone_code = l_dss_ts_spec.time_zone_code;
                
      select tz_usage_id
        into l_tz_usage_id
        from cwms_tz_usage
       where tz_usage_code = l_dss_ts_spec.tz_usage_code;
    exception
      when others then
         cwms_err.raise('ERROR', sqlerrm);
    end;
    
   --
   -- compare the non-pathname parameters against any other records with the
   -- same pathname mapped to the same DSS file 
   --
   declare
      l_errmsg varchar2(64) := null;
      l_dss_file at_dss_file%rowtype;
   begin
      for l_dss_ts_spec in l_dss_ts_spec_cur loop
         if l_dss_ts_spec.dss_parameter_type_code != l_dss_parameter_type_code then
            select dss_parameter_type_id
              into l_errmsg
              from cwms_dss_parameter_type
             where dss_parameter_type_code = l_dss_ts_spec.dss_parameter_type_code;
            l_errmsg := 'parameter type ' || l_errmsg;
            exit;
         elsif upper(l_dss_ts_spec.unit_id) != upper(l_unit_id) then
            l_errmsg := 'units ' || l_dss_ts_spec.unit_id;
            exit;
         elsif l_dss_ts_spec.time_zone_code != l_time_zone_code then
            select time_zone_name
              into l_errmsg
              from cwms_time_zone
             where time_zone_code = l_dss_ts_spec.time_zone_code;
            l_errmsg := 'time zone ' || l_errmsg;
            exit;
         elsif l_dss_ts_spec.tz_usage_code != l_tz_usage_code then
            select tz_usage_id
              into l_errmsg
              from cwms_tz_usage
             where tz_usage_code = l_dss_ts_spec.tz_usage_code;
            l_errmsg := 'tz usage ' || l_errmsg;
            exit;
         end if;
      end loop;               
      if l_errmsg is not null then
         select *
           into l_dss_file
           from at_dss_file
          where dss_file_code = (
                  select dss_file_code
                    from at_dss_xchg_set
                   where dss_xchg_set_code = :new.dss_xchg_set_code);

         cwms_err.raise(
            'ERROR',
            'Cannot map HEC-DSS time series specification '
            || cwms_xchg.make_dss_ts_id(
                  l_dss_ts_spec.a_pathname_part,
                  l_dss_ts_spec.b_pathname_part,
                  l_dss_ts_spec.c_pathname_part,
                  null,
                  l_dss_ts_spec.e_pathname_part,
                  l_dss_ts_spec.f_pathname_part,
                  l_dss_parameter_type_id,
                  l_dss_ts_spec.unit_id,
                  l_time_zone_id,
                  l_tz_usage_id)
            || ' to file '
            || l_dss_file.dss_filemgr_url
            || l_dss_file.dss_file_name
            || ': existing mapping has '
            || l_errmsg); 
      end if; 
   end;

   -- 
   -- get the real-time and direction settings from the new exchange set 
   -- 
   select *
     into l_xchg_set
     from at_dss_xchg_set
    where dss_xchg_set_code = :new.dss_xchg_set_code;
      
   if l_xchg_set.realtime is not null then
      -- 
      -- a real-time set is specified, so we have to check everything out 
      --
       
      -- 
      -- save the new real-time and direction
      -- 
      l_realtime := l_xchg_set.realtime;
      l_set_id := l_xchg_set.dss_xchg_set_id;
      --
      -- get the ts_code from the new at_dss_ts_xchg_spec
      --
      select ts_code
         into  l_ts_code
         from  at_dss_ts_xchg_spec
         where dss_ts_xchg_code = :new.dss_ts_xchg_code;
      -- 
      -- loop through every at_dss_xchg_spec that maps to a at_dss_ts_xchg_spec record
      -- that contains the ts_code 
      -- 
      for l_xchg_set in l_xchg_set_cur loop
         begin
            if l_xchg_set.realtime is not null and l_xchg_set.realtime != l_realtime then
               --
               -- this realtime set has a mapping that includes sending the ts_code
               -- in the opposite direction
               --
               select cwms_ts_id 
               into   l_ts_id
               from   mv_cwms_ts_id 
               where  ts_code=l_ts_xchg_spec.ts_code;

               cwms_err.raise('XCHG_TS_ERROR', l_ts_id, l_set_id, l_xchg_set.dss_xchg_set_id);
            end if;
         exception
            when others then
               --
               -- unexpected error
               --
               rollback;
               dbms_output.put_line(sqlerrm);
               raise;
         end;
      end loop;
   end if;
   
end at_dss_ts_xchg_map_rules;
/
show errors;

COMMIT;

/*
-----------------------------
-- AT_DSS_RATING_XCHG_MAP table
--
CREATE TABLE AT_DSS_RATING_XCHG_MAP
   (
       DSS_RATING_XCHG_MAP_CODE NUMBER(10) NOT NULL,
       DSS_XCHG_SET_CODE        NUMBER(10) NOT NULL,
       DSS_RATING_XCHG_CODE     NUMBER(10) NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE CWMS_20AT_DATA
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-----------------------------
-- AT_DSS_RATING_XCHG_MAP comments
--
COMMENT ON TABLE  AT_DSS_RATING_XCHG_MAP                          IS 'Maps exchange sets and rating specs in many-to-many relationship';
COMMENT ON COLUMN AT_DSS_RATING_XCHG_MAP.DSS_RATING_XCHG_MAP_CODE IS 'Primary key used to relate specification to other entities';
COMMENT ON COLUMN AT_DSS_RATING_XCHG_MAP.DSS_XCHG_SET_CODE        IS 'Reference to Oracle/HEC-DSS exchange set';
COMMENT ON COLUMN AT_DSS_RATING_XCHG_MAP.DSS_RATING_XCHG_CODE     IS 'Reference to Oracle/HEC-DSS rating exchange spec';
-----------------------------
-- AT_DSS_RATING_XCHG_MAP constraints
--
ALTER TABLE AT_DSS_RATING_XCHG_MAP ADD CONSTRAINT PK_AT_DSS_RATING_XCHG_MAP   PRIMARY KEY (DSS_RATING_XCHG_MAP_CODE);
ALTER TABLE AT_DSS_RATING_XCHG_MAP ADD CONSTRAINT UK_AT_DSS_RATING_XCHG_MAP   UNIQUE      (DSS_XCHG_SET_CODE, DSS_RATING_XCHG_CODE);
ALTER TABLE AT_DSS_RATING_XCHG_MAP ADD CONSTRAINT FK_AT_DSS_RATING_XCHG_MAP_1 FOREIGN KEY (DSS_XCHG_SET_CODE)    REFERENCES AT_DSS_XCHG_SET (DSS_XCHG_SET_CODE);
ALTER TABLE AT_DSS_RATING_XCHG_MAP ADD CONSTRAINT FK_AT_DSS_RATING_XCHG_MAP_2 FOREIGN KEY (DSS_RATING_XCHG_CODE) REFERENCES AT_DSS_RATING_XCHG_SPEC (DSS_RATING_XCHG_CODE);

-----------------------------
-- AT_DSS_RATING_XCHG_MAP_RULES trigger
--
create or replace trigger at_dss_rating_xchg_map_rules
before insert or update
of dss_xchg_set_code
  ,dss_rating_xchg_code
on at_dss_rating_xchg_map
referencing new as new old as old
for each row
declare
   -- 
   -- this trigger ensures that, if individual data sets are included in 
   -- multiple real-time exchange sets, all sets exchange data in the 
   -- same direction. 
   -- 
   pkval                number;
   l_rating_xchg_spec   at_dss_rating_xchg_spec%rowtype;
   l_xchg_set           at_dss_xchg_set%rowtype;
   l_rating_code        at_dss_rating_xchg_spec.rating_code%type;
   l_realtime           at_dss_xchg_set.realtime%type;
   l_set_id             at_dss_xchg_set.dss_xchg_set_id%type;
   l_rating_id          at_rating_id_mview.rating_id%type;

   --
   -- all at_dss_rating_xchg_set records that are mapped to at_dss_rating_xchg_spec
   -- records that contain a specified rating_code
   --
   cursor l_xchg_set_cur is
      select xset.*
      from  at_dss_xchg_set xset, at_dss_rating_xchg_map xmap, at_dss_rating_xchg_spec xspec
      where xspec.rating_code = l_rating_code
         and xmap.dss_rating_xchg_code = xspec.dss_rating_xchg_code
         and xset.dss_xchg_set_code = xmap.dss_xchg_set_code;
begin
   -- 
   -- get the real-time and direction settings from the new exchange set 
   -- 
   select *
   into   l_xchg_set
   from   at_dss_xchg_set
   where  dss_xchg_set_code=:new.dss_xchg_set_code;

   if l_xchg_set.realtime is not null then
      -- 
      -- a real-time set is specified, so we have to check everything out 
      --
       
      -- 
      -- save the new real-time and direction
      -- 
      l_realtime := l_xchg_set.realtime;
      l_set_id := l_xchg_set.dss_xchg_set_id;
      --
      -- get the rating_code from the new at_dss_rating_xchg_spec
      --
      select rating_code
      into   l_rating_code
      from   at_dss_rating_xchg_spec
      where  dss_rating_xchg_code = :new.dss_rating_xchg_code;
      -- 
      -- loop through every at_dss_xchg_spec that maps to a at_dss_rating_xchg_spec record
      -- that contains the ts_code 
      -- 
      for l_xchg_set in l_xchg_set_cur loop
         begin
            if l_xchg_set.realtime is not null and l_xchg_set.realtime != l_realtime then
               --
               -- this realtime set has a mapping that includes sending the rating_code
               -- in the opposite direction
               --
               select rating_id 
               into   l_rating_id
               from   at_rating_id_mview 
               where  rating_code=l_rating_xchg_spec.rating_code;
               
               cwms_err.raise('XCHG_RATING_ERROR', l_rating_id, l_set_id, l_xchg_set.dss_xchg_set_id);
                     
            end if;
         exception
            when others then
               --
               -- unexpected error
               --
               dbms_output.put_line(sqlerrm);
               raise;
         end;
      end loop;
   end if;
      
end at_dss_rating_xchg_map_rules;
/
SHOW ERRORS;
COMMIT;
*/

-----------------------------
-- END OF DSS XCHG SECTION --
-----------------------------

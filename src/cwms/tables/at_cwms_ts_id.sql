--
-- AT_CWMS_TS_ID  (Table)
--
CREATE TABLE AT_CWMS_TS_ID
(
  DB_OFFICE_CODE        NUMBER                  NOT NULL,
  BASE_LOCATION_CODE    NUMBER,
  BASE_LOC_ACTIVE_FLAG  VARCHAR2(1 BYTE),
  LOCATION_CODE         NUMBER                  NOT NULL,
  LOC_ACTIVE_FLAG       VARCHAR2(1 BYTE),
  PARAMETER_CODE        NUMBER,
  TS_CODE               NUMBER                  NOT NULL,
  TS_ACTIVE_FLAG        VARCHAR2(1 BYTE),
  NET_TS_ACTIVE_FLAG    CHAR(1 BYTE),
  DB_OFFICE_ID          VARCHAR2(16 BYTE)       NOT NULL,
  CWMS_TS_ID            VARCHAR2(191 BYTE),
  UNIT_ID               VARCHAR2(16 BYTE)       NOT NULL,
  ABSTRACT_PARAM_ID     VARCHAR2(32 BYTE)       NOT NULL,
  BASE_LOCATION_ID      VARCHAR2(24 BYTE)       NOT NULL,
  SUB_LOCATION_ID       VARCHAR2(32 BYTE),
  LOCATION_ID           VARCHAR2(57 BYTE),
  BASE_PARAMETER_ID     VARCHAR2(16 BYTE)       NOT NULL,
  SUB_PARAMETER_ID      VARCHAR2(32 BYTE),
  PARAMETER_ID          VARCHAR2(49 BYTE),
  PARAMETER_TYPE_ID     VARCHAR2(16 BYTE)       NOT NULL,
  INTERVAL_ID           VARCHAR2(16 BYTE)       NOT NULL,
  DURATION_ID           VARCHAR2(16 BYTE)       NOT NULL,
  VERSION_ID            VARCHAR2(32 BYTE)       NOT NULL,
  INTERVAL              NUMBER(14)              NOT NULL,
  INTERVAL_UTC_OFFSET   NUMBER                  NOT NULL,
  VERSION_FLAG          VARCHAR2(1 BYTE),
  HISTORIC_FLAG         VARCHAR2(1 BYTE)        DEFAULT 'F',
  TIME_ZONE_ID          VARCHAR2(28 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

comment on table  at_cwms_ts_id                       is 'Holds useful information about time series identfiers';
comment on column at_cwms_ts_id.db_office_code        is 'Primary key in CWMS_OFFICE for the office that owns the time series';
comment on column at_cwms_ts_id.base_location_code    is 'Primary key in AT_BASE_LOCATION for the base location of the time series';
comment on column at_cwms_ts_id.base_loc_active_flag  is 'A flag (''T''/''F'') that specifies whether the base location is marked as active';
comment on column at_cwms_ts_id.location_code         is 'Primary key in AT_PHYSICAL_LOCATION for the location of the time series';
comment on column at_cwms_ts_id.loc_active_flag       is 'A flag (''T''/''F'') that specifies whether the location is marked as active';
comment on column at_cwms_ts_id.parameter_code        is 'Primary key in AT_PARAMETER for the parameter of the time series';
comment on column at_cwms_ts_id.ts_code               is 'Primary key in AT_CWMS_TS_SPEC for the time series ID';
comment on column at_cwms_ts_id.ts_active_flag        is 'A flag (''T''/''F'') that specifies whether the time series is marked as active';
comment on column at_cwms_ts_id.net_ts_active_flag    is 'A flag (''T''/''F'') that specifies whether the time series is inactivated by any other of the active flags';
comment on column at_cwms_ts_id.db_office_id          is 'The identifier of the office that owns the time series';
comment on column at_cwms_ts_id.cwms_ts_id            is 'The identifier of the time series';
comment on column at_cwms_ts_id.unit_id               is 'The identifier of the database storage unit for the time series';
comment on column at_cwms_ts_id.abstract_param_id     is 'The identifier of the abstract parameter of the time series';
comment on column at_cwms_ts_id.base_location_id      is 'The identifier of the base location of the time series';
comment on column at_cwms_ts_id.sub_location_id       is 'The identifier of the sub-location of the time series';
comment on column at_cwms_ts_id.location_id           is 'The identifier of the complete location of the time series';
comment on column at_cwms_ts_id.base_parameter_id     is 'The identifier of the base parameter of the time series';
comment on column at_cwms_ts_id.sub_parameter_id      is 'The identifier of the sub-parameter of the time series';
comment on column at_cwms_ts_id.parameter_id          is 'The identifier of the complete parameter of the time series';
comment on column at_cwms_ts_id.parameter_type_id     is 'The identifier of the parameter type of the time series';
comment on column at_cwms_ts_id.interval_id           is 'The identifier of the recurrence interval of the time series';
comment on column at_cwms_ts_id.duration_id           is 'The identifier of the duration of the time series';
comment on column at_cwms_ts_id.version_id            is 'The identifier of the version of the time series';
comment on column at_cwms_ts_id.interval              is 'The interval of the time series in minutes';
comment on column at_cwms_ts_id.interval_utc_offset   is 'The offset in minutes into the interval for time series values';
comment on column at_cwms_ts_id.version_flag          is 'A flag (''T''/''F'') that specifies whether the time series is versioned';
comment on column at_cwms_ts_id.historic_flag         is 'A flag (''T''/''F'') that specifies whether the time series is part of the historical record';
comment on column at_cwms_ts_id.time_zone_id          is 'The time zone of the location of the time series';


--
-- AT_CWMS_TS_ID_PK  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
CREATE UNIQUE INDEX AT_CWMS_TS_ID_PK ON AT_CWMS_TS_ID
(TS_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

CREATE OR REPLACE SYNONYM MV_CWMS_TS_ID
FOR AT_CWMS_TS_ID
/
--
-- AT_CWMS_TS_ID_U01  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
CREATE UNIQUE INDEX AT_CWMS_TS_ID_U01 ON AT_CWMS_TS_ID
(DB_OFFICE_ID, CWMS_TS_ID)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


--
-- AT_CWMS_TS_ID_U02  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
CREATE UNIQUE INDEX AT_CWMS_TS_ID_U02 ON AT_CWMS_TS_ID
(UPPER("DB_OFFICE_ID"), UPPER("CWMS_TS_ID"))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

--
-- AT_CWMS_TS_ID_U03  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
CREATE INDEX AT_CWMS_TS_ID_U03 ON AT_CWMS_TS_ID
(CWMS_TS_ID)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

--
-- AT_CWMS_TS_ID_U04  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
CREATE INDEX AT_CWMS_TS_ID_U04 ON AT_CWMS_TS_ID
(UPPER("CWMS_TS_ID"))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

--
-- AT_CWMS_TS_ID_ACTIVE  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
create index at_cwms_ts_id_active on at_cwms_ts_id(location_code, ts_active_flag)
tablespace cwms_20data;

--
-- Non Foreign Key Constraints for Table AT_CWMS_TS_ID
--
ALTER TABLE AT_CWMS_TS_ID ADD (
  CONSTRAINT AT_CWMS_TS_ID_PK
  PRIMARY KEY
  (TS_CODE)
  USING INDEX AT_CWMS_TS_ID_PK)
/
--
-- AT_BASE_LOCATION_T01  (Trigger)
--
--  Dependencies:
--   STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_BASE_LOCATION (Table)
--
CREATE OR REPLACE TRIGGER at_base_location_t01
    AFTER UPDATE OF active_flag, base_location_id
    ON at_base_location
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
BEGIN
    cwms_ts_id.touched_abl (:new.db_office_code,
                                    :new.base_location_code,
                                    :new.active_flag,
                                    :new.base_location_id
                                  );
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_base_location_t01;
/


--
-- AT_CWMS_TS_SPEC_T01  (Trigger)
--
--  Dependencies:
--   STANDARD (Package)
--   DBMS_STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_CWMS_TS_SPEC (Table)
--
CREATE OR REPLACE TRIGGER at_cwms_ts_spec_t01
    AFTER INSERT OR UPDATE OR DELETE
    ON AT_CWMS_TS_SPEC     REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
    l_cwms_ts_spec   at_cwms_ts_spec%ROWTYPE;
BEGIN
    IF INSERTING OR UPDATING
    THEN
        l_cwms_ts_spec.ts_code := :new.ts_code;
        l_cwms_ts_spec.location_code := :new.location_code;
        l_cwms_ts_spec.parameter_code := :new.parameter_code;
        l_cwms_ts_spec.parameter_type_code := :new.parameter_type_code;
        l_cwms_ts_spec.interval_code := :new.interval_code;
        l_cwms_ts_spec.duration_code := :new.duration_code;
        l_cwms_ts_spec.version := :new.version;
        l_cwms_ts_spec.description := :new.description;
        l_cwms_ts_spec.interval_utc_offset := :new.interval_utc_offset;
        l_cwms_ts_spec.interval_forward := :new.interval_forward;
        l_cwms_ts_spec.interval_backward := :new.interval_backward;
        l_cwms_ts_spec.interval_offset_id := :new.interval_offset_id;
        l_cwms_ts_spec.time_zone_code := :new.time_zone_code;
        l_cwms_ts_spec.version_flag := :new.version_flag;
        l_cwms_ts_spec.migrate_ver_flag := :new.migrate_ver_flag;
        l_cwms_ts_spec.active_flag := :new.active_flag;
        l_cwms_ts_spec.delete_date := :new.delete_date;
        l_cwms_ts_spec.data_source := :new.data_source;
        l_cwms_ts_spec.historic_flag := :new.historic_flag;
        --
        cwms_ts_id.touched_acts (l_cwms_ts_spec);
    END IF;

    IF DELETING
    THEN
        cwms_ts_id.delete_from_at_cwms_ts_id (:old.ts_code);
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_cwms_ts_spec_t01;
/


--
-- AT_PARAMETER_T01  (Trigger)
--
--  Dependencies:
--   STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_PARAMETER (Table)
--
CREATE OR REPLACE TRIGGER at_parameter_t01
    AFTER UPDATE OF sub_parameter_id
    ON at_parameter
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
BEGIN
    cwms_ts_id.touched_api (:new.parameter_code,
                                    :new.base_parameter_code,
                                    :new.sub_parameter_id
                                  );
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_parameter_t01;
/


--
-- AT_PHYSICAL_LOCATION_T01  (Trigger)
--
--  Dependencies:
--   STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_PHYSICAL_LOCATION (Table)
--
CREATE OR REPLACE TRIGGER at_physical_location_t01
    AFTER UPDATE OF active_flag, sub_location_id, base_location_code
    ON at_physical_location
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
BEGIN
    cwms_ts_id.touched_apl (:new.location_code,
                                    :new.active_flag,
                                    :new.sub_location_id,
                                    :new.base_location_code
                                  );
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_physical_location_t01;
/

--
-- AT_PHYSICAL_LOCATION_T02  (Trigger)
--
--  Dependencies:
--   STANDARD (Package)
--   CWMS_LOC (Package)
--   AT_PHYSICAL_LOCATION (Table)
--
create or replace trigger at_physical_location_t02
   before insert or update
   on at_physical_location
   referencing new as new old as old
   for each row
declare
   l_lat_lon_changed boolean;
   l_update_non_null boolean;
   l_county_code     integer;
begin
   if :new.latitude is not null and :new.longitude is not null then
      -------------------------------------------------------------
      -- won't apply to sub-locations that inherit their lat/lon --
      -------------------------------------------------------------
      l_lat_lon_changed :=
         :old.latitude is null
         or :old.longitude is null
         or :new.latitude != :old.latitude
         or :new.longitude != :old.longitude;
      if l_lat_lon_changed then
         l_update_non_null := instr(
            'TRUE',
            upper(cwms_properties.get_property(
               'CWMSDB',
               'location.update_non_null_items_on_latlon_change',
               'false'))) = 1;
      end if;
      if :new.county_code is null or mod(:new.county_code, 1000) = 0 or (l_lat_lon_changed and l_update_non_null) then
         -------------------------------------
         -- get the county from the lat/lon --
         -------------------------------------
         l_county_code := cwms_loc.get_county_code(:new.latitude, :new.longitude);
         if l_county_code is not null then
            :new.county_code := l_county_code;
            if :new.nation_code is null then
               :new.nation_code := 'US';
            end if;
         end if;
      end if;
      if :new.office_code is null or (l_lat_lon_changed and l_update_non_null) then
         ----------------------------------------------
         -- get the bounding office from the lat/lon --
         ----------------------------------------------
         :new.office_code := cwms_loc.get_bounding_ofc_code(:new.latitude, :new.longitude);
      end if;
      if :new.nearest_city is null or (l_lat_lon_changed and l_update_non_null) then
         -------------------------------------------
         -- get the nearest city from the lat/lon --
         -------------------------------------------
         :new.nearest_city := cwms_loc.get_nearest_city(:new.latitude, :new.longitude)(1);
      end if;
   end if;
exception
   when others then cwms_err.raise('ERROR', dbms_utility.format_error_backtrace);
end at_physical_location_t02;
/


--
-- AT_PHYSICAL_LOCATION_T03  (Trigger)
--
--  Dependencies:
--   STANDARD (Package)
--   CWMS_LOC (Package)
--   AT_PHYSICAL_LOCATION (Table)
--
create or replace trigger at_physical_location_t03
after delete or update of time_zone_code,
                          county_code,
                          location_type,
                          elevation,
                          vertical_datum,
                          longitude,
                          latitude,
                          horizontal_datum,
                          public_name,
                          long_name,
                          description,
                          active_flag,
                          location_kind,
                          published_latitude,
                          published_longitude,
                          office_code,
                          nation_code,
                          nearest_city
on at_physical_location
referencing new as new old as old
for each row
declare
   l_msg varchar2(4000);
   l_ofc varchar2(16);
   l_loc varchar2(256);
begin
   if deleting then
      select o.office_id,
             bl.base_location_id
             ||substr('-', 1, length(:old.sub_location_id))
             ||:old.sub_location_id
        into l_ofc,
             l_loc
        from at_base_location bl,
             cwms_office o
       where bl.base_location_code = :old.base_location_code
         and o.office_code = bl.db_office_code;
      l_msg := 'Location '||l_ofc||'/'||l_loc||' deleted';
      cwms_msg.log_db_message(cwms_msg.msg_level_normal, l_msg);
   elsif updating then
      if nvl(to_char(:new.county_code), '<NULL>')          != nvl(to_char(:old.county_code), '<NULL>')           then l_msg := l_msg||'county_code           : '||nvl(to_char(:old.county_code), '<NULL>')          ||' -> '||nvl(to_char(:new.county_code), '<NULL>')          ||chr(10); end if;
      if nvl(:new.location_type, '<NULL>')                 != nvl(:old.location_type, '<NULL>')                  then l_msg := l_msg||'location_type         : '||nvl(:old.location_type, '<NULL>')                 ||' -> '||nvl(:new.location_type, '<NULL>')                 ||chr(10); end if;
      if nvl(to_char(:new.elevation), '<NULL>')            != nvl(to_char(:old.elevation), '<NULL>')             then l_msg := l_msg||'elevation             : '||nvl(to_char(:old.elevation), '<NULL>')            ||' -> '||nvl(to_char(:new.elevation), '<NULL>')            ||chr(10); end if;
      if nvl(:new.vertical_datum, '<NULL>')                != nvl(:old.vertical_datum, '<NULL>')                 then l_msg := l_msg||'vertical_datum        : '||nvl(:old.vertical_datum, '<NULL>')                ||' -> '||nvl(:new.vertical_datum, '<NULL>')                ||chr(10); end if;
      if nvl(to_char(:new.longitude), '<NULL>')            != nvl(to_char(:old.longitude), '<NULL>')             then l_msg := l_msg||'longitude             : '||nvl(to_char(:old.longitude), '<NULL>')            ||' -> '||nvl(to_char(:new.longitude), '<NULL>')            ||chr(10); end if;
      if nvl(to_char(:new.latitude), '<NULL>')             != nvl(to_char(:old.latitude), '<NULL>')              then l_msg := l_msg||'latitude              : '||nvl(to_char(:old.latitude), '<NULL>')             ||' -> '||nvl(to_char(:new.latitude), '<NULL>')             ||chr(10); end if;
      if nvl(:new.horizontal_datum, '<NULL>')              != nvl(:old.horizontal_datum, '<NULL>')               then l_msg := l_msg||'horizontal_datum      : '||nvl(:old.horizontal_datum, '<NULL>')              ||' -> '||nvl(:new.horizontal_datum, '<NULL>')              ||chr(10); end if;
      if nvl(:new.public_name, '<NULL>')                   != nvl(:old.public_name, '<NULL>')                    then l_msg := l_msg||'public_name           : '||nvl(:old.public_name, '<NULL>')                   ||' -> '||nvl(:new.public_name, '<NULL>')                   ||chr(10); end if;
      if nvl(:new.long_name, '<NULL>')                     != nvl(:old.long_name, '<NULL>')                      then l_msg := l_msg||'long_name             : '||nvl(:old.long_name, '<NULL>')                     ||' -> '||nvl(:new.long_name, '<NULL>')                     ||chr(10); end if;
      if nvl(:new.description, '<NULL>')                   != nvl(:old.description, '<NULL>')                    then l_msg := l_msg||'description           : '||nvl(:old.description, '<NULL>')                   ||' -> '||nvl(:new.description, '<NULL>')                   ||chr(10); end if;
      if nvl(:new.active_flag, '<NULL>')                   != nvl(:old.active_flag, '<NULL>')                    then l_msg := l_msg||'active_flag           : '||nvl(:old.active_flag, '<NULL>')                   ||' -> '||nvl(:new.active_flag, '<NULL>')                   ||chr(10); end if;
      if nvl(to_char(:new.location_kind), '<NULL>')        != nvl(to_char(:old.location_kind), '<NULL>')         then l_msg := l_msg||'location_kind         : '||nvl(to_char(:old.location_kind), '<NULL>')        ||' -> '||nvl(to_char(:new.location_kind), '<NULL>')        ||chr(10); end if;
      if nvl(to_char(:new.published_latitude), '<NULL>')   != nvl(to_char(:old.published_latitude), '<NULL>')    then l_msg := l_msg||'published_latitude    : '||nvl(to_char(:old.published_latitude), '<NULL>')   ||' -> '||nvl(to_char(:new.published_latitude), '<NULL>')   ||chr(10); end if;
      if nvl(to_char(:new.published_longitude), '<NULL>')  != nvl(to_char(:old.published_longitude), '<NULL>')   then l_msg := l_msg||'published_longitude   : '||nvl(to_char(:old.published_longitude), '<NULL>')  ||' -> '||nvl(to_char(:new.published_longitude), '<NULL>')  ||chr(10); end if;
      if nvl(to_char(:new.office_code), '<NULL>')          != nvl(to_char(:old.office_code), '<NULL>')           then l_msg := l_msg||'office_code           : '||nvl(to_char(:old.office_code), '<NULL>')          ||' -> '||nvl(to_char(:new.office_code), '<NULL>')          ||chr(10); end if;
      if nvl(to_char(:new.nation_code), '<NULL>')          != nvl(to_char(:old.nation_code), '<NULL>')           then l_msg := l_msg||'nation_code           : '||nvl(to_char(:old.nation_code), '<NULL>')          ||' -> '||nvl(to_char(:new.nation_code), '<NULL>')          ||chr(10); end if;
      if nvl(:new.nearest_city, '<NULL>')                  != nvl(:old.nearest_city, '<NULL>')                   then l_msg := l_msg||'nearest_city          : '||nvl(:old.nearest_city, '<NULL>')                  ||' -> '||nvl(:new.nearest_city, '<NULL>')                  ||chr(10); end if;
      if l_msg is not null then
         select o.office_id,
                bl.base_location_id
                ||substr('-', 1, length(:old.sub_location_id))
                ||:old.sub_location_id
           into l_ofc,
                l_loc
           from at_base_location bl,
                cwms_office o
          where bl.base_location_code = :old.base_location_code
            and o.office_code = bl.db_office_code;
         l_msg := 'Location '||l_ofc||'/'||l_loc||' updated:'||chr(10)||l_msg;
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, l_msg);
      end if;
   end if;
end at_physical_location_t03;
/


insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_A2W_TS_CODES_BY_LOC2', null,
'
/**
 * Displays A2W_TS_CODES_BY_LOC2 information
 *
 * @since CWMS 3.0
 *
 * @field ts_code                 The selected ts code
 * @field location_code           The location code of the UR/A2W location
 * @field location_id             The location ID of A2W Location this TS Code is associated   to (it could be different then the location ID of the TS Code)
 * @field ts_type                 The A2W TS Type  (elevation, stage, etc)
 * @field cwms_ts_id              The CWMS TS ID
 * @field unit_id                 The DB units of the TS Code
 * @field base_parameter_id       The base parameter ID of the TS Code
 * @field db_office_id            The DB Office of the location and TS Code
/*
');
-- Sourced from AT_PUBLISHED_TS / CWMS_PUBLISHED_ID / AT_A2W_ATTRIBUTES instead of the
-- retired wide AT_A2W_TS_CODES_BY_LOC columns, to preserve this view's shape (and, in
-- particular, its TS_TYPE label strings, which existing consumers such as CDA's
-- PublishedTimeSeriesDao key off of) while the underlying schema is normalized.
-- If a new PUBLISHED_ID is added to CWMS_PUBLISHED_ID that should appear here, add a
-- WHEN clause to the CASE expression below.
CREATE OR REPLACE FORCE VIEW "CWMS_20"."AV_A2W_TS_CODES_BY_LOC2" ("TS_CODE", "LOCATION_CODE", "LOCATION_ID", "TS_TYPE", "CWMS_TS_ID", "UNIT_ID", "BASE_PARAMETER_ID", "DB_OFFICE_ID") AS
  SELECT pts.ts_code, pts.location_code, l.location_id, pts.ts_type, tsi.cwms_ts_id, tsi.unit_id, tsi.base_parameter_id, tsi.db_Office_id
  FROM (
        SELECT ts_code, location_code,
               CASE published_id
                  WHEN 'TS_ELEV'             THEN 'ELEV'
                  WHEN 'TS_PRECIP'           THEN 'PRECIP'
                  WHEN 'TS_STAGE'            THEN 'STAGE'
                  WHEN 'TS_INFLOW'           THEN 'INFLOW'
                  WHEN 'TS_OUTFLOW'          THEN 'OUTFLOW'
                  WHEN 'TS_SUR_RELEASE'      THEN 'SURCHARGE RELEASE'
                  WHEN 'TS_STOR_FLOOD'       THEN 'FLOOD STORAGE'
                  WHEN 'TS_STOR_DROUGHT'     THEN 'CONSERVATION STORAGE'
                  WHEN 'TS_ELEV_TW'          THEN 'ELEV TAILWATER'
                  WHEN 'TS_STAGE_TW'         THEN 'STAGE TAILWATER'
                  WHEN 'TS_RULE_CURVE_ELEV'  THEN 'ELEV RULE CURVE'
                  WHEN 'TS_POWER_GEN'        THEN 'POWER GENERATION'
                  WHEN 'TS_TEMP_AIR'         THEN 'AIR TEMPERATURE'
                  WHEN 'TS_TEMP_WATER'       THEN 'WATER TEMPERATURE'
                  WHEN 'TS_DO'               THEN 'DISOLVED OXYGEN'
                  WHEN 'TS_COND'             THEN 'CONDUCTIVITY'
                  WHEN 'TS_PH'               THEN 'PH'
                  WHEN 'TS_WIND_DIR'         THEN 'WIND DIRECTION'
                  WHEN 'TS_WIND_SPEED'       THEN 'WIND SPEED'
                  WHEN 'TS_OPENING'          THEN 'OPENING'
                  WHEN 'TS_VOLT'             THEN 'VOLTAGE'
                  WHEN 'TS_PCT_FLOOD'        THEN 'PCT FLOOD POOL'
                  WHEN 'TS_PCT_CON'          THEN 'PCT CON POOL'
                  WHEN 'TS_IRRAD'            THEN 'IRRADIANCE'
                  WHEN 'TS_EVAP'             THEN 'EVAPORATION'
               END ts_type
          FROM at_published_ts
       ) pts
      , at_a2w_attributes attr
      , cwms_v_ts_id tsi
      , cwms_v_loc l
 WHERE pts.ts_type IS NOT NULL
   AND attr.location_code = pts.location_code
   AND attr.display_flag = 'T'
   AND pts.ts_code = tsi.ts_code
   AND pts.location_code = l.location_code
   AND l.unit_System = 'EN';
/

begin
	execute immediate 'grant select on av_a2w_ts_codes_by_loc2 to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_a2w_ts_codes_by_loc2 for av_a2w_ts_codes_by_loc2;

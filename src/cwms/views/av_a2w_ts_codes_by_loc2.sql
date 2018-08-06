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
CREATE OR REPLACE FORCE VIEW "CWMS_20"."AV_A2W_TS_CODES_BY_LOC2" ("TS_CODE", "LOCATION_CODE", "LOCATION_ID", "TS_TYPE", "CWMS_TS_ID", "UNIT_ID", "BASE_PARAMETER_ID", "DB_OFFICE_ID") AS 
  SELECT a2w.ts_code, a2w.location_code, l.location_id, a2w.ts_type, tsi.cwms_ts_id, tsi.unit_id,  tsi.base_parameter_id, tsi.db_Office_id
  FROM (
        SELECT a2w.ts_code_elev ts_code, a2w.location_code, 'ELEV' ts_type
          FROM at_a2w_Ts_codes_By_loc a2w
         WHERE ts_code_Elev IS NOT NULL
           AND display_flag = 'T'
       UNION ALL
        SELECT a2w.ts_code_precip ts_code, a2w.location_code, 'PRECIP' ts_type
          FROM at_a2w_Ts_codes_By_loc a2w
         WHERE a2w.ts_code_precip IS NOT NULL
           AND display_flag = 'T'
        UNION ALL
        SELECT a2w.ts_code_stage ts_code, a2w.location_code, 'STAGE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_stage IS NOT NULL
           AND display_flag = 'T'
        UNION ALL
        SELECT a2w.ts_code_inflow ts_code, a2w.location_code, 'INFLOW' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_inflow IS NOT NULL
           AND display_flag = 'T'
       UNION ALL
        SELECT a2w.ts_code_outflow ts_code, a2w.location_code, 'OUTFLOW' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_outflow IS NOT NULL
           AND display_flag = 'T'
      UNION ALL
        SELECT a2w.ts_code_sur_release ts_code, a2w.location_code, 'SURCHARGE RELEASE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_sur_release IS NOT NULL
           AND display_flag = 'T'
       UNION ALL
        SELECT a2w.ts_code_stor_flood ts_code, a2w.location_code, 'FLOOD STORAGE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_stor_flood IS NOT NULL
           AND display_flag = 'T'
      UNION ALL
        SELECT a2w.ts_code_stor_Drought ts_code, a2w.location_code, 'CONSERVATION STORAGE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_stor_Drought IS NOT NULL
          AND display_flag = 'T'
      UNION ALL
        SELECT a2w.ts_code_elev_tw ts_code, a2w.location_code, 'ELEV TAILWATER' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_elev_tw IS NOT NULL
          AND display_flag = 'T'
      UNION ALL
        SELECT a2w.ts_code_stage_tw ts_code, a2w.location_code, 'STAGE TAILWATER' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_stage_tw IS NOT NULL
          AND display_flag = 'T'
      UNION ALL
        SELECT a2w.ts_code_rule_curve_elev ts_code, a2w.location_code, 'ELEV RULE CURVE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_rule_curve_elev IS NOT NULL
          AND display_flag = 'T'
      UNION ALL
        SELECT a2w.TS_CODE_POWER_GEN ts_code, a2w.location_code, 'POWER GENERATION' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_POWER_GEN      IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_TEMP_AIR ts_code, a2w.location_code, 'AIR TEMPERATURE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_TEMP_AIR              IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_TEMP_WATER ts_code, a2w.location_code, 'WATER TEMPERATURE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_TEMP_WATER                    IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_DO ts_code, a2w.location_code, 'DISOLVED OXYGEN' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_DO                                  IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_COND ts_code, a2w.location_code, 'CONDUCTIVITY' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_COND                                  IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_PH ts_code, a2w.location_code, 'PH' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_PH                                 IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_WIND_DIR ts_code, a2w.location_code, 'WIND DIRECTION' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_WIND_DIR  IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_WIND_SPEED ts_code, a2w.location_code, 'WIND SPEED' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_WIND_SPEED                                 IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_OPENING ts_code, a2w.location_code, 'OPENING' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_OPENING  IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.TS_CODE_VOLT ts_code, a2w.location_code, 'VOLTAGE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.TS_CODE_VOLT                                IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.ts_code_pct_flood       ts_code, a2w.location_code, 'PCT FLOOD POOL' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_pct_flood      IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.ts_code_pct_con       ts_code, a2w.location_code, 'PCT CON POOL' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_pct_con     IS NOT NULL
          AND display_flag = 'T'
    UNION ALL
        SELECT a2w.ts_code_irrad      ts_code, a2w.location_code, 'IRRADIANCE' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_irrad     IS NOT NULL
          AND display_flag = 'T'
     UNION ALL
        SELECT a2w.ts_code_evap       ts_code, a2w.location_code, 'EVAPORATION' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_evap     IS NOT NULL
          AND display_flag = 'T'
      ) a2w
      , cwms_v_ts_id tsi
      , cwms_v_loc l
 WHERE a2w.ts_code = tsi.ts_code
   AND a2w.location_code = l.location_code
   AND l.unit_System = 'EN';
/

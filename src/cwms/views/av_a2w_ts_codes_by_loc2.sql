insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_A2W_TS_CODES_BY_LOC', null,
'
/**
 * Displays A2W_TS_CODES_BY_LOC information
 *
 * @since CWMS 3.0 
 *
 * @field ts_code                The selected ts code
 * @field location_code           The location code of the UR/A2W location
 * @field locatioN_id             The location ID of A2W Location this TS Code is associated   to (it could be different then the location ID of the TS Code)
 * @field ts_type                 The A2W TS Type  (elevation, stage, etc)
 * @field cwms_ts_id              The CWMS TS ID
 * @field unit_id                 The DB units of the TS Code
 * @field base_parameter_id       The base parameter ID of the TS Code
 * @field db_office_id            The DB Office of the location and TS Code
 
');
create or replace force view av_a2w_ts_codes_by_loc2
(
   ts_code,
   location_code,
   locatioN_id,
   ts_type,
   cwms_ts_id,
   unit_id,
   base_parameter_id,
   db_office_id
)
as
    SELECT a2w.ts_code, a2w.location_code, tsi.location_id, a2w.ts_type, tsi.cwms_ts_id, tsi.unit_id,  tsi.base_parameter_id, tsi.db_Office_id
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
        SELECT a2w.ts_code_stage_elev ts_code, a2w.location_code, 'ELEV TAILWATER' ts_type
          FROM at_a2w_ts_codes_by_loc a2w 
         WHERE a2w.ts_code_stage_elev IS NOT NULL
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
      ) a2w
      , cwms_v_ts_id tsi
 WHERE a2w.ts_code = tsi.ts_code;
/

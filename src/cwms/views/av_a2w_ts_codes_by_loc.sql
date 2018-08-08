insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_A2W_TS_CODES_BY_LOC', null,
'
/**
 * Displays A2W_TS_CODES_BY_LOC information
 *
 * @since CWMS 2.1
 *
 * @field LOCATION_ID                The...
 * @field DB_OFFICE_ID               The...
 * @field TS_CODE_ELEV               The...
 * @field TS_CODE_PRECIP             The...
 * @field TS_CODE_STAGE              The...
 * @field TS_CODE_INFLOW             The...
 * @field TS_CODE_OUTFLOW            The...
 * @field DATE_REFRESHED             The...
 * @field TS_CODE_STOR_FLOOD         The...
 * @field NOTES                      The...
 * @field DISPLAY_FLAG               The...
 * @field NUM_TS_CODES               The...
 * @field TS_CODE_STOR_DROUGHT       The...
 * @field LAKE_SUMMARY_TF            The...
 * @field TS_CODE_SUR_RELEASE        The...
 * @field LOCATION_CODE              The Location Code (Used to uniquely identify this location in the database).
 */
');
create or replace force view av_a2w_ts_codes_by_loc
(
   location_id,
   db_office_id,
   ts_code_elev,
   ts_code_precip,
   ts_code_stage,
   ts_code_inflow,
   ts_code_outflow,
   date_refreshed,
   ts_code_stor_flood,
   notes,
   display_flag,
   num_ts_codes,
   ts_code_stor_drought,
   lake_summary_tf,
   ts_code_sur_release,
   location_code,
   ts_code_elev_tw,
   ts_code_stage_tw,
   ts_code_rule_curve_elev,
   TS_CODE_POWER_GEN ,
   TS_CODE_TEMP_AIR ,
   TS_CODE_TEMP_WATER ,      
   TS_CODE_DO             ,  
   ts_code_PH,
   ts_code_cond,
   RATING_CODE_ELEV_STOR  
)
as
   select l.location_id,
          l.db_office_id,
          a2w.ts_code_elev,
          a2w.ts_code_precip,
          a2w.ts_code_stage,
          a2w.ts_code_inflow,
          a2w.ts_code_outflow,
          a2w.date_refreshed,
          a2w.ts_code_stor_flood,
          a2w.notes,
          a2w.display_flag,
          a2w.num_ts_codes,
          a2w.ts_code_stor_drought,
          a2w.lake_summary_tf,
          a2w.ts_code_sur_release,
          l.location_code,
          a2w.ts_code_elev_tw,
          a2w.ts_code_stage_tw,
          a2w.ts_code_rule_curve_elev,
   a2w.TS_CODE_POWER_GEN       ,
   a2w.TS_CODE_TEMP_AIR        ,
   a2w.TS_CODE_TEMP_WATER      ,
   a2w.TS_CODE_DO              ,
   a2w.ts_code_ph             ,
   a2w.ts_code_cond,
   a2w.RATING_CODE_ELEV_STOR   
     from at_a2w_ts_codes_by_loc a2w
        , av_loc l 
    where a2w.location_code = l.location_code
      AND l.unit_system = 'SI'
/

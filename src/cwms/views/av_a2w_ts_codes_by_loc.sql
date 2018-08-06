insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_A2W_TS_CODES_BY_LOC', null,
'
/**
 * Displays A2W_TS_CODES_BY_LOC information
 *
 * @since CWMS 2.1
 *
 * @field LOCATION_ID                The CWMS Location ID (from cwms_v_loc) of the location
 * @field DB_OFFICE_ID               The DB Office ID for the location
 * @field TS_CODE_ELEV               The TSC to show elevation at a location
 * @field TS_CODE_PRECIP             The TSC of precip at this location
 * @field TS_CODE_STAGE              The TSC to show stage at location
 * @field TS_CODE_INFLOW             The TSC to show inflow into a project
 * @field TS_CODE_OUTFLOW            The TSC to show outflow from a project or flow through a streamgage
 * @field DATE_REFRESHED             The date last refreshed
 * @field TS_CODE_STOR_FLOOD         The TSC of a projects storage. A value here indicates the project has a flood control mission.
 * @field NOTES                      Misc. Notes
 * @field DISPLAY_FLAG               The display flag to display this location in A2W. T = display. F = do not display.
 * @field NUM_TS_CODES               The number of TS codes shared at this location
 * @field TS_CODE_STOR_DROUGHT       The TSC of a projects storage. A value here indicates the project has a water conservation mission.
 * @field LAKE_SUMMARY_TF            The Lake Summary TF flag indicates if the location should be grouped in the lake summary reports
 * @field TS_CODE_SUR_RELEASE        The TSC of the projects surcharge release
 * @field LOCATION_CODE              The Location Code (Used to uniquely identify this location in the database).
 * @field TS_CODE_ELEV_TW            The TSC to show tailwater elevation at a location
 * @field TS_CODE_STAGE_TW           The TSC to show tailwater stage at a location
 * @field TS_CODE_RULE_CURVE_ELEV    The TSC to show a elevation Rule or Guide Curve
 * @field TS_CODE_DO                 The TSC to show dissolved oxygen at a location
 * @field TS_CODE_PH                 The TSC to show pH at a location
 * @field TS_CODE_COND               The TSC to show Conductivity at a location
 * @field TS_CODE_WIND_DIR           The TSC to show Wind Direction at a location
 * @field TS_CODE_WIND_SPEED         The TSC to show Wind Speed at a location
 * @field TS_CODE_VOLT               The TSC to show voltage at a location
 * @field TS_CODE_PCT_FLOOD          The TSC to show Calculated Flood Pool Percentage at a location.
 * @field TS_CODE_PCT_CON            The TSC to show Calculated Conservation Pool Percentage at a location.
 * @field RATING_CODE_ELEV_STOR      The Rating Code of the elevation to storage curve for the location
 * @field TS_CODE_IRRAD              The TSC to show Irradaiance at a location (amount of sunlight).
 * @field TS_CODE_EVAP               The TSC to show Evaporations at a location.
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
   ts_code_stor_flood,
   date_refreshed,
   notes,
   display_flag,
   num_ts_codes,
   ts_code_stor_drought   ,
   lake_summary_tf        ,
   ts_code_sur_release    ,
   location_code          ,
   ts_code_elev_tw        ,
   ts_code_stage_tw       ,
   ts_code_rule_curve_elev,
   TS_CODE_POWER_GEN      ,
   TS_CODE_TEMP_AIR       ,
   TS_CODE_TEMP_WATER     ,      
   TS_CODE_DO             ,  
   ts_code_PH             ,
   ts_code_cond           ,
   ts_code_opening        ,
   ts_code_Wind_dir       ,
   ts_code_wind_speed     ,
   ts_code_volt	          ,    
   ts_code_pct_flood      ,   
   ts_code_pct_con        ,  
   RATING_CODE_ELEV_STOR  ,
   RATING_CODE_ELEV_AREA  ,
   RATING_CODE_OUTLET_FLOW,
   opening_Source_Obj     ,
   ts_code_irrad          ,
   ts_code_evap		  
)
as
   select l.location_id            ,
          l.db_office_id           ,
          a2w.ts_code_elev         ,
          a2w.ts_code_precip       ,
          a2w.ts_code_stage        ,
          a2w.ts_code_inflow       ,
          a2w.ts_code_outflow      ,
          a2w.ts_code_stor_flood   ,
          a2w.date_refreshed       ,
          a2w.notes                ,
          a2w.display_flag         ,
          a2w.num_ts_codes         ,
          a2w.ts_code_stor_drought    ,
          a2w.lake_summary_tf         ,
          a2w.ts_code_sur_release     ,
          l.location_code             ,
          a2w.ts_code_elev_tw         ,
          a2w.ts_code_stage_tw        ,
          a2w.ts_code_rule_curve_elev ,
          a2w.TS_CODE_POWER_GEN       ,
          a2w.TS_CODE_TEMP_AIR        ,
          a2w.TS_CODE_TEMP_WATER      ,
          a2w.TS_CODE_DO              ,
          a2w.ts_code_ph              ,
          a2w.ts_code_cond            ,
          a2w.ts_code_opening         ,
          a2w.ts_code_Wind_dir        ,
          a2w.ts_code_wind_Speed      ,
          a2w.ts_code_volt            ,
          a2w.ts_code_pct_flood       ,
          a2w.ts_code_pct_con         ,
          a2w.RATING_CODE_ELEV_STOR   ,
          a2w.rating_code_elev_area   ,
          a2w.rating_code_outlet_Flow ,
          a2w.opening_Source_Obj      ,
          a2w.ts_code_irrad           ,
          a2w.ts_code_evap
     from at_a2w_ts_codes_by_loc a2w
        , av_loc l 
    where a2w.location_code = l.location_code
      AND l.unit_system = 'SI'
/

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
   -- Sourced from the normalized AT_PUBLISHED_TS / AT_PUBLISHED_RATING / AT_A2W_ATTRIBUTES
   -- tables (see at_published.sql, at_a2w_attributes.sql) instead of the retired wide
   -- AT_A2W_TS_CODES_BY_LOC columns, to preserve this view's shape for existing consumers
   -- (CDA's PublishedTimeSeriesDao, CMA reports) while the underlying schema is normalized.
   --
   -- Known behavior change vs. the old wide table: TS_CODE_OPENING here only ever holds a
   -- real TS Code. Rows where OPENING_SOURCE_OBJ = 'OBJ' (the opening value is an object
   -- reference, not a TS Code) are not present in AT_PUBLISHED_TS - see the "known gap" note
   -- in migrate_a2w_to_published.sql - so TS_CODE_OPENING will be NULL for those locations
   -- even though OPENING_SOURCE_OBJ = 'OBJ'.
   select l.location_id            ,
          l.db_office_id           ,
          ts.ts_code_elev          ,
          ts.ts_code_precip        ,
          ts.ts_code_stage         ,
          ts.ts_code_inflow        ,
          ts.ts_code_outflow       ,
          ts.ts_code_stor_flood    ,
          attr.date_refreshed      ,
          attr.notes               ,
          attr.display_flag        ,
          ts.num_ts_codes          ,
          ts.ts_code_stor_drought     ,
          attr.lake_summary_tf        ,
          ts.ts_code_sur_release      ,
          l.location_code             ,
          ts.ts_code_elev_tw          ,
          ts.ts_code_stage_tw         ,
          ts.ts_code_rule_curve_elev  ,
          ts.TS_CODE_POWER_GEN        ,
          ts.TS_CODE_TEMP_AIR         ,
          ts.TS_CODE_TEMP_WATER       ,
          ts.TS_CODE_DO               ,
          ts.ts_code_ph               ,
          ts.ts_code_cond             ,
          ts.ts_code_opening          ,
          ts.ts_code_Wind_dir         ,
          ts.ts_code_wind_Speed       ,
          ts.ts_code_volt             ,
          ts.ts_code_pct_flood        ,
          ts.ts_code_pct_con          ,
          rt.RATING_CODE_ELEV_STOR    ,
          rt.rating_code_elev_area    ,
          rt.rating_code_outlet_Flow  ,
          attr.opening_Source_Obj     ,
          ts.ts_code_irrad            ,
          ts.ts_code_evap
     from at_a2w_attributes attr
        , av_loc l
        , (select location_code,
                  count(*) as num_ts_codes,
                  max(case when published_id = 'TS_ELEV' then ts_code end) as ts_code_elev,
                  max(case when published_id = 'TS_PRECIP' then ts_code end) as ts_code_precip,
                  max(case when published_id = 'TS_STAGE' then ts_code end) as ts_code_stage,
                  max(case when published_id = 'TS_INFLOW' then ts_code end) as ts_code_inflow,
                  max(case when published_id = 'TS_OUTFLOW' then ts_code end) as ts_code_outflow,
                  max(case when published_id = 'TS_STOR_FLOOD' then ts_code end) as ts_code_stor_flood,
                  max(case when published_id = 'TS_STOR_DROUGHT' then ts_code end) as ts_code_stor_drought,
                  max(case when published_id = 'TS_SUR_RELEASE' then ts_code end) as ts_code_sur_release,
                  max(case when published_id = 'TS_ELEV_TW' then ts_code end) as ts_code_elev_tw,
                  max(case when published_id = 'TS_STAGE_TW' then ts_code end) as ts_code_stage_tw,
                  max(case when published_id = 'TS_RULE_CURVE_ELEV' then ts_code end) as ts_code_rule_curve_elev,
                  max(case when published_id = 'TS_POWER_GEN' then ts_code end) as ts_code_power_gen,
                  max(case when published_id = 'TS_TEMP_AIR' then ts_code end) as ts_code_temp_air,
                  max(case when published_id = 'TS_TEMP_WATER' then ts_code end) as ts_code_temp_water,
                  max(case when published_id = 'TS_DO' then ts_code end) as ts_code_do,
                  max(case when published_id = 'TS_PH' then ts_code end) as ts_code_ph,
                  max(case when published_id = 'TS_COND' then ts_code end) as ts_code_cond,
                  max(case when published_id = 'TS_OPENING' then ts_code end) as ts_code_opening,
                  max(case when published_id = 'TS_WIND_DIR' then ts_code end) as ts_code_wind_dir,
                  max(case when published_id = 'TS_WIND_SPEED' then ts_code end) as ts_code_wind_speed,
                  max(case when published_id = 'TS_VOLT' then ts_code end) as ts_code_volt,
                  max(case when published_id = 'TS_PCT_FLOOD' then ts_code end) as ts_code_pct_flood,
                  max(case when published_id = 'TS_PCT_CON' then ts_code end) as ts_code_pct_con,
                  max(case when published_id = 'TS_IRRAD' then ts_code end) as ts_code_irrad,
                  max(case when published_id = 'TS_EVAP' then ts_code end) as ts_code_evap
             from at_published_ts
            group by location_code
          ) ts
        , (select location_code,
                  max(case when published_id = 'RATING_ELEV_STOR' then rating_spec_code end) as rating_code_elev_stor,
                  max(case when published_id = 'RATING_ELEV_AREA' then rating_spec_code end) as rating_code_elev_area,
                  max(case when published_id = 'RATING_OUTLET_FLOW' then rating_spec_code end) as rating_code_outlet_flow
             from at_published_rating
            group by location_code
          ) rt
    where attr.location_code = l.location_code
      and ts.location_code (+) = attr.location_code
      and rt.location_code (+) = attr.location_code
      AND l.unit_system = 'SI'
/
begin
	execute immediate 'grant select on av_a2w_ts_codes_by_loc to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_a2w_ts_codes_by_loc for av_a2w_ts_codes_by_loc;

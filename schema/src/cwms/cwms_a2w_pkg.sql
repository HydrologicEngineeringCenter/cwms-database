create or replace package cwms_a2w
as
   ------------------------------------------------------------------------------
   -- Maintains the Access to Water (A2W) publication settings for a location:
   -- AT_A2W_ATTRIBUTES (notes / display flag / lake summary flag / opening source)
   -- and the AT_PUBLISHED_TS / AT_PUBLISHED_RATING mappings.
   --
   -- These procedures used to live only in CWMS_CMA. They were moved here because
   -- CWMS_CMA depends on Oracle APEX and is not installed by the schema build, so
   -- nothing in it can be tested in CI. CWMS_CMA keeps its procedures with the same
   -- names and signatures and simply calls these.
   --
   -- Parameter types are plain VARCHAR2 / NUMBER / CLOB (matching the old
   -- AT_A2W_TS_CODES_BY_LOC column types) so nothing here depends on that table.
   ------------------------------------------------------------------------------

   ------------------------------------------------------------------------------
   -- Saves the A2W attributes and every published TS / rating slot for one
   -- location. A NULL ts/rating code clears that slot. P_NUM_TS_CODES is accepted
   -- for backward compatibility but ignored (AV_A2W_TS_CODES_BY_LOC derives it).
   -- Errors are returned in P_ERROR_MSG rather than raised.
   ------------------------------------------------------------------------------
   procedure p_load_a2w_by_location (
      p_db_office_id            in  varchar2,
      p_location_id             in  varchar2,
      p_display_flag            in  varchar2,
      p_notes                   in  clob,
      p_num_ts_codes            in  number,
      p_ts_code_elev            in  number,
      p_ts_code_inflow          in  number,
      p_ts_code_outflow         in  number,
      p_ts_code_sur_release     in  number,
      p_ts_code_precip          in  number,
      p_ts_code_stage           in  number,
      p_ts_code_stor_drought    in  number,
      p_ts_code_stor_flood      in  number,
      p_ts_code_elev_tw         in  number,
      p_ts_code_stage_tw        in  number,
      p_ts_code_rule_curve_elev in  number,
      p_ts_code_power_gen       in  number,
      p_ts_code_temp_air        in  number,
      p_ts_code_temp_water      in  number,
      p_ts_code_do              in  number,
      p_ts_code_ph              in  number,
      p_ts_code_cond            in  number,
      p_ts_code_wind_dir        in  number,
      p_ts_code_wind_speed      in  number,
      p_ts_code_volt            in  number,
      p_ts_code_pct_flood       in  number,
      p_ts_code_pct_con         in  number,
      p_ts_code_irrad           in  number,
      p_ts_code_evap            in  number,
      p_rating_code_elev_stor   in  number,
      p_rating_code_elev_area   in  number,
      p_rating_code_outlet_flow in  number,
      p_ts_code_opening         in  number,
      p_opening_source_obj      in  varchar2,
      p_lake_summary_tf         in  varchar2,
      p_error_msg               out varchar2);

   ------------------------------------------------------------------------------
   -- Removes a ts_code from every published slot it occupies, then re-runs
   -- p_set_a2w_num_tsids for the location(s) that own that time series.
   ------------------------------------------------------------------------------
   procedure p_clear_a2w_ts_code (
      p_ts_code in number);

   ------------------------------------------------------------------------------
   -- Stamps the location's AT_A2W_ATTRIBUTES notes, and sets DISPLAY_FLAG to F
   -- when the location has no displayable published time series left.
   ------------------------------------------------------------------------------
   procedure p_set_a2w_num_tsids (
      p_db_office_id  in varchar2,
      p_location_code in number,
      p_user_id       in varchar2);

   ------------------------------------------------------------------------------
   -- Creates an AT_A2W_ATTRIBUTES row for each active, non-stream/basin location
   -- of the office that does not have one yet (or only for P_LOCATION_CODE).
   ------------------------------------------------------------------------------
   procedure p_add_missing_a2w_rows (
      p_db_office_id  in varchar2,
      p_location_code in number default null,
      p_user_id       in varchar2);

end cwms_a2w;
/
show errors

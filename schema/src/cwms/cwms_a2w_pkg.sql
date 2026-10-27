create or replace package cwms_a2w
/**
 * Maintains the Access to Water (A2W) publication settings for a location:
 * AT_A2W_ATTRIBUTES (notes / display flag / lake summary flag / opening source)
 * and the AT_PUBLISHED_TS / AT_PUBLISHED_RATING mappings.
 *
 * These procedures used to live only in CWMS_CMA. They were moved here because
 * CWMS_CMA depends on Oracle APEX and is not installed by the schema build, so
 * nothing in it can be tested in CI. CWMS_CMA keeps its procedures with the same
 * names and signatures and simply calls these.
 *
 * Parameter types are plain VARCHAR2 / NUMBER / CLOB (matching the old
 * AT_A2W_TS_CODES_BY_LOC column types) so nothing here depends on that table.
 */
as

   /**
    * Populates AT_PUBLISHED_xxx tables used for A2W for a specified location.
    * Specifying NULL for any of the P_Xxx_Code parameters will delete any previously populated row for that parameter for the location.cursor
    * Errors are returned in p_error_msg instead of being raised.
    *
    * @param p_db_office_id            The text identifier of the office that owns the location that is being populated
    * @param p_location_id             The text identifier of the location that is being populated
    * @param p_display_flag            A flag ('T'/'F') specifying whether location should be displayed in the location hierarchy
    * @param p_notes                   Notes associated with this operation
    * @param p_num_ts_codes            Unused. For backward compatibility of signature only.
    * @param p_ts_code_elev            Numeric code of time series to publish as 'Elevation Time Series' for this location
    * @param p_ts_code_inflow          Numeric code of time series to publish as 'Inflow Time Series' for this location
    * @param p_ts_code_outflow         Numeric code of time series to publish as 'Outflow Time Series' for this location
    * @param p_ts_code_sur_release     Numeric code of time series to publish as 'Surcharge Release Time Series' for this location
    * @param p_ts_code_precip          Numeric code of time series to publish as 'Precipitation Time Series' for this location
    * @param p_ts_code_stage           Numeric code of time series to publish as 'Stage Time Series' for this location
    * @param p_ts_code_stor_drought    Numeric code of time series to publish as 'Drought Storage Time Series' for this location
    * @param p_ts_code_stor_flood      Numeric code of time series to publish as 'Flood Storage Time Series' for this location
    * @param p_ts_code_elev_tw         Numeric code of time series to publish as 'Tailwater Elevation Time Series' for this location
    * @param p_ts_code_stage_tw        Numeric code of time series to publish as 'Tailwater Stage Time Series' for this location
    * @param p_ts_code_rule_curve_elev Numeric code of time series to publish as 'Rule Curve Elevation Time Series' for this location
    * @param p_ts_code_power_gen       Numeric code of time series to publish as 'Power Generation Time Series' for this location
    * @param p_ts_code_temp_air        Numeric code of time series to publish as 'Air Temperature Time Series' for this location
    * @param p_ts_code_temp_water      Numeric code of time series to publish as 'Water Temperature Time Series' for this location
    * @param p_ts_code_do              Numeric code of time series to publish as 'Dissolved Oxygen Time Series' for this location
    * @param p_ts_code_ph              Numeric code of time series to publish as 'pH Time Series' for this location
    * @param p_ts_code_cond            Numeric code of time series to publish as 'Conductivity Time Series' for this location
    * @param p_ts_code_wind_dir        Numeric code of time series to publish as 'Wind Direction Time Series' for this location
    * @param p_ts_code_wind_speed      Numeric code of time series to publish as 'Wind Speed Time Series' for this location
    * @param p_ts_code_volt            Numeric code of time series to publish as 'Voltage Time Series' for this location
    * @param p_ts_code_pct_flood       Numeric code of time series to publish as 'Flood Percent Time Series' for this location
    * @param p_ts_code_pct_con         Numeric code of time series to publish as 'Conservation Percent Time Series' for this location
    * @param p_ts_code_irrad           Numeric code of time series to publish as 'Solar Irradiance Time Series' for this location
    * @param p_ts_code_evap            Numeric code of time series to publish as 'Evaporation Time Series' for this location
    * @param p_rating_code_elev_stor   Numeric code of rating to publish as 'Elevation-Storage Rating' for this location
    * @param p_rating_code_elev_area   Numeric code of rating to publish as 'Elevation-Area Rating' for this location
    * @param p_rating_code_outlet_flow Numeric code of rating to publish as 'Outlet Flow Rating' for this location
    * @param p_ts_code_opening         Numeric code of time series to publish as 'Opening Time Series' for this location
    * @param p_opening_source_obj      A flag ('T'/'F') specifying whether p_ts_code_opening is an object instead of a time series code
    * @param p_lake_summary_tf         A flag ('T'/'F') specifying whether a lake summary is to be created for this location
    * @param p_error_msg               Any error messages that arise during calling this routine
    */
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

   /**
    * Removes a ts_code from every published slot it occupies, then re-runs
    * p_set_a2w_num_tsids for the location(s) that own that time series.
    *
    * @param p_ts_code The ts_code to remove from all published slots
    */
   procedure p_clear_a2w_ts_code (
      p_ts_code in number);

   /**
    * Sets the DATE_REFRESHED and appends to NOTES columsn in AT_A2W_ATTRIBUTES table.
    * Also sets the DISPLAY_FLAG to 'F' if location has no published time series
    *
    * @param p_db_office_id  The ID of the office that owns the location to update (could be deterined programmatically)
    * @param p_location_code The numeric code of the location to update
    * @param p_user_id       The user to put in the update to NOTES column
    */
   procedure p_set_a2w_num_tsids (
      p_db_office_id  in varchar2,
      p_location_code in number,
      p_user_id       in varchar2);

   /**
    * Creates an AT_A2W_ATTRIBUTES row for the specified location. If p_location is NULL, creates a row for each active, non-stream/basin location
    * of the specified office that does not have one yet.
    *
    * @param p_db_office_id
    * @param p_location_code The numeric code of the location to create the row for. If NULL, a row is creaded  each active, non-stream/basin location
    *                        of the specified office that does not have one yet.
    * @param p_user_id       Unused. For backward compatibility of signature only.
    */
   procedure p_add_missing_a2w_rows (
      p_db_office_id  in varchar2,
      p_location_code in number,
      p_user_id       in varchar2);

end cwms_a2w;
/
show errors

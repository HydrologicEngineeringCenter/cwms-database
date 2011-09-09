create or replace package cwms_forecast
/**
 * Routines for dealing with forecasts or other model runs
 *
 * @since CWMS 2.1
 *
 * @author Mike Perryman
 */
as
-- not documented
function get_forecast_spec_code(
   p_location_id in varchar2,
   p_forecast_id in varchar2,
   p_office_id   in varchar2 default null) -- null = user's office id
   return number;
/**
 * Stores (inserts or updates) a forecast specification to the database
 *
 * @param p_location_id    The forecast location identifier
 * @param p_forecast_id    The forecast identifier
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the forecast specification already exists in the database
 * @param p_ignore_nulls   A flag ('T' or 'F') that specifies whether to ignore NULL values when updating an existing forecast specification.  If 'T' no data will be overwritten by a NULL
 * @param p_source_agency  The agency that supplies forecasts under this spcecification
 * @param p_source_office  The office within the source agency that supplies forecasts under this spcecification
 * @param p_valid_lifetime The number of hours that a forecast under this specification is considered to be current
 * @param p_forecast_type  The forecast type as determined by the source agency, if applicable
 * @param p_source_loc_id  The location that is the source for forecasts under this specification, if applicable
 * @param p_office_id      The office that owns the forecast specification.  If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the forecast specification already exists in the database
 */
procedure store_spec(
   p_location_id    in varchar2,
   p_forecast_id    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_source_agency  in varchar2,
   p_source_office  in varchar2,
   p_valid_lifetime in integer, -- in hours
   p_forecast_type  in varchar2 default null,  -- null = null
   p_source_loc_id  in varchar2 default null,  -- null = null
   p_office_id      in varchar2 default null); -- null = user's office id
/**
 * Retieves a forecast specification from the database
 *
 * @param p_source_agency  The agency that supplies forecasts under this spcecification
 * @param p_source_office  The office within the source agency that supplies forecasts under this spcecification
 * @param p_valid_lifetime The number of hours that a forecast under this specification is considered to be current
 * @param p_forecast_type  The forecast type as determined by the source agency, if applicable
 * @param p_source_loc_id  The location that is the source for forecasts under this specification, if applicable
 * @param p_location_id    The forecast location identifier
 * @param p_forecast_id    The forecast identifier
 * @param p_office_id      The office that owns the forecast specification.  If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_spec(
   p_source_agency  out varchar2,
   p_source_office  out varchar2,
   p_valid_lifetime out integer, -- in hours
   p_forecast_type  out varchar2,
   p_source_loc_id  out varchar2,
   p_location_id    in  varchar2,
   p_forecast_id    in  varchar2,
   p_office_id      in  varchar2 default null); -- null = user's office id
/**
 * Deletes a forecast specification from the database
 *
 * @param p_location_id    The forecast location identifier
 * @param p_forecast_id    The forecast identifier
 * @param p_delete_action  Specifies what to delete. Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the forcast specification, and then only if it has no forecast time series or text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only the forecast time series and text under this forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes the forecast specification and all forecast timeseries and text under it</td>
 *   </tr>
 * </table>
 * @param p_office_id      The office that owns the forecast specification.  If not specified or NULL, the session user's default office is used.
 */
procedure delete_spec(
   p_location_id    in varchar2,
   p_forecast_id    in varchar2,
   p_delete_action  in varchar2 default cwms_util.delete_key,
   p_office_id      in varchar2 default null); -- null = user's office id
/**
 * Renames an existing forecast specification from the database
 *
 * @param p_location_id      The forecast location identifier
 * @param p_old_forecast_id  The existing forecast identifier
 * @param p_new_forecast_id  The new forecast identifier
 * @param p_office_id        The office that owns the forecast specification.  If not specified or NULL, the session user's default office is used.
 */
procedure rename_spec(
   p_location_id     in varchar2,
   p_old_forecast_id in varchar2,
   p_new_forecast_id in varchar2,
   p_office_id       in varchar2 default null); -- null = user's office id
/**
 * Catalogs forecast specifications that match the specified parameters.Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_spec_catalog A cursor containing all matching forecast specifications.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">forecast_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The forecast identifier of the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">source_agency</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The agency that supplies forecasts under this spcecification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">source_office</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office within the source agency that supplies forecasts under this spcecification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">valid_lifetime</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The number of hours that a forecast under this specification is considered current</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">forecast_type</td>
 *     <td class="descr">varchar2(5)</td>
 *     <td class="descr">The forecast type as determined by the source agency</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">source_loc_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location that is the source for forecasts under this specification</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask  The location identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_forecast_id_mask  The forecast identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_source_agency_mask  The source agency pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_source_office_mask  The source office pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_forecast_type_mask  The forecast type pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_source_loc_id_mask  The source location identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_specs(
   p_spec_catalog       out sys_refcursor,
   p_location_id_mask   in  varchar2 default '*',
   p_forecast_id_mask   in  varchar2 default '*',
   p_source_agency_mask in  varchar2 default '*',
   p_source_office_mask in  varchar2 default '*',
   p_forecast_type_mask in  varchar2 default '*',
   p_source_loc_id_mask in  varchar2 default '*',
   p_office_id_mask     in  varchar2 default null); -- null = user's office id
/**
 * Catalogs forecast specifications that match the specified parameters.Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask  The location identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_forecast_id_mask  The forecast identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_source_agency_mask  The source agency pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_source_office_mask  The source office pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_forecast_type_mask  The forecast type pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_source_loc_id_mask  The source location identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching forecast specifications.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">forecast_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The forecast identifier of the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">source_agency</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The agency that supplies forecasts under this spcecification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">source_office</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office within the source agency that supplies forecasts under this spcecification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">valid_lifetime</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The number of hours that a forecast under this specification is considered current</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">forecast_type</td>
 *     <td class="descr">varchar2(5)</td>
 *     <td class="descr">The forecast type as determined by the source agency</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">source_loc_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location that is the source for forecasts under this specification</td>
 *   </tr>
 * </table>
 */
function cat_specs_f(
   p_location_id_mask   in varchar2 default '*',
   p_forecast_id_mask   in varchar2 default '*',
   p_source_agency_mask in varchar2 default '*',
   p_source_office_mask in varchar2 default '*',
   p_forecast_type_mask in varchar2 default '*',
   p_source_loc_id_mask in varchar2 default '*',
   p_office_id_mask     in varchar2 default null) -- null = user's office id
   return sys_refcursor;
/**
 * Stores (inserts or updates) a single time series for a forecast to the database
 *
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_cwms_ts_id      The time series identifier
 * @param p_units           The unit of the time series values
 * @param p_forecast_time   The forecast time
 * @param p_issue_time      The time the forecast was issued
 * @param p_version_date    The version date for the time series
 * @param p_time_zone       The time zone for p_forecast_time, p_issue_time, p_verion_date, and p_timeseries_data
 * @param p_timeseries_data The time series data to store
 * @param p_fail_if_exists  A flag ('T' or 'F') that specifies whether the routine should fail if the forecast time series already exists in the database
 * @param p_store_rule      The store rule to use.  Same as for <a href="pkg_cwms_ts.html#procedure store_ts(p_cwms_ts_id in varchar2, p_units in varchar2, p_timeseries_data in tsv_array, p_store_rule in varchar2, p_override_prot in varchar2, p_version_date in date, p_office_id in varchar2)">cwms_ts.store_ts</a>
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the forecast time series exists in the database
 */
procedure store_ts(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_cwms_ts_id      in varchar2,
   p_units           in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_version_date    in date,
   p_time_zone       in varchar2,
   p_timeseries_data in ztsv_array,
   p_fail_if_exists  in varchar2,
   p_store_rule      in varchar2 default null,  -- null = DELETE INSERT
   p_office_id       in varchar2 default null); -- null = user's office id   
/**
 * Retrieves a single time series for a forecast from the database
 *
 * @param p_ts_cursor       The cursor of time series data. The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time of the value, in the specified time zone</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">value</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The time series value in the specified unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">quality_code</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The quality code of the time series value</td>
 *   </tr>
 * </table>
 * @param p_version_date    The version date for the time series
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_cwms_ts_id      The time series identifier
 * @param p_units           The unit of the time series values
 * @param p_forecast_time   The forecast time
 * @param p_issue_time      The time the forecast was issued
 * @param p_start_time      The start of the time window to retrieve. If not specified or NULL, the start of the time window is the start of the forecast time series
 * @param p_end_time        The end of the time window to retrieve. If not specified or NULL, the end of the time window is the end of the forecast time series
 * @param p_time_zone       The time zone for p_forecast_time, p_issue_time, p_start_time, and p_end_time, as well as for the retrieved time series data
 * @param p_trim            A flag ('T' or 'F') that specifies whether to trim missing values from the beginning and end of the time series data
 * @param p_start_inclusive A flag ('T' or 'F') that specifies whether the time window starts on or after p_start_time
 * @param p_end_inclusive   A flag ('T' or 'F') that specifies whether the time window ends on or before p_end_time
 * @param p_preivous        A flag ('T' or 'F') that specifies whether to retrieve the latest time series value before the start of the time window
 * @param p_next            A flag ('T' or 'F') that specifies whether to retrieve the earliest time series value after the end of the time window
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_ts(
   p_ts_cursor       out sys_refcursor,
   p_version_date    out date,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_cwms_ts_id      in  varchar2,
   p_units           in  varchar2,
   p_forecast_time   in  date,
   p_issue_time      in  date,
   p_start_time      in  date default null,
   p_end_time        in  date default null,
   p_time_zone       in  varchar2 default null, -- null = location time zone
   p_trim            in  varchar2 default 'F',
   p_start_inclusive in  varchar2 default 'T',
   p_end_inclusive   in  varchar2 default 'T',
   p_previous        in  varchar2 default 'F',
   p_next            in  varchar2 default 'F',
   p_office_id       in  varchar2 default null); -- null = user's office id   
/**
 * Deletes forecast time series from the database
 *
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_cwms_ts_id      The time series identifier. If not specified or NULL, time series for all time series identifiers is deleted
 * @param p_forecast_time   The forecast time. If not specified or NULL, time series for all forecast times is deleted
 * @param p_issue_time      The time the forecast was issued. If not specified or NULL, time series for all issue times is deleted
 * @param p_time_zone       The time zone for p_forecast_time and p_issue_time. If not specified or NULL, the local time zone for the location is used
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 */
procedure delete_ts(
   p_location_id   in varchar2,
   p_forecast_id   in varchar2,
   p_cwms_ts_id    in varchar2,               -- null = all time series
   p_forecast_time in date,                   -- null = all forecast times
   p_issue_time    in date,                   -- null = all issue times
   p_time_zone     in varchar2 default null,  -- null = location time zone
   p_office_id     in varchar2 default null); -- null = user's office id   

--------------------------------------------------------------------------------
-- procedure cat_ts
--
-- cursor contains the following field, ordered by the first 4:
--
--    office_id      varchar2(16)
--    forecast_date  date          
--    issue_date     date          
--    cwms_ts_id      varchar2(183)
--    version_date   date          
--    min_time       date          
--    max_time       date
--    time_zone_name varchar2(28)  
--
-- all dates are in the indicated time zone (passed in or location default) and
-- the time series extents are indicated in min_time, max_time
--
--------------------------------------------------------------------------------
/**
 * Catalogs forecast time series that match the specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_ts_catalog A cursor containing all matching forecast specifications.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the forecast time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">forecast_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The forecast date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">issue_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The issue date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">cwms_ts_id</td>
 *     <td class="descr">varchar2(183)</td>
 *     <td class="descr">The time series identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">version_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The version date of the time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">min_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The earliest date/time for the time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">max_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The latest date/time for the time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">time_zone_name</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone for the date/time columns</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id  The forecast location identifier.
 *
 * @param p_forecast_id  The forecast identifier.
 *
 * @param p_source_agency_mask  The source agency pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_cwms_ts_id_mask  The time series identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_time_zone  The time zone to retrieve the catalog in
 *
 * @param p_office_id  The office that owns the forecast.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used.
 */
procedure cat_ts(
   p_ts_catalog      out sys_refcursor,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_cwms_ts_id_mask in  varchar2 default '*',
   p_time_zone       in  varchar2 default null,  -- null = location time zone
   p_office_id       in  varchar2 default null); -- null = user's office id   
/**
 * Catalogs forecast time series that match the specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id  The forecast location identifier.
 *
 * @param p_forecast_id  The forecast identifier.
 *
 * @param p_source_agency_mask  The source agency pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return  The time series identifier pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_time_zone  The time zone to retrieve the catalog in
 *
 * @param p_office_id  The office that owns the forecast.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used.
 *
 * @param p_ts_catalog A cursor containing all matching forecast specifications.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the forecast time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">forecast_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The forecast date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">issue_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The issue date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">cwms_ts_id</td>
 *     <td class="descr">varchar2(183)</td>
 *     <td class="descr">The time series identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">version_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The version date of the time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">min_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The earliest date/time for the time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">max_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The latest date/time for the time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">time_zone_name</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone for the date/time columns</td>
 *   </tr>
 * </table>
 */
function cat_ts_f(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_cwms_ts_id_mask in varchar2 default '*',
   p_time_zone       in varchar2 default null, -- null = location time zone
   p_office_id       in varchar2 default null) -- null = user's office id   
   return sys_refcursor;   
/**
 * Stores (inserts or updates) text for a forecast to the database
 *
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_forecast_time   The forecast time
 * @param p_issue_time      The time the forecast was issued
 * @param p_time_zone       The time zone for p_forecast_time and p_issue_time
 * @param p_text            The text to store
 * @param p_fail_if_exists  A flag ('T' or 'F') that specifies whether the routine should fail if the forecast text already exists in the database
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the forecast text exists in the database
 */
procedure store_text(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_time_zone       in varchar2,
   p_text            in clob,
   p_fail_if_exists  in varchar2,
   p_office_id       in varchar2 default null); -- null = user's office id   
/**
 * Retrieves text for a forecast from the database
 *
 * @param p_text            The forecast text
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_forecast_time   The forecast time
 * @param p_issue_time      The time the forecast was issued
 * @param p_time_zone       The time zone for p_forecast_time and p_issue_time
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_text(
   p_text            out clob,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_forecast_time   in  date,
   p_issue_time      in  date,
   p_time_zone       in  varchar2 default null,  -- null = location time zone
   p_office_id       in  varchar2 default null); -- null = user's office id   
/**
 * Deletes text for a forecast from the database
 *
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_forecast_time   The forecast time. If not specified or NULL, text for all forecast times is deleted
 * @param p_issue_time      The time the forecast was issued. If not specified or NULL, text for all issue times is deleted
 * @param p_time_zone       The time zone for p_forecast_time and p_issue_time
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 */
procedure delete_text(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,                   -- null = all forecast times
   p_issue_time      in date,                   -- null = all issue times
   p_time_zone       in varchar2 default null,  -- null = location time zone
   p_office_id       in varchar2 default null); -- null = user's office id   
/**
 * Catalogs all forecast text for a forecast specification
 *
 * @param p_text_catalog A cursor containging the following columns, sorted by the first four:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the forecast text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">forecast_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The forecast date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">issue_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The issue date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">text_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The text identifier. Can be used with <a href="pkg_cwms_text.html#procedure retrieve_text(p_text out clob,p_id in varchar2,p_office_id in varchar2)">cwms_text.retieve_text</a> to retrieve the actual text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">time_zone_name</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone for the forecast and issue dates</td>
 *   </tr>
 * </table>
 * @param p_location_id  The forecast location identifier
 * @param p_forecast_id  The forecast identifier
 * @param p_time_zone    The time zone for p_forecast_time and p_issue_time
 * @param p_office_id    The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 */
procedure cat_text(
   p_text_catalog out sys_refcursor,
   p_location_id  in  varchar2,
   p_forecast_id  in  varchar2,
   p_time_zone    in  varchar2 default null,  -- null = location time zone
   p_office_id    in  varchar2 default null); -- null = user's office id   
/**
 * Catalogs all forecast text for a forecast specification
 *
 * @param p_location_id  The forecast location identifier
 * @param p_forecast_id  The forecast identifier
 * @param p_time_zone    The time zone for p_forecast_time and p_issue_time
 * @param p_office_id    The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 *
 * @return A cursor containging the following columns, sorted by the first four:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the forecast text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">forecast_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The forecast date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">issue_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The issue date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">text_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The text identifier. Can be used with <a href="pkg_cwms_text.html#procedure retrieve_text(p_text out clob,p_id in varchar2,p_office_id in varchar2)">cwms_text.retieve_text</a> to retrieve the actual text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">time_zone_name</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone for the forecast and issue dates</td>
 *   </tr>
 * </table>
 */
function cat_text_f (
   p_location_id  in varchar2,
   p_forecast_id  in varchar2,
   p_time_zone    in varchar2 default null, -- null = location time zone
   p_office_id    in varchar2 default null) -- null = user's office id   
   return sys_refcursor;   
/**
 * Stores time series and text for a forecast to the database
 *
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_forecast_time   The forecast time
 * @param p_issue_time      The time the forecast was issued
 * @param p_time_zone       The time zone for p_forecast_time, p_issue_time, p_verion_date, and p_timeseries_data
 * @param p_fail_if_exists  A flag ('T' or 'F') that specifies whether the routine should fail if any of the forecast time series or the forecast text already exists in the database
 * @param p_text            The time series text to store
 * @param p_timeseries      The time series data to store
 * @param p_store_rule      The store rule to use.  Same as for <a href="pkg_cwms_ts.html#procedure store_ts(p_cwms_ts_id in varchar2, p_units in varchar2, p_timeseries_data in tsv_array, p_store_rule in varchar2, p_override_prot in varchar2, p_version_date in date, p_office_id in varchar2)">cwms_ts.store_ts</a>
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and any of the forecast time series or the forecast text already exists in the database
 */
procedure store_forecast(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_time_zone       in varchar2, -- null = location time zone
   p_fail_if_exists  in varchar2,
   p_text            in clob,
   p_time_series     in ztimeseries_array,
   p_store_rule      in varchar2 default null,  -- null = DELETE INSERT
   p_office_id       in varchar2 default null); -- null = user's office id   
/**
 * Retrieves time series and text for a forecast from the database
 *
 * @param p_timeseries      The time series data to store
 * @param p_text            The time series text to store
 * @param p_location_id     The forecast location identifier
 * @param p_forecast_id     The forecast identifier
 * @param p_unit_system     The unit system ('EN' or 'SI') to return the time series values in
 * @param p_forecast_time   The forecast time
 * @param p_issue_time      The time the forecast was issued
 * @param p_time_zone       The time zone for p_forecast_time, p_issue_time, p_verion_date, and p_timeseries_data
 * @param p_office_id       The office that owns the forecast specification and time series.  If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_forecast(
   p_time_series     out ztimeseries_array,
   p_text            out clob,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_unit_system     in  varchar2 default null, -- null = retrieved from preferences, SI if none
   p_forecast_time   in  date     default null,  -- null = most recent
   p_issue_time      in  date     default null,  -- null = most_recent
   p_time_zone       in  varchar2 default null,  -- null = location time zone
   p_office_id       in  varchar2 default null); -- null = user's office id   
   
end cwms_forecast;
/
show errors;
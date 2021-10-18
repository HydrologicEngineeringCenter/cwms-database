set define off
create or replace package cwms_usgs
/**
 * Facilities for retrieving data from USGS
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.2
 */
as

/**
 * URL for retrieving instantaneous value time series data from USGS NWIS for a period ending at current time
 * @see https://waterservices.usgs.gov/rest/IV-Service.html
 */
realtime_ts_url_period constant varchar2(110) := 'https://waterservices.usgs.gov/nwis/iv/?format=<format>&period=<period>&parameterCd=<parameters>&sites=<sites>';
/**
 * URL for retrieving instantaneous value time series data from USGS NWIS for specified start and end dates
 * @see https://waterservices.usgs.gov/rest/IV-Service.html
 */
realtime_ts_url_dates  constant varchar2(122) := 'https://waterservices.usgs.gov/nwis/iv/?format=<format>&startDT=<start>&endDT=<end>&parameterCd=<parameters>&sites=<sites>';
/**
 * Maximum number of sites that can be requested at once from USGS NWIS
 */
max_sites constant integer := 100;
/**
 * CWMS Properties ID for specifying run interval in minutes for automatic instantaneous value time series retrieval job. Job doesn't run if property is not set. Property category is 'USGS'. Property value is integer.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_ts_interval
 * @see get_auto_ts_interval
 */
auto_ts_interval_prop constant varchar2(28) := 'timeseries_retrieve_interval';
/**
 * CWMS Properties ID for text filter for determining locations for which to retrieve instantaneous value time series data from USGS NWIS. No time series are retrieved if property is not set. Property category is 'USGS'.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_ts_filter_id
 * @see get_auto_ts_filter_id
 */
auto_ts_filter_prop constant varchar2(27) := 'timeseries_locations_filter';
/**
 * CWMS Properties ID for specifying lookback period when retrieving instantaneous value time series from USGS NWIS. Property value is in minutes. If property is not set, default period is 240 (4 hours).
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_ts_period
 * @see get_auto_ts_period
 */
auto_ts_period_prop constant varchar2(26) := 'timeseries_retrieve_period';
/**
 * URL for retrieving streamflow measurement data from USGS NWIS for specified start and end dates
 */
stream_meas_url     constant varchar2(114) := 'https://waterdata.usgs.gov/nwis/measurements?format=rdb&begin_date=<start>&end_date=<end>&multiple_site_no=<sites>';
/**
 * CWMS Properties ID for specifying run interval in minutes for automatic streamflow measurements retrieval job. Job doesn't run if property is not set. Property category is 'USGS'. Property value is integer.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_stream_meas_interval
 * @see get_auto_stream_meas_interval
 */
auto_stream_meas_interval_prop constant varchar2(33) := 'streamflow_meas_retrieve_interval';
/**
 * CWMS Properties ID for specifying lookback period when retrieving streamflow measurements from USGS NWIS. Property value is in minutes. If property is not set, default period is 10080 (7 days).
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_stream_meas_period
 * @see get_auto_stream_meas_period
 */
auto_stream_meas_period_prop constant varchar2(31) := 'streamflow_meas_retrieve_period';
/**
 * CWMS Properties ID for text filter for determining locations for which to retrieve streamflow measurements data from USGS NWIS. No time series are retrieved if property is not set. Property category is 'USGS'.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_stream_meas_filter_id
 * @see get_auto_stream_meas_filter_id
 */
auto_stream_meas_filter_prop constant varchar2(32) := 'streamflow_meas_locations_filter';
/**
 * URL for retrieving rating update info from the USGS NWIS rating depot for all ratings updated within a specified period
 * @see https://waterdata.usgs.gov/nwisweb/get_ratings?help
 */
rating_query_url_period   constant varchar2(72) := 'https://waterdata.usgs.gov/nwisweb/get_ratings?format=rdb&period=<hours>';
/**
 * URL for retrieving rating update info from the USGS NWIS rating depot for all ratings for a specified site
 * @see https://waterdata.usgs.gov/nwisweb/get_ratings?help
 */
rating_query_url_site constant varchar2(72) := 'https://waterdata.usgs.gov/nwisweb/get_ratings?format=rdb&site_no=<site>';
/**
 * URL for retrieving rating from the USGS NWIS rating depot
 * @see https://waterdata.usgs.gov/nwisweb/get_ratings?help
 */
rating_url constant varchar2(77) := 'https://waterdata.usgs.gov/nwisweb/data/ratings/<type>/USGS.<site>.<type>.rdb';
/**
 * CWMS Properties ID for specifying run interval in minutes for job to automatically retrieve new ratings. Job doesn't run if property is not set. Property category is 'USGS'. Property value is integer.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_new_rating_interval
 * @see get_auto_new_rating_interval
 */
auto_new_rating_interval_prop constant varchar2(28) := 'new_rating_retrieve_interval';
/**
 * CWMS Properties ID for specifying run interval in minutes for job to automatically retrieve updated ratings. Job doesn't run if property is not set. Property category is 'USGS'. Property value is integer.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_upd_rating_interval
 * @see get_auto_upd_rating_interval
 */
auto_upd_rating_interval_prop constant varchar2(28) := 'upd_rating_retrieve_interval';

/**
 * Default rating template version for BASE ratings retrieved from the USGS if no other value is set via the property
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant base_rating_templ_ver_prop
 * @see set_base_rating_templ_version
 * @see get_base_rating_templ_version
 */
default_base_rating_templ_ver constant varchar2(9) := 'USGS-BASE';

/**
 * Default rating specification version for BASE ratings retrieved from the USGS if no other value is set via the property
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant base_rating_spec_ver_prop
 * @see set_base_rating_spec_version
 * @see get_base_rating_spec_version
 */
default_base_rating_spec_ver constant varchar2(4)  := 'USGS';

/**
 * Default rating template version for EXSA ratings retrieved from the USGS if no other value is set via the property
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant exsa_rating_templ_ver_prop
 * @see set_exsa_rating_templ_version
 * @see get_exsa_rating_templ_version
 */
default_exsa_rating_templ_ver constant varchar2(9) := 'USGS-EXSA';

/**
 * Default rating specification version for EXSA ratings retrieved from the USGS if no other value is set via the property
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant exsa_rating_spec_ver_prop
 * @see set_exsa_rating_spec_version
 * @see get_exsa_rating_spec_version
 */
default_exsa_rating_spec_ver constant varchar2(4)  := 'USGS';

/**
 * Default rating template version for CORR ratings retrieved from the USGS if no other value is set via the property
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant corr_rating_templ_ver_prop
 * @see set_corr_rating_templ_version
 * @see get_corr_rating_templ_version
 */
default_corr_rating_templ_ver constant varchar2(9) := 'USGS-CORR';

/**
 * Default rating specification version for CORR ratings retrieved from the USGS if no other value is set via the property
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant corr_rating_spec_ver_prop
 * @see set_corr_rating_spec_version
 * @see get_corr_rating_spec_version
 */
default_corr_rating_spec_ver constant varchar2(4)  := 'USGS';

/**
 * Default rating template version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS)
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant prod_rating_templ_ver_prop
 * @see set_prod_rating_templ_version
 * @see get_prod_rating_templ_version
 */
default_prod_rating_templ_ver constant varchar2(15) := 'USGS-Production';

/**
 * Default rating specification version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS)
 *
 * @since CWMS database schema 18.1.6
 *
 * @see constant prod_rating_spec_ver_prop
 * @see set_prod_rating_spec_version
 * @see get_prod_rating_spec_version
 */
default_prod_rating_spec_ver constant varchar2(4)  := 'USGS';

/**
 * CWMS Properties ID for the rating template version for BASE ratings retrieved from the USGS
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_base_rating_templ_version
 * @see get_base_rating_templ_version
 */
base_rating_templ_ver_prop constant varchar2(28) := 'base_rating_template_version';

/**
 * CWMS Properties ID for the rating specification version for BASE ratings retrieved from the USGS
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_base_rating_spec_version
 * @see get_base_rating_spec_version
 */
base_rating_spec_ver_prop constant varchar2(24) := 'base_rating_spec_version';

/**
 * CWMS Properties ID for the rating template version for EXSA ratings retrieved from the USGS
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_exsa_rating_templ_version
 * @see get_exsa_rating_templ_version
 */
exsa_rating_templ_ver_prop constant varchar2(28) := 'exsa_rating_template_version';

/**
 * CWMS Properties ID for the rating specification version for EXSA ratings retrieved from the USGS
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_exsa_rating_spec_version
 * @see get_exsa_rating_spec_version
 */
exsa_rating_spec_ver_prop constant varchar2(24) := 'exsa_rating_spec_version';

/**
 * CWMS Properties ID for the rating template version for CORR ratings retrieved from the USGS
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_corr_rating_templ_version
 * @see get_corr_rating_templ_version
 */
corr_rating_templ_ver_prop constant varchar2(28) := 'corr_rating_template_version';

/**
 * CWMS Properties ID for the rating specification version for CORR ratings retrieved from the USGS
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_corr_rating_spec_version
 * @see get_corr_rating_spec_version
 */
corr_rating_spec_ver_prop constant varchar2(24) := 'corr_rating_spec_version';

/**
 * CWMS Properties ID for the rating template version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS)
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_prod_rating_templ_version
 * @see get_prod_rating_templ_version
 */
prod_rating_templ_ver_prop constant varchar2(28) := 'prod_rating_template_version';

/**
 * CWMS Properties ID for the rating specification version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS)
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_prod_rating_spec_version
 * @see get_prod_rating_spec_version
 */
prod_rating_spec_ver_prop constant varchar2(24) := 'prod_rating_spec_version';

/**
 * Retrieves the rating specification version for BASE ratings retrieved from the USGS.
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating specification version for BASE ratings retrieved from the USGS.
 *
 * @since CWMS database schema 18.1.6
 * @see constant base_rating_spec_ver_prop
 * @see constant default_base_rating_spec_ver
 * @see set_base_rating_spec_version
 */
function get_base_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating specification version for BASE ratings retrieved from the USGS.
 *
 * @param p_version_text The new rating specification version for BASE ratings retrieved from the USGS.
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS database schema 18.1.6
 * @see constant base_rating_spec_ver_prop
 * @see get_base_rating_spec_version
 */
procedure set_base_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Retrieves the rating template version for BASE ratings retrieved from the USGS.
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating template version for BASE ratings retrieved from the USGS.
 *
 * @since CWMS database schema 18.1.6
 * @see constant base_rating_templ_ver_prop
 * @see constant default_base_rating_templ_ver
 * @see set_base_rating_templ_version
 */
function get_base_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating template version for BASE ratings retrieved from the USGS.
 *
 * @param p_version_text The new rating template version for BASE ratings retrieved from the USGS.
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS database schema 18.1.6
 * @see constant base_rating_templ_ver_prop
 * @see get_base_rating_templ_version
 */
procedure set_base_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Retrieves the rating specification version for EXSA ratings retrieved from the USGS.
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating specification version for EXSA ratings retrieved from the USGS.
 *
 * @since CWMS dataexsa schema 18.1.6
 * @see constant exsa_rating_spec_ver_prop
 * @see constant default_exsa_rating_spec_ver
 * @see set_exsa_rating_spec_version
 */
function get_exsa_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating specification version for EXSA ratings retrieved from the USGS.
 *
 * @param p_version_text The new rating specification version for EXSA ratings retrieved from the USGS.
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS dataexsa schema 18.1.6
 * @see constant exsa_rating_spec_ver_prop
 * @see get_exsa_rating_spec_version
 */
procedure set_exsa_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Retrieves the rating template version for EXSA ratings retrieved from the USGS.
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating template version for EXSA ratings retrieved from the USGS.
 *
 * @since CWMS dataexsa schema 18.1.6
 * @see constant exsa_rating_templ_ver_prop
 * @see constant default_exsa_rating_templ_ver
 * @see set_exsa_rating_templ_version
 */
function get_exsa_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating template version for EXSA ratings retrieved from the USGS.
 *
 * @param p_version_text The new rating template version for EXSA ratings retrieved from the USGS.
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS dataexsa schema 18.1.6
 * @see constant exsa_rating_templ_ver_prop
 * @see get_exsa_rating_templ_version
 */
procedure set_exsa_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Retrieves the rating specification version for CORR ratings retrieved from the USGS.
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating specification version for CORR ratings retrieved from the USGS.
 *
 * @since CWMS datacorr schema 18.1.6
 * @see constant corr_rating_spec_ver_prop
 * @see constant default_corr_rating_spec_ver
 * @see set_corr_rating_spec_version
 */
function get_corr_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating specification version for CORR ratings retrieved from the USGS.
 *
 * @param p_version_text The new rating specification version for CORR ratings retrieved from the USGS.
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS datacorr schema 18.1.6
 * @see constant corr_rating_spec_ver_prop
 * @see get_corr_rating_spec_version
 */
procedure set_corr_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Retrieves the rating template version for CORR ratings retrieved from the USGS.
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating template version for CORR ratings retrieved from the USGS.
 *
 * @since CWMS datacorr schema 18.1.6
 * @see constant corr_rating_templ_ver_prop
 * @see constant default_corr_rating_templ_ver
 * @see set_corr_rating_templ_version
 */
function get_corr_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating template version for CORR ratings retrieved from the USGS.
 *
 * @param p_version_text The new rating template version for CORR ratings retrieved from the USGS.
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS datacorr schema 18.1.6
 * @see constant corr_rating_templ_ver_prop
 * @see get_corr_rating_templ_version
 */
procedure set_corr_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Retrieves the rating specification version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS).
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating specification version for PROD ratings retrieved from the USGS.
 *
 * @since CWMS database schema 18.1.6
 * @see constant prod_rating_spec_ver_prop
 * @see constant default_prod_rating_spec_ver
 * @see set_prod_rating_spec_version
 */
function get_prod_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating specification version for PROD ratings retrieved from the USGS.
 *
 * @param p_version_text The new rating specification version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS).
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS database schema 18.1.6
 * @see constant prod_rating_spec_ver_prop
 * @see get_prod_rating_spec_version
 */
procedure set_prod_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Retrieves the rating template version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS).
 * This will be the value set in the property, or the default value if no value is set in the property.
 *
 * @return The rating template version for PROD ratings retrieved from the USGS.
 *
 * @since CWMS database schema 18.1.6
 * @see constant prod_rating_templ_ver_prop
 * @see constant default_prod_rating_templ_ver
 * @see set_prod_rating_templ_version
 */
function get_prod_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2;

/**
 * Sets the rating template version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS).
 *
 * @param p_version_text The new rating template version for PROD ratings retrieved from the USGS.
 * @param p_office_id    The office to set the property for.
 *                       If unspecified or NULL, the current session's default office will be used.
 *
 * @since CWMS database schema 18.1.6
 * @see constant prod_rating_templ_ver_prop
 * @see get_prod_rating_templ_version
 */
procedure set_prod_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null);

/**
 * Sets the text filter used to determine locations for which to retrieve instantaneous value time series data from USGS NWIS.
 *
 * @param p_text_filter_id The text filter to use to determine location for which to retrieve time series data.
 * @param p_office_id      The office to set the text filter for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_ts_filter_prop
 */
procedure set_auto_ts_filter_id(
   p_text_filter_id in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Retrieves the text filter used to determine locations for which to retrieve instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id The office that owns the text filter. If NULL or not specified, the session user's default office is used.
 * @return The text filter to use to determine location for which to retrieve time series data.
 *
 * @see constant auto_ts_filter_prop
 */
function get_auto_ts_filter_id(
   p_office_id in varchar2 default null)
   return varchar2;
/**
 * Sets the lookback period to use for retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_period     The period in minutes to use for retrieving time series data from USGS NWIS
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_ts_period_prop
 */
procedure set_auto_ts_period(
   p_period    in integer,
   p_office_id in varchar2 default null);
/**
 * Retrieves the lookback period in minutes to use for retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id  The office to get the period for. If NULL or not specified, the session user's default office is used.
 * @return             The period in minutes to use for retrieving time series data from USGS NWIS
 *
 * @see constant auto_ts_period_prop
 */
function get_auto_ts_period(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Sets the run interval for automatically retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_interval   The run interval in minutes for automatically retrieving time series data from USGS NWIS.
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_ts_interval_prop
 */
procedure set_auto_ts_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null);
/**
 * Retrieves the run interval for automatically retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 * @return             The run interval in minutes for automatically retrieving time series data from USGS NWIS.
 *
 * @see constant auto_ts_interval_prop
 */
function get_auto_ts_interval(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Retrieves the list of locations that will be processed for a specified parameter. This function uses a text filter with a
 * name based on the one specified (or returned from the get_auto_ts_filter_id function); it has a five-character parameter as a suffix. For example,
 * if the main text filter is named USGS_Auto_TS, the text filter for USGS parameter 65 would be USGS_Auto_TS.00065.
 *
 * @param p_parameter The USGS parameter to retrieve the locations for, specified as an integer.
 * @param p_filter_id The name of the text filter to use for locations. If not specified or null, the filter returned by the get_auto_ts_filter_id function is used.
 * @param p_office_id The office to retrieve locations for. If NULL or not spcecified, the session user's default office is used.
 *
 * @see get_auto_ts_filter_id
 */
function get_parameter_ts_locations(
   p_parameter in integer,
   p_filter_id in varchar2 default null,
   p_office_id in varchar2 default null)
   return str_tab_t;
/**
 * Retrieves the list of locations that will be processed for a specified parameter. This function uses a text filter with a
 * name based on the one returned from the get_auto_ts_filter_id function; it has a five-character parameter as a suffix. For example,
 * if the main text filter is named USGS_Auto_TS, the text filter for USGS parameter 65 would be USGS_Auto_TS.00065.
 *
 * @param p_parameter The USGS parameter to retrieve the locations for, specified as an integer.
 * @param p_office_id The office to retrieve locations for. If NULL or not spcecified, the session user's default office is used.
 *
 * @see get_auto_ts_filter_id
 */
function get_auto_param_ts_locations(
   p_parameter in integer,
   p_office_id in varchar2 default null)
   return str_tab_t;
/**
 * Retrieves the list of locations whose instantaneous value time series will be retrieved from the USGS NWIS.
 *
 * @param p_office_id The office to retrieve locations for. If NULL or not spcecified, the session user's default office is used.
 *
 * @see get_auto_ts_filter_id
 */
function get_auto_ts_locations(
   p_office_id in varchar2 default null)
   return str_tab_t;
/**
 * Retrieves the USGS parameters that will be processed when retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id The office to retrieve parameters for. If NULL or not spcecified, the session user's default office is used.
 * @return      The USGS parameters as a table of integers.
 */
function get_parameters(
   p_office_id in varchar2 default null)
   return number_tab_t;
/**
 * Retrieves the USGS parameters that will be processed when retrieving instantaneous value time series data for a specified site from USGS NWIS.
 *
 * @param p_usgs_id   The USGS site name (station number) to retrieve the parameters for
 * @param p_office_id The office to retrieve parameters for. If NULL or not spcecified, the session user's default office is used.
 * @return The USGS parameters as a table of integers.
 */
function get_parameters(
   p_usgs_id   in varchar2,
   p_office_id in varchar2 default null)
   return number_tab_t;
/**
 * Sets the USGS-to-CWMS parameter mapping for a specified USGS parameter and office
 *
 * @param p_parameter     The USGS parameter to set the mapping for, specified as an integer
 * @param p_parameter_id  The CWMS parameter to use for the USGS parameter
 * @param p_param_type_id The CWMS parameter type to use for the USGS parameter
 * @param p_unit          The CWMS unit  to use for the USGS parameter
 * @param p_factor        The factor in CWMS = USGS * factor + offset to get the data into the specified CWMS unit
 * @param p_offset        The offset in CWMS = USGS * factor + offset to get the data into the specified CWMS unit
 * @param p_office_id     The office to set the parameter mapping for. If NULL or not specified, the session user's default office is used
 */
procedure set_parameter_info(
   p_parameter     in integer,
   p_parameter_id  in varchar2,
   p_param_type_id in varchar2,
   p_unit          in varchar2,
   p_factor        in binary_double default 1.0,
   p_offset        in binary_double default 0.0,
   p_office_id     in varchar2 default null);
/**
 * Retrieves the USGS-to-CWMS parameter mapping for a specified USGS parameter and office
 *
 * @param p_parameter_id  The CWMS parameter to use for the USGS parameter
 * @param p_param_type_id The CWMS parameter type to use for the USGS parameter
 * @param p_unit          The CWMS unit  to use for the USGS parameter
 * @param p_factor        The factor in CWMS = USGS * factor + offset to get the data into the specified CWMS unit. If not specified, the factor defaults to 1.0
 * @param p_offset        The offset in CWMS = USGS * factor + offset to get the data into the specified CWMS unit  If not specified, the offset defatuls to 0.0
 * @param p_parameter     The USGS parameter to retrieve the mapping for, specified as an integer
 * @param p_office_id     The office to retrieve the parameter mapping for. If NULL or not specified, the session user's default office is used
 */
procedure get_parameter_info(
   p_parameter_id  out varchar2,
   p_param_type_id out varchar2,
   p_unit          out varchar2,
   p_factor        out binary_double,
   p_offset        out binary_double,
   p_parameter     in integer,
   p_office_id     in varchar2 default null);
/**
 * Deletes the USGS-to-CWMS parameter mapping for a specified USGS parameter and office
 *
 * @param p_parameter_id The CWMS parameter to use for the USGS parameter
 * @param p_office_id    The office to retrieve the parameter mapping for. If NULL or not specified, the session user's default office is used
 */
procedure delete_parameter_info(
   p_parameter in integer,
   p_office_id in varchar2 default null);
/**
 * Retrieves the CWMS time series identifer based on specified location, version, USGS parameter, and interval
 *
 * @param p_location_id    The location identifier for the time series
 * @param p_usgs_parameter The USGS parameter to use, specified as an integer
 * @param p_interval       The interval of the data, specified in minutes
 * @param p_version        The version portion of the time series. If not specified, the version defaults to 'USGS'
 * @param p_office_id      The office to create the time series identifier for.  If NULL or not specified, the session user's default office is used
 * @return The time series identifier constructed from the specified information and the office's USGS-to-CWMS parameter mapping information
 */
function get_ts_id(
   p_location_id    in varchar2,
   p_usgs_parameter in integer,
   p_interval       in integer,
   p_version        in varchar2 default 'USGS',
   p_office_id      in varchar2 default null)
   return varchar2;
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on a lookback period
 *
 * @param p_format     The format for the returned data.  Currently valid values are
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">format</th>
 *     <th class="descr">description</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb,1.0</td>
 *     <td class="descr">tab-delimited USGS RDB format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb</td>
 *     <td class="descr">synonym for 'rdb,1.0'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json,1.0</td>
 *     <td class="descr">JavaScript Object Notaion format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json</td>
 *     <td class="descr">synonym for 'json,1.0'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,1.1</td>
 *     <td class="descr">the CUAHSI WaterML 1.1 format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml</td>
 *     <td class="descr">synonym for 'waterml,1.1'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,2.0</td>
 *     <td class="descr">the OGC WaterML 2.0 format</td>
 *   </tr>
 * </table>
 * @param p_period     The lookback period to retrieve data for. If NULL, the value returned by get_auto_ts_period for the specified or default office is used.
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used.
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in the requested format as a CLOB
 *
 * @see https://waterservices.usgs.gov/rest/IV-Service.html
 * @see https://en.wikipedia.org/wiki/JSON
 * @see https://his.cuahsi.org/wofws.html
 * @see http://www.waterml2.org/
 */
function get_ts_data(
   p_format     in varchar2,
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob;
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on start and end times
 *
 * @param p_format     The format for the returned data.  Currently valid values are
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">format</th>
 *     <th class="descr">description</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb,1.0</td>
 *     <td class="descr">tab-delimited USGS RDB format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb</td>
 *     <td class="descr">synonym for 'rdb,1.0'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,1.1</td>
 *     <td class="descr">the CUAHSI WaterML 1.1 format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml</td>
 *     <td class="descr">synonym for 'waterml,1.1'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,2.0</td>
 *     <td class="descr">the OGC WaterML 2.0 format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json,1.1</td>
 *     <td class="descr">The WaterML 1.1 data in JavaScript Object Notation format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json</td>
 *     <td class="descr">synonym for 'json,1.1'</td>
 *   </tr>
 * </table>
 * @param p_start_time The beginning of the time window specified in ISO 8601 date/time format
 * @param p_end_time   The end of the time window specified in ISO 8601 date/time format
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used.
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in the requested format as a CLOB
 *
 * @see https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations
 * @see https://waterservices.usgs.gov/rest/IV-Service.html
 * @see https://en.wikipedia.org/wiki/JSON
 * @see https://his.cuahsi.org/wofws.html
 * @see http://www.waterml2.org/
 */
function get_ts_data(
   p_format     in varchar2,
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob;
/**
 * Retrieve instantaneous value time series data in RDB format from USGS NWIS based on a lookback period
 *
 * @param p_period     The lookback period to retrieve data for. If NULL, the value returned by get_auto_ts_period for the specified or default office is used.
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used.
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in RDB format format as a CLOB
 */
function get_ts_data_rdb(
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob;
/**
 * Retrieve instantaneous value time series data in RDB format from USGS NWIS based on based on start and end times
 *
 * @param p_start_time The beginning of the time window specified in ISO 8601 date/time format
 * @param p_end_time   The end of the time window specified in ISO 8601 date/time format
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used.
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in RDB format format as a CLOB
 */
function get_ts_data_rdb(
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob;
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on a lookback period and store in CWMS.
 * The period used is the same as returned from get_auto_ts_period for the specified or defatul office
 * The list of sites is the same as returned from get_auto_ts_locations (without the input parameter) for the specified or default office
 * All available parameters for each site will be retrieved, but only those parameters with USGS-to-CWMS parameter mapping will be processed and stored
 *
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_ts(
   p_office_id in varchar2 default null);
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on a lookback period and store in CWMS
 *
 * @param p_period     The lookback period to retrieve data for. If NULL, the value returned by get_auto_ts_period for the specified or default office is used.
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used.
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site, but only those parameters with USGS-to-CWMS parameter mapping will be processed and stored
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_ts(
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null);
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on based on start and end times and store in CWMS
 *
 * @param p_start_time The beginning of the time window specified in ISO 8601 date/time format
 * @param p_end_time   The end of the time window specified in ISO 8601 date/time format
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used.
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site, but only those parameters with USGS-to-CWMS parameter mapping will be processed and stored
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_ts(
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null);
/**
 * Schedules (or re-schedules) the job to automatically retrieve instaneous value time series data.
 * The scheduled job name is USGS_AUTO_TS_XXX, where XXX is the office identifier the job is running for
 *
 * @param p_office_id  The office to start the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure start_auto_ts_job(
   p_office_id in varchar2 default null);
/**
 * Unschedules the job to automatically retrieve instaneous value time series data.
 *
 * @param p_office_id  The office to stop the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure stop_auto_ts_job(
   p_office_id in varchar2 default null);
/**
 * Sets the lookback period to use for retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_period     The period in minutes to use for retrieving time series data from USGS NWIS
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_ts_period_prop
 */
procedure set_auto_stream_meas_period(
   p_period    in integer,
   p_office_id in varchar2 default null);
/**
 * Retrieves the lookback period in minutes to use for retrieving streamflow measurements data from USGS NWIS.
 *
 * @param p_office_id  The office to get the period for. If NULL or not specified, the session user's default office is used.
 * @return             The period in minutes to use for retrieving time series data from USGS NWIS
 *
 * @see constant auto_stream_meas_period_prop
 */
function get_auto_stream_meas_period(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Sets the run interval for automatically retrieving streamflow measurements data from USGS NWIS.
 *
 * @param p_interval   The run interval in minutes for automatically retrieving time series data from USGS NWIS.
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_stream_meas_interval_prop
 */
procedure set_auto_stream_meas_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null);
/**
 * Retrieves the run interval for automatically retrieving streamflow measurements data from USGS NWIS.
 *
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 * @return             The run interval in minutes for automatically retrieving time series data from USGS NWIS.
 *
 * @see constant auto_stream_meas_interval_prop
 */
function get_auto_stream_meas_interval(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Sets the text filter used to determine locations for which to retrieve streamflow measurement data from USGS NWIS.
 *
 * @param p_text_filter_id The text filter to use to determine locations for which to retrieve streamflow measurement data.
 * @param p_office_id      The office to set the text filter for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_ts_filter_prop
 */
procedure set_auto_stream_meas_filter_id(
   p_text_filter_id in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Retrieves the text filter used to determine locations for which to retrieve streamflow measurement data from USGS NWIS.
 *
 * @param p_office_id The office that owns the text filter. If NULL or not specified, the session user's default office is used.
 * @return The text filter to use to determine locations for which to retrieve streamflow measurement data.
 *
 * @see constant auto_stream_meas_filter_prop
 */
function get_auto_stream_meas_filter_id(
   p_office_id in varchar2 default null)
   return varchar2;
/**
 * Retrieves the list of locations whose streamflow measurements will be retrieved from the USGS NWIS.
 *
 * @param p_office_id The office to retrieve locations for. If NULL or not spcecified, the session user's default office is used.
 *
 * @see get_auto_stream_meas_filter_id
 */
function get_auto_stream_meas_locations(
   p_office_id in varchar2 default null)
   return str_tab_t;
/**
 * Retrieve streamflow measurement data from USGS NWIS based on a lookback period and store in CWMS
 *
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_stream_meas(
   p_office_id  in varchar2 default null);
/**
 * Retrieve streamflow measurement data from USGS NWIS based on a lookback period and store in CWMS
 *
 * @param p_period     The lookback period to retrieve data for. If NULL, the value returned by get_auto_stream_meas_period for the specified or default office is used.
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_stream_meas_locations (without the input parameter) for the specified or default office is used.
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_stream_meas(
   p_period     in varchar2,
   p_sites      in varchar2,
   p_office_id  in varchar2 default null);
/**
 * Retrieve streamflow measurement data from USGS NWIS based on based on start and end times and store in CWMS
 *
 * @param p_start_time The beginning of the time window specified in ISO 8601 date/time format
 * @param p_end_time   The end of the time window specified in ISO 8601 date/time format
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_stream_meas_locations (without the input parameter) for the specified or default office is used.
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_stream_meas(
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_office_id  in varchar2 default null);
/**
 * Schedules (or re-schedules) the job to automatically retrieve streamflow measurement data.
 * The scheduled job name is USGS_AUTO_MEAS_XXX, where XXX is the office identifier the job is running for
 *
 * @param p_office_id  The office to start the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure start_auto_stream_meas_job(
   p_office_id in varchar2 default null);
/**
 * Unschedules the job to automatically retrieve streamflow measurement data.
 *
 * @param p_office_id  The office to stop the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure stop_auto_stream_meas_job(
   p_office_id in varchar2 default null);
/**
 * Retreives all the rating specification codes that have a template version of USGS-BASE, USGS-EXSA, USGS-CORR, a specification version of USGS, and are set to auto-update.
 *
 * @param p_office_id  The office to retrieve the rating specification identifiers for.  If NULL or not specified, the session user's default office is used.
 * @return A table of the matching rating specification identifiers.
 */
function get_auto_update_ratings(
   p_office_id in varchar2 default null)
   return number_tab_t;
/**
 * Updates any BASE, EXSA, or CORR ratings from USGS ratings depot that are set to auto update
 *
 * @param p_office_id   The office to update the ratings for.  If NULL or not specified, the session user's default office is used.
 */
procedure update_existing_ratings(
   p_office_id in varchar2 default null);
/**
 * Retreieves BASE, EXSA, or CORR ratings from USGS ratings depot for specified locations
 *
 * @param p_rating_type The rating type. Must be 'BASE', 'EXSA', or 'CORR'.
 * @param p_sites       A comma-separated string of the locations to retrieve ratings for.  If the name of an existing text filter is specified, the locations that match the filter will be used.  If NULL, all locations with a USGS Station Number alias will be used.
 * @param p_office_id   The office to retrieve the ratings for.  If NULL or not specified, the session user's default office is used.
 */
procedure retrieve_and_store_ratings(
   p_rating_type in varchar2,
   p_sites       in varchar2 default null,
   p_office_id   in varchar2 default null);
/**
 * Generates <site>.Stage;Flow.USGS-Production.USGS ratings for every site that has a <site>.Stage;Flow.USGS-BASE.USGS or <site>.Stage;Flow.USGS-EXSA.USGS rating.
 * The procedure generates a virtual rating if the site has a <site.Stage;Stage-Correction.USGS-CORR.USGS rating and a transitional rating if it does not.  The virtual rating
 * will compute the stage correction and add it to the input stage before rating via the BASE or EXSA rating.  The procedure will not retrieve the stage correction ratings;
 * they must be retrieved separately. Executing this procedure allows a similar rating specification identifier to be used for every site regardless of whether the site
 * has a stage correction rating.
 *
 * @param p_office_id The office to generate the production ratings for.  If NULL or not specified, the session user's default office is used.
 */
procedure generate_production_ratings2(
   p_office_id in varchar2 default null);
/**
 * Generates <site>.Stage;Flow.USGS-Production.USGS ratings for the specified site if it has a <site>.Stage;Flow.USGS-BASE.USGS or <site>.Stage;Flow.USGS-EXSA.USGS rating.
 * The procedure generates a virtual rating if the site has a <site.Stage;Stage-Correction.USGS-CORR.USGS rating and a transitional rating if it does not.  The virtual rating
 * will compute the stage correction and add it to the input stage before rating via the BASE or EXSA rating.  The procedure will not retrieve the stage correction rating;
 * it must be retrieved separately. Executing this procedure allows a similar rating specification identifier to be used for every site regardless of whether the site
 * has a stage correction rating.
 *
 * @param location_id The location to generate the production rating for.
 * @param p_office_id The office to generate the production ratings for.  If NULL or not specified, the session user's default office is used.
 */
procedure generate_production_ratings(
   p_location_id in varchar2,
   p_office_id in varchar2 default null);
/**
 * Retrieves BASE and CORR ratings for all locations that have USGS Station Number aliases, if such ratings exist. Also generates production ratings
 * that use the CORR+BASE ratings where the CORR ratings exist and just BASE ratings otherwise. Note that the use of the BASE ratings includes using
 * any available shifts and offsets in the same manner as they are used by the USGS and does not just use the BASE rating points for lookup.
 *
 * @param p_office_id The office retreive ratings for.  If NULL or not specified, the session user's default office is used.
 */
procedure retrieve_available_ratings2(
   p_office_id in varchar2 default null);
/**
 * Retrieves BASE and CORR ratings for the specified location, if such ratings exist. Also generates production rating
 * that use the CORR+BASE ratings if the CORR rating exists and just BASE rating otherwise. Note that the use of the BASE rating includes using
 * any available shifts and offsets in the same manner as they are used by the USGS and does not just use the BASE rating points for lookup.
 *
 * @param location_id The location to retrieve the available ratings for.
 * @param p_office_id The office retreive ratings for.  If NULL or not specified, the session user's default office is used.
 */
procedure retrieve_available_ratings(
   p_location_id in varchar2,
   p_office_id   in varchar2 default null);
/**
 * Sets the run interval for automatically retrieving new ratings from USGS.
 *
 * @param p_interval   The run interval in minutes for automatically retrieving new ratings from USGS.
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_new_rating_interval_prop
 */
procedure set_auto_new_rating_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null);
/**
 * Sets the run interval for automatically retrieving new ratings from USGS.
 *
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @return  The run interval in minutes for automatically retrieving new ratings from USGS.
 *
 * @see constant auto_new_rating_interval_prop
 *
 */
function get_auto_new_rating_interval(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Sets the run interval for automatically retrieving updated ratings from USGS.
 *
 * @param p_interval   The run interval in minutes for automatically retrieving updated ratings from USGS.
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_upd_rating_interval_prop
 */
procedure set_auto_upd_rating_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null);
/**
 * Sets the run interval for automatically retrieving updated ratings from USGS.
 *
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *
 * @return  The run interval in minutes for automatically retrieving updated ratings from USGS.
 *
 * @see constant auto_upd_rating_interval_prop
 *
 */
function get_auto_upd_rating_interval(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Schedules (or re-schedules) the job to automatically retrieve USGS ratings for locations that have USGS Station Number aliases
 * The scheduled job name is USGS_AUTO_NEW_RATE_XXX, where XXX is the office identifier the job is running for
 *
 * @param p_office_id  The office to start the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure start_auto_new_rating_job(
   p_office_id in varchar2 default null);
/**
 * Unschedules the job to automatically retrieve USGS ratings for locations that have USGS Station Number aliases
 *
 * @param p_office_id  The office to stop the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure stop_auto_new_rating_job(
   p_office_id in varchar2 default null);
/**
 * Schedules (or re-schedules) the job to automatically retrieve updates to existing USGS ratings that are so specified..
 * The scheduled job name is USGS_AUTO_UPD_RATE_XXX, where XXX is the office identifier the job is running for
 *
 * @param p_office_id  The office to start the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure start_auto_update_rating_job(
   p_office_id in varchar2 default null);
/**
 * Unschedules the job to automatically retrieve updates to existing USGS ratings that are so specified.
 *
 * @param p_office_id  The office to stop the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure stop_auto_update_rating_job(
   p_office_id in varchar2 default null);
/**
 * Generates CWMS Rating XML instance for a USGS stage correction rating in RDB format. The location will be converted to the CWMS location id for the specified office, if possible.
 *
 * @param p_rating_text The RDB-formatted USGS stage correction rating
 * @param p_office_id   The office to use for resolving the USGS station number into a location id. If NULL or not specified, the current user's default office is used.
 *
 * @return The XML-formatted rating
 */
function corr_to_xml(
   p_rating_text in clob,
   p_office_id   in varchar2)
   return clob;
/**
 * Generates CWMS Rating XML instance for a USGS base stage-flow rating in RDB format. The location will be converted to the CWMS location id for the specified office, if possible.
 *
 * @param p_rating_base The RDB-formatted USGS base stage-flow rating
 * @param p_rating_exsa The RDB-formatted USGS EXSA stage-flow rating for the same location. This rating is used to get the shift information. If NULL or not specified, no shifts will be in the generated XML.
 * @param p_office_id   The office to use for resolving the USGS station number into a location id. If NULL or not specified, the current user's default office is used.
 *
 * @return The XML-formatted rating
 */
function base_to_xml(
   p_rating_base in clob,
   p_rating_exsa in clob,
   p_office_id   in varchar2)
   return clob;
/**
 * Generates CWMS Rating XML instance for a USGS extended, shift-adjusted (EXSA) stage-flow rating in RDB format. The location will be converted to the CWMS location id for the specified office, if possible.
 *
 * @param p_rating_text The RDB-formatted USGS EXSA stage-flow rating
 * @param p_office_id   The office to use for resolving the USGS station number into a location id. If NULL or not specified, the current user's default office is used.
 *
 * @return The XML-formatted rating
 */
function exsa_to_xml(
   p_rating_text in clob,
   p_office_id   in varchar2)
   return clob;
/**
 * Retrieves a rating from the USGS ratings depot and returns it as a CLOB in either the USGS RDB format or  the CWMS ratings XML format.
 *
 * @param p_location_id The location to retreive the rating for. May be any valid location identifier or alias for the specified or default office.
 * @param p_rating_type The type of rating to retrieve. Must be one of ''EXSA'', ''BASE'', or ''CORR''.
 * @param xml_encode    A flag (''T''/''F'') specifying whether to enccode the retrieved rating in the CWMS ratings XML format.
 * @param p_office_id   The office that the specified location belongs to. If NULL or not specified, the current user's default office is used.
 *
 * @return The rating in RDB or XML format
 */
function retrieve_rating(
   p_location_id in varchar2,
   p_rating_type in varchar2,
   p_xml_encode  in varchar2,
   p_office_id   in varchar2 default null)
   return clob;


end cwms_usgs;
/
show errors


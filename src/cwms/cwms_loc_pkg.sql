/* Formatted on 7/29/2011 11:54:36 AM (QP5 v5.163.1008.3004) */
set define off
CREATE OR REPLACE PACKAGE cwms_loc
/**
 * Facilities for working with locations in the CWMS database
 *
 * @author Gerhard Krueger
 *
 * @since CWMS 2.0
 */
AS
   -- leave these undocumented for now
	l_elev_db_unit 			VARCHAR2 (16) := 'm';
	l_abstract_elev_param	VARCHAR2 (32) := 'Length';
   /**
    * Retrieves an actual location identifier given an identifier that may or may not be a location alias
    *
    * @param p_location_id_or alias The location identifier or location alias
    * @param p_office_id            The office that owns the location. If not specified or NULL the session user's default office is used
    *
    * @return The actual location identifier
    */
	FUNCTION get_location_id (p_location_id_or_alias	 VARCHAR2,
									  p_office_id					 VARCHAR2 DEFAULT NULL
									 )
		RETURN VARCHAR2;
   /**
    * Retrieves an actual location identifier given an identifier that may or may not be a location alias
    *
    * @param p_location_id_or alias The location identifier or location alias
    * @param p_office_code          The unique numeric code that identifies the office that owns the location
    *
    * @return The actual location identifier
    */
	FUNCTION get_location_id (p_location_id_or_alias	 VARCHAR2,
									  p_office_code				 NUMBER
									 )
		RETURN VARCHAR2;
   /**
    * Retrieves a location identifier given its unique numeric code
    *
    * @param p_location code The unique numeric code that identifies the location
    *
    * @return The location identifier
    */
	FUNCTION get_location_id (p_location_code IN NUMBER)
		RETURN VARCHAR2;
   /**
    * Retrieves a location's unique numeric code. Retrieves the location code if p_location_id is a location identifier or location alias.
    *
    * @param p_db_office_id The office that owns the location. If not specified or NULL the session user's default office is used
    * @param p_location_id  The location identifier
    *
    * @return The unique numeric code that identifies the location
    */
	FUNCTION get_location_code (p_db_office_id	IN VARCHAR2,
										 p_location_id 	IN VARCHAR2
										)
		RETURN NUMBER
		RESULT_CACHE;
   /**
    * Retrieves a location's unique numeric code. Retrieves the location code if p_location_id is a location identifier or location alias.
    *
    * @param p_office_code The unique numeric code that identifies the office that owns the location
    * @param p_location_id The location identifier
    *
    * @return The unique numeric code that identifies the location
    */
	FUNCTION get_location_code (p_db_office_code   IN NUMBER,
										 p_location_id 	  IN VARCHAR2
										)
		RETURN NUMBER
		RESULT_CACHE;
   /**
    * Retrieves a location's unique numeric code
    *
    * @param p_office_code The unique numeric code that identifies the office that owns the location
    * @param p_location_id The location identifier
    * @param p_check_aliases A flag ('T' or 'F') that specifies whether to check aliases if p_location_id is not found as a location identifier
    *
    * @return The unique numeric code that identifies the location
    */
   FUNCTION get_location_code (p_db_office_code   IN NUMBER,
                               p_location_id      IN VARCHAR2,
                               p_check_aliases    IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE;
   /**
    * Retrieves a location's unique numeric code
    *
    * @param p_db_office_id The office that owns the location. If not specified or NULL the session user's default office is used
    * @param p_location_id  The location identifier
    * @param p_check_aliases A flag ('T' or 'F') that specifies whether to check aliases if p_location_id is not found as a location identifier
    *
    * @return The unique numeric code that identifies the location
    */
   FUNCTION get_location_code (p_db_office_id   IN VARCHAR2,
                               p_location_id    IN VARCHAR2,
                               p_check_aliases  IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE;
   /**
    * Retrieves a state's unique numeric code given its two letter state abbreviation
    *
    * @param p_state_initial The state's two letter abbreviation
    *
    * @return The unique numeric code that identifies the state
    */
	FUNCTION get_state_code (p_state_initial IN VARCHAR2 DEFAULT NULL)
		RETURN NUMBER;
   /**
    * Retrieves a county's unique numeric code given its name and the two letter state abbreviation
    *
    * @param p_county_name   The name of the county
    * @param p_state_initial The two letter abbreviation of the state that contains the county
    *
    * @return The unique numeric code that identifies the county
    */
	FUNCTION get_county_code (p_county_name	  IN VARCHAR2 DEFAULT NULL,
									  p_state_initial   IN VARCHAR2 DEFAULT NULL
									 )
		RETURN NUMBER;
   -- not documented, use cwms_util.convert_units
	FUNCTION convert_from_to (p_orig_value 			 IN NUMBER,
									  p_from_unit_name		 IN VARCHAR2,
									  p_to_unit_name			 IN VARCHAR2,
									  p_abstract_paramname	 IN VARCHAR2
									 )
		RETURN NUMBER;
   -- not documented
	FUNCTION get_unit_code (unitname 			  IN VARCHAR2,
									abstractparamname   IN VARCHAR2
								  )
		RETURN NUMBER;
   /**
    * Returns whether a specified base location identifier is valid
    *
    * @param p_base_loc_id The base location identifier to verify
    *
    * @return Whether the specified base location identifier is valid
    */
	FUNCTION is_cwms_id_valid (p_base_loc_id IN VARCHAR2)
		RETURN BOOLEAN;
   -- not documented. CWMS 1.4
	PROCEDURE insert_loc (p_office_id		  IN VARCHAR2,
								 p_base_loc_id 	  IN VARCHAR2,
								 p_state_initial	  IN VARCHAR2 DEFAULT NULL,
								 p_county_name 	  IN VARCHAR2 DEFAULT NULL,
								 p_timezone_name	  IN VARCHAR2 DEFAULT NULL,
								 p_location_type	  IN VARCHAR2 DEFAULT NULL,
								 p_latitude 		  IN NUMBER DEFAULT NULL,
								 p_longitude		  IN NUMBER DEFAULT NULL,
								 p_elevation		  IN NUMBER DEFAULT NULL,
								 p_elev_unit_id	  IN VARCHAR2 DEFAULT NULL,
								 p_vertical_datum   IN VARCHAR2 DEFAULT NULL,
								 p_public_name 	  IN VARCHAR2 DEFAULT NULL,
								 p_long_name		  IN VARCHAR2 DEFAULT NULL,
								 p_description 	  IN VARCHAR2 DEFAULT NULL
								);
   -- not documented, use store_location
	PROCEDURE create_location (p_location_id			IN VARCHAR2,
										p_location_type		IN VARCHAR2 DEFAULT NULL,
										p_elevation 			IN NUMBER DEFAULT NULL,
										p_elev_unit_id 		IN VARCHAR2 DEFAULT NULL,
										p_vertical_datum		IN VARCHAR2 DEFAULT NULL,
										p_latitude				IN NUMBER DEFAULT NULL,
										p_longitude 			IN NUMBER DEFAULT NULL,
										p_horizontal_datum	IN VARCHAR2 DEFAULT NULL,
										p_public_name			IN VARCHAR2 DEFAULT NULL,
										p_long_name 			IN VARCHAR2 DEFAULT NULL,
										p_description			IN VARCHAR2 DEFAULT NULL,
										p_time_zone_id 		IN VARCHAR2 DEFAULT NULL,
										p_county_name			IN VARCHAR2 DEFAULT NULL,
										p_state_initial		IN VARCHAR2 DEFAULT NULL,
										p_active 				IN VARCHAR2 DEFAULT NULL,
										p_db_office_id 		IN VARCHAR2 DEFAULT NULL
									  );
   -- not documented, use store_location2
	PROCEDURE create_location2 (
		p_location_id				IN VARCHAR2,
		p_location_type			IN VARCHAR2 DEFAULT NULL,
		p_elevation 				IN NUMBER DEFAULT NULL,
		p_elev_unit_id 			IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum			IN VARCHAR2 DEFAULT NULL,
		p_latitude					IN NUMBER DEFAULT NULL,
		p_longitude 				IN NUMBER DEFAULT NULL,
		p_horizontal_datum		IN VARCHAR2 DEFAULT NULL,
		p_public_name				IN VARCHAR2 DEFAULT NULL,
		p_long_name 				IN VARCHAR2 DEFAULT NULL,
		p_description				IN VARCHAR2 DEFAULT NULL,
		p_time_zone_id 			IN VARCHAR2 DEFAULT NULL,
		p_county_name				IN VARCHAR2 DEFAULT NULL,
		p_state_initial			IN VARCHAR2 DEFAULT NULL,
		p_active 					IN VARCHAR2 DEFAULT NULL,
		p_location_kind_id		IN VARCHAR2 DEFAULT NULL,
		p_map_label 				IN VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN NUMBER DEFAULT NULL,
		p_published_longitude	IN NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	);
   -- not documented
	PROCEDURE create_location_raw (
		p_base_location_code 	  OUT NUMBER,
		p_location_code			  OUT NUMBER,
		p_base_location_id	  IN		VARCHAR2,
		p_sub_location_id 	  IN		VARCHAR2,
		p_db_office_code		  IN		NUMBER,
		p_location_type		  IN		VARCHAR2 DEFAULT NULL,
		p_elevation 			  IN		NUMBER DEFAULT NULL,
		p_vertical_datum		  IN		VARCHAR2 DEFAULT NULL,
		p_latitude				  IN		NUMBER DEFAULT NULL,
		p_longitude 			  IN		NUMBER DEFAULT NULL,
		p_horizontal_datum	  IN		VARCHAR2 DEFAULT NULL,
		p_public_name			  IN		VARCHAR2 DEFAULT NULL,
		p_long_name 			  IN		VARCHAR2 DEFAULT NULL,
		p_description			  IN		VARCHAR2 DEFAULT NULL,
		p_time_zone_code		  IN		NUMBER DEFAULT NULL,
		p_county_code			  IN		NUMBER DEFAULT NULL,
		p_active_flag			  IN		VARCHAR2 DEFAULT 'T'
	);
   -- not documented
	PROCEDURE create_location_raw2 (
		p_base_location_code 		OUT NUMBER,
		p_location_code				OUT NUMBER,
		p_base_location_id		IN 	 VARCHAR2,
		p_sub_location_id 		IN 	 VARCHAR2,
		p_db_office_code			IN 	 NUMBER,
		p_location_type			IN 	 VARCHAR2 DEFAULT NULL,
		p_elevation 				IN 	 NUMBER DEFAULT NULL,
		p_vertical_datum			IN 	 VARCHAR2 DEFAULT NULL,
		p_latitude					IN 	 NUMBER DEFAULT NULL,
		p_longitude 				IN 	 NUMBER DEFAULT NULL,
		p_horizontal_datum		IN 	 VARCHAR2 DEFAULT NULL,
		p_public_name				IN 	 VARCHAR2 DEFAULT NULL,
		p_long_name 				IN 	 VARCHAR2 DEFAULT NULL,
		p_description				IN 	 VARCHAR2 DEFAULT NULL,
		p_time_zone_code			IN 	 NUMBER DEFAULT NULL,
		p_county_code				IN 	 NUMBER DEFAULT NULL,
		p_active_flag				IN 	 VARCHAR2 DEFAULT 'T',
		p_location_kind_id		IN 	 VARCHAR2 DEFAULT NULL,
		p_map_label 				IN 	 VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN 	 NUMBER DEFAULT NULL,
		p_published_longitude	IN 	 NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN 	 VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN 	 VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN 	 VARCHAR2 DEFAULT NULL,
		p_db_office_id 			IN 	 VARCHAR2 DEFAULT NULL
	);
   -- not documented. CWMS 1.4
	PROCEDURE rename_loc (p_officeid 			IN VARCHAR2,
								 p_base_loc_id_old	IN VARCHAR2,
								 p_base_loc_id_new	IN VARCHAR2
								);
   /**
    * Renames a location in the database
    *
    * @param p_location_id_old The existing location identifier
    * @param p_location_id_new The new location identifier
    * @param p_db_office_id    The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE rename_location (p_location_id_old   IN VARCHAR2,
										p_location_id_new   IN VARCHAR2,
										p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
									  );
   -- not documented. CWMS 1.4
	PROCEDURE update_loc (
		p_office_id 		 IN VARCHAR2,
		p_base_loc_id		 IN VARCHAR2,
		p_location_type	 IN VARCHAR2 DEFAULT NULL,
		p_elevation 		 IN NUMBER DEFAULT NULL,
		p_elev_unit_id 	 IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum	 IN VARCHAR2 DEFAULT NULL,
		p_latitude			 IN NUMBER DEFAULT NULL,
		p_longitude 		 IN NUMBER DEFAULT NULL,
		p_public_name		 IN VARCHAR2 DEFAULT NULL,
		p_description		 IN VARCHAR2 DEFAULT NULL,
		p_timezone_id		 IN VARCHAR2 DEFAULT NULL,
		p_county_name		 IN VARCHAR2 DEFAULT NULL,
		p_state_initial	 IN VARCHAR2 DEFAULT NULL,
		p_ignorenulls		 IN NUMBER DEFAULT cwms_util.true_num
	);
   -- not documented. use store_location
	PROCEDURE update_location (p_location_id			IN VARCHAR2,
										p_location_type		IN VARCHAR2 DEFAULT NULL,
										p_elevation 			IN NUMBER DEFAULT NULL,
										p_elev_unit_id 		IN VARCHAR2 DEFAULT NULL,
										p_vertical_datum		IN VARCHAR2 DEFAULT NULL,
										p_latitude				IN NUMBER DEFAULT NULL,
										p_longitude 			IN NUMBER DEFAULT NULL,
										p_horizontal_datum	IN VARCHAR2 DEFAULT NULL,
										p_public_name			IN VARCHAR2 DEFAULT NULL,
										p_long_name 			IN VARCHAR2 DEFAULT NULL,
										p_description			IN VARCHAR2 DEFAULT NULL,
										p_time_zone_id 		IN VARCHAR2 DEFAULT NULL,
										p_county_name			IN VARCHAR2 DEFAULT NULL,
										p_state_initial		IN VARCHAR2 DEFAULT NULL,
										p_active 				IN VARCHAR2 DEFAULT NULL,
										p_ignorenulls			IN VARCHAR2 DEFAULT 'T',
										p_db_office_id 		IN VARCHAR2 DEFAULT NULL
									  );
   -- not documented. use store_location2
	PROCEDURE update_location2 (
		p_location_id				IN VARCHAR2,
		p_location_type			IN VARCHAR2 DEFAULT NULL,
		p_elevation 				IN NUMBER DEFAULT NULL,
		p_elev_unit_id 			IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum			IN VARCHAR2 DEFAULT NULL,
		p_latitude					IN NUMBER DEFAULT NULL,
		p_longitude 				IN NUMBER DEFAULT NULL,
		p_horizontal_datum		IN VARCHAR2 DEFAULT NULL,
		p_public_name				IN VARCHAR2 DEFAULT NULL,
		p_long_name 				IN VARCHAR2 DEFAULT NULL,
		p_description				IN VARCHAR2 DEFAULT NULL,
		p_time_zone_id 			IN VARCHAR2 DEFAULT NULL,
		p_county_name				IN VARCHAR2 DEFAULT NULL,
		p_state_initial			IN VARCHAR2 DEFAULT NULL,
		p_active 					IN VARCHAR2 DEFAULT NULL,
		p_location_kind_id		IN VARCHAR2 DEFAULT NULL,
		p_map_label 				IN VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN NUMBER DEFAULT NULL,
		p_published_longitude	IN NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN VARCHAR2 DEFAULT NULL,
		p_ignorenulls				IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	);
   -- not documented. CWMS 1.4
	PROCEDURE delete_loc (p_officeid IN VARCHAR2, p_base_loc_id IN VARCHAR2);
   /**
    * Deletes a location from the database
    *
    * @see constant cwms_util.delete_loc
    * @see constant cwms_util.delete_loc_cascade
    * @see constant cwms_util.delete_key
    * @see constant cwms_util.delete_data
    * @see constant cwms_util.delete_all
    * @see constant cwms_util.delete_ts_id
    * @see constant cwms_util.delete_ts_data
    * @see constant cwms_util.delete_ts_cascade
    *
    * @param p_location_id   The location identifier
    * @param p_delete_action Specifies what to delete.  Actions are as follows:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_delete_action</th>
    *     <th class="descr">Action</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_loc<br>cwms_util.delete_key</td>
    *     <td class="descr">deletes only this location, and then only if it has no associated dependent data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_data</td>
    *     <td class="descr">deletes only dependent data of this location, if any</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_ts_id</td>
    *     <td class="descr">deletes time series identifiers associated with this location, and then only if they have no time series data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_ts_data</td>
    *     <td class="descr">deletes time series data of all time series identifiers associated with this location, but not the time series identifiers themselves</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_ts_cascade</td>
    *     <td class="descr">deletes time series identifiers associated with this location, and all of their time series data, if any</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_loc_cascade<br>cwms_util.delete_all</td>
    *     <td class="descr">deletes this location and all dependent data, if any</td>
    *   </tr>
    * </table>
    * @param p_db_office_id  The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE delete_location (
		p_location_id		IN VARCHAR2,
		p_delete_action	IN VARCHAR2 DEFAULT cwms_util.delete_loc,
		p_db_office_id 	IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Deletes a location and all of its dependent data from the database
    *
    * @param p_location_id   The location identifier
    * @param p_db_office_id  The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE delete_location_cascade (
		p_location_id	  IN VARCHAR2,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Duplicates a location in the database
    *
    * @param p_location_id_old The existing location identifier
    * @param p_location_id_new The new location identifier
    * @param p_active          Specifies whether the new location is marked as active
    * @param p_db_office_id    The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE copy_location (p_location_id_old	IN VARCHAR2,
									 p_location_id_new	IN VARCHAR2,
									 p_active				IN VARCHAR2 DEFAULT 'T',
									 p_db_office_id		IN VARCHAR2 DEFAULT NULL
									);
   /**
    * Stores (inserts or updates) a location in the database
    *
    * @param p_location_id      The location identifier
    * @param p_location_type    A user-defined type for the location
    * @param p_elevation        The elevation of the location
    * @param p_elev_unit_id     The elevation unit
    * @param p_vertical_datum   The datum of the elevation
    * @param p_latitude         The actual latitude of the location
    * @param p_longitude        The actual longitude of the location
    * @param p_horizontal_datum The datum for the latitude and longitude
    * @param p_public_name      The public name for the location
    * @param p_long_name        The long name for the location
    * @param p_description      A description of the location
    * @param p_time_zone_id     The time zone name for the location
    * @param p_county_name      The name of the county that the location is in
    * @param p_state_initial    The two letter abbreviation of the state that the location is in
    * @param p_active           A flag ('T' or 'F') that specifies whether the location is marked as active
    * @param p_ignorenulls      A flag ('T' or 'F') that specifies whether to ignore NULL parameters. If 'F', existing data will be updated with NULL parameter values.
    * @param p_db_office_id     The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE store_location (p_location_id		  IN VARCHAR2,
									  p_location_type 	  IN VARCHAR2 DEFAULT NULL,
									  p_elevation			  IN NUMBER DEFAULT NULL,
									  p_elev_unit_id		  IN VARCHAR2 DEFAULT NULL,
									  p_vertical_datum	  IN VARCHAR2 DEFAULT NULL,
									  p_latitude			  IN NUMBER DEFAULT NULL,
									  p_longitude			  IN NUMBER DEFAULT NULL,
									  p_horizontal_datum   IN VARCHAR2 DEFAULT NULL,
									  p_public_name		  IN VARCHAR2 DEFAULT NULL,
									  p_long_name			  IN VARCHAR2 DEFAULT NULL,
									  p_description		  IN VARCHAR2 DEFAULT NULL,
									  p_time_zone_id		  IN VARCHAR2 DEFAULT NULL,
									  p_county_name		  IN VARCHAR2 DEFAULT NULL,
									  p_state_initial 	  IN VARCHAR2 DEFAULT NULL,
									  p_active				  IN VARCHAR2 DEFAULT NULL,
									  p_ignorenulls		  IN VARCHAR2 DEFAULT 'T',
									  p_db_office_id		  IN VARCHAR2 DEFAULT NULL
									 );
   /**
    * Stores (inserts or updates) a location in the database
    *
    * @param p_location_id         The location identifier
    * @param p_location_type       A user-defined type for the location
    * @param p_elevation           The elevation of the location
    * @param p_elev_unit_id        The elevation unit
    * @param p_vertical_datum      The datum of the elevation
    * @param p_latitude            The actual latitude of the location
    * @param p_longitude           The actual longitude of the location
    * @param p_horizontal_datum    The datum for the latitude and longitude
    * @param p_public_name         The public name for the location
    * @param p_long_name           The long name for the location
    * @param p_description         A description of the location
    * @param p_time_zone_id        The time zone name for the location
    * @param p_county_name         The name of the county that the location is in
    * @param p_state_initial       The two letter abbreviation of the state that the location is in
    * @param p_active              A flag ('T' or 'F') that specifies whether the location is marked as active
    * @param p_location_kind_id    The geographic type of the location
    * @param p_map_label           A label to be used on maps for location
    * @param p_published_latitude  The published latitude for the location
    * @param p_published_longitude The published longitude for the location
    * @param p_bounding_office_id  The office whose boundary encompasses the location
    * @param p_nation_id           The nation that the location is in
    * @param p_nearest_city        The name of the city nearest to the location
    * @param p_ignorenulls         A flag ('T' or 'F') that specifies whether to ignore NULL parameters. If 'F', existing data will be updated with NULL parameter values.
    * @param p_db_office_id        The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE store_location2 (
		p_location_id				IN VARCHAR2,
		p_location_type			IN VARCHAR2 DEFAULT NULL,
		p_elevation 				IN NUMBER DEFAULT NULL,
		p_elev_unit_id 			IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum			IN VARCHAR2 DEFAULT NULL,
		p_latitude					IN NUMBER DEFAULT NULL,
		p_longitude 				IN NUMBER DEFAULT NULL,
		p_horizontal_datum		IN VARCHAR2 DEFAULT NULL,
		p_public_name				IN VARCHAR2 DEFAULT NULL,
		p_long_name 				IN VARCHAR2 DEFAULT NULL,
		p_description				IN VARCHAR2 DEFAULT NULL,
		p_time_zone_id 			IN VARCHAR2 DEFAULT NULL,
		p_county_name				IN VARCHAR2 DEFAULT NULL,
		p_state_initial			IN VARCHAR2 DEFAULT NULL,
		p_active 					IN VARCHAR2 DEFAULT NULL,
		p_location_kind_id		IN VARCHAR2 DEFAULT NULL,
		p_map_label 				IN VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN NUMBER DEFAULT NULL,
		p_published_longitude	IN NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN VARCHAR2 DEFAULT NULL,
		p_ignorenulls				IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Retreives location information from the database
    *
    * @param p_location_id      The location identifier
    * @param p_elev_unit_id     The unit to retrieve the elevation in
    * @param p_location_type    A user-defined type for the location
    * @param p_elevation        The elevation of the location
    * @param p_vertical_datum   The datum of the elevation
    * @param p_latitude         The actual latitude of the location
    * @param p_longitude        The actual longitude of the location
    * @param p_horizontal_datum The datum for the latitude and longitude
    * @param p_public_name      The public name for the location
    * @param p_long_name        The long name for the location
    * @param p_description      A description of the location
    * @param p_time_zone_id     The time zone name for the location
    * @param p_county_name      The name of the county that the location is in
    * @param p_state_initial    The two letter abbreviation of the state that the location is in
    * @param p_active           A flag ('T' or 'F') that specifies whether the location is marked as active
    * @param p_alias_cursor     A cursor containing the aliases for the location. The columns are as follows, ordered by location_id, loc_category_id, and loc_group_id:
    * <p>
    * <table class="descr">
    *    <tr>
    *       <td class="descr-center">1</td>
    *       <td class="descr">db_office_id</td>
    *       <td class="descr">varchar2(16)</td>
    *       <td class="descr">The office that owns the location</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">2</td>
    *       <td class="descr">location_id</td>
    *       <td class="descr">varchar2(49)</td>
    *       <td class="descr">The location identifier</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">3</td>
    *       <td class="descr">cat_db_office_id</td>
    *       <td class="descr">varchar2(16)</td>
    *       <td class="descr">The office that owns the location category</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">4</td>
    *       <td class="descr">loc_category_id</td>
    *       <td class="descr">varchar2(32)</td>
    *       <td class="descr">The location category identifier</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">5</td>
    *       <td class="descr">grp_db_office_id</td>
    *       <td class="descr">varchar2(16)</td>
    *       <td class="descr">The office that owns the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">6</td>
    *       <td class="descr">loc_group_id</td>
    *       <td class="descr">varchar2(32)</td>
    *       <td class="descr">The location group identifier</td>
    *    </tr>
    *       <tr>
    *       <td class="descr-center">7</td>
    *       <td class="descr">loc_group_desc</td>
    *       <td class="descr">varchar2(256)</td>
    *       <td class="descr">A description of the location group</td>
    *    </tr>
    *       <tr>
    *       <td class="descr-center">8</td>
    *       <td class="descr">loc_alias_id</td>
    *       <td class="descr">varchar2(256)</td>
    *       <td class="descr">An alias for the location within the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">9</td>
    *       <td class="descr">ref_location_id</td>
    *       <td class="descr">varchar2(49)</td>
    *       <td class="descr">A referenced location for the location within the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">10</td>
    *       <td class="descr">shared_loc_alias_id</td>
    *       <td class="descr">varchar2(256)</td>
    *       <td class="descr">An alias that applies to all locatations in the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">11</td>
    *       <td class="descr">shared_loc_ref_id</td>
    *       <td class="descr">varchar2(49)</td>
    *       <td class="descr">A referenced location that applies to all locations within the location group</td>
    *    </tr>
    * </table>
    * @param p_db_office_id     The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE retrieve_location (
		p_location_id			IN OUT VARCHAR2,
		p_elev_unit_id 		IN 	 VARCHAR2 DEFAULT 'm',
		p_location_type			OUT VARCHAR2,
		p_elevation 				OUT NUMBER,
		p_vertical_datum			OUT VARCHAR2,
		p_latitude					OUT NUMBER,
		p_longitude 				OUT NUMBER,
		p_horizontal_datum		OUT VARCHAR2,
		p_public_name				OUT VARCHAR2,
		p_long_name 				OUT VARCHAR2,
		p_description				OUT VARCHAR2,
		p_time_zone_id 			OUT VARCHAR2,
		p_county_name				OUT VARCHAR2,
		p_state_initial			OUT VARCHAR2,
		p_active 					OUT VARCHAR2,
		p_alias_cursor 			OUT SYS_REFCURSOR,
		p_db_office_id 		IN 	 VARCHAR2 DEFAULT NULL
	);
   /**
    * Retreives location information from the database
    *
    * @param p_location_id         The location identifier
    * @param p_elev_unit_id        The unit to retrieve the elevation in
    * @param p_location_type       A user-defined type for the location
    * @param p_elevation           The elevation of the location
    * @param p_vertical_datum      The datum of the elevation
    * @param p_latitude            The actual latitude of the location
    * @param p_longitude           The actual longitude of the location
    * @param p_horizontal_datum    The datum for the latitude and longitude
    * @param p_public_name         The public name for the location
    * @param p_long_name           The long name for the location
    * @param p_description         A description of the location
    * @param p_time_zone_id        The time zone name for the location
    * @param p_county_name         The name of the county that the location is in
    * @param p_state_initial       The two letter abbreviation of the state that the location is in
    * @param p_active              A flag ('T' or 'F') that specifies whether the location is marked as active
    * @param p_location_kind_id    The geographic type of the location
    * @param p_map_label           A label to be used on maps for location
    * @param p_published_latitude  The published latitude for the location
    * @param p_published_longitude The published longitude for the location
    * @param p_bounding_office_id  The office whose boundary encompasses the location
    * @param p_nation_id           The nation that the location is in
    * @param p_nearest_city        The name of the city nearest to the location
    * @param p_alias_cursor        A cursor containing the aliases for the location. The columns are as follows, ordered by location_id, loc_category_id, and loc_group_id:
    * <p>
    * <table class="descr">
    *    <tr>
    *       <td class="descr-center">1</td>
    *       <td class="descr">db_office_id</td>
    *       <td class="descr">varchar2(16)</td>
    *       <td class="descr">The office that owns the location</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">2</td>
    *       <td class="descr">location_id</td>
    *       <td class="descr">varchar2(49)</td>
    *       <td class="descr">The location identifier</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">3</td>
    *       <td class="descr">cat_db_office_id</td>
    *       <td class="descr">varchar2(16)</td>
    *       <td class="descr">The office that owns the location category</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">4</td>
    *       <td class="descr">loc_category_id</td>
    *       <td class="descr">varchar2(32)</td>
    *       <td class="descr">The location category identifier</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">5</td>
    *       <td class="descr">grp_db_office_id</td>
    *       <td class="descr">varchar2(16)</td>
    *       <td class="descr">The office that owns the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">6</td>
    *       <td class="descr">loc_group_id</td>
    *       <td class="descr">varchar2(32)</td>
    *       <td class="descr">The location group identifier</td>
    *    </tr>
    *       <tr>
    *       <td class="descr-center">7</td>
    *       <td class="descr">loc_group_desc</td>
    *       <td class="descr">varchar2(256)</td>
    *       <td class="descr">A description of the location group</td>
    *    </tr>
    *       <tr>
    *       <td class="descr-center">8</td>
    *       <td class="descr">loc_alias_id</td>
    *       <td class="descr">varchar2(256)</td>
    *       <td class="descr">An alias for the location within the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">9</td>
    *       <td class="descr">ref_location_id</td>
    *       <td class="descr">varchar2(49)</td>
    *       <td class="descr">A referenced location for the location within the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">10</td>
    *       <td class="descr">shared_loc_alias_id</td>
    *       <td class="descr">varchar2(256)</td>
    *       <td class="descr">An alias that applies to all locatations in the location group</td>
    *    </tr>
    *    <tr>
    *       <td class="descr-center">11</td>
    *       <td class="descr">shared_loc_ref_id</td>
    *       <td class="descr">varchar2(49)</td>
    *       <td class="descr">A referenced location that applies to all locations within the location group</td>
    *    </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A numeric attribute for the location with respect to the group. Can be used for sorting, etc...</td>
    *   </tr>
    * </table>
    * @param p_db_office_id     The office that owns the location. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE retrieve_location2 (
		p_location_id				IN OUT VARCHAR2,
		p_elev_unit_id 			IN 	 VARCHAR2 DEFAULT 'm',
		p_location_type				OUT VARCHAR2,
		p_elevation 					OUT NUMBER,
		p_vertical_datum				OUT VARCHAR2,
		p_latitude						OUT NUMBER,
		p_longitude 					OUT NUMBER,
		p_horizontal_datum			OUT VARCHAR2,
		p_public_name					OUT VARCHAR2,
		p_long_name 					OUT VARCHAR2,
		p_description					OUT VARCHAR2,
		p_time_zone_id 				OUT VARCHAR2,
		p_county_name					OUT VARCHAR2,
		p_state_initial				OUT VARCHAR2,
		p_active 						OUT VARCHAR2,
		p_location_kind_id			OUT VARCHAR2,
		p_map_label 					OUT VARCHAR2,
		p_published_latitude 		OUT NUMBER,
		p_published_longitude		OUT NUMBER,
		p_bounding_office_id 		OUT VARCHAR2,
		p_nation_id 					OUT VARCHAR2,
		p_nearest_city 				OUT VARCHAR2,
		p_alias_cursor 				OUT SYS_REFCURSOR,
		p_db_office_id 			IN 	 VARCHAR2 DEFAULT NULL
	);
   -- not documeneted. use should be restricted
	PROCEDURE create_location_kind (p_location_kind_id   IN VARCHAR2,
											  p_description		  IN VARCHAR2
											 );
   -- not documeneted. use should be restricted
	PROCEDURE update_location_kind (p_location_kind_id   IN VARCHAR2,
											  p_description		  IN VARCHAR2
											 );
   -- not documeneted. use should be restricted
	PROCEDURE delete_location_kind (p_location_kind_id IN VARCHAR2);
   /**
    * Retreives the time zone of a location
    *
    * @param p_location_code The unique numeric code that identifies the location
    *
    * @return The local time zone for the specified location
    */
	FUNCTION get_local_timezone (p_location_code IN NUMBER)
		RETURN VARCHAR2;
   /**
    * Retreives the time zone of a location
    *
    * @param p_location_id The location identifier
    * @param p_office_id   The office that owns the location. If not specified or NULL, the session user's default office will be used
    *
    * @return The local time zone for the specified location
    */
	FUNCTION get_local_timezone (p_location_id	IN VARCHAR2,
										  p_office_id		IN VARCHAR2
										 )
      RETURN VARCHAR2;
   -- not documented. use store_loc_group
   PROCEDURE create_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_loc_group_desc 	IN VARCHAR2 DEFAULT NULL,
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										);
   -- not documented. use store_loc_group
	PROCEDURE create_loc_group2 (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_group_id 		 IN VARCHAR2,
		p_loc_group_desc		 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL,
		p_shared_alias_id 	 IN VARCHAR2 DEFAULT NULL,
		p_shared_loc_ref_id	 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Stores (inserts or updates) a location group to the database
    *
    * @param p_loc_category_id   The location category identifier (parent of location group)
    * @param p_loc_group_id      The location group identifier
    * @param p_loc_group_desc    A description of the location group
    * @param p_fail_if_exists    A flag ('T' or 'F') that specifies whether the routine should fail if the location group already exists
    * @param p_ignore_nulls      A flag ('T' or 'F') that specifies whether to ignore NULL parameters when updating and existing location group
    * @param p_shared_alias_id   An alias shared by all locations in the location group
    * @param p_shared_loc_ref_id A location identifier
    * @param p_db_office_id      The office that owns the location group. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE store_loc_group (p_loc_category_id 	 IN VARCHAR2,
										p_loc_group_id 		 IN VARCHAR2,
										p_loc_group_desc		 IN VARCHAR2 DEFAULT NULL,
										p_fail_if_exists		 IN VARCHAR2 DEFAULT 'F',
										p_ignore_nulls 		 IN VARCHAR2 DEFAULT 'T',
										p_shared_alias_id 	 IN VARCHAR2 DEFAULT NULL,
										p_shared_loc_ref_id	 IN VARCHAR2 DEFAULT NULL,
										p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
									  );
   /**
    * Renames a location group in the database
    *
    * @param p_loc_category_id   The location category identifier (parent of location group)
    * @param p_loc_group_id_old  The existing location group identifier
    * @param p_loc_group_id_new  The new location group identifier
    * @param p_loc_group_desc    A description of the location group
    * @param p_ignore_null       A flag ('T' or 'F') that specifies whether to ignore NULL description
    * @param p_db_office_id      The office that owns the location group. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE rename_loc_group (p_loc_category_id	 IN VARCHAR2,
										 p_loc_group_id_old	 IN VARCHAR2,
										 p_loc_group_id_new	 IN VARCHAR2,
										 p_loc_group_desc 	 IN VARCHAR2 DEFAULT NULL,
										 p_ignore_null 		 IN VARCHAR2 DEFAULT 'T',
										 p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										);
   -- not documented. use store_loc_category
	PROCEDURE create_loc_category (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	);
   -- not documented. use store_loc_category
	FUNCTION create_loc_category_f (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER;
   /**
    * Stores (inserts or updates) a location category to the database
    *
    * @param p_loc_category_id   The location category identifier
    * @param p_loc_category_desc A description of the location category
    * @param p_fail_if_exists    A flag ('T' or 'F') that specifies whether the routine should fail if the location category already exists
    * @param p_ignore_null       A flag ('T' or 'F') that specifies whether to ignore NULL description when updating
    * @param p_db_office_id      The office that owns the location category. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE store_loc_category (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_fail_if_exists		 IN VARCHAR2 DEFAULT 'F',
		p_ignore_null			 IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	);
   -- not documented. use store_loc_category
	FUNCTION store_loc_category_f (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_fail_if_exists		 IN VARCHAR2 DEFAULT 'F',
		p_ignore_null			 IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER;
   /**
    * Deletes a location group from the database
    *
    * @param p_loc_category_id  The location category identifier (parent of location group)
    * @param p_loc_group_id     The location group identifier
    * @param p_db_office_id     The office that owns the location group. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE delete_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										);
   /**
    * Deletes a location group from the database
    *
    * @param p_loc_category_id  The location category identifier (parent of location group)
    * @param p_loc_group_id     The location group identifier
    * @param p_cascade          A flag ('T' or 'F') that specifies whether to unassign any location assignments
    * @param p_db_office_id     The office that owns the location group. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE delete_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_cascade              IN VARCHAR2 DEFAULT 'F',
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										);
   /**
    * Deletes a location category from the database
    *
    * @param p_loc_category_id  The location category identifier (parent of location group)
    * @param p_cascade          A flag ('T' or 'F') that specifies whether to delete any location groups in this location category
    * @param p_db_office_id     The office that owns the location category. If not specified or NULL, the session user's default office will be used
    */
	PROCEDURE delete_loc_cat (p_loc_category_id	 IN VARCHAR2,
									  p_cascade 			 IN VARCHAR2 DEFAULT 'F',
									  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
									 );
   /**
    * Assigns a location to a location group, optionally assigning an alias
    *
    * @param p_loc_category_id The location category identifier that contains the location group
    * @param p_loc_group_id    The location group identifier
    * @param p_location_id     The location identifier to assign to the location group
    * @param p_loc_alias_id    The alias, if any, that applies to the location in the context of the location group
    * @param p_db_office_id    The office that owns the locaation category, location group, and location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_location_id 		IN VARCHAR2,
										 p_loc_alias_id		IN VARCHAR2 DEFAULT NULL,
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										);
   /**
    * Assigns a location to a location group, optionally assigning an alias and attribute
    *
    * @param p_loc_category_id The location category identifier that contains the location group
    * @param p_loc_group_id    The location group identifier
    * @param p_location_id     The location identifier to assign to the location group
    * @param p_loc_attribute   A numeric value that is used for the location in the context of the location group. Can be used for sorting or other purposes
    * @param p_loc_alias_id    The alias, if any, that applies to the location in the context of the location group
    * @param p_db_office_id    The office that owns the locaation category, location group, and location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_group2 (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_location_id		 IN VARCHAR2,
										  p_loc_attribute 	 IN NUMBER DEFAULT NULL,
										  p_loc_alias_id		 IN VARCHAR2 DEFAULT NULL,
										  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										 );
   /**
    * Assigns a location to a location group, optionally assigning an alias, attribute, and referenced location
    *
    * @param p_loc_category_id The location category identifier that contains the location group
    * @param p_loc_group_id    The location group identifier
    * @param p_location_id     The location identifier to assign to the location group
    * @param p_loc_attribute   A numeric value that is used for the location in the context of the location group. Can be used for sorting or other purposes
    * @param p_loc_alias_id    The alias, if any, that applies to the location in the context of the location group
    * @param p_ref_loc_id      A location identifier, if any, that is referenced from the location in the context of the location group
    * @param p_db_office_id    The office that owns the locaation category, location group, and location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_group3 (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_location_id		 IN VARCHAR2,
										  p_loc_attribute 	 IN NUMBER DEFAULT NULL,
										  p_loc_alias_id		 IN VARCHAR2 DEFAULT NULL,
										  p_ref_loc_id 		 IN VARCHAR2 DEFAULT NULL,
										  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										 );
   /**
    * Assigns one ore more locations to a location group, optionally assigning aliases
    *
    * @param p_loc_category_id The location category identifier that contains the location group
    * @param p_loc_group_id    The location group identifier
    * @param p_loc_alias_array The locations to assign to the group
    * @param p_db_office_id    The office that owns the locaation category, location group, and location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_groups (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_loc_alias_array	 IN loc_alias_array,
										  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										 );
   /**
    * Assigns one ore more locations to a location group, optionally assigning aliases and attributes
    *
    * @param p_loc_category_id The location category identifier that contains the location group
    * @param p_loc_group_id    The location group identifier
    * @param p_loc_alias_array The locations to assign to the group
    * @param p_db_office_id    The office that owns the locaation category, location group, and location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_groups2 (p_loc_category_id   IN VARCHAR2,
											p_loc_group_id 	  IN VARCHAR2,
											p_loc_alias_array   IN loc_alias_array2,
											p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
										  );
   /**
    * Assigns one ore more locations to a location group, optionally assigning aliases, attributes, and referenced locations
    *
    * @param p_loc_category_id The location category identifier that contains the location group
    * @param p_loc_group_id    The location group identifier
    * @param p_loc_alias_array The locations to assign to the group
    * @param p_db_office_id    The office that owns the locaation category, location group, and location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_groups3 (p_loc_category_id   IN VARCHAR2,
											p_loc_group_id 	  IN VARCHAR2,
											p_loc_alias_array   IN loc_alias_array3,
											p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
										  );
   /**
    * Renames a location category
    *
    * @param p_loc_category_id_old The existing location category identifier
    * @param p_loc_category_id_new The new locatio category identifier
    * @param p_loc_category_desc   A description of the location category
    * @param p_ignore_null         A flag ('T' or 'F') that specifies whether to ignore a NULL description
    * @param p_db_office_id        The office that owns the location category. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE rename_loc_category (
		p_loc_category_id_old	IN VARCHAR2,
		p_loc_category_id_new	IN VARCHAR2,
		p_loc_category_desc		IN VARCHAR2 DEFAULT NULL,
		p_ignore_null				IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	);
   -- not documented. use store_loc_group
	PROCEDURE assign_loc_grp_cat (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_id 	  IN VARCHAR2,
		p_loc_group_desc	  IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Stores (inserts or updates) one or more location groups in a common location category
    *
    * @param p_loc_category_id  The location category identifer
    * @param p_loc_group_array  The location groups to store
    * @param p_db_office_id     The office that owns the location category. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_grps_cat (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_array   IN group_array,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	);
   -- not documented. use store_loc_group
	PROCEDURE assign_loc_grp_cat2 (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_group_id 		 IN VARCHAR2,
		p_loc_group_desc		 IN VARCHAR2 DEFAULT NULL,
		p_shared_alias_id 	 IN VARCHAR2 DEFAULT NULL,
		p_shared_loc_ref_id	 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Stores (inserts or updates) one or more location groups in a common location category
    *
    * @param p_loc_category_id  The location category identifer
    * @param p_loc_group_array  The location groups to store
    * @param p_db_office_id     The office that owns the location category. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE assign_loc_grps_cat2 (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_array   IN group_array2,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Unassigns a location, or all locations, from a location group
    *
    * @param p_loc_category_id The location category identifier
    * @param p_loc_group_id    The location group identifier
    * @param p_location_id     The location identifier of the location to unassign. Can be NULL if p_unassign_all is 'T'
    * @param p_unassign_all    A flag ('T' or 'F') specifying whether to unassign all locations from the specified group
    * @param p_db_office_id    The office that owns the location.  If not specified or NULL the session user's default office is used
    */
	PROCEDURE unassign_loc_group (p_loc_category_id   IN VARCHAR2,
											p_loc_group_id 	  IN VARCHAR2,
											p_location_id		  IN VARCHAR2,
											p_unassign_all 	  IN VARCHAR2 DEFAULT 'F',
											p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
										  );
   /**
    * Unassigns one or more locations, or all locations, from a location group
    *
    * @param p_loc_category_id The location category identifier
    * @param p_loc_group_id    The location group identifier
    * @param p_location_array  The location identifiers of the locations to unassign. Can be NULL if p_unassign_all is 'T'
    * @param p_unassign_all    A flag ('T' or 'F') specifying whether to unassign all locations from the specified group
    * @param p_db_office_id    The office that owns the locations.  If not specified or NULL the session user's default office is used
    */
	PROCEDURE unassign_loc_groups (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_id 	  IN VARCHAR2,
		p_location_array	  IN char_49_array_type,
		p_unassign_all 	  IN VARCHAR2 DEFAULT 'F',
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	);
   -- not docuemented
	FUNCTION num_group_assigned_to_shef (
		p_group_cat_array   IN group_cat_tab_t,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER;
   /**
    * Retrieves a location from the database
    *
    * @param p_location_code The unique numeric code that identifies the location
    *
    * @return The location
    */
	FUNCTION retrieve_location (p_location_code IN NUMBER)
		RETURN location_obj_t;
   /**
    * Retrieves a location from the database
    *
    * @param p_location_id  The location identifier
    * @param p_db_office_id The office that owns the loation. If not specified or NULL the session user's default office will be used
    *
    * @return The location
    */
	FUNCTION retrieve_location (p_location_id 	IN VARCHAR2,
										 p_db_office_id	IN VARCHAR2 DEFAULT NULL
										)
		RETURN location_obj_t;
   /**
    * Stores a location to the database
    *
    * @param p_location       The location to store
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the location already exists in the database
    */
	PROCEDURE store_location (p_location			IN location_obj_t,
									  p_fail_if_exists	IN VARCHAR2 DEFAULT 'T'
									 );
   -- not documented
	FUNCTION store_location_f (p_location			 IN location_obj_t,
										p_fail_if_exists	 IN VARCHAR2 DEFAULT 'T'
									  )
		RETURN NUMBER;
   /**
    * Retrieves the location identifier for an alias
    *
    * @param p_alias_id    The location alias
    * @param p_group_id    The location group identifier. If not specified or NULL, all groups in the specified category are searched
    * @param p_category_id The location category identifier of the category the loction group belongs to. If not specified or NULL, all categories are searched
    * @param p_office_id   The office that owns the location group.  If not specified or NULL the session user's default office will be used
    */
	FUNCTION get_location_id_from_alias (
		p_alias_id		 IN VARCHAR2,
		p_group_id		 IN VARCHAR2 DEFAULT NULL,
		p_category_id	 IN VARCHAR2 DEFAULT NULL,
		p_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN VARCHAR2;
   -- not documented
	FUNCTION get_location_code_from_alias (
		p_alias_id		 IN VARCHAR2,
		p_group_id		 IN VARCHAR2 DEFAULT NULL,
		p_category_id	 IN VARCHAR2 DEFAULT NULL,
		p_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER;
   /**
    * Checks an alias for suitability within a location group. This procedure raises an exception
    * if the alias is not suitable
    *
    * @see cwms_property
    *
    * @param p_alias_id     The alias to check
    * @param p_location_id  The location identifier to check the alias for
    * @param p_category_id  The location category identifier
    * @param p_group_id     The location group identifer
    * @param p_office_id    The office that owns the location group.  If not specified or NULL the session user's default office will be used
    *
    * @exception ERROR if the specified alias is already in use for another location identifier within the group
    * @exception ERROR if the specified alias is already in use for any location in another group, and the
    * CWMS databse property 'CWMSDB'/'Allow_multiple_locations_for_alias' is not 'T'
    */
	PROCEDURE check_alias_id (p_alias_id		IN VARCHAR2,
									  p_location_id	IN VARCHAR2,
									  p_category_id	IN VARCHAR2,
									  p_group_id		IN VARCHAR2,
									  p_office_id		IN VARCHAR2 DEFAULT NULL
									 );
   /**
    * Checks an alias for suitability within a location group. This procedure raises an exception
    * if the alias is not suitable
    *
    * @see cwms_property
    *
    * @param p_alias_id     The alias to check
    * @param p_location_id  The location identifier to check the alias for
    * @param p_category_id  The location category identifier
    * @param p_group_id     The location group identifer
    * @param p_office_id    The office that owns the location group.  If not specified or NULL the session user's default office will be used
    *
    * @return The alias, if it is suitable
    *
    * @exception ERROR if the specified alias is already in use for another location identifier within the group
    * @exception ERROR if the specified alias is already in use for any location in another group, and the
    * CWMS databse property 'CWMSDB'/'Allow_multiple_locations_for_alias' is not 'T'
    */
	FUNCTION check_alias_id_f (p_alias_id		 IN VARCHAR2,
										p_location_id	 IN VARCHAR2,
										p_category_id	 IN VARCHAR2,
										p_group_id		 IN VARCHAR2,
										p_office_id 	 IN VARCHAR2 DEFAULT NULL
									  )
		RETURN VARCHAR2;
   /**
    * Stores (inserts or updates) a URL associated with a location. Locations may have many associated URLs, each
    * with their own identifier.  Multiple locations may use the same URL identifier to refer to URLs
    *
    * @param p_location_id    The location identifier to be associated with the ULR
    * @param p_url_id         The URL identifier
    * @param p_url_address    The actual URL
    * @param p_fail_if_exists A flag ('T' or 'F') specifying whether the routine should fail if a URL is already associated with the location
    * @param p_ignore_nulls   A flag ('T' or 'F') specifying whether to ignore NULL parameters when updating
    * @param p_url_title      A title to be used with the URL
    * @param p_office_id      The office that owns the location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE store_url (p_location_id		 IN VARCHAR2,
								p_url_id 			 IN VARCHAR2,
								p_url_address		 IN VARCHAR2,
								p_fail_if_exists	 IN VARCHAR2,
								p_ignore_nulls 	 IN VARCHAR2,
								p_url_title 		 IN VARCHAR2 DEFAULT NULL,
								p_office_id 		 IN VARCHAR2 DEFAULT NULL
							  );
   /**
    * Retrieves a URL associated with a location. Locations may have many associated URLs, each
    * with their own identifier.  Multiple locations may use the same URL identifier to refer to URLs
    *
    * @param p_url_address    The actual URL
    * @param p_url_title      A title to be used with the URL
    * @param p_location_id    The location identifier
    * @param p_url_id         The URL identifier
    * @param p_office_id      The office that owns the location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE retrieve_url (p_url_address		 OUT VARCHAR2,
									p_url_title 		 OUT VARCHAR2,
									p_location_id	 IN	  VARCHAR2,
									p_url_id 		 IN	  VARCHAR2,
									p_office_id 	 IN	  VARCHAR2 DEFAULT NULL
								  );
   /**
    * Deletes a URL associated with a location. Locations may have many associated URLs, each
    * with their own identifier.  Multiple locations may use the same URL identifier to refer to URLs
    *
    * @param p_location_id    The location identifier
    * @param p_url_id         The URL identifier. If NULL, all URLs associated with the location are deleted.
    * @param p_office_id      The office that owns the location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE delete_url (p_location_id   IN VARCHAR2,
								 p_url_id		  IN VARCHAR2, 		-- NULL = all urls
								 p_office_id	  IN VARCHAR2 DEFAULT NULL
								);
   /**
    * Renames a URL associated with a location. Locations may have many associated URLs, each
    * with their own identifier.  Multiple locations may use the same URL identifier to refer to URLs
    *
    * @param p_location_id    The location identifier
    * @param p_old_url_id     The existing URL identifier
    * @param p_new_url_id     The new URL identifier
    * @param p_office_id      The office that owns the location. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE rename_url (p_location_id   IN VARCHAR2,
								 p_old_url_id	  IN VARCHAR2,
								 p_new_url_id	  IN VARCHAR2,
								 p_office_id	  IN VARCHAR2 DEFAULT NULL
								);
   /**
    * Catalogs location URLs in the database that match input parameters. Matching is
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
    * @param p_url_catalog A cursor containing all matching URLs.  The cursor contains
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
    *     <td class="descr">The office owning the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">url_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The URL identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">url_address</td>
    *     <td class="descr">varchar2(1024)</td>
    *     <td class="descr">The actual URL</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">url_title</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The title to be used with the URL</td>
    *   </tr>
    * </table>
    *
    * @param p_location_id_mask  The location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_url_id_mask  The URL identifier pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_url_address_mask  The URL address pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_url_title_mask  The URL title pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_office_id_mask  The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    */
	PROCEDURE cat_urls (p_url_catalog			  OUT SYS_REFCURSOR,
							  p_location_id_mask   IN		VARCHAR2 DEFAULT '*',
							  p_url_id_mask		  IN		VARCHAR2 DEFAULT '*',
							  p_url_address_mask   IN		VARCHAR2 DEFAULT '*',
							  p_url_title_mask	  IN		VARCHAR2 DEFAULT '*',
							  p_office_id_mask	  IN		VARCHAR2 DEFAULT NULL
							 );
   /**
    * Catalogs location URLs in the database that match input parameters. Matching is
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
    * @param p_location_id_mask  The location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_url_id_mask  The URL identifier pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_url_address_mask  The URL address pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_url_title_mask  The URL title pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_office_id_mask  The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @return A cursor containing all matching URLs.  The cursor contains
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
    *     <td class="descr">The office owning the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">url_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The URL identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">url_address</td>
    *     <td class="descr">varchar2(1024)</td>
    *     <td class="descr">The actual URL</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">url_title</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The title to be used with the URL</td>
    *   </tr>
    * </table>
    */
	FUNCTION cat_urls_f (p_location_id_mask	IN VARCHAR2 DEFAULT '*',
								p_url_id_mask			IN VARCHAR2 DEFAULT '*',
								p_url_address_mask	IN VARCHAR2 DEFAULT '*',
								p_url_title_mask		IN VARCHAR2 DEFAULT '*',
								p_office_id_mask		IN VARCHAR2 DEFAULT NULL
							  )
		RETURN SYS_REFCURSOR;
   /**
    * Retrieves the type of the location
    *
    * @param p_location_code The unique numeric code that identifies the location
    *
    * @return A string identifying the type of the location. Will be one of:
    * <ul>
    *   <li>BASIN</li>
    *   <li>STREAM</li>
    *   <li>OUTLET</li>
    *   <li>TURBINE</li>
    *   <li>PROJECT</li>
    *   <li>EMBANKMENT</li>
    *   <li>LOCK</li>
    *   <li>NONE</li>
    * </ul>
    */
   function get_location_type(
      p_location_code in number)
      return varchar2;
   /**
    * Retrieves the type of the location
    *
    * @param p_location_id The location identifier
    * @param p_office_id   The office that owns the location. If not specified or NULL, the session user's default office will be used
    *
    * @return A string identifying the type of the location. Will be one of:
    * <ul>
    *   <li>BASIN</li>
    *   <li>STREAM</li>
    *   <li>OUTLET</li>
    *   <li>TURBINE</li>
    *   <li>PROJECT</li>
    *   <li>EMBANKMENT</li>
    *   <li>LOCK</li>
    *   <li>NONE</li>
    * </ul>
    */
   function get_location_type(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2;
   /**
    * Stores (inserts or updates) a vertical datum offset to the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id         The location the offset applies to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_offset              The offset that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
    * @param p_unit                The unit of the offset
    * @param p_effective_date      The date and time the offset became effective.  If not specified, the date 01-JAN-1000 representing 'far in the past' is used.
    * @param p_time_zone           The time zone of the effective date field. If not speciifed or NULL, the location's local time zone is used.
    * @param p_description         A description of the offset
    * @param p_fail_if_exists      A flag ('T'/'F') specifying whether to fail if a vertical datum offset already exists for the location and vertical datum identifers
    * @param p_office_id           The offset that owns the location.  If not specified or NULL the session user's default office is used.
    */
   procedure store_vertical_datum_offset(
      p_location_id         in varchar2,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_offset              in binary_double,
      p_unit                in varchar2,
      p_effective_date      in date default date '1000-01-01',
      p_time_zone           in varchar2 default null,
      p_description         in varchar2 default null,
      p_fail_if_exists      in varchar2 default 'T',
      p_office_id           in varchar2 default null);
   /**
    * Stores (inserts or updates) a vertical datum offset to the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_vertical_datum_offset  The vertical datum offset to store.
    * @param p_fail_if_exists         A flag ('T'/'F') specifying whether to fail if a vertical datum offset already exists for the location and vertical datum identifers
    *
    * @see type vert_datum_offset_t
    */
   procedure store_vertical_datum_offset(
      p_vertical_datum_offset in vert_datum_offset_t,
      p_fail_if_exists        in varchar2 default 'T');
   /**
    * Retrieves a vertical datum offset from the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_offset               The value of the offset
    * @param p_unit_out             The unit of the offset
    * @param p_description          A description of the offset
    * @param p_effective_date_out   The effective date of the offset, in the time zone specified or indicated by p_time_zone
    * @param p_location_id          The location the offset applies to
    * @param p_vertical_datum_id_1  The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2  The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_effective_date_in    The effective date to use, depending on the value of p_match_effective_date. If p_match_effective_date is 'T' then this parameter, combined with p_time_zone, specifies
    *                               the actual effective date of the datum offset. If p_match_effective_date is 'F', then this parameter, combined with p_time_zone specifies
    *                               retrieving the latest effective date on or before this parameter.  If not specified or NULL, the current date and time is used.
    * @param p_time_zone            The time zone of the effective date field. If not speciifed or NULL, the location's local time zone is used, unless p_effective_date is also unspecified or NULL, in which
    *                               case the effective date is returned in UTC.
    * @param p_unit_in              The desired unit of the offset. If not specifed or NULL, the offset will be return with the storage unit of 'm'.
    * @param p_match_effective_date A flag ('T'/'F') that specifies whether the p_effective_date_in parameter is an actual effective date ('T') or a maximum effective date ('F').
    * @param p_office_id            The offset that owns the location.  If not specified or NULL the session user's default office is used.
    */
   procedure retrieve_vertical_datum_offset(
      p_offset               out binary_double,
      p_unit_out             out varchar2,
      p_description          out varchar2,
      p_effective_date_out   out date,
      p_location_id          in  varchar2,
      p_vertical_datum_id_1  in  varchar2,
      p_vertical_datum_id_2  in  varchar2,
      p_effective_date_in    in  date     default null,
      p_time_zone            in  varchar2 default null,
      p_unit_in              in  varchar2 default null,
      p_match_effective_date in  varchar2 default 'F',
      p_office_id            in  varchar2 default null);
   /**
    * Retrieves a vertical datum offset from the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id          The location the offset applies to
    * @param p_vertical_datum_id_1  The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2  The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_effective_date_in    The effective date to use, depending on the value of p_match_effective_date. If p_match_effective_date is 'T' then this parameter, combined with p_time_zone, specifies
    *                               the actual effective date of the datum offset. If p_match_effective_date is 'F', then this parameter, combined with p_time_zone specifies
    *                               retrieving the latest effective date on or before this parameter.  If not specified or NULL, the current date and time is used.
    * @param p_time_zone            The time zone of the effective date field. If not speciifed or NULL, the location's local time zone is used, unless p_effective_date is also unspecified or NULL, in which
    *                               case the effective date is returned in UTC.
    * @param p_unit                 The desired unit of the offset. If not specifed or NULL, the offset will be return with the storage unit of 'm'.
    * @param p_match_effective_date A flag ('T'/'F') that specifies whether the p_effective_date_in parameter is an actual effective date ('T') or a maximum effective date ('F').
    * @param p_office_id            The offset that owns the location.  If not specified or NULL the session user's default office is used.
    *
    * @see type vert_datum_offset_t
    */
   function retrieve_vertical_datum_offset(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date_in    in date     default null,
      p_time_zone            in varchar2 default null,
      p_unit                 in varchar2 default null,
      p_match_effective_date in varchar2 default 'F',
      p_office_id            in varchar2 default null)
      return vert_datum_offset_t;
   /**
    * Deletes a vertical datum offset from the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id          The location the offset applies to
    * @param p_vertical_datum_id_1  The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2  The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_effective_date_in    The effective date to use, depending on the value of p_match_effective_date. If p_match_effective_date is 'T' then this parameter, combined with p_time_zone, specifies
    *                               the actual effective date of the datum offset. If p_match_effective_date is 'F', then this parameter, combined with p_time_zone specifies
    *                               retrieving the latest effective date on or before this parameter.  If not specified or NULL, the current date and time is used.
    * @param p_time_zone            The time zone of the effective date field. If not speciifed or NULL, the location's local time zone is used, unless p_effective_date is also unspecified or NULL, in which
    *                               case this parameter defaults to 'UTC'.
    * @param p_match_effective_date A flag ('T'/'F') that specifies whether the p_effective_date_in parameter is an actual effective date ('T') or a maximum effective date ('F').
    * @param p_office_id            The offset that owns the location.  If not specified or NULL the session user's default office is used.
    *
    * @see type vert_datum_offset_t
    */
   procedure delete_vertical_datum_offset(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date_in    in date     default null,
      p_time_zone            in varchar2 default null,
      p_match_effective_date in varchar2 default 'T',
      p_office_id            in varchar2 default null);
   /**
    * Retrieves a vertical datum offset value in meters and effective date in UTC from the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_offset              The offset in meters that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
    * @param p_effective_date      The effective date of the offset
    * @param p_estimate            A flag (T/F) specifying whether the returned offset is an estimate
    * @param p_location_code       The numeric code that refers to the location the offset applies to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_datetime_utc        The date of applicability of the offset. The offset returned will be the one having the latest effective date on or before this parameter. If not specified, the current time is used.
    */
   procedure get_vertical_datum_offset(   
      p_offset              out binary_double, 
      p_effective_date      out date,
      p_estimate            out varchar2,
      p_location_code       in  number,
      p_vertical_datum_id_1 in  varchar2,   
      p_vertical_datum_id_2 in  varchar2,
      p_datetime_utc        in  date default sysdate); 
   /**
    * Retrieves a collection vertical datum offset values in meters and effective dates in UTC from the database for a location and time window
    *
    * @since CWMS 2.2
    *
    * @param p_location_code       The numeric code that refers to the location the offsets apply to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_start_time_utc      The beginning of the time window. The earliest effective date retrieved will be in effect on this date.
    * @param p_end_time_utc        The end of the time window.  The latest effective date retrieved will be in effect on this date.
    * 
    * @return The datum offsets values and effective dates. For each item the date_time field contains the effective_date in UTC and the value field contains the datum offset in meters.  The quality field is not used.
    *
    * @see type ztsv_array
    */
   function get_vertical_datum_offsets(
      p_location_code       in number,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_start_time_utc      in date,
      p_end_time_utc        in date)
      return ztsv_array;        
   /**
    * Retrieves a collection vertical datum offset values in meters and effective dates in UTC from the database for a location and time window
    *
    * @since CWMS 2.2
    *
    * @param p_offsets             The datum offsets values and effective dates. For each item the date_time field contains the effective_date in UTC and the value field contains the datum offset in meters.  The quality field is not used.
    * @param p_location_code       The numeric code that refers to the location the offsets apply to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_start_time_utc      The beginning of the time window. The earliest effective date retrieved will be in effect on this date.
    * @param p_end_time_utc        The end of the time window.  The latest effective date retrieved will be in effect on this date.
    * 
    * @see type ztsv_array
    */
   procedure get_vertical_datum_offsets(  
      p_offsets             out ztsv_array,
      p_location_code       in  number,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_start_time_utc      in  date,
      p_end_time_utc        in  date);        
   /**
    * Retrieves a vertical datum offset value in a specified unit from the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id         The unique numeric code of the location the offset applies to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_datetime_utc        The date of applicability of the offset. The offset returned will be the one having the latest effective date on or before this parameter.
    *                              If not specified, the current date and time will be used.
    * @param p_unit                The unit to retrieve the offset in.  If not specified or NULL, the offset will be returned in meters.
    * 
    * @return The offset in the specified unit that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
    */
   function get_vertical_datum_offset(
      p_location_code       in number,
      p_vertical_datum_id_1 in varchar2,   
      p_vertical_datum_id_2 in varchar2, 
      p_datetime_utc        in date     default sysdate,
      p_unit                in varchar2 default null)
      return binary_double;   
   /**
    * Retrieves a vertical datum offset value in a specified unit from the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id         The text name of the location the offset applies to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_datetime            The date of applicability of the offset. The offset returned will be the one having the latest effective date on or before this parameter.
    *                              If not specified or NULL, the current date and time will be used.
    * @param p_time_zone           The time zone of p_datetime (if specified). If not specified or NULL, the location's location time zone is used.
    * @param p_unit                The unit to retrieve the offset in.  If not specified or NULL, the offset will be returned in meters.
    * @param p_office_id           The office that owns the location.
    * 
    * @return The offset in the specified unit that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
    */
   function get_vertical_datum_offset(
      p_location_id         in varchar,
      p_vertical_datum_id_1 in varchar2,   
      p_vertical_datum_id_2 in varchar2, 
      p_datetime            in date     default null,
      p_time_zone           in varchar2 default null,
      p_unit                in varchar2 default null,
      p_office_id           in varchar2 default null)
      return binary_double;   
   /**
    * Retrieves a vertical datum offset value in a specified unit and effective date in a specified time zone from the database for a location
    *
    * @since CWMS 2.2
    *
    * @param p_offset              The offset in the specified unit that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
    * @param p_effecive_date       The effective date of the offset in the time time zone specified or indicated by p_time_zone
    * @param p_estimate            A flag (T/F) specifying whether the returned offset is an estimate
    * @param p_location_id         The text name of the location the offset applies to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_datetime            The date of applicability of the offset. The offset returned will be the one having the latest effective date on or before this parameter.
    *                              If not specified or NULL, the current date and time will be used.
    * @param p_time_zone           The time zone of p_datetime (if specified). If not specified or NULL, the location's location time zone is used, unless p_effective_date is also unspecified or NULL, in which
    *                              case the effectie date is returned in UTC.
    * @param p_unit                The unit to retrieve the offset in.  If not specified or NULL, the offset will be returned in meters.
    * @param p_office_id           The office that owns the location.
    */
   procedure get_vertical_datum_offset(
      p_offset              out binary_double,  
      p_effective_date      out date,
      p_estimate            out varchar2,
      p_location_id         in  varchar,
      p_vertical_datum_id_1 in  varchar2,   
      p_vertical_datum_id_2 in  varchar2,
      p_datetime            in  date     default null,
      p_time_zone           in  varchar2 default null,
      p_unit                in  varchar2 default null,
      p_office_id           in  varchar2 default null);   
   /**
    * Retrieves a collection vertical datum offset values in a specified unit and effective dates in a specified time zone from the database for a location and time window
    *
    * @since CWMS 2.2
    *
    * @param p_location_id         The text name of the location the offsets apply to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_start_time          The beginning of the time window in the specified time zone. The earliest effective date retrieved will be in effect on this date.
    * @param p_end_time            The end of the time window in the specified time zone.  The latest effective date retrieved will be in effect on this date.
    * @param p_time_zone           The time zone of time window. If not specified or NULL, the location's location time zone is used.
    * @param p_unit                The unit to retrieve the offsets in.  If not specified or NULL, the offsets will be returned in meters.
    * @param p_office_id           The office that owns the location.
    * 
    * @return The datum offset values and effective dates. For each item the date_time field contains the effective_date in the specified time zone and the value field contains the datum offset in the specified unit. The quality field is not used.
    *
    * @see type ztsv_array
    */
   function get_vertical_datum_offsets(
      p_location_id         in varchar,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_start_time          in date,
      p_end_time            in date,
      p_time_zone           in varchar2 default null,
      p_unit                in varchar2 default null,
      p_office_id           in varchar2 default null)
      return ztsv_array;        
   /**
    * Retrieves a collection vertical datum offset values in a specified unit and effective dates in a specified time zone from the database for a location and time window
    *
    * @since CWMS 2.2
    *
    * @param p_offsets             The datum offset values and effective dates. For each item the date_time field contains the effective_date in the specified time zone and the value field contains the datum offset in the specified unit. The quality field is not used.
    * @param p_location_id         The text name of the location the offsets apply to
    * @param p_vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
    * @param p_start_time          The beginning of the time window in the specified time zone. The earliest effective date retrieved will be in effect on this date.
    * @param p_end_time            The end of the time window in the specified time zone.  The latest effective date retrieved will be in effect on this date.
    * @param p_time_zone           The time zone of time window. If not specified or NULL, the location's location time zone is used.
    * @param p_unit                The unit to retrieve the offsets in.  If not specified or NULL, the offsets will be returned in meters.
    * @param p_office_id           The office that owns the location.
    * 
    * @see type ztsv_array
    */
   procedure get_vertical_datum_offsets(
      p_offsets             out ztsv_array,
      p_location_id         in  varchar,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_start_time          in  date,
      p_end_time            in  date,
      p_time_zone           in  varchar2 default null,
      p_unit                in  varchar2 default null,
      p_office_id           in  varchar2 default null);
   
   /**
    * Sets the default vertical datum for the current session. The default vertical datum is the datum in which all queried elevations
    * are reported and in which all specified elevations are intepreted. If the default vertical datum is NULL, all queried elevations are
    * reported - and all specified elvations are interpreted - in the identified vertical datum of their associated location.
    *
    * @since CWMS 2.2
    *
    * @param p_vertical_datum The default vertical datum for the session.  Must be one of NULL, 'NGVD29', 'NAVD88', or 'LOCAL'.
    *
    * @see get_default_vertical_datum
    * @see get_default_vertical_datum_f
    */
   procedure set_default_vertical_datum(
      p_vertical_datum in varchar2);
      
   /**
    * Retrieves the default vertical datum for the current session. The default vertical datum is the datum in which all queried elevations
    * are reported and in which all specified elevations are intepreted. If the default vertical datum is NULL, all queried elevations are
    * reported - and all specified elvations are interpreted - in the identified vertical datum of their associated location.
    *
    * @since CWMS 2.2
    *
    * @param p_vertical_datum The default vertical datum for the session.  Will be one of NULL, 'NGVD29', 'NAVD88', or 'LOCAL'.
    *
    * @see set_default_vertical_datum
    * @see get_default_vertical_datum_f
    */
   procedure get_default_vertical_datum(
      p_vertical_datum out varchar2);
      
   /**
    * Retrieves the default vertical datum for the current session. The default vertical datum is the datum in which all queried elevations
    * are reported and in which all specified elevations are intepreted. If the default vertical datum is NULL, all queried elevations are
    * reported - and all specified elvations are interpreted - in the identified vertical datum of their associated location.
    *
    * @since CWMS 2.2
    *
    * @return The default vertical datum for the session.  Will be one of NULL, 'NGVD29', 'NAVD88', or 'LOCAL'.
    *
    * @see set_default_vertical_datum
    * @see get_default_vertical_datum
    */
   function get_default_vertical_datum
      return varchar2;
   /**
    * Retreives the identified vertical datum for the specified location.  If no vertical datum is identified for a sub-location, the vertical datum identified for its base location is returned, if any.
    *
    * @since CWMS 2.2
    *
    * @param p_vertical_datum The identified vertical datum for the location
    * @param p_location_code  The unique numeric code for the location
    */
   procedure get_location_vertical_datum(
      p_vertical_datum out varchar2,
      p_location_code  in  number);
   /**
    * Retreives the identified vertical datum for the specified location.  If no vertical datum is identified for a sub-location, the vertical datum identified for its base location is returned, if any.
    *
    * @since CWMS 2.2
    *
    * @param p_vertical_datum The identified vertical datum for the location
    * @param p_location_id  The text identifier for the location
    * @param p_office_id    The text identifier of the office that owns the location. If not specified or NULL, the session user's default office is used.
    */
   procedure get_location_vertical_datum(
      p_vertical_datum out varchar2,
      p_location_id    in  varchar2,
      p_office_id      in  varchar2 default null);
   /**
    * Returns the identified vertical datum for the specified location.  If no vertical datum is identified for a sub-location, the vertical datum identified for its base location is returned, if any.
    *
    * @since CWMS 2.2
    *
    * @param p_location_code  The unique numeric code for the location
    * @return The identified vertical datum for the location
    */
   function get_location_vertical_datum(
      p_location_code in number)
      return varchar2;
   /**
    * Returns the identified vertical datum for the specified location.  If no vertical datum is identified for a sub-location, the vertical datum identified for its base location is returned, if any.
    *
    * @since CWMS 2.2
    *
    * @param p_location_id  The text identifier for the location
    * @param p_office_id    The text identifier of the office that owns the location. If not specified or NULL, the session user's default office is used.
    * @return The identified vertical datum for the location
    */
   function get_location_vertical_datum(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2;
   /**
    * Returns the elevation offset (in the specified unit) that must be ADDED to an elevation WRT the specified location's identified datum to generate an elavation WRT to the effective vertical datum.
    *
    * @since CWMS 2.2
    *
    * @param p_location_code The unique numeric code for the location
    * @param p_unit_spec     The unit specifier that may have a vertical datum encoded to override the default vertical datum for the session.
    * @return the elevation offset in the specified unit that must be ADDED to an elevation WRT the specified location's identified datum to generate an elavation WRT to the effective vertical datum.
    * @see cwms_util.parse_unit
    */
   function get_vertical_datum_offset(
      p_location_code in number,
      p_unit          in varchar2)
      return binary_double;
   /**
    * Returns the elevation offset (in the specified unit ) that must be ADDED to an elevation WRT the specified location's identified datum to generate an elavation WRT to the effective vertical datum.
    *
    * @since CWMS 2.2
    *
    * @param p_location_id The text identifier for the location
    * @param p_unit_spec   The unit specifier that may have a vertical datum encoded to override the default vertical datum for the session.
    * @param p_office_id   The office that owns the location. If not specified or NULL, the current session user's default office is used.
    * @return the elevation offsetin the specified unit  that must be ADDED to an elevation WRT the specified location's identified datum to generate an elavation WRT to the effective vertical datum. 
    * @see cwms_util.parse_unit
    */
   function get_vertical_datum_offset(
      p_location_id   in varchar2,
      p_unit          in varchar2,
      p_office_id     in varchar2 default null)
      return binary_double;
   /**
    * Retrieves a XML string containing the elevation, native datum, and elevation offsets to other datums for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_vert_datum_info The XML-encoded vertical datum information string
    * @param p_location_code   The unique numeric code identifying the location
    * @param p_unit            The unit to return the elevation and elevation offsets in
    */
   procedure get_vertical_datum_info(
      p_vert_datum_info out varchar2,
      p_location_code   in  number,
      p_unit            in  varchar2);
   /**
    * Retrieves a XML string containing the elevation, native datum, and elevation offsets to other datums for the specified location or locations
    *
    * @since CWMS 2.2
    *
    * @param p_vert_datum_info The XML-encoded vertical datum information string. If p_location_id is a recordset the XML root element will be
    * <code><big>&lt;vertical-datum-info-set&gt;</big></code> and will contain one <code><big>&lt;vertical-datum-info&gt;</big></code> element for each location:
    * <pre><big>&lt;vertical-datum-info-set&gt;
    *   &lt;vertical-datum-info office="SWT" unit="ft"&gt;
    *     &lt;location&gt;PENS&lt;/location&gt;
    *     &lt;native-datum&gt;LOCAL&lt;/native-datum&gt;
    *     &lt;elevation/&gt;
    *     &lt;offset estimate="true"&gt;
    *       &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *       &lt;value&gt;1.457&lt;/value&gt;
    *     &lt;/offset&gt;
    *     &lt;offset estimate="false"&gt;
    *       &lt;to-datum&gt;NGVD29&lt;/to-datum&gt;
    *       &lt;value&gt;1.07&lt;/value&gt;
    *     &lt;/offset&gt;
    *   &lt;/vertical-datum-info&gt;
    *   &lt;vertical-datum-info office="SWT" unit="ft"&gt;
    *     &lt;location&gt;KEYS&lt;/location&gt;
    *     &lt;native-datum&gt;NGVD29&lt;/native-datum&gt;
    *     &lt;elevation/&gt;
    *     &lt;offset estimate="true"&gt;
    *       &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *       &lt;value&gt;.362&lt;/value&gt;
    *     &lt;/offset&gt;
    *   &lt;/vertical-datum-info&gt;
    * &lt;/vertical-datum-info-set&gt;</big></pre>
    * If p_location_id is a single location, the XML root element will be <code><big>&lt;vertical-datum-info&gt;</big></code> and will not contain an <code><big>office</big></code>
    * attribute or a <code><big>&lt;location&gt;</big></code> child element:
    * <pre><big>&lt;vertical-datum-info unit="ft"&gt;
    *   &lt;native-datum&gt;LOCAL&lt;/native-datum&gt;
    *   &lt;elevation/&gt;
    *   &lt;offset estimate="true"&gt;
    *     &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *     &lt;value&gt;1.457&lt;/value&gt;
    *   &lt;/offset&gt;
    *   &lt;offset estimate="false"&gt;
    *     &lt;to-datum&gt;NGVD29&lt;/to-datum&gt;
    *     &lt;value&gt;1.07&lt;/value&gt;
    *   &lt;/offset&gt;
    * &lt;/vertical-datum-info&gt;</big></pre>
    * @param p_location_id     The text name the location or a recordset of location names. If a recordset is used, it may be a single record with
    *                          multiple fields, multiple records each with a single field, or multiple records with multiple fields.
    * @param p_unit            The unit to return the elevation and elevation offsets in
    * @param p_office_id       The office that owns the location. If not specified or NULL, the session user's default office is used. If p_location_id
    *                          is a recordset, this parameter may be, but is not required to be, a recordset. If this parameter is not a recordset then
    *                          the one (specified or implied) office applies to all locations.  If this parameter is a recordset, it must have the same 
    *                          number of records as p_location_id. Each record may have a single office, which applies to every location on the same record
    *                          in p_location_id, or it may have one field for each field in the same record of p_location_id.
    * @see cwms_util.parse_string_recordset
    */
   procedure get_vertical_datum_info(
      p_vert_datum_info out varchar2,
      p_location_id     in  varchar2,
      p_unit            in  varchar2,
      p_office_id       in  varchar2 default null);
   /**
    * Returns a XML string containing the elevation, native datum, and elevation offsets to other datums for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_code The unique numeric code identifying the location
    * @param p_unit          The unit to return the elevation and elevation offsets in
    *
    * @return The XML-encoded vertical datum information string
    */
   function get_vertical_datum_info_f(
      p_location_code in number,
      p_unit          in varchar2)
      return varchar2;
   /**
    * Returns a XML string containing the elevation, native datum, and elevation offsets to other datums for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id     The text name the location or a recordset of location names. If a recordset is used, it may be a single record with
    *                          multiple fields, multiple records each with a single field, or multiple records with multiple fields.
    * @param p_unit            The unit to return the elevation and elevation offsets in
    * @param p_office_id       The office that owns the location. If not specified or NULL, the session user's default office is used. If p_location_id
    *                          is a recordset, this parameter may be, but is not required to be, a recordset. If this parameter is not a recordset then
    *                          the one (specified or implied) office applies to all locations.  If this parameter is a recordset, it must have the same 
    *                          number of records as p_location_id. Each record may have a single office, which applies to every location on the same record
    *                          in p_location_id, or it may have one field for each field in the same record of p_location_id.
    *
    * @return The XML-encoded vertical datum information string. If p_location_id is a recordset the XML root element will be
    * <code><big>&lt;vertical-datum-info-set&gt;</big></code> and will contain one <code><big>&lt;vertical-datum-info&gt;</big></code> element for each location:
    * <pre><big>&lt;vertical-datum-info-set&gt;
    *   &lt;vertical-datum-info office="SWT" unit="ft"&gt;
    *     &lt;location&gt;PENS&lt;/location&gt;
    *     &lt;native-datum&gt;LOCAL&lt;/native-datum&gt;
    *     &lt;elevation/&gt;
    *     &lt;offset estimate="true"&gt;
    *       &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *       &lt;value&gt;1.457&lt;/value&gt;
    *     &lt;/offset&gt;
    *     &lt;offset estimate="false"&gt;
    *       &lt;to-datum&gt;NGVD29&lt;/to-datum&gt;
    *       &lt;value&gt;1.07&lt;/value&gt;
    *     &lt;/offset&gt;
    *   &lt;/vertical-datum-info&gt;
    *   &lt;vertical-datum-info office="SWT" unit="ft"&gt;
    *     &lt;location&gt;KEYS&lt;/location&gt;
    *     &lt;native-datum&gt;NGVD29&lt;/native-datum&gt;
    *     &lt;elevation/&gt;
    *     &lt;offset estimate="true"&gt;
    *       &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *       &lt;value&gt;.362&lt;/value&gt;
    *     &lt;/offset&gt;
    *   &lt;/vertical-datum-info&gt;
    * &lt;/vertical-datum-info-set&gt;</big></pre>
    * If p_location_id is a single location, the XML root element will be <code><big>&lt;vertical-datum-info&gt;</big></code> and will not contain an <code><big>office</big></code>
    * attribute or a <code><big>&lt;location&gt;</big></code> child element:
    * <pre><big>&lt;vertical-datum-info unit="ft"&gt;
    *   &lt;native-datum&gt;LOCAL&lt;/native-datum&gt;
    *   &lt;elevation/&gt;
    *   &lt;offset estimate="true"&gt;
    *     &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *     &lt;value&gt;1.457&lt;/value&gt;
    *   &lt;/offset&gt;
    *   &lt;offset estimate="false"&gt;
    *     &lt;to-datum&gt;NGVD29&lt;/to-datum&gt;
    *     &lt;value&gt;1.07&lt;/value&gt;
    *   &lt;/offset&gt;
    * &lt;/vertical-datum-info&gt;</big></pre>
    * @see cwms_util.parse_string_recordset
    */
   function get_vertical_datum_info_f(
      p_location_id in varchar2,
      p_unit        in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2;                       
   /**
    * Sets vertical datum info for one or more locations
    *
    * @since CWMS 2.2
    *
    * @param p_vert_datum_info A multiple location XML snippet as described in get_vertical_datum_info (root element = <code><big>&lt;vertical-datum-info-set&gt;</big></code>).
    *                          The XML root element may have one or more <code><big>&lt;vertical-datum-info&gt;</big></code> child elements, each of which must include an
    *                          <code><big>office</big></code> attribute and <code><big>&lt;location&gt;</big></code> child element.
    * <pre><big>&lt;vertical-datum-info-set&gt;
    *   &lt;vertical-datum-info office="SWT" unit="ft"&gt;
    *     &lt;location&gt;PENS&lt;/location&gt;
    *     &lt;native-datum&gt;LOCAL&lt;/native-datum&gt;
    *     &lt;elevation/&gt;
    *     &lt;offset estimate="true"&gt;
    *       &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *       &lt;value&gt;1.457&lt;/value&gt;
    *     &lt;/offset&gt;
    *     &lt;offset estimate="false"&gt;
    *       &lt;to-datum&gt;NGVD29&lt;/to-datum&gt;
    *       &lt;value&gt;1.07&lt;/value&gt;
    *     &lt;/offset&gt;
    *   &lt;/vertical-datum-info&gt;
    *   &lt;vertical-datum-info office="SWT" unit="ft"&gt;
    *     &lt;location&gt;KEYS&lt;/location&gt;
    *     &lt;native-datum&gt;NGVD29&lt;/native-datum&gt;
    *     &lt;elevation/&gt;
    *     &lt;offset estimate="true"&gt;
    *       &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *       &lt;value&gt;.362&lt;/value&gt;
    *     &lt;/offset&gt;
    *   &lt;/vertical-datum-info&gt;
    * &lt;/vertical-datum-info-set&gt;</big></pre>
    * This procedure will not update a location's existing native vertical datum nor its existing elevation and will fail if either are specified and do not match the current values in the database.
    * However, If either of these items are not set in the database they will be initialized from the XML values.  
    * @param p_fail_if_exists  A flag ('T'/'F') specifying whether the procedure should fail if any of the specified vertical datum info (except native datum and elevation) already exists
    */
   procedure set_vertical_datum_info(
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2);     
   /**
    * Sets vertical datum information for a specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_code   The unique number identifying the location
    * @param p_vert_datum_info An single location XML snippet as described in get_vertical_datum_info (root element = <code><big>&lt;vertical-datum-info&gt;</big></code>).
    *                          The <code><big>office</big></code> attribute and <code><big>&lt;location&gt;</big></code> child element are not required. If they exist, they must match the 
    *                          location specified in p_location_code
    * <pre><big>&lt;vertical-datum-info unit="ft"&gt;
    *   &lt;native-datum&gt;LOCAL&lt;/native-datum&gt;
    *   &lt;elevation/&gt;
    *   &lt;offset estimate="true"&gt;
    *     &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *     &lt;value&gt;1.457&lt;/value&gt;
    *   &lt;/offset&gt;
    *   &lt;offset estimate="false"&gt;
    *     &lt;to-datum&gt;NGVD29&lt;/to-datum&gt;
    *     &lt;value&gt;1.07&lt;/value&gt;
    *   &lt;/offset&gt;
    * &lt;/vertical-datum-info&gt;</big></pre>
    * This procedure will not update a location's existing native vertical datum nor its existing elevation and will fail if either are specified and do not match the current values in the database.
    * However, If either of these items are not set in the database they will be initialized from the XML values.  
    * @param p_fail_if_exists  A flag ('T'/'F') specifying whether the procedure should fail if any of the specified vertical datum info (except native datum and elevation) already exists
    *
    * @see get_vertical_datum_info
    */
   procedure set_vertical_datum_info(
      p_location_code   in number,
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2);     
   /**
    * Sets vertical datum information for a specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id   The text name of the location
    * @param p_vert_datum_info A single location XML snippet as described in get_vertical_datum_info (root element = <code><big>&lt;vertical-datum-info&gt;</big></code>).
    *                          The <code><big>office</big></code> attribute and <code><big>&lt;location&gt;</big></code> child element are not required. If they exist, they must match the 
    *                          location specified in p_location_id and p_office_id
    * <pre><big>&lt;vertical-datum-info unit="ft"&gt;
    *   &lt;native-datum&gt;LOCAL&lt;/native-datum&gt;
    *   &lt;elevation/&gt;
    *   &lt;offset estimate="true"&gt;
    *     &lt;to-datum&gt;NAVD88&lt;/to-datum&gt;
    *     &lt;value&gt;1.457&lt;/value&gt;
    *   &lt;/offset&gt;
    *   &lt;offset estimate="false"&gt;
    *     &lt;to-datum&gt;NGVD29&lt;/to-datum&gt;
    *     &lt;value&gt;1.07&lt;/value&gt;
    *   &lt;/offset&gt;
    * &lt;/vertical-datum-info&gt;</big></pre>
    * This procedure will not update a location's existing native vertical datum nor its existing elevation and will fail if either are specified and do not match the current values in the database.
    * However, If either of these items are not set in the database they will be initialized from the XML values.  
    * @param p_fail_if_exists  A flag ('T'/'F') specifying whether the procedure should fail if any of the specified vertical datum info (except native datum and elevation) already exists
    * @param p_office_id       The office that owns the location.  If unspecified or NULL, the session user's default location will be used.
    *
    * @see get_vertical_datum_info
    */
   procedure set_vertical_datum_info(
      p_location_id     in varchar2,
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2,     
      p_office_id       in varchar2 default null);     
   /**
    * Retrieves the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_local_vert_datum_name The name of the local vertical datum, or NULL if the local vertical datum is unnamed.
    * @param p_location_code         The unique numeric code or the location to retrieve the informaton for.
    */
   procedure get_local_vert_datum_name (
      p_local_vert_datum_name out varchar2,
      p_location_code         in  number);
   /**
    * Returns the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_code The unique numeric code of the location to retrieve the informaton for.
    * @return The name of the local vertical datum, or NULL if the local vertical datum is unnamed.
    */
   function get_local_vert_datum_name_f (
      p_location_code in number)
      return varchar2;
   /**
    * Retrieves the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_local_vert_datum_name The name of the local vertical datum, or NULL if the local vertical datum is unnamed.
    * @param p_location_id           The text identifier of the location to retrieve the informaton for.
    * @param p_office_id             The text identifier of the office that owns the location.  If unspecified or NULL, the session user's default office is used.
    */
   procedure get_local_vert_datum_name (
      p_local_vert_datum_name out varchar2,
      p_location_id           in  varchar2,
      p_office_id             in  varchar2 default null);
   /**
    * Returns the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id  The text identifier of the location to retrieve the informaton for.
    * @param p_office_id    The text identifier of the office that owns the location.  If unspecified or NULL, the session user's default office is used.
    * @return The name of the local vertical datum, or NULL if the local vertical datum is unnamed.
    */
   function get_local_vert_datum_name_f (
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2;
   /**
    * Sets the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_code   The unique numeric code of the location to set the informaton for.
    * @param p_vert_datum_name The name of the local vertical datum for the location
    * @param p_fail_if_exists  A flag ('T'/'F') specifying whether to fail if a local vertical datum name already exists.
    */
   procedure set_local_vert_datum_name(
      p_location_code   in number,
      p_vert_datum_name in varchar2,
      p_fail_if_exists  in varchar2 default 'T');
   /**
    * Sets the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id     The text identifier of the location to set the informaton for.
    * @param p_vert_datum_name The name of the local vertical datum for the location
    * @param p_fail_if_exists  A flag ('T'/'F') specifying whether to fail if a local vertical datum name already exists.
    * @param p_office_id       The text identifier of the office that owns the location.  If unspecified or NULL, the session user's default office is used.
    */
   procedure set_local_vert_datum_name(
      p_location_id     in varchar2,
      p_vert_datum_name in varchar2,
      p_fail_if_exists  in varchar2 default 'T',
      p_office_id       in varchar2 default null);
   /**
    * Deletes the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_code The unique numeric code of the location to delete the informaton for.
    */
   procedure delete_local_vert_datum_name (
      p_location_code in number);
   /**
    * Deletes the name of the local vertical datum for the specified location
    *
    * @since CWMS 2.2
    *
    * @param p_location_id The text identifier of the location to delete the informaton for.
    * @param p_office_id   The text identifier of the office that owns the location.  If unspecified or NULL, the session user's default office is used.
    */
   procedure delete_local_vert_datum_name (
      p_location_id in varchar2,
      p_office_id   in varchar2 default null);
      
END cwms_loc;
/

SHOW ERRORS;
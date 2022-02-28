create or replace package cwms_overflow
/**
 * Routines to manage overflow outlets (uncontrolled spillways) in the CWMS database
 *
 * @author Mike Perryman
 * @since CWMS 3.0
 */
as
/**
 * Stores (creates or updates) information about a spillway or weir in the database
 *
 * @param p_location_id        The text location identifier of the overflow to store. New locations will not be created except for sub-locations of project base locations.
 * @param p_fail_if_exists     A flag ('T'/'F') specifying whether to fail if the location already exists as an overflow
 * @param p_ignore_nulls       A flag ('T'/'F') specifying whether to ignore NULL parameters when updating an existing overflow
 * @param p_crest_elev         The elevation of the overflow crest
 * @param p_elev_unit          The unit of the specified elevation
 * @param p_length_or_diameter The length (or diameter for circular spillways) of the overflow
 * @param p_length_unit        The unit of the specified length or diameter
 * @param p_is_circular        A flag ('T'/'F') specifying whether the overflow is circular
 * @param p_rating_spec_id     The rating specification for the overflow
 * @param p_description        A description of the overflow
 * @param p_office_id          The office that owns the overflow location. If not specified or NULL, the session user's current office is used
 *
 */
procedure store_overflow(
   p_location_id        in varchar2,
   p_fail_if_exists     in varchar2,
   p_ignore_nulls       in varchar2,
   p_crest_elev         in binary_double default null,
   p_elev_unit          in varchar2      default null,
   p_length_or_diameter in binary_double default null,
   p_length_unit        in varchar2      default null,
   p_is_circular        in varchar2      default null,
   p_rating_spec_id     in varchar2      default null,
   p_description        in varchar2      default null,
   p_office_id          in varchar2      default null);
/**
 * Retrieves information about a spillway or weir in the database
 *
 * @param p_crest_elev         The elevation of the overflow crest in the specified unit
 * @param p_length_or_diameter The length (or diameter for circular spillways) of the overflow in the specified unit
 * @param p_is_circular        A flag ('T'/'F') specifying whether the overflow is circular
 * @param p_rating_spec_id     The rating specification for the overflow
 * @param p_description        A description of the overflow
 * @param p_location_id        The text location identifier of the overflow
 * @param p_elev_unit          The unit of the specified elevation
 * @param p_length_unit        The unit of the specified length or diameter
 * @param p_office_id          The office that owns the overflow location. If not specified or NULL, the session user's current office is used
 *
 */
procedure retrieve_overflow(
   p_crest_elev         out binary_double,
   p_length_or_diameter out binary_double,
   p_is_circular        out varchar2,
   p_rating_spec_id     out varchar2,
   p_description        out varchar2,
   p_location_id        in  varchar2,
   p_elev_unit          in  varchar2 default null,
   p_length_unit        in  varchar2 default null,
   p_office_id          in  varchar2 default null);
/**
 * Deletes information about a spillway or weir from the database
 *
 * @param p_location_id The text location identifier of the overflow
 * @param p_delete_action the type of deletion to perform.
 *        <dl>
 *        <dt><code><big><b>cwms_util.delete_key</b></big></code></dt>
 *        <dd>only the overflow information is deleted.</dd>
 *        <dt><code><big><b>cwms_util.delete_all</b></big></code></dt>
 *        <dd>the overflow location and any depedent data will be deleted</dd>
 *        </dl>
 * @param p_office_id   The office that owns the overflow location. If not specified or NULL, the session user's current office is used
 */
procedure delete_overflow(
   p_location_id   in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Renames an overflow location in the database
 *
 * @param p_old_location_id The existing location identifier of the overflow in the database
 * @param p_new_location_id The new location identifier
 * @param p_office_id       The office that owns the overflow location. If not specified or NULL, the session user's current office is used
 */
procedure rename_overflow(
   p_old_location_id in varchar2,
   p_new_location_id in varchar2,
   p_office_id       in varchar2 default null);

end cwms_overflow;
/

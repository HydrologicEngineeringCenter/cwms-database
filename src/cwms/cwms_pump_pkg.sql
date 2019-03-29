create or replace package cwms_pump
/**
 * Routines for managing pump locations
 * @since CWMS 3.0
 * @author Mike Perryman
 */
as
/**
 * Stores (creates or updates) information about a pump location in the database
 *
 * @param p_location_id    The text location identifier of the pump location
 * @param p_fail_if_exists A flag ('T'/'F') specifying whether to fail if a the specified pump location already exists
 * @param p_ignore_nulls   A flag ('T'/'F') specifying whether to ignore a null parameters on updates
 * @param p_description    The pump location description
 * @param p_office_id      The office that owns the pump location in the database. If not specified or NULL, the session user's current office is used.
 */
procedure store_pump(
   p_location_id    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_description    in varchar2 default null,
   p_office_id      in varchar2 default null);
/**
 * Retrieves information about a pump location in the database
 *
 * @param p_description The pump location description
 * @param p_location_id The text location identifier of the pump location
 * @param p_office_id   The office that owns the pump location in the database. If not specified or NULL, the session user's current office is used.
 */
procedure retrieve_pump(
   p_description out varchar2,
   p_location_id in  varchar2,
   p_office_id   in  varchar2 default null);
/**
 * Renames a pump location in the database
 *
 * @param p_old_location_id The existing location identifier
 * @param p_new_location_id The new location identifier
 * @param p_office_id       The office that owns the pump location in the database. If not specified or NULL, the session user's current office is used.
 */
procedure rename_pump(
   p_old_location_id in varchar2,
   p_new_location_id in varchar2,
   p_office_id       in varchar2 default null);
/**
 * Deletes a pump location from the database
 *
 * @param p_location_id The text identifier of the pump location to be deleted
 * @param p_delete_action the type of deletion to perform.
 *        <dl>
 *        <dt><code><big><b>cwms_util.delete_key</b></big></code></dt>
 *        <dd>only the pump is deleted. This will fail if the pump has any dependent data</dd>
 *        <dt><code><big><b>cwms_util.delete_data</b></big></code></dt>
 *        <dd>only the dependent data is deleted.</dd>
 *        <dt><code><big><b>cwms_util.delete_all</b></big></code></dt>
 *        <dd>the pump and any depedent data is deleted</dd>
 *        </dl>
 *        The <code><big><b>cwms_util.delete_key</b></big> or <code><big><b>cwms_util.delete_all</b></big> operations will set the location kind to <code>STREAM_LOCATION</code>
 * @param p_office_id The office that owns the pump location in the database. If not specified or NULL, the session user's current office is used.
 */
procedure delete_pump(
   p_location_id   in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
end cwms_pump;
/
show errors
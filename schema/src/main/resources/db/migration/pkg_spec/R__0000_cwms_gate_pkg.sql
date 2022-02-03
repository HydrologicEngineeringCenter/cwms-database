create or replace package cwms_gate
/**
 * Routines to work with CWMS gate groups
 *
 * @author Mike Perryman
 *
 * @since CWMS 3.0
 */
as

/**
 * Stores a gate group and possibly a rating group to the database
 *
 * @param p_gate_group_id    The name of the new or existing rating group - the gate group will have the same identifier
 * @param p_fail_if_exists   A flag ('T'/'F') that specifies whether to fail if the specified gate group already exists
 * @param p_ignore_nulls     A flag ('T'/'F') that specifies whether to ignore NULL parameters when updating an existing gate group
 * @param p_project_id       The location_id of the project the gate group belongs to. Must not be null when creating new gate group unless a rating group already exists
 * @param p_rating_spec      The rating specification for the rating group. Must not be null when creating new gate group unless a rating group already exists
 * @param p_gate_type_id     The type of gates in the group. The current gate types are:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Gate Type ID</th>
 *     <th class="descr">Description</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">OTHER</td>
 *     <td class="descr">Unknown or unspecified gate type</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">CLAMSHELL</td>
 *     <td class="descr">Gate whose upper and lower halves separate to open</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">CREST</td>
 *     <td class="descr">Gate that increases the crest elevation when raised</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">DRUM</td>
 *     <td class="descr">Hollow cylindrical section shaped crest gate hinged at the axis that floats on an adjustable amount of water in a chamber</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">FUSE</td>
 *     <td class="descr">Non-adjustable gate that is designed to fail (open) at a specific head</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">INFLATABLE</td>
 *     <td class="descr">Crest gate that is inflated to form a weir</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">MITER</td>
 *     <td class="descr">Doors hinged on opposite sides of a walled channel that meet in the center at an angle and are held closed by water pressure</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">NEEDLE</td>
 *     <td class="descr">Flow-through gate that is controlled by placing various numbers of boards (needles) vertically in a support structure</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">RADIAL</td>
 *     <td class="descr">Cylindrical section shaped gate hinged at the axis that passes water underneath when open</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">ROLLER</td>
 *     <td class="descr">Cylindrical crest gate that rolls in cogged slots in piers at each end to control its height</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">STOPLOG</td>
 *     <td class="descr">Crest gate whose height is controlled by varying the number of horizontal boards (logs) stacked between piers</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">VALVE</td>
 *     <td class="descr">Small gate for passing small and precisely controlled amounts of water</td>
 *   </tr>
 *  <tr>
 *     <td class="descr">VERTICAL SLIDE</td>
 *     <td class="descr">Flat gate that slides vertically in tracks (with or without rollers) for control</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">WICKET</td>
 *     <td class="descr">A group of small connected hinged gates (wickets) that overlap when closed and rotate together to open</td>
 *   </tr>
 * </table>
 * @param p_can_be_submerged A flag ('T'/'F') that specifies whether the gates in the group can be submerged
 * @param p_always_submerged A flag ('T'/'F') that specifies whether the gates in the group are always submerged
 * @param p_description      A description of the gates in the group
 * @param p_office_id        The office that owns the gate group. If not specified or NULL, the session user's current office is used
 */
procedure store_gate_group(
   p_gate_group_id          in varchar2,
   p_fail_if_exists         in varchar2,
   p_ignore_nulls           in varchar2,
   p_project_id             in varchar2 default null,
   p_rating_spec            in varchar2 default null,
   p_gate_type_id           in varchar2 default null,
   p_can_be_submerged       in varchar2 default null,
   p_always_submerged       in varchar2 default null,
   p_description            in varchar2 default null,
   p_office_id              in varchar2 default null);
/**
 * Retrieves inforation about a gate group and its underlying rating group
 *
 * @param p_project_id       The location_id of the project the gate group belongs to
 * @param p_rating_spec      The rating specification for the rating group
 * @param p_gate_type_id     The type of gates in the group
 * @param p_can_be_submerged A flag ('T'/'F') that specifies whether the gates in the group can be submerged
 * @param p_always_submerged A flag ('T'/'F') that specifies whether the gates in the group are always submerged
 * @param p_description      A description of the gates in the group
 * @param p_gate_group_id    The name of the the gate group
 * @param p_office_id        The office that owns the gate group. If not specified or NULL, the session user's current office is used
 */
procedure retreive_gate_group(
   p_project_id             out varchar2,
   p_rating_spec            out varchar2,
   p_gate_type_id           out varchar2,
   p_can_be_submerged       out varchar2,
   p_always_submerged       out varchar2,
   p_description            out varchar2,
   p_gate_group_id          in  varchar2,
   p_office_id              in  varchar2 default null);
/**
 * Associates a location with a gate group and underlying rating group, possibly creating the location first.
 *
 * @param p_gate_group_id  The name of the gate group and underlying rating group to associate the locations with
 * @param p_fail_if_exists A flag ('T'/'F') that specifies whether to fail if any of the locations is already associated with a gate group or rating group
 * @param p_gate_location  The location to associate with the gate group. This procedure will not create a base location, but will create a sub-location of an existing project base location.
 * @param p_sort_order     The sort order of this gate within the rating group. If not specified or NULL, any existing sort order will be maintained; no new sort order will be created
 * @param p_office_id      The office that owns the gate group and location in the database. If not specified or NULL, the session user's current office is used
 */
procedure store_gate(
   p_gate_group_id  in varchar2,
   p_fail_if_exists in varchar2,
   p_gate_location  in varchar2,
   p_sort_order     in number   default null,
   p_office_id      in varchar2 default null);
/**
 * Associates locations with a gate group and underlying rating group, possibly creating the locations first.
 *
 * @param p_gate_group_id  The name of the gate group and underlying rating group to associate the locations with
 * @param p_fail_if_exists A flag ('T'/'F') that specifies whether to fail if any of the locations is already associated with a gate group or rating group
 * @param p_gate_locations A comma-separated list of the locations to associate with the gate group. This procedure will not create base locations, but will create sub-locations of existing project base locations.
 * @param p_sort_order     A comma-separated list of sort orders of these gates within the rating group. If not specified or NULL, any existing sorts order will be maintained; no new sort orders will be created except see p_set_sort_order
 * @param p_set_sort_order A flag ('T'/'F') specifying whether to set the sort orders. If 'F', the value of p_sort_order is ignored. If 'T' and p_sort_order is NULL, the orders will be set by the gate locations' positions in p_gate_locations
 * @param p_office_id      The office that owns the gate group and locations in the database. If not specified or NULL, the session user's current office is used
 */
procedure store_gates(
   p_gate_group_id  in varchar2,
   p_fail_if_exists in varchar2,
   p_gate_locations in varchar2,
   p_sort_order     in varchar2 default null,
   p_set_sort_order in varchar2 default 'F',
   p_office_id      in varchar2 default null);
/**
 * Associates existing locations with a gate group and underlying rating group, possibly creating the locations first.
 *
 * @param p_gate_group_id  The name of the gate group and underlying rating group to associate the locations with
 * @param p_fail_if_exists A flag ('T'/'F') that specifies whether to fail if any of the locations is already associated with a gate group or rating group
 * @param p_gate_locations A table of location identifiers to associate with the gate group. This procedure will not create base locations, but will create sub-locations of existing project base locations.
 * @param p_sort_order     A table of sort orders of these gates within the rating group. If not specified or NULL, any existing sorts order will be maintained; no new sort orders will be created except see p_set_sort_order
 * @param p_set_sort_order A flag ('T'/'F') specifying whether to set the sort orders. If 'F', the value of p_sort_order is ignored. If 'T' and p_sort_order is NULL, the orders will be set by the gate locations' positions in p_gate_locations
 * @param p_office_id      The office that owns the gate group and locations in the database. If not specified or NULL, the session user's current office is used
 */
procedure store_gates(
   p_gate_group_id  in varchar2,
   p_fail_if_exists in varchar2,
   p_gate_locations in str_tab_t,
   p_sort_order     in number_tab_t default null,
   p_set_sort_order in varchar2     default 'F',
   p_office_id      in varchar2     default null);
/**
 * Deletes a gate group
 *
 * @param p_gate_group_id         The name of the gate group (and underlying rating group) to delete
 * @param p_delete_rating_group   A flag ('T'/'F') that specifies whether to delete the underlying rating group
 * @param p_delete_gate_locations A flag ('T'/'F') that specifies whether to delete the gate locations
 * @param p_delete_gates_action   Specifies what action to take when deleting gate locations
 * @param p_office_id             The office that owns the gate group. If not specified or NULL, the session user's current office is used
 */
procedure delete_gate_group(
   p_gate_group_id         in varchar2,
   p_delete_rating_group   in varchar2 default 'F',
   p_delete_gate_locations in varchar2 default 'F',
   p_delete_gates_action   in varchar2 default 'DELETE KEY',
   p_office_id             in varchar2 default null);
/**
 * Disassociates a gate from a gate group and the underlying rating group
 *
 * @param p_gate_location  The gate location to disassociate from its gate group
 * @param p_delete_action  If 'DELETE KEY', the gate will only be disassociated, if 'DELETE ALL', the gate location and any dependent data will be deleted.
 * @param p_office_id      The office that owns the gate in the database. If not specified or NULL, the session user's current office is used.
 */
procedure delete_gate(
   p_gate_location in varchar2,
   p_delete_action in varchar2,
   p_office_id     in varchar2 default null);
/**
 * Disassociates gates from a gate group and the underlying rating group
 *
 * @param p_gate_locations A comma-separated string of gate locations to disassociate from their gate group
 * @param p_delete_action  If 'DELETE KEY', the gates will only be disassociated, if 'DELETE ALL', the gate locations and any dependent data will be deleted.
 * @param p_office_id      The office that owns the gates in the database. If not specified or NULL, the session user's current office is used.
 */
procedure delete_gates(
   p_gate_locations in varchar2,
   p_delete_action  in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Disassociates gates from a gate group and the underlying rating group
 *
 * @param p_gate_locations A table of gate location identifiers to disassociate from their gate group
 * @param p_delete_action  If 'DELETE KEY', the gates will only be disassociated, if 'DELETE ALL', the gate locations and any dependent data will be deleted.
 * @param p_office-Id      The office that owns the gates in the database. If not specified or NULL, the session user's current office is used.
 */
procedure delete_gates(
   p_gate_locations in str_tab_t,
   p_delete_action  in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Renames a gate group and its underlying rating group in the database
 *
 * @param p_old_gate_group_id The existing name of the gate group and rating group
 * @param p_new_gate_group_id The new name of the gate group and rating group
 * @param p_office_id         The office that owns the gate group. If not specified or NULL, the session user's current office is used.
 */
procedure rename_gate_group(
   p_old_gate_group_id in varchar2,
   p_new_gate_group_id in varchar2,
   p_office_id         in varchar2 default null);
/**
 * Retrieves the gate locations associated with a specified gate group
 *
 * @param p_gate_locations A table of gate location identifiers that are associated with the gate group
 * @param p_gate_group_id  The gate group to retrieve gate for
 * @param p_office_id      The office that owns the gate group in the database. If not specified or NULL, the session user's current office is used
 */
procedure get_gates(
   p_gate_locations out str_tab_t,
   p_gate_group_id  in  varchar2,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves the gate locations associated with a specified gate group
 *
 * @param p_gate_group_id  The gate group to retrieve gate for
 * @param p_office_id      The office that owns the gate group in the database. If not specified or NULL, the session user's current office is used
 * @return A table of gate location identifiers that are associated with the gate group
 */
function get_gates_f(
   p_gate_group_id  in varchar2,
   p_office_id      in varchar2 default null)
   return str_tab_t;

end cwms_gate;
/

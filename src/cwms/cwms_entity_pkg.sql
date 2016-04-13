create or replace package cwms_entity as

/**
 * Stores an entity to the database
 *
 * @param p_entity_id        The character identifier of the entity
 * @param p_entity_name      The name of the entity
 * @param p_parent_entity_id The character identifier of the parent entity, if any
 * @param p_category_id      The category the entity belongs to
 * @param p_fail_if_exists   A flag ('T'/'F') specifying whether to fail if the entity identifier already exists
 * @param p_ignore_nulls     A flag ('T'/'F') specifying whether to ignore null parameters when updating an entity
 * @param p_office_id        The office that owns the entity in the database. If not specified or NULL, the sessions user's default office will be used
 */
procedure store_entity (
   p_entity_id        in varchar2,
   p_entity_name      in varchar2,
   p_parent_entity_id in varchar2 default null,
   p_category_id      in varchar2 default null,
   p_fail_if_exists   in varchar2 default 'T',
   p_ignore_nulls     in varchar2 default 'T',
   p_office_id        in varchar2 default null);
/**
 * Retrieves information about an entity in the database
 *
 * @param p_entity_code      The numeric code for the specified entity in the database. Specify NULL if this parameter is not desired.
 * @param p_office_id_out    The office that owns the entity in the database. Specify NULL if this parameter is not desired.
 * @param p_parent_entity_id The identifier of the parent entity, if any. Specify NULL if this parameter is not desired.
 * @param p_category_id      The category of the entity. Specify NULL if this parameter is not desired.
 * @param p_entity_name      The name of the entity. Specify NULL if this parameter is not desired.
 * @param p_entity_id        The text identifier of the entity to retrieve information about.
 * @param p_office_id        The selected office. Only entities that are owned by the CWMS office or this one will be retrieved. If not specified or NULL, the sessions user's default office will be used
 */
procedure retrieve_entity (
   p_entity_code      in out nocopy integer,
   p_office_id_out    in out nocopy varchar2,
   p_parent_entity_id in out nocopy varchar2,
   p_category_id      in out nocopy varchar2,
   p_entity_name      in out nocopy varchar2,  
   p_entity_id        in varchar2,
   p_office_id        in varchar2 default null);
/**
 * Retreives the numeric code for the specified entity
 *
 * @param p_entity_id The indentifier of the entity to retrieve the code for
 * @param p_office_id The selected office. Only entities that are owned by the CWMS office or this one will be retrieved. If not specified or NULL, the sessions user's default office will be used
 *
 * @return The numeric code for the specified entity
 */
function get_entity_code (
   p_entity_id in varchar2,
   p_office_id in varchar2 default null)
   return integer;
--   
-- Not documented   
--
function get_entity_id (
   p_entity_code in integer)
   return varchar2;
/**
 * Deletes an entry from the database
 *
 * @param p_entity_id The indentifier of the entity to delete
 * @param p_office_id The office that owns the entity in the database. If not specified or NULL, the sessions user's default office will be used
 */
procedure delete_entity (
   p_entity_id             in varchar2,
   p_delete_child_entities in varchar default 'F',
   p_office_id             in varchar2 default null);
/**
 * Catalogs entities in the database that match input parameters. Matching is
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
 * @param p_entity_cursor A cursor containing the matched entities. The cursor
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
 *     <td class="descr">The office that owns the entity</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">entity_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the entity</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_entity_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the parent entity, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">category_id</td>
 *     <td class="descr">varchar2(3)</td>
 *     <td class="descr">The category to which the entity belongs</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">entity_name</td>
 *     <td class="descr">varchar2(128)</td>
 *     <td class="descr">The name of the entity</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">entity_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the entity in the database</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the parent entity, if any, in the database</td>
 *   </tr>
 * </table>
 * @param p_entity_id_mask        The entity identifier pattern to match. If not specified, all entity identfiers are matched
 * @param p_parent_entity_id_mask The parent entity identifier pattern to match. If not specified or '*', all non-NULL parent entity identfiers are matched
 * @param p_match_null_parents    A flag ('T'/'F') specifying whether to match entities without a parent entity
 * @param p_category_id_mask      The category identifier pattern to match. If not specified, all category identifiers are matched
 * @param p_entity_name_mask      The entity name pattern to match. If not specified, all entity names are matched
 * @param p_office_id_mask        The owning office to match. If not specified or NULL, only enities owned by the CWMS office and the session user's default office are matched
 */
procedure cat_entities (
   p_entity_cursor         out sys_refcursor,
   p_entity_id_mask        in varchar2 default '*',
   p_parent_entity_id_mask in varchar2 default '*',
   p_match_null_parents    in varchar2 default 'T',
   p_category_id_mask      in varchar2 default '*',
   p_entity_name_mask      in varchar2 default '*',
   p_office_id_mask        in varchar2 default null);
/**
 * Catalogs entities in the database that match input parameters. Matching is
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
 * @param p_entity_id_mask        The entity identifier pattern to match. If not specified, all entity identfiers are matched
 * @param p_parent_entity_id_mask The parent entity identifier pattern to match. If not specified or '*', all non-NULL parent entity identfiers are matched
 * @param p_match_null_parents    A flag ('T'/'F') specifying whether to match entities without a parent entity
 * @param p_category_id_mask      The category identifier pattern to match. If not specified, all category identifiers are matched
 * @param p_entity_name_mask      The entity name pattern to match. If not specified, all entity names are matched
 * @param p_office_id_mask        The owning office to match. If not specified or NULL, only enities owned by the CWMS office and the session user's default office are matched
 *
 * @return A cursor containing the matched entities. The cursor
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
 *     <td class="descr">The office that owns the entity</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">entity_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the entity</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_entity_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the parent entity, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">category_id</td>
 *     <td class="descr">varchar2(3)</td>
 *     <td class="descr">The category to which the entity belongs</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">entity_name</td>
 *     <td class="descr">varchar2(128)</td>
 *     <td class="descr">The name of the entity</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">entity_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the entity in the database</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the parent entity, if any, in the database</td>
 *   </tr>
 * </table>
 */
function cat_entities_f (
   p_entity_id_mask        in varchar2 default '*',
   p_parent_entity_id_mask in varchar2 default '*',
   p_match_null_parents    in varchar2 default 'T',
   p_category_id_mask      in varchar2 default '*',
   p_entity_name_mask      in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor;

end cwms_entity;
/

show errors

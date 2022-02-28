create or replace package cwms_entity
/**
 * Routines to work with CWMS entities
 *
 * @author Mike Perryman
 *
 * @since CWMS 3.0
 */
as

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
 * Retrieves information about an entity in the database given the entity's text identifier
 *
 * @param p_entity_code      The numeric code of the specified entity in the database.
 * @param p_office_id_out    The office that owns the entity in the database.
 * @param p_parent_entity_id The identifier of the parent entity, if any.
 * @param p_category_id      The category of the entity.
 * @param p_entity_name      The name of the entity.
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
 * Retrieves information about an entity in the database given the entity's numeric code
 *
 * @param p_entity_code      The numeric code of the entity to retrieve information about.
 * @param p_entity_id        The text identifier of the entity in the database.
 * @param p_office_id_out    The office that owns the entity in the database.
 * @param p_parent_entity_id The identifier of the parent entity, if any.
 * @param p_category_id      The category of the entity.
 * @param p_entity_name      The name of the entity.
 */
procedure retrieve_entity (
   p_entity_id        in out nocopy varchar2,
   p_office_id        in out nocopy varchar2,
   p_parent_entity_id in out nocopy varchar2,
   p_category_id      in out nocopy varchar2,
   p_entity_name      in out nocopy varchar2,
   p_entity_code      in integer);
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
/**
 * Retrieves the entity id for a specified numeric code
 *
 * @param p_entity_code The numeric code that specifies the entity in the database
 *
 * @return The text identifier of the entity
 */
function get_entity_id (
   p_entity_code in integer)
   return varchar2;
/**
 * Retrieves the descendent entities for a specified entity
 *
 * @param p_descendents  A table of entities that are direct and possibly indirect descendants of the specified ancestor entity
 * @param p_entity_id    The text identifier of the specified ancestor entity to retrieve descendants for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified ancestor entity in the results
 * @param p_office_id    The selected office of specified ancestor entity. If not specified or NULL, the session user's current office will be used. The specified ancestor entity is owned either by this office or the CWMS office.
 */
procedure retrieve_descendants(
   p_descendants  out entity_tab_t,
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves the descendent entities for a specified entity
 *
 * @param p_entity_id    The text identifier of the specified ancestor entity to retrieve descendants for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified ancestor entity in the results
 * @param p_office_id    The selected office of specified ancestor entity. If not specified or NULL, the session user's current office will be used. The specified ancestor entity is owned either by this office or the CWMS office.
 *
 * @return A table of entities that are direct and possibly indirect descendants of the specified ancestor entity
 */
function retrieve_descendants_f(
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null)
   return entity_tab_t;
/**
 * Retrieves the descendent entities for a specified entity
 *
 * @param p_descendents  A table of entities that are direct and possibly indirect descendants of the specified ancestor entity
 * @param p_entity_code  The numeric code of the specified ancestor entity to retrieve descendants for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified ancestor entity in the results
 */
procedure retrieve_descendants(
   p_descendants  out entity_tab_t,
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2);
/**
 * Retrieves the descendent entities for a specified entity
 *
 * @param p_entity_code  The numeric code of the specified ancestor entity to retrieve descendants for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified ancestor entity in the results
 *
 * @return  A table of entities that are direct and possibly indirect descendants of the specified ancestor entity
 */
function retrieve_descendants_f(
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2)
   return entity_tab_t;
/**
 * Retrieves the ancestor entities for a specified entity
 *
 * @param p_ancestors    A table of entities that are direct and possibly indirect ancestors of the specified descendant entity. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.
 * @param p_entity_id    The text identifier of the specified descendant entity to retrieve ancestors for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified descendant entity in the results
 * @param p_office_id    The selected office of specified descendant entity. If not specified or NULL, the session user's current office will be used. The specified descendant entity is owned either by this office or the CWMS office.
 */
procedure retrieve_ancestors(
   p_ancestors    out entity_tab_t,
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null);
/**
 * Retrieves the ancestor entities for a specified entity
 *
 * @param p_entity_id    The text identifier of the specified descendant entity to retrieve ancestors for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified descendant entity in the results
 * @param p_office_id    The selected office of specified descendant entity. If not specified or NULL, the session user's current office will be used. The specified descendant entity is owned either by this office or the CWMS office.
 *
 * @return A table of entities that are direct and possibly indirect ancestors of the specified descendant entity. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.
 */
function retrieve_ancestors_f(
   p_entity_id    in  varchar2,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2,
   p_office_id    in  varchar2 default null)
   return entity_tab_t;
/**
 * Retrieves the ancestor entities for a specified entity
 *
 * @param p_ancestors    A table of entities that are direct and possibly indirect ancestors of the specified descendant entity. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.
 * @param p_entity_code  The numeric code of the specified descendant entity to retrieve ancestors for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified descendant entity in the results
 */
procedure retrieve_ancestors(
   p_ancestors    out entity_tab_t,
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2);
/**
 * Retrieves the ancestor entities for a specified entity
 *
 * @param p_entity_code  The numeric code of the specified descendant entity to retrieve ancestors for
 * @param p_direct_only  A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self A flag ('T'/'F') specifying whether to include the specified descendant entity in the results
 *
 * @return  A table of entities that are direct and possibly indirect ancestors of the specified descendant entity. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.
 */
function retrieve_ancestors_f(
   p_entity_code  in  integer,
   p_direct_only  in  varchar2,
   p_include_self in  varchar2)
   return entity_tab_t;
/**
 * Deletes an entity from the database
 *
 * @param p_entity_code           The entity to delete
 * @param p_delete_child_entities A flag ('T'/'F') specifying whether to delete all child entities. If 'T' any descendant entities will also be deleted. If 'F', the procedure will fail if the entity has any descendants.
 * @param p_office_id             The office that owns the entity in the database. If not specified or NULL, the sessions user's default office will be used
 */
procedure delete_entity (
   p_entity_code           in integer,
   p_delete_child_entities in varchar default 'F');
/**
 * Deletes an entity from the database
 *
 * @param p_entity_id             The indentifier of the entity to delete
 * @param p_delete_child_entities A flag ('T'/'F') specifying whether to delete all child entities. If 'T' any descendant entities will also be deleted. If 'F', the procedure will fail if the entity has any descendants.
 * @param p_office_id             The office that owns the entity in the database. If not specified or NULL, the sessions user's default office will be used
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
procedure cat_entities(
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
function cat_entities_f(
   p_entity_id_mask        in varchar2 default '*',
   p_parent_entity_id_mask in varchar2 default '*',
   p_match_null_parents    in varchar2 default 'T',
   p_category_id_mask      in varchar2 default '*',
   p_entity_name_mask      in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor;
/**
 * Associates an existing location with an existing entity
 *
 * @param p_location_code The location to associate with an entity
 * @param p_entity_code The entity to associate with the location
 * @param p_comments Comments about the location-entity association
 * @param p_fail_if_exists A flag ('T'/'F') that specifies whether to fail if the location is already associated with an entity
 */
procedure store_entity_location(
   p_location_code  in integer,
   p_entity_code    in integer,
   p_comments       in varchar2,
   p_fail_if_exists in varchar2);
/**
 * Associates an existing location with an existing entity
 *
 * @param p_location_id The location to associate with an entity
 * @param p_entity_id The entity to associate with the location
 * @param p_comments Comments about the location-entity association
 * @param p_fail_if_exists A flag ('T'/'F') that specifies whether to fail if the location is already associated with an entity
 * @param p_office_id The office that owns the location and reference office for the enity. The entity must be owned by this office or by the CWMS office. If not specified or NULL, the session user's current office is used.
 */
procedure store_entity_location(
   p_location_id    in varchar2,
   p_entity_id      in varchar2,
   p_comments       in varchar2,
   p_fail_if_exists in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Disassociates a location from an entity, optionally deleting the location and/or entity
 *
 * @param p_location_code The location to disassociate from the entity
 * @param p_delete_location A flag ('T'/'F') specifying whether to delete the location. Defaults to 'F'.
 * @param p_delete_entity A flag ('T'/'F') specifying whether to delete the entity. Defaults to 'F'.
 * @param p_del_location_action Specifies the location deletion action if p_delete_location is 'T'. Defaults to 'DELETE KEY'.
 * @param p_del_child_entities Specifies whether to delete child entities if p_delete_entity is 'T'. Defaults to 'F'.
 */
procedure delete_entity_location(
   p_location_code       in integer,
   p_delete_location     in varchar2 default 'F',
   p_delete_entity       in varchar2 default 'F',
   p_del_location_action in varchar2 default 'DELETE KEY',
   p_del_child_entities  in varchar2 default 'F');
/**
 * Disassociates a location from an entity, optionally deleting the location and/or entity
 *
 * @param p_location_id The location to disassociate from the entity
 * @param p_delete_location A flag ('T'/'F') specifying whether to delete the location. Defaults to 'F'.
 * @param p_delete_entity A flag ('T'/'F') specifying whether to delete the entity. Defaults to 'F'.
 * @param p_del_location_action Specifies the location deletion action if p_delete_location is 'T'. Defaults to 'DELETE KEY'.
 * @param p_del_child_entities Specifies whether to delete child entities if p_delete_entity is 'T'. Defaults to 'F'.
 * @param p_office_id The office that owns the location. If not specified or NULL, the session user's current office is used.
 */
procedure delete_entity_location(
   p_location_id         in varchar2,
   p_delete_location     in varchar2 default 'F',
   p_delete_entity       in varchar2 default 'F',
   p_del_location_action in varchar2 default 'DELETE KEY',
   p_del_child_entities  in varchar2 default 'F',
   p_office_id           in varchar2 default null);

end cwms_entity;
/

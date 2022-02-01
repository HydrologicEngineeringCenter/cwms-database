create or replace package cwms_configuration
/**
 * Facilities for working with configurations in the CWMS database
 *
 * @author Mike Perryman
 *
 * @since CWMS 3.2
 */
as

/**
 * Stores an configuration to the database
 *
 * @param p_configuration_id        The character identifier of the configuration
 * @param p_configuration_name      The name of the configuration
 * @param p_parent_configuration_id The character identifier of the parent configuration, if any
 * @param p_category_id             The category the configuration belongs to
 * @param p_fail_if_exists          A flag ('T'/'F') specifying whether to fail if the configuration identifier already exists
 * @param p_ignore_nulls            A flag ('T'/'F') specifying whether to ignore null parameters when updating an configuration
 * @param p_office_id               The office that owns the configuration in the database. If not specified or NULL, the sessions user's default office will be used
 */
procedure store_configuration (
   p_configuration_id        in varchar2,
   p_configuration_name      in varchar2,
   p_parent_configuration_id in varchar2 default null,
   p_category_id             in varchar2 default null,
   p_fail_if_exists          in varchar2 default 'T',
   p_ignore_nulls            in varchar2 default 'T',
   p_office_id               in varchar2 default null);
/**
 * Retrieves information about an configuration in the database given the configuration's text identifier
 *
 * @param p_configuration_code      The numeric code of the specified configuration in the database.
 * @param p_office_id_out           The office that owns the configuration in the database.
 * @param p_parent_configuration_id The identifier of the parent configuration, if any.
 * @param p_category_id             The category of the configuration.
 * @param p_configuration_name      The name of the configuration.
 * @param p_configuration_id        The text identifier of the configuration to retrieve information about.
 * @param p_office_id               The selected office. Only configurations that are owned by the CWMS office or this one will be retrieved. If not specified or NULL, the sessions user's default office will be used
 */
procedure retrieve_configuration (
   p_configuration_code      in out nocopy integer,
   p_office_id_out           in out nocopy varchar2,
   p_parent_configuration_id in out nocopy varchar2,
   p_category_id             in out nocopy varchar2,
   p_configuration_name      in out nocopy varchar2,  
   p_configuration_id        in varchar2,
   p_office_id               in varchar2 default null);
/**
 * Retrieves information about an configuration in the database given the configuration's numeric code
 *
 * @param p_configuration_code      The numeric code of the configuration to retrieve information about.
 * @param p_configuration_id        The text identifier of the configuration in the database.
 * @param p_office_id_out           The office that owns the configuration in the database.
 * @param p_parent_configuration_id The identifier of the parent configuration, if any.
 * @param p_category_id             The category of the configuration.
 * @param p_configuration_name      The name of the configuration.
 */
procedure retrieve_configuration (
   p_configuration_id        in out nocopy varchar2,
   p_office_id               in out nocopy varchar2,
   p_parent_configuration_id in out nocopy varchar2,
   p_category_id             in out nocopy varchar2,
   p_configuration_name      in out nocopy varchar2,  
   p_configuration_code      in integer);
/**
 * Retreives the numeric code for the specified configuration
 *
 * @param p_configuration_id The indentifier of the configuration to retrieve the code for
 * @param p_office_id        The selected office. Only configurations that are owned by the CWMS office or this one will be retrieved. If not specified or NULL, the sessions user's default office will be used
 *
 * @return The numeric code for the specified configuration
 */
function get_configuration_code (
   p_configuration_id in varchar2,
   p_office_id        in varchar2 default null)
   return integer;
/**
 * Retrieves the configuration id for a specified numeric code
 *
 * @param p_configuration_code The numeric code that specifies the configuration in the database
 *
 * @return The text identifier of the configuration
 */
function get_configuration_id (
   p_configuration_code in integer)
   return varchar2;
/**
 * Retrieves the descendent configurations for a specified configuration
 *
 * @param p_descendents      A table of configurations that are direct and possibly indirect descendants of the specified ancestor configuration  
 * @param p_configuration_id The text identifier of the specified ancestor configuration to retrieve descendants for 
 * @param p_direct_only      A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self     A flag ('T'/'F') specifying whether to include the specified ancestor configuration in the results
 * @param p_office_id        The selected office of specified ancestor configuration. If not specified or NULL, the session user's current office will be used. The specified ancestor configuration is owned either by this office or the CWMS office.
 */
procedure retrieve_descendants(
   p_descendants      out configuration_tab_t,
   p_configuration_id in  varchar2,
   p_direct_only      in  varchar2,
   p_include_self     in  varchar2,
   p_office_id        in  varchar2 default null);
/**
 * Retrieves the descendent configurations for a specified configuration
 *
 * @param p_configuration_id The text identifier of the specified ancestor configuration to retrieve descendants for 
 * @param p_direct_only      A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self     A flag ('T'/'F') specifying whether to include the specified ancestor configuration in the results
 * @param p_office_id        The selected office of specified ancestor configuration. If not specified or NULL, the session user's current office will be used. The specified ancestor configuration is owned either by this office or the CWMS office.
 *
 * @return A table of configurations that are direct and possibly indirect descendants of the specified ancestor configuration
 */
function retrieve_descendants_f(
   p_configuration_id in  varchar2,
   p_direct_only      in  varchar2,
   p_include_self     in  varchar2,
   p_office_id        in  varchar2 default null)
   return configuration_tab_t;
/**
 * Retrieves the descendent configurations for a specified configuration
 *
 * @param p_descendents        A table of configurations that are direct and possibly indirect descendants of the specified ancestor configuration  
 * @param p_configuration_code The numeric code of the specified ancestor configuration to retrieve descendants for 
 * @param p_direct_only        A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self       A flag ('T'/'F') specifying whether to include the specified ancestor configuration in the results
 */
procedure retrieve_descendants(
   p_descendants        out configuration_tab_t,
   p_configuration_code in  integer,
   p_direct_only        in  varchar2,
   p_include_self       in  varchar2);
/**
 * Retrieves the descendent configurations for a specified configuration
 *
 * @param p_configuration_code The numeric code of the specified ancestor configuration to retrieve descendants for 
 * @param p_direct_only        A flag ('T'/'F') specifying whether to retrieve direct descendants (children) only ('T') or to retrieve descendants of all levels ('F')
 * @param p_include_self       A flag ('T'/'F') specifying whether to include the specified ancestor configuration in the results
 *
 * @return  A table of configurations that are direct and possibly indirect descendants of the specified ancestor configuration  
 */
function retrieve_descendants_f(
   p_configuration_code in  integer,
   p_direct_only        in  varchar2,
   p_include_self       in  varchar2)
   return configuration_tab_t;
/**
 * Retrieves the ancestor configurations for a specified configuration
 *
 * @param p_ancestors        A table of configurations that are direct and possibly indirect ancestors of the specified descendant configuration. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.  
 * @param p_configuration_id The text identifier of the specified descendant configuration to retrieve ancestors for 
 * @param p_direct_only      A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self     A flag ('T'/'F') specifying whether to include the specified descendant configuration in the results
 * @param p_office_id        The selected office of specified descendant configuration. If not specified or NULL, the session user's current office will be used. The specified descendant configuration is owned either by this office or the CWMS office.
 */
procedure retrieve_ancestors(
   p_ancestors        out configuration_tab_t,
   p_configuration_id in  varchar2,
   p_direct_only      in  varchar2,
   p_include_self     in  varchar2,
   p_office_id        in  varchar2 default null);
/**
 * Retrieves the ancestor configurations for a specified configuration
 *
 * @param p_configuration_id The text identifier of the specified descendant configuration to retrieve ancestors for 
 * @param p_direct_only      A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self     A flag ('T'/'F') specifying whether to include the specified descendant configuration in the results
 * @param p_office_id        The selected office of specified descendant configuration. If not specified or NULL, the session user's current office will be used. The specified descendant configuration is owned either by this office or the CWMS office.
 *
 * @return A table of configurations that are direct and possibly indirect ancestors of the specified descendant configuration. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.
 */
function retrieve_ancestors_f(
   p_configuration_id in  varchar2,
   p_direct_only      in  varchar2,
   p_include_self     in  varchar2,
   p_office_id        in  varchar2 default null)
   return configuration_tab_t;
/**
 * Retrieves the ancestor configurations for a specified configuration
 *
 * @param p_ancestors          A table of configurations that are direct and possibly indirect ancestors of the specified descendant configuration. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.  
 * @param p_configuration_code The numeric code of the specified descendant configuration to retrieve ancestors for 
 * @param p_direct_only        A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self       A flag ('T'/'F') specifying whether to include the specified descendant configuration in the results
 */
procedure retrieve_ancestors(
   p_ancestors          out configuration_tab_t,
   p_configuration_code in  integer,
   p_direct_only        in  varchar2,
   p_include_self       in  varchar2);
/**
 * Retrieves the ancestor configurations for a specified configuration
 *
 * @param p_configuration_code The numeric code of the specified descendant configuration to retrieve ancestors for 
 * @param p_direct_only        A flag ('T'/'F') specifying whether to retrieve direct ancestors (children) only ('T') or to retrieve ancestors of all levels ('F')
 * @param p_include_self       A flag ('T'/'F') specifying whether to include the specified descendant configuration in the results
 *
 * @return  A table of configurations that are direct and possibly indirect ancestors of the specified descendant configuration. If p_direct_only is 'T' and p_include_self is 'F', this table will have only one element.  
 */
function retrieve_ancestors_f(
   p_configuration_code in  integer,
   p_direct_only        in  varchar2,
   p_include_self       in  varchar2)
   return configuration_tab_t;
/**
 * Deletes an configuration from the database
 *
 * @param p_configuration_id            The indentifier of the configuration to delete
 * @param p_delete_child_configurations A flag ('T'/'F') specifying whether to delete all child configurations. If 'T' any descendant configurations will also be deleted. If 'F', the procedure will fail if the configuration has any descendants.
 * @param p_office_id                   The office that owns the configuration in the database. If not specified or NULL, the sessions user's default office will be used
 */
procedure delete_configuration (
   p_configuration_id            in varchar2,
   p_delete_child_configurations in varchar default 'F',
   p_office_id                   in varchar2 default null);
/**
 * Catalogs configurations in the database that match input parameters. Matching is
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
 * @param p_configuration_cursor A cursor containing the matched configurations. The cursor
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
 *     <td class="descr">The office that owns the configuration</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">configuration_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the configuration</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_configuration_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the parent configuration, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">category_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The category to which the configuration belongs</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">configuration_name</td>
 *     <td class="descr">varchar2(128)</td>
 *     <td class="descr">The name of the configuration</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">configuration_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the configuration in the database</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the parent configuration, if any, in the database</td>
 *   </tr>
 * </table>
 * @param p_configuration_id_mask        The configuration identifier pattern to match. If not specified, all configuration identfiers are matched
 * @param p_parent_configuration_id_mask The parent configuration identifier pattern to match. If not specified or '*', all non-NULL parent configuration identfiers are matched
 * @param p_match_null_parents           A flag ('T'/'F') specifying whether to match configurations without a parent configuration
 * @param p_category_id_mask             The category identifier pattern to match. If not specified, all category identifiers are matched
 * @param p_configuration_name_mask      The configuration name pattern to match. If not specified, all configuration names are matched
 * @param p_office_id_mask               The owning office to match. If not specified or NULL, only enities owned by the CWMS office and the session user's default office are matched
 */
procedure cat_configurations (
   p_configuration_cursor         out sys_refcursor,
   p_configuration_id_mask        in varchar2 default '*',
   p_parent_configuration_id_mask in varchar2 default '*',
   p_match_null_parents           in varchar2 default 'T',
   p_category_id_mask             in varchar2 default '*',
   p_configuration_name_mask      in varchar2 default '*',
   p_office_id_mask               in varchar2 default null);
/**
 * Catalogs configurations in the database that match input parameters. Matching is
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
 * @param p_configuration_id_mask        The configuration identifier pattern to match. If not specified, all configuration identfiers are matched
 * @param p_parent_configuration_id_mask The parent configuration identifier pattern to match. If not specified or '*', all non-NULL parent configuration identfiers are matched
 * @param p_match_null_parents           A flag ('T'/'F') specifying whether to match configurations without a parent configuration
 * @param p_category_id_mask             The category identifier pattern to match. If not specified, all category identifiers are matched
 * @param p_configuration_name_mask      The configuration name pattern to match. If not specified, all configuration names are matched
 * @param p_office_id_mask               The owning office to match. If not specified or NULL, only enities owned by the CWMS office and the session user's default office are matched
 *
 * @return A cursor containing the matched configurations. The cursor
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
 *     <td class="descr">The office that owns the configuration</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">configuration_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the configuration</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_configuration_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The text identifier of the parent configuration, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">category_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The category to which the configuration belongs</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">configuration_name</td>
 *     <td class="descr">varchar2(128)</td>
 *     <td class="descr">The name of the configuration</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">configuration_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the configuration in the database</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The numeric code of the parent configuration, if any, in the database</td>
 *   </tr>
 * </table>
 */
function cat_configurations_f (
   p_configuration_id_mask        in varchar2 default '*',
   p_parent_configuration_id_mask in varchar2 default '*',
   p_match_null_parents           in varchar2 default 'T',
   p_category_id_mask             in varchar2 default '*',
   p_configuration_name_mask      in varchar2 default '*',
   p_office_id_mask               in varchar2 default null)
   return sys_refcursor;

end cwms_configuration;
/

show errors

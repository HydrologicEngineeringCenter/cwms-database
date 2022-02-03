create or replace package cwms_rating
/**
 * Provides routines dealing with ratings.<p>
 * General information about CWMS ratings can be found <a href="CWMS RATINGS.pdf">here</a>.
 *
 * @since CWMS 2.1
 *
 * @author Mike Perryman
 */
as

/*
 * Not documented. Package-specific and session-specific logging properties
 */
v_package_log_prop_text varchar2(30);
function package_log_property_text return varchar2;

/**
 * Sets text value of package logging property
 *
 * @param p_text The text of the package logging property. If unspecified or NULL, the current session identifier is used.
 */
procedure set_package_log_property_text(
   p_text in varchar2 default null);

/**
 * Top-level separator. Separates location, parameters, template version, and version
 *
 * @see constant separator2
 * @see constant separator3
 */
separator1 constant varchar2(1) := '.';
/**
 * Mid-level separator. Separates independent parameter(s) from dependent parameter
 *
 * @see constant separator1
 * @see constant separator3
 */
separator2 constant varchar2(1) := ';';
/**
 * Low-level separator. Separates multiple independent parameters
 *
 * @see constant separator1
 * @see constant separator2
 */
separator3 constant varchar2(1) := ',';
-- not documented
function get_rating_method_code(
   p_rating_method_id in varchar2)
   return number result_cache;
/**
 * Stores rating templates to the database.
 *
 * @see type rating_template_t
 *
 * @param p_xml The rating templates to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-template">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating templates already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates
 * already exists
 */
procedure store_templates(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);
/**
 * Stores rating templates to the database.
 *
 * @see type rating_template_t
 *
 * @param p_xml The rating templates to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-template">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating templates already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates
 * already exists
 */
procedure store_templates(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2);
/**
 * Stores rating templates to the database.
 *
 * @see type rating_template_t
 *
 * @param p_xml The rating templates to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-template">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating templates already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates
 * already exists
 */
procedure store_templates(
   p_xml            in clob,
   p_fail_if_exists in varchar2);
/**
 * Stores rating templates to the database.
 *
 * @see type rating_template_tab_t
 * @see type rating_template_t
 *
 * @param p_templates The rating templates to store
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating templates already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates
 * already exists
 */
procedure store_templates(
   p_templates      in rating_template_tab_t,
   p_fail_if_exists in varchar2);
/**
 * Catalogs stored rating templates that match specified parameters.  Matching is
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
 * @param p_cat_cursor A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">template_id</td>
 *     <td class="descr">varchar2(289)</td>
 *     <td class="descr">The rating template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parameters_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The parameters used by the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">version</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The template version</td>
 *   </tr>
 * </table>
 *
 * @param p_template_id_mask The rating template pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_template_ids(
   p_cat_cursor       out sys_refcursor,
   p_template_id_mask in  varchar2 default '*',
   p_office_id_mask   in  varchar2 default null);
/**
 * Catalogs stored rating templates that match specified parameters.  Matching is
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
 * @param p_template_id_mask The rating template pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">template_id</td>
 *     <td class="descr">varchar2(289)</td>
 *     <td class="descr">The rating template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parameters_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The parameters used by the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">version</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The template version</td></tr>
 * </table>
 */
function cat_template_ids_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieve rating templates matching input parameters. Matching is
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
 * @see type rating_template_tab_t
 *
 * @param p_templates A collection of templates that match the input parameters
 *
 * @param p_template_id_mask The rating template pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_templates_obj(
   p_templates        out rating_template_tab_t,
   p_template_id_mask in  varchar2 default '*',
   p_office_id_mask   in  varchar2 default null);
/**
 * Retrieve rating templates matching input parameters. Matching is
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
 * @see type rating_template_tab_t
 *
 * @param p_template_id_mask The rating template pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A collection of templates that match the input parameters
 */
function retrieve_templates_obj_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return rating_template_tab_t;
/**
 * Retrieve rating templates matching input parameters. Matching is
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
 * @param p_templates An XML instance of templates that match the input parameters
 * in a CLOB
 *
 * @param p_template_id_mask The rating template pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_templates_xml(
   p_templates        out clob,
   p_template_id_mask in  varchar2 default '*',
   p_office_id_mask   in  varchar2 default null);
/**
 * Retrieve rating templates matching input parameters. Matching is
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
 * @param p_template_id_mask The rating template pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return An XML instance of templates that match the input parameters
 * in a CLOB
 */
function retrieve_templates_xml_f(
   p_template_id_mask in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
   return clob;
/**
 * Delete rating templates matching input parameters from the database. Matching is
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
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_template_id_mask The rating template pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the matching templates, and only then if they are not referenced by any rating specifications</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only the rating specifications that reference the matching templates</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes the matching templates, as well as any rating specifications that reference them</td>
 *   </tr>
 * </table>
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure delete_templates(
   p_template_id_mask in varchar2 default '*',
   p_delete_action    in varchar2 default cwms_util.delete_key,
   p_office_id_mask   in varchar2 default null);
/**
 * Retrieves the "opening" parameter for the specified gate rating template. Gate ratings
 * have multiple independent parameters (pool elevation, gate opening, and possibly
 * tailwater elevation or others), with no standard order in which to specify them. Also,
 * the CWMS database is very strict in its parameter usage, requiring a parameter of
 * "Opening" to have units of length. However, for many gate ratings the "opening" is
 * specified in terms of percent of maximum opening, revolutions of a valve handle, etc...
 * Thus the need to locate the actual "opening" parameter, its unit, and its position in the
 * independent parameter specifications.
 *
 * @param p_template The rating template to retrieve the "opening" parameter for
 *
 * @return The formal CWMS parameter used to specify the gate opening.
 */
function get_opening_parameter(
   p_template in varchar2)
   return varchar2;
/**
 * Retrieves the "opening" parameter position for the specified gate rating template. Gate ratings
 * have multiple independent parameters (pool elevation, gate opening, and possibly
 * tailwater elevation or others), with no standard order in which to specify them. Also,
 * the CWMS database is very strict in its parameter usage, requiring a parameter of
 * "Opening" to have units of length. However, for many gate ratings the "opening" is
 * specified in terms of percent of maximum opening, revolutions of a valve handle, etc...
 * Thus the need to locate the actual "opening" parameter, its unit, and its position in the
 * independent parameter specifications.
 *
 * @param p_template The rating template to retrieve position of the "opening" parameter for
 *
 * @return The position of the parameter used to specify the gate opening in the
 * list of independent parameters.
 */
function get_opening_parameter_position(
   p_template in varchar2)
   return integer;
/**
 * Retrieves the unit of "opening" parameter for the specified gate rating template.
 * in the specified unit system Gate ratings have multiple independent parameters
 * (pool elevation, gate opening, and possibly tailwater elevation or others), with
 * no standard order in which to specify them. Also, the CWMS database is very strict
 * in its parameter usage, requiring a parameter of "Opening" to have units of length.
 * However, for many gate ratings the "opening" is specified in terms of percent of
 * maximum opening, revolutions of a valve handle, etc... Thus the need to locate the
 * actual "opening" parameter, its unit, and its position in the independent parameter
 * specifications.
 *
 * @param p_template The rating template to retrieve the unit of the "opening" parameter for
 *
 * @param p_unit_system The unit system ('EN' or 'SI') to retrieve the unit of the
 * "opening" parameter for
 *
 * @return The unit of the formal CWMS parameter used to specify the gate opening
 * for the specified unit system
 */
function get_opening_unit(
   p_template    in varchar2,
   p_unit_system in varchar2 default 'SI')
   return varchar2;
/**
 * Stores rating specifications to the database.
 *
 * @see type rating_spec_t
 *
 * @param p_xml The rating specifications to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-spec">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating specifications already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the specifications
 * already exists
 */
procedure store_specs(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);
/**
 * Stores rating specifications to the database.
 *
 * @see type rating_spec_t
 *
 * @param p_xml The rating specifications to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-spec">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating specifications already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the specifications
 * already exists
 */
procedure store_specs(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2);
/**
 * Stores rating specifications to the database.
 *
 * @see type rating_spec_t
 *
 * @param p_xml The rating specifications to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-spec">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating specifications already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the specifications
 * already exists
 */
procedure store_specs(
   p_xml            in clob,
   p_fail_if_exists in varchar2);
/**
 * Stores rating specifications to the database.
 *
 * @see type rating_spec_tab_t
 *
 * @param p_specs The collection of rating specifications to store
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the rating specifications already exists.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the specifications
 * already exists
 */
procedure store_specs(
   p_specs          in rating_spec_tab_t,
   p_fail_if_exists in varchar2);
/**
 * Catalogs stored rating specifications that match specified parameters.  Matching is
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
 * @param p_cat_cursor A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The location portion of the rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">template_id</td>
 *     <td class="descr">varchar2(289)</td>
 *     <td class="descr">The template portion of the rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">version</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The version portion of the rating specification</td>
 *   </tr>
 * </table>
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_spec_ids(
   p_cat_cursor     out sys_refcursor,
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null);
/**
 * Catalogs stored rating specifications that match specified parameters.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The location portion of the rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">template_id</td>
 *     <td class="descr">varchar2(289)</td>
 *     <td class="descr">The template portion of the rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">version</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The version portion of the rating specification</td>
 *   </tr>
 * </table>
 */
function cat_spec_ids_f(
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves rating specifications that match specified parameters.  Matching is
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
 * @param p_specs The rating specifications that match the input parameters
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_specs_obj(
   p_specs          out rating_spec_tab_t,
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null);
/**
 * Retrieves rating specifications that match specified parameters.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The rating specifications that match the input parameters
 */
function retrieve_specs_obj_f(
   p_spec_id_mask   in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return rating_spec_tab_t;
/**
 * Retrieves rating specifications that match specified parameters.  Matching is
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
 * @param p_specs The rating specifications that match the input parameters as an XML instance
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_specs_xml(
   p_specs          out clob,
   p_spec_id_mask   in  varchar2 default '*',
   p_office_id_mask in  varchar2 default null);
/**
 * Retrieves rating specifications that match specified parameters.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The rating specifications that match the input parameters as an XML instance
 */
function retrieve_specs_xml_f(
   p_spec_id_mask   in varchar2 default '*',
   p_office_id_mask in varchar2 default null)
   return clob;

--------------------------------------------------------------------------------
-- DELETE_SPECS
--
-- p_spec_id_mask
--    wildcard pattern to match for rating specification id
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to '*'
--
-- p_delete_action
--    cwms_util.delete_key
--       deletes only the specs, and only then if they are not referenced
--       by any rating ratings
--    cwms_util.delete_data
--       deletes only the ratings that reference the specs
--    cwms_util.delete_all
--       deletes the specs and the ratings that reference them
--
-- p_office_id_mask
--    wildcard pattern to match for rating spec id
--       use '*' and '?' instead of '%' and '_'
--       null input defaults to current user's office id
--
/**
 * Delete rating templates matching input parameters from the database. Matching is
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
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the matching specifications, and only then if they are not referenced by any ratings</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only the ratings that reference the matching specifications</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes the matching specifications, as well as any ratings that reference them</td>
 *   </tr>
 * </table>
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure delete_specs(
   p_spec_id_mask   in varchar2 default '*',
   p_delete_action  in varchar2 default cwms_util.delete_key,
   p_office_id_mask in varchar2 default null);
/**
 * Retrieves the rating template portion of a rating specification
 *
 * @param p_spec_id the rating specification
 *
 * @return the rating template portion of the rating specification
 */
function get_template(
   p_spec_id in varchar2)
   return varchar2;
/**
 * Stores ratings to the database.
 *
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>
 *  <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_usgs-stream-rating">and here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the ratings already exists.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the ratings
 * already exists
 */
procedure store_ratings(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F');
/**
 * Stores ratings to the database.
 *
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>
 *  <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_usgs-stream-rating">and here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the ratings already exists.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the ratings
 * already exists
 */
procedure store_ratings(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F');
/**
 * Stores ratings to the database.
 *
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>
 *  <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_usgs-stream-rating">and here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the ratings already exists.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the ratings
 * already exists
 */
procedure store_ratings(
   p_xml            in clob,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F');
/**
 * Stores ratings to the database.
 *
 * @see type rating_tab_t
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_ratings The collection of ratings to store. Contains one or more rating_t and/or
 * stream_rating_t objects.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the ratings already exists.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the ratings
 * already exists
 */
procedure store_ratings(
   p_ratings        in rating_tab_t,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F');
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
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
 * @param p_cat_cursor A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_ratings(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
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
 * @param p_cat_cursor A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_effective_date_end The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_eff_ratings(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 */
function cat_ratings_f(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor;
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 */
function cat_eff_ratings_f(
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor;
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards. Unlike cat_ratings, this routine catalogs ratings that are related
 * to parent ratings.
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
 * @param p_cat_cursor A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">parent_rating_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The rating code of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">parent_specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">parent_create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_ratings2(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.  Unlike cat_eff_ratings, this routine catalogs ratings that are related
 * to parent ratings.
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
 * @param p_cat_cursor A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">parent_rating_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The rating code of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">parent_specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">parent_create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_effective_date_end The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_eff_ratings2(
   p_cat_cursor           out sys_refcursor,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards. Unlike cat_ratings_f, this routine catalogs ratings that are related
 * to parent ratings.
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">parent_rating_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The rating code of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">parent_specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">parent_create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 */
function cat_ratings2_f(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor;
/**
 * Catalogs stored ratings that match specified parameters.  Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards. Unlike cat_eff_ratings_f, this routine catalogs ratings that are related
 * to parent ratings.
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching rating templates.  The cursor contains
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
 *     <td class="descr">The office that owns the template</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the rating was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">parent_rating_code</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The rating code of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">parent_specification_id</td>
 *     <td class="descr">varchar2(380)</td>
 *     <td class="descr">The rating specification of the parent rating, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">parent_effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, went into effect, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">parent_create_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The date/time that the parent rating, if any, was loaded into the database, in the specified time zone or in the rating location's local time zone if no time zone is specified</td>
 *   </tr>
 * </table>
 */
function cat_eff_ratings2_f(
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @see type rating_tab_t
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_ratings The ratings that match the input parameters.  May contain rating_t
 * and/or stream_rating_t objects
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_ratings_obj(
   p_ratings              out rating_tab_t,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @see type rating_tab_t
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_ratings The ratings that match the input parameters.  May contain rating_t
 * and/or stream_rating_t objects
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_eff_ratings_obj(
   p_ratings              out rating_tab_t,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @see type rating_tab_t
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters.  May contain rating_t
 * and/or stream_rating_t objects
 */
function retrieve_ratings_obj_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return rating_tab_t;
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @see type rating_tab_t
 * @see type rating_t
 * @see type stream_rating_t
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters.  May contain rating_t
 * and/or stream_rating_t objects
 */
function retrieve_eff_ratings_obj_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return rating_tab_t;
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @param p_ratings The ratings that match the input parameters, in XML format as a CLOB
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_ratings_xml(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @param p_ratings The ratings that match the input parameters, in XML format as a CLOB
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location. The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_eff_ratings_xml(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates.
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_ratings The ratings that match the input parameters, in XML format as a CLOB
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching. If the first character is '-' (hyphen), no rating values will be included in the output,
 * and the remaining characters are interpreted as the specification pattern to match.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_ratings_xml2(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates.
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_ratings The ratings that match the input parameters, in XML format as a CLOB
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching. If the first character is '-' (hyphen), no rating values will be included in the output,
 * and the remaining characters are interpreted as the specification pattern to match.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location. The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_eff_ratings_xml2(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates as well as ratings, parameters, and templates for any source ratings used (transitional and virtual ratings only).
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_ratings The ratings that match the input parameters, in XML format as a CLOB
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching. If the first character is '-' (hyphen), no rating values will be included in the output,
 * and the remaining characters are interpreted as the specification pattern to match.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_ratings_xml3(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates as well as ratings, parameters, and templates for any source ratings used (transitional and virtual ratings only).
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_ratings The ratings that match the input parameters, in XML format as a CLOB
 *
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching. If the first character is '-' (hyphen), no rating values will be included in the output,
 * and the remaining characters are interpreted as the specification pattern to match.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location. The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure retrieve_eff_ratings_xml3(
   p_ratings              out clob,
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null);
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters, in XML format as a CLOB
 */
function retrieve_ratings_xml_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob;
/**
 * Retrieves ratings that match specified parameters.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location. The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters, in XML format as a CLOB
 */
function retrieve_eff_ratings_xml_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob;
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates.
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters, in XML format as a CLOB
 */
function retrieve_ratings_xml2_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob;
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates.
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location. The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters, in XML format as a CLOB
 */
function retrieve_eff_ratings_xml2_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob;
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates as well as ratings, parameters, and templates for any source ratings used (transitional and virtual ratings only).
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters, in XML format as a CLOB
 */
function retrieve_ratings_xml3_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_effective_date_start in  date     default null,
   p_effective_date_end   in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob;
/**
 * Retrieves ratings that match specified parameters, plus rating specifications and templates as well as ratings, parameters, and templates for any source ratings used (transitional and virtual ratings only).
 * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_start_date The start time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or after than this date/time.
 * If not specified or NULL, no lower bound for effecive time window will be used.
 *
 * @param p_end_date The end time of the time window that the returned ratings will be effective in. If specified
 * and not NULL, no ratings will be matched that are not effective on or before than this date/time.
 * If not specified or NULL, no upper bound for effecive time window will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective time window.  If not
 * specified or NULL, the effective time window for each rating specification will be the
 * local time zone of that specification's location. The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return The ratings that match the input parameters, in XML format as a CLOB
 */
function retrieve_eff_ratings_xml3_f(
   p_spec_id_mask         in  varchar2 default '*',
   p_start_date           in  date     default null,
   p_end_date             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_office_id_mask       in  varchar2 default null)
   return clob;

-- not documented
function retrieve_ratings_xml_data(
   p_effective_tw         in varchar2,
   p_spec_id_mask         in varchar2 default '*',
   p_start_date           in date     default null,
   p_end_date             in date     default null,
   p_time_zone            in varchar2 default null,
   p_retrieve_templates   in boolean  default true,
   p_retrieve_specs       in boolean  default true,
   p_retrieve_ratings     in boolean  default true,
   p_recurse              in boolean  default true,
   p_include_points       in varchar2 default 'T',
   p_office_id_mask       in varchar2 default null)
   return clob;

/**
 * Deletes ratings that match specified parameters from the database.  Matching is
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
 * @param p_spec_id_mask The rating specification pattern to match.  Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_effective_date_start The start time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates earlier than this date/time.
 * If not specified or NULL, no lower bound for effecive date matching will be used.
 *
 * @param p_effective_date_end The end time of the effective date time window. If specified
 * and not NULL, no ratings will be matched that have effective dates later than this date/time.
 * If not specified or NULL, no upper bound for effecive date matching will be used.
 *
 * @param p_time_zone The time zone in which to intepret the effective date time window.  If not
 * specified or NULL, the effective data time window for each rating specification will be the
 * local time zone of that specification's location.  The output effective and create dates will
 * also be in this time zone, or in each specification's local time zone if not specified or NULL.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure delete_ratings(
   p_spec_id_mask         in varchar2 default '*',
   p_effective_date_start in date     default null,
   p_effective_date_end   in date     default null,
   p_time_zone            in varchar2 default null,
   p_office_id_mask       in varchar2 default null);
/**
 * Stores rating templates, rating specifications, and ratings to the database from a single XML instance.
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_ratings">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the templates, specifications, or ratings already exists.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates,
 * specifications, or ratings already exists
 */
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F');
/**
 * Stores rating templates, rating specifications, and ratings to the database from a single XML instance.
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_ratings">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the templates, specifications, or ratings already exists.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates,
 * specifications, or ratings already exists
 */
procedure store_ratings_xml(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F');
/**
 * Stores rating templates, rating specifications, and ratings to the database from a single XML instance.
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_ratings">documented here</a>.
 *
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies if the procedure should
 * fail if one of the templates, specifications, or ratings already exists.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates,
 * specifications, or ratings already exists
 */
procedure store_ratings_xml(
   p_xml            in clob,
   p_fail_if_exists in varchar2,
   p_replace_base   in varchar2 default 'F');
/**
 * Stores rating templates, rating specifications, and ratings to the database from a single XML instance.
 *
 * @param p_errors The list of errors encountered in storing the templates, specifications, or ratings. Sets of are separated by a
 * blank line. Each error set includes:
 * <ul>
 * <li> A line describing the operation</li>
 * <li> One or more lines for each error during the operation
 *      <ul>
 *      <li>Data errors are occupy a single line</li>
 *      <li>Oracle exceptions normally occupy multiple lines for the stack trace</li>
 *      </ul>
 * </li>
 * </ul>
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_ratings">documented here</a>.
 *
 * @param p_fail_if_exists A one or two character flag ('T', 'TT', 'TF' or 'F') that controls how the procedure handles existing items (templates,
 *                         specifications, or ratings). The first character (required) controls overwriting existing items. If 'T', no existing items
 *                         will be overwritten. If 'F', existing items will be overwritten. The second character (optional), is meaningful only if
 *                         the first character is 'T', and specifies whether ITEM_ALREADY_EXISTS errors will be included in the p_errors list. If
 *                         'T', ITEM_ALREADY_EXISTS errors will be included; if 'F' or unspecified, they will not be included.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates,
 * specifications, or ratings already exists
 */
procedure store_ratings_xml(
   p_errors         out nocopy clob,
   p_xml            in  xmltype,
   p_fail_if_exists in  varchar2,
   p_replace_base   in  varchar2 default 'F');
/**
 * Stores rating templates, rating specifications, and ratings to the database from a single XML instance.
 *
 * @param p_errors The list of errors encountered in storing the templates, specifications, or ratings. Sets of are separated by a
 * blank line. Each error set includes:
 * <ul>
 * <li> A line describing the operation</li>
 * <li> One or more lines for each error during the operation
 *      <ul>
 *      <li>Data errors are occupy a single line</li>
 *      <li>Oracle exceptions normally occupy multiple lines for the stack trace</li>
 *      </ul>
 * </li>
 * </ul>
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_ratings">documented here</a>.
 *
 * @param p_fail_if_exists A one or two character flag ('T', 'TT', 'TF' or 'F') that controls how the procedure handles existing items (templates,
 *                         specifications, or ratings). The first character (required) controls overwriting existing items. If 'T', no existing items
 *                         will be overwritten. If 'F', existing items will be overwritten. The second character (optional), is meaningful only if
 *                         the first character is 'T', and specifies whether ITEM_ALREADY_EXISTS errors will be included in the p_errors list. If
 *                         'T', ITEM_ALREADY_EXISTS errors will be included; if 'F' or unspecified, they will not be included.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates,
 * specifications, or ratings already exists
 */
procedure store_ratings_xml(
   p_errors         out nocopy clob,
   p_xml            in  varchar2,
   p_fail_if_exists in  varchar2,
   p_replace_base   in  varchar2 default 'F');
/**
 * Stores rating templates, rating specifications, and ratings to the database from a single XML instance.
 *
 * @param p_errors The list of errors encountered in storing the templates, specifications, or ratings. Sets of are separated by a
 * blank line. Each error set includes:
 * <ul>
 * <li> A line describing the operation</li>
 * <li> One or more lines for each error during the operation
 *      <ul>
 *      <li>Data errors are occupy a single line</li>
 *      <li>Oracle exceptions normally occupy multiple lines for the stack trace</li>
 *      </ul>
 * </li>
 * </ul>
 *
 * @param p_xml The ratings to store, in XML.  The XML instance must conform to
 * the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
 *  The specific format is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_ratings">documented here</a>.
 *
 * @param p_fail_if_exists A one or two character flag ('T', 'TT', 'TF' or 'F') that controls how the procedure handles existing items (templates,
 *                         specifications, or ratings). The first character (required) controls overwriting existing items. If 'T', no existing items
 *                         will be overwritten. If 'F', existing items will be overwritten. The second character (optional), is meaningful only if
 *                         the first character is 'T', and specifies whether ITEM_ALREADY_EXISTS errors will be included in the p_errors list. If
 *                         'T', ITEM_ALREADY_EXISTS errors will be included; if 'F' or unspecified, they will not be included.
 *
 * @param p_replace_base A flag('T' or 'F') that specifies whether any existing USGS-style stream rating
 * should be completely replaced even if the base ratings are the same. This flag has no effect on other types of ratings
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Flag</th>
 *     <th class="descr">Behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">'T'</td>
 *     <td class="descr">The existing USGS-style stream rating will be completely replaced with this one, even if the only difference is a new shift</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">'F'</td>
 *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
 *   </tr>
 * </table>
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the templates,
 * specifications, or ratings already exists
 */
procedure store_ratings_xml(
   p_errors         out nocopy clob,
   p_xml            in  clob,
   p_fail_if_exists in  varchar2,
   p_replace_base   in  varchar2 default 'F');
/**
 * Rates input values with ratings stored in the database.
 *
 * @param p_results     The rated (dependent) values
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) values. Each element of the table contains values for one of the independent parameters, in position order. Each element must be of the same length.
 * @param p_units       The units of each of the independent parameters, in position order, plus the desired output unit.  The length must be one greater that the length of p_values.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_times The date/time for each set of independent parameter values. Must be of the same length as each element of p_values.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate(
   p_results     out double_tab_t,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in  date_table_type default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates input values with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_results     The rated (dependent) values
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) values.
 * @param p_units       The unit of independent parameter, and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_times The date/time for each independent parameter value. Must be of the same length as p_values.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate(
   p_results     out double_tab_t,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in  date_table_type default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates a single input value with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_result      The rated (dependent) value
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input (independent) value.
 * @param p_units       The unit of independent parameter, and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_time  The date/time of the independent parameter value.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate(
   p_result      out binary_double,
   p_rating_spec in  varchar2,
   p_value       in  binary_double,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_time  in  date default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates a single input value with a rating stored in the database.
 *
 * @param p_result      The rated (dependent) value
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) parameter values.  Each element is a single value for an independent parameter, in position order.
 * @param p_units       The units of independent parameters, and the desired unit of the output. The length must be one greater that the length of p_values.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_time  The date/time of the independent parameter value.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate_one(
   p_result      out binary_double,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_time  in  date default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates a time series with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_results     The rated (dependent) values
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) parameter values.
 * @param p_units       The units of independent parameters, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As each element of the p_values parameter carries its own time zone, this parameter is not used to interpret those times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate(
   p_results     out tsv_array,
   p_rating_spec in  varchar2,
   p_values      in  tsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates a time series with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_results     The rated (dependent) values
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) parameter values.
 * @param p_units       The units of independent parameters, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date_time fields of each element of the p_values parameter, as well as p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate(
   p_results     out ztsv_array,
   p_rating_spec in  varchar2,
   p_values      in  ztsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates a single time series value with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_result      The rated (dependent) value
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input (independent) parameter value.
 * @param p_units       The units of independent parameter, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As the p_value parameter carries its own time zone, this parameter is not used to interpret that times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate(
   p_result      out tsv_type,
   p_rating_spec in  varchar2,
   p_value       in  tsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates a single time series value with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_result      The rated (dependent) value
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input (independent) parameter value.
 * @param p_units       The units of independent parameter, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date_time field of each element of the p_value parameter, as well as the p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As the p_value parameter carries its own time zone, this parameter is not used to interpret that times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure rate(
   p_result      out ztsv_type,
   p_rating_spec in  varchar2,
   p_value       in  ztsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Rates input values with ratings stored in the database.
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) values. Each element of the table contains values for one of the independent parameters, in position order. Each element must be of the same length.
 * @param p_units       The units of each of the independent parameters, in position order, plus the desired output unit.  The length must be one greater that the length of p_values.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_times The date/time for each set of independent parameter values. Must be of the same length as each element of p_values.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) values
 */
function rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t;
/**
 * Rates input values with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) values.
 * @param p_units       The unit of independent parameter, and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_times The date/time for each independent parameter value. Must be of the same length as p_values.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) values
 */
function rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t;
/**
 * Rates a single input value with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input (independent) value.
 * @param p_units       The unit of independent parameter, and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_time  The date/time of the independent parameter value.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) value
 */
function rate_f(
   p_rating_spec in varchar2,
   p_value       in binary_double,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return binary_double;
/**
 * Rates a single input value with a rating stored in the database.
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) parameter values.  Each element is a single value for an independent parameter, in position order.
 * @param p_units       The units of independent parameters, and the desired unit of the output. The length must be one greater that the length of p_values.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_time  The date/time of the independent parameter value.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) value
 */
function rate_one_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_time  in date default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return binary_double;
/**
 * Rates a time series with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) parameter values.
 * @param p_units       The units of independent parameters, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As each element of the p_values parameter carries its own time zone, this parameter is not used to interpret those times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) values
 */
function rate_f(
   p_rating_spec in varchar2,
   p_values      in tsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_array;
/**
 * Rates a time series with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input (independent) parameter values.
 * @param p_units       The units of independent parameters, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date_time fields of each element of the p_values parameter, as well as p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) values
 */
function rate_f(
   p_rating_spec in varchar2,
   p_values      in ztsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;
/**
 * Rates a single time series value with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input (independent) parameter value.
 * @param p_units       The units of independent parameter, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As the p_value parameter carries its own time zone, this parameter is not used to interpret that times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) value
 */
function rate_f(
   p_rating_spec in varchar2,
   p_value       in tsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_type;
/**
 * Rates a single time series value with a rating stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input (independent) parameter value.
 * @param p_units       The units of independent parameter, and the desired unit of the output. The length must be 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date_time field of each element of the p_value parameter, as well as the p_ratings_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As the p_value parameter carries its own time zone, this parameter is not used to interpret that times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated (dependent) value
 */
function rate_f(
   p_rating_spec in varchar2,
   p_value       in ztsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_type;
/**
 * Reverse rates input values with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_results     The rated values
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_times The date/time for each independent parameter value. Must be of the same length as p_values.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure reverse_rate(
   p_results     out double_tab_t,
   p_rating_spec in  varchar2,
   p_values      in  double_tab_t,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_times in  date_table_type default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Reverse rates an input value with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_result      The rated value
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input value
 * @param p_units       The unit of input value and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_time  The date/time for the input value
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure reverse_rate(
   p_result      out binary_double,
   p_rating_spec in  varchar2,
   p_value       in  binary_double,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_value_time  in  date default null,
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Reverse rates a time series with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_results     The rated values
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As each element of the p_values parameter carries its own time zone, this parameter is not used to interpret those times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure reverse_rate(
   p_results     out tsv_array,
   p_rating_spec in  varchar2,
   p_values      in  tsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Reverse rates a time series with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_results     The rated values
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret date_time fields of each element of the p_values parameter, as well as the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure reverse_rate(
   p_results     out ztsv_array,
   p_rating_spec in  varchar2,
   p_values      in  ztsv_array,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Reverse rates a single time series value with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_result      The rated value
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As the p_value parameter carries its own time zone, this parameter is not used to interpret that time.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure reverse_rate(
   p_result      out tsv_type,
   p_rating_spec in  varchar2,
   p_value       in  tsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Reverse rates a single time series value with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_result      The rated value
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input value .
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret date_time field the p_value parameter, as well as the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 */
procedure reverse_rate(
   p_result      out ztsv_type,
   p_rating_spec in  varchar2,
   p_value       in  ztsv_type,
   p_units       in  str_tab_t,
   p_round       in  varchar2 default 'F',
   p_rating_time in  date default null,
   p_time_zone   in  varchar2 default null,
   p_office_id   in  varchar2 default null);
/**
 * Reverse rates input values with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_times The date/time for each independent parameter value. Must be of the same length as p_values.
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated values
 */
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in double_tab_t,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date_table_type default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return double_tab_t;
/**
 * Reverse rates an input value with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input value
 * @param p_units       The unit of input value and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_value_time  The date/time for the input value
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated value
 */
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in binary_double,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_value_times in date default null,
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return binary_double;
/**
 * Reverse rates a time series with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As each element of the p_values parameter carries its own time zone, this parameter is not used to interpret those times.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated values
 */
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in tsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_array;
/**
 * Reverse rates a time series with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_values      The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret date_time fields of each element of the p_values parameter, as well as the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated values
 */
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_values      in ztsv_array,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_array;
/**
 * Reverse rates a single time series value with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input values.
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used. As the p_value parameter carries its own time zone, this parameter is not used to interpret that time.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated value
 */
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in tsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return tsv_type;
/**
 * Reverse rates a single time series value with ratings stored in the database. Restricted to ratings with a single independent parameter
 *
 * @param p_rating_spec The rating specification to use
 * @param p_value       The input value .
 * @param p_units       The unit of input values and the desired unit of the output.  Must be of length 2.
 * @param p_round       A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_rating_time A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone   The time zone in which to interpret date_time field the p_value parameter, as well as the p_rating_time parameter. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_office_id   The office that owns the rating specification and associated ratings.  If not specified or NULL, the session user's default office will be used.
 *
 * @return The rated value
 */
function reverse_rate_f(
   p_rating_spec in varchar2,
   p_value       in ztsv_type,
   p_units       in str_tab_t,
   p_round       in varchar2 default 'F',
   p_rating_time in date default null,
   p_time_zone   in varchar2 default null,
   p_office_id   in varchar2 default null)
   return ztsv_type;
/**
 * Rates one or more input time series stored in the database with ratings stored in
 * the database to generate a rated time series, which is returned
 *
 * @see cwms_ts.retrieve_ts
 *
 * @param p_independent_ids  A collection of time series identifiers of the time series to rate, in position order of the independent parameters of the rating
 * @param p_rating_id        The rating specification to use
 * @param p_units            The desired unit of the rated time series
 * @param p_start_time       The start of the time window to rate
 * @param p_end_time         The end of the time window to rate
 * @param p_rating_time      A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone        The time zone in which to interpret date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_round            A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_trim             Parameter for cwms_ts.retrieve_ts. Specifies whether to trim missing values from the ends of the retrieved time series
 * @param p_start_inclusive  Parameter for cwms_ts.retrieve_ts. Specifies whether the time window starts on or after the specified time
 * @param p_end_inclusive    Parameter for cwms_ts.retrieve_ts. Specifies whether the time window ends on or before the specified time
 * @param p_previous         Parameter for cwms_ts.retrieve_ts. Specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     Parameter for cwms_ts.retrieve_ts. Specifies the version date of the retrieve time series
 * @param p_max_version      Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the max or min version data of the time sereies if p_version_date is NULL
 * @param p_ts_office_id     Office owning the time series.  If not specified or NULL the session user's default office is used.
 * @param p_rating_office_id Office owning the ratings.  If not specified or NULL the session user's default office is used.
 *
 * @return The rated time series
 */
function retrieve_rated_ts(
   p_independent_ids  in str_tab_t,
   p_rating_id        in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_round            in varchar2 default 'F',
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
   return ztsv_array;
/**
 * Rates a single input time series stored in the database with ratings stored in
 * the database to generate a rated time series, which is returned
 *
 * @see cwms_ts.retrieve_ts
 *
 * @param p_independent_id   The time series identifier of the time series to rate
 * @param p_rating_id        The rating specification to use
 * @param p_units            The desired unit of the rated time series
 * @param p_start_time       The start of the time window to rate
 * @param p_end_time         The end of the time window to rate
 * @param p_rating_time      A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone        The time zone in which to interpret date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_round            A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_trim             Parameter for cwms_ts.retrieve_ts. Specifies whether to trim missing values from the ends of the retrieved time series
 * @param p_start_inclusive  Parameter for cwms_ts.retrieve_ts. Specifies whether the time window starts on or after the specified time
 * @param p_end_inclusive    Parameter for cwms_ts.retrieve_ts. Specifies whether the time window ends on or before the specified time
 * @param p_previous         Parameter for cwms_ts.retrieve_ts. Specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     Parameter for cwms_ts.retrieve_ts. Specifies the version date of the retrieve time series
 * @param p_max_version      Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the max or min version data of the time sereies if p_version_date is NULL
 * @param p_ts_office_id     Office owning the time series.  If not specified or NULL the session user's default office is used.
 * @param p_rating_office_id Office owning the ratings.  If not specified or NULL the session user's default office is used.
 *
 * @return The rated time series
 */
function retrieve_rated_ts(
   p_independent_id   in varchar2,
   p_rating_id        in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_round            in varchar2 default 'F',
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
   return ztsv_array;
/**
 * Rates one or more input time series stored in the database with ratings stored in
 * the database to generate a rated time series, which is stored to the database
 *
 * @see cwms_ts.retrieve_ts
 *
 * @param p_independent_ids  A collection of time series identifiers of the time series to rate, in position order of the independent parameters of the rating
 * @param p_dependent_id     The time series identifiers of the rated time series
 * @param p_rating_id        The rating specification to use
 * @param p_units            The desired unit of the rated time series
 * @param p_start_time       The start of the time window to rate
 * @param p_end_time         The end of the time window to rate
 * @param p_rating_time      A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone        The time zone in which to interpret date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_round            A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_trim             Parameter for cwms_ts.retrieve_ts. Specifies whether to trim missing values from the ends of the retrieved time series
 * @param p_start_inclusive  Parameter for cwms_ts.retrieve_ts. Specifies whether the time window starts on or after the specified time
 * @param p_end_inclusive    Parameter for cwms_ts.retrieve_ts. Specifies whether the time window ends on or before the specified time
 * @param p_previous         Parameter for cwms_ts.retrieve_ts. Specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     Parameter for cwms_ts.retrieve_ts. Specifies the version date of the retrieve time series
 * @param p_max_version      Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the max or min version data of the time sereies if p_version_date is NULL
 * @param p_ts_office_id     Office owning the time series.  If not specified or NULL the session user's default office is used.
 * @param p_rating_office_id Office owning the ratings.  If not specified or NULL the session user's default office is used.
 */
procedure rate(
   p_independent_ids  in str_tab_t,
   p_dependent_id     in varchar2,
   p_rating_id        in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null);
/**
 * Rates a single input time series stored in the database with ratings stored in
 * the database to generate a rated time series, which is stored to the database
 *
 * @see cwms_ts.retrieve_ts
 *
 * @param p_independent_id   The time series identifier of the time series to rate
 * @param p_dependent_id     The time series identifiers of the rated time series which is stored to the database
 * @param p_rating_id        The rating specification to use
 * @param p_units            The desired unit of the rated time series
 * @param p_start_time       The start of the time window to rate
 * @param p_end_time         The end of the time window to rate
 * @param p_rating_time      A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone        The time zone in which to interpret date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_round            A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_trim             Parameter for cwms_ts.retrieve_ts. Specifies whether to trim missing values from the ends of the retrieved time series
 * @param p_start_inclusive  Parameter for cwms_ts.retrieve_ts. Specifies whether the time window starts on or after the specified time
 * @param p_end_inclusive    Parameter for cwms_ts.retrieve_ts. Specifies whether the time window ends on or before the specified time
 * @param p_previous         Parameter for cwms_ts.retrieve_ts. Specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     Parameter for cwms_ts.retrieve_ts. Specifies the version date of the retrieve time series
 * @param p_max_version      Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the max or min version data of the time sereies if p_version_date is NULL
 * @param p_ts_office_id     Office owning the time series.  If not specified or NULL the session user's default office is used.
 * @param p_rating_office_id Office owning the ratings.  If not specified or NULL the session user's default office is used.
 */
procedure rate(
   p_independent_id   in varchar2,
   p_dependent_id     in varchar2,
   p_rating_id        in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null);
/**
 * Reverse rates a single input time series stored in the database with ratings stored in
 * the database to generate a rated time series, which is returned
 *
 * @see cwms_ts.retrieve_ts
 *
 * @param p_input_id         The time series identifier of the time series to rate
 * @param p_rating_id        The rating specification to use
 * @param p_units            The desired unit of the rated time series
 * @param p_start_time       The start of the time window to rate
 * @param p_end_time         The end of the time window to rate
 * @param p_rating_time      A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone        The time zone in which to interpret date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_round            A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_trim             Parameter for cwms_ts.retrieve_ts. Specifies whether to trim missing values from the ends of the retrieved time series
 * @param p_start_inclusive  Parameter for cwms_ts.retrieve_ts. Specifies whether the time window starts on or after the specified time
 * @param p_end_inclusive    Parameter for cwms_ts.retrieve_ts. Specifies whether the time window ends on or before the specified time
 * @param p_previous         Parameter for cwms_ts.retrieve_ts. Specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     Parameter for cwms_ts.retrieve_ts. Specifies the version date of the retrieve time series
 * @param p_max_version      Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the max or min version data of the time sereies if p_version_date is NULL
 * @param p_ts_office_id     Office owning the time series.  If not specified or NULL the session user's default office is used.
 * @param p_rating_office_id Office owning the ratings.  If not specified or NULL the session user's default office is used.
 *
 * @return The rated time series
 */
function retrieve_reverse_rated_ts(
   p_input_id         in varchar2,
   p_rating_id        in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_round            in varchar2 default 'F',
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null)
   return ztsv_array;
/**
 * Reverse rates a single input time series stored in the database with ratings stored in
 * the database to generate a rated time series, which is stored to the database
 *
 * @see cwms_ts.retrieve_ts
 *
 * @param p_input_id         The time series identifier of the time series to rate
 * @param p_output_id        The time series identifier of the rated time series stored to the databse
 * @param p_rating_id        The rating specification to use
 * @param p_units            The desired unit of the rated time series
 * @param p_start_time       The start of the time window to rate
 * @param p_end_time         The end of the time window to rate
 * @param p_rating_time      A specific date/time to use as the "current time" of the rating.  No ratings with a create date later than this will be used. Useful for performing historical ratings. If not specified or NULL, the current time is use.
 * @param p_time_zone        The time zone in which to interpret date/time parameters. If not specified or NULL, the location time zone for the location in the rating specification will be used.
 * @param p_round            A flag ('T' or 'F') specifying whether to round the rated values according to the rounding spec contained in the rating specification
 * @param p_trim             Parameter for cwms_ts.retrieve_ts. Specifies whether to trim missing values from the ends of the retrieved time series
 * @param p_start_inclusive  Parameter for cwms_ts.retrieve_ts. Specifies whether the time window starts on or after the specified time
 * @param p_end_inclusive    Parameter for cwms_ts.retrieve_ts. Specifies whether the time window ends on or before the specified time
 * @param p_previous         Parameter for cwms_ts.retrieve_ts. Specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     Parameter for cwms_ts.retrieve_ts. Specifies the version date of the retrieve time series
 * @param p_max_version      Parameter for cwms_ts.retrieve_ts  Specifies whether to retrieve the max or min version data of the time sereies if p_version_date is NULL
 * @param p_ts_office_id     Office owning the time series.  If not specified or NULL the session user's default office is used.
 * @param p_rating_office_id Office owning the ratings.  If not specified or NULL the session user's default office is used.
 *
 * @return The rated time series
 */
procedure reverse_rate(
   p_input_id         in varchar2,
   p_output_id        in varchar2,
   p_rating_id        in varchar2,
   p_start_time       in date,
   p_end_time         in date,
   p_rating_time      in date     default null,
   p_time_zone        in varchar2 default null,
   p_trim             in varchar2 default 'F',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_ts_office_id     in varchar2 default null,
   p_rating_office_id in varchar2 default null);
/**
 * Rounds independent values according e to the rounding specifications contained in
 * the rating specification
 *
 * @param p_independent The values to round/rounded values
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_independent(
   p_independent in out nocopy double_tab_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Rounds independent values according e to the rounding specifications contained in
 * the rating specification. Restricted to ratings with a single independent parameter
 *
 * @param p_independent The values to round/rounded values
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_independent(
   p_independent in out nocopy double_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Rounds independent time series values according e to the rounding specifications contained in
 * the rating specification. Restricted to ratings with a single independent parameter
 *
 * @param p_independent The values to round/rounded values
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_independent(
   p_independent in out nocopy tsv_array,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Rounds independent time series values according e to the rounding specifications contained in
 * the rating specification. Restricted to ratings with a single independent parameter
 *
 * @param p_independent The values to round/rounded values
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_independent(
   p_independent in out nocopy ztsv_array,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Rounds a single independent value set according e to the rounding specifications contained in
 * the rating specification. Restricted to ratings with a single independent parameter
 *
 * @param p_independent The values to round/rounded values
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_one_independent(
   p_independent in out nocopy double_tab_t,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Rounds a single independent value according e to the rounding specifications contained in
 * the rating specification. Restricted to ratings with a single independent parameter
 *
 * @param p_independent The value to round/rounded value
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_independent(
   p_independent in out nocopy binary_double,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Rounds a single independent time series value according e to the rounding specifications contained in
 * the rating specification. Restricted to ratings with a single independent parameter
 *
 * @param p_independent The value to round/rounded value
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_independent(
   p_independent in out nocopy tsv_type,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Rounds a single independent time series value according e to the rounding specifications contained in
 * the rating specification. Restricted to ratings with a single independent parameter
 *
 * @param p_independent The value to round/rounded value
 * @param p_rating_id   The rating specification
 * @param p_office_id   The office owning the rating specification
 */
procedure round_independent(
   p_independent in out nocopy ztsv_type,
   p_rating_id   in            varchar2,
   p_office_id   in            varchar2 default null);
/**
 * Gets the min and max of each independent and dependent parameter for the specified rating
 *
 * @param p_values  The min and max values for each parameter.  The outer (first) dimension
 * will be 2, with the first containing min values and the second containing
 * max values.  The inner (second) dimension will be the number of independent
 * parameters for the rating plus one.  The first value will be the extent
 * for the first independent parameter, and the last value will be the extent
 * for the dependent parameter.
 *
 * @param p_parameters The names for each parameter.  The  dimension will be the number of
 * independent parameters for the rating plus one.  The first name is for the
 * first independent parameter, and the last name is for the dependent parameter.
 *
 * @param p_units The units for each parameter.  The  dimension will be the number of
 * independent parameters for the rating plus one.  The first unit is for the
 * first independent parameter, and the last unit is for the dependent parameter.
 *
 * @param p_rating_id  The rating id of the rating specification to use
 *
 * @param p_native_units 'T' to get values in units native to rating, 'F' to get database units
 *
 * @param p_rating_time  The time to use in determining the rating from the rating spec - defaults
 * to the current time
 *
 * @param p_time_zone  The time zone to use if p_rating_time is specified. Defaults to UTC
 * @param p_office_id  The office that owns the rating. If not specified or NULL the
 * session user's default office is used
 */
procedure get_rating_extents(
   p_values       out double_tab_tab_t,
   p_parameters   out str_tab_t,
   p_units        out str_tab_t,
   p_rating_id    in  varchar2,
   p_native_units in  varchar2 default 'T',
   p_rating_time  in  date     default null,
   p_time_zone    in  varchar2 default 'UTC',
   p_office_id    in  varchar2 default null);
/**
 * Retrieves the minimum value of the "opening" parmeter for the specified gate rating.
 * Gate ratings have multiple independent parameters (pool elevation, gate opening, and possibly
 * tailwater elevation or others), with no standard order in which to specify them. Also,
 * the CWMS database is very strict in its parameter usage, requiring a parameter of
 * "Opening" to have units of length. However, for many gate ratings the "opening" is
 * specified in terms of percent of maximum opening, revolutions of a valve handle, etc...
 *
 * @param p_rating_id   The rating specification
 * @param p_unit        The unit to return the minimum "opening" value in
 * @param p_rating_time The time to use when choosing a rating from rating specification.  If not specified or NULL, the current time is used.
 * @param p_time_zone   The time zone to use in interpreting the p_rating_time parameter.  If not specified or NULL, UTC is used.
 * @param p_office_id   The office that owns the ratings.  If not specified or NULL, the session user's default office is used.
 *
 * @return the minimum value of the "opening" parmeter for the specified gate rating.
 */
function get_min_opening(
   p_rating_id   in varchar2,
   p_unit        in varchar2  default null,
   p_rating_time in  date     default null,
   p_time_zone   in  varchar2 default 'UTC',
   p_office_id   in  varchar2 default null)
   return binary_double;
/**
 * Retrieves the minimum value of the "opening" parmeter for the specified gate rating.
 * Gate ratings have multiple independent parameters (pool elevation, gate opening, and possibly
 * tailwater elevation or others), with no standard order in which to specify them. Also,
 * the CWMS database is very strict in its parameter usage, requiring a parameter of
 * "Opening" to have units of length. However, for many gate ratings the "opening" is
 * specified in terms of percent of maximum opening, revolutions of a valve handle, etc...
 *
 * @param p_rating_id   The rating specification
 * @param p_unit        The unit to return the minimum "opening" value in
 * @param p_rating_time The time to use when choosing a rating from rating specification.  If not specified or NULL, the current time is used.
 * @param p_time_zone   The time zone to use in interpreting the p_rating_time parameter.  If not specified or NULL, UTC is used.
 * @param p_office_id   The office that owns the ratings.  If not specified or NULL, the session user's default office is used.
 *
 * @return the minimum value of the "opening" parmeter for the specified gate rating. The value is wrapped in a double_tab_t for Java access through JPublisher
 */
function get_min_opening2(
   p_rating_id   in varchar2,
   p_unit        in varchar2  default null,
   p_rating_time in  date     default null,
   p_time_zone   in  varchar2 default 'UTC',
   p_office_id   in  varchar2 default null)
   return double_tab_t;
/**
 * Retrieves the database units string for a rating specification, rating template, or parameters identifier
 *
 * @param p_id The rating specification, rating template, or parameters identifier to get the database units for
 *
 * @return the database units string for the specified identifier
 */
function get_database_units(
   p_id in varchar2)
   return varchar2;
/**
 * Retrieves the number of independent parameters for a rating specification, rating template, or parameters identifier
 *
 * @param p_id The rating specification, rating template, or parameters identifier to get the number of independent parameters for
 *
 * @return the number of independent parameters for the specified identifier
 */
function get_ind_parameter_count(
   p_id in varchar2)
   return integer;
/**
 * Retrieves the independent parameters for a rating specification, rating template, or parameters identifier
 *
 * @param p_id The rating specification, rating template, or parameters identifier to get the independent parameters for
 *
 * @return the independent parameters for the specified identifier
 */
function get_ind_parameters(
   p_id in varchar2)
   return varchar2;
/**
 * Retrieves the independent parameter at a specified position for a rating specification, rating template, or parameters identifier
 *
 * @param p_id The rating specification, rating template, or parameters identifier to get the independent parameter for
 *
 * @return the independent parameter at the specified position for the identifier
 */
function get_ind_parameter(
   p_id       in varchar2,
   p_position in integer)
   return varchar2;
/**
 * Retrieves the dependent parameter for a rating specification, rating template, or parameters identifier
 *
 * @param p_id The rating specification, rating template, or parameters identifier to get the dependent parameter for
 *
 * @return the dependent parameter for the specified identifier
 */
function get_dep_parameter(
   p_id in varchar2)
   return varchar2;
/**
 * Returns a table of positions in the template parameters that are elevation parameters. Used for determining whether a rating should include vertical datum information.
 *
 * @param p_rating_template_id The rating template to analyze for elevation positions
 *
 * @return A table of positions in the template parameters that are elevation parameters. Null if no parameters are elevation parameters. A positive position indicates the independent parameter in that position is an elevation.  -1 indicates the dependent parameter is an elevation.
 */
function get_elevation_positions(
   p_rating_template_id in varchar2)
   return number_tab_t;

procedure get_spec_flags(
   p_active_flag           out varchar,
   p_auto_update_flag      out varchar,
   p_auto_activate_flag    out varchar,
   p_auto_migrate_ext_flag out varchar,
   p_rating_spec           in  varchar,
   p_office_id             in  varchar2 default null);

function is_spec_active(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2;

function is_auto_update(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2;

function is_auto_activate(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2;

function is_auto_migrate_ext(
   p_rating_spec in varchar,
   p_office_id   in varchar2 default null)
   return varchar2;

procedure set_spec_flags(
   p_rating_spec           in varchar,
   p_active_flag           in varchar,
   p_auto_update_flag      in varchar,
   p_auto_activate_flag    in varchar,
   p_auto_migrate_ext_flag in varchar,
   p_office_id             in varchar2 default null);

procedure set_spec_active(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null);

procedure set_auto_update(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null);

procedure set_auto_activate(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null);

procedure set_auto_migrate_ext(
   p_rating_spec in varchar,
   p_flag        in varchar,
   p_office_id   in varchar2 default null);

function is_rating_active(
   p_rating_spec    in varchar2,
   p_effective_date in date,
   p_time_zone      in varchar2,
   p_office_id      in varchar2 default null)
   return varchar2;

procedure set_rating_active(
   p_rating_spec    in varchar2,
   p_effective_date in date,
   p_time_zone      in varchar2,
   p_active_flag    in varchar2,
   p_office_id      in varchar2 default null);

/**
 * Retreives ratings in a number of formats for a combination time window, timezone, formats, and vertical datums
 *
 * @param p_results        The ratings, in the specified time zones, formats, and vertical datums
 * @param p_date_time      The time that the routine was called, in UTC
 * @param p_query_time     The time the routine took to retrieve the specified ratings, along with their associated specifications and templates, from the database
 * @param p_format_time    The time the routine took to format the results into the specified format, in milliseconds
 * @param p_template_count The number of rating templates retrieved by the routine
 * @param p_spec_count     The number of rating specifications retrieved by the routine
 * @param p_rating_count   The number of ratings retrieved by the routine
 * @param p_names          The names (rating specification identifers) of the ratings to retrieve.  Multiple ratings can be specified by
 *                         <or><li>specifying multiple rating spec ids separated by the <b>'|'</b> character (multiple name positions)</li>
 *                         <li>specifying a rating spec id with wildcard (<b>'*'</b> and/or <b>'?'</b> characters) (single name position)</li>
 *                         <li>a combination of 1 and 2 (multiple name positions with one or more positions matching possibly more than one rating)</li></ol>
 *                         If unspecified or NULL, a listing of rating specifications will be returned.
 * @param p_format         The format to retrieve the ratings in. Valid formats are <ul><li>TAB</li><li>CSV</li><li>XML</li><li>JSON</li></ul>
 *                         If the format is unspecified or NULL, the TAB format will be used.
 * @param p_units          The units to return the units in.  Valid units are <ul><li>NATIVE</li><li>EN</li><li>SI</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_units variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_units variable has fewer positions than the p_name variable, the last unit position is used for all
 *                         remaning names. If the units are unspecified or NULL, the NATIVE units will be used for all ratings.
 * @param p_datums         The vertical datums to return the units in.  Valid datums are <ul><li>NATIVE</li><li>NGVD29</li><li>NAVD88</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_datums variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_datums variable has fewer positions than the p_name variable, the last datum position is used for all
 *                         remaning names. If the datums are unspecified or NULL, the NATIVE veritcal datum will be used for all ratings.
 * @param p_start          The start of the time window to retrieve ratings for.  No ratings with effective dates earlier this time will be retrieved.
 *                         If unspecified or NULL, no restriction will be used for the start of the time window.
 * @param p_end            The end of the time window to retrieve ratings for.  No ratings with effective dates later this time will be retrieved.
 *                         If unspecified or NULL, no restriction will be used for the end of the time window.
 * @param p_timezone       The time zone to retrieve the ratings in. The p_start and p_end parameters - if used - are also interpreted according to this time zone.
 *                         If unspecified or NULL, the UTC time zone is used.
 * @param p_office_id      The office to retrieve ratings for.  If unspecified or NULL, ratings for all offices in the database that match the other criteria will be retrieved.
 */
procedure retrieve_ratings(
   p_results        out clob,
   p_date_time      out date,
   p_query_time     out integer,
   p_format_time    out integer,
   p_template_count out integer,
   p_spec_count     out integer,
   p_rating_count   out integer,
   p_names          in  varchar2 default null,
   p_format         in  varchar2 default null,
   p_units          in  varchar2 default null,
   p_datums         in  varchar2 default null,
   p_start          in  varchar2 default null,
   p_end            in  varchar2 default null,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retreives ratings in a number of formats for a combination time window, timezone, formats, and vertical datums
 *
 * @param p_names          The names (rating specification identifers) of the ratings to retrieve.  Multiple ratings can be specified by
 *                         <or><li>specifying multiple rating spec ids separated by the <b>'|'</b> character (multiple name positions)</li>
 *                         <li>specifying a rating spec id with wildcard (<b>'*'</b> and/or <b>'?'</b> characters) (single name position)</li>
 *                         <li>a combination of 1 and 2 (multiple name positions with one or more positions matching possibly more than one rating)</li></ol>
 *                         If unspecified or NULL, a listing of rating specifications will be returned.
 * @param p_format         The format to retrieve the ratings in. Valid formats are <ul><li>TAB</li><li>CSV</li><li>XML</li><li>JSON</li></ul>
 *                         If the format is unspecified or NULL, the TAB format will be used.
 * @param p_units          The units to return the units in.  Valid units are <ul><li>NATIVE</li><li>EN</li><li>SI</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_units variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_units variable has fewer positions than the p_name variable, the last unit position is used for all
 *                         remaning names. If the units are unspecified or NULL, the NATIVE units will be used for all ratings.
 * @param p_datums         The vertical datums to return the units in.  Valid datums are <ul><li>NATIVE</li><li>NGVD29</li><li>NAVD88</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_datums variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_datums variable has fewer positions than the p_name variable, the last datum position is used for all
 *                         remaning names. If the datums are unspecified or NULL, the NATIVE veritcal datum will be used for all ratings.
 * @param p_start          The start of the time window to retrieve ratings for.  No ratings with effective dates earlier this time will be retrieved.
 *                         If unspecified or NULL, no restriction will be used for the start of the time window.
 * @param p_end            The end of the time window to retrieve ratings for.  No ratings with effective dates later this time will be retrieved.
 *                         If unspecified or NULL, no restriction will be used for the end of the time window.
 * @param p_timezone       The time zone to retrieve the ratings in. The p_start and p_end parameters - if used - are also interpreted according to this time zone.
 *                         If unspecified or NULL, the UTC time zone is used.
 * @param p_office_id      The office to retrieve ratings for.  If unspecified or NULL, ratings for all offices in the database that match the other criteria will be retrieved.
 *
 * @return                 The ratings, in the specified time zones, formats, and vertical datums
 */

function retrieve_ratings_f(
   p_names       in  varchar2,
   p_format      in  varchar2,
   p_units       in  varchar2 default null,
   p_datums      in  varchar2 default null,
   p_start       in  varchar2 default null,
   p_end         in  varchar2 default null,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
   return clob;

end;
/

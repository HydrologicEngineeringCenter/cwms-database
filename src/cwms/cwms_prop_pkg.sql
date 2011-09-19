/* Formatted on 4/6/2009 12:40:25 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE cwms_properties
/**
 * Facilities for working with CWMS properties.
 * <p>
    * <dl>CWMS database properties are modeled after property files widely used in
    * UNIX and Java environments. Each property has the following:
    * <dd><dl>
    *   <dt>office_id</dt>
    *   <dd>The office owning the property. This is <em>somewhat</em> analogous to the host on which a property file resides</dd>
    *   <dt>prop_category</dt>
    *   <dd>The property category. This is analogous to a property file name</dd>
    *   <dt>prop_id</dt>
    *   <dd>The property identifier. This is analogous to the left of equals sign in a property file</dd>
    *   <dt>prop_value</dt>
    *   <dd>The property value. This is analogous to the right side of the equals sign in a properties file</dd>
    *   <dt>prop_comment</dt>
    *   <dd>A comment about the property. This is <em>somewhat</em> analogous to a comment line above the property in a property file</dd>
    * </dl></dd></dl>
 *
 * @since CWMS 2.0
 *
 * @author Mike Perryman
 */
AS
   /**
    * Retrieve properties that match specified parameters
    *
    * @see cwms_util.parse_string_recordset
    *
    * @param p_cwms_cat A cursor containing properties that match any element of p_property_info.
    * The cursor contains the following columns, sorted by the first three:
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
    *     <td class="descr">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">prop_category</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">prop_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">prop_value</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">prop_comment</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property comment</td>
    *   </tr>
    *   <tr>
    * </table>
    *
    * @param p_property_info A string that holds values to match. This value is parsed
    * by <a href="pkg_cwms_util.html#function parse_string_recordset(p_string in varchar2)">cwms_util.parse_string_recordset</a>
    * so the value should be constructed accordingly.
    * The fields of each element of this parameter can have sql-wildcard characters '%' and '_', using '\' for
    * the escape character if necessary.  Matching is performed using the LIKE operator
    * so zero or more properties may be returned.
    */
	PROCEDURE get_properties (p_cwms_cat		  OUT sys_refcursor,
									  p_property_info IN 	VARCHAR2
									 );
   /**
    * Retrieve properties that match specified parameters
    *
    * @see cwms_util.parse_clob_recordset
    *
    * @param p_cwms_cat A cursor containing properties that match any element of p_property_info.
    * The cursor contains the following columns, sorted by the first three:
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
    *     <td class="descr">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">prop_category</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">prop_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">prop_value</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">prop_comment</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property comment</td>
    *   </tr>
    *   <tr>
    * </table>
    *
    * @param p_property_info A CLOB object that holds values to match. This value is parsed
    * by <a href="pkg_cwms_util.html#function parse_clob_recordset(p_clob in clob)">cwms_util.parse_clob_recordset</a>
    * so the value should be constructed accordingly.
    * The fields of each element of this parameter can have sql-wildcard characters '%' and '_', using '\' for
    * the escape character if necessary.  Matching is performed using the LIKE operator
    * so zero or more properties may be returned.
    */
	PROCEDURE get_properties (p_cwms_cat		  OUT sys_refcursor,
									  p_property_info IN 	CLOB
									 );
   /**
    * Retrieve properties that match specified parameters
    *
    * @param p_cwms_cat A cursor containing properties that match any element of p_property_info.
    * The cursor contains the following columns, sorted by the first three:
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
    *     <td class="descr">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">prop_category</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">prop_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">prop_value</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">prop_comment</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property comment</td>
    *   </tr>
    *   <tr>
    * </table>
    *
    * @param p_property_info A property_info_tab_t object that holds values to match.
    * The fields of each element of this parameter can have sql-wildcard characters '%' and '_', using '\' for
    * the escape character if necessary.  Matching is performed using the LIKE operator
    * so zero or more properties may be returned.
    */
	PROCEDURE get_properties (p_cwms_cat		  OUT sys_refcursor,
									  p_property_info IN 	property_info_tab_t
									 );
   /**
    * Retrieve properties that match specified parameters
    *
    * @param p_cwms_cat A cursor containing the matching properties. The cursor contains
    * the following columns, sorted by the first three:
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
    *     <td class="descr">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">prop_category</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">prop_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">prop_value</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">prop_comment</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property comment</td>
    *   </tr>
    *   <tr>
    * </table>
    *
    * @param p_property_info A property_info_t object that holds values to match.
    * The fields of this parameter can have sql-wildcard characters '%' and '_', using '\' for
    * the escape character if necessary.  Matching is performed using the LIKE operator
    * so zero or more properties may be returned.
    */
   PROCEDURE get_properties (p_cwms_cat        OUT sys_refcursor,
                             p_property_info IN    property_info_t
                            );
   /**
    * Retrieve a property value
    *
    * @param p_category  The property category
    * @param p_id        The property identifier
    * @param p_default   The value to return if the property does't exist
    * @param p_office_id The office that owns the property
    *
    * @return The property value
    */
	FUNCTION get_property (p_category	  IN VARCHAR2,
								  p_id			  IN VARCHAR2,
								  p_default 	  IN VARCHAR2 DEFAULT NULL ,
								  p_office_id	  IN VARCHAR2 DEFAULT NULL
								 )
		RETURN VARCHAR2;
   /**
    * Retrieve a property value and comment
    *
    * @param p_value     The property value
    * @param p_comment   The property comment
    * @param p_category  The property category
    * @param p_id        The property identifier
    * @param p_default   The value to return if the property does't exist
    * @param p_office_id The office that owns the property
    *
    */
	PROCEDURE get_property (p_value				OUT VARCHAR2,
									p_comment			OUT VARCHAR2,
									p_category		IN 	 VARCHAR2,
									p_id				IN 	 VARCHAR2,
									p_default		IN 	 VARCHAR2 DEFAULT NULL ,
									p_office_id 	IN 	 VARCHAR2 DEFAULT NULL
								  );
   /**
    * Retrieve properties that match specified parameters, in XML format
    *
    * @see cwms_util.parse_string_recordset
    *
    * @param p_property_info A string that holds values to match. This value is parsed
    * by <a href="pkg_cwms_util.html#function parse_string_recordset(p_string in varchar2)">cwms_util.parse_string_recordset</a>
    * so the value should be constructed accordingly.
    * The fields of each element of this parameter can have sql-wildcard characters '%' and '_', using '\' for
    * the escape character if necessary.  Matching is performed using the LIKE operator
    * so zero or more properties may be returned.
    *
    * @return An XML instance that contains the matching properties
    */
	FUNCTION get_properties_xml (p_property_info IN VARCHAR2)
		RETURN CLOB;
   /**
    * Retrieve properties that match specified parameters, in XML format
    *
    * @see cwms_util.parse_clob_recordset
    *
    * @param p_property_info A CLOB object that holds values to match. This value is parsed
    * by <a href="pkg_cwms_util.html#function parse_clob_recordset(p_clob in clob)">cwms_util.parse_clob_recordset</a>
    * so the value should be constructed accordingly.
    * The fields of each element of this parameter can have sql-wildcard characters '%' and '_', using '\' for
    * the escape character if necessary.  Matching is performed using the LIKE operator
    * so zero or more properties may be returned.
    *
    * @return An XML instance that contains the matching properties
    */
	FUNCTION get_properties_xml (p_property_info IN CLOB)
		RETURN CLOB;
   /**
    * Retrieve properties that match specified parameters, in XML format
    *
    * @param p_property_info A property_info_tab_t object that holds values to match.
    * The fields of each element of this parameter can have sql-wildcard characters '%' and '_', using '\' for
    * the escape character if necessary.  Matching is performed using the LIKE operator
    * so zero or more properties may be returned.
    *
    * @return An XML instance that contains the matching properties
    */
	FUNCTION get_properties_xml (p_property_info property_info_tab_t)
		RETURN CLOB;
   /**
    * Set (insert or update) properties
    *
    * @see cwms_util.parse_string_recordset
    *
    * @param p_property_info The properties to set. This value is parsed
    * by <a href="pkg_cwms_util.html#function parse_string_recordset(p_string in varchar2)">cwms_util.parse_string_recordset</a>
    * so the value should be constructed accordingly.
    *
    * @return The number of properties successfully inserted or updated.
    */
	FUNCTION set_properties (p_property_info IN VARCHAR2)
		RETURN BINARY_INTEGER;
   /**
    * Set (insert or update) properties
    *
    * @see cwms_util.parse_clob_recordset
    *
    * @param p_property_info The properties to set. This value is parsed
    * by <a href="pkg_cwms_util.html#function parse_clob_recordset(p_clob in clob)">cwms_util.parse_clob_recordset</a>
    * so the value should be constructed accordingly.
    *
    * @return The number of properties successfully inserted or updated.
    */
	FUNCTION set_properties (p_property_info IN CLOB)
		RETURN BINARY_INTEGER;
   /**
    * Set (insert or update) properties
    *
    * @see cwms_util.parse_clob_recordset
    *
    * @param p_property_info The properties to set.
    *
    * @return The number of properties successfully inserted or updated.
    */
	FUNCTION set_properties (p_property_info IN property_info2_tab_t)
		RETURN BINARY_INTEGER;
   /**
    * Sets (inserts or updates) a property
    *
    * @param p_category  The property category
    * @param p_id        The property identifier
    * @param p_value     The property value
    * @param p_comment   The property_comment
    * @param p_office_id The office that owns the property
    */
	PROCEDURE set_property (p_category		IN VARCHAR2,
									p_id				IN VARCHAR2,
									p_value			IN VARCHAR2,
									p_comment		IN VARCHAR2,
									p_office_id 	IN VARCHAR2 DEFAULT NULL
								  );
   /**
    * Deletes a property
    *
    * @param p_category  The property category
    * @param p_id        The property identifier
    * @param p_office_id The office that owns the property
    */
   PROCEDURE delete_property (p_category     IN VARCHAR2,
                              p_id           IN VARCHAR2,
                              p_office_id    IN VARCHAR2 DEFAULT NULL
                             );
   /**
    * Deletes one or more properties
    *
    * @param p_property_info The properties to delete.
    */
   PROCEDURE delete_properties (p_property_info IN property_info_tab_t);
END cwms_properties;
/

show errors;
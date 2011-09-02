/* Formatted on 4/6/2009 12:40:25 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE cwms_properties
/**
 * Facilities for working with CWMS properties
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
    * <table style="border-collapse:collapse; border:1px solid black;">
    *   <tr>
    *     <th style="border:1px solid black;">Column No.</th>
    *     <th style="border:1px solid black;">Column Name</th>
    *     <th style="border:1px solid black;">Data Type</th>
    *     <th style="border:1px solid black;">Contents</th>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">1</td>
    *     <td style="border:1px solid black;">office_id</td>
    *     <td style="border:1px solid black;">varchar2(16)</td>
    *     <td style="border:1px solid black;">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">2</td>
    *     <td style="border:1px solid black;">prop_category</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property category</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">3</td>
    *     <td style="border:1px solid black;">prop_id</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">4</td>
    *     <td style="border:1px solid black;">prop_value</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property value</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">5</td>
    *     <td style="border:1px solid black;">prop_comment</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property comment</td>
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
    * <table style="border-collapse:collapse; border:1px solid black;">
    *   <tr>
    *     <th style="border:1px solid black;">Column No.</th>
    *     <th style="border:1px solid black;">Column Name</th>
    *     <th style="border:1px solid black;">Data Type</th>
    *     <th style="border:1px solid black;">Contents</th>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">1</td>
    *     <td style="border:1px solid black;">office_id</td>
    *     <td style="border:1px solid black;">varchar2(16)</td>
    *     <td style="border:1px solid black;">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">2</td>
    *     <td style="border:1px solid black;">prop_category</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property category</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">3</td>
    *     <td style="border:1px solid black;">prop_id</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">4</td>
    *     <td style="border:1px solid black;">prop_value</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property value</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">5</td>
    *     <td style="border:1px solid black;">prop_comment</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property comment</td>
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
    * <table style="border-collapse:collapse; border:1px solid black;">
    *   <tr>
    *     <th style="border:1px solid black;">Column No.</th>
    *     <th style="border:1px solid black;">Column Name</th>
    *     <th style="border:1px solid black;">Data Type</th>
    *     <th style="border:1px solid black;">Contents</th>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">1</td>
    *     <td style="border:1px solid black;">office_id</td>
    *     <td style="border:1px solid black;">varchar2(16)</td>
    *     <td style="border:1px solid black;">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">2</td>
    *     <td style="border:1px solid black;">prop_category</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property category</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">3</td>
    *     <td style="border:1px solid black;">prop_id</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">4</td>
    *     <td style="border:1px solid black;">prop_value</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property value</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">5</td>
    *     <td style="border:1px solid black;">prop_comment</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property comment</td>
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
    * <table style="border-collapse:collapse; border:1px solid black;">
    *   <tr>
    *     <th style="border:1px solid black;">Column No.</th>
    *     <th style="border:1px solid black;">Column Name</th>
    *     <th style="border:1px solid black;">Data Type</th>
    *     <th style="border:1px solid black;">Contents</th>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">1</td>
    *     <td style="border:1px solid black;">office_id</td>
    *     <td style="border:1px solid black;">varchar2(16)</td>
    *     <td style="border:1px solid black;">The office that owns the property</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">2</td>
    *     <td style="border:1px solid black;">prop_category</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property category</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">3</td>
    *     <td style="border:1px solid black;">prop_id</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property identifier</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">4</td>
    *     <td style="border:1px solid black;">prop_value</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property value</td>
    *   </tr>
    *   <tr>
    *     <td style="border:1px solid black;">5</td>
    *     <td style="border:1px solid black;">prop_comment</td>
    *     <td style="border:1px solid black;">varchar2(256)</td>
    *     <td style="border:1px solid black;">The property comment</td>
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
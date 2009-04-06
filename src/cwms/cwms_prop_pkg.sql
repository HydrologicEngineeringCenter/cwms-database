/* Formatted on 4/6/2009 12:40:25 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE cwms_properties
AS
	TYPE property_info_t IS RECORD (
										office_id	VARCHAR2 (16),
										category 	VARCHAR2 (256),
										id 			VARCHAR2 (256)
									);

	TYPE property_info_tab_t IS TABLE OF property_info_t;

	TYPE property_info2_t IS RECORD (
										 office_id	 VARCHAR2 (16),
										 category	 VARCHAR2 (256),
										 id			 VARCHAR2 (256),
										 VALUE		 VARCHAR2 (256),
										 comment 	 VARCHAR2 (256)
									 );

	TYPE property_info2_tab_t IS TABLE OF property_info2_t;

	-------------------------------------------------------------------------------
	-- procedure get_properties(...)
	--
	--
	PROCEDURE get_properties (p_cwms_cat		  OUT sys_refcursor,
									  p_property_info IN 	VARCHAR2
									 );

	PROCEDURE get_properties (p_cwms_cat		  OUT sys_refcursor,
									  p_property_info IN 	CLOB
									 );

	PROCEDURE get_properties (p_cwms_cat		  OUT sys_refcursor,
									  p_property_info IN 	property_info_tab_t
									 );

	-------------------------------------------------------------------------------
	-- function get_property(...)
	--
	--

	FUNCTION get_property (p_category	  IN VARCHAR2,
								  p_id			  IN VARCHAR2,
								  p_default 	  IN VARCHAR2 DEFAULT NULL ,
								  p_office_id	  IN VARCHAR2 DEFAULT NULL
								 )
		RETURN VARCHAR2;

	PROCEDURE get_property (p_value				OUT VARCHAR2,
									p_comment			OUT VARCHAR2,
									p_category		IN 	 VARCHAR2,
									p_id				IN 	 VARCHAR2,
									p_default		IN 	 VARCHAR2 DEFAULT NULL ,
									p_office_id 	IN 	 VARCHAR2 DEFAULT NULL
								  );

	-------------------------------------------------------------------------------
	-- function get_properties_xml(...)
	--
	--
	FUNCTION get_properties_xml (p_property_info IN VARCHAR2)
		RETURN CLOB;

	FUNCTION get_properties_xml (p_property_info IN CLOB)
		RETURN CLOB;

	FUNCTION get_properties_xml (p_property_info property_info_tab_t)
		RETURN CLOB;

	-------------------------------------------------------------------------------
	-- function set_properties(...)
	--
	-- returns the number successfully inserted/updated
	--
	FUNCTION set_properties (p_property_info IN VARCHAR2)
		RETURN BINARY_INTEGER;

	FUNCTION set_properties (p_property_info IN CLOB)
		RETURN BINARY_INTEGER;

	FUNCTION set_properties (p_property_info IN property_info2_tab_t)
		RETURN BINARY_INTEGER;

	-------------------------------------------------------------------------------
	-- procedure set_property(...)
	--
	--
	PROCEDURE set_property (p_category		IN VARCHAR2,
									p_id				IN VARCHAR2,
									p_value			IN VARCHAR2,
									p_comment		IN VARCHAR2,
									p_office_id 	IN VARCHAR2 DEFAULT NULL
								  );
END cwms_properties;
/

show errors;
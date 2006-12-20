CREATE OR REPLACE PACKAGE cwms_properties AUTHID CURRENT_USER
AS
   
   type property_info_t is record(
      office_id varchar2(16), 
      category  varchar2(256),
      id        varchar2(256));
      
   type property_info_tab_t is table of property_info_t;      
      
   type property_info2_t is record(
      office_id varchar2(16), 
      category  varchar2(256),
      id        varchar2(256),
      value     varchar2(256),
      comment   varchar2(256));

   type property_info2_tab_t is table of property_info2_t;
         
-------------------------------------------------------------------------------
-- procedure get_properties(...)
--
--
   PROCEDURE get_properties (
      p_cwms_cat      OUT sys_refcursor,
      p_property_info IN  VARCHAR2);
   
   PROCEDURE get_properties (
      p_cwms_cat      OUT sys_refcursor,
      p_property_info IN  CLOB);
   
   PROCEDURE get_properties (
      p_cwms_cat      OUT sys_refcursor,
      p_property_info IN  property_info_tab_t);
   
-------------------------------------------------------------------------------
-- function get_property(...)
--
--
   FUNCTION get_property (
      p_office_id in varchar2,
      p_category  in varchar2,
      p_id        in varchar2)
      return varchar2;
   
-------------------------------------------------------------------------------
-- function get_properties_xml(...)
--
--
   FUNCTION get_properties_xml (
      p_property_info IN VARCHAR2)
      return CLOB;
      
   FUNCTION get_properties_xml (
      p_property_info IN CLOB)
      return CLOB;

   FUNCTION get_properties_xml (
      p_property_info property_info_tab_t)
      return CLOB;

-------------------------------------------------------------------------------
-- function set_properties(...)
--
-- returns the number successfully inserted/updated
--
   FUNCTION set_properties (p_property_info IN VARCHAR2)
            return binary_integer;
  
   FUNCTION set_properties (p_property_info IN CLOB)
            return binary_integer;
  
   FUNCTION set_properties (p_property_info IN  property_info2_tab_t)
            return binary_integer;
   
-------------------------------------------------------------------------------
-- procedure set_property(...)
--
--
   PROCEDURE set_property (
      p_office_id in varchar2,
      p_category  in varchar2,
      p_id        in varchar2,
      p_value     in varchar2,
      p_comment   in varchar2);
   
END cwms_properties;
/
show errors;
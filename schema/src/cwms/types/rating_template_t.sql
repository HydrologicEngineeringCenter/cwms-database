create type rating_template_t
/**
 * Holds information about a rating template.  Rating templates specify "classes"
 * of ratings by specifying the parameters and lookup behaviors. Templates are
 * then incorporated into rating specifications which add additional information
 * such as specific locations.
 *
 * @see type rating_ind_par_spec_tab_t
 * @see type rating_template_tab_t
 *
 * @member office_id         The office that owns the rating template
 * @member parameters_id     The parameters used by the rating template. Multiple independent parameters are separated by <a href="pkg_cwms_rating.html#separator3">','</a>, the dependent parameter is separated by <a href="pkg_cwms_rating.html#separator2">';'</a>
 * @member version           The version for this parameter. Used to differentiate this template from others with the same parameters
 * @member ind_parameters    The independent parameter(s) specification for this rating template
 * @member dep_parameter_id  The dependent parameter for this rating template
 * @member description       A description of the rating template
 */
as object(
   office_id         varchar2(16),
   parameters_id     varchar2(256),
   version           varchar2(32),
   ind_parameters    rating_ind_par_spec_tab_t,
   dep_parameter_id  varchar2(49),
   description       varchar2(256),
   /**
    * Constructs a rating_template_t object from unique parameters. The parameters_id field is generated from the p_ind_parameters and p_dep_parmeter_id arguments.
    *
    * @param p_office_id         The office that owns the rating template
    * @param p_version           The version for this parameter. Used to differentiate this template from others with the same parameters
    * @param p_ind_parameters    The independent parameter(s) specification for this rating template
    * @param p_dep_parameter_id  The dependent parameter for this rating template
    * @param p_description       A description of the rating template
    */
   constructor function rating_template_t(
      p_office_id         in varchar2,
      p_version           in varchar2,
      p_ind_parameters    in rating_ind_par_spec_tab_t,
      p_dep_parameter_id  in varchar2,
      p_description       in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_template_code the primary key of the table record
    */
   constructor function rating_template_t(
      p_template_code in number)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_office_id     The office that owns the rating template
    * @param p_parameters_id The parameters used by the rating template. Multiple independent parameters are separated by <a href="pkg_cwms_rating.html#separator3">','</a>, the dependent parameter is separated by <a href="pkg_cwms_rating.html#separator2">';'</a>
    * @param p_version       The version for this parameter. Used to differentiate this template from others with the same parameters
    */
   constructor function rating_template_t(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_office_id   The office that owns the rating template
    * @param p_template_id The template identifier.  The parameters_id, comprised of the parameters_id and verssion, separated by <a href="pkg_cwms_rating.html#separator1">'.'</a>
    */
   constructor function rating_template_t(
      p_office_id   in varchar2,
      p_template_id in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from an XML instance. The XML instance
    * must conform to the <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Rating XML Schema</a>. The rating template
    * portion is <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-template">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_template_t(
      p_xml in xmltype)
   return self as result,      
   -- not documented
   member procedure init(
      p_template_code in number),
   -- not documented
   member procedure init(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2),
   -- not documented
   member procedure validate_obj,
   -- not documented
   member function get_office_code
   return number,
   -- not documented
   member function get_dep_parameter_code
   return number,
   /**
    * Stores the rating template to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating template already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating template already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Retrieves the rating template as an XML instance in an XMLTYPE object
    *
    * @return the rating template as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,      
   /**
    * Retrieves the rating template as an XML instance in a CLOB object
    *
    * @return the rating template as an XML instance in a CLOB object
    */
   member function to_clob
   return clob,      
   -- not documented
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_id     in varchar2 default null)
   return number result_cache,      
   -- not documented
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_code   in number)
   return number result_cache,      
   -- not documented
   static function get_template_code(
      p_template_id in varchar2,
      p_office_code in number)
   return number result_cache      
);
/


create or replace public synonym cwms_t_rating_template for rating_template_t;


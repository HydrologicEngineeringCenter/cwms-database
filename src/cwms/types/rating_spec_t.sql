create or replace type rating_spec_t
/**
 * Holds a rating specification. A rating specification is identified by a location,
 * a rating template, and a version. It also contains information about
 * <ul>
 *   <li>rating behaviors for when the date of a rated value falls before, within, or after the range of rating effective dates</li>
 *   <li>flags for whether the the specification is active and for automated updating procedures</li>
 *   <li>how values for independent and dependent parameters are rounded for public display</li>
 * </ul>
 *
 * @see cwms_lookup.method_null
 * @see cwms_lookup.method_error
 * @see cwms_lookup.method_linear
 * @see cwms_lookup.method_previous
 * @see cwms_lookup.method_next
 * @see cwms_lookup.method_nearest
 * @see cwms_lookup.method_lower
 * @see cwms_lookup.method_higher
 * @see cwms_lookup.method_closest
 * @see type cwms_rating_spec_tab_t
 *
 * @member office_id                    The office that owns the rating spec
 * @member location_id                  The location for the rating spec
 * @member template_id                  The rating template for the rating spec
 * @member version                      The version of the rating spec
 * @member source_agency_id             The agency that provides ratings for the rating spec
 * @member in_range_rating_method       The rating behavior when the effective dates of the ratings encompass the date of a value being rated
 * @member out_range_low_rating_method  The rating behavior when the earliest of effective dates of the ratings is later than the date of a value being rated
 * @member out_range_high_rating_method The rating behavior when the latest of effective dates of the ratings is earlier than the date of a value being rated
 * @member active_flag                  A flag ('T' or 'F') specifying whether this rating spec is active
 * @member auto_update_flag             A flag ('T' or 'F') specifying whether new ratings with this rating spec should automatically be loaded into the database
 * @member auto_activate_flag           A flag ('T' or 'F') specifying whether newly-loaded ratings with this rating spec should automatically be marked as active
 * @member auto_migrate_ext_flag        A flag ('T' or 'F') specifying whether newly-loaded ratings with this rating spec should automatically have previously-defined rating extensions applied
 * @member ind_rounding_specs           USGS-style rounding specifications for each of the independent parameters. Used for public display of data rated by ratings under this rating spec.  Multiple rounding specs are separated by <a href="pkg_cwms_rating.html#separator3">','</a>
 * @member dep_rounding_spec            USGS-style rounding specifications for each of the dependent parameter. Used for public display of data rated by ratings under this rating spec.
 * @member description                  A description of this rating spec
 */
as object(
   office_id                    varchar2(16),
   location_id                  varchar2(57),
   template_id                  varchar2(289), -- template.parameters_id + template.version
   version                      varchar2(32),
   source_agency_id             varchar2(32),
   in_range_rating_method       varchar2(32),
   out_range_low_rating_method  varchar2(32),
   out_range_high_rating_method varchar2(32),
   active_flag                  varchar2(1),
   auto_update_flag             varchar2(1),
   auto_activate_flag           varchar2(1),
   auto_migrate_ext_flag        varchar2(1),
   ind_rounding_specs           str_tab_t,
   dep_rounding_spec            varchar2(10),
   description                  varchar2(256),
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_rating_spec_code The primary key for the table record
    */
   constructor function rating_spec_t(
      p_rating_spec_code in number)
   return self as result,
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_location_id The location for the rating spec
    * @param p_template_id The rating template for the rating spec
    * @param p_version     The version of the rating spec
    * @param p_office_id   The office that owns the rating spec. If NULL or not specified, the session user's default office will be used.
    */
   constructor function rating_spec_t(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return self as result,      
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_rating_id The rating identifier. A rating identifier is comprised of the location_id, template_id, and version, separated by <a href="pkg_cwms_rating.html#separator1">'.'</a>
    * @param p_office_id The office that owns the rating spec. If NULL or not specified, the session user's default office will be used.
    */
   constructor function rating_spec_t(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_spec_t object from an XML instance. The XML instance
    * must conform to the <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Rating XML Schema</a>. The rating spec
    * portion is <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-spec">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_spec_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure init(
      p_rating_spec_code in number),
   -- not documented
   member procedure init(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null),
   -- not documented
   member procedure validate_obj,
   -- not documented
   member function get_location_code
   return number,
   -- not documented
   member function get_template_code
   return number,
   -- not documented
   member function get_source_agency_code
   return number,
   -- not documented
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
   -- not documented
   member function get_in_range_rating_code
   return number,     
   -- not documented
   member function get_out_range_low_rating_code
   return number,     
   -- not documented
   member function get_out_range_high_rating_code
   return number,
   /**
    * Stores the rating specification to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating specification already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating specification already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),     
   /**
    * Retrieves the rating specification as an XML instance in a CLOB object
    *
    * @return the rating specification as an XML instance in a CLOB object
    */
   member function to_clob
   return clob,
   /**
    * Retrieves the rating specification as an XML instance in an XMLTYPE object
    *
    * @return the rating specification as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,
   -- not documented
   static function get_rating_spec_code(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return number,      
   -- not documented
   static function get_rating_spec_code(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return number
);
/


create or replace public synonym cwms_t_rating_spec for rating_spec_t;


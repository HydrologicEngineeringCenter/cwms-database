create type rating_t
/**
 * Holds a rating
 *
 * @see type rating_ind_parameter_t
 * @see type rating_spec_t
 * @see type stream_rating_t
 * @see type rating_tab_t
 *
 * @member office_id       The office that owns the rating
 * @member rating_spec_id  The rating specification identifier
 * @member effective_date  The earliest date/time that the rating is to be in effect
 * @member create_date     The date/time that the rating was loaded into the datbase
 * @member active_flag     A flag ('T' or 'F') specifying whether the rating is active
 * @member formula         The formula (algebraic or RPN) for the rating if the rating is formula-based
 * @member connections     The connection strings for the source ratings if the rating is a virtual rating
 * @member native_units    The native units for the rating
 * @member description     The description of the rating
 * @member rating_info     The rating lookup values if the rating is lookup-based
 * @member current_units   A flag ('D' or 'N') specfying whether the lookup values are currently in database storage ('D') or native ('N') units
 * @member current_time    A flag ('D' or 'L') specifying whether the times are currently in database ('D') (=UTC) or rating location local ('L') time zone
 * @member formula_tokens  A collection of formula tokens if the rating is formula-based
 * @member source_ratings  An ordered collection of source rating specifications if the rating is a virtual rating
 * @member connections_map A map of data inputs to ratings inputs if the rating is a virtual rating
 */
as object (
   office_id       varchar2(16),
   rating_spec_id  varchar2(372),
   effective_date  date,
   create_date     date,
   active_flag     varchar2(1),
   formula         varchar2(1000),
   connections     varchar2(80),
   native_units    varchar2(256),
   description     varchar2(256),
   rating_info     rating_ind_parameter_t,
   current_units   varchar2(1), -- 'D' = database, 'N' = native, other = don't know
   current_time    varchar2(2), -- 'D' = database, 'L' = native, other = don't know
   formula_tokens  str_tab_t,
   source_ratings  str_tab_t,
   connections_map rating_conn_map_tab_t,
   /**
    * Construct a rating_t object for a simple concrete rating.
    *
    * @param p_rating_spec_id  The rating specification identifier
    * @param p_native_units    The native units for the rating
    * @param p_effective_date  The earliest date/time that the rating is to be in effect
    * @param p_active_flag     A flag ('T' or 'F') specifying whether the rating is active
    * @param p_formula         The formula (algebraic or RPN) for the rating if the rating is formula-based
    * @param p_description     The description of the rating
    * @param p_rating_info     The rating lookup values if the rating is lookup-based
    * @param p_office_id       The office that owns the rating
    */
   constructor function rating_t(
      p_rating_spec_id  varchar2,
      p_native_units    varchar2,
      p_effective_date  date,
      p_active_flag     varchar2,
      p_formula         varchar2,
      p_rating_info     rating_ind_parameter_t,
      p_description     varchar2,
      p_office_id       varchar2 default null)
      return self as result,
   /**
    * Construct a rating_t object from data in the database.
    *
    * @param p_rating_code The primary key of the AT_RATING table
    */
   constructor function rating_t(
      p_rating_code in number)
   return self as result,
   /**
    * Construct a rating_t object from data in the database.
    *
    * @param p_rating_spec_id The rating specification of the rating to construct
    * @param p_effective_date The effective date
    * @param p_match_date     A flag ('T' or 'F') specifying whether the p_effective_date parameter is to be matched exactly.  If 'F', the latest effective date on or before p_effective_date will be used.
    * @param p_time_zone      The time zone for p_effective_date.  If NULL, the local time zone of the rating's location will be used.
    * @param p_office_id      The office owning the rating.  If NULL, the session user's default office will be used
    */
   constructor function rating_t(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_t(
      p_xml in xmltype)
   return self as result,
   /**
    * Construction one rating_t object from another.
    *
    * @param p_other another object of type rating_t or one of its subclasses
    */
   constructor function rating_t(
      p_other in rating_t)
   return self as result,
   -- not documented
   member procedure init(
      p_rating_code in number),
   -- not documented
   member procedure init(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null),
   -- not documented
   member function rating_expr_ind_param_count(
      p_text in varchar2)
      return pls_integer,
   -- not documented
   member procedure parse_source_rating(
      self           in  rating_t, -- to keep from implicity being defined as OUT type
      p_is_rating    out boolean,
      p_rating_part  out varchar2,
      p_units_part   out varchar2,
      p_text         in  varchar2),
   -- not documented
   member procedure parse_connection_part(
      self        in  rating_t, -- to keep from implicity being defined as OUT type
      p_rating    out pls_integer,
      p_ind_param out pls_integer,
      p_conn_part in  varchar2),
   -- not documented
   member procedure validate_obj,
   /**
    * Sets all rating values of this rating to database storage units, converting if necessary
    */
   member procedure convert_to_database_units,
   /**
    * Sets all rating values of this rating to native units, converting if necessary
    */
   member procedure convert_to_native_units,
   /**
    * Sets the times of this rating to UTC, converting if necessary
    */
   member procedure convert_to_database_time,
   /**
    * Sets the times of this rating to the local time of the rating's location, converting if necessary
    */
   member procedure convert_to_local_time,
   -- not documented
   member procedure store(
      p_rating_code    out number,
      p_fail_if_exists in  varchar2),
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   member function to_clob
   return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in binary_double)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in tsv_array)
   return tsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in tsv_type)
   return tsv_type,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type,
   /*
    * not documented, called only from CWMS_RATING.RATE
    * only for virtual ratings
    *
    */
   member function rate(
      p_values      in  double_tab_tab_t,
      p_units       in  str_tab_t,
      p_round       in  varchar2,
      p_value_times in  date_table_type,
      p_rating_time in  date,
      p_time_zone   in  varchar2)
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type,
   /*
    * not documented, called only from CWMS_RATING.RATE
    * only for virtual ratings
    *
    */
   member function reverse_rate(
      p_values      in  double_tab_t,
      p_units       in  str_tab_t,
      p_round       in  varchar2,
      p_value_times in  date_table_type,
      p_rating_time in  date,
      p_time_zone   in  varchar2)
   return double_tab_t,
   -- not documented
   member function get_date(
      p_timestr in varchar2)
   return date,
   /**
    * Returns the number of independent paramters for this rating
    *
    * @return the number of independent paramters for this rating
    */
   member function get_ind_parameter_count
   return pls_integer,
   /**
    * Returns the independent parameters for this rating
    *
    * @return the independent parameters for this rating
    */
   member function get_ind_parameters
   return str_tab_t,
   /**
    * Returns the independent paramter at the specified position
    *
    * @param p_position The position (starting at 1) of the independent paramter to retrieve
    *
    * @return the independent paramter at the specified position
    */
   member function get_ind_parameter(
      p_position in integer)
   return varchar2,
   /**
    * Returns the dependent parameter for this rating
    *
    * @return the dependent parameter for this rating
    */
   member function get_dep_parameter
   return varchar2,
   -- not documented
    member function reverse
    return rating_t,
   -- not documented
   static function get_rating_code(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return number

) not final;
/


create or replace public synonym cwms_t_rating for rating_t;


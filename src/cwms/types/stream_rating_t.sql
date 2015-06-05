create type stream_rating_t
/**
 * Holds a USGS-style stream rating with shifts and offsets
 *
 * @see type rating_t
 *
 * @member offsets The logarithmic stage interpolation offsets, if any to use with the rating
 * @member shifts  The stage shifts, if any, to use with the rating
 */
under rating_t (
-- office_id      varchar2(16),
-- rating_spec_id varchar2(372),
-- effective_date date,
-- create_date    date,
-- active_flag    varchar2(1),
-- formula        varchar2(1000),
-- native_units   varchar2(256),
-- description    varchar2(256),
-- rating_info    rating_ind_parameter_t,
-- current_units  varchar2(1), -- 'D' = database, 'N' = native, other = don't know
-- current_time   varchar2(2), -- 'D' = database, 'L' = native, other = don't know
   offsets        rating_t,
   shifts         rating_tab_t,
   
   /**
    * Construct a stream_rating_t object from data in the database.
    *
    * @param p_rating_code The primary key of the AT_RATING table
    */
   constructor function stream_rating_t(
      p_rating_code in number)
   return self as result,
   /**
    * Construct a stream_rating_t object from data in the database.
    *
    * @param p_rating_spec_id The rating specification of the rating to construct
    * @param p_effective_date The effective date
    * @param p_match_date     A flag ('T' or 'F') specifying whether the p_effective_date parameter is to be matched exactly.  If 'F', the latest effective date on or before p_effective_date will be used.
    * @param p_time_zone      The time zone for p_effective_date.  If NULL, the local time zone of the rating's location will be used.
    * @param p_office_id      The office owning the rating.  If NULL, the session user's default office will be used
    */
   constructor function stream_rating_t(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_usgs-stream-rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function stream_rating_t(
      p_xml in xmltype)
   return self as result,
   /**
    * Construction one stream_rating_t object from another.
    *
    * @param p_other another object of type stream_rating_t or one of its subclasses
    */   
   constructor function stream_rating_t(
      p_other in stream_rating_t)
   return self as result,
   -- not documented
   overriding member procedure init(
      p_rating_code in number),
   -- not documented
   member procedure init(
      p_other in stream_rating_t),
   -- not documented
   overriding member procedure validate_obj,
   /**
    * Sets all rating values of this rating to database storage units, converting if necessary
    */
   overriding member procedure convert_to_database_units,
   /**
    * Sets all rating values of this rating to native units, converting if necessary
    */
   overriding member procedure convert_to_native_units,
   /**
    * Sets the times of this rating to UTC, converting if necessary
    */
   overriding member procedure convert_to_database_time,
   /**
    * Sets the times of this rating to the local time of the rating's location, converting if necessary
    */
   overriding member procedure convert_to_local_time,
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   overriding member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @param p_replace A flag('T' or 'F') that specifies whether any existing rating
    *        should be completely replaced even if the base ratings are the same.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Flag</th>
    *     <th class="descr">Behavior</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">'T'</td>
    *     <td class="descr">The existing rating will be completely replaced with this one, even if the only difference is a new shift</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'F'</td>
    *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
    *   </tr>
    * </table>
    *  
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2,
      p_replace        in varchar2),
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   overriding member function to_clob(
      self         in out nocopy stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   overriding member function to_xml(
      self         in out nocopy stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return xmltype,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in binary_double)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in tsv_array)
   return tsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in tsv_type)
   return tsv_type,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type,      
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type,     
   -- not documented
   member procedure trim_to_effective_date(
      p_date_time in date),
   -- not documented
   member procedure trim_to_create_date(
      p_date_time in date),
   -- not documented
   member function latest_shift_date
   return date      
) not final;
/


create or replace public synonym cwms_t_stream_rating for stream_rating_t;


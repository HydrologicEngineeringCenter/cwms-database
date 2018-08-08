create type location_ref_t
/**
 * Object type representing a location reference.
 *
 * @member base_location_id specifies the base location portion
 *
 * @member sub_location_id specifies the sub-location portion
 *
 * @member office_id specifies the office which owns the referenced location
 *
 * @see type location_obj_t
 * @see type location_ref_tab_t
 */
is object(
   base_location_id varchar2(16),
   sub_location_id  varchar2(32),
   office_id        varchar2(16),
   /**
    * Constructs an instance from separate location and office identifiers
    *
    * @param p_location_id the location identifier
    * @param p_office_id   the office that owns the location.  If <code><big>NULL</big></code>
    *        the session user's office is used.
    *
    * @throws INVALID_OFFICE_ID if <code><big>p_office_id</big></code>
    *         contains an invalid office identifier.
    */
   constructor function location_ref_t (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   return self as result,
   /**
    * Constructs an instance from a combined office/location identifier
    *
    * @param p_office_and_location_id the combined identifier in the form
    *        office_id<code><big>'/'</big></code>location_id. If the office
    *        identifier portion isomitted (with or without the <code><big>'/'</big></code>),
    *        the the session user's default office is used.
    *
    * @throws INVALID_OFFICE_ID if <code><big>p_office_and_location_id</big></code>
    *         contains an invalid office identifier.
    */
   constructor function location_ref_t (
      p_office_and_location_id in varchar2) -- office-id/location-id
   return self as result,
   /**
    * Constructs an instance from a database location code
    *
    * @param p_location_code the database location code
    *
    * @throws NO_DATA_FOUND if <code><big>p_location_code</big></code> is
    *         not a valid location code.
    */
   constructor function location_ref_t (
      p_location_code in number)
   return self as result,
   /**
    * Returns the database location code for the instance, optionally creating
    * it first if it doesn't already exist
    *
    * @param p_create_if_necessary specifies whether to create the location
    *        code if it doesn't already exist in the database. Valid values
    *        are <code><big>'T'</big></code> and <code><big>'F'</big></code>.
    *
    * @return the database location code for the instance
    *
    * @throws NO_DATA_FOUND if <code><big>p_create_if_necessary</big></code> is
    *         <code><big>'F'</big></code> and the location code does not already
    *         exist in the database.
    */
   member function get_location_code(
      p_create_if_necessary in varchar2 default 'F')
   return number,
   /**
    * Returns the location identifer of the instance
    *
    * @return the location identifier of the instance
    */
   member function get_location_id
   return varchar2,
   /**
    * Returns the office identifer of the instance
    *
    * @return the office code of the instance
    */
   member function get_office_code
   return number,
   /**
    * Returns the office identifer of the instance
    *
    * @return the office identifier of the instance
    */
   member function get_office_id
   return varchar2,
   /**
    * Retrieves the office and location codes of the instance, optionally creating
    * the location code if it doesn't already exist
    *
    * @param p_location_code receives the location code
    * @param p_office_code receives the office code
    * @param p_create_if_necessary specifies whether to create the location
    *        code if it doesn't already exist in the database. Valid values
    *        are <code><big>'T'</big></code> and <code><big>'F'</big></code>.
    *
    * @throws NO_DATA_FOUND if <code><big>p_create_if_necessary</big></code> is
    *         <code><big>'F'</big></code> and the location code does not already
    *         exist in the database.
    */
   member procedure get_codes(
      p_location_code       out number,
      p_office_code         out number,
      p_create_if_necessary in  varchar2 default 'F'),
   /**
    * Creates a location in the database from the instance
    *
    * @param p_fail_if_exists specifies whether the method should return silently
    *        or raise an exception if the location already exists in the database.
    *        Valid values are <code><big>'T'</big></code> and <code><big>'F'</big></code>.
    *
    * @throws LOCATION_ID_ALREADY_EXISTS if <code><big>p_fail_if_exists</big></code>
    *         is <code><big>'T'</big></code> and the location already exists in
    *         the database.
    */
   member procedure create_location(
      p_fail_if_exists in varchar2)
);
/


create or replace public synonym cwms_t_location_ref for location_ref_t;


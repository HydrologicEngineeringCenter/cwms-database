create type specified_level_t
/**
 * Holds information about a specified level.  Specified levels are named levels
 * that can be associated with combinations of locations, parameters, and durations.
 *
 * @see type specified_level_tab_t
 *
 * @member office_id   The office owning the specified level
 * @member level_id    The specified level identifier
 * @member description A description of the specified level
 */
is object(
   office_id   varchar2(16),
   level_id    varchar2(256),
   description varchar2(256),
   /**
    * Constructs a specified_level_t object from an office code and level id
    *
    * @param p_office_code a unique numeric value identifying the office that owns the specified level.
    * @param p_level_id    the specified level identifier
    * @param p_description an optional description of the specified level
    */
   constructor function specified_level_t(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2 default null)
      return self as result,
   /**
    * Constructs a specified_level_t object from information stored in the database
    *
    * @param p_level_code a unique numeric value identifying the specified level in the database
    */
   constructor function specified_level_t(
      p_level_code number)
      return self as result,
   -- undocumented
   member procedure init(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2),
   /**
    * Stores the specified level information to the database
    */
   member procedure store
);
/


create or replace public synonym cwms_t_specified_level for specified_level_t;


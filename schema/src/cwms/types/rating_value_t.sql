create type rating_value_t
/**
 * Holds one lookup value for an independent parameter for a rating, as well as the
 * associated dependent value or dependent rating sub-table.
 *
 * @see type abs_rating_ind_param_t
 * @see type rating_value_tab_t
 *
 * @member ind_value            The independent value
 * @member dep_value            The dependent value if the independent value is for the highest-position (or only) independent parameter
 * @member dep_rating_ind_param The dependent value if the independent value is not for the highest-position independent parameter
 * @member note_id              The identifier of a rating value note, if any
 */
as object(
   ind_value            binary_double,
   dep_value            binary_double,
   dep_rating_ind_param abs_rating_ind_param_t,
   note_id              varchar2(16),
   /**
    * Zero-parameter constructor. Constructs an object with all fields set to NULL.
    */
   constructor function rating_value_t
   return self as result,
   /**
    * Normal constructor.
    *
    * @param p_rating_ind_param_code The CWMS parameter code for the independent parameter represented by this lookup value
    * @param p_other_ind             A collection of the values of all lower-position independent parameters, if any, that lead to this independent parameter value
    * @param p_other_ind_hash        A hash value used to identify the collection held in the p_other_ind parameter
    * @param p_ind_value             The independent lookup value for this independent parameter
    * @param p_is_extension          A flag ('T' or 'F') that specifies whether this lookup value belongs to a rating ('F') or to a rating extension ('T')
    */
   constructor function rating_value_t(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_other_ind_hash        in varchar2,
      p_ind_value             in binary_double,
      p_is_extension          in varchar2)
   return self as result,
   /**
    * Stores this rating_value_t object to the databse
    *
    * @param p_rating_ind_param_code The CWMS parameter code for the independent parameter represented by this lookup value
    * @param p_other_ind             A collection of the values of all lower-position independent parameters, if any, that lead to this independent parameter value
    * @param p_is_extension          A flag ('T' or 'F') that specifies whether this lookup value belongs to a rating ('F') or to a rating extension ('T')
    * @param p_office_id             The office owning the rating value
    */
   member procedure store(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_is_extension          in varchar2,
      p_office_id             in varchar2),
   /**
    * Generates a unique hash code to identify the specified collection of values
    *
    * @param p_other_ind A collection of the values
    *
    * @return a unique hash code to identify the specified collection of values
    */
   static function hash_other_ind(
      p_other_ind in double_tab_t)
   return varchar2      
);
/


create or replace public synonym cwms_t_rating_value for rating_value_t;


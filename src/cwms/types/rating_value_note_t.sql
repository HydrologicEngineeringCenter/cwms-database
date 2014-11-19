create type rating_value_note_t
/**
 * Hold a not about a rating value. Rating value notes can apply to multiple rating
 * values.
 *
 * @see type rating_value_note_tab_t
 *
 * @member office_id   The office owning the note
 * @member note_id     The identifier of the note
 * @member description The text of the note
 */
as object(
   office_id   varchar2(16),
   note_id     varchar2(16),
   description varchar2(256),
   -- not documented
   constructor function rating_value_note_t(
      p_note_code in number)
   return self as result,      
   -- not documented
   member function get_note_code
   return number,
   /**
    * Stores a rating value not to the databse
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating value note already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating value note already exists
    */
   member procedure store(
      p_fail_if_exists in varchar)
);
/


create or replace public synonym cwms_t_rating_value_note for rating_value_note_t;


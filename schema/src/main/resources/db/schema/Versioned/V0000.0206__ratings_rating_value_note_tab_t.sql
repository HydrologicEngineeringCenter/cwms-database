create type rating_value_note_tab_t
/**
 * Holds a collection of rating value notes
 *
 * @see type rating_value_note_t
 */
is table of rating_value_note_t;
/


create or replace public synonym cwms_t_rating_value_note_tab for rating_value_note_tab_t;


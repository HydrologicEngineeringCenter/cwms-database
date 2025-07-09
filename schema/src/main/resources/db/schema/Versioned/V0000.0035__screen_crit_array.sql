CREATE TYPE screen_crit_array
/* (non-javadoc)
 * [description needed]
 *
 * @see type screen_crit_type
 * @see cwms_vt.store_screening_criteria
 */
IS TABLE OF screen_crit_type;
/


create or replace public synonym cwms_t_screen_crit_array for screen_crit_array;


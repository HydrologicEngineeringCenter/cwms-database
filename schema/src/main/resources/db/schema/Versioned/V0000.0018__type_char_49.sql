create or replace TYPE char_49_array_type
/**
 * Type suitable for holding parameters or other text
 * not longer than 49 bytes.
 */
IS TABLE OF VARCHAR2 (49);
/


create or replace public synonym cwms_t_char_49_array for char_49_array_type;


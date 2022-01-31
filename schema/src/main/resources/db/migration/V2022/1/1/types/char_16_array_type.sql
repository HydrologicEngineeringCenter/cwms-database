CREATE TYPE char_16_array_type
/**
 * Type suitable for holding multiple base locations, base parameters, or other text
 * not longer than 16 bytes.
 */
IS TABLE OF VARCHAR2 (16);
/


create or replace public synonym cwms_t_char_16_array for char_16_array_type;


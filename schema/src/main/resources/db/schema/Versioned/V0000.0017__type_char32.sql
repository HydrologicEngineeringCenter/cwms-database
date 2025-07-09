CREATE TYPE char_32_array_type
/**
 * Type suitable for holding multiple sub-locations, sub-parameters, or other text
 * not longer than 32 bytes.
 */
IS TABLE OF VARCHAR2 (32);
/


create or replace public synonym cwms_t_char_32_array for char_32_array_type;


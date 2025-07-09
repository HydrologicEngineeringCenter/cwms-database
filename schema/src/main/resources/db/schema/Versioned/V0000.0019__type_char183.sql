CREATE TYPE char_183_array_type
/**
 * Type suitable for holding multiple time series identifiers or other text
 * not longer than 183 bytes.
 */
IS TABLE OF VARCHAR2 (183);
/


create or replace public synonym cwms_t_char_183_array for char_183_array_type;


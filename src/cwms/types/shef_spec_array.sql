create type SHEF_SPEC_ARRAY
/**
 * Table of <code><big>shef_spec_type</big></code> records.  This collection usually
 * comprises the entire SHEF decoding criteria set for a single CWMS data stream.
 *
 * @see type shef_spec_type
 */
IS TABLE OF shef_spec_type;
/

create or replace public synonym cwms_t_shef_spec_array for shef_spec_array;


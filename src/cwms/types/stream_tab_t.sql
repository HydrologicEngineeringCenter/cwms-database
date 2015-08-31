create type stream_tab_t
/**
 * Holds a collection of streams
 *
 * @see type stream_t
 */
is table of stream_t;
/

create or replace public synonym cwms_t_stream_tab for stream_tab_t;



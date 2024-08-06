create or replace package cwms_cache
/**
 * Implements generic key/value pair caches in PL/SQL. Caches comprise key/payload pairs where each payload includes a value and access time.
 * Keys are unique within a cache, but multiple keys can have the same payload value.
 */
as
/**
 * Default cache capacity
 */
g_default_capacity constant binary_integer := 1000;

type str_payload_t
/**
 * Payload type for varchar2 values or values implicitly convertable to/from varchar2
 *
 * @member value       The payload value
 * @member access_time The last accessed time of the payload, in microseconds of the Unix epoch converted to string
 */
is record(
   value       varchar2(32767),
   access_time varchar2(16));

type str_payload_by_str_t
/**
 * Table of str_payload_t indexed by string
 */
is table of str_payload_t index by varchar2(32767);

type str_key_by_time_t
/**
 * Table of varchar2 keys indexed by access time, in microseconds of the Unix epoch converted to string
 */
is table of varchar2(32767) index by varchar2(16);

type str_str_cache_t
/**
 * Generic hash type for keys and values of varchar2 or implicityly convertable to/from varchar2. Variables of this type implement the cache data for specific purposes.
 *
 * @member name              The name of this cache, defaults to null. Package global variable caches are named in package body initialization
 * @member enabled           A flag specifying whether the cache is currently enabled
 * @member dbms_output       A flag specifying whether cache operations will be output to dbms_output
 * @member output_call_stack A flag specifying whether the call stack will be included when outputting cache operations
 * @member payloads_by_key   The table of payloads indexed by keys for this cache
 * @member keys_by_time      The table of keys indexed by access time for this cache
 * @member capacity          The current capacity of this cache
 * @member get_count         The number of times get() has been called on this chache since it was created, enabled, or had its capacity changed
 * @member hit_count         The number of cache hits on this chache since it was created, enabled, or had its capacity changed
 * @member miss_count        The number of cache misses on this chache since it was created, enabled, or had its capacity changed
 * @member put_count         The number of times put() has been called on this chache since it was created, enabled, or had its capacity changed
 * @member remove_count      The number of times remove() has been called on this cache since it was created, enabled, or had its capacity changed.
 * @member trim_count        The number of least-recently-accessed key/payload pairs removed from this chache to prevent exceeding capacity since it was created, enabled, or had its capacity changed
 */
is record(
   name              varchar2(64),
   enabled           boolean := true,
   dbms_output       boolean := false,
   output_call_stack boolean := false,
   payload_by_key    str_payload_by_str_t,
   key_by_time       str_key_by_time_t,
   capacity          binary_integer := g_default_capacity,
   get_count         binary_integer := 0,
   hit_count         binary_integer := 0,
   miss_count        binary_integer := 0,
   put_count         binary_integer := 0,
   remove_count      binary_integer := 0,
   trim_count        binary_integer := 0);
/**
 * @param p_cache The cache variable
 * @return The current number of cached key/payload pairs
 */
function count(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The current capacity
 */
function get_capacity(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * Sets the current capacity if the cache is currently enabled. Resets counts to zero.
 * @param p_cache The cache variable
 */
procedure set_capacity(
   p_cache    in out nocopy str_str_cache_t,
   p_capacity in binary_integer);
/**
 * Tests whether a key is cached. Any associated payload access time is not updated.
 * @param p_cache The cache variable
 * @param p_key   The key to test
 * @return Whether the specified key is cached.
 */
function contains_key(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
   return boolean;
/**
 * Retrieves the value associated with a key if the cache is enabled, otherwise returns NULL.
 * If the key is already cached, the payload access time is updated, otherwise NULL is returned.
 * @param p_cache The cache variable
 * @param p_key   The key for the value to retieve
 * @return The value associated with p_key, or NULL if none.
 *         There is no difference between a disabled cache, a non-existent key and one whose associated value is NULL;
           enabled() and contains_key() must be called if difference matters in context.
 */
function get(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
   return varchar2;
/**
 * Stores a key/payload pair to the cache if the cache is enabled.
 * If the key is already cached, it's associated payload value and access time will be updated, otherwise a new payload will be created.
 * @param p_cache The cache variable
 * @param p_key   The key for the value
 * @param p_val   The associated payload value
 */
procedure put(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2,
   p_val   in varchar2);
/**
 * Removes a key/payload pair from the cache if it exists and the cache is enabled.
 * No error is generated if the cache is disabled or the key is not cached
 * @param p_cache The cache variable
 * @param p_key   The key to remove
 */
procedure remove(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2);
/**
 * Removes all key/payload pairs from the cahce whose payload value matches the specified value if the cache is enabled
 * @param p_cache The cache variable
 * @param p_val   The payload value to remove - any/all key/payload pairs with this value will be removed
 * @param p_match_case A flag (T/F) specifying whethter to match the values in a case-sensitive (T) or -insensitive (F) manner. If unspecified, 'T' will be used
 */
procedure remove_by_value(
   p_cache      in out nocopy str_str_cache_t,
   p_val        in varchar2,
   p_match_case in varchar2 default 'T');
/**
 * Clears all data from the cache, but leaves it enabled. Resets counts to 0.
 * @param p_cache The cache variable
 */
procedure clear(
   p_cache in out nocopy str_str_cache_t);
/**
 * Retrieves all keys for the cache
 * @return the all keys
 */
function keys(
   p_cache in out nocopy str_str_cache_t)
   return str_tab_t;
/**
 * Disables the cache, optionally also clearing it. Operations that would normally modify the cache do not do so when disabled.
 * @param p_cache The cache variable
 * @param p_clear A flag specfying whether to also clear the cache. If true, then resets counts to zero.
 */
procedure disable(
   p_cache in out nocopy str_str_cache_t,
   p_clear in boolean default true);
/**
 * Enables a previously disabled cache. No error is generated if the cache is already enabled.
 * @param p_cache    The cache variable
 */
procedure enable(
   p_cache in out nocopy str_str_cache_t);
/**
 * Tests whether the cache is currently enabled
 * @param p_cache The cache variable
 * @return Whether the caches is currently enabled
 */
function enabled(
   p_cache in out nocopy str_str_cache_t)
   return boolean;
/**
 * @param p_cache The cache variable
 * @return The number of get() calls since creation or the most recent setting of counts to zero
 */
function gets(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of cache hits since creation or the most recent setting of counts to zero
 */
function hits(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of cache misses since creation or the most recent setting of counts to zero
 */
function misses(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of put() calls since creation or the most recent setting of counts to zero
 */
function puts(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of key/value pairs removed by remove() or remove_by_value() calls since creation or the most recent setting of counts to zero
 */
function removes(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of oldest key/value pairs trimmed to keep from exceeding capacity since creation or the most recent setting of counts to zero
 */
function trims(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of cache hits as a fraction of the number of get() calls since creation or the most recent setting of counts to zero
 */
function hit_ratio(
   p_cache in out nocopy str_str_cache_t)
   return binary_float;
/**
 * Specifies whether to print operations to dbms_out
 * @param p_cache  The cache variable
 * @param p_output Whether to print operations to dbms_out
 */
procedure set_dbms_output(
   p_cache  in out nocopy str_str_cache_t,
   p_output in boolean);
/**
 * Specifies whether to print the call stack whenever operations are printed to dbms_out
 * @param p_cache  The cache variable
 * @param p_output Whether to print the call stack whenever operations are printed to dbms_out
 */
procedure set_output_call_stack(
   p_cache  in out nocopy str_str_cache_t,
   p_output in boolean);
   
end cwms_cache;
/

grant execute on cwms_cache to cwms_user;
create or replace public synonym cwms_cache for cwms_cache;
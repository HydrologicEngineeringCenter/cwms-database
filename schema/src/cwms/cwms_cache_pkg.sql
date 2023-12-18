create or replace package cwms_cache
/**
 * Implements generic key/value pair caches in PL/SQL.
 */
as
/**
 * Default cache capacity
 */
g_default_capacity constant binary_integer := 1000;
/**
 * Payload type for table of string values indexed by string keys
 *
 * @member value       The value
 * @member access_time The last time this value was accessed, in microseconds of the Unix epoch converted to string
 */
type str_payload_t is record(
   value       varchar2(32767),
   access_time varchar2(16));
/**
 * Table of str_payload_t indexed by string
 */
type str_payload_by_str_t is table of str_payload_t index by varchar2(32767);
/**
 * Table of string keys indexed by access time, in microseconds of the Unix epoch converted to string
 */
type str_key_by_time_t is table of varchar2(32767) index by varchar2(16);
/**
 * Generic hash type. Variables of this type implement the cache data for specific purposes.
 *
 * @member name             The name of this cache, defaults to the timestamp of its creation,
 * @member dbms_output      A flag specifying whether cache operations will be output to dbms_output,
 * @member payloads_by_key  The table of payloads indexed by keys for this cache
 * @member keys_by_time     The table of keys indexed by access time for this cache,
 * @member capacity         The capacity of this cache,
 * @member get_count        The number of times get() has been called on this chache since it was created, enabled, or had its capacity changed,
 * @member hit_count        The number of cache hits on this chache since it was created, enabled, or had its capacity changed,
 * @member miss_count       The number of cache misses on this chache since it was created, enabled, or had its capacity changed,
 * @member put_count        The number of times put() has been called on this chache since it was created, enabled, or had its capacity changed,
 * @member remove_count     The number of times remove() has been called on this chache since it was created, enabled, or had its capacity changed,
 * @member trim_count       The number of items removed from this chache to keep put() from exceeding the capacity since it was created, enabled, or had its capacity changed;
 */
type str_str_cache_t is record(
   name             varchar2(64),
   dbms_output      boolean := false,
   payload_by_key   str_payload_by_str_t,
   key_by_time      str_key_by_time_t,
   capacity         binary_integer := g_default_capacity,
   get_count        binary_integer := 0,
   hit_count        binary_integer := 0,
   miss_count       binary_integer := 0,
   put_count        binary_integer := 0,
   remove_count     binary_integer := 0,
   trim_count       binary_integer := 0);
/**
 * @param p_cache The cache variable
 * @return The current number of cached key/value pairs
 */
function count(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The current capacity (max count)
 */
function get_capacity(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * Sets the current capacity (max count)
 * @param p_cache The cache variable
 */
procedure set_capacity(
   p_cache    in out nocopy str_str_cache_t,
   p_capacity in binary_integer);
/**
 * Retrieves the value associated with a key, or NULL if none exists. If the key was previously cached, its used time is updated.
 * @param p_cache The cache variable
 * @param p_key   The key for the value to retieve
 * @return The value associated with p_key, or NULL if none.
 *         There is no difference between a non-existent key and one whose associated value is NULL
 */
function get(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
   return varchar2;
/**
 * Adds a key/value pair to the cache.
 * If the key is already cached, it's associated value will be chaged to p_val if it was different.
 * Updates the used time for the key.
 * @param p_cache The cache variable
 * @param p_key   The key for the value
 * @param p_val   The associated value
 */
procedure put(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2,
   p_val   in varchar2);
/**
 * Removes a key/value pair from the cache if it exists.
 * @param p_cache The cache variable
 * @param p_key   The key for the value to remove
 */
procedure remove(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2);
/**
 * Removes a key/value pair from the cache if it exists.
 * @param p_cache The cache variable
 * @param p_val   The value to remove - any/all key/value pairs with this value will be removed
 */
procedure remove_by_value(
   p_cache in out nocopy str_str_cache_t,
   p_val   in varchar2);
/**
 * Clears all data from the cache, but leaves it enabled. Resets hit and miss counts to 0.
 * @param p_cache The cache variable
 */
procedure clear(
   p_cache in out nocopy str_str_cache_t);
/**
 * Clears all data from the cache and disables it. No new key/value pairs will be added via set. Resets hit and miss counts to 0.
 * @param p_cache The cache variable
 */
procedure disable(
   p_cache in out nocopy str_str_cache_t);
/**
 * Enables a previously disabled cache. If the cache is already enabled, no changes are made (e.g., the current capacity is not changed).
 * @param p_cache    The cache variable
 * @param p_capacity The capacity to set for the cache. If not specified, the default capacity will be used.
 */
procedure enable(
   p_cache    in out nocopy str_str_cache_t,
   p_capacity in binary_integer default g_default_capacity);
/**
 * @param p_cache The cache variable
 * @return The number of get() calls since the most recent creation, clear, or enable operation
 */
function gets(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of cache hits since the most recent creation, clear, or enable operation
 */
function hits(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of cache misses since the most recent creation, clear, or enable operation
 */
function misses(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of put() calls since the most recent creation, clear, or enable operation
 */
function puts(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of key/value pairs removed by remove() or remove_by_value() calls since the most recent creation, clear, or enable operation
 */
function removes(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of oldest key/value pairs trimmed to keep from exceeding capacity since the most recent creation, clear, or enable operation
 */
function trims(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer;
/**
 * @param p_cache The cache variable
 * @return The number of cache hits as a fraction of the number of get() calls since the most recent creation, clear, or enable operation
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
   
end cwms_cache;
/

grant execute on cwms_cache to cwms_user;
create or replace public synonym cwms_cache for cwms_cache;
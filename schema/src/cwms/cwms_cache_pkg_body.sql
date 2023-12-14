create or replace package body cwms_cache
as
--------------------------------------------------------------------------------
-- procedure trim_oldest
--------------------------------------------------------------------------------
procedure trim_oldest(
   p_cache in out nocopy str_str_cache_t)
is
   l_time varchar2(16);
   l_key  varchar2(32767);
begin
   l_time := p_cache.keys_by_time.first;
   if l_time is not null then
      l_key := p_cache.keys_by_time(l_time);
      p_cache.vals_by_key.delete(l_key);
      p_cache.times_by_key.delete(l_key);
      p_cache.keys_by_time.delete(l_time);
      p_cache.trim_count := p_cache.trim_count + 1;
   end if;
end trim_oldest;
--------------------------------------------------------------------------------
-- procedure update_last_used_time
--------------------------------------------------------------------------------
procedure update_last_used_time(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
is
   l_time varchar2(16);
begin
   begin
      l_time := p_cache.times_by_key(p_key);
   exception
      when no_data_found then null;
   end;
   if l_time is not null then
      p_cache.keys_by_time.delete(l_time);
   end if;
   l_time := cwms_util.current_micros;
   p_cache.times_by_key(p_key) := l_time;
   p_cache.keys_by_time(l_time) := p_key;
end update_last_used_time;
--------------------------------------------------------------------------------
-- function count
--------------------------------------------------------------------------------
function count(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.vals_by_key.count;
end count;
--------------------------------------------------------------------------------
-- function get_capacity
--------------------------------------------------------------------------------
function get_capacity(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.capacity;
end get_capacity;
--------------------------------------------------------------------------------
-- procedure set_capacity
--------------------------------------------------------------------------------
procedure set_capacity(
   p_cache    in out nocopy str_str_cache_t,
   p_capacity in binary_integer)
is
begin
   case
   when p_capacity < 0 then
      cwms_err.raise('ERROR', 'Invalid cache capacity: '||p_capacity);
   when nvl(p_capacity, 0) = 0 then
      clear(p_cache);
      p_cache.capacity := 0;
   else
      while cwms_cache.count(p_cache) > p_capacity loop
         trim_oldest(p_cache);
      end loop;
      p_cache.capacity := p_capacity;
   end case;
end set_capacity;
--------------------------------------------------------------------------------
-- function get
--------------------------------------------------------------------------------
function get(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
   return varchar2
is
   l_val  varchar2(32767);
begin
   p_cache.get_count := p_cache.get_count + 1;
   begin
      l_val := p_cache.vals_by_key(p_key);
   exception
      when no_data_found then null;
   end;   
   if l_val is not null then
      if p_cache.dbms_output then
         dbms_output.put_line('Cache '||p_cache.name||': hit ('||p_key||', '||l_val||')');
      end if;
      update_last_used_time(p_cache, p_key);
      p_cache.hit_count := p_cache.hit_count + 1;
   else
      if p_cache.dbms_output then
         dbms_output.put_line('Cache '||p_cache.name||': miss ('||p_key||', '||'???'||')');
      end if;
      p_cache.miss_count := p_cache.miss_count + 1;
   end if;
   return l_val;
end get;
--------------------------------------------------------------------------------
-- procedure put
--------------------------------------------------------------------------------
procedure put(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2,
   p_val   in varchar2)
is
begin
   p_cache.get_count := p_cache.put_count + 1;
   if p_cache.capacity > 0 then
      if p_cache.dbms_output then
         dbms_output.put_line('Cache '||p_cache.name||': putting ('||p_key||', '||p_val||')');
      end if;
      p_cache.vals_by_key(p_key) := p_val;
      update_last_used_time(p_cache, p_key);
      p_cache.put_count := p_cache.put_count + 1;
      while cwms_cache.count(p_cache) > p_cache.capacity loop
         trim_oldest(p_cache);
      end loop;
   end if;
end put;
--------------------------------------------------------------------------------
-- procedure remove
--------------------------------------------------------------------------------
procedure remove(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
is
   l_val  varchar2(32767);
   l_time varchar2(16);
begin
   p_cache.remove_count := p_cache.remove_count + 1;
   begin
      l_time := p_cache.times_by_key(p_key);
      p_cache.times_by_key.delete(p_key);
   exception
      when no_data_found then null;
   end;
   if l_time is not null and p_cache.keys_by_time.exists(l_time) then
      p_cache.keys_by_time.delete(l_time);
   end if;
   if p_cache.vals_by_key.exists(p_key) then
      if p_cache.dbms_output then
         dbms_output.put_line('Cache '||p_cache.name||': removing ('||p_key||', '||p_cache.vals_by_key(p_key)||')');
      end if;
      p_cache.vals_by_key.delete(p_key);
      p_cache.remove_count := p_cache.remove_count + 1;
   end if;
end remove;
--------------------------------------------------------------------------------
-- procedure remove_by_value
--------------------------------------------------------------------------------
procedure remove_by_value(
   p_cache in out nocopy str_str_cache_t,
   p_val   in varchar2)
is
   l_key  varchar2(32767) := p_cache.vals_by_key.first;
   l_keys str_tab_t := str_tab_t();
begin
   ---------------------------------
   -- collect keys matching value --
   ---------------------------------
   while l_key is not null loop
      if p_cache.vals_by_key(l_key) = p_val then
         l_keys.extend;
         l_keys(l_keys.count) := l_key;
      end if;
      l_key := p_cache.vals_by_key.next(l_key);
   end loop;
   --------------------------
   -- remove matching keys --
   --------------------------
   for i in 1..l_keys.count loop
      remove(p_cache, l_keys(i));
   end loop;
end remove_by_value;
--------------------------------------------------------------------------------
-- procedure clear
--------------------------------------------------------------------------------
procedure clear(
   p_cache in out nocopy str_str_cache_t)
is
begin
   if p_cache.dbms_output then
      dbms_output.put_line('Cache '||p_cache.name||': clearing cache');
   end if;
   p_cache.vals_by_key.delete;
   p_cache.times_by_key.delete;
   p_cache.keys_by_time.delete;
   p_cache.get_count := 0;
   p_cache.hit_count := 0;
   p_cache.miss_count := 0;
   p_cache.put_count := 0;
   p_cache.remove_count := 0;
   p_cache.trim_count := 0;
end clear;
--------------------------------------------------------------------------------
-- procedure disable
--------------------------------------------------------------------------------
procedure disable(
   p_cache in out nocopy str_str_cache_t)
is
begin
   clear(p_cache);
   set_capacity(p_cache, 0);
end disable;
--------------------------------------------------------------------------------
-- procedure enable
--------------------------------------------------------------------------------
procedure enable(
   p_cache    in out nocopy str_str_cache_t,
   p_capacity in binary_integer default g_default_capacity)
is
begin
   enable(p_cache, p_capacity);
end enable;
--------------------------------------------------------------------------------
-- function gets
--------------------------------------------------------------------------------
function gets(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.get_count;
end gets;
--------------------------------------------------------------------------------
-- function hits
--------------------------------------------------------------------------------
function hits(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.hit_count;
end hits;
--------------------------------------------------------------------------------
-- function misses
--------------------------------------------------------------------------------
function misses(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.miss_count;
end misses;
--------------------------------------------------------------------------------
-- function puts
--------------------------------------------------------------------------------
function puts(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.put_count;
end puts;
--------------------------------------------------------------------------------
-- function removes
--------------------------------------------------------------------------------
function removes(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.remove_count;
end removes;
--------------------------------------------------------------------------------
-- function trims
--------------------------------------------------------------------------------
function trims(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.trim_count;
end trims;
--------------------------------------------------------------------------------
-- function hit_ratio
--------------------------------------------------------------------------------
function hit_ratio(
   p_cache in out nocopy str_str_cache_t)
   return binary_float
is
   l_total binary_integer;
begin
   return case
          when  p_cache.get_count = 0 then binary_float_nan
          else p_cache.hit_count / p_cache.get_count
          end;
end hit_ratio;
--------------------------------------------------------------------------------
-- function set_dbms_output
--------------------------------------------------------------------------------
procedure set_dbms_output(
   p_cache  in out nocopy str_str_cache_t,
   p_output in boolean)
is
begin
   p_cache.dbms_output := p_output;
end set_dbms_output;

end cwms_cache;
/
create or replace package body cwms_cache
as
--------------------------------------------------------------------------------
-- procedure set_session_global_output_level
--------------------------------------------------------------------------------
procedure set_session_global_output_level(
   p_output_level in binary_integer)
is
begin
   if p_output_level not in (g_output_level_none, g_output_level_dbms_output, g_output_level_call_stack) then
      cwms_err.raise('INVALID_ITEM', p_output_level, 'session global cache output level');
   end if;
   g_session_global_output_level := p_output_level;
end;
--------------------------------------------------------------------------------
-- procedure output_call_stack
--------------------------------------------------------------------------------
procedure output_call_stack
is
   l_call_stack str_tab_tab_t := cwms_util.get_call_stack;
begin
      for i in 4..l_call_stack.count loop
         dbms_output.put_line(chr(9)||cwms_util.join_text(l_call_stack(i), ':'));
      end loop;
end;
--------------------------------------------------------------------------------
-- function count
--------------------------------------------------------------------------------
function count(
   p_cache in out nocopy str_str_cache_t)
   return binary_integer
is
begin
   return p_cache.payload_by_key.count;
end count;
--------------------------------------------------------------------------------
-- function contains_key
--------------------------------------------------------------------------------
function contains_key(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
   return boolean
is
begin
   if p_key is null then
      return null;
   end if;
   return p_cache.payload_by_key.exists(p_key);
end contains_key;
--------------------------------------------------------------------------------
-- function get
--------------------------------------------------------------------------------
function get(
   p_cache in out nocopy str_str_cache_t,
   p_key   in varchar2)
   return varchar2
is
   l_payload str_payload_t;
begin
   if p_cache.enabled = false then
      return null;
   end if;
   p_cache.get_count := p_cache.get_count + 1;
   if p_key is null then
      if p_cache.dbms_output or g_session_global_output_level > 0 then
         dbms_output.put_line('Cache '||p_cache.name||': miss (<NULL>, ???)');
         if p_cache.output_call_stack or g_session_global_output_level > 1 then
            output_call_stack;
         end if;
      end if;
      p_cache.miss_count := p_cache.miss_count + 1;
      return null;
   end if;
   begin
      l_payload := p_cache.payload_by_key(p_key);
   exception
      when no_data_found then null;
   end;
   if l_payload.value is not null then
      if p_cache.dbms_output or g_session_global_output_level > 0 then
         dbms_output.put_line('Cache '||p_cache.name||': hit ('||p_key||', '||l_payload.value||')');
         if p_cache.output_call_stack or g_session_global_output_level > 1 then
            output_call_stack;
         end if;
      end if;
      p_cache.hit_count := p_cache.hit_count + 1;
   else
      if p_cache.dbms_output or g_session_global_output_level > 0 then
         dbms_output.put_line('Cache '||p_cache.name||': miss ('||p_key||', ???)');
         if p_cache.output_call_stack or g_session_global_output_level > 1 then
            output_call_stack;
         end if;
      end if;
      p_cache.miss_count := p_cache.miss_count + 1;
   end if;
   return l_payload.value;
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
   if p_cache.enabled then
      if p_key is null then
         cwms_err.raise('ERROR', 'Cache '||p_cache.name||': Attempt to store a NULL key');
      end if;
      if p_cache.dbms_output or g_session_global_output_level > 0 then
         dbms_output.put_line('Cache '||p_cache.name||': putting ('||p_key||', '||p_val||')');
         if p_cache.output_call_stack or g_session_global_output_level > 1 then
            output_call_stack;
         end if;
      end if;
      p_cache.payload_by_key(p_key) := str_payload_t(p_val);
      p_cache.put_count := p_cache.put_count + 1;
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
begin
   if p_cache.enabled then
      p_cache.remove_count := p_cache.remove_count + 1;
      if p_cache.payload_by_key.exists(p_key) then
         if p_cache.dbms_output or g_session_global_output_level > 0 then
            dbms_output.put_line('Cache '||p_cache.name||': removing ('||p_key||', '||p_cache.payload_by_key(p_key).value||')');
         if p_cache.output_call_stack or g_session_global_output_level > 1 then
            output_call_stack;
         end if;
         end if;
         p_cache.payload_by_key.delete(p_key);
         p_cache.remove_count := p_cache.remove_count + 1;
      end if;
   end if;
end remove;
--------------------------------------------------------------------------------
-- procedure remove_by_value
--------------------------------------------------------------------------------
procedure remove_by_value(
   p_cache      in out nocopy str_str_cache_t,
   p_val        in varchar2,
   p_match_case in varchar2 default 'T')
is
   l_key   varchar2(32767) := p_cache.payload_by_key.first;
   l_keys  str_tab_t := str_tab_t();
   l_uval  varchar2(32767) := upper(p_val);
   l_value varchar2(32767);
begin
   if p_cache.enabled then
      ---------------------------------
      -- collect keys matching value --
      ---------------------------------
      while l_key is not null loop
         l_value := p_cache.payload_by_key(l_key).value;
         if l_value = p_val or (p_match_case = 'T' and upper(l_value) = l_uval) then
            l_keys.extend;
            l_keys(l_keys.count) := l_key;
         end if;
         l_key := p_cache.payload_by_key.next(l_key);
      end loop;
      --------------------------
      -- remove matching keys --
      --------------------------
      for i in 1..l_keys.count loop
         remove(p_cache, l_keys(i));
      end loop;
   end if;
end remove_by_value;
--------------------------------------------------------------------------------
-- procedure clear
--------------------------------------------------------------------------------
procedure clear(
   p_cache in out nocopy str_str_cache_t)
is
begin
   if p_cache.enabled then
      if p_cache.dbms_output or g_session_global_output_level > 0 then
         dbms_output.put_line('Cache '||p_cache.name||': clearing cache');
         if p_cache.output_call_stack or g_session_global_output_level > 1 then
            output_call_stack;
         end if;
      end if;
      p_cache.payload_by_key.delete;
      p_cache.get_count := 0;
      p_cache.hit_count := 0;
      p_cache.miss_count := 0;
      p_cache.put_count := 0;
      p_cache.remove_count := 0;
      p_cache.trim_count := 0;
   end if;
end clear;
--------------------------------------------------------------------------------
-- function keys
--------------------------------------------------------------------------------
function keys(
   p_cache in out nocopy str_str_cache_t)
   return str_tab_t
is
   l_key varchar2(32767) := p_cache.payload_by_key.first;
   l_keys str_tab_t      := str_tab_t();
   i    binary_integer   := 1;
begin
   l_keys.extend(p_cache.payload_by_key.count);
   while l_key is not null loop
      l_keys(i) := l_key;
      l_key     := p_cache.payload_by_key.next(l_key);
      i         := i + 1;
   end loop;
   return l_keys;
end keys;
--------------------------------------------------------------------------------
-- procedure disable
--------------------------------------------------------------------------------
procedure disable(
   p_cache in out nocopy str_str_cache_t,
   p_clear in boolean default true)
is
begin
   p_cache.enabled := false;
   if p_clear then
      clear(p_cache);
   end if;
end disable;
--------------------------------------------------------------------------------
-- procedure enable
--------------------------------------------------------------------------------
procedure enable(
   p_cache    in out nocopy str_str_cache_t)
is
begin
   p_cache.enabled := true;
end enable;
--------------------------------------------------------------------------------
-- function enabled
--------------------------------------------------------------------------------
function enabled(
   p_cache in out nocopy str_str_cache_t)
   return boolean
is
begin
   return p_cache.enabled;
end;
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
--------------------------------------------------------------------------------
-- function set_output_call_stack
--------------------------------------------------------------------------------
procedure set_output_call_stack(
   p_cache  in out nocopy str_str_cache_t,
   p_output in boolean)
is
begin
   p_cache.output_call_stack := p_output;
end set_output_call_stack;

end cwms_cache;
/
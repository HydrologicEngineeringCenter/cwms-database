create or replace package test_cwms_cache
as
--%suite (Test CWMS_CACHE package code)
--%beforeall (setup)
--%afterall (teardown)
--%rollback (manual)

procedure setup;
procedure teardown;

--%test(Test CWMS_CACHE routines)
procedure basic_test;
end test_cwms_cache;
/
create or replace package body test_cwms_cache
as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   null;
end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
begin
   null;
end teardown;
--------------------------------------------------------------------------------
-- procedure basic_test
--------------------------------------------------------------------------------
procedure basic_test
is
   l_cache cwms_cache.str_str_cache_t;
   l_key   binary_integer;
   l_val   varchar2(64);
   l_cap   binary_integer;
begin
   ------------------------------------
   -- test newly-created empty cache --
   ------------------------------------
   ut.expect(l_cache.name).to_be_null;
   ut.expect(l_cache.enabled).to_be_true;
   ut.expect(l_cache.dbms_output).to_be_false;
   ut.expect(cwms_cache.count(l_cache)).to_equal(0);
   ut.expect(cwms_cache.gets(l_cache)).to_equal(0);
   ut.expect(cwms_cache.hits(l_cache)).to_equal(0);
   ut.expect(cwms_cache.misses(l_cache)).to_equal(0);
   ut.expect(cwms_cache.puts(l_cache)).to_equal(0);
   ut.expect(cwms_cache.removes(l_cache)).to_equal(0);
   ut.expect(cwms_cache.trims(l_cache)).to_equal(0);
   ut.expect(cwms_cache.hit_ratio(l_cache) is nan).to_be_true;
   ---------------------------------------
   -- store a value and test operations --
   ---------------------------------------
   cwms_cache.put(l_cache, 'key_0001', 'val_0001');
   ut.expect(cwms_cache.contains_key(l_cache, 'key_0001')).to_be_true;
   ut.expect(cwms_cache.get(l_cache, 'key_0001')).to_equal('val_0001');
   ut.expect(cwms_cache.count(l_cache)).to_equal(1);
   ut.expect(cwms_cache.gets(l_cache)).to_equal(1);
   ut.expect(cwms_cache.hits(l_cache)).to_equal(1);
   ut.expect(cwms_cache.misses(l_cache)).to_equal(0);
   ut.expect(cwms_cache.puts(l_cache)).to_equal(1);
   ut.expect(cwms_cache.removes(l_cache)).to_equal(0);
   ut.expect(cwms_cache.trims(l_cache)).to_equal(0);
   ut.expect(cwms_cache.hit_ratio(l_cache)).to_equal(1.0);
   -------------------------------------------
   -- disable the cache and test operations --
   -------------------------------------------
   cwms_cache.disable(l_cache, p_clear => false);
   ut.expect(l_cache.enabled).to_be_false;
   cwms_cache.put(l_cache, 'key_0002', 'val_0002');                     -- would modify disabled cache
   ut.expect(cwms_cache.contains_key(l_cache, 'key_0001')).to_be_true;  -- doesn't modify cache
   ut.expect(cwms_cache.get(l_cache, 'key_0001')).to_be_null;           -- would modify disabled cache (access time for key and get_count)
   ut.expect(cwms_cache.contains_key(l_cache, 'key_0002')).to_be_false; -- doesn't modify cache
   ut.expect(cwms_cache.get(l_cache, 'key_0002')).to_be_null;           -- would modify disabled cache (get_count)
   ut.expect(cwms_cache.count(l_cache)).to_equal(1);
   ut.expect(cwms_cache.gets(l_cache)).to_equal(1);
   ut.expect(cwms_cache.hits(l_cache)).to_equal(1);
   ut.expect(cwms_cache.misses(l_cache)).to_equal(0);
   ut.expect(cwms_cache.puts(l_cache)).to_equal(1);
   ut.expect(cwms_cache.removes(l_cache)).to_equal(0);
   ut.expect(cwms_cache.trims(l_cache)).to_equal(0);
   ut.expect(cwms_cache.hit_ratio(l_cache)).to_equal(1.0);
   ---------------------------------------
   -- reset cache and output operations --
   ---------------------------------------
   cwms_cache.enable(l_cache);
   cwms_cache.clear(l_cache);
   cwms_cache.set_dbms_output(l_cache, true);
end basic_test;
end test_cwms_cache;
/
create or replace package test_cwms_util as

--%suite(Test cwms_util package code)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test split_text {/no regex/split all/default delimiter})
procedure split_text_no_regex_split_all_default_delimiter;
--%test(Test split_text {/no regex/split all/specified delimiter})
procedure split_text_no_regex_split_all_specified_delimiter;
--%test(Test split_text {/no regex/max split/default delimiter})
procedure split_text_no_regex_max_split_default_delimiter;
--%test(Test split_text {/no regex/max split/specified delimiter})
procedure split_text_no_regex_max_split_specified_delimiter;
--%test(Test split_text {/no regex/get index/default delimiter})
procedure split_text_no_regex_get_index_default_delimiter;
--%test(Test split_text {/no regex/get index/specified delimiter})
procedure split_text_no_regex_get_index_specified_delimiter;
--%test(Test split_text {/regex/split all/don't include delimiters})
procedure split_text_regex_split_all_no_include_delimiters;
--%test(Test split_text {/regex/split all/include delimiters})
procedure split_text_regex_split_all_include_delimiters;
--%test(Test split_text {/regex/max split/don't include delimiters})
procedure split_text_regex_max_split_no_include_delimiters;
--%test(Test split_text {/regex/max split/include delimiters})
procedure split_text_regex_max_split_include_delimiters;
--%test(Test split_text {/regex/get index})
procedure split_text_regex_get_index;
--%test(Test CWMS_DB_CHANGE_LOG entry)
procedure test_cwms_db_change_log;
--%test(Test math expressions)
procedure test_math_expressions;
--%test(Test comparison expressions)
procedure test_comparison_expressions;
--%test(Test logic expressions)
procedure test_logic_expressions;
--%test(Test CWDB-255 Cache unit conversion factors and formulas in convert_units)
procedure cwdb_255_cache_unit_conversion_factors_and_formulas_in_convert_units;
--%test(Test passing a null timestamp to to_timestamp returns null)
procedure test_to_timestamp_null_timestamp;
--%test(Test RUNSTSTATS package)
procedure test_runstats;

procedure setup;
procedure teardown;
--------------------------
-- split_text test data --
--------------------------
test_data_varchar varchar2(32767);
test_data_clob    clob;
len_data_varchar  integer;
len_data_clob     integer;
end test_cwms_util;
/
create or replace package body test_cwms_util as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
   l_line varchar(128);
begin
   --------------------------------------------------
   -- initialize the data for the split_text tests --
   --------------------------------------------------
   test_data_varchar := null;
   test_data_clob    := null;
   len_data_varchar  := 1;
   len_data_clob     := 1;
   -- test_data_clob will be barely larger than largest varchar2
   dbms_lob.createtemporary(test_data_clob, true);
   for i in 1..999999 loop
      l_line := 'line_'||i||'_space line_'||i||'_tab'||chr(9)||'line_'||i||'_newline'||chr(10);
      exit when length(test_data_varchar) + length(l_line) > 32766;
      test_data_varchar := test_data_varchar||chr(10)||l_line;
      len_data_varchar  := len_data_varchar + 2;
      cwms_util.append(test_data_clob, chr(10)||l_line);
      len_data_clob := len_data_clob + 2;
   end loop;
   cwms_util.append(test_data_clob, chr(10)||l_line);
   len_data_clob := len_data_clob + 2;
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
-- procedure split_text_no_regex_split_all_default_delimiter
--------------------------------------------------------------------------------
procedure split_text_no_regex_split_all_default_delimiter
is
   l_parts          str_tab_t;
   l_expected_count integer;
   l_idx            integer;
   l_clob           clob;
begin
   --------------------------------------------
   -- make sure we pass the trivial examples --
   --------------------------------------------
   l_parts := cwms_util.split_text('---', '.');
   ut.expect(l_parts.count).to_equal(1);
   ut.expect(l_parts(1)).to_equal('---');
   l_parts := cwms_util.split_text('', '.');
   ut.expect(l_parts.count).to_equal(0);
   l_parts := cwms_util.split_text(l_clob, '.');
   ut.expect(l_parts.count).to_equal(0);
   dbms_lob.createtemporary(l_clob, true);
   l_parts := cwms_util.split_text(l_clob, '.');
   ut.expect(l_parts.count).to_equal(0);
   l_parts := cwms_util.split_text('1 2 3 4 5 6 7 8 9 10');
   ut.expect(l_parts.count).to_equal(10);
   for i in 1..l_parts.count loop
      ut.expect(to_number(l_parts(i))).to_equal(i);
   end loop;
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text(test_data_varchar);
   l_expected_count := (len_data_varchar-1)/2 * 3 + 2; -- add 2 instead of 1 b/c data starts with delimiter
   ut.expect(l_parts.count).to_equal(l_expected_count);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_varchar/2));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text(test_data_clob);
   l_expected_count := (len_data_clob-1)/2 * 3 + 2;  -- add 2 instead of 1 b/c data starts with delimiter
   ut.expect(l_parts.count).to_equal(l_expected_count);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_clob/2));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
end split_text_no_regex_split_all_default_delimiter;
--------------------------------------------------------------------------------
-- procedure split_text_no_regex_split_all_specified_delimiter
--------------------------------------------------------------------------------
procedure split_text_no_regex_split_all_specified_delimiter
is
   l_parts str_tab_t;
   l_idx   integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text(test_data_varchar, chr(10));
   ut.expect(l_parts.count).to_equal(len_data_varchar);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(1, len_data_varchar/2));
      ut.expect(l_parts((l_idx *2))).to_equal('line_'||l_idx||'_space line_'||l_idx||'_tab'||chr(9)||'line_'||l_idx||'_newline');
   end loop;
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text(test_data_clob, chr(10));
   ut.expect(l_parts.count).to_equal(len_data_clob);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(1, len_data_clob/2));
      ut.expect(l_parts((l_idx *2))).to_equal('line_'||l_idx||'_space line_'||l_idx||'_tab'||chr(9)||'line_'||l_idx||'_newline');
   end loop;
end split_text_no_regex_split_all_specified_delimiter;
--------------------------------------------------------------------------------
-- procedure split_text_no_regex_max_split_default_delimiter
--------------------------------------------------------------------------------
procedure split_text_no_regex_max_split_default_delimiter
is
   l_parts     str_tab_t;
   l_idx       integer;
   l_max_split integer := 50;
   l_len       integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text(test_data_varchar, null, l_max_split);
   ut.expect(l_parts.count).to_equal(l_max_split + 1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, l_max_split/3));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   l_len := 0;
   for i in 1..l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(l_max_split+1))).to_be_greater_than(l_len);
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text(test_data_clob, null, l_max_split);
   ut.expect(l_parts.count).to_equal(l_max_split + 1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, l_max_split/3));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   l_len := 0;
   for i in 1..l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(l_max_split+1))).to_be_greater_than(l_len);
end split_text_no_regex_max_split_default_delimiter;
--------------------------------------------------------------------------------
-- procedure split_text_no_regex_max_split_specified_delimiter
--------------------------------------------------------------------------------
procedure split_text_no_regex_max_split_specified_delimiter
is
   l_parts     str_tab_t;
   l_idx       integer;
   l_max_split integer := 50;
   l_len       integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text(test_data_varchar, chr(10), l_max_split);
   ut.expect(l_parts.count).to_equal(l_max_split + 1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(1, l_max_split/2));
      ut.expect(l_parts((l_idx *2))).to_equal('line_'||l_idx||'_space line_'||l_idx||'_tab'||chr(9)||'line_'||l_idx||'_newline');
   end loop;
   l_len := 0;
   for i in 1..l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(l_max_split+1))).to_be_greater_than(l_len);
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text(test_data_clob, chr(10), l_max_split);
   ut.expect(l_parts.count).to_equal(l_max_split + 1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(1, l_max_split/2));
      ut.expect(l_parts((l_idx *2))).to_equal('line_'||l_idx||'_space line_'||l_idx||'_tab'||chr(9)||'line_'||l_idx||'_newline');
   end loop;
   l_len := 0;
   for i in 1..l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(l_max_split+1))).to_be_greater_than(l_len);
end split_text_no_regex_max_split_specified_delimiter;
--------------------------------------------------------------------------------
-- procedure split_text_no_regex_get_index_default_delimiter
--------------------------------------------------------------------------------
procedure split_text_no_regex_get_index_default_delimiter
is
   l_idx integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_varchar/2));
      ut.expect(cwms_util.split_text(test_data_varchar, (l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(cwms_util.split_text(test_data_varchar, (l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(cwms_util.split_text(test_data_varchar, (l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   ut.expect(cwms_util.split_text(test_data_varchar, len_data_varchar*2)).to_be_null();
   ------------------------
   -- next the clob data --
   ------------------------
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_clob/2));
      ut.expect(cwms_util.split_text(test_data_clob, (l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(cwms_util.split_text(test_data_clob, (l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(cwms_util.split_text(test_data_clob, (l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   ut.expect(cwms_util.split_text(test_data_clob, len_data_clob*2)).to_be_null();
end split_text_no_regex_get_index_default_delimiter;
--------------------------------------------------------------------------------
-- procedure split_text_no_regex_get_index_specified_delimiter
--------------------------------------------------------------------------------
procedure split_text_no_regex_get_index_specified_delimiter
is
   l_idx integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_varchar/2));
      ut.expect(cwms_util.split_text(test_data_varchar, l_idx*2, chr(10))).to_equal('line_'||l_idx||'_space line_'||l_idx||'_tab'||chr(9)||'line_'||l_idx||'_newline');
   end loop;
   ut.expect(cwms_util.split_text(test_data_varchar, len_data_varchar*2)).to_be_null();
   ------------------------
   -- next the clob data --
   ------------------------
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_clob/2));
      ut.expect(cwms_util.split_text(test_data_clob, l_idx*2, chr(10))).to_equal('line_'||l_idx||'_space line_'||l_idx||'_tab'||chr(9)||'line_'||l_idx||'_newline');
   end loop;
   ut.expect(cwms_util.split_text(test_data_clob, len_data_clob*2)).to_be_null();
end split_text_no_regex_get_index_specified_delimiter;
--------------------------------------------------------------------------------
-- procedure split_text_regex_split_all_no_include_delimiters
--------------------------------------------------------------------------------
procedure split_text_regex_split_all_no_include_delimiters
is
   l_parts          str_tab_t;
   l_expected_count integer;
   l_idx            integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text_regexp(test_data_varchar, '\s+');
   l_expected_count := (len_data_varchar-1)/2 * 3 + 2; -- add 2 instead of 1 b/c data starts with delimiter
   ut.expect(l_parts.count).to_equal(l_expected_count);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_varchar/2));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text_regexp(test_data_clob, '\s+');
   l_expected_count := (len_data_clob-1)/2 * 3 + 2;  -- add 2 instead of 1 b/c data starts with delimiter
   ut.expect(l_parts.count).to_equal(l_expected_count);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_clob/2));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
end split_text_regex_split_all_no_include_delimiters;
--------------------------------------------------------------------------------
-- procedure split_text_regex_split_all_include_delimiters
--------------------------------------------------------------------------------
procedure split_text_regex_split_all_include_delimiters
is
   l_parts          str_tab_t;
   l_expected_count integer;
   l_idx            integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text_regexp(test_data_varchar, '\s+', 'T');
   ut.expect(l_parts.count).to_equal(len_data_varchar * 3);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_varchar/3));
      ut.expect(l_parts((l_idx - 1) * 6 + 3)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 6 + 4)).to_equal(' ');
      ut.expect(l_parts((l_idx - 1) * 6 + 5)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 6 + 6)).to_equal(chr(9));
      ut.expect(l_parts((l_idx - 1) * 6 + 7)).to_equal('line_'||l_idx||'_newline');
      ut.expect(l_parts((l_idx - 1) * 6 + 8)).to_equal(chr(10)||chr(10));
   end loop;
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text_regexp(test_data_clob, '\s+', 'T');
   ut.expect(l_parts.count).to_equal(len_data_clob * 3);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_clob/3));
      ut.expect(l_parts((l_idx - 1) * 6 + 3)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 6 + 4)).to_equal(' ');
      ut.expect(l_parts((l_idx - 1) * 6 + 5)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 6 + 6)).to_equal(chr(9));
      ut.expect(l_parts((l_idx - 1) * 6 + 7)).to_equal('line_'||l_idx||'_newline');
      ut.expect(l_parts((l_idx - 1) * 6 + 8)).to_equal(chr(10)||chr(10));
   end loop;
end split_text_regex_split_all_include_delimiters;
--------------------------------------------------------------------------------
-- procedure split_text_regex_max_split_no_include_delimiters
--------------------------------------------------------------------------------
procedure split_text_regex_max_split_no_include_delimiters
is
   l_parts     str_tab_t;
   l_idx       integer;
   l_max_split integer := 50;
   l_len       integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text_regexp(test_data_varchar, '\s+', 'F', 'c', l_max_split);
   ut.expect(l_parts.count).to_equal(l_max_split + 1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, l_max_split/3));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   l_len := 0;
   for i in 1..l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(l_max_split+1))).to_be_greater_than(l_len);
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text_regexp(test_data_clob, '\s+', 'F', 'c', l_max_split);
   ut.expect(l_parts.count).to_equal(l_max_split + 1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, l_max_split/3));
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
   l_len := 0;
   for i in 1..l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(l_max_split+1))).to_be_greater_than(l_len);
end split_text_regex_max_split_no_include_delimiters;
--------------------------------------------------------------------------------
-- procedure split_text_regex_max_split_include_delimiters
--------------------------------------------------------------------------------
procedure split_text_regex_max_split_include_delimiters
is
   l_parts     str_tab_t;
   l_idx       integer;
   l_max_split integer := 50;
   l_len       integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text_regexp(test_data_varchar, '\s+', 'T', 'c', l_max_split);
   ut.expect(l_parts.count).to_equal(2*l_max_split+1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, l_max_split/3));
      ut.expect(l_parts((l_idx - 1) * 6 + 3)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 6 + 4)).to_equal(' ');
      ut.expect(l_parts((l_idx - 1) * 6 + 5)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 6 + 6)).to_equal(chr(9));
      ut.expect(l_parts((l_idx - 1) * 6 + 7)).to_equal('line_'||l_idx||'_newline');
      ut.expect(l_parts((l_idx - 1) * 6 + 8)).to_equal(chr(10)||chr(10));
   end loop;
   l_len := 0;
   for i in 1..2*l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(l_parts.count))).to_be_greater_than(l_len);
   ------------------------
   -- next the clob data --
   ------------------------
   l_parts := cwms_util.split_text_regexp(test_data_clob, '\s+', 'T', 'c', l_max_split);
   ut.expect(l_parts.count).to_equal(2*l_max_split+1);
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, l_max_split/3));
      ut.expect(l_parts((l_idx - 1) * 6 + 3)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 6 + 4)).to_equal(' ');
      ut.expect(l_parts((l_idx - 1) * 6 + 5)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 6 + 6)).to_equal(chr(9));
      ut.expect(l_parts((l_idx - 1) * 6 + 7)).to_equal('line_'||l_idx||'_newline');
      ut.expect(l_parts((l_idx - 1) * 6 + 8)).to_equal(chr(10)||chr(10));
   end loop;
   l_len := 0;
   for i in 1..2*l_max_split loop
      l_len := l_len + case when l_parts(i) is null then 0 else length(l_parts(i)) end;
   end loop;
   ut.expect(length(l_parts(2*l_max_split+1))).to_be_greater_than(l_len);
end split_text_regex_max_split_include_delimiters;
--------------------------------------------------------------------------------
-- procedure split_text_regex_get_index
--------------------------------------------------------------------------------
procedure split_text_regex_get_index
is
   l_idx integer;
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_varchar/2));
      ut.expect(cwms_util.split_text_ex(test_data_varchar, '\s+', 'T', 'c', 'F', (l_idx - 1) * 3 + 2, null)(1)).to_equal('line_'||l_idx||'_space');
      ut.expect(cwms_util.split_text_ex(test_data_varchar, '\s+', 'T', 'c', 'F', (l_idx - 1) * 3 + 3, null)(1)).to_equal('line_'||l_idx||'_tab');
      ut.expect(cwms_util.split_text_ex(test_data_varchar, '\s+', 'T', 'c', 'F', (l_idx - 1) * 3 + 4, null)(1)).to_equal('line_'||l_idx||'_newline');
   end loop;
   ut.expect(cwms_util.split_text_ex(test_data_varchar, '\s+', 'T', 'c', 'F', len_data_varchar*2).count).to_equal(0);
   ------------------------
   -- next the clob data --
   ------------------------
   for i in 1..3 loop
      l_idx := trunc(dbms_random.value(2, len_data_clob/2));
      ut.expect(cwms_util.split_text_ex(test_data_clob, '\s+', 'T', 'c', 'F', (l_idx - 1) * 3 + 2, null)(1)).to_equal('line_'||l_idx||'_space');
      ut.expect(cwms_util.split_text_ex(test_data_clob, '\s+', 'T', 'c', 'F', (l_idx - 1) * 3 + 3, null)(1)).to_equal('line_'||l_idx||'_tab');
      ut.expect(cwms_util.split_text_ex(test_data_clob, '\s+', 'T', 'c', 'F', (l_idx - 1) * 3 + 4, null)(1)).to_equal('line_'||l_idx||'_newline');
   end loop;
   ut.expect(cwms_util.split_text_ex(test_data_clob, '\s+', 'T', 'c', 'F', len_data_varchar*2).count).to_equal(0);
end split_text_regex_get_index;
--------------------------------------------------------------------------------
-- procedure test_math_expressions
--------------------------------------------------------------------------------
procedure test_math_expressions
is
begin
   -------------------------
   -- test unary operator --
   -------------------------
   ut.expect(cwms_util.eval_expression('-i1', cwms_t_double_tab(10))).to_equal(-10);
   ---------------------------
   -- test binary operators --
   ---------------------------
   ut.expect(cwms_util.eval_expression(' 10 +   7', null)).to_equal(17);
   ut.expect(cwms_util.eval_expression(' 10 -   7', null)).to_equal(3);
   ut.expect(cwms_util.eval_expression(' 10 *   7', null)).to_equal(70);
   ut.expect(cwms_util.eval_expression(' 10 /   7', null)).to_equal(10D/7D);
   ut.expect(cwms_util.eval_expression(' 10 //  7', null)).to_equal(1);
   ut.expect(cwms_util.eval_expression(' 10 %   7', null)).to_equal(mod(10D,7D));
   ut.expect(cwms_util.eval_expression('-10 %   7', null)).to_equal(mod(-10D,7D));
   ut.expect(cwms_util.eval_expression(' 10 %  -7', null)).to_equal(mod(10D,-7D));
   ut.expect(cwms_util.eval_expression('-10 %  -7', null)).to_equal(mod(-10D,-7D));
   ut.expect(cwms_util.eval_expression(' 10 ^   7', null)).to_equal(1E7);
   --------------------------
   -- test unary functions --
   --------------------------
   ut.expect(cwms_util.eval_expression('abs(-10)',   null)).to_equal(10);
   ut.expect(cwms_util.eval_expression('abs(10)',    null)).to_equal(10);
   ut.expect(cwms_util.eval_expression('acos(0.5)',  null)).to_equal(acos(0.5D));
   ut.expect(cwms_util.eval_expression('asin(0.5)',  null)).to_equal(asin(0.5D));
   ut.expect(cwms_util.eval_expression('atan(9.5)',  null)).to_equal(atan(9.5D));
   ut.expect(cwms_util.eval_expression('cos(2.5)',   null)).to_equal(cos(2.5D));
   ut.expect(cwms_util.eval_expression('ceil(2.5)',  null)).to_equal(3);
   ut.expect(cwms_util.eval_expression('exp(2.5)',   null)).to_equal(exp(2.5D));
   ut.expect(cwms_util.eval_expression('floor(2.5)', null)).to_equal(2);
   ut.expect(cwms_util.eval_expression('inv(2.5)',   null)).to_equal(1D/2.5D);
   ut.expect(cwms_util.eval_expression('ln(2.5)',    null)).to_equal(ln(2.5D));
   ut.expect(cwms_util.eval_expression('log(2.5)',   null)).to_equal(log(10D, 2.5D));
   ut.expect(cwms_util.eval_expression('log10(2.5)', null)).to_equal(log(10D, 2.5D));
   ut.expect(cwms_util.eval_expression('logn(2.5)',  null)).to_equal(ln(2.5D));
   ut.expect(cwms_util.eval_expression('neg(2.5)',   null)).to_equal(-2.5);
   ut.expect(cwms_util.eval_expression('neg(-2.5)',  null)).to_equal(2.5);
   ut.expect(cwms_util.eval_expression('round(2.5)', null)).to_equal(2);
   ut.expect(cwms_util.eval_expression('round(3.5)', null)).to_equal(4);
   ut.expect(cwms_util.eval_expression('sign(2.5)',  null)).to_equal(1);
   ut.expect(cwms_util.eval_expression('sign(-2.5)', null)).to_equal(-1);
   ut.expect(cwms_util.eval_expression('sqrt(2.5)',  null)).to_equal(sqrt(2.5D));
   ut.expect(cwms_util.eval_expression('tan(2.5)',   null)).to_equal(tan(2.5D));
   ut.expect(cwms_util.eval_expression('trunc(2.5)', null)).to_equal(2);
   --------------------------
   -- test binary function --
   --------------------------
   ut.expect(cwms_util.eval_expression('fmod( 10,  7)', null)).to_equal(mod(10D,7D));
   ut.expect(cwms_util.eval_expression('fmod(-10,  7)', null)).to_equal(mod(-10D,7D));
   ut.expect(cwms_util.eval_expression('fmod( 10, -7)', null)).to_equal(mod(10D,-7D));
   ut.expect(cwms_util.eval_expression('fmod(-10, -7)', null)).to_equal(mod(-10D,-7D));
   -----------------------------
   -- test variadic functions --
   -----------------------------
   ut.expect(cwms_util.eval_expression('avg(1,2,3,4)',   null)).to_equal(2.5);
   ut.expect(cwms_util.eval_expression('count(1,2,3,4)', null)).to_equal(4);
   ut.expect(cwms_util.eval_expression('max(1,2,3,4)',   null)).to_equal(4);
   ut.expect(cwms_util.eval_expression('mean(1,2,3,4)',  null)).to_equal(2.5);
   ut.expect(cwms_util.eval_expression('min(1,2,3,4)',   null)).to_equal(1);
   ut.expect(cwms_util.eval_expression('prod(1,2,3,4)',  null)).to_equal(24);
   ut.expect(cwms_util.eval_expression('sum(1,2,3,4)',   null)).to_equal(10);
   ------------------------------------
   -- test nested variadic functions --
   ------------------------------------
   ut.expect(cwms_util.eval_expression('sum(1,max(0,1,2),3,min(4,5,6))', null)).to_equal(10);
   -------------------------------
   -- test formats of variables --
   -------------------------------
   ut.expect(cwms_util.eval_expression('sum(arg1,arg2,arg3,arg4)', cwms_t_double_tab(1,2,3,4))).to_equal(10);
   ut.expect(cwms_util.eval_expression('sum( $i1, $i2, $i3, $i4)', cwms_t_double_tab(1,2,3,4))).to_equal(10);
   ut.expect(cwms_util.eval_expression('sum(  i1,  i2,  i3,  i4)', cwms_t_double_tab(1,2,3,4))).to_equal(10);
end test_math_expressions;
--------------------------------------------------------------------------------
-- procedure test_comparison_expressions
--------------------------------------------------------------------------------
procedure test_comparison_expressions
is
begin
   --------------------
   -- test operators --
   --------------------
   ut.expect(cwms_util.eval_comparison_expression('0  = 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('0 != 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('0 <> 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('0 NE 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('0  < 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('0 LT 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('0 <= 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('0 LE 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('0  > 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('0 GT 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('0 >= 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('0 GE 1', null)).to_equal(false);

   ut.expect(cwms_util.eval_comparison_expression('1  = 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 != 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 <> 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 NE 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1  < 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 LT 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 <= 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 LE 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1  > 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 GT 1', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 >= 1', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 GE 1', null)).to_equal(true);

   ut.expect(cwms_util.eval_comparison_expression('1  = 0', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 != 0', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 <> 0', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 NE 0', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1  < 0', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 LT 0', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 <= 0', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1 LE 0', null)).to_equal(false);
   ut.expect(cwms_util.eval_comparison_expression('1  > 0', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 GT 0', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 >= 0', null)).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('1 GE 0', null)).to_equal(true);
   -------------------------------
   -- test formats of variables --
   -------------------------------
   ut.expect(cwms_util.eval_comparison_expression('arg1 GE arg2', cwms_t_double_tab(1, 0))).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression(' $i1 GE  $i2', cwms_t_double_tab(1, 0))).to_equal(true);
   ut.expect(cwms_util.eval_comparison_expression('  i1 GE   i2', cwms_t_double_tab(1, 0))).to_equal(true);
end test_comparison_expressions;
--------------------------------------------------------------------------------
-- procedure test_logic_expressions
--------------------------------------------------------------------------------
procedure test_logic_expressions
is
begin
   ut.expect(cwms_t_logic_expr('not 0  = 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('not 0 != 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('not 0 <> 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('not 0 ne 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('not 0  < 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('not 0 lt 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('not 0 <= 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('not 0 le 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('not 0  > 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('not 0 gt 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('not 0 >= 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('not 0 ge 1').evaluate(null)).to_equal(true);

   ut.expect(cwms_t_logic_expr('0  = 1 and 1  = 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 != 1 and 1 != 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 <> 1 and 1 <> 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 ne 1 and 1 ne 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0  < 1 and 1  < 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 lt 1 and 1 lt 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 <= 1 and 1 <= 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 le 1 and 1 le 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0  > 1 and 1  > 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 gt 1 and 1 gt 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 >= 1 and 1 >= 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 ge 1 and 1 ge 1').evaluate(null)).to_equal(false);

   ut.expect(cwms_t_logic_expr('0  = 1 or 1  = 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 != 1 or 1 != 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 <> 1 or 1 <> 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 ne 1 or 1 ne 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0  < 1 or 1  < 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 lt 1 or 1 lt 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 <= 1 or 1 <= 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 le 1 or 1 le 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0  > 1 or 1  > 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 gt 1 or 1 gt 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 >= 1 or 1 >= 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 ge 1 or 1 ge 1').evaluate(null)).to_equal(true);

   ut.expect(cwms_t_logic_expr('0  = 1 xor 1  = 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 != 1 xor 1 != 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 <> 1 xor 1 <> 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 ne 1 xor 1 ne 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0  < 1 xor 1  < 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 lt 1 xor 1 lt 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 <= 1 xor 1 <= 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 le 1 xor 1 le 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0  > 1 xor 1  > 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 gt 1 xor 1 gt 1').evaluate(null)).to_equal(false);
   ut.expect(cwms_t_logic_expr('0 >= 1 xor 1 >= 1').evaluate(null)).to_equal(true);
   ut.expect(cwms_t_logic_expr('0 ge 1 xor 1 ge 1').evaluate(null)).to_equal(true);
   -------------------------------
   -- test formats of variables --
   -------------------------------
   ut.expect(cwms_t_logic_expr('arg1 ge 1 xor arg2 ge 1').evaluate(cwms_t_double_tab(0, 1))).to_equal(true);
   ut.expect(cwms_t_logic_expr(' $i1 ge 1 xor  $i2 ge 1').evaluate(cwms_t_double_tab(0, 1))).to_equal(true);
   ut.expect(cwms_t_logic_expr('  i1 ge 1 xor   i2 ge 1').evaluate(cwms_t_double_tab(0, 1))).to_equal(true);
end test_logic_expressions;
---------------------------------------
-- procedure test_cwms_db_change_log --
---------------------------------------
-- not really a part of CWMS_UTIL, but I didn't want to create another test package just for this
procedure test_cwms_db_change_log
is
   l_count      pls_integer;
   l_apply_date date;
begin
   select count(*)
     into l_count
     from cwms_db_change_log;
   ut.expect(l_count).to_be_greater_than(0);
   select max(apply_date)
     into l_apply_date
     from cwms_db_change_log;
   ut.expect(sysdate - l_apply_date).to_be_less_than(1);
end test_cwms_db_change_log;
---------------------------------------------------------------------------------
-- procedure cwdb_255_cache_unit_conversion_factors_and_formulas_in_convert_units
---------------------------------------------------------------------------------
procedure cwdb_255_cache_unit_conversion_factors_and_formulas_in_convert_units
is
   l_from_unit_ids cwms_t_str_tab := cwms_t_str_tab('B',  'B',  'B',    'F', 'Hz', 'K', 'MHz', 'ft', 'ft', 'ft',   'ft', 'ft', 'ft', 'ft', 'ft', 'kHz');
   l_to_unit_ids   cwms_t_str_tab := cwms_t_str_tab('Hz', 'MHz', 'kHz', 'K', 'B',  'F', 'B',   'cm', 'ft', 'ftUS', 'in', 'km', 'm',  'mi', 'mm', 'B');
   l_results       cwms_t_double_tab;
   l_val_count     binary_integer := l_from_unit_ids.count;
   l_loop_count    binary_integer := 100;
   l_converted     binary_double;
   l_ts            timestamp;
   l_elapsed_1     interval day to second;
   l_elapsed_2     interval day to second;
begin
   ----------------------------------------------------------------------------
   -- reset the cache and convert units, forcing record retrieval from table --
   ----------------------------------------------------------------------------
   l_results := cwms_t_double_tab();
   l_results.extend(l_from_unit_ids.count);
   cwms_cache.clear(cwms_util.g_unit_conversion_info_cache);
   for i in 1..l_val_count loop
      l_results(i) := cwms_util.convert_units(1.0, l_from_unit_ids(i), l_to_unit_ids(i));
   end loop;
   ----------------------------------------------------------------------------------------------
   -- all conversions are now cached, so verify conversions and get the cached conversion time --
   ----------------------------------------------------------------------------------------------
   for i in 1..l_val_count loop
      l_converted := cwms_util.convert_units(1.0, l_from_unit_ids(i), l_to_unit_ids(i));
      ut.expect(l_converted).to_equal(l_results(i));
   end loop;
   l_ts := systimestamp;
   for i in 1..l_loop_count loop
      for j in 1..l_val_count loop
         l_converted := cwms_util.convert_units(1.0, l_from_unit_ids(j), l_to_unit_ids(j));
      end loop;
   end loop;
   l_elapsed_1 := systimestamp - l_ts;
   ------------------------------------------
   -- now get the uncached conversion time --
   ------------------------------------------
   cwms_cache.disable(cwms_util.g_unit_conversion_info_cache);
   l_ts := systimestamp;
   for i in 1..l_loop_count loop
      for j in 1..l_val_count loop
         l_converted := cwms_util.convert_units(1.0, l_from_unit_ids(j), l_to_unit_ids(j));
      end loop;
   end loop;
   l_elapsed_2 := systimestamp - l_ts;
   cwms_cache.enable(cwms_util.g_unit_conversion_info_cache);

   ut.expect(l_elapsed_2).to_be_greater_than(l_elapsed_1);

end cwdb_255_cache_unit_conversion_factors_and_formulas_in_convert_units;

procedure test_to_timestamp_null_timestamp
is
    l_null_timestamp timestamp;
begin
    l_null_timestamp := cwms_util.to_timestamp(p_millis => null);
    ut.expect(l_null_timestamp).to_be_null();
end test_to_timestamp_null_timestamp;
---------------------------------------
-- procedure test_runstats --
---------------------------------------
-- not really a part of CWMS_UTIL, but I didn't want to create another test package just for this
procedure test_runstats
is
   type qcode_tab_t is table of cwms_data_quality%rowtype;
   l_tab1           qcode_tab_t;
   l_tab2           qcode_tab_t;
   l_gets           cwms_t_number_tab := cwms_t_number_tab(null, null);
   l_reads          cwms_t_number_tab := cwms_t_number_tab(null, null);
   l_times          cwms_t_number_tab := cwms_t_number_tab(null, null);
   l_names          cwms_t_str_tab;
   l_expected_names cwms_t_str_tab := cwms_t_str_tab(
      'recursive calls',
      'db block gets',
      'consistent gets',
      'physical reads',
      'redo size',
      'SQL*Net roundtrips to/from client',
      'sorts (memory)',
      'sorts (disk)',
      'sorts (rows)');
begin
   runstats.at_start(1);
   runstats.at_pause(1);
   runstats.at_start(2);
   runstats.at_resume(1);
   select * bulk collect into l_tab1 from cwms_data_quality;
   runstats.at_pause(1);
   runstats.at_stop('Trace 1/2', 2);

   l_gets(2)  := runstats.at_get_value(2, 'consistent gets');
   l_reads(2) := runstats.at_get_value(2, 'physical reads');
   l_times(2) := runstats.at_get_value(2, 'elapsed time');

   runstats.at_start(2);
   runstats.at_resume(1);
   select * bulk collect into l_tab2 from cwms_data_quality where protection_id = 'PROTECTED';
   runstats.at_stop('Trace 2/2', 2);
   runstats.at_stop('Resumed', 1);

   l_gets(1)  := runstats.at_get_value(1, 'consistent gets');
   l_reads(1) := runstats.at_get_value(1, 'physical reads');
   l_times(1) := runstats.at_get_value(1, 'elapsed time');

   l_gets(2)  := l_gets(2) + runstats.at_get_value(2, 'consistent gets');
   l_reads(2) := l_reads(2) + runstats.at_get_value(2, 'physical reads');
   l_times(2) := l_times(2) + runstats.at_get_value(2, 'elapsed time');

   l_names := runstats.at_get_names(1);
   ut.expect(l_names.count).to_equal(9);
   if l_names.count = 9 then
      for i in 1..l_names.count loop
         ut.expect(l_names(i)).to_equal(l_expected_names(i));
      end loop;
   end if;

   dbms_output.put_line('GETS  : 1='||l_gets(1)||chr(9) ||', 2='||l_gets(2)||chr(9) ||', Ratio='||case when l_gets(2) = 0 then '???' else to_char(round(l_gets(1)/l_gets(2), 2)) end);
   dbms_output.put_line('READS : 1='||l_reads(1)||chr(9)||', 2='||l_reads(2)||chr(9)||', Ratio='||case when l_reads(2) = 0 then '???' else to_char(round(l_reads(1)/l_reads(2), 2)) end);
   dbms_output.put_line('TIMES : 1='||l_times(1)||chr(9)||', 2='||l_times(2)||chr(9)||', Ratio='||case when l_times(2) = 0 then '???' else to_char(round(l_times(1)/l_times(2), 2)) end);

   if l_gets(2) > 0 then
      ut.expect(round(l_gets(1)/l_gets(2), 1)).to_equal(1);
   end if;
   if l_reads(2) > 0 then
      ut.expect(round(l_reads(1)/l_reads(2), 1)).to_equal(1);
   end if;
   if l_times(2) > 0 then
      ut.expect(round(l_times(1)/l_times(2), 1)).to_equal(1);
   end if;
end test_runstats;
end test_cwms_util;
/

grant execute on test_cwms_util to cwms_user;

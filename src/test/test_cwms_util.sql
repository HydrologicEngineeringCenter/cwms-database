create or replace package test_cwms_util as

--%suite(Test cwms_util package code)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test split_text {/no regex/split all/default delimiter})
procedure split_text_no_regex_split_all_default_delimiter;
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
   dbms_lob.createtemporary(test_data_clob, true);
   for i in 1..999999 loop
      l_line := 'line_'||i||'_space line_'||i||'_tab'||chr(9)||'line_'||i||'_newline'||chr(10);
      exit when length(test_data_varchar) + length(l_line) > 32766;
      test_data_varchar := test_data_varchar||chr(10)||l_line;
      len_data_varchar  := len_data_varchar + 2;
      cwms_util.append(test_data_clob, chr(10)||l_line);
      len_data_clob := len_data_clob + 2;
   end loop;
   dbms_output.put_line(l_line);
   cwms_util.append(test_data_clob, chr(10)||l_line);
   len_data_clob := len_data_clob + 2;
   dbms_output.put_line(len_data_varchar);
   dbms_output.put_line(len_data_clob);
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
begin
   ----------------------------
   -- first the varchar data --
   ----------------------------
   l_parts := cwms_util.split_text(test_data_varchar);
   l_expected_count := (len_data_varchar-1)/2 * 3 + 2; -- add 2 instead of 1 b/c data starts with delimiter 
   ut.expect(l_parts.count).to_equal(l_expected_count);
   for i in 1..5 loop
      l_idx := trunc(dbms_random.value(2, len_data_varchar/2));
      dbms_output.put_line(l_idx);
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
   for i in 1..5 loop
      l_idx := trunc(dbms_random.value(2, len_data_clob/2));
      dbms_output.put_line(l_idx);
      ut.expect(l_parts((l_idx - 1) * 3 + 2)).to_equal('line_'||l_idx||'_space');
      ut.expect(l_parts((l_idx - 1) * 3 + 3)).to_equal('line_'||l_idx||'_tab');
      ut.expect(l_parts((l_idx - 1) * 3 + 4)).to_equal('line_'||l_idx||'_newline');
   end loop;
end split_text_no_regex_split_all_default_delimiter;


end test_cwms_util;
/

grant execute on test_cwms_util to cwms_user;

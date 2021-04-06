create or replace package test_cwms_rating
as
--%suite(Test cwms_rating package code)
--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Ratings XSL Transformations)
procedure test_ratings_xsl;
procedure setup;
procedure teardown;
procedure setup_xslt;
procedure teardown_xslt;
procedure teardown_xslt2;

inspect_after_test constant boolean := false;
end test_cwms_rating;
/
show errors

create or replace package body test_cwms_rating
as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   setup_xslt;
   commit;
end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
begin
   teardown_xslt2;
   commit;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup_xslt
--------------------------------------------------------------------------------
procedure setup_xslt
is
begin
   teardown_xslt;
end setup_xslt;
--------------------------------------------------------------------------------
-- procedure teardown_xslt
--------------------------------------------------------------------------------
procedure teardown_xslt
is
begin
   if not inspect_after_test then
      delete from at_clob where id like '/XSLT\_TEST/RESULT\_%' escape '\';
   end if;   
end teardown_xslt;
--------------------------------------------------------------------------------
-- procedure teardown_xslt2
--------------------------------------------------------------------------------
procedure teardown_xslt2
is
begin
   if not inspect_after_test then
      delete from at_clob where id like '/XSLT\_TEST/%' escape '\';
   end if;   
end teardown_xslt2;
--------------------------------------------------------------------------------
-- procedure test_ratings_xsl
--------------------------------------------------------------------------------
procedure test_ratings_xsl
is
   l_rating          clob;
   l_transform       clob;
   l_output          clob;
   l_errors          clob;
   l_transformed     xmltype;
   l_json            json_object_t;
   l_rating_ids      str_tab_t;
   l_transform_ids   str_tab_t;
   l_rating_specs    str_tab_t;
   l_transform_type  varchar2(16);
   l_clob_code       at_clob.clob_code%type;
   exc_null_object   exception;
   pragma exception_init(exc_null_object, -30625);
begin
   ----------------------------------------------------------------------
   -- make sure we have the number of ratings and transforms we expect --
   ----------------------------------------------------------------------
   select id bulk collect into l_rating_ids from at_clob where regexp_like(id, '/XSLT_TEST/TEST_\d') order by 1;
   ut.expect(l_rating_ids.count).to_equal(6);
   select id bulk collect into l_transform_ids from at_clob where id like '/XSLT/%' order by 1;
   ut.expect(l_transform_ids.count).to_equal(3);
   ---------------------------------------------------
   -- update the rating clobs to the current office --
   ---------------------------------------------------
   update at_clob
      set value = replace(value, 'office-id="XXX"', 'office-id="&&office_id"')
   where id in (select column_value from table(l_rating_ids));
   commit;
   ----------------------------------
   -- test the raw XSLT operations --
   ----------------------------------
   for i in 1..l_rating_ids.count loop
      l_rating := cwms_text.retrieve_text(l_rating_ids(i), '&&office_id');
      for j in 1..l_transform_ids.count loop
         l_transform_type := cwms_util.split_text(l_transform_ids(j), 5, '_');
         l_transform := cwms_text.retrieve_text(l_transform_ids(j), '&&office_id');
         l_transformed := xmltype(l_rating).transform(xmltype(l_transform)); -- will barf if l_rating, l_transform, or l_transformed is not valid XML
         if l_transform_type = 'XML' then
            l_output := l_transformed.getclobval;
         else
            begin
               l_output := l_transformed.extract('/ratings/text()').getclobval;
            exception
               when exc_null_object then
                  if l_transform_type = 'JSON' then
                     l_output := '{"ratings":{"rating-templates":[],"rating-specs":[],"ratings":[]}}';
                  else
                     l_output := chr(10)||chr(10);
                  end if;
            end;
            l_output := dbms_xmlgen.convert(l_output, dbms_xmlgen.entity_decode);
            if l_transform_type = 'JSON' then
               l_output := regexp_replace(l_output, '([[{]),', '\1');
               l_output := replace(l_output, '[,', '[');
               l_output := replace(l_output, '""', 'null');
               l_json   := json_object_t(l_output); -- will barf if l_output is not valid JSON
            end if;
         end if;
         l_clob_code := cwms_text.store_text(
            p_text           => l_output,
            p_id             => '/XSLT_TEST/RESULT_'||i||'_'||l_transform_type,
            p_description    => null,
            p_fail_if_exists => 'F',
            p_office_id      => '&&office_id');
      end loop;
   end loop;
   commit;
   -------------------------------------------------------------------------
   -- get the rating specs for the test rating clobs and store as ratings --
   -------------------------------------------------------------------------
   l_rating_specs := str_tab_t();
   l_rating_specs.extend(l_rating_ids.count);
   for i in 1..l_rating_ids.count loop
      l_rating_specs(i) := regexp_substr(cwms_text.retrieve_text(l_rating_ids(i), '&&office_id'), '<rating-spec-id>(.+?)</rating-spec-id>', 1, 1, 'c', 1);
      cwms_rating.store_ratings_xml(
         p_errors         => l_errors,
         p_xml            => cwms_text.retrieve_text(l_rating_ids(i), '&&office_id'),
         p_fail_if_exists => 'F',
         p_replace_base   => 'T');
      if l_errors is not null then
         for rec in (select column_value as line from table(cwms_util.split_text(l_errors, chr(10)))) loop
            dbms_output.put_line('===> '||rec.line);
         end loop;
      end if;
   end loop;
   -------------------------------------------------
   -- compare RADAR outputs with raw XSLT outputs --
   -------------------------------------------------
   for i in 1..l_rating_specs.count loop
      for rec in (select column_value as transform_type from table(str_tab_t('JSON', 'TAB', 'XML'))) loop
         l_output := cwms_rating.retrieve_ratings_f(
            p_names     => nvl(l_rating_specs(i), l_rating_specs(2)||'x'), -- force non-existing rating instead of catalog for null
            p_format    => rec.transform_type,
            p_units     => 'EN',
            p_datums    => 'NATIVE',
            p_start     => null,
            p_end       => null,
            p_timezone  => null,
            p_office_id => '&&office_id');
         l_clob_code := cwms_text.store_text(
            p_text           => l_output,
            p_id             => '/XSLT_TEST/COMPARISON_'||i||'_'||rec.transform_type,
            p_description    => null,
            p_fail_if_exists => 'F',
            p_office_id      => '&&office_id');
         case rec.transform_type
         when 'JSON' then l_output := regexp_replace(l_output, '"query-info".+"unique-ratings-retrieved":\d+},', null);
         when 'TAB'  then l_output := regexp_replace(l_output, '#Processed At.+#Unique Ratings Retrieved\s+\d+\s', null, 1, 1, 'n');
         when 'XML'  then l_output := regexp_replace(regexp_replace(l_output, '<query-info>.+</query-info>', null), '<\?xml.+?\?>', null);
         end case;
         l_rating := cwms_text.retrieve_text('/XSLT_TEST/RESULT_'||i||'_'||rec.transform_type, '&&office_id');
         if regexp_instr(l_rating, '^<ratings[^<]+/>$') = 1 then -- transform <ratings .../> the same way that the RADAR routine does in order to include the query info
            l_rating := '<ratings></ratings>';
         end if;
         ut.expect(l_output).to_equal(regexp_replace(regexp_replace(l_rating, ' xmlns:xsi[^>]+>', '>'), '>\s+', '>'));
      end loop;
   end loop;
   commit;
end test_ratings_xsl;

end test_cwms_rating;
/
show errors

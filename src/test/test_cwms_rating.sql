create or replace package test_cwms_rating
as
--%suite(Test cwms_rating package code)
--%rollback(manual)

--%test(Ratings XSL Transformations)
procedure test_ratings_xsl;
end test_cwms_rating;
/
create or replace package body test_cwms_rating
as
procedure test_ratings_xsl
is
   l_rating          clob;
   l_transform       clob;
   l_output          clob;
   l_rating_names    str_tab_t;
   l_transform_names str_tab_t;
   l_transform_type  varchar2(16);
   l_clob_code       at_clob.clob_code%type;
begin
   select id bulk collect into l_rating_names from at_clob where regexp_like(id, '/XSLT_TEST/TEST_\d') order by 1;
   ut.expect(l_rating_names.count).to_equal(6);
   select id bulk collect into l_transform_names from at_clob where id like '/XSLT/%' order by 1;
   ut.expect(l_transform_names.count).to_equal(3);
   for i in 1..l_rating_names.count loop
      l_rating := cwms_text.retrieve_text(l_rating_names(i), '&&office_id');
      for j in 1..l_transform_names.count loop
         l_transform_type := cwms_util.split_text(l_transform_names(j), 5, '_');
         l_transform := cwms_text.retrieve_text(l_transform_names(j), '&&office_id');
         dbms_output.put_line('rating '||i||', transform '||j);
         l_output := xmltype(l_rating).transform(xmltype(l_transform)).getclobval;
         l_clob_code := cwms_text.store_text(
            p_text           => l_output,
            p_id             => '/XSLT_TEST/RESULT_'||i||'_'||l_transform_type,
            p_description    => null,
            p_fail_if_exists => 'F',
            p_office_id      => '&&office_id');
      end loop;
   end loop;
   commit;
end test_ratings_xsl;

end test_cwms_rating;
/
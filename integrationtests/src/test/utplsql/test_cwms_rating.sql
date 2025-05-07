create or replace package test_cwms_rating
as
--%suite(Test cwms_rating package code)
--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

procedure setup;
procedure teardown;
procedure setup_xslt;
procedure teardown_xslt;
procedure teardown_xslt2;

--[don't run]%test(Ratings XSL Transformations)
procedure test_ratings_xsl;
--[don't run]%test(Test Deleting of ratings)
procedure test_ratings_delete;
--%test(Test retrieving usgs-stream-rating object that no shift points)
procedure test_retrieve_usgs_rating_without_shift_points;
--%test(Test expression rating)
procedure test_expression_rating;
--%test(Test table rating)
procedure test_table_rating;

c_location_id        constant varchar2(57) := 'Test_Ratings_Loc';
c_inspect_after_test constant boolean := false;
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
   location_id_not_found exception;
   pragma exception_init(location_id_not_found, -20025);
begin
   teardown_xslt2;
   begin
      cwms_loc.delete_location(c_location_id, cwms_util.delete_all, '&&office_id');
   exception
      when location_id_not_found then null;
   end;
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
   if not c_inspect_after_test then
      delete from at_clob where id like '/XSLT\_TEST/RESULT\_%' escape '\';
      delete from at_clob where id like '/XSLT\_TEST/COMPARISON\_%' escape '\';
   end if;
end teardown_xslt;
--------------------------------------------------------------------------------
-- procedure teardown_xslt2
--------------------------------------------------------------------------------
procedure teardown_xslt2
is
begin
   if not c_inspect_after_test then
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
   cwms_properties.set_property('CWMS-RADAR', 'query.max-time', '00 00:01:00','TESTing default', 'CWMS');
   ----------------------------------------------------------------------
   -- make sure we have the number of ratings and transforms we expect --
   ----------------------------------------------------------------------
   select id bulk collect into l_rating_ids from at_clob where regexp_like(id, '/XSLT_TEST/RATING_\d') order by 1;
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
   --------------------------------------------------------------------
   -- get the rating specs for the rating clobs and store as ratings --
   --------------------------------------------------------------------
   l_rating_specs := str_tab_t();
   l_rating_specs.extend(l_rating_ids.count);
   for i in 2..l_rating_ids.count loop -- skip empty rating at position 1
      l_rating_specs(i) := regexp_substr(cwms_text.retrieve_text(l_rating_ids(i), '&&office_id'), '<rating-spec-id>(.+?)</rating-spec-id>', 1, 1, 'c', 1);
      cwms_rating.store_ratings_xml(
         p_errors         => l_errors,
         p_xml            => cwms_text.retrieve_text(l_rating_ids(i), '&&office_id'),
         p_fail_if_exists => 'F',
         p_replace_base   => 'T');
      commit;
      if l_errors is not null then
         for rec in (select column_value as line from table(cwms_util.split_text(l_errors, chr(10)))) loop
            dbms_output.put_line('===> '||rec.line);
         end loop;
         cwms_err.raise('ERROR', substr(l_errors, 1, 4000));
      end if;
   end loop;
   ---------------------------------------------------
   -- re-store rating clobs withtout source ratings --
   ---------------------------------------------------
   for i in 1..l_rating_ids.count loop
      if i = 1 then
         l_rating := cwms_text.retrieve_text('/XSLT_TEST/RATING_1', '&&office_id');
      else
         l_rating := cwms_rating.retrieve_ratings_xml2_f(l_rating_specs(i), null, null, null, '&&office_id');
         l_rating := regexp_replace(l_rating, '<\?xml.+?\?>\s*', null);
      end if;
      l_clob_code := cwms_text.store_text(
         p_text           => l_rating,
         p_id             => '/XSLT_TEST/TEST_'||i,
         p_description    => null,
         p_fail_if_exists => 'F',
         p_office_id      => '&&office_id');
   end loop;
   ----------------------------------
   -- test the raw XSLT operations --
   ----------------------------------
   for i in 1..l_rating_ids.count loop
      l_rating := cwms_text.retrieve_text(replace(l_rating_ids(i), '/RATING_', '/TEST_'), '&&office_id');
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
--------------------------------------------------------------------------------
-- procedure test_ratings_delete
--------------------------------------------------------------------------------
procedure test_ratings_delete
is
 l_count NUMBER;
begin
 select count(*) into l_count from cwms_v_rating;
 ut.expect(l_count).to_be_greater_than(0);
 CWMS_RATING.DELETE_TEMPLATES('*', cwms_util.delete_all, '*');
 select count(*) into l_count from cwms_v_rating;
 ut.expect(l_count).to_equal(0);
end;
--------------------------------------------------------------------------------
-- procedure test_expression_rating
--------------------------------------------------------------------------------
procedure test_expression_rating
is
   l_result        binary_double;
   l_results       cwms_t_double_tab;
   l_rating_spec   cwms_v_rating.rating_id%type;
   l_errors        clob;
   l_pool_elev     cwms_t_double_tab := cwms_t_double_tab(516.47,516.41,516.33,516.30,516.26,516.24,516.21,516.17,516.13,516.22,516.26,516.25,516.28,516.30,516.29,516.31,516.3,516.29,516.29,516.29,516.28,516.3,516.30);
   l_tail_elev     cwms_t_double_tab := cwms_t_double_tab(512.35,512.39,512.37,512.39,512.43,512.42,512.36,512.35,512.46,512.16,512.17,512.13,512.16,512.20,512.19,512.19,512.2,512.09,512.17,512.11,512.09,512.1,512.12);
   l_expected_flow cwms_t_double_tab := cwms_t_double_tab(3786,3718,3662,3628,3577,3566,3569,3541,3457,3669,3697,3707,3717,3716,3712,3728,3716,3757,3721,3748,3749,3761,3752); -- computed with rating formula in Excel
   l_xml           varchar2(32767) := '
<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
  <rating-template office-id="&&office_id">
    <parameters-id>Elev-Pool,Elev-Tailwater;Flow</parameters-id>
    <version>Standard</version>
    <ind-parameter-specs>
      <ind-parameter-spec position="1">
        <parameter>Elev-Pool</parameter>
        <in-range-method>LINEAR</in-range-method>
        <out-range-low-method>NEAREST</out-range-low-method>
        <out-range-high-method>NEAREST</out-range-high-method>
      </ind-parameter-spec>
      <ind-parameter-spec position="2">
        <parameter>Elev-Tailwater</parameter>
        <in-range-method>LINEAR</in-range-method>
        <out-range-low-method>NEAREST</out-range-low-method>
        <out-range-high-method>NEAREST</out-range-high-method>
      </ind-parameter-spec>
    </ind-parameter-specs>
    <dep-parameter>Flow</dep-parameter>
    <description/>
  </rating-template>
  <rating-spec office-id="&&office_id">
    <rating-spec-id>$location-id.Elev-Pool,Elev-Tailwater;Flow.Standard.Production</rating-spec-id>
    <template-id>Elev-Pool,Elev-Tailwater;Flow.Standard</template-id>
    <location-id>$location-id</location-id>
    <version>Production</version>
    <source-agency/>
    <in-range-method>LINEAR</in-range-method>
    <out-range-low-method>NEAREST</out-range-low-method>
    <out-range-high-method>NEAREST</out-range-high-method>
    <active>true</active>
    <auto-update>true</auto-update>
    <auto-activate>true</auto-activate>
    <auto-migrate-extension>true</auto-migrate-extension>
    <ind-rounding-specs>
      <ind-rounding-spec position="1">4444444444</ind-rounding-spec>
      <ind-rounding-spec position="2">4444444444</ind-rounding-spec>
    </ind-rounding-specs>
    <dep-rounding-spec>4444444444</dep-rounding-spec>
    <description>$location-id elevation-discharge rates $location-id - Gate</description>
  </rating-spec>
  <simple-rating office-id="&&office_id">
    <rating-spec-id>$location-id.Elev-Pool,Elev-Tailwater;Flow.Standard.Production</rating-spec-id>
    <units-id>ft,ft;cfs</units-id>
    <effective-date>2018-05-24T09:22:00-05:00</effective-date>
    <create-date>1969-12-31T18:00:00-06:00</create-date>
    <active>true</active>
    <description>$location-id elevation-discharge rates $location-id - Gate</description>
    <formula>0.37*60*(i1-506)*sqrt(2*32.2*(i1-i2))</formula>
  </simple-rating>
</ratings>
';
begin
   ------------------------
   -- store the location --
   ------------------------
   cwms_loc.store_location(
      p_location_id  => c_location_id,
      p_db_office_id => '&&office_id');
   ----------------------
   -- store the rating --
   ----------------------
   l_xml := replace(l_xml, '$location-id', c_location_id);
   cwms_rating.store_ratings_xml(
      p_errors         => l_errors,
      p_xml            =>l_xml,
      p_fail_if_exists => 'F',
      p_replace_base   => 'T');

   ut.expect(l_errors).to_be_null;
   ------------------------------
   -- rate one input value set --
   ------------------------------
   l_rating_spec := regexp_substr(l_xml, '<rating-spec-id>(.+?)</rating-spec-id>', 1, 1, 'i', 1);
   l_result := cwms_rating.rate_one_f(
      p_rating_spec => l_rating_spec,
      p_values      => cwms_t_double_tab(516.3, 512.2),
      p_units       => cwms_t_str_tab('ft', 'ft', 'cfs'),
      p_round       => 'T',
      p_office_id   => '&&office_id');

   ut.expect(l_result).to_equal(3716);
   ------------------------------------
   -- rate multiple input value sets --
   ------------------------------------
   l_results := cwms_rating.rate_f(
      p_rating_spec => l_rating_spec,
      p_values      => cwms_t_double_tab_tab(l_pool_elev, l_tail_elev),
      p_units       => cwms_t_str_tab('ft', 'ft', 'cfs'),
      p_round       => 'T',
      p_office_id   => '&&office_id');

   ut.expect(l_results.count).to_equal(l_expected_flow.count);
   for i in 1..l_results.count loop
      ut.expect(l_results(i)).to_equal(l_expected_flow(i));
   end loop;
end test_expression_rating;
--------------------------------------------------------------------------------
-- procedure test_retrieve_usgs_rating_without_shift_points
--------------------------------------------------------------------------------
procedure test_retrieve_usgs_rating_without_shift_points
is
   l_rating_spec      cwms_v_rating.rating_id%type;
   l_rating_spec_code cwms_v_rating.rating_code%type;
   l_errors           clob;
   l_xml              varchar2(32767) := '
<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
  <rating-template office-id="&&office_id">
    <parameters-id>Stage;Flow</parameters-id>
    <version>Logarithmic</version>
    <ind-parameter-specs>
      <ind-parameter-spec position="1">
        <parameter>Stage</parameter>
        <in-range-method>LOGARITHMIC</in-range-method>
        <out-range-low-method>NULL</out-range-low-method>
        <out-range-high-method>NULL</out-range-high-method>
      </ind-parameter-spec>
    </ind-parameter-specs>
    <dep-parameter>Flow</dep-parameter>
    <description>Stream Rating (Base + Shifts and Offsets)</description>
  </rating-template>
  <rating-spec office-id="&&office_id">
    <rating-spec-id>$location-id.Stage;Flow.Logarithmic.USGS-NWIS</rating-spec-id>
    <template-id>Stage;Flow.Logarithmic</template-id>
    <location-id>$location-id</location-id>
    <version>USGS-NWIS</version>
    <source-agency/>
    <in-range-method>PREVIOUS</in-range-method>
    <out-range-low-method>NEAREST</out-range-low-method>
    <out-range-high-method>PREVIOUS</out-range-high-method>
    <active>true</active>
    <auto-update>true</auto-update>
    <auto-activate>true</auto-activate>
    <auto-migrate-extension>true</auto-migrate-extension>
    <ind-rounding-specs>
      <ind-rounding-spec position="1">2223456782</ind-rounding-spec>
    </ind-rounding-specs>
    <dep-rounding-spec>2222233332</dep-rounding-spec>
    <description>Arkansas River at Tulsa, OK USGS-NWIS Stream Rating (Base + Shifts and Offsets)</description>
  </rating-spec>
  <usgs-stream-rating office-id="&&office_id">
    <rating-spec-id>$location-id.Stage;Flow.Logarithmic.USGS-NWIS</rating-spec-id>
    <units-id>ft;cfs</units-id>
    <effective-date>2014-01-15T12:00:00-06:00</effective-date>
    <create-date>2015-11-06T11:28:36-06:00</create-date>
    <active>true</active>
    <description>20.0</description>
    <height-shifts>
      <effective-date>2015-03-05T11:35:00-06:00</effective-date>
      <create-date>2015-11-06T11:28:36-06:00</create-date>
      <active>true</active>
      <point><ind>.9</ind><dep>.09</dep></point>
      <point><ind>2</ind><dep>0</dep></point>
      <point><ind>8</ind><dep>0</dep></point>
    </height-shifts>
    <height-offsets>
      <point><ind>14.499</ind><dep>0</dep></point>
      <point><ind>14.5</ind><dep>7</dep></point>
    </height-offsets>
    <rating-points>
      <point><ind>.03</ind><dep>0</dep></point>
      <point><ind>.04</ind><dep>.02</dep></point>
      <point><ind>.1</ind><dep>.26</dep></point>
      <point><ind>.2</ind><dep>1.92</dep></point>
      <point><ind>.5</ind><dep>26.6</dep></point>
      <point><ind>.95</ind><dep>168</dep></point>
      <point><ind>3</ind><dep>4640</dep></point>
      <point><ind>3.1</ind><dep>5100</dep></point>
      <point><ind>3.2</ind><dep>5560</dep></point>
      <point><ind>3.3</ind><dep>6020</dep></point>
      <point><ind>3.4</ind><dep>6480</dep></point>
      <point><ind>3.5</ind><dep>6940</dep></point>
      <point><ind>3.6</ind><dep>7400</dep></point>
      <point><ind>3.7</ind><dep>7860</dep></point>
      <point><ind>3.8</ind><dep>8320</dep></point>
      <point><ind>3.9</ind><dep>8780</dep></point>
      <point><ind>4</ind><dep>9240</dep></point>
      <point><ind>4.2</ind><dep>10170</dep></point>
      <point><ind>5.46</ind><dep>16700</dep></point>
      <point><ind>6</ind><dep>19900</dep></point>
      <point><ind>6.1</ind><dep>20520</dep></point>
      <point><ind>6.2</ind><dep>21140</dep></point>
      <point><ind>6.3</ind><dep>21760</dep></point>
      <point><ind>6.4</ind><dep>22390</dep></point>
      <point><ind>6.5</ind><dep>23020</dep></point>
      <point><ind>9.19</ind><dep>42300</dep></point>
      <point><ind>11.91</ind><dep>66600</dep></point>
      <point><ind>13.5</ind><dep>83500</dep></point>
      <point><ind>14.5</ind><dep>96400</dep></point>
      <point><ind>14.6</ind><dep>97960</dep></point>
      <point><ind>14.7</ind><dep>99530</dep></point>
      <point><ind>14.8</ind><dep>101110</dep></point>
      <point><ind>14.9</ind><dep>102680</dep></point>
      <point><ind>15</ind><dep>104300</dep></point>
      <point><ind>16</ind><dep>121300</dep></point>
      <point><ind>18</ind><dep>157400</dep></point>
      <point><ind>20</ind><dep>195400</dep></point>
      <point><ind>23</ind><dep>255800</dep></point>
      <point><ind>26</ind><dep>319600</dep></point>
    </rating-points>
  </usgs-stream-rating>
</ratings>';
begin
   ------------------------
   -- store the location --
   ------------------------
   cwms_loc.store_location(
      p_location_id  => c_location_id,
      p_db_office_id => '&&office_id');
   ----------------------
   -- store the rating --
   ----------------------
   l_xml := replace(l_xml, '$location-id', c_location_id);
   cwms_rating.store_ratings_xml(
      p_errors         => l_errors,
      p_xml            =>l_xml,
      p_fail_if_exists => 'F',
      p_replace_base   => 'T');

   ut.expect(l_errors).to_be_null;
   -------------------------------------------------
   -- delete the shift points, but not the shifts --
   -------------------------------------------------
   l_rating_spec := regexp_substr(l_xml, '<rating-spec-id>(.+?)</rating-spec-id>', 1, 1, 'i', 1);
   select rating_spec_code
     into l_rating_spec_code
     from av_rating_spec
    where rating_id = l_rating_spec
      and office_id = '&&office_id';

   for rec1 in (select rating_code from at_rating where rating_spec_code = l_rating_spec_code) loop
      for rec2 in (select rating_code from at_rating where ref_rating_code = rec1.rating_code) loop
         select rating_id into l_rating_spec from av_rating where rating_code = rec2.rating_code;
         if instr(l_rating_spec, 'Stage-Shift') > 0 then
            delete from at_rating_value where rating_ind_param_code in (select rating_ind_param_code from at_rating_ind_parameter where rating_code = rec2.rating_code);
            delete from at_rating_ind_parameter where rating_code = rec2.rating_code;
         end if;
      end loop;
   end loop;
   -----------------------------------
   -- retreieve the modified rating --
   -----------------------------------
   l_xml := cwms_rating.retrieve_ratings_xml3_f(l_rating_spec, null, null, null, '&&office_id');
   -- if no exception then the test passed
end test_retrieve_usgs_rating_without_shift_points;

--------------------------------------------------------------------------------
-- procedure test_table_rating
--------------------------------------------------------------------------------
procedure test_table_rating
is
    l_result        binary_double;
    l_results       cwms_t_double_tab;
    l_rating_spec   cwms_v_rating.rating_id%type;
    l_errors        clob;
    l_pool_elev     cwms_t_double_tab := cwms_t_double_tab(392.0);
    l_expected_area cwms_t_double_tab := cwms_t_double_tab(12.0);
    l_xml           varchar2(32767) := '
        <ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
          <rating-template office-id="&&office_id">
            <parameters-id>Elev;Area</parameters-id>
            <version>Standard</version>
            <ind-parameter-specs>
              <ind-parameter-spec position="1">
                <parameter>Elev</parameter>
                <in-range-method>LINEAR</in-range-method>
                <out-range-low-method>NEXT</out-range-low-method>
                <out-range-high-method>PREVIOUS</out-range-high-method>
              </ind-parameter-spec>
            </ind-parameter-specs>
            <dep-parameter>Area</dep-parameter>
            <description>12</description>
          </rating-template>
          <rating-spec office-id="&&office_id">
            <rating-spec-id>$location-id.Elev;Area.Standard.Production</rating-spec-id>
            <template-id>Elev;Area.Standard</template-id>
            <location-id>$location-id</location-id>
            <version>Production</version>
            <source-agency/>
            <in-range-method>PREVIOUS</in-range-method>
            <out-range-low-method>NEAREST</out-range-low-method>
            <out-range-high-method>PREVIOUS</out-range-high-method>
            <active>true</active>
            <auto-update>true</auto-update>
            <auto-activate>true</auto-activate>
            <auto-migrate-extension>true</auto-migrate-extension>
            <ind-rounding-specs>
              <ind-rounding-spec position="1">4444444444</ind-rounding-spec>
            </ind-rounding-specs>
            <dep-rounding-spec>4444444444</dep-rounding-spec>
            <description></description>
          </rating-spec>
          <simple-rating office-id="&&office_id">
            <rating-spec-id>$location-id.Elev;Area.Standard.Production</rating-spec-id>
            <units-id>ft;acre</units-id>
            <effective-date>2017-09-26T20:06:00Z</effective-date>
            <transition-start-date>2017-09-24T20:06:00Z</transition-start-date>
            <create-date>2017-09-26T20:06:00Z</create-date>
            <active>true</active>
            <description/>
            <rating-points>
              <point><ind>370.0</ind><dep>0.0</dep></point>
              <point><ind>383.0</ind><dep>0.1</dep></point>
              <point><ind>387.0</ind><dep>1.0</dep></point>
              <point><ind>388.0</ind><dep>2.0</dep></point>
              <point><ind>389.0</ind><dep>4.0</dep></point>
              <point><ind>390.2</ind><dep>7.0</dep></point>
              <point><ind>391.0</ind><dep>10.0</dep></point>
              <point><ind>392.0</ind><dep>12.0</dep></point>
              <point><ind>393.0</ind><dep>14.0</dep></point>
              <point><ind>394.0</ind><dep>18.0</dep></point>
              <point><ind>395.0</ind><dep>20.0</dep></point>
              <point><ind>396.0</ind><dep>22.0</dep></point>
              <point><ind>397.0</ind><dep>25.0</dep></point>
              <point><ind>398.0</ind><dep>27.0</dep></point>
              <point><ind>399.0</ind><dep>29.0</dep></point>
            </rating-points>
          </simple-rating>
        </ratings>';
begin
    ------------------------
    -- store the location --
    ------------------------
    cwms_loc.store_location(
            p_location_id  => c_location_id,
            p_db_office_id => '&&office_id');
    ----------------------
    -- store the rating --
    ----------------------
    l_xml := replace(l_xml, '$location-id', c_location_id);
    cwms_rating.store_ratings_xml(
            p_errors         => l_errors,
            p_xml            =>l_xml,
            p_fail_if_exists => 'F',
            p_replace_base   => 'T');

    ut.expect(l_errors).to_be_null;
    ------------------------------
    -- rate one input value set --
    ------------------------------
    l_rating_spec := regexp_substr(l_xml, '<rating-spec-id>(.+?)</rating-spec-id>', 1, 1, 'i', 1);
    l_result := cwms_rating.rate_one_f(
            p_rating_spec => l_rating_spec,
            p_values      => cwms_t_double_tab(392.0),
            p_units       => cwms_t_str_tab('ft', 'acre'),
            p_round       => 'T',
            p_office_id   => '&&office_id');

    ut.expect(l_result).to_equal(12.0);

    l_result := cwms_rating.rate_one_f(
            p_rating_spec => l_rating_spec,
            p_values      => cwms_t_double_tab(392.0),
            p_units       => cwms_t_str_tab('ft', 'ft2'),
            p_round       => 'F',
            p_office_id   => '&&office_id');

    ut.expect(l_result).to_equal(12.0 * 43560);
end test_table_rating;

end test_cwms_rating;
/

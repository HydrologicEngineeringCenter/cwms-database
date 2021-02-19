create or replace package missing_shift_points as

--%suite(Test handling of usgs style stream ratings with shifts with missing points)
--%rollback(manual)
--%beforeall(setup)
--%afterall(teardown)
   
--%test(Retrieve usgs-stream-rating object that no shift points)
procedure run_test;
procedure setup;
procedure teardown;


c_office_id   constant varchar2(3)  := 'SWT';
c_rating_spec constant varchar2(37) := 'TULA.Stage;Flow.Logarithmic.USGS-NWIS';
c_rating_xml constant clob := '
   <ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
     <rating-template office-id="'||c_office_id||'">
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
     <rating-spec office-id="'||c_office_id||'">
       <rating-spec-id>'||c_rating_spec||'</rating-spec-id>
       <template-id>Stage;Flow.Logarithmic</template-id>
       <location-id>TULA</location-id>
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
     <usgs-stream-rating office-id="'||c_office_id||'">
       <rating-spec-id>'||c_rating_spec||'</rating-spec-id>
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

end missing_shift_points;
/

create or replace package body missing_shift_points as

procedure teardown
is
begin
   ------------------------------------
   -- delete the rating if it exists --
   ------------------------------------
   cwms_rating.delete_specs(
      p_spec_id_mask   => c_rating_spec,
      p_delete_action  => cwms_util.delete_all,
      p_office_id_mask => c_office_id);
   commit;   
end teardown;

procedure setup
is
   l_errors           clob;
   l_rating_spec_code integer;
   l_rating_spec      varchar2(612);
begin
   ----------------------
   -- store the rating --
   ----------------------
   cwms_rating.store_ratings_xml(
      p_errors         => l_errors,
      p_xml            => c_rating_xml,
      p_fail_if_exists => 'F',
      p_replace_base   => 'F');
   if l_errors is not null then
      cwms_err.raise('ERROR', substr(l_errors, 1, 4000));
   end if;
   -------------------------------------------------
   -- delete the shift points, but not the shifts --
   -------------------------------------------------
   select rating_spec_code
     into l_rating_spec_code
     from av_rating_spec
    where rating_id = c_rating_spec
      and office_id = c_office_id;
      
   for rec1 in (select rating_code from at_rating where rating_spec_code = l_rating_spec_code) loop
      for rec2 in (select rating_code from at_rating where ref_rating_code = rec1.rating_code) loop
         select rating_id into l_rating_spec from av_rating where rating_code = rec2.rating_code;
         if instr(l_rating_spec, 'Stage-Shift') > 0 then
            delete from at_rating_value where rating_ind_param_code in (select rating_ind_param_code from at_rating_ind_parameter where rating_code = rec2.rating_code);
            delete from at_rating_ind_parameter where rating_code = rec2.rating_code;
         end if;
      end loop;
   end loop;
   commit;
end setup;

procedure run_test
is
   l_rating_xml clob;
begin
   l_rating_xml := cwms_rating.retrieve_ratings_xml3_f(c_rating_spec, null, null, null, c_office_id);
end run_test;

end missing_shift_points;
/
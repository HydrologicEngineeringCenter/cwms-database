/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

create or replace package test_av_location_level_ref_values as
   --%suite(Test schema for av_location_level_ref and av_location_level_values views)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Test that the view shows the correct level identifier and values for a constant level)
   procedure constant_level;
   --%test(Test that the view shows the correct level identifier and values for a time series level)
   procedure ts_level;
   --%test(Test that the view shows the correct level identifier and values for a seasonal level)
   procedure seasonal_level;
   --%test(Test that the view shows the correct level identifier and values for virtual level)
   procedure virtual_level;

   procedure teardown;

   c_base_loc constant varchar2(11) := 'Murphysboro';
   c_sub_loc constant varchar2(9) := 'Big Muddy';
   c_loc constant varchar2(21) := 'Murphysboro-Big Muddy';
   c_office_id constant varchar2(3) := 'SPK';
   c_timezone_id constant varchar2(3) := 'UTC';
   c_ts_level_id constant varchar2(44) := 'Murphysboro-Big Muddy.Elev.Inst.0.Top of Dam';
   c_ts_id constant varchar2(49) := 'Murphysboro-Big Muddy.Elev.Inst.1Day.0.Top of Dam';
   c_ts_date constant date := DATE '2025-07-22';
   c_seasonal_id constant varchar2(48) := 'Murphysboro-Big Muddy.Stage.Inst.0.Bottom of Dam';
   c_seasonal_date constant date := DATE '2025-10-25';
   c_constant_id constant varchar2(49) := 'Murphysboro-Big Muddy.Elev.Inst.0.Top of Spillway';
   c_constant_date constant date := DATE '2025-04-10';
   c_constant_value constant number := 123.4;
   c_virtual_id constant varchar2(50) := 'Murphysboro-Big Muddy.Stage.Inst.0.Top of Spillway';
   c_virtual_date constant date := DATE '2025-07-15';
   c_connections constant varchar2(7) := 'L1=R1I1';
   c_expiration_date constant date := DATE '2026-07-22';
   c_elev_param constant varchar2(4) := 'Elev';
   c_stage_param constant varchar2(5) := 'Stage';
   c_inst_param constant varchar2(4) := 'Inst';
   c_0_duration constant varchar2(1) := '0';
   c_day_duration constant varchar2(4) := '1Day';
   c_top_of_dam constant varchar2(10) := 'Top of Dam';
   c_top_of_spillway constant varchar2(15) := 'Top of Spillway';
   c_bottom_of_dam constant varchar2(13) := 'Bottom of Dam';
   c_virtual constant varchar2(15) := 'Top of Spillway';
   c_rating_id constant varchar2(48) := 'Murphysboro-Big Muddy.Stage;Flow.COE.Production';

   l_virt_const   str_tab_tab_t
      := str_tab_tab_t(
      str_tab_t('L1', 'LOCATION_LEVEL', c_seasonal_id),
      str_tab_t('R1', 'RATING', c_rating_id)
   );

   l_ts_data     cwms_t_ztsv_array
      := cwms_t_ztsv_array (
      cwms_t_ztsv (c_ts_date, 1, 0),
      cwms_t_ztsv (c_ts_date + 1, 2, 0),
      cwms_t_ztsv (c_ts_date + 2, 3, 0),
      cwms_t_ztsv (c_ts_date + 3, 2.5, 0),
      cwms_t_ztsv (c_ts_date + 4, 3, 0),
      cwms_t_ztsv (c_ts_date + 5, 4.5, 0),
      cwms_t_ztsv (c_ts_date + 6, 3.5, 0),
      cwms_t_ztsv (c_ts_date + 7, 5, 0)
   );
   l_seasonal_data seasonal_value_tab_t
      := seasonal_value_tab_t (
      seasonal_value_t (0, 0, 128.4),
      seasonal_value_t (1, 0, 130.6),
      seasonal_value_t (2, 0, 145.7),
      seasonal_value_t (3, 0, 127.9),
      seasonal_value_t (4, 0, 115.9),
      seasonal_value_t (5, 0, 110.3),
      seasonal_value_t (6, 0, 120.2),
      seasonal_value_t (7, 0, 130.5),
      seasonal_value_t (8, 0, 145.2),
      seasonal_value_t (9, 0, 128.9),
      seasonal_value_t (10, 0, 115.1),
      seasonal_value_t (11, 0, 109.3)
   );

   l_xml varchar2(15000)
      := '<?xml version="1.0" encoding="utf-8"?>
        <ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
        <rating-template office-id="SPK">
          <parameters-id>Stage;Flow</parameters-id>
          <version>COE</version>
          <ind-parameter-specs>
            <ind-parameter-spec position="1">
              <parameter>Stage</parameter>
              <in-range-method>LINEAR</in-range-method>
              <out-range-low-method>ERROR</out-range-low-method>
              <out-range-high-method>ERROR</out-range-high-method>
            </ind-parameter-spec>
          </ind-parameter-specs>
          <dep-parameter>Flow</dep-parameter>
          <description></description>
        </rating-template>
        <rating-spec office-id="SPK">
          <rating-spec-id>Murphysboro-Big Muddy.Stage;Flow.COE.Production</rating-spec-id>
          <template-id>Stage;Flow.COE</template-id>
          <location-id>Murphysboro-Big Muddy</location-id>
          <version>Production</version>
          <source-agency></source-agency>
          <in-range-method>LINEAR</in-range-method>
          <out-range-low-method>NULL</out-range-low-method>
          <out-range-high-method>NEAREST</out-range-high-method>
          <active>true</active>
          <auto-update>false</auto-update>
          <auto-activate>false</auto-activate>
          <auto-migrate-extension>false</auto-migrate-extension>
          <ind-rounding-specs>
            <ind-rounding-spec position="1">4444444444</ind-rounding-spec>
          </ind-rounding-specs>
          <dep-rounding-spec>4444444444</dep-rounding-spec>
          <description></description>
        </rating-spec>
        <simple-rating office-id="SPK">
          <rating-spec-id>Murphysboro-Big Muddy.Stage;Flow.COE.Production</rating-spec-id>
          <units-id>ft;cfs</units-id>
          <effective-date>2002-04-09T13:53:01Z</effective-date>
          <create-date>2014-06-11T14:46:00Z</create-date>
          <active>true</active>
          <description/>
          <rating-points>
            <point>
              <ind>2.37744006</ind>
              <dep>14.1584233</dep>
            </point>
            <point>
              <ind>2.49935994</ind>
              <dep>25.7683304</dep>
            </point>
            <point>
              <ind>2.56031988</ind>
              <dep>32.2812051</dep>
            </point>
            <point>
              <ind>2.62128012</ind>
              <dep>40.7762591</dep>
            </point>
            <point>
              <ind>2.68224006</ind>
              <dep>50.4039869</dep>
            </point>
            <point>
              <ind>2.7432</ind>
              <dep>61.4475571</dep>
            </point>
            <point>
              <ind>2.80415994</ind>
              <dep>73.3406327</dep>
            </point>
            <point>
              <ind>2.86511988</ind>
              <dep>86.3663821</dep>
            </point>
            <point>
              <ind>2.92608012</ind>
              <dep>100.241637</dep>
            </point>
            <point>
              <ind>2.98704006</ind>
              <dep>114.40006</dep>
            </point>
            <point>
              <ind>3.048</ind>
              <dep>129.407989</dep>
            </point>
            <point>
              <ind>3.10895994</ind>
              <dep>144.415918</dep>
            </point>
            <point>
              <ind>3.16991988</ind>
              <dep>159.990183</dep>
            </point>
            <point>
              <ind>3.23088012</ind>
              <dep>176.130786</dep>
            </point>
            <point>
              <ind>3.29184006</ind>
              <dep>191.705051</dep>
            </point>
            <point>
              <ind>3.3528</ind>
              <dep>208.978328</dep>
            </point>
            <point>
              <ind>3.41375994</ind>
              <dep>225.968436</dep>
            </point>
            <point>
              <ind>3.47471988</ind>
              <dep>244.940723</dep>
            </point>
            <point>
              <ind>3.53568012</ind>
              <dep>264.196179</dep>
            </point>
            <point>
              <ind>3.59664006</ind>
              <dep>284.017971</dep>
            </point>
            <point>
              <ind>3.6576</ind>
              <dep>305.821943</dep>
            </point>
            <point>
              <ind>3.71855994</ind>
              <dep>328.47542</dep>
            </point>
            <point>
              <ind>3.77951988</ind>
              <dep>351.128898</dep>
            </point>
            <point>
              <ind>3.84048012</ind>
              <dep>373.782375</dep>
            </point>
            <point>
              <ind>3.90144006</ind>
              <dep>396.435852</dep>
            </point>
            <point>
              <ind>3.9624</ind>
              <dep>416.257645</dep>
            </point>
            <point>
              <ind>4.02335994</ind>
              <dep>438.911122</dep>
            </point>
            <point>
              <ind>4.08431988</ind>
              <dep>464.396284</dep>
            </point>
            <point>
              <ind>4.14528012</ind>
              <dep>487.049761</dep>
            </point>
            <point>
              <ind>4.20624006</ind>
              <dep>509.703239</dep>
            </point>
            <point>
              <ind>4.2672</ind>
              <dep>532.356716</dep>
            </point>
            <point>
              <ind>4.32815994</ind>
              <dep>555.010193</dep>
            </point>
            <point>
              <ind>4.38911988</ind>
              <dep>577.66367</dep>
            </point>
            <point>
              <ind>4.45008012</ind>
              <dep>597.485463</dep>
            </point>
            <point>
              <ind>4.51104006</ind>
              <dep>620.13894</dep>
            </point>
            <point>
              <ind>4.572</ind>
              <dep>642.792418</dep>
            </point>
            <point>
              <ind>4.63295994</ind>
              <dep>659.782526</dep>
            </point>
            <point>
              <ind>4.69391988</ind>
              <dep>682.436003</dep>
            </point>
            <point>
              <ind>4.75488012</ind>
              <dep>705.08948</dep>
            </point>
            <point>
              <ind>4.81584006</ind>
              <dep>722.079588</dep>
            </point>
            <point>
              <ind>4.8768</ind>
              <dep>741.901381</dep>
            </point>
            <point>
              <ind>4.93776024</ind>
              <dep>761.723173</dep>
            </point>
            <point>
              <ind>4.99871988</ind>
              <dep>784.376651</dep>
            </point>
            <point>
              <ind>5.05968012</ind>
              <dep>807.030128</dep>
            </point>
            <point>
              <ind>5.12063976</ind>
              <dep>826.85192</dep>
            </point>
            <point>
              <ind>5.1816</ind>
              <dep>843.842028</dep>
            </point>
            <point>
              <ind>5.24256024</ind>
              <dep>866.495506</dep>
            </point>
            <point>
              <ind>5.30351988</ind>
              <dep>886.317298</dep>
            </point>
            <point>
              <ind>5.36448012</ind>
              <dep>903.307406</dep>
            </point>
            <point>
              <ind>5.42543976</ind>
              <dep>923.129199</dep>
            </point>
            <point>
              <ind>5.4864</ind>
              <dep>945.782676</dep>
            </point>
            <point>
              <ind>5.54736024</ind>
              <dep>962.772784</dep>
            </point>
            <point>
              <ind>5.60831988</ind>
              <dep>979.762892</dep>
            </point>
            <point>
              <ind>5.66928012</ind>
              <dep>999.584685</dep>
            </point>
            <point>
              <ind>5.73023976</ind>
              <dep>1016.57479</dep>
            </point>
            <point>
              <ind>5.7912</ind>
              <dep>1033.5649</dep>
            </point>
            <point>
              <ind>5.82168012</ind>
              <dep>1044.89164</dep>
            </point>
            <point>
              <ind>5.85216024</ind>
              <dep>1053.38669</dep>
            </point>
            <point>
              <ind>5.88263976</ind>
              <dep>1061.88175</dep>
            </point>
            <point>
              <ind>5.91311988</ind>
              <dep>1073.20849</dep>
            </point>
            <point>
              <ind>5.9436</ind>
              <dep>1081.70354</dep>
            </point>
            <point>
              <ind>6.33983976</ind>
              <dep>1254.4363</dep>
            </point>
            <point>
              <ind>6.58368012</ind>
              <dep>1349.29774</dep>
            </point>
            <point>
              <ind>6.79703976</ind>
              <dep>1438.49581</dep>
            </point>
            <point>
              <ind>7.07136024</ind>
              <dep>1557.42656</dep>
            </point>
            <point>
              <ind>7.37616024</ind>
              <dep>1676.35732</dep>
            </point>
            <point>
              <ind>7.65048012</ind>
              <dep>1798.11976</dep>
            </point>
            <point>
              <ind>7.9248</ind>
              <dep>1906.62991</dep>
            </point>
            <point>
              <ind>8.47343976</ind>
              <dep>2123.76349</dep>
            </point>
            <point>
              <ind>9.20496024</ind>
              <dep>2406.93196</dep>
            </point>
            <point>
              <ind>10.668</ind>
              <dep>3114.85313</dep>
            </point>
            <point>
              <ind>12.192</ind>
              <dep>4105.94276</dep>
            </point>
            <point>
              <ind>13.716</ind>
              <dep>5238.61662</dep>
            </point>
            <point>
              <ind>15.24</ind>
              <dep>6456.24102</dep>
            </point>
            <point>
              <ind>17.3736</ind>
              <dep>8778.22244</dep>
            </point>
          </rating-points>
        </simple-rating>
      </ratings>';
end test_av_location_level_ref_values;
/

show errors;

show errors
grant execute on test_av_location_level_ref_values to cwms_user;
create or replace package body test_av_location_level_ref_values as
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
   procedure teardown
   is
   begin
      cwms_ts.delete_ts(
         p_cwms_ts_id=> c_ts_id,
         p_delete_action=> 'DELETE ALL',
         p_db_office_id=> c_office_id
      );
      cwms_level.delete_location_level(
         p_location_level_id=> c_constant_id,
         p_effective_date=> c_constant_date,
         p_office_id=> c_office_id,
         p_cascade=> 'T'
      );
      cwms_level.delete_location_level(
         p_location_level_id=> c_virtual_id,
         p_effective_date=> c_virtual_date,
         p_office_id=> c_office_id,
         p_cascade=> 'T'
      );
      cwms_level.delete_location_level(
         p_location_level_id=> c_seasonal_id,
         p_effective_date=> c_seasonal_date,
         p_office_id=> c_office_id,
         p_cascade=> 'T'
      );
   exception
      when others then null;
   end teardown;

--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
   procedure setup
   is
   begin
      teardown;
      cwms_loc.store_location(p_location_id => c_loc,
                              p_active => 'T',
                              p_db_office_id => c_office_id,
                              p_time_zone_id => c_timezone_id
      );
      -- create a time series and time series level
      cwms_ts.create_ts(c_office_id, c_ts_id);
      cwms_ts.zstore_ts(p_cwms_ts_id => c_ts_id,
                        p_units => 'm',
                        p_timeseries_data => l_ts_data,
                        p_store_rule => cwms_util.replace_all,
                        p_office_id => c_office_id
      );
      cwms_level.store_location_level4(p_location_level_id => c_ts_level_id,
                                       p_level_value => NULL,
                                       p_level_units => 'm',
                                       p_effective_date => c_ts_date,
                                       p_timezone_id => c_timezone_id,
                                       p_tsid => c_ts_id,
                                       p_expiration_date => c_expiration_date,
                                       p_office_id => c_office_id
      );
      -- create a seasonal level
      cwms_level.store_location_level4(p_location_level_id=> c_seasonal_id,
                                       p_level_value => NULL,
                                       p_level_units => 'm',
                                       p_effective_date => c_seasonal_date,
                                       p_timezone_id => c_timezone_id,
                                       p_interval_origin => c_seasonal_date,
                                       p_interval_months => 12,
                                       p_expiration_date => c_expiration_date,
                                       p_seasonal_values => l_seasonal_data,
                                       p_office_id => c_office_id
      );
      -- create a constant level
      cwms_level.store_location_level4(p_location_level_id => c_constant_id,
                                       p_level_value => c_constant_value,
                                       p_level_units => 'm',
                                       p_effective_date => c_constant_date,
                                       p_expiration_date => c_expiration_date,
                                       p_timezone_id => c_timezone_id,
                                       p_office_id => c_office_id
      );
      cwms_rating.store_ratings_xml(p_xml => l_xml,
                                       p_fail_if_exists => 'F',
                                       p_replace_base => 'F'
      );
      -- create a virtual level using seasonal level as constituent
      cwms_level.store_virtual_location_level(p_location_level_id => c_virtual_id,
                                       p_constituents => l_virt_const,
                                       p_constituent_connections => c_connections,
                                       p_effective_date => c_virtual_date,
                                       p_expiration_date => c_expiration_date,
                                       p_timezone_id => c_timezone_id,
                                       p_fail_if_exists => 'F',
                                       p_ignore_nulls => 'T',
                                       p_office_id => c_office_id
      );
   end setup;

--------------------------------------------------------------------------------
-- procedure constant_level
--------------------------------------------------------------------------------
   procedure constant_level
   is
      l_expected_count INTEGER := 1;
      l_actual_count INTEGER;
      cursor l_expected_data is
         select c_constant_id as location_level_id,
                'm' as level_units,
                c_constant_date as effective_date,
                c_office_id as office_id,
                c_expiration_date as expiration_date,
                c_base_loc as base_location_id,
                c_sub_loc as sub_location_id,
                c_loc as location_id,
                c_elev_param as base_parameter_id,
                c_elev_param as parameter_id,
                c_inst_param as parameter_type,
                c_0_duration as duration,
                c_top_of_spillway as specified_level
         from dual;
      l_expected_data_count INTEGER := 1;
      l_actual_data_count INTEGER;
      cursor l_expected_value_data is
         select c_constant_value as level_value,
                'm' as level_unit_si,
                'ft' as level_unit_en,
                c_expiration_date as expiration_date
         from dual;
   begin
      -- check reference values
      FOR r_expected IN l_expected_data LOOP
         SELECT COUNT(*)
         INTO l_actual_count
         FROM cwms_20.av_location_level_ref v
         WHERE v.location_level_id = r_expected.location_level_id
            AND v.location_level_date = r_expected.effective_date
            AND v.office_id = r_expected.office_id
            AND v.location_level_code is not null
            AND v.location_code is not null
            AND v.attribute_id is null
            AND v.expiration_date = r_expected.expiration_date
            AND v.base_location_id = r_expected.base_location_id
            AND v.sub_location_id = r_expected.sub_location_id
            AND v.location_id = r_expected.location_id
            AND v.base_parameter_id = r_expected.base_parameter_id
            AND v.sub_parameter_id is null
            AND v.parameter_id = r_expected.parameter_id
            AND v.parameter_type_id = r_expected.parameter_type
            AND v.duration_id = r_expected.duration
            AND v.specified_level_id = r_expected.specified_level
            AND v.attribute_duration_id is null
            AND v.attribute_parameter_id is null
            AND v.attribute_parameter_type_id is null
            AND v.attribute_base_parameter_id is null
            AND v.attribute_sub_parameter_id is null;
      end loop;
      ut.expect(l_actual_count).to_equal(l_expected_count);

      -- check values
      FOR r_expected IN l_expected_value_data LOOP
         SELECT COUNT(*)
         INTO l_actual_data_count
         FROM cwms_20.av_location_level_values v
         WHERE v.location_level_code is not null
            AND v.constant_level_si = r_expected.level_value
            AND v.constant_level_en is not null
            AND v.seasonal_value_en is null
            AND v.seasonal_value_si is null
            AND v.interpolate is null
            AND v.interval_origin is null
            AND v.calendar_interval is null
            AND v.time_interval is null
            AND v.calendar_offset is null
            AND v.time_offset is null
            AND v.tsid is null
            AND v.attribute_value_en is null
            AND v.attribute_value_si is null
            AND v.level_unit_en = r_expected.level_unit_en
            AND v.level_unit_si = r_expected.level_unit_si
            AND v.connections is null
            AND v.expiration_date = r_expected.expiration_date
            AND v.default_label is null
            AND v.source is null;
      end loop;
      ut.expect(l_actual_data_count).to_equal(l_expected_data_count);
   end constant_level;

--------------------------------------------------------------------------------
-- procedure ts_level
--------------------------------------------------------------------------------
   procedure ts_level
   is
      l_expected_count INTEGER := 1;
      l_actual_count INTEGER;
      cursor l_expected_data is
         select c_ts_level_id as location_level_id,
                'm' as level_units,
                c_ts_date as effective_date,
                c_office_id as office_id,
                c_expiration_date as expiration_date,
                c_base_loc as base_location_id,
                c_sub_loc as sub_location_id,
                c_loc as location_id,
                c_elev_param as base_parameter_id,
                c_elev_param as parameter_id,
                c_inst_param as parameter_type,
                c_0_duration as duration,
                c_top_of_dam as specified_level
         from dual;
      l_expected_data_count INTEGER := 1;
      l_actual_data_count INTEGER;
      cursor l_expected_value_data is
         select 'T' as interpolate,
                c_ts_id as ts_id,
                'm' as level_unit_si,
                'ft' as level_unit_en,
                c_expiration_date as expiration_date
         from dual;
   begin
      -- check reference values
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_location_level_ref v
            WHERE v.location_level_id = r_expected.location_level_id
              AND v.location_level_date = r_expected.effective_date
              AND v.office_id = r_expected.office_id
              AND v.location_level_code is not null
              AND v.location_code is not null
              AND v.attribute_id is null
              AND v.expiration_date = r_expected.expiration_date
              AND v.base_location_id = r_expected.base_location_id
              AND v.sub_location_id = r_expected.sub_location_id
              AND v.location_id = r_expected.location_id
              AND v.base_parameter_id = r_expected.base_parameter_id
              AND v.sub_parameter_id is null
              AND v.parameter_id = r_expected.parameter_id
              AND v.parameter_type_id = r_expected.parameter_type
              AND v.duration_id = r_expected.duration
              AND v.specified_level_id = r_expected.specified_level
              AND v.attribute_duration_id is null
              AND v.attribute_parameter_id is null
              AND v.attribute_parameter_type_id is null
              AND v.attribute_base_parameter_id is null
              AND v.attribute_sub_parameter_id is null;
         end loop;
      ut.expect(l_actual_count).to_equal(l_expected_count);

      -- check values
      FOR r_expected IN l_expected_value_data LOOP
            SELECT COUNT(*)
            INTO l_actual_data_count
            FROM cwms_20.av_location_level_values v
            WHERE v.location_level_code is not null
              AND v.constant_level_si is null
              AND v.constant_level_en is null
              AND v.seasonal_value_en is null
              AND v.seasonal_value_si is null
              AND v.interpolate = r_expected.interpolate
              AND v.interval_origin is null
              AND v.calendar_interval is null
              AND v.time_interval is null
              AND v.calendar_offset is null
              AND v.time_offset is null
              AND v.tsid = r_expected.ts_id
              AND v.attribute_value_en is null
              AND v.attribute_value_si is null
              AND v.level_unit_en = r_expected.level_unit_en
              AND v.level_unit_si = r_expected.level_unit_si
              AND v.connections is null
              AND v.expiration_date = r_expected.expiration_date
              AND v.default_label is null
              AND v.source is null;
         end loop;
      ut.expect(l_actual_data_count).to_equal(l_expected_data_count);
   end ts_level;

--------------------------------------------------------------------------------
-- procedure seasonal_level
--------------------------------------------------------------------------------
   procedure seasonal_level
      is
      l_expected_count INTEGER := 1;
      l_actual_count INTEGER;
      cursor l_expected_data is
         select c_seasonal_id as location_level_id,
                'm' as level_units,
                c_seasonal_date as effective_date,
                c_office_id as office_id,
                c_expiration_date as expiration_date,
                c_base_loc as base_location_id,
                c_sub_loc as sub_location_id,
                c_loc as location_id,
                c_stage_param as base_parameter_id,
                c_stage_param as parameter_id,
                c_inst_param as parameter_type,
                c_0_duration as duration,
                c_bottom_of_dam as specified_level
         from dual;
      l_expected_data_count INTEGER := 12;
      l_actual_data_count INTEGER;
      cursor l_expected_value_data is
         select 'T' as interpolate,
                c_ts_id as ts_id,
                'm' as level_unit_si,
                'ft' as level_unit_en,
                c_expiration_date as expiration_date,
                c_seasonal_date as seasonal_date,
                '1-0' as cal_interval,
                '0 0:0:0.0' as time_offset
         from dual;
      l_seasonal_count INTEGER;
   begin
      -- check reference values
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_location_level_ref v
            WHERE v.location_level_id = r_expected.location_level_id
              AND v.location_level_date = r_expected.effective_date
              AND v.office_id = r_expected.office_id
              AND v.location_level_code is not null
              AND v.location_code is not null
              AND v.attribute_id is null
              AND v.expiration_date = r_expected.expiration_date
              AND v.base_location_id = r_expected.base_location_id
              AND v.sub_location_id = r_expected.sub_location_id
              AND v.location_id = r_expected.location_id
              AND v.base_parameter_id = r_expected.base_parameter_id
              AND v.sub_parameter_id is null
              AND v.parameter_id = r_expected.parameter_id
              AND v.parameter_type_id = r_expected.parameter_type
              AND v.duration_id = r_expected.duration
              AND v.specified_level_id = r_expected.specified_level
              AND v.attribute_duration_id is null
              AND v.attribute_parameter_id is null
              AND v.attribute_parameter_type_id is null
              AND v.attribute_base_parameter_id is null
              AND v.attribute_sub_parameter_id is null;
         end loop;
      ut.expect(l_actual_count).to_equal(l_expected_count);

      -- check values
      FOR r_expected IN l_expected_value_data LOOP
            SELECT COUNT(*)
            INTO l_actual_data_count
            FROM cwms_20.av_location_level_values v
            WHERE v.location_level_code is not null
              AND v.constant_level_si is null
              AND v.constant_level_en is null
              AND v.seasonal_value_en is not null
              AND v.seasonal_value_si is not null
              AND v.seasonal_value_si >= 109.3
              AND v.seasonal_value_si <= 145.7
              AND v.interpolate = r_expected.interpolate
              AND v.interval_origin = r_expected.seasonal_date
              AND v.calendar_interval = r_expected.cal_interval
              AND v.time_interval is null
              AND v.calendar_offset is not null
              AND v.time_offset = r_expected.time_offset
              AND v.tsid is null
              AND v.attribute_value_en is null
              AND v.attribute_value_si is null
              AND v.level_unit_en = r_expected.level_unit_en
              AND v.level_unit_si = r_expected.level_unit_si
              AND v.connections is null
              AND v.expiration_date = r_expected.expiration_date
              AND v.default_label is null
              AND v.source is null;
         end loop;
      ut.expect(l_actual_data_count).to_equal(l_expected_data_count);

      FOR i IN 1..l_seasonal_data.COUNT LOOP
            SELECT COUNT(*)
            INTO l_seasonal_count
            FROM cwms_20.av_location_level_values v
            WHERE v.location_level_code is not null
              AND v.constant_level_si is null
              AND v.constant_level_en is null
              AND v.seasonal_value_si = l_seasonal_data(i).value
              AND v.interpolate = 'T'
              AND v.interval_origin = c_seasonal_date
              AND v.calendar_interval is not null
              AND v.time_interval is null
              AND v.calendar_offset is not null
              AND v.time_offset is not null
              AND v.tsid is null  -- Note: should be null for seasonal, not ts
              AND v.attribute_value_en is null
              AND v.attribute_value_si is null
              AND v.level_unit_en = 'ft'
              AND v.level_unit_si = 'm'
              AND v.connections is null
              AND v.expiration_date = c_expiration_date
              AND v.default_label is null
              AND v.source is null;

            ut.expect(l_seasonal_count).to_equal(1);
      END LOOP;
   end seasonal_level;

--------------------------------------------------------------------------------
-- procedure virtual_level
--------------------------------------------------------------------------------
   procedure virtual_level
   is
      l_expected_count INTEGER := 1;
      l_actual_count INTEGER;
      cursor l_expected_data is
         select c_constant_id as location_level_id,
                'm' as level_units,
                c_virtual_date as effective_date,
                c_office_id as office_id,
                c_expiration_date as expiration_date,
                c_base_loc as base_location_id,
                c_sub_loc as sub_location_id,
                c_loc as location_id,
                c_stage_param as base_parameter_id,
                c_stage_param as parameter_id,
                c_inst_param as parameter_type,
                c_0_duration as duration,
                c_virtual as specified_level
         from dual;
      l_expected_data_count INTEGER := 1;
      l_actual_data_count INTEGER;
      cursor l_expected_value_data is
         select c_connections as connections,
                'm' as level_unit_si,
                'ft' as level_unit_en,
                c_expiration_date as expiration_date
         from dual;
   begin
      -- check reference values
      FOR r_expected IN l_expected_data LOOP
            SELECT COUNT(*)
            INTO l_actual_count
            FROM cwms_20.av_location_level_ref v
            WHERE v.location_level_id = r_expected.location_level_id
              AND v.location_level_date = r_expected.effective_date
              AND v.office_id = r_expected.office_id
              AND v.location_level_code is not null
              AND v.location_code is not null
              AND v.attribute_id is null
              AND v.expiration_date = r_expected.expiration_date
              AND v.base_location_id = r_expected.base_location_id
              AND v.sub_location_id = r_expected.sub_location_id
              AND v.location_id = r_expected.location_id
              AND v.base_parameter_id = r_expected.base_parameter_id
              AND v.sub_parameter_id is null
              AND v.parameter_id = r_expected.parameter_id
              AND v.parameter_type_id = r_expected.parameter_type
              AND v.duration_id = r_expected.duration
              AND v.specified_level_id = r_expected.specified_level
              AND v.attribute_duration_id is null
              AND v.attribute_parameter_id is null
              AND v.attribute_parameter_type_id is null
              AND v.attribute_base_parameter_id is null
              AND v.attribute_sub_parameter_id is null;
         end loop;
      ut.expect(l_actual_count).to_equal(l_expected_count);

      -- check values
      FOR r_expected IN l_expected_value_data LOOP
            SELECT COUNT(*)
            INTO l_actual_data_count
            FROM cwms_20.av_location_level_values v
            WHERE v.location_level_code is not null
              AND v.constant_level_si is null
              AND v.constant_level_en is null
              AND v.seasonal_value_en is null
              AND v.seasonal_value_si is null
              AND v.interpolate is null
              AND v.interval_origin is null
              AND v.calendar_interval is null
              AND v.time_interval is null
              AND v.calendar_offset is null
              AND v.time_offset is null
              AND v.tsid is null
              AND v.attribute_value_en is null
              AND v.attribute_value_si is null
              AND v.level_unit_en = r_expected.level_unit_en
              AND v.level_unit_si = r_expected.level_unit_si
              AND v.connections = r_expected.connections
              AND v.expiration_date = r_expected.expiration_date
              AND v.default_label is null
              AND v.source is null;
         end loop;
      ut.expect(l_actual_data_count).to_equal(l_expected_data_count);
   end virtual_level;
end test_av_location_level_ref_values;
/

show errors;
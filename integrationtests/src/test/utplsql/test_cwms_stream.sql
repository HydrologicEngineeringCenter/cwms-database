set verify off
create or replace package &&cwms_schema..test_cwms_stream as
--%suite(Test CWMS_STREAM package)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test Jira issue CWDB-206 Inserting new streamflow measurements shifts date time)
procedure measurement_roundtrip_shifts_datetime_CWDB_206;
--%test(Test Jira issue CWMSVUE-476 Overwiting Measurements)
procedure cwmsvue_476_overwrite_measurements;
--%test(Test Jira issue CWMSVUE-470 Importing USGS RDB measurement fails if Flow Adjustment is "NONE")
procedure cwmsvue_470_import_meas_rdb_fails_with_flow_adjustment_of_none;

procedure teardown;
procedure setup;


c_office_id             varchar2(16)  := '&&office_id';
c_location_id           varchar2(57)  := 'StreamTestLoc';
c_timezone_id           varchar2(28)  := 'US/Central';
c_elev_unit             varchar2(16)  := 'ft';
c_flow_unit             varchar2(16)  := 'cfs';
c_temp_unit             varchar2(16)  := 'F';
end test_cwms_stream;
/
show errors;
create or replace package body &&cwms_schema..test_cwms_stream as
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
   cwms_loc.delete_location(
      p_location_id   => c_location_id,
      p_delete_action => cwms_util.delete_all,
      p_db_office_id  => c_office_id);
exception
   when exc_location_id_not_found then null;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  => c_location_id,
      p_time_zone_id => c_timezone_id,
      p_db_office_id => c_office_id);
   commit;
end setup;
--------------------------------------------------------------------------------
-- procedure measurement_roundtrip_shifts_datetime_CWDB_206
--------------------------------------------------------------------------------
procedure measurement_roundtrip_shifts_datetime_CWDB_206
is
   l_meas_xml_str clob;
   l_meas_xml     xmltype;
   l_datetime_str varchar2(32) := '2023-02-24T17:10:00Z';
   l_datetime     date := cwms_util.to_timestamp(l_datetime_str);
begin
   setup;

   l_meas_xml_str :=
'<stream-flow-measurement height-unit=":elev_unit" flow-unit=":flow_unit" temp-unit=":temp_unit" used="true" office-id=":office_id">
    <agency>USACE</agency>
    <gage-height>0.0</gage-height>
    <flow>0.0</flow>
    <quality>Unspecified</quality>
    <date>:datetime</date>
    <location>:location</location>
    <number>17</number>
</stream-flow-measurement>';

   l_meas_xml_str := replace(l_meas_xml_str, ':office_id', c_office_id);
   l_meas_xml_str := replace(l_meas_xml_str, ':elev_unit', c_elev_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':flow_unit', c_flow_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':tem;_unit', c_temp_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':location',  c_location_id);
   l_meas_xml_str := replace(l_meas_xml_str, ':datetime',  l_datetime_str);

   cwms_stream.store_streamflow_meas_xml(
      p_xml            => l_meas_xml_str,
      p_fail_if_exists => 'F');

   l_meas_xml_str := cwms_stream.retrieve_streamflow_meas_xml(
      p_location_id_mask => c_location_id,
      p_unit_system      => 'EN',
      p_office_id_mask   => c_office_id);

   l_meas_xml := xmltype(l_meas_xml_str);
   l_datetime_str := cwms_util.get_xml_text(xmltype(l_meas_xml_str), '//date');
   ut.expect(cast (cwms_util.to_timestamp(l_datetime_str) as date)).to_equal(l_datetime);

end measurement_roundtrip_shifts_datetime_CWDB_206;
--------------------------------------------------------------------------------
-- procedure cwmsvue_476_overwrite_measurements
--------------------------------------------------------------------------------
procedure cwmsvue_476_overwrite_measurements
is
   type expected_values_rec_t is record (datetime date, stage binary_double, flow binary_double);
   type expected_values_tab_t is table of expected_values_rec_t;
   l_meas_xml_str    clob;
   l_expected_values expected_values_tab_t;
   l_datetime        cwms_v_streamflow_meas.date_time_utc%type;
   l_stage           cwms_v_streamflow_meas.gage_height%type;
   l_flow            cwms_v_streamflow_meas.flow%type;
begin
   setup;

   l_meas_xml_str :=
'<stream-flow-measurements>
   <stream-flow-measurement height-unit=":elev_unit" flow-unit=":flow_unit" temp-unit=":temp_unit" used="true" office-id=":office_id">
       <location>:location</location><date>2000-01-01T18:00:00Z</date><number>1</number>
       <gage-height>0.0</gage-height><flow>0.0</flow><quality>Unspecified</quality><agency>USACE</agency>
   </stream-flow-measurement>
   <stream-flow-measurement height-unit=":elev_unit" flow-unit=":flow_unit" temp-unit=":temp_unit" used="true" office-id=":office_id">
       <location>:location</location><date>2000-02-01T18:00:00Z</date><number>2</number>
       <gage-height>1.0</gage-height><flow>10.0</flow><quality>Unspecified</quality><agency>USACE</agency>
   </stream-flow-measurement>
   <stream-flow-measurement height-unit=":elev_unit" flow-unit=":flow_unit" temp-unit=":temp_unit" used="true" office-id=":office_id">
       <location>:location</location><date>2000-03-01T18:00:00Z</date><number>3</number>
       <gage-height>2.0</gage-height><flow>20.0</flow><quality>Unspecified</quality><agency>USACE</agency>
   </stream-flow-measurement>
</stream-flow-measurements>';

   l_meas_xml_str := replace(l_meas_xml_str, ':office_id', c_office_id);
   l_meas_xml_str := replace(l_meas_xml_str, ':elev_unit', c_elev_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':flow_unit', c_flow_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':tem;_unit', c_temp_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':location',  c_location_id);

   cwms_stream.store_streamflow_meas_xml(
      p_xml            => l_meas_xml_str,
      p_fail_if_exists => 'T');

   l_expected_values := expected_values_tab_t();
   l_expected_values.extend(3);
   l_expected_values(1) := expected_values_rec_t(timestamp '2000-01-01 18:00:00', 0.0,  0.0);
   l_expected_values(2) := expected_values_rec_t(timestamp '2000-02-01 18:00:00', 1.0, 10.0);
   l_expected_values(3) := expected_values_rec_t(timestamp '2000-03-01 18:00:00', 2.0, 20.0);

   for i in 1..3 loop
      select date_time_utc,
             gage_height,
             flow
        into l_datetime,
             l_stage,
             l_flow
        from cwms_v_streamflow_meas
       where office_id = c_office_id
         and location_id = c_location_id
         and meas_number = i
         and unit_system = 'EN';

      ut.expect(l_datetime).to_equal(l_expected_values(i).datetime);
      ut.expect(round(l_stage, 5)).to_equal(l_expected_values(i).stage);
      ut.expect(round(l_flow, 5)).to_equal(l_expected_values(i).flow);
   end loop;

   l_meas_xml_str :=
'<stream-flow-measurements>
   <stream-flow-measurement height-unit=":elev_unit" flow-unit=":flow_unit" temp-unit=":temp_unit" used="true" office-id=":office_id">
       <location>:location</location><date>2010-01-01T18:00:00Z</date><number>1</number>
       <gage-height>1.0</gage-height><flow>10.0</flow><quality>Unspecified</quality><agency>USACE</agency>
   </stream-flow-measurement>
   <stream-flow-measurement height-unit=":elev_unit" flow-unit=":flow_unit" temp-unit=":temp_unit" used="true" office-id=":office_id">
       <location>:location</location><date>2010-02-01T18:00:00Z</date><number>2</number>
       <gage-height>2.0</gage-height><flow>20.0</flow><quality>Unspecified</quality><agency>USACE</agency>
   </stream-flow-measurement>
   <stream-flow-measurement height-unit=":elev_unit" flow-unit=":flow_unit" temp-unit=":temp_unit" used="true" office-id=":office_id">
       <location>:location</location><date>2010-03-01T18:00:00Z</date><number>3</number>
       <gage-height>3.0</gage-height><flow>30.0</flow><quality>Unspecified</quality><agency>USACE</agency>
   </stream-flow-measurement>
</stream-flow-measurements>';

   l_meas_xml_str := replace(l_meas_xml_str, ':office_id', c_office_id);
   l_meas_xml_str := replace(l_meas_xml_str, ':elev_unit', c_elev_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':flow_unit', c_flow_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':tem;_unit', c_temp_unit);
   l_meas_xml_str := replace(l_meas_xml_str, ':location',  c_location_id);

   cwms_stream.store_streamflow_meas_xml(
      p_xml            => l_meas_xml_str,
      p_fail_if_exists => 'F');

   l_expected_values(1) := expected_values_rec_t(timestamp '2010-01-01 18:00:00', 1.0, 10.0);
   l_expected_values(2) := expected_values_rec_t(timestamp '2010-02-01 18:00:00', 2.0, 20.0);
   l_expected_values(3) := expected_values_rec_t(timestamp '2010-03-01 18:00:00', 3.0, 30.0);

   for i in 1..3 loop
      select date_time_utc,
             gage_height,
             flow
        into l_datetime,
             l_stage,
             l_flow
        from cwms_v_streamflow_meas
       where office_id = c_office_id
         and location_id = c_location_id
         and meas_number = i
         and unit_system = 'EN';

      ut.expect(l_datetime).to_equal(l_expected_values(i).datetime);
      ut.expect(round(l_stage, 5)).to_equal(l_expected_values(i).stage);
      ut.expect(round(l_flow, 5)).to_equal(l_expected_values(i).flow);
   end loop;

end cwmsvue_476_overwrite_measurements;
--------------------------------------------------------------------------------
-- procedure cwmsvue_470_import_meas_rdb_fails_with_flow_adjustment_of_none
--------------------------------------------------------------------------------
procedure cwmsvue_470_import_meas_rdb_fails_with_flow_adjustment_of_none
is
   l_meas     cwms_t_streamflow_meas;
   l_parts    cwms_t_str_tab;
   l_flow_adj cwms_v_streamflow_meas.flow_adjustment%type;
   l_rdb      clob := '
#
# U.S. Geological Survey, National Water Information System
# Surface water measurements
#
# Retrieved: 2023-02-16 17:32:06 EST     (caww02)
#
# Further descriptions of the columns and codes used can be found at:
# https://help.waterdata.usgs.gov/output-formats#streamflow_measurement_data
#
# Data for the following 1 site(s) are contained in this file
#  USGS 06090800 Missouri River at Fort Benton MT
# -----------------------------------------------------------------------------------
#
#
agency_cd	site_no	measurement_nu	measurement_dt	tz_cd	q_meas_used_fg	party_nm	site_visit_coll_agency_cd	gage_height_va	discharge_va	measured_rating_diff	gage_va_change	gage_va_time	control_type_cd	discharge_cd
5s	15s	6s	19d	12s	1s	12s	5s	12s	12s	12s	7s	6s	21s	15s
USGS	06090800	150	1948-05-25		Yes	WB	USGS	8.19	34100	Good	0.35	3.40	Clear	NONE
USGS	06090800	151	1948-06-15		Yes	nn	USGS		7370	Unspecified				NONE
USGS	06090800	152	1948-06-16		Yes	WB	USGS	8.35	33800	Good	0.02	3.10	Clear	NONE
USGS	06090800	196	1953-06-06		Yes	JD/	USGS	12.00	63000	Unspecified				NONE
USGS	06090800	197	1953-06-07		Yes	WB	USGS	10.32	49700	Good	0.19	3.90		NONE
USGS	06090800	198	1953-06-10		Yes	WB	USGS	7.74	30000	Good	-0.17	2.90	Clear	NONE
USGS	06090800	315	1964-06-08		Yes	nn	USGS		21600	Unspecified				NONE
USGS	06090800	316	1964-06-11		Yes	JD/	USGS	11.67	61400	Good	-0.18	2.10		NONE
USGS	06090800	317	1964-06-12		Yes	JD/	USGS	9.36	38600	Unspecified	-0.08	1.10		NONE
USGS	06090800	318	1964-06-13		Yes	EOL	USGS	8.34	32700	Good	-0.03	1.40		NONE
USGS	06090800	435	1975-06-21		Yes	WHE/CLC	USGS	11.52	60300	Good	0.02	2.10	Clear	NONE
USGS	06090800	439	1975-10-30		Yes	CLC	USGS	3.92	10500	Excellent	-0.05	1.50	Clear	NONE
USGS	06090800	440	1975-11-28		Yes	CLC	USGS	3.48	8830	Good	0.03	1.40	Clear	NONE
USGS	06090800	441	1976-01-29		Yes	CLC	USGS	3.40	8760	Good	-0.08	2.00	Clear	NONE
USGS	06090800	442	1976-02-25		Yes	CLC	USGS	3.24	8240	Fair	0.01	1.20	Clear	NONE
USGS	06090800	443	1976-03-22		Yes	CLC	USGS	3.81	9640	Good	0.02	1.30	Clear	NONE
USGS	06090800	444	1976-05-03		Yes	CLC	USGS	5.97	20400	Excellent	0.04	1.30	DebrisLight	NONE
USGS	06090800	445	1976-06-01		Yes	CLC	USGS	6.18	21000	Good	0.02	1.30	Clear	NONE
USGS	06090800	446	1976-07-01		Yes	CLC/F	USGS	5.85	19500	Good	0.08	1.20	Clear	NONE
USGS	06090800	447	1976-07-29		Yes	CLC/F	USGS	3.24	8030	Good	0.00	1.50	Clear	NONE
USGS	06090800	448	1976-09-02		Yes	CLC	USGS	3.13	7250	Good	0.09	1.30	Clear	NONE
USGS	06090800	449	1976-10-05		Yes	CLC	USGS	3.23	7380	Good	0.00	1.50	Clear	NONE
USGS	06090800	450	1976-11-18		Yes	CLC/RC	USGS	3.00	7060	Fair	-0.16	1.50	Clear	NONE
USGS	06090800	451	1976-12-30		Yes	RRS/RC	USGS	2.96	6810	Good	0.00	1.30	Clear	NONE
USGS	06090800	452	1977-02-24		Yes	RC	USGS	2.55	5510	Good	-0.03	1.00	Clear	NONE
USGS	06090800	453	1977-04-13		Yes	RC	USGS	2.75	5780	Fair	0.07	1.20	Clear	NONE
USGS	06090800	454	1977-05-10		Yes	RC	USGS	2.40	5360	Good	0.07	1.20	Clear	NONE
USGS	06090800	455	1977-06-13		Yes	RC /MM	USGS	2.81	5430	Fair	1.06	2.20	Clear	NONE
USGS	06090800	456	1977-06-14		Yes	RC /MM	USGS	2.23	3840	Fair	-0.09	1.20	Clear	NONE
USGS	06090800	457	1977-07-05		Yes	RC	USGS	1.93	2990	Fair	-0.14	2.00	Clear	NONE
USGS	06090800	458	1977-07-28		Yes	RC /F	USGS	2.05	3820	Good	0.00	1.30	Clear	NONE
USGS	06090800	459	1977-09-01		Yes	RC	USGS	1.50	2320	Good	0.08	1.30	Clear	NONE
USGS	06090800	460	1977-10-14		Yes	RC	USGS	1.63	2910	Good	0.02	1.20	Clear	NONE
USGS	06090800	461	1977-11-18		Yes	RC	USGS	2.40	5000	Good	-0.13	1.20	Clear	NONE
USGS	06090800	462	1978-03-19		Yes	MK /JW	USGS	4.95	15700	Good	0.15	1.90	Clear	NONE
USGS	06090800	463	1978-05-03		Yes	NAM	USGS	4.29	12200	Good	0.08	2.20	Clear	NONE
USGS	06090800	464	1978-06-12		Yes	RC	USGS	5.47	17400	Excellent	-0.05	1.60	Clear	NONE
USGS	06090800	465	1978-08-10		Yes	RC	USGS	3.05	7390	Good	-0.05	1.80	Clear	NONE
USGS	06090800	466	1978-10-07		Yes	RC	USGS	2.61	5720	Good	0.00	1.30	Clear	NONE
USGS	06090800	467	1979-03-09		Yes	CLC/LM	USGS	4.44	12800	Good	-0.04	1.20	DebrisLight	NONE';
begin
   setup;

   cwms_loc.assign_loc_group(
      p_loc_category_id => 'Agency Aliases',
      p_loc_group_id    => 'USGS Station Number',
      p_location_id     => c_location_id,
      p_loc_alias_id    => '06090800',
      p_db_office_id    => c_office_id);

   for rec in (select column_value as line from table(cwms_util.split_text(l_rdb, chr(10)))) loop
      if instr(rec.line, 'USGS') = 1 then
         l_meas := streamflow_meas_t(rec.line, c_office_id);
         l_meas.store('T');
      end if;
   end loop;

   for rec in (select column_value as line from table(cwms_util.split_text(l_rdb, chr(10)))) loop
      if instr(rec.line, 'USGS') = 1 then
         l_parts := cwms_util.split_text(rec.line, chr(9));
         if l_parts(15) = 'NONE' then
            select flow_adjustment
              into l_flow_adj
              from cwms_v_streamflow_meas
             where office_id = c_office_id
               and location_id = c_location_id
               and meas_number = l_parts(3)
               and unit_system = 'EN';
            ut.expect(l_flow_adj).to_equal('Unknown');
         end if;
      end if;
   end loop;

end cwmsvue_470_import_meas_rdb_fails_with_flow_adjustment_of_none;


end test_cwms_stream;
/
show errors;

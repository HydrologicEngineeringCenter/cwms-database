set verify off
create or replace package &&cwms_schema..test_cwms_stream as
--%suite(Test CWMS_STREAM package)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test Jira issue CWDB-206 Inserting new streamflow measurements shifts date time)
procedure measurement_roundtrip_shifts_datetime_CWDB_206;

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

end test_cwms_stream;
/
show errors;

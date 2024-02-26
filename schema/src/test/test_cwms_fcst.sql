create or replace package test_cwms_fcst as

--%suite(Test cwms_fcst package code)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test store, catalog, and delete forecast_specification)
procedure simple_store_cat_delete_spec;
--%test(Test store, catalog, and delete forecast_instance)
procedure simple_store_cat_delete_inst;

procedure setup;
procedure teardown;

c_office_id        constant cwms_office.office_id%type         := '&&office_id';
c_location_id      constant at_cwms_ts_id.location_id%type     := 'FcstTestLoc';
c_time_zone_id     constant cwms_time_zone.time_zone_name%type := 'US/Pacific';
c_fcst_spec_id     constant at_fcst_spec.fcst_spec_id%type     := 'TEST';
c_location_count   constant binary_integer := 5;
c_fcst_date_count  constant binary_integer := 5;
c_issue_date_count constant binary_integer := 5;
c_value_count      constant binary_integer := 48;
c_base_date_time   constant date := trunc(sysdate - c_issue_date_count/24*6, 'dd');
c_xml_content      constant varchar2(32767) := '<forecast_info>
  <forecast-spec index="false">:fcst_spec</forecast-spec>
  <forecast-time>:fcst_time</forecast-time>
  <issue-time>:issue_time</issue-time>
  <user-id index="true">:user_id</user-id>
  <host-id>:host_id</host-id>
</forecast_info>
';
c_txt_content      constant varchar2(32767) := '
forecast_spec : :fcst_spec
forecast_time : :fcst_time
issue_time    : :issue_time
user_id       : :user_id
host_id       : :host_id
';
end test_cwms_fcst;
/
show errors
create or replace package body test_cwms_fcst as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  => c_location_id,
      p_time_zone_id => c_time_zone_id,
      p_active       => 'T',
      p_db_office_id => c_office_id);
end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   location_id_not_found exception;
   pragma exception_init(location_id_not_found, -20025);
begin
   begin
      cwms_loc.delete_location(c_location_id, cwms_util.delete_all, c_office_id);
   exception
      when location_id_not_found then null;
   end;
   commit;
end teardown;
--------------------------------------------------------------------------------
-- private function make_issue_dates
--------------------------------------------------------------------------------
function make_issue_dates(
   p_fcst_date in date)
   return cwms_t_date_table
is
   l_issue_dates cwms_t_date_table;
begin
   l_issue_dates := cwms_t_date_table();
   l_issue_dates.extend(c_issue_date_count);
   for i in 1..c_issue_date_count loop
      l_issue_dates(i) := p_fcst_date + (i-1)/24;
   end loop;
   return l_issue_dates;
end make_issue_dates;
---------------------------------------------------------------------------------
-- procedure simple_store_cat_delete_spec
---------------------------------------------------------------------------------
procedure simple_store_cat_delete_spec
is
   l_count        binary_integer;
   l_crsr         sys_refcursor;
   l_office_id    cwms_office.office_id%type;
   l_fcst_spec_id at_fcst_spec.fcst_spec_id%type;
   l_location_id  at_cwms_ts_id.location_id%type;
   l_entity_id    at_entity.entity_id%type;
   l_entity_name  at_entity.entity_name%type;
   l_description  at_fcst_spec.description%type;
begin
   ----------------
   -- store spec --
   ----------------
   cwms_fcst.store_fcst_spec(
      p_fcst_spec_id   => c_fcst_spec_id,
      p_location_id    => c_location_id,
      p_entity_id      => 'CE'||c_office_id,
      p_description    => 'Test forecast spec',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   begin
      cwms_fcst.store_fcst_spec(
         p_fcst_spec_id   => c_fcst_spec_id,
         p_location_id    => c_location_id,
         p_entity_id      => 'CE'||c_office_id,
         p_description    => 'Test forecast spec',
         p_fail_if_exists => 'T',
         p_office_id      => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then raise;
   end;
   ----------------
   -- check view --
   ----------------
   l_count := 0;
   for rec in (select * from cwms_v_fcst_spec) loop
      l_count := l_count + 1;
      ut.expect(rec.office_id).to_equal(c_office_id);
      ut.expect(rec.fcst_spec_id).to_equal(c_fcst_spec_id);
      ut.expect(rec.location_id).to_equal(c_location_id);
      ut.expect(rec.entity_id).to_equal('CE'||c_office_id);
   end loop;
   ut.expect(l_count).to_equal(1);
   -------------------
   -- check catalog --
   -------------------
   cwms_fcst.cat_fcst_spec(
      p_cursor         => l_crsr,
      p_office_id_mask => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_office_id,
            l_fcst_spec_id,
            l_location_id,
            l_entity_id,
            l_entity_name,
            l_description;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      ut.expect(l_office_id).to_equal(c_office_id);
      ut.expect(l_fcst_spec_id).to_equal(c_fcst_spec_id);
      ut.expect(l_location_id).to_equal(c_location_id);
      ut.expect(l_entity_id).to_equal('CE'||c_office_id);
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(1);
   -----------------
   -- delete spec --
   -----------------
   cwms_fcst.delete_fcst_spec(
      p_fcst_spec_id   => c_fcst_spec_id,
      p_location_id    => c_location_id,
      p_delete_action  => cwms_util.delete_key,
      p_office_id      => c_office_id);
   ----------------
   -- check view --
   ----------------
   l_count := 0;
   for rec in (select * from cwms_v_fcst_spec) loop
      l_count := l_count + 1;
   end loop;
   ut.expect(l_count).to_equal(0);
   -------------------
   -- check catalog --
   -------------------
   cwms_fcst.cat_fcst_spec(
      p_cursor         => l_crsr,
      p_office_id_mask => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_office_id,
            l_fcst_spec_id,
            l_location_id,
            l_entity_id,
            l_entity_name,
            l_description;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(0);
end simple_store_cat_delete_spec;
---------------------------------------------------------------------------------
-- procedure simple_store_cat_delete_inst
---------------------------------------------------------------------------------
procedure simple_store_cat_delete_inst
is
   l_count            binary_integer;
   l_crsr             sys_refcursor;
   l_office_id        cwms_office.office_id%type;
   l_fcst_spec_id     at_fcst_spec.fcst_spec_id%type;
   l_location_id      at_cwms_ts_id.location_id%type;
   l_issue_date       date;
   l_date             date;
   l_value            binary_double;
   l_precip_data      cwms_t_ztsv_array;
   l_stage_data       cwms_t_ztsv_array;
   l_flow_data        cwms_t_ztsv_array;
   l_ts_data          cwms_t_ztimeseries_array;
   l_xml_content      varchar2(32767);
   l_txt_content      varchar2(32767);
   l_file_data        cwms_t_fcst_file_tab;
begin
   ----------------
   -- store spec --
   ----------------
   cwms_fcst.store_fcst_spec(
      p_fcst_spec_id   => c_fcst_spec_id,
      p_location_id    => c_location_id,
      p_entity_id      => 'CE'||c_office_id,
      p_description    => 'Test forecast spec',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   -------------------------------
   -- prepare the data to store --
   -------------------------------
   l_issue_date := make_issue_dates(c_base_date_time)(1);
   l_precip_data := cwms_t_ztsv_array();
   l_precip_data.extend(c_value_count);
   l_stage_data := cwms_t_ztsv_array();
   l_stage_data.extend(c_value_count);
   l_flow_data := cwms_t_ztsv_array();
   l_flow_data.extend(c_value_count);
   for j in 1..c_value_count loop
      l_date := c_base_date_time + (j-3)/24;
      l_value := j + j/10;
      l_precip_data(j) := cwms_t_ztsv(l_date, l_value / 10, 0);
      l_stage_data(j)  := cwms_t_ztsv(l_date, l_value, 0);
      l_flow_data(j)   := cwms_t_ztsv(l_date, l_value * 10, 0);
   end loop;
   l_ts_data(1) := cwms_t_ztimeseries(
      c_location_id||'.Precip.Inst.1Hour.0.Fcst',
      'in',
      l_precip_data);
   l_ts_data(2) := cwms_t_ztimeseries(
      c_location_id||'.Stage.Inst.1Hour.0.Fcst',
      'ft',
      l_stage_data);
   l_ts_data(3) := cwms_t_ztimeseries(
      c_location_id||'.Flow.Inst.1Hour.0.Fcst',
      'cfs',
      l_flow_data);
   l_xml_content := replace(c_xml_content, ':fcst_spec',  c_office_id||'/'||c_fcst_spec_id||'/'||c_location_id);
   l_xml_content := replace(l_xml_content, ':fcst_time',  to_char(c_base_date_time, 'yyyy-mm-ddThh24:mi:ssZ'));
   l_xml_content := replace(l_xml_content, ':issue_time', to_char(l_issue_date, 'yyyy-mm-ddThh24:mi:ssZ'));
   l_xml_content := replace(l_xml_content, ':user_id',    user);
   l_xml_content := replace(l_xml_content, ':host_id',    cwms_util.get_db_host);
   l_file_data(1) := cwms_t_fcst_file(
      'forecast_info.xml',
      'forecast info in xml format',
      utl_raw.cast_to_raw(l_xml_content));
   l_txt_content := replace(c_txt_content, ':fcst_spec',  c_office_id||'/'||c_fcst_spec_id||'/'||c_location_id);
   l_txt_content := replace(l_txt_content, ':fcst_time',  to_char(c_base_date_time, 'yyyy-mm-ddThh24:mi:ssZ'));
   l_txt_content := replace(l_txt_content, ':issue_time', to_char(l_issue_date, 'yyyy-mm-ddThh24:mi:ssZ'));
   l_txt_content := replace(l_txt_content, ':user_id',    user);
   l_txt_content := replace(l_txt_content, ':host_id',    cwms_util.get_db_host);
   l_file_data(2) := cwms_t_fcst_file(
      'forecast_info.txt',
      'forecast info in txt format',
      utl_raw.cast_to_raw(l_txt_content));
   ------------------------
   -- store the forecast --
   ------------------------
   cwms_fcst.store_fcst(
      p_fcst_spec_id       => c_fcst_spec_id,
      p_location_id        => c_location_id,
      p_forecast_date_time => c_base_date_time,
      p_issue_date_time    => l_issue_date,
      p_time_zone          => 'UTC',
      p_max_age            => 24,
      p_notes              => 'Testing',
      p_time_series        => l_ts_data,
      p_files              => l_file_data,
      p_fail_if_exists     => 'T',
      p_office_id          => c_office_Id);
end simple_store_cat_delete_inst;
end test_cwms_fcst;
/
show errors

grant execute on test_cwms_fcst to cwms_user;

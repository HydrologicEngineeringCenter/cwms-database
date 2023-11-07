create or replace package test_cwms_xchg as

--%suite(Test CWMS Data Exchange functionality)

--%beforeeach(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(CWDB-248 Error when attempting to save Data Exchange Set with space in name)
procedure cwdb_248_error_when_storing_exchange_set_with_space_in_name;

procedure setup;
procedure teardown;
end test_cwms_xchg;
/
create or replace package body test_cwms_xchg as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  => 'XchgTestLoc',
      p_db_office_id => '&&office_id');
end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   l_crsr sys_refcursor;
   l_office_ids            cwms_t_str_tab;
   l_xchg_set_ids          cwms_t_str_tab;
   l_xchg_set_descriptions cwms_t_str_tab;
   l_filemgr_urls          cwms_t_str_tab;
   l_dss_filenames         cwms_t_str_tab;
   l_xchg_directions       cwms_t_str_tab;
   l_conf_xml                  xmltype;
   l_nodes                 cwms_t_xml_tab;
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
   -------------------------------
   -- catalog the exchange sets --
   -------------------------------
   cwms_cat.cat_dss_xchg_set(l_crsr, '&&office_id');
   fetch l_crsr
    bulk collect
    into l_office_ids,
         l_xchg_set_ids,
         l_xchg_set_descriptions,
         l_filemgr_urls,
         l_dss_filenames,
         l_xchg_directions;
   close l_crsr;
   ------------------------------
   -- delete each exchange set --
   ------------------------------
   for i in 1..l_xchg_set_ids.count loop
      cwms_xchg.delete_dss_xchg_set(l_xchg_set_ids(i), '&&office_id');
   end loop;
   commit;
   -------------------------------
   -- delete unused data stores --
   -------------------------------
   cwms_xchg.del_unused_dss_xchg_info('&&office_id');
   -----------------------------------
   -- verify everything was deleted --
   -----------------------------------
   l_conf_xml := xmltype(cwms_xchg.get_dss_xchg_sets(p_office_id => '&&office_id'));
   l_nodes := cwms_util.get_xml_nodes(l_conf_xml, '/*/office');
   if l_nodes.count != 1 then
      cwms_err.raise('ERROR', 'Expected office count of 1, got '||l_nodes.count);
   end if;
   l_nodes := cwms_util.get_xml_nodes(l_conf_xml, '/*/datastore');
   if l_nodes.count != 1 then
      cwms_err.raise('ERROR', 'Expected datastore count of 1, got '||l_nodes.count);
   end if;
   l_nodes := cwms_util.get_xml_nodes(l_conf_xml, '/*/dataexchange-set');
   if l_nodes.count != 0 then
      cwms_err.raise('ERROR', 'Expected dataexchange-set count of 0, got '||l_nodes.count);
   end if;
   ------------------------
   -- delete the location --
   ------------------------
   begin
      cwms_loc.delete_location(
         p_location_id   => 'XchgTestLoc',
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => '&&office_id');
   exception
      when exc_location_id_not_found then null;
   end;
end teardown;
--------------------------------------------------------------------------------
-- procedure cwdb_248_error_when_storing_exchange_set_with_space_in_name
--------------------------------------------------------------------------------
procedure cwdb_248_error_when_storing_exchange_set_with_space_in_name
is
   l_office_name  cwms_v_office.long_name%type;
   l_conf_xml     xmltype;
   l_office_node  xmltype;
   l_db_ds_node   xmltype;
   l_db_ds_id     varchar2(32);
   l_host_id      varchar2(64);
   l_host_port    integer;
   l_sets_ins     integer;
   l_sets_upd     integer;
   l_maps_ins     integer;
   l_maps_upd     integer;
   l_maps_del     integer;
   l_conf_str_out clob;
   l_conf_str_in  clob := '
<cwms-dataexchange-configuration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/dataexchangeconfiguration_v2.xsd">
  :office_node
  :db_ds_node
  <datastore>
    <dssfilemanager id="datastore with space" office-id="&&office_id">
      <host>:host_id</host>
      <port>:host_port</port>
      <filepath>/var/tmp/file with space</filepath>
      <description>Datastore description</description>
    </dssfilemanager>
  </datastore>
  <dataexchange-set id="exchange set with space" office-id="&&office_id">
    <description>Export Daily and Monthly WSA Data to DSS</description>
    <datastore-ref id=":db_ds_id" office-id="&&office_id" />
    <datastore-ref id="datastore with space" office-id="&&office_id" />
    <override-timezone>GMT</override-timezone>
    <ts-mapping-set>
      <ts-mapping>
        <cwms-timeseries datastore-id=":db_ds_id" office-id="&&office_id">XchgTestLoc.Flow.Inst.1Hour.0.Test</cwms-timeseries>
        <dss-timeseries datastore-id="datastore with space" office-id="&&office_id" type="INST-VAL" units="cfs" timezone="UTC" tz-usage="Standard">//XchgTestLoc/Flow//1Hour/Test/</dss-timeseries>
      </ts-mapping>
    </ts-mapping-set>
  </dataexchange-set>
</cwms-dataexchange-configuration>
';

begin
   -----------------------------------------------
   -- get database-specific configuration parts --
   -----------------------------------------------
   l_conf_xml    := xmltype(cwms_xchg.get_dss_xchg_sets(p_office_id => '&&office_id'));
   l_office_node := cwms_util.get_xml_node(l_conf_xml, '/*/office');
   l_db_ds_node  := cwms_util.get_xml_node(l_conf_xml, '/*/datastore');
   l_db_ds_id    := cwms_util.get_xml_text(l_db_ds_node, '/datastore/oracle/@id');
   l_host_id     := cwms_util.get_xml_text(l_db_ds_node, '/datastore/oracle/host');
   select db_host_office_code * 1000 + 101 into l_host_port from av_office where office_id = '&&office_id';
   ----------------------------------------
   -- create the configuration to store --
   ----------------------------------------
   l_conf_str_in := replace(l_conf_str_in, ':office_node', l_office_node.getstringval);
   l_conf_str_in := replace(l_conf_str_in, ':db_ds_node',  l_db_ds_node.getstringval);
   l_conf_str_in := replace(l_conf_str_in, ':host_id',     l_host_id);
   l_conf_str_in := replace(l_conf_str_in, ':host_port',   l_host_port);
   l_conf_str_in := replace(l_conf_str_in, ':db_ds_id',    l_db_ds_id);
   select trim(xmlserialize(content xmltype(l_conf_str_in) indent)) into l_conf_str_in from dual;
   -----------------------------
   -- store the configuration --
   -----------------------------
   cwms_xchg.store_dataexchange_conf(
      l_sets_ins,
      l_sets_upd,
      l_maps_ins,
      l_maps_upd,
      l_maps_del,
      l_conf_str_in);
   ut.expect(l_sets_ins).to_equal(1);
   ut.expect(l_sets_upd).to_equal(0);
   ut.expect(l_maps_ins).to_equal(1);
   ut.expect(l_maps_upd).to_equal(0);
   ut.expect(l_maps_del).to_equal(0);
   commit;
   ---------------------------------------------------
   -- verify retrieved configuration against stored --
   ---------------------------------------------------
   select trim(xmlserialize(content xmltype(cwms_xchg.get_dss_xchg_sets(p_office_id => '&&office_id')) indent)) into l_conf_str_out from dual;
   l_conf_str_out := substr(l_conf_str_out, instr(l_conf_str_out, chr(10))+1);
   ut.expect(l_conf_str_out).to_equal(l_conf_str_in);

end cwdb_248_error_when_storing_exchange_set_with_space_in_name;


end test_cwms_xchg;
/

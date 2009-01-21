declare
   type str_tab_t is table of varchar2(64);
   error_count binary_integer;
   no_such_type exception;
   has_dependency exception;
   pragma exception_init(no_such_type, -04043);
   pragma exception_init(has_dependency, -02303);
   types str_tab_t := str_tab_t(
      'xchg_cwms_dataexchange_conf_t',
      'xchg_cwms_timeseries_t',
      'xchg_dataexchange_conf_t',
      'xchg_dataexchange_set_t',
      'xchg_dataexchange_set_tab_t',
      'xchg_datastore_t',
      'xchg_datastore_tab_t',
      'xchg_dss_timeseries_t',
      'xchg_dssfilemanager_t',
      'xchg_office_t',
      'xchg_office_tab_t',
      'xchg_oracle_t',
      'xchg_timeseries_t',
      'xchg_timeseries_tab_t',
      'xchg_timewindow_t',
      'xchg_max_interpolate_t',
      'xchg_ts_mapping_set_t',
      'xchg_ts_mapping_t',
      'xchg_ts_mapping_tab_t');
begin
   loop
      error_count := 0;
      for i in 1..types.count loop
         begin
            execute immediate 'drop type ' || types(i);
            dbms_output.put_line('Dropped type ' || types(i));
         exception
            when no_such_type then
               null;

            when has_dependency then
               error_count := error_count + 1;
               
            when others then
               raise;
         end;
      end loop;
      exit when error_count = 0;
   end loop;
end;
/

create type xchg_timeseries_t as object (
   m_subtype       varchar2(32),
   m_datastore_id  varchar2(16),
   
   member function get_subtype return varchar2,
   member function get_datastore_id return varchar2,
   member function get_timeseries return varchar2,
   member function get_xml return xmltype
) not instantiable not final;
/
show errors;

create type body xchg_timeseries_t 
as 
   member function get_subtype return varchar2
   is
   begin
      return m_subtype;
   end get_subtype;   
   
   member function get_datastore_id return varchar2
   is
   begin
      return m_datastore_id;
   end get_datastore_id;
   
   member function get_timeseries return varchar2
   is
   begin
      return null;
   end;
   
   member function get_xml return xmltype
   is
   begin
      return null;
   end;
end;
/
show errors;

create type xchg_timeseries_tab_t as table of xchg_timeseries_t;
/

create type xchg_cwms_timeseries_t under xchg_timeseries_t(
   m_tsid varchar2(183),
   
   constructor function xchg_cwms_timeseries_t(
      p_datastore_id in varchar2,
      p_tsid         in varchar2)
      return self as result,
   
   constructor function xchg_cwms_timeseries_t(
      p_node in xmltype)
      return self as result,
   
   member procedure init(
      p_datastore_id in varchar2,
      p_tsid         in varchar2),
      
   overriding member function get_timeseries return varchar2,
   
   overriding member function get_xml return xmltype
);
/
show errors;

create type body xchg_cwms_timeseries_t
as
   member procedure init(
      p_datastore_id in varchar2,
      p_tsid         in varchar2)
   is
      l_tsid_parts         cwms_util.str_tab_t;
      l_component_names    cwms_util.str_tab_t := new cwms_util.str_tab_t();
      l_component_patterns cwms_util.str_tab_t := new cwms_util.str_tab_t();
   begin
      if p_datastore_id is null or p_datastore_id = '' then
         cwms_err.raise('ERROR', 'The Datastore ID cannot be NULL or empty.');
      end if;
      if p_tsid is null or p_tsid = '' then
         cwms_err.raise('ERROR', 'The Time Series ID cannot be NULL or empty.');
      end if;
      l_tsid_parts := cwms_util.split_text(cwms_util.strip(p_tsid), '.');
      if l_tsid_parts.count != 6 then
         cwms_err.raise('TS_IS_INVALID', cwms_util.strip(p_tsid), ': invalid format');      
      end if;
      -- same regex pattern as XML schema, broken into compoents
      l_component_names.extend(6);
      l_component_patterns.extend(6);
      l_component_names(1)    := 'location';
      l_component_patterns(1) := '[^.\-]{1,16}(-[^.]{1,32}){0,1}';
      l_component_names(2)    := 'parameter';
      l_component_patterns(2) := '(%|Area|Code|Con[cd]|Count|Currency|Depth|Dir|Dist|Elev|Energy|Evap(Rate){0,1}|Fish|Flow|Frost|Irrad|Opening|pH|Power|Precip|Pres|Rad|Ratio|Speed|SpinRate|Stage|Stor|Temp|Thick|Timing|Travel|Turb[FJN]{0,1}|Volt)(-[^.]{1,32}){0,1}';
      l_component_names(3)    := 'parameter_type';
      l_component_patterns(3) := '(Total|Max|Min|Const|Ave|Inst)';
      l_component_names(4)    := 'interval';
      l_component_patterns(4) := '(0|1(Minute|Hour|Day|Year|Decade)|([234568]|1[25]|[23]0)Minutes|([23468]|12)Hours|[23456]Days)';
      l_component_names(5)    := 'duration';
      l_component_patterns(5) := '((0|1(Minute|Hour|Day|Year|Decade)|([234568]|1[25]|[23]0)Minutes|([23468]|12)Hours|[23456]Days)|(1(Minute|Hour|Day|Year|Decade)BOP|([234568]|1[25]|[23]0)MinutesBOP|([23468]|12)HoursBOP|[23456]DaysBOP))';
      l_component_names(6)    := 'version';
      l_component_patterns(6) := '[^.]{1,32}';
      for i in 1..6 loop
         if l_tsid_parts(i) is null or l_tsid_parts(i) = '' then
            cwms_err.raise('TS_IS_INVALID', cwms_util.strip(p_tsid), ': empty ' || l_component_names(i));
         end if;
         if regexp_instr(l_tsid_parts(i), l_component_patterns(i)) != 1 or
            regexp_instr(l_tsid_parts(i), l_component_patterns(i), 1, 1, 1) != length(l_tsid_parts(i)) + 1 
            then
            cwms_err.raise('TS_IS_INVALID', cwms_util.strip(p_tsid), ': invalid ' || l_component_names(i) ||' : ' || l_tsid_parts(i));      
         end if;
      end loop;
      m_subtype      := 'xchg_cwms_timeseries_t';
      m_datastore_id := cwms_util.strip(p_datastore_id);
      m_tsid         := cwms_util.strip(p_tsid);
   end init;
   
   constructor function xchg_cwms_timeseries_t(
      p_datastore_id in varchar2,
      p_tsid         in varchar2)
      return self as result
   is
   begin
      init(p_datastore_id, p_tsid);
      return;
   end xchg_cwms_timeseries_t;
   
   constructor function xchg_cwms_timeseries_t(
      p_node in xmltype)
      return self as result
   is
   begin
      if p_node.getrootelement() != 'cwms-timeseries' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'cwms-timeseries node'); 
      end if;
      init(
         p_node.extract('/cwms-timeseries/@datastore-id').getstringval(),
         p_node.extract('/cwms-timeseries/node()').getstringval());
      return;
   end xchg_cwms_timeseries_t;

   overriding member function get_timeseries return varchar2
   is
   begin
      return m_tsid;
   end;
   
   overriding member function get_xml return xmltype
   is
   begin
      return xmltype('<cwms-timeseries datastore-id="'||m_datastore_id||'">'||m_tsid||'</cwms-timeseries>');
   end get_xml;
end;
/
show errors;

create type xchg_dss_timeseries_t under xchg_timeseries_t(
   m_pathname varchar2(391),
   m_datatype varchar2(  8),
   m_units    varchar2( 16),
   m_timezone varchar2( 28),
   m_tz_usage varchar2(  8),
   
   constructor function xchg_dss_timeseries_t(
      p_datastore_id in varchar2,
      p_pathname     in varchar2,
      p_datatype     in varchar2,
      p_units        in varchar2,
      p_timezone     in varchar2 default null,
      p_tz_usage     in varchar2 default null)
      return self as result,
   
   constructor function xchg_dss_timeseries_t(
      p_node in xmltype)
      return self as result,
   
   member procedure init(
      p_datastore_id in varchar2,
      p_pathname     in varchar2,
      p_datatype     in varchar2,
      p_units        in varchar2,
      p_timezone     in varchar2 default null,
      p_tz_usage     in varchar2 default null),
      
   member function get_datatype return varchar2,
      
   member function get_units return varchar2,
      
   member function get_timezone return varchar2,
      
   member function get_tz_usage return varchar2,
      
   overriding member function get_timeseries return varchar2,
   
   overriding member function get_xml return xmltype
);
/
show errors;

create type body xchg_dss_timeseries_t
as
   constructor function xchg_dss_timeseries_t(
      p_datastore_id in varchar2,
      p_pathname     in varchar2,
      p_datatype     in varchar2,
      p_units        in varchar2,
      p_timezone     in varchar2 default null,
      p_tz_usage     in varchar2 default null)
      return self as result
   is
   begin
      init(
         p_datastore_id,
         p_pathname,
         p_datatype,
         p_units,
         p_timezone,
         p_tz_usage);
      return;
   end;
   
   constructor function xchg_dss_timeseries_t(
      p_node in xmltype)
      return self as result
   is
      l_datastore_id_node xmltype;
      l_pathname_node     xmltype;
      l_datatype_node     xmltype;
      l_units_node        xmltype;
      l_timezone_node     xmltype;
      l_tz_usage_node     xmltype;
      l_datastore_id_text varchar2(512);
      l_pathname_text     varchar2(512);
      l_datatype_text     varchar2(512);
      l_units_text        varchar2(512);
      l_timezone_text     varchar2(512);
      l_tz_usage_text     varchar2(512);
   begin
      if p_node.getrootelement() != 'dss-timeseries' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'dss-timeseries node'); 
      end if;
      l_datastore_id_node := p_node.extract('/dss-timeseries/@datastore-id');
      l_pathname_node     := p_node.extract('/dss-timeseries/node()');
      l_datatype_node     := p_node.extract('/dss-timeseries/@type');
      l_units_node        := p_node.extract('/dss-timeseries/@units');
      l_timezone_node     := p_node.extract('/dss-timeseries/@timezone');
      l_tz_usage_node     := p_node.extract('/dss-timeseries/@tz-usage');
      if l_datastore_id_node is null
         or l_pathname_node is null
         or l_datatype_node is null
         or l_units_node is null
      then
         cwms_err.raise('INVALID_ITEM', p_node.getstringval(), 'dss-timeseries node'); 
      else
         l_datastore_id_text := l_datastore_id_node.getstringval();
         l_pathname_text     := l_pathname_node.getstringval();
         l_datatype_text     := l_datatype_node.getstringval();
         l_units_text        := l_units_node.getstringval();
         if l_timezone_node is null then
            l_timezone_text := null;
         else
            l_timezone_text := l_timezone_node.getstringval();
         end if;
         if l_tz_usage_node is null then
            l_tz_usage_text := null;
         else
            l_tz_usage_text := l_tz_usage_node.getstringval();
         end if;
      end if;
        
      init(
         l_datastore_id_text,
         l_pathname_text,
         l_datatype_text,
         l_units_text,
         l_timezone_text,
         l_tz_usage_text);
      return;
   end;
   
   member procedure init(
      p_datastore_id in varchar2,
      p_pathname     in varchar2,
      p_datatype     in varchar2,
      p_units        in varchar2,
      p_timezone     in varchar2,
      p_tz_usage     in varchar2)
   is
   l_pathname         varchar2(391);
   l_datatype         varchar2(  8);
   l_timezone         varchar2( 28) := nvl(p_timezone, 'UTC');
   l_tz_usage         varchar2(  8) := nvl(p_tz_usage, 'Standard');
   -- same pattern as in XML schema
   l_pathname_pattern varchar2(223) := '/[^/]{0,64}(/[^/]{1,64}){2}/(\d{2}(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\d{4})?/(([123456]|1[025]|[23]0)MIN|([123468]|12)HOUR|1(DAY|WEEK|MON|YEAR)|IR-(DAY|MONTH|YEAR|DECADE|CENTURY)|(SEMI-|TRI-)MONTH)/[^/]{0,64}/';
   begin
      if p_datastore_id is null or p_datastore_id = '' then
         cwms_err.raise('ERROR', 'The Datastore ID cannot be NULL or empty.');
      end if;
      if p_pathname is null or cwms_util.strip(p_pathname) = '' then
         cwms_err.raise('ERROR', 'The pathname cannot be NULL or empty.');
      end if;
      if p_datatype is null or p_datatype = '' then
         cwms_err.raise('ERROR', 'The data type cannot be NULL or empty.');
      end if;
      if p_units is null or p_units = '' then
         cwms_err.raise('ERROR', 'The units cannot be NULL or empty.');
      end if;
      if l_timezone = '' then
         l_timezone := 'UTC';
      end if;
      if l_tz_usage = '' then
         l_tz_usage := 'Standard';
      end if;
      
      l_pathname := upper(cwms_util.strip(p_pathname));
      if regexp_instr(l_pathname, l_pathname_pattern) != 1 or
         regexp_instr(l_pathname, l_pathname_pattern, 1, 1, 1) != length(l_pathname) + 1
      then
         cwms_err.raise('INVALID_ITEM', l_pathname, 'HEC-DSS time series pathname');
      end if;
      l_datatype := upper(p_datatype);
      if l_datatype != 'INST-VAL' and
         l_datatype != 'INST-CUM' and
         l_datatype != 'PER-AVER' and
         l_datatype != 'PER-CUM'
      then
          cwms_err.raise('INVALID_ITEM', p_datatype, 'HEC-DSS time series data type');
     end if;
     if length(p_units) > 16 then
          cwms_err.raise('INVALID_ITEM', p_units, 'HEC-DSS units');
     end if; 
     if length(l_timezone) > 28 then
          cwms_err.raise('INVALID_ITEM', l_timezone, 'time zone');
     end if; 
      
      m_subtype      := 'xchg_dss_timeseries_t';
      m_datastore_id := p_datastore_id;
      m_pathname     := l_pathname;
      m_datatype     := l_datatype;
      m_units        := p_units;
      m_timezone     := l_timezone;
      m_tz_usage     := case upper(l_tz_usage)
                           when 'STANDARD' then 'Standard'
                           when 'DAYLIGHT' then 'Daylight'
                           when 'LOCAL'    then 'Local'
                           else null
                        end;
      if m_tz_usage is null then
          cwms_err.raise('INVALID_ITEM', l_tz_usage, 'time zone usage');
      end if;
   end;
      
   member function get_datatype return varchar2
   is
   begin
      return m_datatype;
   end;
      
   member function get_units return varchar2
   is
   begin
      return m_units;
   end;
      
   member function get_timezone return varchar2
   is
   begin
      return m_timezone;
   end;
      
   member function get_tz_usage return varchar2
   is
   begin
      return m_tz_usage;
   end;
      
   overriding member function get_timeseries return varchar2
   is
   begin
      return m_pathname;
   end;
   
   overriding member function get_xml return xmltype
   is
   begin
      return xmltype(
         '<dss-timeseries '
         || 'datastore-id="' || m_datastore_id || '" '
         || 'type="'         || m_datatype     || '" '
         || 'units="'        || m_units        || '" '
         || 'timezone="'     || m_timezone     || '" '
         || 'tz-usage="'     || m_tz_usage     || '">'
         || m_pathname
         || '</dss-timeseries>');
   end;
   
end; 
/
show errors;


create type xchg_ts_mapping_t as object (
   m_timeseries xchg_timeseries_tab_t,
   
   constructor function xchg_ts_mapping_t(
      p_ts1 in xchg_timeseries_t,
      p_ts2 in xchg_timeseries_t)
      return self as result,
   
   constructor function xchg_ts_mapping_t(
      p_node in xmltype)
      return self as result,
   
   member procedure init(
      p_ts1 in xchg_timeseries_t,
      p_ts2 in xchg_timeseries_t),
      
   member procedure get_timeseries(
      p_ts1 out xchg_timeseries_t,
      p_ts2 out xchg_timeseries_t),
      
   member function get_xml return xmltype
);
/
show errors;

create type body xchg_ts_mapping_t
as
   constructor function xchg_ts_mapping_t(
      p_ts1 in xchg_timeseries_t,
      p_ts2 in xchg_timeseries_t)
      return self as result
   is
   begin
      init(p_ts1, p_ts2);
      return;
   end;
   
   constructor function xchg_ts_mapping_t(
      p_node in xmltype)
      return self as result
   is
      l_nodes    xmltype;
      l_count    integer;
      l_ts1_node xmltype;
      l_ts2_node xmltype;
      l_ts1      xchg_timeseries_t;
      l_ts2      xchg_timeseries_t;
   begin
      if p_node.getrootelement() != 'ts-mapping' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'ts-mapping node'); 
      end if;
      l_nodes := p_node.extract('/ts-mapping/dss-timeseries | /ts-mapping/cwms-timeseries');
      if l_nodes is null then
         cwms_err.raise('ERROR', 'A timeseries mapping must contain exactly 2 timeseries, found 0');
      end if;
      l_count := 0;
      loop
         exit when l_nodes.existsNode('/*['||(l_count+1)||']') = 0;
         l_count := l_count + 1;
      end loop;
      if l_count != 2 then
         cwms_err.raise('ERROR', 'A timeseries mapping must contain exactly 2 timeseries, found ' || l_count);
      end if;
      l_ts1_node := l_nodes.extract('/*[1]');
      l_ts2_node := l_nodes.extract('/*[2]');
      if regexp_instr(l_ts1_node.getstringval(), '\s*<\s*dss-timeseries') = 1 then
         l_ts1 := new xchg_dss_timeseries_t(l_ts1_node);
      else
         l_ts1 := new xchg_cwms_timeseries_t(l_ts1_node);
      end if;
      if regexp_instr(l_ts2_node.getstringval(), '\s*<\s*dss-timeseries') = 1 then
         l_ts2 := new xchg_dss_timeseries_t(l_ts2_node);
      else
         l_ts2 := new xchg_cwms_timeseries_t(l_ts2_node);
      end if;
      init(l_ts1, l_ts2);
      return;
   end;
   
   member procedure init(
      p_ts1 in xchg_timeseries_t,
      p_ts2 in xchg_timeseries_t)
   is
      l_version cwms_util.str_tab_t := cwms_util.str_tab_t();
      l_parts   cwms_util.str_tab_t;
   begin
      if p_ts1 is null or p_ts2 is null then
         cwms_err.raise('ERROR', 'NULL timeseries passed to timeseries mapping constructor');
      end if;
      if p_ts1.get_datastore_id() = p_ts2.get_datastore_id() then
         cwms_err.raise('ERROR', 'Timeseries in mapping object cannot reference the same datastore.');
      end if;
      l_version.extend(2);
      if p_ts1.get_subtype() = 'xchg_cwms_timeseries_t' then
        l_parts := cwms_util.split_text(p_ts1.get_timeseries(), '.');
        l_version(1) := l_parts(l_parts.count); 
      else
        l_parts := cwms_util.split_text(p_ts1.get_timeseries(), '/');
        l_version(1) := l_parts(l_parts.count-1); 
      end if;
      if regexp_instr(l_version(1), '%+') = 1 
         and regexp_instr(l_version(1), '%+', 1, 1, 1) = length(l_version(1)) + 1 then
         if p_ts2.get_subtype() = 'xchg_cwms_timeseries_t' then
           l_parts := cwms_util.split_text(p_ts2.get_timeseries(), '.');
           l_version(2) := l_parts(l_parts.count); 
         else
           l_parts := cwms_util.split_text(p_ts2.get_timeseries(), '/');
           l_version(2) := l_parts(l_parts.count-1); 
         end if;
         if l_version(2) != l_version(1) then
            cwms_err.raise(
               'ERROR', 'Mis-matched parameterized versions ('
               || p_ts1.get_timeseries()
               || ', '
               || p_ts2.get_timeseries()
               || ')');
         end if;
      end if; 
      m_timeseries := new xchg_timeseries_tab_t();
      m_timeseries.extend(2);
      m_timeseries(1) := p_ts1;
      m_timeseries(2) := p_ts2;
   end;
      
   member procedure get_timeseries(
      p_ts1 out xchg_timeseries_t,
      p_ts2 out xchg_timeseries_t)
   is
   begin
      p_ts1 := m_timeseries(1);
      p_ts2 := m_timeseries(2);
   end;
      
   member function get_xml return xmltype
   is
   begin
      return xmltype(
         '<ts-mapping>'
         ||m_timeseries(1).get_xml().getstringval()
         ||m_timeseries(2).get_xml().getstringval()
         ||'</ts-mapping>');
   end;
end;
/
show errors;

create type xchg_ts_mapping_tab_t as table of xchg_ts_mapping_t;
/
 
create type xchg_ts_mapping_set_t as object (
   m_mappings xchg_ts_mapping_tab_t,
   
   constructor function xchg_ts_mapping_set_t 
      return self as result,
   
   constructor function xchg_ts_mapping_set_t(
      p_node     in xmltype,
      p_is_cwms  in boolean default false) 
      return self as result,
   
   constructor function xchg_ts_mapping_set_t(
      p_mappings in xchg_ts_mapping_tab_t,
      p_is_cwms  in boolean default false) 
      return self as result,
   
   member procedure add_mapping(
      p_mapping in xchg_ts_mapping_t,
      p_is_cwms  in boolean default false),
   
   member procedure add_mappings(
      p_mappings in xchg_ts_mapping_tab_t,
      p_is_cwms  in boolean default false),
         
   member procedure get_datastore_ids(
      p_datastore_id1 out varchar2,
      p_datastore_id2 out varchar2),
      
   member procedure get_mappings(
      p_mappings out xchg_ts_mapping_tab_t),
      
   member procedure init(
      p_mappings in xchg_ts_mapping_tab_t,
      p_is_cwms  in boolean default false),
      
   member function get_xml return xmltype,
   
   member procedure check_validity(
      p_is_cwms in boolean default false) 
      
);
/
show errors;

create type body xchg_ts_mapping_set_t 
as

   constructor function xchg_ts_mapping_set_t 
      return self as result
   is
   begin
      init(null);
      return;
   end;
   
   constructor function xchg_ts_mapping_set_t(
      p_node     in xmltype,
      p_is_cwms  in boolean) 
      return self as result
   is
      l_mappings xchg_ts_mapping_tab_t := new xchg_ts_mapping_tab_t();
      l_node     xmltype;
      i          pls_integer := 0;
   begin
      if p_node.getrootelement() != 'ts-mapping-set' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'ts-mapping-set node'); 
      end if;
      loop
         i := i + 1;
         l_node := p_node.extract('/*/ts-mapping['||i||']');
         exit when l_node is null;
         l_mappings.extend();
         l_mappings(i) := new xchg_ts_mapping_t(l_node);
      end loop;
      init(l_mappings, p_is_cwms);
      return;
   end;
   
   constructor function xchg_ts_mapping_set_t(
      p_mappings in xchg_ts_mapping_tab_t,
      p_is_cwms  in boolean) 
      return self as result
   is
   begin
      init(p_mappings, p_is_cwms);
      return;
   end;
   
   member procedure add_mapping(
      p_mapping in xchg_ts_mapping_t,
      p_is_cwms in boolean)
   is
   begin
      if p_mapping is not null then
         m_mappings.extend();
         m_mappings(m_mappings.last) := p_mapping;
         check_validity(p_is_cwms);
      end if;
   end;
   
   member procedure add_mappings(
      p_mappings in xchg_ts_mapping_tab_t,
      p_is_cwms  in boolean)
   is
      i pls_integer;
   begin
      if p_mappings is not null then
         i := p_mappings.first;
         loop
            m_mappings.extend();
            m_mappings(m_mappings.last) := p_mappings(i);
            i := p_mappings.next(i);
            exit when i is null;
         end loop;
         check_validity(p_is_cwms);
      end if;
   end;
         
   member procedure get_datastore_ids(
      p_datastore_id1 out varchar2,
      p_datastore_id2 out varchar2)
   is
   begin
      if m_mappings.count > 0 then
         p_datastore_id1 := m_mappings(m_mappings.first).m_timeseries(1).get_datastore_id();
         p_datastore_id2 := m_mappings(m_mappings.first).m_timeseries(2).get_datastore_id();
      else
         p_datastore_id1 := null;
         p_datastore_id2 := null;
      end if;
   end;
      
   member procedure get_mappings(
      p_mappings out xchg_ts_mapping_tab_t)
   is
      i pls_integer;
   begin
      p_mappings := new xchg_ts_mapping_tab_t();
      if m_mappings.count > 0 then
         i := m_mappings.first;
         loop
            p_mappings.extend();
            p_mappings(p_mappings.last) := m_mappings(i);
            i := m_mappings.next(i);
            exit when i is null;
         end loop;
      end if;
   end;
      
   member procedure init(
      p_mappings in xchg_ts_mapping_tab_t,
      p_is_cwms  in boolean)
   is
   begin
      m_mappings := new xchg_ts_mapping_tab_t();
      add_mappings(p_mappings, p_is_cwms);
   end;
      
   member function get_xml return xmltype
   is
      l_xmlclob clob;
      l_xml     xmltype;
      i         pls_integer;
            
      procedure write_xml(p_data varchar2) 
      is
      begin
         dbms_lob.writeappend(l_xmlclob, length(p_data), p_data);
      end;
      
      procedure write_xml(p_data xmltype) 
      is
         l_data_clob clob; 
         l_text      varchar2(32767);
         l_length    integer := 32767;
         l_offset    integer := 1;
      begin
         l_data_clob := p_data.getclobval;
         dbms_lob.open(l_data_clob, dbms_lob.lob_readonly);
         loop
            dbms_lob.read(l_data_clob, l_length, l_offset, l_text);
            if l_length > 0 then
               write_xml(l_text);
            end if;
            exit when l_length != 32767;
            l_offset := l_offset + l_length;
         end loop;
         dbms_lob.close(l_data_clob);
         dbms_lob.freetemporary(l_data_clob);
      end;
      
   begin
      dbms_lob.createtemporary(l_xmlclob, true, dbms_lob.call);
      dbms_lob.open(l_xmlclob, dbms_lob.lob_readwrite);
      write_xml('<ts-mapping-set>');
      if m_mappings.count > 0 then
         i := m_mappings.first;
         loop
            write_xml(m_mappings(i).get_xml());
            i := m_mappings.next(i);
            exit when i is null;
         end loop;
      end if;
      write_xml('</ts-mapping-set>');
      dbms_lob.close(l_xmlclob);
      l_xml := xmltype(l_xmlclob);
      dbms_lob.freetemporary(l_xmlclob);
      return l_xml;
   end;
   
   member procedure check_validity(
      p_is_cwms in boolean)
   is
      type vc16_vc32_tab_t is table of varchar2(16) index by varchar2(32);
      type vc391_vc391_tab_t is table of varchar2(391) index by varchar2(391);
      l_id1         varchar2(16);
      l_id2         varchar2(16);
      l_ts1         varchar2(391);
      l_ts2         varchar2(391);
      l_2types      boolean := false;
      l_ids_by_type vc16_vc32_tab_t;
      l_mapped_ts   vc391_vc391_tab_t;
      i             pls_integer;
   begin
      if m_mappings.count > 0 then
         if m_mappings(1).m_timeseries(1).get_subtype != m_mappings(1).m_timeseries(2).get_subtype then
            l_2types := true;
            l_ids_by_type(m_mappings(1).m_timeseries(1).get_subtype) := m_mappings(1).m_timeseries(1).get_datastore_id; 
            l_ids_by_type(m_mappings(1).m_timeseries(2).get_subtype) := m_mappings(1).m_timeseries(2).get_datastore_id; 
         end if;      
         i := m_mappings.first;
         loop
            if i = m_mappings.first then
               l_id1 := m_mappings(i).m_timeseries(1).get_datastore_id;
               l_id2 := m_mappings(i).m_timeseries(2).get_datastore_id;
            else
               if m_mappings(i).m_timeseries(1).get_datastore_id = l_id1 then
                  if m_mappings(i).m_timeseries(2).get_datastore_id != l_id2 then
                     cwms_err.raise('ERROR', 'Timeseries mapping set contains more that 2 datastore IDs.');
                  end if;
               elsif m_mappings(i).m_timeseries(1).get_datastore_id = l_id2 then
                  if m_mappings(i).m_timeseries(2).get_datastore_id != l_id1 then
                     cwms_err.raise('ERROR', 'Timeseries mapping set contains more that 2 datastore IDs.');
                  end if;
               else
                     cwms_err.raise('ERROR', 'Timeseries mapping set contains more that 2 datastore IDs.');
               end if;            
            end if;
            if p_is_cwms then
               if m_mappings(i).m_timeseries(1).get_subtype = 'xchg_dss_timeseries_t' then
                  if m_mappings(i).m_timeseries(2).get_subtype != 'xchg_cwms_timeseries_t' then
                     cwms_err.raise('ERROR', 'CWMS timeseries mapping set contains mapping without CWMS timeseries type.');
                  end if;
               elsif m_mappings(i).m_timeseries(1).get_subtype = 'xchg_cwms_timeseries_t' then
                  if m_mappings(i).m_timeseries(2).get_subtype != 'xchg_dss_timeseries_t' then
                     cwms_err.raise('ERROR', 'CWMS timeseries mapping set contains mapping without DSS timeseries type.');
                  end if;
               else
                     cwms_err.raise(
                        'ERROR', 
                        'CWMS timeseries mapping set contains mapping with unknown timeseries type (' 
                        || m_mappings(i).m_timeseries(1).get_subtype 
                        || ').');
               end if;
            end if;
            if l_2types then
               if m_mappings(i).m_timeseries(1).get_datastore_id != l_ids_by_type(m_mappings(i).m_timeseries(1).get_subtype) then
                  cwms_err.raise('ERROR', 'Timeseries mapping set contains mapping with datastore IDs reversed.');
               end if;
            end if;
            l_ts1 := m_mappings(i).m_timeseries(1).get_timeseries;
            l_ts2 := case l_mapped_ts.exists(l_ts1)
                        when true then l_mapped_ts(l_ts1)
                        else null
                     end;
            if l_ts2 is not null and l_ts2 = m_mappings(i).m_timeseries(2).get_timeseries then
                  cwms_err.raise('ERROR', 'Timeseries mapping set contains duplicate mappings.');
            end if;
            l_ts2 := m_mappings(i).m_timeseries(2).get_timeseries;
            l_mapped_ts(l_ts1) := l_ts2; 
            l_mapped_ts(l_ts2) := l_ts1; 
            i := m_mappings.next(i);
            exit when i is null;
         end loop;
      end if;
   end; 
      
end;
/
show errors;

create type xchg_timewindow_t as object (
   m_starttime varchar2(32),
   m_endtime   varchar2(32),
   m_dummy     varchar2(1), -- force default constructor to have a different signature
                            -- than the specified constructor
   
   constructor function xchg_timewindow_t(
      p_starttime in varchar2,
      p_endtime   in varchar2)
      return self as result,
      
   constructor function xchg_timewindow_t(
      p_node in xmltype)
      return self as result,
      
   member procedure init(
      p_starttime in varchar2,
      p_endtime   in varchar2),
      
   member function get_xml return xmltype,
   
   member function get_starttime return varchar2,
   
   member function get_endtime return varchar2,
   
   member procedure get_times(
      p_starttime out varchar2,
      p_endtime   out varchar2)       
);
/
show errors;

create type body xchg_timewindow_t 
as
   
   constructor function xchg_timewindow_t(
      p_starttime in varchar2,
      p_endtime   in varchar2)
      return self as result
   is
   begin
      init(p_starttime, p_endtime);
      return;
   end;
      
   constructor function xchg_timewindow_t(
      p_node in xmltype)
      return self as result
   is
      l_node      xmltype;
      l_starttime varchar2(32);
      l_endtime   varchar2(32);
   begin
      if p_node.getrootelement() != 'timewindow' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'timewindow node'); 
      end if;
      l_node := p_node.extract('/timewindow/starttime/node()');
      l_starttime := 
         case (l_node is null)
            when true  then null
            when false then l_node.getstringval()
         end; 
      l_node := p_node.extract('/timewindow/endtime/node()');
      l_endtime := 
         case (l_node is null)
            when true  then null
            when false then l_node.getstringval()
         end; 
      init(l_starttime, l_endtime);
      return;
   end;
      
   member procedure init(
      p_starttime in varchar2,
      p_endtime   in varchar2)
   is
      -- same patten as XML schema
      l_time_pattern varchar2(69) := '-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}([.]\d+)?)?([-+]\d{2}:\d{2}|Z)?';
      l_time varchar(64);
      l_explicit boolean;
   begin
      if p_starttime is null or cwms_util.strip(p_starttime) = '' then
         cwms_err.raise('ERROR', 'Time window start time cannot be NULL or empty.');
      end if;
      if p_endtime is null or cwms_util.strip(p_endtime) = '' then
         cwms_err.raise('ERROR', 'Time window end time cannot be NULL or empty.');
      end if;
      l_time := cwms_util.strip(p_starttime);
      case
         when l_time = '$lookback-time'   then null;
         when l_time = '$start-time'      then null;
         when l_time = '$forecast-time'   then null;
         when l_time = '$simulation-time' then null;
         when regexp_instr(l_time, l_time_pattern) = 1 
            and regexp_instr(l_time, l_time_pattern, 1, 1, 1) = length(l_time) + 1 then null;  
         else cwms_err.raise('INVALID_ITEM', l_time, 'Time window start time');
      end case;
      m_starttime := l_time;
      l_time := cwms_util.strip(p_endtime);
      case
         when l_time = '$start-time'      then null;
         when l_time = '$forecast-time'   then null;
         when l_time = '$simulation-time' then null;
         when l_time = '$end-time'        then null;
         when regexp_instr(l_time, l_time_pattern) = 1 
            and regexp_instr(l_time, l_time_pattern, 1, 1, 1) = length(l_time) + 1 then null;  
         else cwms_err.raise('INVALID_ITEM', l_time, 'Time window end time');
      end case;
      m_endtime := l_time;
      if substr(m_starttime, 1, 1) = '$' then
         l_explicit := false;
      else
         l_explicit := true;
      end if;
      if substr(m_endtime, 1, 1) = '$' then
         if l_explicit then
            cwms_err.raise('ERROR', 'Time window cannot mix explicit and parameterized times');
         else
            if m_starttime != '$lookback-time' and m_endtime != '$end-time' then
               cwms_err.raise('ERROR', 'Parameterized time window is zero-length ('||m_starttime||'-->'||m_endtime||')');
            end if;
         end if;
      else
         if l_explicit then
            if cwms_util.to_timestamp(m_endtime) <= cwms_util.to_timestamp(m_starttime) then
               cwms_err.raise('ERROR', 'Explicit time window has non-positive length ('||m_starttime||'-->'||m_endtime||')');
            end if;
         else
            cwms_err.raise('ERROR', 'Time window cannot mix explicit and parameterized times');
         end if;
      end if;
   end;
      
   member function get_xml return xmltype
   is
   begin
      return xmltype(
      '<timewindow><starttime>'
      || m_starttime
      || '</starttime><endtime>'
      || m_endtime
      || '</endtime></timewindow>');
   end;
   
   member function get_starttime return varchar2
   is
   begin
      return m_starttime;
   end;
   
   member function get_endtime return varchar2
   is
   begin
      return m_endtime;
   end;
   
   member procedure get_times(
      p_starttime out varchar2,
      p_endtime   out varchar2)
   is
   begin
      p_starttime := m_starttime;
      p_endtime   := m_endtime;
   end;       
end;
/
show errors;

create type xchg_max_interpolate_t as object (
   m_count integer,
   m_unit  varchar2(16),
   m_dummy varchar2(1), -- force default constructor to have a different signature
                        -- than the specified constructor
   
   constructor function xchg_max_interpolate_t(
      p_count integer,
      p_unit  varchar2)
      return self as result,
      
   constructor function xchg_max_interpolate_t(
      p_node in xmltype)
      return self as result,
      
   member procedure init(
      p_count integer,
      p_unit  varchar2),
      
   member function get_xml return xmltype,
   
   member function get_string return varchar2,
   
   member procedure get_values(
      p_count out integer,
      p_unit  out varchar2)       
);
/
show errors;

create type body xchg_max_interpolate_t 
as
   
   constructor function xchg_max_interpolate_t(
      p_count integer,
      p_unit  varchar2)
      return self as result
   is
   begin
      init(p_count, p_unit);
      return;
   end;
      
   constructor function xchg_max_interpolate_t(
      p_node in xmltype)
      return self as result
   is
      l_node   xmltype;
      l_count integer;
      l_unit  varchar2(16);
   begin
      if p_node.getrootelement() != 'max_interpolate' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'max_interpolate node'); 
      end if;
      l_count := p_node.extract('/max_interpolate/node()').getnumberval();
      l_unit  := p_node.extract('/max_interpolate/@units').getstringval();
      init(l_count, l_unit);
      return;
   end;
      
   member procedure init(
      p_count integer,
      p_unit  varchar2)
   is
   begin
      if p_count is null or p_count < 0 then
         cwms_err.raise('ERROR', 'max-interpolate requires non-negative value');
      end if;
      case p_unit
         when 'minutes'   then null;
         when 'intervals' then null;
         cwms_err.raise('ERROR', 'max-interpolate units must be "minutes" or "intervals"');
      end case;
      m_count := p_count;
      m_unit  := p_unit;
   end;
      
   member function get_xml return xmltype
   is
   begin
      return xmltype(
      '<max_interpolate units="'
      || m_unit
      || '">'
      || m_count
      || '</max_interpolate>');
   end;
   
   member function get_string return varchar2
   is
   begin
      return '' || m_count || ' ' || m_unit;
   end;
   
   member procedure get_values(
      p_count out integer,
      p_unit  out varchar2)
   is
   begin
      p_count := m_count;
      p_unit  := m_unit;
   end;       
end;
/
show errors;

create type xchg_dataexchange_set_t as object (
   m_id                 varchar2(32),
   m_datastore_1        varchar2(16),
   m_datastore_2        varchar2(16),
   m_ts_mapping_set     xchg_ts_mapping_set_t,
   m_description        varchar2(80),
   m_realtime_source_id varchar2(16),
   m_timewindow         xchg_timewindow_t,
   m_max_interpolate    xchg_max_interpolate_t,
   m_office_id          varchar2(16),
   
   constructor function xchg_dataexchange_set_t(
      p_id                 in varchar2,
      p_datastore_1        in varchar2,
      p_datastore_2        in varchar2,
      p_ts_mapping_set     in xchg_ts_mapping_set_t  default null,
      p_is_cwms            in boolean                default false,
      p_description        in varchar2               default null,
      p_realtime_source_id in varchar2               default null,
      p_timewindow         in xchg_timewindow_t      default null,
      p_max_interpolate    in xchg_max_interpolate_t default null,
      p_office_id          in varchar2               default null)
      return self as result,
   
   constructor function xchg_dataexchange_set_t(
      p_node    in xmltype,
      p_is_cwms in boolean default false)
      return self as result,
   
   member procedure init(
      p_id                 in varchar2,
      p_datastore_1        in varchar2,
      p_datastore_2        in varchar2,
      p_ts_mapping_set     in xchg_ts_mapping_set_t,
      p_description        in varchar2,
      p_realtime_source_id in varchar2,
      p_timewindow         in xchg_timewindow_t,
      p_max_interpolate    in xchg_max_interpolate_t,
      p_office_id          in varchar2),
      
   member function get_id return varchar2,
   
   member function get_office_id return varchar2,
   
   member function get_realtime_source_id return varchar2,
   
   member function get_description return varchar2,
   
   member procedure get_datastores(
      p_datastore_1 out varchar2,
      p_datastore_2 out varchar2),
      
   member procedure get_timewindow(
      p_timewindow out xchg_timewindow_t),
  
   member procedure get_max_interpolate(
      p_max_interpolate out xchg_max_interpolate_t),
          
   member procedure get_ts_mapping_set(
      p_ts_mapping_set out xchg_ts_mapping_set_t),
      
   member function get_xml return xmltype
);
/
show errors;

create type body xchg_dataexchange_set_t
as
   
   constructor function xchg_dataexchange_set_t(
      p_id                 in varchar2,
      p_datastore_1        in varchar2,
      p_datastore_2        in varchar2,
      p_ts_mapping_set     in xchg_ts_mapping_set_t,
      p_is_cwms            in boolean,
      p_description        in varchar2,
      p_realtime_source_id in varchar2,
      p_timewindow         in xchg_timewindow_t,
      p_max_interpolate    in xchg_max_interpolate_t,
      p_office_id          in varchar2)
      return self as result
   is
      l_ts_mapping_set xchg_ts_mapping_set_t;
   begin
      if p_ts_mapping_set is not null then
         l_ts_mapping_set := p_ts_mapping_set;
         l_ts_mapping_set.check_validity(p_is_cwms);
      end if;
      init(
         p_id,
         p_datastore_1,
         p_datastore_2,
         p_ts_mapping_set,
         p_description,
         p_realtime_source_id,
         p_timewindow,
         p_max_interpolate,
         p_office_id);
      return;
   end;
   
   constructor function xchg_dataexchange_set_t(
      p_node    in xmltype,
      p_is_cwms in boolean default false)
      return self as result
   is
      l_id                 varchar2(32);
      l_datastore_1        varchar2(16);
      l_datastore_2        varchar2(16);
      l_ts_mapping_set     xchg_ts_mapping_set_t  := null;
      l_description        varchar2(80)           := null;
      l_realtime_source_id varchar2(16)           := null;
      l_timewindow         xchg_timewindow_t      := null;
      l_max_interpolate    xchg_max_interpolate_t := null;
      l_office_id          varchar2(16)           := null;
      l_node               xmltype;
   begin
      if p_node.getrootelement() != 'dataexchange-set' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'dataexchange-set node'); 
      end if;
      --------------------
      -- required items --
      --------------------
      l_node := p_node.extract('/*/@id');
      if l_node is null then
         cwms_err.raise('ERROR', 'dataexchange-set node must have id attribute.');
      end if;
      l_id := l_node.getstringval();
      l_node := p_node.extract('/*/datastore-ref[1]/@id');
      if l_node is null then
         cwms_err.raise('ERROR', 'dataexchange-set node must have two datastore-ref sub-nodes.');
      end if;
      l_datastore_1 := cwms_util.strip(l_node.getstringval());
      l_node := p_node.extract('/*/datastore-ref[2]/@id');
      if l_node is null then
         cwms_err.raise('ERROR', 'dataexchange-set node must have two datastore-ref sub-nodes.');
      end if;
      l_datastore_2 := cwms_util.strip(l_node.getstringval());
      --------------------
      -- optional items --
      --------------------
      l_node := p_node.extract('/*/ts-mapping-set');
      if l_node is not null then
         l_ts_mapping_set := new xchg_ts_mapping_set_t(l_node, p_is_cwms);
      end if;
      l_node := p_node.extract('/*/description/node()');
      if l_node is not null then
         l_description := cwms_util.strip(l_node.getstringval());
      end if;
      l_node := p_node.extract('/*/@realtime-source-id');
      if l_node is not null then
         l_realtime_source_id := l_node.getstringval();
      end if;
      l_node := p_node.extract('/*/timewindow');
      if l_node is not null then
         l_timewindow := new xchg_timewindow_t(l_node);
      end if;
      l_node := p_node.extract('/*/max-interpolate');
      if l_node is not null then
         l_max_interpolate := new xchg_max_interpolate_t(l_node);
      end if;
      l_node := p_node.extract('/*/@office-id');
      if l_node is not null then
         l_office_id := l_node.getstringval();
      end if;
      init(
         l_id,
         l_datastore_1,
         l_datastore_2,
         l_ts_mapping_set,
         l_description,
         l_realtime_source_id,
         l_timewindow,
         l_max_interpolate,
         l_office_id);
      return;
   end;
   
   member procedure init(
      p_id                 in varchar2,
      p_datastore_1        in varchar2,
      p_datastore_2        in varchar2,
      p_ts_mapping_set     in xchg_ts_mapping_set_t,
      p_description        in varchar2,
      p_realtime_source_id in varchar2,
      p_timewindow         in xchg_timewindow_t,
      p_max_interpolate    in xchg_max_interpolate_t,
      p_office_id          in varchar2)
   is
      l_datastore_1 varchar2(16);
      l_datastore_2 varchar2(16);
      l_mappings    xchg_ts_mapping_tab_t;
      l_ts1         xchg_timeseries_t;
      l_ts2         xchg_timeseries_t;
      l_version     varchar2(64);
      l_forecast    boolean := false;
      l_starttime   varchar2(32);
      l_endtime     varchar2(32);
   begin
      m_id                 := p_id;
      m_datastore_1        := p_datastore_1;
      m_datastore_2        := p_datastore_2;
      m_ts_mapping_set     := p_ts_mapping_set;
      m_description        := p_description;
      m_realtime_source_id := p_realtime_source_id;
      m_timewindow         := p_timewindow;
      m_max_interpolate    := p_max_interpolate;
      m_office_id          := nvl(p_office_id, cwms_util.user_office_id);
      
      if m_realtime_source_id is not null then
         if m_realtime_source_id != m_datastore_1 and 
            m_realtime_source_id != m_datastore_2
         then
            cwms_err.raise('ERROR', 'The realtime source does not match either datastore.');
         end if;
      end if;
      
      if m_ts_mapping_set is not null then
         m_ts_mapping_set.get_datastore_ids(l_datastore_1, l_datastore_2);
         if m_datastore_1 = l_datastore_1 and m_datastore_2 = l_datastore_2 or
            m_datastore_1 = l_datastore_2 and m_datastore_2 = l_datastore_1
         then
            null;
         else
            cwms_err.raise('ERROR', 'Data stores in mapping set don''t match those in data exchange set.');
         end if;
      end if;
      
      m_ts_mapping_set.get_mappings(l_mappings);
      for i in 1..l_mappings.count loop
         l_mappings(i).get_timeseries(l_ts1, l_ts2);
         if l_ts1.get_subtype() = 'xchg_cwms_timeseries_t' then
            l_version := cwms_util.split_text(l_ts1.get_timeseries(), '.')(6);
         else
            l_version := cwms_util.split_text(l_ts1.get_timeseries(), '/')(7);
         end if;
         if regexp_instr(l_version, '%+') = 1 and
            regexp_instr(l_version, '%+', 1, 1, 1) = length(l_version) + 1
         then
            l_forecast := true;
            exit;
         end if;    
      end loop;
      
      if l_forecast then
         if m_timewindow is null then
            cwms_err.raise('ERROR', 'Data exchange set ' || m_id || ' contains parameterized time series mappings but has no timewindow.');
         else
            m_timewindow.get_times(l_starttime, l_endtime);
            if substr(l_starttime, 1, 1) != '$' then
               cwms_err.raise('ERROR', 'Data exchange set ' || m_id || ' contains parameterized time series mappings but has explicit timewindow.');
            end if;
         end if;
      end if;       
   end;
      
   member function get_id return varchar2
   is
   begin
      return m_id;
   end;
   
   member function get_office_id return varchar2
   is
   begin
      return m_office_id;
   end;
   
   member function get_realtime_source_id return varchar2
   is
   begin
      return m_realtime_source_id;
   end;
   
   member function get_description return varchar2
   is
   begin
      return m_description;
   end;
   
   member procedure get_datastores(
      p_datastore_1 out varchar2,
      p_datastore_2 out varchar2)
   is
   begin
      p_datastore_1 := m_datastore_1;
      p_datastore_2 := m_datastore_2;
   end;
      
   member procedure get_timewindow(
      p_timewindow out xchg_timewindow_t)
   is
   begin
      p_timewindow := m_timewindow;
   end;
      
   member procedure get_max_interpolate(
      p_max_interpolate out xchg_max_interpolate_t)
   is
   begin
      p_max_interpolate := m_max_interpolate;
   end;
   
   member procedure get_ts_mapping_set(
      p_ts_mapping_set out xchg_ts_mapping_set_t)
   is
   begin
      p_ts_mapping_set := m_ts_mapping_set;
   end;
      
   member function get_xml return xmltype
   is
      l_clob clob;
      
      procedure write_clob(p_text in varchar2)
      is
         l_len binary_integer := length(p_text);
      begin
         dbms_lob.writeappend(l_clob, l_len, p_text);
      end;
      
   begin
      dbms_lob.createtemporary(l_clob, true);
      dbms_lob.open(l_clob, dbms_lob.lob_readwrite);   
      write_clob(
         '<dataexchange-set'
         || ' id="' || m_id || '"'
         || ' office-id="' || m_office_id || '"'
         || case (m_realtime_source_id is null)
               when true  then null
               when false then ' realtime-source-id="' || m_realtime_source_id || '"'
            end
         || '>'
         || case (m_description is null)
               when true  then null
               when false then '<description>' || m_description || '</description>'
            end
         || '<datastore-ref id="' || m_datastore_1 || '"/>'
         || '<datastore-ref id="' || m_datastore_2 || '"/>'
         || case (m_timewindow is null)
               when true  then null
               when false then m_timewindow.get_xml().getstringval()
            end
         || case (m_max_interpolate is null)
               when true  then null
               when false then m_max_interpolate.get_xml().getstringval()
            end);
            
         if (m_ts_mapping_set is not null) then
            declare
               l_mappingset_clob clob := m_ts_mapping_set.get_xml().getclobval(); 
            begin
               dbms_lob.copy(
                  l_clob, 
                  l_mappingset_clob, 
                  dbms_lob.getlength(l_mappingset_clob), 
                  dbms_lob.getlength(l_clob)+1, 
                  1);
            end;
         end if;
         
         write_clob('</dataexchange-set>');
      dbms_lob.close(l_clob);
      return xmltype(l_clob);   
   end;
   
end;
/
show errors;

create type xchg_dataexchange_set_tab_t is table of xchg_dataexchange_set_t;
/

create type xchg_datastore_t as object(
   m_subtype varchar2(32),
   m_id      varchar2(16),
   
   member function get_subtype return varchar2,
   
   member function get_id return varchar2,
   
   member function get_xml return xmltype
) not instantiable not final;
/
show errors;

create type body xchg_datastore_t
as
   member function get_subtype return varchar2
   is
   begin
      return m_subtype;
   end;
   
   member function get_id return varchar2
   is
   begin
      return m_id;
   end;
   
   member function get_xml return xmltype
   is
   begin
      return null;
   end;
   
end;
/
show errors;   

create type xchg_datastore_tab_t is table of xchg_datastore_t;
/

create type xchg_oracle_t under xchg_datastore_t(
   m_host        varchar2(255),
   m_sid         varchar2( 64),
   m_description varchar2(256),
   
   constructor function xchg_oracle_t(
      p_id          in varchar2,
      p_host        in varchar2,
      p_sid         in varchar2,
      p_description in varchar2 default null)
      return self as result,
   
   constructor function xchg_oracle_t(
      p_node in xmltype)
      return self as result,
      
   member procedure init(
      p_id          in varchar2,
      p_host        in varchar2,
      p_sid         in varchar2,
      p_description in varchar2),

   member function get_host return varchar2,
   
   member function get_sid return varchar2,
   
   member function get_description return varchar2,
         
   overriding member function get_xml return xmltype
);
/
show errors;

create type body xchg_oracle_t
as
   
   constructor function xchg_oracle_t(
      p_id          in varchar2,
      p_host        in varchar2,
      p_sid         in varchar2,
      p_description in varchar2 default null)
      return self as result
   is
   begin
      init(p_id, p_host, p_sid, p_description);
      return;
   end;
   
   constructor function xchg_oracle_t(
      p_node in xmltype)
      return self as result
   is
      l_node        xmltype;
      l_id          varchar2( 16);
      l_host        varchar2(255);
      l_sid         varchar2( 64);
      l_description varchar2(256) := null;
   begin
      if p_node.getrootelement() != 'oracle' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'oracle datastore node'); 
      end if;
      l_node := p_node.extract('/*/@id');
      if l_node is null then
         cwms_err.raise('ERROR', 'Oracle datastore node has missing id attribute');
      end if;
      l_id := l_node.getstringval();
      l_node := p_node.extract('/*/host/node()');
      if l_node is null then
         cwms_err.raise('ERROR', 'Oracle datastore node has missing host subnode');
      end if;
      l_host := cwms_util.strip(l_node.getstringval());
      l_node := p_node.extract('/*/sid/node()');
      if l_node is null then
         cwms_err.raise('ERROR', 'Oracle datastore node has missing sid subnode');
      end if;
      l_sid := cwms_util.strip(l_node.getstringval());
      l_node := p_node.extract('/*/description/node()');
      if l_node is not null then
         l_description := cwms_util.strip(l_node.getstringval());
      end if;
      init(l_id, l_host, l_sid, l_description);
      return;
   end;
      
   member procedure init(
      p_id          in varchar2,
      p_host        in varchar2,
      p_sid         in varchar2,
      p_description in varchar2)
   is
      i             pls_integer;
      -- same patterns as in XML schema
      l_host_patterns cwms_util.str_tab_t := cwms_util.str_tab_t(
         /* ip v4    */ '(\d{1,3}[.]){3}\d{1,3}',
         /* ip v6 #1 */ '([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}',
         /* ip v6 #2 */ '([a-fA-F0-9]{1,4}:){1,7}:',
         /* ip v6 #3 */ ':(:[a-fA-F0-9]{1,4}){1,7}',
         /* ip v6 #4 */ '([a-fA-F0-9]{1,4}:){1,6}(:[a-fA-F0-9]{1,4}){1}',
         /* ip v6 #5 */ '([a-fA-F0-9]{1,4}:){1,5}(:[a-fA-F0-9]{1,4}){1,2}',
         /* ip v6 #6 */ '([a-fA-F0-9]{1,4}:){1,4}(:[a-fA-F0-9]{1,4}){1,3}',
         /* ip v6 #7 */ '([a-fA-F0-9]{1,4}:){1,3}(:[a-fA-F0-9]{1,4}){1,4}',
         /* ip v6 #8 */ '([a-fA-F0-9]{1,4}:){1,2}(:[a-fA-F0-9]{1,4}){1,5}',
         /* ip v6 #9 */ '([a-fA-F0-9]{1,4}:){1}(:[a-fA-F0-9]{1,4}){1,6}',
         /* DNS      */ '([a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9][.])*[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9]');
   begin
      if length(p_id) > 16 then
         cwms_err.raise('ERROR', 'Oracle datastore id must not exceed 16 characters.');
      end if;
      if length(p_host) > 255 then
         cwms_err.raise('ERROR', 'Oracle datastore host must not exceed 255 characters.');
      end if;
      i := 0;
      loop
         i := i + 1;
         if i > l_host_patterns.count then
            cwms_err.raise('INVALID_ITEM', p_host, 'internet host specification');
         end if;
         exit when regexp_instr(p_host, l_host_patterns(i)) = 1 and
                   regexp_instr(p_host, l_host_patterns(i), 1, 1, 1) = length(p_host) + 1;
      end loop;
      if length(p_sid) > 64 then
         cwms_err.raise('ERROR', 'Oracle datastore SID must not exceed 64 characters.');
      end if;
      if length(p_description) > 256 then
         cwms_err.raise('ERROR', 'Oracle datastore description must not exceed 256 characters.');
      end if;
      m_subtype     := 'xchg_oracle_t';
      m_id          := p_id;
      m_host        := p_host;
      m_sid         := p_sid;
      m_description := p_description;
   end;

   member function get_host return varchar2
   is
   begin
      return m_host;
   end;
   
   member function get_sid return varchar2
   is
   begin
      return m_sid;
   end;
   
   member function get_description return varchar2
   is
   begin
      return m_description;
   end;
         
   overriding member function get_xml return xmltype
   is
   begin
      return xmltype(
         '<oracle id="' || m_id || '">'
         || '<host>' || m_host || '</host>'
         || '<sid>' || m_sid || '</sid>'
         || case (m_description is null)
               when true  then null
               when false then '<description>' || m_description || '</description>'
            end
         || '</oracle>');
   end;
end;
/
show errors;

create type xchg_dssfilemanager_t under xchg_datastore_t(
   m_host        varchar2(255),
   m_port        integer,
   m_filepath    varchar2(255),
   m_description varchar2(256),
   m_office_id   varchar2( 16),
   
   constructor function xchg_dssfilemanager_t(
      p_id          in varchar2,
      p_host        in varchar2,
      p_port        in integer,
      p_filepath    in varchar2,
      p_description in varchar2 default null,
      p_office_id   in varchar2 default null)
      return self as result,
   
   constructor function xchg_dssfilemanager_t(
      p_node in xmltype)
      return self as result,
      
   member procedure init(
      p_id          in varchar2,
      p_host        in varchar2,
      p_port        in integer,
      p_filepath    in varchar2,
      p_description in varchar2,
      p_office_id   in varchar2),

   member function get_host return varchar2,
   
   member function get_port return integer,
   
   member function get_filepath return varchar2,
   
   member function get_description return varchar2,
   
   member function get_office_id return varchar2,
         
   overriding member function get_xml return xmltype
);
/
show errors;

create type body xchg_dssfilemanager_t
as
   
   constructor function xchg_dssfilemanager_t(
      p_id          in varchar2,
      p_host        in varchar2,
      p_port        in integer,
      p_filepath    in varchar2,
      p_description in varchar2,
      p_office_id   in varchar2)
      return self as result
   is
   begin
      init(
         p_id, 
         p_host, 
         p_port, 
         p_filepath, 
         p_description, 
         nvl(p_office_id, cwms_util.user_office_id));
      return;
   end;
   
   constructor function xchg_dssfilemanager_t(
      p_node in xmltype)
      return self as result
   is
      l_node        xmltype;
      l_id          varchar2(16);
      l_host        varchar2(255);
      l_port        integer;
      l_filepath    varchar2(255);
      l_description varchar2(256) := null;
      l_office_id   varchar2( 16) := null;
   begin
      if p_node.getrootelement() != 'dssfilemanager' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'dssfilemanager datastore node'); 
      end if;
      l_node := p_node.extract('/*/@id');
      if l_node is null then
         cwms_err.raise('ERROR', 'DSS file manager datastore node has missing id attribute');
      end if;
      l_id := l_node.getstringval();
      l_node := p_node.extract('/*/host/node()');
      if l_node is null then
         cwms_err.raise('ERROR', 'DSS file manager datastore node has missing host subnode');
      end if;
      l_host := cwms_util.strip(l_node.getstringval());
      l_node := p_node.extract('/*/port/node()');
      if l_node is null then
         cwms_err.raise('ERROR', 'DSS file manager datastore node has missing port subnode');
      end if;
      l_port := l_node.getnumberval();
      l_node := p_node.extract('/*/filepath/node()');
      if l_node is null then
         cwms_err.raise('ERROR', 'DSS file manager datastore node has missing filepath subnode');
      end if;
      l_filepath := cwms_util.strip(l_node.getstringval());
      l_node := p_node.extract('/*/description/node()');
      if l_node is not null then
         l_description := cwms_util.strip(l_node.getstringval());
      end if;
      l_node := p_node.extract('/*/@office-id');
      if l_node is not null then
         l_office_id := cwms_util.strip(l_node.getstringval());
      else
         l_office_id := cwms_util.user_office_id;
      end if;
      init(l_id, l_host, l_port, l_filepath, l_description, l_office_id);
      return;
   end;
      
   member procedure init(
      p_id          in varchar2,
      p_host        in varchar2,
      p_port        in integer,
      p_filepath    in varchar2,
      p_description in varchar2,
      p_office_id   in varchar2)
   is
      i             pls_integer;
      -- same patterns as in XML schema
      l_host_patterns cwms_util.str_tab_t := cwms_util.str_tab_t(
         /* ip v4    */ '(\d{1,3}[.]){3}\d{1,3}',
         /* ip v6 #1 */ '([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}',
         /* ip v6 #2 */ '([a-fA-F0-9]{1,4}:){1,7}:',
         /* ip v6 #3 */ ':(:[a-fA-F0-9]{1,4}){1,7}',
         /* ip v6 #4 */ '([a-fA-F0-9]{1,4}:){1,6}(:[a-fA-F0-9]{1,4}){1}',
         /* ip v6 #5 */ '([a-fA-F0-9]{1,4}:){1,5}(:[a-fA-F0-9]{1,4}){1,2}',
         /* ip v6 #6 */ '([a-fA-F0-9]{1,4}:){1,4}(:[a-fA-F0-9]{1,4}){1,3}',
         /* ip v6 #7 */ '([a-fA-F0-9]{1,4}:){1,3}(:[a-fA-F0-9]{1,4}){1,4}',
         /* ip v6 #8 */ '([a-fA-F0-9]{1,4}:){1,2}(:[a-fA-F0-9]{1,4}){1,5}',
         /* ip v6 #9 */ '([a-fA-F0-9]{1,4}:){1}(:[a-fA-F0-9]{1,4}){1,6}',
         /* DNS      */ '([a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9][.])*[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9]');
      l_file_pattern varchar2(32) := '([$/]|[a-zA-Z]:/)[^/]+(/[^/]+)*';         
   begin
      if length(p_id) > 16 then
         cwms_err.raise('ERROR', 'DSS file manager datastore id must not exceed 16 characters.');
      end if;
      if length(p_host) > 255 then
         cwms_err.raise('ERROR', 'DSS file manager datastore host must not exceed 255 characters.');
      end if;
      i := 0;
      loop
         i := i + 1;
         if i > l_host_patterns.count then
            cwms_err.raise('INVALID_ITEM', p_host, 'internet host specification');
         end if;
         exit when regexp_instr(p_host, l_host_patterns(i)) = 1 and
                   regexp_instr(p_host, l_host_patterns(i), 1, 1, 1) = length(p_host) + 1;
      end loop;
      if p_port < 1 or p_port > 65535 then
         cwms_err.raise('IVALID_ITEM', p_port, 'internet port'); 
      end if;
      if length(p_filepath) > 255 then
         cwms_err.raise('ERROR', 'DSS file manager datastore file path must not exceed 255 characters.');
      end if;
      if regexp_instr(p_filepath, l_file_pattern) != 1 or
         regexp_instr(p_filepath, l_file_pattern, 1, 1, 1) != length(p_filepath) + 1
      then
         cwms_err.raise('INVALID_ITEM', p_filepath, 'file pathname');
      end if;
      if length(p_description) > 256 then
         cwms_err.raise('ERROR', 'DSS file manager datastore description must not exceed 256 characters.');
      end if;
      m_subtype     := 'xchg_dssfilemanager_t';
      m_host        := p_host;
      m_port        := p_port;
      m_filepath    := p_filepath;
      m_id          := p_id;
      m_description := p_description;
      m_office_id   := p_office_id;
   end;

   member function get_host return varchar2
   is
   begin
      return m_host;
   end;
   
   member function get_port return integer
   is
   begin
      return m_port;
   end;
   
   member function get_filepath return varchar2
   is
   begin
      return m_filepath;
   end;
   
   member function get_description return varchar2
   is
   begin
      return m_description;
   end;
         
   member function get_office_id return varchar2
   is
   begin
      return m_office_id;
   end;
   
   overriding member function get_xml return xmltype
   is
   begin
      return xmltype(
         '<dssfilemanager id="' || m_id || '"' 
         || case (m_office_id is null)
               when true  then null
               when false then ' office-id="' || m_office_id || '"'
            end 
         || '><host>' || m_host || '</host>'
         || '<port>' || m_port || '</port>'
         || '<filepath>' || m_filepath || '</filepath>'
         || case (m_description is null)
               when true  then null
               when false then '<description>' || m_description || '</description>'
            end
         || '</dssfilemanager>');
   end;
   
end;
/
show errors;

create type xchg_office_t as object(
   m_id          varchar2( 16),
   m_name        varchar2( 80),
   m_description varchar2(256),
   
   constructor function xchg_office_t(
      p_id          in varchar2,
      p_name        in varchar2,
      p_description in varchar2 default null)
      return self as result,
      
   constructor function xchg_office_t(
      p_node in xmltype)
      return self as result,
      
   member procedure init(
      p_id          in varchar2,
      p_name        in varchar2,
      p_description in varchar2),
      
   member function get_id return varchar2,
      
   member function get_name return varchar2,
      
   member function get_description return varchar2,
   
   member function get_xml return xmltype
);
/
show errors;

create type body xchg_office_t
as
   
   constructor function xchg_office_t(
      p_id          in varchar2,
      p_name        in varchar2,
      p_description in varchar2 default null)
      return self as result
   is
   begin
      init(p_id, p_name, p_description);
      return;
   end;
      
   constructor function xchg_office_t(
      p_node in xmltype)
      return self as result
   is
      l_node        xmltype;
      l_id          varchar2( 16);
      l_name        varchar2( 80);
      l_description varchar2(256) := null;
   begin
      if p_node.getrootelement() != 'office' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'office node');
      end if;
      l_node := p_node.extract('/*/@id');
      if l_node is null then
         cwms_err.raise('ERROR', 'Office node is missing id attribute.');
      end if;
      l_id := l_node.getstringval();
      l_node := p_node.extract('/*/name/node()');
      if l_node is null then
         cwms_err.raise('ERROR', 'Office node is missing name subnode.');
      end if;
      l_name := cwms_util.strip(l_node.getstringval());
      l_node := p_node.extract('/*/description/node()');
      if l_node is not null then
         l_description := cwms_util.strip(l_node.getstringval());
      end if;
      init(l_id, l_name, l_description);
      return;            
   end;
      
   member procedure init(
      p_id          in varchar2,
      p_name        in varchar2,
      p_description in varchar2)
   is
   begin
      if length(m_id) > 16 then
         cwms_err.raise('ERROR', 'Office id must not exceed 16 characters.');
      end if;
      if length(m_name) > 80 then
         cwms_err.raise('ERROR', 'Office name must not exceed 80 characters.');
      end if;
      if length(m_description) > 256 then
         cwms_err.raise('ERROR', 'Office description must not exceed 256 characters.');
      end if;
      m_id          := p_id;
      m_name        := p_name;
      m_description := p_description;
   end;
      
   member function get_id return varchar2
   is
   begin
      return m_id;
   end;
      
   member function get_name return varchar2
   is
   begin
      return m_name;
   end;
      
   member function get_description return varchar2
   is
   begin
      return m_description;
   end;
   
   member function get_xml return xmltype
   is
   begin
      return xmltype(
         '<office id="' || m_id || '">'
         || '<name>' || m_name || '</name>'
         || case (m_description is null)
               when true  then null
               when false then '<description>' || m_description || '</description>'
            end
         || '</office>');
   end;
   
end;
/
show errors;

create type xchg_office_tab_t is table of xchg_office_t;
/

create type xchg_dataexchange_conf_t as object(
   m_subtype           varchar2(32),
   m_offices           xchg_office_tab_t,
   m_datastores        xchg_datastore_tab_t,
   m_dataexchange_sets xchg_dataexchange_set_tab_t,
   
   constructor function xchg_dataexchange_conf_t(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t)
      return self as result,
      
   constructor function xchg_dataexchange_conf_t(
      p_node in xmltype)
      return self as result,
      
   member procedure init(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t),
      
   member procedure check_validity(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t,
      p_is_cwms           in boolean default false),
   
   member function get_subtype return varchar2,
      
   member procedure get_offices(
      p_offices out xchg_office_tab_t),
      
   member procedure get_datastores(
      p_datastores out xchg_datastore_tab_t),
      
   member procedure get_dataexchange_sets(
      p_dataexchange_sets out xchg_dataexchange_set_tab_t),
      
   member function get_xml return xmltype,
   
   member function get_xml$ return xmltype
) not final;
/
show errors;

create type body xchg_dataexchange_conf_t
as
   
   constructor function xchg_dataexchange_conf_t(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t)
      return self as result
   is
   begin
      init(p_offices, p_datastores, p_dataexchange_sets);
      return;
   end;
      
   constructor function xchg_dataexchange_conf_t(
      p_node in xmltype)
      return self as result
   is
      l_node              xmltype;
      l_nodes             xmltype;
      l_count             pls_integer;
      l_offices           xchg_office_tab_t;
      l_datastores        xchg_datastore_tab_t;
      l_dataexchange_sets xchg_dataexchange_set_tab_t;
   begin
      if p_node.getrootelement() != 'dataexchange-configuration' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'dataexchange-configuration node.');
      end if;
      l_nodes := p_node.extract('/*/*[local-name()="office"]');
      if l_nodes is null then
         cwms_err.raise('ERROR', 'dataexchange-configuration has no office nodes.'); 
      end if;
      select count(*) into l_count from table(xmlsequence(l_nodes));
      l_offices := xchg_office_tab_t();
      l_offices.extend(l_count);
      for i in 1..l_count loop
         l_offices(i) := new xchg_office_t(l_nodes.extract('*['||i||']'));
      end loop;
      
      l_nodes := p_node.extract('/*/*[local-name()="datastore"]');
      if l_nodes is null then
         cwms_err.raise('ERROR', 'dataexchange-configuration has no datastore nodes.'); 
      end if;
      select count(*) into l_count from table(xmlsequence(l_nodes));
      l_datastores := xchg_datastore_tab_t();
      l_datastores.extend(l_count);
      for i in 1..l_count loop
         l_node := l_nodes.extract('*['||i||']/*[1]');
         case l_node.extract('local-name()').getstringval()
            when 'dssfilemanager' then 
               l_datastores(i) := new xchg_dssfilemanager_t(l_node);
            when 'oracle' 
               then l_datastores(i) := new xchg_oracle_t(l_node);
            else
               cwms_err.raise('INVALID_ITEM', l_node.extract('local-name()').getstringval(), 'datastore subnode.'); 
         end case;
      end loop;
      
      l_nodes := p_node.extract('/*/*[local-name()="dataexchange-set"]');
      if l_nodes is null then
         cwms_err.raise('ERROR', 'dataexchange-configuration has no dataexchange-set nodes.'); 
      end if;
      select count(*) into l_count from table(xmlsequence(l_nodes));
      l_dataexchange_sets := xchg_dataexchange_set_tab_t();
      l_dataexchange_sets.extend(l_count);
      for i in 1..l_count loop
         l_dataexchange_sets(i) := new xchg_dataexchange_set_t(l_nodes.extract('*['||i||']'));
      end loop;
      
      init(l_offices, l_datastores, l_dataexchange_sets);
      return;
   end;
      
   member procedure init(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t)
   is
   begin
      check_validity(p_offices, p_datastores, p_dataexchange_sets);
      m_subtype           := 'xchg_dataexchange_conf_t';
      m_offices           := p_offices;
      m_datastores        := p_datastores;
      m_dataexchange_sets := p_dataexchange_sets;
   end;
   
   member procedure check_validity(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t,
      p_is_cwms           in boolean)
   is
      type b_vc64 is table of boolean index by varchar2(64);
      type b_vc64_vc16 is table of b_vc64 index by varchar2(16);
      l_datastores       b_vc64;
      l_offices          b_vc64;
      l_dx_sets          b_vc64;
      l_realtime_exports b_vc64_vc16;
      l_realtime_imports b_vc64_vc16;
      l_office           varchar2(64);
      l_datastore_1      varchar2(64);
      l_datastore_2      varchar2(64);
      l_dx_set_id        varchar2(64);
      l_export_ds        varchar2(64);
      l_import_ds        varchar2(64);
      l_dataexchange_set xchg_dataexchange_set_t;
      l_mapping_set      xchg_ts_mapping_set_t;
      l_mappings         xchg_ts_mapping_tab_t;
      l_ts               xchg_timeseries_tab_t := xchg_timeseries_tab_t();
      i                  pls_integer;
      j                  pls_integer;
   begin
      if p_dataexchange_sets is null then 
         return; 
      end if;
      l_ts.extend(2);
      if p_offices is null or p_offices.count < 1 then
         cwms_err.raise('ERROR', 'Data exchange configuration must have at least one office.');
      end if;
      i := p_offices.first;
      loop
         if l_offices.exists(p_offices(i).get_id()) then
            cwms_err.raise('ERROR', 'Data exchange configuration contains duplicate office ids.');
         end if;
         l_offices(p_offices(i).get_id()) := true;
         i := p_offices.next(i);
         exit when i is null;
      end loop;
      if p_datastores is null or p_datastores.count < 2 then
         cwms_err.raise('ERROR', 'Data exchange configuration must have at least two datastores.');
      end if;
      i := p_datastores.first;
      loop
         if l_datastores.exists(p_datastores(i).get_id()) then
            cwms_err.raise('ERROR', 'Data exchange configuration contains duplicate datastore ids.');
         end if;
         if p_datastores(i).get_subtype() = 'xchg_dssfilemanager_t' then
            if not l_offices.exists(treat(p_datastores(i) as xchg_dssfilemanager_t).get_office_id()) then
              cwms_err.raise(
                 'ERROR', 
                 'Data exchange configuration is missing an office ('
                 || treat(p_datastores(i) as xchg_dssfilemanager_t).get_office_id()
                 || ') that is referenced by a DSS file manager. ');
            end if;
         end if;
         l_datastores(p_datastores(i).get_id()) := true;
         i := p_datastores.next(i);
         exit when i is null;
      end loop;
      i := p_dataexchange_sets.first;
      loop
         l_dataexchange_set := p_dataexchange_sets(i);
         if not l_offices.exists(l_dataexchange_set.get_office_id()) then
           cwms_err.raise('ERROR', 'Data exchange configuration is missing an office that is referenced by a data exchange set');
         end if;
         if l_dx_sets.exists(l_dataexchange_set.get_office_id() || ',' || l_dataexchange_set.get_id()) then
           cwms_err.raise('ERROR', 'Data exchange configuration contains duplicate data exchange sets (office-id, id)');
         end if;
         l_dx_sets(l_dataexchange_set.get_office_id() || ',' || l_dataexchange_set.get_id()) := true;
         l_dataexchange_set.get_datastores(l_datastore_1, l_datastore_2);
         if not (l_datastores.exists(l_datastore_1) and l_datastores.exists(l_datastore_2)) then
            cwms_err.raise('ERROR', 'Data exchange configuration is missing a datastore that is referenced by a data exchange set.');
         end if;
         if l_dataexchange_set.get_realtime_source_id() is not null then
            l_dx_set_id := l_dataexchange_set.get_id();
            if l_dataexchange_set.get_realtime_source_id() = l_datastore_1 then
               l_export_ds := l_datastore_1;
               l_import_ds := l_datastore_2;
            else
               l_export_ds := l_datastore_2;
               l_import_ds := l_datastore_1;
            end if;
            if l_export_ds = l_datastore_1 then
               l_import_ds := l_datastore_2;
            else
               l_import_ds := l_datastore_1;
            end if;
            l_dataexchange_set.get_ts_mapping_set(l_mapping_set);
            if l_mapping_set is not null then
               l_mapping_set.get_mappings(l_mappings);
               j := l_mappings.first;
               loop
                  l_mappings(j).get_timeseries(l_ts(1), l_ts(2));
                  for k in 1..2 loop
                     if l_ts(k).get_datastore_id() = l_export_ds then
                        if l_realtime_imports.exists(l_export_ds) and 
                           l_realtime_imports(l_export_ds).exists(l_ts(k).get_timeseries()) 
                        then
                           cwms_err.raise('XCHG_TS_ERROR', l_ts(k).get_timeseries(), l_dx_set_id, '<set name not available>');
                        end if;
                        l_realtime_exports(l_export_ds)(l_ts(k).get_timeseries()) := true;
                     elsif l_ts(k).get_datastore_id() = l_import_ds then
                        if l_realtime_exports.exists(l_import_ds) and 
                           l_realtime_exports(l_import_ds).exists(l_ts(k).get_timeseries()) 
                        then
                           cwms_err.raise('XCHG_TS_ERROR', l_ts(k).get_timeseries(), l_dx_set_id, '<set name not available>');
                        end if;
                        l_realtime_imports(l_import_ds)(l_ts(k).get_timeseries()) := true;
                     end if;
                  end loop;
                  j := l_mappings.next(j);
                  exit when j is null;
               end loop;
            end if;
         end if;
         if p_is_cwms then
            l_dataexchange_set.get_ts_mapping_set(l_mapping_set);
            if l_mapping_set is not null then
               l_mapping_set.check_validity(true);
            end if;
         end if;
         i := p_dataexchange_sets.next(i);
         exit when i is null;
      end loop;
   end;
      
   member function get_subtype return varchar2
   is
   begin
      return m_subtype;
   end;
      
   member procedure get_offices(
      p_offices out xchg_office_tab_t)
   is
   begin
      p_offices := m_offices;
   end;
      
   member procedure get_datastores(
      p_datastores out xchg_datastore_tab_t)
   is
   begin
      p_datastores := m_datastores;
   end;
      
   member procedure get_dataexchange_sets(
      p_dataexchange_sets out xchg_dataexchange_set_tab_t)
   is
   begin
      p_dataexchange_sets := m_dataexchange_sets;
   end;
      
   member function get_xml return xmltype
   is
   begin
      return get_xml$;
   end;
   
   member function get_xml$ return xmltype
   is
      l_xmlclob clob;
      l_xml     xmltype;
      i         pls_integer;
            
      procedure write_xml(p_data varchar2) 
      is
      begin
         dbms_lob.writeappend(l_xmlclob, length(p_data), p_data);
      end;
      
      procedure write_xml(p_data xmltype) 
      is
         l_data_clob clob; 
         l_text      varchar2(32767);
         l_length    integer := 32767;
         l_offset    integer := 1;
      begin
         l_data_clob := p_data.getclobval;
         dbms_lob.open(l_data_clob, dbms_lob.lob_readonly);
         loop
            dbms_lob.read(l_data_clob, l_length, l_offset, l_text);
            if l_length > 0 then
               write_xml(l_text);
            end if;
            exit when l_length != 32767;
            l_offset := l_offset + l_length;
         end loop;
         dbms_lob.close(l_data_clob);
         dbms_lob.freetemporary(l_data_clob);
      end;
      
   begin
      dbms_lob.createtemporary(l_xmlclob, true, dbms_lob.call);
      dbms_lob.open(l_xmlclob, dbms_lob.lob_readwrite);
      write_xml('<?xml version = "1.0" encoding = "UTF-8"?>');
      write_xml('<!-- Generated by Oracle at ' || to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') || ' -->');
      write_xml('<dataexchange-configuration 
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/dataexchangeconfiguration.xsd">');
      i := m_offices.first;
      loop
         write_xml(m_offices(i).get_xml());
         i := m_offices.next(i);
         exit when i is null;
      end loop;
      i := m_datastores.first;
      loop
         write_xml('<datastore>');
         write_xml(m_datastores(i).get_xml());
         write_xml('</datastore>');
         i := m_datastores.next(i);
         exit when i is null;
      end loop;
      i := m_dataexchange_sets.first;
      loop
         write_xml(m_dataexchange_sets(i).get_xml());
         i := m_dataexchange_sets.next(i);
         exit when i is null;
      end loop;
      write_xml('</dataexchange-configuration>');
      dbms_lob.close(l_xmlclob);
      l_xml := xmltype(l_xmlclob);
      dbms_lob.freetemporary(l_xmlclob);
      return l_xml;
   end;
      
end;
/
show errors;

create type xchg_cwms_dataexchange_conf_t under xchg_dataexchange_conf_t(
   constructor function xchg_cwms_dataexchange_conf_t(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t,
      p_dummy             in varchar2)
      return self as result,
      
   constructor function xchg_cwms_dataexchange_conf_t(
      p_node  in xmltype,
      p_dummy in varchar2)
      return self as result,
      
   overriding member procedure init(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t),

   overriding member function get_xml return xmltype
);
/
show errors;

create type body xchg_cwms_dataexchange_conf_t
as
   constructor function xchg_cwms_dataexchange_conf_t(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t,
      p_dummy             in varchar2)
      return self as result
   is
   begin
      init(p_offices, p_datastores, p_dataexchange_sets);
      return;
   end;
      
   constructor function xchg_cwms_dataexchange_conf_t(
      p_node  in xmltype,
      p_dummy in varchar2)
      return self as result
   is
      l_node              xmltype;
      l_nodes             xmltype;
      l_count             pls_integer;
      l_xpath             varchar2(64);
      l_offices           xchg_office_tab_t;
      l_datastores        xchg_datastore_tab_t;
      l_dataexchange_sets xchg_dataexchange_set_tab_t;
   begin
      if p_node.getrootelement() != 'cwms-dataexchange-configuration' then
         cwms_err.raise('INVALID_ITEM', p_node.getrootelement(), 'cwms-dataexchange-configuration node.');
      end if;
      l_nodes := p_node.extract('/*/*[local-name()="office"]');
      if l_nodes is null then
         l_offices := null; 
      else
         select count(*) into l_count from table(xmlsequence(l_nodes));
         l_offices := xchg_office_tab_t();
         l_offices.extend(l_count);
         for i in 1..l_count loop
            l_offices(i) := new xchg_office_t(l_nodes.extract('*['||i||']'));
         end loop;
      end if;
      
      l_nodes := p_node.extract('/*/*[local-name()="datastore"]');
      if l_nodes is null then
         l_datastores := null;
      else 
         select count(*) into l_count from table(xmlsequence(l_nodes));
         l_datastores := xchg_datastore_tab_t();
         l_datastores.extend(l_count);
         for i in 1..l_count loop
            l_node := xmltype(l_nodes.extract('*['||i||']/*[1]').getstringval()); -- to force non-fragment
            case l_node.getrootelement()
               when 'dssfilemanager' then 
                  l_datastores(i) := new xchg_dssfilemanager_t(l_node);
               when 'oracle' 
                  then l_datastores(i) := new xchg_oracle_t(l_node);
               else
                  cwms_err.raise('INVALID_ITEM', l_node.getrootelement(), 'datastore subnode.'); 
            end case;
         end loop;
      end if;
      
      l_nodes := p_node.extract('/*/*[local-name()="dataexchange-set"]');
      if l_nodes is null then
         l_dataexchange_sets := null;
      else 
         select count(*) into l_count from table(xmlsequence(l_nodes));
         l_dataexchange_sets := xchg_dataexchange_set_tab_t();
         l_dataexchange_sets.extend(l_count);
         for i in 1..l_count loop
            l_dataexchange_sets(i) := new xchg_dataexchange_set_t(l_nodes.extract('*['||i||']'));
         end loop;
      end if;
      
      init(l_offices, l_datastores, l_dataexchange_sets);
      return;
   end;
      
   overriding member procedure init(
      p_offices           in xchg_office_tab_t,
      p_datastores        in xchg_datastore_tab_t,
      p_dataexchange_sets in xchg_dataexchange_set_tab_t)
   is
      l_ts_mapping_set    xchg_ts_mapping_set_t;
   begin
      begin
         self.check_validity(p_offices, p_datastores, p_dataexchange_sets, true);
      exception
         when others then
            if sqlcode < -20000 then
               raise_application_error(sqlcode, replace(sqlerrm, 'Data exchange', 'CWMS data exchange'), TRUE);
            else
               raise;
            end if;
      end;
      m_subtype           := 'xchg_cwms_dataexchange_conf_t';
      m_offices           := p_offices;
      m_datastores        := p_datastores;
      m_dataexchange_sets := p_dataexchange_sets;
   end;
      
   overriding member function get_xml return xmltype
   is
   begin
      return xmltype(
         replace(self.get_xml$().getclobval(), 
                 'dataexchange-configuration', 
                 'cwms-dataexchange-configuration'));
   end;
end;
/
show errors;
commit;

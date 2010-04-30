CREATE OR REPLACE package body cwms_xchg as

--------------------------------------------------------------------------------
-- PROCEDURE GET_QUEUE_NAMES
--
   procedure get_queue_names(
      p_status_queue_name   out nocopy varchar2,
      p_realtime_queue_name out nocopy varchar2,
      p_office_id           in  varchar2 default null)
   is
      l_office_id varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   begin
      p_status_queue_name   := l_office_id || '_STATUS';
      p_realtime_queue_name := l_office_id || '_REALTIME_OPS';
   end get_queue_names;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION DB_DATASTORE_ID()
--
   function db_datastore_id
      return varchar2
   is
      l_db_name      v$database.name%type;
      l_datastore_id varchar2(64);
   begin
      select name into l_db_name from v$database;
      l_datastore_id := utl_inaddr.get_host_name || ':' || l_db_name;
      l_datastore_id := substr(l_datastore_id, -(least(length(l_datastore_id), 16)));
      l_datastore_id := substr(l_datastore_id, regexp_instr(l_datastore_id, '[a-zA-Z0-9]'));
      return l_datastore_id;
   end db_datastore_id;


--------------------------------------------------------------------------------
-- NUMBER FUNCTION GET_XCHG_SET_CODE(...)
--
   function get_xchg_set_code(
      p_xchg_set_id in varchar2,
      p_office_id   in varchar2 default null)
      return number
   is
      l_xchg_set_code number(10);
   begin
      select xchg_set_code
        into l_xchg_set_code
        from at_xchg_set
       where office_code = cwms_util.get_office_code(p_office_id)
         and upper(xchg_set_id) = upper(p_xchg_set_id);

      return l_xchg_set_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_office_id || '/' || p_xchg_set_id,
            'HEC-DSS exchange set');
   end get_xchg_set_code;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION GET_XCHG_DIRECTION_CODE(VARCHAR2)
--
   function get_xchg_direction_code(
      p_xchg_direction_id varchar2)
      return number
   is
      l_xchg_direction_code number;
   begin
      select dss_xchg_direction_code
        into l_xchg_direction_code
        from cwms_dss_xchg_direction
       where upper(dss_xchg_direction_id) = upper(p_xchg_direction_id);

   return l_xchg_direction_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_xchg_direction_id,
            'Data exchange direction');

   end get_xchg_direction_code;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION GET_DSS_PARAMETER_TYPE_CODE(VARCHAR2)
--
   function get_dss_parameter_type_code(
      p_dss_parameter_type_id in varchar2)
      return number
   is
      l_dss_parameter_type_code number(10);
   begin
      select dss_parameter_type_code
        into l_dss_parameter_type_code
        from cwms_dss_parameter_type
       where dss_parameter_type_id = upper(p_dss_parameter_type_id);

      return l_dss_parameter_type_code;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM',p_dss_parameter_type_id,'DSS parameter type');

   end get_dss_parameter_type_code;

--------------------------------------------------------------------------------
-- PROCEDURE PARSE_DSS_PATHNAME(...)
--
   procedure parse_dss_pathname(
      p_a_pathname_part out nocopy varchar2,
      p_b_pathname_part out nocopy varchar2,
      p_c_pathname_part out nocopy varchar2,
      p_d_pathname_part out nocopy varchar2,
      p_e_pathname_part out nocopy varchar2,
      p_f_pathname_part out nocopy varchar2,
      p_pathname        in  varchar2)
   is
      l_parts str_tab_t := str_tab_t();
   begin
      l_parts := cwms_util.split_text(upper(cwms_util.strip(p_pathname)), '/');
      if l_parts.count != 8 or l_parts(1) is not null or l_parts(8) is not null then
         cwms_err.raise('INVALID_ITEM', p_pathname, 'HEC-DSS pathname');
      end if;
      p_a_pathname_part := l_parts(2);
      p_b_pathname_part := l_parts(3);
      p_c_pathname_part := l_parts(4);
      p_d_pathname_part := l_parts(5);
      p_e_pathname_part := l_parts(6);
      p_f_pathname_part := l_parts(7);
   end parse_dss_pathname;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_PATHNAME(...)
--
   function make_dss_pathname(
      p_a_pathname_part   in   varchar2,
      p_b_pathname_part   in   varchar2,
      p_c_pathname_part   in   varchar2,
      p_d_pathname_part   in   varchar2,
      p_e_pathname_part   in   varchar2,
      p_f_pathname_part   in   varchar2)
      return varchar2
   is
   begin
      return '/'
         || p_a_pathname_part
         || '/'
         || p_b_pathname_part
         || '/'
         || p_c_pathname_part
         || '/'
         || p_d_pathname_part
         || '/'
         || p_e_pathname_part
         || '/'
         || p_f_pathname_part
         || '/';
   end;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_TS_ID(...)
--
   function make_dss_ts_id(
      p_pathname          in   varchar2,
      p_parameter_type    in   varchar2 default null,
      p_units             in   varchar2 default null,
      p_time_zone         in   varchar2 default null,
      p_tz_usage          in   varchar2 default null)
      return varchar2
   is
      l_dss_ts_id   varchar2(512);
   begin
      l_dss_ts_id := upper(p_pathname);

      if p_parameter_type is not null then
         l_dss_ts_id := l_dss_ts_id || ';Type=' || upper(p_parameter_type);
      end if;

      if p_units is not null then
         l_dss_ts_id := l_dss_ts_id || ';Units=' || p_units;
      end if;

      if p_time_zone is not null then
         l_dss_ts_id := l_dss_ts_id || ';Time_zone=' || p_time_zone;
      end if;

      if p_tz_usage is not null then
         l_dss_ts_id := l_dss_ts_id || ';Times=' || upper(p_tz_usage);
      end if;

      return l_dss_ts_id;

   end make_dss_ts_id;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_TS_ID(...)
--
   function make_dss_ts_id(
      p_a_pathname_part   in   varchar2,
      p_b_pathname_part   in   varchar2,
      p_c_pathname_part   in   varchar2,
      p_d_pathname_part   in   varchar2,
      p_e_pathname_part   in   varchar2,
      p_f_pathname_part   in   varchar2,
      p_parameter_type    in   varchar2 default null,
      p_units             in   varchar2 default null,
      p_time_zone         in   varchar2 default null,
      p_tz_usage          in   varchar2 default null)
      return varchar2
   is
   begin
      return make_dss_ts_id(
         make_dss_pathname(
            p_a_pathname_part,
            p_b_pathname_part,
            p_c_pathname_part,
            p_d_pathname_part,
            p_e_pathname_part,
            p_f_pathname_part),
         p_parameter_type,
         p_units,
         p_time_zone,
         p_tz_usage);

   end make_dss_ts_id;

---------------------------------------------------------------------------------
-- PROCEDURE DELETE_DSS_XCHG_SET(NUMBER)
--
   procedure delete_dss_xchg_set(
      p_dss_xchg_set_code in number)
   is
   begin
      delete
        from at_xchg_dss_ts_mappings
       where xchg_set_code = p_dss_xchg_set_code;

      delete
        from at_xchg_set
       where xchg_set_code = p_dss_xchg_set_code;

   end delete_dss_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE DELETE_DSS_XCHG_SET(...)
--
   procedure delete_dss_xchg_set(
      p_dss_xchg_set_id in varchar2,
      p_office_id       in varchar2 default null)
   is
   begin
      delete_dss_xchg_set(get_xchg_set_code(p_dss_xchg_set_id, p_office_id));
   end delete_dss_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE RENAME_DSS_XCHG_SET(...)
--
   procedure rename_dss_xchg_set(
      p_old_xchg_set_id       in   varchar2,
      p_new_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null)
   is
      l_xchg_set_code number(10);
      already_exists exception;
      pragma exception_init (already_exists, -00001);
   begin
      l_xchg_set_code := get_xchg_set_code(p_old_xchg_set_id, p_office_id);
      update at_xchg_set
         set xchg_set_id = p_new_xchg_set_id
       where xchg_set_code = l_xchg_set_code;
   exception
      when already_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'HEC-DSS exchange set',
            p_office_id || '/' || p_new_xchg_set_id);
   end rename_dss_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE DUPLICATE_DSS_XCHG_SET(...)
--
   procedure duplicate_dss_xchg_set(
      p_old_xchg_set_id   in   varchar2,
      p_new_xchg_set_id   in   varchar2,
      p_office_id         in   varchar2 default null)
   is
      l_xchg_set_code number(10) := get_xchg_set_code(p_old_xchg_set_id, p_office_id);
      l_table_row at_xchg_set%rowtype;
      already_exists exception;
      pragma exception_init(already_exists, -00001);
   begin
      select *
        into l_table_row
        from at_xchg_set
       where xchg_set_code = l_xchg_set_code;

      select cwms_seq.nextval into l_table_row.xchg_set_code from dual;
      l_table_row.xchg_set_id   := p_new_xchg_set_id;

      insert into at_xchg_set values l_table_row;
   exception
      when already_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'HEC-DSS exchange set',
            p_office_id || '/' || p_new_xchg_set_id);
   end duplicate_dss_xchg_set;

--------------------------------------------------------------------------------
-- PROCEDURE UPDATE_DSS_XCHG_SET_TIME(...)
--
   procedure update_dss_xchg_set_time(
      p_xchg_set_code    in  number,
      p_last_update      in  timestamp)
   is
      l_last_update at_xchg_set.last_update%type := null;
   begin
      select last_update
        into l_last_update
        from at_xchg_set
       where xchg_set_code = p_xchg_set_code;

      if l_last_update is not null and l_last_update > p_last_update then
         cwms_err.raise(
            'INVALID_ITEM',
            to_char(p_last_update),
            'timestamp for this exhange set because it pre-dates the existing last update time of '
            || to_char(l_last_update));
      end if;

      update at_xchg_set
         set last_update = p_last_update
       where xchg_set_code = p_xchg_set_code;

   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', 'Specfied value', 'exchange set code.');
   end update_dss_xchg_set_time;

--------------------------------------------------------------------------------
-- PROCEDURE LOG_CONFIGURATION_XML
--
   procedure log_configuration_xml(
      p_xml       in clob,
      p_direction in varchar2)
   is
      pragma autonomous_transaction;
      l_date_time varchar2(19) := to_char(sysdate, 'yyyy/mm/dd hh24:mi:ss');
      l_clob_id   varchar2(36);
      l_number    number;
      already_exists exception;
      pragma exception_init (already_exists, -00001);
   begin
      if upper(substr(p_direction, 1, 1)) = 'I' then
         l_clob_id := '/dataexchange/incoming-configuration';
      elsif upper(substr(p_direction, 1, 1)) = 'O' then
         l_clob_id := '/dataexchange/outgoing-configuration';
      else
         l_clob_id := '/dataexchange/configuration';
      end if;
      l_number := cwms_text.store_text(p_xml, l_clob_id, l_date_time, 'F');
      commit;
   end log_configuration_xml;
--------------------------------------------------------------------------------
-- CLOB FUNCTION GET_DSS_XCHG_SETS(...)
--
   function get_dss_xchg_sets(
      p_dss_filemgr_url in varchar2 default null, -- not used
      p_dss_file_name   in varchar2 default null, -- not used
      p_dss_xchg_set_id in varchar2 default null, -- '%' if null
      p_office_id       in varchar2 default null) -- user's office if null
      return clob
   is
      type vc16_by_pi is table of varchar2(16) index by pls_integer;
      c_dss_to_oracle        constant integer := 1;
      c_oracle_to_dss        constant integer := 2;
      l_tab                  constant varchar2(1) := chr(9);
      l_nl                   constant varchar2(1) := chr(10);
      l_xml                  clob;
      l_level                binary_integer := 0;
      l_indent_str           varchar2(256) := null;
      -- l_dss_filemgr_url_mask varchar2(256);
      -- l_dss_file_name_mask   varchar2(256);
      l_xchg_set_id_mask     varchar2(256);
      l_office_id_mask       varchar2(256);
      l_xchg_set_codes       number_tab_t := new number_tab_t();
      l_mapping_codes        number_tab_t := new number_tab_t();
      l_pos                  integer;
      l_office_ids           vc16_by_pi;
      l_datastore_id         varchar2(32);
      l_interpolate_units    varchar2(16);
      l_db_name              v$database.name%type;
      l_oracle_id            varchar2(256);
      l_line_break           boolean := true;

      procedure write_xml(p_data varchar2) is begin
         if l_line_break then
            if l_indent_str is not null then
               dbms_lob.writeappend(l_xml, length(l_indent_str), l_indent_str);
            end if;
         end if;
         dbms_lob.writeappend(l_xml, length(p_data), p_data);
         l_line_break := substr(p_data, length(p_data), 1) = l_nl;
      end;

      procedure writeln_xml(p_data varchar2) is begin
         write_xml(p_data || l_nl);
      end;

      procedure indent is begin
         l_level := l_level + 1;
         l_indent_str := l_indent_str || l_tab;
      end;

      procedure dedent is begin
         l_level := l_level - 1;
         l_indent_str := substr(l_indent_str, 1, l_level * length(l_tab));
      end;

      function rinstr(p_str varchar2, p_substr varchar2) return integer is
         i integer;
      begin
         for i in reverse 1..length(p_str) loop
            if substr(p_str, i, length(p_substr)) = p_substr  then
               return i;
            end if;
         end loop;
         return 0;
      end;

   begin
      -- l_dss_filemgr_url_mask := cwms_util.normalize_wildcards(regexp_replace(p_dss_filemgr_url, '/DssFileManger$', '', 1, 1, 'i'));
      -- l_dss_file_name_mask   := cwms_util.normalize_wildcards(p_dss_file_name);
      l_xchg_set_id_mask     := cwms_util.normalize_wildcards(nvl(p_dss_xchg_set_id, '%'), true);
      l_office_id_mask       := cwms_util.normalize_wildcards(nvl(p_office_id, cwms_util.user_office_id), true);
      ----------------------------------------------
      -- retrieve all the matching xchg set codes --
      ----------------------------------------------
      for rec in (
         select xchg_set_code
           from at_xchg_set
          where upper(xchg_set_id) like upper(l_xchg_set_id_mask)
            and office_code in (
                   select office_code
                     from cwms_office
                    where upper(office_id) like upper(l_office_id_mask) escape '\'))
      loop
         l_xchg_set_codes.extend;
         l_xchg_set_codes(l_xchg_set_codes.last) := rec.xchg_set_code;
      end loop;
      ---------------------------------------------
      -- retrieve all the matching mapping codes --
      ---------------------------------------------
      for rec in (
         select mapping_code
           from at_xchg_dss_ts_mappings
          where xchg_set_code in (select * from table(l_xchg_set_codes)))
      loop
         l_mapping_codes.extend();
         l_mapping_codes(l_mapping_codes.last) := rec.mapping_code;
      end loop;
      --------------------------------------------------------------------
      -- refine the xchg set codes to only those with matching mappings --
      --------------------------------------------------------------------
      l_xchg_set_codes.delete;
      for rec in (
         select xchg_set_code
           from at_xchg_dss_ts_mappings
          where mapping_code in (select * from table(l_mapping_codes)))
      loop
         l_xchg_set_codes.extend;
         l_xchg_set_codes(l_xchg_set_codes.last) := rec.xchg_set_code;
      end loop;
      -----------------------------
      -- output the root element --
      -----------------------------
      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      writeln_xml('<?xml version="1.0" encoding="UTF-8"?>');
      writeln_xml('<cwms-dataexchange-configuration');
      indent;
      writeln_xml('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
      writeln_xml('xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/dataexchangeconfiguration.xsd">');
      ------------------------
      -- output the offices --
      ------------------------
      for rec in (
         select office_code,
                office_id,
                long_name
           from cwms_office
          where office_code in (
                   select office_code
                     from at_xchg_set
                    where xchg_set_code in (select * from table(l_xchg_set_codes)))
       order by office_id)
      loop
         l_office_ids(rec.office_code) := rec.office_id;
         writeln_xml('<office id="'||rec.office_id||'">');
         indent;
         writeln_xml('<name>'||rec.long_name||'</name>');
         dedent;
         writeln_xml('</office>');
      end loop;
      if l_office_ids.count = 0 then
        declare
          rec cwms_office%rowtype;
        begin
          select *
            into rec
            from cwms_office
           where office_code = cwms_util.user_office_code;
          l_office_ids(rec.office_code) := rec.office_id;
          writeln_xml('<office id="'||rec.office_id||'">');
          indent;
          writeln_xml('<name>'||rec.long_name||'</name>');
          dedent;
          writeln_xml('</office>');
        end;
      end if;
      ---------------------------
      -- output the datastores --
      ---------------------------
      select name into l_db_name from v$database;
      l_oracle_id := db_datastore_id;
      writeln_xml('<datastore>');
      indent;
      writeln_xml('<oracle id="'||l_oracle_id||'">');
      indent;
      writeln_xml('<host>'||utl_inaddr.get_host_address||'</host>');
      writeln_xml('<sid>'||l_db_name||'</sid>');
      dedent;
      writeln_xml('</oracle>');
      dedent;
      writeln_xml('</datastore>');
      for rec in (
         select office_code,
                datastore_id,
                dss_filemgr_url,
                dss_file_name,
                description
           from at_xchg_datastore_dss
          where datastore_code in (
                  select datastore_code
                    from at_xchg_set
                   where xchg_set_code in (select * from table(l_xchg_set_codes)))
       order by datastore_id)
      loop
         writeln_xml('<datastore>');
         indent;
         writeln_xml('<dssfilemanager id="'||rec.datastore_id||'" office-id="'||l_office_ids(rec.office_code)||'">');
         indent;
         l_pos := rinstr(rec.dss_filemgr_url, ':');
         writeln_xml('<host>'||substr(rec.dss_filemgr_url, 3, l_pos-3)||'</host>');
         writeln_xml('<port>'||substr(rec.dss_filemgr_url, l_pos+1)||'</port>');
         writeln_xml('<filepath>'||rec.dss_file_name||'</filepath>');
         if rec.description is not null then
            writeln_xml('<description>'||rec.description||'</description>');
         end if;
         dedent;
         writeln_xml('</dssfilemanager>');
         dedent;
         writeln_xml('</datastore>');
      end loop;
      ----------------------------------
      -- output the dataexchange sets --
      ----------------------------------
      for rec in (
         select xchg_set_code,
                datastore_code,
                office_code,
                xchg_set_id,
                description,
                start_time,
                end_time,
                interpolate_count,
                interpolate_units,
                realtime
           from at_xchg_set
          where xchg_set_code in (select * from table(l_xchg_set_codes))
       order by xchg_set_id)
      loop
         select datastore_id
           into l_datastore_id
           from at_xchg_datastore_dss
          where datastore_code = rec.datastore_code;
         write_xml('<dataexchange-set id="'||rec.xchg_set_id||'" office-id="'||l_office_ids(rec.office_code)||'"');
         if rec.realtime = c_oracle_to_dss then
            write_xml(' realtime-source-id="'||l_oracle_id||'"');
         elsif rec.realtime = c_dss_to_oracle then
            write_xml(' realtime-source-id="'||l_datastore_id||'"');
         end if;
         writeln_xml('>');
         indent;
         if rec.description is not null then
            writeln_xml('<description>'||rec.description||'</description>');
         end if;
         writeln_xml('<datastore-ref id="'||l_oracle_id||'"/>');
         writeln_xml('<datastore-ref id="'||l_datastore_id||'"/>');
         if rec.start_time is not null then
            writeln_xml('<timewindow>');
            indent;
            writeln_xml('<starttime>'||rec.start_time||'</starttime>');
            writeln_xml('<endtime>'||rec.end_time||'</endtime>');
            dedent;
            writeln_xml('</timewindow>');
         end if;
         if rec.interpolate_units is not null then
            select interpolate_units_id
              into l_interpolate_units
              from cwms_interpolate_units
             where interpolate_units_code = rec.interpolate_units;
            writeln_xml('<max-interpolate units="'||l_interpolate_units||'">'||rec.interpolate_count||'</max-interpolate>');
         end if;
         ---------------------------------------------------
         -- output the mappings for this dataexchange set --
         ---------------------------------------------------
         writeln_xml('<ts-mapping-set>');
         indent;
         for rec2 in (
            select v.db_office_id,
                   v.cwms_ts_id,
                   m.cwms_ts_code,
                   m.a_pathname_part,
                   m.b_pathname_part,
                   m.c_pathname_part,
                   m.e_pathname_part,
                   m.f_pathname_part,
                   p.dss_parameter_type_id,
                   m.unit_id,
                   z.time_zone_name,
                   u.tz_usage_id
              from at_xchg_dss_ts_mappings m,
                   mv_cwms_ts_id v,
                   cwms_dss_parameter_type p,
                   cwms_time_zone z,
                   cwms_tz_usage u
             where m.mapping_code in (select * from table(l_mapping_codes))
               and m.xchg_set_code = rec.xchg_set_code
               and v.ts_code = m.cwms_ts_code
               and p.dss_parameter_type_code = m.dss_parameter_type_code
               and z.time_zone_code = m.time_zone_code
               and u.tz_usage_code = m.tz_usage_code
            order by v.cwms_ts_id)
         loop
            writeln_xml('<ts-mapping>');
            indent;
            writeln_xml('<cwms-timeseries datastore-id="'
                        ||l_oracle_id
                        || case
                             when rec2.db_office_id != l_office_ids(rec.office_code) then
                                '" office-id="'
                                || rec2.db_office_id
                             else
                                null
                           end
                        ||'">'
                        ||rec2.cwms_ts_id
                        ||'</cwms-timeseries>');
            writeln_xml('<dss-timeseries datastore-id="'
                        || l_datastore_id
                        || '" type="'
                        || rec2.dss_parameter_type_id
                        || '" units="'
                        || rec2.unit_id
                        || '" timezone="'
                        || rec2.time_zone_name
                        || '" tz-usage="'
                        || rec2.tz_usage_id
                        || '">'
                        || make_dss_pathname(
                              rec2.a_pathname_part,
                              rec2.b_pathname_part,
                              rec2.c_pathname_part,
                              null,
                              rec2.e_pathname_part,
                              rec2.f_pathname_part)
                        || '</dss-timeseries>');
            dedent;
            writeln_xml('</ts-mapping>');
         end loop;
         dedent;
         writeln_xml('</ts-mapping-set>');
         dedent;
         writeln_xml('</dataexchange-set>');
      end loop;
      dedent;
      writeln_xml('</cwms-dataexchange-configuration>');

      dbms_lob.close(l_xml);
      log_configuration_xml(l_xml, 'out');
      return l_xml;

   end get_dss_xchg_sets;

--------------------------------------------------------------------------------
   procedure validate_realtime_direction
   is
      cursor l_conflicts_cur is
         select map1.cwms_ts_code ts_code_1,
                map2.cwms_ts_code ts_code_2,
                set1.xchg_set_id id_1,
                set2.xchg_set_id id_2,
                v.cwms_ts_id ts_id
           from at_xchg_dss_ts_mappings map1,
                at_xchg_dss_ts_mappings map2,
                at_xchg_set set1,
                at_xchg_set set2,
                mv_cwms_ts_id v
          where map2.cwms_ts_code = map1.cwms_ts_code
            and set1.xchg_set_code = map1.xchg_set_code
            and set2.xchg_set_code = map2.xchg_set_code
            and set1.realtime is not null
            and set2.realtime is not null
            and set1.realtime != set1.realtime
            and v.ts_code = map1.cwms_ts_code;
   begin
      for rec in l_conflicts_cur loop
         cwms_err.raise('XCHG_TS_ERROR', rec.ts_id, rec.id_2, rec.id_1);
      end loop;
   end validate_realtime_direction;

--------------------------------------------------------------------------------
   procedure validate_dss_units
   is
      l_invalid_units varchar2(256) := '';
      cursor l_invalid_units_cur
      is
         select unit_id
           from at_xchg_dss_ts_mappings
          where unit_id not in (select unit_id from cwms_unit
                                union
                                select alias_id unit_id
                                  from at_unit_alias
                                 where db_office_code in (select db_office_code
                                                            from cwms_office
                                                           where office_id = 'CWMS'
                                                              or office_id = cwms_util.user_office_id
                                                         )
                               )
       order by unit_id;
   begin
      for rec in l_invalid_units_cur loop
         l_invalid_units := l_invalid_units || ', ' || rec.unit_id;
      end loop;
      if length(l_invalid_units) > 0 then
         cwms_err.raise('INVALID_ITEM', substr(l_invalid_units, 3), 'DSS units');
      end if;
   end validate_dss_units;

--------------------------------------------------------------------------------
   procedure validate_dss_consistency
   is
      type l_indexed_text_t is table of varchar2(32767) index by varchar2(512);
      type l_indexed_bool_t is table of boolean index by varchar2(512);
      l_fileurl     at_xchg_datastore_dss.dss_filemgr_url%type;
      l_filename    at_xchg_datastore_dss.dss_file_name%type;
      l_fqpathnames l_indexed_bool_t;
      l_param_types l_indexed_text_t;
      l_units       l_indexed_text_t;
      l_time_zones  l_indexed_text_t;
      l_tz_usages   l_indexed_text_t;
      l_fqpathname  varchar2(512);
      l_item1       varchar2(128);
      l_item2       varchar2(128);
      l_errormsg    varchar2(32767);
      l_parts       str_tab_t;
      lf            constant varchar2(1) := chr(10);
      tab           constant varchar2(1) := chr(9);
      cursor l_comparison_cur
      is
         select s.datastore_code file1,
             m.a_pathname_part a1,
             m.b_pathname_part b1,
             m.c_pathname_part c1,
             m.e_pathname_part e1,
             m.f_pathname_part f1,
             m.dss_parameter_type_code type1,
             m.unit_id unit1,
             m.time_zone_code time_zone1,
             m.tz_usage_code tz_usage1,
             lag(s.datastore_code,  1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) file2,
             lag(m.a_pathname_part, 1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) a2,
             lag(m.b_pathname_part, 1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) b2,
             lag(m.c_pathname_part, 1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) c2,
             lag(m.e_pathname_part, 1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) e2,
             lag(m.f_pathname_part, 1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) f2,
             lag(m.dss_parameter_type_code, 1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) type2,
             lag(m.unit_id,         1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) unit2,
             lag(m.time_zone_code,  1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) time_zone2,
             lag(m.tz_usage_code,   1, 0) over (order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code) tz_usage2
        from at_xchg_set s,
             at_xchg_dss_ts_mappings m
       where s.xchg_set_code = m.xchg_set_code
    order by s.datastore_code, m.a_pathname_part, m.b_pathname_part, m.c_pathname_part, m.e_pathname_part, m.f_pathname_part, m.dss_parameter_type_code, m.unit_id, m.time_zone_code, m.tz_usage_code;
   begin
      for rec in l_comparison_cur loop
         if rec.file2 = rec.file1
            and nvl(rec.a2, '@') = nvl(rec.a1, '@')
            and rec.b2 = rec.b1
            and rec.c2 = rec.c1
            and rec.e2 = rec.e1
            and nvl(rec.f2, '@') = nvl(rec.f1, '@')
            and (rec.type2 != rec.type1
                 or upper(rec.unit2) != upper(rec.unit1)
                 or rec.time_zone2 != rec.time_zone1
                 or rec.tz_usage2 != rec.tz_usage1)
         then
            select dss_filemgr_url, dss_file_name into l_fileurl, l_filename from at_xchg_datastore_dss where datastore_code = rec.file1;
            l_fqpathname := l_fileurl || '/' || l_filename || ':/' || rec.a1 || '/' || rec.b1 || '/' || rec.c1 || '//' || rec.e1 || '/' || rec.f1 || '/';
            if rec.type2 != rec.type1 then
               l_item1 := '[' || rec.type1 || ']';
               l_item2 := '[' || rec.type2 || ']';
               l_fqpathnames(l_fqpathname) := true;
               if not l_param_types.exists(l_fqpathname) then
                  l_param_types(l_fqpathname) := l_item1 || l_item2;
               else
                  if instr(l_param_types(l_fqpathname), l_item1) = 0 then
                     l_param_types(l_fqpathname) := l_param_types(l_fqpathname) || l_item1;
                  end if;
                  if instr(l_param_types(l_fqpathname), l_item2) = 0 then
                     l_param_types(l_fqpathname) := l_param_types(l_fqpathname) || l_item2;
                  end if;
               end if;
            end if;
            if upper(rec.unit2) != upper(rec.unit1) then
               l_item1 := '[' || rec.unit1 || ']';
               l_item2 := '[' || rec.unit2 || ']';
               l_fqpathnames(l_fqpathname) := true;
               if not l_units.exists(l_fqpathname) then
                  l_units(l_fqpathname) := l_item1 || l_item2;
               else
                  if instr(l_units(l_fqpathname), l_item1) = 0 then
                     l_units(l_fqpathname) := l_units(l_fqpathname) || l_item1;
                  end if;
                  if instr(l_units(l_fqpathname), l_item2) = 0 then
                     l_units(l_fqpathname) := l_units(l_fqpathname) || l_item2;
                  end if;
               end if;
            end if;
            if rec.time_zone2 != rec.time_zone1 then
               l_item1 := '[' || rec.time_zone1 || ']';
               l_item2 := '[' || rec.time_zone2 || ']';
               l_fqpathnames(l_fqpathname) := true;
               if not l_time_zones.exists(l_fqpathname) then
                  l_time_zones(l_fqpathname) := l_item1 || l_item2;
               else
                  if instr(l_time_zones(l_fqpathname), l_item1) = 0 then
                     l_time_zones(l_fqpathname) := l_time_zones(l_fqpathname) || l_item1;
                  end if;
                  if instr(l_time_zones(l_fqpathname), l_item2) = 0 then
                     l_time_zones(l_fqpathname) := l_time_zones(l_fqpathname) || l_item2;
                  end if;
               end if;
            end if;
            if rec.tz_usage2 != rec.tz_usage1 then
               l_item1 := '[' || rec.tz_usage1 || ']';
               l_item2 := '[' || rec.tz_usage2 || ']';
               l_fqpathnames(l_fqpathname) := true;
               if not l_tz_usages.exists(l_fqpathname) then
                  l_tz_usages(l_fqpathname) := l_item1 || l_item2;
               else
                  if instr(l_tz_usages(l_fqpathname), l_item1) = 0 then
                     l_tz_usages(l_fqpathname) := l_tz_usages(l_fqpathname) || l_item1;
                  end if;
                  if instr(l_tz_usages(l_fqpathname), l_item2) = 0 then
                     l_tz_usages(l_fqpathname) := l_tz_usages(l_fqpathname) || l_item2;
                  end if;
               end if;
            end if;
         end if;
      end loop;
      if l_fqpathnames.count > 0 then
         l_errormsg := 'DSS Consistency Errors:' || lf;
         l_fqpathname := l_fqpathnames.first;
         while l_fqpathname is not null loop
            l_errormsg := l_errormsg || tab || l_fqpathname || lf;
            if l_param_types.exists(l_fqpathname) then
               l_errormsg := l_errormsg || tab || tab || 'Multiple parameter types: ';
               l_parts := cwms_util.split_text(substr(l_param_types(l_fqpathname), 2, length(l_param_types(l_fqpathname)) - 2), '][');
               for i in 1..l_parts.count loop
                  select dss_parameter_type_id
                    into l_item1
                    from cwms_dss_parameter_type
                   where dss_parameter_type_code = to_number(l_parts(i));
                  if i = 1 then
                     l_errormsg := l_errormsg || l_item1;
                  else
                     l_errormsg := l_errormsg || ', ' || l_item1;
                  end if;
               end loop;
               l_errormsg := l_errormsg || lf;
            end if;
            if l_units.exists(l_fqpathname) then
               l_errormsg := l_errormsg || tab || tab || 'Multiple units: ' || replace(replace(substr(l_units(l_fqpathname), 2, length(l_units(l_fqpathname)) - 2), ']', ','), '[', ' ') || lf;
            end if;
            if l_time_zones.exists(l_fqpathname) then
               l_errormsg := l_errormsg || tab || tab || 'Multiple time zones: ';
               l_parts := cwms_util.split_text(substr(l_time_zones(l_fqpathname), 2, length(l_time_zones(l_fqpathname)) - 2), '][');
               for i in 1..l_parts.count loop
                  select time_zone_name
                    into l_item1
                    from cwms_time_zone
                   where time_zone_code = to_number(l_parts(i));
                  if i = 1 then
                     l_errormsg := l_errormsg || l_item1;
                  else
                     l_errormsg := l_errormsg || ', ' || l_item1;
                  end if;
               end loop;
               l_errormsg := l_errormsg || lf;
            end if;
            if l_tz_usages.exists(l_fqpathname) then
               l_errormsg := l_errormsg || tab || tab || 'Multiple time zone usages: ';
               l_parts := cwms_util.split_text(substr(l_tz_usages(l_fqpathname), 2, length(l_tz_usages(l_fqpathname)) - 2), '][');
               for i in 1..l_parts.count loop
                  select tz_usage_id
                    into l_item1
                    from cwms_tz_usage
                   where tz_usage_code = to_number(l_parts(i));
                  if i = 1 then
                     l_errormsg := l_errormsg || l_item1;
                  else
                     l_errormsg := l_errormsg || ', ' || l_item1;
                  end if;
               end loop;
               l_errormsg := l_errormsg || lf;
            end if;
            l_fqpathname := l_fqpathnames.next(l_fqpathname);
         end loop;
         cwms_err.raise('ERROR', l_errormsg);
      end if;
   end validate_dss_consistency;

--------------------------------------------------------------------------------
   procedure store_dataexchange_conf(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_dx_config         in  clob,
      p_store_rule        in  varchar2 default 'MERGE')
   is
      type bool_by_str is table of boolean index by varchar2(256);
      type str_by_str is table of varchar2(512) index by varchar2(512);
      type int_by_id16 is table of integer index by varchar2(16);
      type dss_filemgr_t is record(
         code        integer,
         id          varchar2(32),
         office      varchar2(16),
         url         varchar2(256),
         filename    varchar2(256),
         description varchar2(256));
      type dataexchange_set_t is record(
         code         integer,
         id           varchar2(32),
         office       varchar2(16),
         datastore_id varchar2(32),
         start_time   varchar2(32),
         end_time     varchar2(32),
         interp_count integer,
         interp_units varchar2(16),
         realtime_dir varchar2(16),
         description  varchar2(256));
      type mapping_t is record(
         code        integer,
         a_path_part varchar2(64),
         b_path_part varchar2(64),
         c_path_part varchar2(64),
         e_path_part varchar2(64),
         f_path_part varchar2(64),
         param_type  varchar2(8),
         units       varchar2(16),
         time_zone   varchar2(28),
         tz_usage    varchar2(16));
      type dss_filemgr_by_id is table of dss_filemgr_t index by varchar2(49);
      l_mappings           str_tab_t;
      l_parts              str_tab_t;
      l_parts2             str_tab_t;
      l_offices            int_by_id16;
      l_dss_filemgrs       dss_filemgr_by_id;
      l_id                 varchar2(32);
      l_office_id          varchar2(16);
      l_ts_office_id       varchar2(16);
      l_host               varchar2(256);
      l_port               varchar2(5);
      l_url                varchar2(262);
      l_filename           varchar2(256);
      l_description        varchar2(256);
      l_pos                integer;
      l_xchg_set_text      varchar2(32767);
      l_xchg_set_1         dataexchange_set_t;
      l_xchg_set_2         dataexchange_set_t;
      l_xchg_set_code      number(10) := null;
      l_datastore_id       varchar2(32);
      l_set_id             varchar2(32);
      l_start_time         varchar2(32);
      l_end_time           varchar2(32);
      l_interp_count       integer;
      l_interp_units       varchar2(16);
      l_realtime_dir       varchar2(16);
      l_last_update        timestamp;
      l_map_1              mapping_t;
      l_map_2              mapping_t;
      d_path_part          varchar2(64);
      l_pathname           varchar2(391);
      l_type_id            varchar2(8);
      l_units_id           varchar2(16);
      l_time_zone_id       varchar2(28);
      l_tz_usage_id        varchar2(16);
      l_tsid               varchar2(193);
      l_att_text           varchar2(512);
      l_attributes         str_by_str;
      l_ts_code            number;
      l_compound_id        varchar(49);
      l_mappings_specified number_tab_t := new number_tab_t();
      l_dss_filemgr_urls   bool_by_str;
      l_sets_inserted      number := 0;
      l_sets_updated       number := 0;
      l_mappings_inserted  number := 0;
      l_mappings_updated   number := 0;
      l_mappings_deleted   number := 0;
      l_dss_filemgr        dss_filemgr_t;
      l_text               varchar2(32767);
      l_can_insert         boolean := false;
      l_can_update         boolean := false;
      l_can_delete         boolean := false;

      -------------------
      -- local modules --
      -------------------
      function unquote(p_str in varchar2) return varchar2 is
      begin
         return ltrim(rtrim(p_str, '''"'), '''"');
      end;

      function trim(p_str in varchar2) return varchar2 is
         whitespace constant varchar2(4) := ' '||chr(9)||chr(10)||chr(13);
      begin
         return ltrim(rtrim(p_str, whitespace), whitespace);
      end;

      function split(
         p_str       in varchar2,
         p_delimiter in varchar2 default null,
         p_max_split in integer  default null)
      return str_tab_t
      is
      begin
         return cwms_util.split_text(p_str, p_delimiter, p_max_split);
      end;

      function split(
         p_clob      in clob,
         p_delimiter in varchar2 default null,
         p_max_split in integer  default null)
      return str_tab_t
      is
      begin
         return cwms_util.split_text(p_clob, p_delimiter, p_max_split);
      end;

      function make_attributes(p_att_str in varchar2) return str_by_str
      is
         l_attr    str_by_str;
         l_att_str varchar2(256) := trim(p_att_str);
         l_len     binary_integer := length(l_att_str);
         parts     str_tab_t;
         parts2    str_tab_t;
      begin
         if substr(l_att_str, l_len) = '/' then
            l_att_str := trim(substr(l_att_str, 1, l_len-1));
         end if;
         parts := split(trim(l_att_str));
         for j in 1..parts.count loop
            parts2 := split(parts(j), '=', 1);
            l_attr(trim(parts2(1))) := unquote(trim(parts2(2)));
         end loop;
         return l_attr;
      end;

   begin
      -----------------------------
      -- validate the store rule --
      -----------------------------
      if substr('MERGE',      1, length(p_store_rule)) = p_store_rule then
         l_can_insert := true;
         l_can_update := true;
      elsif substr('INSERT',  1, length(p_store_rule)) = p_store_rule then
         l_can_insert := true;
      elsif substr('UPDATE',  1, length(p_store_rule)) = p_store_rule then
         l_can_update := true;
      elsif substr('REPLACE', 1, length(p_store_rule)) = p_store_rule then
         l_can_insert := true;
         l_can_update := true;
         l_can_delete := true;
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_store_rule,
            'HEC-DSS exhange set store rule, should be [I]nsert, [U]pdate, [R]eplace, or [M]erge');
      end if;
      -------------------------------------------------
      -- log the incoming XML for debugging purposes --
      -------------------------------------------------
      log_configuration_xml(p_dx_config, 'in');
      -----------------------------------------------------------------------
      -- split the incoming XML around the ts-mapping element opening tags --
      -----------------------------------------------------------------------
      l_mappings := split(p_dx_config, '<ts-mapping>');
      -------------------------
      -- process the offices --
      -------------------------
      l_parts := split(l_mappings(1), '<office ');
      for i in 2..l_parts.count loop
         l_att_text := split(l_parts(i), '>')(1);
         l_attributes := make_attributes(l_att_text);
         l_offices(l_attributes('id')) := null;
         select office_code
           into l_offices(l_attributes('id'))
           from cwms_office
          where upper(office_id) = upper(l_attributes('id'));
      end loop;
      ----------------------------
      -- process the datastores --
      ----------------------------
      l_parts := split(split(l_mappings(1), '<dataexchange-set ')(1), '<dssfilemanager ');
      for i in 2..l_parts.count loop
         l_att_text     := split(l_parts(i), '>')(1);
         l_attributes   := make_attributes(l_att_text);
         l_datastore_id := l_attributes('id');
         l_filename     := trim(split(split(l_parts(i), 'filepath>')(2), '<')(1));
         l_host         := trim(split(split(l_parts(i), 'host>')(2), '<')(1));
         l_port         := trim(split(split(l_parts(i), 'port>')(2), '<')(1));
         if instr(l_parts(i), '<description>') > 0 then
            l_description := trim(split(split(l_parts(i), 'description>')(2), '<')(1));
         else
            l_description := null;
         end if;
         if l_attributes.exists('office-id') then
            l_office_id := l_attributes('office-id');
         else
            if l_offices.count > 1 then
               cwms_err.raise('ERROR', 'dssfilemanagager with no office-id attribute is ambiguous');
            end if;
            l_office_id := l_offices.first;
         end if;
         l_compound_id := l_datastore_id||'@'||l_office_id;
         l_url := '//' || l_host || ':' || l_port;
         l_dss_filemgrs(l_compound_id).code        := null;
         l_dss_filemgrs(l_compound_id).id          := l_datastore_id;
         l_dss_filemgrs(l_compound_id).office      := l_office_id;
         l_dss_filemgrs(l_compound_id).url         := l_url;
         l_dss_filemgrs(l_compound_id).filename    := l_filename;
         l_dss_filemgrs(l_compound_id).description := l_description;

         cwms_xchg.retrieve_dss_datastore(
            l_dss_filemgrs(l_compound_id).code,
            l_dss_filemgr.url,
            l_dss_filemgr.filename,
            l_dss_filemgr.description,
            l_datastore_id,
            l_office_id);
         if l_dss_filemgrs(l_compound_id).code is null then
            if l_can_insert then
               cwms_xchg.store_dss_datastore(
                  l_dss_filemgrs(l_compound_id).code,
                  l_datastore_id,
                  l_url,
                  l_filename,
                  l_description,
                  'T',
                  l_office_id);
            end if;
         else
            if l_can_update and
               (l_dss_filemgr.url != l_url or
                l_dss_filemgr.filename != l_filename or
                nvl(l_dss_filemgr.description, '@') != nvl(l_description, '@'))
            then
               update at_xchg_datastore_dss
                  set dss_filemgr_url = l_url,
                      dss_file_name = l_filename,
                      description = l_description
                where datastore_code = l_dss_filemgrs(l_compound_id).code;
            end if;
         end if;
         l_dss_filemgr_urls(l_url) := true;
      end loop;
      --------------------------
      -- process the mappings --
      --------------------------
      for i in 1..l_mappings.count loop
         if instr(l_mappings(i), '<dataexchange-set') > 0 then
            ---------------------------------------------------------------------
            -- process any dataexchange set we find when we split the mappings --
            ---------------------------------------------------------------------
            l_xchg_set_text := split(l_mappings(i), '<dataexchange-set')(2);
            l_att_text      := split(l_xchg_set_text, '>')(1);
            l_attributes    := make_attributes(l_att_text);
            l_set_id        := l_attributes('id');
            l_office_id     := l_attributes('office-id');
            if l_attributes.exists('realtime-source-id') then
               if l_dss_filemgrs.exists(l_attributes('realtime-source-id')||'@'||l_office_id) then
                  l_realtime_dir := 'DssToOracle';
               else
                  l_realtime_dir := 'OracleToDss';
               end if;
            else
               l_realtime_dir := null;
            end if;
            l_att_text    := split(split(l_xchg_set_text, 'datastore-ref')(2), '/>')(1);
            l_attributes  := make_attributes(l_att_text);
            l_id          := l_attributes('id');
            l_compound_id := l_id||'@'||l_office_id;
            if l_dss_filemgrs.exists(l_compound_id) then
               l_xchg_set_1.datastore_id := l_compound_id;
            else
               l_att_text   := split(split(l_xchg_set_text, 'datastore-ref')(3), '/>')(1);
               l_attributes := make_attributes(l_att_text);
               l_id := l_attributes('id');
               l_compound_id := l_id||'@'||l_office_id;
               if l_dss_filemgrs.exists(l_compound_id) then
                  l_xchg_set_1.datastore_id := l_compound_id;
               else
                  cwms_err.raise(
                     'ERROR',
                     'dataexchange-set '
                     ||l_set_id
                     ||' for office '
                     ||l_office_id
                     ||' references non-existent datastore');
               end if;
            end if;
            if instr(l_xchg_set_text, '<description>') > 0  then
               l_description := trim(split(split(l_xchg_set_text, '<description>')(2), '<')(1));
            else
               l_description := null;
            end if;
            if instr(l_xchg_set_text, '<starttime') > 0  then
               l_start_time := trim(split(split(l_xchg_set_text, '<starttime>')(2), '<')(1));
               l_end_time   := trim(split(split(l_xchg_set_text, '<endtime>')(2), '<')(1));
            else
               l_start_time := null;
               l_end_time   := null;
            end if;
            if instr(l_xchg_set_text, '<max-interpolate') > 0  then
               l_att_text := split(split(l_xchg_set_text, '<max-interpolate')(2), '<')(1);
               l_attributes := make_attributes(l_att_text);
               l_interp_units := l_attributes('units');
               l_interp_count := to_number(trim(split(split(l_xchg_set_text, '<max-interpolate')(2), '<')(1)));
            else
               l_interp_count := null;
               l_interp_units := null;
            end if;
            l_xchg_set_1.code         := null;
            l_xchg_set_1.id           := l_set_id;
            l_xchg_set_1.office       := l_office_id;
            l_xchg_set_1.start_time   := l_start_time;
            l_xchg_set_1.end_time     := l_end_time;
            l_xchg_set_1.interp_count := l_interp_count;
            l_xchg_set_1.interp_units := l_interp_units;
            l_xchg_set_1.description  := l_description;
            l_xchg_set_1.realtime_dir := l_realtime_dir;

            cwms_xchg.retrieve_xchg_set(
               l_xchg_set_1.code,
               l_xchg_set_2.datastore_id,
               l_xchg_set_2.description,
               l_xchg_set_2.start_time,
               l_xchg_set_2.end_time,
               l_xchg_set_2.interp_count,
               l_xchg_set_2.interp_units,
               l_xchg_set_2.realtime_dir,
               l_last_update,
               l_set_id,
               l_office_id);
            if l_xchg_set_1.code is null then
               if l_can_insert then
                  cwms_xchg.store_xchg_set(
                     l_xchg_set_1.code,
                     l_xchg_set_1.id,
                     split(l_xchg_set_1.datastore_id, '@')(1),
                     l_xchg_set_1.description,
                     l_xchg_set_1.start_time,
                     l_xchg_set_1.end_time,
                     l_xchg_set_1.interp_count,
                     l_xchg_set_1.interp_units,
                     l_xchg_set_1.realtime_dir,
                     'T',
                     l_office_id);
                  l_sets_inserted := l_sets_inserted + 1;
               end if;
            else
               l_xchg_set_2.datastore_id := l_xchg_set_2.datastore_id || '@' || l_office_id;
               if l_can_update and
                     (upper(l_xchg_set_1.datastore_id) != upper(l_xchg_set_2.datastore_id) or
                      upper(nvl(l_xchg_set_1.description, '@')) != upper(nvl(l_xchg_set_2.description, '@')) or
                      upper(nvl(l_xchg_set_1.start_time, '@')) != upper(nvl(l_xchg_set_2.start_time, '@')) or
                      nvl(l_xchg_set_1.interp_count, -1) != nvl(l_xchg_set_2.interp_count, -1) or
                      upper(nvl(l_xchg_set_1.interp_units, '@')) != upper(nvl(l_xchg_set_2.interp_units, '@')) or
                      upper(nvl(l_xchg_set_1.realtime_dir, '@')) != upper(nvl(l_xchg_set_2.realtime_dir, '@')))
               then
                  update at_xchg_set
                     set datastore_code = l_dss_filemgrs(l_xchg_set_1.datastore_id).code,
                         description = l_xchg_set_1.description,
                         start_time = l_xchg_set_1.start_time,
                         end_time = l_xchg_set_1.end_time,
                         interpolate_count = l_xchg_set_1.interp_count,
                         interpolate_units = (select interpolate_units_code
                                                from cwms_interpolate_units
                                               where interpolate_units_id = l_xchg_set_1.interp_units),
                         realtime = (select dss_xchg_direction_code
                                       from cwms_dss_xchg_direction
                                      where dss_xchg_direction_id = l_xchg_set_1.realtime_dir)
                   where xchg_set_code = l_xchg_set_1.code;
                  l_sets_updated := l_sets_updated + 1;
               end if;
            end if;
            if l_xchg_set_code is null then
               l_xchg_set_code := l_xchg_set_1.code;
            end if;
         end if;
         if i > 1 then
            -------------------------------------
            -- now back to the mapping at hand --
            -------------------------------------
            l_pathname   := split(l_mappings(i), 'dss-timeseries')(2);
            l_parts      := split(l_pathname, '>');
            l_att_text   := l_parts(1);
            l_pathname   := trim(split(l_parts(2), '<')(1));
            l_attributes := make_attributes(l_att_text); -- from dss-timeseries element
            l_tsid       := split(l_mappings(i), 'cwms-timeseries')(2);
            l_parts      := split(l_tsid, '>');
            l_att_text   := l_parts(1);
            l_tsid       := trim(split(l_parts(2), '<')(1));
            if not l_attributes.exists('type') then
               cwms_err.raise('ERROR', 'No data type specified for pathname ' || l_pathname);
            end if;
            l_map_1.param_type := l_attributes('type');
            if not l_attributes.exists('units') then
               cwms_err.raise('ERROR', 'No units specified for pathname ' || l_pathname);
            end if;
            l_map_1.units := l_attributes('units');
            if l_attributes.exists('timezone') then
               l_map_1.time_zone := l_attributes('timezone');
            else
               l_map_1.time_zone := 'UTC';
            end if;
            if l_attributes.exists('tz-usage') then
               l_map_1.tz_usage := l_attributes('tz-usage');
            else
               l_map_1.tz_usage := 'Standard';
            end if;
            l_attributes := make_attributes(l_att_text); -- from cwms-timeseries element
            if l_attributes.exists('office-id') then
               l_ts_office_id := l_attributes('office-id');
            else
               l_ts_office_id := l_office_id; 
            end if;
            cwms_ts.create_ts_code(l_ts_code, l_tsid, null, null, null, 'F', 'T', 'F', l_ts_office_id);
            cwms_xchg.parse_dss_pathname(
               l_map_1.a_path_part,
               l_map_1.b_path_part,
               l_map_1.c_path_part,
               d_path_part,
               l_map_1.e_path_part,
               l_map_1.f_path_part,
               l_pathname);
            cwms_xchg.retrieve_xchg_dss_ts_mapping(
               l_map_1.code,
               l_map_2.a_path_part,
               l_map_2.b_path_part,
               l_map_2.c_path_part,
               l_map_2.e_path_part,
               l_map_2.f_path_part,
               l_map_2.param_type ,
               l_map_2.units,
               l_map_2.time_zone,
               l_map_2.tz_usage,
               l_xchg_set_code,
               l_ts_code);
            if l_map_1.code is null then
               if l_can_insert then
                  cwms_xchg.store_xchg_dss_ts_mapping(
                     l_map_1.code,
                     l_xchg_set_code,
                     l_ts_code,
                     l_map_1.a_path_part,
                     l_map_1.b_path_part,
                     l_map_1.c_path_part,
                     l_map_1.e_path_part,
                     l_map_1.f_path_part,
                     l_map_1.param_type ,
                     l_map_1.units,
                     l_map_1.time_zone,
                     l_map_1.tz_usage,
                     'T');
                  l_mappings_inserted := l_mappings_inserted + 1;
               end if;
            elsif l_can_update then
               if nvl(l_map_1.a_path_part, '@') != upper(nvl(l_map_2.a_path_part, '@')) or
                  l_map_1.b_path_part != upper(l_map_2.b_path_part) or
                  l_map_1.c_path_part != upper(l_map_2.c_path_part) or
                  l_map_1.e_path_part != upper(l_map_2.e_path_part) or
                  nvl(l_map_1.f_path_part, '@') != upper(nvl(l_map_2.f_path_part, '@'))
               then
                  select xchg_set_id
                    into l_set_id
                    from at_xchg_set
                   where xchg_set_code = l_xchg_set_code;
                  cwms_err.raise(
                     'ERROR',
                     'MULTIPLE TIMESERIES MAPPING:'
                     || chr(10)
                     || 'CWMS timeseries '
                     || chr(10) || chr(9)
                     || l_tsid
                     || chr(10)
                     || ' cannot be mapped to '
                     || chr(10) || chr(9)
                     || make_dss_pathname(l_map_2.a_path_part,l_map_2.b_path_part,l_map_2.c_path_part,null,l_map_2.e_path_part,l_map_2.f_path_part)
                     || chr(10)|| chr(9)
                     || make_dss_pathname(l_map_1.a_path_part,l_map_1.b_path_part,l_map_1.c_path_part,null,l_map_1.e_path_part,l_map_1.f_path_part)
                     || chr(10)
                     || 'in data exchange set '
                     || chr(10) || chr(9)
                     || l_set_id);
               end if;
               if l_map_1.param_type != l_map_2.param_type or
                  l_map_1.units != l_map_2.units or
                  l_map_1.time_zone != l_map_2.time_zone or
                  l_map_1.tz_usage != l_map_2.tz_usage
               then
                  update at_xchg_dss_ts_mappings
                     set a_pathname_part = upper(l_map_1.a_path_part),
                         b_pathname_part = upper(l_map_1.b_path_part),
                         c_pathname_part = upper(l_map_1.c_path_part),
                         e_pathname_part = upper(l_map_1.e_path_part),
                         f_pathname_part = upper(l_map_1.f_path_part),
                         dss_parameter_type_code = (select dss_parameter_type_code
                                                      from cwms_dss_parameter_type
                                                     where upper(dss_parameter_type_id) = upper(l_map_1.param_type)),
                         unit_id = l_map_1.units,
                         time_zone_code = (select time_zone_code
                                             from cwms_time_zone
                                            where upper(time_zone_name) = upper(l_map_1.time_zone)),
                         tz_usage_code = (select tz_usage_code
                                            from cwms_tz_usage
                                           where upper(tz_usage_id) = upper(l_map_1.tz_usage))
                   where mapping_code = l_map_1.code;
                  l_mappings_updated := l_mappings_updated + 1;
               end if;
            end if;
            l_mappings_specified.extend;
            l_mappings_specified(l_mappings_specified.last) := l_map_1.code;
         end if;
         l_xchg_set_code := l_xchg_set_1.code;
      end loop;
      if l_can_delete then
         --------------------------------------------
         -- delete mappings that weren't specified --
         --------------------------------------------
         select count(*)
           into l_mappings_deleted
           from at_xchg_dss_ts_mappings
          where mapping_code not in (select * from table(l_mappings_specified));
         delete
           from at_xchg_dss_ts_mappings
          where mapping_code not in (select * from table(l_mappings_specified));
         -------------------------------------------------------------------
         -- delete datastores and xchg sets that are no longer referenced --
         -------------------------------------------------------------------
      end if;
      for rec in (
         select dss_filemgr_url
           from at_xchg_datastore_dss
          where datastore_code not in (select distinct datastore_code from at_xchg_dss_ts_mappings))
      loop
         if not l_dss_filemgr_urls.exists(rec.dss_filemgr_url) then
            l_dss_filemgr_urls(rec.dss_filemgr_url) := true;
         end if;
      end loop;
      -----------------------------------------------------------
      -- verify that we didn't use and invalid units or create --
      -- a realtime import/export loop                         --
      -----------------------------------------------------------
      validate_dss_units;
      validate_dss_consistency;
      validate_realtime_direction;
      ------------------------------
      -- delete any orphaned info --
      ------------------------------
      commit;
      del_unused_dss_xchg_info;
      commit;
      -------------------------------------------------------------
      -- notify listeners that the configuation has been updated --
      -------------------------------------------------------------
      if l_dss_filemgr_urls.count > 0 then
         l_text := '';
         l_url := l_dss_filemgr_urls.first;
         while l_url is not null loop
            l_text := l_text || ',' || l_url || '/DssFileManager';
            l_url := l_dss_filemgr_urls.next(l_url);
         end loop;
         xchg_config_updated(substr(l_text, 1));
      end if;
      ----------------------------
      -- set the out parameters --
      ----------------------------
      p_sets_inserted     := l_sets_inserted;
      p_sets_updated      := l_sets_updated;
      p_mappings_inserted := l_mappings_inserted;
      p_mappings_updated  := l_mappings_updated;
      p_mappings_deleted  := l_mappings_deleted;

   end store_dataexchange_conf;

--------------------------------------------------------------------------------
-- PROCEDURE DEL_UNUSED_DSS_XCHG_INFO(VARCHAR2)
--
   procedure del_unused_dss_xchg_info(
      p_office_id in varchar2 default null)
   is
   begin
      delete
        from at_xchg_set
       where xchg_set_code not in (
                select distinct xchg_set_code
                  from at_xchg_dss_ts_mappings);

      delete
        from at_xchg_datastore_dss
       where datastore_code not in (
                select distinct datastore_code
                  from at_xchg_set);
   end del_unused_dss_xchg_info;

-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION IS_REALTIME_EXPORT(INTEGER)
--
function is_realtime_export(
   p_ts_code in integer)
   return boolean
is
   l_count integer;
begin
   --------------------------------------------------------------------------
   -- determine if the ts_code participates in a realtime Oracle-->DSS set --
   --------------------------------------------------------------------------
   select count(*)
     into l_count
     from dual
    where exists(select null
                   from at_xchg_set     xset,
                        at_xchg_dss_ts_mappings  xmap
                  where xmap.cwms_ts_code = p_ts_code
                    and xset.xchg_set_code = xmap.xchg_set_code
                    and xset.realtime = (select dss_xchg_direction_code
                                           from cwms_dss_xchg_direction
                                          where dss_xchg_direction_id = 'OracleToDss'));
   return l_count = 1;

end is_realtime_export;
-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(TIMESTAMP)
--
function use_first_table(
   p_timestamp in timestamp default null)
   return boolean
is
begin
   return mod(to_char(nvl(p_timestamp, systimestamp), 'MM'), 2) = 1;
end use_first_table;

-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(VARCHAR2)
--
function use_first_table(
   p_timestamp in integer)
   return boolean

is
begin
   return use_first_table(cwms_util.to_timestamp(p_timestamp));
end use_first_table;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_TABLE_NAME(TIMESTAMP)
--
function get_table_name(
   p_timestamp in timestamp default null)
   return varchar2
is
begin
   if use_first_table(p_timestamp) then return 'AT_TS_MSG_ARCHIVE_1'; end if;
   return 'AT_TS_MSG_ARCHIVE_2';
end get_table_name;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_TABLE_NAME(TIMESTAMP)
--
function get_table_name(
   p_timestamp in integer default null)
   return varchar2
is
begin
   return get_table_name(cwms_util.to_timestamp(p_timestamp));
end get_table_name;

-------------------------------------------------------------------------------
-- PROCEDURE XCHG_CONFIG_UPDATED(...)
--
procedure xchg_config_updated(
   p_urls_affected in varchar2)
is
   l_component   varchar2(32)  := 'DataExchangeConfigurationEditor';
   l_instance    varchar2(32)  := null;
   l_host        varchar2(32)  := null;
   l_port        integer       := null;
   l_reported    timestamp     := systimestamp;
   l_message     varchar2(4000);
   l_parts       str_tab_t;
   l_ts          integer;
begin
   l_message := '<cwms_message type="Status">'
                || '<property name="subtype" type="String">XchgConfigUpdated</property>'
                || '<property name="filemanagers" type="String">'
                || p_urls_affected
                || '</property></cwms_message>';

   l_ts := cwms_msg.log_message(
      l_component,
      l_instance,
      l_host,
      l_port,
      l_reported,
      l_message,
      cwms_msg.msg_level_basic,
      true);

end xchg_config_updated;

-------------------------------------------------------------------------------
-- PROCEDURE TIME_SERIES_UPDATED(...)
--
procedure time_series_updated(
   p_ts_code    in integer,
   p_ts_id      in varchar2,
   p_first_time in timestamp with time zone,
   p_last_time  in timestamp with time zone)
is
   pragma autonomous_transaction;
   l_msg        sys.aq$_jms_map_message;
   l_msgid      pls_integer;
   l_first_time timestamp;
   l_last_time  timestamp;
   i     integer;
begin
   -------------------------------------------------------
   -- insert the time series update info into the table --
   -------------------------------------------------------
   l_first_time := sys_extract_utc(p_first_time);
   l_last_time  := sys_extract_utc(p_last_time);
   if use_first_table then
      ----------------
      -- odd months --
      ----------------
      insert
        into at_ts_msg_archive_1
      values (cwms_msg.get_msg_id,
              p_ts_code,
              systimestamp,
              cast(l_first_time as date),
              cast(l_last_time as date));
   else
      -----------------
      -- even months --
      -----------------
      insert
        into at_ts_msg_archive_2
      values (cwms_msg.get_msg_id,
              p_ts_code,
              systimestamp,
              cast(l_first_time as date),
              cast(l_last_time as date));
   end if;

   -------------------------
   -- publish the message --
   -------------------------
   cwms_msg.new_message(l_msg, l_msgid, 'TSDataStored');
   l_msg.set_string(l_msgid, 'ts_id', p_ts_id);
   l_msg.set_long(l_msgid, 'start_time', cwms_util.to_millis(l_first_time));
   l_msg.set_long(l_msgid, 'end_time', cwms_util.to_millis(l_last_time));
   i := cwms_msg.publish_message(l_msg, l_msgid, 'realtime_ops');

   commit;

end time_series_updated;

-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_engine_url  in varchar2,
   p_xchg_code   in integer,
   p_update_time in integer)
is
   l_log_msg varchar2(4000);
   i         integer;
   l_set_id  at_xchg_set.xchg_set_id%type;
begin
   -----------------------------
   -- update the exchange set --
   -----------------------------
   update_dss_xchg_set_time(p_xchg_code, cwms_util.to_timestamp(p_update_time));
   -------------------------
   -- publish the message --
   -------------------------
   select xchg_set_id
     into l_set_id
     from at_xchg_set
    where xchg_set_code = p_xchg_code;

   l_log_msg := '<cwms_message type="Status">'
                || '<property type="String" name="subtype">LastProcessedTimeUpdated</property>'
                || '<property type="String" name="set_id">'
                || l_set_id
                || '</property>'
                || '<property type="long" name="last_processed">'
                || p_update_time
                || '</property>'
                || '</cwms_message>';

   i := cwms_msg.log_message(
      'DataExchange Engine',
      p_engine_url,
      null,
      null,
      systimestamp,
      l_log_msg,
      cwms_msg.msg_level_detailed,
      true);

end update_last_processed_time;

-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_engine_url      in varchar2,
   p_xchg_set_id     in varchar2,
   p_update_time     in integer,
   p_office_id       in varchar2 default null)
is
begin
   update_last_processed_time(
      p_engine_url,
      get_xchg_set_code(p_xchg_set_id, p_office_id),
      p_update_time);
end update_last_processed_time;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REPLAY_DATA_MESSAGES(...)
--
function replay_data_messages(
   p_component   in varchar2,
   p_host        in varchar2,
   p_xchg_set_id in varchar2,
   p_start_time  in integer  default null,
   p_end_time    in integer  default null,
   p_request_id  in varchar2 default null,
   p_office_id   in varchar2 default null)
   return varchar2
is
   type assoc_bool_vc183 is table of boolean index by varchar2(183);
   l_reported      timestamp := systimestamp;
   l_start_time    timestamp;
   l_end_time      timestamp;
   l_log_msg       varchar2(4000);
   l_request_id    varchar2(64) := nvl(p_request_id, rawtohex(sys_guid()));
   l_message       sys.aq$_jms_map_message;
   l_messageid     pls_integer;
   l_message_count integer;
   l_tsids         assoc_bool_vc183;
   l_earliest      date;
   l_latest        date;
   l_ts            integer;
   l_xchg_code     integer := get_xchg_set_code(p_xchg_set_id, p_office_id);
   i               integer;
begin
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   if p_start_time is null then
      select last_update
        into l_start_time
        from at_xchg_set
       where xchg_set_code = l_xchg_code;
      if l_start_time is null then
         l_start_time := systimestamp;
      end if;
   else
      l_start_time := cwms_util.to_timestamp(p_start_time);
   end if;
   if p_end_time is null then
      l_end_time := systimestamp;
   else
      l_end_time := cwms_util.to_timestamp(p_end_time);
   end if;
   ----------------------------
   -- log the replay request --
   ----------------------------
   l_log_msg := '<cwms_message type="RequestAction">'
                || '<property type="String" name="subtype">ReplayRealtime</property>'
                || '<property type="String" name="user">'
                || cwms_util.get_user_id
                || '</property><property type="String" name="set_id">'
                || p_xchg_set_id
                || '</property><property type="String" name="request_id">'
                || l_request_id
                || '</property><property type="String" name="start_time">'
                || l_start_time
                || '</property><property type="String" name="end_time">'
                || l_end_time
                || '</property></cwms_message>';

   i := cwms_msg.log_message(
      p_component,
      null,
      p_host,
      null,
      l_reported,
      l_log_msg,
      cwms_msg.msg_level_basic,
      false);
   -------------------------------------
   -- loop over the archived messages --
   -------------------------------------
   for rec in (select msg.ts_code,
                   msg.message_time,
                   msg.first_data_time,
                   msg.last_data_time,
                   tsid.cwms_ts_id
              from ((select * from at_ts_msg_archive_1) union (select * from at_ts_msg_archive_2)) msg,
                   mv_cwms_ts_id tsid
             where message_time between l_start_time and l_end_time
               and msg.ts_code in (select cwms_ts_code
                                     from at_xchg_dss_ts_mappings
                                    where xchg_set_code = l_xchg_code
                                  )
               and tsid.ts_code = msg.ts_code                            
          order by msg.message_time asc
           )
   loop
      ------------------------------
      -- keep track of statistics --
      ------------------------------
      l_message_count := l_message_count + 1;
      if not l_tsids.exists(rec.cwms_ts_id) then
         l_tsids(rec.cwms_ts_id) := true;
      end if;
      if l_earliest is null or rec.first_data_time < l_earliest then
         l_earliest := rec.first_data_time;
      end if;
      if l_latest is null or rec.last_data_time < l_latest then
         l_latest := rec.last_data_time;
      end if;
      --------------------------------
      -- publish the replay message --
      --------------------------------
      cwms_msg.new_message(l_message, l_messageid, 'TSDataStored');
      l_message.set_string(l_messageid, 'ts_id', rec.cwms_ts_id);
      l_message.set_long(l_messageid, 'start_time', cwms_util.to_millis(to_timestamp(rec.first_data_time)));
      l_message.set_long(l_messageid, 'end_time', cwms_util.to_millis(to_timestamp(rec.last_data_time)));
      l_message.set_long(l_messageid, 'original_millis', cwms_util.to_millis(rec.message_time));
      l_message.set_string(l_messageid, 'replay_id', l_request_id);
      l_ts := cwms_msg.publish_message(l_message, l_messageid, 'realtime_ops');
   end loop;
   ------------------------------------------
   -- publish the replay completed message --
   ------------------------------------------
   cwms_msg.new_message(l_message, l_messageid, 'TSReplayDone');
   l_message.set_string(l_messageid, 'replay_id', l_request_id);
   l_message.set_int(l_messageid, 'message_count', l_message_count);
   l_message.set_int(l_messageid, 'ts_id_count', l_tsids.count);
   l_message.set_long(l_messageid, 'first_time', cwms_util.to_millis(to_timestamp(l_earliest)));
   l_message.set_long(l_messageid, 'last_time', cwms_util.to_millis(to_timestamp(l_latest)));
   l_ts := cwms_msg.publish_message(l_message, l_messageid, 'realtime_ops');
   return l_request_id;
end replay_data_messages;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION RESTART_REALTIME(...)
--
function restart_realtime(
   p_engine_url in varchar2)
   return varchar2
is
   l_request_ids varchar2(4000) := '';
   l_engine_url  varchar2(256)  := regexp_replace(p_engine_url, '/DssFileManager$', '', 1, 1, 'i');
   l_host        varchar2(64)   := regexp_substr(l_engine_url, '[a-zA-Z0-9._]+');
begin
   for rec in (select xchg_set_id
                 from at_xchg_set xset,
                      at_xchg_datastore_dss    dfile
                where dfile.dss_filemgr_url = l_engine_url
                  and dfile.office_code = cwms_util.user_office_code
                  and xset.datastore_code = dfile.datastore_code
                  and xset.realtime is not null)
   loop
      l_request_ids := l_request_ids || ',' || replay_data_messages('DataExchange Engine', l_host, rec.xchg_set_id);
   end loop;
   return substr(l_request_ids, 2);
end restart_realtime;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REQUEST_BATCH_EXCHANGE(...)
--
function request_batch_exchange(
   p_component        in varchar2,
   p_host             in varchar2,
   p_set_id           in varchar2,
   p_dst_datastore_id in varchar2,
   p_start_time       in integer,
   p_end_time         in integer  default null,
   p_office_id        in varchar2 default null)
   return varchar2
is
   l_job_id    varchar2(32) := rawtohex(sys_guid());
   l_office_id varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
   l_log_msg   varchar2(4000);
   l_rt_msg    varchar2(4000);
   l_to_dss    varchar2(8) := null;
   l_reported  timestamp := systimestamp;
   l_rec       at_xchg_datastore_dss%rowtype;
   i           integer;
begin
   if p_dst_datastore_id = db_datastore_id then
      l_to_dss := 'false';
   else
      begin
         select datastore_code
           into l_rec.datastore_code
           from at_xchg_set
          where upper(xchg_set_id) = upper(p_set_id)
            and office_code = cwms_util.get_office_code(l_office_id);
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_set_id, 'data exchange set id for office ' || l_office_id);
      end;

      select *
        into l_rec
        from at_xchg_datastore_dss
       where datastore_code = l_rec.datastore_code;
      if upper(p_dst_datastore_id) = upper(l_rec.datastore_id) then
         l_to_dss := 'true';
      else
         cwms_err.raise('ERROR', 'Destination datastore ('||p_dst_datastore_id||') is neither '||db_datastore_id||' nor '||l_rec.datastore_id);
      end if;
   end if;
   l_log_msg := '<cwms_message type="RequestAction">'
                || '<property type="String" name="subtype">BatchExchange</property>'
                || '<property type="String" name="user">'
                || cwms_util.get_user_id
                || '</property><property type="String" name="set_id">'
                || p_set_id
                || '</property><property type="String" name="office_id">'
                || l_office_id
                || '</property><property type="String" name="job_id">'
                || l_job_id
                || '</property><property type="long" name="start_time">'
                || p_start_time
                || '</property><property type="long" name="end_time">'
                || nvl(p_end_time, cwms_util.current_millis)
                || '</property><property type="String" name="destination_datastore_id">'
                || p_dst_datastore_id
                || '</property><property type="boolean" name="to_dss">'
                || l_to_dss
                || '</property></cwms_message>';

   i := cwms_msg.log_message(
      p_component,
      null,
      p_host,
      null,
      l_reported,
      l_log_msg,
      cwms_msg.msg_level_basic,
      true);

   return l_job_id;
end request_batch_exchange;

-------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_DSS_DATASTORE(...)
--
procedure retrieve_dss_datastore(
   p_datastore_code  out number,
   p_dss_filemgr_url out nocopy varchar2,
   p_dss_file_name   out nocopy varchar2,
   p_description     out nocopy varchar2,
   p_datastore_id    in  varchar2,
   p_office_id       in  varchar2 default null)
is
   l_office_code    number  := cwms_util.get_office_code(p_office_id);
begin
   begin
      select datastore_code,
             dss_filemgr_url,
             dss_file_name,
             description
        into p_datastore_code,
             p_dss_filemgr_url,
             p_dss_file_name,
             p_description
        from at_xchg_datastore_dss
       where datastore_id = p_datastore_id
         and office_code = l_office_code;
   exception
      when no_data_found then
         p_datastore_code  := null;
         p_dss_filemgr_url := null;
         p_dss_file_name   := null;
         p_description     := null;
   end;
end retrieve_dss_datastore;

-------------------------------------------------------------------------------
-- PROCEDURE STORE_DSS_DATASTORE(...)
--
procedure store_dss_datastore(
   p_datastore_code  out number,
   p_datastore_id    in  varchar2,
   p_dss_filemgr_url in  varchar2,
   p_dss_file_name   in  varchar2,
   p_description     in  varchar2 default null,
   p_fail_if_exists  in  varchar2 default 'T',
   p_office_id       in  varchar2 default null)
is
   l_office_id      varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
   l_office_code    number       := cwms_util.get_office_code(l_office_id);
   l_fail_if_exists boolean      := cwms_util.return_true_or_false(p_fail_if_exists);
   l_datastore_code number       := null;
   l_url_patterns   str_tab_t;
   l_file_pattern   varchar2(64) := '(\$CWMS_HOME|[$/]|[a-zA-Z]:/)[^/]+(/[^/]+)*';
   l_port           integer := 0;
begin
   begin
      select datastore_code
        into l_datastore_code
        from at_xchg_datastore_dss
       where datastore_id = p_datastore_id
         and office_code = l_office_code;
   exception
      when no_data_found then null;
   end;
   if l_datastore_code is not null and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'DSS Datastore',
         p_datastore_id || ' for office ' || l_office_id);
   end if;
   -----------------------------
   -- validate the url format --
   -----------------------------
   l_url_patterns := str_tab_t(
      /* ip v4    */ '//(\d{1,3}[.]){3}\d{1,3}:\d{1,5}',
      /* DNS      */ '//([a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9][.])*[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9]:\d{1,5}',
      /* ip v6 #1 */ '//([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}:\d{1,5}',
      /* ip v6 #2 */ '//([a-fA-F0-9]{1,4}:){1,7}::\d{1,5}',
      /* ip v6 #3 */ '//:(:[a-fA-F0-9]{1,4}){1,7}',
      /* ip v6 #4 */ '//([a-fA-F0-9]{1,4}:){1,6}(:[a-fA-F0-9]{1,4}){1}:\d{1,5}',
      /* ip v6 #5 */ '//([a-fA-F0-9]{1,4}:){1,5}(:[a-fA-F0-9]{1,4}){1,2}:\d{1,5}',
      /* ip v6 #6 */ '//([a-fA-F0-9]{1,4}:){1,4}(:[a-fA-F0-9]{1,4}){1,3}:\d{1,5}',
      /* ip v6 #7 */ '//([a-fA-F0-9]{1,4}:){1,3}(:[a-fA-F0-9]{1,4}){1,4}:\d{1,5}',
      /* ip v6 #8 */ '//([a-fA-F0-9]{1,4}:){1,2}(:[a-fA-F0-9]{1,4}){1,5}:\d{1,5}',
      /* ip v6 #9 */ '//([a-fA-F0-9]{1,4}:){1}(:[a-fA-F0-9]{1,4}){1,6}:\d{1,5}');
   for i in 1..l_url_patterns.count+1 loop
      if i > l_url_patterns.count then
         cwms_err.raise('INVALID_ITEM', p_dss_filemgr_url, 'DSS Filemanager URL');
      end if;
      exit when regexp_instr(p_dss_filemgr_url, l_url_patterns(i)) = 1 and
                regexp_instr(p_dss_filemgr_url, l_url_patterns(i), 1, 1, 1) = length(p_dss_filemgr_url) + 1;
   end loop;
   ---------------------------
   -- validate the url port --
   ---------------------------
   for i in reverse 1..length(p_dss_filemgr_url) loop
      if substr(p_dss_filemgr_url, i, 1) = ':' then
         l_port := to_number(substr(p_dss_filemgr_url, i+1));
         exit;
      end if;
   end loop;
   if l_port < 1 or l_port > 65535 then
      cwms_err.raise('IVALID_ITEM', l_port, 'internet port');
   end if;
   ----------------------------
   -- validate the file name --
   ----------------------------
   if regexp_instr(p_dss_file_name, l_file_pattern) != 1 or
      regexp_instr(p_dss_file_name, l_file_pattern, 1, 1, 1) != length(p_dss_file_name) + 1
   then
      cwms_err.raise('INVALID_ITEM', p_dss_file_name, 'file name');
   end if;
   ----------------------------------------------------
   -- everything is validated, insert into the table --
   ----------------------------------------------------
   if l_datastore_code is null then
      insert
         into at_xchg_datastore_dss
         values(cwms_seq.nextval,
                l_office_code,
                p_datastore_id,
                p_dss_filemgr_url,
                p_dss_file_name,
                p_description)
      returning datastore_code
           into l_datastore_code;
   else
      update at_xchg_datastore_dss
         set dss_filemgr_url = p_dss_filemgr_url,
             dss_file_name   = p_dss_file_name,
             description     = p_description
       where datastore_code  = l_datastore_code;
   end if;
   p_datastore_code := l_datastore_code;
end store_dss_datastore;

-------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_XCHG_SET(...)
--
procedure retrieve_xchg_set(
   p_xchg_set_code out number,
   p_datastore_id  out nocopy varchar2,
   p_description   out nocopy varchar2,
   p_start_time    out nocopy varchar2,
   p_end_time      out nocopy varchar2,
   p_interp_count  out number,
   p_interp_units  out nocopy varchar2,
   p_realtime_dir  out nocopy varchar2,
   p_last_update   out timestamp,
   p_xchg_set_id   in  varchar2,
   p_office_id     in  varchar2 default null)
is
   l_office_code    number := cwms_util.get_office_code(p_office_id);
   l_datastore_code number;
   l_interp_units   number;
   l_realtime_dir   number;
begin
   begin
      select xchg_set_code,
             datastore_code,
             description,
             start_time,
             end_time,
             interpolate_count,
             interpolate_units,
             realtime,
             last_update
        into p_xchg_set_code,
             l_datastore_code,
             p_description,
             p_start_time,
             p_end_time,
             p_interp_count,
             l_interp_units,
             l_realtime_dir,
             p_last_update
        from at_xchg_set
       where upper(xchg_set_id) = upper(p_xchg_set_id)
         and office_code = l_office_code;
   exception
      when no_data_found then
         p_xchg_set_code := null;
         p_datastore_id  := null;
         p_description   := null;
         p_start_time    := null;
         p_end_time      := null;
         p_interp_count  := null;
         p_interp_units  := null;
         p_realtime_dir  := null;
         p_last_update   := null;
   end;
   if p_xchg_set_code is not null then
      select datastore_id
        into p_datastore_id
        from at_xchg_datastore_dss
       where datastore_code  = l_datastore_code;
      if l_interp_units is null then
         p_interp_units := null;
      else
         select interpolate_units_id
           into p_interp_units
           from cwms_interpolate_units
          where interpolate_units_code = l_interp_units;
      end if;
      if l_realtime_dir is null then
         p_realtime_dir := null;
      else
         select dss_xchg_direction_id
           into p_realtime_dir
           from cwms_dss_xchg_direction
          where dss_xchg_direction_code = l_realtime_dir;
      end if;
   end if;
end retrieve_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE STORE_XCHG_SET(...)
--
procedure store_xchg_set(
   p_xchg_set_code  out number,
   p_xchg_set_id    in  varchar2,
   p_datastore_id   in  varchar2,
   p_description    in  varchar2 default null,
   p_start_time     in  varchar2 default null,
   p_end_time       in  varchar2 default null,
   p_interp_count   in  integer  default null,
   p_interp_units   in  varchar2 default null, -- Intervals or Minutes
   p_realtime_dir   in  varchar2 default null, -- DssToOracle or OracleToDss
   p_fail_if_exists in  varchar2 default 'T',  -- T or F
   p_office_id      in  varchar2 default null)
is
   l_office_id           varchar2(16)  := nvl(p_office_id, cwms_util.user_office_id);
   l_office_code         number        := cwms_util.get_office_code(l_office_id);
   l_fail_if_exists      boolean       := cwms_util.return_true_or_false(p_fail_if_exists);
   l_xchg_set_code       number        := null;
   l_datastore_code      number        := null;
   l_start_time_pattern  varchar2(128) := '(-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}([.]\d+)?)?([-+]\d{2}:\d{2}|Z)?|$(lookback|start|forecast|simulation)-time)';
   l_end_time_pattern    varchar2(128) := '(-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}([.]\d+)?)?([-+]\d{2}:\d{2}|Z)?|$(start|forecast|simulation|end)-time)';
   l_parameterized_start boolean;
   l_parameterized_end   boolean;
   l_interpolate_units   integer := null;
   l_realtime_dir        integer := null;
begin
   begin
      select xchg_set_code
        into l_xchg_set_code
        from at_xchg_set
       where xchg_set_id = p_xchg_set_id
         and office_code = l_office_code;
   exception
      when no_data_found then null;
   end;
   if l_xchg_set_code is not null and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'XCHG SET',
         p_xchg_set_id || ' for office ' || l_office_id);
   end if;
   ----------------------------
   -- get the datastore code --
   ----------------------------
   begin
      select datastore_code
        into l_datastore_code
        from at_xchg_datastore_dss
       where upper(datastore_id) = upper(p_datastore_id)
         and office_code = l_office_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_datastore_id,
            'datastore id for office '||l_office_id);
   end;
   if p_start_time is null then
      if p_end_time is not null then
         cwms_err.raise('ERROR', 'End time specified without start time.');
      end if;
   else
      ------------------------------
      -- validate the time window --
      ------------------------------
      if p_end_time is null then
         cwms_err.raise('ERROR', 'Start time specified without end time.');
      end if;
      if regexp_instr(p_start_time, l_start_time_pattern) != 1 or
         regexp_instr(p_start_time, l_start_time_pattern, 1, 1, 1) != length(p_start_time) + 1
      then
         cwms_err.raise('INVALID_ITEM', p_start_time, 'start time');
      end if;
      l_parameterized_start := substr(p_start_time, 1, 1) = '$';
      if regexp_instr(p_end_time, l_end_time_pattern) != 1 or
         regexp_instr(p_end_time, l_end_time_pattern, 1, 1, 1) != length(p_end_time) + 1
      then
         cwms_err.raise('INVALID_ITEM', p_end_time, 'end time');
      end if;
      l_parameterized_end := substr(p_end_time, 1, 1) = '$';
      if l_parameterized_start != l_parameterized_end then
         cwms_err.raise('ERROR', 'Start time and end time must both be parameterized or explicit.');
      end if;
   end if;
   if p_interp_count is not null then
      ------------------------------------
      -- validate the max interpolation --
      ------------------------------------
      if p_interp_count < 0 then
         cwms_err.raise('INVALID_ITEM', p_interp_count, 'interpolation count');
      end if;
      if p_interp_units is null then
         cwms_err.raise('ERROR', 'Max interpolate count specified without units.');
      end if;
      begin
         select interpolate_units_code
           into l_interpolate_units
           from cwms_interpolate_units
          where upper(interpolate_units_id) = upper(p_interp_units);
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_interp_units, 'interpolation unit');
      end;
   else
      if p_interp_units is not null then
         cwms_err.raise('ERROR', 'Max interpolate units specified without count.');
      end if;
   end if;
   if p_realtime_dir is not null then
      -------------------------------------
      -- validate the realtime direction --
      -------------------------------------
      begin
         select dss_xchg_direction_code
           into l_realtime_dir
           from cwms_dss_xchg_direction
          where upper(dss_xchg_direction_id) = upper(p_realtime_dir);
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_realtime_dir, 'Xchg realtime direction.');
      end;
   end if;
   ----------------------------------------------------
   -- everything is validated, insert into the table --
   ----------------------------------------------------
   if l_xchg_set_code is null then
      insert
         into at_xchg_set
         values(cwms_seq.nextval,
                l_datastore_code,
                l_office_code,
                p_xchg_set_id,
                p_description,
                p_start_time,
                p_end_time,
                p_interp_count,
                l_interpolate_units,
                l_realtime_dir,
                null)
      returning xchg_set_code
           into l_xchg_set_code;
   else
      update at_xchg_set
         set datastore_code = l_datastore_code,
             description = p_description,
             start_time = p_start_time,
             end_time = p_end_time,
             interpolate_count = p_interp_count,
             interpolate_units = l_interpolate_units,
             realtime = l_realtime_dir
       where xchg_set_code = l_xchg_set_code;
   end if;
   p_xchg_set_code := l_xchg_set_code;
end store_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_XCHG_DSS_TS_MAPPING(...)
--
procedure retrieve_xchg_dss_ts_mapping(
   p_mapping_code    out number,
   p_a_pathname_part out varchar2,
   p_b_pathname_part out varchar2,
   p_c_pathname_part out varchar2,
   p_e_pathname_part out varchar2,
   p_f_pathname_part out varchar2,
   p_parameter_type  out varchar2,
   p_units           out varchar2,
   p_time_zone       out varchar2,
   p_tz_usage        out varchar2,
   p_xchg_set_code   in  number,
   p_cwms_ts_code    in  number)
is
   l_parameter_type number := null;
   l_time_zone      number := null;
   l_tz_usage       number := null;
begin
   begin
      select mapping_code,
             a_pathname_part,
             b_pathname_part,
             c_pathname_part,
             e_pathname_part,
             f_pathname_part,
             dss_parameter_type_code,
             unit_id,
             time_zone_code,
             tz_usage_code
        into p_mapping_code,
             p_a_pathname_part,
             p_b_pathname_part,
             p_c_pathname_part,
             p_e_pathname_part,
             p_f_pathname_part,
             l_parameter_type,
             p_units,
             l_time_zone,
             l_tz_usage
        from at_xchg_dss_ts_mappings
       where xchg_set_code = p_xchg_set_code
         and cwms_ts_code = p_cwms_ts_code;
   exception
      when no_data_found then
         p_mapping_code    := null;
         p_a_pathname_part := null;
         p_b_pathname_part := null;
         p_c_pathname_part := null;
         p_e_pathname_part := null;
         p_f_pathname_part := null;
         p_parameter_type  := null;
         p_units           := null;
         p_time_zone       := null;
         p_tz_usage        := null;
   end;
   if l_parameter_type is null then
      p_parameter_type := null;
   else
      select dss_parameter_type_id
        into p_parameter_type
        from cwms_dss_parameter_type
       where dss_parameter_type_code = l_parameter_type;
   end if;
   if l_time_zone is null then
      p_time_zone := null;
   else
      select time_zone_name
        into p_time_zone
        from cwms_time_zone
       where time_zone_code = l_time_zone;
   end if;
   if l_tz_usage is null then
      p_tz_usage := null;
   else
      select tz_usage_id
        into p_tz_usage
        from cwms_tz_usage
       where tz_usage_code = l_tz_usage;
   end if;
end retrieve_xchg_dss_ts_mapping;

-------------------------------------------------------------------------------
-- PROCEDURE STORE_XCHG_DSS_TS_MAPPING(...)
--
procedure store_xchg_dss_ts_mapping(
   p_mapping_code    out number,
   p_xchg_set_code   in  number,
   p_cwms_ts_code    in  number,
   p_a_pathname_part in  varchar2,
   p_b_pathname_part in  varchar2,
   p_c_pathname_part in  varchar2,
   p_e_pathname_part in  varchar2,
   p_f_pathname_part in  varchar2,
   p_parameter_type  in  varchar2,
   p_units           in  varchar2,
   p_time_zone       in  varchar2 default 'UTC',
   p_tz_usage        in  varchar2 default 'Standard',
   p_fail_if_exists  in  varchar2 default 'T')
is
   l_fail_if_exists  boolean      := cwms_util.return_true_or_false(p_fail_if_exists);
   l_mapping_code    number       := null;
   l_a_pathname_part varchar2(64) := null;
   l_b_pathname_part varchar2(64) := null;
   l_c_pathname_part varchar2(64) := null;
   l_e_pathname_part varchar2(64) := null;
   l_f_pathname_part varchar2(64) := null;
   l_parameter_type  number       := null;
   l_units           varchar2(16) := null;
   l_time_zone       number       := null;
   l_tz_usage        number       := null;
begin
   begin
      select mapping_code,
             a_pathname_part,
             b_pathname_part,
             c_pathname_part,
             e_pathname_part,
             f_pathname_part,
             dss_parameter_type_code,
             unit_id,
             time_zone_code,
             tz_usage_code
        into l_mapping_code,
             l_a_pathname_part,
             l_b_pathname_part,
             l_c_pathname_part,
             l_e_pathname_part,
             l_f_pathname_part,
             l_parameter_type,
             l_units,
             l_time_zone,
             l_tz_usage
        from at_xchg_dss_ts_mappings
       where xchg_set_code = p_xchg_set_code
         and cwms_ts_code = p_cwms_ts_code;
   exception
      when no_data_found then null;
   end;
   if l_mapping_code is not null and l_fail_if_exists then
      declare
         l_tsid        varchar2(193);
         l_xchg_set_id varchar2(32);
         l_office_id   varchar2(16);
      begin
         select cwms_ts_id
           into l_tsid
           from mv_cwms_ts_id
          where ts_code = p_cwms_ts_code;
         select s.xchg_set_id,
                o.office_id
           into l_xchg_set_id,
                l_office_id
           from at_xchg_set s,
                cwms_office o
           where s.xchg_set_code = p_xchg_set_code
             and o.office_code = s.office_code;
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'DSS mapping for '
            || l_tsid
            || ' in dataexchange set '
            || l_xchg_set_id
            || ' for office '
            || l_office_id);
      end;
   end if;
   if l_mapping_code is null then
      insert
         into at_xchg_dss_ts_mappings
       values(cwms_seq.nextval,
              p_xchg_set_code,
              p_cwms_ts_code,
              upper(p_a_pathname_part),
              upper(p_b_pathname_part),
              upper(p_c_pathname_part),
              upper(p_e_pathname_part),
              upper(p_f_pathname_part),
              (select dss_parameter_type_code
                 from cwms_dss_parameter_type
                where upper(dss_parameter_type_id) = upper(p_parameter_type)),
              p_units,
              (select time_zone_code
                 from cwms_time_zone
                where upper(time_zone_name) = upper(p_time_zone)),
              (select tz_usage_code
                 from cwms_tz_usage
                where upper(tz_usage_id) = upper(p_tz_usage)));
   else
      select dss_parameter_type_code
        into l_parameter_type
        from cwms_dss_parameter_type
       where upper(dss_parameter_type_id) = upper(p_parameter_type);
      select time_zone_code
        into l_time_zone
        from cwms_time_zone
       where upper(time_zone_name) = upper(p_time_zone);
      select tz_usage_code
        into l_tz_usage
        from cwms_tz_usage
       where upper(tz_usage_id) = upper(p_tz_usage);
      if nvl(l_a_pathname_part, '@') != upper(nvl(p_a_pathname_part, '@')) or
         l_b_pathname_part != upper(p_b_pathname_part) or
         l_c_pathname_part != upper(p_c_pathname_part) or
         l_e_pathname_part != upper(p_e_pathname_part) or
         nvl(l_f_pathname_part, '@') != upper(nvl(p_f_pathname_part, '@')) or
         l_parameter_type != p_parameter_type or
         l_units != p_units or
         l_time_zone != p_time_zone or
         l_tz_usage != p_tz_usage
      then
         update at_xchg_dss_ts_mappings
            set a_pathname_part = upper(p_a_pathname_part),
                b_pathname_part = upper(p_b_pathname_part),
                c_pathname_part = upper(p_c_pathname_part),
                e_pathname_part = upper(p_e_pathname_part),
                f_pathname_part = upper(p_f_pathname_part),
                dss_parameter_type_code = l_parameter_type,
                unit_id = p_units,
                time_zone_code = l_time_zone,
                tz_usage_code = l_tz_usage
          where mapping_code = l_mapping_code;
      end if;
   end if;
   p_mapping_code := l_mapping_code;
end store_xchg_dss_ts_mapping;

end cwms_xchg;
/
commit;
show errors;


set define on
@@defines.sql
create or replace package body cwms_usgs
as

function split_clob(
   p_text       in clob,
   p_delimiter  in varchar2,
   p_max_splits in integer default null)
   return clob_tab_t
is
   l_text_pos  integer := 1;
   l_delim_pos integer;
   l_text_len  integer := dbms_lob.getlength(p_text);
   l_delim_len integer := length(p_delimiter);
   l_part_len  integer;
   l_results   clob_tab_t := clob_tab_t();
   l_done      boolean := false;
begin
   loop
      l_results.extend;
      if p_max_splits is not null and l_results.count > p_max_splits then
         l_part_len := l_text_len - l_text_pos + 1;
         l_done := true;
      else
         l_delim_pos := instr(p_text, p_delimiter, l_text_pos);
         if l_delim_pos = 0 then
            l_part_len := l_text_len - l_text_pos + 1;
            l_done := true;
         else
            l_part_len := l_delim_pos - l_text_pos;
         end if;
      end if;
      dbms_lob.createtemporary(l_results(l_results.count), true);
      dbms_lob.copy(l_results(l_results.count), p_text, l_part_len, 1, l_text_pos);
      exit when l_done;
      l_text_pos := l_delim_pos + l_delim_len;
   end loop;
   return l_results;
end split_clob;

procedure set_auto_ts_filter_id(
   p_text_filter_id in varchar2,
   p_office_id      in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property('USGS', cwms_usgs.auto_ts_filter_prop, p_text_filter_id, 'Text filter locations to retrieve ts data from USGS', l_office_id);
end set_auto_ts_filter_id;

function get_auto_ts_filter_id(
   p_office_id in varchar2 default null)
   return varchar2
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return cwms_properties.get_property('USGS', cwms_usgs.auto_ts_filter_prop, null, l_office_id);
end get_auto_ts_filter_id;

procedure set_auto_ts_period(
   p_period    in integer,
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property('USGS', cwms_usgs.auto_ts_period_prop, to_char(p_period), 'lookback period in minutes for retrieving time series data', l_office_id);
end set_auto_ts_period;

function get_auto_ts_period(
   p_office_id in varchar2 default null)
   return integer
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return to_number(cwms_properties.get_property('USGS', cwms_usgs.auto_ts_period_prop, '240', l_office_id));
end get_auto_ts_period;

procedure set_auto_ts_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property('USGS', cwms_usgs.auto_ts_interval_prop, to_char(p_interval), 'interval in minutes for running automatic time series data retrieval', l_office_id);
end set_auto_ts_interval;

function get_auto_ts_interval(
   p_office_id in varchar2 default null)
   return integer
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return to_number(cwms_properties.get_property('USGS', cwms_usgs.auto_ts_interval_prop, '0', l_office_id));
end get_auto_ts_interval;

function filter_locations(
   p_filter_id  in varchar2,
   p_must_exist in varchar2,
   p_locations  in str_tab_t default null,
   p_office_id  in varchar2  default null)
   return str_tab_t
is
   l_must_exist  boolean := cwms_util.is_true(p_must_exist);
   l_locations   str_tab_t;
   l_filtered    str_tab_t;
   l_office_code integer;
   l_office_id   varchar2(16);
   l_count       integer;
begin
   l_office_id   := cwms_util.get_db_office_id(p_office_id);
   l_office_code := cwms_util.get_db_office_code(l_office_id);

   select count(*)
     into l_count
     from at_text_filter
    where upper(text_filter_id) = upper(p_filter_id);

   if l_count = 1 or not l_must_exist then
      if p_locations is null then
         -----------------------
         -- get all locations --
         -----------------------
         select distinct location_id
           bulk collect
           into l_locations
           from av_loc2
          order by location_id;
      else
         l_locations := p_locations;
      end if;

      if l_count = 1 then
         --------------------------
         -- filter the locations --
         --------------------------
         l_filtered := cwms_text.filter_text(
            p_filter_id,
            l_locations,
            l_office_id);
         l_locations := l_filtered;
      end if;
   else
      l_locations := str_tab_t();
   end if;

   return l_locations;
end filter_locations;


function get_auto_ts_locations(
   p_office_id in varchar2 default null)
   return str_tab_t
is
begin
   return get_auto_param_ts_locations(null, p_office_id);
end get_auto_ts_locations;

function get_auto_param_ts_locations(
   p_parameter in integer,
   p_office_id in varchar2 default null)
   return str_tab_t
is
begin
   return get_parameter_ts_locations(p_parameter, null, p_office_id);
end get_auto_param_ts_locations;

function get_parameter_ts_locations(
   p_parameter in integer,
   p_filter_id in varchar2 default null,
   p_office_id in varchar2 default null)
   return str_tab_t
is
   l_office_code       integer;
   l_office_id         varchar2(16);
   l_text_filter_id    varchar2(32);
   l_locations         str_tab_t;
   l_filtered          str_tab_t;
   l_filter_must_exist varchar2(1) := 'T';
begin
   l_office_id   := cwms_util.get_db_office_id(p_office_id);
   l_office_code := cwms_util.get_db_office_code(l_office_id);
   --------------------------------
   -- get the base filter to use --
   --------------------------------
   case p_filter_id is null
   when true  then l_text_filter_id := get_auto_ts_filter_id(l_office_id);
   when false then l_text_filter_id := p_filter_id;
   end case;
   --------------------------------
   -- get the filtered locations --
   --------------------------------
   if l_text_filter_id is null then
      ---------------------------------------------------------
      -- no filter specified and no auto-ts-filter on record --
      ---------------------------------------------------------
      cwms_err.raise(
         'ERROR',
         'No text filter specified and no stored default filter for USGS time sereies locations exists.'
         ||chr(10)
         ||'Create a text filter that includes all locations that can have USGS time series '
         ||'retrived and store it using CWMS_USGS.SET_AUTO_TS_FILTER_ID(filter_id, office_id)');
   else
      if p_parameter is null then
         ------------------------------
         -- use just the base filter --
         ------------------------------
         l_filtered := filter_locations(
            p_filter_id  => l_text_filter_id,
            p_must_exist => l_filter_must_exist,
            p_locations  => null,
            p_office_id  => l_office_id);
      else
         -------------------------------
         -- first use the base filter --
         -------------------------------
         l_filtered := filter_locations(
            p_filter_id  => l_text_filter_id,
            p_must_exist => l_filter_must_exist,
            p_locations  => null,
            p_office_id  => l_office_id);
         ------------------------------------------------
         -- next use the parameter filter if it exists --
         ------------------------------------------------
         l_filtered := filter_locations(
            p_filter_id  => l_text_filter_id||'.'||lpad(to_char(p_parameter), 5, '0'),
            p_must_exist => 'F',
            p_locations  => l_filtered,
            p_office_id  => l_office_id);
      end if;
   end if;
   --------------------------------------------
   -- get the USGS aliases for the locations --
   --------------------------------------------
   select lga.loc_alias_id
     bulk collect
     into l_locations
     from at_loc_group_assignment lga,
          at_loc_group lg,
          at_loc_category lc
    where location_code in
          (select location_code
             from (select location_code,
                          lag (location_code, 1, 0) over (order by location_code) as prev
                     from av_loc2
                   where location_id in
                          (select column_value
                             from table(l_filtered)
                          )
                  )
            where location_code != prev
          )
      and lc.loc_category_id = 'Agency Aliases'
      and lg.loc_category_code = lc.loc_category_code
      and lg.loc_group_id = 'USGS Station Number'
      and lga.loc_group_code = lg.loc_group_code;

   return l_locations;
end get_parameter_ts_locations;

function get_parameters(
   p_office_id in varchar2 default null)
   return number_tab_t
is
   l_parameter_codes number_tab_t;
begin
   select distinct
          usgs_parameter_code
     bulk collect
     into l_parameter_codes
     from at_usgs_parameter
    where office_code in (cwms_util.db_office_code_all, cwms_util.get_db_office_code(p_office_id))
    order by usgs_parameter_code;
   return l_parameter_codes;
end get_parameters;


function get_parameters(
   p_usgs_id   in varchar2,
   p_office_id in varchar2 default null)
   return number_tab_t
is
   l_all_parameters number_tab_t;
   l_parameters     number_tab_t;
   l_locations      str_tab_t;
   l_count          integer;
begin
   l_all_parameters := get_parameters(p_office_id => p_office_id);
   for i in 1..l_all_parameters.count loop
      l_locations := get_auto_param_ts_locations(l_all_parameters(i), p_office_id);
      select count(*)
        into l_count
        from table(l_locations)
       where column_value = p_usgs_id;
      if l_count = 1 then
         if l_parameters is null then l_parameters := number_tab_t(); end if;
         l_parameters.extend;
         l_parameters(l_parameters.count) := l_all_parameters(i);
      end if;
   end loop;
   return l_parameters;
end get_parameters;


procedure set_parameter_info(
   p_parameter     in integer,
   p_parameter_id  in varchar2,
   p_param_type_id in varchar2,
   p_unit          in varchar2,
   p_factor        in binary_double default 1.0,
   p_offset        in binary_double default 0.0,
   p_office_id     in varchar2 default null)
is
   l_rec at_usgs_parameter%rowtype;
   l_insert boolean;
begin
   l_rec.office_code := cwms_util.get_db_office_code(p_office_id);
   l_rec.usgs_parameter_code := p_parameter;
   begin
      select *
        into l_rec
        from at_usgs_parameter
       where office_code = l_rec.office_code
         and usgs_parameter_code = l_rec.usgs_parameter_code;
      l_insert := false;
   exception
      when no_data_found then
         l_insert := true;
   end;
   l_rec.cwms_parameter_code := cwms_ts.get_parameter_code(
      cwms_util.get_base_id(p_parameter_id),
      cwms_util.get_sub_id(p_parameter_id),
      p_office_id,
      'T');

   select parameter_type_code
     into l_rec.cwms_parameter_type_code
     from cwms_parameter_type
    where upper(parameter_type_id) = upper(p_param_type_id);

   select unit_code
     into l_rec.cwms_unit_code
     from cwms_unit
    where unit_id = p_unit;

   l_rec.factor := p_factor;
   l_rec.offset := p_offset;

   if l_insert then
      insert
        into at_usgs_parameter
      values l_rec;
   else
      update at_usgs_parameter
         set row = l_rec
       where office_code = l_rec.office_code
         and usgs_parameter_code = l_rec.usgs_parameter_code;
   end if;

end set_parameter_info;

procedure delete_parameter_info(
   p_parameter in integer,
   p_office_id in varchar2 default null)
is
   l_office_code  integer := cwms_util.get_db_office_code(p_office_id);
begin
   if   cwms_util.user_office_code != cwms_util.db_office_code_all
   and  cwms_util.user_office_code != l_office_code
   then cwms_err.raise('ERROR', 'Cannot delete another office''s USGS parameter information');
   end if;
   delete
     from at_usgs_parameter
    where office_code = l_office_code
      and usgs_parameter_code = p_parameter;
end delete_parameter_info;

procedure get_parameter_info(
   p_parameter_id  out varchar2,
   p_param_type_id out varchar2,
   p_unit          out varchar2,
   p_factor        out binary_double,
   p_offset        out binary_double,
   p_parameter     in  integer,
   p_office_id     in  varchar2 default null)
is
   l_rec at_usgs_parameter%rowtype;
begin
   begin
      select *
        into l_rec
        from at_usgs_parameter
       where office_code = cwms_util.get_db_office_code(p_office_id)
         and usgs_parameter_code = p_parameter;
   exception
      when no_data_found then
         begin
            select *
              into l_rec
              from at_usgs_parameter
             where office_code = cwms_util.db_office_code_all
               and usgs_parameter_code = p_parameter;
         exception
            when no_data_found then null;
         end;
   end;
   if l_rec.office_code is not null then
      select bp.base_parameter_id
             ||substr('-', 1, length(ap.sub_parameter_id))
             ||ap.sub_parameter_id
        into p_parameter_id
        from at_parameter ap,
             cwms_base_parameter bp
       where ap.parameter_code = l_rec.cwms_parameter_code
         and bp.base_parameter_code = ap.base_parameter_code;

      select parameter_type_id
        into p_param_type_id
        from cwms_parameter_type
       where parameter_type_code = l_rec.cwms_parameter_type_code;

      select unit_id
        into p_unit
        from cwms_unit
       where unit_code = l_rec.cwms_unit_code;

      p_factor := l_rec.factor;
      p_offset := l_rec.offset;
   end if;
end get_parameter_info;

function get_url(
   p_url     in varchar2,
   p_timeout in integer default 60)
   return clob
is
   l_max_tries       pls_integer := 15;
   l_cert_error      boolean;
   l_req             utl_http.req;
   l_resp            utl_http.resp;
   l_buf             varchar2(32767);
   l_wallet          varchar2(256);
   l_clob            clob;

   procedure write_clob(p_text in varchar2)
   is
      l_len binary_integer := length(p_text);
   begin
      dbms_lob.writeappend(l_clob, l_len, p_text);
   end;
begin
   dbms_lob.createtemporary(l_clob, true);
   dbms_lob.open(l_clob, dbms_lob.lob_readwrite);

   l_wallet := cwms_properties.get_property(
      p_category  => 'CWMSDB',
      p_id        => 'oracle.wallet.filename.usgs',
      p_default   => cwms_properties.get_property(
                        p_category  => 'CWMSDB',
                        p_id        => 'oracle.wallet.filename',
                        p_default   => null,
                        p_office_id =>'CWMS'),
      p_office_id =>'CWMS');
   if l_wallet is not null then
      utl_http.set_wallet('file:'||l_wallet, null);
   end if;
   utl_http.set_transfer_timeout(p_timeout);
   for i in 1..l_max_tries loop
      begin
         l_req := utl_http.begin_request(p_url);
         utl_http.set_header(l_req, 'User-Agent', 'Mozilla/4.0');
         l_resp := utl_http.get_response(l_req);
         utl_http.set_transfer_timeout;
          loop
            utl_http.read_text(l_resp, l_buf);
            write_clob(l_buf);
         end loop;
      exception
         when utl_http.end_of_body then
            utl_http.end_response(l_resp);
            if i > 1 then
               cwms_msg.log_db_message(cwms_msg.msg_level_detailed, 'Connected after '||i-1||' failed attempts');
            end if;
            exit;
         when others then
            l_cert_error := instr(dbms_utility.format_error_backtrace, 'Certificate validation failure') > 0;
            begin
               utl_http.end_response(l_resp);
            exception
               when others then null;
            end;
            if l_cert_error then
               if i = l_max_tries then
                  raise;
               else
                  begin
                     utl_http.end_response(l_resp);
                  exception
                     when others then null;
                  end;
                  dbms_lock.sleep(1);
               end if;
            else
               raise;
            end if;
      end;
   end loop;
   dbms_lob.close(l_clob);
   return l_clob;
end get_url;

function get_ts_id(
   p_location_id    in varchar2,
   p_usgs_parameter in integer,
   p_interval       in integer,
   p_version        in varchar2 default 'USGS',
   p_office_id      in varchar2 default null)
   return varchar2
is
   l_ts_id       varchar2(191);
   l_interval_id varchar2(16);
begin
   if p_interval = 0 then
      l_interval_id := '0';
   else
      begin
         select interval_id
           into l_interval_id
           from cwms_interval
          where interval = p_interval;
       exception
         when no_data_found then
            l_interval_id := '0';
       end;
   end if;

   select ts_id
     into l_ts_id
     from (select p_location_id
                  ||'.'
                  ||bp.base_parameter_id
                  ||substr('-', 1, length(p.sub_parameter_id))
                  ||p.sub_parameter_id
                  ||'.'
                  ||pt.parameter_type_id
                  ||'.'
                  ||l_interval_id
                  ||'.'
                  ||case
                       when pt.parameter_type_id = 'Inst' then '0'
                       else l_interval_id
                    end
                  ||'.'
                  ||p_version as ts_id
             from at_usgs_parameter up,
                  at_parameter p,
                  cwms_base_parameter bp,
                  cwms_parameter_type pt
            where up.usgs_parameter_code = p_usgs_parameter
              and p.parameter_code = up.cwms_parameter_code
              and bp.base_parameter_code = p.base_parameter_code
              and pt.parameter_type_code = up.cwms_parameter_type_code
              and up.office_code in (cwms_util.get_db_office_code(p_office_id), cwms_util.db_office_code_all)
            order by case
                        when up.office_code = cwms_util.db_office_code_all then 9999
                        else up.office_code
                     end
          )
    where rownum = 1;
    return l_ts_id;
end get_ts_id;

function get_ts_data(
   p_format     in varchar2,
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob
is
   l_office_id varchar2(16);
   l_period    varchar2(16);
   l_sites_txt varchar2(32767);
   l_sites_tab str_tab_t;
   l_set_tab   str_tab_t;
   l_set_count pls_integer;
   l_set_min   pls_integer;
   l_set_max   pls_integer;
   l_url       varchar2(32767);
   l_data      clob;
   l_data2     clob;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_period := nvl(p_period, cwms_util.minutes_to_duration(get_auto_ts_period(l_office_id)));
   if cwms_util.duration_to_minutes(l_period) = 0 then
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         'Retrieval aborted due to invalid period: '||l_period);
   end if;
   if p_sites is null then
      l_sites_tab := get_auto_ts_locations(l_office_id);
   else
      select trim(column_value)
        bulk collect
        into l_sites_tab
        from table(cwms_util.split_text(p_sites, ','));
   end if;
   if l_sites_tab is null or l_sites_tab.count = 0 then
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         'Retrieval aborted due to no sites to retrieve');
   else
      l_set_count := trunc((l_sites_tab.count - 1) / cwms_usgs.max_sites) + 1;
      for i in 1..l_set_count loop
         l_url := cwms_usgs.realtime_ts_url_period;
         l_url := replace(l_url, '<format>', p_format);
         l_url := replace(l_url, '<period>', l_period);
         if p_parameters is null then
            l_url := replace(l_url, '&'||'parameterCd=<parameters>', null);
         else
            l_url := replace(l_url, '<parameters>', p_parameters);
         end if;
         l_set_min := (i-1) * cwms_usgs.max_sites + 1;
         l_set_max := case
                         when i = l_set_count then l_sites_tab.count
                         else l_set_min + cwms_usgs.max_sites - 1
                      end;
         select column_value
           bulk collect
           into l_set_tab
           from (select rownum as j,
                        column_value
                   from table(l_sites_tab)
                )
          where j between l_set_min and l_set_max;
         l_sites_txt := cwms_util.join_text(l_set_tab, ',');
         l_url := replace(l_url, '<sites>' , l_sites_txt);
         cwms_msg.log_db_message(
            cwms_msg.msg_level_detailed,
            l_office_id||': USGS URL: '||l_url);
         if i = 1 then
            l_data := get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               l_office_id||': bytes retrieved: '||dbms_lob.getlength(l_data));
         else
            l_data2 := get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               l_office_id||': bytes retrieved: '||dbms_lob.getlength(l_data2));
            dbms_lob.append(l_data, l_data2);
         end if;
      end loop;
   end if;

   return l_data;

end get_ts_data;

function get_ts_data(
   p_format     in varchar2,
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob
is
   l_url varchar2(32767) := cwms_usgs.realtime_ts_url_dates;
begin
   l_url := replace(l_url, '<format>', p_format);
   l_url := replace(l_url, '<start>' , p_start_time);
   l_url := replace(l_url, '<end>'   , p_end_time);
   l_url := replace(l_url, '<sites>' , p_sites);
   if p_parameters is null then
      l_url := replace(l_url, '&'||'parameterCd=<parameters>', null);
   else
      l_url := replace(l_url, '<parameters>', p_parameters);
   end if;
   return get_url(l_url);
end get_ts_data;

function get_ts_data_rdb(
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob
is
begin
   return get_ts_data('rdb', p_period, p_sites, p_parameters, p_office_id=>p_office_id);
end get_ts_data_rdb;

function get_ts_data_rdb(
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
   return clob
is
begin
   return get_ts_data('rdb', p_start_time, p_end_time, p_sites, p_parameters, p_office_id);
end get_ts_data_rdb;

function minutes_between(
   p_time1 in timestamp with time zone,
   p_time2 in timestamp with time zone)
   return integer
is
   l_intvl interval day (3) to second (0);
begin
   l_intvl := p_time2 at time zone 'UTC' - p_time1 at time zone 'UTC';
   return extract(day    from l_intvl) * 1440 +
          extract(hour   from l_intvl) *   60 +
          extract(minute from l_intvl);
end;

function make_text_id(
   p_location_id in varchar2)
   return varchar2
is
begin
   return '/__RDB_DATA/'||p_location_id;
end make_text_id;

procedure store_text(
   p_text      in varchar2,
   p_text_id   in varchar2,
   p_office_id in varchar2 default null)
is
   pragma autonomous_transaction;
   l_code      integer;
begin
   l_code := cwms_text.store_text(p_text, p_text_id, null, 'F', p_office_id);
   commit;
end store_text;

procedure store_text(
   p_text      in clob,
   p_text_id   in varchar2,
   p_office_id in varchar2 default null)
is
   pragma autonomous_transaction;
   l_code      integer;
begin
   l_code := cwms_text.store_text(p_text, p_text_id, null, 'F', p_office_id);
   commit;
end store_text;

procedure delete_text(
   p_text_id   in varchar2,
   p_office_id in varchar2 default null)
is
   pragma autonomous_transaction;
begin
   cwms_text.delete_text(p_text_id, p_office_id);
   commit;
end delete_text;

procedure process_ts_rdb(
   p_ts_ids      out str_tab_t,
   p_units       out str_tab_t,
   p_ts_data     out tsv_array_tab,
   p_location_id in  varchar2,
   p_rdb_data    in  clob,
   p_office_id   in  varchar2 default null)
is
   type col_t is table of integer index by varchar2(16);
   l_ts_ids     str_tab_t;
   l_units      str_tab_t;
   l_factors    double_tab_t;
   l_offsets    double_tab_t;
   l_ts_data    tsv_array_tab;
   l_all_params number_tab_t;
   l_params     number_tab_t := number_tab_t();
   l_lines      str_tab_t;
   l_cols       str_tab_t;
   l_ts         ztsv_array_tab;
   l_col_count  pls_integer;
   l_col_info   col_t;
   l_date_time  timestamp with time zone;
   l_value      number;
   l_interval   integer;
   l_interval2  integer;
begin
   l_all_params := get_parameters(p_location_id, p_office_id);
   if l_params is null or l_all_params.count = 0 then
      cwms_msg.log_db_message(cwms_msg.msg_level_detailed, 'No USGS parameters specified for location '||p_location_id);
      return;
   end if;
   -----------------------------------------------
   -- skip the header and parse the column info --
   -----------------------------------------------
   cwms_msg.log_db_message(7, p_location_id||' : '||length(p_rdb_data)||' bytes');
   select column_value
     bulk collect
     into l_lines
     from table(cwms_util.split_text(p_rdb_data, chr(10)))
    where column_value not like '#%';
   l_cols := cwms_util.split_text(l_lines(1), chr(9));
   l_col_count := l_cols.count;
   for j in 1..l_col_count loop
      case l_cols(j)
         when 'agency_cd' then l_col_info('agency') := j;
         when 'site_no'   then l_col_info('site')   := j;
         when 'datetime'  then l_col_info('time')   := j;
         when 'tz_cd'     then l_col_info('tz')     := j;
         else
            l_value := to_number(regexp_substr(l_cols(j), '^\d+_(\d{5})$', 1, 1, null, 1));
            if l_value is not null and l_value member of l_all_params then
               l_col_info(to_char(l_value)) := j;
               l_params.extend;
               l_params(l_params.count) := l_value;
            end if;
      end case;
   end loop;
   if not l_col_info.exists('agency') or
      not l_col_info.exists('site')   or
      not l_col_info.exists('time')   or
      not l_col_info.exists('tz')
   then
      cwms_err.raise('ERROR', 'Unexpected USGS RDB format for station '||p_location_id);
   end if;
   ----------------------
   -- process the data --
   ----------------------
   if l_params.count > 0 then
      l_ts_data := tsv_array_tab();
      l_ts_data.extend(l_params.count);
      l_units := str_tab_t();
      l_units.extend(l_params.count);
      l_factors := double_tab_t();
      l_factors.extend(l_params.count);
      l_offsets := double_tab_t();
      l_offsets.extend(l_params.count);
      <<data_setup_loop>>
      for i in 1..l_params.count loop
         select unit_id,
                factor,
                offset
           into l_units(i),
                l_factors(i),
                l_offsets(i)
           from (select u.unit_id,
                        up.factor,
                        up.offset
                   from at_usgs_parameter up,
                        cwms_unit u
                  where up.usgs_parameter_code = l_params(i)
                    and up.office_code in (cwms_util.get_db_office_code(p_office_id), cwms_util.db_office_code_all)
                    and u.unit_code = up.cwms_unit_code
                  order by case
                              when up.office_code = cwms_util.db_office_code_all then 9999
                              else up.office_code
                           end
                )
          where rownum = 1;
      end loop;
      <<data_loop>>
      for i in 2..l_lines.count loop
         continue data_loop when trim(l_lines(i)) is null;
         exit data_loop when substr(l_lines(i), 1, 1) = '#'; -- beginning of next data retrieval response
         l_cols := cwms_util.split_text(l_lines(i), chr(9));
            continue data_loop when l_cols.count = 1;
            if l_cols.count != l_col_count then
               cwms_err.raise('ERROR', 'Unexpected USGS RDB format for station '||p_location_id);
            end if;
            continue data_loop when l_cols(l_col_info('site')) != p_location_id; -- shouldn't happen, but just in case
            l_date_time := from_tz(to_timestamp(l_cols(l_col_info('time')), 'yyyy-mm-dd hh24:mi'), cwms_util.get_timezone(l_cols(l_col_info('tz'))));
            <<params_loop>>
            for j in 1..l_params.count loop
               if l_ts_data(j) is null then
                  l_ts_data(j) := tsv_array();
               end if;
               begin
                  l_value := to_binary_double(l_cols(l_col_info(to_char(l_params(j)))));
               exception
                  when others then l_value := null; -- sometimes have text reasons for missing data
               end;
               if l_value is not null then
                  l_ts_data(j).extend;
                  l_ts_data(j)(l_ts_data(j).count) := tsv_type(l_date_time, l_value * l_factors(j) + l_offsets(j), 0);
               end if;
            end loop;
      end loop;
   end if;
   ----------------------------------
   -- generate the time series ids --
   ----------------------------------
   l_ts_ids := str_tab_t();
   l_ts_ids.extend(l_params.count);
   for i in 1..l_params.count loop
      -------------------------------------------------
      -- determine the interval for this time series --
      -------------------------------------------------
      l_interval := null;
      if l_ts_data(i) is not null and l_ts_data(i).count > 2 then -- must have minimum of 2 values
         for j in 2..l_ts_data(i).count loop
            if j = 2 then
               l_interval := minutes_between(l_ts_data(i)(j-1).date_time, l_ts_data(i)(j).date_time);
            else
               if l_interval > 0 then
                  l_interval2 := minutes_between(l_ts_data(i)(j-1).date_time, l_ts_data(i)(j).date_time);
                  case
                     when l_interval2 > l_interval then
                        if mod(l_interval2, l_interval) = 0 then
                           null;
                        else
                           l_interval := 0;
                        end if;
                     when l_interval2 < l_interval then
                        if mod(l_interval, l_interval2) = 0 then
                           l_interval := l_interval2;
                        else
                           l_interval := 0;
                        end if;
                     else
                        null; -- evquivalent intervals
                  end case;
               end if;
            end if;
         end loop;
         l_ts_ids(i) := get_ts_id(p_location_id, l_params(i), l_interval, 'USGS', p_office_id);
      end if;
   end loop;
   ---------------------------
   -- set the out parametrs --
   ---------------------------
   p_ts_ids  := l_ts_ids;
   p_units   := l_units;
   p_ts_data := l_ts_data;
exception
   when others then
      -----------------------------------
      -- store the data for inspection --
      -----------------------------------
      store_text(p_rdb_data, make_text_id(p_location_id), p_office_id);
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         dbms_utility.format_error_backtrace);
      cwms_err.raise('ERROR', dbms_utility.format_error_backtrace);
end process_ts_rdb;

procedure process_ts_rdb_and_store(
   p_rdb_data  in clob,
   p_office_id in varchar2 default null)
is
   l_office_id   varchar2(16);
   l_datasets    clob_tab_t;
   l_parts       clob_tab_t;
   l_ts_ids      str_tab_t;
   l_units       str_tab_t;
   l_ts_data     tsv_array_tab;
   l_tsid_count  pls_integer := 0;
   l_value_count pls_integer := 0;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   -------------------------------------------------------
   -- split the clob into datasets for individual sites --
   -------------------------------------------------------
   l_datasets := split_clob(p_rdb_data, '# Data provided for site ');
   if l_datasets is null then
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         l_office_id||': No data retrieved');
   else
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         l_office_id||': RDB data contains '||(l_datasets.count-1)||' sites');
      <<dataset_loop>>
      for i in 1..l_datasets.count loop
         if i > 1 then
            ------------------------------------------------------
            -- split the site number off the top of the dataset --
            ------------------------------------------------------
            l_parts := split_clob(l_datasets(i), chr(10), 1);
            ----------------------------------------------
            -- parse the time series out of the dataset --
            ----------------------------------------------
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               l_office_id||': Processing site '||(i-1)||' of '||(l_datasets.count-1)||' : '||trim(l_parts(1)));
            begin
               process_ts_rdb(l_ts_ids, l_units, l_ts_data, trim(l_parts(1)), trim(l_parts(2)), p_office_id);
            exception
               when others then
                  cwms_msg.log_db_message(
                     cwms_msg.msg_level_basic,
                     l_office_id||': '||sqlerrm);
                  cwms_msg.log_db_message(
                     cwms_msg.msg_level_basic,
                     l_office_id||': '||dbms_utility.format_error_backtrace);
                  cwms_msg.log_db_message(
                     cwms_msg.msg_level_basic,
                     l_office_id||': RDB Clob ID is '||make_text_id(l_parts(1)));
                  dbms_lob.freetemporary(l_datasets(i));
                  continue dataset_loop;
            end;
            -----------------------------------------------------
            -- store each time series contained in the dataset --
            -----------------------------------------------------
            if l_ts_ids is not null then
               <<tsid_loop>>
               for j in 1..l_ts_ids.count loop
                  if l_ts_ids(j) is not null then
                     l_tsid_count  := l_tsid_count + 1;
                     l_value_count := l_value_count + l_ts_data(j).count;
                     cwms_ts.store_ts(
                        p_cwms_ts_id      => l_ts_ids(j),
                        p_units           => l_units(j),
                        p_timeseries_data => l_ts_data(j),
                        p_store_rule      => cwms_util.replace_with_non_missing,
                        p_override_prot   => 'F',
                        p_version_date    => cwms_util.non_versioned,
                        p_office_id       => l_office_id);
                     commit;
                  end if;
               end loop;
            end if;
         end if;
         dbms_lob.freetemporary(l_datasets(i));
      end loop;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         l_office_id||': processed '
         ||l_value_count
         ||' values in '
         ||l_tsid_count
         ||' time series in '
         ||(l_datasets.count-1)
         ||' locations');
   end if;

end process_ts_rdb_and_store;

procedure retrieve_and_store_ts(
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16);
begin
   --------------------------------------
   -- setup for running from scheduler --
   --------------------------------------
   begin
      select sys_context('CWMS_ENV', 'SESSION_OFFICE_ID')
        into l_office_id
        from dual;
      if l_office_id is null then
         cwms_env.set_session_office_id(p_office_id);
      end if;
   exception
      when others then null;
   end;
   retrieve_and_store_ts(null, null, null, p_office_id=>p_office_id);
end retrieve_and_store_ts;

procedure retrieve_and_store_ts(
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
is
   l_office_id varchar2(16);
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   cwms_msg.log_db_message(
      cwms_msg.msg_level_normal,
      'CWMS_USGS.RETRIEVE_AND_STORE_TS starting for '||l_office_id);
   process_ts_rdb_and_store(
      get_ts_data_rdb(p_period, p_sites, p_parameters, p_office_id=>l_office_id),
      l_office_id);
   cwms_msg.log_db_message(
      cwms_msg.msg_level_normal,
      'CWMS_USGS.RETRIEVE_AND_STORE_TS done for '||l_office_id);
end retrieve_and_store_ts;

procedure retrieve_and_store_ts(
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2 default null)
is
   l_office_id varchar2(16);
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   cwms_msg.log_db_message(
      cwms_msg.msg_level_normal,
      'CWMS_USGS.RETRIEVE_AND_STORE_TS starting for '||l_office_id);
   process_ts_rdb_and_store(
      get_ts_data_rdb(p_start_time, p_end_time, p_sites, p_parameters, p_office_id),
      p_office_id);
   cwms_msg.log_db_message(
      cwms_msg.msg_level_normal,
      'CWMS_USGS.RETRIEVE_AND_STORE_TS done for '||l_office_id);
end retrieve_and_store_ts;

procedure start_auto_ts_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);
   l_run_interval    integer;
   l_comment         varchar2(256);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_TS_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot start job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   l_run_interval := get_auto_ts_interval(l_office_id);
   if l_run_interval is null then
      cwms_err.raise(
         'ERROR',
         'No run interval defined for job in property '||auto_ts_interval_prop);
   elsif l_run_interval < 15 then
      cwms_err.raise(
         'ERROR',
         'Run interval of '
         ||l_run_interval
         ||' defined for job in property '
         ||auto_ts_interval_prop
         ||' is less than 15 minutes');
   end if;
   -------------------------------------------
   -- drop the job if it is already running --
   -------------------------------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (l_job_id);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

   if job_count = 0
   then
      begin
         ---------------------
         -- restart the job --
         ---------------------
         dbms_scheduler.create_job(
            job_name             => l_job_id,
            job_type             => 'stored_procedure',
            job_action           => 'cwms_usgs.retrieve_and_store_ts',
            number_of_arguments  => 1,
            start_date           => null,
            repeat_interval      => 'freq=minutely; interval=' || l_run_interval,
            end_date             => null,
            job_class            => 'default_job_class',
            enabled              => false,
            auto_drop            => false,
            comments             => 'Retrieves time series data from USGS');

         dbms_scheduler.set_job_argument_value(
            job_name          => l_job_id,
            argument_position => 1,
            argument_value    => l_office_id);

         dbms_scheduler.enable(l_job_id);
         if job_count = 1 then
            dbms_output.put_line(
               'Job '
               ||l_job_id
               ||' successfully scheduled to execute every '
               ||l_run_interval
               ||' minutes.');
         else
            cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
         end if;
      exception
         when others then
            cwms_err.raise (
               'ITEM_NOT_CREATED',
               'job',l_job_id || ':' || sqlerrm);
      end;
   end if;
end start_auto_ts_job;

procedure stop_auto_ts_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_TS_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot stop job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   ------------------
   -- drop the job --
   ------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (job_name=>l_job_id, force=>true);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

end stop_auto_ts_job;

procedure set_auto_stream_meas_filter_id(
   p_text_filter_id in varchar2,
   p_office_id      in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property('USGS', cwms_usgs.auto_stream_meas_filter_prop, p_text_filter_id, 'Text filter locations to retrieve stream measurements from USGS', l_office_id);
end set_auto_stream_meas_filter_id;

function get_auto_stream_meas_filter_id(
   p_office_id in varchar2 default null)
   return varchar2
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return cwms_properties.get_property('USGS', cwms_usgs.auto_stream_meas_filter_prop, null, l_office_id);
end get_auto_stream_meas_filter_id;

procedure set_auto_stream_meas_period(
   p_period    in integer,
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property('USGS', cwms_usgs.auto_stream_meas_period_prop, to_char(p_period), 'lookback period in minutes for retrieving streamflow measurements data', l_office_id);
end set_auto_stream_meas_period;

function get_auto_stream_meas_period(
   p_office_id in varchar2 default null)
   return integer
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return to_number(cwms_properties.get_property('USGS', cwms_usgs.auto_stream_meas_period_prop, '10080', l_office_id));
end get_auto_stream_meas_period;

procedure set_auto_stream_meas_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property('USGS', cwms_usgs.auto_stream_meas_interval_prop, to_char(p_interval), 'interval in minutes for running automatic streamflow measurements data retrieval', l_office_id);
end set_auto_stream_meas_interval;

function get_auto_stream_meas_interval(
   p_office_id in varchar2 default null)
   return integer
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return to_number(cwms_properties.get_property('USGS', cwms_usgs.auto_stream_meas_interval_prop, '0', l_office_id));
end get_auto_stream_meas_interval;

function get_auto_stream_meas_locations(
   p_office_id in varchar2 default null)
   return str_tab_t
is
   l_office_code       integer;
   l_office_id         varchar2(16);
   l_text_filter_id    varchar2(32);
   l_locations         str_tab_t;
   l_filtered          str_tab_t;
   l_filter_must_exist varchar2(1) := 'T';
begin
   l_office_id      := cwms_util.get_db_office_id(p_office_id);
   l_office_code    := cwms_util.get_db_office_code(l_office_id);
   l_text_filter_id := get_auto_stream_meas_filter_id(l_office_id);
   if l_text_filter_id is not null then
      -----------------------------------
      -- get the locations to retrieve --
      -----------------------------------
      l_filtered := filter_locations(l_text_filter_id, l_filter_must_exist, null, l_office_id);
      --------------------------------------------
      -- get the USGS aliases for the locations --
      --------------------------------------------
      select distinct
             location_id
        bulk collect
        into l_locations
        from av_loc2
       where aliased_item = 'LOCATION'
         and loc_alias_category = 'Agency Aliases'
         and loc_alias_group = 'USGS Station Number'
         and location_code in (select location_code
                                 from av_loc2
                                where location_id in (select * from table(l_filtered))
                                  and db_office_id = l_office_id
                              );
   end if;
   return l_locations;
end get_auto_stream_meas_locations;

procedure retrieve_and_store_stream_meas(
   p_office_id  in varchar2 default null)
is
begin
   retrieve_and_store_stream_meas(p_period=>null, p_sites=>null, p_office_id=>p_office_id);
end retrieve_and_store_stream_meas;

procedure retrieve_and_store_stream_meas(
   p_period     in varchar2,
   p_sites      in varchar2,
   p_office_id  in varchar2 default null)
is
   l_period      varchar2(32);
   l_start_time  date;
   l_end_time    date;
   l_ym_interval yminterval_unconstrained;
   l_ds_interval dsinterval_unconstrained;
begin
   if p_period is null then
      if p_sites is null then
         ---------------
         -- all sites --
         ---------------
         l_period := cwms_util.minutes_to_duration(get_auto_stream_meas_period);
      else
         ---------------------
         -- specified sites --
         ---------------------
         l_period := 'P200Y';
      end if;
   else
      l_period := p_period;
   end if;
   cwms_util.duration_to_interval(l_ym_interval, l_ds_interval, l_period);
   l_end_time   := sysdate;
   l_start_time := cast((cast(l_end_time as timestamp) - l_ym_interval - l_ds_interval) as date);
   retrieve_and_store_stream_meas(
      to_char(l_start_time, 'yyyy-mm-dd'),
      to_char(l_end_time, 'yyyy-mm-dd'),
      p_sites,
      p_office_id);
end retrieve_and_store_stream_meas;

procedure retrieve_and_store_stream_meas(
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_office_id  in varchar2 default null)
is
   l_office_id  varchar2(16);
   l_start_time varchar2(10);
   l_end_time   varchar2(10);
   l_sites_txt  varchar2(32767);
   l_sites_tab  str_tab_t;
   l_sites_tab2 str_tab_t;
   l_set_tab    str_tab_t;
   l_set_count  pls_integer;
   l_set_min    pls_integer;
   l_set_max    pls_integer;
   l_url        varchar2(32767);
   l_data       clob;
   l_data2      clob;
   l_lines      str_tab_t;
   l_count      pls_integer;
   l_meas       streamflow_meas_t;
   l_loc_code   number(14);
   l_group_code number(14);
begin
   l_start_time := nvl(p_start_time, '1800-01-01');
   l_end_time   := nvl(p_end_time, to_char(sysdate, 'yyyy-mm-dd'));


   l_office_id := cwms_util.get_db_office_id(p_office_id);
   cwms_msg.log_db_message(
      cwms_msg.msg_level_normal,
      'CWMS_USGS.RETRIEVE_AND_STORE_STREAM_MEAS starting for '||l_office_id);
   if p_sites is null then
      l_sites_tab := get_auto_stream_meas_locations(l_office_id);
   else
      select loc_group_code
        into l_group_code
        from at_loc_group where loc_group_id = 'USGS Station Number'
          and loc_category_code = (select loc_category_code
                                     from at_loc_category
                                    where loc_category_id = 'Agency Aliases'
                                  );
      l_data := to_clob(p_sites);
      select trim(column_value)
        bulk collect
        into l_sites_tab2
        from table(cwms_util.split_text(l_data, ','));
      l_sites_tab := str_tab_t();
      for i in 1..l_sites_tab2.count loop
         l_sites_tab.extend;
         begin
            l_loc_code := cwms_loc.get_location_code(l_office_id, l_sites_tab2(i), 'T');
         select loc_alias_id
              into l_sites_tab(l_sites_tab.count)
           from at_loc_group_assignment
          where location_code = l_loc_code
            and loc_group_code = l_group_code;
         exception
            when others then
               cwms_msg.log_db_message(
                  cwms_msg.msg_level_normal,
                  dbms_utility.format_error_stack||chr(10)||dbms_utility.format_error_backtrace);
               l_sites_tab.trim;
         end;
      end loop;
   end if;
   if l_sites_tab.count = 0 then
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         'Retrieval aborted due to no sites to retrieve');
   else
      l_set_count := trunc((l_sites_tab.count - 1) / cwms_usgs.max_sites) + 1;
      for i in 1..l_set_count loop
         l_url := cwms_usgs.stream_meas_url;
         l_url := replace(l_url, '<start>', l_start_time);
         l_url := replace(l_url, '<end>', l_end_time);
         l_set_min := (i-1) * cwms_usgs.max_sites + 1;
         l_set_max := case
                         when i = l_set_count then l_sites_tab.count
                         else l_set_min + cwms_usgs.max_sites - 1
                      end;
         select column_value
           bulk collect
           into l_set_tab
           from (select rownum as j,
                        column_value
                   from table(l_sites_tab)
                )
          where j between l_set_min and l_set_max;
         l_sites_txt := cwms_util.join_text(l_set_tab, ',');
         l_url := replace(l_url, '<sites>' , l_sites_txt);
         cwms_msg.log_db_message(
            cwms_msg.msg_level_detailed,
            l_office_id||': USGS URL: '||l_url);
         if i = 1 then
            l_data := get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               l_office_id||': bytes retrieved: '||dbms_lob.getlength(l_data));
         else
            l_data2 := get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               l_office_id||': bytes retrieved: '||dbms_lob.getlength(l_data2));
            dbms_lob.append(l_data, l_data2);
         end if;
      end loop;
      l_count := 0;
      if instr(l_data, 'No sites') = 1 then
         cwms_msg.log_db_message(
            cwms_msg.msg_level_detailed,
            l_office_id||': '||l_data);
      else
         cwms_msg.log_db_message(
            cwms_msg.msg_level_detailed,
            'Processing measurements');
         l_lines := cwms_util.split_text(l_data, chr(10));
         for i in 1..l_lines.count loop
            if length(l_lines(i)) < 20
               or substr(l_lines(i), 1, 1) = '#'
               or substr(l_lines(i), 1, 9) = 'agency_cd'
               or substr(l_lines(i), 1, 2) = '5s'
            then
               continue;
            end if;
            begin
               l_meas := streamflow_meas_t(l_lines(i), l_office_id);
            exception
               when others then
                  cwms_msg.log_db_message(
                     cwms_msg.msg_level_normal,
                        l_office_id||': cannot process: '||sqlerrm||chr(10)||l_lines(i)||chr(10)||dbms_utility.format_error_backtrace);
                  continue;
            end;
            if l_meas is null or l_meas.location is null then
               continue;
            end if;
            l_meas.store('F');
            l_count := l_count + 1;
         end loop;
      end if;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         l_office_id||': '||l_count||' measurements stored');
   end if;
   cwms_msg.log_db_message(
      cwms_msg.msg_level_normal,
      'CWMS_USGS.RETRIEVE_AND_STORE_STREAM_MEAS stopping for '||l_office_id);
end retrieve_and_store_stream_meas;

procedure start_auto_stream_meas_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);
   l_run_interval    integer;
   l_comment         varchar2(256);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_MEAS_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot start job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   l_run_interval := get_auto_stream_meas_interval(l_office_id);
   if l_run_interval is null then
      cwms_err.raise(
         'ERROR',
         'No run interval defined for job in property '||auto_stream_meas_interval_prop);
   elsif l_run_interval < 15 then
      cwms_err.raise(
         'ERROR',
         'Run interval of '
         ||l_run_interval
         ||' defined for job in property '
         ||auto_stream_meas_interval_prop
         ||' is less than 15 minutes');
   end if;
   -------------------------------------------
   -- drop the job if it is already running --
   -------------------------------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (l_job_id);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

   if job_count = 0
   then
      begin
         ---------------------
         -- restart the job --
         ---------------------
         dbms_scheduler.create_job(
            job_name             => l_job_id,
            job_type             => 'stored_procedure',
            job_action           => 'cwms_usgs.retrieve_and_store_stream_meas',
            number_of_arguments  => 1,
            start_date           => null,
            repeat_interval      => 'freq=minutely; interval=' || l_run_interval,
            end_date             => null,
            job_class            => 'default_job_class',
            enabled              => false,
            auto_drop            => false,
            comments             => 'Retrieves streamflow measurements data from USGS');

         dbms_scheduler.set_job_argument_value(
            job_name          => l_job_id,
            argument_position => 1,
            argument_value    => l_office_id);

         dbms_scheduler.enable(l_job_id);
         if job_count = 1 then
            dbms_output.put_line(
               'Job '
               ||l_job_id
               ||' successfully scheduled to execute every '
               ||l_run_interval
               ||' minutes.');
         else
            cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
         end if;
      exception
         when others then
            cwms_err.raise (
               'ITEM_NOT_CREATED',
               'job',l_job_id || ':' || sqlerrm);
      end;
   end if;
end start_auto_stream_meas_job;

procedure stop_auto_stream_meas_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_MEAS_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot stop job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   ------------------
   -- drop the job --
   ------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (job_name=>l_job_id, force=>true);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

end stop_auto_stream_meas_job;

function get_base_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      base_rating_spec_ver_prop,
      default_base_rating_spec_ver,
      p_office_id);
end get_base_rating_spec_version;

procedure set_base_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      base_rating_spec_ver_prop,
      p_version_text,
      'Rating specification version for BASE ratings retrieved from the USGS',
      p_office_id);
end set_base_rating_spec_version;

function get_base_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      base_rating_templ_ver_prop,
      default_base_rating_templ_ver,
      p_office_id);
end get_base_rating_templ_version;

procedure set_base_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      base_rating_templ_ver_prop,
      p_version_text,
      'Rating template version for BASE ratings retrieved from the USGS',
      p_office_id);
end set_base_rating_templ_version;

function get_exsa_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      exsa_rating_spec_ver_prop,
      default_exsa_rating_spec_ver,
      p_office_id);
end get_exsa_rating_spec_version;

procedure set_exsa_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      exsa_rating_spec_ver_prop,
      p_version_text,
      'Rating specification version for EXSA ratings retrieved from the USGS',
      p_office_id);
end set_exsa_rating_spec_version;

function get_exsa_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      exsa_rating_templ_ver_prop,
      default_exsa_rating_templ_ver,
      p_office_id);
end get_exsa_rating_templ_version;

procedure set_exsa_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      exsa_rating_templ_ver_prop,
      p_version_text,
      'Rating template version for EXSA ratings retrieved from the USGS',
      p_office_id);
end set_exsa_rating_templ_version;

function get_corr_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      corr_rating_spec_ver_prop,
      default_corr_rating_spec_ver,
      p_office_id);
end get_corr_rating_spec_version;

procedure set_corr_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      corr_rating_spec_ver_prop,
      p_version_text,
      'Rating specification version for CORR ratings retrieved from the USGS',
      p_office_id);
end set_corr_rating_spec_version;

function get_corr_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      corr_rating_templ_ver_prop,
      default_corr_rating_templ_ver,
      p_office_id);
end get_corr_rating_templ_version;

procedure set_corr_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      corr_rating_templ_ver_prop,
      p_version_text,
      'Rating template version for CORR ratings retrieved from the USGS',
      p_office_id);
end set_corr_rating_templ_version;

function get_prod_rating_spec_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      prod_rating_spec_ver_prop,
      default_prod_rating_spec_ver,
      p_office_id);
end get_prod_rating_spec_version;

procedure set_prod_rating_spec_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      prod_rating_spec_ver_prop,
      p_version_text,
      'Rating specification version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS)',
      p_office_id);
end set_prod_rating_spec_version;

function get_prod_rating_templ_version(
	p_office_id in varchar2 default null)
	return varchar2
is
begin
   return cwms_properties.get_property(
      'USGS',
      prod_rating_templ_ver_prop,
      default_prod_rating_templ_ver,
      p_office_id);
end get_prod_rating_templ_version;

procedure set_prod_rating_templ_version(
	p_version_text in varchar2,
	p_office_id    in varchar2 default null)
is
begin
   cwms_properties.set_property(
      'USGS',
      prod_rating_templ_ver_prop,
      p_version_text,
      'Rating template version for USGS Production ratings (virtual or transitional ratings generated from ratings retrieved fromthe USGS)',
      p_office_id);
end set_prod_rating_templ_version;

function get_auto_update_ratings(
   p_office_id in varchar2 default null)
   return number_tab_t
is
   l_rating_specs number_tab_t;
   l_office_code  integer := cwms_util.get_db_office_code(p_office_id);
begin
   select rs.rating_spec_code
     bulk collect
     into l_rating_specs
     from at_rating_template rt,
          at_rating_spec rs
    where rt.office_code = l_office_code
      and rt.version in (get_base_rating_templ_version(p_office_id), get_exsa_rating_templ_version(p_office_id), get_corr_rating_templ_version(p_office_id))
      and rt.parameters_id not in ('Stage;Stage-Shift', 'Stage;Stage-Offset')
      and rs.template_code = rt.template_code
      and rs.version  in (get_base_rating_spec_version(p_office_id), get_exsa_rating_spec_version(p_office_id), get_corr_rating_spec_version(p_office_id))
      and rs.active_flag = 'T'
      and rs.auto_update_flag = 'T' ;
   return l_rating_specs;
end get_auto_update_ratings;

function hash_rating_text(
   p_rating_text in clob)
   return varchar2
is
begin
   return rawtohex(dbms_crypto.hash(regexp_replace(p_rating_text, '# //.+?'||chr(10), null), dbms_crypto.hash_sh1));
end;

procedure write_clob(
   p_clob in out nocopy clob,
   p_text in            varchar2)
is
begin
   dbms_lob.writeappend(p_clob, length(p_text), p_text);
end write_clob;

procedure writeln_clob(
   p_clob in out nocopy clob,
   p_text in            varchar2)
is
begin
   dbms_lob.writeappend(p_clob, length(p_text)+1, p_text||chr(10));
end writeln_clob;

function expand_xml_entities(
   p_text in varchar2)
   return varchar2
is
begin
   return replace(
             replace(
                replace(
                   replace(
                      replace(
                        p_text,
                        '&',
                        '&'||'amp;'),
                      '>',
                      '&'||'gt;'),
                   '<',
                   '&'||'lt;'),
                '''',
                '&'||'apos;'),
             '"',
             '&'||'quot;');

end expand_xml_entities;

function date_from_line(
   p_line in varchar2)
   return date
is
   l_regex1 varchar2(128) := '^.+?((\d{4})-?(\d{2})-?(\d{2}) ?(\d{2}):?(\d{2}):?(\d{2})).*$';
   l_regex2 varchar2(128) := '^.+?{dt}.+(BZONE="?)?(\w+|[+-]\d{2}:?\d{2}).*$';
   l_dt_str varchar2(24);
   l_yr     varchar2(4);
   l_mon    varchar2(2);
   l_day    varchar2(2);
   l_hr     varchar2(2);
   l_min    varchar2(2);
   l_sec    varchar2(2);
   l_tz     varchar2(8);
   l_ts     timestamp with time zone;
   l_dt     date;
begin
   if regexp_like(p_line, l_regex1) then
      l_dt_str := regexp_substr(p_line, l_regex1, 1, 1, 'c', 1);
      l_yr     := regexp_substr(p_line, l_regex1, 1, 1, 'c', 2);
      l_mon    := regexp_substr(p_line, l_regex1, 1, 1, 'c', 3);
      l_day    := regexp_substr(p_line, l_regex1, 1, 1, 'c', 4);
      l_hr     := regexp_substr(p_line, l_regex1, 1, 1, 'c', 5);
      l_min    := regexp_substr(p_line, l_regex1, 1, 1, 'c', 6);
      l_sec    := regexp_substr(p_line, l_regex1, 1, 1, 'c', 7);
      l_tz     := regexp_substr(p_line, replace(l_regex2, '{dt}', l_dt_str), 1, 1, 'c', 2);
      l_ts     := from_tz(to_timestamp(l_yr||l_mon||l_day||l_hr||l_min||l_sec, 'yyyymmddhh24miss'), nvl(l_tz, 'UTC'));
      l_dt     := cwms_util.change_timezone(cast(l_ts as date), nvl(l_tz, 'UTC'), 'UTC');
      return l_dt;
   end if;
   return l_dt;
end date_from_line;

function corr_to_xml(
   p_rating_text in clob,
   p_office_id   in varchar2)
   return clob
is
   tab               constant varchar2(1) := chr(9);
   l_xml             clob;
   l_lines           str_tab_t;
   l_lines2          str_tab_t;
   l_parts           str_tab_t;
   l_clob_id         varchar2(256) := '/_usgs-ratings/corr/'||cwms_msg.get_msg_id;
   l_station_number  varchar2(15);
   l_location_id      varchar2(57);
   l_station_name     varchar2(32);
   l_date            date;
   l_values          number_tab_t;
   l_effective_dates date_table_type  := date_table_type();
   l_heights_str      str_tab_t;
   l_corrections_str  str_tab_t;
   l_corr_heights_str str_tab_t;
   l_heights          number_tab_t := number_tab_t();
   l_corr_heights     number_tab_t := number_tab_t();
   l_description      varchar2(128);
begin
   begin
      -------------------------------
      -- get just the header lines --
      -------------------------------
      select column_value
        bulk collect
        into l_lines
        from table(cwms_util.split_text(p_rating_text, chr(10)))
       where column_value like '#%';
      -------------------------------------
      -- get the station number and name --
      -------------------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //STATION AGENCY%';
      if l_parts.count = 0 then
            cwms_err.raise('ERROR', 'Could not find rating station number. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count > 1 then
            cwms_err.raise('ERROR', 'Found multiple rating station numbers. Clob ID is '||l_clob_id);
      end if;
      l_parts := cwms_util.split_text(l_parts(1));
      for i in 1..l_parts.count loop
         if l_parts(i) like 'NUMBER=%' then
            l_station_number := trim(cwms_util.split_text(replace(l_parts(i), '"', null), 2, '='));
            exit;
         end if;
      end loop;
      if l_station_number is null then
         cwms_err.raise('ERROR', 'Could not find rating station number. Clob ID is '||l_clob_id);
      end if;
      l_location_id := nvl(cwms_loc.get_location_id(l_station_number, p_office_id), l_station_number);
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //STATION NAME%';
      if l_parts.count > 1 then
         cwms_err.raise('ERROR', 'Found multiple rating station names. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count = 1 then
         l_station_name := trim('"' from trim(substr(l_parts(1), instr(l_parts(1), '=')+1)));
      end if;
      ---------------------------
      -- get the rating number --
      ---------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING ID=%';
      if l_parts.count > 0 then
         l_description := 'Rating '||trim('"' from trim(cwms_util.split_text(l_parts(1), 2, '=')));
      end if;
      ----------------------------
      -- get the effective date --
      ----------------------------
      ----------------------------------------------------------------
      -- first try from the # //CORRn_PREV and # //CORRn_NEXT lines --
      ----------------------------------------------------------------
      select trim(replace(substr(column_value, 15), '"', null))
        bulk collect
        into l_lines2
        from table(l_lines)
       where column_value like '# //CORR_\_____ %' escape '\';
      for i in 1..l_lines2.count / 3 loop
         l_parts := cwms_util.split_text(l_lines2(3*i-2));
         begin
            l_date := to_date(cwms_util.split_text(l_parts(1), 2, '='), 'yyyymmddhh24miss');
         exception
            when others then continue;
         end;
         begin
            l_date := cwms_util.change_timezone(l_date, cwms_util.split_text(l_parts(2), 2, '='), 'UTC');
         exception
            when others then null;
         end;
         l_parts := cwms_util.split_text(l_lines2(3*i-1));
         select to_number(cwms_util.split_text(column_value, 2, '='))
           bulk collect
           into l_values
           from table(l_parts)
          where instr(column_value, '--') = 0;

         continue when l_parts.count = 0;
         l_effective_dates.extend;
         l_effective_dates(l_effective_dates.count) := l_date;
      end loop;
      if l_effective_dates.count = 0 then
         ------------------------------------------------------
         -- default effective date to the # //RETRIEVED line --
         ------------------------------------------------------
         l_effective_dates.extend;
         select column_value
           bulk collect
           into l_parts
           from table(l_lines)
          where column_value like '# //RETRIEVED: %';
         if l_parts.count = 0 then
               cwms_err.raise('ERROR', 'Could not find rating retrieval time. Clob ID is '||l_clob_id);
         end if;
         if l_parts.count > 1 then
               cwms_err.raise('ERROR', 'Found multiple rating retrieval times. Clob ID is '||l_clob_id);
         end if;
         l_parts := cwms_util.split_text(l_parts(1));
         l_effective_dates(1) := to_date(l_parts(3)||' '||l_parts(4), 'yyyy-mm-dd hh24:mi:ss');
         -----------------------------------------------------------
         -- get the time zone from the line with TIME_ZONE= on it --
         -----------------------------------------------------------
         select column_value
           bulk collect
           into l_parts
           from table(l_lines)
          where column_value like '%TIME_ZONE=%';
         if l_parts.count = 0 then
               cwms_err.raise('ERROR', 'Could not find rating retrieval time zone. Clob ID is '||l_clob_id);
         end if;
         if l_parts.count > 1 then
               cwms_err.raise('ERROR', 'Found multiple rating retrieval time zones. Clob ID is '||l_clob_id);
         end if;
         l_parts := cwms_util.split_text(l_parts(1));
         for i in 1..l_parts.count loop
            if l_parts(i) like 'TIME_ZONE=%' then
               select trim(upper(column_value))
                 bulk collect
                 into l_parts
                 from table(cwms_util.split_text(replace(l_parts(i), '"', null), '='));
               l_effective_dates(1) := cwms_util.change_timezone(l_effective_dates(1), l_parts(2), 'UTC');
               exit;
            end if;
         end loop;
      end if;
      ---------------------------
      -- get the rating values --
      ---------------------------
      select cwms_util.split_text(column_value, 1),
             cwms_util.split_text(column_value, 2),
             cwms_util.split_text(column_value, 3)
                 bulk collect
        into l_heights_str,
             l_corrections_str,
             l_corr_heights_str
        from table(cwms_util.split_text(p_rating_text, chr(10)))
       where regexp_like(column_value, '^-?\d+\.\d+\s+-?\d+\.\d+\s+-?\d+\.\d+$');

      for i in 1..l_heights_str.count loop
         if i = 1 or i = l_heights_str.count then
            ---------------------------------------------
            -- always insert the first and last values --
            ---------------------------------------------
            l_heights.extend;
            l_corr_heights.extend;
            l_heights(l_heights.count) := l_heights_str(i);
            l_corr_heights(l_heights.count) := l_corr_heights_str(i);
         elsif l_corrections_str(i) != l_corrections_str(i-1) then
            -----------------------------------------------------
            -- always insert or update when correction changes --
            -----------------------------------------------------
            if l_heights(i) != l_heights(i-1) then
               ------------
               -- extend --
               ------------
               l_heights.extend;
               l_corr_heights.extend;
               l_heights(l_heights.count) := l_heights_str(i);
               l_corr_heights(l_heights.count) := l_corr_heights_str(i);
            else
               -------------------------------------------
               -- update previous value for this height --
               -------------------------------------------
               l_corr_heights(l_heights.count) := l_corr_heights_str(i);
      end if;
         else
            null;
         end if;
      end loop;

      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      writeln_clob(l_xml, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlschema/cwms/Ratings.xsd">');
      writeln_clob(l_xml, tab||'<rating-template office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<parameters-id>Stage;Stage-Corrected</parameters-id>');
      writeln_clob(l_xml, tab||tab||'<version>'||get_corr_rating_templ_version(p_office_id)||'</version>');
      writeln_clob(l_xml, tab||tab||'<ind-parameter-specs>');
      writeln_clob(l_xml, tab||tab||tab||'<ind-parameter-spec position="1">');
      writeln_clob(l_xml, tab||tab||tab||tab||'<parameter>Stage</parameter>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<in-range-method>LINEAR</in-range-method>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<out-range-low-method>LINEAR</out-range-low-method>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<out-range-high-method>LINEAR</out-range-high-method>');
      writeln_clob(l_xml, tab||tab||tab||'</ind-parameter-spec>');
      writeln_clob(l_xml, tab||tab||'</ind-parameter-specs>');
      writeln_clob(l_xml, tab||tab||'<dep-parameter>Stage-Corrected</dep-parameter>');
      writeln_clob(l_xml, tab||tab||'<description>Stream Actual Stage Rating</description>');
      writeln_clob(l_xml, tab||'</rating-template>');
      writeln_clob(l_xml, tab||'<rating-spec office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<rating-spec-id>'||l_location_id||'.Stage;Stage-Corrected.'||get_corr_rating_templ_version(p_office_id)||'.'||get_corr_rating_spec_version(p_office_id)||'</rating-spec-id>');
      writeln_clob(l_xml, tab||tab||'<template-id>Stage;Stage-Corrected.'||get_corr_rating_templ_version(p_office_id)||'</template-id>');
      writeln_clob(l_xml, tab||tab||'<location-id>'||l_location_id||'</location-id>');
      writeln_clob(l_xml, tab||tab||'<version>'||get_corr_rating_spec_version(p_office_id)||'</version>');
      writeln_clob(l_xml, tab||tab||'<source-agency>USGS</source-agency>');
      writeln_clob(l_xml, tab||tab||'<in-range-method>LINEAR</in-range-method>');
      writeln_clob(l_xml, tab||tab||'<out-range-low-method>NEAREST</out-range-low-method>');
      writeln_clob(l_xml, tab||tab||'<out-range-high-method>NEAREST</out-range-high-method>');
      writeln_clob(l_xml, tab||tab||'<active>true</active>');
      writeln_clob(l_xml, tab||tab||'<auto-update>true</auto-update>');
      writeln_clob(l_xml, tab||tab||'<auto-activate>false</auto-activate>');
      writeln_clob(l_xml, tab||tab||'<auto-migrate-extension>false</auto-migrate-extension>');
      writeln_clob(l_xml, tab||tab||'<ind-rounding-specs>');
      writeln_clob(l_xml, tab||tab||tab||'<ind-rounding-spec position="1">4444444444</ind-rounding-spec>');
      writeln_clob(l_xml, tab||tab||'</ind-rounding-specs>');
      writeln_clob(l_xml, tab||tab||'<dep-rounding-spec>4444444444</dep-rounding-spec>');
      writeln_clob(l_xml, tab||tab||'<description>'||nvl(l_station_name, l_location_id)||' Actual Stage USGS Rating</description>');
      writeln_clob(l_xml, tab||'</rating-spec>');
      writeln_clob(l_xml, tab||'<simple-rating office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<rating-spec-id>'||l_location_id||'.Stage;Stage-Corrected.'||get_corr_rating_templ_version(p_office_id)||'.'||get_corr_rating_spec_version(p_office_id)||'</rating-spec-id>');
      writeln_clob(l_xml, tab||tab||'<units-id>ft;ft</units-id>');
      writeln_clob(l_xml, tab||tab||'<effective-date>'||to_char(trunc(l_effective_dates(l_effective_dates.count), 'mi'), 'yyyy-mm-dd"T"hh24:mi:ss"Z"')||'</effective-date>');
      writeln_clob(l_xml, tab||tab||'<create-date/>');
      writeln_clob(l_xml, tab||tab||'<active>true</active>');
      if l_description is null then
         writeln_clob(l_xml, tab||tab||'<description/>');
      else
         writeln_clob(l_xml, tab||tab||'<description>'||l_description||'</description>');
      end if;
      writeln_clob(l_xml, tab||tab||'<rating-points>');
      for i in 1..l_heights.count loop
         writeln_clob(l_xml, tab||tab||tab||'<point>');
         writeln_clob(l_xml, tab||tab||tab||tab||'<ind>'||cwms_rounding.round_dt_f(l_heights(i), '9999999999')||'</ind>');
         writeln_clob(l_xml, tab||tab||tab||tab||'<dep>'||cwms_rounding.round_dt_f(l_corr_heights(i), '9999999999')||'</dep>');
         writeln_clob(l_xml, tab||tab||tab||'</point>');
      end loop;
      writeln_clob(l_xml, tab||tab||'</rating-points>');
      writeln_clob(l_xml, tab||'</simple-rating>');
      writeln_clob(l_xml, '</ratings>');
      dbms_lob.close(l_xml);
      return l_xml;
   exception
      when others then
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, dbms_utility.format_error_backtrace);
         store_text(p_rating_text, l_clob_id, p_office_id);
         raise;
   end;
end corr_to_xml;


function base_to_xml(
   p_rating_base in clob,
   p_rating_exsa in clob,
   p_office_id   in varchar2)
   return clob
is
   type              shift_t is record(effective_date date, stages number_tab_t, shifts number_tab_t, description varchar2(1024));
   type              shift_tab_t is table of shift_t;
   type              offsets_t is record(stages number_tab_t, offsets number_tab_t);
   tab               constant varchar2(1) := chr(9);
   l_xml             clob;
   l_lines           str_tab_t;
   l_lines2          str_tab_t;
   l_parts           str_tab_t;
   l_text            varchar2(256);
   l_clob_id         varchar2(256) := '/_usgs-ratings/base/'||cwms_msg.get_msg_id;
   l_effective_date  date;
   l_station_number  varchar2(15);
   l_location_id     varchar2(57);
   l_station_name    varchar2(128);
   l_description     varchar2(256);
   l_stages          number_tab_t;
   l_flows           number_tab_t;
   l_dates           date_table_type;
   l_ind_rounding    varchar2(10);
   l_dep_rounding    varchar2(10);
   l_shifts          shift_tab_t  := shift_tab_t();
   l_offsets         offsets_t;
begin
   begin
      l_lines := cwms_util.split_text(p_rating_base, chr(10));
      -------------------------------------
      -- get the station number and name --
      -------------------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //STATION AGENCY%';
      if l_parts.count = 0 then
            cwms_err.raise('ERROR', 'Could not find rating station number. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count > 1 then
            cwms_err.raise('ERROR', 'Found multiple rating station numbers. Clob ID is '||l_clob_id);
      end if;
      l_parts := cwms_util.split_text(replace(l_parts(1), '"', null));
      begin
         select cwms_util.split_text(column_value, 2, '=')
           into l_station_number
           from table(l_parts)
          where column_value like 'NUMBER=%';
      exception
         when no_data_found then
            cwms_err.raise('ERROR', 'Could not find rating station number. Clob ID is '||l_clob_id);
      end;
      l_location_id := nvl(cwms_loc.get_location_id(l_station_number, p_office_id), l_station_number);
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //STATION NAME%';
      if l_parts.count > 1 then
         cwms_err.raise('ERROR', 'Found multiple rating station names. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count = 1 then
         l_station_name := trim('"' from trim(substr(l_parts(1), instr(l_parts(1), '=')+1)));
      end if;
      -------------------------------------------
      -- get the rating number and description --
      -------------------------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING ID=%';
      if l_parts.count > 0 then
         l_description := 'Rating '||trim(cwms_util.split_text(replace(substr(l_parts(1), instr(l_parts(1), '=')+1), '"', null), 1));
      end if;
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING REMARKS=%';
      if l_parts.count > 0 then
         if l_description is not null then
            l_description := l_description||'-';
         end if;
         l_description := l_description||trim(replace(substr(l_parts(1), instr(l_parts(1), '=')+1), '"', null));
      end if;
      ----------------------------
      -- get the effective date --
      ----------------------------
      select column_value
        bulk collect
        into l_lines2
        from table(l_lines)
       where column_value like '# //RATING_DATETIME BEGIN=%';
      if l_lines2.count = 0 then
            cwms_err.raise('ERROR', 'Could not find rating effective time. Clob ID is '||l_clob_id);
      end if;
      l_dates := date_table_type();
      for i in 1..l_lines2.count loop
         l_dates.extend;
         l_dates(l_dates.count) := date_from_line(l_lines2(i));
         if l_dates(l_dates.count) is null then l_dates.trim; end if;
      end loop;
      select max(column_value)
        into l_effective_date
        from table(l_dates);
      l_dates.delete;
      ----------------------------
      -- get the rounding specs --
      ----------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING_INDEP ROUNDING=%';
      if l_parts.count > 1 then
            cwms_err.raise('ERROR', 'Found multiple stage rounding specifications. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count = 0 then
         l_ind_rounding := '4444444444';
      else
         begin
            select cwms_util.split_text(trim(replace(column_value, '"', null)), 2, '=')
              into l_ind_rounding
              from table(cwms_util.split_text(l_parts(1)))
             where column_value like 'ROUNDING=%';
         exception
            when no_data_found then
               cwms_err.raise('ERROR', 'Could not find stage rounding specification. Clob ID is '||l_clob_id);
         end;
      end if;
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING_DEP ROUNDING=%';
      if l_parts.count > 1 then
            cwms_err.raise('ERROR', 'Found multiple flow rounding specifications. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count = 0 then
         l_dep_rounding := '4444444444';
      else
         begin
            select cwms_util.split_text(trim(replace(column_value, '"', null)), 2, '=')
              into l_dep_rounding
              from table(cwms_util.split_text(l_parts(1)))
             where column_value like 'ROUNDING=%';
         exception
            when no_data_found then
               cwms_err.raise('ERROR', 'Could not find flow rounding specification. Clob ID is '||l_clob_id);
         end;
      end if;
      ---------------------------
      -- get the rating values --
      ---------------------------
      select column_value
        bulk collect
        into l_lines2
        from table(l_lines)
       where column_value not like '#%';

      select to_number(text)
        bulk collect
        into l_stages
        from (select cwms_util.split_text(column_value, 1) as text
                from table(l_lines2)
             )
       where trim(translate(text, '-+.0123456789E', ' ')) is null;

      select to_number(text)
        bulk collect
        into l_flows
        from (select cwms_util.split_text(column_value, 2) as text
                from table(l_lines2)
             )
       where trim(translate(text, '-+.0123456789E', ' ')) is null;

      if l_stages.count != l_flows.count or l_stages.count != l_lines2.count-2 then
        cwms_err.raise('ERROR', 'Error parsing rating values.  Clob ID is '||l_clob_id);
      end if;
      ----------------------------------
      -- get the shifts from the exsa --
      ----------------------------------
      select column_value
        bulk collect
        into l_lines
        from table(cwms_util.split_text(p_rating_exsa, chr(10)))
       where column_value like '#%';

      select column_value
        bulk collect
        into l_lines2
        from table(l_lines)
       where column_value like '# //SHIFT\_____%' escape '\';
      for i in 1..l_lines2.count / 3 loop
         l_parts := cwms_util.split_text(replace(l_lines2(3*i-2), '"', null));
         --
         -- shift date/time
         --
         l_shifts.extend;
         l_shifts(i).stages := number_tab_t(null, null, null);
         l_shifts(i).shifts := number_tab_t(null, null, null);
         begin
            l_shifts(i).effective_date := to_date(cwms_util.split_text(l_parts(3), 2, '='), 'yyyymmddhh24miss');
         exception
            when others then
               l_shifts.trim;
               exit;
         end;
         begin
            l_shifts(i).effective_date := cwms_util.change_timezone(l_shifts(i).effective_date, cwms_util.split_text(l_parts(4), 2, '='));
         exception
            when others then null;
         end;
         --
         -- shift values
         --
         l_parts := cwms_util.split_text(replace(l_lines2(3*i-1), '"', null));
         begin
            if l_parts.count > 3 then
               l_shifts(i).stages(1) := to_number(cwms_util.split_text(l_parts(3), 2, '='));
               l_shifts(i).shifts(1) := to_number(cwms_util.split_text(l_parts(4), 2, '='));
            else
               l_shifts.trim;
               exit;
            end if;
            if l_parts.count > 5 then
               l_shifts(i).stages(2) := to_number(cwms_util.split_text(l_parts(5), 2, '='));
               l_shifts(i).shifts(2) := to_number(cwms_util.split_text(l_parts(6), 2, '='));
            end if;
            if l_parts.count > 7 then
               l_shifts(i).stages(3) := to_number(cwms_util.split_text(l_parts(7), 2, '='));
               l_shifts(i).shifts(3) := to_number(cwms_util.split_text(l_parts(8), 2, '='));
            end if;
         exception
            when others then
              cwms_err.raise('ERROR', 'Error parsing shift values.  Clob ID is '||l_clob_id);
         end;
         --
         -- shift comment
         --
         l_lines2(3*i) := replace(l_lines2(3*i), '"', null);
         l_shifts(i).description := trim(substr(l_lines2(3*i), instr(l_lines2(3*i), '=')+1));
      end loop;
      -----------------------------------
      -- get the offsets from the exsa --
      -----------------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING BREAKPOINT1=%';

      if l_parts.count = 1 then
         --
         -- offset breakpoints
         --
         select to_number(value)
           bulk collect
           into l_offsets.stages
           from (select 0 as seq,
                        '0' as value
                   from dual
                 union all
                 select rownum as seq,
                        value
                   from (select cwms_util.split_text(column_value, 2, '=') as value
                           from table(cwms_util.split_text(substr(l_parts(1), 12)))
                        )
                );
           l_offsets.stages(1) := l_offsets.stages(2) - .01;
      end if;
      --
      -- offset values
      --
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING OFFSET1=%';

      if l_parts.count > 0 then
         select to_number(value)
           bulk collect
           into l_offsets.offsets
           from (select cwms_util.split_text(column_value, 2, '=') as value
                   from table(cwms_util.split_text(substr(l_parts(1), 12)))
                );
         while l_offsets.offsets(l_offsets.offsets.count) is null loop
            -- don't know why this is necessary, but I ran into a case where it was
            l_offsets.offsets.trim;
         end loop;

         if l_offsets.offsets.count = 1 and l_offsets.stages is null then
            -- single offset
            l_offsets.stages := number_tab_t(0);
         end if;

         if l_offsets.offsets.count != l_offsets.stages.count then
           cwms_err.raise('ERROR', 'Error parsing rating offsets.  Clob ID is '||l_clob_id);
         end if;
      elsif l_offsets.stages is not null then
        cwms_err.raise('ERROR', 'Error parsing rating offsets.  Clob ID is '||l_clob_id);
      end if;


      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      writeln_clob(l_xml, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlschema/cwms/Ratings.xsd">');
      writeln_clob(l_xml, tab||'<rating-template office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<parameters-id>Stage;Flow</parameters-id>');
      writeln_clob(l_xml, tab||tab||'<version>'||get_base_rating_templ_version(p_office_id)||'</version>');
      writeln_clob(l_xml, tab||tab||'<ind-parameter-specs>');
      writeln_clob(l_xml, tab||tab||tab||'<ind-parameter-spec position="1">');
      writeln_clob(l_xml, tab||tab||tab||tab||'<parameter>Stage</parameter>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<in-range-method>LOGARITHMIC</in-range-method>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<out-range-low-method>NULL</out-range-low-method>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<out-range-high-method>NULL</out-range-high-method>');
      writeln_clob(l_xml, tab||tab||tab||'</ind-parameter-spec>');
      writeln_clob(l_xml, tab||tab||'</ind-parameter-specs>');
      writeln_clob(l_xml, tab||tab||'<dep-parameter>Flow</dep-parameter>');
      writeln_clob(l_xml, tab||tab||'<description>Stream Rating (Base + Shifts and Offsets)</description>');
      writeln_clob(l_xml, tab||'</rating-template>');
      writeln_clob(l_xml, tab||'<rating-spec office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_base_rating_templ_version(p_office_id)||'.'||get_base_rating_spec_version(p_office_id)||'</rating-spec-id>');
      writeln_clob(l_xml, tab||tab||'<template-id>Stage;Flow.'||get_base_rating_templ_version(p_office_id)||'</template-id>');
      writeln_clob(l_xml, tab||tab||'<location-id>'||l_location_id||'</location-id>');
      writeln_clob(l_xml, tab||tab||'<version>'||get_base_rating_spec_version(p_office_id)||'</version>');
      writeln_clob(l_xml, tab||tab||'<source-agency>USGS</source-agency>');
      writeln_clob(l_xml, tab||tab||'<in-range-method>LINEAR</in-range-method>');
      writeln_clob(l_xml, tab||tab||'<out-range-low-method>NEAREST</out-range-low-method>');
      writeln_clob(l_xml, tab||tab||'<out-range-high-method>NEAREST</out-range-high-method>');
      writeln_clob(l_xml, tab||tab||'<active>true</active>');
      writeln_clob(l_xml, tab||tab||'<auto-update>true</auto-update>');
      writeln_clob(l_xml, tab||tab||'<auto-activate>false</auto-activate>');
      writeln_clob(l_xml, tab||tab||'<auto-migrate-extension>false</auto-migrate-extension>');
      writeln_clob(l_xml, tab||tab||'<ind-rounding-specs>');
      writeln_clob(l_xml, tab||tab||tab||'<ind-rounding-spec position="1">'||replace(l_ind_rounding, '????', '4444444444')||'</ind-rounding-spec>');
      writeln_clob(l_xml, tab||tab||'</ind-rounding-specs>');
      writeln_clob(l_xml, tab||tab||'<dep-rounding-spec>'||replace(l_dep_rounding, '????', '4444444444')||'</dep-rounding-spec>');
      writeln_clob(l_xml, tab||tab||'<description>'||nvl(l_station_name, l_location_id)||' USGS Stream Rating (Base + Shifts and Offsets)</description>');
      writeln_clob(l_xml, tab||'</rating-spec>');
      writeln_clob(l_xml, tab||'<usgs-stream-rating office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_base_rating_templ_version(p_office_id)||'.'||get_base_rating_spec_version(p_office_id)||'</rating-spec-id>');
      writeln_clob(l_xml, tab||tab||'<units-id>ft;cfs</units-id>');
      writeln_clob(l_xml, tab||tab||'<effective-date>'||to_char(trunc(l_effective_date, 'mi'), 'yyyy-mm-dd"T"hh24:mi:ss"Z"')||'</effective-date>');
      writeln_clob(l_xml, tab||tab||'<create-date/>');
      writeln_clob(l_xml, tab||tab||'<active>true</active>');
      if l_description is null then
         writeln_clob(l_xml, tab||tab||'<description/>');
      else
         writeln_clob(l_xml, tab||tab||'<description>'||expand_xml_entities(l_description)||'</description>');
      end if;
      if l_shifts.count > 0 then
         for i in 1..l_shifts.count loop
            writeln_clob(l_xml, tab||tab||'<height-shifts>');
            writeln_clob(l_xml, tab||tab||tab||'<effective-date>'||to_char(trunc(l_shifts(i).effective_date, 'mi'), 'yyyy-mm-dd"T"hh24:mi:ss"Z"')||'</effective-date>');
            writeln_clob(l_xml, tab||tab||tab||'<create-date/>');
            writeln_clob(l_xml, tab||tab||tab||'<active>true</active>');
            for j in 1..l_shifts(i).stages.count loop
               exit when l_shifts(i).stages(j) is null;
               writeln_clob(l_xml, tab||tab||tab||'<point>');
               writeln_clob(l_xml, tab||tab||tab||tab||'<ind>'||l_shifts(i).stages(j)||'</ind>');
               writeln_clob(l_xml, tab||tab||tab||tab||'<dep>'||l_shifts(i).shifts(j)||'</dep>');
               writeln_clob(l_xml, tab||tab||tab||'</point>');
            end loop;
            writeln_clob(l_xml, tab||tab||'</height-shifts>');
         end loop;
      else
         writeln_clob(l_xml, tab||tab||'<height-shifts/>');
      end if;
      if l_offsets.stages is not null and l_offsets.stages.count > 0 then
         writeln_clob(l_xml, tab||tab||'<height-offsets>');
         for j in 1..l_offsets.stages.count loop
            writeln_clob(l_xml, tab||tab||tab||'<point>');
            writeln_clob(l_xml, tab||tab||tab||tab||'<ind>'||l_offsets.stages(j)||'</ind>');
            writeln_clob(l_xml, tab||tab||tab||tab||'<dep>'||l_offsets.offsets(j)||'</dep>');
            writeln_clob(l_xml, tab||tab||tab||'</point>');
         end loop;
         writeln_clob(l_xml, tab||tab||'</height-offsets>');
      else
         writeln_clob(l_xml, tab||tab||'<height-offsets/>');
      end if;
      writeln_clob(l_xml, tab||tab||'<rating-points>');
      for i in 1..l_stages.count loop
         writeln_clob(l_xml, tab||tab||tab||'<point>');
         writeln_clob(l_xml, tab||tab||tab||tab||'<ind>'||l_stages(i)||'</ind>');
         writeln_clob(l_xml, tab||tab||tab||tab||'<dep>'||l_flows(i)||'</dep>');
         writeln_clob(l_xml, tab||tab||tab||'</point>');
      end loop;
      writeln_clob(l_xml, tab||tab||'</rating-points>');
      writeln_clob(l_xml, tab||'</usgs-stream-rating>');
      writeln_clob(l_xml, '</ratings>');
      dbms_lob.close(l_xml);
      return l_xml;
   exception
      when others then
         cwms_msg.log_db_message( cwms_msg.msg_level_normal, dbms_utility.format_error_backtrace);
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, dbms_utility.format_error_stack);
         declare
            l_clob clob;
         begin
            dbms_lob.createtemporary(l_clob, true);
            dbms_lob.append(l_clob, p_rating_base);
            dbms_lob.append(l_clob, p_rating_exsa);
            store_text(l_clob, l_clob_id, p_office_id);
            commit;
         end;
         raise;
   end;
end base_to_xml;

function exsa_to_xml(
   p_rating_text in clob,
   p_office_id   in varchar2)
   return clob
is
   tab               constant varchar2(1) := chr(9);
   l_xml             clob;
   l_lines           str_tab_t;
   l_lines2          str_tab_t;
   l_parts           str_tab_t;
   l_text            varchar2(256);
   l_clob_id         varchar2(256) := '/_usgs-ratings/exsa/'||cwms_msg.get_msg_id;
   l_description     varchar2(256);
   l_effective_date  date;
   l_station_number  varchar2(15);
   l_location_id     varchar2(57);
   l_station_name    varchar2(128);
   l_stages          number_tab_t;
   l_flows           number_tab_t;
   l_dates           date_table_type;
   l_ind_rounding    varchar2(10);
   l_dep_rounding    varchar2(10);
begin
   begin
      l_lines := cwms_util.split_text(p_rating_text, chr(10));
      -------------------------------------
      -- get the station number and name --
      -------------------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //STATION AGENCY%';
      if l_parts.count = 0 then
            cwms_err.raise('ERROR', 'Could not find rating station number. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count > 1 then
            cwms_err.raise('ERROR', 'Found multiple rating station numbers. Clob ID is '||l_clob_id);
      end if;
      l_parts := cwms_util.split_text(l_parts(1));
      for i in 1..l_parts.count loop
         if l_parts(i) like 'NUMBER=%' then
            l_station_number := trim(cwms_util.split_text(replace(l_parts(i), '"', null), 2, '='));
            exit;
         end if;
      end loop;
      if l_station_number is null then
         cwms_err.raise('ERROR', 'Could not find rating station number. Clob ID is '||l_clob_id);
      end if;
      l_location_id := nvl(cwms_loc.get_location_id(l_station_number, p_office_id), l_station_number);
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //STATION NAME%';
      if l_parts.count > 1 then
         cwms_err.raise('ERROR', 'Found multiple rating station names. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count = 1 then
         l_station_name := trim('"' from trim(substr(l_parts(1), instr(l_parts(1), '=')+1)));
      end if;
      -------------------------------------------
      -- get the rating number and description --
      -------------------------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING ID=%';
      if l_parts.count > 0 then
         l_description := 'Rating '||trim(cwms_util.split_text(replace(substr(l_parts(1), instr(l_parts(1), '=')+1), '"', null), 1));
      end if;
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING REMARKS=%';
      if l_parts.count > 0 then
         if l_description is not null then
            l_description := l_description||'-';
         end if;
         l_description := l_description||trim(replace(substr(l_parts(1), instr(l_parts(1), '=')+1), '"', null));
      end if;
      ----------------------------
      -- get the effective date --
      ----------------------------
      select column_value
        bulk collect
        into l_lines2
        from table(l_lines)
       where regexp_like(column_value,  '^# //(RATING SHIFTED|SHIFT_(PREV|NEXT) BEGIN)=.+$');
      if l_lines2.count = 0 then
         select column_value
           bulk collect
           into l_lines2
           from table(l_lines)
          where column_value like  '# // RATING\_DATETIME BEGIN=%' escape '\';
         if l_lines2.count = 0 then
            select column_value
              bulk collect
              into l_lines2
              from table(l_lines)
             where column_value like  '# // RETRIEVED:%';
            if l_lines2.count = 0 then
                  cwms_err.raise('ERROR', 'Could not find rating effective time. Clob ID is '||l_clob_id);
            end if;
         end if;
      end if;
      l_dates := date_table_type();
      for i in 1..l_lines2.count loop
         l_dates.extend;
         l_dates(l_dates.count) := date_from_line(l_lines2(i));
         if l_dates(l_dates.count) is null then l_dates.trim; end if;
      end loop;
      select max(column_value)
        into l_effective_date
        from table(l_dates);
      l_dates.delete;
      ----------------------------
      -- get the rounding specs --
      ----------------------------
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING_INDEP ROUNDING=%';
      if l_parts.count > 1 then
            cwms_err.raise('ERROR', 'Found multiple stage rounding specifications. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count = 0 then
            l_ind_rounding := '4444444444';
      else
         begin
            select cwms_util.split_text(trim(replace(column_value, '"', null)), 2, '=')
              into l_ind_rounding
              from table(cwms_util.split_text(l_parts(1)))
             where column_value like 'ROUNDING=%';
         exception
            when no_data_found then
               cwms_err.raise('ERROR', 'Could not find stage rounding specification. Clob ID is '||l_clob_id);
         end;
      end if;
      select column_value
        bulk collect
        into l_parts
        from table(l_lines)
       where column_value like '# //RATING_DEP ROUNDING=%';
      if l_parts.count > 1 then
            cwms_err.raise('ERROR', 'Found multiple flow rounding specifications. Clob ID is '||l_clob_id);
      end if;
      if l_parts.count = 0 then
            l_dep_rounding := '4444444444';
      else
         begin
            select cwms_util.split_text(trim(replace(column_value, '"', null)), 2, '=')
              into l_dep_rounding
              from table(cwms_util.split_text(l_parts(1)))
             where column_value like 'ROUNDING=%';
         exception
            when no_data_found then
               cwms_err.raise('ERROR', 'Could not find flow rounding specification. Clob ID is '||l_clob_id);
         end;
      end if;
      ---------------------------
      -- get the rating values --
      ---------------------------
      select column_value
        bulk collect
        into l_lines2
        from table(l_lines)
       where column_value not like '#%';

      select to_number(text)
        bulk collect
        into l_stages
        from (select cwms_util.split_text(column_value, 1) as text
                from table(l_lines2)
             )
       where trim(translate(text, '-+.0123456789', ' ')) is null;

      select to_number(text)
        bulk collect
        into l_flows
        from (select cwms_util.split_text(column_value, 3) as text
                from table(l_lines2)
             )
       where trim(translate(text, '-+.0123456789', ' ')) is null;
       if l_stages.count != l_flows.count or l_stages.count != l_lines2.count-2 then
         cwms_err.raise('ERROR', 'Error parsing rating values.  Clob ID is '||l_clob_id);
       end if;

      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      writeln_clob(l_xml, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlschema/cwms/Ratings.xsd">');
      writeln_clob(l_xml, tab||'<rating-template office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<parameters-id>Stage;Flow</parameters-id>');
      writeln_clob(l_xml, tab||tab||'<version>'||get_exsa_rating_templ_version(p_office_id)||'</version>');
      writeln_clob(l_xml, tab||tab||'<ind-parameter-specs>');
      writeln_clob(l_xml, tab||tab||tab||'<ind-parameter-spec position="1">');
      writeln_clob(l_xml, tab||tab||tab||tab||'<parameter>Stage</parameter>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<in-range-method>LINEAR</in-range-method>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<out-range-low-method>NULL</out-range-low-method>');
      writeln_clob(l_xml, tab||tab||tab||tab||'<out-range-high-method>NULL</out-range-high-method>');
      writeln_clob(l_xml, tab||tab||tab||'</ind-parameter-spec>');
      writeln_clob(l_xml, tab||tab||'</ind-parameter-specs>');
      writeln_clob(l_xml, tab||tab||'<dep-parameter>Flow</dep-parameter>');
      writeln_clob(l_xml, tab||tab||'<description>Expanded, Shift-Adjusted Stream Rating</description>');
      writeln_clob(l_xml, tab||'</rating-template>');
      writeln_clob(l_xml, tab||'<rating-spec office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_exsa_rating_templ_version(p_office_id)||'.'||get_exsa_rating_spec_version(p_office_id)||'</rating-spec-id>');
      writeln_clob(l_xml, tab||tab||'<template-id>Stage;Flow.'||get_exsa_rating_templ_version(p_office_id)||'</template-id>');
      writeln_clob(l_xml, tab||tab||'<location-id>'||l_location_id||'</location-id>');
      writeln_clob(l_xml, tab||tab||'<version>'||get_exsa_rating_spec_version(p_office_id)||'</version>');
      writeln_clob(l_xml, tab||tab||'<source-agency>USGS</source-agency>');
      writeln_clob(l_xml, tab||tab||'<in-range-method>LINEAR</in-range-method>');
      writeln_clob(l_xml, tab||tab||'<out-range-low-method>NEAREST</out-range-low-method>');
      writeln_clob(l_xml, tab||tab||'<out-range-high-method>NEAREST</out-range-high-method>');
      writeln_clob(l_xml, tab||tab||'<active>true</active>');
      writeln_clob(l_xml, tab||tab||'<auto-update>true</auto-update>');
      writeln_clob(l_xml, tab||tab||'<auto-activate>false</auto-activate>');
      writeln_clob(l_xml, tab||tab||'<auto-migrate-extension>false</auto-migrate-extension>');
      writeln_clob(l_xml, tab||tab||'<ind-rounding-specs>');
      writeln_clob(l_xml, tab||tab||tab||'<ind-rounding-spec position="1">'||replace(l_ind_rounding, '????', '4444444444')||'</ind-rounding-spec>');
      writeln_clob(l_xml, tab||tab||'</ind-rounding-specs>');
      writeln_clob(l_xml, tab||tab||'<dep-rounding-spec>'||replace(l_dep_rounding, '????', '4444444444')||'</dep-rounding-spec>');
      writeln_clob(l_xml, tab||tab||'<description>'||nvl(l_station_name, l_location_id)||' Expanded, Shift-Adjusted USGS Stream Rating</description>');
      writeln_clob(l_xml, tab||'</rating-spec>');
      writeln_clob(l_xml, tab||'<simple-rating office-id="'||p_office_id||'">');
      writeln_clob(l_xml, tab||tab||'<rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_exsa_rating_templ_version(p_office_id)||'.'||get_exsa_rating_spec_version(p_office_id)||'</rating-spec-id>');
      writeln_clob(l_xml, tab||tab||'<units-id>ft;cfs</units-id>');
      writeln_clob(l_xml, tab||tab||'<effective-date>'||to_char(trunc(l_effective_date, 'mi'), 'yyyy-mm-dd"T"hh24:mi:ss"Z"')||'</effective-date>');
      writeln_clob(l_xml, tab||tab||'<create-date/>');
      writeln_clob(l_xml, tab||tab||'<active>true</active>');
      if l_description is null then
         writeln_clob(l_xml, tab||tab||'<description/>');
      else
         writeln_clob(l_xml, tab||tab||'<description>'||expand_xml_entities(l_description)||'</description>');
      end if;
      writeln_clob(l_xml, tab||tab||'<rating-points>');
      for i in 1..l_stages.count loop
         writeln_clob(l_xml, tab||tab||tab||'<point>');
         writeln_clob(l_xml, tab||tab||tab||tab||'<ind>'||l_stages(i)||'</ind>');
         writeln_clob(l_xml, tab||tab||tab||tab||'<dep>'||l_flows(i)||'</dep>');
         writeln_clob(l_xml, tab||tab||tab||'</point>');
      end loop;
      writeln_clob(l_xml, tab||tab||'</rating-points>');
      writeln_clob(l_xml, tab||'</simple-rating>');
      writeln_clob(l_xml, '</ratings>');
      dbms_lob.close(l_xml);
      return l_xml;
   exception
      when others then
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, dbms_utility.format_error_backtrace);
         store_text(p_rating_text, l_clob_id, p_office_id);
         raise;
   end;
end exsa_to_xml;

function retrieve_rating(
   p_location_id in varchar2,
   p_rating_type in varchar2,
   p_xml_encode  in varchar2,
   p_office_id   in varchar2 default null)
   return clob
is
   l_office_id   varchar2(16);
   l_rating_type varchar2(4);
   l_usgs_id     varchar2(32);
   l_clob1       clob;
   l_clob2       clob;
   l_encode      boolean;
begin
   if p_location_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_OFFICE_ID');
   end if;
   if p_rating_type is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_RATING_TYPE');
   end if;
   if p_xml_encode is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_XML_ENCODE');
   end if;
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_rating_type := lower(p_rating_type);
   if l_rating_type not in ('exsa', 'base', 'corr') then
      cwms_err.raise('ERROR', 'Rating type must be ''EXSA'', ''BASE'', or ''CORR''');
   end if;
   l_encode := cwms_util.is_true(p_xml_encode);
   begin
      select location_id
        into l_usgs_id
        from av_loc2
       where location_code = cwms_loc.get_location_code(l_office_id, p_location_id)
         and unit_system = 'EN'
         and loc_alias_category = 'Agency Aliases'
         and loc_alias_group = 'USGS Station Number';
   exception
      when no_data_found then
         cwms_err.raise('ERROR', 'No USGS Station number found for location '||p_location_id);
   end;
   l_clob1 := get_url(replace(replace(rating_url, '<type>', l_rating_type), '<site>', l_usgs_id));
   if l_encode then
      case l_rating_type
      when 'exsa' then
         return exsa_to_xml(l_clob1, l_office_id);
      when 'base' then
         l_clob2 := get_url(replace(replace(rating_url, '<type>', 'exsa'), '<site>', l_usgs_id));
         return base_to_xml(l_clob1, l_clob2, l_office_id);
      when 'corr' then
         return corr_to_xml(l_clob1, l_office_id);
      end case;
   else
      return l_clob1;
   end if;
end retrieve_rating;

procedure process_and_store_rating_text(
   p_rating_type in varchar2,
   p_rating_text in clob,
   p_rating_exsa in clob,
   p_office_id   in varchar2)
is
   item_does_not_exist exception;
   pragma exception_init(item_does_not_exist, -20034);
   l_clob           clob;
   l_xml            xmltype;
   l_template       rating_template_t;
   l_spec           rating_spec_t;
   l_rating         rating_t;
   l_spec_code      integer;
   l_hash_value     varchar2(40);
   l_first          boolean := true;
   l_active         boolean;
begin
   --------------------------------------------------------
   -- process the rating into the CWMS XML rating format --
   --------------------------------------------------------
   l_clob := case upper(p_rating_type)
             when 'BASE' then base_to_xml(p_rating_text, p_rating_exsa, p_office_id)
             when 'EXSA' then exsa_to_xml(p_rating_text, p_office_id)
             when 'CORR' then corr_to_xml(p_rating_text, p_office_id)
             else null
             end;
   if l_clob is null then
      cwms_err.raise('INVALID_ITEM', p_rating_type, 'USGS rating type');
   end if;
   l_xml := xmltype(l_clob);
   ---------------------------------------------------------
   -- get the existing rating template or store a new one --
   ---------------------------------------------------------
   if l_first then
      begin
         l_template := new rating_template_t(
            p_office_id,
            cwms_util.get_xml_text(l_xml, '/ratings/rating-template/parameters-id'),
            cwms_util.get_xml_text(l_xml, '/ratings/rating-template/version'));
      exception
         when item_does_not_exist then
            l_template := new rating_template_t(cwms_util.get_xml_node(l_xml, '/ratings/rating-template'));
            l_template.store('T');
      end;
      l_first := false;
   end if;
   -----------------------------------------------------
   -- get the existing rating spec or store a new one --
   -----------------------------------------------------
   begin
      l_spec := new rating_spec_t(
         cwms_util.get_xml_text(l_xml, '/ratings/rating-spec/rating-spec-id'),
         p_office_id);
   exception
      when item_does_not_exist then
         l_spec := new rating_spec_t(cwms_util.get_xml_node(l_xml, '/ratings/rating-spec'));
         l_spec.store('T');
   end;
   ----------------------------------------------------------------------
   -- create the rating from the XML and adjust settings based on spec --
   ----------------------------------------------------------------------
   if upper(p_rating_type) = 'BASE' then
      l_rating := new stream_rating_t(cwms_util.get_xml_node(l_xml, '/ratings/usgs-stream-rating'));
   else
      l_rating := new rating_t(cwms_util.get_xml_node(l_xml, '/ratings/simple-rating'));
   end if;
   l_rating.convert_to_database_time;
   l_rating.active_flag := l_spec.auto_activate_flag;
   if l_spec.auto_migrate_ext_flag = 'T' and l_rating.rating_info is not null then
      declare
         l_prev rating_tab_t;
      begin
         l_prev := cwms_rating.retrieve_ratings_obj_f(
            p_spec_id_mask         => l_rating.rating_spec_id,
            p_effective_date_start => null,
            p_effective_date_end   => l_rating.effective_date - 1/86400,
            p_time_zone            => 'UTC',
            p_office_id_mask       => p_office_id);

         if l_prev.count > 0 and l_prev(l_prev.count).rating_info is not null then
            l_rating.rating_info.extension_values := l_prev(l_prev.count).rating_info.extension_values;
         end if;
      end;
   end if;
   ------------------------------------------------------------------
   -- store the rating and store a hash code for future comparison --
   ------------------------------------------------------------------
   l_rating.store('F');
   l_spec_code := rating_spec_t.get_rating_spec_code(
      l_spec.location_id
      ||'.'
      ||l_spec.template_id
      ||'.'
      ||l_spec.version,
      p_office_id);
   if upper(p_rating_type) = 'BASE' then
      l_hash_value := hash_rating_text(p_rating_exsa);
   else
      l_hash_value := hash_rating_text(p_rating_text);
   end if;
   begin
      select rating_spec_code
        into l_spec_code
        from at_usgs_rating_hash
       where rating_spec_code = l_spec_code;

      update at_usgs_rating_hash
         set hash_value = l_hash_value
       where rating_spec_code = l_spec_code;
   exception
      when no_data_found then
         insert
           into at_usgs_rating_hash
         values (l_spec_code, l_hash_value);
   end;
   commit;
end process_and_store_rating_text;

procedure retrieve_and_store_ratings(
   p_rating_type  in varchar2,
   p_sites        in str_tab_t,
   p_log_progress in varchar2 default 'F',
   p_office_id    in varchar2)
is
   l_log_progress   boolean := cwms_util.return_true_or_false(p_log_progress);
   l_url            varchar2(81);
   l_rating_text    clob;
   l_rating_exsa    clob;
begin
   for i in 1..p_sites.count loop
      l_url := replace(rating_url, '<type>', lower(p_rating_type));
      --------------------------------------------
      -- get the rating from the USGS NWIS site --
      --------------------------------------------
      begin
         l_rating_text := cwms_util.get_url(replace(l_url, '<site>', p_sites(i)));
      exception
         when others then
            cwms_msg.log_db_message(
               cwms_msg.msg_level_normal,
               p_office_id
               ||': '
               ||i
               ||' of '
               ||p_sites.count
               ||': '
               ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
               ||': '
               ||sqlerrm
               ||' retrieving data from '
               ||replace(l_url, '<site>', p_sites(i)));
            continue;
      end;
      if not l_rating_text like '%# //%' then
         cwms_msg.log_db_message(
            cwms_msg.msg_level_normal,
            p_office_id
            ||': '
            ||i
            ||' of '
            ||p_sites.count
            ||': '
            ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
            ||': Invalid rating text:'
            ||chr(10)
            ||substr(l_rating_text, 1, 1000));
         continue;
      end if;
      if l_log_progress then
         cwms_msg.log_db_message(
            cwms_msg.msg_level_verbose,
            p_office_id
            ||': '
            ||i
            ||' of '
            ||p_sites.count
            ||': '
            ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
            ||': '
            ||dbms_lob.getlength(l_rating_text)
            ||' bytes retrieved from '
            ||replace(l_url, '<site>', p_sites(i)));
      end if;
      if p_rating_type = 'BASE' then
         ------------------------------------------------------------
         -- retrieve the EXSA rating for the shift and offset info --
         ------------------------------------------------------------
         l_url := replace(l_url, 'base', 'exsa');
         begin
            l_rating_exsa := get_url(replace(l_url, '<site>', p_sites(i)));
         exception
            when others then
               cwms_msg.log_db_message(
                  cwms_msg.msg_level_normal,
                  p_office_id
                  ||': '
                  ||i
                  ||' of '
                  ||p_sites.count
                  ||': '
                  ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
                  ||': '
                  ||sqlerrm
                  ||' retrieving data from '
                  ||replace(l_url, '<site>', p_sites(i)));
               continue;
         end;
         if not l_rating_exsa like '%# //%' then
            cwms_msg.log_db_message(
               cwms_msg.msg_level_normal,
               p_office_id
               ||': '
               ||i
               ||' of '
               ||p_sites.count
               ||': '
               ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
               ||': Invalid rating text:'
               ||chr(10)
               ||substr(l_rating_exsa, 1, 1000));
            continue;
         end if;
         if l_log_progress then
            cwms_msg.log_db_message(
               cwms_msg.msg_level_verbose,
               p_office_id
               ||': '
               ||i
               ||' of '
               ||p_sites.count
               ||': '
               ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
               ||': '
               ||dbms_lob.getlength(l_rating_exsa)
               ||' bytes retrieved from '
               ||replace(l_url, '<site>', p_sites(i)));
         end if;
      else
         l_rating_exsa := null;
      end if;
      begin
         process_and_store_rating_text(p_rating_type, l_rating_text, l_rating_exsa, p_office_id);
      exception
         when others then
            cwms_msg.log_db_message(
               cwms_msg.msg_level_basic,
               p_office_id
               ||': '
               ||i
               ||' of '
               ||p_sites.count
               ||': '
               ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
               ||': '
               ||dbms_utility.format_error_backtrace);
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               p_office_id
               ||': '
               ||i
               ||' of '
               ||p_sites.count
               ||': '
               ||nvl(cwms_loc.get_location_id_from_alias(p_sites(i), 'USGS Station Number', 'Agency Aliases', p_office_id), p_sites(i))
               ||': '
               ||dbms_utility.format_error_stack);
      end;
   end loop;
end retrieve_and_store_ratings;

procedure retrieve_and_store_ratings(
   p_rating_type in varchar2,
   p_sites       in varchar2 default null,
   p_office_id   in varchar2 default null)
is
   l_office_id      varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_office_code    integer := cwms_util.get_db_office_code(l_office_id);
   l_rating_type    varchar2(9);
   l_sites          str_tab_t;
   l_parts          str_tab_t;
   l_text_filter_id varchar2(32);
begin
   if upper(p_rating_type) not in ('BASE', 'EXSA', 'CORR') then
      cwms_err.raise('INVALID_ITEM', p_rating_type, 'USGS rating type');
   end if;
   l_rating_type := upper(p_rating_type);
   cwms_msg.log_db_message(
      cwms_msg.msg_level_basic,
      l_rating_type||' ratings retreival started for '||l_office_id);
   begin
      -----------------------
      -- get the locations --
      -----------------------
      if p_sites is null then
         -------------------
         -- all locations --
         -------------------
         select bl.base_location_id
                ||substr('-', 1, length(pl.sub_location_id))
                ||pl.sub_location_id
           bulk collect
           into l_parts
           from at_physical_location pl,
                at_base_location bl
          where bl.db_office_code = l_office_code
            and pl.base_location_code = bl.base_location_code;
      else
         -------------------------
         -- specified locations --
         -------------------------
         select trim(column_value)
           bulk collect
           into l_parts
           from table(cwms_util.split_text(p_sites, ','));
         if l_parts.count = 1 then
            begin
               select text_filter_id
                 into l_text_filter_id
                 from at_text_filter
                where office_code in (l_office_code, cwms_util.db_office_code_all)
                  and upper(text_filter_id) = upper(l_parts(1));
            exception
               when no_data_found then null;
            end;
            if l_text_filter_id is not null then
               ------------------------------
               -- text filter id specified --
               ------------------------------
               l_parts := cwms_usgs.filter_locations(l_text_filter_id, 'T', null, p_office_id);
            end if;
         end if;
      end if;
      ----------------------------------
      -- get the USGS station numbers --
      ----------------------------------
      select lga.loc_alias_id
        bulk collect
        into l_sites
        from at_loc_category lc,
             at_loc_group lg,
             at_loc_group_assignment lga
       where lc.loc_category_id = 'Agency Aliases'
         and lg.loc_category_code = lc.loc_category_code
         and lg.loc_group_id = 'USGS Station Number'
         and lga.loc_group_code = lg.loc_group_code
         and lga.location_code in (select cwms_loc.get_location_code(l_office_code, column_value)
                                     from table(l_parts)
                                  )
       order by 1;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_detailed,
         l_office_id||': retrieving ratings for '||l_sites.count||' sites');
      -----------------------
      -- store the ratings --
      -----------------------
      retrieve_and_store_ratings(
         l_rating_type,
         l_sites,
         'T',
         l_office_id);
   exception
      when others then
         cwms_msg.log_db_message(
            cwms_msg.msg_level_basic,
            l_office_id||': '||dbms_utility.format_error_backtrace);
         cwms_msg.log_db_message(
            cwms_msg.msg_level_detailed,
            l_office_id||': '||dbms_utility.format_error_stack);
   end;
   cwms_msg.log_db_message(
      cwms_msg.msg_level_basic,
      l_rating_type||' ratings retreival ended for '||l_office_id);

end retrieve_and_store_ratings;

procedure update_existing_ratings(
   p_office_id in varchar2 default null)
is
   l_office_id        varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_office_code      integer := cwms_util.get_db_office_code(l_office_id);
   l_location_id      varchar2(57);
   l_rating_text      clob;
   l_rating_exsa      clob;
   l_hash_value       varchar2(40);
   l_rating_count     pls_integer := 0;
   l_update_count     pls_integer := 0;
   i                  pls_integer := 0;
begin
   cwms_msg.log_db_message(
      cwms_msg.msg_level_basic,
      'Updating USGS ratings started for '||l_office_id);
   select count(*)
     into l_rating_count
     from (select a.site_number,
                  a.rating_type,
                  a.location_code,
                  a.parameters_id,
                  b.hash_value
             from (select aur.column_value as rating_spec_code,
                          lga.loc_alias_id as site_number,
                          lower(substr(rt.version, 6)) as rating_type,
                          rs.location_code,
                          rt.parameters_id
                     from table(cwms_usgs.get_auto_update_ratings(l_office_id)) aur,
                          at_rating_spec rs,
                          at_rating_template rt,
                          at_loc_category lc,
                          at_loc_group lg,
                          at_loc_group_assignment lga
                    where rs.rating_spec_code = aur.column_value
                      and rs.template_code = rt.template_code
                      and lc.loc_category_id = 'Agency Aliases'
                      and lg.loc_category_code = lc.loc_category_code
                      and lg.loc_group_id = 'USGS Station Number'
                      and lga.loc_group_code = lg.loc_group_code
                      and lga.location_code = rs.location_code
                  ) a
             left outer join at_usgs_rating_hash b
             on b.rating_spec_code = a.rating_spec_code
          );
   for rec in (select a.site_number,
                      a.rating_type,
                      a.location_code,
                      a.parameters_id,
                      b.hash_value
                 from (select aur.column_value as rating_spec_code,
                              lga.loc_alias_id as site_number,
                              lower(substr(rt.version, 6)) as rating_type,
                              rs.location_code,
                              rt.parameters_id
                         from table(cwms_usgs.get_auto_update_ratings(l_office_id)) aur,
                              at_rating_spec rs,
                              at_rating_template rt,
                              at_loc_category lc,
                              at_loc_group lg,
                              at_loc_group_assignment lga
                        where rs.rating_spec_code = aur.column_value
                          and rs.template_code = rt.template_code
                          and lc.loc_category_id = 'Agency Aliases'
                          and lg.loc_category_code = lc.loc_category_code
                          and lg.loc_group_id = 'USGS Station Number'
                          and lga.loc_group_code = lg.loc_group_code
                          and lga.location_code = rs.location_code
                      ) a
                 left outer join at_usgs_rating_hash b
                 on b.rating_spec_code = a.rating_spec_code
              )
   loop
      i := i + 1;
      --------------------------------------------
      -- get the rating from the USGS NWIS site --
      --------------------------------------------
      begin
         l_rating_text := get_url(replace(replace(rating_url, '<site>', rec.site_number), '<type>', rec.rating_type));
      exception
         when others then
            cwms_msg.log_db_message(
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);

            cwms_msg.log_db_message(
               cwms_msg.msg_level_basic,
               sqlerrm);

            continue;
      end;
      if rec.rating_type = 'base' then
         begin
            l_rating_exsa := get_url(replace(replace(rating_url, '<site>', rec.site_number), '<type>', 'exsa'));
         exception
            when others then
               cwms_msg.log_db_message(
                  cwms_msg.msg_level_detailed,
                  dbms_utility.format_error_backtrace);

               cwms_msg.log_db_message(
                  cwms_msg.msg_level_basic,
                  sqlerrm);

               continue;
         end;
         l_hash_value := hash_rating_text(l_rating_exsa);
      else
         l_hash_value := hash_rating_text(l_rating_text);
      end if;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_verbose,
         ''
         ||i
         ||' of '
         ||l_rating_count
         ||' Checking USGS rating for '
         ||cwms_loc.get_location_id(rec.location_code)
         ||'.'
         ||rec.parameters_id
         ||case upper(rec.rating_type)
           when 'BASE' then get_base_rating_templ_version(l_office_id)||'.'||get_base_rating_spec_version(l_office_id)
           when 'EXSA' then get_exsa_rating_templ_version(l_office_id)||'.'||get_exsa_rating_spec_version(l_office_id)
           when 'CORR' then get_corr_rating_templ_version(l_office_id)||'.'||get_corr_rating_spec_version(l_office_id)
           end);
      --------------------------------------------------------------------
      -- compare it to the previous rating retrieved from the same site --
      --------------------------------------------------------------------
      if l_hash_value = rec.hash_value then
         null;
      else
         ------------------------------
         -- store the updated rating --
         ------------------------------
         cwms_msg.log_db_message(
            cwms_msg.msg_level_detailed,
            'Updating USGS rating for '
            ||cwms_loc.get_location_id(rec.location_code)
            ||'.'
            ||rec.parameters_id
            ||case upper(rec.rating_type)
              when 'BASE' then get_base_rating_templ_version(l_office_id)||'.'||get_base_rating_spec_version(l_office_id)
              when 'EXSA' then get_exsa_rating_templ_version(l_office_id)||'.'||get_exsa_rating_spec_version(l_office_id)
              when 'CORR' then get_corr_rating_templ_version(l_office_id)||'.'||get_corr_rating_spec_version(l_office_id)
              end);
         process_and_store_rating_text(rec.rating_type, l_rating_text, l_rating_exsa, l_office_id);
         l_update_count := l_update_count + 1;
      end if;
   end loop;
   cwms_msg.log_db_message(
      cwms_msg.msg_level_basic,
      'Updating USGS ratings ended for '||l_office_id||': '||l_update_count||' rating(s) updated');
end update_existing_ratings;

procedure generate_production_ratings2(
   p_office_id in varchar2 default null)
is
   l_base_specs     rating_spec_tab_t;
   l_exsa_specs     rating_spec_tab_t;
   l_corr_specs     rating_spec_tab_t;
   l_ratings1       rating_tab_t;
   l_ratings2       rating_tab_t;
   l_lines          str_tab_t := str_tab_t();
   l_effective_date date;
   l_office_id      varchar2(16);
   l_office_code    number(14);

   procedure append(
      p_table in out nocopy str_tab_t,
      p_text  in            varchar2)
   is
   begin
      p_table.extend;
      p_table(p_table.count) := p_text;
   end append;
begin
   l_office_id   := cwms_util.get_db_office_id(p_office_id);
   l_office_code := cwms_util.get_db_office_code(l_office_id);
   for rec in (
      select cwms_loc.get_location_id(location_code) as location_id
        from at_loc_group_assignment
       where office_code = l_office_code
         and loc_group_code = (select loc_group_code
                                 from at_loc_group where loc_group_id = 'USGS Station Number'
                                  and loc_category_code = (select loc_category_code
                                                             from at_loc_category
                                                            where loc_category_id = 'Agency Aliases'
                                                          )
                              )
       order by 1
              )
   loop
      generate_production_ratings(rec.location_id, p_office_id);
   end loop;
end generate_production_ratings2;

procedure generate_production_ratings(
   p_location_id in varchar2,
   p_office_id   in varchar2 default null)
is
   l_base_specs     rating_spec_tab_t;
   l_exsa_specs     rating_spec_tab_t;
   l_corr_specs     rating_spec_tab_t;
   l_ratings1       rating_tab_t;
   l_ratings2       rating_tab_t;
   l_lines          str_tab_t := str_tab_t();
   l_effective_date date;
   l_location_id    varchar2(57);

   procedure append(
      p_table in out nocopy str_tab_t,
      p_text  in            varchar2)
   is
   begin
      p_table.extend;
      p_table(p_table.count) := p_text;
   end append;
begin
   pragma inline(append, 'YES');

   l_location_id := cwms_loc.get_location_id(p_location_id, p_office_id);

   l_base_specs := cwms_rating.retrieve_specs_obj_f(l_location_id||'.Stage;Flow.'||get_base_rating_templ_version(p_office_id)||'.'||get_base_rating_spec_version(p_office_id)||'', p_office_id);
   if l_base_specs.count = 0 then
      l_exsa_specs := cwms_rating.retrieve_specs_obj_f(l_location_id||'.Stage;Flow.'||get_exsa_rating_templ_version(p_office_id)||'.'||get_exsa_rating_spec_version(p_office_id)||'', p_office_id);
   end if;
   if l_base_specs.count = 1 then
      l_ratings1 := cwms_rating.retrieve_ratings_obj_f(l_location_id||'.Stage;Flow.'||get_base_rating_templ_version(p_office_id)||'.'||get_base_rating_spec_version(p_office_id)||'', null, null, null, p_office_id);
      l_ratings1(l_ratings1.count).convert_to_database_time;
      l_corr_specs := cwms_rating.retrieve_specs_obj_f(l_location_id||'.Stage;Stage-Correction.'||get_corr_rating_templ_version(p_office_id)||'.'||get_corr_rating_spec_version(p_office_id)||'', p_office_id);
      if l_corr_specs.count = 1 then
         --------------------------------
         -- corr + base virtual rating --
         --------------------------------
         l_ratings2 := cwms_rating.retrieve_ratings_obj_f(l_location_id||'.Stage;Stage-Correction.'||get_corr_rating_templ_version(p_office_id)||'.'||get_corr_rating_spec_version(p_office_id)||'', null, null, null, p_office_id);
         l_ratings2(l_ratings2.count).convert_to_database_time;
         l_effective_date := greatest(l_ratings1(l_ratings1.count).effective_date, l_ratings2(l_ratings2.count).effective_date);
         append(l_lines, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
         append(l_lines, '  <rating-template office-id="'||p_office_id||'">');
         append(l_lines, '    <parameters-id>Stage;Flow</parameters-id>');
         append(l_lines, '    <version>'||get_prod_rating_templ_version(p_office_id)||'</version>');
         append(l_lines, '    <ind-parameter-specs>');
         append(l_lines, '      <ind-parameter-spec position="1">');
         append(l_lines, '        <parameter>Stage</parameter>');
         append(l_lines, '        <in-range-method>LINEAR</in-range-method>');
         append(l_lines, '        <out-range-low-method>NULL</out-range-low-method>');
         append(l_lines, '        <out-range-high-method>NULL</out-range-high-method>');
         append(l_lines, '      </ind-parameter-spec>');
         append(l_lines, '    </ind-parameter-specs>');
         append(l_lines, '    <dep-parameter>Flow</dep-parameter>');
         append(l_lines, '    <description>Production Stage;Flow rating using USGS ratings</description>');
         append(l_lines, '  </rating-template>');
         append(l_lines, '  <rating-spec office-id="'||p_office_id||'">');
         append(l_lines, '    <rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'.'||get_prod_rating_spec_version(p_office_id)||'</rating-spec-id>');
         append(l_lines, '    <template-id>Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'</template-id>');
         append(l_lines, '    <location-id>'||l_location_id||'</location-id>');
         append(l_lines, '    <version>'||get_prod_rating_spec_version(p_office_id)||'</version>');
         append(l_lines, '    <in-range-method>LINEAR</in-range-method>');
         append(l_lines, '    <out-range-low-method>NULL</out-range-low-method>');
         append(l_lines, '    <out-range-high-method>PREVIOUS</out-range-high-method>');
         append(l_lines, '    <active>true</active>');
         append(l_lines, '    <auto-update>true</auto-update>');
         append(l_lines, '    <auto-activate>true</auto-activate>');
         append(l_lines, '    <auto-migrate-extension>false</auto-migrate-extension>');
         append(l_lines, '    <ind-rounding-specs>');
         append(l_lines, '      <ind-rounding-spec position="1">'||l_base_specs(1).ind_rounding_specs(1)||'</ind-rounding-spec>');
         append(l_lines, '    </ind-rounding-specs>');
         append(l_lines, '    <dep-rounding-spec>'||l_base_specs(1).dep_rounding_spec||'</dep-rounding-spec>');
         append(l_lines, '    <description>'||l_location_id||' Production Stage;Flow rating using USGS ratings</description>');
         append(l_lines, '  </rating-spec>');
         append(l_lines, '  <virtual-rating office-id="'||p_office_id||'">');
         append(l_lines, '    <rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'.'||get_prod_rating_spec_version(p_office_id)||'</rating-spec-id>');
         append(l_lines, '    <effective-date>'||cwms_util.get_xml_time(l_effective_date, 'UTC')||'</effective-date>');
         append(l_lines, '    <active>true</active>');
         append(l_lines, '    <connections>R2I1=I1,R2I2=R1D,R3I1=R2D</connections>');
         append(l_lines, '    <source-ratings>');
         append(l_lines, '      <source-rating position="1">');
         append(l_lines, '        <rating-spec-id>'||l_location_id||'.Stage;Stage-Correction.'||get_corr_rating_templ_version(p_office_id)||'.'||get_corr_rating_spec_version(p_office_id)||' {ft;ft}</rating-spec-id>');
         append(l_lines, '      </source-rating>');
         append(l_lines, '      <source-rating position="2">');
         append(l_lines, '        <rating-spec-id>I1 + I2 {ft,ft;ft}</rating-spec-id>');
         append(l_lines, '      </source-rating>');
         append(l_lines, '      <source-rating position="3">');
         append(l_lines, '        <rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_base_rating_templ_version(p_office_id)||'.'||get_base_rating_spec_version(p_office_id)||' {ft;cfs}</rating-spec-id>');
         append(l_lines, '      </source-rating>');
         append(l_lines, '    </source-ratings>');
         append(l_lines, '  </virtual-rating>');
         append(l_lines, '</ratings>');
      else
         ------------------------------
         -- base transitional rating --
         ------------------------------
         l_effective_date := l_ratings1(l_ratings1.count).effective_date;
         append(l_lines, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
         append(l_lines, '  <rating-template office-id="'||p_office_id||'">');
         append(l_lines, '    <parameters-id>Stage;Flow</parameters-id>');
         append(l_lines, '    <version>'||get_prod_rating_templ_version(p_office_id)||'</version>');
         append(l_lines, '    <ind-parameter-specs>');
         append(l_lines, '      <ind-parameter-spec position="1">');
         append(l_lines, '        <parameter>Stage</parameter>');
         append(l_lines, '        <in-range-method>LINEAR</in-range-method>');
         append(l_lines, '        <out-range-low-method>NULL</out-range-low-method>');
         append(l_lines, '        <out-range-high-method>NULL</out-range-high-method>');
         append(l_lines, '      </ind-parameter-spec>');
         append(l_lines, '    </ind-parameter-specs>');
         append(l_lines, '    <dep-parameter>Flow</dep-parameter>');
         append(l_lines, '    <description>Production Stage;Flow rating using USGS ratings</description>');
         append(l_lines, '  </rating-template>');
         append(l_lines, '  <rating-spec office-id="'||p_office_id||'">');
         append(l_lines, '    <rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'.'||get_prod_rating_spec_version(p_office_id)||'</rating-spec-id>');
         append(l_lines, '    <template-id>Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'</template-id>');
         append(l_lines, '    <location-id>'||l_location_id||'</location-id>');
         append(l_lines, '    <version>'||get_prod_rating_spec_version(p_office_id)||'</version>');
         append(l_lines, '    <in-range-method>LINEAR</in-range-method>');
         append(l_lines, '    <out-range-low-method>NULL</out-range-low-method>');
         append(l_lines, '    <out-range-high-method>PREVIOUS</out-range-high-method>');
         append(l_lines, '    <active>true</active>');
         append(l_lines, '    <auto-update>true</auto-update>');
         append(l_lines, '    <auto-activate>true</auto-activate>');
         append(l_lines, '    <auto-migrate-extension>false</auto-migrate-extension>');
         append(l_lines, '    <ind-rounding-specs>');
         append(l_lines, '      <ind-rounding-spec position="1">'||l_base_specs(1).ind_rounding_specs(1)||'</ind-rounding-spec>');
         append(l_lines, '    </ind-rounding-specs>');
         append(l_lines, '    <dep-rounding-spec>'||l_base_specs(1).dep_rounding_spec||'</dep-rounding-spec>');
         append(l_lines, '    <description>'||l_location_id||' Production Stage;Flow rating using USGS ratings</description>');
         append(l_lines, '  </rating-spec>');
         append(l_lines, '  <transitional-rating office-id="'||p_office_id||'">');
         append(l_lines, '    <rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'.'||get_prod_rating_spec_version(p_office_id)||'</rating-spec-id>');
         append(l_lines, '    <units-id>ft;cfs</units-id>');
         append(l_lines, '    <effective-date>'||cwms_util.get_xml_time(l_effective_date, 'UTC')||'</effective-date>');
         append(l_lines, '    <active>true</active>');
         append(l_lines, '    <select>');
         append(l_lines, '      <default>R1</default>');
         append(l_lines, '    </select>');
         append(l_lines, '    <source-ratings>');
         append(l_lines, '      <rating-spec-id position="1">'||l_location_id||'.Stage;Flow.'||get_base_rating_templ_version(p_office_id)||'.'||get_base_rating_spec_version(p_office_id)||'</rating-spec-id>');
         append(l_lines, '    </source-ratings>');
         append(l_lines, '  </transitional-rating>');
         append(l_lines, '</ratings>');
      end if;
   elsif l_exsa_specs.count = 1 then
      ------------------------------
      -- exsa transitional rating --
      ------------------------------
      l_ratings1 := cwms_rating.retrieve_ratings_obj_f(l_location_id||'.Stage;Flow.'||get_exsa_rating_templ_version(p_office_id)||'.'||get_exsa_rating_spec_version(p_office_id)||'', null, null, null, p_office_id);
      l_ratings1(l_ratings1.count).convert_to_database_time;
      l_effective_date := l_ratings1(l_ratings1.count).effective_date;
      append(l_lines, '<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">');
      append(l_lines, '  <rating-template office-id="'||p_office_id||'">');
      append(l_lines, '    <parameters-id>Stage;Flow</parameters-id>');
      append(l_lines, '    <version>'||get_prod_rating_templ_version(p_office_id)||'</version>');
      append(l_lines, '    <ind-parameter-specs>');
      append(l_lines, '      <ind-parameter-spec position="1">');
      append(l_lines, '        <parameter>Stage</parameter>');
      append(l_lines, '        <in-range-method>LINEAR</in-range-method>');
      append(l_lines, '        <out-range-low-method>NULL</out-range-low-method>');
      append(l_lines, '        <out-range-high-method>NULL</out-range-high-method>');
      append(l_lines, '      </ind-parameter-spec>');
      append(l_lines, '    </ind-parameter-specs>');
      append(l_lines, '    <dep-parameter>Flow</dep-parameter>');
      append(l_lines, '    <description>Production Stage;Flow rating using USGS ratings</description>');
      append(l_lines, '  </rating-template>');
      append(l_lines, '  <rating-spec office-id="'||p_office_id||'">');
      append(l_lines, '    <rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'.'||get_prod_rating_spec_version(p_office_id)||'</rating-spec-id>');
      append(l_lines, '    <template-id>Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'</template-id>');
      append(l_lines, '    <location-id>'||l_location_id||'</location-id>');
      append(l_lines, '    <version>'||get_prod_rating_spec_version(p_office_id)||'</version>');
      append(l_lines, '    <in-range-method>LINEAR</in-range-method>');
      append(l_lines, '    <out-range-low-method>NULL</out-range-low-method>');
      append(l_lines, '    <out-range-high-method>PREVIOUS</out-range-high-method>');
      append(l_lines, '    <active>true</active>');
      append(l_lines, '    <auto-update>true</auto-update>');
      append(l_lines, '    <auto-activate>true</auto-activate>');
      append(l_lines, '    <auto-migrate-extension>false</auto-migrate-extension>');
      append(l_lines, '    <ind-rounding-specs>');
      append(l_lines, '      <ind-rounding-spec position="1">'||l_exsa_specs(1).ind_rounding_specs(1)||'</ind-rounding-spec>');
      append(l_lines, '    </ind-rounding-specs>');
      append(l_lines, '    <dep-rounding-spec>'||l_exsa_specs(1).dep_rounding_spec||'</dep-rounding-spec>');
      append(l_lines, '    <description>'||l_location_id||' Production Stage;Flow rating using USGS ratings</description>');
      append(l_lines, '  </rating-spec>');
      append(l_lines, '  <transitional-rating office-id="'||p_office_id||'">');
      append(l_lines, '    <rating-spec-id>'||l_location_id||'.Stage;Flow.'||get_prod_rating_templ_version(p_office_id)||'.'||get_prod_rating_spec_version(p_office_id)||'</rating-spec-id>');
      append(l_lines, '    <units-id>ft;cfs</units-id>');
      append(l_lines, '    <effective-date>'||cwms_util.get_xml_time(l_effective_date, 'UTC')||'</effective-date>');
      append(l_lines, '    <active>true</active>');
      append(l_lines, '    <select>');
      append(l_lines, '      <default>R1</default>');
      append(l_lines, '    </select>');
      append(l_lines, '    <source-ratings>');
      append(l_lines, '      <rating-spec-id position="1">'||l_location_id||'.Stage;Flow.'||get_exsa_rating_templ_version(p_office_id)||'.'||get_exsa_rating_spec_version(p_office_id)||'</rating-spec-id>');
      append(l_lines, '    </source-ratings>');
      append(l_lines, '  </transitional-rating>');
      append(l_lines, '</ratings>');
   end if;
   if l_lines.count > 0 then
      cwms_rating.store_ratings_xml(cwms_util.join_text(l_lines, chr(10)), 'F', 'F');
   end if;
end generate_production_ratings;

procedure retrieve_available_ratings2(
   p_office_id in varchar2 default null)
is
   l_office_id     varchar2(16);
   l_office_code   number(14);
   l_locations     str_tab_t;
   l_locations_str varchar2(32767);
   l_ratings       rating_tab_t;
begin
   l_office_id   := cwms_util.get_db_office_id(p_office_id);
   l_office_code := cwms_util.get_db_office_code(l_office_id);
   --------------------------------------------------------
   -- get all locations with USGS Station Number aliases --
   --------------------------------------------------------
   select cwms_loc.get_location_id(location_code)
     bulk collect
     into l_locations
     from at_loc_group_assignment
    where office_code = l_office_code
      and loc_group_code = (select loc_group_code
                              from at_loc_group where loc_group_id = 'USGS Station Number'
                               and loc_category_code = (select loc_category_code
                                                          from at_loc_category
                                                         where loc_category_id = 'Agency Aliases'
                                                       )
                           )
    order by 1;
    -------------------------------------------
    -- get any BASE ratings that don't exist --
    -------------------------------------------
    for i in 1..l_locations.count loop
       l_ratings := cwms_rating.retrieve_ratings_obj_f(l_locations(i)||'.Stage;Flow.'||get_base_rating_templ_version(l_office_id)||'.'||get_base_rating_spec_version(l_office_id)||'', null, null, null, l_office_id);
       if l_ratings.count = 0 then
         l_locations_str := l_locations_str||','||l_locations(i);
         if length(l_locations_str) > 32000 then
            retrieve_and_store_ratings('BASE', substr(l_locations_str, 2), l_office_id);
            l_locations_str := null;
         end if;
       end if;
    end loop;
    if l_locations_str is not null then
      retrieve_and_store_ratings('BASE', substr(l_locations_str, 2), l_office_id);
      l_locations_str := null;
    end if;
    -------------------------------------------
    -- get any CORR ratings that don't exist --
    -------------------------------------------
    for i in 1..l_locations.count loop
       l_ratings := cwms_rating.retrieve_ratings_obj_f(l_locations(i)||'.Stage;Stage-Correction.'||get_corr_rating_templ_version(l_office_id)||'.'||get_corr_rating_spec_version(l_office_id)||'', null, null, null, l_office_id);
       if l_ratings.count = 0 then
         l_locations_str := l_locations_str||','||l_locations(i);
         if length(l_locations_str) > 32000 then
            retrieve_and_store_ratings('CORR', substr(l_locations_str, 2), l_office_id);
            l_locations_str := null;
         end if;
       end if;
    end loop;
    if l_locations_str is not null then
      retrieve_and_store_ratings('CORR', substr(l_locations_str, 2), l_office_id);
    end if;
    ---------------------------------------------------------------------
    -- generate production ratings for any that we may have downloaded --
    ---------------------------------------------------------------------
    generate_production_ratings2(l_office_id);
end retrieve_available_ratings2;

procedure retrieve_available_ratings(
   p_location_id in varchar2,
   p_office_id   in varchar2 default null)
is
begin
   retrieve_and_store_ratings('BASE', p_location_id, p_office_id);
   retrieve_and_store_ratings('CORR', p_location_id, p_office_id);
   generate_production_ratings(p_location_id, p_office_id);
end retrieve_available_ratings;


procedure set_auto_new_rating_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property(
      'USGS',
      cwms_usgs.auto_new_rating_interval_prop,
      to_char(p_interval),
      'interval in minutes for running automatic retrieval of new ratings',
      l_office_id);
end set_auto_new_rating_interval;

function get_auto_new_rating_interval(
   p_office_id in varchar2 default null)
   return integer
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return to_number(cwms_properties.get_property('USGS', cwms_usgs.auto_new_rating_interval_prop, null, l_office_id));
end get_auto_new_rating_interval;

procedure set_auto_upd_rating_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null)
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   cwms_properties.set_property(
      'USGS',
      cwms_usgs.auto_upd_rating_interval_prop,
      to_char(p_interval),
      'interval in minutes for running automatic retrieval of updated ratings',
      l_office_id);
end set_auto_upd_rating_interval;

function get_auto_upd_rating_interval(
   p_office_id in varchar2 default null)
   return integer
is
   l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);
begin
   return to_number(cwms_properties.get_property('USGS', cwms_usgs.auto_upd_rating_interval_prop, null, l_office_id));
end get_auto_upd_rating_interval;

procedure start_auto_new_rating_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);
   l_run_interval    integer;

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_NEW_RATE_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot start job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   l_run_interval := get_auto_new_rating_interval(l_office_id);
   if l_run_interval is null then
      cwms_err.raise(
         'ERROR',
         'No run interval defined for job in property '||auto_new_rating_interval_prop);
   elsif l_run_interval < 720 then
      cwms_err.raise(
         'ERROR',
         'Run interval of '
         ||l_run_interval
         ||' defined for job in property '
         ||auto_new_rating_interval_prop
         ||' is less than 12 hours');
   end if;
   -------------------------------------------
   -- drop the job if it is already running --
   -------------------------------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (l_job_id);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

   if job_count = 0
   then
      begin
         ---------------------
         -- restart the job --
         ---------------------
         dbms_scheduler.create_job(
            job_name             => l_job_id,
            job_type             => 'stored_procedure',
            job_action           => 'cwms_usgs.retrieve_available_ratings2',
            number_of_arguments  => 1,
            start_date           => null,
            repeat_interval      => 'freq=minutely; interval=' || l_run_interval,
            end_date             => null,
            job_class            => 'default_job_class',
            enabled              => false,
            auto_drop            => false,
            comments             => 'Retrieves new ratings from USGS');

         dbms_scheduler.set_job_argument_value(
            job_name          => l_job_id,
            argument_position => 1,
            argument_value    => l_office_id);

         dbms_scheduler.enable(l_job_id);
         if job_count = 1 then
            dbms_output.put_line(
               'Job '
               ||l_job_id
               ||' successfully scheduled to execute every '
               ||l_run_interval
               ||' minutes.');
         else
            cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
         end if;
      exception
         when others then
            cwms_err.raise (
               'ITEM_NOT_CREATED',
               'job',l_job_id || ':' || sqlerrm);
      end;
   end if;
end start_auto_new_rating_job;

procedure stop_auto_new_rating_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_NEW_RATE_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot stop job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   ------------------
   -- drop the job --
   ------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (job_name=>l_job_id, force=>true);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

end stop_auto_new_rating_job;

procedure start_auto_update_rating_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);
   l_run_interval    integer;

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_UPD_RATE_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot start job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   l_run_interval := get_auto_upd_rating_interval(l_office_id);
   if l_run_interval is null then
      cwms_err.raise(
         'ERROR',
         'No run interval defined for job in property '||get_auto_upd_rating_interval);
   elsif l_run_interval < 60 then
      cwms_err.raise(
         'ERROR',
         'Run interval of '
         ||l_run_interval
         ||' defined for job in property '
         ||auto_upd_rating_interval_prop
         ||' is less than 1 hour');
   end if;
   -------------------------------------------
   -- drop the job if it is already running --
   -------------------------------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (l_job_id);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

   if job_count = 0
   then
      begin
         ---------------------
         -- restart the job --
         ---------------------
         dbms_scheduler.create_job(
            job_name             => l_job_id,
            job_type             => 'stored_procedure',
            job_action           => 'cwms_usgs.update_existing_ratings',
            number_of_arguments  => 1,
            start_date           => null,
            repeat_interval      => 'freq=minutely; interval=' || l_run_interval,
            end_date             => null,
            job_class            => 'default_job_class',
            enabled              => false,
            auto_drop            => false,
            comments             => 'Retrieves updated ratings from USGS');

         dbms_scheduler.set_job_argument_value(
            job_name          => l_job_id,
            argument_position => 1,
            argument_value    => l_office_id);

         dbms_scheduler.enable(l_job_id);
         if job_count = 1 then
            dbms_output.put_line(
               'Job '
               ||l_job_id
               ||' successfully scheduled to execute every '
               ||l_run_interval
               ||' minutes.');
         else
            cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
         end if;
      exception
         when others then
            cwms_err.raise (
               'ITEM_NOT_CREATED',
               'job',l_job_id || ':' || sqlerrm);
      end;
   end if;
end start_auto_update_rating_job;

procedure stop_auto_update_rating_job(
   p_office_id in varchar2 default null)
is
   l_count           binary_integer;
   l_office_id       varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_user_office_id  varchar2(16) := cwms_util.user_office_id;
   l_job_id          varchar2(30);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id;

      return l_count;
   end;
begin
   l_job_id := 'USGS_AUTO_UPD_RATE_'||l_office_id;
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   if l_user_office_id != l_office_id and cwms_util.get_user_id != '&cwms_schema' then
      cwms_err.raise(
         'ERROR',
         'Cannot stop job '||l_job_id||' when default office is '||l_user_office_id);
   end if;

   ------------------
   -- drop the job --
   ------------------
   if job_count > 0 then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (job_name=>l_job_id, force=>true);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0 then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

end stop_auto_update_rating_job;

end cwms_usgs;
/
show errors


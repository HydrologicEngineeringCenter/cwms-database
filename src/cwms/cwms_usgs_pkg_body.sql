set define on
create or replace package body cwms_usgs
as

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
   return to_number(cwms_properties.get_property('USGS', cwms_usgs.auto_ts_period_prop, '0', l_office_id));
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
         select location_id
           bulk collect 
           into l_locations 
           from (select bl.base_location_id
                        ||substr('-', 1, length(pl.sub_location_id))
                        ||pl.sub_location_id as location_id
                   from at_physical_location pl,
                        at_base_location bl
                  where bl.base_location_code = pl.base_location_code
                    and bl.db_office_code = l_office_code
                    and pl.location_code > 0
                ) -- locations
                union
                (select loc_alias_id
                        ||substr('-', 1, length(pl.sub_location_id))
                        ||pl.sub_location_id as location_id
                   from at_loc_group_assignment lga,
                        at_physical_location pl
                  where lga.office_code = l_office_code
                        and lga.location_code in (pl.base_location_code, pl.location_code)
                        and loc_alias_id is not null
                ) -- partially-aliased locations
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
   return get_auto_ts_locations(null, p_office_id);
end get_auto_ts_locations;      

function get_auto_ts_locations(
   p_parameter in integer,
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
   l_text_filter_id := get_auto_ts_filter_id(l_office_id);
   if l_text_filter_id is not null then
      if p_parameter is not null then
         l_text_filter_id := l_text_filter_id||'.'||trim(to_char(p_parameter, '00009'));
         l_filter_must_exist := 'F';
      end if;
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
end get_auto_ts_locations;      

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
    where office_code in (cwms_util.get_db_office_code(p_office_id), cwms_util.db_office_code_all)
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
   l_count          integer;
begin
   l_all_parameters := get_parameters(p_office_id => p_office_id);
   for i in 1..l_all_parameters.count loop
      select count(*)
        into l_count
        from table(get_auto_ts_locations(l_all_parameters(i), p_office_id))
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

function get_ts_id(
   p_location_id    in varchar2,
   p_usgs_parameter in integer,
   p_interval       in integer,
   p_version        in varchar2 default 'USGS',
   p_office_id      in varchar2 default null)
   return varchar2 
is
   l_ts_id       varchar2(183);
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
         'cwms_usgs.get_ts_data', 
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
         'cwms_usgs.get_ts_data', 
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
            'cwms_usgs.get_ts_data', 
            cwms_msg.msg_level_detailed, 
            l_office_id||': USGS URL: '||l_url); 
         if i = 1 then
            l_data := cwms_util.get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               'cwms_usgs.get_ts_data', 
               cwms_msg.msg_level_detailed, 
               l_office_id||': bytes retrieved: '||dbms_lob.getlength(l_data)); 
         else
            l_data2 := cwms_util.get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               'cwms_usgs.get_ts_data', 
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
   return cwms_util.get_url(l_url);   
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
   p_rdb_data    in  varchar2,
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
   l_line_num   pls_integer;
   l_col_count  pls_integer;
   l_col_info   col_t;
   l_date_time  timestamp with time zone;
   l_value      number;
   l_interval   integer;
   l_interval2  integer;
begin
   ---------------------------------------------------
   -- store the data for inspection if error occurs --
   ---------------------------------------------------
   store_text(p_rdb_data, make_text_id(p_location_id), p_office_id);
   -----------------------------------------------
   -- skip the header and parse the column info --
   -----------------------------------------------
   l_all_params := get_parameters(p_location_id, p_office_id);
   l_lines := cwms_util.split_text(p_rdb_data, chr(10));
   <<header_loop>>
   for i in 1..l_lines.count loop
      if substr(l_lines(i), 1, 1) != '#' then
         l_line_num := i;
         l_cols := cwms_util.split_text(l_lines(i), chr(9));
         l_col_count := l_cols.count;
         for j in 1..l_col_count loop
            case l_cols(j)
               when 'agency_cd' then l_col_info('agency') := j;
               when 'site_no'   then l_col_info('site')   := j;
               when 'datetime'  then l_col_info('time')   := j;
               when 'tz_cd'     then l_col_info('tz')     := j;
               else
                  l_value := to_number(regexp_substr(l_cols(j), '^\d{2}_(\d{5})$', 1, 1, null, 1));
                  if l_value is not null and l_value member of l_all_params then
                     l_col_info(to_char(l_value)) := j;
                     l_params.extend;
                     l_params(l_params.count) := l_value;
                  end if;
            end case;
         end loop;
         exit header_loop;
      end if;
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
      for i in l_line_num+2..l_lines.count loop
         continue data_loop when trim(l_lines(i)) is null;
         exit data_loop when substr(l_lines(i), 1, 1) = '#'; -- beginning of next data retrieval response
         l_cols := cwms_util.split_text(l_lines(i), chr(9));
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
   delete_text(make_text_id(p_location_id), p_office_id);
   p_ts_ids  := l_ts_ids;
   p_units   := l_units;  
   p_ts_data := l_ts_data;
end process_ts_rdb;
   
procedure process_ts_rdb_and_store(      
   p_rdb_data  in clob,
   p_office_id in varchar2 default null)
is
   l_office_id   varchar2(16);
   l_datasets    str_tab_t;
   l_parts       str_tab_t;
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
   l_datasets := cwms_util.split_text(p_rdb_data, '# Data provided for site ');
   if l_datasets is null then
      cwms_msg.log_db_message(
         'cwms_usgs.process_ts_rdb_and_store', 
         cwms_msg.msg_level_detailed, 
         l_office_id||': No data retrieved');
   else 
      cwms_msg.log_db_message(
         'cwms_usgs.process_ts_rdb_and_store', 
         cwms_msg.msg_level_detailed, 
         l_office_id||': RDB data contains '||(l_datasets.count-1)||' sites');
      <<dataset_loop>>
      for i in 1..l_datasets.count loop
         if i > 1 then
            ------------------------------------------------------
            -- split the site number off the top of the dataset --
            ------------------------------------------------------
            l_parts := cwms_util.split_text(l_datasets(i), chr(10), 1);
            ----------------------------------------------
            -- parse the time series out of the dataset --
            ----------------------------------------------
            begin
               process_ts_rdb(l_ts_ids, l_units, l_ts_data, trim(l_parts(1)), trim(l_parts(2)), p_office_id);
            exception
               when others then
                  cwms_msg.log_db_message(
                     'cwms_usgs.process_ts_rdb_and_store', 
                     cwms_msg.msg_level_basic, 
                     l_office_id||': '||sqlerrm);
                  cwms_msg.log_db_message(
                     'cwms_usgs.process_ts_rdb_and_store', 
                     cwms_msg.msg_level_basic, 
                     l_office_id||': '||dbms_utility.format_error_backtrace);
                  cwms_msg.log_db_message(
                     'cwms_usgs.process_ts_rdb_and_store', 
                     cwms_msg.msg_level_basic, 
                     l_office_id||': RDB data is at '||make_text_id(l_parts(1)));
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
      end loop;
      cwms_msg.log_db_message(
         'cwms_usgs.process_ts_rdb_and_store', 
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
      'cwms_usgs.retrieve_and_store_ts', 
      cwms_msg.msg_level_normal, 
      'CWMS_USGS.RETRIEVE_AND_STORE_TS starting for '||l_office_id); 
   process_ts_rdb_and_store(
      get_ts_data_rdb(p_period, p_sites, p_parameters, p_office_id=>l_office_id), 
      l_office_id);   
   cwms_msg.log_db_message(
      'cwms_usgs.retrieve_and_store_ts', 
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
      'cwms_usgs.retrieve_and_store_ts', 
      cwms_msg.msg_level_normal, 
      'CWMS_USGS.RETRIEVE_AND_STORE_TS starting for '||l_office_id); 
   process_ts_rdb_and_store(
      get_ts_data_rdb(p_start_time, p_end_time, p_sites, p_parameters, p_office_id), 
      p_office_id);   
   cwms_msg.log_db_message(
      'cwms_usgs.retrieve_and_store_ts', 
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
   l_period := nvl(p_period, 'P200Y');
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
begin
   l_start_time := nvl(p_start_time, '1800-01-01');
   l_end_time   := nvl(p_end_time, to_char(sysdate, 'yyyy-mm-dd')); 
 
   
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   if p_sites is null then
      l_sites_tab := get_auto_stream_meas_locations(l_office_id);
   else
      select trim(column_value)
        bulk collect
        into l_sites_tab
        from table(cwms_util.split_text(p_sites, ','));
   end if;
   if l_sites_tab is null or l_sites_tab.count = 0 then
      cwms_msg.log_db_message(
         'cwms_usgs.retrieve_and_store_stream_meas', 
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
            'cwms_usgs.retrieve_and_store_stream_meas', 
            cwms_msg.msg_level_detailed, 
            l_office_id||': USGS URL: '||l_url); 
         if i = 1 then
            l_data := cwms_util.get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               'cwms_usgs.retrieve_and_store_stream_meas', 
               cwms_msg.msg_level_detailed, 
               l_office_id||': bytes retrieved: '||dbms_lob.getlength(l_data)); 
         else
            l_data2 := cwms_util.get_url(l_url, 60 + l_sites_tab.count * 15);
            cwms_msg.log_db_message(
               'cwms_usgs.retrieve_and_store_stream_meas', 
               cwms_msg.msg_level_detailed, 
               l_office_id||': bytes retrieved: '||dbms_lob.getlength(l_data2)); 
            dbms_lob.append(l_data, l_data2);
         end if;
      end loop;
      cwms_msg.log_db_message(
         'cwms_usgs.retrieve_and_store_stream_meas', 
         cwms_msg.msg_level_detailed, 
         'Processing measurements');
      l_lines := cwms_util.split_text(l_data, chr(10));
      l_count := 0;
      for i in 1..l_lines.count loop
         if length(l_lines(i)) < 20 
            or substr(l_lines(i), 1, 1) = '#' 
            or substr(l_lines(i), 1, 9) = 'agency_cd'
            or substr(l_lines(i), 1, 2) = '5s'
         then
            continue;
         end if;
         l_meas := streamflow_meas_t(l_lines(i), l_office_id);
         if l_meas is null or l_meas.location is null then 
            continue;
         end if;
         declare
            l_xml xmltype;
         begin
            dbms_output.put_line(l_meas.to_string);
         end;
         l_meas.store('F'); 
         l_count := l_count + 1;  
      end loop; 
      cwms_msg.log_db_message(
         'cwms_usgs.retrieve_and_store_stream_meas', 
         cwms_msg.msg_level_detailed, 
         l_count||' measurements stored');
   end if;   
   
end retrieve_and_store_stream_meas;    


end cwms_usgs;
/
show errors


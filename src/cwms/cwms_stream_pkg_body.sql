create or replace package body cwms_stream
as
   
--------------------------------------------------------------------------------
-- procedure get_stream_code
--------------------------------------------------------------------------------
function get_stream_code(
   p_office_id in varchar2,
   p_stream_id in varchar2)
   return number
is
   l_location_code number(10);
begin
   begin
      l_location_code := cwms_loc.get_location_code(p_office_id, p_stream_id);
      select stream_location_code
        into l_location_code
        from at_stream
       where stream_location_code = l_location_code;
   exception
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS stream identifier.',
            p_office_id
            ||'/'
            ||p_stream_id);
   end;
   return l_location_code;
end get_stream_code;

--------------------------------------------------------------------------------
-- procedure store_stream
--------------------------------------------------------------------------------
procedure store_stream(
   p_stream_id            in varchar2,
   p_fail_if_exists       in varchar2,
   p_ignore_nulls         in varchar2,
   p_station_units        in varchar2 default null,
   p_stationing_starts_ds in varchar2 default null,
   p_flows_into_stream    in varchar2 default null,
   p_flows_into_station   in binary_double default null,
   p_flows_into_bank      in varchar2 default null,
   p_diverts_from_stream  in varchar2 default null,
   p_diverts_from_station in binary_double default null,
   p_diverts_from_bank    in varchar2 default null,
   p_length               in binary_double default null,
   p_average_slope        in binary_double default null,
   p_comments             in varchar2 default null,
   p_office_id            in varchar2 default null)
is
   l_fail_if_exists        boolean := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls          boolean := cwms_util.is_true(p_ignore_nulls);
   l_exists                boolean;
   l_base_location_code    number(10);
   l_location_code         number(10);
   l_diverting_stream_code number(10);
   l_receiving_stream_code number(10);
   l_office_id             varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id); 
   l_station_units         varchar2(16) := cwms_util.get_unit_id(p_station_units, l_office_id);
   l_rec                   at_stream%rowtype;
   l_location_kind_id      varchar2(32);
begin
   if p_stream_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_STREAM_ID');
   end if;
   begin
      l_location_code := cwms_loc.get_location_code(l_office_id, p_stream_id);
   exception
      when others then null;
   end;                  
   -------------------
   -- sanity checks --
   -------------------
   if l_location_code is null then
      l_exists := false;
   else
      l_location_kind_id := cwms_loc.check_location_kind(l_location_code);
      if l_location_kind_id not in ('STREAM', 'UNSPECIFIED', 'NONE') then
         cwms_err.raise(
            'ERROR',
            'Cannot switch location '
            ||l_office_id
            ||'/'
            ||p_stream_id
            ||' from type '
            ||l_location_kind_id
            ||' to type STREAM');
      end if;
      begin
         select *
           into l_rec
           from at_stream
          where stream_location_code = l_location_code;
         l_exists := true;          
      exception
         when no_data_found then
            l_exists := false;
      end;
   end if;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'CWMS stream identifier',
         l_office_id
         ||'/'
         ||p_stream_id);
   end if; 
   if p_station_units is null then
      if p_flows_into_station is not null or
         p_diverts_from_station is not null or
         p_length is not null
      then
         cwms_err.raise(
            'ERROR',
            'Station and/or length values supplied without units.');
      end if;
   end if;
   if not l_exists or not l_ignore_nulls then
      if p_flows_into_stream is null then
         if p_flows_into_station is not null or
            p_flows_into_bank is not null
         then
            cwms_err.raise(
               'ERROR',
               'Confluence station and/or bank supplied without stream name.');
         end if;
      end if;
      if p_diverts_from_stream is null then
         if p_diverts_from_station is not null or
            p_diverts_from_bank is not null
         then
            cwms_err.raise(
               'ERROR',
               'Diversion station and/or bank supplied without stream name.');
         end if;
      end if;
   end if;
   if p_flows_into_bank is not null and upper(p_flows_into_bank) not in ('L','R') then
      cwms_err.raise(
         'INVALID_ITEM',
         p_flows_into_bank,
         'stream bank, must be ''L'' or ''R''');
   end if;
   if p_flows_into_bank is not null and upper(p_flows_into_bank) not in ('L','R') then
      cwms_err.raise(
         'INVALID_ITEM',
         p_flows_into_bank,
         'stream bank, must be ''L'' or ''R''');
   end if;
   --------------------------------------
   -- create the location if necessary --
   --------------------------------------
   if l_location_code is null then
      cwms_loc.create_location_raw2(
         p_base_location_code => l_base_location_code,
         p_location_code      => l_location_code,
         p_base_location_id   => cwms_util.get_base_id(p_stream_id),
         p_sub_location_id    => cwms_util.get_sub_id(p_stream_id),
         p_db_office_code     => cwms_util.get_db_office_code(l_office_id),
         p_location_kind_id   => 'STREAM');
   end if;
   ---------------------------------
   -- set the record to be stored --
   ---------------------------------
   if not p_flows_into_stream is null then
      l_receiving_stream_code := get_stream_code(l_office_id, p_flows_into_stream);
   end if;
   if not p_diverts_from_stream is null then
      l_diverting_stream_code := get_stream_code(l_office_id, p_diverts_from_stream);
   end if;
   if not l_exists then
      l_rec.stream_location_code := l_location_code;
   end if;
   if p_stationing_starts_ds is null then
      if not l_ignore_nulls then
         l_rec.zero_station := null;
      end if;
   else
      l_rec.zero_station := case cwms_util.is_true(p_stationing_starts_ds)
                               when true  then 'DS'
                               when false then 'US'
                            end;
   end if;
   if l_diverting_stream_code is not null or l_ignore_nulls then
      l_rec.diverting_stream_code := l_diverting_stream_code;
   end if;
   if p_diverts_from_station is not null or l_ignore_nulls then
      l_rec.diversion_station := cwms_util.convert_units(p_diverts_from_station, l_station_units, 'km');
   end if;
   if p_diverts_from_bank is not null or l_ignore_nulls then
      l_rec.diversion_bank := upper(p_diverts_from_bank);
   end if;
   if l_receiving_stream_code is not null or l_ignore_nulls then
      l_rec.receiving_stream_code := l_receiving_stream_code;
   end if;
   if p_flows_into_station is not null or l_ignore_nulls then
      l_rec.confluence_station := cwms_util.convert_units(p_flows_into_station, l_station_units, 'km');
   end if;
   if p_flows_into_bank is not null or l_ignore_nulls then
      l_rec.confluence_bank := upper(p_flows_into_bank);
   end if;
   if p_length is not null or l_ignore_nulls then
      l_rec.stream_length := cwms_util.convert_units(p_length, l_station_units, 'km');
   end if;
   if p_average_slope is not null or l_ignore_nulls then
      l_rec.average_slope := p_average_slope;
   end if;
   if p_comments is not null or l_ignore_nulls then
      l_rec.comments := p_comments;
   end if;
   if l_exists then
      update at_stream
         set row = l_rec
       where stream_location_code = l_rec.stream_location_code;
   else
      insert
        into at_stream
      values l_rec;
   end if;
   ---------------------------      
   -- set the location kind --
   ---------------------------
   update at_physical_location
      set location_kind = (select location_kind_code 
                             from cwms_location_kind 
                            where location_kind_id = 'STREAM'
                          )
    where location_code = l_location_code;                                 
   
end store_stream;   

--------------------------------------------------------------------------------
-- procedure retrieve_stream
--------------------------------------------------------------------------------
procedure retrieve_stream(
   p_stationing_starts_ds out varchar2,
   p_flows_into_stream    out varchar2,
   p_flows_into_station   out binary_double,
   p_flows_into_bank      out varchar2,
   p_diverts_from_stream  out varchar2,
   p_diverts_from_station out binary_double,
   p_diverts_from_bank    out varchar2,
   p_length               out binary_double,
   p_average_slope        out binary_double,
   p_comments             out varchar2 ,
   p_stream_id            in  varchar2,
   p_station_units        in  varchar2,
   p_office_id            in  varchar2 default null)
is
   l_office_id     varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_rec           at_stream%rowtype;
   l_station_units varchar2(16) := cwms_util.get_unit_id(p_station_units, l_office_id);
begin
   ------------------
   -- sanity check --
   ------------------
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   ------------------------------------------ 
   -- get the record and return the values --
   ------------------------------------------ 
   l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id);
   select *
     into l_rec
     from at_stream
    where stream_location_code = l_rec.stream_location_code;
    
   if l_rec.zero_station = 'DS' then
      p_stationing_starts_ds := 'T';
   else
      p_stationing_starts_ds := 'F';
   end if;
   if l_rec.receiving_stream_code is not null then
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
        into p_flows_into_stream
        from at_base_location bl,
             at_physical_location pl
       where pl.location_code = l_rec.receiving_stream_code
         and bl.base_location_code = pl.base_location_code;
      p_flows_into_station := cwms_util.convert_units(l_rec.confluence_station, 'km', l_station_units);
      p_flows_into_bank := l_rec.confluence_bank;         
   end if;    
   if l_rec.diverting_stream_code is not null then
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
        into p_diverts_from_stream
        from at_base_location bl,
             at_physical_location pl
       where pl.location_code = l_rec.diverting_stream_code
         and bl.base_location_code = pl.base_location_code;
      p_diverts_from_station := cwms_util.convert_units(l_rec.diversion_station, 'km', l_station_units);
      p_diverts_from_bank := l_rec.diversion_bank;         
   end if;    
   p_length := cwms_util.convert_units(l_rec.stream_length, 'km', l_station_units);
   p_average_slope := l_rec.average_slope;
   p_comments := l_rec.comments;
end retrieve_stream;   
--------------------------------------------------------------------------------
-- procedure delete_stream
--------------------------------------------------------------------------------
procedure delete_stream(
   p_stream_id      in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
begin
   delete_stream2(
      p_stream_id      => p_stream_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_office_id);
end delete_stream;
--------------------------------------------------------------------------------
-- procedure delete_stream2
--------------------------------------------------------------------------------
procedure delete_stream2(
   p_stream_id              in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null)
is
   l_stream_code     number(10);
   l_delete_location boolean;
   l_delete_action1  varchar2(16);
   l_delete_action2  varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_stream_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_stream_ID');
   end if;
   l_delete_action1 := upper(substr(p_delete_action, 1, 16));
   if l_delete_action1 not in (
      cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
   then
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
   end if;
   l_delete_location := cwms_util.return_true_or_false(p_delete_location); 
   l_delete_action2 := upper(substr(p_delete_location_action, 1, 16));
   if l_delete_action2 not in (
      cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
   then
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
   end if;
   l_stream_code := get_stream_code(p_office_id, p_stream_id);
   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
   if l_delete_action1 in (cwms_util.delete_data, cwms_util.delete_all) then
      begin
         delete
           from at_stream_location
          where stream_location_code = l_stream_code;
      exception
         when no_data_found then null;
      end;             
      begin
         delete
           from at_stream_reach
          where stream_location_code = l_stream_code;
      exception
         when no_data_found then null;
      end;             
   end if;
   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
   if l_delete_action1 in (cwms_util.delete_key, cwms_util.delete_all) then
      delete
        from at_stream
       where stream_location_code = l_stream_code;
   end if; 
   -------------------------------------
   -- delete the location if required --
   -------------------------------------
   if l_delete_location then
      cwms_loc.delete_location(p_stream_id, l_delete_action2, p_office_id);
   else
      update at_physical_location set location_kind=1 where location_code = l_stream_code;   
   end if;
end delete_stream2;   

--------------------------------------------------------------------------------
-- procedure rename_stream
--------------------------------------------------------------------------------
procedure rename_stream(
   p_old_stream_id in varchar2,
   p_new_stream_id in varchar2,
   p_office_id     in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_old_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_new_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if; 
   cwms_loc.rename_location(p_old_stream_id, p_new_stream_id, p_office_id);
end rename_stream;   

--------------------------------------------------------------------------------
-- procedure cat_streams
--------------------------------------------------------------------------------
procedure cat_streams(          
   p_stream_catalog              out sys_refcursor,
   p_stream_id_mask              in  varchar2 default '*',
   p_station_units               in  varchar2 default 'km',
   p_stationing_starts_ds_mask   in  varchar2 default '*',
   p_flows_into_stream_id_mask   in  varchar2 default '*',
   p_flows_into_station_min      in  binary_double default null,
   p_flows_into_station_max      in  binary_double default null,
   p_flows_into_bank_mask        in  varchar2 default '*',
   p_diverts_from_stream_id_mask in  varchar2 default '*',
   p_diverts_from_station_min    in  binary_double default null,
   p_diverts_from_station_max    in  binary_double default null,
   p_diverts_from_bank_mask      in  varchar2 default '*',
   p_length_min                  in  binary_double default null,
   p_length_max                  in  binary_double default null,
   p_average_slope_min           in  binary_double default null,
   p_average_slope_max           in  binary_double default null,
   p_comments_mask               in  varchar2 default '*',
   p_office_id_mask              in  varchar2 default null)
is
   l_stream_id_mask              varchar2(49)  := upper(cwms_util.normalize_wildcards(p_stream_id_mask));
   l_stationing_starts_ds_mask   varchar2(1)   := upper(cwms_util.normalize_wildcards(p_stationing_starts_ds_mask));
   l_flows_into_stream_id_mask   varchar2(49)  := upper(cwms_util.normalize_wildcards(p_flows_into_stream_id_mask));
   l_flows_into_bank_mask        varchar2(1)   := upper(cwms_util.normalize_wildcards(p_flows_into_bank_mask));
   l_diverts_from_stream_id_mask varchar2(49)  := upper(cwms_util.normalize_wildcards(p_diverts_from_stream_id_mask));
   l_diverts_from_bank_mask      varchar2(1)   := upper(cwms_util.normalize_wildcards(p_diverts_from_bank_mask));
   l_comments_mask               varchar2(256) := upper(cwms_util.normalize_wildcards(p_comments_mask));
   l_office_id_mask              varchar2(16)  := upper(cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id)));
   l_flows_into_station_min      binary_double := -binary_double_max_normal;
   l_flows_into_station_max      binary_double :=  binary_double_max_normal;
   l_diverts_from_station_min    binary_double := -binary_double_max_normal;
   l_diverts_from_station_max    binary_double :=  binary_double_max_normal;
   l_length_min                  binary_double := -binary_double_max_normal;
   l_length_max                  binary_double :=  binary_double_max_normal;
   l_average_slope_min           binary_double := -binary_double_max_normal;
   l_average_slope_max           binary_double :=  binary_double_max_normal;
begin
   open p_stream_catalog for
      select stream.office_id,
             stream.stream_id,
             stream.stationing_starts_ds,
             confluence.stream_id as flows_into_stream,
             stream.flows_into_station,
             stream.flows_into_bank, 
             diversion.stream_id as diverts_from_stream,
             stream.diverts_from_station,
             stream.diverts_from_bank,
             stream.stream_length,
             stream.average_slope,
             stream.comments 
        from ( select o.office_id,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as stream_id,
                      case 
                        when zero_station = 'DS' then 'T'
                        when zero_station = 'US' then 'F'
                      end as stationing_starts_ds,
                      receiving_stream_code,
                      cwms_util.convert_units(confluence_station, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) as flows_into_station,
                      confluence_bank as flows_into_bank,
                      diverting_stream_code,
                      cwms_util.convert_units(diversion_station, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) as diverts_from_station,
                      diversion_bank as diverts_from_bank,
                      cwms_util.convert_units(stream_length, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) as stream_length,
                      average_slope,
                      comments
                 from at_physical_location pl,
                      at_base_location bl,
                      at_stream s,
                      cwms_office o
                where o.office_id like l_office_id_mask escape '\'
                  and upper(bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_stream_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and s.stream_location_code = pl.location_code
                  and (not cwms_util.convert_units(confluence_station, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) < l_flows_into_station_min) 
                  and (not cwms_util.convert_units(confluence_station, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) > l_flows_into_station_max)
                  and confluence_bank like l_flows_into_bank_mask 
                  and (not cwms_util.convert_units(diversion_station, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) < l_diverts_from_station_min) 
                  and (not cwms_util.convert_units(diversion_station, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) > l_diverts_from_station_max)
                  and diversion_bank like l_diverts_from_bank_mask 
                  and (not cwms_util.convert_units(stream_length, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) < l_length_min) 
                  and (not cwms_util.convert_units(stream_length, 'km', cwms_util.get_unit_id(p_station_units, o.office_id)) > l_length_max) 
                  and (not average_slope < l_average_slope_min) 
                  and (not average_slope > l_average_slope_max)
                  and upper(comments) like l_comments_mask escape '\'
            ) stream
            left outer join
            (  select bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as stream_id,
                      s.stream_location_code          
                 from at_physical_location pl,
                      at_base_location bl,
                      at_stream s
                where upper(bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_flows_into_stream_id_mask escape '\'
                  and pl.base_location_code = bl.base_location_code
                  and s.stream_location_code = pl.location_code
            ) confluence on stream.receiving_stream_code = confluence.stream_location_code
            left outer join
            (  select bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as stream_id,
                      s.stream_location_code          
                 from at_physical_location pl,
                      at_base_location bl,
                      at_stream s
                where upper(bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_diverts_from_stream_id_mask escape '\'
                  and pl.base_location_code = bl.base_location_code
                  and s.stream_location_code = pl.location_code
            ) diversion on stream.diverting_stream_code = diversion.stream_location_code;
end cat_streams;   

--------------------------------------------------------------------------------
-- function cat_streams_f
--------------------------------------------------------------------------------
function cat_streams_f(          
   p_stream_id_mask              in varchar2 default '*',
   p_station_units               in varchar2 default 'km',
   p_stationing_starts_ds_mask   in varchar2 default '*',
   p_flows_into_stream_id_mask   in varchar2 default '*',
   p_flows_into_station_min      in binary_double default null,
   p_flows_into_station_max      in binary_double default null,
   p_flows_into_bank_mask        in varchar2 default '*',
   p_diverts_from_stream_id_mask in varchar2 default '*',
   p_diverts_from_station_min    in binary_double default null,
   p_diverts_from_station_max    in binary_double default null,
   p_diverts_from_bank_mask      in varchar2 default '*',
   p_length_min                  in binary_double default null,
   p_length_max                  in binary_double default null,
   p_average_slope_min           in binary_double default null,
   p_average_slope_max           in binary_double default null,
   p_comments_mask               in varchar2 default '*',
   p_office_id_mask              in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_streams(
      l_cursor,
      p_stream_id_mask,
      p_station_units,
      p_stationing_starts_ds_mask,
      p_flows_into_stream_id_mask,
      p_flows_into_station_min,
      p_flows_into_station_max,
      p_flows_into_bank_mask,
      p_diverts_from_stream_id_mask,
      p_diverts_from_station_min,
      p_diverts_from_station_max,
      p_diverts_from_bank_mask,
      p_length_min,
      p_length_max,
      p_average_slope_min,
      p_average_slope_max,
      p_comments_mask,
      p_office_id_mask);
      
   return l_cursor;      
end cat_streams_f;   
--------------------------------------------------------------------------------
-- procedure store_stream_reach
--------------------------------------------------------------------------------
procedure store_stream_reach(
   p_stream_id          in varchar2,
   p_reach_id           in varchar2,
   p_fail_if_exists     in varchar2,
   p_ignore_nulls       in varchar2,
   p_upstream_station   in binary_double,
   p_downstream_station in binary_double,
   p_stream_type_id     in varchar2 default null,
   p_comments           in varchar2 default null,
   p_office_id          in varchar2 default null)
is
   l_fail_if_exists boolean := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls   boolean := cwms_util.is_true(p_ignore_nulls);
   l_exists         boolean;
   l_office_id      varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_stream_type_id varchar2(4);
   l_rec            at_stream_reach%rowtype; 
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_reach_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
   end if;
   if p_stream_type_id is not null then
      begin
         select stream_type_id
           into l_stream_type_id
           from cwms_stream_type
          where upper(stream_type_id) = upper(p_stream_type_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               p_stream_type_id,
               'CWMS stream type identifier');
      end;          
   end if;
   l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id);
   ------------------------------------------------------------
   -- determine if the reach exists (retrieve it if it does) --
   ------------------------------------------------------------
   begin
      select *
        into l_rec
        from at_stream_reach
       where stream_location_code = l_rec.stream_location_code
         and upper(stream_reach_id) = upper(p_reach_id);
      l_exists := true;       
   exception           
      when no_data_found then
         l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'CWMS stream reach identifier',
         l_office_id
         ||'/'
         ||p_stream_id
         ||'/'
         ||p_reach_id);
   end if;
   --------------------------
   -- set the reach values --
   --------------------------
   if not l_exists then
      l_rec.stream_reach_id := p_reach_id;
   end if;
   if p_upstream_station is not null or not l_ignore_nulls then
      l_rec.upstream_station := p_upstream_station;
   end if;
   if p_downstream_station is not null or not l_ignore_nulls then
      l_rec.downstream_station := p_downstream_station;
   end if;
   if l_stream_type_id is not null or not l_ignore_nulls then
      l_rec.stream_type_id := l_stream_type_id;
   end if;
   if p_comments is not null or not l_ignore_nulls then
      l_rec.comments := p_comments;
   end if;
   --------------------------------
   -- insert or update the reach --
   --------------------------------
   if l_exists then
      update at_stream_reach
         set row = l_rec
       where stream_location_code = l_rec.stream_location_code; 
   else
      insert
        into at_stream_reach
      values l_rec;
   end if;
end store_stream_reach;   
   
--------------------------------------------------------------------------------
-- procedure retrieve_stream_reach
--------------------------------------------------------------------------------
procedure retrieve_stream_reach(
   p_upstream_station   out binary_double,
   p_downstream_station out binary_double,
   p_stream_type_id     out varchar2,
   p_comments           out varchar2,
   p_stream_id          in  varchar2,
   p_reach_id           in  varchar2,
   p_office_id          in  varchar2 default null)
is
   l_stream_location_code number(10);
   l_office_id            varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_rec                  at_stream_reach%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_reach_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
   end if;
   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);
   begin
      select *
        into l_rec
        from at_stream_reach
       where stream_location_code = l_stream_location_code
         and upper(stream_reach_id) = upper(p_reach_id);
         
      p_upstream_station   := l_rec.upstream_station;
      p_downstream_station := l_rec.downstream_station;
      p_stream_type_id     := l_rec.stream_type_id;
      p_comments           := l_rec.comments;         
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS stream reach identifier',
            l_office_id
            ||'/'
            ||p_stream_id
            ||'/'
            ||p_reach_id);
   end;
end retrieve_stream_reach;   
   
--------------------------------------------------------------------------------
-- procedure delete_stream_reach
--------------------------------------------------------------------------------
procedure delete_stream_reach(
   p_stream_id in varchar2,
   p_reach_id  in varchar2,
   p_office_id in varchar2 default null)
is
   l_stream_location_code number(10);
   l_office_id            varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_reach_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
   end if;
   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);
   begin
      delete
        from at_stream_reach
       where stream_location_code = l_stream_location_code
         and upper(stream_reach_id) = upper(p_reach_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS stream reach identifier',
            l_office_id
            ||'/'
            ||p_stream_id
            ||'/'
            ||p_reach_id);
   end;
end delete_stream_reach;   
   
--------------------------------------------------------------------------------
-- procedure rename_stream_reach
--------------------------------------------------------------------------------
procedure rename_stream_reach(
   p_stream_id    in varchar2,
   p_old_reach_id in varchar2,
   p_new_reach_id in varchar2,
   p_office_id    in varchar2 default null)
is
   l_stream_location_code number(10);
   l_office_id            varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_old_reach_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
   end if;
   if p_new_reach_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
   end if;
   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);
   begin
      update at_stream_reach
         set stream_reach_id = p_new_reach_id
       where stream_location_code = l_stream_location_code
         and upper(stream_reach_id) = upper(p_old_reach_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS stream reach identifier',
            l_office_id
            ||'/'
            ||p_stream_id
            ||'/'
            ||p_old_reach_id);
   end;
end rename_stream_reach;   

--------------------------------------------------------------------------------
-- procedure cat_stream_reaches
--------------------------------------------------------------------------------
procedure cat_stream_reaches(
   p_reach_catalog       out sys_refcursor,
   p_stream_id_mask      in  varchar2 default '*',
   p_reach_id_mask       in  varchar2 default '*',
   p_stream_type_id_mask in  varchar2 default '*',
   p_comments_mask       in  varchar2 default '*',
   p_office_id_mask      in  varchar2 default null)
is
   l_stream_id_mask      varchar2(49)  := cwms_util.normalize_wildcards(p_stream_id_mask);
   l_reach_id_mask       varchar2(64)  := cwms_util.normalize_wildcards(p_reach_id_mask);
   l_stream_type_id_mask varchar2(4)   := cwms_util.normalize_wildcards(p_stream_type_id_mask);
   l_comments_mask       varchar2(256) := cwms_util.normalize_wildcards(p_comments_mask); 
   l_office_id_mask      varchar2(16)  := cwms_util.normalize_wildcards(
                                             nvl(upper(p_office_id_mask), cwms_util.user_office_id)); 
begin
   open p_reach_catalog for 
      select o.office_id,
             bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id as stream_id,
             sr.stream_reach_id,
             sr.upstream_station,
             sr.downstream_station,
             sr.stream_type_id,
             sr.comments
        from at_physical_location pl,
             at_base_location bl,
             at_stream_reach sr,
             cwms_office o
       where o.office_id like l_office_id_mask escape '\'
         and bl.db_office_code = o.office_code 
         and upper(bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id) like upper(l_stream_id_mask) escape '\'
         and sr.stream_location_code = pl.location_code
         and upper(sr.stream_reach_id) like upper(l_reach_id_mask) escape '\'
         and upper(sr.stream_type_id) like upper(l_stream_type_id_mask) escape '\'
         and upper(sr.comments) like upper(l_comments_mask) escape '\'
    order by o.office_id,
             upper(bl.base_location_id),
             upper(pl.sub_location_id),
             upper(sr.stream_reach_id);
end cat_stream_reaches;

--------------------------------------------------------------------------------
-- function cat_stream_reaches_f
--------------------------------------------------------------------------------
function cat_stream_reaches_f(
   p_stream_id_mask      in varchar2 default '*',
   p_reach_id_mask       in varchar2 default '*',
   p_stream_type_id_mask in varchar2 default '*',
   p_comments_mask       in varchar2 default '*',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_stream_reaches(
     l_cursor,
     p_stream_id_mask,
     p_reach_id_mask,
     p_stream_type_id_mask,
     p_comments_mask,
     p_office_id_mask);
     
   return l_cursor;     
end cat_stream_reaches_f;   
   
--------------------------------------------------------------------------------
-- procedure store_stream_location   
--------------------------------------------------------------------------------
procedure store_stream_location(
   p_location_id             in varchar2,
   p_stream_id               in varchar2,
   p_fail_if_exists          in varchar2,
   p_ignore_nulls            in varchar2,
   p_station                 in binary_double,
   p_station_unit            in varchar2,
   p_published_station       in binary_double default null,
   p_navigation_station      in binary_double default null,
   p_bank                    in varchar2 default null,
   p_lowest_measurable_stage in binary_double default null,
   p_stage_unit              in varchar2 default null,
   p_drainage_area           in binary_double default null,
   p_ungaged_drainage_area   in binary_double default null,
   p_area_unit               in varchar2 default null,
   p_office_id               in varchar2 default null)
is
   l_office_id      varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_station_unit   varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id);
   l_stage_unit     varchar2(16) := cwms_util.get_unit_id(p_stage_unit, l_office_id);
   l_area_unit      varchar2(16) := cwms_util.get_unit_id(p_area_unit, l_office_id);
   l_fail_if_exists boolean := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls   boolean := cwms_util.is_true(p_ignore_nulls);
   l_exists         boolean;
   l_rec            at_stream_location%rowtype;  
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
   end if;
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_station is not null and p_station_unit is null then
      cwms_err.raise(
         'ERROR',
         'Station unit must be specified with station.');
   end if;
   if p_lowest_measurable_stage is not null and p_stage_unit is null then
      cwms_err.raise(
         'ERROR',
         'Stage unit must be specified with lowest measureable stage.');
   end if;
   if (p_drainage_area is not null or p_ungaged_drainage_area is not null)  and p_area_unit is null then
      cwms_err.raise(
         'ERROR',
         'Area unit must be specified with drainage areas.');
   end if;
   if p_bank is not null and upper(p_bank) not in ('L','R') then
      cwms_err.raise(
         'INVALID_ITEM',
         p_bank,
         'stream bank, must be ''L'' or ''R''.');
   end if;
   ------------------------------------------
   -- get the existing record if it exists --
   ------------------------------------------
   l_rec.location_code        := cwms_loc.get_location_code(l_office_id, p_location_id);
   begin
      select *
        into l_rec
        from at_stream_location
       where location_code = l_rec.location_code;
         
      l_exists := true;
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ERROR',
         'Location '
         ||l_office_id
         ||'/'
         ||p_location_id
         ||' already exists as a stream location on stream '
         ||l_office_id
         ||'/'
         ||p_stream_id);
   end if;
   --------------------------- 
   -- set the record values --
   ---------------------------
   l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id);
   if p_station is not null or not l_ignore_nulls then
      l_rec.station := cwms_util.convert_units(p_station, l_station_unit, 'km');
   end if;
   if p_published_station is not null or not l_ignore_nulls then
      l_rec.published_station := cwms_util.convert_units(p_published_station, l_station_unit, 'km');
   end if;
   if p_navigation_station is not null or not l_ignore_nulls then
      l_rec.navigation_station := cwms_util.convert_units(p_navigation_station, l_station_unit, 'km');
   end if;
   if p_bank is not null or not l_ignore_nulls then
      l_rec.bank := upper(p_bank);
   end if;
   if p_lowest_measurable_stage is not null or not l_ignore_nulls then
      l_rec.lowest_measurable_stage := cwms_util.convert_units(p_lowest_measurable_stage, l_stage_unit, 'm');
   end if;
   if p_drainage_area is not null or not l_ignore_nulls then
      l_rec.drainage_area := cwms_util.convert_units(p_drainage_area, l_area_unit, 'm2');
   end if; 
   if p_ungaged_drainage_area is not null or not l_ignore_nulls then
      l_rec.ungaged_area := cwms_util.convert_units(p_ungaged_drainage_area, l_area_unit, 'm2');
   end if;
   --------------------------------- 
   -- update or insert the record --
   ---------------------------------
   if l_exists then
      update at_stream_location
         set row = l_rec
       where location_code = l_rec.location_code
         and stream_location_code = l_rec.stream_location_code;
   else
      insert
        into at_stream_location
      values l_rec;
   end if; 
end store_stream_location;   
   
--------------------------------------------------------------------------------
-- procedure retrieve_stream_location   
--------------------------------------------------------------------------------
procedure retrieve_stream_location(
   p_station                 out binary_double,
   p_published_station       out binary_double,
   p_navigation_station      out binary_double,
   p_bank                    out varchar2,
   p_lowest_measurable_stage out binary_double,
   p_drainage_area           out binary_double,
   p_ungaged_drainage_area   out binary_double,
   p_location_id             in  varchar2,
   p_stream_id               in  varchar2,
   p_station_unit            in  varchar2,
   p_stage_unit              in  varchar2,
   p_area_unit               in  varchar2,
   p_office_id               in  varchar2 default null)
is
   l_office_id            varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_station_unit         varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id);
   l_stage_unit           varchar2(16) := cwms_util.get_unit_id(p_stage_unit, l_office_id);
   l_area_unit            varchar2(16) := cwms_util.get_unit_id(p_area_unit, l_office_id);
   l_location_code        number(10);
   l_stream_location_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
   end if;
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_station_unit is null then
      cwms_err.raise(
         'ERROR',
         'Station unit must be specified.');
   end if;
   if p_stage_unit is null then
      cwms_err.raise(
         'ERROR',
         'Stage unit must be specified.');
   end if;
   if p_area_unit is null then
      cwms_err.raise(
         'ERROR',
         'Area unit must be specified.');
   end if;
   -----------------------
   -- retrieve the data --
   -----------------------
   l_location_code        := cwms_loc.get_location_code(l_office_id, p_location_id);
   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);
   begin
      select cwms_util.convert_units(station, 'km', l_station_unit),
             cwms_util.convert_units(published_station, 'km', l_station_unit),
             cwms_util.convert_units(navigation_station, 'km', l_station_unit),
             bank,
             cwms_util.convert_units(lowest_measurable_stage, 'm', l_stage_unit),
             cwms_util.convert_units(drainage_area, 'm2', l_area_unit),
             cwms_util.convert_units(ungaged_area, 'm2', l_area_unit)
        into p_station,
             p_published_station,
             p_navigation_station,
             p_bank,
             p_lowest_measurable_stage,
             p_drainage_area,
             p_ungaged_drainage_area
        from at_stream_location
       where location_code = l_location_code
         and stream_location_code = l_stream_location_code;              
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Location '
            ||l_office_id
            ||'/'
            ||p_location_id
            ||' does not exist as a stream location on stream '
            ||l_office_id
            ||'/'
            ||p_stream_id);
   end;
end retrieve_stream_location;   
   
--------------------------------------------------------------------------------
-- procedure delete_stream_location   
--------------------------------------------------------------------------------
procedure delete_stream_location(
   p_location_id in  varchar2,
   p_stream_id   in  varchar2,
   p_office_id   in  varchar2 default null)
is
   l_office_id            varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_location_code        number(10);
   l_stream_location_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
   end if;
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   -----------------------
   -- delete the record --
   -----------------------
   l_location_code        := cwms_loc.get_location_code(l_office_id, p_location_id);
   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);
   begin
      delete
        from at_stream_location
       where location_code = l_location_code
         and stream_location_code = l_stream_location_code;              
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Location '
            ||l_office_id
            ||'/'
            ||p_location_id
            ||' does not exist as a stream location on stream '
            ||l_office_id
            ||'/'
            ||p_stream_id);
   end;
end delete_stream_location;   
   
--------------------------------------------------------------------------------
-- procedure cat_stream_locations   
--------------------------------------------------------------------------------
procedure cat_stream_locations(
   p_stream_location_catalog out sys_refcursor,
   p_stream_id_mask          in  varchar2 default '*',
   p_location_id_mask        in  varchar2 default '*',
   p_station_unit            in  varchar2 default null,
   p_stage_unit              in  varchar2 default null,
   p_area_unit               in  varchar2 default null,
   p_office_id_mask          in  varchar2 default null)
is
   l_stream_id_mask   varchar2(49) := cwms_util.normalize_wildcards(upper(p_stream_id_mask)); 
   l_location_id_mask varchar2(49) := cwms_util.normalize_wildcards(upper(p_location_id_mask)); 
   l_office_id_mask   varchar2(16) := cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.user_office_id)));
   l_station_unit     varchar2(16) := nvl(p_station_unit, 'km');
   l_stage_unit       varchar2(16) := nvl(p_station_unit, 'm');
   l_area_unit        varchar2(16) := nvl(p_station_unit, 'm2');
begin
    open p_stream_location_catalog for
      select o.office_id,
             bl1.base_location_id
             ||substr('-', 1, length(pl1.sub_location_id))
             ||pl1.sub_location_id as stream_id,
             bl2.base_location_id
             ||substr('-', 1, length(pl2.sub_location_id))
             ||pl2.sub_location_id as location_id,
             cwms_util.convert_units(sl.station, 'km', cwms_util.get_unit_id(l_station_unit, o.office_id)) as station,
             cwms_util.convert_units(sl.published_station, 'km', cwms_util.get_unit_id(l_station_unit, o.office_id)) as pulished_station,
             cwms_util.convert_units(sl.navigation_station, 'km', cwms_util.get_unit_id(l_station_unit, o.office_id)) as navigation_station,
             sl.bank,
             cwms_util.convert_units(sl.lowest_measurable_stage, 'm', cwms_util.get_unit_id(l_stage_unit, o.office_id)) as lowest_measurable_stage,
             cwms_util.convert_units(sl.drainage_area, 'm2', cwms_util.get_unit_id(l_area_unit, o.office_id)) as drainage_area,
             cwms_util.convert_units(sl.ungaged_area, 'm2', cwms_util.get_unit_id(l_area_unit, o.office_id)) as ungaged_area,
             cwms_util.get_unit_id(l_station_unit, o.office_id) as station_unit,
             cwms_util.get_unit_id(l_stage_unit, o.office_id) as stage_unit,
             cwms_util.get_unit_id(l_area_unit, o.office_id) as area_unit
        from at_physical_location pl1,
             at_physical_location pl2,
             at_base_location bl1,
             at_base_location bl2,
             at_stream_location sl,
             cwms_office o
       where o.office_id like l_office_id_mask escape '\'
         and bl1.db_office_code = o.office_code              
         and upper(bl1.base_location_id
             ||substr('-', 1, length(pl1.sub_location_id))
             ||pl1.sub_location_id) like l_stream_id_mask escape '\'
         and bl2.db_office_code = o.office_code              
         and upper(bl2.base_location_id
             ||substr('-', 1, length(pl2.sub_location_id))
             ||pl2.sub_location_id) like l_location_id_mask escape '\'
    order by bl1.base_location_id,
             pl1.sub_location_id,
             sl.station,           -- if station is not null
             bl2.base_location_id, -- if station is null
             pl2.sub_location_id;  -- if station is null           
end cat_stream_locations;   
   
--------------------------------------------------------------------------------
-- function cat_stream_locations_f   
--------------------------------------------------------------------------------
function cat_stream_locations_f(
   p_stream_id_mask   in  varchar2 default '*',
   p_location_id_mask in  varchar2 default '*',
   p_station_unit     in  varchar2 default null,
   p_stage_unit       in  varchar2 default null,
   p_area_unit        in  varchar2 default null,
   p_office_id_mask   in  varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_stream_locations(
      l_cursor,
      p_location_id_mask,
      p_stream_id_mask,
      p_station_unit,
      p_stage_unit,
      p_area_unit,
      p_office_id_mask);

   return l_cursor;
end cat_stream_locations_f;               

--------------------------------------------------------------------------------
-- function get_next_location_code_f
--
-- return  the next-upstream or next-downstream stream location on this stream  
--------------------------------------------------------------------------------
function get_next_location_code_f(
   p_stream_code  in number,
   p_direction    in varchar2, 
   p_station      in binary_double default null) -- in km
   return number   
is
   l_direction        varchar2(2);
   l_zero_station     varchar2(2);
   l_us_location_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_direction is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   l_direction := upper(substr(p_direction, 1, 2));
   if p_direction not in ('US', 'DS') then
      cwms_err.raise(
         'ERROR',
         'Direction must be specified as ''US'' or ''DS''');
   end if;
   
   select zero_station
    into l_zero_station
    from at_stream
   where stream_location_code = p_stream_code;
   
   begin
      if l_zero_station = l_direction then
         select location_code
           into l_us_location_code
           from at_stream_location
          where station = 
                ( select min(station)
                   from at_stream_location
                   where station < nvl(p_station, binary_double_max_normal)
                );
      else
         select location_code
           into l_us_location_code
           from at_stream_location
          where station = 
                ( select min(station)
                   from at_stream_location
                   where station > nvl(p_station, -binary_double_max_normal)
                );
      end if;
   exception
      when no_data_found then null;
   end;      
   
   return l_us_location_code;    
end get_next_location_code_f;   

--------------------------------------------------------------------------------
-- function get_us_location_code_f
--
-- return  the next-upstream stream location on this stream  
--------------------------------------------------------------------------------
function get_us_location_code_f(
   p_stream_code  in number,
   p_station      in binary_double default null) -- in km
   return number
is
begin
   return get_next_location_code_f(p_stream_code, 'US', p_station);
end get_us_location_code_f;      

--------------------------------------------------------------------------------
-- function get_ds_location_code_f
--
-- return  the next-downstream stream location on this stream  
--------------------------------------------------------------------------------
function get_ds_location_code_f(
   p_stream_code  in number,
   p_station      in binary_double default null) -- in km
   return number
is
begin
   return get_next_location_code_f(p_stream_code, 'DS', p_station);
end get_ds_location_code_f;      

--------------------------------------------------------------------------------
-- function get_junctions_between_f
--
-- get streams flowing into or out of this stream between 2 stations
--------------------------------------------------------------------------------
function get_junctions_between_f(
   p_stream_code   in number,
   p_junction_type in varchar2,
   p_station_1     in binary_double, -- in km
   p_station_2     in binary_double) -- in im
   return number_tab_t
is
   l_junction_type varchar2(1);
   l_stream_codes  number_tab_t;
   l_station_1     binary_double;
   l_station_2     binary_double;
   l_stream_code   number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_station_1 is null or p_station_2 is null then
      cwms_err.raise(
         'ERROR',
         'Stream stations must not be null.');
   end if;
   if upper(p_junction_type) not in ('C'/*onfluence*/,'B'/*ifurcation*/) then
      cwms_err.raise(
         'ERROR',
         'Junction type must be ''C''(confluence) or ''B''(bifurcation).');
   end if;
   l_junction_type := upper(p_junction_type);
   l_station_1  := least(p_station_1, p_station_2);
   l_station_2  := greatest(p_station_1, p_station_2);                           
   if l_junction_type = 'C' then
      select stream_location_code
             bulk collect into l_stream_codes
        from at_stream
       where receiving_stream_code = p_stream_code
         and confluence_station between l_station_1 and l_station_2;
   else
      select stream_location_code
             bulk collect into l_stream_codes
        from at_stream
       where diverting_stream_code = p_stream_code
         and confluence_station between l_station_1 and l_station_2;
   end if;      
      
   return l_stream_codes;            
end get_junctions_between_f;

--------------------------------------------------------------------------------
-- function get_confluences_between_f
--
-- get streams flowing into this stream between 2 stations
--------------------------------------------------------------------------------
function get_confluences_between_f(
   p_stream_code  in number,
   p_station_1    in binary_double, -- in km
   p_station_2    in binary_double) -- in km
   return number_tab_t
is
begin
   return get_junctions_between_f(
      p_stream_code,
      'C', -- confluence
      p_station_1,
      p_station_2);
end get_confluences_between_f;

--------------------------------------------------------------------------------
-- function get_bifurcations_between_f
--
-- get streams flowing into this stream between 2 stations
--------------------------------------------------------------------------------
function get_bifurcations_between_f(
   p_stream_code  in number,
   p_station_1    in binary_double, -- in km
   p_station_2    in binary_double) -- in km
   return number_tab_t
is
begin
   return get_junctions_between_f(
      p_stream_code,
      'B', -- bifurcation
      p_station_1,
      p_station_2);
end get_bifurcations_between_f;

--------------------------------------------------------------------------------
-- procedure get_us_location_codes
--
-- get location codes of upstream stations
--------------------------------------------------------------------------------
procedure get_us_location_codes(
   p_location_codes   in out nocopy number_tab_t,
   p_stream_code      in number,
   p_station          in binary_double, -- in km
   p_all_us_locations in boolean default false)
is
   l_location_code  number(10);
   l_stream_codes   number_tab_t;
   l_zero_station   varchar2(2);
   l_station        binary_double;
begin
   --------------------------------------------------
   -- deterine if our stationing begins downstream --
   --------------------------------------------------
   select zero_station
     into l_zero_station
     from at_stream
    where stream_location_code = p_stream_code;
   --------------------------------------------------- 
   -- get the next upstream location on this stream --
   --------------------------------------------------- 
   l_location_code := get_us_location_code_f(p_stream_code, p_station);
   if l_location_code is not null then
      ----------------------------------
      -- add the location to our list --
      ----------------------------------
      p_location_codes.extend;
      p_location_codes(p_location_codes.count) := l_location_code;
      ------------------------------------- 
      -- get the station of the location --
      ------------------------------------- 
      select station 
        into l_station
        from at_stream_location
       where location_code = l_location_code
        and stream_location_code = p_stream_code;
      -----------------------------------------------------        
      -- get all further upstream locations if specified --
      -----------------------------------------------------        
      if p_all_us_locations then
         get_us_location_codes(
            p_location_codes,
            p_stream_code,
            l_station,
            true);
      end if;        
   else
      ---------------------------------------------------------------------------
      -- no next upstream location, set the station beyond the upstream extent --
      ---------------------------------------------------------------------------
      if l_zero_station = 'DS' then
         l_station := binary_double_max_normal;
      else
         l_station := -binary_double_max_normal;
      end if;
   end if;
   -----------------------------------------------------------------------                
   -- find all tribs that flow into this one upstream of here but below --
   -- the next upstream location (if any)                               --
   -----------------------------------------------------------------------                
   l_stream_codes := get_confluences_between_f(p_stream_code, p_station, l_station);
   if l_stream_codes is not null then
      for i in 1..l_stream_codes.count loop
         ----------------------------------------------
         -- set the station to beyond the confluence --
         -- (taking station direction into account)  --
         ----------------------------------------------
         select zero_station
           into l_zero_station
           from at_stream
          where stream_location_code = l_stream_codes(i);
          
         if l_zero_station = 'DS' then
            l_station := -binary_double_max_normal;
         else
            l_station := binary_double_max_normal;
         end if;
         ------------------------------------------------
         -- get all the upstream stations on the tribs --
         ------------------------------------------------
         get_us_location_codes(
            p_location_codes,
            l_stream_codes(i),
            l_station,
            p_all_us_locations);         
      end loop;
   end if;
end get_us_location_codes;   

--------------------------------------------------------------------------------
-- procedure get_ds_location_codes
--
-- get location codes of downstream stations
--------------------------------------------------------------------------------
procedure get_ds_location_codes(
   p_location_codes   in out nocopy number_tab_t,
   p_stream_code      in number,
   p_station          in binary_double, -- in km
   p_all_ds_locations in boolean default false)
is
   l_location_code  number(10);
   l_stream_codes   number_tab_t;
   l_zero_station   varchar2(2);
   l_station        binary_double;
begin
   --------------------------------------------------
   -- deterine if our stationing begins downstream --
   --------------------------------------------------
   select zero_station
     into l_zero_station
     from at_stream
    where stream_location_code = p_stream_code;
   ----------------------------------------------------- 
   -- get the next downstream location on this stream --
   ----------------------------------------------------- 
   l_location_code := get_ds_location_code_f(p_stream_code, p_station);
   if l_location_code is not null then
      ----------------------------------
      -- add the location to our list --
      ----------------------------------
      p_location_codes.extend;
      p_location_codes(p_location_codes.count) := l_location_code;
      ------------------------------------- 
      -- get the station of the location --
      ------------------------------------- 
      select station 
        into l_station
        from at_stream_location
       where location_code = l_location_code
        and stream_location_code = p_stream_code;
      -------------------------------------------------------        
      -- get all further downstream locations if specified --
      -------------------------------------------------------        
      if p_all_ds_locations then
         get_ds_location_codes(
            p_location_codes,
            p_stream_code,
            l_station,
            true);
      end if;        
   else
      -------------------------------------------------------------------------------
      -- no next downstream location, set the station beyond the downstream extent --
      -------------------------------------------------------------------------------
      if l_zero_station = 'DS' then
         l_station := -binary_double_max_normal;
      else
         l_station := binary_double_max_normal;
      end if;
   end if;
   ------------------------------------------------------------------------------                
   -- find all diversions that flow out of this one upstream of here but below --
   -- the next upstream location (if any)                                      --
   ------------------------------------------------------------------------------                
   l_stream_codes := get_bifurcations_between_f(p_stream_code, p_station, l_station);
   if l_stream_codes is not null then
      for i in 1..l_stream_codes.count loop
         ---------------------------------------------------
         -- set the station to beyond the upstream extent --
         -- (taking station direction into account)       --
         ---------------------------------------------------
         select zero_station
           into l_zero_station
           from at_stream
          where stream_location_code = l_stream_codes(i);
          
         if l_zero_station = 'DS' then
            l_station := binary_double_max_normal;
         else
            l_station := -binary_double_max_normal;
         end if;
         -------------------------------------------------------
         -- get all the downstream stations on the diversions --
         -------------------------------------------------------
         get_ds_location_codes(
            p_location_codes,
            l_stream_codes(i),
            l_station,
            p_all_ds_locations);         
      end loop;
   end if;
end get_ds_location_codes;

--------------------------------------------------------------------------------
-- procedure get_us_locations 
--------------------------------------------------------------------------------
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is
   l_office_id      varchar2(16);
   l_stream_code    number(10);
   l_location_codes number_tab_t := number_tab_t();
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_station is null then
      cwms_err.raise(
         'ERROR',
         'Station must not be null.');
   end if;
   ----------------------------
   -- get the location codes --
   ----------------------------
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_stream_code := get_stream_code(l_office_id, p_stream_id);
   get_us_location_codes (
      l_location_codes,
      l_stream_code,
      cwms_util.convert_units(p_station, cwms_util.get_unit_id(p_station_unit), 'km'),
      cwms_util.is_true(p_all_us_locations));
   select bl.base_location_id
          ||substr('-', 1, length(pl.sub_location_id))
          ||pl.sub_location_id
          bulk collect
     into p_us_locations
     from at_stream s,
          at_physical_location pl,      
          at_base_location bl
    where s.stream_location_code in (select * from table(l_location_codes))
      and pl.location_code = s.stream_location_code
      and bl.base_location_code = pl.base_location_code; 
end get_us_locations;      

--------------------------------------------------------------------------------
-- funtion get_us_locations_f 
--------------------------------------------------------------------------------
function get_us_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_locations str_tab_t := str_tab_t();
begin
   get_us_locations(
      l_locations,
      p_stream_id,   
      p_station,
      p_station_unit,
      p_all_us_locations,
      p_office_id);
end get_us_locations_f;   

--------------------------------------------------------------------------------
-- procedure get_ds_locations 
--------------------------------------------------------------------------------
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is   
   l_office_id      varchar2(16);
   l_stream_code    number(10);
   l_location_codes number_tab_t := number_tab_t();
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   if p_station is null then
      cwms_err.raise(
         'ERROR',
         'Station must not be null.');
   end if;
   ----------------------------
   -- get the location codes --
   ----------------------------
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_stream_code := get_stream_code(l_office_id, p_stream_id);
   get_ds_location_codes (
      l_location_codes,
      l_stream_code,
      cwms_util.convert_units(p_station, cwms_util.get_unit_id(p_station_unit), 'km'),
      cwms_util.is_true(p_all_ds_locations));
   select bl.base_location_id
          ||substr('-', 1, length(pl.sub_location_id))
          ||pl.sub_location_id
          bulk collect
     into p_ds_locations
     from at_stream s,
          at_physical_location pl,      
          at_base_location bl
    where s.stream_location_code in (select * from table(l_location_codes))
      and pl.location_code = s.stream_location_code
      and bl.base_location_code = pl.base_location_code; 
end get_ds_locations;      

--------------------------------------------------------------------------------
-- funtion get_ds_locations_f 
--------------------------------------------------------------------------------
function get_ds_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_locations str_tab_t := str_tab_t();
begin
   get_ds_locations(
      l_locations,
      p_stream_id,   
      p_station,
      p_station_unit,
      p_all_ds_locations,
      p_office_id);
end get_ds_locations_f;

--------------------------------------------------------------------------------
-- procedure get_us_locations 
--------------------------------------------------------------------------------
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_location_id      in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is
   l_station       binary_double;
   l_stream_code   number(10);
   l_location_code number(10);
   l_office_id     varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
   end if;
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   -------------------------------
   -- get the codes and station --
   -------------------------------
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   l_stream_code := get_stream_code(l_office_id, p_stream_id);
   begin
      select station
        into l_station
        from at_stream_location
       where location_code = l_location_code
         and stream_location_code = l_stream_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Location '
            ||l_office_id
            ||'/'
            ||p_location_id
            ||' does not exist as a stream location on stream '
            ||l_office_id
            ||'/'
            ||p_stream_id);
   end; 
   -----------------------------  
   -- call the base procedure --
   -----------------------------
   get_us_locations(
      p_us_locations,
      p_stream_id,
      l_station,
      'km',
      p_all_us_locations,
      l_office_id);
end get_us_locations;   

--------------------------------------------------------------------------------
-- funtion get_us_locations_f 
--------------------------------------------------------------------------------
function get_us_locations_f(
   p_stream_id        in varchar2,
   p_location_id      in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_us_locations str_tab_t := str_tab_t();
begin
   get_us_locations(
      l_us_locations,
      p_stream_id,
      p_location_id,
      p_all_us_locations,
      p_office_id);
      
   return l_us_locations;      
end get_us_locations_f;   

--------------------------------------------------------------------------------
-- procedure get_ds_locations 
--------------------------------------------------------------------------------
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_location_id      in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is   
   l_station       binary_double;
   l_stream_code   number(10);
   l_location_code number(10);
   l_office_id     varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
   end if;
   if p_stream_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS stream identifier.');
   end if;
   -------------------------------
   -- get the codes and station --
   -------------------------------
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   l_stream_code := get_stream_code(l_office_id, p_stream_id);
   begin
      select station
        into l_station
        from at_stream_location
       where location_code = l_location_code
         and stream_location_code = l_stream_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Location '
            ||l_office_id
            ||'/'
            ||p_location_id
            ||' does not exist as a stream location on stream '
            ||l_office_id
            ||'/'
            ||p_stream_id);
   end; 
   -----------------------------  
   -- call the base procedure --
   -----------------------------
   get_ds_locations(
      p_ds_locations,
      p_stream_id,
      l_station,
      'km',
      p_all_ds_locations,
      l_office_id);
end get_ds_locations;
--------------------------------------------------------------------------------
-- funtion get_ds_locations_f 
--------------------------------------------------------------------------------
function get_ds_locations_f(
   p_stream_id        in varchar2,
   p_location_id      in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_ds_locations str_tab_t := str_tab_t();
begin
   get_ds_locations(
      l_ds_locations,
      p_stream_id,
      p_location_id,
      p_all_ds_locations,
      p_office_id);
      
   return l_ds_locations;      
end get_ds_locations_f;   
   

end cwms_stream;
/   
   
show errors;
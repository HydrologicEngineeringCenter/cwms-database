create or replace package body cwms_stream
as
   --------------------------------------------------------------------------------
   -- function get_stream_code
   --------------------------------------------------------------------------------
   function get_stream_code(
         p_office_id in varchar2,
         p_stream_id in varchar2)
      return number
   is
      l_location_code number(10) ;
   begin
      begin
         l_location_code := cwms_loc.get_location_code(p_office_id, p_stream_id) ;
          select stream_location_code
            into l_location_code
            from at_stream
           where stream_location_code = l_location_code;
      exception
      when others then
         cwms_err.raise( 'ITEM_DOES_NOT_EXIST', 'CWMS stream identifier.', p_office_id ||'/' ||p_stream_id) ;
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
         p_station_unit         in varchar2 default null,
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
      l_fail_if_exists        boolean := cwms_util.is_true(p_fail_if_exists) ;
      l_ignore_nulls          boolean := cwms_util.is_true(p_ignore_nulls) ;
      l_exists                boolean;
      l_base_location_code    number(10) ;
      l_location_code         number(10) ;
      l_diverting_stream_code number(10) ;
      l_receiving_stream_code number(10) ;
      l_office_id             varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_station_unit          varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id) ;
      l_rec at_stream%rowtype;
   begin
      l_location_code := cwms_loc.get_location_code(l_office_id, p_stream_id) ;
      -------------------
      -- sanity checks --
      -------------------
      if not cwms_loc.can_store(l_location_code, 'STREAM') then
         cwms_err.raise(
            'ERROR', 
            'Cannot store STREAM information to location '
            ||l_office_id||'/'||p_stream_id
            ||' (location kind = '
            ||cwms_loc.check_location_kind(l_location_code)
            ||')');
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
      if l_exists and l_fail_if_exists then
         cwms_err.raise('ITEM_ALREADY_EXISTS', 'CWMS stream identifier', l_office_id ||'/' ||p_stream_id) ;
      end if;
      if p_station_unit is null then
         if p_flows_into_station is not null or p_diverts_from_station is not null or p_length is not null then
            cwms_err.raise( 'ERROR', 'Station and/or length values supplied without unit.') ;
         end if;
      end if;
      if not l_exists or not l_ignore_nulls then
         if p_flows_into_stream is null then
            if p_flows_into_station is not null or p_flows_into_bank is not null then
               cwms_err.raise( 'ERROR', 'Confluence station and/or bank supplied without stream name.') ;
            end if;
         end if;
         if p_diverts_from_stream is null then
            if p_diverts_from_station is not null or p_diverts_from_bank is not null then
               cwms_err.raise( 'ERROR', 'Diversion station and/or bank supplied without stream name.') ;
            end if;
         end if;
      end if;
      if p_flows_into_bank is not null and upper(p_flows_into_bank) not in('L', 'R') then
         cwms_err.raise( 'INVALID_ITEM', p_flows_into_bank, 'stream bank, must be ''L'' or ''R''') ;
      end if;
      if p_flows_into_bank is not null and upper(p_flows_into_bank) not in('L', 'R') then
         cwms_err.raise( 'INVALID_ITEM', p_flows_into_bank, 'stream bank, must be ''L'' or ''R''') ;
      end if;
      ---------------------------------
      -- set the record to be stored --
      ---------------------------------
      if not p_flows_into_stream is null then
         l_receiving_stream_code := get_stream_code(l_office_id, p_flows_into_stream) ;
      end if;
      if not p_diverts_from_stream is null then
         l_diverting_stream_code := get_stream_code(l_office_id, p_diverts_from_stream) ;
      end if;
      if not l_exists then
         l_rec.stream_location_code := l_location_code;
      end if;
      if p_stationing_starts_ds is null then
         if not l_ignore_nulls then
            l_rec.zero_station := null;
         end if;
      else
         l_rec.zero_station :=
         case cwms_util.is_true(p_stationing_starts_ds)
         when true  then 'DS'
         when false then 'US'
         end;
      end if;
      if l_diverting_stream_code is not null or not l_ignore_nulls then
         l_rec.diverting_stream_code := l_diverting_stream_code;
      end if;
      if p_diverts_from_station is not null or not l_ignore_nulls then
         l_rec.diversion_station := cwms_util.convert_units(p_diverts_from_station, l_station_unit, 'km') ;
      end if;
      if p_diverts_from_bank is not null or not l_ignore_nulls then
         l_rec.diversion_bank := upper(p_diverts_from_bank) ;
      end if;
      if l_receiving_stream_code is not null or not l_ignore_nulls then
         l_rec.receiving_stream_code := l_receiving_stream_code;
      end if;
      if p_flows_into_station is not null or not l_ignore_nulls then
         l_rec.confluence_station := cwms_util.convert_units(p_flows_into_station, l_station_unit, 'km') ;
      end if;
      if p_flows_into_bank is not null or not l_ignore_nulls then
         l_rec.confluence_bank := upper(p_flows_into_bank) ;
      end if;
      if p_length is not null or not l_ignore_nulls then
         l_rec.stream_length := cwms_util.convert_units(p_length, l_station_unit, 'km') ;
      end if;
      if p_average_slope is not null or not l_ignore_nulls then
         l_rec.average_slope := p_average_slope;
      end if;
      if p_comments is not null or not l_ignore_nulls then
         l_rec.comments := p_comments;
      end if;
      if l_exists then
          update at_stream
             set row = l_rec
           where stream_location_code = l_rec.stream_location_code;
      else
          insert into at_stream values l_rec;
      end if;
      ---------------------------
      -- set the location kind --
      ---------------------------
      cwms_loc.update_location_kind(l_location_code, 'STREAM', 'A');
   end store_stream;
--------------------------------------------------------------------------------
-- procedure store_streams
--------------------------------------------------------------------------------
   procedure store_streams(
         p_streams        in out nocopy stream_tab_t,
         p_fail_if_exists in varchar2,
         p_ignore_nulls   in varchar2)
   is
   begin
      if p_streams is not null then
         for i in 1..p_streams.count
         loop
            p_streams(i) .store(p_fail_if_exists, p_ignore_nulls) ;
         end loop;
      end if;
   end store_streams;
--------------------------------------------------------------------------------
-- procedure retrieve_stream
--------------------------------------------------------------------------------
   procedure retrieve_stream(
         p_stationing_starts_ds out varchar2,
         p_flows_into_stream out varchar2,
         p_flows_into_station out binary_double,
         p_flows_into_bank out varchar2,
         p_diverts_from_stream out varchar2,
         p_diverts_from_station out binary_double,
         p_diverts_from_bank out varchar2,
         p_length out binary_double,
         p_average_slope out binary_double,
         p_comments out varchar2,
         p_stream_id    in varchar2,
         p_station_unit in varchar2,
         p_office_id    in varchar2 default null)
   is
      l_office_id varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_rec at_stream%rowtype;
      l_station_unit varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id) ;
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_stream_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream identifier.') ;
      end if;
      ------------------------------------------
      -- get the record and return the values --
      ------------------------------------------
      l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id) ;
       select *
         into l_rec
         from at_stream
        where stream_location_code = l_rec.stream_location_code;
      if l_rec.zero_station        = 'DS' then
         p_stationing_starts_ds   := 'T';
      else
         p_stationing_starts_ds := 'F';
      end if;
      if l_rec.receiving_stream_code is not null then
          select bl.base_location_id
            ||substr('-', 1, length(pl.sub_location_id))
            into p_flows_into_stream
            from at_base_location bl,
            at_physical_location pl
           where pl.location_code  = l_rec.receiving_stream_code
         and bl.base_location_code = pl.base_location_code;
         p_flows_into_station     := cwms_util.convert_units(l_rec.confluence_station, 'km', l_station_unit) ;
         p_flows_into_bank        := l_rec.confluence_bank;
      end if;
      if l_rec.diverting_stream_code is not null then
          select bl.base_location_id
            ||substr('-', 1, length(pl.sub_location_id))
            into p_diverts_from_stream
            from at_base_location bl,
            at_physical_location pl
           where pl.location_code  = l_rec.diverting_stream_code
         and bl.base_location_code = pl.base_location_code;
         p_diverts_from_station   := cwms_util.convert_units(l_rec.diversion_station, 'km', l_station_unit) ;
         p_diverts_from_bank      := l_rec.diversion_bank;
      end if;
      p_length        := cwms_util.convert_units(l_rec.stream_length, 'km', l_station_unit) ;
      p_average_slope := l_rec.average_slope;
      p_comments      := l_rec.comments;
   end retrieve_stream;
--------------------------------------------------------------------------------
-- function retrieve_stream_f
--------------------------------------------------------------------------------
   function retrieve_stream_f(
         p_stream_id    in varchar2,
         p_station_unit in varchar2,
         p_office_id    in varchar2 default null)
      return stream_t
   is
      l_stream stream_t;
   begin
      l_stream := stream_t(p_stream_id, p_office_id) ;
      l_stream.convert_to_unit(p_station_unit) ;
      return l_stream;
   end retrieve_stream_f;
--------------------------------------------------------------------------------
-- procedure delete_stream
--------------------------------------------------------------------------------
   procedure delete_stream(
         p_stream_id     in varchar2,
         p_delete_action in varchar2 default cwms_util.delete_key,
         p_office_id     in varchar2 default null)
   is
   begin
      delete_stream2( p_stream_id => p_stream_id, p_delete_action => p_delete_action, p_office_id => p_office_id) ;
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
      l_stream_code      number(10) ;
      l_delete_location  boolean;
      l_delete_action1   varchar2(16) ;
      l_delete_action2   varchar2(16) ;
      l_location_kind_id cwms_location_kind.location_kind_id%type;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_stream_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_stream_ID') ;
      end if;
      l_delete_action1 := upper(substr(p_delete_action, 1, 16)) ;
      if l_delete_action1 not in( cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
         cwms_err.raise( 'ERROR', 'Delete action must be one of ''' ||cwms_util.delete_key ||''',  ''' ||cwms_util.delete_data ||''', or ''' ||cwms_util.delete_all ||'') ;
      end if;
      l_delete_location := cwms_util.return_true_or_false(p_delete_location) ;
      if l_delete_location then
         l_delete_action2  := upper(substr(p_delete_location_action, 1, 16)) ;
         if l_delete_action2 not in( cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
            cwms_err.raise( 'ERROR', 'Delete action must be one of ''' ||cwms_util.delete_key ||''',  ''' ||cwms_util.delete_data ||''', or ''' ||cwms_util.delete_all ||'') ;
         end if;
      end if;
      l_stream_code := get_stream_code(p_office_id, p_stream_id) ;
      l_location_kind_id := cwms_loc.check_location_kind(l_stream_code);
      if l_location_kind_id != 'STREAM' then
         cwms_err.raise(
            'ERROR',
            'Cannot delete stream information for location '
            ||cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||p_stream_id
            ||' (location kind = '
            ||l_location_kind_id
            ||' )');
      l_location_kind_id := cwms_loc.can_revert_loc_kind_to(p_stream_id, p_office_id); -- revert-to kind            
      end if;
      -------------------------------------------
      -- delete the child records if specified --
      -------------------------------------------
      if l_delete_action1 in(cwms_util.delete_data, cwms_util.delete_all) then
         begin
             delete from at_stream_location where stream_location_code = l_stream_code;
         exception
         when no_data_found then
            null;
         end;
         begin
             delete from at_stream_reach where stream_location_code = l_stream_code;
         exception
         when no_data_found then
            null;
         end;
      end if;
      ------------------------------------
      -- delete the record if specified --
      ------------------------------------
      if l_delete_action1 in(cwms_util.delete_key, cwms_util.delete_all) then
          delete from at_stream where stream_location_code = l_stream_code;
          cwms_loc.update_location_kind(l_stream_code, 'STREAM', 'D');
      end if;
      -------------------------------------
      -- delete the location if required --
      -------------------------------------
      if l_delete_location then
         cwms_loc.delete_location(p_stream_id, l_delete_action2, p_office_id) ;
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
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream identifier.') ;
      end if;
      if p_new_stream_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream identifier.') ;
      end if;
      cwms_loc.rename_location(p_old_stream_id, p_new_stream_id, p_office_id) ;
   end rename_stream;
--------------------------------------------------------------------------------
-- procedure cat_streams
--------------------------------------------------------------------------------
   procedure cat_streams(
         p_stream_catalog out sys_refcursor,
         p_stream_id_mask              in varchar2 default '*',
         p_station_unit                in varchar2 default 'km',
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
   is
      l_stream_id_mask              varchar2(57)  := upper(cwms_util.normalize_wildcards(p_stream_id_mask)) ;
      l_stationing_starts_ds_mask   varchar2(1)   := upper(cwms_util.normalize_wildcards(p_stationing_starts_ds_mask)) ;
      l_flows_into_stream_id_mask   varchar2(57)  := upper(cwms_util.normalize_wildcards(p_flows_into_stream_id_mask)) ;
      l_flows_into_bank_mask        varchar2(1)   := upper(cwms_util.normalize_wildcards(p_flows_into_bank_mask)) ;
      l_diverts_from_stream_id_mask varchar2(57)  := upper(cwms_util.normalize_wildcards(p_diverts_from_stream_id_mask)) ;
      l_diverts_from_bank_mask      varchar2(1)   := upper(cwms_util.normalize_wildcards(p_diverts_from_bank_mask)) ;
      l_comments_mask               varchar2(256) := upper(cwms_util.normalize_wildcards(p_comments_mask)) ;
      l_office_id_mask              varchar2(16)  := upper(cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id))) ;
      l_flows_into_station_min binary_double      := nvl(cwms_util.convert_units(p_flows_into_station_min, p_station_unit, 'km'), - binary_double_max_normal) ;
      l_flows_into_station_max binary_double      := nvl(cwms_util.convert_units(p_flows_into_station_max, p_station_unit, 'km'), binary_double_max_normal) ;
      l_diverts_from_station_min binary_double    := nvl(cwms_util.convert_units(p_diverts_from_station_min, p_station_unit, 'km'), - binary_double_max_normal) ;
      l_diverts_from_station_max binary_double    := nvl(cwms_util.convert_units(p_diverts_from_station_max, p_station_unit, 'km'), binary_double_max_normal) ;
      l_length_min binary_double                  := nvl(cwms_util.convert_units(p_length_min, p_station_unit, 'km'), - binary_double_max_normal) ;
      l_length_max binary_double                  := nvl(cwms_util.convert_units(p_length_max, p_station_unit, 'km'), binary_double_max_normal) ;
      l_average_slope_min binary_double           := nvl(p_average_slope_min, - binary_double_max_normal) ;
      l_average_slope_max binary_double           := nvl(p_average_slope_max, binary_double_max_normal) ;
   begin
      open p_stream_catalog for select stream.office_id,
      stream.stream_id,
      stream.stationing_starts_ds,
      confluence.stream_id
   as
      flows_into_stream,
      stream.flows_into_station,
      stream.flows_into_bank,
      diversion.stream_id
   as
      diverts_from_stream,
      stream.diverts_from_station,
      stream.diverts_from_bank,
      stream.stream_length,
      stream.average_slope,
      stream.comments from
      (
          select o.office_id,
            bl.base_location_id
            ||substr('-', 1, length(pl.sub_location_id))
            ||pl.sub_location_id as stream_id,
            case
               when zero_station = 'DS'
               then 'T'
               when zero_station = 'US'
               then 'F'
            end as stationing_starts_ds,
            receiving_stream_code,
            cwms_util.convert_units(confluence_station, 'km', cwms_util.get_unit_id(p_station_unit, o.office_id)) as flows_into_station,
            confluence_bank                                                                                       as flows_into_bank,
            diverting_stream_code,
            cwms_util.convert_units(diversion_station, 'km', cwms_util.get_unit_id(p_station_unit, o.office_id)) as diverts_from_station,
            diversion_bank                                                                                       as diverts_from_bank,
            cwms_util.convert_units(stream_length, 'km', cwms_util.get_unit_id(p_station_unit, o.office_id))     as stream_length,
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
         and bl.db_office_code      = o.office_code
         and pl.base_location_code  = bl.base_location_code
         and s.stream_location_code = pl.location_code
         and nvl(confluence_station, l_flows_into_station_min) between l_flows_into_station_min and l_flows_into_station_max
         and nvl(confluence_bank, '%') like l_flows_into_bank_mask
         and nvl(diversion_station, l_diverts_from_station_min) between l_diverts_from_station_min and l_diverts_from_station_max
         and nvl(diversion_bank, '%') like l_diverts_from_bank_mask
         and nvl(stream_length, l_length_min) between l_length_min and l_length_max
         and nvl(average_slope, l_average_slope_min) between l_average_slope_min and l_average_slope_max
         and upper(nvl(comments, '%')) like l_comments_mask escape '\'
      )
      stream left outer join
      (
          select bl.base_location_id
            ||substr('-', 1, length(pl.sub_location_id))
            ||pl.sub_location_id as stream_id,
            s.stream_location_code
            from at_physical_location pl,
            at_base_location bl,
            at_stream s
           where upper(bl.base_location_id
            ||substr('-', 1, length(pl.sub_location_id))
            ||pl.sub_location_id) like l_flows_into_stream_id_mask escape '\'
         and pl.base_location_code  = bl.base_location_code
         and s.stream_location_code = pl.location_code
      )
      confluence on stream.receiving_stream_code = confluence.stream_location_code left outer join
      (
          select bl.base_location_id
            ||substr('-', 1, length(pl.sub_location_id))
            ||pl.sub_location_id as stream_id,
            s.stream_location_code
            from at_physical_location pl,
            at_base_location bl,
            at_stream s
           where upper(bl.base_location_id
            ||substr('-', 1, length(pl.sub_location_id))
            ||pl.sub_location_id) like l_diverts_from_stream_id_mask escape '\'
         and pl.base_location_code  = bl.base_location_code
         and s.stream_location_code = pl.location_code
      )
      diversion on stream.diverting_stream_code = diversion.stream_location_code;
   end cat_streams;
--------------------------------------------------------------------------------
-- function cat_streams_f
--------------------------------------------------------------------------------
   function cat_streams_f(
         p_stream_id_mask              in varchar2 default '*',
         p_station_unit                in varchar2 default 'km',
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
      cat_streams( l_cursor, p_stream_id_mask, p_station_unit, p_stationing_starts_ds_mask, p_flows_into_stream_id_mask, p_flows_into_station_min, p_flows_into_station_max, p_flows_into_bank_mask, p_diverts_from_stream_id_mask, p_diverts_from_station_min, p_diverts_from_station_max, p_diverts_from_bank_mask, p_length_min, p_length_max, p_average_slope_min, p_average_slope_max, p_comments_mask, p_office_id_mask) ;
      return l_cursor;
   end cat_streams_f;
--------------------------------------------------------------------------------
-- procedure store_stream_reach
--------------------------------------------------------------------------------
   procedure store_stream_reach(
         p_reach_id           in varchar2,
         p_stream_id          in varchar2,
         p_fail_if_exists     in varchar2,
         p_ignore_nulls       in varchar2,
         p_upstream_location   in varchar2,
         p_downstream_location in varchar2,
         p_configuration_id   in varchar2 default null,
         p_comments           in varchar2 default null,
         p_office_id          in varchar2 default null)
   is
      l_fail_if_exists          boolean := cwms_util.is_true(p_fail_if_exists) ;
      l_ignore_nulls            boolean := cwms_util.is_true(p_ignore_nulls) ;
      l_exists                  boolean;
      l_office_id               varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_configuration_code      number(10);
      l_rec                     at_stream_reach%rowtype;
      l_stream_code             integer;
      l_us_stream_code          integer;
      l_ds_stream_code          integer;
      l_us_stream_location_code integer;
      l_ds_stream_location_code integer;
      l_us_stream_location_station  at_stream_location.station%type;
      l_ds_stream_location_station  at_stream_location.station%type;
      l_us_stream_location_station2 at_stream_location.station%type;
      l_ds_stream_location_station2 at_stream_location.station%type;
      l_stream_rec              at_stream%rowtype;
      l_stream_loc_rec          at_stream_location%rowtype;
      l_zero_station            at_stream.zero_station%type;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_reach_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream reach location identifier.') ;
      end if;
      if p_configuration_id is null then
         l_configuration_code := cwms_configuration.get_configuration_code('OTHER', 'CWMS');
      else
         l_configuration_code := cwms_configuration.get_configuration_code(p_configuration_id, p_office_id);
      end if;
      l_rec.stream_reach_location_code := cwms_loc.get_location_code(l_office_id, p_reach_id);
      if not cwms_loc.can_store(l_rec.stream_reach_location_code, 'STREAM_REACH') then
         cwms_err.raise(
            'ERROR', 
            'Cannot store STREAM_REACH information to location '
            ||l_office_id||'/'||p_reach_id
            ||' (location kind = '
            ||cwms_loc.check_location_kind(l_rec.stream_reach_location_code)
            ||')');
      end if;
      ------------------------------------------------------------
      -- determine if the reach exists (retrieve it if it does) --
      ------------------------------------------------------------
      begin
          select *
            into l_rec
            from at_stream_reach
           where stream_reach_location_code = l_rec.stream_reach_location_code;
         l_exists := true;
      exception
         when no_data_found then l_exists := false;
         if p_stream_id is null then
            cwms_err.raise('INVALID_ITEM', '<NULL>', 'CWMS stream location identifier, must be specified for new stream reaches') ;
         end if;
      end;
      if l_exists and l_fail_if_exists then
         cwms_err.raise('ITEM_ALREADY_EXISTS', 'CWMS stream reach identifier', l_office_id ||'/' ||p_stream_id ||'/' ||p_reach_id) ;
      end if;
      ----------------------------------------
      -- get stationing direction on stream --
      ----------------------------------------
      if l_exists then
         select *
           into l_stream_rec
           from at_stream
          where stream_location_code = l_rec.stream_location_code; 
      else
         select *
           into l_stream_rec
           from at_stream
          where stream_location_code = cwms_loc.get_location_code(l_office_id, p_stream_id); 
      end if;
      l_zero_station := l_stream_rec.zero_station;
      ----------------------------------------------------
      -- get specified us and ds locations and stations --
      ----------------------------------------------------
      l_stream_code := get_stream_code(p_office_id, p_stream_id);
      begin
         select location_code,
                stream_location_code,
                station 
           into l_us_stream_location_code,
                l_us_stream_code,
                l_us_stream_location_station
           from at_stream_location
          where location_code = cwms_loc.get_location_code(p_office_id, p_upstream_location);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Stream location',
               cwms_util.get_db_office_id(p_office_id)
               ||'/'
               ||p_upstream_location);
      end;
      if l_us_stream_location_station is null then
         cwms_err.raise(
            'ERROR',
            'Upstream location '
            ||p_upstream_location
            ||' does not have a stream station');
      end if;
      begin
         select location_code,
                stream_location_code,
                station
           into l_ds_stream_location_code,
                l_ds_stream_code,
                l_ds_stream_location_station
           from at_stream_location
          where location_code = cwms_loc.get_location_code(p_office_id, p_downstream_location);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Stream location',
               cwms_util.get_db_office_id(p_office_id)
               ||'/'
               ||p_downstream_location);
      end;
      if l_ds_stream_location_station is null then
         cwms_err.raise(
            'ERROR',
            'Downstream location '
            ||p_downstream_location
            ||' does not have a stream station');
      end if;
      if l_stream_code not in (l_us_stream_code, l_ds_stream_code) then
         cwms_err.raise(
            'ERROR',
            'Upstream location and/or downstream location must be on specified stream');
      end if;
      if l_us_stream_code != l_stream_code or l_ds_stream_code != l_stream_code then
         if l_us_stream_code != l_stream_code then
            select *
              into l_stream_loc_rec
              from at_stream_location
             where location_code = cwms_loc.get_location_code(p_office_id, p_upstream_location);

            if l_stream_loc_rec.stream_location_code != l_stream_rec.diverting_stream_code or
               l_stream_loc_rec.station              != l_stream_rec.diversion_station
            then
               cwms_err.raise(
                  'ERROR',
                  'Stream reach upstream location ('
                  ||p_upstream_location
                  ||') is invalid for stream '
                  ||p_stream_id);
            end if;
            ---------------------------------------------
            -- us location code is on diverting stream --
            ---------------------------------------------
            if l_zero_station = 'DS' then
               l_us_stream_location_station := 1e38; 
            else 
               l_us_stream_location_station := 0;
         end if;
         end if;
         if l_ds_stream_code != l_stream_code then
            select *
              into l_stream_loc_rec
              from at_stream_location
             where location_code = cwms_loc.get_location_code(p_office_id, p_downstream_location);

            if l_stream_loc_rec.stream_location_code != l_stream_rec.receiving_stream_code or
               l_stream_loc_rec.station              != l_stream_rec.confluence_station
            then
               cwms_err.raise(
                  'ERROR',
                  'Stream reach downstream location ('
                  ||p_downstream_location
                  ||') is invalid for stream '
                  ||p_stream_id);
            end if;
            ---------------------------------------------
            -- ds location code is on receiving stream --
            ---------------------------------------------
            if l_zero_station = 'DS' then
               l_us_stream_location_station := 0; 
            else 
               l_us_stream_location_station := 1e38;
            end if;
         end if;
      end if;
      ------------------------
      -- more sanity checks --
      ------------------------
      if (l_zero_station = 'DS' and l_us_stream_location_station <= l_ds_stream_location_station) or
         (l_zero_station = 'US' and l_us_stream_location_station >= l_ds_stream_location_station)
      then   
         cwms_err.raise(
            'ERROR',
            'Specified upstream station is downstream of specified downstream station');
      end if;
      for rec in (select *
            from at_stream_reach
                   where configuration_code = l_configuration_code
                     and stream_reach_location_code != nvl(l_rec.stream_reach_location_code, -1)
                 )
      loop
         select stream_location_code,
                station 
           into l_us_stream_code,
                l_us_stream_location_station2
           from at_stream_location
          where location_code = rec.upstream_location_code;
         if l_us_stream_location_station2 is null then
            cwms_err.raise(
               'ERROR',
               'Stream reach '
               ||cwms_loc.get_location_id(rec.stream_reach_location_code)
               ||' upstream location '
               ||cwms_loc.get_location_id(rec.upstream_location_code)
               ||' does not have a stream station');
         end if;
         if l_us_stream_location_station2 between l_ds_stream_location_station and l_us_stream_location_station and 
            l_us_stream_location_station2 not in (l_ds_stream_location_station, l_us_stream_location_station)
         then
            cwms_err.raise(
               'ERROR',
               'Stream reach overlaps existing stream reach '
               ||cwms_loc.get_location_id(rec.stream_reach_location_code));
         end if;
         select stream_location_code,
                station 
           into l_ds_stream_code,
                l_ds_stream_location_station2
           from at_stream_location
          where location_code = rec.downstream_location_code;
         if l_ds_stream_location_station2 is null then
            cwms_err.raise(
               'ERROR',
               'Stream reach '
               ||cwms_loc.get_location_id(rec.stream_reach_location_code)
               ||' downstream location '
               ||cwms_loc.get_location_id(rec.downstream_location_code)
               ||' does not have a stream station');
      end if;
         if l_ds_stream_location_station2 between l_ds_stream_location_station and l_us_stream_location_station and 
            l_ds_stream_location_station2 not in (l_ds_stream_location_station, l_us_stream_location_station)
         then
            cwms_err.raise(
               'ERROR',
               'Stream reach overlaps existing stream reach '
               ||cwms_loc.get_location_id(rec.stream_reach_location_code));
         end if;
      end loop;
      --------------------------
      -- set the reach values --
      --------------------------
      if p_stream_id is not null then
         l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id);
      end if;
      if p_upstream_location is not null or not l_ignore_nulls then
         l_rec.upstream_location_code := cwms_loc.get_location_code(l_office_id, p_upstream_location);
      end if;
      if p_downstream_location is not null or not l_ignore_nulls then
         l_rec.downstream_location_code := cwms_loc.get_location_code(l_office_id, p_downstream_location);
      end if;
      if l_configuration_code is not null or not l_ignore_nulls then
         l_rec.configuration_code := l_configuration_code;
      end if;
      if p_comments is not null or not l_ignore_nulls then
         l_rec.comments := p_comments;
      end if;
      --------------------------------
      -- insert or update the reach --
      --------------------------------
      if l_exists then
          update at_stream_reach
         set row                      = l_rec
           where stream_reach_location_code = l_rec.stream_reach_location_code;
      else
          insert into at_stream_reach values l_rec;
      end if;
      ---------------------------
      -- set the location kind --
      ---------------------------
      cwms_loc.update_location_kind(l_rec.stream_reach_location_code, 'STREAM_REACH', 'A');
   end store_stream_reach;
--------------------------------------------------------------------------------
-- procedure retrieve_stream_reach
--------------------------------------------------------------------------------
   procedure retrieve_stream_reach(
      p_upstream_location   out varchar2,
      p_downstream_location out varchar2,
      p_configuration_id    out varchar2,
      p_upstream_station    out binary_double,
      p_downstream_station  out binary_double,
      p_comments            out varchar2,
      p_reach_id            in  varchar2,
      p_station_unit        in  varchar2 default null,
      p_office_id           in  varchar2 default null)
   is
      l_stream_id varchar2(256);
   begin
      retrieve_stream_reach2(
         p_upstream_location,
         p_downstream_location,
         p_configuration_id,
         p_upstream_station,
         p_downstream_station,
         p_comments,
         l_stream_id, 
         p_reach_id,
         p_station_unit,
         p_office_id);
   end retrieve_stream_reach;
--------------------------------------------------------------------------------
-- procedure retrieve_stream_reach2
--------------------------------------------------------------------------------
   procedure retrieve_stream_reach2(
      p_upstream_location   out varchar2,
      p_downstream_location out varchar2,
      p_configuration_id    out varchar2,
      p_upstream_station    out binary_double,
      p_downstream_station  out binary_double,
      p_comments            out varchar2,
      p_stream_id           out varchar2, 
      p_reach_id            in  varchar2,
      p_station_unit        in  varchar2 default null,
      p_office_id           in  varchar2 default null)
   is
      l_office_id varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_rec       at_stream_reach%rowtype;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_reach_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream reach identifier.') ;
      end if;
      begin
          select *
            into l_rec
            from at_stream_reach
           where stream_reach_location_code = cwms_loc.get_location_code(l_office_id, p_reach_id);
         p_upstream_location         := cwms_util.get_location_id(l_office_id, l_rec.upstream_location_code);
         p_downstream_location       := cwms_util.get_location_id(l_office_id, l_rec.downstream_location_code);
         p_configuration_id          := cwms_configuration.get_configuration_id(l_rec.configuration_code);
         p_comments                  := l_rec.comments;
         p_stream_id                 := cwms_loc.get_location_id(l_rec.stream_location_code); 
         select cwms_util.convert_units(station, 'km', nvl(cwms_util.get_unit_id(p_station_unit), 'km'))
           into p_upstream_station
           from at_stream_location
          where stream_location_code = l_rec.upstream_location_code; 
         select cwms_util.convert_units(station, 'km', nvl(cwms_util.get_unit_id(p_station_unit), 'km'))
           into p_downstream_station
           from at_stream_location
          where stream_location_code = l_rec.downstream_location_code; 
      exception
      when no_data_found then
         cwms_err.raise( 'ITEM_DOES_NOT_EXIST', 'CWMS stream reach ', l_office_id ||'/' ||p_reach_id) ;
      end;
   end retrieve_stream_reach2;
--------------------------------------------------------------------------------
-- procedure delete_stream_reach
--------------------------------------------------------------------------------
   procedure delete_stream_reach(
         p_reach_id  in varchar2,
         p_office_id in varchar2 default null)
   is
      location_id_not_found exception;
      l_location_kind_id    cwms_location_kind.location_kind_id%type;
      pragma exception_init(location_id_not_found, -20025);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_reach_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream reach identifier.') ;
      end if;
      l_location_kind_id := cwms_loc.check_location_kind(p_reach_id, p_office_id);
      if l_location_kind_id != 'STREAM_REACH' then
         cwms_err.raise(
            'ERROR',
            'Cannot delete stream reach information from location '
            ||cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||p_reach_id
            ||' (location kind = '
            ||l_location_kind_id
            ||')');
      end if;
      l_location_kind_id := cwms_loc.can_revert_loc_kind_to(p_reach_id, p_office_id); -- revert-to kind
      delete
        from at_stream_reach
       where stream_reach_location_code = cwms_loc.get_location_code(p_office_id, p_reach_id);
      cwms_loc.update_location_kind(cwms_loc.get_location_code(p_office_id, p_reach_id), 'STREAM_REACH', 'D');
   end delete_stream_reach;
--------------------------------------------------------------------------------
-- procedure rename_stream_reach
--------------------------------------------------------------------------------
   procedure rename_stream_reach(
         p_old_reach_id in varchar2,
         p_new_reach_id in varchar2,
         p_office_id    in varchar2 default null)
   is
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_old_reach_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream reach identifier.') ;
      end if;
      if p_new_reach_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream reach identifier.') ;
      end if;
      cwms_loc.rename_location(p_old_reach_id, p_new_reach_id, p_office_id);
   end rename_stream_reach;
--------------------------------------------------------------------------------
-- procedure cat_stream_reaches
--------------------------------------------------------------------------------
   procedure cat_stream_reaches(
         p_reach_catalog out sys_refcursor,
         p_stream_id_mask        in varchar2 default '*',
         p_reach_id_mask         in varchar2 default '*',
         p_configuration_id_mask in varchar2 default '*',
         p_comments_mask         in varchar2 default '*',
         p_station_unit          in varchar2 default 'mi',
         p_office_id_mask        in varchar2 default null)
   is
      l_stream_id_mask        varchar2(57)  := cwms_util.normalize_wildcards(upper(trim(p_stream_id_mask)));
      l_reach_id_mask         varchar2(57)  := cwms_util.normalize_wildcards(upper(trim(p_reach_id_mask)));
      l_configuration_id_mask varchar2(32)  := cwms_util.normalize_wildcards(upper(trim(p_configuration_id_mask)));
      l_comments_mask         varchar2(256) := cwms_util.normalize_wildcards(upper(trim(p_comments_mask)));
      l_office_id_mask        varchar2(16)  := cwms_util.normalize_wildcards(nvl(upper(trim(p_office_id_mask)), cwms_util.user_office_id));
   begin
      open p_reach_catalog for
         select q1.office_id,
                q1.configuration,
                q1.stream_location,
                q1.reach_location,
                q2.location_id as upstream_location,
                q2.station     as upstream_station,
                q3.location_id as upstream_reach,
                q4.location_id as downstream_location,
                q4.station     as downstream_station,
                q5.location_id as downstream_reach,
                q1.comments
           from (select o.office_id,
                        c.configuration_code,
                        c.configuration_id as configuration,
                        cwms_loc.get_location_id(sr.stream_location_code) as stream_location,
                        cwms_loc.get_location_id(sr.stream_reach_location_code) as reach_location,
                        sr.stream_location_code,
                        sr.upstream_location_code,
                        sr.downstream_location_code,
                        sr.comments
                   from at_stream_reach sr,
                        at_configuration c,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_office o
                  where upper(o.office_id) like l_office_id_mask escape '\'
                    and upper(c.configuration_id) like l_configuration_id_mask escape '\'
                    and upper(cwms_loc.get_location_id(sr.stream_location_code)) like l_stream_id_mask escape '\'
                    and upper(cwms_loc.get_location_id(sr.stream_reach_location_code)) like l_reach_id_mask escape '\'
                    and upper(nvl(sr.comments, '.')) like l_comments_mask escape '\'
                    and pl.location_code = sr.stream_reach_location_code
                    and bl.base_location_code = pl.base_location_code
                    and o.office_code = bl.db_office_code
                    and c.configuration_code = sr.configuration_code
                ) q1 
                left outer join
                (select location_code,
                        stream_location_code,
                        cwms_loc.get_location_id(location_code) as location_id,
                        cwms_util.convert_units(station, 'km', p_station_unit) as station
                   from at_stream_location
                ) q2 on q2.location_code = q1.upstream_location_code 
                    and q2.stream_location_code = q1.stream_location_code
                left outer join
                (select stream_location_code,
                        downstream_location_code,
                        configuration_code,
                        cwms_loc.get_location_id(stream_reach_location_code) as location_id
                   from at_stream_reach     
                ) q3 on q3.stream_location_code = q1.stream_location_code 
                    and q3.configuration_code = q1.configuration_code 
                    and q3.downstream_location_code = q1.upstream_location_code
                left outer join
                (select location_code,
                        stream_location_code,
                        cwms_loc.get_location_id(location_code) as location_id,
                        cwms_util.convert_units(station, 'km', p_station_unit) as station
                   from at_stream_location
                ) q4 on q4.location_code = q1.downstream_location_code 
                    and q4.stream_location_code = q1.stream_location_code
                left outer join
                (select stream_location_code,
                        upstream_location_code,
                        configuration_code,
                        cwms_loc.get_location_id(stream_reach_location_code) as location_id
                   from at_stream_reach     
                ) q5 on q5.stream_location_code = q1.stream_location_code 
                    and q5.configuration_code = q1.configuration_code 
                    and q5.upstream_location_code = q1.downstream_location_code
          order by 1, 2, 3, 9;
   end cat_stream_reaches;
--------------------------------------------------------------------------------
-- function cat_stream_reaches_f
--------------------------------------------------------------------------------
   function cat_stream_reaches_f(
         p_stream_id_mask        in varchar2 default '*',
         p_reach_id_mask         in varchar2 default '*',
         p_configuration_id_mask in varchar2 default '*',
         p_comments_mask         in varchar2 default '*',
         p_station_unit          in varchar2 default 'mi',
         p_office_id_mask        in varchar2 default null)
      return sys_refcursor
   is
      l_cursor sys_refcursor;
   begin
      cat_stream_reaches(
         l_cursor, 
         p_stream_id_mask, 
         p_reach_id_mask, 
         p_configuration_id_mask, 
         p_comments_mask, 
         p_station_unit, 
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
      l_office_id      varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_station_unit   varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id) ;
      l_stage_unit     varchar2(16) := cwms_util.get_unit_id(p_stage_unit, l_office_id) ;
      l_area_unit      varchar2(16) := cwms_util.get_unit_id(p_area_unit, l_office_id) ;
      l_fail_if_exists boolean      := cwms_util.is_true(p_fail_if_exists) ;
      l_ignore_nulls   boolean      := cwms_util.is_true(p_ignore_nulls) ;
      l_exists         boolean;
      l_rec at_stream_location%rowtype;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID') ;
      end if;
      if p_station is not null and p_station_unit is null then
         cwms_err.raise( 'ERROR', 'Station unit must be specified with station.') ;
      end if;
      if p_lowest_measurable_stage is not null and p_stage_unit is null then
         cwms_err.raise( 'ERROR', 'Stage unit must be specified with lowest measureable stage.') ;
      end if;
      if(p_drainage_area is not null or p_ungaged_drainage_area is not null) and p_area_unit is null then
         cwms_err.raise( 'ERROR', 'Area unit must be specified with drainage areas.') ;
      end if;
      if p_bank is not null and upper(p_bank) not in('L', 'R') then
         cwms_err.raise( 'INVALID_ITEM', p_bank, 'stream bank, must be ''L'' or ''R''.') ;
      end if;
      ------------------------------------------
      -- get the existing record if it exists --
      ------------------------------------------
      l_rec.location_code := cwms_loc.get_location_code(l_office_id, p_location_id) ;
      if not cwms_loc.can_store(l_rec.location_code, 'STREAM_LOCATION') then
         cwms_err.raise(
            'ERROR', 
            'Cannot store STREAM_LOCATION information to location '
            ||l_office_id||'/'||p_location_id
            ||' (location kind = '
            ||cwms_loc.check_location_kind(l_rec.location_code)
            ||')');
      end if;
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
         cwms_err.raise( 'ERROR', 'Location ' ||l_office_id ||'/' ||p_location_id ||' already exists as a stream location on stream ' ||l_office_id ||'/' ||p_stream_id) ;
      end if;
      ---------------------------
      -- set the record values --
      ---------------------------
      if p_stream_id is not null then
         l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id) ;
      elsif not l_ignore_nulls then
         l_rec.stream_location_code := null;
      end if;
      if p_station is not null or not l_ignore_nulls then
         l_rec.station := cwms_util.convert_units(p_station, l_station_unit, 'km') ;
      end if;
      if p_published_station is not null or not l_ignore_nulls then
         l_rec.published_station := cwms_util.convert_units(p_published_station, l_station_unit, 'km') ;
      end if;
      if p_navigation_station is not null or not l_ignore_nulls then
         l_rec.navigation_station := cwms_util.convert_units(p_navigation_station, l_station_unit, 'km') ;
      end if;
      if p_bank is not null or not l_ignore_nulls then
         l_rec.bank := upper(p_bank) ;
      end if;
      if p_lowest_measurable_stage is not null or not l_ignore_nulls then
         l_rec.lowest_measurable_stage := cwms_util.convert_units(p_lowest_measurable_stage, l_stage_unit, 'm') ;
      end if;
      if p_drainage_area is not null or not l_ignore_nulls then
         l_rec.drainage_area := cwms_util.convert_units(p_drainage_area, l_area_unit, 'm2') ;
      end if;
      if p_ungaged_drainage_area is not null or not l_ignore_nulls then
         l_rec.ungaged_area      := cwms_util.convert_units(p_ungaged_drainage_area, l_area_unit, 'm2') ;
      end if;
      ---------------------------------
      -- update or insert the record --
      ---------------------------------
      if l_exists then
         update at_stream_location
            set row = l_rec
          where location_code = l_rec.location_code;
      else
          insert into at_stream_location values l_rec;
      end if;
      ---------------------------
      -- set the location kind --
      ---------------------------
      cwms_loc.update_location_kind(l_rec.location_code, 'STREAM_LOCATION', 'A');
   end store_stream_location;
--------------------------------------------------------------------------------
-- procedure retrieve_stream_location
--------------------------------------------------------------------------------
   procedure retrieve_stream_location(
         p_station out binary_double,
         p_published_station out binary_double,
         p_navigation_station out binary_double,
         p_bank out varchar2,
         p_lowest_measurable_stage out binary_double,
         p_drainage_area out binary_double,
         p_ungaged_drainage_area out binary_double,
         p_location_id  in varchar2,
         p_stream_id    in varchar2,
         p_station_unit in varchar2,
         p_stage_unit   in varchar2,
         p_area_unit    in varchar2,
         p_office_id    in varchar2 default null)
   is
      l_office_id            varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_station_unit         varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id) ;
      l_stage_unit           varchar2(16) := cwms_util.get_unit_id(p_stage_unit, l_office_id) ;
      l_area_unit            varchar2(16) := cwms_util.get_unit_id(p_area_unit, l_office_id) ;
      l_location_code        number(10) ;
      l_stream_location_code number(10) ;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS location identifier.') ;
      end if;
      if p_stream_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream identifier.') ;
      end if;
      if p_station_unit is null then
         cwms_err.raise( 'ERROR', 'Station unit must be specified.') ;
      end if;
      if p_stage_unit is null then
         cwms_err.raise( 'ERROR', 'Stage unit must be specified.') ;
      end if;
      if p_area_unit is null then
         cwms_err.raise( 'ERROR', 'Area unit must be specified.') ;
      end if;
      -----------------------
      -- retrieve the data --
      -----------------------
      l_location_code        := cwms_loc.get_location_code(l_office_id, p_location_id) ;
      l_stream_location_code := get_stream_code(l_office_id, p_stream_id) ;
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
           where location_code    = l_location_code
         and stream_location_code = l_stream_location_code;
      exception
      when no_data_found then
         cwms_err.raise( 'ERROR', 'Location ' ||l_office_id ||'/' ||p_location_id ||' does not exist as a stream location on stream ' ||l_office_id ||'/' ||p_stream_id) ;
      end;
   end retrieve_stream_location;
--------------------------------------------------------------------------------
-- procedure delete_stream_location
--------------------------------------------------------------------------------
   procedure delete_stream_location(
         p_location_id in varchar2,
         p_stream_id   in varchar2, -- unused as stream_id, repurposed as delete action
         p_office_id   in varchar2 default null)
   is
   begin
      delete_stream_location2( p_location_id => p_location_id, p_delete_action => p_stream_id, -- note repurposing
      p_office_id => p_office_id) ;
   end delete_stream_location;
--------------------------------------------------------------------------------
-- procedure delete_stream_location2
--------------------------------------------------------------------------------
   procedure delete_stream_location2(
         p_location_id            in varchar2,
         p_delete_action          in varchar2 default cwms_util.delete_key,
         p_delete_location        in varchar2 default 'F',
         p_delete_location_action in varchar2 default cwms_util.delete_key,
         p_office_id              in varchar2 default null)
   is
      l_location_code    number(10);
      l_delete_location  boolean;
      l_delete_action1   varchar2(16);
      l_delete_action2   varchar2(16);
      l_count            pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION') ;
      end if;
      l_delete_action1 := upper(substr(p_delete_action, 1, 16)) ;
      if l_delete_action1 not in( cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
         l_delete_action1 := cwms_util.delete_key; -- delete_stream_location might pass in a stream_id
      end if;
      l_delete_location := cwms_util.return_true_or_false(p_delete_location) ;
      l_delete_action2  := upper(substr(p_delete_location_action, 1, 16)) ;
      if l_delete_action2 not in( cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
         cwms_err.raise( 'ERROR', 'Delete action must be one of ''' ||cwms_util.delete_key ||''',  ''' ||cwms_util.delete_data ||''', or ''' ||cwms_util.delete_all ||'') ;
      end if;
      l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id) ;
      -------------------------------------------
      -- delete the child records if specified --
      -------------------------------------------
      if l_delete_action1 in(cwms_util.delete_data, cwms_util.delete_all) then
         null; -- no dependent data
      end if;
      ------------------------------------
      -- delete the record if specified --
      ------------------------------------
      if l_delete_action1 in(cwms_util.delete_key, cwms_util.delete_all) then
          delete from at_stream_location where location_code = l_location_code;
          cwms_loc.update_location_kind(l_location_code, 'STREAM_LOCATION', 'D');
      end if;
      -------------------------------------
      -- delete the location if required --
      -------------------------------------
      if l_delete_location then
         cwms_loc.delete_location(p_location_id, l_delete_action2, p_office_id) ;
      end if;
   end delete_stream_location2;
--------------------------------------------------------------------------------
-- procedure cat_stream_locations
--------------------------------------------------------------------------------
   procedure cat_stream_locations(
         p_stream_location_catalog out sys_refcursor,
         p_stream_id_mask   in varchar2 default '*',
         p_location_id_mask in varchar2 default '*',
         p_station_unit     in varchar2 default null,
         p_stage_unit       in varchar2 default null,
         p_area_unit        in varchar2 default null,
         p_office_id_mask   in varchar2 default null)
   is
      l_stream_id_mask   varchar2(57) := cwms_util.normalize_wildcards(upper(p_stream_id_mask)) ;
      l_location_id_mask varchar2(57) := cwms_util.normalize_wildcards(upper(p_location_id_mask)) ;
      l_office_id_mask   varchar2(16) := cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.user_office_id))) ;
      l_station_unit     varchar2(16) := cwms_util.get_unit_id(nvl(p_station_unit, 'km')) ;
      l_stage_unit       varchar2(16) := cwms_util.get_unit_id(nvl(p_stage_unit, 'm')) ;
      l_area_unit        varchar2(16) := cwms_util.get_unit_id(nvl(p_area_unit, 'm2')) ;
   begin
      open p_stream_location_catalog for select o.office_id,
      bl1.base_location_id ||substr('-', 1, length(pl1.sub_location_id)) ||pl1.sub_location_id
   as
      stream_id,
      bl2.base_location_id ||substr('-', 1, length(pl2.sub_location_id)) ||pl2.sub_location_id
   as
      location_id,
      cwms_util.convert_units(station, 'km', l_station_unit)
   as
      station,
      cwms_util.convert_units(published_station, 'km', l_station_unit)
   as
      published_station,
      cwms_util.convert_units(navigation_station, 'km', l_station_unit)
   as
      navigation_station,
      bank,
      cwms_util.convert_units(lowest_measurable_stage, 'm', l_stage_unit)
   as
      lowest_measurable_stage,
      cwms_util.convert_units(drainage_area, 'm2', l_area_unit)
   as
      drainage_area,
      cwms_util.convert_units(ungaged_area, 'm2', l_area_unit)
   as
      ungaged_drainage_area,
      l_station_unit
   as
      station_unit,
      l_stage_unit
   as
      stage_unit,
      l_area_unit
   as
      area_unit from at_physical_location pl1,
      at_physical_location pl2,
      at_base_location bl1,
      at_base_location bl2,
      at_stream_location sl,
      cwms_office o where pl1.location_code = sl.stream_location_code and bl1.base_location_code = pl1.base_location_code and upper(bl1.base_location_id ||substr('-', 1, length(pl1.sub_location_id)) ||pl1.sub_location_id) like l_stream_id_mask escape '\' and pl2.location_code = sl.location_code and bl2.base_location_code = pl2.base_location_code and upper(bl2.base_location_id ||substr('-', 1, length(pl2.sub_location_id)) ||pl2.sub_location_id) like l_location_id_mask escape '\' and o.office_code = bl1.db_office_code order by 1,
      2,
      4,
      3;
   end cat_stream_locations;
--------------------------------------------------------------------------------
-- function cat_stream_locations_f
--------------------------------------------------------------------------------
   function cat_stream_locations_f(
         p_stream_id_mask   in varchar2 default '*',
         p_location_id_mask in varchar2 default '*',
         p_station_unit     in varchar2 default null,
         p_stage_unit       in varchar2 default null,
         p_area_unit        in varchar2 default null,
         p_office_id_mask   in varchar2 default null)
      return sys_refcursor
   is
      l_cursor sys_refcursor;
   begin
      cat_stream_locations( l_cursor, p_location_id_mask, p_stream_id_mask, p_station_unit, p_stage_unit, p_area_unit, p_office_id_mask) ;
      return l_cursor;
   end cat_stream_locations_f;
--------------------------------------------------------------------------------
-- function get_next_location_codes_f
--
-- return  the next-upstream or next-downstream stream location on this stream
--------------------------------------------------------------------------------
   function get_next_location_codes_f(
         p_stream_code in number,
         p_direction   in varchar2,
         p_station     in binary_double default null) -- in km
      return number_tab_t
   is
      l_direction    varchar2(2) ;
      l_zero_station varchar2(2) ;
      l_next_location_codes number_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_direction is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream identifier.') ;
      end if;
      l_direction := upper(substr(p_direction, 1, 2)) ;
      if p_direction not in('US', 'DS') then
         cwms_err.raise( 'ERROR', 'Direction must be specified as ''US'' or ''DS''') ;
      end if;
       select zero_station
         into l_zero_station
         from at_stream
        where stream_location_code = p_stream_code;
      begin
         if l_zero_station = l_direction then
            ------------------------------------------
            -- get location with next lower station --
            ------------------------------------------
             select location_code bulk collect
               into l_next_location_codes
               from at_stream_location
              where stream_location_code = p_stream_code
            and station                  =
               (
                   select max(station)
                     from at_stream_location
                    where stream_location_code = p_stream_code
                  and station                  < nvl(p_station, binary_double_max_normal)
               ) ;
         else
            -------------------------------------------
            -- get location with next higher station --
            -------------------------------------------
             select location_code bulk collect
               into l_next_location_codes
               from at_stream_location
              where stream_location_code = p_stream_code
            and station                  =
               (
                   select min(station)
                     from at_stream_location
                    where stream_location_code = p_stream_code
                  and station                  > nvl(p_station, - binary_double_max_normal)
               ) ;
         end if;
      exception
      when no_data_found then
         null;
      end;
      return l_next_location_codes;
   end get_next_location_codes_f;
--------------------------------------------------------------------------------
-- function get_us_location_codes_f
--
-- return  the next-upstream stream location on this stream
--------------------------------------------------------------------------------
   function get_us_location_codes_f(
         p_stream_code in number,
         p_station     in binary_double default null) -- in km
      return number_tab_t
   is
   begin
      return get_next_location_codes_f(p_stream_code, 'US', p_station) ;
   end get_us_location_codes_f;
--------------------------------------------------------------------------------
-- function get_ds_location_codes_f
--
-- return  the next-downstream stream location on this stream
--------------------------------------------------------------------------------
   function get_ds_location_codes_f(
         p_stream_code in number,
         p_station     in binary_double default null) -- in km
      return number_tab_t
   is
   begin
      return get_next_location_codes_f(p_stream_code, 'DS', p_station) ;
   end get_ds_location_codes_f;
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
      l_junction_type varchar2(1) ;
      l_stream_codes number_tab_t;
      l_station_1 binary_double;
      l_station_2 binary_double;
      l_stream_code number(10) ;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_station_1 is null or p_station_2 is null then
         cwms_err.raise( 'ERROR', 'Stream stations must not be null.') ;
      end if;
      if upper(p_junction_type) not in('C'
         /*onfluence*/
         , 'B'
         /*ifurcation*/
         ) then
         cwms_err.raise( 'ERROR', 'Junction type must be ''C''(confluence) or ''B''(bifurcation).') ;
      end if;
      l_junction_type   := upper(p_junction_type) ;
      l_station_1       := least(p_station_1, p_station_2) ;
      l_station_2       := greatest(p_station_1, p_station_2) ;
      if l_junction_type = 'C' then
          select stream_location_code bulk collect
            into l_stream_codes
            from at_stream
           where receiving_stream_code = p_stream_code
         and confluence_station between l_station_1 and l_station_2;
      else
          select stream_location_code bulk collect
            into l_stream_codes
            from at_stream
           where diverting_stream_code = p_stream_code
         and diversion_station between l_station_1 and l_station_2;
      end if;
      return l_stream_codes;
   end get_junctions_between_f;
--------------------------------------------------------------------------------
-- function get_confluences_between_f
--
-- get streams flowing into this stream between 2 stations
--------------------------------------------------------------------------------
   function get_confluences_between_f(
         p_stream_code in number,
         p_station_1   in binary_double, -- in km
         p_station_2   in binary_double) -- in km
      return number_tab_t
   is
   begin
      return get_junctions_between_f( p_stream_code, 'C', -- confluence
      p_station_1, p_station_2) ;
   end get_confluences_between_f;
--------------------------------------------------------------------------------
-- function get_bifurcations_between_f
--
-- get streams flowing into this stream between 2 stations
--------------------------------------------------------------------------------
   function get_bifurcations_between_f(
         p_stream_code in number,
         p_station_1   in binary_double, -- in km
         p_station_2   in binary_double) -- in km
      return number_tab_t
   is
   begin
      return get_junctions_between_f( p_stream_code, 'B', -- bifurcation
      p_station_1, p_station_2) ;
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
         p_all_us_locations in boolean default false,
         p_same_stream_only in boolean default false)
   is
      l_location_codes number_tab_t;
      l_stream_codes number_tab_t;
      l_zero_station varchar2(2) ;
      l_station binary_double;
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
      l_location_codes         := get_us_location_codes_f(p_stream_code, p_station) ;
      if l_location_codes.count > 0 then
         ----------------------------------
         -- add the location to our list --
         ----------------------------------
         for i in 1..l_location_codes.count
         loop
            p_location_codes.extend;
            p_location_codes(p_location_codes.count) := l_location_codes(i) ;
         end loop;
         -------------------------------------
         -- get the station of the location --
         -------------------------------------
          select station
            into l_station
            from at_stream_location
           where location_code    = l_location_codes(1) -- all same station if more than one
         and stream_location_code = p_stream_code;
         -----------------------------------------------------
         -- get all further upstream locations if specified --
         -----------------------------------------------------
         if p_all_us_locations then
            get_us_location_codes( p_location_codes, p_stream_code, l_station, true, p_same_stream_only) ;
         end if;
      else
         ---------------------------------------------------------------------------
         -- no next upstream location, set the station beyond the upstream extent --
         ---------------------------------------------------------------------------
         if l_zero_station = 'DS' then
            l_station     := binary_double_max_normal;
         else
            l_station := - binary_double_max_normal;
         end if;
      end if;
      if not p_same_stream_only then
         -----------------------------------------------------------------------
         -- find all tribs that flow into this one upstream of here but below --
         -- the next upstream location (if any)                               --
         -----------------------------------------------------------------------
         l_stream_codes    := get_confluences_between_f(p_stream_code, p_station, l_station) ;
         if l_stream_codes is not null and l_stream_codes.count > 0 then
            for i in 1..l_stream_codes.count
            loop
               ----------------------------------------------
               -- set the station to beyond the confluence --
               -- (taking station direction into account)  --
               ----------------------------------------------
                select zero_station
                  into l_zero_station
                  from at_stream
                 where stream_location_code = l_stream_codes(i) ;
               if l_zero_station            = 'DS' then
                  l_station                := - binary_double_max_normal;
               else
                  l_station := binary_double_max_normal;
               end if;
               ------------------------------------------------
               -- get all the upstream stations on the tribs --
               ------------------------------------------------
               get_us_location_codes( p_location_codes, l_stream_codes(i), l_station, p_all_us_locations) ;
            end loop;
         end if;
         ---------------------------------------------------------------
         -- at the head - continue up diverting stream if appropriate --
         ---------------------------------------------------------------
         if l_station in(binary_double_max_normal, - binary_double_max_normal) and(p_all_us_locations or p_location_codes.count = 0) then
            l_stream_codes                                                                                                     := number_tab_t(null) ;
             select diverting_stream_code,
               diversion_station
               into l_stream_codes(1),
               l_station
               from at_stream
              where stream_location_code = p_stream_code;
            if l_stream_codes(1)        is not null then
               get_us_location_codes( p_location_codes, l_stream_codes(1), l_station, p_all_us_locations) ;
            end if;
         end if;
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
         p_all_ds_locations in boolean default false,
         p_same_stream_only in boolean default false)
   is
      l_location_codes number_tab_t;
      l_stream_codes number_tab_t;
      l_zero_station varchar2(2) ;
      l_station binary_double;
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
      l_location_codes         := get_ds_location_codes_f(p_stream_code, p_station) ;
      if l_location_codes.count > 0 then
         ----------------------------------
         -- add the location to our list --
         ----------------------------------
         for i in 1..l_location_codes.count
         loop
            p_location_codes.extend;
            p_location_codes(p_location_codes.count) := l_location_codes(i) ;
         end loop;
         -------------------------------------
         -- get the station of the location --
         -------------------------------------
          select station
            into l_station
            from at_stream_location
           where location_code    = l_location_codes(1) -- all same station if more than one
         and stream_location_code = p_stream_code;
         -------------------------------------------------------
         -- get all further downstream locations if specified --
         -------------------------------------------------------
         if p_all_ds_locations then
            get_ds_location_codes( p_location_codes, p_stream_code, l_station, true, p_same_stream_only) ;
         end if;
      else
         -------------------------------------------------------------------------------
         -- no next downstream location, set the station beyond the downstream extent --
         -------------------------------------------------------------------------------
         if l_zero_station = 'DS' then
            l_station     := - binary_double_max_normal;
         else
            l_station := binary_double_max_normal;
         end if;
      end if;
      if not p_same_stream_only then
         --------------------------------------------------------------------------------
         -- find all diversions that flow out of this one downstream of here but above --
         -- the next downstream location (if any)                                      --
         --------------------------------------------------------------------------------
         l_stream_codes    := get_bifurcations_between_f(p_stream_code, p_station, l_station) ;
         if l_stream_codes is not null and l_stream_codes.count > 0 then
            for i in 1..l_stream_codes.count
            loop
               ---------------------------------------------------
               -- set the station to beyond the upstream extent --
               -- (taking station direction into account)       --
               ---------------------------------------------------
                select zero_station
                  into l_zero_station
                  from at_stream
                 where stream_location_code = l_stream_codes(i) ;
               if l_zero_station            = 'DS' then
                  l_station                := binary_double_max_normal;
               else
                  l_station := - binary_double_max_normal;
               end if;
               -------------------------------------------------------
               -- get all the downstream stations on the diversions --
               -------------------------------------------------------
               get_ds_location_codes( p_location_codes, l_stream_codes(i), l_station, p_all_ds_locations) ;
            end loop;
         end if;
         ------------------------------------------------------------------
         -- at the mouth - continue down receiving stream if appropriate --
         ------------------------------------------------------------------
         if l_station in(binary_double_max_normal, - binary_double_max_normal) and(p_all_ds_locations or p_location_codes.count = 0) then
            l_stream_codes                                                                                                     := number_tab_t(null) ;
             select receiving_stream_code,
               confluence_station
               into l_stream_codes(1),
               l_station
               from at_stream
              where stream_location_code = p_stream_code;
            if l_stream_codes(1)        is not null then
               get_ds_location_codes( p_location_codes, l_stream_codes(1), l_station, p_all_ds_locations) ;
            end if;
         end if;
      end if;
   end get_ds_location_codes;
--------------------------------------------------------------------------------
-- procedure get_us_locations
--------------------------------------------------------------------------------
   procedure get_us_locations(
         p_us_locations out str_tab_t,
         p_stream_id        in varchar2,
         p_station          in binary_double,
         p_station_unit     in varchar2,
         p_all_us_locations in varchar2 default 'F',
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
   is
      l_office_id   varchar2(16) ;
      l_stream_code number(10) ;
      l_location_codes number_tab_t := number_tab_t() ;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_stream_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream identifier.') ;
      end if;
      if p_station is null then
         cwms_err.raise( 'ERROR', 'Station must not be null.') ;
      end if;
      ----------------------------
      -- get the location codes --
      ----------------------------
      l_office_id   := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_stream_code := get_stream_code(l_office_id, p_stream_id) ;
      get_us_location_codes( l_location_codes, l_stream_code, cwms_util.convert_units(p_station, cwms_util.get_unit_id(p_station_unit), 'km'), cwms_util.is_true(p_all_us_locations), cwms_util.is_true(p_same_stream_only)) ;
       select bl.base_location_id
         ||substr('-', 1, length(pl.sub_location_id))
         ||pl.sub_location_id bulk collect
         into p_us_locations
         from table(l_location_codes) lc,
         at_stream_location sl,
         at_physical_location pl,
         at_base_location bl
        where sl.location_code  = lc.column_value
      and pl.location_code      = sl.location_code
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
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
      return str_tab_t
   is
      l_locations str_tab_t := str_tab_t() ;
   begin
      get_us_locations( l_locations, p_stream_id, p_station, p_station_unit, p_all_us_locations, p_same_stream_only, p_office_id) ;
      return l_locations;
   end get_us_locations_f;
--------------------------------------------------------------------------------
-- procedure get_ds_locations
--------------------------------------------------------------------------------
   procedure get_ds_locations(
         p_ds_locations out str_tab_t,
         p_stream_id        in varchar2,
         p_station          in binary_double,
         p_station_unit     in varchar2,
         p_all_ds_locations in varchar2 default 'F',
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
   is
      l_office_id   varchar2(16) ;
      l_stream_code number(10) ;
      l_location_codes number_tab_t := number_tab_t() ;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_stream_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS stream identifier.') ;
      end if;
      if p_station is null then
         cwms_err.raise( 'ERROR', 'Station must not be null.') ;
      end if;
      ----------------------------
      -- get the location codes --
      ----------------------------
      l_office_id   := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_stream_code := get_stream_code(l_office_id, p_stream_id) ;
      get_ds_location_codes( l_location_codes, l_stream_code, cwms_util.convert_units(p_station, cwms_util.get_unit_id(p_station_unit), 'km'), cwms_util.is_true(p_all_ds_locations), cwms_util.is_true(p_same_stream_only)) ;
       select bl.base_location_id
         ||substr('-', 1, length(pl.sub_location_id))
         ||pl.sub_location_id bulk collect
         into p_ds_locations
         from table(l_location_codes) lc,
         at_stream_location sl,
         at_physical_location pl,
         at_base_location bl
        where sl.location_code  = lc.column_value
      and pl.location_code      = sl.location_code
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
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
      return str_tab_t
   is
      l_locations str_tab_t := str_tab_t() ;
   begin
      get_ds_locations( l_locations, p_stream_id, p_station, p_station_unit, p_all_ds_locations, p_same_stream_only, p_office_id) ;
      return l_locations;
   end get_ds_locations_f;
--------------------------------------------------------------------------------
-- procedure get_us_locations
--------------------------------------------------------------------------------
   procedure get_us_locations(
         p_us_locations out str_tab_t,
         p_location_id      in varchar2,
         p_all_us_locations in varchar2 default 'F',
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
   is
      l_station binary_double;
      l_stream_code   number(10) ;
      l_location_code number(10) ;
      l_office_id     varchar2(16) ;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS location identifier.') ;
      end if;
      -------------------------------
      -- get the codes and station --
      -------------------------------
      l_office_id     := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id) ;
      begin
          select stream_location_code,
            station
            into l_stream_code,
            l_station
            from at_stream_location
           where location_code = l_location_code;
      exception
      when no_data_found then
         cwms_err.raise( 'ERROR', 'Location ' ||l_office_id ||'/' ||p_location_id ||' is not a stream location') ;
      end;
      -----------------------------
      -- call the base procedure --
      -----------------------------
      get_us_locations( p_us_locations, cwms_loc.get_location_id(l_stream_code), l_station, 'km', p_all_us_locations, p_same_stream_only, l_office_id) ;
   end get_us_locations;
--------------------------------------------------------------------------------
-- funtion get_us_locations_f
--------------------------------------------------------------------------------
   function get_us_locations_f(
         p_location_id      in varchar2,
         p_all_us_locations in varchar2 default 'F',
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
      return str_tab_t
   is
      l_us_locations str_tab_t := str_tab_t() ;
   begin
      get_us_locations( l_us_locations, p_location_id, p_all_us_locations, p_same_stream_only, p_office_id) ;
      return l_us_locations;
   end get_us_locations_f;
--------------------------------------------------------------------------------
-- procedure get_ds_locations
--------------------------------------------------------------------------------
   procedure get_ds_locations(
         p_ds_locations out str_tab_t,
         p_location_id      in varchar2,
         p_all_ds_locations in varchar2 default 'F',
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
   is
      l_station binary_double;
      l_stream_code   number(10) ;
      l_location_code number(10) ;
      l_office_id     varchar2(16) ;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise( 'INVALID_ITEM', '<NULL>', 'CWMS location identifier.') ;
      end if;
      -------------------------------
      -- get the codes and station --
      -------------------------------
      l_office_id     := nvl(upper(p_office_id), cwms_util.user_office_id) ;
      l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id) ;
      begin
          select stream_location_code,
            station
            into l_stream_code,
            l_station
            from at_stream_location
           where location_code = l_location_code;
      exception
      when no_data_found then
         cwms_err.raise( 'ERROR', 'Location ' ||l_office_id ||'/' ||p_location_id ||' is not a stream location') ;
      end;
      -----------------------------
      -- call the base procedure --
      -----------------------------
      get_ds_locations( p_ds_locations, cwms_loc.get_location_id(l_stream_code), l_station, 'km', p_all_ds_locations, p_same_stream_only, l_office_id) ;
   end get_ds_locations;
--------------------------------------------------------------------------------
-- function get_ds_locations_f
--------------------------------------------------------------------------------
   function get_ds_locations_f(
         p_location_id      in varchar2,
         p_all_ds_locations in varchar2 default 'F',
         p_same_stream_only in varchar2 default 'F',
         p_office_id        in varchar2 default null)
      return str_tab_t
   is
      l_ds_locations str_tab_t := str_tab_t() ;
   begin
      get_ds_locations( l_ds_locations, p_location_id, p_all_ds_locations, p_same_stream_only, p_office_id) ;
      return l_ds_locations;
   end get_ds_locations_f;
--------------------------------------------------------------------------------
-- procedure get_us_locations2
--------------------------------------------------------------------------------
   procedure get_us_locations2(
         p_us_locations out sys_refcursor,
         p_stream_id        in varchar,
         p_station          in binary_double,
         p_station_unit     in varchar,
         p_all_us_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
   is
      l_locations str_tab_t;
   begin
      l_locations := get_us_locations_f( p_stream_id, p_station, p_station_unit, p_all_us_locations, p_same_stream_only, p_office_id) ;
      open p_us_locations for select loc.column_value
   as
      location_id,
      cwms_loc.get_location_id(sl.stream_location_code)
   as
      stream_id,
      cwms_util.convert_units(sl.station, 'km', p_station_unit)
   as
      station,
      sl.bank from table(l_locations) loc,
      at_stream_location sl where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value) ;
   end get_us_locations2;
--------------------------------------------------------------------------------
-- function get_us_locations2_f
--------------------------------------------------------------------------------
   function get_us_locations2_f(
         p_stream_id        in varchar,
         p_station          in binary_double,
         p_station_unit     in varchar,
         p_all_us_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
      return sys_refcursor
   is
      l_us_locations sys_refcursor;
   begin
      get_us_locations2( l_us_locations, p_stream_id, p_station, p_station_unit, p_all_us_locations, p_same_stream_only, p_office_id) ;
      return l_us_locations;
   end get_us_locations2_f;
--------------------------------------------------------------------------------
-- procedure get_ds_locations2
--------------------------------------------------------------------------------
   procedure get_ds_locations2(
         p_ds_locations out sys_refcursor,
         p_stream_id        in varchar,
         p_station          in binary_double,
         p_station_unit     in varchar,
         p_all_ds_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
   is
      l_locations str_tab_t;
   begin
      l_locations := get_ds_locations_f( p_stream_id, p_station, p_station_unit, p_all_ds_locations, p_same_stream_only, p_office_id) ;
      open p_ds_locations for select loc.column_value
   as
      location_id,
      cwms_loc.get_location_id(sl.stream_location_code)
   as
      stream_id,
      cwms_util.convert_units(sl.station, 'km', p_station_unit)
   as
      station,
      sl.bank from table(l_locations) loc,
      at_stream_location sl where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value) ;
   end get_ds_locations2;
--------------------------------------------------------------------------------
-- function get_ds_locations2_f
--------------------------------------------------------------------------------
   function get_ds_locations2_f(
         p_stream_id        in varchar,
         p_station          in binary_double,
         p_station_unit     in varchar,
         p_all_ds_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
      return sys_refcursor
   is
      l_ds_locations sys_refcursor;
   begin
      get_ds_locations2( l_ds_locations, p_stream_id, p_station, p_station_unit, p_all_ds_locations, p_same_stream_only, p_office_id) ;
      return l_ds_locations;
   end get_ds_locations2_f;
--------------------------------------------------------------------------------
-- procedure get_us_locations2
--------------------------------------------------------------------------------
   procedure get_us_locations2(
         p_us_locations out sys_refcursor,
         p_location_id      in varchar,
         p_station_unit     in varchar,
         p_all_us_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
   is
      l_locations str_tab_t;
   begin
      l_locations := get_us_locations_f( p_location_id, p_all_us_locations, p_same_stream_only, p_office_id) ;
      open p_us_locations for select loc.column_value
   as
      location_id,
      cwms_loc.get_location_id(sl.stream_location_code)
   as
      stream_id,
      cwms_util.convert_units(sl.station, 'km', p_station_unit)
   as
      station,
      sl.bank from table(l_locations) loc,
      at_stream_location sl where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value) ;
   end get_us_locations2;
--------------------------------------------------------------------------------
-- function get_us_locations2_f
--------------------------------------------------------------------------------
   function get_us_locations2_f(
         p_location_id      in varchar,
         p_station_unit     in varchar,
         p_all_us_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
      return sys_refcursor
   is
      l_us_locations sys_refcursor;
   begin
      get_us_locations2( l_us_locations, p_location_id, p_station_unit, p_all_us_locations, p_same_stream_only, p_office_id) ;
      return l_us_locations;
   end get_us_locations2_f;
--------------------------------------------------------------------------------
-- procedure get_ds_locations2
--------------------------------------------------------------------------------
   procedure get_ds_locations2(
         p_ds_locations out sys_refcursor,
         p_location_id      in varchar,
         p_station_unit     in varchar,
         p_all_ds_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
   is
      l_locations str_tab_t;
   begin
      l_locations := get_ds_locations_f( p_location_id, p_all_ds_locations, p_same_stream_only, p_office_id) ;
      open p_ds_locations for select loc.column_value
   as
      location_id,
      cwms_loc.get_location_id(sl.stream_location_code)
   as
      stream_id,
      cwms_util.convert_units(sl.station, 'km', p_station_unit)
   as
      station,
      sl.bank from table(l_locations) loc,
      at_stream_location sl where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value) ;
   end get_ds_locations2;
--------------------------------------------------------------------------------
-- function get_ds_locations2_f
--------------------------------------------------------------------------------
   function get_ds_locations2_f(
         p_location_id      in varchar,
         p_station_unit     in varchar,
         p_all_ds_locations in varchar default 'F',
         p_same_stream_only in varchar default 'F',
         p_office_id        in varchar default null)
      return sys_refcursor
   is
      l_ds_locations sys_refcursor;
   begin
      get_ds_locations2( l_ds_locations, p_location_id, p_station_unit, p_all_ds_locations, p_same_stream_only, p_office_id) ;
      return l_ds_locations;
   end get_ds_locations2_f;
--------------------------------------------------------------------------------
-- function is_upstream_of
--------------------------------------------------------------------------------
   function is_upstream_of(
         p_stream_id    in varchar2,
         p_station      in binary_double,
         p_station_unit in varchar2,
         p_location_id  in varchar2,
         p_office_id    in varchar2 default null)
      return varchar2
   is
      l_result varchar2(1) ;
      l_location_ids str_tab_t;
      l_count pls_integer;
   begin
      l_location_ids := get_us_locations_f( p_stream_id => p_stream_id, p_station => p_station, p_station_unit => p_station_unit, p_all_us_locations => 'T', p_same_stream_only => 'F', p_office_id => p_office_id) ;
       select count( *)
         into l_count
         from table(l_location_ids)
        where upper(column_value) = upper(p_location_id) ;
      if l_count                  > 0 then
         l_result                := 'T';
      else
         l_result := 'F';
      end if;
      return l_result;
   end is_upstream_of;
--------------------------------------------------------------------------------
-- function is_upstream_of
--------------------------------------------------------------------------------
   function is_upstream_of(
         p_anchor_location_id in varchar2,
         p_location_id        in varchar2,
         p_office_id          in varchar2 default null)
      return varchar2
   is
      l_result varchar2(1) ;
      l_location_ids str_tab_t;
      l_count pls_integer;
   begin
      l_location_ids := get_us_locations_f( p_location_id => p_anchor_location_id, p_all_us_locations => 'T', p_same_stream_only => 'F', p_office_id => p_office_id) ;
       select count( *)
         into l_count
         from table(l_location_ids)
        where upper(column_value) = upper(p_location_id) ;
      if l_count                  > 0 then
         l_result                := 'T';
      else
         l_result := 'F';
      end if;
      return l_result;
   end is_upstream_of;
--------------------------------------------------------------------------------
-- function is_downstream_of
--------------------------------------------------------------------------------
   function is_downstream_of(
         p_stream_id    in varchar2,
         p_station      in binary_double,
         p_station_unit in varchar2,
         p_location_id  in varchar2,
         p_office_id    in varchar2 default null)
      return varchar2
   is
      l_result varchar2(1) ;
      l_location_ids str_tab_t;
      l_count pls_integer;
   begin
      l_location_ids := get_ds_locations_f( p_stream_id => p_stream_id, p_station => p_station, p_station_unit => p_station_unit, p_all_ds_locations => 'T', p_same_stream_only => 'F', p_office_id => p_office_id) ;
       select count( *)
         into l_count
         from table(l_location_ids)
        where upper(column_value) = upper(p_location_id) ;
      if l_count                  > 0 then
         l_result                := 'T';
      else
         l_result := 'F';
      end if;
      return l_result;
   end is_downstream_of;
--------------------------------------------------------------------------------
-- function is_downstream_of
--------------------------------------------------------------------------------
   function is_downstream_of(
         p_anchor_location_id in varchar2,
         p_location_id        in varchar2,
         p_office_id          in varchar2 default null)
      return varchar2
   is
      l_result varchar2(1) ;
      l_location_ids str_tab_t;
      l_count pls_integer;
   begin
      l_location_ids := get_ds_locations_f( p_location_id => p_anchor_location_id, p_all_ds_locations => 'T', p_same_stream_only => 'F', p_office_id => p_office_id) ;
       select count( *)
         into l_count
         from table(l_location_ids)
        where upper(column_value) = upper(p_location_id) ;
      if l_count                  > 0 then
         l_result                := 'T';
      else
         l_result := 'F';
      end if;
      return l_result;
   end is_downstream_of;
--------------------------------------------------------------------------------
-- store_streamflow_meas_xml
--------------------------------------------------------------------------------
   procedure store_streamflow_meas_xml(
         p_xml            in clob,
         p_fail_if_exists in varchar2)
   is
      l_xml xmltype;
      l_xml_tab xml_tab_t;
      l_meas streamflow_meas_t;
   begin
      l_xml := xmltype(p_xml) ;
      case l_xml.getrootelement
      when 'stream-flow-measurement' then
         ------------------------
         -- single measurement --
         ------------------------
         l_meas := streamflow_meas_t(l_xml) ;
         l_meas.store(p_fail_if_exists) ;
      when 'stream-flow-measurements' then
         --------------------------------------
         -- multiple measurements (possibly) --
         --------------------------------------
         l_xml_tab := cwms_util.get_xml_nodes(l_xml, '/*/stream-flow-measurement') ;
         for i in 1..l_xml_tab.count
         loop
            l_meas := streamflow_meas_t(l_xml_tab(i)) ;
            l_meas.store(p_fail_if_exists) ;
         end loop;
      else
         cwms_err.raise( 'ERROR', 'Expected <stream-flow-measurement> or <stream-flow-measurements> as document root, got <'||l_xml.getrootelement||'>') ;
      end case;
   end store_streamflow_meas_xml;
--------------------------------------------------------------------------------
-- function retrieve_streamflow_meas_objs
--------------------------------------------------------------------------------
   function retrieve_streamflow_meas_objs(
         p_location_id_mask in varchar2,
         p_unit_system      in varchar2 default 'EN',
         p_min_date         in date default null,
         p_max_date         in date default null,
         p_min_height       in number default null,
         p_max_height       in number default null,
         p_min_flow         in number default null,
         p_max_flow         in number default null,
         p_min_num          in varchar2 default null,
         p_max_num          in varchar2 default null,
         p_agencies         in varchar2 default null,
         p_qualities        in varchar2 default null,
         p_time_zone        in varchar2 default null,
         p_office_id_mask   in varchar2 default null)
      return streamflow_meas_tab_t
   is
      l_loc_tab number_tab_t;
      l_meas_num_tab str_tab_t;
      l_meas_tab streamflow_meas_tab_t;
      l_location_id_mask varchar2(256) := cwms_util.normalize_wildcards(p_location_id_mask) ;
      l_office_id_mask   varchar2(64)  := cwms_util.normalize_wildcards(p_office_id_mask) ;
      l_height_unit      varchar2(16) ;
      l_flow_unit        varchar2(16) ;
      l_agencies str_tab_t;
      l_qualities str_tab_t;
   begin
      l_height_unit := cwms_util.get_default_units('Stage', upper(trim(p_unit_system))) ;
      l_flow_unit   := cwms_util.get_default_units('Flow', upper(trim(p_unit_system))) ;
      if p_agencies is not null then
          select trim(upper(column_value)) bulk collect
            into l_agencies
            from table(cwms_util.split_text(p_agencies, ',')) ;
         l_agencies.extend;
         l_agencies(l_agencies.count) := '@';
      end if;
      if p_qualities is not null then
          select substr(trim(upper(column_value)), 1, 1) bulk collect
            into l_qualities
            from table(cwms_util.split_text(p_qualities, ',')) ;
         l_qualities.extend;
         l_qualities(l_qualities.count) := '@';
      end if;
      select distinct 
             sm.location_code,
             sm.meas_number bulk collect
             into l_loc_tab,
             l_meas_num_tab
        from at_streamflow_meas sm,
             av_loc2 v2
       where v2.db_office_id like nvl(l_office_id_mask, cwms_util.user_office_id) escape '\'
         and v2.location_id like l_location_id_mask escape '\'
         and sm.location_code = v2.location_code
         and sm.date_time between 
                case
                when p_min_date is null
                then date '1000-01-01'
                when p_time_zone is null
                then cwms_util.change_timezone(p_min_date, cwms_loc.get_local_timezone(sm.location_code), 'UTC')
                else cwms_util.change_timezone(p_min_date, p_time_zone)
                end
             and
                case
                when p_max_date is null
                then date '3000-01-01'
                when p_time_zone is null
                then cwms_util.change_timezone(p_max_date, cwms_loc.get_local_timezone(sm.location_code), 'UTC')
                else cwms_util.change_timezone(p_max_date, p_time_zone)
                end
         and sm.gage_height between
                 case
                 when p_min_height is null
                 then sm.gage_height
                 else cwms_util.convert_units(p_min_height, l_height_unit, 'm')
                 end
              and
                 case
                 when p_max_height is null
                 then sm.gage_height
                 else cwms_util.convert_units(p_max_height, l_height_unit, 'm')
                 end
         and sm.flow between
                case    
                when p_min_flow is null
                then sm.flow
                else cwms_util.convert_units(p_min_flow, l_flow_unit, 'cms')
                end
             and
                case
                when p_max_flow is null
                then sm.flow
                else cwms_util.convert_units(p_max_flow, l_flow_unit, 'cms')
                end
         and sm.meas_number between nvl(p_min_num, sm.meas_number) and nvl(p_max_num, sm.meas_number)
         and nvl(sm.agency_code, 1) in
             (select entity_code
                from at_entity
               where entity_id in 
                     (select *
                        from table(case
                                   when l_agencies is null then str_tab_t(entity_id)
                                   else l_agencies 
                                   end
                                  )
                     )
             )
         and nvl(sm.quality, '@') in
             (select *
                from table(case
                           when l_qualities is not null
                           then l_qualities
                           else str_tab_t(nvl(sm.quality, '@'))
                           end
                          )
             )
       order by 1, 2;
      if l_loc_tab  is not null then
         l_meas_tab := streamflow_meas_tab_t() ;
         l_meas_tab.extend(l_loc_tab.count) ;
         for i in 1..l_loc_tab.count
         loop
            l_meas_tab(i) := streamflow_meas_t(location_ref_t(l_loc_tab(i)), l_meas_num_tab(i)) ;
         end loop;
      end if;
      return l_meas_tab;
   end retrieve_streamflow_meas_objs;
--------------------------------------------------------------------------------
-- function retrieve_streamflow_meas_xml
--------------------------------------------------------------------------------
   function retrieve_streamflow_meas_xml(
         p_location_id_mask in varchar2,
         p_unit_system      in varchar2 default 'EN',
         p_min_date         in date default null,
         p_max_date         in date default null,
         p_min_height       in number default null,
         p_max_height       in number default null,
         p_min_flow         in number default null,
         p_max_flow         in number default null,
         p_min_num          in varchar2 default null,
         p_max_num          in varchar2 default null,
         p_agencies         in varchar2 default null,
         p_qualities        in varchar2 default null,
         p_time_zone        in varchar2 default null,
         p_office_id_mask   in varchar2 default null)
      return clob
   is
      l_clob clob;
      l_meas_tab streamflow_meas_tab_t;
   begin
      l_meas_tab := retrieve_streamflow_meas_objs( p_location_id_mask, p_unit_system, p_min_date, p_max_date, p_min_height, p_max_height, p_min_flow, p_max_flow, p_min_num, p_max_num, p_agencies, p_qualities, p_time_zone, p_office_id_mask) ;
      dbms_lob.createtemporary(l_clob, true) ;
      if l_meas_tab is null or l_meas_tab.count = 0 then
         cwms_util.append(l_clob, '<stream-flow-measurements/>'||chr(10)) ;
      else
         cwms_util.append(l_clob, '<stream-flow-measurements>'||chr(10)) ;
         for i in 1..l_meas_tab.count
         loop
            cwms_util.append(l_clob, l_meas_tab(i) .to_string1||chr(10)) ;
         end loop;
         cwms_util.append(l_clob, '</stream-flow-measurements>'||chr(10)) ;
      end if;
      return l_clob;
   end retrieve_streamflow_meas_xml;
--------------------------------------------------------------------------------
-- procedure delete_streamflow_meas
--------------------------------------------------------------------------------
   procedure delete_streamflow_meas(
         p_location_id_mask in varchar2,
         p_unit_system      in varchar2 default 'EN',
         p_min_date         in date default null,
         p_max_date         in date default null,
         p_min_height       in number default null,
         p_max_height       in number default null,
         p_min_flow         in number default null,
         p_max_flow         in number default null,
         p_min_num          in varchar2 default null,
         p_max_num          in varchar2 default null,
         p_agencies         in varchar2 default null,
         p_qualities        in varchar2 default null,
         p_time_zone        in varchar2 default null,
         p_office_id_mask   in varchar2 default null)
   is
      l_location_id_mask varchar2(256) := cwms_util.normalize_wildcards(p_location_id_mask) ;
      l_office_id_mask   varchar2(64)  := cwms_util.normalize_wildcards(p_office_id_mask) ;
      l_height_unit      varchar2(16) ;
      l_flow_unit        varchar2(16) ;
      l_agencies str_tab_t;
      l_qualities str_tab_t;
      l_time_zone  varchar2(28) ;
      l_min_date   date;
      l_max_date   date;
      l_min_height number;
      l_max_height number;
      l_min_flow   number;
      l_max_flow   number;
   begin
      l_time_zone                                                     := nvl(p_time_zone, 'UTC') ;
      l_min_date                                                      := cwms_util.change_timezone(p_min_date, l_time_zone, 'UTC') ;
      l_max_date                                                      := cwms_util.change_timezone(p_max_date, l_time_zone, 'UTC') ;
      if coalesce(p_min_height, p_max_height, p_min_flow, p_max_flow) is not null then
         l_height_unit                                                := cwms_util.get_default_units('Stage', upper(trim(p_unit_system))) ;
         l_flow_unit                                                  := cwms_util.get_default_units('Flow', upper(trim(p_unit_system))) ;
         l_min_height                                                 := cwms_util.convert_to_db_units(p_min_height, 'Stage', l_height_unit) ;
         l_max_height                                                 := cwms_util.convert_to_db_units(p_max_height, 'Stage', l_height_unit) ;
         l_min_flow                                                   := cwms_util.convert_to_db_units(p_min_flow, 'Flow', l_flow_unit) ;
         l_max_flow                                                   := cwms_util.convert_to_db_units(p_max_flow, 'Flow', l_flow_unit) ;
      end if;
      if p_agencies is null then
          select distinct entity_id bulk collect into l_agencies from at_entity;
      else
          select trim(upper(column_value)) bulk collect
            into l_agencies
            from table(cwms_util.split_text(p_agencies, ',')) ;
      end if;
      if p_qualities is null then
          select qual_id bulk collect into l_qualities from cwms_usgs_meas_qual;
         l_qualities.extend;
         l_qualities(l_qualities.count) := '@';
      else
          select substr(trim(upper(column_value)), 1, 1) bulk collect
            into l_qualities
            from table(cwms_util.split_text(p_qualities, ',')) ;
         l_qualities.extend;
      end if;
       delete
         from at_streamflow_meas
        where rowid in
         (
             select sm.rowid
               from at_streamflow_meas sm,
               av_loc2 v2
              where v2.db_office_id like nvl(l_office_id_mask, cwms_util.user_office_id) escape '\'
            and v2.location_id like l_location_id_mask escape '\'
            and sm.location_code = v2.location_code
            and sm.date_time between nvl(l_min_date, sm.date_time) and nvl(l_max_date, sm.date_time)
            and sm.gage_height between nvl(l_min_height, sm.gage_height) and nvl(l_max_height, sm.gage_height)
            and sm.flow between nvl(l_min_flow, sm.flow) and nvl(l_max_flow, sm.flow)
            and sm.meas_number between nvl(p_min_num, sm.meas_number) and nvl(p_max_num, sm.meas_number)
            and nvl(sm.agency_code, 1) in (select entity_code from at_entity where entity_id in (select * from table(l_agencies)))
            and nvl(sm.quality, '@') in (select * from table(l_qualities))
         ) ;
   end delete_streamflow_meas;
end cwms_stream;
/
show errors;

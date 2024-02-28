create or replace package body cwms_fcst as
--------------------------------------------------------------------------------
-- private function make_blob_id_for_file
--------------------------------------------------------------------------------
function make_blob_id_for_file(
   p_office_id      in varchar2,
   p_fcst_spec_id   in varchar2,
   p_location_id    in varchar2,
   p_fcst_time_utc  in date,
   p_issue_time_utc in date,
   p_file_name      in varchar2)
   return varchar2
is
begin
   return '/fcst/'||p_office_id
      ||'/'||p_fcst_spec_id||'/'||p_location_id
      ||'/'||to_char(p_fcst_time_utc,  'yyyy-mm-dd"T"hh24:mi:ss"Z"')
      ||'/'||to_char(p_issue_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
      ||'/'||p_file_name;
end make_blob_id_for_file;
--------------------------------------------------------------------------------
-- private function get_file_name_ext
--------------------------------------------------------------------------------
function get_file_name_ext(
   p_file_name in varchar2)
   return varchar2
is
begin
   return substr(p_file_name, instr(p_file_name, '.', -1));
end get_file_name_ext;
--------------------------------------------------------------------------------
-- procedure store_fcst_spec
--------------------------------------------------------------------------------
procedure store_fcst_spec(
   p_fcst_spec_id   in varchar2,
   p_location_id    in varchar2,
   p_entity_id      in varchar2,
   p_description    in varchar2 default null,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null)
is
   l_fail_if_exists boolean;
   l_rec            at_fcst_spec%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'); end if;
   if p_location_id  is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id' ); end if;
   if p_entity_id    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Entity_Id'   ); end if;
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   --------------------------------------
   -- retrieve the record if it exists --
   --------------------------------------
   l_rec.office_code   := cwms_util.get_office_code(p_office_id);
   l_rec.fcst_spec_id  := upper(p_fcst_spec_id);
   l_rec.location_code := cwms_loc.get_location_code(l_rec.office_code, p_location_id);
   begin
      select fcst_spec_code
        into l_Rec.fcst_spec_code
        from at_fcst_spec
       where office_code   = l_rec.office_code
         and fcst_spec_id  = l_rec.fcst_spec_id
         and location_code = l_rec.location_code;
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Forecast specification',
            cwms_util.get_db_office_id_from_code(l_rec.office_code)
            ||'/'||l_rec.fcst_spec_id
            ||'/'||p_location_id);
      end if;
   exception
      when no_data_found then null;
   end;
   -----------------------------------------
   -- populate the record from parameters --
   -----------------------------------------
   begin
      select entity_code
        into l_rec.source_entity
        from at_entity
       where office_code in (cwms_util.db_office_code_all, l_rec.office_code)
         and entity_id = upper(p_entity_id);
   exception
      when no_data_found then
         cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Entity', upper(p_entity_id));
   end;
   l_rec.description := p_description;
   -----------------------------
   -- insert or update record --
   -----------------------------
   if l_rec.fcst_spec_code is null then
      l_rec.fcst_spec_code := cwms_seq.nextval;
      insert
        into at_fcst_spec
      values l_rec;
   else
      update at_fcst_spec
         set row = l_rec
       where fcst_spec_code = l_rec.fcst_spec_code;
   end if;

end store_fcst_spec;
--------------------------------------------------------------------------------
-- procedure cat_fcst_spec
--------------------------------------------------------------------------------
procedure cat_fcst_spec(
   p_cursor            out sys_refcursor,
   p_fcst_spec_id_mask in varchar2 default '*',
   p_location_id_mask  in varchar2 default '*',
   p_entity_id_mask    in varchar2 default '*',
   p_office_id_mask    in varchar2 default null)
is
   l_fcst_spec_id_mask at_fcst_spec.fcst_spec_id%type;
   l_location_id_mask  at_cwms_ts_id.location_id%type;
   l_entity_id_mask    at_entity.entity_name%type;
   l_office_id_mask    cwms_office.office_id%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id_mask is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id_Mask'); end if;
   if p_location_id_mask  is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id_Mask' ); end if;
   if p_entity_id_mask    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Entity_Id_Mask'   ); end if;
   -----------------
   -- do the work --
   -----------------
   l_fcst_spec_id_mask := cwms_util.normalize_wildcards(p_fcst_spec_id_mask);
   l_location_id_mask  := cwms_util.normalize_wildcards(p_location_id_mask);
   l_entity_id_mask    := cwms_util.normalize_wildcards(p_entity_id_mask);
   if p_office_id_mask is null then
      l_office_id_mask := cwms_util.user_office_id;
   else
      l_office_id_mask := cwms_util.normalize_wildcards(p_office_id_mask);
   end if;
   -- 1 office_id    varchar2(16)
   -- 2 fcst_spec_id varchar2(32)
   -- 3 location_id  varchar2(57)
   -- 4 entity_id    varchar2(32)
   -- 5 entity_name  varchar2(32)
   -- 6 description  varchar2(64)
   open p_cursor for
      select o.office_id,
             fs.fcst_spec_id,
             bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id as location_id,
             e.entity_id,
             e.entity_name,
             fs.description
        from at_fcst_spec fs,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o,
             at_entity e
       where o.office_code = fs.office_code
         and pl.location_code = fs.location_code
         and bl.base_location_code = pl.base_location_code
         and e.entity_code = fs.source_entity
         and fs.fcst_spec_id like l_fcst_spec_id_mask escape '\'
         and bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id like l_location_id_mask escape '\'
         and (e.entity_id like l_entity_id_mask escape '\' or e.entity_name like l_entity_id_mask escape '\')
         and o.office_id like l_office_id_mask escape '\';
end cat_fcst_spec;
--------------------------------------------------------------------------------
-- function cat_fcst_spec_f
--------------------------------------------------------------------------------
function cat_fcst_spec_f(
   p_fcst_spec_id_mask in varchar2 default '*',
   p_location_id_mask  in varchar2 default '*',
   p_entity_id_mask    in varchar2 default '*',
   p_office_id_mask    in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_fcst_spec(
      p_cursor            => l_cursor,
      p_fcst_spec_id_mask => p_fcst_spec_id_mask,
      p_location_id_mask  => p_location_id_mask,
      p_entity_id_mask    => p_entity_id_mask,
      p_office_id_mask    => p_office_id_mask );
   return l_cursor;
end cat_fcst_spec_f;
--------------------------------------------------------------------------------
-- procedure delete_fcst_spec
--------------------------------------------------------------------------------
procedure delete_fcst_spec(
   p_fcst_spec_id   in varchar2,
   p_location_id    in varchar2,
   p_delete_action  in varchar2,
   p_office_id      in varchar2 default null)
is
   l_office_id      cwms_office.office_id%type;
   l_office_code    cwms_office.office_code%type;
   l_location_code  at_physical_location.location_code%type;
   l_fcst_spec_id   at_fcst_spec.fcst_spec_id%type;
   l_fcst_spec_code at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_code at_fcst_inst.fcst_inst_code%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id  is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id' ); end if;
   if p_location_id   is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'  ); end if;
   if p_delete_action is null then cwms_err.raise('NULL_ARGUMENT', 'P_Delete_Action'); end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
      null;
   else
      cwms_err.raise(
         'ERROR',
         'P_Delete_Action must be one of '
         ||''''||cwms_util.delete_key||''', '
         ||''''||cwms_util.delete_data||''', or '
         ||''''||cwms_util.delete_all||'''');
   end if;
   -----------------
   -- do the work --
   -----------------
   l_fcst_spec_id  := upper(p_fcst_spec_id);
   l_office_code   := cwms_util.get_office_code(p_office_id);
   l_office_id     := cwms_util.get_db_office_id_from_code(l_office_code);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   begin
      select fcst_spec_code
        into l_fcst_spec_code
        from at_fcst_spec
       where office_code = l_office_code
         and fcst_spec_id = l_fcst_spec_id
         and location_code = l_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Forecast specification',
            l_office_id
            ||'/'||l_fcst_spec_id
            ||'/'||p_location_id);
   end;
   if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      -----------------
      -- delete data --
      -----------------
      for rec in (select fcst_date_time,
                         issue_date_time
                    from at_fcst_inst
                   where fcst_spec_code = l_fcst_spec_code
                 )
      loop
         delete_fcst(
            p_fcst_spec_id        => l_fcst_spec_id,
            p_location_id         => p_location_id,
            p_forecast_date_time  => rec.fcst_date_time,
            p_issue_date_time     => rec.issue_date_time,
            p_time_zone           => 'UTC',
            p_office_id           => l_office_id);
      end loop;
   end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      ----------------
      -- delete key --
      ----------------
      delete
        from at_fcst_spec
       where fcst_spec_code = l_fcst_spec_code;
   end if;
end delete_fcst_spec;
--------------------------------------------------------------------------------
-- procedure store_fcst
--------------------------------------------------------------------------------
procedure store_fcst(
   p_fcst_spec_id       in varchar2,
   p_location_id        in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2          default null,
   p_max_age            in binary_integer    default null,
   p_notes              in varchar2          default null,
   p_time_series        in ztimeseries_array default null,
   p_files              in fcst_file_tab_t   default null,
   p_fail_if_exists     in varchar2          default 'T',
   p_office_id          in varchar2          default null)
is
   type ts_time_window_t is table of date2_t index by varchar2(32767);
   type file_names_t is table of boolean index by varchar2(32767);
   type key_value_t is table of varchar2(64) index by varchar2(32);
   l_fcst_spec_id    at_fcst_spec.fcst_spec_id%type;
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_office_id       cwms_office.office_id%type;
   l_office_code     cwms_office.office_code%type;
   l_location_id     at_cwms_ts_id.location_id%type;
   l_location_code   at_cwms_ts_id.location_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
   l_fail_if_exists  boolean;
   l_fcst_inst_rec   at_fcst_inst%rowtype;
   l_ts_time_windows ts_time_window_t;
   l_ts_id           at_cwms_ts_id.cwms_ts_id%type;
   l_file_names      file_names_t;
   l_code            number(14);
   l_blob_id         at_blob.id%type;
   l_nodes           xml_tab_t;
   l_key_value_pairs key_value_t;
   l_key             varchar2(32);
   l_value           varchar2(64);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_location_id        is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'       ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if (p_time_series is null or p_time_series.count = 0) and (p_files is null or p_files.count = 0) then
      cwms_err.raise('ERROR', 'Cannot store forecast without at least one time series or one file');
   end if;
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   if p_files is not null then
      for i in 1..p_files.count loop
         if p_files(i).file_name is null then
            cwms_err.raise('ERROR', 'Forecast file name must not be null');
         elsif instr(p_files(i).file_name, '.', -1) = 0 then
            cwms_err.raise('ERROR', 'Forecast file name ('||p_files(i).file_name||') must must have an extension');
         end if;
      end loop;
   end if;
   -------------------------
   -- get the spec record --
   -------------------------
   l_fcst_spec_id  := upper(p_fcst_spec_id);
   l_office_code   := cwms_util.get_office_code(p_office_id);
   l_office_id     := cwms_util.get_db_office_id_from_code(l_office_code);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   l_location_id   := cwms_loc.get_location_id(l_location_code);
   begin
      select fcst_spec_code
        into l_fcst_spec_code
        from at_fcst_spec
       where office_code = l_office_code
         and fcst_spec_id = l_fcst_spec_id
         and location_code = l_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Forecast specification',
            l_office_id
            ||'/'||l_fcst_spec_id
            ||'/'||l_location_id);
   end;
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   if p_time_zone in ('UTC', 'GMT') then
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_time_zone_id := nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code));
      if l_time_zone_id is null then
         cwms_err.raise(
            'ERROR',
            'P_Time_Zone is NULL and location '
            ||l_office_id||'/'||l_location_id
            ||' doesn''t have a time zone');
      end if;
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   ---------------------------------------
   -- get or create the instance record --
   ---------------------------------------
   begin
      select *
        into l_fcst_inst_rec
        from at_fcst_inst
       where fcst_spec_code = l_fcst_spec_code
         and fcst_date_time = l_fcst_time_utc
         and issue_date_time = l_issue_time_utc;
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Forecast instance',
            l_office_id||'/'||l_fcst_spec_id||'/'||l_location_id
            ||'/'||to_char(l_fcst_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
            ||'/'||to_char(l_issue_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"'));
      end if;
   exception
      when no_data_found then
         l_fcst_inst_rec.fcst_spec_code  := l_fcst_spec_code;
         l_fcst_inst_rec.fcst_date_time  := l_fcst_time_utc;
         l_fcst_inst_rec.issue_date_time := l_issue_time_utc;
   end;
   -------------------------------------
   -- populate instance record fields --
   -------------------------------------
   l_fcst_inst_rec.max_age := nvl(p_max_age, l_fcst_inst_rec.max_age);
   l_fcst_inst_rec.notes   := nvl(p_notes, l_fcst_inst_rec.notes);
   if l_fcst_inst_rec.fcst_inst_code is not null then
      ---------------------------
      -- collect existing info --
      ---------------------------
      for rec in (select cwms_ts_id,
                         ts_code
                    from at_cwms_ts_id
                   where ts_code in (select ts_code
                                       from at_fcst_time_series
                                      where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code
                                    )
                 )
      loop
         select date2_t(min(date_time),max(date_time))
           into l_ts_time_windows(rec.cwms_ts_id)
           from av_tsv
          where ts_code = rec.ts_code
            and version_date = l_issue_time_utc
            and start_date <= l_fcst_inst_rec.first_date_time
            and end_date > l_fcst_inst_rec.first_date_time;
      end loop;
      for rec in (select file_name
                    from at_fcst_file
                   where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code
                 )
      loop
         l_file_names(rec.file_name) := true;
      end loop;
   end if;
   if p_time_series is not null and p_time_series.count > 0 then
      -----------------------------------
      -- merge in new time seires info --
      -----------------------------------
      for i in 1..p_time_series.count loop
         l_ts_time_windows(p_time_series(i).tsid) := date2_t(
            p_time_series(i).data(1).date_time,
            p_time_series(i).data(p_time_series(i).data.count).date_time);
      end loop;
      l_ts_id := l_ts_time_windows.first;
      while l_ts_id is not null loop
         if l_fcst_inst_rec.first_date_time is null or l_ts_time_windows(l_ts_id).date_1 < l_fcst_inst_rec.first_date_time then
            l_fcst_inst_rec.first_date_time := l_ts_time_windows(l_ts_id).date_1;
         end if;
         if l_fcst_inst_rec.last_date_time is null or l_ts_time_windows(l_ts_id).date_2 > l_fcst_inst_rec.last_date_time then
            l_fcst_inst_rec.last_date_time := l_ts_time_windows(l_ts_id).date_2;
         end if;
         l_ts_id := l_ts_time_windows.next(l_ts_id);
      end loop;
   end if;
   l_fcst_inst_rec.time_series_count := l_ts_time_windows.count;
   if p_files is not null and p_files.count > 0 then
      -----------------------------
      -- merge in new files info --
      -----------------------------
      for i in 1..p_files.count loop
         l_file_names(p_files(i).file_name) := true;

         if p_files(i).file_name = c_forecast_info_filename then
            ------------------------------------------------------------------------
            -- update the key count and save the (key, value) pairs for later use --
            ------------------------------------------------------------------------
            l_fcst_inst_rec.key_count := 0;
            l_nodes := cwms_util.get_xml_nodes(xmltype(utl_raw.cast_to_varchar2(p_files(i).file_data)), '/*/*');
            for j in 1..l_nodes.count loop
               if cwms_util.get_xml_text(l_nodes(j), '/*/@key') = 'true' then
                  l_key := l_nodes(j).getrootelement;
                  l_value := cwms_util.get_xml_text(l_nodes(j), '/*');
                  l_key_value_pairs(l_key) := l_value;
                  l_fcst_inst_rec.key_count := l_fcst_inst_rec.key_count + 1;
               end if;
            end loop;
         end if;
      end loop;
   end if;
   l_fcst_inst_rec.file_count := l_file_names.count;
   -------------------------------
   -- store the instance record --
   -------------------------------
   if l_fcst_inst_rec.fcst_inst_code is null then
      l_fcst_inst_rec.fcst_inst_code := cwms_seq.nextval;
      insert
        into at_fcst_inst
      values l_fcst_inst_rec;
   else
      update at_fcst_inst
         set row = l_fcst_inst_rec
       where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;
   end if;
   ---------------------------
   -- store the time series --
   ---------------------------
   if p_time_series is not null then
      for i in 1..p_time_series.count loop
         cwms_ts.zstore_ts(
            p_cwms_ts_id      => p_time_series(i).tsid,
            p_units           => p_time_series(i).unit,
            p_timeseries_data => p_time_series(i).data,
            p_store_rule      => cwms_util.replace_all,
            p_version_date    => l_issue_time_utc,
            p_office_id       => l_office_id);

         select ts_code
           into l_code
           from at_cwms_ts_id
          where db_office_code = l_office_code
            and cwms_ts_id = p_time_series(i).tsid;

         begin
            insert
              into at_fcst_time_series
            values (l_fcst_inst_rec.fcst_inst_code, l_code);
         exception
            when others then
               if sqlcode = -1 then
                  null; -- alredy existed
               else
                  raise;
               end if;
         end;
      end loop;
   end if;
   ---------------------
   -- store the files --
   ---------------------
   if p_files is not null then
      for i in 1..p_files.count loop
         l_blob_id := make_blob_id_for_file(
            l_office_id,
            l_fcst_spec_id,
            l_location_id,
            l_fcst_time_utc,
            l_issue_time_utc,
            p_files(i).file_name);

         cwms_text.store_binary(
            p_binary_code       => l_code,
            p_binary            => p_files(i).file_data,
            p_id                => l_blob_id,
            p_media_type_or_ext => get_file_name_ext(p_files(i).file_name),
            p_description       => p_files(i).description,
            p_fail_if_exists    => 'F',
            p_office_id         => l_office_id);

         begin
            insert
              into at_fcst_file
            values (l_fcst_inst_rec.fcst_inst_code, l_code, p_files(i).file_name, p_files(i).description);
         exception
            when others then
               if sqlcode = -1 then
                  null; -- alredy existed
               else
                  raise;
               end if;
         end;
      end loop;
   end if;
   ---------------------------------------------------------------
   -- update at_fcst_info table and key_count for this instance --
   ---------------------------------------------------------------
   l_key := l_key_value_pairs.first;
   while l_key is not null loop
      merge into at_fcst_info t
      using (select l_fcst_inst_rec.fcst_inst_code as fcst_inst_code, l_key as key from dual) d
         on (t.fcst_inst_code = d.fcst_inst_code and t.key = d.key)
      when matched then
           update set value = l_key_value_pairs(l_key)
      when not matched then
           insert values (l_fcst_inst_rec.fcst_inst_code, l_key, l_key_value_pairs(l_key));
      l_key := l_key_value_pairs.next(l_key);
   end loop;
end store_fcst;
--------------------------------------------------------------------------------
-- procedure cat_fcst
--------------------------------------------------------------------------------
procedure cat_fcst(
   p_cursor                 out sys_refcursor,
   p_fcst_spec_id_mask      in varchar2 default '*',
   p_location_id_mask       in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default null,
   p_valid_forecasts_only   in varchar2 default 'F',
   p_key_mask               in varchar2 default '*',
   p_value_mask             in varchar2 default '*',
   p_office_id_mask         in varchar2 default null)
is
   l_fcst_spec_id_mask   at_fcst_spec.fcst_spec_id%type;
   l_location_id_mask    at_cwms_ts_id.location_id%type;
   l_office_id_mask      cwms_office.office_id%type;
   l_time_zone           cwms_time_zone.time_zone_name%type;
   l_null_crsr           sys_refcursor;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id_mask is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id_Mask'); end if;
   if p_location_id_mask  is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id_Mask' ); end if;
   if p_key_mask          is null then cwms_err.raise('NULL_ARGUMENT', 'P_Key_Mask' );         end if;
   if p_value_mask        is null then cwms_err.raise('NULL_ARGUMENT', 'P_Value_Mask' );       end if;
   if p_valid_forecasts_only not in ('T', 'F') then
      cwms_err.raise('INVALID_T_F_FLAG', p_valid_forecasts_only);
   end if;
   -----------------
   -- do the work --
   -----------------
   l_fcst_spec_id_mask := cwms_util.normalize_wildcards(p_fcst_spec_id_mask);
   l_location_id_mask  := cwms_util.normalize_wildcards(p_location_id_mask);
   if p_office_id_mask is null then
      l_office_id_mask := cwms_util.user_office_id;
   else
      l_office_id_mask := cwms_util.normalize_wildcards(p_office_id_mask);
   end if;
   if p_time_zone is not null then
      l_time_zone := cwms_util.get_timezone(p_time_zone);
   end if;
   --  1 office_id        varchar2(16)
   --  2 fcst_spec_id     varchar2(32)
   --  3 location_id      varchar2(57)
   --  4 time_zone        varchar2(28)
   --  5 fcst_date_time   date
   --  6 issue_date_time  date
   --  7 first_date_time  date
   --  8 last_date_time   date
   --  9 max_age          number(6)
   -- 10 valid            varchar2(1)
   -- 11 notes            varchar2(256)
   -- 12 time_sereies_ids sys_refcursor   12.1 cwms_ts_id varchar2(193)
   -- 13 file_names       sys_refcursor   13.1 file_name varchar2(64)
   --                                     13.2 description varchar2(64)
   -- 14 key_value_pairs  sys_refcursor   14.1 key varchar2(32)
   --                                     14.2 value varchar2(64)
   open p_cursor for
      select
         o.office_id,
         fs.fcst_spec_id,
         bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id as location_id,
         case
         when l_time_zone is null then
            tz.time_zone_name
         else
            l_time_zone
         end as time_zone,
         case
         when l_time_zone is null then
            cwms_util.change_timezone(fi.fcst_date_time, 'UTC', tz.time_zone_name)
         when l_time_zone in ('UTC', 'GMT') then
            fi.fcst_date_time
         else
            cwms_util.change_timezone(fi.fcst_date_time, 'UTC', l_time_zone)
         end as fcst_date_time,
         case
         when l_time_zone is null then
            cwms_util.change_timezone(fi.issue_date_time, 'UTC', tz.time_zone_name)
         when l_time_zone in ('UTC', 'GMT') then
            fi.issue_date_time
         else
            cwms_util.change_timezone(fi.issue_date_time, 'UTC', l_time_zone)
         end as issue_date_time,
         case
         when l_time_zone is null then
            cwms_util.change_timezone(fi.first_date_time, 'UTC', tz.time_zone_name)
         when l_time_zone in ('UTC', 'GMT') then
            fi.first_date_time
         else
            cwms_util.change_timezone(fi.first_date_time, 'UTC', l_time_zone)
         end as first_date_time,
         case
         when l_time_zone is null then
            cwms_util.change_timezone(fi.last_date_time, 'UTC', tz.time_zone_name)
         when l_time_zone in ('UTC', 'GMT') then
            fi.last_date_time
         else
            cwms_util.change_timezone(fi.last_date_time, 'UTC', l_time_zone)
         end as last_date_time,
         fi.max_age,
         case
            when (sysdate - fi.issue_date_time) * 24 > fi.max_age then 'F'
            else 'T'
         end as valid,
         fi.notes,
         cursor (select tsid.cwms_ts_id
                   from at_cwms_ts_id tsid,
                        at_fcst_time_series fts
                  where fts.fcst_inst_code = fi.fcst_inst_code
                    and tsid.ts_code = fts.ts_code
                  order by 1
                ) as time_sereies_ids,
         cursor (select file_name,
                        description
                   from at_fcst_file ff
                  where ff.fcst_inst_code = fi.fcst_inst_code
                  order by 1
                ) as file_names,
         cursor (select key,
                        value
                   from at_fcst_info info
                  where info.fcst_inst_code = fi.fcst_inst_code
                    and key like cwms_util.normalize_wildcards(p_key_mask) escape '\'
                    and value like cwms_util.normalize_wildcards(p_value_mask) escape '\'
                ) as key_value_pairs
      from
         at_fcst_spec fs,
         at_physical_location pl,
         at_base_location bl,
         cwms_office o,
         at_fcst_inst fi,
         cwms_time_zone tz
      where
         o.office_code = fs.office_code
         and pl.location_code = fs.location_code
         and bl.base_location_code = pl.base_location_code
         and fs.fcst_spec_id like l_fcst_spec_id_mask escape '\'
         and bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id like l_location_id_mask escape '\'
         and o.office_id like l_office_id_mask escape '\'
         and tz.time_zone_code = pl.time_zone_code
         and fi.fcst_spec_code = fs.fcst_spec_code
         and (p_min_forecast_date_time is null or fi.fcst_date_time >= cwms_util.change_timezone(p_min_forecast_date_time, nvl(l_time_zone, 'UTC'), 'UTC'))
         and (p_max_forecast_date_time is null or fi.fcst_date_time <= cwms_util.change_timezone(p_max_forecast_date_time, nvl(l_time_zone, 'UTC'), 'UTC'))
         and (p_min_issue_date_time is null or fi.issue_date_time >= cwms_util.change_timezone(p_min_issue_date_time, nvl(l_time_zone, 'UTC'), 'UTC'))
         and (p_max_issue_date_time is null or fi.issue_date_time <= cwms_util.change_timezone(p_max_issue_date_time, nvl(l_time_zone, 'UTC'), 'UTC'))
         and (p_valid_forecasts_only = 'F' or (sysdate - fi.issue_date_time) * 24 <= fi.max_age)
      order by
         o.office_id,
         fs.fcst_spec_id,
         bl.base_location_id||substr('-',1,length(pl.sub_location_id))||pl.sub_location_id,
         fi.fcst_date_time,
         fi.issue_date_time;
end cat_fcst;
--------------------------------------------------------------------------------
-- function cat_fcst_f
--------------------------------------------------------------------------------
function cat_fcst_f(
   p_fcst_spec_id_mask      in varchar2 default '*',
   p_location_id_mask       in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default null,
   p_valid_forecasts_only   in varchar2 default 'F',
   p_key_mask               in varchar2 default '*',
   p_value_mask             in varchar2 default '*',
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_fcst(
      p_cursor                 => l_cursor,
      p_fcst_spec_id_mask      => p_fcst_spec_id_mask,
      p_location_id_mask       => p_location_id_mask,
      p_min_forecast_date_time => p_min_forecast_date_time,
      p_max_forecast_date_time => p_max_forecast_date_time,
      p_min_issue_date_time    => p_min_issue_date_time,
      p_max_issue_date_time    => p_max_issue_date_time,
      p_time_zone              => p_time_zone,
      p_valid_forecasts_only   => p_valid_forecasts_only,
      p_key_mask               => p_key_mask,
      p_value_mask             => p_value_mask,
      p_office_id_mask         => p_office_id_mask);
   return l_cursor;
end cat_fcst_f;
--------------------------------------------------------------------------------
-- procedure retrieve_fcst
--------------------------------------------------------------------------------
procedure retrieve_fcst(
   p_time_series_out    out nocopy ztimeseries_array,
   p_files_out          out nocopy fcst_file_tab_t,
   p_fcst_spec_id       in varchar2,
   p_location_id        in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2 default null,
   p_unit_system        in varchar2 default 'SI',
   p_ts_id_mask         in varchar2 default '*',
   p_file_name_mask     in varchar2 default '*',
   p_office_id          in varchar2 default null)
is
   l_time_series_out ztimeseries_array;
   l_files_out       fcst_file_tab_t;
   l_office_id       cwms_office.office_id%type;
   l_office_code     cwms_office.office_code%type;
   l_location_id     at_cwms_ts_id.location_id%type;
   l_location_code   at_physical_location.location_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
   l_fcst_spec_id    at_fcst_spec.fcst_spec_id%type;
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_rec   at_fcst_inst%rowtype;
   l_crsr            sys_refcursor;
   l_date_times      date_table_type;
   l_values          double_tab_t;
   l_quality_codes   number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_location_id        is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'       ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if p_unit_system in ('EN', 'SI') then
      null;
   else
      cwms_err.raise('ERROR', 'P_Unit_System ('||nvl(p_unit_system, '<NULL>')||') must be ''EN'' or ''SI''');
   end if;
   if p_ts_id_mask is null and p_file_name_mask is null then
      cwms_err.raise('ERROR', 'P_Ts_Id_Mask and P_File_Name_Mask may not both be null');
   end if;
   -----------------
   -- do the work --
   -----------------
   l_fcst_spec_id  := upper(p_fcst_spec_id);
   l_office_code   := cwms_util.get_office_code(p_office_id);
   l_office_id     := cwms_util.get_db_office_id_from_code(l_office_code);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   l_location_id   := cwms_loc.get_location_id(l_location_code);
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   if p_time_zone in ('UTC', 'GMT') then
      l_time_zone_id := 'UTC';
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_time_zone_id := nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code));
      if l_time_zone_id is null then
         cwms_err.raise(
            'ERROR',
            'P_Time_Zone is NULL and location '
            ||l_office_id||'/'||l_location_id
            ||' doesn''t have a time zone');
      end if;
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   --------------------------
   -- get the forcast spec --
   --------------------------
   begin
      select fcst_spec_code
        into l_fcst_spec_code
        from at_fcst_spec
       where office_code = l_office_code
         and fcst_spec_id = l_fcst_spec_id
         and location_code = l_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Forecast specification',
            l_office_id
            ||'/'||l_fcst_spec_id
            ||'/'||p_location_id);
   end;
   ---------------------------
   -- get the forecast inst --
   ---------------------------
   begin
      select *
        into l_fcst_inst_rec
        from at_fcst_inst
       where fcst_spec_code = l_fcst_spec_code
         and fcst_date_time = l_fcst_time_utc
         and issue_date_time = l_issue_time_utc;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Forecast instance',
            l_office_id||'/'||l_fcst_spec_id||'/'||l_location_id
            ||'/'||to_char(l_fcst_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
            ||'/'||to_char(l_issue_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"'));
   end;
   ------------------------------
   -- retrieve the time series --
   ------------------------------
   if p_ts_id_mask is not null then
      l_time_series_out := ztimeseries_array();
      for rec in (select tsid.cwms_ts_id,
                         parameter_id
                    from at_cwms_ts_id tsid,
                         at_fcst_time_series fts
                   where fts.fcst_inst_code = l_fcst_inst_rec.fcst_inst_code
                     and tsid.ts_code = fts.ts_code
                     and tsid.cwms_ts_id like cwms_util.normalize_wildcards(p_ts_id_mask) escape '\'
                   order by 1
                 )
      loop
         cwms_ts.retrieve_ts(
            p_at_tsv_rc    => l_crsr,
            p_cwms_ts_id   => rec.cwms_ts_id,
            p_units        => cwms_util.get_default_units(rec.parameter_id, p_unit_system),
            p_start_time   => cwms_util.change_timezone(l_fcst_inst_rec.first_date_time, 'UTC', l_time_zone_id),
            p_end_time     => cwms_util.change_timezone(l_fcst_inst_rec.last_date_time, 'UTC', l_time_zone_id),
            p_time_zone    => l_time_zone_id,
            p_trim         => 'T',
            p_version_date => l_fcst_inst_rec.issue_date_time,
            p_office_id    => l_office_id);
         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes;
         close l_crsr;
         l_time_series_out.extend;
         l_time_series_out(l_time_series_out.count) := ztimeseries_type(rec.cwms_ts_id, cwms_util.get_default_units(rec.parameter_id, p_unit_system), ztsv_array());
         l_time_series_out(l_time_series_out.count).data.extend(l_date_times.count);
         for i in 1..l_time_series_out(l_time_series_out.count).data.count loop
            l_time_series_out(l_time_series_out.count).data(i) := ztsv_type(
               l_date_times(i),
               l_values(i),
               l_quality_codes(i));
         end loop;
      end loop;
   end if;
   ------------------------
   -- retrieve the files --
   ------------------------
   if p_file_name_mask is not null then
      l_files_out := fcst_file_tab_t();
      for rec in (select blob_code,
                         file_name,
                         description
                    from at_fcst_file
                   where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code
                     and file_name like cwms_util.normalize_wildcards(p_file_name_mask) escape '\'
                   order by 1
                 )
      loop
         l_files_out.extend;
         l_files_out(l_files_out.count) := fcst_file_t(rec.file_name, rec.description, null);
         select value
           into l_files_out(l_files_out.count).file_data
           from at_blob
          where blob_code = rec.blob_code;
      end loop;
   end if;
   ---------------------------
   -- assign out parameters --
   ---------------------------
   p_time_series_out := l_time_series_out;
   p_files_out := l_files_out;
end retrieve_fcst;
--------------------------------------------------------------------------------
-- procedure delete_fcst
--------------------------------------------------------------------------------
procedure delete_fcst(
   p_fcst_spec_id        in varchar2,
   p_location_id         in varchar2,
   p_forecast_date_time  in date,
   p_issue_date_time     in date,
   p_time_zone           in varchar2 default null,
   p_ts_id_mask          in varchar2 default '*',
   p_file_name_mask      in varchar2 default '*',
   p_office_id           in varchar2 default null)
is
   l_office_id       cwms_office.office_id%type;
   l_office_code     cwms_office.office_code%type;
   l_location_id     at_cwms_ts_id.location_id%type;
   l_location_code   at_physical_location.location_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
   l_fcst_spec_id    at_fcst_spec.fcst_spec_id%type;
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_rec   at_fcst_inst%rowtype;
   l_min_date_time   date;
   l_max_date_time   date;
   l_blob_codes      number_tab_t;
   l_file_names      str_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_location_id        is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'       ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if p_ts_id_mask is null and p_file_name_mask is null then
      cwms_err.raise('ERROR', 'P_Ts_Id_Mask and P_File_Name_Mask may not both be null');
   end if;
   -----------------
   -- do the work --
   -----------------
   l_fcst_spec_id  := upper(p_fcst_spec_id);
   l_office_code   := cwms_util.get_office_code(p_office_id);
   l_office_id     := cwms_util.get_db_office_id_from_code(l_office_code);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   l_location_id   := cwms_loc.get_location_id(l_location_code);
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   if p_time_zone in ('UTC', 'GMT') then
      l_time_zone_id := 'UTC';
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_time_zone_id := nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code));
      if l_time_zone_id is null then
         cwms_err.raise(
            'ERROR',
            'P_Time_Zone is NULL and location '
            ||l_office_id||'/'||l_location_id
            ||' doesn''t have a time zone');
      end if;
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   --------------------------
   -- get the forcast spec --
   --------------------------
   begin
      select fcst_spec_code
        into l_fcst_spec_code
        from at_fcst_spec
       where office_code = l_office_code
         and fcst_spec_id = l_fcst_spec_id
         and location_code = l_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Forecast specification',
            l_office_id
            ||'/'||l_fcst_spec_id
            ||'/'||p_location_id);
   end;
   ---------------------------
   -- get the forecast inst --
   ---------------------------
   begin
      select *
        into l_fcst_inst_rec
        from at_fcst_inst
       where fcst_spec_code = l_fcst_spec_code
         and fcst_date_time = l_fcst_time_utc
         and issue_date_time = l_issue_time_utc;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Forecast instance',
            l_office_id||'/'||l_fcst_spec_id||'/'||l_location_id
            ||'/'||to_char(l_fcst_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
            ||'/'||to_char(l_issue_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"'));
   end;
   --------------------------------------
   -- delete the time series and files --
   --------------------------------------
   if p_ts_id_mask is not null then
      ------------------------
      -- delete time series --
      ------------------------
      for rec in (select fts.ts_code,
                         tsid.cwms_ts_id
                    from at_fcst_time_series fts,
                         at_cwms_ts_id tsid
                   where fts.fcst_inst_code = l_fcst_inst_rec.fcst_inst_code
                     and tsid.ts_code = fts.ts_code
                     and tsid.cwms_ts_id like cwms_util.normalize_wildcards(p_ts_id_mask) escape '\'
                 )
      loop
         cwms_ts.purge_ts_data(
            p_ts_code             => rec.ts_code,
            p_override_protection => 'ERROR',
            p_version_date_utc    => l_fcst_inst_rec.issue_date_time,
            p_start_time_utc      => l_fcst_inst_rec.first_date_time,
            p_end_time_utc        => l_fcst_inst_rec.last_date_time,
            p_ts_item_mask        => cwms_util.ts_all);
         delete from at_fcst_time_series where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code and ts_code = rec.ts_code;
      end loop;
   end if;
   if p_file_name_mask is not null then
      ------------------
      -- delete files --
      ------------------
      select blob_code,
             file_name
        bulk collect
        into l_blob_codes,
             l_file_names
        from at_fcst_file
       where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code
         and file_name like cwms_util.normalize_wildcards(p_file_name_mask) escape '\';
      for i in 1..l_blob_codes.count loop
         delete from at_fcst_file where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code and blob_code = l_blob_codes(i);
         delete from at_blob where blob_code = l_blob_codes(i);
         if l_file_names(i) = c_forecast_info_filename then
            delete from at_fcst_info where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;
            l_fcst_inst_rec.key_count := 0;
         end if;
      end loop;
   end if;
   -----------------------------
   -- update time series info --
   -----------------------------
   l_fcst_inst_rec.time_series_count := 0;
   l_min_date_time := l_fcst_inst_rec.first_date_time;
   l_max_date_time := l_fcst_inst_rec.last_date_time;
   for rec in (select * from at_fcst_time_series where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code) loop
      begin
         for rec2 in (select min(date_time) as min_date_time,
                             max(date_time) as max_date_time
                        from av_tsv
                       where ts_code = rec.ts_code
                         and version_date = l_fcst_inst_rec.issue_date_time
                         and start_date <= l_fcst_inst_rec.first_date_time
                         and end_date > l_fcst_inst_rec.last_date_time
                      )
         loop
            if l_min_date_time is not null then
               l_fcst_inst_rec.time_series_count := l_fcst_inst_rec.time_series_count + 1;
               l_min_date_time := least(l_min_date_time, rec2.min_date_time);
               l_max_date_time := greatest(l_max_date_time, rec2.max_date_time);
            end if;
         end loop;
      exception
         when no_data_found then null;
      end;
   end loop;
   l_fcst_inst_rec.first_date_time := l_min_date_time;
   l_fcst_inst_rec.last_date_time := l_max_date_time;
   select count(*)
     into l_fcst_inst_rec.time_series_count
     from at_fcst_time_series
    where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;
   ---------------------------
   -- update the file count --
   ---------------------------
   select count(*)
     into l_fcst_inst_rec.file_count
     from at_fcst_file
    where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;

   if l_fcst_inst_rec.time_series_count = 0 and l_fcst_inst_rec.file_count = 0 then
      ---------------------------
      -- delete empty instance --
      ---------------------------
      delete from at_fcst_inst where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;
   else
      -----------------
      -- update info --
      -----------------
      update at_fcst_inst
         set row = l_fcst_inst_rec
       where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;
   end if;
end delete_fcst;

end;
/

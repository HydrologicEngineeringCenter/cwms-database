create or replace package body cwms_fcst as
--------------------------------------------------------------------------------
-- private function get_fcst_spec_code
--------------------------------------------------------------------------------
function get_fcst_spec_code(
   p_office_code     in cwms_office.office_code%type,
   p_fcst_spec_id    in varchar2,
   p_fcst_designator in varchar2,
   p_error_if_null   in varchar2)
   return at_fcst_spec.fcst_spec_code%type
is
   l_fcst_spec_code at_fcst_spec.fcst_spec_code%type;
   l_office_id      cwms_office.office_id%type;
begin
   begin
      select fcst_spec_code
        into l_fcst_spec_code
        from at_fcst_spec
       where office_code = p_office_code
         and upper(fcst_spec_id) = upper(p_fcst_spec_id)
         and upper(nvl(fcst_designator, '~')) = upper(nvl(p_fcst_designator, '~'));
   exception
      when no_data_found then
         if p_error_if_null = 'T' then
            select office_id into l_office_id from cwms_office where office_code = p_office_code;
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Forecast specification',
               l_office_id
               ||'/'||p_fcst_spec_id
               ||'/'||p_fcst_designator);
         end if;
   end;
   return l_fcst_spec_code;
end;
--------------------------------------------------------------------------------
-- private function get_fcst_inst_code
--------------------------------------------------------------------------------
function get_fcst_inst_code(
   p_fcst_spec_code at_fcst_spec.fcst_spec_code%type,
   p_fcst_time_utc  date,
   p_issue_time_utc date,
   p_error_if_null  varchar2)
   return at_fcst_inst.fcst_inst_code%type
is
   l_fcst_inst_code  at_fcst_inst.fcst_inst_code%type;
   l_fcst_spec_id    at_fcst_spec.fcst_spec_id%type;
   l_fcst_designator at_fcst_spec.fcst_designator%type;
   l_office_id       cwms_office.office_id%type;
begin
   begin
      select fcst_inst_code
        into l_fcst_inst_code
        from at_fcst_inst
       where fcst_spec_code = p_fcst_spec_code
         and fcst_date_time = p_fcst_time_utc
         and issue_date_time = p_issue_time_utc;
   exception
      when no_data_found then
         if p_error_if_null = 'T' then
            select
               fs.fcst_spec_id,
               fs.fcst_designator,
               o.office_id
            into
               l_fcst_spec_id,
               l_fcst_designator,
               l_office_id
            from
               at_fcst_spec fs,
               cwms_office o
            where
               fs.fcst_spec_code = p_fcst_spec_code
               and o.office_code = fs.office_code;
            cwms_err.raise(
               'ITEM_DOES_NOT_EXISTS',
               'Forecast instance',
               l_office_id||'/'||l_fcst_spec_id||'/'||l_fcst_designator
               ||'/'||to_char(p_fcst_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
               ||'/'||to_char(p_issue_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"'));
         end if;
   end;
   return l_fcst_inst_code;
end get_fcst_inst_code;
--------------------------------------------------------------------------------
-- procedure store_fcst_spec
--------------------------------------------------------------------------------
procedure store_fcst_spec(
   p_fcst_spec_id    in varchar2,
   p_fcst_designator in varchar2,
   p_entity_id       in varchar2,
   p_description     in varchar2 default null,
   p_location_id     in varchar2 default null,
   p_timeseries_ids  in clob     default null,
   p_fail_if_exists  in varchar2 default 'T',
   p_ignore_nulls    in varchar2 default 'T',
   p_office_id       in varchar2 default null)
is
   l_rec            at_fcst_spec%rowtype;
   l_location_code  at_physical_location.location_code%type;
   l_ts_code        at_cwms_ts_spec.ts_code%type;
   l_fail_if_exists boolean;
   l_ignore_nulls   boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'); end if;
   if p_entity_id    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Entity_Id'   ); end if;
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.return_true_or_false(p_ignore_nulls);
   --------------------------------------
   -- retrieve the record if it exists --
   --------------------------------------
   l_rec.office_code := cwms_util.get_office_code(p_office_id);
   l_rec.fcst_spec_code := get_fcst_spec_code(l_rec.office_code, p_fcst_spec_id, p_fcst_designator, 'F');
   if l_rec.fcst_spec_code is null then
      l_rec.fcst_spec_id    := p_fcst_spec_id;
      l_rec.fcst_designator := p_fcst_designator;
      l_ignore_nulls        := false;
   else
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Forecast specification',
            cwms_util.get_db_office_id_from_code(l_rec.office_code)
            ||'/'||l_rec.fcst_spec_id
            ||'/'||p_fcst_designator);
      end if;
      select *
        into l_rec
        from at_fcst_spec
       where fcst_spec_code = l_rec.fcst_spec_code;
   end if;
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
   if p_description is not null or not l_ignore_nulls then
      l_rec.description := p_description;
   end if;
   -----------------------------
   -- insert or update record --
   -----------------------------
   if l_rec.fcst_spec_code is null then
      l_rec.fcst_spec_code := random_uuid;
      insert
        into at_fcst_spec
      values l_rec;
   else
      update at_fcst_spec
         set row = l_rec
       where fcst_spec_code = l_rec.fcst_spec_code;
   end if;
   -------------------------
   -- handle the location --
   -------------------------
   if p_location_id is null then
      if not l_ignore_nulls then
         delete from at_fcst_location where fcst_spec_code = l_rec.fcst_spec_code;
      end if;
   else
      l_location_code := cwms_loc.get_location_code(l_rec.office_code, p_location_id);
      merge into
         at_fcst_location a
      using
         (select l_rec.fcst_spec_code as fcst_spec_code,
                 l_location_code as location_code
            from dual
         ) b
      on
         (a.fcst_spec_code = b.fcst_spec_code and a.primary_location_code = b.location_code)
      when not matched then
         insert values (l_rec.fcst_spec_code, l_location_code);
   end if;
   ----------------------------
   -- handle the time series --
   ----------------------------
   if p_timeseries_ids is null then
      if not l_ignore_nulls then
         delete from at_fcst_time_series where fcst_spec_code = l_rec.fcst_spec_code;
      end if;
   else
      for rec in (select trim(column_value) as tsid from table(cwms_util.split_text(p_timeseries_ids, chr(10)))) loop
         l_ts_code := cwms_ts.get_ts_code(rec.tsid, l_rec.office_code);
         merge into
            at_fcst_time_series a
         using
         (select l_rec.fcst_spec_code as fcst_spec_code,
                 l_ts_code as ts_code
            from dual
         ) b
      on
         (a.fcst_spec_code = b.fcst_spec_code and a.ts_code = b.ts_code)
      when not matched then
         insert values (l_rec.fcst_spec_code, l_ts_code);
      end loop;
   end if;
end store_fcst_spec;
--------------------------------------------------------------------------------
-- procedure cat_fcst_spec
--------------------------------------------------------------------------------
procedure cat_fcst_spec(
   p_cursor               out sys_refcursor,
   p_fcst_spec_id_mask    in varchar2 default '*',
   p_fcst_designator_mask in varchar2 default '*',
   p_entity_id_mask       in varchar2 default '*',
   p_office_id_mask       in varchar2 default null)
is
   l_fcst_spec_id_mask    at_fcst_spec.fcst_spec_id%type;
   l_fcst_designator_mask at_fcst_spec.fcst_designator%type;
   l_entity_id_mask       at_entity.entity_name%type;
   l_office_id_mask       cwms_office.office_id%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id_mask is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id_Mask'); end if;
   if p_entity_id_mask    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Entity_Id_Mask'   ); end if;
   -----------------
   -- do the work --
   -----------------
   l_fcst_spec_id_mask    := cwms_util.normalize_wildcards(p_fcst_spec_id_mask);
   l_fcst_designator_mask := cwms_util.normalize_wildcards(p_fcst_designator_mask);
   l_entity_id_mask       := cwms_util.normalize_wildcards(p_entity_id_mask);
   if p_office_id_mask is null then
      l_office_id_mask := cwms_util.user_office_id;
   else
      l_office_id_mask := cwms_util.normalize_wildcards(p_office_id_mask);
   end if;
   -- 1 office_id          varchar2(16)
   -- 2 fcst_spec_id       varchar2(32)
   -- 3 fcst_designator_id varchar2(57)
   -- 4 entity_id          varchar2(32)
   -- 5 entity_name        varchar2(32)
   -- 6 description        varchar2(256)
   -- 7 times_series_ids sys_refcursor 7.1 time_series_id varchar2(193)
   open p_cursor for
      select o.office_id,
             fs.fcst_spec_id,
             fs.fcst_designator,
             e.entity_id,
             e.entity_name,
             fs.description,
             cursor (select ts.cwms_ts_id as time_series_id
                       from at_cwms_ts_id ts,
                            at_fcst_time_series ft
                      where ft.fcst_spec_code = fs.fcst_spec_code
                        and ts.ts_code = ft.ts_code
                    )
        from at_fcst_spec fs,
             cwms_office o,
             at_entity e
       where o.office_code = fs.office_code
         and e.entity_code = fs.source_entity
         and upper(fs.fcst_spec_id) like upper(l_fcst_spec_id_mask) escape '\'
         and upper(nvl(fs.fcst_designator, '~')) like upper(nvl(l_fcst_designator_mask, '~')) escape '\'
         and (e.entity_id like l_entity_id_mask escape '\' or e.entity_name like l_entity_id_mask escape '\')
         and o.office_id like l_office_id_mask escape '\';
end cat_fcst_spec;
--------------------------------------------------------------------------------
-- function cat_fcst_spec_f
--------------------------------------------------------------------------------
function cat_fcst_spec_f(
   p_fcst_spec_id_mask    in varchar2 default '*',
   p_fcst_designator_mask in varchar2 default '*',
   p_entity_id_mask       in varchar2 default '*',
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_fcst_spec(
      p_cursor               => l_cursor,
      p_fcst_spec_id_mask    => p_fcst_spec_id_mask,
      p_fcst_designator_mask => p_fcst_designator_mask,
      p_entity_id_mask       => p_entity_id_mask,
      p_office_id_mask       => p_office_id_mask );
   return l_cursor;
end cat_fcst_spec_f;
--------------------------------------------------------------------------------
-- procedure retrieve_fcst_spec
--------------------------------------------------------------------------------
procedure retrieve_fcst_spec(
   p_entity_id       out varchar2,
   p_description     out varchar2,
   p_location_id     out varchar2,
   p_timeseries_ids  out nocopy clob,
   p_fcst_spec_id    in varchar2,
   p_fcst_designator in varchar2 default null,
   p_office_id       in varchar2 default null)
is
   l_office_code    cwms_office.office_code%type;
   l_fcst_spec_code at_fcst_spec.fcst_spec_code%type;
   l_ts_ids         str_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id  is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id' ); end if;
   -----------------
   -- do the work --
   -----------------
   l_office_code    := cwms_util.get_office_code(p_office_id);
   l_fcst_spec_code := get_fcst_spec_code(l_office_code, p_fcst_spec_id, p_fcst_designator, 'T');
   -----------------------------------------------
   -- get the entity, desctiption, and location --
   -----------------------------------------------
   select
      entity_id,
      description,
      location_id
   into
      p_entity_id,
      p_description,
      p_location_id
   from
     (select
         fs.fcst_spec_code,
         e.entity_id,
         fs.description
      from
         at_fcst_spec fs,
         at_entity e
      where
         fs.fcst_spec_code = l_fcst_spec_code
         and e.entity_code = fs.source_entity
     ) q1
     left outer join
     (select
         fl.fcst_spec_code,
         bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_Id as location_id
      from
         at_fcst_location fl,
         at_base_location bl,
         at_physical_location pl
      where
         pl.location_code = fl.primary_location_code
         and bl.base_location_code = pl.base_location_code
     ) q2 on q2.fcst_spec_code = q1.fcst_spec_code;
   -------------------------
   -- get the time series --
   -------------------------
   select
      tsid.cwms_ts_id
   bulk collect into
      l_ts_ids
   from
      at_fcst_time_series fts,
      at_cwms_ts_id tsid
   where
      fts.fcst_spec_code = l_fcst_spec_code
      and tsid.ts_code = fts.ts_code
   order by
      tsid.cwms_ts_id;
   if l_ts_ids.count > 0 then
      dbms_lob.createtemporary(p_timeseries_ids, true);
      dbms_lob.open(p_timeseries_ids, dbms_lob.lob_readwrite);
      cwms_util.append(p_timeseries_ids, l_ts_ids(1));
      for i in 2..l_ts_ids.count loop
         cwms_util.append(p_timeseries_ids, chr(10)||l_ts_ids(i));
      end loop;
      dbms_lob.close(p_timeseries_ids);
   end if;
end retrieve_fcst_spec;
--------------------------------------------------------------------------------
-- procedure delete_fcst_spec
--------------------------------------------------------------------------------
procedure delete_fcst_spec(
   p_fcst_spec_id    in varchar2,
   p_fcst_designator in varchar2,
   p_delete_action   in varchar2,
   p_office_id       in varchar2 default null)
is
   l_office_id      cwms_office.office_id%type;
   l_office_code    cwms_office.office_code%type;
   l_fcst_spec_code at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_code at_fcst_inst.fcst_inst_code%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id  is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id' ); end if;
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
   l_office_code    := cwms_util.get_office_code(p_office_id);
   l_office_id      := cwms_util.get_db_office_id_from_code(l_office_code);
   l_fcst_spec_code := get_fcst_spec_code(l_office_code, p_fcst_spec_id, p_fcst_designator, 'T');
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
            p_fcst_spec_id        => p_fcst_spec_id,
            p_fcst_designator     => p_fcst_designator,
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
        from at_fcst_location
       where fcst_spec_code = l_fcst_spec_code;
      delete
        from at_fcst_time_series
       where fcst_spec_code = l_fcst_spec_code;
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
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2,
   p_max_age            in binary_integer default null,
   p_notes              in varchar2       default null,
   p_fcst_info          in varchar2       default null,
   p_fcst_file          in blob_file_t    default null,
   p_fail_if_exists     in varchar2       default 'T',
   p_ignore_nulls       in varchar2       default 'T',
   p_office_id          in varchar2       default null)
is
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_code  at_fcst_inst.fcst_inst_code%type;
   l_office_id       cwms_office.office_id%type;
   l_office_code     cwms_office.office_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
   l_fail_if_exists  boolean;
   l_ignore_nulls    boolean;
   l_fcst_inst_rec   at_fcst_inst%rowtype;
   l_json_obj        json_object_t;
   l_keys            json_key_list;
   l_value           varchar2(4000);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if p_time_zone          is null then cwms_err.raise('NULL_ARGUMENT', 'P_Time_Zone'         ); end if;
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.return_true_or_false(p_ignore_nulls);
   -------------------------
   -- get the spec record --
   -------------------------
   l_office_code    := cwms_util.get_office_code(p_office_id);
   l_office_id      := cwms_util.get_db_office_id_from_code(l_office_code);
   l_fcst_spec_code := get_fcst_spec_code(l_office_code, p_fcst_spec_id, p_fcst_designator, 'T');
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   l_time_zone_id := cwms_util.get_timezone(p_time_zone);
   if l_time_zone_id in ('UTC', 'GMT') then
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   ---------------------------------------
   -- get or create the instance record --
   ---------------------------------------
   l_fcst_inst_code := get_fcst_inst_code(l_fcst_spec_code, l_fcst_time_utc, l_issue_time_utc, 'F');
   if l_fcst_inst_code is null then
      l_fcst_inst_rec.fcst_spec_code  := l_fcst_spec_code;
      l_fcst_inst_rec.fcst_date_time  := l_fcst_time_utc;
      l_fcst_inst_rec.issue_date_time := l_issue_time_utc;
      l_ignore_nulls := false;
   else
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Forecast instance',
            l_office_id||'/'||p_fcst_spec_id||'/'||p_fcst_designator
            ||'/'||to_char(l_fcst_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
            ||'/'||to_char(l_issue_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"'));
      end if;
   end if;
   -------------------------------------
   -- populate instance record fields --
   -------------------------------------
   if p_max_age is not null or not l_ignore_nulls then
      l_fcst_inst_rec.max_age := p_max_age;
   end if;
   if p_notes is not null or not l_ignore_nulls then
      l_fcst_inst_rec.notes := p_notes;
   end if;
   if p_fcst_file is not null or not l_ignore_nulls then
      l_fcst_inst_rec.blob_file := p_fcst_file;
   end if;
   if l_fcst_inst_rec.fcst_inst_code is not null  and p_fcst_info is null and not l_ignore_nulls then
      delete from
         at_fcst_info
      where
         fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;
   end if;
   -------------------------------
   -- store the instance record --
   -------------------------------
   if l_fcst_inst_rec.fcst_inst_code is null then
      l_fcst_inst_rec.fcst_inst_code := random_uuid;
      insert
        into at_fcst_inst
      values l_fcst_inst_rec;
   else
      update at_fcst_inst
         set row = l_fcst_inst_rec
       where fcst_inst_code = l_fcst_inst_rec.fcst_inst_code;
   end if;
   -------------------------------
   -- update at_fcst_info table --
   -------------------------------
   if p_fcst_info is not null then
      l_json_obj := json_object_t.parse(p_fcst_info);
      l_keys := l_json_obj.get_keys;
      for i in 1..l_keys.count loop
         l_value := l_json_obj.get(l_keys(i)).to_string;
         merge into
            at_fcst_info a
         using
            (select
                l_fcst_inst_rec.fcst_inst_code as fcst_inst_code,
                l_keys(i) as key
             from dual
            ) b
         on
            (a.fcst_inst_code = b.fcst_inst_code and a.key = b.key)
         when matched then
            update set value = l_value
         when not matched then
            insert values (l_fcst_inst_rec.fcst_inst_code, l_keys(i), l_value);
      end loop;
   end if;
end store_fcst;
--------------------------------------------------------------------------------
-- procedure store_fcst_file
--------------------------------------------------------------------------------
procedure store_fcst_file(
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2,
   p_fcst_file          in blob_file_t,
   p_fail_if_exists     in varchar2     default 'T',
   p_office_id          in varchar2     default null)
is
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_code  at_fcst_inst.fcst_inst_code%type;
   l_office_id       cwms_office.office_id%type;
   l_office_code     cwms_office.office_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
   l_fail_if_exists  boolean;
   l_fcst_inst_rec   at_fcst_inst%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if p_time_zone          is null then cwms_err.raise('NULL_ARGUMENT', 'P_Time_Zone'         ); end if;
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   -------------------------
   -- get the spec record --
   -------------------------
   l_office_code    := cwms_util.get_office_code(p_office_id);
   l_fcst_spec_code := get_fcst_spec_code(l_office_code, p_fcst_spec_id, p_fcst_designator, 'T');
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   l_time_zone_id := cwms_util.get_timezone(p_time_zone);
   if l_time_zone_id in ('UTC', 'GMT') then
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   --------------------------------------
   -- get the instance code and record --
   --------------------------------------
   l_fcst_inst_code := get_fcst_inst_code(l_fcst_spec_code, l_fcst_time_utc, l_issue_time_utc, 'T');
   select * into l_fcst_inst_rec from at_fcst_inst where fcst_inst_code = l_fcst_inst_code;
   -------------------------------------------
   -- store the file in the instance record --
   -------------------------------------------
   if l_fail_if_exists and l_fcst_inst_rec.blob_file is not null then
      l_office_id := cwms_util.get_db_office_id(l_office_code);
      cwms_err.raise(
         'ERROR',
         'Forecast instance '
         ||l_office_id||'/'||p_fcst_spec_id||'/'||p_fcst_designator
         ||'/'||to_char(l_fcst_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
         ||'/'||to_char(l_issue_time_utc, 'yyyy-mm-dd"T"hh24:mi:ss"Z"')
         ||' already has a forecast file');
   end if;
   update
      at_fcst_inst
   set
      blob_file = p_fcst_file
   where
      fcst_inst_code = l_fcst_inst_code;
end store_fcst_file;
--------------------------------------------------------------------------------
-- procedure cat_fcst
--------------------------------------------------------------------------------
procedure cat_fcst(
   p_cursor                 out sys_refcursor,
   p_fcst_spec_id_mask      in varchar2 default '*',
   p_fcst_designator_mask   in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default 'UTC',
   p_valid_forecasts_only   in varchar2 default 'F',
   p_key_mask               in varchar2 default '*',
   p_value_mask             in varchar2 default '*',
   p_office_id_mask         in varchar2 default null)
is
   l_fcst_spec_id_mask    at_fcst_spec.fcst_spec_id%type;
   l_fcst_designator_mask at_fcst_spec.fcst_designator%type;
   l_office_id_mask      cwms_office.office_id%type;
   l_time_zone           cwms_time_zone.time_zone_name%type;
   l_null_crsr           sys_refcursor;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id_mask is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id_Mask'); end if;
   if p_time_zone         is null then cwms_err.raise('NULL_ARGUMENT', 'P_Time_Zone'        ); end if;
   if p_valid_forecasts_only in ('T', 'F') then
      null;
   else
      cwms_err.raise('INVALID_T_F_FLAG', p_valid_forecasts_only);
   end if;
   l_time_zone := cwms_util.get_timezone(p_time_zone);
   -----------------
   -- do the work --
   -----------------
   l_fcst_spec_id_mask := cwms_util.normalize_wildcards(p_fcst_spec_id_mask);
   l_fcst_designator_mask  := cwms_util.normalize_wildcards(p_fcst_designator_mask);
   if p_office_id_mask is null then
      l_office_id_mask := cwms_util.user_office_id;
   else
      l_office_id_mask := cwms_util.normalize_wildcards(p_office_id_mask);
   end if;
   --  1 office_id        varchar2(16)
   --  2 fcst_spec_id     varchar2(32)
   --  3 fcst_designator  varchar2(57)
   --  4 time_zone        varchar2(28)
   --  5 fcst_date_time   date
   --  6 issue_date_time  date
   --  7 max_age          number(6)
   --  8 valid            varchar2(1)
   --  9 notes            varchar2(256)
   -- 10 file_name        varchar2(256)
   -- 11 file_size        integer
   -- 12 file_media_type  varchar2(256)
   -- 13 key_value_pairs  sys_refcursor   13.1 key varchar2(32767)
   --                                     13.2 value varchar2(32767)
   open p_cursor for
      select
         o.office_id,
         fs.fcst_spec_id,
         fs.fcst_designator,
         l_time_zone as time_zone,
         case
         when l_time_zone in ('UTC', 'GMT') then
            fi.fcst_date_time
         else
            cwms_util.change_timezone(fi.fcst_date_time, 'UTC', l_time_zone)
         end as fcst_date_time,
         case
         when l_time_zone in ('UTC', 'GMT') then
            fi.issue_date_time
         else
            cwms_util.change_timezone(fi.issue_date_time, 'UTC', l_time_zone)
         end as issue_date_time,
         fi.max_age,
         case
            when (sysdate - fi.issue_date_time) * 24 > fi.max_age then 'F'
            else 'T'
         end as valid,
         fi.notes,
         case when fi.blob_file is null then null else fi.blob_file.filename end as file_name,
         case when fi.blob_file is null then null else dbms_lob.getlength(fi.blob_file.the_blob )end as file_size,
         case when fi.blob_file is null then null else fi.blob_file.media_type end as file_media_type,
         cursor (select key,
                        value
                   from at_fcst_info info
                  where info.fcst_inst_code = fi.fcst_inst_code
                    and key like cwms_util.normalize_wildcards(p_key_mask) escape '\'
                    and value like cwms_util.normalize_wildcards(p_value_mask) escape '\'
                ) as key_value_pairs
      from
         cwms_office o,
         at_fcst_spec fs,
         at_fcst_inst fi
      where
         o.office_id like l_office_id_mask
         and o.office_code = fs.office_code
         and fs.fcst_spec_id like l_fcst_spec_id_mask escape '\'
         and upper(nvl(fs.fcst_designator, '~')) like upper(nvl(l_fcst_designator_mask, '~')) escape '\'
         and fi.fcst_spec_code = fs.fcst_spec_code
         and (p_min_forecast_date_time is null or fi.fcst_date_time >= cwms_util.change_timezone(p_min_forecast_date_time, l_time_zone, 'UTC'))
         and (p_max_forecast_date_time is null or fi.fcst_date_time <= cwms_util.change_timezone(p_max_forecast_date_time, l_time_zone, 'UTC'))
         and (p_min_issue_date_time is null or fi.issue_date_time >= cwms_util.change_timezone(p_min_issue_date_time, l_time_zone, 'UTC'))
         and (p_max_issue_date_time is null or fi.issue_date_time <= cwms_util.change_timezone(p_max_issue_date_time, l_time_zone, 'UTC'))
         and (p_valid_forecasts_only = 'F' or (sysdate - fi.issue_date_time) * 24 <= fi.max_age)
      order by
         o.office_id,
         fs.fcst_spec_id,
         fs.fcst_designator,
         fi.fcst_date_time,
         fi.issue_date_time;
end cat_fcst;
--------------------------------------------------------------------------------
-- function cat_fcst_f
--------------------------------------------------------------------------------
function cat_fcst_f(
   p_fcst_spec_id_mask      in varchar2 default '*',
   p_fcst_designator_mask   in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default 'UTC',
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
      p_fcst_designator_mask   => p_fcst_designator_mask,
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
   p_max_age            out binary_integer,
   p_notes              out varchar2,
   p_fcst_info          out varchar2,
   p_has_file           out varchar2,
   p_timeseries_ids     out nocopy clob,
   p_fcst_file          out blob_file_t,
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2 default 'UTC',
   p_retrieve_file      in varchar2 default 'F',
   p_office_id          in varchar2 default null)
is
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_code  at_fcst_inst.fcst_inst_code%type;
   l_office_code     cwms_office.office_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
   l_fcst_info       varchar2(32767);
   l_start_time      date;
   l_end_time        date;
   l_tsids           str_tab_t;
   l_exists          varchar2(1);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if p_time_zone          is null then cwms_err.raise('NULL_ARGUMENT', 'P_Time_Zone'         ); end if;
   if p_retrieve_file not in ('T','F') then
      cwms_err.raise('INVALID_T_F_FLAG', p_retrieve_file);
   end if;
   -------------------------
   -- get the spec record --
   -------------------------
   l_office_code    := cwms_util.get_office_code(p_office_id);
   l_fcst_spec_code := get_fcst_spec_code(l_office_code, p_fcst_spec_id, p_fcst_designator, 'T');
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   l_time_zone_id := cwms_util.get_timezone(p_time_zone);
   if l_time_zone_id in ('UTC', 'GMT') then
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   ---------------------------
   -- get the instance code --
   ---------------------------
   l_fcst_inst_code := get_fcst_inst_code(l_fcst_spec_code, l_fcst_time_utc, l_issue_time_utc, 'T');
   -----------------------------------------------------
   -- get the max_age, notes, has_file, and fcst_file --
   ----------------------------------------------------
   select
      max_age,
      notes,
      case when blob_file is null then 'F' else 'T' end,
      case when p_retrieve_file = 'T' then blob_file else null end
   into
      p_max_age,
      p_notes,
      p_has_file,
      p_fcst_file
   from
      at_fcst_inst
   where
      fcst_inst_code = l_fcst_inst_code;
   ---------------------------
   -- get the forecast info --
   ---------------------------
   for rec in (select key, value from at_fcst_info where fcst_inst_code = l_fcst_inst_code order by key) loop
      if rec.key = 'startTime' then
         begin
            l_start_time := cwms_util.to_timestamp(trim('"' from rec.value));
         exception
            when others then null;
         end;
      elsif rec.key = 'endTime' then
         begin
            l_end_time := cwms_util.to_timestamp(trim('"' from rec.value));
         exception
            when others then null;
         end;
      end if;
      if l_fcst_info is null then
         l_fcst_info := '{';
      else
         l_fcst_info := l_fcst_info||',';
      end if;
      l_fcst_info := l_fcst_info
      ||'"'||rec.key||'":'
      ||case when rec.value is null then 'null' else rec.value end;
   end loop;
   if l_fcst_info is not null then
      l_fcst_info := l_fcst_info||'}';
   end if;
   p_fcst_info := l_fcst_info;
   -------------------------
   -- get the time series --
   -------------------------
   l_tsids := str_tab_t();
   for rec in (select
                  ts.ts_code,
                  ts.cwms_ts_id
               from
                  at_cwms_ts_id ts,
                  at_fcst_time_series fts
               where
                  fts.fcst_spec_code = l_fcst_spec_code
                  and ts.ts_code = fts.ts_code
               order by
                  ts.cwms_ts_id
              )
   loop
      l_exists := 'F';
      begin
         select 'T'
         into l_exists
         from dual
         where exists (select
                        ts_code
                        from
                           av_tsv
                        where
                           ts_code = rec.ts_code
                           and version_date = l_issue_time_utc
                           and date_time  >= case when l_start_time is null then date_time else l_start_time end
                           and date_time  <= case when l_end_time is null then date_time else l_end_time end
                           and start_date <= case when l_end_time is null then date_time else l_end_time end
                           and end_date   >  case when l_start_time is null then date_time else l_start_time end
                     );
      exception
         when no_data_found then null;
      end;
      if l_exists = 'T' then
         l_tsids.extend;
         l_tsids(l_tsids.count) := rec.cwms_ts_id;
      end if;
   end loop;
   if l_tsids.count > 0 then
      dbms_lob.createtemporary(p_timeseries_ids, true);
      dbms_lob.open(p_timeseries_ids, dbms_lob.lob_readwrite);
      cwms_util.append(p_timeseries_ids, l_tsids(1));
      for i in 2..l_tsids.count loop
         cwms_util.append(p_timeseries_ids, chr(10)||l_tsids(i));
      end loop;
      dbms_lob.close(p_timeseries_ids);
   end if;

end retrieve_fcst;
--------------------------------------------------------------------------------
-- procedure retrieve_fcst_file
--------------------------------------------------------------------------------
procedure retrieve_fcst_file(
   p_fcst_file          out blob_file_t,
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2,
   p_office_id          in varchar2     default null)
is
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_code  at_fcst_inst.fcst_inst_code%type;
   l_office_code     cwms_office.office_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if p_time_zone          is null then cwms_err.raise('NULL_ARGUMENT', 'P_Time_Zone'         ); end if;
   -------------------------
   -- get the spec record --
   -------------------------
   l_office_code    := cwms_util.get_office_code(p_office_id);
   l_fcst_spec_code := get_fcst_spec_code(l_office_code, p_fcst_spec_id, p_fcst_designator, 'T');
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   l_time_zone_id := cwms_util.get_timezone(p_time_zone);
   if l_time_zone_id in ('UTC', 'GMT') then
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   ---------------------------
   -- get the instance code --
   ---------------------------
   l_fcst_inst_code := get_fcst_inst_code(l_fcst_spec_code, l_fcst_time_utc, l_issue_time_utc, 'T');
   ------------------
   -- get the file --
   ------------------
   select blob_file into p_fcst_file from at_fcst_inst where fcst_inst_code = l_fcst_inst_code;
end retrieve_fcst_file;
--------------------------------------------------------------------------------
-- procedure delete_fcst
--------------------------------------------------------------------------------
procedure delete_fcst(
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2 default 'UTC',
   p_office_id          in varchar2 default null)
is
   l_fcst_spec_code  at_fcst_spec.fcst_spec_code%type;
   l_fcst_inst_code  at_fcst_inst.fcst_inst_code%type;
   l_office_code     cwms_office.office_code%type;
   l_time_zone_id    cwms_time_zone.time_zone_name%type;
   l_fcst_time_utc   date;
   l_issue_time_utc  date;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_fcst_spec_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fcst_Spec_Id'      ); end if;
   if p_forecast_date_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_Forecast_Date_Time'); end if;
   if p_issue_date_time    is null then cwms_err.raise('NULL_ARGUMENT', 'P_Issue_Date_Time'   ); end if;
   if p_time_zone          is null then cwms_err.raise('NULL_ARGUMENT', 'P_Time_Zone'         ); end if;
   -------------------------
   -- get the spec record --
   -------------------------
   l_office_code    := cwms_util.get_office_code(p_office_id);
   l_fcst_spec_code := get_fcst_spec_code(l_office_code, p_fcst_spec_id, p_fcst_designator, 'T');
   ----------------------------
   -- get the utc date/times --
   ----------------------------
   l_time_zone_id := cwms_util.get_timezone(p_time_zone);
   if l_time_zone_id in ('UTC', 'GMT') then
      l_fcst_time_utc  := p_forecast_date_time;
      l_issue_time_utc := p_issue_date_time;
   else
      l_fcst_time_utc  := cwms_util.change_timezone(p_forecast_date_time, l_time_zone_id, 'UTC');
      l_issue_time_utc := cwms_util.change_timezone(p_issue_date_time, l_time_zone_id, 'UTC');
   end if;
   ---------------------------
   -- get the instance code --
   ---------------------------
   l_fcst_inst_code := get_fcst_inst_code(l_fcst_spec_code, l_fcst_time_utc, l_issue_time_utc, 'T');
   ----------------------------------
   -- delete the forecast instance --
   ----------------------------------
   delete from at_fcst_info where fcst_inst_code = l_fcst_inst_code;
   delete from at_fcst_inst where fcst_inst_code = l_fcst_inst_code;
end delete_fcst;

end;
/

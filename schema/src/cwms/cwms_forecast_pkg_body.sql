create or replace package body cwms_forecast as

--------------------------------------------------------------------------------
-- function get_forecast_spec_code
--------------------------------------------------------------------------------
function get_forecast_spec_code(
   p_location_id in varchar2,
   p_forecast_id in varchar2,
   p_office_id   in varchar2 default null) -- null = user's office id
   return number
is
   l_office_id          varchar2(16);
   l_forecast_spec_code number(14);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier cannot be null');
   end if;
   if p_forecast_id is null then
      cwms_err.raise(
         'ERROR',
         'Forecast identifier cannot be null');
   end if;

   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);

   begin
      select forecast_spec_code
        into l_forecast_spec_code
        from at_forecast_spec fs,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = l_office_id
         and bl.db_office_code = o.office_code
         and upper(bl.base_location_id) = upper(cwms_util.get_base_id(p_location_id))
         and pl.base_location_code = bl.base_location_code
         and nvl(upper(pl.sub_location_id), '.') = nvl(upper(cwms_util.get_sub_id(p_location_id)), '.')
         and fs.target_location_code = pl.location_code
         and upper(fs.forecast_id) = upper(p_forecast_id);

      return l_forecast_spec_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS Forecast',
            l_office_id
            ||'/'
            ||p_location_id
            ||'/'
            ||p_forecast_id);
   end;
end get_forecast_spec_code;

--------------------------------------------------------------------------------
-- procedure store_spec
--------------------------------------------------------------------------------
procedure store_spec(
   p_location_id    in varchar2,
   p_forecast_id    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_source_agency  in varchar2,
   p_source_office  in varchar2,
   p_valid_lifetime in integer, -- in hours
   p_forecast_type  in varchar2 default null, -- null = null
   p_source_loc_id  in varchar2 default null, -- null = null
   p_office_id      in varchar2 default null) -- null = user's office id
is
   item_does_not_exist exception; pragma exception_init(item_does_not_exist, -20034);
   l_office_id      varchar2(16);
   l_rec            at_forecast_spec%rowtype;
   l_fail_if_exists boolean;
   l_ignore_nulls   boolean;
   l_exists         boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier cannot be null');
   end if;
   if p_forecast_id is null then
      cwms_err.raise(
         'ERROR',
         'Forecast identifier cannot be null');
   end if;
   ------------------------------
   -- see if the record exists --
   ------------------------------
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   begin
      l_rec.forecast_spec_code := get_forecast_spec_code(
         p_location_id,
         p_forecast_id,
         l_office_id);
      l_exists := true;
   exception
      when item_does_not_exist then
         l_exists := false;
   end;
   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'CWMS Forecast',
            l_office_id
            ||'/'
            ||p_location_id
            ||'/'
            ||p_forecast_id);
      end if;
   else
      if p_source_agency is null then
         cwms_err.raise(
            'ERROR',
            'Source agency cannot be null on new record');
      end if;
      if p_source_office is null then
         cwms_err.raise(
            'ERROR',
            'Source office cannot be null on new record');
      end if;
   end if;
   -------------------------
   -- populate the record --
   -------------------------
   l_rec.forecast_spec_code := nvl(
      l_rec.forecast_spec_code,
      cwms_seq.nextval);
   l_rec.target_location_code := nvl(
      l_rec.target_location_code,
      cwms_loc.get_location_code(l_office_id, p_location_id));
   l_rec.forecast_id := nvl(
      l_rec.forecast_id,
      p_forecast_id);
   l_rec.source_agency := nvl(
      l_rec.source_agency,
      upper(p_source_agency));
   l_rec.source_office := nvl(
      l_rec.source_office,
      upper(p_source_office));
   if l_rec.source_agency = 'USACE' then
      begin
         select office_id
           into l_rec.source_office
           from cwms_office
          where office_id = l_rec.source_office;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_OFFICE_ID', l_rec.source_office);
      end;
   end if;
   if p_valid_lifetime is not null or not l_ignore_nulls then
      l_rec.max_age := p_valid_lifetime;
   end if;
   if p_forecast_type is not null or not l_ignore_nulls then
      l_rec.forecast_type := p_forecast_type;
   end if;
   if p_source_loc_id is not null or not l_ignore_nulls then
      l_rec.source_location_code :=
         case p_source_loc_id is null
            when true  then null
            when false then cwms_loc.get_location_code(l_office_id, p_source_loc_id)
         end;
   end if;
   ---------------------------------
   -- insert or update the record --
   ---------------------------------
   if l_exists then
      update at_forecast_spec
         set row = l_rec
       where forecast_spec_code = l_rec.forecast_spec_code;
   else
      insert
        into at_forecast_spec
      values l_rec;
   end if;
end store_spec;

--------------------------------------------------------------------------------
-- procedure retrieve_spec
--------------------------------------------------------------------------------
procedure retrieve_spec(
   p_source_agency  out varchar2,
   p_source_office  out varchar2,
   p_valid_lifetime out integer, -- in hours
   p_forecast_type  out varchar2,
   p_source_loc_id  out varchar2,
   p_location_id    in  varchar2,
   p_forecast_id    in  varchar2,
   p_office_id      in  varchar2 default null) -- null = user's office id
is
   l_office_id varchar2(16);
   l_rec       at_forecast_spec%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier cannot be null');
   end if;
   if p_forecast_id is null then
      cwms_err.raise(
         'ERROR',
         'Forecast identifier cannot be null');
   end if;
   ------------------------------
   -- see if the record exists --
   ------------------------------
   l_rec.forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      l_office_id);
   -------------------------
   -- retrieve the record --
   -------------------------
   select *
     into l_rec
     from at_forecast_spec
    where forecast_spec_code = l_rec.forecast_spec_code;
   ---------------------------------
   -- populate the out parameters --
   ---------------------------------
   p_source_agency  := l_rec.source_agency;
   p_source_office  := l_rec.source_office;
   p_valid_lifetime := l_rec.max_age;
   p_forecast_type  := l_rec.forecast_type;
   if l_rec.source_location_code is null then
      p_source_loc_id := null;
   else
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id
        into p_source_loc_id
        from at_physical_location pl,
             at_base_location bl
       where pl.location_code = l_rec.source_location_code
         and bl.base_location_code = pl.base_location_code;
   end if;
end retrieve_spec;
--------------------------------------------------------------------------------
-- procedure rename_spec
--------------------------------------------------------------------------------
procedure rename_spec(
   p_location_id     in varchar2,
   p_old_forecast_id in varchar2,
   p_new_forecast_id in varchar2,
   p_office_id       in varchar2 default null) -- null = user's office id
is
   l_forecast_spec_code number(14);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier cannot be null');
   end if;
   if p_old_forecast_id is null then
      cwms_err.raise(
         'ERROR',
         'Existing forecast identifier cannot be null');
   end if;
   if p_new_forecast_id is null then
      cwms_err.raise(
         'ERROR',
         'New forecast identifier cannot be null');
   end if;
   ------------------------------
   -- see if the record exists --
   ------------------------------
   l_forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_old_forecast_id,
      p_office_id);
   -----------------------
   -- update the record --
   -----------------------
   update at_forecast_spec
      set forecast_id = upper(p_new_forecast_id)
    where forecast_spec_code = l_forecast_spec_code;
end rename_spec;

--------------------------------------------------------------------------------
-- procedure cat_specs
--------------------------------------------------------------------------------
procedure cat_specs(
   p_spec_catalog       out sys_refcursor,
   p_location_id_mask   in  varchar2 default '*',
   p_forecast_id_mask   in  varchar2 default '*',
   p_source_agency_mask in  varchar2 default '*',
   p_source_office_mask in  varchar2 default '*',
   p_forecast_type_mask in  varchar2 default '*',
   p_source_loc_id_mask in  varchar2 default '*',
   p_office_id_mask     in  varchar2 default null) -- null = user's office id
is
   l_location_id_mask   varchar2(57);
   l_forecast_id_mask   varchar2(32);
   l_source_agency_mask varchar2(16);
   l_source_office_mask varchar2(16);
   l_forecast_type_mask varchar2(5);
   l_source_loc_id_mask varchar2(57);
   l_office_id_mask     varchar2(16);
begin
   ----------------------
   -- set up the masks --
   ----------------------
   l_location_id_mask   := cwms_util.normalize_wildcards(upper(p_location_id_mask));
   l_forecast_id_mask   := cwms_util.normalize_wildcards(upper(p_forecast_id_mask));
   l_source_agency_mask := cwms_util.normalize_wildcards(upper(p_source_agency_mask));
   l_source_office_mask := cwms_util.normalize_wildcards(upper(p_source_office_mask));
   l_forecast_type_mask := cwms_util.normalize_wildcards(upper(p_forecast_type_mask));
   l_source_loc_id_mask := cwms_util.normalize_wildcards(upper(p_source_loc_id_mask));
   l_office_id_mask     := cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.user_office_id)));
   -----------------------
   -- perform the query --
   -----------------------
   open p_spec_catalog for
      select office_id,
             location_id,
             forecast_id,
             source_agency,
             source_office,
             max_age as valid_lifetime,
             forecast_type,
             source_loc_id
        from ( select o.office_id,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as location_id,
                      fs.forecast_id,
                      fs.source_agency,
                      fs.source_office,
                      fs.max_age,
                      fs.forecast_type,
                      cwms_loc.get_location_id(fs.source_location_code) as source_loc_id
                 from at_forecast_spec fs,
                      at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where o.office_id like l_office_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and fs.target_location_code = pl.location_code
                  and upper(bl.base_location_id
                            ||substr('-', 1, length(pl.sub_location_id))
                            ||pl.sub_location_id) like l_location_id_mask escape '\'
                  and upper(fs.forecast_id) like l_forecast_id_mask escape '\'
                  and ( (  upper(fs.source_agency) like l_source_agency_mask escape '\')
                        or
                        (  fs.source_agency is null and l_source_agency_mask = '%')
                      )
                  and ( (  upper(fs.source_office) like l_source_office_mask escape '\')
                        or
                        (  fs.source_office is null and l_source_office_mask = '%')
                      )
                  and ( (  upper(fs.forecast_type) like l_forecast_type_mask escape '\')
                        or
                        (  fs.forecast_type is null and l_forecast_type_mask = '%')
                      )
                  and ( (  upper(cwms_util.get_location_id(fs.source_location_code)) like l_source_loc_id_mask escape '\')
                        or
                        (  fs.source_location_code is null and l_source_loc_id_mask = '%')
                      )
             )
    order by office_id,
             location_id,
             forecast_id;
end cat_specs;

--------------------------------------------------------------------------------
-- function cat_specs_f
--------------------------------------------------------------------------------
function cat_specs_f(
   p_location_id_mask   in varchar2 default '*',
   p_forecast_id_mask   in varchar2 default '*',
   p_source_agency_mask in varchar2 default '*',
   p_source_office_mask in varchar2 default '*',
   p_forecast_type_mask in varchar2 default '*',
   p_source_loc_id_mask in varchar2 default '*',
   p_office_id_mask     in varchar2 default null) -- null = user's office id
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_specs(
      l_cursor,
      p_location_id_mask,
      p_forecast_id_mask,
      p_source_agency_mask,
      p_source_office_mask,
      p_forecast_type_mask,
      p_source_loc_id_mask,
      p_office_id_mask);

   return l_cursor;
end cat_specs_f;

--------------------------------------------------------------------------------
-- procedure store_ts
--------------------------------------------------------------------------------
procedure store_ts(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_cwms_ts_id      in varchar2,
   p_units           in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_version_date    in date,
   p_time_zone       in varchar2,
   p_timeseries_data in ztsv_array,
   p_fail_if_exists  in varchar2,
   p_store_rule      in varchar2,
   p_office_id       in varchar2 default null) -- null = user's office id
is
   ts_id_not_found       exception; pragma exception_init(ts_id_not_found, -20001);
   l_forecast_spec_code  number(14);
   l_ts_code             number(14);
   l_fail_if_exists      boolean;
   l_exists              boolean;
   l_timeseries_data     tsv_array;
   l_forecast_time       date;
   l_issue_time          date;
   l_version_date        date;
   l_rec                 at_forecast_ts%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_cwms_ts_id is null then
      cwms_err.raise(
         'ERROR',
         'Time series identifier cannot be null.');
   end if;
   if p_forecast_time is null then
      cwms_err.raise(
         'ERROR',
         'Forecast date cannot be null.');
   end if;
   if p_issue_time is null then
      cwms_err.raise(
         'ERROR',
         'Issue date cannot be null.');
   end if;
   --------------------------
   -- get the forcast spec --
   --------------------------
   l_forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      p_office_id);
   -----------------------------------------
   -- determine whether the record exists --
   -----------------------------------------
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_forecast_time  := cwms_util.change_timezone(p_forecast_time, p_time_zone, 'UTC');
   l_issue_time     := cwms_util.change_timezone(p_issue_time, p_time_zone, 'UTC');
   l_version_date   := cwms_util.change_timezone(p_version_date, p_time_zone, 'UTC');
   begin
      l_ts_code := cwms_ts.get_ts_code(p_cwms_ts_id, p_office_id);
   exception
      when ts_id_not_found then null;
   end;
   if l_ts_code is null then
      l_exists := false;
   else
      begin
         select *
           into l_rec
           from at_forecast_ts
          where forecast_spec_code = l_forecast_spec_code
            and ts_code = l_ts_code
            and forecast_date = l_forecast_time
            and issue_date = l_issue_time;
         l_exists := true;
      exception
         when no_data_found then l_exists := false;
      end;
   end if;
   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'CWMS forecast time series',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_forecast_id
            ||'/'
            ||p_cwms_ts_id
            ||'/forecast_time='
            ||to_char(p_forecast_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||p_time_zone
            ||'/'
            ||p_cwms_ts_id
            ||'/issue_time='
            ||to_char(p_issue_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||p_time_zone);
      end if;
   else
      if p_units is null then
         cwms_err.raise(
            'ERROR',
            'Units cannot be null on new record.');
      end if;
      if p_time_zone is null then
         cwms_err.raise(
            'ERROR',
            'Time zone cannot be null on new record.');
      end if;
      if p_timeseries_data is null then
         cwms_err.raise(
            'ERROR',
            'Time series data cannot be null on new record.');
      end if;
      if p_version_date is null then
         cwms_err.raise(
            'ERROR',
            'Version date cannot be null on new record.');
      end if;
   end if;
   --------------------------------------
   -- convert the incoming time series --
   --------------------------------------
   if p_timeseries_data is not null then
      l_timeseries_data := tsv_array();
      l_timeseries_data.extend(p_timeseries_data.count);
      for i in 1..p_timeseries_data.count loop
         l_timeseries_data(i) := tsv_type(
            from_tz(cast(p_timeseries_data(i).date_time as timestamp), p_time_zone),
            p_timeseries_data(i).value,
            p_timeseries_data(i).quality_code);
      end loop;
   end if;
   -----------------------
   -- modify the tables --
   -----------------------
   if l_exists then
      if p_timeseries_data is null then
         if l_version_date is not null and l_version_date != l_rec.version_date then
            cwms_ts.change_version_date(
               l_rec.ts_code,
               l_rec.version_date,
               l_version_date,
               null,
               null);
         end if;
      else
         cwms_ts.purge_ts_data(
            l_rec.ts_code,
            l_rec.version_date,
            null,
            null);
      end if;
      if l_version_date is not null and l_version_date != l_rec.version_date then
         l_rec.version_date := l_version_date;
      end if;
      update at_forecast_ts
         set row = l_rec
       where forecast_spec_code = l_rec.forecast_spec_code
         and ts_code = l_rec.ts_code
         and forecast_date = l_rec.forecast_date
         and issue_date = l_rec.issue_date;
   else
      if l_ts_code is null then
         cwms_ts.create_ts_code(
            p_ts_code    => l_ts_code, -- out parameter
            p_cwms_ts_id => p_cwms_ts_id,
            p_versioned  => 'T',
            p_office_id  => p_office_id);
      end if;
      insert
        into at_forecast_ts
      values (l_forecast_spec_code, l_ts_code, l_forecast_time, l_issue_time, l_version_date);
   end if;
   if l_timeseries_data is not null then
      if not cwms_util.is_true(cwms_ts.is_tsid_versioned_f(p_cwms_ts_id, p_office_id)) then
         cwms_ts.set_tsid_versioned(p_cwms_ts_id, 'T', p_office_id);
      end if;
      cwms_ts.store_ts(
         p_cwms_ts_id      => p_cwms_ts_id,
         p_units           => p_units,
         p_timeseries_data => l_timeseries_data,
         p_store_rule      => p_store_rule,
         p_version_date    => nvl(l_version_date, l_rec.version_date),
         p_office_id       => p_office_id);
   end if;
end store_ts;

--------------------------------------------------------------------------------
-- procedure retrieve_ts
--------------------------------------------------------------------------------
procedure retrieve_ts(
   p_ts_cursor       out sys_refcursor,
   p_version_date    out date,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_cwms_ts_id      in  varchar2,
   p_units           in  varchar2,
   p_forecast_time   in  date,
   p_issue_time      in  date,
   p_start_time      in  date default null,
   p_end_time        in  date default null,
   p_time_zone       in  varchar2 default null, -- null = location time zone
   p_trim            in  varchar2 default 'F',
   p_start_inclusive in  varchar2 default 'T',
   p_end_inclusive   in  varchar2 default 'T',
   p_previous        in  varchar2 default 'F',
   p_next            in  varchar2 default 'F',
   p_office_id       in  varchar2 default null) -- null = user's office id
is
   l_rec          at_forecast_ts%rowtype;
   l_time_zone    varchar2(28);
   l_version_date date;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_cwms_ts_id is null then
      cwms_err.raise('ERROR', 'Time series identifier cannot be null.');
   end if;
   if p_forecast_time is null then
      cwms_err.raise('ERROR', 'Forecast time cannot be null.');
   end if;
   if p_issue_time is null then
      cwms_err.raise('ERROR', 'Issue time cannot be null.');
   end if;
   --------------------------
   -- get the forcast spec --
   --------------------------
   l_rec.forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      p_office_id);
   --------------------
   -- get the record --
   --------------------
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
   begin
      select *
        into l_rec
        from at_forecast_ts
       where forecast_spec_code = l_rec.forecast_spec_code
         and ts_code = cwms_ts.get_ts_code(p_cwms_ts_id, p_office_id)
         and forecast_date = cwms_util.change_timezone(p_forecast_time, l_time_zone, 'UTC')
         and issue_date = cwms_util.change_timezone(p_issue_time, l_time_zone, 'UTC');
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS forecast time series',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_forecast_id
            ||'/'
            ||p_cwms_ts_id
            ||'/forecast_time='
            ||to_char(p_forecast_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||p_time_zone
            ||'/'
            ||p_cwms_ts_id
            ||'/issue_time='
            ||to_char(p_issue_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||p_time_zone);
   end;
   ---------------------------------    
   -- populate the out parameters --
   ---------------------------------
   l_version_date := cwms_util.change_timezone(l_rec.version_date, 'UTC', l_time_zone);
   p_version_date := l_version_date;
   
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => p_ts_cursor,
      p_cwms_ts_id      => p_cwms_ts_id,
      p_units           => p_units,
      p_start_time      => p_start_time,
      p_end_time        => p_end_time,
      p_time_zone       => l_time_zone,
      p_trim            => p_trim,
      p_start_inclusive => p_start_inclusive,
      p_end_inclusive   => p_end_inclusive,
      p_previous        => p_previous,
      p_next            => p_next,
      p_version_date    => l_version_date, 
      p_office_id       => p_office_id);   
end retrieve_ts;

--------------------------------------------------------------------------------
-- procedure delete_ts
--------------------------------------------------------------------------------
procedure delete_ts(
   p_location_id   in varchar2,
   p_forecast_id   in varchar2,
   p_cwms_ts_id    in varchar2,              -- null = all time series
   p_forecast_time in date,                  -- null = all forecast times
   p_issue_time    in date,                  -- null = all issue times
   p_time_zone     in varchar2 default null, -- null = location time zone
   p_office_id     in varchar2 default null) -- null = user's office id
is
   l_forecast_spec_code number(14);
   l_ts_code            number(14);
   l_time_zone          varchar2(28);
   l_forecast_time      date;
   l_issue_time         date; 
   l_count              pls_integer := 0;
begin
   -------------------      
   -- get the codes --
   -------------------
   l_forecast_spec_code := get_forecast_spec_code(p_location_id, p_forecast_id, p_office_id);
   if p_cwms_ts_id is not null then
      l_ts_code := cwms_ts.get_ts_code(p_cwms_ts_id, p_office_id);
   end if;
   -----------------------------      
   -- process the input times --
   -----------------------------      
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
   if p_forecast_time is not null then
      l_forecast_time := cwms_util.change_timezone(p_forecast_time, l_time_zone, 'UTC');
   end if;
   if p_issue_time is not null then
      l_issue_time := cwms_util.change_timezone(p_issue_time, l_time_zone, 'UTC');
   end if;
   ----------------------------------------------------
   -- delete any time series that matches the inputs --
   ----------------------------------------------------
   for rec in 
      (  select *
           from at_forecast_ts
          where forecast_spec_code = l_forecast_spec_code
            and ts_code = nvl(l_ts_code, ts_code)
            and forecast_date = nvl(l_forecast_time, forecast_date)
            and issue_date = nvl(l_issue_time, issue_date)
      )
   loop
      l_count := l_count + 1;
      cwms_ts.purge_ts_data(rec.ts_code, rec.version_date, null, null);
   end loop;
   if l_count = 0 then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'CWMS forecast time series',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_location_id
         ||'/'
         ||p_forecast_id
         ||'/'
         ||nvl(p_cwms_ts_id, '<any>')
         ||'/forecast_time='
         ||nvl(to_char(p_forecast_time, 'yyyy/mm/dd hh24mi'), '<any>')
         ||' '
         ||p_time_zone
         ||'/'
         ||p_cwms_ts_id
         ||'/issue_time='
         ||nvl(to_char(p_issue_time, 'yyyy/mm/dd hh24mi'), '<any')
         ||' '
         ||p_time_zone);
   end if;
end delete_ts;

--------------------------------------------------------------------------------
-- procedure cat_ts
--------------------------------------------------------------------------------
procedure cat_ts(
   p_ts_catalog      out sys_refcursor,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_cwms_ts_id_mask in  varchar2 default '*',
   p_time_zone       in  varchar2 default null, -- null = location time zone
   p_office_id       in  varchar2 default null) -- null = user's office id   
is
   l_cwms_ts_id_mask varchar2(191);
   l_time_zone       varchar2(28);
begin
   -------------------------
   -- set local variables --
   -------------------------
   l_cwms_ts_id_mask := cwms_util.normalize_wildcards(upper(p_cwms_ts_id_mask));
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
   -----------------------
   -- perform the query --
   -----------------------
   open p_ts_catalog for
      select office_id,
             forecast_date,
             issue_date,
             cwms_ts_id,
             version_date,
             min_time,
             max_time,
             l_time_zone as time_zone_name
        from ( select o.office_id,
                      cwms_util.change_timezone(fts.forecast_date, 'UTC', l_time_zone) as forecast_date,
                      cwms_util.change_timezone(fts.issue_date, 'UTC', l_time_zone) as issue_date,
                      cwms_ts.get_ts_id(fts.ts_code) as cwms_ts_id,
                      cwms_util.change_timezone(fts.version_date, 'UTC', l_time_zone) as version_date,
                      cwms_util.change_timezone(cwms_ts.get_ts_min_date_utc(fts.ts_code, fts.version_date), 'UTC', l_time_zone) as min_time,
                      cwms_util.change_timezone(cwms_ts.get_ts_max_date_utc(fts.ts_code, fts.version_date), 'UTC', l_time_zone) as max_time
                 from at_forecast_ts fts,
                      at_physical_location pl,
                      at_base_location bl,
                      at_cwms_ts_spec cts,
                      cwms_office o
                where o.office_id = nvl(upper(p_office_id), cwms_util.user_office_id)
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and cts.location_code = pl.location_code
                  and fts.ts_code = cts.ts_code
                  and fts.forecast_spec_code = get_forecast_spec_code(p_location_id, p_forecast_id, p_office_id)
                  and upper(cwms_ts.get_ts_id(fts.ts_code)) like l_cwms_ts_id_mask escape '\'
             )
    order by office_id,
             forecast_date,
             issue_date,
             upper(cwms_ts_id);
end cat_ts;

--------------------------------------------------------------------------------
-- function cat_ts_f
--------------------------------------------------------------------------------
function cat_ts_f(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_cwms_ts_id_mask in varchar2 default '*',
   p_time_zone       in varchar2 default null, -- null = location time zone
   p_office_id       in varchar2 default null) -- null = user's office id   
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_ts(
      l_cursor,
      p_location_id,
      p_forecast_id,
      p_cwms_ts_id_mask,
      p_time_zone,
      p_office_id);

   return l_cursor;
end cat_ts_f;

--------------------------------------------------------------------------------
-- procedure store_text
--------------------------------------------------------------------------------
procedure store_text(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_time_zone       in varchar2,
   p_text            in clob,
   p_fail_if_exists  in varchar2,
   p_office_id       in varchar2 default null) -- null = user's office id
is
   l_forecast_spec_code  number(14);
   l_fail_if_exists      boolean;
   l_exists              boolean;
   l_forecast_time       date;
   l_issue_time          date;
   l_rec                 at_forecast_text%rowtype;
   l_text_id             varchar2(256);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_text is null or dbms_lob.getlength(p_text) = 0  then
      cwms_err.raise(
         'ERROR',
         'Forecast text cannot be null or empty.');
   end if;
   if p_forecast_time is null then
      cwms_err.raise(
         'ERROR',
         'Forecast date cannot be null.');
   end if;
   if p_issue_time is null then
      cwms_err.raise(
         'ERROR',
         'Issue date cannot be null.');
   end if;
   --------------------------
   -- get the forcast spec --
   --------------------------
   l_forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      p_office_id);
   -----------------------------------------
   -- determine whether the record exists --
   -----------------------------------------
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_forecast_time  := cwms_util.change_timezone(p_forecast_time, p_time_zone, 'UTC');
   l_issue_time     := cwms_util.change_timezone(p_issue_time, p_time_zone, 'UTC');
   begin
      select *
        into l_rec
        from at_forecast_text
       where forecast_spec_code = l_forecast_spec_code
         and forecast_date = l_forecast_time
         and issue_date = l_issue_time;
      l_exists := true;
   exception
      when no_data_found then l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'CWMS forecast text',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_location_id
         ||'/'
         ||p_forecast_id
         ||'/forecast_time='
         ||to_char(p_forecast_time, 'yyyy/mm/dd hh24mi')
         ||' '
         ||p_time_zone
         ||'/issue_time='
         ||to_char(p_issue_time, 'yyyy/mm/dd hh24mi')
         ||' '
         ||p_time_zone);
   end if;
   -------------------------------
   -- insert or update the text --
   -------------------------------
   if l_exists then
      update at_clob
         set at_clob.value = p_text
      where  at_clob.clob_code = l_rec.clob_code; 
   else                                    
      l_rec.forecast_spec_code := l_forecast_spec_code;
      l_rec.forecast_date      := l_forecast_time;
      l_rec.issue_date         := l_issue_time;
      l_rec.clob_code          := cwms_seq.nextval;

      l_text_id := substr(
         '/fcst/'
         ||p_forecast_id
         ||'/'
         ||cwms_util.to_millis(cwms_util.change_timezone(p_forecast_time, p_time_zone, 'UTC'))/60000 -- minutes
         ||'/'
         ||cwms_util.to_millis(cwms_util.change_timezone(p_issue_time, p_time_zone, 'UTC'))/60000 -- minutes
         ||'/'
         ||p_location_id, 
         1, 
         256);
      
      cwms_text.store_text(
         p_text_code      => l_rec.clob_code, -- out parameter
         p_text           => p_text,
         p_id             => l_text_id,
         p_description    => 'forecast text',
         p_fail_if_exists => 'F',
         p_office_id      => p_office_id);
         
      insert
        into at_forecast_text
      values l_rec;         
   end if;
end store_text;

--------------------------------------------------------------------------------
-- procedure retrieve_text
--------------------------------------------------------------------------------
procedure retrieve_text(
   p_text            out clob,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2,
   p_forecast_time   in  date,
   p_issue_time      in  date,
   p_time_zone       in  varchar2 default null, -- null = location time zone
   p_office_id       in  varchar2 default null) -- null = user's office id
is
   l_forecast_spec_code  number(14);
   l_clob_code           number(14);
   l_forecast_time       date;
   l_issue_time          date;
   l_time_zone           varchar2(28);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_forecast_time is null then
      cwms_err.raise(
         'ERROR',
         'Forecast date cannot be null.');
   end if;
   if p_issue_time is null then
      cwms_err.raise(
         'ERROR',
         'Issue date cannot be null.');
   end if;
   --------------------------
   -- get the forcast spec --
   --------------------------
   l_forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      p_office_id);
   -----------------------------------------
   -- determine whether the record exists --
   -----------------------------------------
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
   l_forecast_time  := cwms_util.change_timezone(p_forecast_time, l_time_zone, 'UTC');
   l_issue_time     := cwms_util.change_timezone(p_issue_time, l_time_zone, 'UTC');
   begin
      select clob_code
        into l_clob_code
        from at_forecast_text
       where forecast_spec_code = l_forecast_spec_code
         and forecast_date = l_forecast_time
         and issue_date = l_issue_time;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS forecast text',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_forecast_id
            ||'/forecast_time='
            ||to_char(p_forecast_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||l_time_zone
            ||'/issue_time='
            ||to_char(p_issue_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||l_time_zone);
   end;
   ------------------
   -- get the text --
   ------------------
   select at_clob.value
     into p_text
     from at_clob
    where at_clob.clob_code = l_clob_code;
end retrieve_text;

--------------------------------------------------------------------------------
-- procedure delete_text
--------------------------------------------------------------------------------
procedure delete_text(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,                  -- null = all forecast times
   p_issue_time      in date,                  -- null = all issue times
   p_time_zone       in varchar2 default null, -- null = location time zone
   p_office_id       in varchar2 default null) -- null = user's office id
is
   l_forecast_spec_code  number(14);
   l_clob_code           number(14);
   l_forecast_time       date;
   l_issue_time          date;
   l_time_zone           varchar2(28);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_forecast_time is null then
      cwms_err.raise(
         'ERROR',
         'Forecast date cannot be null.');
   end if;
   if p_issue_time is null then
      cwms_err.raise(
         'ERROR',
         'Issue date cannot be null.');
   end if;
   --------------------------
   -- get the forcast spec --
   --------------------------
   l_forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      p_office_id);
   -----------------------------------------
   -- determine whether the record exists --
   -----------------------------------------
   l_time_zone := cwms_loc.get_local_timezone(p_location_id, p_office_id);
   l_forecast_time  := cwms_util.change_timezone(p_forecast_time, l_time_zone, 'UTC');
   l_issue_time     := cwms_util.change_timezone(p_issue_time, l_time_zone, 'UTC');
   begin
      select clob_code
        into l_clob_code
        from at_forecast_text
       where forecast_spec_code = l_forecast_spec_code
         and forecast_date = l_forecast_time
         and issue_date = l_issue_time;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS forecast text',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_forecast_id
            ||'/forecast_time='
            ||to_char(p_forecast_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||l_time_zone
            ||'/issue_time='
            ||to_char(p_issue_time, 'yyyy/mm/dd hh24mi')
            ||' '
            ||l_time_zone);
   end;
end delete_text;

--------------------------------------------------------------------------------
-- procedure cat_text
--------------------------------------------------------------------------------
procedure cat_text(
   p_text_catalog out sys_refcursor,
   p_location_id  in  varchar2,
   p_forecast_id  in  varchar2,
   p_time_zone    in  varchar2 default null, -- null = location time zone
   p_office_id    in  varchar2 default null) -- null = user's office id   
is
   l_time_zone  varchar2(28);
begin
   -------------------
   -- sanity checks --
   -------------------
   -------------------------
   -- set local variables --
   -------------------------
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
   -----------------------
   -- perform the query --
   -----------------------
   open p_text_catalog for
      select office_id,
             forecast_date,
             issue_date,
             text_id,
             l_time_zone as time_zone_name
        from ( select o.office_id,
                      cwms_util.change_timezone(ft.forecast_date, 'UTC', l_time_zone) as forecast_date,
                      cwms_util.change_timezone(ft.issue_date, 'UTC', l_time_zone) as issue_date,
                      c.id as text_id
                 from at_forecast_text ft,
                      at_clob c,
                      cwms_office o
                where ft.forecast_spec_code = get_forecast_spec_code(p_location_id, p_forecast_id, p_office_id)
                  and c.clob_code = ft.clob_code
                  and o.office_code = c.office_code
             )
    order by office_id,
             forecast_date,
             issue_date;
end cat_text;

--------------------------------------------------------------------------------
-- function cat_text_f
--------------------------------------------------------------------------------
function cat_text_f (
   p_location_id  in varchar2,
   p_forecast_id  in varchar2,
   p_time_zone    in varchar2 default null, -- null = location time zone
   p_office_id    in varchar2 default null) -- null = user's office id   
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_text(
      l_cursor,
      p_location_id,
      p_forecast_id,
      p_time_zone,
      p_office_id);

   return l_cursor;
end cat_text_f;
--------------------------------------------------------------------------------
-- procedure delete_spec
--------------------------------------------------------------------------------
procedure delete_spec(
   p_location_id    in varchar2,
   p_forecast_id    in varchar2,
   p_delete_action  in varchar2 default cwms_util.delete_key,
   p_office_id      in varchar2 default null) -- null = user's office id
is
   l_forecast_spec_code number(14);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier cannot be null');
   end if;
   if p_forecast_id is null then
      cwms_err.raise(
         'ERROR',
         'Forecast identifier cannot be null');
   end if;
   if upper(p_delete_action) not in
      (  cwms_util.delete_all,
         cwms_util.delete_data,
         cwms_util.delete_key
      )
   then
      cwms_err.raise('INVALID_DELETE_ACTION', p_delete_action);
   end if;
   ------------------------------
   -- see if the record exists --
   ------------------------------
   l_forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      p_office_id);
   ----------------------------------
   -- delete children if specified --
   ----------------------------------
   if upper(p_delete_action) in
      (  cwms_util.delete_all,
         cwms_util.delete_data
      )
   then
      delete_ts(
         p_location_id   => p_location_id,
         p_forecast_id   => p_forecast_id,
         p_cwms_ts_id    => null,
         p_forecast_time => null,
         p_issue_time    => null,
         p_office_id     => p_office_id);

      delete_text(
         p_location_id   => p_location_id,
         p_forecast_id   => p_forecast_id,
         p_forecast_time => null,
         p_issue_time    => null,
         p_office_id     => p_office_id);
   end if;
   --------------------------------
   -- delete record if specified --
   --------------------------------
   if upper(p_delete_action) in
      (  cwms_util.delete_all,
         cwms_util.delete_key
      )
   then
      delete
        from at_forecast_spec
       where forecast_spec_code = l_forecast_spec_code;
   end if;
end delete_spec;

--------------------------------------------------------------------------------
-- procedure store_forecast
--------------------------------------------------------------------------------
procedure store_forecast(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_time_zone       in varchar2, -- null = location time zone
   p_fail_if_exists  in varchar2,
   p_text            in clob,
   p_time_series     in ztimeseries_array,
   p_store_rule      in varchar2 default null, -- null = DELETE INSERT
   p_office_id       in varchar2 default null) -- null = user's office id
is
   l_time_zone    varchar2(28);
   l_version_date date;
begin
   -------------------------
   -- set local variables --
   -------------------------
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
   l_version_date := cast(systimestamp at time zone l_time_zone as date);
   --------------------------------
   -- store the time series data --
   --------------------------------
   if p_time_series is not null then
      for i in 1..p_time_series.count loop
         if p_time_series(i).data is not null then
            store_ts(
               p_location_id     => p_location_id,
               p_forecast_id     => p_forecast_id,
               p_cwms_ts_id      => p_time_series(i).tsid,
               p_units           => p_time_series(i).unit,
               p_forecast_time   => p_forecast_time,
               p_issue_time      => p_issue_time,
               p_version_date    => l_version_date,
               p_time_zone       => l_time_zone,
               p_timeseries_data => p_time_series(i).data,
               p_fail_if_exists  => p_fail_if_exists,
               p_store_rule      => p_store_rule,
               p_office_id       => p_office_id);
         end if;
      end loop;
   end if;
   -------------------------
   -- store the text data --
   -------------------------
   if p_text is not null then
      cwms_forecast.store_text(
         p_location_id    => p_location_id,
         p_forecast_id    => p_forecast_id,
         p_forecast_time  => p_forecast_time,
         p_issue_time     => p_issue_time,
         p_time_zone      => l_time_zone,
         p_text           => p_text,
         p_fail_if_exists => p_fail_if_exists,
         p_office_id      => p_office_id);
   end if;
end store_forecast;

--------------------------------------------------------------------------------
-- procedure retrieve_forecast
--------------------------------------------------------------------------------
procedure retrieve_forecast(
   p_time_series     out ztimeseries_array,
   p_text            out clob,
   p_location_id     in  varchar2,
   p_forecast_id     in  varchar2, 
   p_unit_system     in  varchar2 default null, -- null = retrieved from preferences, SI if none
   p_forecast_time   in  date     default null, -- null = most recent
   p_issue_time      in  date     default null, -- null = most_recent
   p_time_zone       in  varchar2 default null, -- null = location time zone
   p_office_id       in  varchar2 default null) -- null = user's office id
is
   type cat_ts_rec_t is record (
      office_id      varchar2(16),
      forecast_date  date,          
      issue_date     date,         
      cwms_ts_id     varchar2(191),
      version_date   date,
      min_time       date,
      max_time       date,
      time_zone_name varchar2(28));
   type ts_rec_t is record (
      date_time    date,
      value        binary_double,
      quality_code integer);        
   l_forecast_spec_code number(14);
   l_unit_system        varchar2(2);
   l_time_zone          varchar2(28);
   l_forecast_time      date;
   l_issue_time         date;
   l_time               date;
   l_cat_ts_cur         sys_refcursor;
   l_ts_cur             sys_refcursor;
   l_cat_ts_rec         cat_ts_rec_t;
   l_ts_rec             ts_rec_t;
   l_parts              str_tab_t;
   l_units              varchar2(16);
begin
   --------------------------------
   -- get the forecast spec code --
   --------------------------------
   l_forecast_spec_code := get_forecast_spec_code(
      p_location_id,
      p_forecast_id,
      p_office_id);
   -------------------------
   -- set local variables --
   -------------------------
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
   if p_unit_system is null then
      l_unit_system := cwms_properties.get_property(
         'Pref_User.'||cwms_util.get_user_id, 
         'Unit_System', 
         cwms_properties.get_property(
            'Pref_Office',
            'Unit_System',
            'SI',
            p_office_id), 
         p_office_id);
   else
      l_unit_system := p_unit_system;
   end if; 
   if p_forecast_time is null then
      select max(forecast_date)
        into l_forecast_time
        from at_forecast_ts
       where forecast_spec_code = l_forecast_spec_code;
      select max(forecast_date)
        into l_time
        from at_forecast_text
       where forecast_spec_code = l_forecast_spec_code;
      l_forecast_time := cwms_util.change_timezone(greatest(l_forecast_time, l_time), 'UTC', l_time_zone);        
   else
      l_forecast_time := p_forecast_time;
   end if;      
   if p_issue_time is null then
      select max(issue_date)
        into l_issue_time
        from at_forecast_ts
       where forecast_spec_code = l_forecast_spec_code;
      select max(issue_date)
        into l_time
        from at_forecast_text
       where forecast_spec_code = l_forecast_spec_code;
      l_issue_time := cwms_util.change_timezone(greatest(l_issue_time, l_time), 'UTC', l_time_zone);        
   else
      l_issue_time := p_issue_time;
   end if;
   ----------------------------         
   -- retrieve the text data --
   ----------------------------
   retrieve_text(p_text, p_location_id, p_forecast_id, l_forecast_time, l_issue_time, l_time_zone, p_office_id);
   -----------------------------------
   -- retrieve the time series data --
   -----------------------------------
   cat_ts(l_cat_ts_cur, p_location_id, p_forecast_id, '*', l_time_zone, p_office_id);
   loop
      fetch l_cat_ts_cur into l_cat_ts_rec;
      exit when l_cat_ts_cur%notfound;
      l_parts := cwms_util.split_text(l_cat_ts_rec.cwms_ts_id, '.');
      begin
         cwms_display.retrieve_unit(l_units, l_parts(2), l_unit_system, p_office_id); 
      exception
         when others then
            l_units := cwms_util.get_default_units(l_parts(2), l_unit_system);
      end;
      if l_cat_ts_rec.forecast_date = l_forecast_time and l_cat_ts_rec.issue_date = l_issue_time then
         retrieve_ts(
            p_ts_cursor     => l_ts_cur,
            p_version_date  => l_time, -- out parameter
            p_location_id   => p_location_id,
            p_forecast_id   => p_forecast_id,
            p_cwms_ts_id    => l_cat_ts_rec.cwms_ts_id,
            p_units         => l_units,
            p_forecast_time => l_forecast_time,
            p_issue_time    => l_issue_time,
            p_start_time    => l_cat_ts_rec.min_time,
            p_end_time      => l_cat_ts_rec.max_time,
            p_time_zone     => l_time_zone,
            p_office_id     => p_office_id);
         if p_time_series is null then
            p_time_series := ztimeseries_array();
         end if;
         p_time_series.extend;
         p_time_series(p_time_series.count) := ztimeseries_type(
            l_cat_ts_rec.cwms_ts_id,
            l_units,
            ztsv_array());
         p_time_series(p_time_series.count).data := ztsv_array();
         loop
            fetch l_ts_cur into l_ts_rec;
            exit when l_ts_cur%notfound;
            p_time_series(p_time_series.count).data.extend;
            p_time_series(p_time_series.count).data(p_time_series(p_time_series.count).data.count):= ztsv_type(
               l_ts_rec.date_time,
               l_ts_rec.value,
               l_ts_rec.quality_code);
         end loop;                      
         close l_ts_cur;
      end if;
   end loop;
   close l_cat_ts_cur;
            
end retrieve_forecast;
--------------------------------------------------------------------------------
-- procedure delete_forecast
--------------------------------------------------------------------------------
procedure delete_forecast(
   p_location_id     in varchar2,
   p_forecast_id     in varchar2,
   p_forecast_time   in date,
   p_issue_time      in date,
   p_time_zone       in varchar2, -- null = location time zone
   p_override_prot   in varchar2 default 'F',
   p_office_id       in varchar2 default null) -- null = user's office id
is
   type cat_ts_rec_t is record(
      office_id      varchar2(16),
      forecast_date  date,
      issue_date     date,
      cwms_ts_id     varchar2(191),
      version_date   date,
      min_date       date,
      max_date       date,
      time_zone_name varchar2(28));
   type cat_text_rec_t is record(
      office_id      varchar2(16),
      forecast_date  date,
      issue_date     date,
      text_id        varchar2(256),
      time_zone_name varchar2(28));
      
   l_cursor        sys_refcursor;
   l_cat_ts_rec    cat_ts_rec_t;
   l_cat_text_rec  cat_text_rec_t;
   l_ts_code       integer;
   l_forecast_time date;
   l_issue_time    date;
begin
   l_forecast_time := cwms_util.change_timezone(p_forecast_time, p_time_zone, 'UTC');
   l_issue_time := cwms_util.change_timezone(p_issue_time, p_time_zone, 'UTC');
   ----------------------------------
   -- first delete the time series --
   ----------------------------------
   l_cursor := cat_ts_f(
      p_location_id     => p_location_id,
      p_forecast_id     => p_forecast_id,
      p_cwms_ts_id_mask => '*',
      p_time_zone       => 'UTC',
      p_office_id       => p_office_id);
      
   loop   
      fetch l_cursor into l_cat_ts_rec;
      exit when l_cursor%notfound;
      continue when l_cat_ts_rec.forecast_date != l_forecast_time;
      continue when l_cat_ts_rec.issue_date != l_issue_time;

      l_ts_code := cwms_ts.get_ts_code(l_cat_ts_rec.cwms_ts_id, l_cat_ts_rec.office_id);
      
      delete
        from at_forecast_ts
       where ts_code = l_ts_code
         and forecast_date = l_forecast_time
         and issue_date = l_issue_time
         and version_date = l_cat_ts_rec.version_date;
         
      cwms_ts.purge_ts_data(
         p_ts_code             => l_ts_code,
         p_override_protection => p_override_prot,
         p_version_date_utc    => l_cat_ts_rec.version_date,
         p_start_time_utc      => l_cat_ts_rec.min_date,
         p_end_time_utc        => l_cat_ts_rec.max_date,
         p_max_version         => 'F',
         p_ts_item_mask        => cwms_util.ts_values);
   end loop;
   close l_cursor;
   --------------------------
   -- next delete the text --
   --------------------------
   l_cursor := cat_text_f(
      p_location_id     => p_location_id,
      p_forecast_id     => p_forecast_id,
      p_time_zone       => 'UTC',
      p_office_id       => p_office_id);
   loop
      fetch l_cursor into l_cat_text_rec;
      exit when l_cursor%notfound;
      continue when l_cat_text_rec.forecast_date != l_forecast_time;
      continue when l_cat_text_rec.issue_date != l_issue_time;
      
      delete
        from at_forecast_text
       where clob_code = (select clob_code
                            from at_clob c,
                                 cwms_office o
                           where c.office_code = o.office_code
                             and c.id = l_cat_text_rec.text_id
                             and o.office_id = l_cat_text_rec.office_id
                         );
      
      cwms_text.delete_text(l_cat_text_rec.text_id, p_office_id);
   end loop;
   close l_cursor;
   
end delete_forecast;
--------------------------------------------------------------------------------
-- procedure cat_forecast
--------------------------------------------------------------------------------
procedure cat_forecast(
   p_fcst_catalog     out sys_refcursor,
   p_location_id_mask in  varchar2,
   p_forecast_id_mask in  varchar2,
   p_max_fcst_age     in  varchar2 default 'P1Y',
   p_max_issue_age    in  varchar2 default 'P1Y',
   p_abbreviated      in  varchar2 default 'T',
   p_time_zone        in  varchar2 default null, -- null = location time zone
   p_office_id_mask   in  varchar2 default null) -- null = user's office id
is
   l_time_zone      varchar2(28);
   l_loc_id_mask    varchar2(256);
   l_fcst_id_mask   varchar2(32);
   l_office_id_mask varchar2(16);
   l_fcst_ym_intvl  yminterval_unconstrained;
   l_fcst_ds_intvl  dsinterval_unconstrained;
   l_issue_ym_intvl yminterval_unconstrained;
   l_issue_ds_intvl dsinterval_unconstrained;
   l_min_fcst_date  date;
   l_min_issue_date date;
begin
   -------------------------
   -- set local variables --
   -------------------------
   l_loc_id_mask  := cwms_util.normalize_wildcards(upper(p_location_id_mask));
   l_fcst_id_mask := cwms_util.normalize_wildcards(upper(p_forecast_id_mask));
   if p_office_id_mask is null then
      l_office_id_mask := cwms_util.user_office_id;
   else
      l_office_id_mask := cwms_util.normalize_wildcards(upper(p_office_id_mask));
   end if;
   
   cwms_util.duration_to_interval(
      l_fcst_ym_intvl,
      l_fcst_ds_intvl,
      p_max_fcst_age);
      
   l_min_fcst_date := cast(systimestamp - l_fcst_ym_intvl - l_fcst_ds_intvl as date);      
      
   cwms_util.duration_to_interval(
      l_issue_ym_intvl,
      l_issue_ds_intvl,
      p_max_issue_age);
      
   l_min_issue_date := cast(systimestamp - l_issue_ym_intvl - l_issue_ds_intvl as date);      
   -----------------------
   -- perform the query --
   -----------------------
   if cwms_util.is_true(nvl(p_abbreviated, 'T')) then
      open p_fcst_catalog for
         select distinct 
                nvl(q1.office_id, q2.office_id) as office_id,
                cwms_loc.get_location_id(nvl(q1.target_location_code, q2.target_location_code)) as location_id,
                nvl(q1.forecast_id, q2.forecast_id) as forecast_id,
                nvl(q1.forecast_date, q2.forecast_date) as forecast_date,
                nvl(q1.issue_date, q2.issue_date) as issue_date,
                case when q2.text_id is null then 'F' else 'T' end as has_text,
                case when q1.cwms_ts_id is null then 'F' else 'T' end as has_time_series,
                nvl(q1.time_zone_name, q2.time_zone_name) as time_zone_name,
                nvl(q1.valid, q2.valid) as valid
           from ( select o.office_id,
                         fs.target_location_code,
                         fs.forecast_id,
                         fts.forecast_spec_code,
                         cwms_util.change_timezone(fts.forecast_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as forecast_date,
                         cwms_util.change_timezone(fts.issue_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as issue_date,
                         cwms_ts.get_ts_id(fts.ts_code) as cwms_ts_id,
                         nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code)) as time_zone_name,
                         case
                         when fs.max_age is null or (sysdate - fts.issue_date) * 24 < fs.max_age then 'T'
                         else 'F'
                         end as valid
                    from at_forecast_ts fts,
                         at_forecast_spec fs,
                         at_physical_location pl,
                         at_base_location bl,
                         at_cwms_ts_spec cts,
                         cwms_office o
                   where o.office_id like l_office_id_mask escape '\'
                     and bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id) like l_loc_id_mask escape '\'
                     and fs.target_location_code = pl.location_code
                     and upper(fs.forecast_id) like l_fcst_id_mask escape '\'
                     and cts.location_code = pl.location_code
                     and fts.ts_code = cts.ts_code
                     and fts.forecast_date >= l_min_fcst_date
                     and fts.issue_date >= l_min_issue_date
                     and fts.forecast_spec_code = fs.forecast_spec_code
                ) q1
                full outer join
                ( select o.office_id,
                         fs.target_location_code,
                         fs.forecast_id,
                         ft.forecast_spec_code,
                         cwms_util.change_timezone(ft.forecast_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as forecast_date,
                         cwms_util.change_timezone(ft.issue_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as issue_date,
                         c.id as text_id,
                         nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code)) as time_zone_name,
                         case
                         when fs.max_age is null or (sysdate - ft.issue_date) * 24 < fs.max_age then 'T'
                         else 'F'
                         end as valid
                    from at_forecast_text ft,
                         at_forecast_spec fs,
                         at_physical_location pl,
                         at_base_location bl,
                         at_clob c,
                         cwms_office o
                   where o.office_id like l_office_id_mask escape '\'
                     and bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id) like l_loc_id_mask escape '\'
                     and fs.target_location_code = pl.location_code
                     and upper(fs.forecast_id) like l_fcst_id_mask escape '\'
                     and ft.forecast_spec_code = fs.forecast_spec_code
                     and c.clob_code = ft.clob_code
                ) q2 on q2.forecast_spec_code = q1.forecast_spec_code
                    and q2.forecast_date      = q1.forecast_date
                    and q2.issue_date         = q1.issue_date
       order by 1,2,3,4,5;
   else
      open p_fcst_catalog for
         select nvl(q1.office_id, q2.office_id) as office_id,
                cwms_loc.get_location_id(nvl(q1.target_location_code, q2.target_location_code)) as location_id,
                nvl(q1.forecast_id, q2.forecast_id) as forecast_id,
                nvl(q1.forecast_date, q2.forecast_date) as forecast_date,
                nvl(q1.issue_date, q2.issue_date) as issue_date,
                q2.text_id,
                q1.cwms_ts_id,
                q1.version_date,
                q1.min_time,
                q1.max_time,
                nvl(q1.time_zone_name, q2.time_zone_name) as time_zone_name,
                nvl(q1.valid, q2.valid) as valid
           from ( select o.office_id,
                         fs.target_location_code,
                         fs.forecast_id,
                         fts.forecast_spec_code,
                         cwms_util.change_timezone(fts.forecast_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as forecast_date,
                         cwms_util.change_timezone(fts.issue_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as issue_date,
                         cwms_ts.get_ts_id(fts.ts_code) as cwms_ts_id,
                         cwms_util.change_timezone(fts.version_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as version_date,
                         cwms_util.change_timezone(cwms_ts.get_ts_min_date_utc(fts.ts_code, fts.version_date), 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as min_time,
                         cwms_util.change_timezone(cwms_ts.get_ts_max_date_utc(fts.ts_code, fts.version_date), 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as max_time,
                         nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code)) as time_zone_name,
                         case
                         when fs.max_age is null then null
                         when (sysdate - fts.issue_date) * 24 < fs.max_age then 'T'
                         else 'F'
                         end as valid
                    from at_forecast_ts fts,
                         at_forecast_spec fs,
                         at_physical_location pl,
                         at_base_location bl,
                         at_cwms_ts_spec cts,
                         cwms_office o
                   where o.office_id like l_office_id_mask escape '\'
                     and bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id) like l_loc_id_mask escape '\'
                     and fs.target_location_code = pl.location_code
                     and upper(fs.forecast_id) like l_fcst_id_mask escape '\'
                     and cts.location_code = pl.location_code
                     and fts.ts_code = cts.ts_code
                     and fts.forecast_date >= l_min_fcst_date
                     and fts.issue_date >= l_min_issue_date
                     and fts.forecast_spec_code = fs.forecast_spec_code
                ) q1
                full outer join
                ( select o.office_id,
                         fs.target_location_code,
                         fs.forecast_id,
                         ft.forecast_spec_code,
                         cwms_util.change_timezone(ft.forecast_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as forecast_date,
                         cwms_util.change_timezone(ft.issue_date, 'UTC', nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code))) as issue_date,
                         c.id as text_id,
                         nvl(p_time_zone, cwms_loc.get_local_timezone(pl.location_code)) as time_zone_name,
                         case
                         when fs.max_age is null or (sysdate - ft.issue_date) * 24 < fs.max_age then 'T'
                         else 'F'
                         end as valid
                    from at_forecast_text ft,
                         at_forecast_spec fs,
                         at_physical_location pl,
                         at_base_location bl,
                         at_clob c,
                         cwms_office o
                   where o.office_id like l_office_id_mask escape '\'
                     and bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id) like l_loc_id_mask escape '\'
                     and fs.target_location_code = pl.location_code
                     and upper(fs.forecast_id) like l_fcst_id_mask escape '\'
                     and ft.forecast_spec_code = fs.forecast_spec_code
                     and c.clob_code = ft.clob_code
                ) q2 on q2.forecast_spec_code = q1.forecast_spec_code
                    and q2.forecast_date      = q1.forecast_date
                    and q2.issue_date         = q1.issue_date
       order by 1,2,3,4,5;
   end if;
end cat_forecast;
--------------------------------------------------------------------------------
-- function cat_forecast_f
--------------------------------------------------------------------------------
function cat_forecast_f(
   p_location_id_mask in varchar2,
   p_forecast_id_mask in varchar2,
   p_max_fcst_age     in varchar2 default 'P1Y',
   p_max_issue_age    in varchar2 default 'P1Y',
   p_abbreviated      in  varchar2 default 'T',
   p_time_zone        in varchar2 default null, -- null = location time zone
   p_office_id_mask   in varchar2 default null) -- null = user's office id   
   return sys_refcursor
is
 l_fcst_catalog sys_refcursor;
begin
   cat_forecast(
      l_fcst_catalog,
      p_location_id_mask,
      p_forecast_id_mask,
      p_max_fcst_age,
      p_max_issue_age,
      p_abbreviated,
      p_time_zone,
      p_office_id_mask);
      
   return l_fcst_catalog;      
end cat_forecast_f;

end cwms_forecast;
/
show errors;
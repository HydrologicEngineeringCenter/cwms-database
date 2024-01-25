create or replace package body cwms_ts_profile
as
--------------------------------------------------------------------------------
-- undocumented function make_ts_id
--------------------------------------------------------------------------------
function make_ts_id(
   p_location_code  in integer,
   p_parameter_code in integer,
   p_version_id     in varchar2)
   return varchar2
is
   l_ts_id varchar2(191);
begin
   l_ts_id := cwms_loc.get_location_id(p_location_code)
      ||'.'||cwms_util.get_parameter_id(p_parameter_code)
      ||'.Inst.0.0.'||p_version_id;
   return l_ts_id;
end make_ts_id;

-------------------------------------------------------------------------------
-- private function parse_ts_prof_inst_text_codes
-------------------------------------------------------------------------------
function parse_ts_prof_inst_text_codes(
   p_location_code      in varchar2,
   p_key_parameter_code in varchar2,
   p_text               in clob,
   p_time_zone_code     in varchar2)
   return ts_prof_data_t
is
   type assoc_t is table of integer index by varchar2(16);
   l_ts_profile_data ts_prof_data_t;
   l_parser_rec      at_ts_profile_parser%rowtype;
   l_parameter_codes number_tab_t;
   l_unit_codes      number_tab_t;
   l_field_numbers   number_tab_t;
   l_start_columns   number_tab_t;
   l_end_columns     number_tab_t;
   l_lines           str_tab_t;
   l_fields          str_tab_t;
   l_text            varchar2(256);
   l_date_str        varchar2(32);
   l_date            date;
   l_parser_assoc    assoc_t; -- table index by parameter_code
   l_param_assoc     assoc_t; -- parameter_code by position
   l_rec_idx         pls_integer;
   l_param_idx       pls_integer;
   l_position        pls_integer;
   l_start_col       pls_integer;
   l_end_col         pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_code      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_CODE'  );    end if;
   if p_key_parameter_code is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_CODE'); end if;
   --------------------------------
   -- retrieve the parser record --
   --------------------------------
   begin
      select *
        into l_parser_rec
        from at_ts_profile_parser
       where location_code = p_location_code
         and key_parameter_code = p_key_parameter_code;
   exception
      when no_data_found then
         declare
            l_office_id        integer;
            l_location_id      integer;
            l_key_parameter_id integer;
         begin
            select co.office_id,
                   abl.base_location_id||substr('-',1,length(apl.sub_location_id))||apl.sub_location_id
              into l_office_id,
                   l_location_id
              from at_physical_location apl,
                   at_base_location abl,
                   cwms_office co
             where apl.location_code = p_location_code
               and abl.base_location_code = apl.base_location_code
               and co.office_code = abl.db_office_code;
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Time series profile parser',
               l_office_id||'/'||l_location_id||'/'||l_key_parameter_id);
         end;
   end;
   -------------------------------------------
   -- retrieve the parser parameter records --
   -------------------------------------------
   select parameter_code,
          parameter_unit,
          parameter_field,
          parameter_col_start,
          parameter_col_end
     bulk collect
     into l_parameter_codes,
          l_unit_codes,
          l_field_numbers,
          l_start_columns,
          l_end_columns
     from at_ts_profile_parser_param
    where location_code = p_location_code
      and key_parameter_code = p_key_parameter_code;
   -----------------------------------------------
   -- build the position-to-table index indexes --
   -----------------------------------------------
   for i in 1..l_parameter_codes.count loop
      l_parser_assoc(l_parameter_codes(i)) := i;
   end loop;
   l_param_idx := l_parser_assoc.first;
   loop
      exit when l_param_idx is null;
      l_param_idx := l_parser_assoc.next(l_param_idx);
   end loop;
   for rec in (select position,
                      parameter_code
                 from at_ts_profile_param
                where location_code = p_location_code
                  and key_parameter_code = p_key_parameter_code
              )
   loop
      if not l_parser_assoc.exists(rec.parameter_code) then
         cwms_err.raise('ERROR', 'Parser does not contain information for parameter '||cwms_util.get_parameter_id(rec.parameter_code));
      end if;
      l_param_assoc(rec.position) := rec.parameter_code;
   end loop;
   l_param_idx := l_param_assoc.first;
   loop
      exit when l_param_idx is null;
      l_param_idx := l_param_assoc.next(l_param_idx);
   end loop;
   --------------------
   -- parse the text --
   --------------------
   if p_text is not null then
      l_ts_profile_data := ts_prof_data_t(
         location_code => l_parser_rec.location_code,
         key_parameter => l_parser_rec.key_parameter_code,
         time_zone     => null,
         units         => null,
         records       => ts_prof_data_tab_t());

      select time_zone_name
        into l_ts_profile_data.time_zone
        from cwms_time_zone
       where time_zone_code = p_time_zone_code;

      l_ts_profile_data.units := str_tab_t();
      l_ts_profile_data.units.extend(l_unit_codes.count);

      l_lines := cwms_util.split_text(p_text, l_parser_rec.record_delimiter);
      for i in 1..l_lines.count loop
         continue when trim(trim('"' from trim(l_lines(i)))) is null;
         if l_parser_rec.field_delimiter is null then
            -------------------------
            -- fiexed with parsing --
            -------------------------
            ------------------------------------------
            -- skip records without parseable dates --
            ------------------------------------------
            l_text := trim(trim('"' from trim(
                  substr(l_lines(i),
                     l_parser_rec.time_col_start,
                     l_parser_rec.time_col_end-l_parser_rec.time_col_start+1))));
            begin
               l_date := to_date(l_text, l_parser_rec.time_format);
            exception
               when others then continue;
            end;
            continue when to_char(l_date, l_parser_rec.time_format) != l_text;
            ---------------------------
            -- build the data record --
            ---------------------------
            l_ts_profile_data.records.extend;
            l_rec_idx := l_ts_profile_data.records.count;
            l_ts_profile_data.records(l_rec_idx) := ts_prof_data_rec_t(
               date_time  => l_date,
               parameters => pvq_tab_t());
            l_position := l_param_assoc.first;
            loop
               exit when l_position is null;
               l_ts_profile_data.records(l_rec_idx).parameters.extend;
               l_param_idx := l_ts_profile_data.records(l_rec_idx).parameters.count;
               if l_rec_idx = 1 then
                  l_ts_profile_data.units(l_param_idx) := cwms_util.get_unit_id2(l_unit_codes(l_parser_assoc(l_param_assoc(l_position))));
               end if;
               l_start_col := l_start_columns(l_parser_assoc(l_param_assoc(l_position)));
               l_end_col := l_end_columns(l_parser_assoc(l_param_assoc(l_position)));
               l_text := trim(trim('"' from trim(substr(l_lines(i), l_start_col, l_end_col-l_start_col+1))));
               l_ts_profile_data.records(l_rec_idx).parameters(l_param_idx) := pvq_t(
                  parameter_code => l_param_assoc(l_position),
                  value          => l_text,
                  quality_code   => 0);
               l_position := l_param_assoc.next(l_position);
            end loop;
         else
            ------------------------
            -- delimited parsing --
            ------------------------
            l_fields := cwms_util.parse_delimited_text(l_lines(i), l_parser_rec.field_delimiter)(1);
            for j in 1..l_fields.count loop
               l_fields(j) := trim(trim('"' from trim(l_fields(j))));
            end loop;
            ------------------------------------------
            -- skip records without parseable dates --
            ------------------------------------------
            begin
               if l_parser_rec.time_in_two_fields = 'T' then
                  l_date_str := l_fields(l_parser_rec.time_field)||l_parser_rec.field_delimiter||l_fields(l_parser_rec.time_field+1);
               else
                  l_date_str := l_fields(l_parser_rec.time_field);
               end if;
               l_date := to_date(l_date_str, l_parser_rec.time_format);
               continue when upper(to_char(l_date, l_parser_rec.time_format)) != upper(regexp_replace(l_date_str, '(^|\D)(\d)(\D)', '\10\2\3'));
            exception
               when others then continue;
            end;
            ---------------------------
            -- build the data record --
            ---------------------------
            l_ts_profile_data.records.extend;
            l_rec_idx := l_ts_profile_data.records.count;
            l_ts_profile_data.records(l_rec_idx) := ts_prof_data_rec_t(
               date_time  => l_date,
               parameters => pvq_tab_t());
            l_position := l_param_assoc.first;
            loop
               exit when l_position is null;
               l_ts_profile_data.records(l_rec_idx).parameters.extend;
               l_param_idx := l_ts_profile_data.records(l_rec_idx).parameters.count;
               if l_rec_idx = 1 then
                  l_ts_profile_data.units(l_param_idx) := cwms_util.get_unit_id2(l_unit_codes(l_parser_assoc(l_param_assoc(l_position))));
               end if;
               l_ts_profile_data.records(l_rec_idx).parameters(l_param_idx) := pvq_t(
                  parameter_code => l_param_assoc(l_position),
                  value          => trim(trim('"' from trim(l_fields(l_field_numbers(l_parser_assoc(l_param_assoc(l_position))))))),
                  quality_code   => 0);
               l_position := l_param_assoc.next(l_position);
            end loop;
         end if;
      end loop;
   end if;
   return l_ts_profile_data;
end parse_ts_prof_inst_text_codes;

--------------------------------------------------------------------------------
-- procedure store_ts_profile
--------------------------------------------------------------------------------
procedure store_ts_profile(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_profile_params   in varchar2,
   p_description      in varchar2,
   p_ref_ts_id        in varchar2 default null,
   p_fail_if_exists   in varchar2 default 'T',
   p_ignore_nulls     in varchar2 default 'T',
   p_office_id        in varchar2 default null)
is
   l_ts_profile ts_profile_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'  );    end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   --------------------------------------
   -- populate the ts_profile_t object --
   --------------------------------------
   l_ts_profile := ts_profile_t(
      location         => location_ref_t(p_location_id, cwms_util.get_db_office_id(p_office_id)),
      key_parameter_id => p_key_parameter_id,
      profile_params   => case
                          when p_profile_params is null then null
                          else cwms_util.parse_delimited_text(p_profile_params)(1)
                          end,
      reference_ts_id  => p_ref_ts_id,
      description      => p_description);
   -----------------------------
   -- call the base procedure --
   -----------------------------
   store_ts_profile(
      p_ts_profile     => l_ts_profile,
      p_fail_if_exists => p_fail_if_exists,
      p_ignore_nulls   => p_ignore_nulls);
end store_ts_profile;
--------------------------------------------------------------------------------
-- procedure store_ts_profile
--------------------------------------------------------------------------------
procedure store_ts_profile(
   p_ts_profile      in ts_profile_t,
   p_fail_if_exists  in varchar2 default 'T',
   p_ignore_nulls    in varchar2 default 'T')
is
   l_fail_if_exists       boolean;
   l_ignore_nulls         boolean;
   l_exists               boolean;
   l_update_params        boolean;
   l_office_id            varchar2(16);
   l_location_code        integer;
   l_office_code          integer;
   l_key_parameter_code   integer;
   l_ref_ts_code          integer;
   l_parameter_codes      number_tab_t;
   l_existing_param_codes number_tab_t;
   l_profile_rec          at_ts_profile%rowtype;
   l_count                pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_ts_profile   is null then cwms_err.raise('NULL_ARGUMENT', 'P_TS_PROFILE'); end if;
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.return_true_or_false(p_ignore_nulls);
   -------------------------------------------------------------------
   -- get the office, location, key parameter and time series codes --
   -------------------------------------------------------------------
   l_office_id   := p_ts_profile.location.get_office_id;
   l_office_code := p_ts_profile.location.get_office_code;
   l_key_parameter_code := cwms_util.get_parameter_code(p_ts_profile.key_parameter_id, l_office_id);
   begin
      l_location_code := p_ts_profile.location.get_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'LOCATION_ID_NOT_FOUND',
            l_office_id
            ||'/'
            ||p_ts_profile.location.get_location_id);
   end;
   if p_ts_profile.reference_ts_id is not null then
      l_ref_ts_code := cwms_ts.get_ts_code(p_ts_profile.reference_ts_id, l_office_id);
   end if;
   ---------------------------------------------
   -- get the existing record if there is one --
   ---------------------------------------------
   begin
      select *
        into l_profile_rec
        from at_ts_profile
       where location_code = l_location_code
         and key_parameter_code = l_key_parameter_code;
      l_exists := true;
   exception
      when no_data_found then
         l_exists := false;
   end;
   -----------------------------
   -- handle existing profile --
   -----------------------------
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Time series profile',
         l_office_id||'/'||p_ts_profile.location.get_location_id);
   end if;
   -----------------------------
   -- get the parameter codes --
   -----------------------------
   if p_ts_profile.profile_params is null then
      ------------------------
      -- null parameter ids --
      ------------------------
      if not l_exists then
         cwms_err.raise('ERROR', 'Profile parameter string is not allowed to be null when the profile does not exist');
      end if;
      if l_ignore_nulls then
         select parameter_code
           bulk collect
           into l_parameter_codes
           from at_ts_profile_param
          where location_code = l_location_code
            and key_parameter_code = l_key_parameter_code
          order by position;
      else
         cwms_err.raise('ERROR', 'Profile parameter string is not allowed to be null when P_IGNORE_NULLS = "F"');
      end if;
      l_update_params := false;
   else
      -----------------------------
      -- specified parameter ids --
      -----------------------------
      if p_ts_profile.profile_params.count < 2 then
         cwms_err.raise('ERROR', 'Time series profile must have at least two parameters (key parameter plus at least one more)');
      end if;
      begin
         select cwms_util.get_parameter_code(column_value, l_office_id)
           bulk collect
           into l_parameter_codes
           from table(p_ts_profile.profile_params);
      exception
         when others then
            if regexp_instr(sqlerrm, 'Parameter ".+?" does not exist for office', 1, 1, 0, 'm') > 0 then
               l_parameter_codes := number_tab_t();
               l_parameter_codes.extend(p_ts_profile.profile_params.count);
               for i in 1..p_ts_profile.profile_params.count loop
                  l_parameter_codes(i) := cwms_util.create_parameter_code(
                     p_param_id       => p_ts_profile.profile_params(i),
                     p_fail_if_exists => 'F',
                     p_office_id      => p_ts_profile.location.get_office_id);
               end loop;
            end if;
      end;
      select count(*)
        into l_count
        from (select distinct column_value from table(l_parameter_codes));
      if l_count != l_parameter_codes.count then
         cwms_err.raise('ERROR', 'Profile parameters includes duplicate parameter');
      end if;
      select count(*)
        into l_count
        from (select column_value from table(l_parameter_codes) where column_value = l_key_parameter_code);
      if l_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Key parameter "'
            ||p_ts_profile.key_parameter_id
            ||'" is not included in profile parameters: "'
            ||cwms_util.join_text(p_ts_profile.profile_params, ',')
            ||'"');
      end if;
      select parameter_code
        bulk collect
        into l_existing_param_codes
        from at_ts_profile_param
       where location_code = l_location_code
         and key_parameter_code = l_key_parameter_code
       order by position;
      if l_existing_param_codes.count != l_parameter_codes.count then
         l_update_params := true;
      else
         l_update_params := false;
         for i in 1..l_existing_param_codes.count loop
            if l_existing_param_codes(i) != l_parameter_codes(i) then
               l_update_params := true;
               exit;
            end if;
         end loop;
      end if;
   end if;
   ---------------------------
   -- update profile record --
   ---------------------------
   if not l_exists then
      l_profile_rec.location_code      := l_location_code;
      l_profile_rec.key_parameter_code := l_key_parameter_code;
   end if;
   if l_ref_ts_code is not null or not l_ignore_nulls then
      l_profile_rec.reference_ts_code := l_ref_ts_code;
   end if;
   if p_ts_profile.description is not null or not l_ignore_nulls then
      l_profile_rec.description := p_ts_profile.description;
   end if;
   if l_exists then
      ------------------------------
      -- update the profile table --
      ------------------------------
      update at_ts_profile
         set row = l_profile_rec
       where location_code = l_location_code
         and key_parameter_code = l_key_parameter_code;
   else
      -----------------------------------
      -- insert into the profile table --
      -----------------------------------
      insert
        into at_ts_profile
      values l_profile_rec;
   end if;
   ---------------------------------
   -- update the parameters table --
   ---------------------------------
   if l_update_params then
      if l_exists then
         delete
           from at_ts_profile_param
          where location_code = l_location_code
            and key_parameter_code = l_key_parameter_code;
      end if;
      insert
        into at_ts_profile_param
             (select l_location_code,
                     l_key_parameter_code,
                     rownum as position,
                     column_value as parameter_code
                from table(l_parameter_codes)
             );
   end if;

end store_ts_profile;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_profile
--------------------------------------------------------------------------------
procedure retrieve_ts_profile(
   p_profile          out nocopy ts_profile_t,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_office_id        in  varchar2 default null)
is
begin
   p_profile := retrieve_ts_profile_f(
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_office_id        => p_office_id);
end retrieve_ts_profile;
--------------------------------------------------------------------------------
-- function retrieve_ts_profile_f
--------------------------------------------------------------------------------
function retrieve_ts_profile_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_office_id        in varchar2 default null)
   return ts_profile_t
is
   l_ts_profile         ts_profile_t;
   l_location           location_ref_t;
   l_key_parameter_code integer;
   l_profile_rec        at_ts_profile%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'  );    end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;

   l_location := location_ref_t(p_location_id, cwms_util.get_db_office_id(p_office_id));
   l_key_parameter_code := cwms_util.get_parameter_code(p_key_parameter_id, l_location.get_office_id);

   ---------------------------------
   -- retrieve the profile record --
   ---------------------------------
   begin
      select *
        into l_profile_rec
        from at_ts_profile
       where location_code = cwms_loc.get_location_code(p_office_id, p_location_id)
         and key_parameter_code = l_key_parameter_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile',
            cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
   end;
   ---------------------------------------------------------
   -- populate the profile object from the profile record --
   ---------------------------------------------------------
   l_ts_profile := ts_profile_t(
      location         => l_location,
      key_parameter_id => p_key_parameter_id,
      profile_params   => null,
      reference_ts_id  => case
                          when l_profile_rec.reference_ts_code is null then null
                          else cwms_ts.get_ts_id(l_profile_rec.reference_ts_code)
                          end,
      description      => l_profile_rec.description);
   --------------------------------------------
   -- populate the profile object parameters --
   --------------------------------------------
   select cwms_util.get_parameter_id(parameter_code)
     bulk collect
     into l_ts_profile.profile_params
     from at_ts_profile_param
    where location_code =l_profile_rec.location_code
      and key_parameter_code = l_key_parameter_code
    order by position;

   return l_ts_profile;
end retrieve_ts_profile_f;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_profile_params
--------------------------------------------------------------------------------
procedure retrieve_ts_profile_params(
   p_profile_params    out nocopy varchar2,
   p_location_id       in  varchar2,
   p_key_parameter_id  in  varchar2,
   p_office_id         in  varchar2 default null)
is
begin
   p_profile_params := retrieve_ts_profile_params_f(
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_office_id        => p_office_id);
end retrieve_ts_profile_params;
--------------------------------------------------------------------------------
-- function retrieve_ts_profile_params_f
--------------------------------------------------------------------------------
function retrieve_ts_profile_params_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_office_id        in varchar2 default null)
   return varchar2
is
   l_profile_param_ids  str_tab_t;
   l_profile_params_str varchar2(32767);
begin
   select cwms_util.get_parameter_id(parameter_code)
     bulk collect
     into l_profile_param_ids
     from at_ts_profile_param
    where location_code = cwms_loc.get_location_code(p_office_id, p_location_id)
      and key_parameter_code = cwms_util.get_parameter_code(p_key_parameter_id, p_office_id)
    order by position;
   if l_profile_param_ids.count = 0 then
      cwms_err.raise(
         'ERROR',
         'No parameters found for profile "'
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_location_id||'/'||p_key_parameter_id
         ||'"');
   end if;

   for i in 1..l_profile_param_ids.count loop
      if i > 1 then
         l_profile_params_str := l_profile_params_str||',';
      end if;
      if instr(l_profile_param_ids(i), ',') > 0 then
         l_profile_params_str := l_profile_params_str||'"'||l_profile_param_ids(i)||'"';
      else
         l_profile_params_str := l_profile_params_str||l_profile_param_ids(i);
      end if;
   end loop;

   return l_profile_params_str;
end retrieve_ts_profile_params_f;
--------------------------------------------------------------------------------
-- procedure delete_ts_profile
--------------------------------------------------------------------------------
procedure delete_ts_profile(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_delete_action    in varchar2 default cwms_util.delete_key,
   p_office_id        in varchar2 default null)
is
   l_profile_rec at_ts_profile%rowtype;
   l_ts_id       varchar2(191);
   exc_item_does_not_exist exception;
   pragma exception_init(exc_item_does_not_exist, -20034);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID');      end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   l_profile_rec.location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   l_profile_rec.key_parameter_code := cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   begin
      select *
        into l_profile_rec
        from at_ts_profile
       where location_code = l_profile_rec.location_code
         and key_parameter_code = l_profile_rec.key_parameter_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile',
            cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
   end;
   ------------------------------
   -- delete the child records --
   ------------------------------
   if p_delete_action in (cwms_util.delete_all, cwms_util.delete_data) then
      -- delete parser
      begin
         delete_ts_profile_parser(
            p_location_id      => p_location_id,
            p_key_parameter_id => p_key_parameter_id,
            p_office_id        => p_office_id);
      exception
         when exc_item_does_not_exist then null;
      end;
      -- delete time series
      for inst_rec in (select distinct version_id
                         from at_ts_profile_instance
                        where location_code = l_profile_rec.location_code
                          and key_parameter_code = l_profile_rec.key_parameter_code
                      )
      loop
         for param_rec in (select parameter_code
                             from at_ts_profile_param
                            where location_code = l_profile_rec.location_code
                              and key_parameter_code = l_profile_rec.key_parameter_code
                          )
         loop
            l_ts_id := make_ts_id(
               p_location_code  => l_profile_rec.location_code,
               p_parameter_code => param_rec.parameter_code,
               p_version_id     => inst_rec.version_id);

            cwms_ts.delete_ts(
               p_cwms_ts_id    => l_ts_id,
               p_delete_action => cwms_util.delete_all,
               p_db_office_id  => p_office_id);
         end loop;
      end loop;
      -- delete instances
      delete
        from at_ts_profile_instance
       where location_code = l_profile_rec.location_code
         and key_parameter_code = l_profile_rec.key_parameter_code;
   end if;
   --------------------------------
   -- delete the profile records --
   --------------------------------
   if p_delete_action in (cwms_util.delete_all, cwms_util.delete_key) then
      delete
        from at_ts_profile_param
       where location_code = l_profile_rec.location_code
         and key_parameter_code = l_profile_rec.key_parameter_code;

      delete
        from at_ts_profile
       where location_code = l_profile_rec.location_code
         and key_parameter_code = l_profile_rec.key_parameter_code;
   end if;
end delete_ts_profile;
--------------------------------------------------------------------------------
-- procedure copy_ts_profile
--------------------------------------------------------------------------------
procedure copy_ts_profile(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_dest_location_id in varchar2,
   p_dest_ref_ts_id   in varchar2,
   p_fail_if_exists   in varchar2 default 'T',
   p_copy_parser      in varchar2 default 'F',
   p_office_id        in varchar2 default null)
is
   l_ts_profile  ts_profile_t;
   l_copy_parser boolean;
begin
   l_copy_parser := cwms_util.return_true_or_false(p_copy_parser);

   l_ts_profile := retrieve_ts_profile_f(
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_office_id        => p_office_id);

   l_ts_profile.location := location_ref_t(
      p_location_id => p_dest_location_id,
      p_office_id   => p_office_id);

   l_ts_profile.reference_ts_id := nvl(p_dest_ref_ts_id, l_ts_profile.reference_ts_id);

   store_ts_profile(
         p_ts_profile      => l_ts_profile,
         p_fail_if_exists  => p_fail_if_exists,
         p_ignore_nulls    => 'F');

   if l_copy_parser then
      copy_ts_profile_parser(
         p_location_id      => p_location_id,
         p_key_parameter_id => p_key_parameter_id,
         p_dest_location_id => p_dest_location_id,
         p_fail_if_exists   => p_fail_if_exists,
         p_office_id        => p_office_id);
   end if;

end copy_ts_profile;
--------------------------------------------------------------------------------
-- procedure cat_ts_profile
--------------------------------------------------------------------------------
procedure cat_ts_profile(
   p_profile_rc            out nocopy sys_refcursor,
   p_location_id_mask      in  varchar2 default '*',
   p_key_parameter_id_mask in  varchar2 default '*',
   p_office_id_mask        in  varchar2 default null)
is
begin
   p_profile_rc := cat_ts_profile_f(
      p_location_id_mask      => p_location_id_mask,
      p_key_parameter_id_mask => p_key_parameter_id_mask,
      p_office_id_mask        => p_office_id_mask);
end cat_ts_profile;
--------------------------------------------------------------------------------
-- function cat_ts_profile_f
--------------------------------------------------------------------------------
function cat_ts_profile_f(
   p_location_id_mask      in varchar2 default '*',
   p_key_parameter_id_mask in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor
is
   l_crsr sys_refcursor;
begin

   open l_crsr for
      select q1.office_id,
             q1.location_id,
             q1.key_parameter_id,
             cursor (select cwms_util.get_parameter_id(parameter_code) as parmeter_id,
                            position
                       from at_ts_profile_param
                      where location_code = q1.location_code
                        and key_parameter_code = q1.key_parameter_code
                      order by position) as value_parameters,
             q2.cwms_ts_id as ref_ts_id,
             q1.description
        from (select tsp.location_code,
                     tsp.key_parameter_code,
                     co.office_id,
                     abl.base_location_id
                     ||substr('-', 1, length(apl.sub_location_id))
                     ||apl.sub_location_id as location_id,
                     cwms_util.get_parameter_id(key_parameter_code) as key_parameter_id,
                     reference_ts_code,
                     tsp.description
                from at_ts_profile tsp,
                     at_physical_location apl,
                     at_base_location abl,
                     cwms_office co
               where apl.location_code = tsp.location_code
                 and abl.base_location_code = apl.base_location_code
                 and co.office_code = abl.db_office_code
                 and co.office_id like cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.get_db_office_id)) escape '\'
             ) q1
             left outer join
             (select ts_code,
                     cwms_ts_id
                from av_cwms_ts_id
             ) q2 on q2.ts_code = q1.reference_ts_code
       where q1.location_id like cwms_util.normalize_wildcards(p_location_id_mask) escape '\'
         and q1.key_parameter_id like cwms_util.normalize_wildcards(p_key_parameter_id_mask) escape '\';

   return l_crsr;
end cat_ts_profile_f;
--------------------------------------------------------------------------------
-- procedure store_ts_profile_instance
--------------------------------------------------------------------------------
procedure store_ts_profile_instance(
   p_profile_data  in ts_prof_data_t,
   p_version_id    in varchar2,
   p_store_rule    in varchar2,
   p_override_prot in varchar  default 'F',
   p_version_date  in date     default cwms_util.non_versioned,
   p_office_id     in varchar2 default null)
is
   l_inst_rec at_ts_profile_instance%rowtype;
   l_exists   boolean;
   l_tsid     varchar2(191);
   l_ts_data  tsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_profile_data is null then cwms_err.raise('NULL_ARGUMENT', 'P_PROFILE_DATA'); end if;
   if p_version_id   is null then cwms_err.raise('NULL_ARGUMENT', 'P_VERSION_ID'  ); end if;
   if p_store_rule   is null then cwms_err.raise('NULL_ARGUMENT', 'P_STORE_RULE'  ); end if;
   if p_store_rule not in (cwms_util.delete_insert,
                           cwms_util.do_not_replace,
                           cwms_util.replace_all,
                           cwms_util.replace_missing_values_only,
                           cwms_util.replace_with_non_missing)
   then
      cwms_err.raise('INVALID_ITEM', p_store_rule, 'CWMS store rule');
   end if;
   if p_profile_data.records is null or p_profile_data.records.count = 0 then
      -------------------
      -- short circuit --
      -------------------
      return;
   else
      -----------------
      -- more checks --
      -----------------
      for i in 2..p_profile_data.records.count loop
         if p_profile_data.records(i).parameters.count != p_profile_data.records(1).parameters.count then
            cwms_err.raise('ERROR', 'Inconsistent number of parameters in profile records');
         end if;
         for j in 1..p_profile_data.records(i).parameters.count loop
            if p_profile_data.records(i).parameters(j).parameter_code != p_profile_data.records(1).parameters(j).parameter_code then
               cwms_err.raise('ERROR', 'Inconsistent parameter code order in profile records');
            end if;
         end loop;
      end loop;
   end if;
   -------------------------------------------
   -- retrieve any existing instance record --
   -------------------------------------------
   begin
      select *
        into l_inst_rec
        from at_ts_profile_instance
       where location_code = p_profile_data.location_code
         and key_parameter_code = p_profile_data.key_parameter
         and upper(version_id) = upper(p_version_id)
         and first_date_time = cwms_util.change_timezone(p_profile_data.records(1).date_time, p_profile_data.time_zone, 'UTC')
         and version_date = p_version_date;
      l_exists := true;
   exception
      when no_data_found then
         l_inst_rec.location_code := p_profile_data.location_code;
         l_inst_rec.key_parameter_code := p_profile_data.key_parameter;
         l_inst_rec.version_id  := p_version_id;
         l_inst_rec.first_date_time := cwms_util.change_timezone(
            p_in_date => p_profile_data.records(1).date_time,
            p_from_tz => p_profile_data.time_zone,
            p_to_tz   => 'UTC');
         l_inst_rec.version_date := p_version_date;
         l_exists := false;
   end;
   l_inst_rec.last_date_time := cwms_util.change_timezone(
      p_in_date => p_profile_data.records(p_profile_data.records.count).date_time,
      p_from_tz => p_profile_data.time_zone,
      p_to_tz   => 'UTC');
   -----------------------
   -- store time series --
   -----------------------
   l_ts_data := tsv_array();
   l_ts_data.extend(p_profile_data.records.count);
   for param_idx in 1..p_profile_data.records(1).parameters.count loop
      l_tsid := make_ts_id(
         p_location_code  => p_profile_data.location_code,
         p_parameter_code => p_profile_data.records(1).parameters(param_idx).parameter_code,
         p_version_id     => p_version_id);
      for time_idx in 1..p_profile_data.records.count loop
         l_ts_data(time_idx) := tsv_type(
            from_tz(cast(p_profile_data.records(time_idx).date_time as timestamp), p_profile_data.time_zone),
            p_profile_data.records(time_idx).parameters(param_idx).value,
            p_profile_data.records(time_idx).parameters(param_idx).quality_code);
      end loop;
      cwms_ts.store_ts_2(
         p_cwms_ts_id        => l_tsid,
         p_units             => p_profile_data.units(param_idx),
         p_timeseries_data   => l_ts_data,
         p_allow_sub_minute  => 'T',
         p_store_rule        => p_store_rule,
         p_override_prot     => p_override_prot,
         p_version_date      => p_version_date,
         p_office_id         => p_office_id);
   end loop;
   -------------------------------
   -- store the instance record --
   -------------------------------
   if l_exists then
      update at_ts_profile_instance
         set row = l_inst_rec
       where location_code = l_inst_rec.location_code
         and key_parameter_code = l_inst_rec.key_parameter_code
         and upper(version_id) = upper(l_inst_rec.version_id)
         and version_date = l_inst_rec.version_date;
   else
      insert
        into at_ts_profile_instance
      values l_inst_rec;
   end if;
end store_ts_profile_instance;
--------------------------------------------------------------------------------
-- procedure store_ts_profile_instance
--------------------------------------------------------------------------------
procedure store_ts_profile_instance(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_profile_data     in clob,
   p_version_id       in varchar2,
   p_store_rule       in varchar2,
   p_override_prot    in varchar  default 'F',
   p_version_date     in date     default cwms_util.non_versioned,
   p_office_id        in varchar2 default null)
is
   l_parser_rec   at_ts_profile_parser%rowtype;
   l_ts_prof_data ts_prof_data_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   --------------------------------
   -- retrieve the parser record --
   --------------------------------
   begin
      select *
        into l_parser_rec
        from at_ts_profile_parser
       where location_code = cwms_loc.get_location_code(p_office_id, p_location_id)
         and key_parameter_code = cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile parser',
            cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
   end;
   --------------------
   -- parse the text --
   --------------------
   l_ts_prof_data := cwms_ts_profile.parse_ts_prof_inst_text_codes(
      p_location_code      => l_parser_rec.location_code,
      p_key_parameter_code => l_parser_rec.key_parameter_code,
      p_text               => p_profile_data,
      p_time_zone_code     => l_parser_rec.time_zone_code);
   ---------------------------
   -- call the base routine --
   ---------------------------
   store_ts_profile_instance(
      p_profile_data  => l_ts_prof_data,
      p_version_id    => p_version_id,
      p_store_rule    => p_store_rule,
      p_override_prot => p_override_prot,
      p_version_date  => p_version_date,
      p_office_id     => p_office_id);
end store_ts_profile_instance;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_profile_data
--------------------------------------------------------------------------------
procedure retrieve_ts_profile_data(
   p_profile_data     out nocopy ts_prof_data_t,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_units            in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null)
is
begin
   p_profile_data := retrieve_ts_profile_data_f(
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_version_id       => p_version_id,
      p_units            => p_units,
      p_start_time       => p_start_time,
      p_end_time         => p_end_time,
      p_time_zone        => p_time_zone,
      p_start_inclusive  => p_start_inclusive,
      p_end_inclusive    => p_end_inclusive,
      p_previous         => p_previous,
      p_next             => p_next,
      p_version_date     => p_version_date,
      p_max_version      => p_max_version,
      p_office_id        => p_office_id);
end retrieve_ts_profile_data;
--------------------------------------------------------------------------------
-- function retrieve_ts_profile_data_f
--------------------------------------------------------------------------------
function retrieve_ts_profile_data_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_version_id       in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date     default null,
   p_time_zone        in varchar2 default 'UTC',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_office_id        in varchar2 default null)
   return ts_prof_data_t
is
   type vq_t             is record (value binary_double, quality_code integer);
   type vq_assoc_t       is table of vq_t index by varchar2(19);       --  value/quality by time string
   type vq_assoc_assoc_t is table of vq_assoc_t index by varchar2(14); -- (value/quality by time string) by parameter code
   type date_assoc_t     is table of boolean index by varchar2(19);
   c_time_format        constant varchar2(21) := 'YYYY-MM-DD HH24:MI:SS';
   l_location_code      integer;
   l_key_parameter_code integer;
   l_time_zone_code     integer;
   l_parameter_codes    number_tab_t;
   l_units              str_tab_t;
   l_start_time_utc     date;
   l_end_time_utc       date;
   l_version_date       date;
   l_count              pls_integer;
   l_cursor             sys_refcursor;
   l_date_time          date;
   l_value              binary_double;
   l_quality_code       integer;
   l_time_string        varchar2(19);
   l_times              date_assoc_t;
   l_vq_data            vq_assoc_assoc_t;
   l_time_idx           pls_integer;
   l_profile_data       ts_prof_data_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   if p_version_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_VERSION_ID'      ); end if;
   if p_units            is null then cwms_err.raise('NULL_ARGUMENT', 'P_UNITS'           ); end if;
   if p_start_time       is null then cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME'      ); end if;
   if p_time_zone        is null then cwms_err.raise('NULL_ARGUMENT', 'P_TIME_ZONE'       ); end if;
   ------------------------------
   -- set some local variables --
   ------------------------------
   l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   l_key_parameter_code := cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   l_time_zone_code := cwms_util.get_time_zone_code(p_time_zone); -- used only to verify time zone
   l_start_time_utc := cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC');
   if p_end_time is not null then
      l_end_time_utc := cwms_util.change_timezone(p_end_time, p_time_zone, 'UTC');
   end if;
   if p_version_date is not null then
      l_version_date := case
                        when p_version_date = cwms_util.non_versioned then p_version_date
                        else cwms_util.change_timezone(p_version_date, p_time_zone, 'UTC')
                        end;
   end if;
   -------------------------------------
   -- retrieve the profile parameters --
   -------------------------------------
   select parameter_code
     bulk collect
     into l_parameter_codes
     from at_ts_profile_param
    where location_code = l_location_code
      and key_parameter_code = l_key_parameter_code
    order by position;
   if l_parameter_codes.count = 0 then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Time series profile',
         cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
   end if;
   -----------------------------------------------
   -- verify a matching profile instance exists --
   -----------------------------------------------
   if l_end_time_utc is null then
      begin
         if l_version_date is null then
            select max(last_date_time)
              into l_end_time_utc
              from at_ts_profile_instance
             where location_code = l_location_code
               and key_parameter_code = l_key_parameter_code
               and upper(version_id) = upper(p_version_id)
               and first_date_time = l_start_time_utc;
         else
            select last_date_time
              into l_end_time_utc
              from at_ts_profile_instance
             where location_code = l_location_code
               and key_parameter_code = l_key_parameter_code
               and upper(version_id) = upper(p_version_id)
               and first_date_time = l_start_time_utc
               and version_date = l_version_date;
         end if;
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Time series profile instance',
               cwms_util.get_db_office_id(p_office_id)
               ||'/'||p_location_id
               ||'/'||p_key_parameter_id
               ||'/'||p_version_id
               ||' for specified start time and version time');
      end;
   else
      select count(*)
        into l_count
        from at_ts_profile_instance
       where location_code = l_location_code
         and key_parameter_code = l_key_parameter_code
         and upper(version_id) = upper(p_version_id);

      if l_count = 0 then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile instance',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||p_key_parameter_id
            ||'/'||p_version_id);
      end if;
   end if;
   -----------------
   -- more checks --
   -----------------
   l_units := cwms_util.split_text(p_units, ',');
   if l_units.count != l_parameter_codes.count then
      cwms_err.raise(
         'ERROR',
         'Unit count ('||l_units.count||') does not equal parameter count ('||l_parameter_codes.count||')');
   end if;
   for i in 1..l_parameter_codes.count loop
      begin
         l_value := cwms_util.convert_units(
            1,
            cwms_util.get_default_units(cwms_util.get_parameter_id(l_parameter_codes(i))),
            l_units(i));
      exception
         when others then cwms_err.raise(
            'ERROR',
            'Unit '''
            ||l_units(i)
            ||''' is not valid for parameter '
            ||cwms_util.get_parameter_id(l_parameter_codes(i)));
      end;
   end loop;
   -----------------------------------
   -- retrieve the time series data --
   -----------------------------------
   for i in 1..l_parameter_codes.count loop
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_cursor,
         p_cwms_ts_id      => make_ts_id(l_location_code, l_parameter_codes(i), p_version_id),
         p_units           => l_units(i),
         p_start_time      => l_start_time_utc,
         p_end_time        => l_end_time_utc,
         p_time_zone       => 'UTC',
         p_trim            => 'F',
         p_start_inclusive => p_start_inclusive,
         p_end_inclusive   => p_end_inclusive,
         p_previous        => p_previous,
         p_next            => p_next,
         p_version_date    => l_version_date,
         p_max_version     => p_max_version,
         p_office_id       => p_office_id);
      loop
         fetch l_cursor into l_date_time, l_value, l_quality_code;
         exit when l_cursor%notfound;
         ---------------------------------------------------------------
         -- add this time to the list of all times for all parameters --
         ---------------------------------------------------------------
         l_time_string := to_char(cwms_util.change_timezone(l_date_time, 'UTC', p_time_zone), c_time_format);
         l_times(l_time_string) := true;
         ------------------------------------------------------------------------
         -- add this time/value to the list of all values for *this* parameter --
         ------------------------------------------------------------------------
         l_vq_data(l_parameter_codes(i))(l_time_string).value := l_value;
         l_vq_data(l_parameter_codes(i))(l_time_string).quality_code := l_quality_code;
      end loop;
      close l_cursor;
   end loop;
   ----------------------------------
   -- build and return the results --
   ----------------------------------
   l_profile_data := ts_prof_data_t(
      location_code => l_location_code,
      key_parameter => l_key_parameter_code,
      time_zone     => p_time_zone,
      units         => l_units,
      records       => ts_prof_data_tab_t());
   l_profile_data.records.extend(l_times.count);
   l_time_string := l_times.first;
   l_time_idx := 0;
   loop
      exit when l_time_string is null;
      l_time_idx := l_time_idx + 1;
      l_profile_data.records(l_time_idx) := ts_prof_data_rec_t(
         date_time  => to_date(l_time_string, c_time_format),
         parameters => pvq_tab_t());
      l_profile_data.records(l_time_idx).parameters.extend(l_parameter_codes.count);
      for i in 1..l_parameter_codes.count loop
         --------------------------------------------------
         -- value at this time exists for this parameter --
         --------------------------------------------------
         if l_vq_data(l_parameter_codes(i)).exists(l_time_string) then
            l_profile_data.records(l_time_idx).parameters(i) := pvq_t(
               parameter_code => l_parameter_codes(i),
               value          => l_vq_data(l_parameter_codes(i))(l_time_string).value,
               quality_code   => l_vq_data(l_parameter_codes(i))(l_time_string).quality_code);
         else
         ----------------------------------------------
         -- no value at this time for this parameter --
         ----------------------------------------------
            l_profile_data.records(l_time_idx).parameters(i) := pvq_t(
               parameter_code => l_parameter_codes(i),
               value          => null,
               quality_code   => 0);
         end if;
      end loop;
      l_time_string := l_times.next(l_time_string);
   end loop;
   return l_profile_data;
end retrieve_ts_profile_data_f;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_profile_elevs
--------------------------------------------------------------------------------
procedure retrieve_ts_profile_elevs(
   p_elevations       out nocopy ztsv_array,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null)
is
begin
   p_elevations := retrieve_ts_profile_elevs_f(
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_version_id       => p_version_id,
      p_unit             => p_unit,
      p_start_time       => p_start_time,
      p_end_time         => p_end_time,
      p_time_zone        => p_time_zone,
      p_start_inclusive  => p_start_inclusive,
      p_end_inclusive    => p_end_inclusive,
      p_previous         => p_previous,
      p_next             => p_next,
      p_version_date     => p_version_date,
      p_max_version      => p_max_version,
      p_office_id        => p_office_id);
end retrieve_ts_profile_elevs;
--------------------------------------------------------------------------------
-- function retrieve_ts_profile_elevs_f
--------------------------------------------------------------------------------
function retrieve_ts_profile_elevs_f(
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null)
   return ztsv_array
is
   type double_by_vchar_t is table of binary_double index by varchar2(19);
   c_time_format        constant varchar2(21) := 'YYYY-MM-DD HH24:MI:SS';
   l_location_code      integer;
   l_key_parameter_code integer;
   l_unit_code          integer;
   l_time_zone_code     integer;
   l_profile_rec        at_ts_profile%rowtype;
   l_ref_ts_id          varchar2(191);
   l_base_parameter_id  varchar2(32);
   l_start_time_utc     date;
   l_end_time_utc       date;
   l_version_date       date;
   l_count              pls_integer;
   l_cursor             sys_refcursor;
   l_date_time          date;
   l_value              binary_double;
   l_quality_code       integer;
   l_time_string        varchar2(19);
   l_prev_time          varchar2(19);
   l_next_time          varchar2(19);
   l_key_param_ts       ztsv_array;
   l_elevs              double_by_vchar_t;
   l_value_time         date;
   x                    date;
   x1                   date;
   x2                   date;
   y1                   binary_double;
   y2                   binary_double;
   l_elev               binary_double;
   l_elevations         ztsv_array;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   if p_version_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_VERSION_ID'      ); end if;
   if p_unit             is null then cwms_err.raise('NULL_ARGUMENT', 'P_UNIT'            ); end if;
   if p_start_time       is null then cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME'      ); end if;
   if p_time_zone        is null then cwms_err.raise('NULL_ARGUMENT', 'P_TIME_ZONE'       ); end if;
   ------------------------------
   -- set some local variables --
   ------------------------------
   l_base_parameter_id := cwms_util.split_text(p_key_parameter_id, 1, '-');
   if l_base_parameter_id not in ('Depth', 'Height') then
      cwms_err.raise('ERROR', 'Base portion of of P_KEY_PARAMETER_ID must be ''Depth'' or ''Height''');
   end if;
   l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   l_key_parameter_code := cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   l_unit_code := cwms_util.get_unit_code(cwms_util.parse_unit(p_unit), 'Length', p_office_id); -- used only to verify unit
   l_time_zone_code := cwms_util.get_time_zone_code(p_time_zone);                               -- used only to verify time zone
   l_start_time_utc := cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC');
   if p_end_time is not null then
      l_end_time_utc := cwms_util.change_timezone(p_end_time, p_time_zone, 'UTC');
   end if;
   if p_version_date is not null then
      l_version_date := case
                        when p_version_date = cwms_util.non_versioned then p_version_date
                        else cwms_util.change_timezone(p_version_date, p_time_zone, 'UTC')
                        end;
   end if;
   ---------------------------------------------
   -- get the reference elevation time series --
   ---------------------------------------------
   begin
      select *
        into l_profile_rec
        from at_ts_profile
       where location_code = l_location_code
         and key_parameter_code = l_key_parameter_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||p_key_parameter_id);
   end;
   if l_profile_rec.reference_ts_code is null then
      cwms_err.raise('ERROR', 'Time series profile does not have a reference time series');
   end if;
   l_ref_ts_id := cwms_ts.get_ts_id(l_profile_rec.reference_ts_code);
   if cwms_util.split_text(cwms_util.split_text(l_ref_ts_id, 2, '.'), 1, '-') != 'Elev' then
      cwms_err.raise('ERROR', 'The reference time series for the profile is not elevation');
   end if;
   -----------------------------------------------
   -- verify a matching profile instance exists --
   -----------------------------------------------
   if l_end_time_utc is null then
      begin
         if l_version_date is null then
            select max(last_date_time)
              into l_end_time_utc
              from at_ts_profile_instance
             where location_code = l_location_code
               and key_parameter_code = l_key_parameter_code
               and upper(version_id) = upper(p_version_id)
               and first_date_time = l_start_time_utc;
         else
            select last_date_time
              into l_end_time_utc
              from at_ts_profile_instance
             where location_code = l_location_code
               and key_parameter_code = l_key_parameter_code
               and upper(version_id) = upper(p_version_id)
               and first_date_time = l_start_time_utc
               and version_date = l_version_date;
         end if;
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Time series profile instance',
               cwms_util.get_db_office_id(p_office_id)
               ||'/'||p_location_id
               ||'/'||p_key_parameter_id
               ||'/'||p_version_id
               ||' for specified start time and version time');
      end;
   else
      select count(*)
        into l_count
        from at_ts_profile_instance
       where location_code = l_location_code
         and key_parameter_code = l_key_parameter_code
         and upper(version_id) = upper(p_version_id);

      if l_count = 0 then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile instance',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||p_key_parameter_id
            ||'/'||p_version_id);
      end if;
   end if;
   --------------------------------------------
   -- retrieve the key parameter time series --
   --------------------------------------------
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_cursor,
      p_cwms_ts_id      => make_ts_id(l_location_code, l_key_parameter_code, p_version_id),
      p_units           => cwms_util.parse_unit(p_unit),
      p_start_time      => l_start_time_utc,
      p_end_time        => l_end_time_utc,
      p_time_zone       => 'UTC',
      p_trim            => 'F',
      p_start_inclusive => p_start_inclusive,
      p_end_inclusive   => p_end_inclusive,
      p_previous        => p_previous,
      p_next            => p_next,
      p_version_date    => l_version_date,
      p_max_version     => p_max_version,
      p_office_id       => p_office_id);
   l_key_param_ts := ztsv_array();
   loop
      fetch l_cursor into l_date_time, l_value, l_quality_code;
      exit when l_cursor%notfound;
      l_key_param_ts.extend;
      l_key_param_ts(l_key_param_ts.count) := ztsv_type(l_date_time, l_value, l_quality_code);
   end loop;
   close l_cursor;
   if l_key_param_ts.count > 0 then
      ----------------------------------------
      -- retrieve the elevation time series --
      ----------------------------------------
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_cursor,
         p_cwms_ts_id      => l_ref_ts_id,
         p_units           => p_unit,
         p_start_time      => l_key_param_ts(1).date_time,
         p_end_time        => l_key_param_ts(l_key_param_ts.count).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'F',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => l_version_date,
         p_max_version     => p_max_version,
         p_office_id       => p_office_id);
      loop
         fetch l_cursor into l_date_time, l_value, l_quality_code;
         exit when l_cursor%notfound;
         if not (cwms_ts.quality_is_missing(l_quality_code) or cwms_ts.quality_is_rejected(l_quality_code)) then
            l_elevs(to_char(l_date_time, c_time_format)) := l_value;
         end if;
      end loop;
      close l_cursor;
   end if;
   ----------------------------------
   -- build and return the results --
   ----------------------------------
   l_elevations := ztsv_array();
   l_elevations.extend(l_key_param_ts.count);
   for i in 1..l_key_param_ts.count loop
      l_value_time := cwms_util.change_timezone(l_key_param_ts(i).date_time, 'UTC', p_time_zone);
      l_time_string := to_char(l_key_param_ts(i).date_time, c_time_format);
      if l_elevs.exists(l_time_string) then
         --------------------------------------------
         -- use existing elevation at profile time --
         --------------------------------------------
         l_elevations(i) := ztsv_type(
            l_value_time,
            case
            when l_base_parameter_id = 'Depth'  then l_elevs(l_time_string) - l_key_param_ts(i).value
            when l_base_parameter_id = 'Height' then l_elevs(l_time_string) + l_key_param_ts(i).value
            end,
            0);
      else
         -------------------------------------------
         -- interpolate elevation at profile time --
         -------------------------------------------
         l_prev_time := l_elevs.prior(l_time_string);
         l_next_time := l_elevs.next(l_time_string);
         if l_prev_time is null or l_next_time is null then
            l_elevations(i) := ztsv_type(l_value_time, null, 0);
         else
            x  := to_date(l_time_string, c_time_format);
            x1 := to_date(l_prev_time, c_time_format);
            x2 := to_date(l_next_time, c_time_format);
            y1 := l_elevs(l_prev_time);
            y2 := l_elevs(l_next_time);
            l_elev := y1 + (x - x1)/(x2 - x1) * (y2 - y1);
            l_elevations(i) := ztsv_type(
               l_value_time,
               case
               when l_base_parameter_id = 'Depth'  then l_elev - l_key_param_ts(i).value
               when l_base_parameter_id = 'Height' then l_elev + l_key_param_ts(i).value
               end,
               0);
         end if;
      end if;
   end loop;
   return l_elevations;
end retrieve_ts_profile_elevs_f;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_profile_elevs_2
--------------------------------------------------------------------------------
procedure retrieve_ts_profile_elevs_2(
   p_elevations       out nocopy ztsv_array,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null)
is
begin
   p_elevations := retrieve_ts_profile_elevs_2_f(
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_version_id       => p_version_id,
      p_unit             => p_unit,
      p_start_time       => p_start_time,
      p_end_time         => p_end_time,
      p_time_zone        => p_time_zone,
      p_start_inclusive  => p_start_inclusive,
      p_end_inclusive    => p_end_inclusive,
      p_previous         => p_previous,
      p_next             => p_next,
      p_version_date     => p_version_date,
      p_max_version      => p_max_version,
      p_office_id        => p_office_id);
end retrieve_ts_profile_elevs_2;
--------------------------------------------------------------------------------
-- function retrieve_ts_profile_elevs_2_f
--------------------------------------------------------------------------------
function retrieve_ts_profile_elevs_2_f(
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null)
   return ztsv_array
is
   l_location_code      integer;
   l_key_parameter_code integer;
   l_profile_rec        at_ts_profile%rowtype;
   l_ref_ts_id          varchar2(191);
   l_base_parameter_id  varchar2(32);
   l_start_time_utc     date;
   l_end_time_utc       date;
   l_version_date       date;
   l_count              pls_integer;
   l_time_zone_code     integer;
   l_cursor             sys_refcursor;
   l_date_time          date;
   l_value              binary_double;
   l_quality_code       integer;
   l_time_string        varchar2(19);
   l_prev_time          varchar2(19);
   l_next_time          varchar2(19);
   l_time_series        ztsv_array;
   l_elev               binary_double;
   l_unit               varchar2(16);
   l_unit_code          integer;
   l_from_datum         varchar2(16);
   l_to_datum           varchar2(16);
   l_elev_offset        binary_double;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   if p_version_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_VERSION_ID'      ); end if;
   if p_unit             is null then cwms_err.raise('NULL_ARGUMENT', 'P_UNIT'            ); end if;
   if p_start_time       is null then cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME'      ); end if;
   if p_time_zone        is null then cwms_err.raise('NULL_ARGUMENT', 'P_TIME_ZONE'       ); end if;
   ------------------------------
   -- set some local variables --
   ------------------------------
   l_base_parameter_id := cwms_util.split_text(p_key_parameter_id, 1, '-');
   if l_base_parameter_id not in ('Depth', 'Height') then
      cwms_err.raise('ERROR', 'Base portion of of P_KEY_PARAMETER_ID must be ''Depth'' or ''Height''');
   end if;
   l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   l_key_parameter_code := cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   l_time_zone_code := cwms_util.get_time_zone_code(p_time_zone); -- used only to verify time zone
   l_start_time_utc := cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC');
   if p_end_time is not null then
      l_end_time_utc := cwms_util.change_timezone(p_end_time, p_time_zone, 'UTC');
   end if;
   if p_version_date is not null then
      l_version_date := case
                        when p_version_date = cwms_util.non_versioned then p_version_date
                        else cwms_util.change_timezone(p_version_date, p_time_zone, 'UTC')
                        end;
   end if;
   -------------------------------------------------
   -- get the location elevation and datum offset --
   -------------------------------------------------
   l_unit := cwms_util.parse_unit(p_unit);
   l_unit_code := cwms_util.get_unit_code(l_unit, 'Length', p_office_id); -- used only to verify unit
   l_to_datum := nvl(cwms_util.parse_vertical_datum(p_unit), cwms_loc.get_default_vertical_datum);
   select cwms_util.convert_units(elevation, 'm', l_unit),
          vertical_datum
     into l_elev,
          l_from_datum
     from at_physical_location
    where location_code = l_location_code;
   if l_elev is null then
      cwms_err.raise(
         'ERROR',
         'Location '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_location_id
         ||' has NULL elevation');
   end if;
   if l_to_datum is null then
      l_elev_offset := 0;
   elsif l_from_datum is null then
      cwms_err.raise(
         'ERROR',
         'Cannot convert to vertical datum '
         ||l_to_datum
         ||': location '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_location_id
         ||' has no specified vertical datum');
   else
      l_elev_offset := cwms_loc.get_vertical_datum_offset(
         l_location_code,
         l_from_datum,
         l_to_datum,
         cwms_util.change_timezone(p_start_time, p_time_zone),
         l_unit);
      if l_elev_offset is null then
         cwms_err.raise(
            'ERROR',
            'Cannot convert to vertical datum '
            ||l_to_datum
            ||': location '
            ||cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||p_location_id
            ||' has no offset specified from '
            ||l_from_datum);
      end if;
   end if;
   -----------------------------------------------
   -- verify a matching profile instance exists --
   -----------------------------------------------
   if l_end_time_utc is null then
      begin
         if l_version_date is null then
            select max(last_date_time)
              into l_end_time_utc
              from at_ts_profile_instance
             where location_code = l_location_code
               and key_parameter_code = l_key_parameter_code
               and upper(version_id) = upper(p_version_id)
               and first_date_time = l_start_time_utc;
         else
            select last_date_time
              into l_end_time_utc
              from at_ts_profile_instance
             where location_code = l_location_code
               and key_parameter_code = l_key_parameter_code
               and upper(version_id) = upper(p_version_id)
               and first_date_time = l_start_time_utc
               and version_date = l_version_date;
         end if;
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Time series profile instance',
               cwms_util.get_db_office_id(p_office_id)
               ||'/'||p_location_id
               ||'/'||p_key_parameter_id
               ||'/'||p_version_id
               ||' for specified start time and version time');
      end;
   else
      select count(*)
        into l_count
        from at_ts_profile_instance
       where location_code = l_location_code
         and key_parameter_code = l_key_parameter_code
         and upper(version_id) = upper(p_version_id);

      if l_count = 0 then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile instance',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||p_key_parameter_id
            ||'/'||p_version_id);
      end if;
   end if;
   -----------------------------------------------------------------------------------
   -- retrieve the key parameter time series, converting the values into elevations --
   -----------------------------------------------------------------------------------
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_cursor,
      p_cwms_ts_id      => make_ts_id(l_location_code, l_key_parameter_code, p_version_id),
      p_units           => l_unit,
      p_start_time      => l_start_time_utc,
      p_end_time        => l_end_time_utc,
      p_time_zone       => 'UTC',
      p_trim            => 'F',
      p_start_inclusive => p_start_inclusive,
      p_end_inclusive   => p_end_inclusive,
      p_previous        => p_previous,
      p_next            => p_next,
      p_version_date    => l_version_date,
      p_max_version     => p_max_version,
      p_office_id       => p_office_id);
   l_time_series := ztsv_array();
   loop
      fetch l_cursor into l_date_time, l_value, l_quality_code;
      exit when l_cursor%notfound;
      l_time_series.extend;
      l_time_series(l_time_series.count) :=
         ztsv_type(
            cwms_util.change_timezone(l_date_time, 'UTC', p_time_zone),
            case
            when l_base_parameter_id = 'Depth'  then l_elev + l_elev_offset - l_value
            when l_base_parameter_id = 'Height' then l_elev + l_elev_offset + l_value
            end,
            l_quality_code);
   end loop;
   close l_cursor;
   return l_time_series;
end retrieve_ts_profile_elevs_2_f;
--------------------------------------------------------------------------------
-- procedure delete_ts_profile_instance
--------------------------------------------------------------------------------
procedure delete_ts_profile_instance(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_version_id       in varchar2,
   p_first_date_time  in date,
   p_time_zone        in varchar2 default 'UTC',
   p_override_prot    in varchar2 default 'F',
   p_version_date     in date default cwms_util.non_versioned,
   p_office_id        in varchar2 default null)
is
   l_inst_rec       at_ts_profile_instance%rowtype;
   l_first_time     date;
   l_version_date   date;
   l_ts_id          varchar2(191);
   l_ts_code        integer;
   l_time_zone_code integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   if p_version_id       is null then cwms_err.raise('NULL_ARGUMENT', 'P_VERSION_ID'      ); end if;
   if p_first_date_time  is null then cwms_err.raise('NULL_ARGUMENT', 'P_FIRST_DATE_TIME' ); end if;
   if p_time_zone        is null then cwms_err.raise('NULL_ARGUMENT', 'P_TIME_ZONE'       );  end if;
   l_time_zone_code := cwms_util.get_time_zone_code(p_time_zone); -- used to verify time zone
   l_first_time := cwms_util.change_timezone(p_first_date_time, p_time_zone, 'UTC');
   l_version_date := case
                     when p_version_date = cwms_util.non_versioned then p_version_date
                     else cwms_util.change_timezone(p_version_date, p_time_zone, 'UTC')
                     end;
   -----------------------------
   -- get the instance record --
   -----------------------------
   l_inst_rec.location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   l_inst_rec.key_parameter_code := cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   begin
      select *
        into l_inst_rec
        from at_ts_profile_instance
       where location_code = l_inst_rec.location_code
         and key_parameter_code = l_inst_rec.key_parameter_code
         and upper(version_id) = upper(p_version_id)
         and first_date_time = l_first_time
         and version_date = l_version_date;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile instance',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||p_key_parameter_id
            ||'/'||p_version_id
            ||'/'||to_char(l_first_time, 'yyyy-mm-dd hh24:mi:ss')
            ||' ('||case
                   when l_version_date = cwms_util.non_versioned then 'non-versioned'
                   else to_char(l_version_date, 'yyyy-mm-dd hh24:mi:ss')
                   end
            ||')');
   end;
   ---------------------------------
   -- delete the time series data --
   ---------------------------------
   for rec in (select parameter_code
                 from at_ts_profile_param
                where location_code = l_inst_rec.location_code
                  and key_parameter_code = l_inst_rec.key_parameter_code
              )
   loop
      l_ts_id := make_ts_id(
         p_location_code  => l_inst_rec.location_code,
         p_parameter_code => rec.parameter_code,
         p_version_id     => l_inst_rec.version_id);

      l_ts_code := cwms_ts.get_ts_code(
         p_cwms_ts_id   => l_ts_id,
         p_db_office_id => p_office_id);

      cwms_ts.purge_ts_data(
         p_ts_code             => l_ts_code,
         p_override_protection => p_override_prot,
         p_version_date_utc    => l_version_date,
         p_start_time_utc      => l_inst_rec.first_date_time,
         p_end_time_utc        => l_inst_rec.last_date_time,
         p_date_times_utc      => null,
         p_max_version         => 'T',
         p_ts_item_mask        => cwms_util.ts_all);
   end loop;
   --------------------------------
   -- delete the instance record --
   --------------------------------
   delete
     from at_ts_profile_instance
    where location_code = l_inst_rec.location_code
     and key_parameter_code = l_inst_rec.key_parameter_code;
end delete_ts_profile_instance;
--------------------------------------------------------------------------------
-- procedure cat_ts_profile_instance
--------------------------------------------------------------------------------
procedure cat_ts_profile_instance(
   p_instance_rc           out nocopy sys_refcursor,
   p_location_id_mask      in  varchar2 default '*',
   p_key_parameter_id_mask in  varchar2 default '*',
   p_version_id_mask       in  varchar2 default '*',
   p_start_time            in  date     default null,
   p_end_time              in  date     default null,
   p_time_zone             in  varchar2 default 'UTC',
   p_office_id_mask        in  varchar2 default null)
is
begin
   p_instance_rc := cat_ts_profile_instance_f(
      p_location_id_mask      => p_location_id_mask,
      p_key_parameter_id_mask => p_key_parameter_id_mask,
      p_version_id_mask       => p_version_id_mask,
      p_start_time            => p_start_time,
      p_end_time              => p_end_time,
      p_time_zone             => p_time_zone,
      p_office_id_mask        => p_office_id_mask);
end cat_ts_profile_instance;
--------------------------------------------------------------------------------
-- function cat_ts_profile_instance_f
--------------------------------------------------------------------------------
function cat_ts_profile_instance_f(
   p_location_id_mask      in varchar2 default '*',
   p_key_parameter_id_mask in varchar2 default '*',
   p_version_id_mask       in varchar2 default '*',
   p_start_time            in date     default null,
   p_end_time              in date     default null,
   p_time_zone             in varchar2 default 'UTC',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   open l_cursor for
      select al.db_office_id,
             al.location_id,
             cwms_util.get_parameter_id(atpi.key_parameter_code) as key_parameter_id,
             atpi.version_id,
             case
             when atpi.version_date = cwms_util.non_versioned then atpi.version_date
             else cwms_util.change_timezone(atpi.version_date, 'UTC', p_time_zone)
             end as version_date,
             cwms_util.change_timezone(atpi.first_date_time, 'UTC', p_time_zone) as first_data_time,
             cwms_util.change_timezone(atpi.last_date_time, 'UTC', p_time_zone) as last_data_time
        from at_ts_profile_instance atpi,
             av_loc al
       where upper(al.location_id) like cwms_util.normalize_wildcards(upper(p_location_id_mask)) escape '\'
         and al.unit_system = 'EN'
         and upper(al.db_office_id) like cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.get_db_office_id))) escape '\'
         and atpi.location_code = al.location_code
         and upper(cwms_util.get_parameter_id(atpi.key_parameter_code)) like cwms_util.normalize_wildcards(upper(p_key_parameter_id_mask)) escape '\'
         and upper(atpi.version_id) like cwms_util.normalize_wildcards(upper(p_version_id_mask)) escape '\'
         and first_date_time >= case when p_start_time is null then first_date_time else cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC') end
         and first_date_time <= case when p_end_time is null then first_date_time else cwms_util.change_timezone(p_end_time, p_time_zone, 'UTC') end
       order by 1, 2, 3, 4, 5;
   return l_cursor;
end cat_ts_profile_instance_f;
--------------------------------------------------------------------------------
-- procedure store_ts_profile_parser
--------------------------------------------------------------------------------
procedure store_ts_profile_parser(
   p_location_id        in varchar2,
   p_key_parameter_id   in varchar2,
   p_record_delimiter   in varchar2,
   p_field_delimiter    in varchar2,
   p_time_field         in integer,
   p_time_start_col     in integer,
   p_time_end_col       in integer,
   p_time_format        in varchar2,
   p_time_zone          in varchar2,
   p_parameter_info     in varchar2,
   p_time_in_two_fields in varchar2 default 'F',
   p_fail_if_exists     in varchar2 default 'T',
   p_ignore_nulls       in varchar2 default 'T',
   p_office_id          in varchar2 default null)
is
   type param_rec_assoc_t is table of at_ts_profile_parser_param%rowtype index by varchar2(16);
   l_fail_if_exists      boolean;
   l_exists              boolean;
   l_ignore_nulls        boolean;
   l_update_params       boolean;
   l_delimited           boolean;
   l_location_code       integer;
   l_key_parameter_code  integer;
   l_parameter_info      str_tab_tab_t;
   l_parser_rec          at_ts_profile_parser%rowtype;
   l_param_rec           at_ts_profile_parser_param%rowtype;
   l_param_assoc         param_rec_assoc_t;
   l_count               pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.return_true_or_false(p_ignore_nulls);
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   ----------------------------------------------
   -- retrieve the current record if it exists --
   ----------------------------------------------
   l_parser_rec.location_code      := cwms_loc.get_location_code(p_office_id, p_location_id);
   l_parser_rec.key_parameter_code := cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   begin
      select *
        into l_parser_rec
        from at_ts_profile_parser
       where location_code = l_parser_rec.location_code
         and key_parameter_code = l_parser_rec.key_parameter_code;
      l_exists := true;
   exception
      when no_data_found then l_exists := false;
   end;
   ------------------------
   -- more sanity checks --
   ------------------------
   select count(*)
     into l_count
     from at_ts_profile
    where location_code = l_parser_rec.location_code
      and key_parameter_code = l_parser_rec.key_parameter_code;
   if l_count = 0 then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile',
            cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
   end if;
   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Time series profile parser',
            cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
      end if;
   else
      if p_parameter_info is null then
         cwms_err.raise('ERROR', 'P_PARAMETER_INFO cannot be null for new parser');
      end if;
   end if;
   ------------------------------
   -- update the parser record --
   ------------------------------
   case
   when p_field_delimiter is not null then l_delimited := true;
   when not l_ignore_nulls then l_delimited := false;
   when l_exists and l_parser_rec.field_delimiter is not null then l_delimited := true;
   else l_delimited := false;
   end case;
   if p_time_field is not null or not l_ignore_nulls then
      l_parser_rec.time_field := p_time_field;
   end if;
   if p_time_in_two_fields is not null or not l_ignore_nulls then
      l_parser_rec.time_in_two_fields := p_time_in_two_fields;
   end if;
   if p_field_delimiter is not null or not l_ignore_nulls then
      begin
         l_parser_rec.field_delimiter := p_field_delimiter;
      exception
         when others then
            if regexp_instr(sqlerrm, 'character string buffer too small', 1, 1, 0, 'm') != 0 then
               cwms_err.raise('ERROR', 'FIELD_DELIMITER must be a single character');
            else
               raise;
            end if;
      end;
   end if;
   if p_time_start_col is not null or not l_ignore_nulls then
      l_parser_rec.time_col_start := p_time_start_col;
   end if;
   if p_time_end_col is not null or not l_ignore_nulls then
      l_parser_rec.time_col_end := p_time_end_col;
   end if;
   if p_record_delimiter is not null or not l_ignore_nulls then
      begin
         l_parser_rec.record_delimiter := p_record_delimiter;
      exception
         when others then
            if regexp_instr(sqlerrm, 'character string buffer too small', 1, 1, 0, 'm') != 0 then
               cwms_err.raise('ERROR', 'RECORD_DELIMITER must be a single character');
            else
               raise;
            end if;
      end;
   end if;
   if p_time_format is not null or not l_ignore_nulls then
      l_parser_rec.time_format := p_time_format;
   end if;
   if p_time_zone is not null or not l_ignore_nulls then
      l_parser_rec.time_zone_code := case when p_time_zone is null then null else cwms_util.get_time_zone_code(p_time_zone) end;
   end if;
   ------------------------
   -- more sanity checks --
   ------------------------
   if p_parameter_info is not null then
      l_parameter_info := cwms_util.parse_delimited_text(p_parameter_info);
      for i in 1..l_parameter_info.count loop
         -------------------
         -- common checks --
         -------------------
         if l_parameter_info(i).count > 5 then
            cwms_err.raise('ERROR', 'More than 5 fields specified in parameter record '||i||' of P_PARAMETER_INFO');
         end if;
         if l_delimited then
            ----------------------
            -- delimited checks --
            ----------------------
            if l_parameter_info(i).count < 3 or
               l_parameter_info(i)(1) is null or
               l_parameter_info(i)(2) is null or
               l_parameter_info(i)(3) is null
            then
               cwms_err.raise('ERROR',
               'Record '
               ||i
               ||' of P_PARAMETER_INFO: '
               ||'Fields 1..3 of profile parameter records must not be NULL for delimited parsers');
            end if;
            if l_parameter_info(i).count > 3 and l_parameter_info(i)(4) is not null then
               cwms_err.raise(
                  'ERROR',
                  'Record '
                  ||i
                  ||' of P_PARAMETER_INFO: '
                  ||'Fields 4 and 5 of profile parameter records must be NULL for delimited parsers.');
            end if;
            if l_parameter_info(i).count > 4 and l_parameter_info(i)(5) is not null then
               cwms_err.raise(
                  'ERROR',
                  'Record '
                  ||i
                  ||' of P_PARAMETER_INFO: '
                  ||'Fields 4 and 5 of profile parameter records must be NULL for delimited parsers.');
            end if;
            l_parameter_info(i).trim(l_parameter_info(i).count-3);
         else
            --------------------------
            -- non-delimited checks --
            --------------------------
            l_parser_rec.time_in_two_fields := null; -- regardless of parameter
            if l_parameter_info(i).count < 5 or
               l_parameter_info(i)(1) is null or
               l_parameter_info(i)(2) is null or
               l_parameter_info(i)(3) is not null or
               l_parameter_info(i)(4) is null or
               l_parameter_info(i)(5) is null
            then
               cwms_err.raise(
                  'ERROR',
                  'Record '
                  ||i
                  ||' of P_PARAMETER_INFO: '
                  ||'Fields 1,2,4,and 5 of profile parameter records must not be NULL for non-delimited parsers. Field 3 must be NULL.');
            end if;
         end if;
         --------------------------------------------------------------------------
         -- associate a parameter record with the parameter for later comparison --
         --------------------------------------------------------------------------
         begin
            l_param_rec.parameter_code := cwms_util.get_parameter_code(l_parameter_info(i)(1), p_office_id);
            if l_param_assoc.exists(l_param_rec.parameter_code) then
               cwms_err.raise('ERROR', 'Parameter "'||l_parameter_info(i)(1)||'" specified multiple times in P_PARAMETER_INFO');
            end if;
         exception
            when others then
               if regexp_instr(sqlerrm, 'Parameter ".+?" does not exist', 1, 1, 0, 'm') != 0 then
                  cwms_err.raise('ERROR', 'Invalid parameter "'||l_parameter_info(i)(1)||'" specified in P_PARAMETER_INFO');
               else
                  raise;
               end if;
         end;
         begin
            select cu.unit_code
              into l_param_rec.parameter_unit
              from cwms_unit cu,
                   at_parameter ap,
                   cwms_base_parameter cbp,
                   cwms_office co
             where cu.unit_id =  cwms_util.get_unit_id(l_parameter_info(i)(2), p_office_id)
               and ap.parameter_code = l_param_rec.parameter_code
               and co.office_code = ap.db_office_code
               and cbp.base_parameter_code = ap.base_parameter_code
               and cbp.abstract_param_code = cu.abstract_param_code;
         exception
            when no_data_found then
               cwms_err.raise('ERROR', 'Unit "'||l_parameter_info(i)(2)||'" is not valid for parameter "'||l_parameter_info(i)(1)||'"');
         end;
         if l_delimited then
            l_param_rec.parameter_field := l_parameter_info(i)(3);
         else
            l_param_rec.parameter_col_start := l_parameter_info(i)(4);
            l_param_rec.parameter_col_end   := l_parameter_info(i)(5);
         end if;
         l_param_assoc(l_param_rec.parameter_code) := l_param_rec;
      end loop;
   end if;
   if l_parser_rec.record_delimiter is null then
      cwms_err.raise('ERROR', 'New/updated RECORD_DELIMITER cannot be null');
   end if;
   if l_parser_rec.time_format is null then
      cwms_err.raise('ERROR', 'New/updated TIME_FORMAT cannot be null');
   end if;
   if l_parser_rec.time_zone_code is null then
      cwms_err.raise('ERROR', 'New/updated TIME_ZONE_CODE cannot be null');
   end if;
   if (l_parser_rec.field_delimiter is null) != (l_parser_rec.time_field is null) then
      cwms_err.raise('ERROR', 'Neither or both of new/updated/existing FIELD_DELIMIETER and TIME_FIELD must be present');
   end if;
   if (l_parser_rec.time_field is null) != (l_parser_rec.time_in_two_fields is null) then
      cwms_err.raise('ERROR', 'Neither or both of new/updated/existing TIME_FIELD and TIME_IN_TWO_FIELDS must be present');
   end if;
   if (l_parser_rec.time_field is null) = (l_parser_rec.time_col_start is null) then
      cwms_err.raise('ERROR', 'One (and only one) of new/updated/existing TIME_FIELD and TIME_START_COL/TIME_END_COL must be present');
   end if;
   if (l_parser_rec.time_col_start is null) != (l_parser_rec.time_col_end is null) then
      cwms_err.raise('ERROR', 'Neither or both of (new/updated/existing) TIME_COL_START and TIME_COL_END must be present');
   end if;
   begin
      if to_date(to_char(sysdate, l_parser_rec.time_format), l_parser_rec.time_format) != sysdate then
         cwms_err.raise('ERROR', 'Invalid time format');
      end if;
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid time format: '||l_parser_rec.time_format);
   end;
   if l_parser_rec.time_col_start is not null and l_parser_rec.time_col_end - l_parser_rec.time_col_start + 1 < length(to_char(sysdate, l_parser_rec.time_format)) then
      cwms_err.raise('ERROR', 'Time formatted with new/updated/existing TIME_FORMAT exceeds width specified in new/updated/existing TIME_COL_START and TIME_COL_END');
   end if;
   ---------------------------------------------------
   -- determine whether to update the param records --
   ---------------------------------------------------
   if l_exists then
      l_update_params := false;
      for rec in (select rownum,
                         location_code,
                         key_parameter_code,
                         parameter_code,
                         parameter_unit,
                         parameter_field,
                         parameter_col_start,
                         parameter_col_end
                    from at_ts_profile_parser_param
                   where location_code = l_parser_rec.location_code
                     and key_parameter_code = l_parser_rec.key_parameter_code
                   order by parameter_code
                 )
      loop
         l_count := rec.rownum;
         if not l_param_assoc.exists(rec.parameter_code) or
            rec.parameter_unit               != l_param_assoc(rec.parameter_code).parameter_unit               or
            nvl(rec.parameter_field,     -1) != nvl(l_param_assoc(rec.parameter_code).parameter_field,     -1) or
            nvl(rec.parameter_col_start, -1) != nvl(l_param_assoc(rec.parameter_code).parameter_col_start, -1) or
            nvl(rec.parameter_col_end,   -1) != nvl(l_param_assoc(rec.parameter_code).parameter_col_end,   -1)
         then
            l_update_params := true;
            exit;
         end if;
      end loop;
      if not l_update_params then
         l_update_params := l_count != l_param_assoc.count;
      end if;
   else
      l_update_params := true;
   end if;
   -------------------------
   -- update the database --
   -------------------------
   if l_exists then
      if l_update_params then
         delete
           from at_ts_profile_parser_param
          where location_code = l_parser_rec.location_code
            and key_parameter_code = l_parser_rec.key_parameter_code;
      end if;
      update at_ts_profile_parser
         set row = l_parser_rec
       where location_code = l_parser_rec.location_code
         and key_parameter_code = l_parser_rec.key_parameter_code;
   else
      insert
        into at_ts_profile_parser
      values l_parser_rec;
   end if;
   if l_update_params then
      l_param_rec.parameter_code := l_param_assoc.first;
      loop
         exit when l_param_rec.parameter_code is null;
         l_param_rec := l_param_assoc(l_param_rec.parameter_code);
         l_param_rec.location_code := l_parser_rec.location_code;
         l_param_rec.key_parameter_code := l_parser_rec.key_parameter_code;
         insert
           into at_ts_profile_parser_param
         values l_param_rec;
         l_param_rec.parameter_code := l_param_assoc.next(l_param_rec.parameter_code);
      end loop;
   end if;
end store_ts_profile_parser;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_profile_parser
--------------------------------------------------------------------------------
procedure retrieve_ts_profile_parser(
   p_record_delimiter out nocopy varchar2,
   p_field_delimiter  out nocopy varchar2,
   p_time_field       out nocopy pls_integer,
   p_time_col_start   out nocopy pls_integer,
   p_time_col_end     out nocopy pls_integer,
   p_time_format      out nocopy varchar2,
   p_time_zone        out nocopy varchar2,
   p_parameter_info   out nocopy varchar2,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_office_id        in  varchar2 default null)
is
   l_parser_rec     at_ts_profile_parser%rowtype;
   l_parameter_info varchar2(32767);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   --------------------------------
   -- retrieve the parser record --
   --------------------------------
   begin
      select *
        into l_parser_rec
        from at_ts_profile_parser
       where location_code = cwms_loc.get_location_code(p_office_id, p_location_id)
         and key_parameter_code = cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile parser',
            cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
   end;
   -----------------------------------------------------
   -- build the parameter info from the param records --
   -----------------------------------------------------
   for rec in (select parameter_code,
                      parameter_unit,
                      parameter_field,
                      parameter_col_start,
                      parameter_col_end
                 from at_ts_profile_parser_param
                where location_code = l_parser_rec.location_code
                  and key_parameter_code = l_parser_rec.key_parameter_code
                order by nvl(parameter_field, parameter_col_start)
              )
   loop
      if rec.parameter_field is null then
         l_parameter_info := l_parameter_info
            ||cwms_util.get_parameter_id(rec.parameter_code)||','
            ||cwms_util.get_unit_id2(rec.parameter_unit)||',,'
            ||rec.parameter_col_start||','
            ||rec.parameter_col_end||chr(10);
      else
         l_parameter_info := l_parameter_info
            ||cwms_util.get_parameter_id(rec.parameter_code)||','
            ||cwms_util.get_unit_id2(rec.parameter_unit)||','
            ||rec.parameter_field||chr(10);
      end if;
   end loop;
   ---------------------------------
   -- populate the out nocopy parameters --
   ---------------------------------
   p_record_delimiter := l_parser_rec.record_delimiter;
   p_field_delimiter  := l_parser_rec.field_delimiter;
   p_time_field       := l_parser_rec.time_field;
   p_time_col_start   := l_parser_rec.time_col_start;
   p_time_col_end     := l_parser_rec.time_col_end;
   p_time_format      := l_parser_rec.time_format;
   p_parameter_info   := substr(l_parameter_info, 1, length(l_parameter_info)-1);
   select time_zone_name into p_time_zone from cwms_time_zone where time_zone_code = l_parser_rec.time_zone_code;
end retrieve_ts_profile_parser;
--------------------------------------------------------------------------------
-- procedure delete_ts_profile_parser
--------------------------------------------------------------------------------
procedure delete_ts_profile_parser(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_office_id        in varchar2 default null)
is
   l_parser_rec at_ts_profile_parser%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'     ); end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   --------------------------------
   -- retrieve the parser record --
   --------------------------------
   begin
      select *
        into l_parser_rec
        from at_ts_profile_parser
       where location_code = cwms_loc.get_location_code(p_office_id, p_location_id)
         and key_parameter_code = cwms_util.get_parameter_code(p_key_parameter_id, p_office_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Time series profile parser',
            cwms_util.get_db_office_id(p_office_id)||'/'||p_location_id||'/'||p_key_parameter_id);
   end;
   ----------------------------------
   -- delete the parameter records --
   ----------------------------------
   delete
     from at_ts_profile_parser_param
    where location_code = l_parser_rec.location_code
      and key_parameter_code = l_parser_rec.key_parameter_code;
   ------------------------------
   -- delete the parser record --
   ------------------------------
   delete
     from at_ts_profile_parser
    where location_code = l_parser_rec.location_code
      and key_parameter_code = l_parser_rec.key_parameter_code;
end delete_ts_profile_parser;
--------------------------------------------------------------------------------
-- procedure copy_ts_profile_parser
--------------------------------------------------------------------------------
procedure copy_ts_profile_parser(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_dest_location_id in varchar2,
   p_fail_if_exists   in varchar2 default 'T',
   p_office_id        in varchar2 default null)
is
   l_record_delimiter varchar2(1);
   l_field_delimiter  varchar2(1);
   l_time_field       pls_integer;
   l_time_col_start   pls_integer;
   l_time_col_end     pls_integer;
   l_time_format      varchar2(32);
   l_time_zone        varchar2(28);
   l_parameter_info   varchar2(32767);
begin
   retrieve_ts_profile_parser(
      p_record_delimiter => l_record_delimiter,
      p_field_delimiter  => l_field_delimiter,
      p_time_field       => l_time_field,
      p_time_col_start   => l_time_col_start,
      p_time_col_end     => l_time_col_end,
      p_time_format      => l_time_format,
      p_time_zone        => l_time_zone,
      p_parameter_info   => l_parameter_info,
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_office_id        => p_office_id);

   store_ts_profile_parser(
      p_location_id      => p_dest_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_record_delimiter => l_record_delimiter,
      p_field_delimiter  => l_field_delimiter,
      p_time_field       => l_time_field,
      p_time_start_col   => l_time_col_start,
      p_time_end_col     => l_time_col_end,
      p_time_format      => l_time_format,
      p_time_zone        => l_time_zone,
      p_parameter_info   => l_parameter_info,
      p_fail_if_exists   => p_fail_if_exists,
      p_ignore_nulls     => 'F',
      p_office_id        => p_office_id);
end copy_ts_profile_parser;
--------------------------------------------------------------------------------
-- procedure cat_ts_profile_parser
--------------------------------------------------------------------------------
procedure cat_ts_profile_parser(
   p_profile_parser_rc     out nocopy sys_refcursor,
   p_location_id_mask      in  varchar2 default '*',
   p_key_parameter_id_mask in  varchar2 default '*',
   p_office_id_mask        in  varchar2 default null)
is
begin
   open p_profile_parser_rc for
      select co.office_id,
             cwms_loc.get_location_id(tsp.location_code) as location_id,
             cwms_util.get_parameter_id(tsp.key_parameter_code) as key_paramter_id,
             tsp.record_delimiter,
             tsp.field_delimiter,
             tsp.time_field,
             tsp.time_col_start as time_start_col,
             tsp.time_col_end as time_end_col,
             tsp.time_format,
             ctz.time_zone_name as time_zone,
             cursor (select cwms_util.get_parameter_id(parameter_code) as parameter_id,
                            cwms_util.get_unit_id2(parameter_unit) as unit,
                            parameter_field as field_number,
                            parameter_col_start as start_col,
                            parameter_col_end as end_col
                       from at_ts_profile_parser_param
                      where location_code = tsp.location_code
                        and key_parameter_code = tsp.key_parameter_code
                      order by nvl(parameter_field, parameter_col_start)
                    ) as parameter_info
        from at_ts_profile_parser tsp,
             cwms_office co,
             cwms_time_zone ctz
       where cwms_loc.get_location_id(tsp.location_code) like cwms_util.normalize_wildcards(p_location_id_mask) escape '\'
         and cwms_util.get_parameter_id(tsp.key_parameter_code) like cwms_util.normalize_wildcards(p_key_parameter_id_mask) escape '\'
         and co.office_id like cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.get_db_office_id)) escape '\'
         and ctz.time_zone_code = tsp.time_zone_code;
end cat_ts_profile_parser;
--------------------------------------------------------------------------------
-- function cat_ts_profile_parser_f
--------------------------------------------------------------------------------
function cat_ts_profile_parser_f(
   p_location_id_mask      in varchar2 default '*',
   p_key_parameter_id_mask in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor
is
   l_crsr sys_refcursor;
begin
   cat_ts_profile_parser(
      p_profile_parser_rc     => l_crsr,
      p_location_id_mask      => p_location_id_mask,
      p_key_parameter_id_mask => p_key_parameter_id_mask,
      p_office_id_mask        => p_office_id_mask);

   return l_crsr;
end cat_ts_profile_parser_f;
--------------------------------------------------------------------------------
-- procedure parse_ts_profile_inst_text
--------------------------------------------------------------------------------
procedure parse_ts_profile_inst_text(
   p_ts_profile_data  out nocopy ts_prof_data_t,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_text             in clob,
   p_time_zone        in varchar2,
   p_office_id        in varchar2 default null)
is
begin
   p_ts_profile_data := parse_ts_profile_inst_text_f(
      p_location_id      => p_location_id,
      p_key_parameter_id => p_key_parameter_id,
      p_text             => p_text,
      p_time_zone        => p_time_zone,
      p_office_id        => p_office_id);
end parse_ts_profile_inst_text;
-------------------------------------------------------------------------------
-- function parse_ts_profile_inst_text_f
-------------------------------------------------------------------------------
function parse_ts_profile_inst_text_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_text             in clob,
   p_time_zone        in varchar2,
   p_office_id        in varchar2 default null)
   return ts_prof_data_t
is
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id      is null then cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID'  );    end if;
   if p_key_parameter_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_KEY_PARAMETER_ID'); end if;
   -------------------------------
   -- call the private function --
   -------------------------------
   return parse_ts_prof_inst_text_codes(
      p_location_code      => cwms_loc.get_location_code(p_office_id, p_location_id),
      p_key_parameter_code => cwms_util.get_parameter_code(p_key_parameter_id, p_office_id),
      p_text               => p_text,
      p_time_zone_code     => cwms_util.get_time_zone_code(p_time_zone));
end parse_ts_profile_inst_text_f;

end cwms_ts_profile;
/


create or replace type body zlocation_level_t
as
   constructor function zlocation_level_t(
      p_location_level_code in number)
      return self as result
   as
      l_rec               at_location_level%rowtype;
      l_vrec              at_virtual_location_level%rowtype;
      l_seasonal_values   seasonal_loc_lvl_tab_t  := seasonal_loc_lvl_tab_t();
      l_indicators        loc_lvl_indicator_tab_t := loc_lvl_indicator_tab_t();
      l_constituents      str_tab_tab_t;
      l_parameter_code    number(14);
   begin
      -------------------------
      -- get the main record --
      -------------------------
      ------------------------------
      -- first try virtual levels --
      ------------------------------
      begin
         select *
           into l_vrec
           from at_virtual_location_level
          where location_level_code = p_location_level_code;
      exception
         when no_data_found then
         -------------------------------
         -- fall back to normal level --
         -------------------------------
         select *
           into l_rec
           from at_location_level
          where location_level_code = p_location_level_code;
      end;
      if l_vrec.location_level_code is not null then
         ------------------------------------------
         -- populate from virtual location level --
         ------------------------------------------
         l_constituents := str_tab_tab_t();
         for rec in (select * from at_vloc_lvl_constituent where location_level_code = l_vrec.location_level_code) loop
            l_constituents.extend;
            l_constituents(l_constituents.count) := str_tab_t();
            l_constituents(l_constituents.count).extend(3);
            l_constituents(l_constituents.count)(1) := rec.constituent_abbr;
            l_constituents(l_constituents.count)(2) := rec.constituent_type;
            l_constituents(l_constituents.count)(3) := rec.constituent_name;
            if rec.constituent_attribute_id is not null then
               l_constituents(l_constituents.count).extend(3);
               l_constituents(l_constituents.count)(4) := rec.constituent_attribute_id;
               l_constituents(l_constituents.count)(5) := rec.constituent_attribute_value;
               l_constituents(l_constituents.count)(6) := cwms_util.get_unit_id(cwms_util.get_db_unit_code(cwms_util.split_text(rec.constituent_attribute_id, 1, '.')));
            end if;
         end loop;
         ---------------------------------------
         -- get the location level indicators --
         ---------------------------------------
         for rec in (
            select rowid
              from at_loc_lvl_indicator
             where location_code                     = l_vrec.location_code
               and parameter_code                    = l_vrec.parameter_code
               and parameter_type_code               = l_vrec.parameter_type_code
               and duration_code                     = l_vrec.duration_code
               and specified_level_code              = l_vrec.specified_level_code
               and nvl(to_char(attr_value), '@')     = nvl(to_char(l_vrec.attribute_value), '@')
               and nvl(attr_parameter_code, -1)      = nvl(l_vrec.attribute_parameter_code, -1)
               and nvl(attr_parameter_type_code, -1) = nvl(l_vrec.attribute_parameter_type_code, -1)
               and nvl(attr_duration_code, -1)       = nvl(l_vrec.attribute_duration_code, -1))
         loop
            l_indicators.extend;
            l_indicators(l_indicators.count) := loc_lvl_indicator_t(rec.rowid);
         end loop;
         ---------------------------
         -- initialize the object --
         ---------------------------
         init(
            p_location_level_code       => l_vrec.location_level_code,
            p_location_code             => l_vrec.location_code,
            p_specified_level_code      => l_vrec.specified_level_code,
            p_parameter_code            => l_vrec.parameter_code,
            p_parameter_type_code       => l_vrec.parameter_type_code,
            p_duration_code             => l_vrec.duration_code,
            p_location_level_date       => l_vrec.effective_date,
            p_location_level_value      => null,
            p_location_level_comment    => l_vrec.location_level_comment,
            p_attribute_value           => l_vrec.attribute_value,
            p_attribute_parameter_code  => l_vrec.attribute_parameter_code,
            p_attribute_param_type_code => l_vrec.attribute_parameter_type_code,
            p_attribute_duration_code   => l_vrec.attribute_duration_code,
            p_attribute_comment         => l_vrec.attribute_comment,
            p_interval_origin           => null,
            p_calendar_interval         => null,
            p_time_interval             => null,
            p_interpolate               => null,
            p_ts_code                   => null,
            p_expiration_date           => l_vrec.expiration_date,
            p_seasonal_values           => null,
            p_indicators                => l_indicators,
            p_constituents              => l_constituents,
            p_connections               => l_vrec.constituent_connections);
      else
         -----------------------------------------
         -- populate from normal location level --
         -----------------------------------------
         -----------------------------
         -- get the seasonal values --
         -----------------------------
         for rec in (
            select *
              from at_seasonal_location_level
             where location_level_code = p_location_level_code
          order by l_rec.interval_origin + calendar_offset + time_offset)
         loop
            l_seasonal_values.extend;
            l_seasonal_values(l_seasonal_values.count) := seasonal_location_level_t(
               rec.calendar_offset,
               rec.time_offset,
               rec.value);
         end loop;
         ---------------------------------------
         -- get the location level indicators --
         ---------------------------------------
         for rec in (
            select rowid
              from at_loc_lvl_indicator
             where location_code                     = l_rec.location_code
               and parameter_code                    = l_rec.parameter_code
               and parameter_type_code               = l_rec.parameter_type_code
               and duration_code                     = l_rec.duration_code
               and specified_level_code              = l_rec.specified_level_code
               and nvl(to_char(attr_value), '@')     = nvl(to_char(l_rec.attribute_value), '@')
               and nvl(attr_parameter_code, -1)      = nvl(l_rec.attribute_parameter_code, -1)
               and nvl(attr_parameter_type_code, -1) = nvl(l_rec.attribute_parameter_type_code, -1)
               and nvl(attr_duration_code, -1)       = nvl(l_rec.attribute_duration_code, -1))
         loop
            l_indicators.extend;
            l_indicators(l_indicators.count) := loc_lvl_indicator_t(rec.rowid);
         end loop;
         ---------------------------
         -- initialize the object --
         ---------------------------
         init(
            p_location_level_code       => l_rec.location_level_code,
            p_location_code             => l_rec.location_code,
            p_specified_level_code      => l_rec.specified_level_code,
            p_parameter_code            => l_rec.parameter_code,
            p_parameter_type_code       => l_rec.parameter_type_code,
            p_duration_code             => l_rec.duration_code,
            p_location_level_date       => l_rec.location_level_date,
            p_location_level_value      => l_rec.location_level_value,
            p_location_level_comment    => l_rec.location_level_comment,
            p_attribute_value           => l_rec.attribute_value,
            p_attribute_parameter_code  => l_rec.attribute_parameter_code,
            p_attribute_param_type_code => l_rec.attribute_parameter_type_code,
            p_attribute_duration_code   => l_rec.attribute_duration_code,
            p_attribute_comment         => l_rec.attribute_comment,
            p_interval_origin           => l_rec.interval_origin,
            p_calendar_interval         => l_rec.calendar_interval,
            p_time_interval             => l_rec.time_interval,
            p_interpolate               => l_rec.interpolate,
            p_ts_code                   => l_rec.ts_code,
            p_expiration_date           => l_rec.expiration_date,
            p_seasonal_values           => l_seasonal_values,
            p_indicators                => l_indicators,
            p_constituents              => null,
            p_connections               => null);
         end if;
      return;
   end zlocation_level_t;

   constructor function zlocation_level_t
      return self as result
   is
   begin
      --------------------------
      -- all members are null --
      --------------------------
      return;
   end;

   member procedure init(
      p_location_level_code           in number,
      p_location_code                 in number,
      p_specified_level_code          in number,
      p_parameter_code                in number,
      p_parameter_type_code           in number,
      p_duration_code                 in number,
      p_location_level_date           in date,
      p_location_level_value          in number,
      p_location_level_comment        in varchar2,
      p_attribute_value               in number,
      p_attribute_parameter_code      in number,
      p_attribute_param_type_code     in number,
      p_attribute_duration_code       in number,
      p_attribute_comment             in varchar2,
      p_interval_origin               in date,
      p_calendar_interval             in interval year to month,
      p_time_interval                 in interval day to second,
      p_interpolate                   in varchar2,
      p_ts_code                       in number,
      p_expiration_date               in date,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t,
      p_constituents                  in str_tab_tab_t,
      p_connections                   in varchar2)
   as
      indicator     zloc_lvl_indicator_t;
      l_office_id   varchar2(16);
      l_attr_values number_tab_t;
   begin
      --------------------------------------
      -- verify whether virutal or normal --
      --------------------------------------
      if (p_constituents is null) != (p_connections is null) then
         cwms_err.raise('ERROR', 'Constituents and connections must both be specified or neither');
      end if;
      if p_constituents is not null then
         if p_location_level_value is not null
         or p_interval_origin      is not null
         or p_calendar_interval    is not null
         or p_time_interval        is not null
         or p_ts_code              is not null
         or p_seasonal_values      is not null then
            cwms_err.raise('ERROR', 'Parameters for both virtual and non-virtual location levels are specified');
         end if;
         select o.office_id
           into l_office_id
           from cwms_office o,
                at_base_location bl,
                at_physical_location pl
          where pl.location_code = p_location_code
            and bl.base_location_code = pl.base_location_code
            and o.office_code = bl.db_office_code;

         select to_number(column_value)
           bulk collect
           into l_attr_values
           from table(cwms_util.get_column(p_constituents, 5));

         cwms_level.validate_constituents(
            p_connections_str         => p_connections,
            p_constituent_abbrs       => cwms_util.get_column(p_constituents, 1),
            p_constituent_types       => cwms_util.get_column(p_constituents, 2),
            p_constituent_names       => cwms_util.get_column(p_constituents, 3),
            p_constituent_attr_ids    => cwms_util.get_column(p_constituents, 4),
            p_constituent_attr_values => l_attr_values,
            p_constituent_attr_units  => cwms_util.get_column(p_constituents, 6),
            p_office                  => l_office_id);

      end if;
      ---------------------------
      -- verify the indicators --
      ---------------------------
      if p_indicators is not null then
         for i in 1..p_indicators.count loop
            indicator := p_indicators(i).zloc_lvl_indicator;
            if indicator.location_code                        != location_code
               or indicator.parameter_code                    != parameter_code
               or indicator.parameter_type_code               != parameter_type_code
               or indicator.duration_code                     != duration_code
               or nvl(to_char(indicator.attr_value), '@')     != nvl(to_char(attribute_value), '@')
               or nvl(indicator.attr_parameter_code, -1)      != nvl(attribute_parameter_code, -1)
               or nvl(indicator.attr_parameter_type_code, -1) != nvl(attribute_param_type_code, -1)
               or nvl(indicator.attr_duration_code, -1)       != nvl(attribute_duration_code, -1)
            then
               cwms_err.raise(
                  'ERROR',
                  'Location level indicator does not match location level.');
            end if;
         end loop;
      end if;
      ---------------------------
      -- set the member fields --
      ---------------------------
      self.location_level_code           := p_location_level_code;
      self.location_code                 := p_location_code;
      self.specified_level_code          := p_specified_level_code;
      self.parameter_code                := p_parameter_code;
      self.parameter_type_code           := p_parameter_type_code;
      self.duration_code                 := p_duration_code;
      self.location_level_date           := p_location_level_date;
      self.location_level_value          := p_location_level_value;
      self.location_level_comment        := p_location_level_comment;
      self.attribute_value               := p_attribute_value;
      self.attribute_parameter_code      := p_attribute_parameter_code;
      self.attribute_param_type_code     := p_attribute_param_type_code;
      self.attribute_duration_code       := p_attribute_duration_code;
      self.attribute_comment             := p_attribute_comment;
      self.interval_origin               := p_interval_origin;
      self.calendar_interval             := p_calendar_interval;
      self.time_interval                 := p_time_interval;
      self.interpolate                   := p_interpolate;
      self.ts_code                       := p_ts_code;
      self.expiration_date               := p_expiration_date;
      self.seasonal_level_values         := p_seasonal_values;
      self.indicators                    := p_indicators;
      self.constituents                  := p_constituents;
      self.connections                   := p_connections;
   end init;

   member procedure store
   as
      l_rec               at_location_level%rowtype;
      l_vrec              at_virtual_location_level%rowtype;
      l_exists            boolean;
      l_ind_codes         number_tab_t;
      l_parameter_code    number(14);
      l_vert_datum_offset binary_double;
   begin
      if self.constituents is not null then
         ----------------------------
         -- virtual location level --
         ----------------------------
         ------------------------------
         -- find any existing record --
         ------------------------------
         begin
            select *
              into l_vrec
              from at_virtual_location_level
             where location_level_code = self.location_level_code;
            l_exists := true;
         exception
            when no_data_found then
               l_exists := false;
         end;
         ---------------------------------
         -- set the level record fields --
         ---------------------------------
         l_vrec.location_level_code           := self.location_level_code;
         l_vrec.location_code                 := self.location_code;
         l_vrec.specified_level_code          := self.specified_level_code;
         l_vrec.parameter_code                := self.parameter_code;
         l_vrec.parameter_type_code           := self.parameter_type_code;
         l_vrec.duration_code                 := self.duration_code;
         l_vrec.effective_date                := self.location_level_date;
         l_vrec.attribute_value               := self.attribute_value;
         l_vrec.attribute_parameter_code      := self.attribute_parameter_code;
         l_vrec.attribute_parameter_type_code := self.attribute_param_type_code;
         l_vrec.attribute_duration_code       := self.attribute_duration_code;
         l_vrec.expiration_date               := self.expiration_date;
         l_vrec.constituent_connections       := self.connections;
         l_vrec.location_level_comment        := self.location_level_comment;
         l_vrec.attribute_comment             := self.attribute_comment;
         ----------------------------
         -- store the level record --
         ----------------------------
         if l_exists then
            update at_virtual_location_level
               set row = l_vrec
             where location_level_code = l_vrec.location_level_code;
         else
            l_vrec.location_level_code := cwms_seq.nextval;
            insert
              into at_virtual_location_level
            values l_vrec;
         end if;
         -----------------------------------
         -- store the constituent records --
         -----------------------------------
         if l_exists then
            delete
              from at_vloc_lvl_constituent
             where location_level_code = l_vrec.location_level_code;
         end if;
         for i in 1..self.constituents.count loop
            case self.constituents(i).count
            when 3 then
               insert
                 into at_vloc_lvl_constituent
               values (l_vrec.location_level_code,
                       self.constituents(i)(1),
                       self.constituents(i)(2),
                       self.constituents(i)(3),
                       null,
                       null);
            when 5 then
               insert
                 into at_vloc_lvl_constituent
               values (l_vrec.location_level_code,
                       self.constituents(i)(1),
                       self.constituents(i)(2),
                       self.constituents(i)(3),
                       self.constituents(i)(4),
                       to_number(self.constituents(i)(5)));
            when 6 then
               insert
                 into at_vloc_lvl_constituent
               values (l_vrec.location_level_code,
                       self.constituents(i)(1),
                       self.constituents(i)(2),
                       self.constituents(i)(3),
                       self.constituents(i)(4),
                       cwms_util.convert_units(
                          to_number(self.constituents(i)(5)),
                          self.constituents(i)(6),
                          cwms_util.get_unit_id(cwms_util.get_db_unit_code(cwms_util.split_text(self.constituents(i)(5), 1, '.')))));
            else cwms_err.raise('ERROR', 'Invalid constituent: '||cwms_util.join_text(self.constituents(i), '/'));
            end case;
         end loop;
      else
         ---------------------------
         -- normal location level --
         ---------------------------
         ------------------------------
         -- find any existing record --
         ------------------------------
         begin
            select *
              into l_rec
              from at_location_level
             where location_level_code = self.location_level_code;
            l_exists := true;
         exception
            when no_data_found then
               l_exists := false;
         end;
         ---------------------------------
         -- set the level record fields --
         ---------------------------------
         l_rec.location_level_code           := self.location_level_code;
         l_rec.location_code                 := self.location_code;
         l_rec.specified_level_code          := self.specified_level_code;
         l_rec.parameter_code                := self.parameter_code;
         l_rec.parameter_type_code           := self.parameter_type_code;
         l_rec.duration_code                 := self.duration_code;
         l_rec.location_level_date           := self.location_level_date;
         l_rec.location_level_value          := self.location_level_value;
         l_rec.location_level_comment        := self.location_level_comment;
         l_rec.attribute_value               := self.attribute_value;
         l_rec.attribute_parameter_code      := self.attribute_parameter_code;
         l_rec.attribute_parameter_type_code := self.attribute_param_type_code;
         l_rec.attribute_duration_code       := self.attribute_duration_code;
         l_rec.attribute_comment             := self.attribute_comment;
         l_rec.interval_origin               := self.interval_origin;
         l_rec.calendar_interval             := self.calendar_interval;
         l_rec.time_interval                 := self.time_interval;
         l_rec.interpolate                   := self.interpolate;
         l_rec.ts_code                       := self.ts_code;
         l_rec.expiration_date               := self.expiration_date;
         --------------------------------------
         -- insert or update the main record --
         --------------------------------------
         if l_exists then
            update at_location_level
               set row = l_rec
             where location_level_code = l_rec.location_level_code;
         else
            l_rec.location_level_code := cwms_seq.nextval;
            l_rec.location_level_date := nvl(l_rec.location_level_date, date '1900-01-01');
            insert
              into at_location_level
            values l_rec;
         end if;
         -------------------------------
         -- store the seasonal values --
         -------------------------------
         if l_exists then
           delete
             from at_seasonal_location_level
            where location_level_code = l_rec.location_level_code;
         end if;
         if self.seasonal_level_values is not null then
            l_vert_datum_offset := 0;
            for i in 1..self.seasonal_level_values.count loop
              insert
                into at_seasonal_location_level
              values (l_rec.location_level_code,
                      self.seasonal_level_values(i).calendar_offset,
                      self.seasonal_level_values(i).time_offset,
                      self.seasonal_level_values(i).level_value + l_vert_datum_offset);
            end loop;
         end if;
      end if;
      --------------------------
      -- store the indicators --
      --------------------------
       if l_exists then
         select level_indicator_code
           bulk collect
           into l_ind_codes
           from at_loc_lvl_indicator
          where location_code                     = l_rec.location_code
            and parameter_code                    = l_rec.parameter_code
            and parameter_type_code               = l_rec.parameter_type_code
            and duration_code                     = l_rec.duration_code
            and specified_level_code              = l_rec.specified_level_code
            and nvl(to_char(attr_value), '@')     = nvl(to_char(l_rec.attribute_value), '@')
            and nvl(attr_parameter_code, -1)      = nvl(l_rec.attribute_parameter_code, -1)
            and nvl(attr_parameter_type_code, -1) = nvl(l_rec.attribute_parameter_type_code, -1)
            and nvl(attr_duration_code, -1)       = nvl(l_rec.attribute_duration_code, -1);
         delete
           from at_loc_lvl_indicator_cond
          where level_indicator_code in (select column_value from table(l_ind_codes));
         delete
           from at_loc_lvl_indicator
          where level_indicator_code in (select column_value from table(l_ind_codes));
       end if;
       if self.indicators is not null then
         for i in 1..indicators.count loop
            self.indicators(i).store;
         end loop;
       end if;
   end store;

end;
/
show errors;

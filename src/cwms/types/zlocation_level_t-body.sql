create or replace type body zlocation_level_t
as
   constructor function zlocation_level_t(
      p_location_level_code in number)
      return self as result
   as
      l_rec             at_location_level%rowtype;
      l_seasonal_values seasonal_loc_lvl_tab_t := new seasonal_loc_lvl_tab_t();
      l_indicators      loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
   begin
      -------------------------
      -- get the main record --
      -------------------------
      select *
        into l_rec
        from at_location_level
       where location_level_code = p_location_level_code;
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
         l_rec.location_level_code,
         l_rec.location_code,
         l_rec.specified_level_code,
         l_rec.parameter_code,
         l_rec.parameter_type_code,
         l_rec.duration_code,
         l_rec.location_level_date,
         l_rec.location_level_value,
         l_rec.location_level_comment,
         l_rec.attribute_value,
         l_rec.attribute_parameter_code,
         l_rec.attribute_parameter_type_code,
         l_rec.attribute_duration_code,
         l_rec.attribute_comment,
         l_rec.interval_origin,
         l_rec.calendar_interval,
         l_rec.time_interval,
         l_rec.interpolate,
         l_rec.ts_code,
         l_seasonal_values,
         l_indicators);
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
      p_ts_code                       number,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t)
   as
      indicator zloc_lvl_indicator_t;
   begin
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
      self.ts_code                       :=  p_ts_code;
      self.seasonal_level_values         := p_seasonal_values;
      self.indicators                    := p_indicators;
   end init;

   member procedure store
   as
      l_rec       at_location_level%rowtype;
      l_exists    boolean;
      l_ind_codes number_tab_t;
   begin
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
      ---------------------------
      -- set the record fields --
      ---------------------------
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
          for i in 1..self.seasonal_level_values.count loop
            insert
              into at_seasonal_location_level
            values (l_rec.location_level_code,
                    self.seasonal_level_values(i).calendar_offset,
                    self.seasonal_level_values(i).time_offset,
                    self.seasonal_level_values(i).level_value);
          end loop;
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

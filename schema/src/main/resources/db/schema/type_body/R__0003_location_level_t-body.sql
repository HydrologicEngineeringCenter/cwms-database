create or replace type body location_level_t
as

   constructor function location_level_t(
      p_obj zlocation_level_t)
      return self as result
   is
   begin
      select o.office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id
        into self.office_id,
             self.location_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_obj.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;

      select bp.base_parameter_id
             || substr('-', 1, length(p.sub_parameter_id))
             || p.sub_parameter_id
        into self.parameter_id
        from at_parameter p,
             cwms_base_parameter bp
       where p.parameter_code = p_obj.parameter_code
         and bp.base_parameter_code = p.base_parameter_code;

      select parameter_type_id
        into self.parameter_type_id
        from cwms_parameter_type
       where parameter_type_code = p_obj.parameter_type_code;

      select duration_id
        into self.duration_id
        from cwms_duration
       where duration_code = p_obj.duration_code;

      select specified_level_id
        into self.specified_level_id
        from at_specified_level
       where specified_level_code = p_obj.specified_level_code;

      self.level_date := p_obj.location_level_date;
      self.timezone_id := 'UTC';
      self.level_value := p_obj.location_level_value;
      self.level_units_id := cwms_util.get_unit_id2(cwms_util.get_db_unit_code(parameter_id));

      if p_obj.attribute_parameter_code is not null then
         select bp.base_parameter_id
                || substr('-', 1, length(p.sub_parameter_id))
                || p.sub_parameter_id
           into self.attribute_parameter_id
           from at_parameter p,
                cwms_base_parameter bp
          where p.parameter_code = p_obj.attribute_parameter_code
            and bp.base_parameter_code = p.base_parameter_code;

         select parameter_type_id
           into self.attribute_parameter_type_id
           from cwms_parameter_type
          where parameter_type_code = p_obj.attribute_param_type_code;

         select duration_id
           into self.attribute_duration_id
           from cwms_duration
          where duration_code = p_obj.attribute_duration_code;
         attribute_value := p_obj.attribute_value;
         attribute_units_id := cwms_util.get_unit_id2(cwms_util.get_db_unit_code(attribute_parameter_id));

         attribute_comment := p_obj.attribute_comment;
      end if;

      self.interval_origin  := p_obj.interval_origin;
      self.interval_months  := cwms_util.yminterval_to_months(p_obj.calendar_interval);
      self.interval_minutes := cwms_util.dsinterval_to_minutes(p_obj.time_interval);
      self.interpolate      := p_obj.interpolate;
      self.expiration_date  := p_obj.expiration_date;
      begin
         self.tsid := case p_obj.ts_code is null
                         when true  then null
                         when false then cwms_ts.get_ts_id(p_obj.ts_code)
                      end;
      exception
         when no_data_found then
            ---------------------------------------------------------------------
            -- this happens when deleting irregularly varying location levels  --
            -- the time series is deleted before the location level is deleted --
            ---------------------------------------------------------------------
            self.tsid := null;
      end;
      if p_obj.seasonal_level_values is not null then
         self.seasonal_values := new seasonal_value_tab_t();
         for i in 1..p_obj.seasonal_level_values.count loop
            self.seasonal_values.extend;
            dbms_output.put_line('Seasonal Cal_offset: ' || p_obj.seasonal_level_values(i).calendar_offset);
            self.seasonal_values(i) := seasonal_value_t(
               p_obj.seasonal_level_values(i).calendar_offset,
               p_obj.seasonal_level_values(i).time_offset,
               p_obj.seasonal_level_values(i).level_value);
         end loop;
      end if;
      self.indicators   := p_obj.indicators;
      self.constituents := p_obj.constituents;
      self.connections  := p_obj.connections;

      return;
   end location_level_t;

 constructor function location_level_t
      return self as result
   is
   begin
      --------------------------
      -- all members are null --
      --------------------------
      return;
   end;

   member function zlocation_level
      return zlocation_level_t
   is
      l_office_code                   number(14);
      l_cwms_office_code              number(14) := cwms_util.get_office_code('CWMS');
      l_location_level_code           number(14);
      l_location_code                 number(14);
      l_specified_level_code          number(14);
      l_parameter_code                number(14);
      l_parameter_type_code           number(14);
      l_duration_code                 number(14);
      l_location_level_value          number;
      l_attribute_value               number;
      l_attribute_parameter_code      number(14);
      l_attribute_param_type_code     number(14);
      l_attribute_duration_code       number(14);
      l_calendar_interval             interval year(2) to month;
      l_time_interval                 interval day(3) to second(0);
      l_seasonal_level_values         seasonal_loc_lvl_tab_t;
      l_obj                           zlocation_level_t;
      l_parameter_type_id             parameter_type_id%type := parameter_type_id;
      l_duration_id                   duration_id%type := duration_id;
      l_specified_level_id            specified_level_id%type := specified_level_id;
      l_current_vertical_datum        at_vert_datum_offset.vertical_datum_id_1%type;
      l_clone                         location_level_t := self;

   begin
      l_current_vertical_datum := self.vertical_datum;
      if l_current_vertical_datum is not null then
         l_clone.set_to_native_vertical_datum;
      end if;
      select o.office_code,
             pl.location_code
        into l_office_code,
             l_location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where upper(o.office_id) = upper(l_clone.office_id)
         and bl.db_office_code = o.office_code
         and bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id) = upper(cwms_util.get_base_id(l_clone.location_id))
         and upper(nvl(pl.sub_location_id, '.')) = upper(nvl(cwms_util.get_sub_id(l_clone.location_id), '.'));

      select p.parameter_code
        into l_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(l_clone.parameter_id))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '.')) = upper(nvl(cwms_util.get_sub_id(l_clone.parameter_id), '.'))
         and p.db_office_code in (l_office_code, l_cwms_office_code);

      select pt.parameter_type_code
        into l_parameter_type_code
        from cwms_parameter_type pt
       where upper(pt.parameter_type_id) = upper(l_parameter_type_id);

      select d.duration_code
        into l_duration_code
        from cwms_duration d
       where upper(d.duration_id) = upper(l_duration_id);

      select sl.specified_level_code
        into l_specified_level_code
        from at_specified_level sl
       where upper(sl.specified_level_id) = upper(l_specified_level_id);

      l_location_level_value := cwms_util.convert_units(
         level_value,
         l_clone.level_units_id,
         cwms_util.get_unit_id2(cwms_util.get_db_unit_code(l_clone.parameter_id)));

      if l_clone.attribute_parameter_id is not null then
         select p.parameter_code
           into l_attribute_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(l_clone.attribute_parameter_id))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '.')) = upper(nvl(cwms_util.get_sub_id(l_clone.attribute_parameter_id), '.'))
            and p.db_office_code in (l_office_code, l_cwms_office_code);

         select pt.parameter_type_code
           into l_attribute_param_type_code
           from cwms_parameter_type pt
          where upper(pt.parameter_type_id) = upper(l_clone.attribute_parameter_type_id);

         select d.duration_code
           into l_attribute_duration_code
           from cwms_duration d
          where upper(d.duration_id) = upper(l_clone.attribute_duration_id);

         select cwms_rounding.round_f(nvl(cwms_util.eval_rpn_expression(function, double_tab_t(l_clone.attribute_value)), l_clone.attribute_value), 12)
           into l_attribute_value
           from cwms_unit_conversion cuc
          where from_unit_id = attribute_units_id
            and to_unit_id = cwms_util.get_unit_id2(cwms_util.get_db_unit_code(l_clone.attribute_parameter_id));
      end if;

      l_calendar_interval := cwms_util.months_to_yminterval(l_clone.interval_months);
      l_time_interval     := cwms_util.minutes_to_dsinterval(l_clone.interval_minutes);

      if l_clone.seasonal_values is not null then
         l_seasonal_level_values := new seasonal_loc_lvl_tab_t();
         for i in 1..l_clone.seasonal_values.count loop
            l_seasonal_level_values.extend;
            l_seasonal_level_values(i) := seasonal_location_level_t(
               cwms_util.months_to_yminterval(l_clone.seasonal_values(i).offset_months),
               cwms_util.minutes_to_dsinterval(l_clone.seasonal_values(i).offset_minutes),
               cwms_util.convert_units(
                  seasonal_values(i).value,
                  l_clone.level_units_id,
                  cwms_util.get_unit_id2(cwms_util.get_db_unit_code(l_clone.parameter_id))));
         end loop;
      end if;

      begin
         select location_level_code
           into l_location_level_code
           from at_location_level
          where location_code = l_location_code
            and parameter_code = l_parameter_code
            and parameter_type_code = l_parameter_type_code
            and duration_code = l_duration_code
            and specified_level_code = l_specified_level_code
            and location_level_date = l_clone.level_date
            and nvl(to_char(attribute_value), '@') = nvl(to_char(l_attribute_value), '@')
            and nvl(attribute_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
            and nvl(attribute_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
            and nvl(attribute_duration_code, -1) = nvl(l_attribute_duration_code, -1);
      exception
         when no_data_found then null;
      end;
      l_obj := zlocation_level_t();
      l_obj.init(
         nvl(l_location_level_code, cwms_seq.nextval),
         l_location_code,
         l_specified_level_code,
         l_parameter_code,
         l_parameter_type_code,
         l_duration_code,
         cwms_util.change_timezone(l_clone.level_date, l_clone.timezone_id, 'UTC'),
         l_location_level_value,
         l_clone.level_comment,
         l_attribute_value,
         l_attribute_parameter_code,
         l_attribute_param_type_code,
         l_attribute_duration_code,
         l_clone.attribute_comment,
         cwms_util.change_timezone(l_clone.interval_origin, l_clone.timezone_id, 'UTC'),
         l_calendar_interval,
         l_time_interval,
         l_clone.interpolate,
         case l_clone.tsid is null
            when true  then null
            when false then cwms_ts.get_ts_code(l_clone.tsid, l_office_code)
         end,
         l_clone.expiration_date,
         l_seasonal_level_values,
         l_clone.indicators,
         l_clone.constituents,
         l_clone.connections);

      return l_obj;
   end zlocation_level;

   member function location_level_id
      return varchar2
   is
   begin
      return self.location_id
             ||'.'||self.parameter_id
             ||'.'||self.parameter_type_id
             ||'.'||self.duration_id
             ||'.'||self.specified_level_id;
   end location_level_id;

   member function attribute_id
      return varchar2
   is
      l_attribute_id varchar2(83);
   begin
      if self.attribute_parameter_id is not null then
         l_attribute_id := self.attribute_parameter_id
                           ||'.'||self.attribute_parameter_type_id
                           ||'.'||self.duration_id;
      end if;
      return l_attribute_id;
   end attribute_id;

   member procedure set_timezone(
      p_timezone_id in varchar2)
   is
      l_timezone_id varchar2(28);
   begin
      l_timezone_id := cwms_util.get_time_zone_name(p_timezone_id);
      self.level_date := cwms_util.change_timezone(self.level_date, self.timezone_id, l_timezone_id);
      if self.expiration_date is not null then
         self.expiration_date := cwms_util.change_timezone(self.expiration_date, self.timezone_id, l_timezone_id);
      end if;
      if self.interval_origin is not null then
         self.interval_origin := cwms_util.change_timezone(self.interval_origin, self.timezone_id, l_timezone_id);
      end if;
      self.timezone_id := l_timezone_id;
   end set_timezone;

   member procedure set_level_unit(
      p_level_unit in varchar2)
   is
   begin
      if self.level_value is not null then
         self.level_value := cwms_util.convert_units(self.level_value, self.level_units_id, p_level_unit);
      end if;
      if self.seasonal_values is not null then
         for i in 1..self.seasonal_values.count loop
            self.seasonal_values(i).value := cwms_util.convert_units(self.seasonal_values(i).value, self.level_units_id, p_level_unit);
         end loop;
      end if;
      self.level_units_id := p_level_unit;
   end set_level_unit;

   member procedure set_attribute_unit(
      p_attribute_unit in varchar2)
   is
   begin
      if self.attribute_value is not null then
         self.attribute_value := cwms_util.convert_units(self.attribute_value, self.attribute_units_id, p_attribute_unit);
         self.attribute_units_id := p_attribute_unit;
      end if;
   end set_attribute_unit;

   member procedure set_unit_system(
      p_unit_system in varchar2)
   is
      l_level_unit varchar2(16);
      l_attr_unit  varchar2(16);
   begin
      if p_unit_system not in ('EN', 'SI') then
         cwms_err.raise('ERROR', 'P_UNIT_SYSTEM must be one of ''EN'' or ''SI''');
      end if;
      self.set_level_unit(cwms_util.get_default_units(self.parameter_id, p_unit_system));
      if self.attribute_value is not null then
         self.set_attribute_unit(cwms_util.get_default_units(self.attribute_parameter_id, p_unit_system));
      end if;
   end set_unit_system;

   member procedure set_vertical_datum(
      p_vertical_datum in varchar2)
   is
      l_vert_datum_offset binary_double;
   begin
      if instr(self.parameter_id, 'Elev') != 1 and instr(self.attribute_parameter_id, 'Elev') != 1 then
         cwms_err.raise('ERROR', 'Cannot set vertical datum on location level unless parameter or attribute parameter is elevation');
      end if;
      if self.vertical_datum is null then
         self.vertical_datum := cwms_loc.get_location_vertical_datum(
            p_location_id => self.location_id,
            p_office_id   => self.office_id);
      end if;
      if instr(self.parameter_id, 'Elev') = 1 then
         l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(
            p_location_id         => self.location_id,
            p_vertical_datum_id_1 => self.vertical_datum,
            p_vertical_datum_id_2 => p_vertical_datum,
            p_datetime            => self.level_date,
            p_time_zone           => self.timezone_id,
            p_unit                => self.level_units_id,
            p_office_id           => self.office_id);
         if self.level_value is not null then
            self.level_value := self.level_value + l_vert_datum_offset;
         end if;
         if self.seasonal_values is not null then
            for i in 1..self.seasonal_values.count loop
               self.seasonal_values(i).value := self.seasonal_values(i).value + l_vert_datum_offset;
            end loop;
         end if;
      end if;
      if instr(self.attribute_parameter_id, 'Elev') = 1 then
         l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(
            p_location_id         => self.location_id,
            p_vertical_datum_id_1 => self.vertical_datum,
            p_vertical_datum_id_2 => p_vertical_datum,
            p_datetime            => self.level_date,
            p_time_zone           => self.timezone_id,
            p_unit                => self.attribute_units_id,
            p_office_id           => self.office_id);
         self.attribute_value := self.attribute_value + l_vert_datum_offset;
      end if;
   end set_vertical_datum;

   member procedure set_to_native_vertical_datum
   is
   begin
      self.set_vertical_datum(cwms_loc.get_location_vertical_datum(self.location_id, self.office_id));
   end set_to_native_vertical_datum;

   member function is_virtual
      return boolean is
   begin
      return self.constituents is not null;
   end is_virtual;

   member procedure store
   is
      l_obj zlocation_level_t;
   begin
      l_obj:= zlocation_level;
      l_obj.store;
   end store;
end;

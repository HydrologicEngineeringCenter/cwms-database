create or replace type body loc_lvl_indicator_t
as
   constructor function loc_lvl_indicator_t(
      p_obj in zloc_lvl_indicator_t)
      return self as result
   is
   begin
      init(p_obj);
      return;
   end loc_lvl_indicator_t;

   constructor function loc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result
   is
   begin
      init(zloc_lvl_indicator_t(p_rowid));
      return;
   end loc_lvl_indicator_t;

   member procedure init(
      p_obj in zloc_lvl_indicator_t)
   is
   begin
      select o.office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id
        into office_id,
             location_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_obj.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;

      select bp.base_parameter_id
             || substr('-', 1, length(p.sub_parameter_id))
             || p.sub_parameter_id
        into parameter_id
        from at_parameter p,
             cwms_base_parameter bp
       where p.parameter_code = p_obj.parameter_code
         and bp.base_parameter_code = p.base_parameter_code;

      select parameter_type_id
        into parameter_type_id
        from cwms_parameter_type
       where parameter_type_code = p_obj.parameter_type_code;

      select duration_id
        into duration_id
        from cwms_duration
       where duration_code = p_obj.duration_code;

      select specified_level_id
        into specified_level_id
        from at_specified_level
       where specified_level_code = p_obj.specified_level_code;

      if p_obj.attr_value is not null then
         select bp.base_parameter_id
                || substr('-', 1, length(p.sub_parameter_id))
                || p.sub_parameter_id,
                u.unit_id
           into attr_parameter_id,
                attr_units_id
           from at_parameter p,
                cwms_base_parameter bp,
                cwms_unit u
          where p.parameter_code = p_obj.attr_parameter_code
            and bp.base_parameter_code = p.base_parameter_code
            and u.unit_code = bp.unit_code;

         select parameter_type_id
           into attr_parameter_type_id
           from cwms_parameter_type
          where parameter_type_code = p_obj.attr_parameter_type_code;

         select duration_id
           into attr_duration_id
           from cwms_duration
          where duration_code = p_obj.attr_duration_code;
         attr_value := p_obj.attr_value;
      end if;

      if p_obj.ref_specified_level_code is not null then
         select specified_level_id
           into ref_specified_level_id
           from at_specified_level
          where specified_level_code = p_obj.ref_specified_level_code;
         ref_attr_value := p_obj.ref_attr_value;
      end if;

      level_indicator_id := p_obj.level_indicator_id;
      minimum_duration   := p_obj.minimum_duration;
      maximum_age        := p_obj.maximum_age;
      conditions         := p_obj.conditions;
   end init;

   member function zloc_lvl_indicator
      return zloc_lvl_indicator_t
   is
      l_parts       str_tab_t;
      l_obj         zloc_lvl_indicator_t := new zloc_lvl_indicator_t;
      l_sub_id      varchar2(48);
      l_id          varchar2(256);
      l_factor      binary_double;
      l_offset      binary_double;
   begin
      l_parts := cwms_util.split_text(location_id, '-', 1);
      l_sub_id := case l_parts.count
                     when 1 then null
                     else l_parts(2)
                  end;
      select pl.location_code
        into l_obj.location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where upper(o.office_id) = upper(self.office_id)
         and bl.db_office_code = o.office_code
         and upper(bl.base_location_id) = upper(l_parts(1))
         and pl.base_location_code = bl.base_location_code
         and upper(nvl(pl.sub_location_id, '@')) = upper(nvl(l_sub_id, '@'));

      l_parts := cwms_util.split_text(parameter_id, '-', 1);
      l_sub_id := case l_parts.count
                     when 1 then null
                     else l_parts(2)
                  end;
      select p.parameter_code
        into l_obj.parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(l_parts(1))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '@')) = upper(nvl(l_sub_id, '@'))
         and p.db_office_code in (cwms_util.get_db_office_code(self.office_id), cwms_util.db_office_code_all);

      l_id := parameter_type_id;
      select parameter_type_code
        into l_obj.parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(l_id);

      l_id := duration_id;
      select duration_code
        into l_obj.duration_code
        from cwms_duration
       where upper(duration_id) = upper(l_id);

      l_id := specified_level_id;
      begin
         select specified_level_code
           into l_obj.specified_level_code
           from at_specified_level
          where upper(specified_level_id) = upper(l_id)
            and office_code in (cwms_util.get_db_office_code(self.office_id), cwms_util.db_office_code_all);
      exception
         when no_data_found then
            cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Specified level', upper(l_id));
      end;

      if attr_value is not null then
         l_parts := cwms_util.split_text(attr_parameter_id, '-', 1);
         l_sub_id := case l_parts.count
                        when 1 then null
                        else l_parts(2)
                     end;
         select p.parameter_code
           into l_obj.attr_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(l_parts(1))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '@')) = upper(nvl(l_sub_id, '@'));
         select parameter_type_code
           into l_obj.attr_parameter_type_code
           from cwms_parameter_type
          where upper(parameter_type_id) = upper(attr_parameter_type_id);

         select duration_code
           into l_obj.attr_duration_code
           from cwms_duration
          where upper(duration_id) = upper(attr_duration_id);

         select factor,
                offset
           into l_factor,
                l_offset
           from cwms_unit_conversion
          where from_unit_id = attr_units_id
            and to_unit_id = cwms_util.get_default_units(attr_parameter_id);
      end if;

      if ref_specified_level_id is not null then
         select sl.specified_level_code
           into l_obj.ref_specified_level_code
           from at_specified_level sl
          where upper(sl.specified_level_id) = upper(ref_specified_level_id)
            and sl.office_code in (
                select office_code
                  from cwms_office
                 where office_id in (self.office_id, 'CWMS'));
      end if;

      l_obj.level_indicator_id := level_indicator_id;
      l_obj.attr_value         := cwms_rounding.round_f(attr_value * l_factor + l_offset, 12);
      l_obj.ref_attr_value     := cwms_rounding.round_f(ref_attr_value * l_factor + l_offset, 12);
      l_obj.minimum_duration   := minimum_duration;
      l_obj.maximum_age        := maximum_age;
      l_obj.conditions         := conditions;

      return l_obj;
   end zloc_lvl_indicator;

   member procedure store
   is
      l_obj zloc_lvl_indicator_t := zloc_lvl_indicator;
   begin
      l_obj.store;
   end store;

   member function get_indicator_expr_values(
      p_ts        in ztsv_array,
      p_unit      in varchar2 default null,
      p_condition in integer  default null,
      p_eval_time in date     default null,
      p_time_zone in varchar2 default null)
      return double_tab_tab_t
   is
      l_results       double_tab_tab_t;
      l_unit          varchar2(16);
      l_default_unit  varchar2(16);
      l_conditions    number_tab_t;
      l_eval_times    date_table_type;
      l_values        double_tab_t;
      l_time_zone     varchar2(28);
      l_level1_id     varchar2(512);
      l_level2_id     varchar2(512);
      l_level_attr_id varchar2(256);
      l_level1_values double_tab_t;
      l_level2_values double_tab_t;
      l_rate          binary_double;

   begin
      l_default_unit := cwms_util.get_default_units(self.parameter_id);
      l_unit := cwms_util.get_unit_id(nvl(p_unit, l_default_unit));
      l_time_zone := cwms_util.get_timezone(nvl(p_time_zone, 'UTC'));
      -----------------------------------------
      -- get the evaluation times and values --
      -----------------------------------------
      l_eval_times := date_table_type();
      l_values := double_tab_t();
      if p_eval_time is null then
         l_eval_times.extend(p_ts.count);
         l_values.extend(p_ts.count);
         for i in 1..p_ts.count loop
            l_eval_times(i) := p_ts(i).date_time;
            l_values(i) := p_ts(i).value;
         end loop;
      else
         l_eval_times.extend;
         l_values.extend;
         l_eval_times(1) := p_eval_time;
         select value
           into l_values(1)
           from table(p_ts)
          where date_time = (select max(date_time) from table(p_ts) where date_time <= p_eval_time);
      end if;
      if l_time_zone != 'UTC' then
         for i in 1..l_eval_times.count loop
            l_eval_times(i) := cwms_util.change_timezone(l_eval_times(i), l_time_zone, 'UTC');
         end loop;
      end if;
      if l_unit != l_default_unit then
         for i in 1..l_values.count loop
            l_values(i) := cwms_util.convert_units(l_values(i), l_unit, l_default_unit);
         end loop;
      end if;
      --------------------------------------------------
      -- get the level values for the specified times --
      --------------------------------------------------
      l_level1_id := cwms_util.join_text(
         str_tab_t(
            self.location_id,
            self.parameter_id,
            self.parameter_type_id,
            self.duration_id,
            self.specified_level_id),
         '.');

      if self.ref_specified_level_id is not null then
         l_level2_id := cwms_util.join_text(
            str_tab_t(
               self.location_id,
               self.parameter_id,
               self.parameter_type_id,
               self.duration_id,
               self.ref_specified_level_id),
            '.');
      end if;

      if self.attr_parameter_id is not null then
         l_level_attr_id := cwms_util.join_text(
            str_tab_t(
               self.attr_parameter_id,
               self.attr_parameter_type_id,
               self.attr_duration_id),
            '.');
      end if;

      l_level1_values := cwms_level.retrieve_loc_lvl_values3(
         p_specified_times   => l_eval_times,
         p_location_level_id => l_level1_id,
         p_level_units       => l_default_unit,
         p_attribute_id      => l_level_attr_id,
         p_attribute_value   => self.attr_value,
         p_attribute_units   => self.attr_units_id,
         p_timezone_id       => 'UTC',
         p_office_id         => self.office_id);

      if l_level2_id is null then
         l_level2_values := double_tab_t();
         l_level2_values.extend(l_eval_times.count);
      else
         l_level2_values := cwms_level.retrieve_loc_lvl_values3(
            p_specified_times   => l_eval_times,
            p_location_level_id => l_level2_id,
            p_level_units       => l_default_unit,
            p_attribute_id      => l_level_attr_id,
            p_attribute_value   => self.ref_attr_value,
            p_attribute_units   => self.attr_units_id,
            p_timezone_id       => 'UTC',
            p_office_id         => self.office_id);
      end if;
      -----------------------------
      -- build the results table --
      -----------------------------
      l_results := double_tab_tab_t();
      l_results.extend(l_eval_times.count);
      for i in 1..l_results.count loop
         l_results(i) := double_tab_t();
         l_results(i).extend(case when p_condition is null then 5 else 1 end);
      end loop;
      --------------------------------
      -- populate the results table --
      --------------------------------
      for i in 1..l_eval_times.count loop
         if p_condition is null then
            for j in 1..5 loop
               if self.conditions(j).rate_expression is null then
                  l_results(i)(j) := self.conditions(j).eval_expression(
                     l_values(i),
                     l_level1_values(i),
                     l_level2_values(i));
               else
               if i > 1 then
                  l_rate := (l_values(i) - l_values(i-1)) / (l_eval_times(i) - l_eval_times(i-1)); -- per day
                  l_rate := l_rate / 24; -- per hour, condition will convert from here to final interval
                  l_results(i)(j) := self.conditions(j).eval_rate_expression(l_rate);
               end if;
               end if;
            end loop;
         else
            if self.conditions(p_condition).rate_expression is null then
               l_results(i)(1) := self.conditions(p_condition).eval_expression(
                  l_values(i),
                  l_level1_values(i),
                  l_level2_values(i));
            else
               if i > 1 then
                  l_rate := (l_values(i) - l_values(i-1)) / (l_eval_times(i) - l_eval_times(i-1)); -- per day
                  l_rate := l_rate / 24; -- per hour, condition will convert from here to final interval
                  l_results(i)(1) := self.conditions(p_condition).eval_rate_expression(l_rate);
               end if;
            end if;
         end if;
      end loop;
      return l_results;
   end get_indicator_expr_values;

   member function get_indicator_values(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number_tab_t
   is
      l_eval_time            date := nvl(p_eval_time, cast(systimestamp at time zone 'UTC' as date));
      l_max_age              number;
      l_min_dur              number;
      l_indicator_values     number_tab_t := number_tab_t();
      l_rate_of_change       boolean := false;
      l_is_set               boolean;
      l_set                  boolean;
      l_last                 pls_integer;
      l_level_values_1       ztsv_array;
      l_level_values_2       ztsv_array;
      l_level_values_array_1 double_tab_t := double_tab_t();
      l_level_values_array_2 double_tab_t := double_tab_t();
      l_rate_values_array    double_tab_t := double_tab_t();
      i                      binary_integer;
      j                      binary_integer;
      function is_valid(
         p_quality_code in number)
         return boolean
      is
         -- l_validity_id varchar2(16);
      begin
         /*
         select validity_id
           into l_validity_id
           from cwms_data_quality
          where quality_code = p_quality_code;
         return l_validity_id not in ('MISSING', 'REJECTED');
         */
         return bitand(p_quality_code, 20) = 0; -- 30 x faster!
      end is_valid;
   begin
      --------------------------------------
      -- create day values from durations --
      --------------------------------------
      l_max_age := extract(day    from maximum_age) +
                  (extract(hour   from maximum_age) / 24) +
                  (extract(minute from maximum_age) / 1440) +
                  (extract(second from maximum_age) / 86400);
      l_min_dur := extract(day    from minimum_duration) +
                  (extract(hour   from minimum_duration) / 24) +
                  (extract(minute from minimum_duration) / 1440) +
                  (extract(second from minimum_duration) / 86400);
      -------------------------------------
      -- determine whether we need rates --
      -------------------------------------
      for i in 1..conditions.count loop
         if not l_rate_of_change and conditions(i).rate_expression is not null then
            l_rate_of_change := true;
         end if;
         exit when l_rate_of_change;
      end loop;
      ----------------------------------------------------------------
      -- find the last valid value on or before the evaluation time --
      ----------------------------------------------------------------
      if p_ts is null or p_ts.count = 0 then
         return l_indicator_values;
      end if;
      for i in reverse 1..p_ts.count loop
         l_last := i;
         continue when p_ts(l_last).date_time > l_eval_time;
         exit when bitand(p_ts(l_last).quality_code, 20) = 0; --is_valid(p_ts(l_last).quality_code);
      end loop;
      -------------------------------------------------------
      -- only evaluate if last valid time is recent enough --
      -------------------------------------------------------
      if l_eval_time - p_ts(l_last).date_time <= l_max_age then
         l_rate_values_array.extend(l_last);
         if l_rate_of_change then
            -------------------------------------------------------
            -- compute the hourly rates of change if using rates --
            -------------------------------------------------------
            for i in reverse 2..l_last loop
               continue when bitand(p_ts(i).quality_code, 20) != 0; --not is_valid(p_ts(i).quality_code);
               for j in reverse 1..i-1 loop
                  get_indicator_values.j := j;
                  exit when bitand(p_ts(j).quality_code, 20) = 0; --is_valid(p_ts(j).quality_code);
               end loop;
               l_rate_values_array(i) :=
                  (p_ts(i).value - p_ts(j).value) /
                  ((p_ts(i).date_time - p_ts(j).date_time) * 24);
            end loop;
         end if;
         --------------------------------------------------
         -- retrieve the level values to compare against --
         --------------------------------------------------
         l_level_values_1 := cwms_level.retrieve_location_level_values(
            cwms_level.get_location_level_id(
               location_id,
               parameter_id,
               parameter_type_id,
               duration_id,
               specified_level_id),
            cwms_util.get_default_units(parameter_id),
            p_ts(1).date_time,
            p_ts(l_last).date_time,
            cwms_level.get_attribute_id(
               attr_parameter_id,
               attr_parameter_type_id,
               attr_duration_id),
            attr_value,
            attr_units_id,
            'UTC',
            office_id);
         if ref_specified_level_id is not null then
            l_level_values_2 := cwms_level.retrieve_location_level_values(
               cwms_level.get_location_level_id(
                  location_id,
                  parameter_id,
                  parameter_type_id,
                  duration_id,
                  ref_specified_level_id),
               cwms_util.get_default_units(parameter_id),
               p_ts(1).date_time,
               p_ts(l_last).date_time,
               cwms_level.get_attribute_id(
                  attr_parameter_id,
                  attr_parameter_type_id,
                  attr_duration_id),
               ref_attr_value,
               attr_units_id,
               'UTC',
               office_id);
         end if;
         ----------------------------------
         -- build tables of level values --
         ----------------------------------
         l_level_values_array_1.extend(l_last);
         l_level_values_array_2.extend(l_last);
         j := l_level_values_1.count;
         for i in reverse 1..l_last loop
            while l_level_values_1(j).date_time > p_ts(i).date_time loop
               exit when j = 1;
               j := j - 1;
            end loop;
            l_level_values_array_1(i) := l_level_values_1(j).value;
         end loop;
         if ref_specified_level_id is not null then
            j := l_level_values_2.count;
            for i in reverse 1..l_last loop
               while l_level_values_2(j).date_time > p_ts(i).date_time loop
                  exit when j = 1;
                  j := j - 1;
               end loop;
               l_level_values_array_2(i) := l_level_values_2(j).value;
            end loop;
         end if;
         -----------------------------
         -- evaluate each condition --
         -----------------------------
         for i in 1..conditions.count loop
            l_set := false;
            for j in reverse 1..l_last loop
               continue when bitand(p_ts(j).quality_code, 20) != 0; --not is_valid(p_ts(j).quality_code);
               exit when not conditions(i).is_set(
                  p_ts(j).value,
                  l_level_values_array_1(j),
                  l_level_values_array_2(j),
                  l_rate_values_array(j));
               if (p_ts(l_last).date_time - p_ts(j).date_time) >= l_min_dur then
                  l_set := true;
                  exit;
               end if;
            end loop;
            if l_set then
               l_indicator_values.extend;
               l_indicator_values(l_indicator_values.count) := conditions(i).indicator_value;
            end if;
         end loop;
      end if;
      return l_indicator_values;
   end get_indicator_values;

   member function get_max_indicator_value(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number
   is
      l_eval_time           date;
      l_lookback_time       date;
      l_indicator_values    number_tab_t;
      l_max_indicator_value number;
      l_eval_times          date_table_type;
   begin
      l_eval_time     := nvl(p_eval_time, sysdate);
      l_lookback_time := cast(cast(l_eval_time as timestamp) - maximum_age as date);
      ------------------------------------------------------------------------------------------
      -- get a reversed-ordered collection of times in the data and also within lookback time --
      ------------------------------------------------------------------------------------------
      select t.date_time
        bulk collect into l_eval_times
        from table(p_ts) t
       where t.date_time between l_lookback_time and l_eval_time
       order by t.date_time desc;
      ----------------------------------------------------------------
      -- get the first (most recent) time that has a non-zero value --
      ----------------------------------------------------------------
      for i in 1..l_eval_times.count loop
         l_indicator_values := get_indicator_values(p_ts, l_eval_times(i));
         case l_indicator_values.count
            when 0 then l_max_indicator_value :=  0;
            else l_max_indicator_value := l_indicator_values(l_indicator_values.count);
         end case;
         exit when l_max_indicator_value != 0;
      end loop;
      return l_max_indicator_value;
   end get_max_indicator_value;

   member function get_max_indicator_values(
      p_ts         in ztsv_array,
      p_start_time in date)
      return ztsv_array
   is
      l_results ztsv_array := new ztsv_array();
   begin
      for i in 1..p_ts.count loop
         continue when p_ts(i).date_time < p_start_time;
         l_results.extend;
         l_results(l_results.count) := new ztsv_type(
            p_ts(i).date_time,
            get_max_indicator_value(p_ts, p_ts(i).date_time),
            0);
      end loop;
      return l_results;
   end get_max_indicator_values;

end;
/
show errors;

CREATE OR REPLACE PACKAGE BODY cwms_level as

--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE validate_specified_level_input
--------------------------------------------------------------------------------
procedure validate_specified_level_input(
   p_office_code out number,
   p_office_id   in  varchar2,
   p_level_id    in  varchar2)
is
begin
   if p_level_id != ltrim(rtrim(p_level_id)) then
      cwms_err.raise('ERROR', 'Level id includes leading or trailing spaces');
   end if;
   if p_level_id is null then
      cwms_err.raise('ERROR', 'Level id cannot be null');
   end if;
   begin
      select office_code
        into p_office_code
        from cwms_office
       where office_id = nvl(upper(p_office_id), cwms_util.user_office_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_OFFICE_ID',
            p_office_id);
   end;
end;   

--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE get_units_conversion
--------------------------------------------------------------------------------
procedure get_units_conversion(
   p_factor         out binary_double,
   p_offset         out binary_double,
   p_direction      in  varchar2,
   p_units          in  varchar2,
   p_parameter_code in  number)
is
   l_to_cwms           boolean;
   l_parameter_id      varchar2(49);
   l_sub_parameter_id  varchar2(32);
begin
   l_to_cwms :=
      case upper(p_direction)
         when 'TO_CWMS'   then true
         when 'FROM_CWMS' then false
         else                  null
      end;
   if l_to_cwms is null then
      cwms_err.raise(
         'ERROR',
         'Parameter p_direction must be ''TO_CWMS'' or ''FROM_CWMS''.');
   end if;      
   if p_units is null then
      p_factor := 1;
      p_offset := 0;
   else
      begin
         if l_to_cwms then
            -------------
            -- TO CWMS --
            -------------
            select factor,
                   offset
              into p_factor,
                   p_offset
              from cwms_unit_conversion uc,
                   cwms_base_parameter bp,
                   at_parameter ap
             where uc.to_unit_code = bp.unit_code
               and bp.base_parameter_code = ap.base_parameter_code
               and ap.parameter_code = p_parameter_code
               and uc.from_unit_id = p_units;
         else
            ---------------
            -- FROM CWMS --
            ---------------
            select factor,
                   offset
              into p_factor,
                   p_offset
              from cwms_unit_conversion uc,
                   cwms_base_parameter bp,
                   at_parameter ap
             where uc.from_unit_code = bp.unit_code
               and bp.base_parameter_code = ap.base_parameter_code
               and ap.parameter_code = p_parameter_code
               and uc.to_unit_id = p_units;
         end if;
      exception
         when no_data_found then
            select base_parameter_id,
                   sub_parameter_id
              into l_parameter_id,
                   l_sub_parameter_id
              from at_parameter ap,
                   cwms_base_parameter bp
             where ap.parameter_code = p_parameter_code
               and bp.base_parameter_code = ap.base_parameter_code;
            if l_sub_parameter_id is not null then
               l_parameter_id :=
                  l_parameter_id || '-' || l_sub_parameter_id;
            end if;
            cwms_err.raise(
               'ERROR',
               'Cannot convert parameter '
               || l_parameter_id
               || case l_to_cwms
                     when true then ' to'
                     else           ' from'
                  end
               || ' specified units: '
               || p_units);
      end;
   end if;
end;

--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE get_location_level_codes
--------------------------------------------------------------------------------
procedure get_location_level_codes(
   p_location_level_code       out number,
   p_spec_level_code           out number,
   p_location_code             out number,
   p_parameter_code            out number,
   p_parameter_type_code       out number,
   p_duration_code             out number,
   p_effective_date_out        out date,
   p_attribute_parameter_code  out number,
   p_attribute_param_type_code out number,
   p_attribute_duration_code   out number,
   p_location_id               in  varchar2,
   p_parameter_id              in  varchar2,
   p_parameter_type_id         in  varchar2,
   p_duration_id               in  varchar2,
   p_spec_level_id             in  varchar2,
   p_effective_date_in         in  date,      -- UTC
   p_match_date                in  boolean,   -- earlier date OK if false
   p_attribute_value           in  number,
   p_attribute_units           in  varchar2,
   p_attribute_parameter_id    in  varchar2,
   p_attribute_param_type_id   in  varchar2,
   p_attribute_duration_id     in  varchar2,
   p_office_id                 in  varchar2)
is
   l_parts              str_tab_t;
   l_base_parameter_id  varchar2(16);
   l_sub_parameter_id   varchar2(32) := null;
   l_spec_level_code    number(10);
   l_office_id          varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
   l_office_code        number(10)   := cwms_util.get_office_code(l_office_id);
   l_factor             binary_double;
   l_offset             binary_double;
   l_attribute_value    number := null;
   l_significant_digits constant pls_integer := 10; -- for attribute comparison
   l_digits             pls_integer := l_significant_digits;
begin
   --------------
   -- location --
   --------------
   p_location_code := cwms_loc.get_location_code(l_office_code, p_location_id);
   ---------------
   -- parameter --
   ---------------
   l_parts := cwms_util.split_text(p_parameter_id, '-', 1);
   l_base_parameter_id := l_parts(1);
   if l_parts.count > 1 then
      l_sub_parameter_id := l_parts(2);
   end if;
   p_parameter_code := cwms_ts.get_parameter_code(
      l_base_parameter_id,
      l_sub_parameter_id,
      p_office_id,
      'T');
   --------------------
   -- parameter type --
   --------------------
   begin
      select parameter_type_code
        into p_parameter_type_code
        from cwms_parameter_type
       where parameter_type_id = p_parameter_type_id;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_parameter_type_id,
            'parameter type id');
   end;
   --------------
   -- duration --
   --------------
   begin
      select duration_code
        into p_duration_code
        from cwms_duration
       where duration_id = p_duration_id;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_duration_id,
            'duration id');
   end;
   ---------------------
   -- specified level --
   ---------------------
   p_spec_level_code := get_specified_level_code(
      p_spec_level_id,
      'F',
      p_office_id);
   if p_spec_level_code is null then
      create_specified_level_out(
         p_spec_level_code,
         p_spec_level_id,
         null,
         'T',
         p_office_id);
   end if;
   ---------------
   -- attribute --
   ---------------
   if p_attribute_value is null then
      ----------------------------
      -- no attribute specified --
      ----------------------------
      p_attribute_parameter_code := null;
      p_attribute_param_type_code := null;
      p_attribute_duration_code := null;
      l_attribute_value := null;
   else
      -------------------------
      -- attribute specified --
      -------------------------
      -------------------------
      -- attribute parameter --
      -------------------------
      l_parts := cwms_util.split_text(p_attribute_parameter_id, '-', 1);
      if l_parts.count > 1 then
         l_base_parameter_id := l_parts(1);
         l_sub_parameter_id := l_parts(2);
      else
         l_base_parameter_id := p_attribute_parameter_id;
         l_sub_parameter_id := null;
      end if;
      p_attribute_parameter_code := cwms_ts.get_parameter_code(
         l_base_parameter_id,
         l_sub_parameter_id,
         p_office_id,
         'T');
      ------------------------------
      -- attribute parameter type --
      ------------------------------
      begin
         select parameter_type_code
           into p_attribute_param_type_code
           from cwms_parameter_type
          where parameter_type_id = p_attribute_param_type_id;
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               p_parameter_type_id,
               'parameter type id');
      end;
      ------------------------
      -- attribute duration --
      ------------------------
      begin
         select duration_code
           into p_attribute_duration_code
           from cwms_duration
          where duration_id = p_attribute_duration_id;
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               p_duration_id,
               'duration id');
      end;
      --------------------------------
      -- attribute units conversion --
      --------------------------------
      get_units_conversion(
         l_factor,
         l_offset,
         'TO_CWMS',
         p_attribute_units,
         p_attribute_parameter_code);
      l_attribute_value := p_attribute_value * l_factor + l_offset;
      ------------------------
      -- attribute rounding --
      ------------------------
      l_digits := l_significant_digits - trunc(log(10, l_attribute_value));
   end if;
   begin
      if p_match_date then
         ------------------------
         -- match date exactly --
         ------------------------
         select distinct
                location_level_code,
                location_level_date
           into p_location_level_code,
                p_effective_date_out
           from at_location_level
          where location_code = p_location_code
            and specified_level_code = p_spec_level_code
            and parameter_code = p_parameter_code
            and parameter_type_code = p_parameter_type_code
            and duration_code = p_duration_code
            and location_level_date = p_effective_date_in
            and nvl(to_char(attribute_parameter_code), '@')
                = nvl(to_char(p_attribute_parameter_code), '@')
            and nvl(to_char(attribute_parameter_type_code), '@')
                = nvl(to_char(p_attribute_param_type_code), '@')
            and nvl(to_char(attribute_duration_code), '@')
                = nvl(to_char(p_attribute_duration_code), '@')
            and nvl(to_char(round(attribute_value, l_digits)), '@')
                = nvl(to_char(round(l_attribute_value, l_digits)), '@');
      else
         ---------------------
         -- earlier date OK --
         ---------------------
         select location_level_code,
                location_level_date
           into p_location_level_code,
                p_effective_date_out
           from at_location_level
          where location_code = p_location_code
            and specified_level_code = p_spec_level_code
            and parameter_code = p_parameter_code
            and parameter_type_code = p_parameter_type_code
            and duration_code = p_duration_code
            and location_level_date = (select max(location_level_date)
                                         from at_location_level
                                        where location_code = p_location_code
                                          and specified_level_code = p_spec_level_code
                                          and parameter_code = p_parameter_code
                                          and parameter_type_code = p_parameter_type_code
                                          and duration_code = p_duration_code
                                          and location_level_date <= p_effective_date_in
                                          and nvl(to_char(attribute_parameter_code), '@')
                                              = nvl(to_char(p_attribute_parameter_code), '@')
                                          and nvl(to_char(attribute_parameter_type_code), '@')
                                              = nvl(to_char(p_attribute_param_type_code), '@')
                                          and nvl(to_char(attribute_duration_code), '@')
                                              = nvl(to_char(p_attribute_duration_code), '@')
                                          and nvl(to_char(round(attribute_value, l_digits)), '@')
                                              = nvl(to_char(round(l_attribute_value, l_digits)), '@'))
            and nvl(to_char(attribute_parameter_code), '@')
                = nvl(to_char(p_attribute_parameter_code), '@')
            and nvl(to_char(attribute_parameter_type_code), '@')
                = nvl(to_char(p_attribute_param_type_code), '@')
            and nvl(to_char(attribute_duration_code), '@')
                = nvl(to_char(p_attribute_duration_code), '@')
            and nvl(to_char(round(attribute_value, l_digits)), '@')
                = nvl(to_char(round(l_attribute_value, l_digits)), '@');
      end if;
   exception
      when no_data_found then
         p_location_level_code := null;
   end;
end get_location_level_codes;

--------------------------------------------------------------------------------
-- PRIVATE FUNCTION get_location_level_code
--------------------------------------------------------------------------------
function get_location_level_code(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_effective_date_in       in  date,      -- UTC
   p_match_date              in  boolean,   -- earlier date OK if false
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_office_id               in  varchar2)
   return number result_cache
is
   l_location_level_code       number(10);
   l_spec_level_code           number(10);
   l_location_code             number(10);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_effective_date            date;
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
begin
   get_location_level_codes(
      l_location_level_code,
      l_spec_level_code,
      l_location_code,
      l_parameter_code,
      l_parameter_type_code,
      l_duration_code,
      l_effective_date,
      l_attribute_parameter_code,
      l_attribute_param_type_code,
      l_attribute_duration_code,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_effective_date_in,
      p_match_date,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_office_id);

   return l_location_level_code;
end get_location_level_code;

--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE get_tsid_ids
--------------------------------------------------------------------------------
procedure get_tsid_ids(
   p_location_id       out varchar2,
   p_parameter_id      out varchar2,
   p_parameter_type_id out varchar2,
   p_duration_id       out varchar2,
   p_tsid              in  varchar2)
is
   l_parts str_tab_t := cwms_util.split_text(p_tsid, '.');
begin
   p_location_id       := l_parts(1);
   p_parameter_id      := l_parts(2);
   p_parameter_type_id := l_parts(3);
   p_duration_id       := l_parts(5);
end get_tsid_ids;

--------------------------------------------------------------------------------
-- PRIVATE FUNCTION top_of_interval_on_or_before
--------------------------------------------------------------------------------
function top_of_interval_on_or_before(
   p_rec  in at_location_level%rowtype,
   p_date in date,
   p_tz   in varchar2 default null)
   return date
is
   l_ts               timestamp;
   l_intvl            timestamp;
   l_origin           timestamp;
   l_high             integer;
   l_low              integer;
   l_mid              integer;
   l_expansion_factor integer := 5;
   l_tz               varchar2(28) := nvl(p_tz, 'UTC');
begin
   --------------------------------------------
   -- get the date to interpolate for in UTC --
   --------------------------------------------
   if p_date is null then
      l_ts := systimestamp at time zone 'UTC';
   else
      l_ts := from_tz(cast(p_date as timestamp), l_tz) at time zone 'UTC';
   end if;
   -----------------------------
   -- get the interval origin --
   -----------------------------
   l_origin := from_tz(p_rec.interval_origin, 'UTC') at time zone p_tz;
   -------------------------------
   -- find the desired interval --
   -------------------------------
   if p_rec.calendar_interval is null then
      if p_date > l_origin then
         ---------------------------------------
         -- time interval, origin before time --
         ---------------------------------------
         l_low  := 0;
         l_high := 1;
         while l_origin + l_high * p_rec.time_interval < p_date loop
            l_low  := l_high;
            l_high := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.time_interval > p_date then
               l_high := l_mid;
            else
               l_low := l_mid;
            end if;
         end loop;
      else
         --------------------------------------
         -- time interval, origin after time --
         --------------------------------------
         l_low  := -1;
         l_high :=  0;
         while l_origin + l_low * p_rec.time_interval >= p_date loop
            l_high := l_low;
            l_low  := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.time_interval <= p_date then
               l_low := l_mid;
            else
               l_high := l_mid;
            end if;
         end loop;
      end if;
      l_intvl := l_origin + l_low * p_rec.time_interval;
   else
      if p_date > l_origin then
         -------------------------------------------
         -- calendar interval, origin before time --
         -------------------------------------------
         l_low  := 0;
         l_high := 1;
         while l_origin + l_high * p_rec.calendar_interval < p_date loop
            l_low  := l_high;
            l_high := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.calendar_interval > p_date then
               l_high := l_mid;
            else
               l_low := l_mid;
            end if;
         end loop;
      else
         ------------------------------------------
         -- calendar interval, origin after time --
         ------------------------------------------
         l_low  := -1;
         l_high :=  0;
         while l_origin + l_low * p_rec.calendar_interval >= p_date loop
            l_high := l_low;
            l_low  := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.calendar_interval <= p_date then
               l_low := l_mid;
            else
               l_high := l_mid;
            end if;
         end loop;
      end if;
      l_intvl := l_origin + l_low * p_rec.calendar_interval;
   end if;
   ---------------------------------------------------------------
   -- return the top of the interval in the specified time zone --
   ---------------------------------------------------------------
   return cast(l_intvl at time zone l_tz as date);
end top_of_interval_on_or_before;

--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE find_nearest
--------------------------------------------------------------------------------
procedure find_nearest(
   p_nearest_date  out date,
   p_nearest_value out number,
   p_rec           in  at_location_level%rowtype,
   p_date          in  date,
   p_direction     in  varchar2,
   p_tz            in  varchar2 default 'UTC')
is
   l_after        boolean;
   l_intvl        date;
   l_date_before  date;
   l_date_after   date;
   l_value_before number;
   l_value_after  number;
begin
   l_intvl := top_of_interval_on_or_before(p_rec, p_date, p_tz);
   if p_tz != 'UTC' then
      l_intvl := cast(from_tz(cast(l_intvl as timestamp), p_tz) at time zone 'UTC' as date);
   end if;
   l_after :=
      case upper(p_direction)
         when 'BEFORE' then false
         when 'AFTER'  then true
         else               null
      end;
   if l_after is null then
      -------------------------------------
      -- CLOSEST REGARDLESS OF DIRECTION --
      -------------------------------------
      find_nearest(
         l_date_before,
         l_value_before,
         p_rec,
         p_date,
         'BEFORE',
         p_tz);
      find_nearest(
         l_date_after,
         l_value_after,
         p_rec,
         p_date,
         'AFTER',
         p_tz);
      if (p_date - l_date_before) < (l_date_after - p_date) then
         p_nearest_date  := l_date_before;
         p_nearest_value := l_value_before;
      else
         p_nearest_date  := l_date_after;
         p_nearest_value := l_value_after;
      end if;
   else
      if l_after then
         ------------------------
         -- ON OR AFTER P_DATE --
         ------------------------
         for i in 1..2 loop
            begin
               select distinct
                      cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date),
                      value
                 into p_nearest_date,
                      p_nearest_value
                 from at_seasonal_location_level
                where location_level_code = p_rec.location_level_code
                  and cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date) =
                         (select min(cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date))
                            from at_seasonal_location_level
                           where location_level_code = p_rec.location_level_code
                                 and cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date) >= p_date);
            exception
               when no_data_found then
                  if i = 2 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot locate seasonal level date before '
                        || to_char(p_date, 'ddMonyyyy hh24mi')
                        || ' for '
                        || get_location_level_id(p_rec.location_level_code));
                  else
                     if p_rec.calendar_interval is null then
                        l_intvl := cast(cast(l_intvl as timestamp) + p_rec.time_interval as date);
                     else
                        l_intvl := cast(cast(l_intvl as timestamp) + p_rec.calendar_interval as date);
                     end if;
                  end if;
            end;
         end loop;
      else
         ------------------------
         -- ON OR BEFORE P_DATE --
         ------------------------
         for i in 1..2 loop
            begin
               select --distinct
                      cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date),
                      value
                 into p_nearest_date,
                      p_nearest_value
                 from at_seasonal_location_level
                where location_level_code = p_rec.location_level_code
                  and cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date) =
                         (select max(cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date))
                            from at_seasonal_location_level
                           where location_level_code = p_rec.location_level_code
                                 and cast(cast(l_intvl as timestamp) + calendar_offset + time_offset as date) <= p_date);
            exception
               when no_data_found then
                  if i = 2 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot locate seasonal level date after '
                        || to_char(p_date, 'ddMonyyyy hh24mi')
                        || ' for '
                        || get_location_level_id(p_rec.location_level_code));
                  else
                     if p_rec.calendar_interval is null then
                        l_intvl := cast(cast(l_intvl as timestamp) - p_rec.time_interval as date);
                     else
                        l_intvl := cast(cast(l_intvl as timestamp) - p_rec.calendar_interval as date);
                     end if;
                  end if;
            end;
         end loop;
      end if;
      if p_tz != 'UTC' then
         p_nearest_date := cast(from_tz(cast(p_nearest_date as timestamp), 'UTC') at time zone p_tz as date);
      end if;
   end if;
end;

--------------------------------------------------------------------------------
-- PROCEDURE parse_attribute_id
--------------------------------------------------------------------------------
procedure parse_attribute_id(
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_attribute_id       in  varchar2)
is
   l_parts str_tab_t := cwms_util.split_text(p_attribute_id, '.');
begin
   if p_attribute_id is null then
      p_parameter_id       := null;
      p_parameter_type_id  := null;
      p_duration_id        := null;
   else
      if l_parts.count < 3 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_attribute_id,
            'location level attribute identifier');
      end if;
      p_parameter_id       := l_parts(1);
      p_parameter_type_id  := l_parts(2);
      p_duration_id        := l_parts(3);
   end if;
end parse_attribute_id;   

--------------------------------------------------------------------------------
-- FUNCTION get_attribute_id
--------------------------------------------------------------------------------
function get_attribute_id(
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2)
   return varchar2 result_cache
is
   l_attribute_id varchar2(83);
begin
   if p_parameter_id is null 
      or p_parameter_type_id is null
      or p_duration_id is null
   then
      return null;
   end if;
   l_attribute_id := p_parameter_id
                     || '.' || p_parameter_type_id
                     || '.' || p_duration_id;
                          
   return l_attribute_id;                          
end get_attribute_id;

--------------------------------------------------------------------------------
-- PROCEDURE parse_location_level_id
--------------------------------------------------------------------------------
procedure parse_location_level_id(
   p_location_id        out varchar2,
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_specified_level_id out varchar2,
   p_location_level_id  in  varchar2)
is
   l_parts str_tab_t := cwms_util.split_text(p_location_level_id, '.');
begin
   if l_parts.count < 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_location_level_id,
         'location level identifier');
   end if;
   p_location_id        := l_parts(1);
   p_parameter_id       := l_parts(2);
   p_parameter_type_id  := l_parts(3);
   p_duration_id        := l_parts(4);
   p_specified_level_id := l_parts(5);
end parse_location_level_id;   

--------------------------------------------------------------------------------
-- FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_level_code in number)
   return varchar2 result_cache
is
   l_location_level_id varchar2(422);
   l_office_id         varchar2(16);
   l_location_id       varchar2(49);
   l_parameter_id      varchar2(49);
   l_parameter_type_id varchar2(16);
   l_duration_id       varchar2(16);
   l_spec_level_id     varchar2(256);
   l_effective_date    varchar2(14);
begin
   select co.office_id,
          vl.location_id,
          vp.parameter_id,
          cpt.parameter_type_id,
          cd.duration_id,
          asl.specified_level_id,
          to_char(a_ll.location_level_date, 'ddMonyyyy hh24mi')
     into l_office_id,
          l_location_id,
          l_parameter_id,
          l_parameter_type_id,
          l_duration_id,
          l_spec_level_id,
          l_effective_date
     from at_location_level a_ll,
          cwms_office co,
          av_loc vl,
          av_parameter vp,
          cwms_parameter_type cpt,
          cwms_duration cd,
          at_specified_level asl
    where a_ll.location_level_code = p_location_level_code
      and vl.location_code = a_ll.location_code
      and vl.unit_system = 'EN'
      and vp.parameter_code = a_ll.parameter_code
      and cpt.parameter_type_code = a_ll.parameter_type_code
      and cd.duration_code = a_ll.duration_code
      and asl.specified_level_code = a_ll.specified_level_code
      and co.office_code = vp.db_office_code;
      
   l_location_level_id :=
      l_office_id
      || '/' || l_location_id
      || '.' || l_parameter_id
      || '.' || l_parameter_type_id
      || '.' || l_duration_id
      || '.' || l_spec_level_id
      || '@' || l_effective_date;
      
   return l_location_level_id;

end get_location_level_id;

--------------------------------------------------------------------------------
-- FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2)
   return varchar2 result_cache
is
   l_location_level_id varchar2(390);
begin
   l_location_level_id := p_location_id
                          || '.' || p_parameter_id
                          || '.' || p_parameter_type_id
                          || '.' || p_duration_id
                          || '.' || p_specified_level_id;
                          
   return l_location_level_id;                          
end get_location_level_id;   
   
--------------------------------------------------------------------------------
-- PROCEDURE parse_loc_lvl_indicator_id
--------------------------------------------------------------------------------
procedure parse_loc_lvl_indicator_id(
   p_location_id          out varchar2,
   p_parameter_id         out varchar2,
   p_parameter_type_id    out varchar2,
   p_duration_id          out varchar2,
   p_specified_level_id   out varchar2,
   p_level_indicator_id   out varchar2,
   p_loc_lvl_indicator_id in  varchar2)
is
   l_parts str_tab_t := cwms_util.split_text(p_loc_lvl_indicator_id, '.');
begin
   if l_parts.count < 6 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_loc_lvl_indicator_id,
         'location level indicator identifier');
   end if;
   p_location_id        := l_parts(1);
   p_parameter_id       := l_parts(2);
   p_parameter_type_id  := l_parts(3);
   p_duration_id        := l_parts(4);
   p_specified_level_id := l_parts(5);
   p_level_indicator_id := l_parts(6);
end parse_loc_lvl_indicator_id;   
   
--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indicator_id
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2,
   p_level_indicator_id in varchar2)
   return varchar2 result_cache
is
   l_location_level_id varchar2(374);
begin
   l_location_level_id := p_location_id
                          || '.' || p_parameter_id
                          || '.' || p_parameter_type_id
                          || '.' || p_duration_id
                          || '.' || p_specified_level_id
                          || '.' || p_level_indicator_id;
   return l_location_level_id;                          
end get_loc_lvl_indicator_id;   
   
--------------------------------------------------------------------------------
-- PROCEDURE create_specified_level_out
--------------------------------------------------------------------------------
procedure create_specified_level_out(
   p_level_code     out number,
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null)
is   
   l_office_code      number;
   l_cwms_office_code number;
   l_fail_if_exists   boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_level_code       number(10) := null;
   l_rec              at_specified_level%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   validate_specified_level_input(l_office_code, p_office_id, p_level_id);
   select office_code
     into l_cwms_office_code
     from cwms_office
    where office_id = 'CWMS';
         ------------------------------------------------------------
         -- see if the level id already exists for the CWMS office --
         ------------------------------------------------------------
   begin
      select *
        into l_rec
        from at_specified_level
       where office_code = l_cwms_office_code
         and upper(specified_level_id) = upper(p_level_id);
      if l_fail_if_exists then
         --------------------
         -- raise an error --
         --------------------
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Specified level',
            p_level_id);
      else
         p_level_code := l_rec.specified_level_code;
      end if;
   exception
      when no_data_found then
         -----------------------------------------------------------------
         -- see if the level id already exists for the specified office --
         -----------------------------------------------------------------
         begin
            select *
              into l_rec
              from at_specified_level
             where office_code = l_office_code
               and upper(specified_level_id) = upper(p_level_id);
            if l_fail_if_exists then
               --------------------
               -- raise an error --
               --------------------
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'Specified level',
                  p_level_id);
            else
               --------------------------------
               -- update the existing record --
               --------------------------------
               p_level_code := l_rec.specified_level_code;
               update at_specified_level
                  set specified_level_id = p_level_id, -- might change case
                      description = p_description
                where specified_level_code = p_level_code;
            end if;
         exception
            when no_data_found then
               ---------------------------
               -- create the new record --
               ---------------------------
               p_level_code := cwms_seq.nextval;
               insert
                 into at_specified_level
               values (p_level_code, l_office_code, p_level_id, p_description);
         end;
   end;
    
end create_specified_level_out;   
   
--------------------------------------------------------------------------------
-- PROCEDURE store_specified_level
--------------------------------------------------------------------------------
procedure store_specified_level(
   p_level_id       in varchar2,
   p_description    in varchar2,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null)
is
   l_specified_level_code number(10);
begin
   create_specified_level_out(
      l_specified_level_code,
      p_level_id,
      p_description,
      p_fail_if_exists,
      p_office_id);
end store_specified_level;   
   
--------------------------------------------------------------------------------
-- PROCEDURE store_specified_level
--------------------------------------------------------------------------------
procedure store_specified_level(
   p_obj            in specified_level_t,
   p_fail_if_exists in varchar2 default 'T')
is
begin
   store_specified_level(
      p_obj.level_id,
      p_obj.description,
      p_fail_if_exists,   
      p_obj.office_id);
end store_specified_level;   

--------------------------------------------------------------------------------
-- PROCEDURE get_specified_level_code
--------------------------------------------------------------------------------
procedure get_specified_level_code(
   p_level_code        out number,
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
is
   l_office_code       number(10);
   l_cwms_office_code  number(10);
   l_fail_if_not_found boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   validate_specified_level_input(l_office_code, p_office_id, p_level_id);
   l_fail_if_not_found := cwms_util.return_true_or_false(p_fail_if_not_found);
   select office_code
     into l_cwms_office_code
     from cwms_office
    where office_id = 'CWMS';
   -----------------------
   -- retrieve the code --
   -----------------------
   begin
      select specified_level_code
        into p_level_code
        from at_specified_level
       where office_code = l_cwms_office_code
         and upper(specified_level_id) = upper(p_level_id);
   exception
      when no_data_found then
         begin
            select specified_level_code
              into p_level_code
              from at_specified_level
             where office_code = l_office_code
               and upper(specified_level_id) = upper(p_level_id);
         exception
            when no_data_found then
               if l_fail_if_not_found then
                  cwms_err.raise(
                     'ITEM_DOES_NOT_EXIST',
                     'Specified level',
                     p_level_id);
               else
                  p_level_code := null;
               end if;
         end;
   end;
end get_specified_level_code;

--------------------------------------------------------------------------------
-- FUNCTION get_specified_level_code
--------------------------------------------------------------------------------
function get_specified_level_code(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
   return number result_cache
is
   l_level_code number(10);
begin
   get_specified_level_code(
      l_level_code,
      p_level_id,
      p_fail_if_not_found,
      p_office_id);
      
   return l_level_code;
end get_specified_level_code;
   
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_specified_level
--------------------------------------------------------------------------------
procedure retrieve_specified_level(
   p_description    out varchar2,
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null)
is
begin
   select description
     into p_description
     from at_specified_level
    where specified_level_code = 
      get_specified_level_code(
         p_level_id,
         'T',
         p_office_id);
end retrieve_specified_level;
   
--------------------------------------------------------------------------------
-- FUNCTION retrieve_specified_level
--------------------------------------------------------------------------------
function retrieve_specified_level(
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null)
   return specified_level_t
is
begin
   return specified_level_t(get_specified_level_code(
         p_level_id,
         'T',
         p_office_id));
end retrieve_specified_level;

--------------------------------------------------------------------------------
-- PROCEDURE delete_specified_level
--------------------------------------------------------------------------------
procedure delete_specified_level(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
is
begin
   --------------------------------
   -- delete the existing record --
   --------------------------------
   delete from at_specified_level
    where specified_level_code = get_specified_level_code(
             p_level_id, 
             p_fail_if_not_found, 
             p_office_id);
end delete_specified_level;   

--------------------------------------------------------------------------------
-- PROCEDURE catalog_specified_levels
--
-- The cursor returned by this routine contains two fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure catalog_specified_levels(
   p_level_cursor   out sys_refcursor,
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
is
   l_level_id_mask  varchar2(256);
   l_office_id_mask varchar2(16);
begin
   ----------------------------------------------
   -- normalize the wildcards (handle * and ?) --
   ----------------------------------------------
   l_level_id_mask  := cwms_util.normalize_wildcards(p_level_id_mask,  true);
   l_office_id_mask := nvl(upper(p_office_id_mask), cwms_util.user_office_id);
   l_office_id_mask := cwms_util.normalize_wildcards(l_office_id_mask, true);
   -----------------------------
   -- get the matching levels --
   -----------------------------
   open p_level_cursor
    for select o.office_id,
               l.specified_level_id
          from cwms_office o,
               at_specified_level l
         where o.office_id like upper(l_office_id_mask)
           and l.office_code = o.office_code
           and l.specified_level_id like upper(l_level_id_mask);
end catalog_specified_levels;

--------------------------------------------------------------------------------
-- FUNCTION catalog_specified_levels
--
-- The cursor returned by this routine contains two fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
function catalog_specified_levels(
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor
is
   l_level_cursor sys_refcursor;
begin
   catalog_specified_levels(
      l_level_cursor,
      p_level_id_mask,
      p_office_id_mask);
      
   return l_level_cursor;
end catalog_specified_levels;

--------------------------------------------------------------------------------
-- PROCEDURE create_location_level
--------------------------------------------------------------------------------
procedure create_location_level(
   p_location_level_code     out number,
   p_fail_if_exists          in  varchar2 default 'T',
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_office_id               in  varchar2 default null)
is
   l_location_level_code       number(10) := null;
   l_office_code               number;
   l_fail_if_exists            boolean;
   l_spec_level_code           number(10);
   l_loc_level_code            number(10);
   l_interval_origin           date;
   l_location_code             number(10);
   l_location_tz_code          number(10);
   l_parts                     str_tab_t;
   l_base_parameter_id         varchar2(16);
   l_sub_parameter_id          varchar2(32);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_level_factor              binary_double;
   l_level_offset              binary_double;
   l_attr_factor               binary_double;
   l_attr_offset               binary_double;
   l_attribute_value           number;
   l_effective_date            date;
   l_timezone_id               varchar2(28);
   l_effective_date_out        date;
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
   l_calendar_interval         interval year to month;
   l_time_interval             interval day to second;
begin
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   if p_interval_months is not null then
      l_calendar_interval := cwms_util.months_to_yminterval(p_interval_months);
   end if;
   if p_interval_minutes is not null then
      l_time_interval := cwms_util.minutes_to_dsinterval(p_interval_minutes);
   end if;
   -------------------
   -- sanity checks --
   -------------------
   validate_specified_level_input(l_office_code, p_office_id, p_spec_level_id);
   l_location_code := cwms_loc.get_location_code(l_office_code, p_location_id);
   select time_zone_code
     into l_location_tz_code
     from at_physical_location
    where location_code = l_location_code;
   if l_location_tz_code is null then
      cwms_err.raise(
         'ERROR',
         'Location '''
         ||p_location_id
         ||''' must be assigned a time zone before calling this routine.');
   end if;    
   if p_attribute_value is not null and p_attribute_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Must specify attribute parameter id with attribute value '
         || 'in CREATE_LOCATION_LEVEL');
   end if;
   if p_level_value is null and p_seasonal_values is null then
      cwms_err.raise(
         'ERROR',
         'Must specify either seasonal values or '
         || 'non-seasonal value to CREATE_LOCATION_LEVEL');
   elsif p_level_value is not null and p_seasonal_values is not null then
      cwms_err.raise(
         'ERROR',
         'Cannot specify both seasonal values and '
         || 'non-seasonal value to CREATE_LOCATION_LEVEL');
   elsif p_seasonal_values is not null then
      if l_calendar_interval is null and l_time_interval is null then
         cwms_err.raise(
            'ERROR',
            'seasonal values require either months interval or minutes interval '
            || 'in CREATE_LOCATION_LEVEL');
      elsif l_calendar_interval is not null and l_time_interval is not null then
         cwms_err.raise(
            'ERROR',
            'seasonal values cannot have months interval and minutes interval '
            || 'in CREATE_LOCATION_LEVEL');
      end if;
   end if;
   -------------------------------------------------------
   -- default the time zone to the location's time zone --
   -------------------------------------------------------
   if p_timezone_id is null then
      select time_zone_name
        into l_timezone_id
        from cwms_time_zone
       where time_zone_code = l_location_tz_code;
   else
      l_timezone_id := p_timezone_id;
   end if;
   ---------------------------------
   -- get the codes for input ids --
   ---------------------------------
   if p_effective_date is null then
      l_effective_date := cast(
         from_tz(to_timestamp('01JAN1900 0000', 'ddmonyyyy hh24mi'), l_timezone_id)
         at time zone 'UTC' as date);
   else
      l_effective_date := cast(
         from_tz(cast(p_effective_date as timestamp), l_timezone_id)
         at time zone 'UTC' as date);
   end if;
   get_location_level_codes(
      l_location_level_code,
      l_spec_level_code,
      l_location_code,
      l_parameter_code,
      l_parameter_type_code,
      l_duration_code,
      l_effective_date_out,
      l_attribute_parameter_code,
      l_attribute_param_type_code,
      l_attribute_duration_code,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      l_effective_date,
      true,             -- match date exactly
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_office_id);
   -------------------------------
   -- get the units conversions --
   -------------------------------
   get_units_conversion(
      l_level_factor,
      l_level_offset,
      'TO_CWMS',
      p_level_units,
      l_parameter_code);
   if p_attribute_value is null then
      l_attribute_value := null;
   else
      get_units_conversion(
         l_attr_factor,
         l_attr_offset,
         'TO_CWMS',
         p_attribute_units,
         l_attribute_parameter_code);
      l_attribute_value := p_attribute_value * l_attr_factor + l_attr_offset;
   end if;
   --------------------------------------
   -- determine whether already exists --
   --------------------------------------
   if l_location_level_code is null then
      ------------------------------------
      -- new location level - insert it --
      ------------------------------------
      l_location_level_code := cwms_seq.nextval;
      if p_seasonal_values is null then
         --------------------
         -- constant value --
         --------------------
         insert
           into at_location_level
         values(l_location_level_code,
                l_location_code,
                l_spec_level_code,
                l_parameter_code,
                l_parameter_type_code,
                l_duration_code,
                l_effective_date,
                p_level_value * l_level_factor + l_level_offset,
                p_level_comment,
                l_attribute_value,
                l_attribute_parameter_code,
                l_attribute_param_type_code,
                l_attribute_duration_code,
                p_attribute_comment,
                null, null, null, null);
      else
         ---------------------
         -- seasonal values --
         ---------------------
         ----------------------------------------------------
         -- set the interval origin for the seaonal values --
         -- (always stored in UTC in the database)         --
         ----------------------------------------------------
         if p_interval_origin is null then
            l_interval_origin := to_date('01JAN2000 0000', 'ddmonyyyy hh24mi');
         else
            l_interval_origin := cast(
               from_tz(cast(p_interval_origin as timestamp), l_timezone_id)
               at time zone 'UTC' as date);
         end if;
         if l_calendar_interval is null then
            -------------------
            -- time interval --
            -------------------
            insert
              into at_location_level
            values(l_location_level_code,
                   l_location_code,
                   l_spec_level_code,
                   l_parameter_code,
                   l_parameter_type_code,
                   l_duration_code,
                   l_effective_date,
                   null,
                   p_level_comment,
                   l_attribute_value,
                   l_attribute_parameter_code,
                   l_attribute_param_type_code,
                   l_attribute_duration_code,
                   p_attribute_comment,
                   l_interval_origin,
                   null,
                   l_time_interval,
                   p_interpolate);
         else
            -----------------------
            -- calendar interval --
            -----------------------
            insert
              into at_location_level
            values(l_location_level_code,
                   l_location_code,
                   l_spec_level_code,
                   l_parameter_code,
                   l_parameter_type_code,
                   l_duration_code,
                   l_effective_date,
                   null,
                   p_level_comment,
                   l_attribute_value,
                   l_attribute_parameter_code,
                   l_attribute_param_type_code,
                   l_attribute_duration_code,
                   p_attribute_comment,
                   l_interval_origin,
                   l_calendar_interval,
                   null,
                   p_interpolate);
         end if;
         for i in 1..p_seasonal_values.count loop
            insert
              into at_seasonal_location_level
            values(l_location_level_code,
                   cwms_util.months_to_yminterval(p_seasonal_values(i).offset_months),
                   cwms_util.minutes_to_dsinterval(p_seasonal_values(i).offset_minutes),
                   p_seasonal_values(i).value * l_level_factor + l_level_offset);
         end loop;
      end if;
   else
      -----------------------------
      -- existing location level --
      -----------------------------
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Location level ',
            get_location_level_id(l_location_level_code));
      end if;
      -------------------------------
      -- update the existing level --
      -------------------------------
      if p_seasonal_values is null then
         --------------------
         -- constant value --
         --------------------
         update at_location_level
            set location_level_value = p_level_value * l_level_factor + l_level_offset,
                location_level_comment = p_level_comment,
                location_level_date = l_effective_date,
                attribute_value = l_attribute_value,
                attribute_parameter_code = l_attribute_parameter_code,
                attribute_comment = p_attribute_comment,
                interval_origin = null,
                calendar_interval = null,
                time_interval = null,
                interpolate = null
          where location_level_code = l_location_level_code;
         delete
           from at_seasonal_location_level
          where location_level_code = l_location_level_code;
      else
         ---------------------
         -- seasonal values --
         ---------------------
         ----------------------------------------------------
         -- set the interval origin for the seaonal values --
         -- (always stored in UTC in the database)         --
         ----------------------------------------------------
         if p_interval_origin is null then
            l_interval_origin := to_date('01JAN2000 0000', 'ddmonyyyy hh24mi');
         else
            l_interval_origin := cast(
               from_tz(cast(p_interval_origin as timestamp), l_timezone_id)
               at time zone 'UTC' as date);
         end if;
         update at_location_level
            set location_level_value = p_level_value * l_level_factor + l_level_offset,
                location_level_comment = p_level_comment,
                location_level_date = l_effective_date,
                attribute_value = l_attribute_value,
                attribute_parameter_code = l_attribute_parameter_code,
                attribute_comment = p_attribute_comment,
                interval_origin = l_interval_origin,
                calendar_interval = l_calendar_interval,
                time_interval = l_time_interval,
                interpolate = p_interpolate
          where location_level_code = l_location_level_code;
         delete
           from at_seasonal_location_level
          where location_level_code = l_location_level_code;
         for i in 1..p_seasonal_values.count loop
            insert
              into at_seasonal_location_level
            values(l_location_level_code,
                   cwms_util.months_to_yminterval(p_seasonal_values(i).offset_months),
                   cwms_util.minutes_to_dsinterval(p_seasonal_values(i).offset_minutes),
                   p_seasonal_values(i).value * l_level_factor + l_level_offset);
         end loop;
      end if;
   end if;
end create_location_level;

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level
--
-- Creates or updates a Location Level in the database
--
-- Only one of p_interval_months and p_interval_minutes can be specified for
-- seasonal levels
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null)
is
   l_location_level_code     number(10);
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);

   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);

   create_location_level(
      l_location_level_code,
      p_fail_if_exists,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      p_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_comment,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_seasonal_values,
      p_office_id);               
      
end store_location_level;   

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level
--
-- Creates or updates a Location Level in the database
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level in  location_level_t)
is
   l_location_level location_level_t := p_location_level;
begin
   l_location_level.store;
end store_location_level;   

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level2
--
-- Creates or updates a Location Level in the database using only text and 
-- numeric parameters
--
-- Only one of p_interval_months and p_interval_minutes can be specified for
-- seasonal levels
--
-- p_effective_date should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_interval_origin should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_seasonal_values should be specified as text records separated by the RS
-- character (chr(30)) with each record containing offset_months, offset_minutes
-- and offset_value, each separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure store_location_level2(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  varchar2 default null, -- 'yyyy/mm/dd hh:mm:ss'
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null, -- 'yyyy/mm/dd hh:mm:ss'
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null, -- recordset of (offset_months, offset_minutes, offset_values) records
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null)
is
   l_seasonal_values seasonal_value_tab_t := null;
   l_recordset       str_tab_tab_t;
   l_offset_months   integer;
   l_offset_minutes  integer;
   l_offset_value    number;
   l_effective_date  date;
   l_interval_origin date;
begin
   ----------------------------
   -- parse the date strings --
   ----------------------------
   if p_effective_date is not null then
      l_effective_date := to_date(p_effective_date, 'YYYY/MM/DD HH24:MI:SS');
   end if;
   if p_interval_origin is not null then
      l_interval_origin := to_date(p_interval_origin, 'YYYY/MM/DD HH24:MI:SS');
   end if;
   -------------------------------------------
   -- parse the data seasonal values string --
   -------------------------------------------
   if p_seasonal_values is not null then
      l_seasonal_values := new seasonal_value_tab_t();
      l_recordset := cwms_util.parse_string_recordset(p_seasonal_values);
      for i in 1..l_recordset.count loop
         begin
            l_offset_months := to_number(l_recordset(i)(1));
            if l_offset_months != trunc(l_offset_months) then
               raise_application_error(-20999, 'Invalid');
            end if;
         exception 
            when others then
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_recordset(i)(1),
                  'months offset (integer)');
         end;
         begin
            l_offset_minutes := to_number(l_recordset(i)(2));
            if l_offset_minutes != trunc(l_offset_minutes) then
               raise_application_error(-20999, 'Invalid');
            end if;
         exception 
            when others then
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_recordset(i)(2),
                  'minutes offset (integer)');
         end;
         begin
            l_offset_value := to_number(l_recordset(i)(3));
         exception 
            when others then
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_recordset(i)(3),
                  'seasonal value (number)');
         end;
         l_seasonal_values.extend;
         l_seasonal_values(i) := new seasonal_value_t(
            l_offset_months, 
            l_offset_minutes, 
            l_offset_value);
      end loop;
   end if;
   -----------------------------
   -- call the base procedure --
   -----------------------------
   store_location_level(
      p_location_level_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      l_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      p_attribute_id,
      p_attribute_comment,
      l_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      l_seasonal_values,
      p_fail_if_exists,
      p_office_id);
end store_location_level2;   

--------------------------------------------------------------------------------
-- PROCEDURE update_location_level
--------------------------------------------------------------------------------
procedure update_location_level(
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_attribute_comment       in  varchar2,
   p_interval_origin         in  date default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_office_id               in  varchar2 default null)
is
   l_location_level_code number(10);
   l_date                date;
begin
   l_date := cast(
      from_tz(cast(p_effective_date as timestamp), p_timezone_id)
      at time zone 'UTC' as date);
   -----------------------------
   -- verify the level exists --
   -----------------------------
   l_location_level_code := get_location_level_code(
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      l_date,
      true,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_parameter_id,
      p_office_id);
      
   if l_location_level_code is null then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level',
         nvl(p_office_id, cwms_util.user_office_id)
         || '/' || p_location_id
         || '.' || p_parameter_id
         || '.' || p_parameter_type_id
         || '.' || p_duration_id
         || '.' || p_spec_level_id
         || '@' || p_effective_date);
   end if;
   ----------------------------------------
   -- use the create procedure to update --
   ----------------------------------------
   create_location_level(
      l_location_level_code,
      'F',
      p_spec_level_id,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      p_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_attribute_comment,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_seasonal_values,
      p_office_id);
end update_location_level;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level
--
-- Retrieves the Location Level in effect at a specified time
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
procedure retrieve_location_level(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out seasonal_value_tab_t,
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_rec                       at_location_level%rowtype;
   l_spec_level_code           number(10);
   l_location_level_code       number(10);
   l_interval_origin           date;
   l_location_code             number(10);
   l_parts                     str_tab_t;
   l_base_parameter_id         varchar2(16);
   l_sub_parameter_id          varchar2(32);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_factor                    binary_double;
   l_offset                    binary_double;
   l_date                      date;
   l_match_date                boolean := cwms_util.return_true_or_false(p_match_date);
   l_office_code               number := cwms_util.get_office_code(p_office_id);
   l_office_id                 varchar2(16);
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
begin
   ----------------------------
   -- get the specified date --
   ----------------------------
   if p_date is null then
      l_date := cast(systimestamp at time zone 'UTC' as date);
   else
      l_date := cast(
         from_tz(cast(p_date as timestamp), p_timezone_id)
         at time zone 'UTC' as date);
   end if;
   ---------------------------------
   -- get the codes for input ids --
   ---------------------------------
   get_location_level_codes(
      l_location_level_code,
      l_spec_level_code,
      l_location_code,
      l_parameter_code,
      l_parameter_type_code,
      l_duration_code,
      l_date,
      l_attribute_parameter_code,
      l_attribute_param_type_code,
      l_attribute_duration_code,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      l_date,
      l_match_date,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_office_id);
      
   if l_location_level_code is null then
      select office_id
        into l_office_id
        from cwms_office
       where office_code = l_office_code;
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level',
         l_office_id
         || '/' || p_location_id
         || '.' || p_parameter_id
         || '.' || p_parameter_type_id
         || '.' || p_duration_id
         || '.' || p_spec_level_id
         || '@' || l_date);
   end if;
   ------------------------------
   -- get the units conversion --
   ------------------------------
   get_units_conversion(
      l_factor,
      l_offset,
      'FROM_CWMS',
      p_level_units,
      l_parameter_code);
   --------------------------------------
   -- get the at_location_level record --
   --------------------------------------
   select *
     into l_rec
     from at_location_level
    where location_level_code = l_location_level_code;
   p_level_comment        := l_rec.location_level_comment;
   p_effective_date       := l_rec.location_level_date;
   p_interval_months      := cwms_util.yminterval_to_months(l_rec.calendar_interval);
   p_interval_minutes     := cwms_util.dsinterval_to_minutes(l_rec.time_interval);
   p_interval_origin      := l_rec.interval_origin;
   p_interpolate          := l_rec.interpolate;
   if l_rec.location_level_value is null then
      ---------------------
      -- seasonal values --
      ---------------------
      p_level_value     := null;
      p_seasonal_values := new seasonal_value_tab_t();
      for rec in (select *
                    from at_seasonal_location_level
                   where location_level_code = l_rec.location_level_code
                order by l_rec.interval_origin + calendar_offset + time_offset)
      loop
         p_seasonal_values.extend;
         p_seasonal_values(p_seasonal_values.count) :=
            new seasonal_value_t(
               cwms_util.yminterval_to_months(rec.calendar_offset),
               cwms_util.dsinterval_to_minutes(rec.time_offset),
               rec.value * l_factor + l_offset);
      end loop;
   else
      --------------------
      -- constant value --
      --------------------
      p_seasonal_values := null;
      p_level_value := l_rec.location_level_value * l_factor + l_offset;
   end if;
end retrieve_location_level;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
procedure retrieve_location_level(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out seasonal_value_tab_t,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_seasonal_values,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_units,
      p_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_match_date,
      p_office_id);
end retrieve_location_level;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level2
--
-- Retrieves the Location Level in effect at a specified time using only text
-- and numeric parameters
--
-- p_date should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--
-- p_effective_date is returned as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_interval_origin is returned as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_seasonal_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing offset_months, offset_minutes
-- and offset_value, each separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure retrieve_location_level2(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out varchar2,
   p_interval_origin         out varchar2,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_effective_date  date;
   l_interval_origin date;
   l_date            date := to_date(p_date, 'yyyy/mm/dd hh24:mi:ss');
   l_seasonal_values seasonal_value_tab_t;
   l_recordset_txt   varchar2(32767);
   l_rs              varchar2(1) := chr(30);
   l_gs              varchar2(1) := chr(29);
begin
   retrieve_location_level(
      p_level_value,
      p_level_comment,
      l_effective_date,
      l_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      l_seasonal_values,
      p_location_level_id,
      p_level_units,
      l_date,
      p_timezone_id,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_match_date,
      p_office_id);
      
   p_effective_date  := to_char(l_effective_date, 'yyyy/mm/dd hh24:mi:ss');      
   p_interval_origin := to_char(l_interval_origin, 'yyyy/mm/dd hh24:mi:ss');
   for i in 1..l_seasonal_values.count loop
      l_recordset_txt := l_recordset_txt
         || l_rs
         || to_char(l_seasonal_values(i).offset_months)
         || l_gs
         || to_char(l_seasonal_values(i).offset_minutes)
         || l_gs
         || to_char(l_seasonal_values(i).value);
   end loop;
   p_seasonal_values := substr(l_recordset_txt, 2);      
      
end retrieve_location_level2;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level
--
-- Returns the Location Level in effect at a specified time
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
function retrieve_location_level(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units          in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
   return location_level_t
is
   l_location_id                 varchar2(49);
   l_parameter_id                varchar2(49);
   l_parameter_type_id           varchar2(16);
   l_duration_id                 varchar2(16);
   l_specified_level_id          varchar2(256);
   l_attribute_parameter_id      varchar2(49);
   l_attribute_parameter_type_id varchar2(16);
   l_attribute_duration_id       varchar2(16);
   l_location_level_code         number;
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);

   parse_attribute_id(      
      l_attribute_parameter_id,
      l_attribute_parameter_type_id,
      l_attribute_duration_id,
      p_attribute_id);
      
   l_location_level_code := get_location_level_code(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_date,
      cwms_util.return_true_or_false(p_match_date),
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_parameter_type_id,
      l_attribute_duration_id,
      p_office_id);
      
         
   return case l_location_level_code is null
      when true  then null
      when false then location_level_t(zlocation_level_t(l_location_level_code))
   end;      
            
end retrieve_location_level;   
   
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--
-- Retreives a time series of Location Level values for a specified time window
--
-- The returned QUALITY_CODE values of the time series will be zero.
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   type encoded_date_t is table of boolean index by binary_integer;
   l_encoded_dates             encoded_date_t;
   l_start_time                date;
   l_end_time                  date;
   l_rec                       at_location_level%rowtype;
   l_spec_level_code           number(10);
   l_location_level_code       number(10);
   l_interval_origin           date;
   l_location_code             number(10);
   l_parts                     str_tab_t;
   l_base_parameter_id         varchar2(16);
   l_sub_parameter_id          varchar2(32);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_effective_date            date;
   l_factor                    binary_double;
   l_offset                    binary_double;
   l_office_code               number := cwms_util.get_office_code(p_office_id);
   l_office_id                 varchar2(16);
   l_date                      date;
   l_date_prev                 date;
   l_date_next                 date;
   l_value                     number;
   l_value_prev                number;
   l_value_next                number;
   l_attribute_value           number := null;
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
   l_attribute_factor          binary_double := null;
   l_attribute_offset          binary_double := null;
   l_significant_digits        constant pls_integer := 10; -- for attribute comparison
   l_digits                    pls_integer := l_significant_digits;
   --------------------
   -- local routines --
   --------------------
   function encode_date(p_date in date) return binary_integer result_cache
   is
      l_origin constant date := to_date('01Jan2000 0000', 'ddMonyyyy hh24mi');
   begin
      return (p_date - l_origin) * 1440;
   end;
   
   function decode_date(p_int in binary_integer) return date result_cache
   is
      l_origin constant date := to_date('01Jan2000 0000', 'ddMonyyyy hh24mi');
   begin
      return l_origin + p_int / 1440;
   end;
begin
   -----------------------------------------------------------
   -- get the start and end times of the time window in UTC --
   -----------------------------------------------------------
   if p_start_time is null then
      l_start_time := cast(systimestamp at time zone 'UTC' as date);
   else 
      l_start_time := cast(
               from_tz(cast(p_start_time as timestamp), p_timezone_id)
               at time zone 'UTC' as date);
   end if;
   if p_end_time is null then
      l_end_time := null;
   else
      l_end_time := cast(
               from_tz(cast(p_end_time as timestamp), p_timezone_id)
               at time zone 'UTC' as date);
   end if;
   -----------------------------------------------------------
   -- get the codes and effective dates for the time window --
   -----------------------------------------------------------
   if p_end_time is not null then
      get_location_level_codes(
         l_location_level_code,
         l_spec_level_code,
         l_location_code,
         l_parameter_code,
         l_parameter_type_code,
         l_duration_code,
         l_effective_date,
         l_attribute_parameter_code,
         l_attribute_param_type_code,
         l_attribute_duration_code,
         p_location_id,
         p_parameter_id,
         p_parameter_type_id,
         p_duration_id,
         p_spec_level_id,
         l_end_time,
         false,
         p_attribute_value,
         p_attribute_units,
         p_attribute_parameter_id,
         p_attribute_param_type_id,
         p_attribute_duration_id,
         p_office_id);
      if l_location_level_code is null then
         select office_id
           into l_office_id
           from cwms_office
          where office_code = l_office_code;
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location level',
            l_office_id
            || '/' || p_location_id
            || '.' || p_parameter_id
            || '.' || p_parameter_type_id
            || '.' || p_duration_id
            || '.' || p_spec_level_id
            || '@' || to_char(l_start_time, 'dd-Mon-yyyy hh24:mi'));
      end if;
      l_encoded_dates(encode_date(l_effective_date)) := true;
      while l_effective_date > l_start_time loop
         get_location_level_codes(
            l_location_level_code,
            l_spec_level_code,
            l_location_code,
            l_parameter_code,
            l_parameter_type_code,
            l_duration_code,
            l_effective_date,
            l_attribute_parameter_code,
            l_attribute_param_type_code,
            l_attribute_duration_code,
            p_location_id,
            p_parameter_id,
            p_parameter_type_id,
            p_duration_id,
            p_spec_level_id,
            l_effective_date - 1 / 1440,
            false,
            p_attribute_value,
            p_attribute_units,
            p_attribute_parameter_id,
            p_attribute_param_type_id,
            p_attribute_duration_id,
            p_office_id);
         if l_location_level_code is null then
            select office_id
              into l_office_id
              from cwms_office
             where office_code = l_office_code;
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Location level',
               l_office_id
               || '/' || p_location_id
               || '.' || p_parameter_id
               || '.' || p_parameter_type_id
               || '.' || p_duration_id
               || '.' || p_spec_level_id
               || '@' || to_char(l_end_time, 'dd-Mon-yyyy hh24:mi'));
         end if;
         l_encoded_dates(encode_date(l_effective_date)) := true;
      end loop;
   else
      -----------------------------------------
      -- no time window, just the start time --
      -----------------------------------------
      get_location_level_codes(
         l_location_level_code,
         l_spec_level_code,
         l_location_code,
         l_parameter_code,
         l_parameter_type_code,
         l_duration_code,
         l_effective_date,
         l_attribute_parameter_code,
         l_attribute_param_type_code,
         l_attribute_duration_code,
         p_location_id,
         p_parameter_id,
         p_parameter_type_id,
         p_duration_id,
         p_spec_level_id,
         l_start_time,
         false,
         p_attribute_value,
         p_attribute_units,
         p_attribute_parameter_id,
         p_attribute_param_type_id,
         p_attribute_duration_id,
         p_office_id);
      if l_location_level_code is null then
         select office_id
           into l_office_id
           from cwms_office
          where office_code = l_office_code;
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location level',
            l_office_id
            || '/' || p_location_id
            || '.' || p_parameter_id
            || '.' || p_parameter_type_id
            || '.' || p_duration_id
            || '.' || p_spec_level_id
            || '@' || to_char(l_start_time, 'dd-Mon-yyyy hh24:mi'));
      end if;
      l_encoded_dates(encode_date(l_effective_date)) := true;
   end if;
   p_level_values := new ztsv_array();
   if l_encoded_dates.count > 1 then
      -------------------------------------------
      -- working with multiple effective dates --
      -------------------------------------------
      declare
         l_level_values       ztsv_array;
         l_encoded_start_time integer := l_encoded_dates.first;
         l_encoded_end_time   integer := l_encoded_dates.next(l_encoded_start_time);
         l_encoded_last_time  integer := l_encoded_dates.last;
      begin
         while l_encoded_end_time is not null loop
            l_encoded_start_time := l_encoded_end_time;
            l_encoded_end_time := l_encoded_dates.next(l_encoded_start_time);
            l_start_time := decode_date(l_encoded_start_time);
            if l_encoded_end_time < l_encoded_last_time then
               l_end_time := decode_date(l_encoded_end_time - 1); -- one minute before
            else
               l_end_time := decode_date(l_encoded_end_time);
            end if;
            -------------------------------------
            -- recurse for the sub time window --
            -------------------------------------
            retrieve_location_level_values(
               l_level_values,
               p_location_id,
               p_parameter_id,
               p_parameter_type_id,
               p_duration_id,
               p_spec_level_id,
               p_level_units,
               l_start_time,
               l_end_time,
               p_attribute_value,
               p_attribute_units,
               p_attribute_parameter_id,
               p_attribute_param_type_id,
               p_attribute_duration_id,
               'UTC',
               p_office_id);
            for i in 1..l_level_values.count loop
               p_level_values.extend;
               p_level_values(p_level_values.count) := l_level_values(i);
            end loop;
         end loop;
      end;
   else
      ------------------------------------------
      -- working with a single effective date --
      ------------------------------------------
      -------------------------------
      -- get the units conversions --
      -------------------------------
      get_units_conversion(
         l_factor,
         l_offset,
         'FROM_CWMS',
         p_level_units,
         l_parameter_code);
      if p_attribute_value is not null then
         get_units_conversion(
            l_attribute_factor,
            l_attribute_offset,
            'TO_CWMS',
            p_attribute_units,
            l_attribute_parameter_code);
         l_attribute_value := p_attribute_value * l_attribute_factor + l_attribute_offset;
         l_digits := l_significant_digits - trunc(log(10, l_attribute_value));
      end if;
      --------------------------------------
      -- get the at_location_level record --
      --------------------------------------
      begin
         select *
           into l_rec
           from at_location_level
          where location_code = l_location_code
            and specified_level_code = l_spec_level_code
            and parameter_code = l_parameter_code
            and parameter_type_code = l_parameter_type_code
            and duration_code = l_duration_code
            and nvl(to_char(attribute_parameter_code), '@') = nvl(to_char(l_attribute_parameter_code), '@')
            and nvl(to_char(attribute_parameter_type_code), '@') = nvl(to_char(l_attribute_param_type_code), '@')
            and nvl(to_char(attribute_duration_code), '@') = nvl(to_char(l_attribute_duration_code), '@')
            and nvl(to_char(round(attribute_value, l_digits)), '@') = nvl(to_char(round(l_attribute_value, l_digits)), '@')
            and location_level_date = (select max(location_level_date)
                                         from at_location_level
                                        where location_code = l_location_code
                                          and specified_level_code = l_spec_level_code
                                          and parameter_code = l_parameter_code
                                          and parameter_type_code = l_parameter_type_code
                                          and duration_code = l_duration_code
                                          and nvl(to_char(attribute_parameter_code), '@') = nvl(to_char(l_attribute_parameter_code), '@')
                                          and nvl(to_char(attribute_parameter_type_code), '@') = nvl(to_char(l_attribute_param_type_code), '@')
                                          and nvl(to_char(attribute_duration_code), '@') = nvl(to_char(l_attribute_duration_code), '@')
                                          and nvl(to_char(round(attribute_value, l_digits)), '@') = nvl(to_char(round(l_attribute_value, l_digits)), '@')
                                          and location_level_date <= l_start_time);
      exception
         when no_data_found then
            select office_id
              into l_office_id
              from cwms_office
             where office_code = l_office_code;
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Location level',
               l_office_id
               || '/' || p_location_id
               || '.' || p_parameter_id
               || '.' || p_parameter_type_id
               || '.' || p_duration_id
               || '.' || p_spec_level_id
               || case
                     when p_attribute_value is null then
                        null
                     else
                        ' (' || p_attribute_value || ' ' || p_attribute_units || ')'
                  end
               || '@' || p_start_time);
      end;
      ----------------------------
      -- fill out the tsv array --
      ----------------------------
      if l_rec.location_level_value is null then
         ---------------------
         -- seasonal values --
         ---------------------
         ---------------------------------------------------------
         -- find the nearest date/value on or before start time --
         ---------------------------------------------------------
         find_nearest(
            l_date_prev,
            l_value_prev,
            l_rec,
            l_start_time,
            'BEFORE',
            'UTC');
         if l_date_prev = l_start_time then
            l_value := l_value_prev * l_factor + l_offset;
         else
            --------------------------------------------------------
            -- find the nearest date/value on or after start time --
            --------------------------------------------------------
            find_nearest(
               l_date_next,
               l_value_next,
               l_rec,
               l_start_time,
               'AFTER',
               'UTC');
            if l_date_next = l_start_time then
               l_value := l_value_next * l_factor + l_offset;
            else
               -----------------------------
               -- compute the level value --
               -----------------------------
               if l_rec.interpolate = 'T' then
                  l_value := (
                     l_value_prev +
                     (l_start_time - l_date_prev) /
                     (l_date_next - l_date_prev) *
                     (l_value_next - l_value_prev)) * l_factor + l_offset;
               else
                  l_value := l_value_prev * l_factor + l_offset;
               end if;
            end if;
         end if;
         p_level_values.extend;
         p_level_values(1) := new ztsv_type(p_start_time, l_value, 0);
         if l_end_time is null then
            --------------------------------------------------
            -- called from retrieve_location_level_value(), --
            -- just looking for a single value              --
            --------------------------------------------------
            null;
         else
            -----------------------------------------------------
            -- find the remainder of values in the time window --
            -----------------------------------------------------
            loop
               find_nearest(
                  l_date_next,
                  l_value_next,
                  l_rec,
                  p_level_values(p_level_values.count).date_time + 1 / 86400,
                  'AFTER',
                  'UTC');
               p_level_values.extend;
               if l_date_next <= l_end_time then
                  -------------------------------------
                  -- on or before end of time window --
                  -------------------------------------
                  p_level_values(p_level_values.count) :=
                     new ztsv_type(l_date_next, l_value_next, 0);
               else
                  -------------------------------
                  -- beyond end of time window --
                  -------------------------------
                  find_nearest(
                     l_date_prev,
                     l_value_prev,
                     l_rec,
                     l_date_next - 1 / 86400,
                     'BEFORE',
                     'UTC');
                  -----------------------------
                  -- compute the level value --
                  -----------------------------
                  if l_rec.interpolate = 'T' then
                     l_value := (
                        l_value_prev +
                        (l_end_time - l_date_prev) /
                        (l_date_next - l_date_prev) *
                        (l_value_next - l_value_prev)) * l_factor + l_offset;
                  else
                     l_value := l_value_prev * l_factor + l_offset;
                  end if;
                  p_level_values(p_level_values.count) :=
                     new ztsv_type(l_end_time, l_value, 0);
               end if;
               if l_date_next > l_end_time then
                  exit;
               end if;
            end loop;
         end if;
      else
         --------------------
         -- constant value --
         --------------------
         l_value := l_rec.location_level_value * l_factor + l_offset;
         p_level_values.extend(2);
         p_level_values(1) := new ztsv_type(l_start_time, l_value, 0);
         p_level_values(2) := new ztsv_type(l_end_time,   l_value, 0);
      end if;
      if p_timezone_id != 'UTC' then
         for i in 1..p_level_values.count loop
            p_level_values(i).date_time :=
               cast(
                  from_tz(cast(p_level_values(i).date_time as timestamp), 'UTC')
                  at time zone p_timezone_id
                  as date);
         end loop;
      end if;
   end if;
end retrieve_location_level_values;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--
-- Retreives a time series of Location Level values for a specified time window
--
-- The returned QUALITY_CODE values of the time series will be zero.
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is   
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level_values(
      p_level_values,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_timezone_id,
      p_office_id);
end retrieve_location_level_values;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_values
--
-- Returns a time series of Location Level values for a specified time window
--
-- The returned QUALITY_CODE values of the time series will be zero.
--------------------------------------------------------------------------------
function retrieve_location_level_values(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array
is
   l_values ztsv_array;
begin
   retrieve_location_level_values(
      l_values,
      p_location_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);

   return l_values;
end retrieve_location_level_values;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_values2
--
-- Retreives a time series of Location Level values for a specified time window
-- using only text and numeric parameters
--
-- p_start_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_end_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_level_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing date-time and value
-- separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_values2(
   p_level_values            out varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2,
   p_end_time                in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_loc_lvl_values varchar2(32767);
   l_level_values   ztsv_array;
   l_rs             varchar2(1) := chr(30);
   l_gs             varchar2(1) := chr(29);
begin
   retrieve_location_level_values(
      l_level_values,
      p_location_level_id,
      p_level_units,
      to_date(p_start_time, 'yyyy/mm/dd hh24:mi:ss'),
      to_date(p_end_time, 'yyyy/mm/dd hh24:mi:ss'),
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   for i in 1..l_level_values.count loop
      l_loc_lvl_values := l_loc_lvl_values
         || l_rs
         || to_char(l_level_values(i).date_time, 'yyyy/mm/dd hh24:mi:ss') 
         || l_gs
         || to_char(l_level_values(i).value); 
   end loop;
   p_level_values := substr(l_loc_lvl_values, 2);      
end retrieve_loc_lvl_values2;   

--------------------------------------------------------------------------------
-- FUNCTION retrieve_loc_lvl_values2
--
-- Returns a time series of Location Level values for a specified time window
-- using only text and numeric parameters
--
-- p_start_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_end_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_level_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing date-time and value
-- separated by the GS character (chr(29))
--------------------------------------------------------------------------------

function retrieve_loc_lvl_values2(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2, -- yyyy/mm/dd hh:mm:ss
   p_end_time                in  varchar2, -- yyyy/mm/dd hh:mm:ss
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return varchar2 result_cache -- recordset of (date, value) records
is
   l_level_values varchar2(32767);
begin
   retrieve_loc_lvl_values2(
      l_level_values,
      p_location_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   
   return l_level_values;
end retrieve_loc_lvl_values2;   

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--
-- Retreives a time series of Location Level values for a specified time window
-- for a specified Time Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--
-- The returned QUALITY_CODE values of the time series will be zero.
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_location_id       varchar2(49);
   l_parameter_id      varchar2(49);
   l_parameter_type_id varchar2(16);
   l_duration_id       varchar2(16);
begin
   get_tsid_ids(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_ts_id);

   retrieve_location_level_values(
      p_level_values,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_spec_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);

end retrieve_location_level_values;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_values
--
-- Returns a time series of Location Level values for a specified time window
-- for a specified Time Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--
-- The returned QUALITY_CODE values of the time series will be zero.
--------------------------------------------------------------------------------
function retrieve_location_level_values(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array
is
   l_values ztsv_array;
begin
   retrieve_location_level_values(
      l_values,
      p_ts_id,
      p_spec_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);

   return l_values;
end retrieve_location_level_values;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--
-- Retreives a Location Level value for a specified time
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_values ztsv_array;
begin
   retrieve_location_level_values(
      l_values,
      p_location_level_id,
      p_level_units,
      p_date,
      null,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);

   p_level_value := l_values(1).value;
end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--
-- Returns a Location Level value for a specified time
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number result_cache
is
   l_level_value number;
begin
   retrieve_location_level_value(
      l_level_value,
      p_location_level_id,
      p_level_units,
      p_date,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);

   return l_level_value;
end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--
-- Retreives a Location Level value for a specified time for a specified Time
-- Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_location_id       varchar2(49);
   l_parameter_id      varchar2(49);
   l_parameter_type_id varchar2(16);
   l_duration_id       varchar2(16);
begin
   get_tsid_ids(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_ts_id);

   retrieve_location_level_value(
      p_level_value,
      get_location_level_id(
         l_location_id,
         l_parameter_id,
         l_parameter_type_id,
         l_duration_id,
         p_spec_level_id),
      p_level_units,
      p_date,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);

end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--
-- Retrurns a Location Level value for a specified time for a specified Time
-- Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number result_cache
is
   l_location_level_value number(10);
begin
   retrieve_location_level_value(
      l_location_level_value,
      p_ts_id,
      p_spec_level_id,
      p_level_units,
      p_date,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);

   return l_location_level_value;
end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time
--
-- The attribute values are returned in the units specified
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs(
   p_attribute_values        out number_tab_t,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
is
   l_attribute_values number_tab_t := new number_tab_t();
begin
   for rec in (
      select a_ll.attribute_value * c_uc.factor + c_uc.offset as attribute_value
        from at_location_level    a_ll,
             at_physical_location a_pl,
             at_base_location     a_bl,
             at_parameter         a_p1,
             at_parameter         a_p2,
             at_specified_level   a_sl,
             cwms_office          c_o,
             cwms_base_parameter  c_bp1,
             cwms_base_parameter  c_bp2,
             cwms_parameter_type  c_pt1,
             cwms_parameter_type  c_pt2,
             cwms_duration        c_d1,
             cwms_duration        c_d2,
             cwms_unit_conversion c_uc
       where c_o.office_code = cwms_util.get_office_code(upper(p_office_id))
         and a_bl.db_office_code = c_o.office_code
         and upper(a_bl.base_location_id) =
             upper(case
                      when instr(p_location_id, '-') = 0 then p_location_id
                      else substr(p_location_id, 1, instr(p_location_id, '-') - 1)
                   end)
         and nvl(upper(a_pl.sub_location_id), '.') =
             nvl(upper(case
                          when instr(p_location_id, '-') = 0 then null
                          else substr(p_location_id, instr(p_location_id, '-') + 1)
                       end), '.')
         and a_pl.base_location_code = a_bl.base_location_code
         and a_ll.location_code = a_pl.location_code
         and upper(c_bp1.base_parameter_id) =
             upper(case
                      when instr(p_parameter_id, '-') = 0 then p_parameter_id
                      else substr(p_parameter_id, 1, instr(p_parameter_id, '-') - 1)
                        end)
         and nvl(upper(a_p1.sub_parameter_id), '.') =
             nvl(upper(case
                          when instr(p_parameter_id, '-') = 0 then null
                          else substr(p_parameter_id, instr(p_parameter_id, '-') + 1)
                       end), '.')
         and a_ll.parameter_code = a_p1.parameter_code
         and upper(c_pt1.parameter_type_id) = upper(p_parameter_type_id)
         and a_ll.parameter_type_code = c_pt1.parameter_type_code
         and upper(c_d1.duration_id) = upper(p_duration_id)
         and a_ll.duration_code = c_d1.duration_code
         and upper(a_sl.specified_level_id) = upper(p_spec_level_id)
         and a_ll.specified_level_code = a_sl.specified_level_code
         and upper(c_bp2.base_parameter_id) =
             upper(case
                      when instr(p_attribute_parameter_id, '-') = 0 then p_attribute_parameter_id
                      else substr(p_attribute_parameter_id, 1, instr(p_attribute_parameter_id, '-') - 1)
                   end)
         and nvl(upper(a_p2.sub_parameter_id), '.') =
             nvl(upper(case
                          when instr(p_attribute_parameter_id, '-') = 0 then null
                          else substr(p_attribute_parameter_id, instr(p_attribute_parameter_id, '-') + 1)
                       end), '.')
         and a_ll.attribute_parameter_code = a_p2.parameter_code
         and upper(c_pt2.parameter_type_id) = upper(p_attribute_param_type_id)
         and a_ll.parameter_type_code = c_pt2.parameter_type_code
         and upper(c_d2.duration_id) = upper(p_attribute_duration_id)
         and a_ll.duration_code = c_d2.duration_code
         and c_uc.abstract_param_code = c_bp2.abstract_param_code
         and c_uc.from_unit_code = c_bp2.unit_code
         and c_uc.to_unit_id = p_attribute_units
         and a_ll.location_level_date = (
             select max(a_ll.location_level_date)
               from at_location_level    a_ll,
                    at_physical_location a_pl,
                    at_base_location     a_bl,
                    at_parameter         a_p1,
                    at_parameter         a_p2,
                    at_specified_level   a_sl,
                    cwms_office          c_o,
                    cwms_base_parameter  c_bp1,
                    cwms_base_parameter  c_bp2,
                    cwms_parameter_type  c_pt1,
                    cwms_parameter_type  c_pt2,
                    cwms_duration        c_d1,
                    cwms_duration        c_d2
             where c_o.office_code = cwms_util.get_office_code(upper(p_office_id))
                and a_bl.db_office_code = c_o.office_code
                and upper(a_bl.base_location_id) =
                    upper(case
                             when instr(p_location_id, '-') = 0 then p_location_id
                             else substr(p_location_id, 1, instr(p_location_id, '-') - 1)
                          end)
                and nvl(upper(a_pl.sub_location_id), '.') =
                    nvl(upper(case
                                 when instr(p_location_id, '-') = 0 then null
                                 else substr(p_location_id, instr(p_location_id, '-') + 1)
                              end), '.')
                and a_pl.base_location_code = a_bl.base_location_code
                and a_ll.location_code = a_pl.location_code
                and upper(c_bp1.base_parameter_id) =
                    upper(case
                             when instr(p_parameter_id, '-') = 0 then p_parameter_id
                             else substr(p_parameter_id, 1, instr(p_parameter_id, '-') - 1)
                               end)
                and nvl(upper(a_p1.sub_parameter_id), '.') =
                    nvl(upper(case
                                 when instr(p_parameter_id, '-') = 0 then null
                                 else substr(p_parameter_id, instr(p_parameter_id, '-') + 1)
                              end), '.')
                and a_ll.parameter_code = a_p1.parameter_code
                and upper(c_pt1.parameter_type_id) = upper(p_parameter_type_id)
                and a_ll.parameter_type_code = c_pt1.parameter_type_code
                and upper(c_d1.duration_id) = upper(p_duration_id)
                and a_ll.duration_code = c_d1.duration_code
                and upper(a_sl.specified_level_id) = upper(p_spec_level_id)
                and a_ll.specified_level_code = a_sl.specified_level_code
                and upper(c_bp2.base_parameter_id) =
                    upper(case
                             when instr(p_attribute_parameter_id, '-') = 0 then p_attribute_parameter_id
                             else substr(p_attribute_parameter_id, 1, instr(p_attribute_parameter_id, '-') - 1)
                          end)
                and nvl(upper(a_p2.sub_parameter_id), '.') =
                    nvl(upper(case
                                 when instr(p_attribute_parameter_id, '-') = 0 then null
                                 else substr(p_attribute_parameter_id, instr(p_attribute_parameter_id, '-') + 1)
                              end), '.')
                and a_ll.attribute_parameter_code = a_p2.parameter_code
                and upper(c_pt2.parameter_type_id) = upper(p_attribute_param_type_id)
                and a_ll.parameter_type_code = c_pt2.parameter_type_code
                and upper(c_d2.duration_id) = upper(p_attribute_duration_id)
                and a_ll.duration_code = c_d2.duration_code
                and a_ll.location_level_date <=
                    case
                      when p_date is null then
                         cast(systimestamp at time zone 'UTC' as date)
                      else
                         cast(from_tz(cast(p_date as timestamp), nvl(p_timezone_id, 'UTC')) as date)
                    end)
    order by a_ll.attribute_value * c_uc.factor + c_uc.offset)
   loop
      l_attribute_values.extend;
      l_attribute_values(l_attribute_values.count) := rec.attribute_value;
   end loop;
   p_attribute_values := l_attribute_values;    
end retrieve_location_level_attrs;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time
--
-- The attribute values are returned in the units specified
--------------------------------------------------------------------------------

procedure retrieve_location_level_attrs(
   p_attribute_values        out number_tab_t,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
is   
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_spec_level_id           varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level_attrs(
      p_attribute_values,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_timezone_id,
      p_date,
      p_office_id);
end retrieve_location_level_attrs;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--
-- Returns a table of attribute values for a Location Level in effect at a
-- specified time
--
-- The attribute values are returned in the units specified
--------------------------------------------------------------------------------
function retrieve_location_level_attrs(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number_tab_t
is
   l_attribute_values number_tab_t;
begin
   retrieve_location_level_attrs(
      l_attribute_values,
      p_location_level_id,
      p_attribute_id,
      p_attribute_units,
      p_timezone_id,
      p_date,
      p_office_id);
      
   return l_attribute_values;
end retrieve_location_level_attrs;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs2
--
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time using only text and numeric parameters
--
-- p_date should be specifed as 'yyyy/mm/dd hh:mm:ss'
--
-- p_attribute_values is returned as text records separated by the RS character
-- (chr(30)) with each record containing an attribute value in the units 
-- specified
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs2(
   p_attribute_values        out varchar2,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
is
   l_attribute_values number_tab_t;
begin
   p_attribute_values := null;
   retrieve_location_level_attrs(
      l_attribute_values,
      p_location_level_id,
      p_attribute_id,
      p_attribute_units,
      p_timezone_id,
      to_date(p_date, 'yyyy/mm/dd hh24:mi:ss'),
      p_office_id);
   for i in 1..l_attribute_values.count loop
      p_attribute_values := p_attribute_values || to_char(l_attribute_values(i)) || cwms_util.record_separator;
   end loop;
end retrieve_location_level_attrs2;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs2
--
-- Returns a table of attribute values for a Location Level in effect at a
-- specified time using only text and numeric parameters
--
-- p_date should be specifed as 'yyyy/mm/dd hh:mm:ss'
--
-- The attribute values are returned as text records separated by the RS
-- character (chr(30)) with each record containing an attribute value in the 
-- units specified
--------------------------------------------------------------------------------
function retrieve_location_level_attrs2(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return varchar2 result_cache
is
   l_attribute_values varchar2(32767);
begin
   retrieve_location_level_attrs2(
      l_attribute_values,
      p_location_level_id,
      p_attribute_id,
      p_attribute_units,
      p_timezone_id,
      p_date,
      p_office_id);
      
   return l_attribute_values;
end;

--------------------------------------------------------------------------------
-- PRIVATE FUNCTION lookup_level_or_attribute
--------------------------------------------------------------------------------
function lookup_level_or_attribute(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_value                   in  number,
   p_lookup_level            in  boolean,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number result_cache
is
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_spec_level_id           varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
   l_value                   number;
   l_attrs                   number_tab_t;
   l_levels                  number_tab_t := new number_tab_t();
begin
   -----------------------------
   -- retrieve the attributes --
   -----------------------------
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level_attrs(
      l_attrs,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_timezone_id,
      p_date,
      p_office_id);
   if l_attrs.count = 0 then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level with attribute',
         nvl(p_office_id, cwms_util.user_office_id)
         || '/' || p_location_level_id
         || '/' || p_attribute_id
         || '@' || to_char(nvl(p_date, sysdate), 'yyyy-mm-dd hh24mi'));
   end if;
   -------------------------
   -- retrieve the levels --
   -------------------------
   l_levels.extend(l_attrs.count);
   for i in 1..l_attrs.count loop
      l_levels(i) := retrieve_location_level_value(
         p_location_level_id,
         p_level_units,
         p_date,
         l_attrs(i),
         p_attribute_id,
         p_attribute_units,
         p_timezone_id,
         p_office_id);
   end loop;
   ------------------------
   -- perform the lookup --
   ------------------------
   if p_lookup_level then
      l_value := cwms_lookup.lookup(
         p_value,
         l_attrs,
         l_levels,
         false,
         false,
         null,
         p_in_range_behavior,
         p_out_range_behavior);
   else
      l_value := cwms_lookup.lookup(
         p_value,
         l_levels,
         l_attrs,
         false,
         false,
         null,
         p_in_range_behavior,
         p_out_range_behavior);
   end if;
   -----------------------
   -- return the result --
   -----------------------
   return l_value;
end lookup_level_or_attribute;

--------------------------------------------------------------------------------
-- PROCEDURE lookup_level_by_attribute
--
-- Retrieves the level value of a Location Level that corresponds to a specified
-- attribute value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- attribute value is within the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.IN_RANGE_INTERP - if the specified attribute value is not one
--    of the Location Level attributes, the retrieved level is interpolated
--    between levels associated with the nearest attribute values less and 
--    greater than the specified attribute value
--
--    CWMS_LOOKUP.IN_RANGE_PREV - if the specified attribute value is not one
--    of the Location Level attributes, the retrieved level is the level
--    associated with the nearest attribute value less than the specified
--    attribute value 
--
--    CWMS_LOOKUP.IN_RANGE_NEXT - if the specified attribute value is not one
--    of the Location Level attributes, the retrieved level is the level
--    associated with the nearest attribute value greater than the specified
--    attribute value
--
--    CWMS_LOOKUP.IN_RANGE_NEAREST - if the specified attribute value is not one
--    of the Location Level attributes, the retrieved level is the level
--    associated with the nearest attribute value to the specified attribute 
--    value
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.OUT_RANGE_NULL - NULL is retrieved for the level value
--
--    CWMS_LOOKUP.OUT_RANGE_ERROR - an error is raised instead of retrieving
--    a value 
--
--    CWMS_LOOKUP.OUT_RANGE_NEAREST - the level value retrieved is the level
--    value associated with the attribute value nearest the specified attribute
--    value
--
--    CWMS_LOOKUP.OUT_RANGE_EXTRAP - the level value retrieved is extrapolated
--    from the level values associated with the two attribute values nearst to
--    the specified attribute value
--------------------------------------------------------------------------------
procedure lookup_level_by_attribute(
   p_level                   out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
is
begin
   p_level := lookup_level_or_attribute(
      p_location_level_id,
      p_attribute_id,
      p_attribute_value,
      true,
      p_level_units,
      p_attribute_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
end lookup_level_by_attribute;

--------------------------------------------------------------------------------
-- FUNCTION lookup_level_by_attribute
--
-- Returns the level value of a Location Level that corresponds to a specified
-- attribute value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- attribute value is within the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.IN_RANGE_INTERP - if the specified attribute value is not one
--    of the Location Level attributes, the returned level is interpolated
--    between levels associated with the nearest attribute values less and 
--    greater than the specified attribute value
--
--    CWMS_LOOKUP.IN_RANGE_PREV - if the specified attribute value is not one
--    of the Location Level attributes, the returned level is the level
--    associated with the nearest attribute value less than the specified
--    attribute value 
--
--    CWMS_LOOKUP.IN_RANGE_NEXT - if the specified attribute value is not one
--    of the Location Level attributes, the returned level is the level
--    associated with the nearest attribute value greater than the specified
--    attribute value
--
--    CWMS_LOOKUP.IN_RANGE_NEAREST - if the specified attribute value is not one
--    of the Location Level attributes, the returned level is the level
--    associated with the nearest attribute value to the specified attribute 
--    value
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.OUT_RANGE_NULL - NULL is returned for the level value
--
--    CWMS_LOOKUP.OUT_RANGE_ERROR - an error is raised instead of retrieving
--    a value 
--
--    CWMS_LOOKUP.OUT_RANGE_NEAREST - the level value returned is the level
--    value associated with the attribute value nearest the specified attribute
--    value
--
--    CWMS_LOOKUP.OUT_RANGE_EXTRAP - the level value returned is extrapolated
--    from the level values associated with the two attribute values nearest to
--    the specified attribute value
--------------------------------------------------------------------------------
function lookup_level_by_attribute(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number result_cache
is
   l_level number;
begin
   lookup_level_by_attribute(
      l_level,
      p_location_level_id,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_level_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
      
   return l_level;
end lookup_level_by_attribute;

--------------------------------------------------------------------------------
-- PROCEDURE lookup_attribute_by_level
--
-- Retrieves the attribute value of a Location Level that corresponds to a 
-- specified level value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- level value is within the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.IN_RANGE_INTERP - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the retrieved
--    attribute value is interpolated between the attribute values whose
--    associated levels are the nearest values less and greater than the
--    specified level value
--
--    CWMS_LOOKUP.IN_RANGE_PREV - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the retrieved
--    attribute value is the attribute value whose associated level is the 
--    nearest value less than the specified level value 
--
--    CWMS_LOOKUP.IN_RANGE_NEXT - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the retrieved
--    attribute value is the attribute value whose associated level is the 
--    nearest value greater than the specified level value
--
--    CWMS_LOOKUP.IN_RANGE_NEAREST - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the retrieved
--    attribute value is the attribute value whose associated level is the 
--    nearest the specified level value
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.OUT_RANGE_NULL - NULL is retrieved for the attribute value
--
--    CWMS_LOOKUP.OUT_RANGE_ERROR - an error is raised instead of retrieving
--    a value 
--
--    CWMS_LOOKUP.OUT_RANGE_NEAREST - the attribute value whose associated level
--    value is the nearest the specified level value is retrieved
--
--    CWMS_LOOKUP.OUT_RANGE_EXTRAP - the attribute value retrieved is
--    extrapolated from the two attribute values whose associated level values
--    are nearset to the specified level value
--------------------------------------------------------------------------------
procedure lookup_attribute_by_level(
   p_attribute               out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
is
begin
   p_attribute := lookup_level_or_attribute(
      p_location_level_id,
      p_attribute_id,
      p_level_value,
      false,
      p_level_units,
      p_attribute_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
end lookup_attribute_by_level;

--------------------------------------------------------------------------------
-- FUNCTION lookup_attribute_by_level
--
-- Returns the attribute value of a Location Level that corresponds to a 
-- specified level value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- level value is within the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.IN_RANGE_INTERP - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the returned
--    attribute value is interpolated between the attribute values whose
--    associated levels are the nearest values less and greater than the
--    specified level value
--
--    CWMS_LOOKUP.IN_RANGE_PREV - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the returned
--    attribute value is the attribute value whose associated level is the 
--    nearest value less than the specified level value 
--
--    CWMS_LOOKUP.IN_RANGE_NEXT - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the returned
--    attribute value is the attribute value whose associated level is the 
--    nearest value greater than the specified level value
--
--    CWMS_LOOKUP.IN_RANGE_NEAREST - if the specified level value is not a level
--    value associated with one of the Location Level attributes, the returned
--    attribute value is the attribute value whose associated level is the 
--    nearest the specified level value
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
--    CWMS_LOOKUP.OUT_RANGE_NULL - NULL is returned for the attribute value
--
--    CWMS_LOOKUP.OUT_RANGE_ERROR - an error is raised instead of returning
--    a value 
--
--    CWMS_LOOKUP.OUT_RANGE_NEAREST - the attribute value whose associated level
--    value is the nearest the specified level value is returned
--
--    CWMS_LOOKUP.OUT_RANGE_EXTRAP - the attribute value returned is
--    extrapolated from the two attribute values whose associated level values
--    are nearset to the specified level value
--------------------------------------------------------------------------------
function lookup_attribute_by_level(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number result_cache
is
   l_attribute number;
begin
   lookup_attribute_by_level(
      l_attribute,
      p_location_level_id,
      p_attribute_id,
      p_level_value,
      p_level_units,
      p_attribute_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
      
   return l_attribute;
end lookup_attribute_by_level;

--------------------------------------------------------------------------------
-- PROCEDURE delete_location_level
--
-- Deletes the specified Location Level from the database
--------------------------------------------------------------------------------
procedure delete_location_level(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null)
is
   l_location_level_code     number(10);
   l_date                    date;
   l_cascade                 boolean := cwms_util.return_true_or_false(p_cascade);
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_spec_level_id           varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   l_date := cast(
      from_tz(cast(p_effective_date as timestamp), p_timezone_id)
      at time zone 'UTC' as date);
   -----------------------------
   -- verify the level exists --
   -----------------------------
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   l_location_level_code := get_location_level_code(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      l_date,
      true,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_office_id);

   if l_location_level_code is null then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level',
         nvl(p_office_id, cwms_util.user_office_id)
         || '/' || p_location_level_id
         || case
               when p_attribute_value is null then
                  null
               else
                  ' (' || p_attribute_value || ' ' || p_attribute_units || ')'
            end
         || '@' || p_effective_date);
   end if;
   ------------------------
   -- delete the records --
   ------------------------
   if l_cascade then
      delete
        from at_seasonal_location_level
       where location_level_code = l_location_level_code;
   end if;
   delete
     from at_location_level
    where location_level_code = l_location_level_code;
    
end delete_location_level;

--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indicator_code
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_code(
   p_location_id            in  varchar2,
   p_parameter_id           in  varchar2,
   p_parameter_type_id      in  varchar2,
   p_duration_id            in  varchar2,
   p_specified_level_id     in  varchar2,
   p_level_indicator_id     in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_parameter_id      in  varchar2 default null,
   p_attr_parameter_type_id in  varchar2 default null,
   p_attr_duration_id       in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return number result_cache
is
   l_location_code            number(10);
   l_parameter_code           number(10);
   l_parameter_type_code      number(10);
   l_duration_code            number(10);
   l_specified_level_code     number(10);
   l_level_indicator_code     number(10);
   l_attr_units_code          number(10);
   l_attr_parameter_code      number(10);
   l_attr_parameter_type_code number(10);
   l_attr_duration_code       number(10);
   l_ref_specified_level_code number(10);
   l_office_code              number(10) := cwms_util.get_office_code(upper(p_office_id));
   l_cwms_office_code         number(10) := cwms_util.get_office_code('CWMS');
   l_loc_lvl_indicator_code   number(10);
   l_factor                   number := 1.;
   l_offset                   number := 0.;
   l_has_attribute            boolean;
   l_attr_value               number;
   l_ref_attr_value           number;
   l_significant_digits       constant integer := 10;
   l_attr_digits              integer;
   l_ref_attr_digits          integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_attr_value             is null or
      p_attr_units_id          is null or
      p_attr_parameter_id      is null or
      p_attr_parameter_type_id is null or
      p_attr_duration_id       is null
   then
      if p_attr_value             is not null or
         p_attr_units_id          is not null or
         p_attr_parameter_id      is not null or
         p_attr_parameter_type_id is not null or
         p_attr_duration_id       is not null
      then
         cwms_err.raise(
            'ERROR',
            'Attribute parameters must either all be null or all be non-null.');
      else
         l_has_attribute := false;            
      end if;
   else
      l_has_attribute := true;            
   end if;      
   if p_ref_specified_level_id is null
      and p_ref_attr_value     is not null
   then      
      cwms_err.raise(
         'ERROR',
         'Cannot have a reference attribute without a reference specified level.');
   end if;
   -----------------------------     
   -- get the component codes --
   -----------------------------     
   begin
      select pl.location_code
        into l_location_code
        from at_physical_location pl,
             at_base_location bl
       where BL.DB_OFFICE_CODE = l_office_code
         and upper(BL.BASE_LOCATION_ID) = upper(cwms_util.get_base_id(p_location_id))
         and pl.base_location_code = bl.base_location_code
         and upper(nvl(pl.sub_location_id, '-')) = upper(nvl(cwms_util.get_sub_id(p_location_id), '-'));
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location',
            p_location_id);
   end;
   begin
      select p.parameter_code
        into l_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(p_parameter_id))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '-')) = upper(nvl(cwms_util.get_sub_id(p_parameter_id), '-'))
         and p.db_office_code in (l_office_code, l_cwms_office_code);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Parameter',
            p_parameter_id);
   end;
   begin
      select parameter_type_code
        into l_parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(p_parameter_type_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Parameter type',
            p_parameter_type_id);
   end;               
   begin
      select duration_code
        into l_duration_code
        from cwms_duration
       where upper(duration_id) = upper(p_duration_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Duration',
            p_duration_id);
   end;               
   begin
      select specified_level_code
        into l_specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(p_specified_level_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Specified level',
            p_specified_level_id);
   end;
   if l_has_attribute then
      begin
         select p.parameter_code
           into l_attr_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(p_attr_parameter_id))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '-')) = upper(nvl(cwms_util.get_sub_id(p_attr_parameter_id), '-'))
            and p.db_office_code in (l_office_code, l_cwms_office_code);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Parameter',
               p_attr_parameter_id);
      end;
      begin
         select parameter_type_code
           into l_attr_parameter_type_code
           from cwms_parameter_type
          where upper(parameter_type_id) = upper(p_attr_parameter_type_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Parameter type',
               p_attr_parameter_type_id);
      end;               
      begin
         select duration_code
           into l_attr_duration_code
           from cwms_duration
          where upper(duration_id) = upper(p_attr_duration_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Duration',
               p_attr_duration_id);
      end;
      select factor,
             offset
        into l_factor,
             l_offset
        from cwms_unit_conversion
       where from_unit_id = p_attr_units_id
         and to_unit_id = cwms_util.get_default_units(p_attr_parameter_id);                
   end if;
   if p_ref_specified_level_id is not null then
      begin
         select specified_level_code
           into l_ref_specified_level_code
           from at_specified_level
          where upper(specified_level_id) = upper(p_ref_specified_level_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Specified level',
               p_ref_specified_level_id);
      end;
   end if;
   ------------------------------------               
   -- get the loc_lvl_indicator code --
   ------------------------------------
   if p_attr_value is not null then
      l_attr_value := p_attr_value * l_factor + l_offset;
      l_attr_digits := l_significant_digits - trunc(log(10, l_attr_value));
   end if;
   if p_ref_attr_value is not null then
      l_ref_attr_value := p_ref_attr_value * l_factor + l_offset;
      l_ref_attr_digits := l_significant_digits - trunc(log(10, l_ref_attr_value));
   end if;
   begin
      select level_indicator_code
        into l_loc_lvl_indicator_code
        from at_loc_lvl_indicator
       where location_code = l_location_code
         and parameter_code = l_parameter_code
         and parameter_type_code = l_parameter_type_code
         and duration_code = l_duration_code
         and specified_level_code = l_specified_level_code
         and nvl(to_char(round(attr_value, l_attr_digits)), '@') = nvl(to_char(round(l_attr_value, l_attr_digits)), '@')
         and nvl(attr_parameter_code, -1) = nvl(l_attr_parameter_code, -1)
         and nvl(attr_parameter_type_code, -1) = nvl(l_attr_parameter_type_code, -1)
         and nvl(attr_duration_code, -1) = nvl(l_attr_duration_code, -1)
         and nvl(to_char(round(ref_attr_value, l_ref_attr_digits)), '@') = nvl(to_char(round(l_ref_attr_value, l_ref_attr_digits)), '@')
         and nvl(ref_specified_level_code, -1) = nvl(l_ref_specified_level_code, -1)
         and level_indicator_id = upper(p_level_indicator_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location level indicator',
            null);
   end;
   return l_loc_lvl_indicator_code;               
end get_loc_lvl_indicator_code;   

--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indicator_code
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_code(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return number result_cache
is
   ITEM_DOES_NOT_EXIST      exception; pragma exception_init (ITEM_DOES_NOT_EXIST, -20034);
   l_location_id            varchar2(49);
   l_parameter_id           varchar2(49);
   l_param_type_id          varchar2(16);
   l_duration_id            varchar2(16);
   l_specified_level_id     varchar2(256);
   l_level_indicator_id     varchar2(32);
   l_attr_parameter_id      varchar2(49);
   l_attr_param_type_id     varchar2(16);
   l_attr_duration_id       varchar2(16);
   l_loc_lvl_indicator_code number(10);
begin
   cwms_level.parse_loc_lvl_indicator_id(
      l_location_id,
      l_parameter_id,
      l_param_type_id,
      l_duration_id,
      l_specified_level_id,
      l_level_indicator_id,
      p_loc_lvl_indicator_id);
      
   cwms_level.parse_attribute_id(
      l_attr_parameter_id,
      l_attr_param_type_id,
      l_attr_duration_id,
      p_attr_id);

   begin
      l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
         l_location_id,
         l_parameter_id,
         l_param_type_id,
         l_duration_id,
         l_specified_level_id,
         l_level_indicator_id,
         p_attr_value,
         p_attr_units_id,
         l_attr_parameter_id,
         l_attr_param_type_id,
         l_attr_duration_id,
         p_ref_specified_level_id,
         p_ref_attr_value,
         p_office_id);
         
      return l_loc_lvl_indicator_code;      
   exception
      when ITEM_DOES_NOT_EXIST then
         declare
            l_location_level_text varchar2(4000);
         begin
            l_location_level_text := p_loc_lvl_indicator_id;
            if p_attr_id is not null then
               l_location_level_text := l_location_level_text
                  || ' (attribute '
                  || p_attr_id
                  || ' = '
                  || p_attr_value
                  || ' '
                  || p_attr_units_id
                  ||')';
            end if;
            if p_ref_specified_level_id is not null then
               l_location_level_text := l_location_level_text
                  || ' (reference = '
                  || p_ref_specified_level_id;
               if p_ref_attr_value is not null then
                  l_location_level_text := l_location_level_text
                     || ' (attribute '
                     || p_attr_id
                     || ' = '
                     || p_ref_attr_value
                     || ' '
                     || p_attr_units_id
                     || ')';
               end if;                  
               l_location_level_text := l_location_level_text || ')';
            end if;
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Location Level Indicator',
               l_location_level_text);
         end;
   end;      
end get_loc_lvl_indicator_code;   

--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_cond
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_cond(
   p_level_indicator_code        in number,
   p_level_indicator_value       in number,
   p_expression                  in varchar2,
   p_comparison_operator_1       in varchar2,
   p_comparison_value_1          in binary_double,
   p_comparison_unit_code        in number                 default null,
   p_connector                   in varchar2               default null, 
   p_comparison_operator_2       in varchar2               default null,
   p_comparison_value_2          in binary_double          default null,
   p_rate_expression             in varchar2               default null,
   p_rate_comparison_operator_1  in varchar2               default null,
   p_rate_comparison_value_1     in binary_double          default null,
   p_rate_comparison_unit_code   in number                 default null,
   p_rate_connector              in varchar2               default null, 
   p_rate_comparison_operator_2  in varchar2               default null,
   p_rate_comparison_value_2     in binary_double          default null,
   p_rate_interval               in interval day to second default null,
   p_description                 in varchar2               default null,
   p_fail_if_exists              in varchar2               default 'F',
   p_ignore_nulls_on_update      in varchar2               default 'T')
is
   l_fail_if_exists         boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls_on_update boolean := cwms_util.return_true_or_false(p_ignore_nulls_on_update);
   l_exists                 boolean := true;
   l_rec                    at_loc_lvl_indicator_cond%rowtype;
   l_unit_code              number(10);
   l_from_unit_id           varchar2(16);
   l_to_unit_id             varchar2(16);
begin
   begin
      select *
        into l_rec
        from at_loc_lvl_indicator_cond
       where level_indicator_code = p_level_indicator_code
         and level_indicator_value = p_level_indicator_value;
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Location level indicator condition',
         null);
   end if;
   if l_exists and l_ignore_nulls_on_update then
      l_rec.expression                 := nvl(upper(trim(p_expression)), l_rec.expression);
      l_rec.comparison_operator_1      := nvl(upper(trim(p_comparison_operator_1)), l_rec.comparison_operator_1);
      l_rec.comparison_value_1         := nvl(p_comparison_value_1, l_rec.comparison_value_1);
      l_rec.comparison_unit            := nvl(trim(p_comparison_unit_code), l_rec.comparison_unit);
      l_rec.connector                  := nvl(upper(trim(p_connector)), l_rec.connector);
      l_rec.comparison_operator_2      := nvl(upper(trim(p_comparison_operator_2)), l_rec.comparison_operator_2);
      l_rec.comparison_value_2         := nvl(p_comparison_value_2, l_rec.comparison_value_2);
      l_rec.rate_expression            := nvl(upper(trim(p_rate_expression)), l_rec.rate_expression);
      l_rec.rate_comparison_operator_1 := nvl(upper(trim(p_rate_comparison_operator_1)), l_rec.rate_comparison_operator_1);
      l_rec.rate_comparison_value_1    := nvl(p_rate_comparison_value_1, l_rec.rate_comparison_value_1);
      l_rec.rate_comparison_unit       := nvl(trim(p_rate_comparison_unit_code), l_rec.rate_comparison_unit);
      l_rec.rate_connector             := nvl(upper(trim(p_rate_connector)), l_rec.rate_connector);
      l_rec.rate_comparison_operator_2 := nvl(upper(trim(p_rate_comparison_operator_2)), l_rec.rate_comparison_operator_2);
      l_rec.rate_comparison_value_2    := nvl(p_rate_comparison_value_2, l_rec.rate_comparison_value_2);
      l_rec.rate_interval              := nvl(p_rate_interval, l_rec.rate_interval);
      l_rec.description                := nvl(trim(p_description), l_rec.description);
   else
      l_rec.level_indicator_value      := p_level_indicator_value;
      l_rec.expression                 := p_expression;
      l_rec.comparison_operator_1      := p_comparison_operator_1;
      l_rec.comparison_value_1         := p_comparison_value_1;
      l_rec.comparison_unit            := p_comparison_unit_code;
      l_rec.connector                  := p_connector;
      l_rec.comparison_operator_2      := p_comparison_operator_2;
      l_rec.comparison_value_2         := p_comparison_value_2;
      l_rec.rate_expression            := p_rate_expression;
      l_rec.rate_comparison_operator_1 := p_rate_comparison_operator_1;
      l_rec.rate_comparison_value_1    := p_rate_comparison_value_1;
      l_rec.rate_comparison_unit       := p_rate_comparison_unit_code;
      l_rec.rate_connector             := p_rate_connector;
      l_rec.rate_comparison_operator_2 := p_rate_comparison_operator_2;
      l_rec.rate_comparison_value_2    := p_rate_comparison_value_2;
      l_rec.rate_interval              := p_rate_interval;
      l_rec.description                := p_description;
   end if;
   l_rec.level_indicator_code := p_level_indicator_code;
   --------------------------------------
   -- sanity check on comparison units --
   --------------------------------------
   if l_rec.comparison_unit is not null then
      begin
         select uc.from_unit_id,
                uc.to_unit_id
           into l_from_unit_id,
                l_to_unit_id
           from at_loc_lvl_indicator lli,
                at_parameter p,
                cwms_base_parameter bp,
                cwms_unit_conversion uc
          where lli.level_indicator_code = l_rec.level_indicator_code
            and p.parameter_code = lli.parameter_code
            and bp.base_parameter_code = p.base_parameter_code
            and uc.from_unit_code = bp.unit_code
            and uc.to_unit_code = l_rec.comparison_unit;
      exception
         when no_data_found then
            select u.unit_id
              into l_from_unit_id
              from at_loc_lvl_indicator lli,
                   at_parameter p,
                   cwms_base_parameter bp,
                   cwms_unit u
             where lli.level_indicator_code = l_rec.level_indicator_code
               and p.parameter_code = lli.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and u.unit_code = bp.unit_code;
            select unit_id 
              into l_to_unit_id 
              from cwms_unit 
             where unit_code = l_rec.comparison_unit;
         cwms_err.raise(
            'ERROR',
            'Cannot convert from database unit ('
            || l_from_unit_id
            ||') to comparison unit ('
            || l_to_unit_id
            || ')');             
      end;
   end if;
   -------------------------------------------
   -- sanity check on rate comparison units --
   -------------------------------------------
   if l_rec.rate_comparison_unit is not null then
      begin
         select uc.from_unit_id,
                uc.to_unit_id
           into l_from_unit_id,
                l_to_unit_id
           from at_loc_lvl_indicator lli,
                at_parameter p,
                cwms_base_parameter bp,
                cwms_unit_conversion uc
          where lli.level_indicator_code = l_rec.level_indicator_code
            and p.parameter_code = lli.parameter_code
            and bp.base_parameter_code = p.base_parameter_code
            and uc.from_unit_code = bp.unit_code
            and uc.to_unit_code = l_rec.rate_comparison_unit;
      exception
         when no_data_found then
            select u.unit_id
              into l_from_unit_id
              from at_loc_lvl_indicator lli,
                   at_parameter p,
                   cwms_base_parameter bp,
                   cwms_unit u
             where lli.level_indicator_code = l_rec.level_indicator_code
               and p.parameter_code = lli.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and u.unit_code = bp.unit_code;
            select unit_id 
              into l_to_unit_id 
              from cwms_unit 
             where unit_code = l_rec.rate_comparison_unit;
         cwms_err.raise(
            'ERROR',
            'Cannot convert from database unit ('
            || l_from_unit_id
            ||') to rate comparison unit ('
            || l_to_unit_id
            || ')');             
      end;
   end if;
   ---------------------------------------
   -- insert or update condition record --
   ---------------------------------------
   if l_exists then
      update at_loc_lvl_indicator_cond
         set row = l_rec
       where level_indicator_code = l_rec.level_indicator_code
         and level_indicator_value = l_rec.level_indicator_value;
   else
      insert into at_loc_lvl_indicator_cond values l_rec;
   end if;
end store_loc_lvl_indicator_cond;   

--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_cond
--
-- Creates or updates a Location Level Indicator Condition in the database
--
-- p_rate_interval is specified as 'ddd hh:mm:ss'
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_cond(
   p_loc_lvl_indicator_id        in varchar2,
   p_level_indicator_value       in number,
   p_expression                  in varchar2,
   p_comparison_operator_1       in varchar2,
   p_comparison_value_1          in number,
   p_comparison_unit_id          in varchar2 default null,
   p_connector                   in varchar2 default null, 
   p_comparison_operator_2       in varchar2 default null,
   p_comparison_value_2          in number   default null,
   p_rate_expression             in varchar2 default null,
   p_rate_comparison_operator_1  in varchar2 default null,
   p_rate_comparison_value_1     in number   default null,
   p_rate_comparison_unit_id     in varchar2 default null,
   p_rate_connector              in varchar2 default null, 
   p_rate_comparison_operator_2  in varchar2 default null,
   p_rate_comparison_value_2     in number   default null,
   p_rate_interval               in varchar2 default null,
   p_description                 in varchar2 default null,
   p_attr_value                  in number   default null,
   p_attr_units_id               in varchar2 default null,
   p_attr_id                     in varchar2 default null,
   p_ref_specified_level_id      in varchar2 default null,
   p_ref_attr_value              in number   default null,
   p_fail_if_exists              in varchar2 default 'F',
   p_ignore_nulls_on_update      in varchar2 default 'T',
   p_office_id                   in varchar2 default null)
is
   l_unit_code               number(10);
   l_rate_unit_code          number(10);
   l_loc_lvl_indicator_code  number(10);
   l_rate_interval           interval day(3) to second(0);
begin
   if p_comparison_unit_id is not null then
      select unit_code
        into l_unit_code
        from cwms_unit
       where unit_id = p_comparison_unit_id;
   end if;
   if p_rate_comparison_unit_id is not null then
      select unit_code
        into l_rate_unit_code
        from cwms_unit
       where unit_id = p_rate_comparison_unit_id;
   end if;
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
   l_rate_interval := to_dsinterval(p_rate_interval);      
      
   store_loc_lvl_indicator_cond(
      l_loc_lvl_indicator_code,
      p_level_indicator_value,
      p_expression,
      p_comparison_operator_1,
      p_comparison_value_1,
      l_unit_code,
      p_connector, 
      p_comparison_operator_2,
      p_comparison_value_2,
      p_rate_expression,
      p_rate_comparison_operator_1,
      p_rate_comparison_value_1,
      l_rate_unit_code,
      p_rate_connector, 
      p_rate_comparison_operator_2,
      p_rate_comparison_value_2,
      l_rate_interval,
      p_description,
      p_fail_if_exists,
      p_ignore_nulls_on_update);
end store_loc_lvl_indicator_cond;   
   
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_out
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_out(
   p_level_indicator_code     out number,
   p_location_code            in  number,
   p_parameter_code           in  number,
   p_parameter_type_code      in  number,
   p_duration_code            in  number,
   p_specified_level_code     in  number,
   p_level_indicator_id       in  varchar2,
   p_attr_value               in  number default null,
   p_attr_parameter_code      in  number default null,
   p_attr_parameter_type_code in  number default null,
   p_attr_duration_code       in  number default null,
   p_ref_specified_level_code in  number default null,
   p_ref_attr_value           in  number default null,
   p_minimum_duration         in  interval day to second default null,
   p_maximum_age              in  interval day to second default null,
   p_fail_if_exists           in  varchar2 default 'F',
   p_ignore_nulls_on_update   in  varchar2 default 'T')
is
   l_fail_if_exists         boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls_on_update boolean := cwms_util.return_true_or_false(p_ignore_nulls_on_update);
   l_exists                 boolean := true;
   l_rec                    at_loc_lvl_indicator%rowtype;
begin
   begin
      select *
        into l_rec
        from at_loc_lvl_indicator
       where location_code = p_location_code
         and parameter_code = p_parameter_code
         and parameter_type_code = p_parameter_type_code
         and duration_code = p_duration_code
         and specified_level_code = p_specified_level_code
         and nvl(to_char(attr_parameter_code), '@') = nvl(to_char(p_attr_parameter_code), '@')
         and level_indicator_id = upper(p_level_indicator_id); 
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Location level indicator',
         null);
   end if;
   if l_exists and l_ignore_nulls_on_update then
      l_rec.attr_value               := nvl(p_attr_value,               l_rec.attr_value);
      l_rec.attr_parameter_code      := nvl(p_attr_parameter_code,      l_rec.attr_parameter_code);
      l_rec.attr_parameter_type_code := nvl(p_attr_parameter_type_code, l_rec.attr_parameter_type_code);
      l_rec.attr_duration_code       := nvl(p_attr_duration_code,       l_rec.attr_duration_code);
      l_rec.ref_specified_level_code := nvl(p_ref_specified_level_code, l_rec.ref_specified_level_code);
      l_rec.ref_attr_value           := nvl(p_ref_attr_value,           l_rec.ref_attr_value);
      l_rec.minimum_duration         := nvl(p_minimum_duration,         l_rec.minimum_duration);
      l_rec.maximum_age              := nvl(p_maximum_age,              l_rec.maximum_age);
   else
      l_rec.location_code            := p_location_code;
      l_rec.parameter_code           := p_parameter_code;
      l_rec.parameter_type_code      := p_parameter_type_code;
      l_rec.duration_code            := p_duration_code;
      l_rec.specified_level_code     := p_specified_level_code;
      l_rec.level_indicator_id       := upper(p_level_indicator_id);
      l_rec.attr_value               := p_attr_value;
      l_rec.attr_parameter_code      := p_attr_parameter_code;
      l_rec.attr_parameter_type_code := p_attr_parameter_type_code;
      l_rec.attr_duration_code       := p_attr_duration_code;
      l_rec.ref_specified_level_code := p_ref_specified_level_code;
      l_rec.ref_attr_value           := p_ref_attr_value;
      l_rec.minimum_duration         := p_minimum_duration;
      l_rec.maximum_age              := p_maximum_age;
   end if;
   if l_exists then
      update at_loc_lvl_indicator
         set row = l_rec
       where level_indicator_code = l_rec.level_indicator_code;
   else
      l_rec.level_indicator_code := cwms_seq.nextval;
      insert into at_loc_lvl_indicator values l_rec; 
   end if;
   p_level_indicator_code := l_rec.level_indicator_code;
end store_loc_lvl_indicator_out;   
   
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator
--
-- Creates or updates a Location Level Indicator in the database
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator(
   p_location_id            in  varchar2,
   p_parameter_id           in  varchar2,
   p_parameter_type_id      in  varchar2,
   p_duration_id            in  varchar2,
   p_specified_level_id     in  varchar2,
   p_level_indicator_id     in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_parameter_id      in  varchar2 default null,
   p_attr_parameter_type_id in  varchar2 default null,
   p_attr_duration_id       in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  interval day to second default null,
   p_maximum_age            in  interval day to second default null,
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null)
is
   l_obj  loc_lvl_indicator_t;
   l_zobj zloc_lvl_indicator_t;
begin
   l_obj := loc_lvl_indicator_t(
      nvl(p_office_id, cwms_util.user_office_id),                 
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_specified_level_id,
      p_level_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_parameter_id,
      p_attr_parameter_type_id,
      p_attr_duration_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_minimum_duration,
      p_maximum_age,
      null); -- conditions

   l_zobj := l_obj.zloc_lvl_indicator; 
        
   store_loc_lvl_indicator_out(
      l_zobj.level_indicator_code,
      l_zobj.location_code,
      l_zobj.parameter_code,
      l_zobj.parameter_type_code,
      l_zobj.duration_code,
      l_zobj.specified_level_code,
      l_zobj.level_indicator_id,
      l_zobj.attr_value,
      l_zobj.attr_parameter_code,
      l_zobj.attr_parameter_type_code,
      l_zobj.attr_duration_code,
      l_zobj.ref_specified_level_code,
      l_zobj.ref_attr_value,
      l_zobj.minimum_duration,
      l_zobj.maximum_age,
      p_fail_if_exists,
      p_ignore_nulls_on_update);
   
end store_loc_lvl_indicator;

--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator
--
-- Creates or updates a Location Level Indicator in the database
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attribute_id           in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  interval day to second default null,
   p_maximum_age            in  interval day to second default null,
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null)
is
   l_location_id        varchar2(49);
   l_parameter_id       varchar2(49);
   l_param_type_id      varchar2(16);
   l_duration_id        varchar2(16);
   l_specified_level_id varchar2(256);
   l_level_indicator_id varchar2(32);
   l_attr_parameter_id  varchar2(49);
   l_attr_param_type_id varchar2(16);
   l_attr_duration_id   varchar2(16);
begin
   cwms_level.parse_loc_lvl_indicator_id(
      l_location_id,
      l_parameter_id,
      l_param_type_id,
      l_duration_id,
      l_specified_level_id,
      l_level_indicator_id,
      p_loc_lvl_indicator_id);
      
   cwms_level.parse_attribute_id(
      l_attr_parameter_id,
      l_attr_param_type_id,
      l_attr_duration_id,
      p_attribute_id);
      
   store_loc_lvl_indicator(
      l_location_id,
      l_parameter_id,
      l_param_type_id,
      l_duration_id,
      l_specified_level_id,
      l_level_indicator_id,
      p_attr_value,
      p_attr_units_id,
      l_attr_parameter_id,
      l_attr_param_type_id,
      l_attr_duration_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_minimum_duration,
      p_maximum_age,
      p_fail_if_exists,
      p_ignore_nulls_on_update,
      p_office_id);
end store_loc_lvl_indicator;
   
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator2
--
-- Creates or updates a Location Level Indicator in the database using only text
-- and numeric parameters
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator2(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attribute_id           in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  varchar2 default null, -- 'ddd hh:mi:ss'
   p_maximum_age            in  varchar2 default null, -- 'ddd hh:mi:ss'
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null)
is
begin
   store_loc_lvl_indicator(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attribute_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      to_dsinterval(p_minimum_duration),
      to_dsinterval(p_maximum_age),
      p_fail_if_exists,
      p_ignore_nulls_on_update,
      p_office_id);
end store_loc_lvl_indicator2;

--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator_codes
--
-- The returned cursor contains only the matching location_level_code
--
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator_codes(
   p_cursor                     out sys_refcursor,
   p_loc_lvl_indicator_id_mask  in  varchar2 default null,  -- '%.%.%.%.%.%' if null
   p_attribute_id_mask          in  varchar2 default null,
   p_office_id_mask             in  varchar2 default null) -- user's office if null
is
   l_loc_lvl_indicator_id_mask varchar2(423) := p_loc_lvl_indicator_id_mask;
   l_attribute_id_mask         varchar2(83)  := p_attribute_id_mask;
   l_office_id_mask            varchar2(16)  := nvl(p_office_id_mask, cwms_util.user_office_id);
   l_location_id_mask          varchar2(49);
   l_parameter_id_mask         varchar2(49);
   l_param_type_id_mask        varchar2(16);
   l_duration_id_mask          varchar2(16);
   l_spec_level_id_mask        varchar2(256);
   l_level_indicator_id_mask   varchar2(32);
   l_attr_parameter_id_mask    varchar2(49);
   l_attr_param_type_id_mask   varchar2(16);
   l_attr_duration_id_mask     varchar2(16);
   l_cwms_office_code          number := cwms_util.get_office_code('CWMS');
   l_include_null_attrs        boolean := false;
begin
   if l_loc_lvl_indicator_id_mask is null or 
      l_loc_lvl_indicator_id_mask in ('%', '*')
   then
      l_loc_lvl_indicator_id_mask := nvl(p_loc_lvl_indicator_id_mask, '%.%.%.%.%.%');
   end if;
   if l_attribute_id_mask in ('%', '*')
   then
      l_attribute_id_mask := nvl(p_attribute_id_mask, '%.%.%');
   end if;
   if l_attribute_id_mask in ('%.%.%', '*.*.*')
   then
      l_include_null_attrs := true;
   end if;
   parse_loc_lvl_indicator_id(
      l_location_id_mask,
      l_parameter_id_mask,
      l_param_type_id_mask,
      l_duration_id_mask,
      l_spec_level_id_mask,
      l_level_indicator_id_mask,
      l_loc_lvl_indicator_id_mask);
   parse_attribute_id(      
      l_attr_parameter_id_mask,
      l_attr_param_type_id_mask,
      l_attr_duration_id_mask,
      l_attribute_id_mask);
   l_office_id_mask          := upper(cwms_util.normalize_wildcards(l_office_id_mask,          true));      
   l_location_id_mask        := upper(cwms_util.normalize_wildcards(l_location_id_mask,        true));      
   l_parameter_id_mask       := upper(cwms_util.normalize_wildcards(l_parameter_id_mask,       true));      
   l_param_type_id_mask      := upper(cwms_util.normalize_wildcards(l_param_type_id_mask,      true));      
   l_duration_id_mask        := upper(cwms_util.normalize_wildcards(l_duration_id_mask,        true));      
   l_spec_level_id_mask      := upper(cwms_util.normalize_wildcards(l_spec_level_id_mask,      true));      
   l_level_indicator_id_mask := upper(cwms_util.normalize_wildcards(l_level_indicator_id_mask, true));      
   l_attr_parameter_id_mask  := upper(cwms_util.normalize_wildcards(l_attr_parameter_id_mask,  true));      
   l_attr_param_type_id_mask := upper(cwms_util.normalize_wildcards(l_attr_param_type_id_mask, true));      
   l_attr_duration_id_mask   := upper(cwms_util.normalize_wildcards(l_attr_duration_id_mask,   true));
   
   if l_attribute_id_mask is null then
      open p_cursor for 
         select lli.level_indicator_code as level_indicator_code
           from at_loc_lvl_indicator lli,
                at_physical_location pl,
                at_base_location bl,
                cwms_office o,
                at_parameter p,
                cwms_base_parameter bp,
                cwms_parameter_type pt,
                cwms_duration d,
                at_specified_level sl
          where o.office_id like l_office_id_mask escape '\'
            and bl.db_office_code = o.office_code
            and upper(bl.base_location_id
                      || substr('-', 1, length(pl.sub_location_id))
                      || pl.sub_location_id) like l_location_id_mask escape '\'
            and pl.base_location_code = bl.base_location_code
            and lli.location_code = pl.location_code
            and upper(bp.base_parameter_id
                      || substr('-', 1, length(p.sub_parameter_id))
                      || p.sub_parameter_id) like l_parameter_id_mask escape '\'
            and bp.base_parameter_code = p.base_parameter_code
            and p.db_office_code in (o.office_code, l_cwms_office_code)
            and lli.parameter_code = p.parameter_code
            and upper(pt.parameter_type_id) like l_param_type_id_mask escape '\'
            and lli.parameter_type_code = pt.parameter_type_code
            and upper(d.duration_id) like l_duration_id_mask escape '\'
            and lli.duration_code = d.duration_code
            and upper(sl.specified_level_id) like l_spec_level_id_mask escape '\'
            and lli.specified_level_code = sl.specified_level_code
            and upper(lli.level_indicator_id) like l_level_indicator_id_mask escape '\'
            and lli.attr_parameter_code is null
       order by o.office_id,
                upper(bl.base_location_id
                      || substr('-', 1, length(pl.sub_location_id))
                      || pl.sub_location_id),         
                upper(bp.base_parameter_id
                      || substr('-', 1, length(p.sub_parameter_id))
                      || p.sub_parameter_id),
                upper(pt.parameter_type_id),
                upper(d.duration_id),
                upper(sl.specified_level_id),
                upper(lli.level_indicator_id);
   else   
      if l_include_null_attrs then
         open p_cursor for
            select level_indicator_code from ( 
               select lli.level_indicator_code as level_indicator_code,
                      o.office_id as office_id,
                      upper(bl.base_location_id
                            || substr('-', 1, length(pl.sub_location_id))
                            || pl.sub_location_id) as location_id,         
                      upper(bp.base_parameter_id
                            || substr('-', 1, length(p.sub_parameter_id))
                            || p.sub_parameter_id) as parameter_id,
                      upper(pt.parameter_type_id) as parameter_type_id,
                      upper(d.duration_id) as duration_id,
                      upper(sl.specified_level_id) as specified_level_id,
                      upper(lli.level_indicator_id) as level_indicator_id,
                      null as attr_parameter_id,
                      null as attr_parameter_type_id,
                      null as attr_duration_id
                  from at_loc_lvl_indicator lli,
                       at_physical_location pl,
                       at_base_location bl,
                       cwms_office o,
                       at_parameter p,
                       cwms_base_parameter bp,
                       cwms_parameter_type pt,
                       cwms_duration d,
                       at_specified_level sl
                 where o.office_id like l_office_id_mask escape '\'
                   and bl.db_office_code = o.office_code
                   and upper(bl.base_location_id
                             || substr('-', 1, length(pl.sub_location_id))
                             || pl.sub_location_id) like l_location_id_mask escape '\'
                   and pl.base_location_code = bl.base_location_code
                   and lli.location_code = pl.location_code
                   and upper(bp.base_parameter_id
                             || substr('-', 1, length(p.sub_parameter_id))
                             || p.sub_parameter_id) like l_parameter_id_mask escape '\'
                   and bp.base_parameter_code = p.base_parameter_code
                   and p.db_office_code in (o.office_code, l_cwms_office_code)
                   and lli.parameter_code = p.parameter_code
                   and upper(pt.parameter_type_id) like l_param_type_id_mask escape '\'
                   and lli.parameter_type_code = pt.parameter_type_code
                   and upper(d.duration_id) like l_duration_id_mask escape '\'
                   and lli.duration_code = d.duration_code
                   and upper(sl.specified_level_id) like l_spec_level_id_mask escape '\'
                   and lli.specified_level_code = sl.specified_level_code
                   and upper(lli.level_indicator_id) like l_level_indicator_id_mask escape '\'
                   and lli.attr_parameter_code is null
               union
               select distinct 
                      lli.level_indicator_code as level_indicator_code,
                      o.office_id as office_id,
                      upper(bl.base_location_id
                            || substr('-', 1, length(pl.sub_location_id))
                            || pl.sub_location_id) as location_id,         
                      upper(bp1.base_parameter_id
                            || substr('-', 1, length(p1.sub_parameter_id))
                            || p1.sub_parameter_id) as parameter_id,
                      upper(pt1.parameter_type_id) as parameter_type_id,
                      upper(d1.duration_id) as duration_id,
                      upper(sl.specified_level_id) as specified_level_id,
                      upper(lli.level_indicator_id) as level_indicator_id,
                      upper(bp2.base_parameter_id
                            || substr('-', 1, length(p2.sub_parameter_id))
                            || p2.sub_parameter_id) as attr_parameter_id,
                      upper(pt2.parameter_type_id) as attr_parameter_type_id,
                      upper(d2.duration_id) as attr_duration_id
                  from at_loc_lvl_indicator lli,
                       at_physical_location pl,
                       at_base_location bl,
                       cwms_office o,
                       at_parameter p1,
                       cwms_base_parameter bp1,
                       cwms_parameter_type pt1,
                       cwms_duration d1,
                       at_specified_level sl,
                       at_parameter p2,
                       cwms_base_parameter bp2,
                       cwms_parameter_type pt2,
                       cwms_duration d2
                 where o.office_id like l_office_id_mask escape '\'
                   and bl.db_office_code = o.office_code
                   and upper(bl.base_location_id
                             || substr('-', 1, length(pl.sub_location_id))
                             || pl.sub_location_id) like l_location_id_mask escape '\'
                   and pl.base_location_code = bl.base_location_code
                   and lli.location_code = pl.location_code
                   and upper(bp1.base_parameter_id
                             || substr('-', 1, length(p1.sub_parameter_id))
                             || p1.sub_parameter_id) like l_parameter_id_mask escape '\'
                   and bp1.base_parameter_code = p1.base_parameter_code
                   and p1.db_office_code in (o.office_code, l_cwms_office_code)
                   and lli.parameter_code = p1.parameter_code
                   and upper(pt1.parameter_type_id) like l_param_type_id_mask escape '\'
                   and lli.parameter_type_code = pt1.parameter_type_code
                   and upper(d1.duration_id) like l_duration_id_mask escape '\'
                   and lli.duration_code = d1.duration_code
                   and upper(sl.specified_level_id) like l_spec_level_id_mask escape '\'
                   and lli.specified_level_code = sl.specified_level_code
                   and upper(lli.level_indicator_id) like l_level_indicator_id_mask escape '\'
                   and upper(bp2.base_parameter_id
                             || substr('-', 1, length(p2.sub_parameter_id))
                             || p2.sub_parameter_id) like l_attr_parameter_id_mask escape '\'
                   and bp2.base_parameter_code = p2.base_parameter_code
                   and p2.db_office_code in (o.office_code, l_cwms_office_code)
                   and lli.attr_parameter_code = p2.parameter_code
                   and upper(pt2.parameter_type_id) like l_attr_param_type_id_mask escape '\'
                   and lli.attr_parameter_type_code = pt2.parameter_type_code
                   and upper(d2.duration_id) like l_attr_duration_id_mask escape '\'
                   and lli.attr_duration_code = d2.duration_code
              order by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
      else
         open p_cursor for 
            select distinct 
                   lli.level_indicator_code as level_indicator_code
              from at_loc_lvl_indicator lli,
                   at_physical_location pl,
                   at_base_location bl,
                   cwms_office o,
                   at_parameter p1,
                   cwms_base_parameter bp1,
                   cwms_parameter_type pt1,
                   cwms_duration d1,
                   at_specified_level sl,
                   at_parameter p2,
                   cwms_base_parameter bp2,
                   cwms_parameter_type pt2,
                   cwms_duration d2
             where o.office_id like l_office_id_mask escape '\'
               and bl.db_office_code = o.office_code
               and upper(bl.base_location_id
                         || substr('-', 1, length(pl.sub_location_id))
                         || pl.sub_location_id) like l_location_id_mask escape '\'
               and pl.base_location_code = bl.base_location_code
               and lli.location_code = pl.location_code
               and upper(bp1.base_parameter_id
                         || substr('-', 1, length(p1.sub_parameter_id))
                         || p1.sub_parameter_id) like l_parameter_id_mask escape '\'
               and bp1.base_parameter_code = p1.base_parameter_code
               and p1.db_office_code in (o.office_code, l_cwms_office_code)
               and lli.parameter_code = p1.parameter_code
               and upper(pt1.parameter_type_id) like l_param_type_id_mask escape '\'
               and lli.parameter_type_code = pt1.parameter_type_code
               and upper(d1.duration_id) like l_duration_id_mask escape '\'
               and lli.duration_code = d1.duration_code
               and upper(sl.specified_level_id) like l_spec_level_id_mask escape '\'
               and lli.specified_level_code = sl.specified_level_code
               and upper(lli.level_indicator_id) like l_level_indicator_id_mask escape '\'
               and upper(bp2.base_parameter_id
                         || substr('-', 1, length(p2.sub_parameter_id))
                         || p2.sub_parameter_id) like l_attr_parameter_id_mask escape '\'
               and bp2.base_parameter_code = p2.base_parameter_code
               and p2.db_office_code in (o.office_code, l_cwms_office_code)
               and lli.attr_parameter_code = p2.parameter_code
               and upper(pt2.parameter_type_id) like l_attr_param_type_id_mask escape '\'
               and lli.attr_parameter_type_code = pt2.parameter_type_code
               and upper(d2.duration_id) like l_attr_duration_id_mask escape '\'
               and lli.attr_duration_code = d2.duration_code
          order by o.office_id,
                   upper(bl.base_location_id
                         || substr('-', 1, length(pl.sub_location_id))
                         || pl.sub_location_id),         
                   upper(bp1.base_parameter_id
                         || substr('-', 1, length(p1.sub_parameter_id))
                         || p1.sub_parameter_id),
                   upper(pt1.parameter_type_id),
                   upper(d1.duration_id),
                   upper(sl.specified_level_id),
                   upper(lli.level_indicator_id),
                   upper(bp2.base_parameter_id
                         || substr('-', 1, length(p2.sub_parameter_id))
                         || p2.sub_parameter_id),
                   upper(pt2.parameter_type_id),
                   upper(d2.duration_id);
      end if;             
   end if;
                          
end cat_loc_lvl_indicator_codes;   

--------------------------------------------------------------------------------
-- FUNCTION cat_loc_lvl_indicator_codes
--
-- The returned cursor contains only the matching location_level_code
--
--------------------------------------------------------------------------------
function cat_loc_lvl_indicator_codes(
   p_loc_lvl_indicator_id_mask in  varchar2 default null, -- '%.%.%.%.%.%' if null
   p_attribute_id_mask         in  varchar2 default null,
   p_office_id_mask            in  varchar2 default null) -- user's office if null
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_loc_lvl_indicator_codes(
      l_cursor,
      p_loc_lvl_indicator_id_mask,
      p_attribute_id_mask,
      p_office_id_mask);
      
   return l_cursor;      
end cat_loc_lvl_indicator_codes;      

--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator
--
-- Retrieves a cursor of Location Level Indicators and associated Conditions
-- that match the input masks
--
-- p_location_level_id_mask - Location Level Identifier that can contain SQL
-- wildcards (%, _) or filename wildcards (*, ?), cannot be NULL
--
-- p_attribute_id_mask - Attribute Identifier that can contain wildcards, cannot
-- be NULL
--
-- p_office_id_mask - Office Identifier that can contain wildcards, if NULL, the
-- user's office id is used
--
-- p_unit_system is 'EN' or 'SI'
--
-- p_cursor contains 18 fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(256)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       interval day(3) to second(0)
--  15 : maximum_age            interval day(3) to second(0)
--  16 : ref_specified_level_id varchar2(256)
--  17 : ref_attribute_value    number
--  18 : conditions             sys_refcursor
--
-- The cursor returned in field 18 contains 17 fields:
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day(3) to second(0)
--  17 : description                 varchar2(256)  
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI')
is
   l_location_id_mask            varchar2(49);
   l_parameter_id_mask           varchar2(49);
   l_parameter_type_id_mask      varchar2(16);
   l_duration_id_mask            varchar2(16);
   l_specified_level_id_mask     varchar2(256);
   l_attr_parameter_id_mask      varchar2(49);
   l_attr_parameter_type_id_mask varchar2(16);
   l_attr_duration_id_mask       varchar2(16);
   l_office_id_mask              varchar2(16) := cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id), true);
   l_cwms_office_code            number(10)   := cwms_util.get_office_code('CWMS');
begin
   cwms_level.parse_location_level_id(
      l_location_id_mask,
      l_parameter_id_mask,
      l_parameter_type_id_mask,
      l_duration_id_mask,
      l_specified_level_id_mask,
      cwms_util.normalize_wildcards(p_location_level_id_mask, true));
   cwms_level.parse_attribute_id(
      l_attr_parameter_id_mask,
      l_attr_parameter_type_id_mask,
      l_attr_duration_id_mask,
      cwms_util.normalize_wildcards(p_attribute_id_mask, true));
            
   open p_cursor for
      with 
         indicator as 
         (select o.office_id as office_id,
                 bl.base_location_id
                 || substr('-', 1, length(pl.sub_location_id))
                 || pl.sub_location_id as location_id,
                 bp.base_parameter_id
                 || substr('-', 1, length(p.sub_parameter_id))
                 || p.sub_parameter_id as parameter_id,
                 pt.parameter_type_id as parameter_type_id,
                 d.duration_id as duration_id,
                 sl.specified_level_id as specified_level_id,
                 lli.level_indicator_code as level_indicator_code,
                 lli.level_indicator_id as level_indicator_id,
                 lli.minimum_duration as minimum_duration,
                 lli.maximum_age as maximum_age,
                 lli.attr_parameter_code as attr_parameter_code,
                 lli.attr_parameter_type_code as attr_parameter_type_code,
                 lli.attr_duration_code as attr_duration_code,
                 lli.attr_value as attr_value,
                 lli.ref_specified_level_code as ref_specified_level_code,
                 lli.ref_attr_value as ref_attr_value
            from at_loc_lvl_indicator lli,
                 at_physical_location pl,
                 at_base_location bl,
                 cwms_office o,
                 at_parameter p,
                 cwms_base_parameter bp,
                 cwms_parameter_type pt,
                 cwms_duration d,
                 at_specified_level sl,
                 cwms_unit_conversion cuc
           where upper(o.office_id) like upper(l_office_id_mask) escape '\'
             and upper(bl.base_location_id
                       || substr('-', 1, length(pl.sub_location_id))
                       || pl.sub_location_id) like upper(l_location_id_mask) escape '\'
             and upper(bp.base_parameter_id
                       || substr('-', 1, length(p.sub_parameter_id))
                       ||p.sub_parameter_id) like upper(l_parameter_id_mask) escape '\'
             and upper(pt.parameter_type_id) like upper(l_parameter_type_id_mask) escape '\'
             and upper(d.duration_id) like upper(l_duration_id_mask) escape '\'
             and upper(sl.specified_level_id) like upper(l_specified_level_id_mask) escape '\'
             and bl.db_office_code = o.office_code
             and pl.base_location_code = bl.base_location_code
             and lli.location_code = pl.location_code
             and p.base_parameter_code = bp.base_parameter_code
             and (p.db_office_code = o.office_code or p.db_office_code = l_cwms_office_code)
             and lli.parameter_code = p.parameter_code
             and lli.parameter_type_code = pt.parameter_type_code
             and lli.duration_code = d.duration_code
             and lli.specified_level_code = sl.specified_level_code
             and cuc.from_unit_id = cwms_util.get_default_units(bp.base_parameter_id)
             and cuc.to_unit_id = cwms_util.get_default_units(bp.base_parameter_id, p_unit_system)
         ),
         attr_param as  
         (select bp.base_parameter_id
                 || substr('-', 1, length(p.sub_parameter_id))
                 || p.sub_parameter_id as attr_parameter_id,
                 p.parameter_code,
                 cuc.offset as offset,
                 cuc.factor as factor
            from cwms_office o,
                 at_parameter p,
                 cwms_base_parameter bp,
                 cwms_unit_conversion cuc
           where upper(o.office_id) like upper(l_office_id_mask) escape '\'
             and upper(bp.base_parameter_id) like upper(cwms_util.get_base_id(l_attr_parameter_id_mask)) escape '\'
             and upper(nvl(p.sub_parameter_id, '.')) like upper(nvl(cwms_util.get_sub_id(l_attr_parameter_id_mask), '.')) escape '\'
             and p.base_parameter_code = bp.base_parameter_code
             and (p.db_office_code = o.office_code or p.db_office_code = l_cwms_office_code)
             and cuc.from_unit_id = cwms_util.get_default_units(bp.base_parameter_id)
             and cuc.to_unit_id = cwms_util.get_default_units(bp.base_parameter_id, p_unit_system)
         ),
         attr_param_type as
         (select parameter_type_code,
                 parameter_type_id as attr_parameter_type_id
            from cwms_parameter_type
           where upper(parameter_type_id) like upper(l_attr_parameter_type_id_mask) escape '\'
         ),
         attr_duration as
         (select duration_code,
                 duration_id as attr_duration_id
            from cwms_duration
           where upper(duration_id) like upper(l_attr_duration_id_mask) escape '\'
         ),
         ref as    
         (select specified_level_code,
                 specified_level_id as ref_specified_level_id
            from at_specified_level
         )
      select office_id,
             location_id,
             parameter_id,
             parameter_type_id,
             duration_id,
             specified_level_id,
             level_indicator_id,
             cwms_util.get_default_units(parameter_id, p_unit_system) as level_units_id,
             attr_parameter_id,
             attr_parameter_type_id,
             attr_duration_id,
             cwms_util.get_default_units(attr_parameter_id, p_unit_system) as attr_units_id,
             round(attr_value * attr_param.factor + attr_param.offset, 10 - trunc(log(10, attr_value * attr_param.factor + attr_param.offset))) as attr_value,
             minimum_duration,
             maximum_age,
             ref_specified_level_id,
             round(ref_attr_value * attr_param.factor + attr_param.offset, 10 - trunc(log(10, ref_attr_value * attr_param.factor + attr_param.offset))) as ref_attr_value,
                 cursor (
                    select level_indicator_value,
                           expression,
                           comparison_operator_1,
                           comparison_value_1,
                           comparison_unit_id,
                           connector,
                           comparison_operator_2,
                           comparison_value_2,
                           rate_expression,
                           rate_comparison_operator_1,
                           rate_comparison_value_1,
                           rate_comparison_unit_id,
                           rate_connector,
                           rate_comparison_operator_2,
                           rate_comparison_value_2,
                           rate_interval,
                           description
                      from (select level_indicator_code,
                                   level_indicator_value,
                                   expression,
                                   comparison_operator_1,
                                   comparison_value_1,
                                   comparison_unit,
                                   connector,
                                   comparison_operator_2,
                                   comparison_value_2,
                                   rate_expression,
                                   rate_comparison_operator_1,
                                   rate_comparison_value_1,
                                   rate_comparison_unit,
                                   rate_connector,
                                   rate_comparison_operator_2,
                                   rate_comparison_value_2,
                                   rate_interval,
                                   description
                              from at_loc_lvl_indicator_cond
                           ) cond
                           left outer join
                           (select unit_code,
                                   unit_id as comparison_unit_id
                              from cwms_unit
                           ) unit
                           on unit.unit_code = cond.comparison_unit
                           left outer join
                           (select unit_code,
                                   unit_id as rate_comparison_unit_id
                              from cwms_unit
                           ) rate_unit
                           on rate_unit.unit_code = cond.rate_comparison_unit
                     where level_indicator_code = indicator.level_indicator_code
                  order by level_indicator_value
                 ) as conditions
        from ((((indicator left outer join attr_param
                 on attr_param.parameter_code = indicator.attr_parameter_code
                ) left outer join attr_param_type
                on attr_param_type.parameter_type_code = indicator.attr_parameter_type_code
               ) left outer join attr_duration
               on attr_duration.duration_code = indicator.attr_duration_code
              ) left outer join ref
              on ref.specified_level_code = indicator.ref_specified_level_code
             )
    order by office_id,
             location_id,
             parameter_id,
             parameter_type_id,
             duration_id,
             specified_level_id,
             level_indicator_id,
             attr_parameter_id,
             attr_parameter_type_id,
             attr_duration_id,
             ref_specified_level_id;             
end cat_loc_lvl_indicator;   

--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator2
--
-- Retrieves a cursor of Location Level Indicators and associated Conditions
-- that match the input masks and contains only text and numeric fields
--
-- p_location_level_id_mask - Location Level Identifier that can contain SQL
-- wildcards (%, _) or filename wildcards (*, ?), cannot be NULL
--
-- p_attribute_id_mask - Attribute Identifier that can contain wildcards, cannot
-- be NULL
--
-- p_office_id_mask - Office Identifier that can contain wildcards, if NULL, the
-- user's office id is used
--
-- p_unit_system is 'EN' or 'SI'
--
-- p_cursor contains 18 fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(256)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       varchar2(12)
--  15 : maximum_age            varchar2(12)
--  16 : ref_specified_level_id varchar2(256)
--  17 : ref_attribute_value    number
--  18 : conditions             varchar2(4096)
--
-- Fields 14 and 15 are in the format 'ddd hh:mm:ss'
--
-- The character string returned in field 18 contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2(12)
--  17 : description                 varchar2(256)  
--
-- Field 16 is in the format 'ddd hh:mm:ss'
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator2(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI')
is
   l_cursor                      sys_refcursor;
   l_parts                       str_tab_tab_t := str_tab_tab_t();
   l_seq                         integer;
   l_office_id                   varchar2(16);
   l_location_id                 varchar2(49);
   l_parameter_id                varchar2(49);
   l_parameter_type_id           varchar2(16);
   l_duration_id                 varchar2(16);
   l_specified_level_id          varchar2(256);
   l_level_indicator_id          varchar2(32);
   l_level_units_id              varchar2(16);
   l_attr_parameter_id           varchar2(49);
   l_attr_parameter_type_id      varchar2(16);
   l_attr_duration_id            varchar2(16);
   l_attr_units_id               varchar2(16);
   l_attr_value                  number;
   l_minimum_duration            interval day(3) to second(0);
   l_maximum_age                 interval day(3) to second(0);
   l_rate_of_change              varchar2(1);
   l_ref_specified_level_id      varchar2(256);
   l_ref_attribute_value         number;
   l_conditions                  sys_refcursor;
   l_conditions_txt              varchar2(4096);
   l_indicator_value             integer;
   l_expression                  varchar2(64);
   l_comparison_operator_1       varchar2(2);
   l_comparison_value_1          binary_double;
   l_comparison_unit_id          varchar2(16);
   l_connector                   varchar2(3);
   l_comparison_operator_2       varchar2(2);
   l_comparison_value_2          binary_double;
   l_rate_expression             varchar2(64);
   l_rate_comparison_operator_1  varchar2(2);
   l_rate_comparison_value_1     binary_double;
   l_rate_comparison_unit_id     varchar2(16);
   l_rate_connector              varchar2(3);
   l_rate_comparison_operator_2  varchar2(2);
   l_rate_comparison_value_2     binary_double;
   l_rate_interval               interval day(3) to second(0);
   l_description                 varchar2(256);
   l_rs                          varchar2(1) := chr(30);
   l_gs                          varchar2(1) := chr(29);
begin
   delete from at_loc_lvl_indicator_tab;
   cat_loc_lvl_indicator(
      l_cursor,
      p_location_level_id_mask,
      p_attribute_id_mask,
      p_office_id_mask,
      p_unit_system);
   loop
      fetch l_cursor 
       into l_office_id,
            l_location_id,
            l_parameter_id,
            l_parameter_type_id,
            l_duration_id,
            l_specified_level_id,
            l_level_indicator_id,
            l_level_units_id,
            l_attr_parameter_id,
            l_attr_parameter_type_id,
            l_attr_duration_id,
            l_attr_units_id,
            l_attr_value,
            l_minimum_duration,
            l_maximum_age,
            l_ref_specified_level_id,
            l_ref_attribute_value,
            l_conditions;
      exit when l_cursor%notfound;
      l_parts.delete; 
      loop
         fetch l_conditions
               into l_indicator_value,
                    l_expression,
                    l_comparison_operator_1,
                    l_comparison_value_1,
                    l_comparison_unit_id,
                    l_connector,
                    l_comparison_operator_2,
                    l_comparison_value_2,
                    l_rate_expression,
                    l_rate_comparison_operator_1,
                    l_rate_comparison_value_1,
                    l_rate_comparison_unit_id,
                    l_rate_connector,
                    l_rate_comparison_operator_2,
                    l_rate_comparison_value_2,
                    l_rate_interval,
                    l_description;
         exit when l_conditions%notfound;
         l_parts.extend;
         l_parts(l_conditions%rowcount) := str_tab_t();
         l_parts(l_conditions%rowcount).extend(17);
         l_parts(l_conditions%rowcount)( 1) := to_char(l_indicator_value);               
         l_parts(l_conditions%rowcount)( 2) := l_expression;               
         l_parts(l_conditions%rowcount)( 3) := l_comparison_operator_1;               
         l_parts(l_conditions%rowcount)( 4) := to_char(l_comparison_value_1);               
         l_parts(l_conditions%rowcount)( 5) := l_comparison_unit_id;               
         l_parts(l_conditions%rowcount)( 6) := l_connector;               
         l_parts(l_conditions%rowcount)( 7) := l_comparison_operator_2;               
         l_parts(l_conditions%rowcount)( 8) := to_char(l_comparison_value_2);               
         l_parts(l_conditions%rowcount)( 9) := l_rate_expression;               
         l_parts(l_conditions%rowcount)(10) := l_rate_comparison_operator_1;               
         l_parts(l_conditions%rowcount)(11) := to_char(l_rate_comparison_value_1);               
         l_parts(l_conditions%rowcount)(12) := l_rate_comparison_unit_id;               
         l_parts(l_conditions%rowcount)(13) := l_rate_connector;               
         l_parts(l_conditions%rowcount)(14) := l_rate_comparison_operator_2;               
         l_parts(l_conditions%rowcount)(15) := to_char(l_rate_comparison_value_2);               
         l_parts(l_conditions%rowcount)(16) := substr(to_char(l_rate_interval), 2);               
         l_parts(l_conditions%rowcount)(17) := l_description;               
      end loop;
      close l_conditions;
      l_conditions_txt := '';
      for i in 1..l_parts.count loop
         if i > 1 then
            l_conditions_txt := l_conditions_txt || l_rs;
         end if;
         for j in 1..l_parts(i).count loop
            if j > 1 then
               l_conditions_txt := l_conditions_txt || l_gs;
            end if;
            l_conditions_txt := l_conditions_txt || l_parts(i)(j);
         end loop;            
      end loop;
      l_seq := l_cursor%rowcount;
      insert
        into at_loc_lvl_indicator_tab
      values (l_seq,
              l_office_id,
              l_location_id,
              l_parameter_id,
              l_parameter_type_id,
              l_duration_id,
              l_specified_level_id,
              l_level_indicator_id,
              l_level_units_id,
              l_attr_parameter_id,
              l_attr_parameter_type_id,
              l_attr_duration_id,
              l_attr_units_id,
              l_attr_value,
              to_char(l_minimum_duration),            
              to_char(l_maximum_age),
              l_rate_of_change,
              l_ref_specified_level_id,
              l_ref_attribute_value,
              l_conditions_txt);            
   end loop;
   close l_cursor;
   open p_cursor for
      select *
        from at_loc_lvl_indicator_tab
    order by seq;
end cat_loc_lvl_indicator2;   

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_indicator
--
-- Retrieves a Location Level Indicator and its associated Conditions
--
-- The cursor returned in p_conditions contains 17 fields:
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day(3) to second(0)
--  17 : description                 varchar2(256)  
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_indicator(
   p_minimum_duration       out interval day to second,
   p_maximum_age            out interval day to second,
   p_conditions             out sys_refcursor,
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is
   l_loc_lvl_indicator_code number(10);
   l_level_factor           number := 1.;
   l_level_offset           number := 0.;
   l_location_id            varchar2(49);
   l_parameter_id           varchar2(49);
   l_parameter_type_id      varchar2(16);
   l_duration_id            varchar2(16);
   l_specified_level_id     varchar2(256);
   l_level_indicator_id     varchar2(32);
begin
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
      
      if p_level_units_id is not null then
         cwms_level.parse_loc_lvl_indicator_id(
            l_location_id,
            l_parameter_id,
            l_parameter_type_id,
            l_duration_id,
            l_specified_level_id,
            l_level_indicator_id,
            p_loc_lvl_indicator_id);
         select factor,
                offset
           into l_level_factor,
                l_level_offset
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_default_units(l_parameter_id)
            and to_unit_id = p_level_units_id;
      end if;
      select minimum_duration,
             maximum_age,
             conditions
        into p_minimum_duration,
             p_maximum_age,
             p_conditions             
        from (select lli.minimum_duration as minimum_duration,
                     lli.maximum_age as maximum_age,
                     cursor (
                        select level_indicator_value,
                                expression,
                                comparison_operator_1,
                                comparison_value_1,
                                comparison_unit_id,
                                connector,
                                comparison_operator_2,
                                comparison_value_2,
                                rate_expression,
                                rate_comparison_operator_1,
                                rate_comparison_value_1,
                                rate_comparison_unit_id,
                                rate_connector,
                                rate_comparison_operator_2,
                                rate_comparison_value_2,
                                rate_interval,
                                description
                           from ((select level_indicator_value,
                                          expression,
                                          comparison_operator_1,
                                          comparison_value_1,
                                          comparison_unit,
                                          connector,
                                          comparison_operator_2,
                                          comparison_value_2,
                                          rate_expression,
                                          rate_comparison_operator_1,
                                          rate_comparison_value_1,
                                          rate_comparison_unit,
                                          rate_connector,
                                          rate_comparison_operator_2,
                                          rate_comparison_value_2,
                                          rate_interval,
                                          description
                                     from at_loc_lvl_indicator_cond
                                 ) cond
                                 left outer join
                                 (select unit_code,
                                         unit_id as comparison_unit_id
                                    from cwms_unit
                                 ) unit
                                 on unit.unit_code = cond.comparison_unit
                                )
                                left outer join
                                (select unit_code,
                                        unit_id as rate_comparison_unit_id
                                   from cwms_unit
                                ) rate_unit
                                on rate_unit.unit_code = cond.rate_comparison_unit
                          where level_indicator_code = lli.level_indicator_code
                       order by level_indicator_value) as conditions
                from at_loc_lvl_indicator lli
               where lli.level_indicator_code = l_loc_lvl_indicator_code);
                
end retrieve_loc_lvl_indicator;   

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_indicator2
--
-- Retrieves a Location Level Indicator and its associated Conditions and uses
-- only text and numeric fields
--
-- p_minimum_duration is in the format 'ddd hh:mm:ss'
--
-- p_maximum_age is in the format 'ddd hh:mm:ss'
--
-- The character string returned in p_conditions contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2(12)
--  17 : description                 varchar2(256)  
--
-- Field 16 is in the format 'ddd hh:mm:ss'
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_indicator2(
   p_minimum_duration       out varchar2, -- 'ddd hh:mi:ss'
   p_maximum_age            out varchar2, -- 'ddd hh:mi:ss'
   p_conditions             out varchar2,
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is
   l_minimum_duration            interval day(3) to second(0);
   l_maximum_age                 interval day(3) to second(0);
   l_parts                       str_tab_tab_t;
   l_conditions                  sys_refcursor;
   l_conditions_txt              varchar2(4096);
   l_indicator_value             integer;
   l_expression                  varchar2(64);
   l_comparison_operator_1       varchar2(2);
   l_comparison_value_1          binary_double;
   l_comparison_unit_id          varchar2(16);
   l_connector                   varchar2(3);
   l_comparison_operator_2       varchar2(2);
   l_comparison_value_2          binary_double;
   l_rate_expression             varchar2(64);
   l_rate_comparison_operator_1  varchar2(2);
   l_rate_comparison_value_1     binary_double;
   l_rate_comparison_unit_id     varchar2(16);
   l_rate_connector              varchar2(3);
   l_rate_comparison_operator_2  varchar2(2);
   l_rate_comparison_value_2     binary_double;
   l_rate_interval               interval day(3) to second(0);
   l_description                 varchar2(256);
   l_rs                          varchar2(1) := chr(30);
   l_gs                          varchar2(1) := chr(29);
begin
   retrieve_loc_lvl_indicator(
      l_minimum_duration,
      l_maximum_age,
      l_conditions,
      p_loc_lvl_indicator_id,
      p_level_units_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
      
   p_minimum_duration := substr(to_char(l_minimum_duration), 2);      
   p_maximum_age      := substr(to_char(l_maximum_age), 2);      
   loop
      fetch l_conditions
            into l_indicator_value,
                 l_expression,
                 l_comparison_operator_1,
                 l_comparison_value_1,
                 l_comparison_unit_id,
                 l_connector,
                 l_comparison_operator_2,
                 l_comparison_value_2,
                 l_rate_expression,
                 l_rate_comparison_operator_1,
                 l_rate_comparison_value_1,
                 l_rate_comparison_unit_id,
                 l_rate_connector,
                 l_rate_comparison_operator_2,
                 l_rate_comparison_value_2,
                 l_rate_interval,
                 l_description;
      exit when l_conditions%notfound;
      l_parts.extend;
      l_parts(l_conditions%rowcount).extend(17);
      l_parts(l_conditions%rowcount)( 1) := to_char(l_indicator_value);               
      l_parts(l_conditions%rowcount)( 2) := l_expression;               
      l_parts(l_conditions%rowcount)( 3) := l_comparison_operator_1;               
      l_parts(l_conditions%rowcount)( 4) := to_char(l_comparison_value_1);               
      l_parts(l_conditions%rowcount)( 5) := l_comparison_unit_id;               
      l_parts(l_conditions%rowcount)( 6) := l_connector;               
      l_parts(l_conditions%rowcount)( 7) := l_comparison_operator_2;               
      l_parts(l_conditions%rowcount)( 8) := to_char(l_comparison_value_2);               
      l_parts(l_conditions%rowcount)( 9) := l_rate_expression;               
      l_parts(l_conditions%rowcount)(10) := l_rate_comparison_operator_1;               
      l_parts(l_conditions%rowcount)(11) := to_char(l_rate_comparison_value_1);               
      l_parts(l_conditions%rowcount)(12) := l_rate_comparison_unit_id;               
      l_parts(l_conditions%rowcount)(13) := l_rate_connector;               
      l_parts(l_conditions%rowcount)(14) := l_rate_comparison_operator_2;               
      l_parts(l_conditions%rowcount)(15) := to_char(l_rate_comparison_value_2);               
      l_parts(l_conditions%rowcount)(16) := substr(to_char(l_rate_interval), 2);               
      l_parts(l_conditions%rowcount)(17) := l_description;               
   end loop;
   close l_conditions;
   l_conditions_txt := '';
   for i in 1..l_parts.count loop
      if i > 1 then
         l_conditions_txt := l_conditions_txt || l_rs;
      end if;
      for j in 1..l_parts(i).count loop
         if j > 1 then
            l_conditions_txt := l_conditions_txt || l_gs;
         end if;
         l_conditions_txt := l_conditions_txt || l_parts(i)(j);
      end loop;            
   end loop;
   p_conditions := l_conditions_txt;
end retrieve_loc_lvl_indicator2;   

--------------------------------------------------------------------------------
-- FUNCTION retrieve_loc_lvl_indicator 
--
-- Returns a Location Level Indicator and its associated Conditions in a
-- LOC_LVL_INDICATOR_T object
--------------------------------------------------------------------------------
function retrieve_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return loc_lvl_indicator_t
is
   l_loc_lvl_indicator_code number(10);
   l_row_id                 urowid;
   l_obj                    loc_lvl_indicator_t;
begin
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);

   select rowid
     into l_row_id
     from at_loc_lvl_indicator
    where level_indicator_code = l_loc_lvl_indicator_code;

   l_obj := loc_lvl_indicator_t(l_row_id);
   return l_obj;
             
end retrieve_loc_lvl_indicator;   

--------------------------------------------------------------------------------
-- PROCEDURE delete_loc_lvl_indicator
--
-- Deletes a Location Level Indicator and its associated Conditions
--------------------------------------------------------------------------------
procedure delete_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is
   l_loc_lvl_indicator_code number(10);
begin
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
      
   delete
     from at_loc_lvl_indicator_cond
    where level_indicator_code = l_loc_lvl_indicator_code;      
      
   delete
     from at_loc_lvl_indicator
    where level_indicator_code = l_loc_lvl_indicator_code;      
end delete_loc_lvl_indicator;   

--------------------------------------------------------------------------------
-- PROCEDURE get_level_indicator_values
--
-- Retreieves the values for all Location Level Indicator Conditions that are
-- set at p_eval_time and that match the input parameters.  Each indicator may
-- have multiple condions set.
--
-- p_tsid - time series identifier, p_cursor will only include Conditions for 
-- Location Levels that have the same Location, Parameter, and Parameter Type
-- 
-- p_eval_time - evaluation time, current time if NULL
--
-- p_time_zone - time zone of p_eval_time, 'UTC' if NULL
--
-- p_specified_level_mask - Specified Level Indicator with optional SQL
-- wildcards (%, _) or filename wildcards (*, ?), '%' if NULL
--
-- p_indicator_id_mask - Location Level Identifier with optional wildcards, '%'
-- if NULL
--
-- p_unit_system - unit system for which to retrieve attribute values, 'EN' or 
-- 'SI', 'SI' if NULL
--
-- p_office_id - office identifier for p_tsid, user's office identifier if NULL
-- 
-- p_cursor contains the following fields:
-- 1 indicator_id     varchar2(423)
-- 2 attribute_id     varchar2(83)
-- 3 attribute_value  number           
-- 4 attribute_units  varchar2(16)
-- 5 indicator_values number_tab_t
--------------------------------------------------------------------------------
procedure get_level_indicator_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_eval_time            in  date     default null,   -- sysdate if null
   p_time_zone            in  varchar2 default null,   -- 'UTC' if null
   p_specified_level_mask in  varchar2 default null,   -- '%' if null
   p_indicator_id_mask    in  varchar2 default null,   -- '%' if null
   p_unit_system          in  varchar2 default null,   -- 'SI' if null
   p_office_id            in  varchar2 default null)   -- user's office if null 
is
   l_tsid                   varchar2(183) := replace(p_tsid, '\%', '%');
   l_office_id              varchar2(16)  := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_specified_level_mask   varchar2(256) := nvl(p_specified_level_mask, '%');
   l_indicator_id_mask      varchar2(256) := nvl(p_indicator_id_mask, '%');
   l_location_level_id_mask varchar2(423);
   l_base_location_id       varchar2(16);
   l_sub_location_id        varchar2(32);
   l_base_parameter_id      varchar2(16);
   l_sub_parameter_id       varchar2(32);
   l_parameter_type_id      varchar2(16);
   l_interval_id            varchar2(16);
   l_duration_id            varchar2(16);
   l_version_id             varchar2(32);
   l_indicator_codes_crsr   sys_refcursor;
   l_ts_crsr                sys_refcursor;
   l_indicator_code         number(10);
   l_rowid                  rowid;
   l_loc_lvl_objs           loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
   l_ts_units               varchar2(16);
   l_start_time             timestamp;
   l_end_time               timestamp;
   l_ts_date_time           date;
   l_ts_value               binary_double;
   l_ts_quality             number;
   l_ts                     ztsv_array := new ztsv_array();
begin
   ------------------------------------------------------------------
   -- open a cursor of all matching location level indicator codes --
   ------------------------------------------------------------------
   cwms_ts.parse_ts(
      l_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   l_indicator_codes_crsr := cat_loc_lvl_indicator_codes(
      get_loc_lvl_indicator_id(
         l_base_location_id
            || substr('-', 1, length(l_sub_location_id))
            || l_sub_location_id,
         l_base_parameter_id
            || substr('-', 1, length(l_sub_parameter_id))
            || l_sub_parameter_id,
         l_parameter_type_id,
         l_duration_id,
         l_specified_level_mask,
         l_indicator_id_mask),
      '%.%.%',
      l_office_id);
   --------------------------------------------------               
   -- build a table of loc_lvl_indicator_t objects --
   --------------------------------------------------
   loop
      fetch l_indicator_codes_crsr into l_indicator_code;
      exit when l_indicator_codes_crsr%notfound;
      select rowid 
        into l_rowid
        from at_loc_lvl_indicator 
       where level_indicator_code = l_indicator_code;   
      l_loc_lvl_objs.extend;
      l_loc_lvl_objs(l_loc_lvl_objs.count) := new loc_lvl_indicator_t(l_rowid);
   end loop;
   close l_indicator_codes_crsr;
   -------------------------------------
   -- compute the start and end times --
   -------------------------------------
   if p_eval_time is null then
      l_end_time := systimestamp at time zone 'UTC';
   else
      l_end_time := from_tz(cast(p_eval_time as timestamp), nvl(p_time_zone, 'UTC')) at time zone 'UTC';
   end if;
   select min(l_end_time-minimum_duration-maximum_age)
     into l_start_time
     from table(l_loc_lvl_objs);
   ------------------------------               
   -- retrieve the time series --
   ------------------------------               
   l_ts_units := cwms_util.get_default_units(l_base_parameter_id);
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_ts_crsr,
      p_cwms_ts_id      => l_tsid,
      p_units           => l_ts_units,
      p_start_time      => cast(l_start_time as date),
      p_end_time        => cast(l_end_time as date),
      p_time_zone       => 'UTC',
      p_trim            => 'F',
      p_start_inclusive => 'T',
      p_end_inclusive   => 'T',
      p_previous        => 'T',
      p_next            => 'F',
      p_version_date    => null,
      p_max_version     => 'T',
      p_office_id       => l_office_id);
   loop
      fetch l_ts_crsr into l_ts_date_time, l_ts_value, l_ts_quality;
      exit when l_ts_crsr%notfound;
      l_ts.extend;
      l_ts(l_ts.count) := ztsv_type(l_ts_date_time, l_ts_value, l_ts_quality);   
   end loop;
   close l_ts_crsr;
   /*
   cwms_msg.log_db_message('z', 7, 'retrieved '||l_ts.count||' values from '||p_tsid);
   for i in 1..l_ts.count loop
      cwms_msg.log_db_message('z', 7, ''||i||' = ('||l_ts(i).date_time||', '||l_ts(i).value||')');
   end loop;
   */
   -----------------------                     
   -- return the cursor --
   -----------------------
   open p_cursor for
      select get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id) as indicator_id,
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id) as attribute_id,
             round(o.attr_value * cuc.factor + cuc.offset, 10 - trunc(log(10, o.attr_value * cuc.factor + cuc.offset))) as attribute_value,
             cuc.to_unit_id as attribute_units,
             o.get_indicator_values(
                l_ts,
                l_end_time) as indicator_values
        from table(l_loc_lvl_objs) o,
             cwms_unit_conversion cuc
       where cuc.from_unit_id = nvl(
                o.attr_units_id, 
                cwms_util.get_default_units
                   (nvl(o.attr_parameter_id, o.parameter_id), 
                   p_unit_system))
         and cuc.to_unit_id = cwms_util.get_default_units(
                nvl(o.attr_parameter_id, o.parameter_id), 
                p_unit_system)
    order by get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id),
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id),
             o.attr_value;
end get_level_indicator_values;    

--------------------------------------------------------------------------------
-- PROCEDURE get_level_indicator_max_values
--
-- Retrieves a time series of the maximum Condition value that is set for each 
-- Location Level Indicator that matches the input parameters.  Each time series 
-- has the same times as the time series defined by p_tsid, p_start_time and
-- p_end_time.  Each date_time in the time series is in the specified time
-- zone. The quality_code of each time series value is set to zero.
--
-- p_tsid - time series identifier, p_cursor will only include Conditions for 
-- Location Levels that have the same Location, Parameter, and Parameter Type
-- 
-- p_start_time - start of the time window for p_tsid, in p_time_zone
-- 
-- p_end_time - end of the time window for p_tsid, in p_time_zone
--
-- p_time_zone - time zone of p_start_time, p_end_time and the date_times of the
-- retrieved time series, 'UTC' if NULL
--
-- p_specified_level_mask - Specified Level Indicator with optional SQL
-- wildcards (%, _) or filename wildcards (*, ?), '%' if NULL
--
-- p_indicator_id_mask - Location Level Identifier with optional wildcards, '%'
-- if NULL
--
-- p_unit_system - unit system for which to retrieve attribute values, 'EN' or 
-- 'SI', 'SI' if NULL
--
-- p_office_id - office identifier for p_tsid, user's office identifier if NULL
-- 
-- p_cursor has the following fields:
-- 1 indicator_id     varchar2(423)
-- 2 attribute_id     varchar2(83)
-- 3 attribute_value  number
-- 4 attribute_units  varchar2(16)
-- 5 indicator_values ztsv_array  
--------------------------------------------------------------------------------
procedure get_level_indicator_max_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_start_time           in  date,
   p_end_time             in  date     default null,   -- sysdate if null
   p_time_zone            in  varchar2 default null,   -- 'UTC' if null
   p_specified_level_mask in  varchar2 default null,   -- '%' if null
   p_indicator_id_mask    in  varchar2 default null,   -- '%' if null
   p_unit_system          in  varchar2 default null,   -- 'SI' if null
   p_office_id            in  varchar2 default null)   -- user's office if null
is
   l_tsid                   varchar2(183) := replace(p_tsid, '\%', '%');
   l_office_id              varchar2(16)  := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_specified_level_mask   varchar2(256) := nvl(p_specified_level_mask, '%');
   l_indicator_id_mask      varchar2(256) := nvl(p_indicator_id_mask, '%');
   l_location_level_id_mask varchar2(423);
   l_base_location_id       varchar2(16);
   l_sub_location_id        varchar2(32);
   l_base_parameter_id      varchar2(16);
   l_sub_parameter_id       varchar2(32);
   l_parameter_type_id      varchar2(16);
   l_interval_id            varchar2(16);
   l_duration_id            varchar2(16);
   l_version_id             varchar2(32);
   l_indicator_codes_crsr   sys_refcursor;
   l_ts_crsr                sys_refcursor;
   l_indicator_code         number(10);
   l_rowid                  rowid;
   l_loc_lvl_objs           loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
   l_ts_units               varchar2(16);
   l_lookback_time          timestamp;
   l_start_time             timestamp;
   l_end_time               timestamp;
   l_ts_date_time           date;
   l_ts_value               binary_double;
   l_ts_quality             number;
   l_ts                     ztsv_array := new ztsv_array();
   l_transaction_time       date;
   l_units_out              varchar2(16);
   l_cwms_ts_id_out         varchar2(183);
begin
   ------------------------------------------------------------------
   -- open a cursor of all matching location level indicator codes --
   ------------------------------------------------------------------
   cwms_ts.parse_ts(
      l_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   l_indicator_codes_crsr := cat_loc_lvl_indicator_codes(
      get_loc_lvl_indicator_id(
         l_base_location_id
            || substr('-', 1, length(l_sub_location_id))
            || l_sub_location_id,
         l_base_parameter_id
            || substr('-', 1, length(l_sub_parameter_id))
            || l_sub_parameter_id,
         l_parameter_type_id,
         l_duration_id,
         l_specified_level_mask,
         l_indicator_id_mask),
      '%.%.%',
      l_office_id);
   --------------------------------------------------               
   -- build a table of loc_lvl_indicator_t objects --
   --------------------------------------------------
   loop
      fetch l_indicator_codes_crsr into l_indicator_code;
      exit when l_indicator_codes_crsr%notfound;
      select rowid 
        into l_rowid
        from at_loc_lvl_indicator 
       where level_indicator_code = l_indicator_code;   
      l_loc_lvl_objs.extend;
      l_loc_lvl_objs(l_loc_lvl_objs.count) := new loc_lvl_indicator_t(l_rowid);
   end loop;
   close l_indicator_codes_crsr;
   -------------------------------------
   -- compute the start and end times --
   -------------------------------------
   l_start_time := from_tz(cast(p_start_time as timestamp), nvl(p_time_zone, 'UTC')) at time zone 'UTC';
   if p_end_time is null then
      l_end_time := systimestamp at time zone 'UTC';
   else
      l_end_time := from_tz(cast(p_end_time as timestamp), nvl(p_time_zone, 'UTC')) at time zone 'UTC';
   end if;
   select min(l_start_time-minimum_duration-maximum_age)
     into l_lookback_time
     from table(l_loc_lvl_objs);
   ------------------------------               
   -- retrieve the time series --
   ------------------------------               
   l_ts_units := cwms_util.get_default_units(l_base_parameter_id);      
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_ts_crsr,
      p_cwms_ts_id      => l_tsid,
      p_units           => l_ts_units,
      p_start_time      => cast(l_start_time as date),
      p_end_time        => cast(l_end_time as date),
      p_time_zone       => 'UTC',
      p_trim            => 'F',
      p_start_inclusive => 'T',
      p_end_inclusive   => 'T',
      p_previous        => 'T',
      p_next            => 'F',
      p_version_date    => null,
      p_max_version     => 'T',
      p_office_id       => l_office_id);
   loop
      fetch l_ts_crsr into l_ts_date_time, l_ts_value, l_ts_quality;
      exit when l_ts_crsr%notfound;
      l_ts.extend;
      l_ts_date_time := cast(from_tz(cast(l_ts_date_time as timestamp), 'UTC') at time zone nvl(p_time_zone, 'UTC') as date);
      l_ts(l_ts.count) := ztsv_type(l_ts_date_time, l_ts_value, l_ts_quality);   
   end loop;
   close l_ts_crsr;
   -----------------------                     
   -- return the cursor --
   -----------------------
   open p_cursor for
      select get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id) as indicator_id,
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id) as attribute_id,
             round(o.attr_value * cuc.factor + cuc.offset, 10 - trunc(log(10, o.attr_value * cuc.factor + cuc.offset))) as attribute_value,
             cuc.to_unit_id as attribute_units,
             o.get_max_indicator_values(
                l_ts,
                l_start_time) as indicator_values
        from table(l_loc_lvl_objs) o,
             cwms_unit_conversion cuc
       where cuc.from_unit_id = nvl(
                o.attr_units_id, 
                cwms_util.get_default_units
                   (nvl(o.attr_parameter_id, o.parameter_id), 
                   p_unit_system))
         and cuc.to_unit_id = cwms_util.get_default_units(
                nvl(o.attr_parameter_id, o.parameter_id), 
                p_unit_system)
    order by get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id),
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id),
             o.attr_value;
end get_level_indicator_max_values;    

END cwms_level;
/
show errors;
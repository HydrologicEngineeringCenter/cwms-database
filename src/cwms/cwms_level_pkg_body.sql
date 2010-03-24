CREATE OR REPLACE PACKAGE BODY cwms_level as

--------------------------------------------------------------------------------
-- PRIVATE FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_level_code in number)
   return varchar2
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
      || '/' || l_spec_level_id
      || '@' || l_effective_date;
      
   return l_location_level_id;

end get_location_level_id;

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
   p_spec_level_code := retrieve_specified_level(
      p_spec_level_id,
      'F',
      p_office_id);
   if p_spec_level_code is null then
      p_spec_level_code := create_specified_level(
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
   return number
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
-- PROCEDURE create_specified_level
--------------------------------------------------------------------------------
procedure create_specified_level(
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
    
end create_specified_level;   

--------------------------------------------------------------------------------
-- FUNCTION create_specified_level
--------------------------------------------------------------------------------
function create_specified_level(
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null)
   return number
is
   l_level_code number(10);
begin
   create_specified_level(
      l_level_code,
      p_level_id,
      p_description,
      p_fail_if_exists,
      p_office_id);
      
   return l_level_code;      
end create_specified_level;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_specified_level
--------------------------------------------------------------------------------
procedure retrieve_specified_level(
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
end retrieve_specified_level;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_specified_level
--------------------------------------------------------------------------------
function retrieve_specified_level(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
   return number
is
   l_level_code number(10);
begin
   retrieve_specified_level(
      l_level_code,
      p_level_id,
      p_fail_if_not_found,
      p_office_id);
      
   return l_level_code;
end retrieve_specified_level;

--------------------------------------------------------------------------------
-- PROCEDURE update_specified_level
--------------------------------------------------------------------------------
procedure update_specified_level(
   p_level_id    in  varchar2,
   p_description in  varchar2,
   p_office_id   in  varchar2 default null)
is
   l_level_code number(10);
begin
   -----------------------
   -- retrieve the code --
   -----------------------
   l_level_code := retrieve_specified_level(p_level_id, 'T', p_office_id);
   --------------------------------
   -- update the existing record --
   --------------------------------
   update at_specified_level
      set specified_level_id = p_level_id,
          description = p_description
    where specified_level_code = l_level_code;
end update_specified_level;

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
    where specified_level_code = retrieve_specified_level(
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
   p_seasonal_values         in  seasonal_value_array default null,
   p_office_id               in  varchar2 default null)
is
   l_location_level_code       number(10) := null;
   l_office_id                 varchar2(16);
   l_office_code               number;
   l_fail_if_exists            boolean;
   l_spec_level_code           number(10);
   l_loc_level_code            number(10);
   l_interval_origin           date;
   l_location_code             number(10);
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
   ---------------------------------
   -- get the codes for input ids --
   ---------------------------------
   if p_effective_date is null then
      l_effective_date := to_date('01JAN1900 0000', 'ddmonyyyy hh24mi');
   else
      l_effective_date := cast(
         from_tz(cast(p_effective_date as timestamp), p_timezone_id)
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
               from_tz(cast(p_interval_origin as timestamp), p_timezone_id)
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
                interpolate = null;
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
               from_tz(cast(p_interval_origin as timestamp), p_timezone_id)
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
                interpolate = p_interpolate;
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
-- FUNCTION create_location_level
--------------------------------------------------------------------------------
function create_location_level(
   p_fail_if_exists          in varchar2 default 'T',
   p_spec_level_id           in varchar2,
   p_location_id             in varchar2,
   p_parameter_id            in varchar2,
   p_parameter_type_id       in varchar2,
   p_duration_id             in varchar2,
   p_level_value             in number,
   p_level_units             in varchar2,
   p_level_comment           in varchar2 default null,
   p_effective_date          in date default null,
   p_timezone_id             in varchar2 default 'UTC',
   p_attribute_value         in number default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_parameter_id  in varchar2 default null,
   p_attribute_param_type_id in varchar2 default null,
   p_attribute_duration_id   in varchar2 default null,
   p_attribute_comment       in varchar2 default null,
   p_interval_origin         in date default null,
   p_interval_months         in integer default null,
   p_interval_minutes        in integer default null,
   p_interpolate             in varchar2 default 'T',
   p_seasonal_values         in seasonal_value_array default null,
   p_office_id               in varchar2 default null)
   return  number
is
   l_location_level_code number(10);
begin
   create_location_level(
      l_location_level_code,
      p_fail_if_exists,
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

   return l_location_level_code;
end create_location_level;

--------------------------------------------------------------------------------
-- PROCEDURE create_location_level2
--------------------------------------------------------------------------------
procedure create_location_level2(
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
   p_effective_date          in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null,
   p_office_id               in  varchar2 default null)
is
   l_recordset           str_tab_tab_t;
   l_offset_months       integer;
   l_offset_minutes      integer;
   l_offset_value        number;
   l_seasonal_values     seasonal_value_array := null;
   l_effective_date      date := cwms_util.parse_odbc_ts_or_d_string(p_effective_date);
   l_interval_origin     date := cwms_util.parse_odbc_ts_or_d_string(p_interval_origin);
begin
   ---------------------------
   -- parse the data string --
   ---------------------------
   if p_seasonal_values is not null then
      l_seasonal_values := new seasonal_value_array();
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
   create_location_level(
      p_location_level_code,
      p_fail_if_exists,
      p_spec_level_id,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      l_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_attribute_comment,
      l_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      l_seasonal_values,
      p_office_id);
end create_location_level2;

--------------------------------------------------------------------------------
-- FUNCTION create_location_level2
--------------------------------------------------------------------------------
function create_location_level2(
   p_fail_if_exists          in  varchar2 default 'T',
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return number
is
   l_location_level_code number(10);
begin
   create_location_level2(
      l_location_level_code,
      p_fail_if_exists,
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
      
   return l_location_level_code;      
end create_location_level2;   

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
   p_seasonal_values         in  seasonal_value_array default null,
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
         || '/' || p_spec_level_id
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
   p_seasonal_values         out seasonal_value_array,
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribut_units          in  varchar2 default null,
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
      p_attribut_units,
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
         || '/' || p_spec_level_id
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
      p_seasonal_values := new seasonal_value_array();
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
-- PROCEDURE retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
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
   function encode_date(p_date in date) return binary_integer
   is
      l_origin constant date := to_date('01Jan2000 0000', 'ddMonyyyy hh24mi');
   begin
      return (p_date - l_origin) * 1440;
   end;
   
   function decode_date(p_int in binary_integer) return date
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
            || '/' || p_spec_level_id
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
               || '/' || p_spec_level_id
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
            || '/' || p_spec_level_id
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
               || '/' || p_spec_level_id
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
                     p_level_values(p_level_values.count).date_time,
                     'BEFORE',
                     'UTC');
                  -----------------------------
                  -- compute the level value --
                  -----------------------------
                  if l_rec.interpolate = 'T' then
                     l_value := (
                        l_value_prev +
                        (l_date_next - l_end_time) /
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
-- FUNCTION retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
--------------------------------------------------------------------------------
function retrieve_location_level_values(
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
   return ztsv_array
is
   l_values ztsv_array;
begin
   retrieve_location_level_values(
      l_values,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
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
-- PROCEDURE retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
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
-- Note: The returned QUALITY_CODE values will be zero.
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
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_values ztsv_array;
begin
   retrieve_location_level_values(
      l_values,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_level_units,
      p_date,
      null,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);

   p_level_value := l_values(1).value;
end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number
is
   l_level_value number;
begin
   retrieve_location_level_value(
      l_level_value,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_level_units,
      p_date,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);

   return l_level_value;
end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
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

   retrieve_location_level_value(
      p_level_value,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_spec_level_id,
      p_level_units,
      p_date,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);

end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number
is
   l_location_level_value number(10);
begin
   retrieve_location_level_value(
      l_location_level_value,
      p_ts_id,
      p_spec_level_id,
      p_level_units,
      p_date,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);

   return l_location_level_value;
end retrieve_location_level_value;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs(
   p_attribute_values        out sys_refcursor,
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
begin
   open p_attribute_values for
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
    order by a_ll.attribute_value * c_uc.factor + c_uc.offset;
end retrieve_location_level_attrs;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--------------------------------------------------------------------------------
function retrieve_location_level_attrs(
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
   return sys_refcursor
is
   l_attribute_values sys_refcursor;
begin
   retrieve_location_level_attrs(
      l_attribute_values,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_date,
      p_office_id);
      
   return l_attribute_values;
end retrieve_location_level_attrs;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs2
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs2(
   p_attribute_values        out varchar2,
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
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
is
   l_cursor    sys_refcursor;
   l_attribute number;
begin
   p_attribute_values := null;
   retrieve_location_level_attrs(
      l_cursor,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      cwms_util.parse_odbc_ts_or_d_string(p_date),
      p_office_id);
      
   loop
      fetch l_cursor into l_attribute;
      exit when l_cursor%notfound;
      p_attribute_values := p_attribute_values || to_char(l_attribute) || cwms_util.record_separator;
   end loop;
   close l_cursor;
   p_attribute_values := rtrim(p_attribute_values, cwms_util.record_separator);
end retrieve_location_level_attrs2;

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--------------------------------------------------------------------------------
function retrieve_location_level_attrs2(
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
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return varchar2
is
   l_attribute_values varchar2(32767);
begin
   retrieve_location_level_attrs2(
      l_attribute_values,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_date,
      p_office_id);
      
   return l_attribute_values;
end;

--------------------------------------------------------------------------------
-- PRIVATE FUNCTION lookup_level_or_attribute
--------------------------------------------------------------------------------
function lookup_level_or_attribute(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_value                   in  number,
   p_lookup_level            in  boolean,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number
is
   l_cursor sys_refcursor;
   l_value  number;
   l_attrs  number_tab_t := new number_tab_t();
   l_levels number_tab_t := new number_tab_t();
begin
   -----------------------------
   -- retrieve the attributes --
   -----------------------------
   retrieve_location_level_attrs(
      l_cursor,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_date,
      p_office_id);
   loop
      fetch l_cursor into l_value;
      exit when l_cursor%notfound;
      l_attrs.extend;
      l_attrs(l_attrs.count) := l_value;
   end loop;
   if l_attrs.count = 0 then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level with attribute',
         nvl(p_office_id, cwms_util.user_office_id)
         || '/' || p_location_id
         || '.' || p_parameter_id
         || '.' || p_parameter_type_id
         || '.' || p_duration_id
         || '/' || p_spec_level_id
         || '/' || p_attribute_parameter_id
         || '.' || p_attribute_param_type_id
         || '.' || p_attribute_duration_id
         || '@' || to_char(nvl(p_date, sysdate), 'yyyy-mm-dd hh24mi'));
   end if;
   -------------------------
   -- retrieve the levels --
   -------------------------
   l_levels.extend(l_attrs.count);
   for i in 1..l_attrs.count loop
      l_levels(i) := retrieve_location_level_value(
         p_location_id,
         p_parameter_id,
         p_parameter_type_id,
         p_duration_id,
         p_spec_level_id,
         p_level_units,
         p_date,
         l_attrs(i),
         p_attribute_units,
         p_attribute_parameter_id,
         p_attribute_param_type_id,
         p_attribute_duration_id,
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
--------------------------------------------------------------------------------
procedure lookup_level_by_attribute(
   p_level                   out number,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
is
begin
   p_level := lookup_level_or_attribute(
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
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
--------------------------------------------------------------------------------
function lookup_level_by_attribute(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number
is
   l_level number;
begin
   lookup_level_by_attribute(
      l_level,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
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
--------------------------------------------------------------------------------
procedure lookup_attribute_by_level(
   p_attribute               out number,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
is
begin
   p_attribute := lookup_level_or_attribute(
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
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
--------------------------------------------------------------------------------
function lookup_attribute_by_level(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number
is
   l_attribute number;
begin
   lookup_attribute_by_level(
      l_attribute,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
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
--------------------------------------------------------------------------------
procedure delete_location_level(
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null)
is
   l_location_level_code number(10);
   l_date                date;
   l_cascade             boolean := cwms_util.return_true_or_false(p_cascade);
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
      p_attribute_duration_id,
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
         || '/' || p_spec_level_id
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

END cwms_level;
/

show errors;
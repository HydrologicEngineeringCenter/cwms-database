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
end validate_specified_level_input;        
            
--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE get_units_conversion
--------------------------------------------------------------------------------
procedure get_units_conversion(
   p_factor         out binary_double,
   p_offset         out binary_double,
   p_to_cwms        in  boolean,
   p_units          in  varchar2,
   p_parameter_code in  number)
is          
   l_parameter_id      varchar2(49);
   l_sub_parameter_id  varchar2(32);
begin       
   if p_to_cwms is null then
      cwms_err.raise(
         'ERROR',
         'Parameter p_to_cwms must be true (To CWMS) or false (From CWMS)');
   end if;      
   if p_units is null then
      p_factor := 1;
      p_offset := 0;
   else     
      begin 
         if p_to_cwms then
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
               || case p_to_cwms
                     when true then ' to'
                     else           ' from'
                  end
               || ' specified units: '
               || p_units);
      end;  
   end if;  
end get_units_conversion;        
            
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
   p_expiration_date_out       out date,
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
   l_office_id          varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
   l_office_code        number(10)   := cwms_util.get_office_code(l_office_id);
   l_factor             binary_double;
   l_offset             binary_double;
   l_attribute_value    number := null;
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
       where upper(parameter_type_id) = upper(p_parameter_type_id);
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
       where upper(duration_id) = upper(p_duration_id);
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
         true, -- To CWMS
         p_attribute_units,
         p_attribute_parameter_code);
      l_attribute_value := cwms_rounding.round_f(p_attribute_value * l_factor + l_offset, 12);
   end if;  
   begin    
      if p_match_date then
         ------------------------
         -- match date exactly --
         ------------------------
         select distinct
                location_level_code,
                location_level_date,
                expiration_date
           into p_location_level_code,
                p_effective_date_out,
                p_expiration_date_out
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
            and nvl(to_char(attribute_value), '@')
                = nvl(to_char(l_attribute_value), '@');
      else  
         ---------------------
         -- earlier date OK --
         ---------------------
         select location_level_code,
                location_level_date,
                expiration_date
           into p_location_level_code,
                p_effective_date_out,
                p_expiration_date_out
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
                                          and nvl(to_char(attribute_value), '@')
                                              = nvl(to_char(l_attribute_value), '@'))
            and nvl(to_char(attribute_parameter_code), '@')
                = nvl(to_char(p_attribute_parameter_code), '@')
            and nvl(to_char(attribute_parameter_type_code), '@')
                = nvl(to_char(p_attribute_param_type_code), '@')
            and nvl(to_char(attribute_duration_code), '@')
                = nvl(to_char(p_attribute_duration_code), '@')
            and nvl(to_char(attribute_value), '@')
                = nvl(to_char(l_attribute_value), '@');
      end if;
   exception
      when no_data_found then
         p_location_level_code := null;
   end;     
end get_location_level_codes;

function get_prev_effective_date(
   p_location_level_code in integer,
   p_timezone            in varchar2 default 'UTC')
   return date
is
   l_rec            at_location_level%rowtype;
   l_effective_date date;
begin
   select *
     into l_rec
     from at_location_level
    where location_level_code = p_location_level_code;
    
   begin
      select cwms_util.change_timezone(location_level_date, 'UTC', p_timezone)
        into l_effective_date
        from at_location_level
       where location_code = l_rec.location_code
         and specified_level_code = l_rec.specified_level_code
         and parameter_code = l_rec.parameter_code
         and parameter_type_code = l_rec.parameter_type_code
         and duration_code = l_rec.duration_code
         and location_level_date = (select max(location_level_date)
                                      from at_location_level
                                     where location_code = l_rec.location_code
                                       and specified_level_code = l_rec.specified_level_code
                                       and parameter_code = l_rec.parameter_code
                                       and parameter_type_code = l_rec.parameter_type_code
                                       and duration_code = l_rec.duration_code
                                       and location_level_date < l_rec.location_level_date
                                   )
         and rownum = 1;
   exception
      when no_data_found then null;
   end;
   return l_effective_date;
end get_prev_effective_date;

function get_next_effective_date(
   p_location_level_code in integer,
   p_timezone            in varchar2 default 'UTC')
   return date
is
   l_rec            at_location_level%rowtype;
   l_effective_date date;
begin
   select *
     into l_rec
     from at_location_level
    where location_level_code = p_location_level_code;
    
   begin
      select cwms_util.change_timezone(location_level_date, 'UTC', p_timezone)
        into l_effective_date
        from at_location_level
       where location_code = l_rec.location_code
         and specified_level_code = l_rec.specified_level_code
         and parameter_code = l_rec.parameter_code
         and parameter_type_code = l_rec.parameter_type_code
         and duration_code = l_rec.duration_code
         and location_level_date = (select min(location_level_date)
                                      from at_location_level
                                     where location_code = l_rec.location_code
                                       and specified_level_code = l_rec.specified_level_code
                                       and parameter_code = l_rec.parameter_code
                                       and parameter_type_code = l_rec.parameter_type_code
                                       and duration_code = l_rec.duration_code
                                       and location_level_date > l_rec.location_level_date
                                   )
         and rownum = 1;
   exception
      when no_data_found then null;
   end;
   return l_effective_date;
end get_next_effective_date;
            
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
   l_expiration_date           date;
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
      l_expiration_date,
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
   -------------------------------------
   -- get the date to interpolate for --
   -------------------------------------
   if p_date is null then
      l_ts := systimestamp at time zone l_tz;
   else     
      l_ts := from_tz(cast(p_date as timestamp), l_tz);
   end if;
   -----------------------------
   -- get the interval origin --
   -----------------------------
   l_origin := from_tz(p_rec.interval_origin, 'UTC') at time zone l_tz;
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
   return cast(l_intvl as date);
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
   l_intvl        timestamp;
   l_date         date;
   l_date_before  date;
   l_date_after   date;
   l_value_before number;
   l_value_after  number;
begin
   l_date := cwms_util.change_timezone(p_date, 'UTC', p_tz);      
   l_intvl := top_of_interval_on_or_before(p_rec, l_date, 'UTC');
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
         l_date,
         'BEFORE',
         p_tz);
      find_nearest(
         l_date_after,
         l_value_after,
         p_rec,
         l_date,
         'AFTER',
         p_tz);
      if (l_date - l_date_before) < (l_date_after - l_date) then
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
                      cast(l_intvl + calendar_offset + time_offset as date),
                      value
                 into p_nearest_date,
                      p_nearest_value
                 from at_seasonal_location_level
                where location_level_code = p_rec.location_level_code
                  and cast(l_intvl + calendar_offset + time_offset as date) =
                         (select min(cast(l_intvl + calendar_offset + time_offset as date))
                            from at_seasonal_location_level
                           where location_level_code = p_rec.location_level_code
                                 and cast(l_intvl + calendar_offset + time_offset as date) >= l_date);
               exit; -- when found                                 
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
                        l_intvl := l_intvl + p_rec.time_interval;
                     else
                        l_intvl := l_intvl + p_rec.calendar_interval;
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
               select distinct
                      cast(l_intvl + calendar_offset + time_offset as date),
                      value
                 into p_nearest_date,
                      p_nearest_value
                 from at_seasonal_location_level
                where location_level_code = p_rec.location_level_code
                  and cast(l_intvl + calendar_offset + time_offset as date) =
                         (select max(cast(l_intvl + calendar_offset + time_offset as date))
                            from at_seasonal_location_level
                           where location_level_code = p_rec.location_level_code
                                 and cast(l_intvl + calendar_offset + time_offset as date) <= l_date);
               exit; -- when found                                 
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
                        l_intvl := l_intvl - p_rec.time_interval;
                     else
                        l_intvl := l_intvl - p_rec.calendar_interval;
                     end if;
                  end if;
            end;
         end loop;
      end if;
   end if;  
end find_nearest;        
            
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
   return varchar2 /*result_cache*/
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
   return varchar2 /*result_cache*/
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
   return varchar2  /*result_cache*/
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
   return varchar2 /*result_cache*/
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
   return number
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
-- PROCEDURE rename_specified_level
--------------------------------------------------------------------------------
procedure rename_specified_level(
   p_old_level_id in varchar2,
   p_new_level_id in varchar2,
   p_office_id    in varchar2 default null)
is
   l_office_code  number(10) := cwms_util.get_db_office_code(p_office_id);
   l_old_level_id at_specified_level.specified_level_id%type; 
begin
   begin
      select office_code,
             specified_level_id
        into l_office_code,
             l_old_level_id
        from at_specified_level
       where upper(specified_level_id) = upper(p_old_level_id)
         and office_code in (l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_old_level_id,
            'Specified Level ID');
   end;
   if l_office_code = cwms_util.db_office_code_all then
      cwms_err.raise(
         'ERROR',
         'Cannot rename a Specified Level owned by CWMS');
   end if;
   update at_specified_level
      set specified_level_id = p_new_level_id
    where specified_level_id = l_old_level_id
      and office_code = l_office_code; 
end rename_specified_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE delete_specified_level
--------------------------------------------------------------------------------
procedure delete_specified_level(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
is
   l_spec_level_code  number;
begin       
   --------------------------------
   -- delete the existing record --
   --------------------------------
   l_spec_level_code := get_specified_level_code(
             p_level_id, 
             p_fail_if_not_found, 
             p_office_id);
   delete from at_specified_level
    where specified_level_code = l_spec_level_code;
end delete_specified_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE cat_specified_levels
--          
-- The cursor returned by this routine contains three fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--    3 : description        varchar2(256)
--          
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure cat_specified_levels(
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
   l_level_id_mask  := cwms_util.normalize_wildcards(upper(p_level_id_mask));
   l_office_id_mask := nvl(upper(p_office_id_mask), cwms_util.user_office_id);
   l_office_id_mask := cwms_util.normalize_wildcards(l_office_id_mask);
   -----------------------------
   -- get the matching levels --
   -----------------------------
   open p_level_cursor
    for select o.office_id,
               l.specified_level_id,
               l.description
          from cwms_office o,
               at_specified_level l
         where upper(o.office_id) like l_office_id_mask
           and l.office_code = o.office_code
           and upper(l.specified_level_id) like l_level_id_mask;
end cat_specified_levels;
            
--------------------------------------------------------------------------------
-- FUNCTION cat_specified_levels
--          
-- The cursor returned by this routine contains three fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--    3 : description        varchar2(256)
--          
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
function cat_specified_levels(
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor
is          
   l_level_cursor sys_refcursor;
begin       
   cat_specified_levels(
      l_level_cursor,
      p_level_id_mask,
      p_office_id_mask);
            
   return l_level_cursor;
end cat_specified_levels;
            
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
   p_timezone_id             in  varchar2 default null,
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
   p_tsid                    in  varchar2 default null,
   p_expiration_date         in  date, 
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_office_id               in  varchar2 default null)
is          
   l_location_level_code       number(10) := null;
   l_office_code               number;
   l_fail_if_exists            boolean;
   l_spec_level_code           number(10);
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
   l_expiration_date           date;
   l_timezone_id               varchar2(28);
   l_effective_date_out        date;
   l_expiration_date_out       date;
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
   l_calendar_interval         yminterval_unconstrained;
   l_time_interval             dsinterval_unconstrained;
   l_ts_code                   number(10);
   l_count                     pls_integer;
   l_interpolate               varchar2(1);
   l_level_param_is_elev       boolean;
   l_attr_param_is_elev        boolean;
   l_level_vert_datum_offset   binary_double;
   l_attr_vert_datum_offset    binary_double;
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
   l_count :=
      case p_level_value is null
         when true  then 0
         when false then 1
      end +
      case p_seasonal_values is null
         when true  then 0
         when false then 1
      end +
      case p_tsid is null
         when true  then 0
         when false then 1
      end;
   validate_specified_level_input(l_office_code, p_office_id, p_spec_level_id);
   l_location_code := cwms_loc.get_location_code(l_office_code, p_location_id);
   if p_attribute_value is not null and p_attribute_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Must specify attribute parameter id with attribute value '
         || 'in CREATE_LOCATION_LEVEL');
   end if;
   if l_count != 1 then
      cwms_err.raise(
         'ERROR',
         'Must specify exactly one of p_level_value, p_seasonal_values, and p_tsid '
         || 'in CREATE_LOCATION_LEVEL');
   end if;
   if p_seasonal_values is not null then
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
   if p_level_value is null then
      l_interpolate := p_interpolate;
   end if;
   -------------------------------------------------------
   -- default the time zone to the location's time zone --
   -------------------------------------------------------
   if p_timezone_id is null then
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
   l_effective_date := cwms_util.change_timezone(
      nvl(p_effective_date, date '1900-01-01'),
      l_timezone_id, 
      'UTC');
   l_expiration_date := cwms_util.change_timezone(
      p_expiration_date,
      l_timezone_id, 
      'UTC');
   get_location_level_codes(
      l_location_level_code,
      l_spec_level_code,
      l_location_code,
      l_parameter_code,
      l_parameter_type_code,
      l_duration_code,
      l_effective_date_out,
      l_expiration_date_out,
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
   if p_tsid is not null then
      l_ts_code := cwms_ts.get_ts_code(p_tsid, l_office_code);
   end if;
   -------------------------------
   -- get the units conversions --
   -------------------------------
   get_units_conversion(
      l_level_factor,
      l_level_offset,
      true, -- To CWMS
      p_level_units,
      l_parameter_code);
   if p_attribute_value is null then
      l_attribute_value := null;
   else     
      get_units_conversion(
         l_attr_factor,
         l_attr_offset,
         true, -- To CWMS
         p_attribute_units,
         l_attribute_parameter_code);
      l_attribute_value := cwms_rounding.round_f(p_attribute_value * l_attr_factor + l_attr_offset, 12);
   end if;  
   ----------------------------------------------
   -- get vertical datum offset for elevations --
   ----------------------------------------------
   l_level_param_is_elev := instr(upper(p_parameter_id), 'ELEV') = 1; 
   l_attr_param_is_elev  := instr(upper(p_attribute_parameter_id), 'ELEV') = 1;
   if l_level_param_is_elev then
      l_level_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_level_units);
      l_level_offset := l_level_offset - l_level_vert_datum_offset;
   end if;
   if l_attr_param_is_elev then
      l_attr_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_attribute_units);
      l_attribute_value := l_attribute_value - l_attr_vert_datum_offset;
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
         -----------------------------------
         -- constant value or time series --
         -----------------------------------
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
                null, null, null,
                l_interpolate,
                l_ts_code,
                l_expiration_date);
      else  
         ---------------------
         -- seasonal values --
         ---------------------
         ----------------------------------------------------
         -- set the interval origin for the seaonal values --
         -- (always stored in UTC in the database)         --
         ----------------------------------------------------
         l_interval_origin := cwms_util.change_timezone(
            nvl(p_interval_origin, to_date('01JAN2000 0000', 'ddmonyyyy hh24mi')), 
            l_timezone_id, 
            'UTC');
         
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
                   l_interpolate,
                   l_ts_code,
                   l_expiration_date);
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
                   l_interpolate,
                   l_ts_code,
                   l_expiration_date);
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
         -----------------------------------
         -- constant value or time series --
         -----------------------------------
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
                interpolate = l_interpolate,
                ts_code = l_ts_code,
                expiration_date = l_expiration_date
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
            set location_level_value = null,
                location_level_comment = p_level_comment,
                location_level_date = l_effective_date,
                attribute_value = l_attribute_value,
                attribute_parameter_code = l_attribute_parameter_code,
                attribute_comment = p_attribute_comment,
                interval_origin = l_interval_origin,
                calendar_interval = l_calendar_interval,
                time_interval = l_time_interval,
                interpolate = l_interpolate,
                expiration_date = l_expiration_date
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
   p_timezone_id             in  varchar2 default null,
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
      null,
      null,
      p_seasonal_values,
      p_office_id);               
            
end store_location_level;
   
procedure store_location_level3(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_tsid                    in  varchar2 default null,
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
      p_tsid,
      null,
      p_seasonal_values,
      p_office_id);

end store_location_level3;

   
procedure store_location_level4(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_tsid                    in  varchar2 default null,
   p_expiration_date         in  date     default null, 
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
      p_tsid,
      p_expiration_date,
      p_seasonal_values,
      p_office_id);

end store_location_level4;

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
-- p_effective_date should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_interval_origin should be specified as 'yyyy/mm/dd hh:mm:ss'
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
   p_timezone_id             in  varchar2 default null,
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

procedure retrieve_location_level4(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
   p_expiration_date         out date,
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
      p_expiration_date,
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
      false, -- From CWMS
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
   p_tsid                 := case l_rec.ts_code is null
                                when true  then null
                                when false then cwms_ts.get_ts_id(l_rec.ts_code)
                             end;
   p_expiration_date      := l_rec.expiration_date;
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
end retrieve_location_level4;

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
   l_tsid varchar2(183);
   l_expiration_date date;
begin
   retrieve_location_level4(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      l_tsid,
      l_expiration_date,
      p_seasonal_values,
      p_spec_level_id,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_level_units,
      p_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_match_date,
      p_office_id);
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

procedure retrieve_location_level3(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
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
   l_expiration_date         date;
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
   retrieve_location_level4(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_tsid,
      l_expiration_date,
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
end retrieve_location_level3;

procedure retrieve_location_level4(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
   p_expiration_date         out date,
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
   retrieve_location_level4(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_tsid,
      p_expiration_date,
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
end retrieve_location_level4;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level2
--          
-- Retrieves the Location Level in effect at a specified time using only text
-- and numeric parameters
--          
-- p_date should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--          
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--          
-- p_effective_date is returned as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_interval_origin is returned as 'yyyy/mm/dd hh:mm:ss'
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
   p_attribute_units         in  varchar2 default null,
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
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_values_utc(
   p_level_values            out ztsv_array,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time_utc          in  date,
   p_end_time_utc            in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_office_id               in  varchar2 default null,
   p_in_recursion            in boolean default false)
is
   type encoded_date_t is table of boolean index by binary_integer;
   l_encoded_dates             encoded_date_t;
   l_rec                       at_location_level%rowtype;
   l_level_values              ztsv_array;
   l_spec_level_code           number(10);
   l_location_level_code       number(10);
   l_start_time                date;
   l_end_time                  date;
   l_start_time_utc            date := p_start_time_utc;
   l_end_time_utc              date;
   l_location_code             number(10);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_effective_date            date;
   l_expiration_date           date;
   l_factor                    binary_double;
   l_offset                    binary_double;
   l_vert_datum_offset         binary_double;
   l_office_code               number := cwms_util.get_office_code(p_office_id);
   l_office_id                 varchar2(16) := cwms_util.get_db_office_id(p_office_id);
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
   l_unit                      varchar2(16);
   --------------------
   -- local routines --
   --------------------
   function encode_date(p_date in date) return binary_integer /*result_cache*/
   is
      l_origin constant date := to_date('01Jan2000 0000', 'ddMonyyyy hh24mi');
   begin
      return (p_date - l_origin) * 1440;
   end;

   function decode_date(p_int in binary_integer) return date /*result_cache*/
   is
      l_origin constant date := to_date('01Jan2000 0000', 'ddMonyyyy hh24mi');
   begin
      return l_origin + p_int / 1440;
   end;
   
   function get_quality(p_rec in at_location_level%rowtype) return integer
   is 
      l_quality integer := 0;
   begin
      if p_rec.location_level_value is null and p_rec.interpolate = 'T' then   
         l_quality := 1; -- interpolate between values
      end if;  
      return l_quality; 
   end;
   
begin
   l_level_values := ztsv_array();
   -------------------------------------------------------
   -- get_location_level_codes() will try to create the --
   -- specified level if it doesn't exist, so test here --
   -------------------------------------------------------
   begin
      select specified_level_code
        into l_spec_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(p_spec_level_id)
         and office_code in (l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Specified level', l_office_id||'/'||p_spec_level_id);
   end;
   -----------------------------------------------------------
   -- get the codes and effective dates for the time window --
   -----------------------------------------------------------
   if p_end_time_utc is not null and p_end_time_utc != p_start_time_utc then
      if p_end_time_utc < p_start_time_utc then
         cwms_err.raise('ERROR', 'Parameter p_end_time_utc must be later than p_start_time_utc');
      end if;
      get_location_level_codes(
         l_location_level_code,
         l_spec_level_code,
         l_location_code,
         l_parameter_code,
         l_parameter_type_code,
         l_duration_code,
         l_effective_date,
         l_expiration_date,
         l_attribute_parameter_code,
         l_attribute_param_type_code,
         l_attribute_duration_code,
         p_location_id,
         p_parameter_id,
         p_parameter_type_id,
         p_duration_id,
         p_spec_level_id,
         p_end_time_utc,
         false,
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
            l_office_id
            || '/' || p_location_id
            || '.' || p_parameter_id
            || '.' || p_parameter_type_id
            || '.' || p_duration_id
            || '.' || p_spec_level_id
            || '@' || to_char(p_end_time_utc, 'dd-Mon-yyyy hh24:mi'));
      end if;
      l_encoded_dates(encode_date(l_effective_date)) := true;
      l_start_time_utc := l_effective_date;
      l_end_time_utc := get_next_effective_date(l_location_level_code, 'UTC');
      l_end_time_utc := least(p_end_time_utc, nvl(l_end_time_utc, p_end_time_utc));
      while l_effective_date > p_start_time_utc loop
         get_location_level_codes(
            l_location_level_code,
            l_spec_level_code,
            l_location_code,
            l_parameter_code,
            l_parameter_type_code,
            l_duration_code,
            l_effective_date,
            l_expiration_date,
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
            exit;
         end if;
         l_encoded_dates(encode_date(l_effective_date)) := true;
         l_start_time_utc := l_effective_date;
      end loop;
      l_start_time_utc := greatest(l_start_time_utc, p_start_time_utc);
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
         l_expiration_date,
         l_attribute_parameter_code,
         l_attribute_param_type_code,
         l_attribute_duration_code,
         p_location_id,
         p_parameter_id,
         p_parameter_type_id,
         p_duration_id,
         p_spec_level_id,
         l_start_time_utc,
         false,
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
            l_office_id
            || '/' || p_location_id
            || '.' || p_parameter_id
            || '.' || p_parameter_type_id
            || '.' || p_duration_id
            || '.' || p_spec_level_id
            || '@' || to_char(l_start_time_utc, 'dd-Mon-yyyy hh24:mi'));
      end if;
      l_encoded_dates(encode_date(l_effective_date)) := true;
   end if;
   if l_encoded_dates.count > 1 then
      -------------------------------------------
      -- working with multiple effective dates --
      -------------------------------------------
      declare
         l_values       ztsv_array;
         l_encoded_start_time integer := l_encoded_dates.first;
         l_encoded_end_time   integer := l_encoded_dates.next(l_encoded_start_time);
      begin
         while l_encoded_start_time is not null loop
            l_start_time := greatest(decode_date(l_encoded_start_time), l_start_time_utc);
            l_end_time := decode_date(l_encoded_end_time - 1); -- one minute before
            -------------------------------------
            -- recurse for the sub time window --
            -------------------------------------
            retrieve_loc_lvl_values_utc(
               l_values,
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
               p_office_id,
               p_in_recursion => true);
            for i in 1..l_values.count loop
               l_level_values.extend;
               l_level_values(l_level_values.count) := l_values(i);
            end loop;
            l_encoded_start_time := l_encoded_dates.next(l_encoded_start_time);
            l_encoded_end_time   := nvl(l_encoded_dates.next(l_encoded_start_time), encode_date(l_end_time_utc));
         end loop;
         l_level_values(l_level_values.count).date_time := nvl(l_level_values(l_level_values.count).date_time, l_end_time_utc);
      end;
   else
      ------------------------------------------
      -- working with a single effective date --
      ------------------------------------------
      -------------------------------
      -- get the units conversions --
      -------------------------------
      l_unit := cwms_util.get_unit_id(cwms_util.parse_unit(p_level_units), l_office_id);
      get_units_conversion(
         l_factor,
         l_offset,
         false, -- From CWMS
         l_unit,
         l_parameter_code);
      if p_attribute_value is not null then
         get_units_conversion(
            l_attribute_factor,
            l_attribute_offset,
            true, -- To CWMS
            p_attribute_units,
            l_attribute_parameter_code);
         l_attribute_value := cwms_rounding.round_f(p_attribute_value * l_attribute_factor + l_attribute_offset, 12);
         if instr(upper(p_parameter_id), 'ELEV') = 1 and not p_in_recursion then
            l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_level_units);
            l_attribute_value := l_attribute_value - l_vert_datum_offset;
         end if;
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
            and nvl(to_char(attribute_value), '@') = nvl(to_char(l_attribute_value), '@')
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
                                          and nvl(to_char(attribute_value), '@') = nvl(to_char(l_attribute_value), '@')
                                          and location_level_date <= l_start_time_utc);
      exception
         when no_data_found then
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
               || '@' || l_start_time_utc);
      end;
      ----------------------------
      -- fill out the tsv array --
      ----------------------------
      if l_rec.location_level_value is null and l_rec.ts_code is null then
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
            l_start_time_utc,
            'BEFORE',
            'UTC');
         if l_date_prev = l_start_time_utc then
            l_value := l_value_prev * l_factor + l_offset;
         else
            --------------------------------------------------------
            -- find the nearest date/value on or after start time --
            --------------------------------------------------------
            find_nearest(
               l_date_next,
               l_value_next,
               l_rec,
               l_start_time_utc,
               'AFTER',
               'UTC');
            if l_date_next = l_start_time_utc then
               l_value := l_value_next * l_factor + l_offset;
            else
               -----------------------------
               -- compute the level value --
               -----------------------------
               if l_rec.interpolate = 'T' then
                  l_value := (
                     l_value_prev +
                     (l_start_time_utc - l_date_prev) /
                     (l_date_next - l_date_prev) *
                     (l_value_next - l_value_prev)) * l_factor + l_offset;
               else
                  l_value := l_value_prev * l_factor + l_offset;
               end if;
            end if;
         end if;
         l_level_values.extend;
         l_level_values(1) := new ztsv_type(l_start_time_utc, l_value, get_quality(l_rec));
         if l_end_time_utc is null then
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
                  l_level_values(l_level_values.count).date_time + 1 / 86400,
                  'AFTER',
                  'UTC');
               l_level_values.extend;
               if l_date_next <= l_end_time_utc then
                  -------------------------------------
                  -- on or before end of time window --
                  -------------------------------------
                  l_level_values(l_level_values.count) :=
                     new ztsv_type(l_date_next, l_value_next * l_factor + l_offset, get_quality(l_rec));
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
                  if l_rec.interpolate = 'T' and l_date_next != l_date_prev then
                     l_value := (
                        l_value_prev +
                        (l_end_time_utc - l_date_prev) /
                        (l_date_next - l_date_prev) *
                        (l_value_next - l_value_prev)) * l_factor + l_offset;
                  else
                     l_value := l_value_prev * l_factor + l_offset;
                  end if;
                  l_level_values(l_level_values.count) :=
                     new ztsv_type(l_end_time_utc, l_value, get_quality(l_rec));
               end if;
               if l_date_next > l_end_time_utc then
                  exit;
               end if;
            end loop;
         end if;
      elsif l_rec.location_level_value is null then
         -----------------
         -- time series --
         -----------------
         declare
            l_ts_cur sys_refcursor;
            l_dates   date_table_type;
            l_values  double_tab_t;
            l_quality number_tab_t;
            l_ts      ztsv_array;
            l_first   pls_integer;
            l_last    pls_integer;
            a         pls_integer;
            b         pls_integer;
         begin
            cwms_ts.retrieve_ts(
               p_at_tsv_rc       => l_ts_cur,
               p_cwms_ts_id      => cwms_ts.get_ts_id(l_rec.ts_code),
               p_units           => p_level_units,
               p_start_time      => l_start_time_utc,
               p_end_time        => l_end_time_utc,
               p_time_zone       => 'UTC',
               p_start_inclusive => 'T',
               p_end_inclusive   => 'T',
               p_previous        => 'T',
               p_next            => 'T',
               p_version_date    => cwms_util.non_versioned,
               p_max_version     => 'T',
               p_office_id       => l_office_id);
            fetch l_ts_cur bulk collect into l_dates, l_values, l_quality;
            close l_ts_cur;                                              
            l_ts := ztsv_array();
            l_ts.extend(l_dates.count);
            for i in 1..l_dates.count loop
               l_ts(i) := ztsv_type(l_dates(i), l_values(i), get_quality(l_rec));
            end loop;
            if l_ts is not null and l_ts.count > 0 then
               if l_ts(1).date_time < l_start_time_utc then
                  l_first := 2;
                  if l_ts(2).date_time > l_start_time_utc then
                     l_level_values.extend;
                     l_level_values(1) := ztsv_type(l_start_time_utc, null, get_quality(l_rec));
                     if l_rec.interpolate = 'T' then
                        a := 1;
                        b := 2;
                        l_level_values(1).value := l_ts(a).value + (l_start_time_utc  - l_ts(a).date_time) / (l_ts(b).date_time - l_ts(a).date_time) * (l_ts(b).value - l_ts(a).value);
                     else
                        l_level_values(1).value := l_ts(1).value;
                     end if;
                  end if;
               else
                  l_first := 1;
               end if;
               if l_ts(l_ts.count).date_time > l_end_time_utc then
                  l_last := l_ts.count - 1;
               else
                  l_last := l_ts.count;
               end if;
               for i in l_first..l_last loop
                  l_level_values.extend;
                  l_level_values(l_level_values.count) := l_ts(i);
               end loop;
               if l_ts(l_ts.count).date_time > l_end_time_utc then
                  if l_ts(l_ts.count - 1).date_time < l_end_time_utc then
                     l_level_values.extend;
                     l_level_values(l_level_values.count) := ztsv_type(l_end_time_utc, null, get_quality(l_rec));
                     if l_rec.interpolate = 'T' then
                        a := l_ts.count - 1;
                        b := l_ts.count;
                        l_level_values(l_level_values.count).value := l_ts(a).value + (l_end_time_utc  - l_ts(a).date_time) / (l_ts(b).date_time - l_ts(a).date_time) * (l_ts(b).value - l_ts(a).value);
                     else
                        l_level_values(l_level_values.count).value := l_ts(l_ts.count - 1).value;
                     end if;
                  end if;
               end if;
            end if;
         end;
      else
         --------------------
         -- constant value --
         --------------------
         l_value := l_rec.location_level_value * l_factor + l_offset;
         l_level_values.extend(2);
         l_level_values(1) := new ztsv_type(l_start_time_utc, l_value, get_quality(l_rec));
         l_level_values(2) := new ztsv_type(l_end_time_utc,   l_value, get_quality(l_rec));
      end if;
      if l_rec.expiration_date is not null then
         -----------------------------------------------------------------------------
         -- level has expiration date - see if it expires before end of time window --
         -----------------------------------------------------------------------------
         declare
            l_next   pls_integer;
            l_prev   pls_integer;
            l_values ztsv_array;
         begin
            select min(seq)
              into l_next
              from ( select date_time,
                            rownum as seq
                       from table(l_level_values)
                   )
             where date_time > l_rec.expiration_date;
             
            if l_next is not null then
               ---------------------------------------------
               -- level expires before end of time window --
               ---------------------------------------------
               if l_next = 1 then
                  ---------------------------------------------
                  -- level is expired for entire time window --
                  ---------------------------------------------
                  l_values := ztsv_array(
                     ztsv_type(l_level_values(1).date_time, null, get_quality(l_rec)),
                     ztsv_type(l_level_values(l_level_values.count).date_time, null, get_quality(l_rec)));
               else
                  ----------------------------------------------
                  -- level is expired for part of time window --
                  ----------------------------------------------
                  select ztsv_type(date_time, value, quality_code)
                    bulk collect
                    into l_values
                    from table(l_level_values)
                   where rownum < l_next; 
                   
                  l_prev := l_next - 1;
                  if l_rec.interpolate = 'T' then
                     declare
                        t  date := l_rec.expiration_date;
                        t1 date := l_level_values(l_prev).date_time;
                        t2 date := l_level_values(l_next).date_time;
                        v  binary_double;
                        v1 binary_double := l_level_values(l_prev).value;
                        v2 binary_double := l_level_values(l_next).value;
                     begin
                        v := v1 + (v2 - v1) * (t - t1) / (t2 - t1);
                        l_values.extend;
                        l_values(l_values.count) := ztsv_type(t-1/1440, v, get_quality(l_rec));
                     end;
                  else
                     l_values.extend;
                     l_values(l_values.count) := ztsv_type(l_rec.expiration_date-1/1440, l_level_values(l_prev).value, get_quality(l_rec));
                  end if;
                  l_values.extend(2);
                  l_values(l_values.count-1) := ztsv_type(l_rec.expiration_date, null, get_quality(l_rec));
                  l_values(l_values.count  ) := ztsv_type(l_level_values(l_level_values.count).date_time, null, get_quality(l_rec));
               end if;
               l_level_values := l_values;
            end if;
         end;
      end if;
      if instr(upper(p_parameter_id), 'ELEV') = 1 and l_rec.ts_code is null and not p_in_recursion then
         l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_level_units);
         if l_vert_datum_offset != 0 then
            for i in 1..l_level_values.count loop
               if l_level_values(i).value is not null then
                  l_level_values(i).value := l_level_values(i).value + l_vert_datum_offset;
               end if;
            end loop;
         end if;
      end if;
   end if;
   p_level_values := l_level_values;
end retrieve_loc_lvl_values_utc;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--          
-- Retreives a time series of Location Level values for a specified time window
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
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
   l_office_id    varchar2(16);
   l_timezone_id  varchar2(28);
   l_start_time   date;
   l_end_time     date;
   l_level_values ztsv_array;
begin
   -----------------------------------------------------------
   -- get the start and end times of the time window in UTC --
   -----------------------------------------------------------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_timezone_id := nvl(p_timezone_id, cwms_loc.get_local_timezone(p_location_id, l_office_id)); 
   if p_start_time is null then
      l_start_time := cast(systimestamp at time zone 'UTC' as date);
   else
      l_start_time := cast(
               from_tz(cast(p_start_time as timestamp), l_timezone_id)
               at time zone 'UTC' as date);
   end if;
   if p_end_time is null then
      l_end_time := null;
   else
      l_end_time := cast(
               from_tz(cast(p_end_time as timestamp), l_timezone_id)
               at time zone 'UTC' as date);
   end if;
   -----------------------------------------------
   -- retrieve the location level values in UTC --
   -----------------------------------------------
   retrieve_loc_lvl_values_utc(
      p_level_values            =>  p_level_values,
      p_location_id             =>  p_location_id,
      p_parameter_id            =>  p_parameter_id,
      p_parameter_type_id       =>  p_parameter_type_id,
      p_duration_id             =>  p_duration_id,
      p_spec_level_id           =>  p_spec_level_id,
      p_level_units             =>  p_level_units,
      p_start_time_utc          =>  l_start_time,
      p_end_time_utc            =>  l_end_time,
      p_attribute_value         =>  p_attribute_value,
      p_attribute_units         =>  p_attribute_units,
      p_attribute_parameter_id  =>  p_attribute_parameter_id,
      p_attribute_param_type_id =>  p_attribute_param_type_id,
      p_attribute_duration_id   =>  p_attribute_duration_id,
      p_office_id               =>  p_office_id);
     
   -------------------------------------------------------   
   -- convert the times back to the specified time zone --
   -------------------------------------------------------
   select ztsv_type(cwms_util.change_timezone(date_time, 'UTC', l_timezone_id), value, quality_code)
     bulk collect
     into l_level_values
     from table(p_level_values);
     
   p_level_values := l_level_values;        
end retrieve_location_level_values;   
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--          
-- Retreives a time series of Location Level values for a specified time window
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
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
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
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
-- p_start_time should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_end_time should be specified as 'yyyy/mm/dd hh:mm:ss'
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
-- p_start_time should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_end_time should be specified as 'yyyy/mm/dd hh:mm:ss'
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
   return varchar2 -- recordset of (date, value) records
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
            

procedure retrieve_loc_lvl_values3(
   p_level_values            out ztsv_array,
   p_specified_times         in  ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_utc_dates    date_table_type;
   l_min_date_utc date;
   l_max_date_utc date;
   l_level_id_parts str_tab_t;
   l_attr_id_parts  str_tab_t;
   l_level_values ztsv_array;
   l_date_offset  number;  
   l_date_offsets number_tab_t;
   l_values       double_tab_t;
   l_quality      number_tab_t; 
   l_seq_props    cwms_lookup.sequence_properties_t;
   l_hi_idx       pls_integer;
   l_lo_idx       pls_integer;
   l_log_used     boolean; 
   l_ratio        number;
begin
   if p_specified_times is not null then 
      -------------------------------------------------- 
      -- collect the times and the time window in UTC --
      -------------------------------------------------- 
      select cwms_util.change_timezone(date_time, p_timezone_id, 'UTC')
        bulk collect
        into l_utc_dates
        from table(p_specified_times);
        
      select min(column_value),
             max(column_value)
        into l_min_date_utc,
             l_max_date_utc
        from table(l_utc_dates);
      ---------------------------------------------------------                              
      -- get the location level values the level breakpoints --
      ---------------------------------------------------------                              
      l_level_id_parts := cwms_util.split_text(p_location_level_id, '.');
      if p_attribute_id is null then
         l_attr_id_parts := str_tab_t(null, null, null);
      else
         l_attr_id_parts :=  cwms_util.split_text(p_attribute_id, '.'); 
      end if;                                           
      retrieve_loc_lvl_values_utc(
         p_level_values            => l_level_values,
         p_location_id             => l_level_id_parts(1),
         p_parameter_id            => l_level_id_parts(2),
         p_parameter_type_id       => l_level_id_parts(3),
         p_duration_id             => l_level_id_parts(4),
         p_spec_level_id           => l_level_id_parts(5),
         p_level_units             => p_level_units,
         p_start_time_utc          => l_min_date_utc,
         p_end_time_utc            => l_max_date_utc,
         p_attribute_value         => p_attribute_value,
         p_attribute_units         => p_attribute_units,
         p_attribute_parameter_id  => l_attr_id_parts(1),
         p_attribute_param_type_id => l_attr_id_parts(2),
         p_attribute_duration_id   => l_attr_id_parts(3),
         p_office_id               => p_office_id); 
      -----------------------------------------          
      -- set up variables to do lookups with --
      -----------------------------------------          
      select date_time - l_min_date_utc,
             value,
             quality_code
        bulk collect
        into l_date_offsets,
             l_values,
             l_quality 
        from table(l_level_values);
      l_seq_props := cwms_lookup.analyze_sequence(l_date_offsets);
      -------------------------------------------- 
      -- do the lookups for the specified times --
      -------------------------------------------- 
      p_level_values := ztsv_array();
      p_level_values.extend(p_specified_times.count);
      for i in 1..p_specified_times.count loop
         p_level_values(i) := ztsv_type(p_specified_times(i).date_time, null, 0);
         l_date_offset := l_utc_dates(i) - l_min_date_utc;
         l_hi_idx := cwms_lookup.find_high_index(l_date_offset, l_date_offsets, l_seq_props);
         l_lo_idx := l_hi_idx -1 ;
         l_ratio  := cwms_lookup.find_ratio(
            p_log_used                => l_log_used, 
            p_value                   => l_date_offset, 
            p_sequence                => l_date_offsets, 
            p_high_index              => l_hi_idx, 
            p_increasing              => l_seq_props.increasing_range, 
            p_in_range_behavior       => cwms_lookup.method_linear, 
            p_out_range_low_behavior  => cwms_lookup.method_null,   -- set values to null before earliest effective date 
            p_out_range_high_behavior => cwms_lookup.method_linear);
         if l_ratio is not null then
            if l_level_values(l_lo_idx).quality_code = 0 then
               ----------------------
               -- no interpolation --
               ----------------------
               p_level_values(i).value := l_level_values(l_lo_idx).value; 
            else
               -------------------
               -- interpolation --
               -------------------
               p_level_values(i).value := l_level_values(l_lo_idx).value + l_ratio * (l_level_values(l_hi_idx).value - l_level_values(l_lo_idx).value); 
            end if;
         end if;
      end loop;
      ---------------------------------------------------------      
      -- filter out any times before earliest effective date --
      ---------------------------------------------------------      
      select ztsv_type(date_time, value, quality_code)
        bulk collect
        into l_level_values
        from table(p_level_values)
       where value is not null;
      p_level_values := l_level_values;                        
   end if;
end retrieve_loc_lvl_values3;   
   

function retrieve_loc_lvl_values3(
   p_specified_times         in  ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array
is
   l_level_values ztsv_array;
begin
   retrieve_loc_lvl_values3(
      l_level_values,
      p_specified_times,
      p_location_level_id,
      p_level_units,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   return l_level_values;      
end retrieve_loc_lvl_values3;   

procedure retrieve_loc_lvl_values3(
   p_level_values            out double_tab_t,
   p_specified_times         in  date_table_type,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
begin
   if p_specified_times is not null then
      p_level_values := double_tab_t();
      p_level_values.extend(p_specified_times.count);
      for i in 1..p_specified_times.count loop
         p_level_values(i) := 
            retrieve_location_level_value(
               p_location_level_id, 
               p_level_units, 
               p_specified_times(i), 
               p_attribute_id, 
               p_attribute_value, 
               p_attribute_units, 
               p_timezone_id, 
               p_office_id);                           
      end loop;
   end if;
end retrieve_loc_lvl_values3;

function retrieve_loc_lvl_values3(
   p_specified_times         in  date_table_type,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return double_tab_t
is
   l_level_values double_tab_t;
begin
   retrieve_loc_lvl_values3(
      l_level_values,
      p_specified_times,
      p_location_level_id,
      p_level_units,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   return l_level_values;      
end retrieve_loc_lvl_values3;

procedure retrieve_loc_lvl_values3(
   p_level_values            out ztsv_array,
   p_ts_id                   in  varchar2,
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
   l_cursor          sys_refcursor;
   l_specified_times date_table_type;
   l_level_values    double_tab_t;
   l_quality_codes   number_tab_t;
begin
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_cursor,
      p_cwms_ts_id      => p_ts_id, 
      p_units           => cwms_util.get_default_units(cwms_util.split_text(p_ts_id, 2, '.')), 
      p_start_time      => p_start_time, 
      p_end_time        => p_end_time, 
      p_time_zone       => p_timezone_id, 
      p_trim            => 'T', 
      p_start_inclusive => 'T', 
      p_end_inclusive   => 'T', 
      p_previous        => 'F', 
      p_next            => 'F', 
      p_version_date    => cwms_util.non_versioned, 
      p_max_version     => 'T', 
      p_office_id       => p_office_id);
   fetch l_cursor
     bulk collect
     into l_specified_times,
          l_level_values,
          l_quality_codes;
          
   close l_cursor;
   
   l_level_values := cwms_level.retrieve_loc_lvl_values3(
      p_specified_times   => l_specified_times, 
      p_location_level_id => p_location_level_id, 
      p_level_units       => p_level_units, 
      p_attribute_id      => p_attribute_id, 
      p_attribute_value   => p_attribute_value, 
      p_attribute_units   => p_attribute_units, 
      p_timezone_id       => p_timezone_id, 
      p_office_id         => p_office_id);
      
   p_level_values := ztsv_array();
   p_level_values.extend(l_level_values.count);
   for i in 1..l_level_values.count loop
      p_level_values(i) := ztsv_type(l_specified_times(i), l_level_values(i), 0);
   end loop;                
      
end retrieve_loc_lvl_values3;   

function retrieve_loc_lvl_values3(
   p_ts_id                   in  varchar2,
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
   l_level_values ztsv_array;
begin
   retrieve_loc_lvl_values3(
      l_level_values,
      p_ts_id,
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
end retrieve_loc_lvl_values3;   

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--          
-- Retreives a time series of Location Level values for a specified time window
-- for a specified Time Series Identifier and Specified Level Identifier
--          
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
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
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
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
   return number
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
      l_attribute_values(l_attribute_values.count) := cwms_rounding.round_f(rec.attribute_value, 9);
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
-- p_date should be specified as 'yyyy/mm/dd hh:mm:ss'
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
      if i = l_attribute_values.count then
         p_attribute_values := p_attribute_values || to_char(l_attribute_values(i));
      else
         p_attribute_values := p_attribute_values || to_char(l_attribute_values(i)) || cwms_util.record_separator;
      end if;
   end loop;
end retrieve_location_level_attrs2;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs2
--          
-- Returns a table of attribute values for a Location Level in effect at a
-- specified time using only text and numeric parameters
--          
-- p_date should be specified as 'yyyy/mm/dd hh:mm:ss'
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
   return varchar2
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
end retrieve_location_level_attrs2;        
            
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
   p_in_range_behavior       in  integer default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number
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
         null,
         p_in_range_behavior,
         p_out_range_behavior,
         p_out_range_behavior);
   else     
      l_value := cwms_lookup.lookup(
         p_value,
         l_levels,
         l_attrs,
         null,
         p_in_range_behavior,
         p_out_range_behavior,
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
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
procedure lookup_level_by_attribute(
   p_level                   out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
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
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
function lookup_level_by_attribute(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number
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
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
procedure lookup_attribute_by_level(
   p_attribute               out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
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
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
function lookup_attribute_by_level(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number
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
-- PROCEDURE rename_location_level
--------------------------------------------------------------------------------
procedure rename_location_level(
   p_old_location_level_id in  varchar2,
   p_new_location_level_id in  varchar2,
   p_office_id             in  varchar2 default null)
is
   l_office_code              number(10) := cwms_util.get_db_office_code(p_office_id);
   l_old_parts                str_tab_t; 
   l_new_parts                str_tab_t; 
   l_old_location_code        number(10);
   l_old_parameter_code       number(10);
   l_old_parameter_type_code  number(10);
   l_old_duration_code        number(10);  
   l_old_specified_level_code number(10);
   l_new_location_code        number(10);
   l_new_parameter_code       number(10);
   l_new_parameter_type_code  number(10);
   l_new_duration_code        number(10);
   l_new_specified_level_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_old_location_level_id is null or
      p_new_location_level_id is null
   then   
      cwms_err.raise(
         'ERROR',
         'Location Level IDs must not be null.');
   end if;
   l_old_parts := cwms_util.split_text(p_old_location_level_id, '.');
   if l_old_parts.count != 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_old_location_level_id,
         'Location Level ID');
   end if;
   l_new_parts := cwms_util.split_text(p_new_location_level_id, '.');
   if l_new_parts.count != 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_new_location_level_id,
         'Location Level ID');
   end if;
   -------------------------------
   -- get the codes for the ids --
   -------------------------------
   begin
      select pl.location_code
        into l_old_location_code
        from at_physical_location pl,
             at_base_location bl
       where bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id) = cwms_util.get_base_id(upper(l_old_parts(1)))
         and upper(nvl(pl.sub_location_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_old_parts(1))), '.') 
         and bl.db_office_code = l_office_code;
         
      select p.parameter_code
        into l_old_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where bp.base_parameter_code = p.base_parameter_code
         and upper(bp.base_parameter_id) = cwms_util.get_base_id(upper(l_old_parts(2)))
         and upper(nvl(p.sub_parameter_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_old_parts(2))), '.') 
         and p.db_office_code in (l_office_code, cwms_util.db_office_code_all);

      select parameter_type_code
        into l_old_parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(l_old_parts(3));

      select duration_code
        into l_old_duration_code
        from cwms_duration
       where upper(duration_id) = upper(l_old_parts(4));

      select specified_level_code
        into l_old_specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(l_old_parts(5))
         and office_code in(l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_old_location_level_id,
            'Location Level ID');
   end;
   begin
      select pl.location_code
        into l_new_location_code
        from at_physical_location pl,
             at_base_location bl
       where bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id) = cwms_util.get_base_id(upper(l_new_parts(1)))
         and upper(nvl(pl.sub_location_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_new_parts(1))), '.') 
         and bl.db_office_code = l_office_code;
         
      select p.parameter_code
        into l_new_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where bp.base_parameter_code = p.base_parameter_code
         and upper(bp.base_parameter_id) = cwms_util.get_base_id(upper(l_new_parts(2)))
         and upper(nvl(p.sub_parameter_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_new_parts(2))), '.') 
         and p.db_office_code in (l_office_code, cwms_util.db_office_code_all);

      select parameter_type_code
        into l_new_parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(l_new_parts(3));

      select duration_code
        into l_new_duration_code
        from cwms_duration
       where upper(duration_id) = upper(l_new_parts(4));

      select specified_level_code
        into l_new_specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(l_new_parts(5))
         and office_code in(l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_new_location_level_id,
            'Location Level ID');
   end;
   ----------------------        
   -- update the table --
   ----------------------
   update at_location_level
      set location_code        = l_new_location_code,
          parameter_code       = l_new_parameter_code,        
          parameter_type_code  = l_new_parameter_type_code,        
          duration_code        = l_new_duration_code,        
          specified_level_code = l_new_specified_level_code
    where location_code        = l_old_location_code
      and parameter_code       = l_old_parameter_code        
      and parameter_type_code  = l_old_parameter_type_code        
      and duration_code        = l_old_duration_code        
      and specified_level_code = l_old_specified_level_code;
                
end rename_location_level;   


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
begin
   delete_location_level_ex(
      p_location_level_id,
      p_effective_date,
      p_timezone_id,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_cascade,
      'F',
      p_office_id);
end delete_location_level;

procedure delete_location_level(
   p_location_level_code in integer,
   p_cascade             in  varchar2 default ('F'))
is
begin
   delete_location_level_ex(
      p_location_level_code,
      p_cascade,
      'F');
end delete_location_level;   

procedure delete_location_level_ex(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_delete_indicators       in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null)
is
   l_location_level_code       number(10);
   l_location_id               varchar2(49);
   l_parameter_id              varchar2(49);
   l_parameter_type_id         varchar2(16);
   l_duration_id               varchar2(16);
   l_spec_level_id             varchar2(256);
   l_date                      date;
   l_attribute_parameter_id    varchar2(49);
   l_attribute_param_type_id   varchar2(16);
   l_attribute_duration_id     varchar2(16); 
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
          
   delete_location_level_ex(
      l_location_level_code,
      p_cascade,
      p_delete_indicators);
        
end delete_location_level_ex;

procedure delete_location_level_ex(
   p_location_level_code in integer,
   p_cascade             in  varchar2 default ('F'),
   p_delete_indicators   in  varchar2 default ('F'))
is
   l_location_code             number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_specified_level_code      number(10);
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
   l_attribute_value           number;
   l_cascade                   boolean := cwms_util.return_true_or_false(p_cascade);
   l_delete_indicators         boolean := cwms_util.return_true_or_false(p_delete_indicators);
   l_seasonal_count            pls_integer;
   l_level_count               pls_integer;
   l_indicator_count           pls_integer;
   l_parameter_code            number(10);
begin
   ----------------------------------------------------
   -- check for seasonal records and p_cascase = 'F' --
   ----------------------------------------------------
   select count(*)
     into l_seasonal_count
     from at_seasonal_location_level
    where location_level_code = p_location_level_code;
   if l_seasonal_count > 0 and not l_cascade then
      declare
         ll location_level_t := location_level_t(zlocation_level_t(p_location_level_code));
      begin
         cwms_err.raise(
            'ERROR',
            'Cannot delete location level '
            ||ll.office_id || '/'
            ||ll.location_id || '.'
            ||ll.parameter_id || '.'
            ||ll.parameter_type_id || '.'
            ||ll.duration_id || '.'
            ||ll.specified_level_id
            || case
                  when ll.attribute_value is null then
                     null
                  else
                     ' ('||ll.attribute_value || ' ' || ll.attribute_units_id || ')'
               end
            || '@' || ll.level_date
            || ' with p_cascade = ''F''');
      end;
   end if;
   ------------------------------------------------------------------------------------    
   -- check for indicators and p_delete_indicators = 'F' and no more matching levels --
   ------------------------------------------------------------------------------------    
   select location_code,
          parameter_code,
          parameter_type_code,
          duration_code,
          specified_level_code,
          attribute_parameter_code,
          attribute_parameter_type_code,
          attribute_duration_code,
          attribute_value
     into l_location_code,
          l_parameter_code,
          l_parameter_type_code,
          l_duration_code,
          l_specified_level_code,
          l_attribute_parameter_code,
          l_attribute_param_type_code,
          l_attribute_duration_code,
          l_attribute_value
     from at_location_level            
    where location_level_code = p_location_level_code;
    
   select count(*)
     into l_level_count
     from at_location_level
    where location_code = l_location_code
      and parameter_code = l_parameter_code
      and parameter_type_code = l_parameter_type_code
      and specified_level_code = l_specified_level_code
      and nvl(attribute_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
      and nvl(attribute_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
      and nvl(attribute_duration_code, -1) = nvl(l_attribute_duration_code, -1)
      and nvl(cwms_rounding.round_dt_f(attribute_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@');
   if l_level_count > 1 then
      l_indicator_count := 0;
   else
      select count(*)
        into l_indicator_count
        from at_loc_lvl_indicator
       where location_code = l_location_code
         and parameter_code = l_parameter_code
         and parameter_type_code = l_parameter_type_code
         and specified_level_code = l_specified_level_code
         and nvl(attr_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
         and nvl(attr_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
         and nvl(attr_duration_code, -1) = nvl(l_attribute_duration_code, -1)
         and nvl(cwms_rounding.round_nt_f(attr_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@');          
   end if;                
   if l_indicator_count > 0 and not l_delete_indicators then
      declare
         ll location_level_t := location_level_t(zlocation_level_t(p_location_level_code));
      begin
         cwms_err.raise(
            'ERROR',
            'Cannot delete location level '
            ||ll.office_id || '/'
            ||ll.location_id || '.'
            ||ll.parameter_id || '.'
            ||ll.parameter_type_id || '.'
            ||ll.duration_id || '.'
            ||ll.specified_level_id
            || case
                  when ll.attribute_value is null then
                     null
                  else
                     ' ('||ll.attribute_value || ' ' || ll.attribute_units_id || ')'
               end
            || '@' || ll.level_date
            || ' with p_delete_indicators = ''F''');
      end;
   end if;    
   ---------------------------------
   -- delete any seasonal records --
   ---------------------------------
   if l_seasonal_count > 0 then
      delete
        from at_seasonal_location_level
       where location_level_code = p_location_level_code;
   end if;
   --------------------------------------    
   -- delete any associated indicators --
   --------------------------------------
   if l_indicator_count > 0 then
      begin
         select location_code,
                parameter_code,
                parameter_type_code,
                duration_code,
                specified_level_code,
                attribute_parameter_code,
                attribute_parameter_type_code,
                attribute_duration_code,
                attribute_value
           into l_location_code,
                l_parameter_code,
                l_parameter_type_code,
                l_duration_code,
                l_specified_level_code,
                l_attribute_parameter_code,
                l_attribute_param_type_code,
                l_attribute_duration_code,
                l_attribute_value
           from at_location_level           
          where location_level_code = p_location_level_code;
         delete
           from at_loc_lvl_indicator_cond
          where level_indicator_code in 
                (  select level_indicator_code
                     from at_loc_lvl_indicator
                    where location_code = l_location_code
                      and parameter_code = l_parameter_code
                      and parameter_type_code = l_parameter_type_code
                      and specified_level_code = l_specified_level_code
                      and nvl(attr_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
                      and nvl(attr_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
                      and nvl(attr_duration_code, -1) = nvl(l_attribute_duration_code, -1)
                      and nvl(cwms_rounding.round_dt_f(attr_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@')
                );
         delete
           from at_loc_lvl_indicator
          where location_code = l_location_code
            and parameter_code = l_parameter_code
            and parameter_type_code = l_parameter_type_code
            and specified_level_code = l_specified_level_code
            and nvl(attr_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
            and nvl(attr_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
            and nvl(attr_duration_code, -1) = nvl(l_attribute_duration_code, -1)
            and nvl(cwms_rounding.round_nt_f(attr_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@');          
      exception
         when no_data_found then null;
      end;
   end if;
   -------------------------------
   -- delete the location level --
   -------------------------------
   delete
     from at_location_level
    where location_level_code = p_location_level_code;
end delete_location_level_ex;   

            
--------------------------------------------------------------------------------
-- PROCEDURE cat_location_levels
--
-- in this procedure SQL- (%, _) or glob-style (*, ?) wildcards can be used
-- in masks, and all masks are case insensitive
--
-- muilt-part masks need not specify all the parts if a partial mask will match
-- all desired results 
--
-- p_cursor
--   the cursor that is opened by this procedure. it must be manually closed
--   after use.
--
-- p_location_level_id_mask
--   a wildcard mask of the five-part location level identifier.  defaults
--   to matching every location level identifier
--
-- p_attribute_id_mask
--   a wildcard mask of the three-part attribute identifier.  null attribute
--   identifiers are matched by '*' (or '%'), to match ONLY null attributes, 
--   specify null for this parameter.  defaults to matching all attribute
--   identifiers
--
-- p_office_id_mask
--   a wildcard mask of the office identifier that owns the location levels.
--   specify '*' (or '%') for this parameter to match every office identifier.
--   defaults to matching only the calling user's office identifier
--
-- p_timezone_id
--   the time zone in which location level dates are to be represented in the
--   cursor opened by this procedure.  defaults to 'UTC'
--
-- p_unit_system
--   the unit system in which the attribute values are to be represented in the
--   cursor opened by this procedure.  The actual units will be determined by
--   the entry in the AT_DISPLAY_UNITS table for the office that owns the 
--   location level and the attribute parameter. defaults to SI
--
-- The cursor opened by this routine contains six fields:
--    1 : office_id           varchar2(16)
--    2 : location_level_id   varchar2(390)
--    3 : attribute_id        varchar2(83)
--    4 : attribute_value     binary_double
--    5 : attribute_unit      varchar2(16)
--    6 : location_level_date date
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure cat_location_levels(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2 default '*',
   p_attribute_id_mask      in  varchar2 default '*',
   p_office_id_mask         in  varchar2 default null,
   p_timezone_id            in  varchar2 default 'UTC',
   p_unit_system            in  varchar2 default 'SI')
is          
   l_parts                    str_tab_t;
   l_count                    binary_integer;
   l_office_id_mask           varchar2(16);
   l_location_mask            varchar2(49);
   l_parameter_mask           varchar2(49);
   l_parameter_type_mask      varchar2(16);
   l_duration_mask            varchar2(16);
   l_specified_level_mask     varchar2(256);
   l_attr_parameter_mask      varchar2(49);
   l_attr_parameter_type_mask varchar2(16);
   l_attr_duration_mask       varchar2(16);
   l_query_str                varchar2(32767);
begin       
   -------------------------------------------------------
   -- process the office id mask (NULL = user's office) --
   -------------------------------------------------------
   l_office_id_mask := cwms_util.normalize_wildcards(upper(p_office_id_mask));
   if l_office_id_mask is null then
      l_office_id_mask := cwms_util.user_office_id;
   end if;  
   ---------------------------------------------------------------
   -- process the location level id mask into constituent parts --
   ---------------------------------------------------------------
   l_parts := cwms_util.split_text(p_location_level_id_mask, '.');
   l_count := l_parts.count;
   if l_count < 5 then
      l_parts.extend(5 - l_count);
      for i in l_count+1..5 loop
         l_parts(i) := '*';
      end loop;
   elsif l_parts.count > 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_location_level_id_mask,
         'location level identifier mask (too many parts).');
   end if;  
   l_location_mask        := cwms_util.normalize_wildcards(upper(l_parts(1)));
   l_parameter_mask       := cwms_util.normalize_wildcards(upper(l_parts(2)));
   l_parameter_type_mask  := cwms_util.normalize_wildcards(upper(l_parts(3)));
   l_duration_mask        := cwms_util.normalize_wildcards(upper(l_parts(4)));
   l_specified_level_mask := cwms_util.normalize_wildcards(upper(l_parts(5)));
   ----------------------------------------------------------
   -- process the attribute id mask into constituent parts --
   ----------------------------------------------------------
   if p_attribute_id_mask is not null then
      l_parts := cwms_util.split_text(p_attribute_id_mask, '.');
      l_count := l_parts.count;
      if l_count < 3 then
         l_parts.extend(3 - l_count);
         for i in l_count+1..3 loop
            l_parts(i) := '*';
         end loop;
      elsif l_count > 3 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_attribute_id_mask,
            'attribute identifier mask (too many parts).');
      end if;  
      l_attr_parameter_mask      := cwms_util.normalize_wildcards(upper(l_parts(1)));
      l_attr_parameter_type_mask := cwms_util.normalize_wildcards(upper(l_parts(2)));
      l_attr_duration_mask       := cwms_util.normalize_wildcards(upper(l_parts(3)));
   end if;
   ---------------------
   -- build the query --
   ---------------------
   l_query_str :=    
     'select office_id,
             location_level_id,
             attribute_parameter_id
             || substr(''.'', 1, length(attribute_parameter_type_id))
             || attribute_parameter_type_id
             || substr(''.'', 1, length(attribute_duration_id))
             ||attribute_duration_id as attribute_parameter_type_id,
             cwms_rounding.round_f(
                case
                when attr_base_parameter_id =  ''Elev'' then
                   attribute_value * factor + offset + cwms_loc.get_vertical_datum_offset(location_code, attribute_unit_id)
                else
                   attribute_value * factor + offset
                end, 9) as attribute_value,
             attribute_unit_id,
             cwms_util.change_timezone(location_level_date, ''UTC'', :p_timezone_id)
        from (  (  select o.office_code as office_code1,
                          o.office_id as office_id,
                          pl.location_code,
                          bl.base_location_id
                          || substr(''-'', 1, length(pl.sub_location_id))
                          || pl.sub_location_id
                          || ''.''
                          || bp1.base_parameter_id
                          || substr(''-'', 1, length(p1.sub_parameter_id))
                          || p1.sub_parameter_id
                          || ''.''
                          || pt1.parameter_type_id
                          || ''.''
                          || d1.duration_id
                          || ''.''
                          || sl.specified_level_id as location_level_id,
                          ll.attribute_parameter_code as attr_parameter_code1,
                          ll.attribute_parameter_type_code as attr_parameter_type_code1,
                          ll.attribute_duration_code as attr_duration_code1,
                          ll.attribute_value,
                          ll.location_level_date
                     from at_location_level ll,
                          at_physical_location pl,
                          at_base_location bl,
                          cwms_office o,
                          cwms_base_parameter bp1,
                          at_parameter p1,
                          cwms_parameter_type pt1,
                          cwms_duration d1,
                          at_specified_level sl
                    where pl.location_code = ll.location_code
                      and bl.base_location_code = pl.base_location_code
                      and o.office_code = bl.db_office_code
                      and upper(o.office_id) like :l_office_id_mask escape ''\''
                      and upper(bl.base_location_id
                          || substr(''-'', 1, length(pl.sub_location_id))
                          || pl.sub_location_id) like :l_location_mask escape ''\''
                      and p1.parameter_code = ll.parameter_code
                      and bp1.base_parameter_code = p1.base_parameter_code
                      and upper(bp1.base_parameter_id
                          || substr(''-'', 1, length(p1.sub_parameter_id))
                          || p1.sub_parameter_id) like :l_parameter_mask escape ''\''
                      and pt1.parameter_type_code = ll.parameter_type_code
                      and upper(pt1.parameter_type_id) like :l_parameter_type_mask escape ''\''
                      and d1.duration_code = ll.duration_code
                      and upper(d1.duration_id) like :l_duration_mask escape ''\''
                      and sl.specified_level_code = ll.specified_level_code
                      and upper(sl.specified_level_id) like :l_specified_level_mask escape ''\''
                          -- the next clause evaluates to false only when the 
                          -- attribute mask is null and the attribute code is non-null
                          -- (thus it filters out all levels with an attribute when
                          -- the attribute_mask is null)
                      and nvl(ll.attribute_parameter_code, -1) = 
                          decode(nvl(:l_attr_parameter_mask, ''.''), ''.'', -1, nvl(ll.attribute_parameter_code, -1))
                )
                left outer join
                (  select p2.parameter_code as attr_parameter_code2,
                          bp2.base_parameter_id as attr_base_parameter_id,
                          bp2.base_parameter_id
                          || substr(''-'', 1, length(p2.sub_parameter_id))
                          || p2.sub_parameter_id as attribute_parameter_id,
                          pt2.parameter_type_code as attr_parameter_type_code2,
                          pt2.parameter_type_id as attribute_parameter_type_id,
                          du.db_office_code as office_code2,
                          cu.to_unit_id as attribute_unit_id,
                          d2.duration_code as attr_duration_code2,
                          d2.duration_id as attribute_duration_id,
                          cu.factor as factor,
                          cu.offset as offset
                     from cwms_base_parameter bp2,
                          at_parameter p2,
                          cwms_parameter_type pt2,
                          cwms_duration d2,
                          at_display_units du,
                          cwms_unit_conversion cu
                    where bp2.base_parameter_code = p2.base_parameter_code
                      and upper(bp2.base_parameter_id
                          || substr(''-'', 1, length(p2.sub_parameter_id))
                          || p2.sub_parameter_id) like :l_attr_parameter_mask escape ''\''
                      and upper(pt2.parameter_type_id) like :l_attr_parameter_type_mask escape ''\''
                      and upper(d2.duration_id) like :l_attr_duration_mask escape ''\''
                      and du.parameter_code = p2.parameter_code
                      and du.unit_system = :p_unit_system
                      and cu.from_unit_code = bp2.unit_code
                      and cu.to_unit_code = du.display_unit_code
                ) on attr_parameter_code2 = attr_parameter_code1
                 and attr_parameter_type_code2 = attr_parameter_type_code1 
                 and attr_duration_code2 = attr_duration_code1
                 and office_code2 = office_code1
             )';
   ------------------------------------------------------------              
   -- change the outer join to an inner join if we specify a --
   -- non-null attribute mask that doesn't match everything  --
   -- (null attribute masks are handled in the decode(...)   --
   ------------------------------------------------------------              
   if l_attr_parameter_mask      != '%' or 
      l_attr_parameter_type_mask != '%' or 
      l_attr_duration_mask       != '%'
   then
      l_query_str := replace(l_query_str, 'left outer join', 'inner join');
   end if;
   --------------------------
   -- retrieve the catalog --
   --------------------------
   open p_cursor 
    for l_query_str 
  using p_timezone_id,
        l_office_id_mask,
        l_location_mask,
        l_parameter_mask,
        l_parameter_type_mask,
        l_duration_mask,
        l_specified_level_mask,
        l_attr_parameter_mask,
        l_attr_parameter_mask,
        l_attr_parameter_type_mask,
        l_attr_duration_mask,
        p_unit_system;

end cat_location_levels;
            
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
   return number
is          
   l_location_code            number(10);
   l_parameter_code           number(10);
   l_parameter_type_code      number(10);
   l_duration_code            number(10);
   l_specified_level_code     number(10);
   l_level_indicator_code     number(10);
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
      if instr(upper(p_attr_parameter_id), 'ELEV') = 1 then
         l_attr_value := cwms_rounding.round_f(p_attr_value * l_factor + l_offset - cwms_loc.get_vertical_datum_offset(l_location_code, p_attr_units_id), 12);
      else
         l_attr_value := cwms_rounding.round_f(p_attr_value * l_factor + l_offset, 12);
      end if;
   end if;  
   if p_ref_attr_value is not null then
      l_ref_attr_value := cwms_rounding.round_f(p_ref_attr_value * l_factor + l_offset, 12);
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
         and nvl(to_char(attr_value), '@') = nvl(to_char(l_attr_value), '@')
         and nvl(attr_parameter_code, -1) = nvl(l_attr_parameter_code, -1)
         and nvl(attr_parameter_type_code, -1) = nvl(l_attr_parameter_type_code, -1)
         and nvl(attr_duration_code, -1) = nvl(l_attr_duration_code, -1)
         and nvl(to_char(ref_attr_value), '@') = nvl(to_char(l_ref_attr_value), '@')
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
   return number
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
   p_rate_interval               in dsinterval_unconstrained default null,
   p_description                 in varchar2               default null,
   p_fail_if_exists              in varchar2               default 'F',
   p_ignore_nulls_on_update      in varchar2               default 'T')
is          
   l_fail_if_exists         boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls_on_update boolean := cwms_util.return_true_or_false(p_ignore_nulls_on_update);
   l_exists                 boolean := true;
   l_rec                    at_loc_lvl_indicator_cond%rowtype;
   l_unit_code              number(10);
   l_na_unit_code           number(10);
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
   select unit_code
     into l_na_unit_code
     from cwms_unit
    where unit_id = 'n/a';
   if l_rec.comparison_unit is not null and l_rec.comparison_unit != l_na_unit_code then
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
   p_minimum_duration         in  dsinterval_unconstrained default null,
   p_maximum_age              in  dsinterval_unconstrained default null,
   p_fail_if_exists           in  varchar2 default 'F',
   p_ignore_nulls_on_update   in  varchar2 default 'T')
is          
   l_fail_if_exists         boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls_on_update boolean := cwms_util.return_true_or_false(p_ignore_nulls_on_update);
   l_exists                 boolean := true;
   l_rec                    at_loc_lvl_indicator%rowtype;
   l_parameter_code         number(10);
   l_vert_datum_offset      binary_double;
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
      l_rec.attr_value               := nvl(cwms_rounding.round_f(p_attr_value, 12), l_rec.attr_value);
      l_rec.attr_parameter_code      := nvl(p_attr_parameter_code,      l_rec.attr_parameter_code);
      l_rec.attr_parameter_type_code := nvl(p_attr_parameter_type_code, l_rec.attr_parameter_type_code);
      l_rec.attr_duration_code       := nvl(p_attr_duration_code,       l_rec.attr_duration_code);
      l_rec.ref_specified_level_code := nvl(p_ref_specified_level_code, l_rec.ref_specified_level_code);
      l_rec.ref_attr_value           := nvl(cwms_rounding.round_f(p_ref_attr_value, 12), l_rec.ref_attr_value);
      l_rec.minimum_duration         := nvl(p_minimum_duration,         l_rec.minimum_duration);
      l_rec.maximum_age              := nvl(p_maximum_age,              l_rec.maximum_age);
   else     
      l_rec.location_code            := p_location_code;
      l_rec.parameter_code           := p_parameter_code;
      l_rec.parameter_type_code      := p_parameter_type_code;
      l_rec.duration_code            := p_duration_code;
      l_rec.specified_level_code     := p_specified_level_code;
      l_rec.level_indicator_id       := upper(p_level_indicator_id);
      l_rec.attr_value               := cwms_rounding.round_f(p_attr_value, 12);
      l_rec.attr_parameter_code      := p_attr_parameter_code;
      l_rec.attr_parameter_type_code := p_attr_parameter_type_code;
      l_rec.attr_duration_code       := p_attr_duration_code;
      l_rec.ref_specified_level_code := p_ref_specified_level_code;
      l_rec.ref_attr_value           := cwms_rounding.round_f(p_ref_attr_value, 12);
      l_rec.minimum_duration         := p_minimum_duration;
      l_rec.maximum_age              := p_maximum_age;
   end if;
   ----------------------------------------------------------
   -- adjust elevation attribute values for vertical datum --
   ----------------------------------------------------------
   begin
      select ap.parameter_code
        into l_parameter_code
        from at_parameter ap,
             cwms_base_parameter bp
       where ap.parameter_code = l_rec.attr_parameter_code
         and bp.base_parameter_code = ap.base_parameter_code
         and bp.base_parameter_id = 'Elev';
   exception
      when no_data_found then null;
   end;
   if l_parameter_code != null then
      l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(p_location_code, 'm');
      l_rec.attr_value := l_rec.attr_value - l_vert_datum_offset;
      l_rec.ref_attr_value := l_rec.ref_attr_value - l_vert_datum_offset;
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
   p_minimum_duration       in  dsinterval_unconstrained default null,
   p_maximum_age            in  dsinterval_unconstrained default null,
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
   p_minimum_duration       in  dsinterval_unconstrained default null,
   p_maximum_age            in  dsinterval_unconstrained default null,
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
-- PROCEDURE store_loc_lvl_indicator
--          
-- Creates or updates a Location Level Indicator in the database
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator(
   p_loc_lvl_indicator in  loc_lvl_indicator_t)
is
   l_loc_lvl_indicator loc_lvl_indicator_t;
begin
   l_loc_lvl_indicator := l_loc_lvl_indicator;
   l_loc_lvl_indicator.store;
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
   p_loc_lvl_indicator_id_mask  in  varchar2 default null,  -- '*.*.*.*.*.*' if null
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
      l_loc_lvl_indicator_id_mask = '*'
   then     
      l_loc_lvl_indicator_id_mask := '*.*.*.*.*.*';
   end if;  
   if l_attribute_id_mask is null or
      l_attribute_id_mask = '*'
   then     
      l_attribute_id_mask := '*.*.*';
   end if;  
   if l_attribute_id_mask = '*.*.*'
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
   l_office_id_mask          := upper(cwms_util.normalize_wildcards(l_office_id_mask));      
   l_location_id_mask        := upper(cwms_util.normalize_wildcards(l_location_id_mask));      
   l_parameter_id_mask       := upper(cwms_util.normalize_wildcards(l_parameter_id_mask));      
   l_param_type_id_mask      := upper(cwms_util.normalize_wildcards(l_param_type_id_mask));      
   l_duration_id_mask        := upper(cwms_util.normalize_wildcards(l_duration_id_mask));      
   l_spec_level_id_mask      := upper(cwms_util.normalize_wildcards(l_spec_level_id_mask));      
   l_level_indicator_id_mask := upper(cwms_util.normalize_wildcards(l_level_indicator_id_mask));      
   l_attr_parameter_id_mask  := upper(cwms_util.normalize_wildcards(l_attr_parameter_id_mask));      
   l_attr_param_type_id_mask := upper(cwms_util.normalize_wildcards(l_attr_param_type_id_mask));      
   l_attr_duration_id_mask   := upper(cwms_util.normalize_wildcards(l_attr_duration_id_mask));
            
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
            union all
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
                and lli.attr_parameter_code is not null
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
                          
end cat_loc_lvl_indicator_codes;   
            
--------------------------------------------------------------------------------
-- FUNCTION cat_loc_lvl_indicator_codes
--          
-- The returned cursor contains only the matching location_level_code
--          
--------------------------------------------------------------------------------
function cat_loc_lvl_indicator_codes(
   p_loc_lvl_indicator_id_mask in  varchar2 default null, -- '*.*.*.*.*.*' if null
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
--  17 : ref_attr_value         number
--  18 : conditions             sys_refcursor
--          
-- The cursor returned in field 18 contains 17 fields:
--   1 : level_indicator_value       integer  (1..5)
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
   l_office_id_mask              varchar2(16) := cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id));
   l_cwms_office_code            number(10)   := cwms_util.get_office_code('CWMS');
begin       
   cwms_level.parse_location_level_id(
      l_location_id_mask,
      l_parameter_id_mask,
      l_parameter_type_id_mask,
      l_duration_id_mask,
      l_specified_level_id_mask,
      cwms_util.normalize_wildcards(p_location_level_id_mask));
   cwms_level.parse_attribute_id(
      l_attr_parameter_id_mask,
      l_attr_parameter_type_id_mask,
      l_attr_duration_id_mask,
      cwms_util.normalize_wildcards(p_attribute_id_mask));
            
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
             cwms_rounding.round_f(attr_value * attr_param.factor + attr_param.offset, 9) as attr_value,
             minimum_duration,
             maximum_age,
             ref_specified_level_id,
             cwms_rounding.round_f(ref_attr_value * attr_param.factor + attr_param.offset, 9) as ref_attr_value,
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
              cwms_rounding.round_f(l_attr_value, 9),
              to_char(l_minimum_duration),            
              to_char(l_maximum_age),
              l_rate_of_change,
              l_ref_specified_level_id,
              cwms_rounding.round_f(l_ref_attribute_value, 9),
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
   p_minimum_duration       out dsinterval_unconstrained,
   p_maximum_age            out dsinterval_unconstrained,
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
-- PROCEDURE rename_loc_lvl_indicator
--          
-- Renames a Location Level Indicator
--------------------------------------------------------------------------------
procedure rename_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_new_indicator_id       in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is
   l_level_indicator_code number(10);   
begin
   l_level_indicator_code := cwms_level.get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id, 
      p_attr_value, 
      p_attr_units_id, 
      p_attr_id, 
      p_ref_specified_level_id, 
      p_ref_attr_value, 
      p_office_id); 

   update at_loc_lvl_indicator
      set level_indicator_id = p_new_indicator_id
    where level_indicator_code = l_level_indicator_code; 
end rename_loc_lvl_indicator;
     
function eval_level_indicator_expr(
   p_tsid                   in varchar2,
   p_start_time             in date,
   p_end_time               in date,      
   p_unit                   in varchar2,
   p_specified_level_id     in varchar2,
   p_indicator_id           in varchar2,
   p_attribute_id           in varchar2      default null,
   p_attribute_value        in binary_double default null,
   p_attribute_unit         in varchar2      default null,
   p_ref_specified_level_id in varchar2      default null,
   p_ref_attribute_value    in number        default null,
   p_time_zone              in varchar2      default null,
   p_condition_number       in integer       default 1,
   p_office_id              in varchar2      default null)
   return ztsv_array
is
   l_unit         varchar2(16);
   l_time_zone    varchar2(28);
   l_ts           ztsv_array;   
   l_parts        str_tab_t;
   l_indicator_id varchar2(512);
   c              sys_refcursor;
   l_date_time    timestamp with time zone;
   l_value        binary_double;
   l_quality      number;
begin
   l_unit := cwms_util.get_unit_id(p_unit);      
   l_time_zone := nvl(
      cwms_util.get_timezone(p_time_zone), 
      cwms_loc.get_local_timezone(cwms_util.split_text(p_tsid, 1, '.'), p_office_id));
      
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => c,      
      p_cwms_ts_id      => p_tsid, 
      p_units           => l_unit, 
      p_start_time      => p_start_time, 
      p_end_time        => p_end_time, 
      p_time_zone       => l_time_zone, 
      p_trim            => 'T', 
      p_start_inclusive => 'T', 
      p_end_inclusive   => 'T', 
      p_previous        => 'F', 
      p_next            => 'F', 
      p_version_date    => cwms_util.non_versioned, 
      p_max_version     => 'T', 
      p_office_id       => p_office_id);
      
   l_ts := ztsv_array();
   loop    
      fetch c into l_date_time, l_value, l_quality;
      exit when c%notfound;
      l_ts.extend();
      l_ts(l_ts.count) := ztsv_type(cast(l_date_time as date), l_value, l_quality);
   end loop;
   close c;      
      
   l_parts := cwms_util.split_text(p_tsid, '.');         
   l_indicator_id := cwms_util.join_text(
      str_tab_t(
         l_parts(1),
         l_parts(2),
         l_parts(3),
         l_parts(5),
         p_specified_level_id,
         p_indicator_id),
      '.');   
                                                 
   l_ts := eval_level_indicator_expr(
      p_ts                     => l_ts,  
      p_unit                   => l_unit,
      p_loc_lvl_indicator_id   => l_indicator_id,
      p_attribute_id           => p_attribute_id,
      p_attribute_value        => p_attribute_value,
      p_attribute_unit         => p_attribute_unit,
      p_ref_specified_level_id => p_ref_specified_level_id,
      p_ref_attribute_value    => p_ref_attribute_value,
      p_time_zone              => l_time_zone,
      p_condition_number       => p_condition_number,
      p_office_id              => p_office_id);
      
   return l_ts;      
end eval_level_indicator_expr;    

function eval_level_indicator_expr(
   p_ts                     in ztsv_array,  
   p_unit                   in varchar2,
   p_loc_lvl_indicator_id   in varchar2,
   p_attribute_id           in varchar2      default null,
   p_attribute_value        in binary_double default null,
   p_attribute_unit         in varchar2      default null,
   p_ref_specified_level_id in varchar2      default null,
   p_ref_attribute_value    in number        default null,
   p_time_zone              in varchar2      default null,
   p_condition_number       in integer       default 1,
   p_office_id              in varchar2      default null)
   return ztsv_array 
is
   l_indicator loc_lvl_indicator_t;
   l_values    double_tab_tab_t;
   l_results   ztsv_array;
begin
   l_indicator := retrieve_loc_lvl_indicator(
      p_loc_lvl_indicator_id   => p_loc_lvl_indicator_id, 
      p_attr_value             => p_attribute_value, 
      p_attr_units_id          => p_attribute_unit, 
      p_attr_id                => p_attribute_id, 
      p_ref_specified_level_id => p_ref_specified_level_id, 
      p_ref_attr_value         => p_ref_attribute_value, 
      p_office_id              => p_office_id);
   l_values := l_indicator.get_indicator_expr_values(
      p_ts        => p_ts,
      p_unit      => p_unit,
      p_condition => p_condition_number,
      p_eval_time => null,
      p_time_zone => p_time_zone);

   l_results := ztsv_array();
   l_results.extend(l_values.count);
   for i in 1..l_values.count loop
      l_results(i) := ztsv_type(p_ts(i).date_time, l_values(i)(1), 0);
   end loop;
   return l_results;
end eval_level_indicator_expr;
       
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
   l_tsid                   varchar2(183) := p_tsid;
   l_office_id              varchar2(16)  := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_specified_level_mask   varchar2(256) := nvl(p_specified_level_mask, '*');
   l_indicator_id_mask      varchar2(256) := nvl(p_indicator_id_mask, '*');
   l_unit_system            varchar2(2)   := nvl(p_unit_system, 'SI');
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
      '*.*.*',
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
             cwms_rounding.round_f(o.attr_value * cuc.factor + cuc.offset, 9) as attribute_value,
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
                   l_unit_system))
         and cuc.to_unit_id = cwms_util.get_default_units(
                nvl(o.attr_parameter_id, o.parameter_id), 
                l_unit_system)
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
   l_tsid                   varchar2(183) := p_tsid;
   l_office_id              varchar2(16)  := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_specified_level_mask   varchar2(256) := nvl(p_specified_level_mask, '*');
   l_indicator_id_mask      varchar2(256) := nvl(p_indicator_id_mask, '*');
   l_unit_system            varchar2(2)   := nvl(p_unit_system, 'SI');
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
      '*.*.*',
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
   select min(l_start_time-minimum_duration-2*maximum_age)
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
             cwms_rounding.round_f(o.attr_value * cuc.factor + cuc.offset, 9) as attribute_value,
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
                   l_unit_system))
         and cuc.to_unit_id = cwms_util.get_default_units(
                nvl(o.attr_parameter_id, o.parameter_id), 
                l_unit_system)
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
            
function retrieve_location_levels_f(
   p_names       in  varchar2,            
   p_format      in  varchar2,
   p_units       in  varchar2 default null,   
   p_datums      in  varchar2 default null,
   p_start       in  varchar2 default null,
   p_end         in  varchar2 default null, 
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
   return clob
is
   l_results     clob;
   l_date_time   date;
   l_query_time  integer;
   l_format_time integer;
   l_count       integer;
begin
   retrieve_location_levels(
      p_results     => l_results,
      p_date_time   => l_date_time,
      p_query_time  => l_query_time,
      p_format_time => l_format_time, 
      p_count       => l_count,
      p_names       => p_names,            
      p_format      => p_format,
      p_units       => p_units,   
      p_datums      => p_datums,
      p_start       => p_start,
      p_end         => p_end, 
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);
      
   return l_results;
end retrieve_location_levels_f;   
            
procedure retrieve_location_levels(
   p_results        out clob,
   p_date_time      out date,
   p_query_time     out integer,
   p_format_time    out integer, 
   p_count          out integer,
   p_names          in  varchar2 default null,            
   p_format         in  varchar2 default null,
   p_units          in  varchar2 default null,   
   p_datums         in  varchar2 default null,
   p_start          in  varchar2 default null,
   p_end            in  varchar2 default null, 
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   type rec_t is record(
      lvl_code    integer, 
      office     varchar2(16), 
      name       varchar2(512), 
      unit       varchar2(16), 
      attr_name  varchar2(128), 
      attr_value binary_double, 
      attr_unit  varchar2(16));
   type rec_tab_t is table of rec_t;
   type idx_t is table of str_tab_t index by varchar2(16);
   type bool_t is table of boolean index by varchar2(32767);
   type segment_t is record(first_index integer, last_index integer, interp varchar2(5));
   type seg_tab_t is table of segment_t;
   l_data             clob;  
   l_format           varchar2(16);
   l_names            str_tab_t;
   l_names_sql        str_tab_t; 
   l_units            str_tab_t;
   l_datums           str_tab_t;
   l_start            date;
   l_start_utc        date;
   l_end              date;  
   l_end_utc          date;
   l_timezone         varchar2(28);
   l_office_id        varchar2(16);
   l_parts            str_tab_t; 
   l_unit             varchar2(16);
   l_attr_unit        varchar2(16);
   l_datum            varchar2(16);  
   l_count            pls_integer := 0;
   l_unique_count     pls_integer := 0;
   l_name             varchar2(512);
   l_first            boolean;
   l_ts1              timestamp;
   l_ts2              timestamp;
   l_elapsed_query    interval day (0) to second (6);
   l_elapsed_format   interval day (0) to second (6);
   l_query_time       date; 
   l_attrs            str_tab_t;
   c                  sys_refcursor;
   l_lvlids           rec_tab_t := rec_tab_t();  
   l_lvlids2          idx_t;
   l_used             bool_t;
   l_text             varchar2(32767);
   l_text2            varchar2(32767);
   l_interp           pls_integer;
   l_estimated        boolean;
   l_level_values     ztsv_array_tab;
   l_code             pls_integer;
   l_segments         seg_tab_t;
   l_max_size         integer;
   l_max_time         interval day (0) to second (3);
   l_max_size_msg     varchar2(17) := 'MAX SIZE EXCEEDED';
   l_max_time_msg     varchar2(17) := 'MAX TIME EXCEEDED';
   
   function iso_duration(
      p_intvl in dsinterval_unconstrained)
      return varchar2
   is
      l_hours   integer := extract(hour   from p_intvl);
      l_minutes integer := extract(minute from p_intvl);
      l_seconds number  := extract(second from p_intvl);
      l_iso     varchar2(17) := 'PT';
   begin
      if l_hours > 0 then
         l_iso := l_iso || l_hours || 'H';
      end if;
      if l_minutes > 0 then
         l_iso := l_iso || l_minutes || 'M';
      end if;
      if l_seconds > 0 then
         l_iso := l_iso || trim(to_char(l_seconds, '90.999')) || 'S';
      end if;
      if l_iso = 'PT' then
         l_iso := l_iso || '0S';
      end if;
      return l_iso;
   end;
begin
   l_query_time := cast(systimestamp at time zone 'UTC' as date);
   l_max_size := to_number(cwms_properties.get_property('CWMS-RADAR', 'results.max-size', '5242880', 'CWMS')); -- 5 MB default
   l_max_time := to_dsinterval(cwms_properties.get_property('CWMS-RADAR', 'query.max-time', '00 00:00:30', 'CWMS')); -- 30 sec default
   ----------------------------
   -- process the parameters --
   ----------------------------
   -----------
   -- names --
   -----------
   if p_names is not null then
      l_names := cwms_util.split_text(p_names, '|');
      for i in 1..l_names.count loop
         l_names(i) := trim(l_names(i));
      end loop;
   end if;
   ------------
   -- format --
   ------------
   if p_format is null then
      l_format := 'TAB';
   else                 
      l_format := upper(trim(p_format));
      if l_format not in ('TAB','CSV','XML','JSON') then
         cwms_err.raise('INVALID_ITEM', l_format, 'time series response format');
      end if;
   end if;
   ------------
   -- office --
   ------------
   if p_office_id is null then
      l_office_id := '*';
   else               
      begin                                                                              
         l_office_id := upper(trim(p_office_id));
         select office_id into l_office_id from cwms_office where office_id = l_office_id;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_OFFICE_ID', l_office_id);
      end;
   end if;
   l_office_id := cwms_util.normalize_wildcards(l_office_id);
   if l_names is not null then
      ------------
      -- datums --
      ------------
      if p_datums is null then
         l_datums := str_tab_t();
         l_datums.extend(l_names.count);
         for i in 1..l_datums.count loop
            l_datums(i) := 'NATIVE';
         end loop;
      else
         l_datums := cwms_util.split_text(p_datums, '|');
         for i in 1..l_datums.count loop
            l_datums(i) := trim(l_datums(i));
            if upper(l_datums(i)) in ('NATIVE', 'NAVD88', 'NGVD29') then
               l_datums(i) := upper(l_datums(i));
            else
               cwms_err.raise('INVALID_ITEM', l_datums(i), 'time series response datum');
            end if; 
         end loop;
         l_count := l_datums.count - l_names.count; 
         if l_count > 0 then
            l_datums.trim(l_count);
         elsif l_count < 0 then
            l_datum := l_datums(l_datums.count);
            l_count := -l_count;
            l_datums.extend(l_count);
            for i in 1..l_count loop
               l_datums(l_datums.count - i + 1) := l_datum;
            end loop; 
         end if;
      end if;
   end if;
   -----------
   -- units --
   -----------
   if p_units is null then
      if l_names is null then
         l_unit := 'EN';
      else
         l_units := str_tab_t();
         l_units.extend(l_names.count);
         for i in 1..l_units.count loop
            l_units(i) := 'EN';
         end loop;
      end if;
   else
      l_units := cwms_util.split_text(p_units, '|');
      if l_names is null then
         if l_units.count > 1 or upper(l_units(1)) not in ('EN', 'SI') then
            cwms_err.raise('ERROR', 'P_units must be ''EN'' or ''SI'' if p_names is null');
         end if;
         l_unit := upper(l_units(1));
      else
         l_count := l_units.count - l_names.count; 
         if l_count > 0 then
            l_units.trim(l_count);
         elsif l_count < 0 then
            l_unit := l_units(l_units.count);
            l_count := -l_count;
            l_units.extend(l_count);
            for i in 1..l_count loop
               l_units(l_units.count - i + 1) := l_unit;
            end loop; 
         end if;
      end if;
   end if;   
   -----------------      
   -- time window --
   -----------------
   if p_timezone is null then
      l_timezone := 'UTC';
   else
      l_timezone := cwms_util.get_time_zone_name(trim(p_timezone));
      if l_timezone is null then
         cwms_err.raise('INVALID_ITEM', p_timezone, 'CWMS time zone name');
      end if;
   end if;
   if p_end is null then
      l_end_utc := sysdate;
      l_end     := cwms_util.change_timezone(l_end_utc, 'UTC', l_timezone);
   else
      l_end     := cast(from_tz(cwms_util.to_timestamp(p_end), l_timezone) as date);
      l_end_utc := cwms_util.change_timezone(l_end, l_timezone, 'UTC');
   end if;
   if p_start is null then
      l_start     := l_end - 1;
      l_start_utc := l_end_utc - 1;
   else
      l_start     := cast(from_tz(cwms_util.to_timestamp(p_start), l_timezone) as date);
      l_start_utc := cwms_util.change_timezone(l_start, l_timezone, 'UTC');
   end if;
   -----------------------
   -- retreive the data --
   -----------------------
   dbms_lob.createtemporary(l_data, true);
   begin
      if l_names is null then
         -----------------------------------------
         -- retrieve catalog of location levels --
         -----------------------------------------
         l_ts1 := systimestamp;
         l_elapsed_format := l_ts1 - l_ts1;
         select *
           bulk collect
           into l_lvlids
           from (select ll.location_level_code, 
                        o.office_id,
                        bl.base_location_id
                        ||substr('-', 1, length(pl.sub_location_id))
                        ||pl.sub_location_id
                        ||'.'
                        ||bp1.base_parameter_id
                        ||substr('-', 1, length(p1.sub_parameter_id))
                        ||p1.sub_parameter_id
                        ||'.'
                        ||pt1.parameter_type_id
                        ||'.'
                        ||d1.duration_id
                        ||'.'
                        ||sl.specified_level_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'EN')
                        when l_unit = 'SI' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'SI')
                        else
                          l_unit
                        end,
                        bp2.base_parameter_id
                        ||substr('-', 1, length(p2.sub_parameter_id))
                        ||p2.sub_parameter_id
                        ||substr('.', 1, length(pt2.parameter_type_id))
                        ||pt2.parameter_type_id
                        ||substr('.', length(d2.duration_id))
                        ||d2.duration_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.convert_units(
                              ll.attribute_value,
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'SI'),
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'EN'))
                        else
                           ll.attribute_value
                        end,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'EN')
                        else
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'SI')
                        end
                   from at_location_level ll,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_base_parameter bp1,
                        cwms_base_parameter bp2,
                        at_parameter p1,
                        at_parameter p2,
                        cwms_parameter_type pt1,
                        cwms_parameter_type pt2,
                        cwms_duration d1,
                        cwms_duration d2,
                        at_specified_level sl,
                        cwms_office o
                  where pl.location_code = ll.location_code
                    and p1.parameter_code = ll.parameter_code
                    and pt1.parameter_type_code = ll.parameter_type_code
                    and d1.duration_code = ll.duration_code
                    and sl.specified_level_code = ll.specified_level_code
                    and ll.location_level_date < l_end_utc
                    and (ll.expiration_date is null or 
                         ll.expiration_date > l_start_utc
                        )
                    and (get_next_effective_date(ll.location_level_code) is null or
                         get_next_effective_date(ll.location_level_code) > l_start_utc
                        ) 
                    and bl.base_location_code = pl.base_location_code
                    and bp1.base_parameter_code = p1.base_parameter_code
                    and o.office_code = bl.db_office_code
                    and o.office_id like l_office_id escape '\'
                    and p2.parameter_code(+) = ll.attribute_parameter_code
                    and bp2.base_parameter_code(+) = p2.base_parameter_code
                    and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
                    and d2.duration_code(+) = ll.attribute_duration_code
                 union 
                 select ll.location_level_code, 
                        o.office_id,
                        lga.loc_alias_id
                        ||'.'
                        ||bp1.base_parameter_id
                        ||substr('-', 1, length(p1.sub_parameter_id))
                        ||p1.sub_parameter_id
                        ||'.'
                        ||pt1.parameter_type_id
                        ||'.'
                        ||d1.duration_id
                        ||'.'
                        ||sl.specified_level_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'EN')
                        when l_unit = 'SI' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'SI')
                        else
                          l_unit
                        end,
                        bp2.base_parameter_id
                        ||substr('-', 1, length(p2.sub_parameter_id))
                        ||p2.sub_parameter_id
                        ||substr('.', 1, length(pt2.parameter_type_id))
                        ||pt2.parameter_type_id
                        ||substr('.', length(d2.duration_id))
                        ||d2.duration_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.convert_units(
                              ll.attribute_value,
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'SI'),
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'EN'))
                        else
                           ll.attribute_value
                        end,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'EN')
                        else
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'SI')
                        end
                   from at_location_level ll,
                        at_loc_category lc,
                        at_loc_group lg,
                        at_loc_group_assignment lga,
                        cwms_base_parameter bp1,
                        cwms_base_parameter bp2,
                        at_parameter p1,
                        at_parameter p2,
                        cwms_parameter_type pt1,
                        cwms_parameter_type pt2,
                        cwms_duration d1,
                        cwms_duration d2,
                        at_specified_level sl,
                        cwms_office o
                  where lga.location_code = ll.location_code
                    and p1.parameter_code = ll.parameter_code
                    and pt1.parameter_type_code = ll.parameter_type_code
                    and d1.duration_code = ll.duration_code
                    and sl.specified_level_code = ll.specified_level_code
                    and ll.location_level_date < l_end_utc
                    and (ll.expiration_date is null or 
                         ll.expiration_date > l_start_utc
                        )
                    and (get_next_effective_date(ll.location_level_code) is null or
                         get_next_effective_date(ll.location_level_code) > l_start_utc
                        ) 
                    and lga.loc_alias_id is not null
                    and lg.loc_group_code = lga.loc_group_code
                    and lc.loc_category_code = lg.loc_category_code
                    and lc.loc_category_id = 'Agency Aliases'
                    and bp1.base_parameter_code = p1.base_parameter_code
                    and o.office_code = lga.office_code
                    and o.office_id like l_office_id escape '\'
                    and p2.parameter_code(+) = ll.attribute_parameter_code
                    and bp2.base_parameter_code(+) = p2.base_parameter_code
                    and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
                    and d2.duration_code(+) = ll.attribute_duration_code
                 union
                 select ll.location_level_code, 
                        o.office_id,
                        lga.loc_alias_id
                        ||substr('-', 1, length(pl.sub_location_id))
                        ||pl.sub_location_id
                        ||'.'
                        ||bp1.base_parameter_id
                        ||substr('-', 1, length(p1.sub_parameter_id))
                        ||p1.sub_parameter_id
                        ||'.'
                        ||pt1.parameter_type_id
                        ||'.'
                        ||d1.duration_id
                        ||'.'
                        ||sl.specified_level_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'EN')
                        when l_unit = 'SI' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'SI')
                        else
                          l_unit
                        end,
                        bp2.base_parameter_id
                        ||substr('-', 1, length(p2.sub_parameter_id))
                        ||p2.sub_parameter_id
                        ||substr('.', 1, length(pt2.parameter_type_id))
                        ||pt2.parameter_type_id
                        ||substr('.', length(d2.duration_id))
                        ||d2.duration_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.convert_units(
                              ll.attribute_value,
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'SI'),
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'EN'))
                        else
                           ll.attribute_value
                        end,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'EN')
                        else
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'SI')
                        end
                   from at_location_level ll,
                        at_loc_category lc,
                        at_loc_group lg,
                        at_loc_group_assignment lga,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_base_parameter bp1,
                        cwms_base_parameter bp2,
                        at_parameter p1,
                        at_parameter p2,
                        cwms_parameter_type pt1,
                        cwms_parameter_type pt2,
                        cwms_duration d1,
                        cwms_duration d2,
                        at_specified_level sl,
                        cwms_office o
                  where pl.location_code = ll.location_code
                    and pl.sub_location_id is not null
                    and bl.base_location_code = pl.base_location_code
                    and bl.base_location_code = lga.location_code
                    and p1.parameter_code = ll.parameter_code
                    and pt1.parameter_type_code = ll.parameter_type_code
                    and d1.duration_code = ll.duration_code
                    and sl.specified_level_code = ll.specified_level_code
                    and ll.location_level_date < l_end_utc
                    and (ll.expiration_date is null or 
                         ll.expiration_date > l_start_utc
                        )
                    and (get_next_effective_date(ll.location_level_code) is null or
                         get_next_effective_date(ll.location_level_code) > l_start_utc
                        ) 
                    and lga.loc_alias_id is not null
                    and lg.loc_group_code = lga.loc_group_code
                    and lc.loc_category_code = lg.loc_category_code
                    and lc.loc_category_id = 'Agency Aliases'
                    and bp1.base_parameter_code = p1.base_parameter_code
                    and o.office_code = lga.office_code
                    and o.office_id like l_office_id escape '\'
                    and p2.parameter_code(+) = ll.attribute_parameter_code
                    and bp2.base_parameter_code(+) = p2.base_parameter_code
                    and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
                    and d2.duration_code(+) = ll.attribute_duration_code
                )
          order by 2, 3, 5, 6;                
         l_ts2 := systimestamp;
         l_elapsed_query := l_ts2 - l_ts1;
         if l_elapsed_query > l_max_time then
            cwms_err.raise('ERROR', l_max_time_msg);
         end if;
         for i in 1..l_lvlids.count loop
            if not l_lvlids2.exists(l_lvlids(i).lvl_code) then
               l_lvlids2(l_lvlids(i).lvl_code) := str_tab_t();
            end if;
            l_lvlids2(l_lvlids(i).lvl_code).extend;
            l_lvlids2(l_lvlids(i).lvl_code)(l_lvlids2(l_lvlids(i).lvl_code).count) := l_lvlids(i).name;
         end loop;
         l_unique_count := l_lvlids2.count;
         l_ts2 := systimestamp;
         l_elapsed_query := l_ts2 - l_ts1;
         if l_elapsed_query > l_max_time then
            cwms_err.raise('ERROR', l_max_time_msg);
         end if;
         l_ts1 := systimestamp;
         
         case
         when l_format = 'XML' then
            -----------------
            -- XML Catalog --
            -----------------
            cwms_util.append(
               l_data, 
               '<location-levels-catalog><!-- Catalog of location levels that are effective between '
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||' and '
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||' -->');
            l_count := 0;
            for i in 1..l_lvlids.count loop
               if i = 1 
                  or l_lvlids(i).office != l_lvlids(i-1).office
                  or l_lvlids(i).name != l_lvlids(i-1).name
                  or nvl(l_lvlids(i).attr_name, '@') != nvl(l_lvlids(i-1).attr_name, '@')
                  or nvl(cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777'), '@') != nvl(cwms_rounding.round_dt_f(l_lvlids(i-1).attr_value, '7777777777'), '@')
                  or nvl(l_lvlids(i).attr_unit, '@') != nvl(l_lvlids(i-1).attr_unit, '@') 
               then
                  l_count := l_count + 1;
                  cwms_util.append(
                     l_data,
                     '<location-level><office>'
                     ||l_lvlids(i).office
                     ||'</office><name>'
                     ||dbms_xmlgen.convert(l_lvlids(i).name, dbms_xmlgen.entity_encode)
                     ||'</name><alternate-names>'); 
                  for j in 1..l_lvlids2(l_lvlids(i).lvl_code).count loop
                     if l_lvlids2(l_lvlids(i).lvl_code)(j) != l_lvlids(i).name then
                        cwms_util.append(
                           l_data,
                           '<name>'
                           ||dbms_xmlgen.convert(l_lvlids2(l_lvlids(i).lvl_code)(j), dbms_xmlgen.entity_encode)
                           ||'</name>');
                     end if;
                  end loop;
                  cwms_util.append(l_data, l_text||'</alternate-names>');
                  if l_lvlids(i).attr_name is not null then
                     cwms_util.append(
                        l_data, 
                        '<attribute><name>'
                        ||l_lvlids(i).attr_name
                        ||'</name><value unit="'
                        ||l_lvlids(i).attr_unit
                        ||'">'
                        ||cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777')
                        ||'</value></attribute>');
                  end if;
                  cwms_util.append(l_data, '</location-level>');
               end if;
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
            cwms_util.append(l_data, '</location-levels-catalog>');
         when l_format = 'JSON' then
            ------------------
            -- JSON Catalog --
            ------------------
            cwms_util.append(
               l_data, 
               '{"location-levels-catalog":{"comment":"Catalog of location levels that are effective between '
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||' and '
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||'","location-levels":[');
            l_count := 0;
            for i in 1..l_lvlids.count loop
               if i = 1 
                  or l_lvlids(i).office != l_lvlids(i-1).office
                  or l_lvlids(i).name != l_lvlids(i-1).name
                  or nvl(l_lvlids(i).attr_name, '@') != nvl(l_lvlids(i-1).attr_name, '@')
                  or nvl(cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777'), '@') != nvl(cwms_rounding.round_dt_f(l_lvlids(i-1).attr_value, '7777777777'), '@')
                  or nvl(l_lvlids(i).attr_unit, '@') != nvl(l_lvlids(i-1).attr_unit, '@') 
               then
                  l_count := l_count + 1;
                  cwms_util.append(
                     l_data,
                     case i when 1 then '{"office":"' else ',{"office":"' end
                     ||l_lvlids(i).office
                     ||'","name":"'
                     ||replace(l_lvlids(i).name, '"', '\"')
                     ||'","alternate-names":[');
                  l_first := true;   
                  for j in 1..l_lvlids2(l_lvlids(i).lvl_code).count loop
                     if l_lvlids2(l_lvlids(i).lvl_code)(j) != l_lvlids(i).name then
                        case l_first
                        when true then
                           l_first := false;
                           cwms_util.append(l_data, '"'||replace(l_lvlids2(l_lvlids(i).lvl_code)(j), '"', '\"')||'"');
                        else
                           cwms_util.append(l_data, ',"'||replace(l_lvlids2(l_lvlids(i).lvl_code)(j), '"', '\"')||'"');
                        end case;
                     end if;
                  end loop;
                  cwms_util.append(l_data, ']');
                  if l_lvlids(i).attr_name is not null then
                     cwms_util.append(
                     l_data, 
                     ',"attribute":{"name":"'
                     ||replace(l_lvlids(i).attr_name, '"', '\"')
                     ||'","unit":"'
                     ||replace(l_lvlids(i).attr_unit, '"', '\"')
                     ||'","value":'
                     ||regexp_replace(cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777'), '^\.', '0.')
                     ||'}');
                  end if;
                  cwms_util.append(l_data, l_text||'}');
               end if;
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
            cwms_util.append(l_data, ']}}');
         when l_format in ('TAB', 'CSV') then
            ------------------------
            -- TAB or CSV Catalog --
            ------------------------
            l_count := 0;
            cwms_util.append(
               l_data, 
               '# Catalog of location levels that are effective between '
               ||to_char(l_start, 'dd-Mon-yyyy hh24:mi')
               ||' and '
               ||to_char(l_end, 'dd-Mon-yyyy hh24:mi')
               ||' '
               ||l_timezone
               ||chr(10)
               ||chr(10)
               ||'#Office'
               ||chr(9)
               ||'Name'
               ||chr(9)
               ||'Attribute'
               ||chr(9)
               ||'Alternate Names'
               ||chr(10));
            for i in 1..l_lvlids.count loop
               if i = 1 or l_text != l_lvlids(i).office
                  ||chr(9)
                  ||l_lvlids(i).name
                  ||chr(9)
                  ||case l_lvlids(i).attr_name is not null
                    when true then l_lvlids(i).attr_name
                                   ||'='
                                   ||cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777')
                                   ||' '
                                   ||l_lvlids(i).attr_unit
                    else null
                    end
               then
                  l_count := l_count + 1;
                  l_text := l_lvlids(i).office
                  ||chr(9)
                  ||l_lvlids(i).name
                  ||chr(9)
                  ||case l_lvlids(i).attr_name is not null
                    when true then l_lvlids(i).attr_name
                                   ||'='
                                   ||cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777')
                                   ||' '
                                   ||l_lvlids(i).attr_unit
                    else null
                    end;
                  cwms_util.append(l_data, l_text);
                     for j in 1..l_lvlids2(l_lvlids(i).lvl_code).count loop
                        if l_lvlids2(l_lvlids(i).lvl_code)(j) != l_lvlids(i).name then
                           cwms_util.append(l_data, chr(9)||l_lvlids2(l_lvlids(i).lvl_code)(j));
                        end if;
                     end loop;
                  cwms_util.append(l_data, chr(10));
               end if;
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
         end case;
         p_results := l_data;
         
         l_ts2 := systimestamp;
         l_elapsed_format := l_ts2 - l_ts1;
      else
         --------------------------------------------------------
         -- retrieve location level values data in time window --
         --------------------------------------------------------
         l_ts1 := systimestamp;
         l_elapsed_query := l_ts1 - l_ts1;
         l_elapsed_format := l_elapsed_query;
         l_names_sql := str_tab_t();
         l_names_sql.extend(l_names.count);
         l_count := 0;
         <<names>>
         for i in 1..l_names.count loop
            l_names_sql(i) := upper(cwms_util.normalize_wildcards(l_names(i)));
            l_parts := cwms_util.split_text(l_units(i), ';');
            l_unit := case
                      when upper(l_parts(1)) in ('EN', 'SI') then upper(l_parts(1))
                      else l_parts(1)
                      end;
            l_attr_unit := case l_parts.count > 1
                           when true then l_parts(2)
                           else l_parts(1)
                           end;
            select distinct 
                   ll.location_level_code, 
                   o.office_id,
                   bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id,
                   case
                   when l_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'EN')
                   when l_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'SI')
                   else
                     l_unit
                   end,
                   bp2.base_parameter_id
                   ||substr('-', 1, length(p2.sub_parameter_id))
                   ||p2.sub_parameter_id
                   ||substr('.', 1, length(pt2.parameter_type_id))
                   ||pt2.parameter_type_id
                   ||substr('.', length(d2.duration_id))
                   ||d2.duration_id,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'EN'))
                   when l_attr_unit = 'SI' then
                      ll.attribute_value
                   else
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         l_attr_unit)
                   end,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'EN')
                   when l_attr_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'SI')
                   else
                     l_attr_unit
                   end
              bulk collect
              into l_lvlids
              from at_location_level ll,
                   at_physical_location pl,
                   at_base_location bl,
                   cwms_base_parameter bp1,
                   cwms_base_parameter bp2,
                   at_parameter p1,
                   at_parameter p2,
                   cwms_parameter_type pt1,
                   cwms_parameter_type pt2,
                   cwms_duration d1,
                   cwms_duration d2,
                   at_specified_level sl,
                   cwms_office o
             where upper(bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id) like upper(l_names_sql(i)) escape '\'
               and pl.location_code = ll.location_code
               and p1.parameter_code = ll.parameter_code
               and pt1.parameter_type_code = ll.parameter_type_code
               and d1.duration_code = ll.duration_code
               and sl.specified_level_code = ll.specified_level_code
               and ll.location_level_date < cwms_util.change_timezone(l_end, l_timezone, 'UTC')
               and (ll.expiration_date is null or 
                    ll.expiration_date > cwms_util.change_timezone(l_start, l_timezone, 'UTC')
                   )
               and (get_next_effective_date(ll.location_level_code, l_timezone) is null or
                    get_next_effective_date(ll.location_level_code, l_timezone) > l_start
                   ) 
               and bl.base_location_code = pl.base_location_code
               and bp1.base_parameter_code = p1.base_parameter_code
               and o.office_code = bl.db_office_code
               and o.office_id like l_office_id escape '\'
               and p2.parameter_code(+) = ll.attribute_parameter_code
               and bp2.base_parameter_code(+) = p2.base_parameter_code
               and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
               and d2.duration_code(+) = ll.attribute_duration_code
            union  
            select distinct
                   ll.location_level_code, 
                   o.office_id,
                   lga.loc_alias_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id,
                   case
                   when l_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'EN')
                   when l_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'SI')
                   else
                     l_unit
                   end,
                   bp2.base_parameter_id
                   ||substr('-', 1, length(p2.sub_parameter_id))
                   ||p2.sub_parameter_id
                   ||substr('.', 1, length(pt2.parameter_type_id))
                   ||pt2.parameter_type_id
                   ||substr('.', length(d2.duration_id))
                   ||d2.duration_id,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'EN'))
                   when l_attr_unit = 'SI' then
                      ll.attribute_value
                   else
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         l_attr_unit)
                   end,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'EN')
                   when l_attr_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'SI')
                   else
                     l_attr_unit
                   end
              from at_location_level ll,
                   at_loc_category lc,
                   at_loc_group lg,
                   at_loc_group_assignment lga,
                   cwms_base_parameter bp1,
                   cwms_base_parameter bp2,
                   at_parameter p1,
                   at_parameter p2,
                   cwms_parameter_type pt1,
                   cwms_parameter_type pt2,
                   cwms_duration d1,
                   cwms_duration d2,
                   at_specified_level sl,
                   cwms_office o
             where upper(lga.loc_alias_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id) like upper(l_names_sql(i)) escape '\'
               and lga.location_code = ll.location_code
               and p1.parameter_code = ll.parameter_code
               and pt1.parameter_type_code = ll.parameter_type_code
               and d1.duration_code = ll.duration_code
               and sl.specified_level_code = ll.specified_level_code
               and ll.location_level_date < cwms_util.change_timezone(l_end, l_timezone, 'UTC')
               and (ll.expiration_date is null or 
                    ll.expiration_date > cwms_util.change_timezone(l_start, l_timezone, 'UTC')
                   )
               and (get_next_effective_date(ll.location_level_code, l_timezone) is null or
                    get_next_effective_date(ll.location_level_code, l_timezone) > l_start
                   ) 
               and lga.loc_alias_id is not null
               and lg.loc_group_code = lga.loc_group_code
               and lc.loc_category_code = lg.loc_category_code
               and lc.loc_category_id = 'Agency Aliases'
               and bp1.base_parameter_code = p1.base_parameter_code
               and o.office_code = lga.office_code
               and o.office_id like l_office_id escape '\'
               and p2.parameter_code(+) = ll.attribute_parameter_code
               and bp2.base_parameter_code(+) = p2.base_parameter_code
               and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
               and d2.duration_code(+) = ll.attribute_duration_code
            union  
            select distinct
                   ll.location_level_code, 
                   o.office_id,
                   lga.loc_alias_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id,
                   case
                   when l_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'EN')
                   when l_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'SI')
                   else
                     l_unit
                   end,
                   bp2.base_parameter_id
                   ||substr('-', 1, length(p2.sub_parameter_id))
                   ||p2.sub_parameter_id
                   ||substr('.', 1, length(pt2.parameter_type_id))
                   ||pt2.parameter_type_id
                   ||substr('.', length(d2.duration_id))
                   ||d2.duration_id,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'EN'))
                   when l_attr_unit = 'SI' then
                      ll.attribute_value
                   else
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         l_attr_unit)
                   end,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'EN')
                   when l_attr_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'SI')
                   else
                     l_attr_unit
                   end
              from at_location_level ll,
                   at_loc_category lc,
                   at_loc_group lg,
                   at_loc_group_assignment lga,
                   at_physical_location pl,
                   at_base_location bl,
                   cwms_base_parameter bp1,
                   cwms_base_parameter bp2,
                   at_parameter p1,
                   at_parameter p2,
                   cwms_parameter_type pt1,
                   cwms_parameter_type pt2,
                   cwms_duration d1,
                   cwms_duration d2,
                   at_specified_level sl,
                   cwms_office o
             where upper(lga.loc_alias_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id) like upper(l_names_sql(i)) escape '\'
               and pl.location_code = ll.location_code
               and pl.sub_location_id is not null
               and bl.base_location_code = pl.base_location_code
               and bl.base_location_code = lga.location_code
               and p1.parameter_code = ll.parameter_code
               and pt1.parameter_type_code = ll.parameter_type_code
               and d1.duration_code = ll.duration_code
               and sl.specified_level_code = ll.specified_level_code
               and ll.location_level_date < cwms_util.change_timezone(l_end, l_timezone, 'UTC')
               and (ll.expiration_date is null or 
                    ll.expiration_date > cwms_util.change_timezone(l_start, l_timezone, 'UTC')
                   )
               and (get_next_effective_date(ll.location_level_code, l_timezone) is null or
                    get_next_effective_date(ll.location_level_code, l_timezone) > l_start
                   ) 
               and lga.loc_alias_id is not null
               and lg.loc_group_code = lga.loc_group_code
               and lc.loc_category_code = lg.loc_category_code
               and lc.loc_category_id = 'Agency Aliases'
               and bp1.base_parameter_code = p1.base_parameter_code
               and o.office_code = lga.office_code
               and o.office_id like l_office_id escape '\'
               and p2.parameter_code(+) = ll.attribute_parameter_code
               and bp2.base_parameter_code(+) = p2.base_parameter_code
               and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
               and d2.duration_code(+) = ll.attribute_duration_code
             order by 2, 3, 5, 6;
             
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
      
            l_lvlids2.delete;      
            for i in 1..l_lvlids.count loop
               if not l_lvlids2.exists(l_lvlids(i).lvl_code) then
                  l_parts := cwms_util.split_text(l_lvlids(i).name, '.');
                  l_code := cwms_loc.get_location_code(l_lvlids(i).office, l_parts(1));
                  select location_id||'.'||l_parts(2)||'.'||l_parts(3)||'.'||l_parts(4)||'.'||l_parts(5)
                    bulk collect
                    into l_lvlids2(l_lvlids(i).lvl_code)
                    from (select location_id
                            from (select bl.base_location_id
                                         ||substr('-', 1, length(pl.sub_location_id))
                                         ||pl.sub_location_id as location_id
                                    from at_physical_location pl,
                                         at_base_location bl
                                   where pl.location_code = l_code
                                     and bl.base_location_code = pl.base_location_code
                                  union
                                  select loc_alias_id as location_id
                                    from at_loc_group_assignment lga,
                                         at_loc_group lg,
                                         at_loc_category lc
                                   where lga.location_code = l_code        
                                     and lg.loc_group_code = lga.loc_group_code
                                     and lc.loc_category_code = lg.loc_category_code
                                     and lc.loc_category_id = 'Agency Aliases'
                                  union
                                  select loc_alias_id
                                         ||substr('-', 1, length(pl.sub_location_id))
                                         ||pl.sub_location_id as location_id
                                    from at_physical_location pl,
                                         at_base_location bl,
                                         at_loc_group_assignment lga,
                                         at_loc_group lg,
                                         at_loc_category lc
                                   where pl.location_code = l_code
                                     and bl.base_location_code = pl.base_location_code
                                     and lga.location_code = bl.base_location_code        
                                     and lg.loc_group_code = lga.loc_group_code
                                     and lc.loc_category_code = lg.loc_category_code
                                     and lc.loc_category_id = 'Agency Aliases'
                                 )
                           order by 1
                         );
               end if;
            end loop;
            l_unique_count := l_unique_count + l_lvlids2.count;
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
      
            l_level_values := ztsv_array_tab();
            l_level_values.extend(l_lvlids.count);
            <<levels>>
            for j in 1..l_lvlids.count loop
               l_name:= l_lvlids(j).name||'/'||l_lvlids(j).attr_name||'/'||l_lvlids(j).attr_value||'/'||l_lvlids(j).attr_unit;
               if l_used.exists(l_name) then
                  continue levels;
               end if;
               l_used(l_name) := true;
               l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
               if instr(upper(l_parts(2)), 'ELEV') = 1 then
                  l_datum := case
                             when l_datums(i) != 'NATIVE' then l_datums(i)
                             else cwms_loc.get_local_vert_datum_name_f(l_parts(1), l_lvlids(j).office)
                             end;
               else
                  l_datum := null;
               end if;
               l_level_values(j) := retrieve_location_level_values(
                  l_lvlids(j).name,
                  case
                  when l_datum is null then l_lvlids(j).unit
                  else 'U='||l_lvlids(j).unit||'|V='||l_datum
                  end,
                  l_start,
                  l_end,
                  l_lvlids(j).attr_name,
                  l_lvlids(j).attr_value,
                  l_lvlids(j).attr_unit,
                  l_timezone,
                  l_lvlids(j).office);
            end loop;
            
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
            l_ts1 := systimestamp;
      
            case
            when l_format = 'XML' then
               --------------
               -- XML Data --
               --------------
               for j in 1..l_lvlids.count loop
                  if l_level_values(j) is not null then
                     l_count := l_count + 1;
                     l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
                     if instr(upper(l_parts(2)), 'ELEV') = 1 then
                        l_name := cwms_loc.get_location_vertical_datum(l_parts(1), l_lvlids(j).office);
                        case
                        when l_name is null then
                           l_datum := 'unknown';
                           l_estimated := false;
                        when l_datums(i) in ('NATIVE', l_name) then
                           l_datum := l_name;
                           l_estimated := false;
                        else
                           l_datum := l_datums(i);
                           l_estimated := cwms_loc.is_vert_datum_offset_estimated(
                              l_parts(1),
                              l_name,
                              l_datum,
                              l_lvlids(j).office) = 'T';
                        end case;
                     else
                        l_datum := null;
                     end if;
                     if l_count = 1 then
                        cwms_util.append(l_data, '<location-levels>');
                     end if;
                     cwms_util.append(
                        l_data,
                        '<location-level><office>'
                        ||l_lvlids(j).office
                        ||'</office><name>'
                        ||l_lvlids(j).name
                        ||'</name><alternate-names>');
                     for k in 1..l_lvlids2(l_lvlids(j).lvl_code).count loop
                        if l_lvlids2(l_lvlids(j).lvl_code)(k) != l_lvlids(j).name then
                           cwms_util.append(
                              l_data,
                              '<name>'
                              ||l_lvlids2(l_lvlids(j).lvl_code)(k)
                              ||'</name>');
                        end if;
                     end loop;
                     if l_lvlids(j).attr_name is not null then
                        cwms_util.append(
                           l_data,
                           '<attribute><name>'
                           ||l_lvlids(j).attr_name
                           ||'</name>'
                           ||'<value unit="'
                           ||l_lvlids(j).attr_unit
                           ||'">'
                           ||cwms_rounding.round_dt_f(l_lvlids(j).attr_value, '7777777777')
                           ||'</value></attribute>');
                     end if;
                     cwms_util.append(
                        l_data,
                        '</alternate-names><values unit="'
                        ||l_lvlids(j).unit
                        ||'"');
                     if l_datum is not null then
                        cwms_util.append(
                           l_data,
                           ' datum="'
                           ||l_datum
                           ||'" estimate='
                           ||case l_estimated when true then '"true"' else '"false"' end);
                     end if;
                     cwms_util.append(l_data, '>');
                     l_segments := seg_tab_t();
                     l_interp := -1;
                     for k in 1..l_level_values(j).count loop
                        if l_level_values(j)(k).quality_code != l_interp then
                           l_segments.extend;
                           l_segments(l_segments.count).first_index := k;
                           l_segments(l_segments.count).interp := case when l_level_values(j)(k).quality_code = 0 then 'false' else 'true' end;
                           l_interp := l_level_values(j)(k).quality_code;
                        end if;
                        l_segments(l_segments.count).last_index := k;
                     end loop;
                     for k in 1..l_segments.count loop
                        cwms_util.append(
                           l_data,
                           '<segment position="'
                           ||k
                           ||'" interpolate="'
                           ||l_segments(k).interp
                           ||'">'
                           ||chr(10));
                        for m in l_segments(k).first_index..l_segments(k).last_index loop
                           continue when m > l_segments(k).first_index
                                     and m < l_segments(k).last_index
                                     and l_level_values(j)(m).value = l_level_values(j)(m-1).value  
                                     and l_level_values(j)(m).value = l_level_values(j)(m+1).value;  
                           cwms_util.append(
                              l_data,
                              cwms_util.get_xml_time(l_level_values(j)(m).date_time, l_timezone)
                              ||' '
                              ||regexp_replace(cwms_rounding.round_dt_f(l_level_values(j)(m).value, '7777777777'), '^\.', '0.')
                              ||chr(10));
                        end loop;
                        cwms_util.append(l_data, '</segment>');
                     end loop;
                     cwms_util.append(l_data, '</values></location-level>');
                  end if;
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
            when l_format = 'JSON' then
               ---------------
               -- JSON Data --
               ---------------
               for j in 1..l_lvlids.count loop
                  if l_level_values(j) is not null then
                     l_count := l_count + 1;
                     l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
                     if instr(upper(l_parts(2)), 'ELEV') = 1 then
                        l_name := cwms_loc.get_location_vertical_datum(l_parts(1), l_lvlids(j).office);
                        case
                        when l_name is null then
                           l_datum := 'unknown';
                           l_estimated := false;
                        when l_datums(i) in ('NATIVE', l_name) then
                           l_datum := l_name;
                           l_estimated := false;
                        else
                           l_datum := l_datums(i);
                           l_estimated := cwms_loc.is_vert_datum_offset_estimated(
                              l_parts(1),
                              l_name,
                              l_datum,
                              l_lvlids(j).office) = 'T';
                        end case;
                     else
                        l_datum := null;
                     end if;
                     if l_count = 1 then
                        cwms_util.append(l_data, '{"location-levels":{"location-levels":[');
                     end if;
                     cwms_util.append(
                        l_data,
                        case when l_count=1 then '{"office":"' else ',{"office":"' end
                        ||l_lvlids(j).office
                        ||'","name":"'
                        ||l_lvlids(j).name
                        ||'","alternate-names":[');
                     l_first := true;
                     for k in 1..l_lvlids2(l_lvlids(j).lvl_code).count loop
                        if l_lvlids2(l_lvlids(j).lvl_code)(k) != l_lvlids(j).name then
                           cwms_util.append(
                              l_data, 
                              case l_first when true then '"' else ',"' end
                              ||l_lvlids2(l_lvlids(j).lvl_code)(k)
                              ||'"');
                           l_first := false;
                        end if;
                     end loop;
                     cwms_util.append(l_data, ']');
                     if l_lvlids(j).attr_name is not null then
                        cwms_util.append(
                           l_data, 
                           ',"attribute":{"name":"'
                           ||l_lvlids(j).attr_name
                           ||'","unit":"'
                           ||l_lvlids(j).attr_unit
                           ||'","value":'
                           ||regexp_replace(cwms_rounding.round_dt_f(l_lvlids(j).attr_value, '7777777777'), '^\.', '0.')
                           ||'}');
                     end if;          
                     cwms_util.append(
                        l_data,
                        ',"values":{"parameter":"'
                        ||cwms_util.split_text(l_lvlids(j).name, 2, '.')
                        ||' ('
                        ||l_lvlids(j).unit
                        ||case l_datum is null
                          when true then ')"'
                          else case l_estimated
                               when true then ' '||l_datum||' estimated)"'
                               else ' '||l_datum||')"'
                               end
                          end);
                     l_segments := seg_tab_t();
                     l_interp := -1;
                     for k in 1..l_level_values(j).count loop
                        if l_level_values(j)(k).quality_code != l_interp then
                           l_segments.extend;
                           l_segments(l_segments.count).first_index := k;
                           l_segments(l_segments.count).interp := case when l_level_values(j)(k).quality_code = 0 then 'false' else 'true' end;
                           l_interp := l_level_values(j)(k).quality_code;
                        end if;
                        l_segments(l_segments.count).last_index := k;
                     end loop;
                     cwms_util.append(l_data, ',"segments":[');
                     for k in 1..l_segments.count loop
                        cwms_util.append(
                           l_data,
                           '{"interpolate":"'
                           ||l_segments(k).interp
                           ||'","values":[');
                        for m in l_segments(k).first_index..l_segments(k).last_index loop
                           continue when m > l_segments(k).first_index
                                     and m < l_segments(k).last_index
                                     and l_level_values(j)(m).value = l_level_values(j)(m-1).value  
                                     and l_level_values(j)(m).value = l_level_values(j)(m+1).value;  
                           cwms_util.append(
                              l_data,
                              case m when 1 then '["' else ',["' end
                              ||cwms_util.get_xml_time(l_level_values(j)(m).date_time, l_timezone)
                              ||'",'
                              ||regexp_replace(cwms_rounding.round_dt_f(l_level_values(j)(m).value, '7777777777'), '^\.', '0.')
                              ||']');
                        end loop;
                        cwms_util.append(l_data, ']}');
                     end loop;
                     cwms_util.append(l_data, ']}}');
                  end if;
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
            when l_format in ('TAB', 'CSV') then
               ---------------------
               -- TAB or CSV Data --
               ---------------------
               cwms_util.append(
                  l_data, 
                  '#Office'
                  ||chr(9)
                  ||'Name'
                  ||chr(9)
                  ||'Attribute'
                  ||chr(9)
                  ||'Alternate Names'
                  ||chr(10));
               for j in 1..l_lvlids.count loop
                  if l_level_values(j) is not null then
                     l_count := l_count + 1;
                     l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
                     if instr(upper(l_parts(2)), 'ELEV') = 1 then
                        l_name := cwms_loc.get_location_vertical_datum(l_parts(1), l_lvlids(j).office);
                        case
                        when l_name is null then
                           l_datum := null;
                        when l_datums(i) in ('NATIVE', l_name) then
                           l_datum := l_name;
                        else
                           l_datum := l_datums(i);
                           if cwms_loc.is_vert_datum_offset_estimated(
                              l_parts(1),
                              l_name,
                              l_datum,
                              l_lvlids(j).office) = 'T'
                           then
                              l_datum := l_datum||' estimated';
                           end if;
                        end case;
                     else
                        l_datum := null;
                     end if;
                     cwms_util.append(
                        l_data,
                        chr(10)
                        ||l_lvlids(j).office
                        ||chr(9)
                        ||l_lvlids(j).name
                        ||chr(9)
                        ||case l_lvlids(j).attr_name is not null
                          when true then l_lvlids(j).attr_name
                                         ||'='
                                         ||trim(cwms_rounding.round_dt_f(l_lvlids(j).attr_value, '7777777777')
                                                ||' '
                                                ||l_lvlids(j).attr_unit)
                                                ||case instr(nvl(l_lvlids(j).attr_unit, '@'), 'Elev')
                                                  when 1 then l_datum
                                                  else null
                                                  end
                          else null
                          end);
                     if l_lvlids2.exists(l_lvlids(j).lvl_code) then
                        for k in 1..l_lvlids2(l_lvlids(j).lvl_code).count loop
                           if l_lvlids2(l_lvlids(j).lvl_code)(k) != l_lvlids(j).name then
                              cwms_util.append(l_data, chr(9)||l_lvlids2(l_lvlids(j).lvl_code)(k));
                           end if;
                        end loop;
                     end if;
                     cwms_util.append(l_data, chr(10));
                     l_interp := null;
                     for k in 1..l_level_values(j).count loop
                        if l_level_values(j)(k).value is not null and l_level_values(j)(k).quality_code != nvl(l_interp, -1) then
                           cwms_util.append(
                              l_data,
                              '#Segment'
                              ||chr(9)
                              ||'Interpolate='
                              ||case 
                                when l_level_values(j)(k).quality_code = 0 then 'False'
                                else 'True'
                                end
                              ||chr(10)
                              ||'#Date-Time '
                              ||l_timezone
                              ||chr(9)
                              ||cwms_util.split_text(l_lvlids(j).name, 2, '.')
                              || ' ('
                              ||l_lvlids(j).unit
                              ||case instr(cwms_util.split_text(l_lvlids(j).name, 2, '.'), 'Elev')
                                when 1 then
                                   case l_datum is not null
                                   when true then ' '||l_datum
                                   else null
                                   end
                                else null
                                end
                              ||')'  
                              ||chr(10));
                        end if;
                        if l_level_values(j)(k).value is null then
                           l_interp := null;
                        else
                           cwms_util.append(
                              l_data,
                              to_char(l_level_values(j)(k).date_time, 'dd-Mon-yyyy hh24:mi')
                              ||chr(9)
                              ||cwms_rounding.round_dt_f(l_level_values(j)(k).value, '7777777777')||chr(10));
                        end if;
                        l_interp := case
                                    when l_level_values(j)(k).value is null then null
                                    else l_level_values(j)(k).quality_code
                                    end;
                     end loop;
                  end if;
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
            end case;
            
            l_ts2 := systimestamp;
            l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;
            l_ts1 := systimestamp;
         end loop;
      end if;
   exception
      when others then 
         case
         when instr(sqlerrm, l_max_time_msg) > 0 then
            dbms_lob.createtemporary(l_data, true);
            case l_format
            when  'XML' then
               if l_names is null then
                  cwms_util.append(l_data, '<location-levels-catalog><error>Query exceeded maximum time of '||l_max_time||'</error></location-levels-catalog>');
               else
                  cwms_util.append(l_data, '<location-levels><error>Query exceeded maximum time of '||l_max_time||'</error></location-levels>');
               end if;
            when 'JSON' then
               if l_names is null then
                  cwms_util.append(l_data, '{"location-levels-catalog":{"error":"Query exceeded maximum time of '||l_max_time||'"}}');
               else
                  cwms_util.append(l_data, '{"location-levels":{"error":"Query exceeded maximum time of '||l_max_time||'"}}');
               end if;
            when 'TAB' then
               cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum time of '||l_max_time||chr(10));
            when 'CSV' then
               cwms_util.append(l_data, 'ERROR,Query exceeded maximum time of '||l_max_time||chr(10));
            end case;
         when instr(sqlerrm, l_max_size_msg) > 0 then
            dbms_lob.createtemporary(l_data, true);
            case l_format
            when  'XML' then
               if l_names is null then
                  cwms_util.append(l_data, '<location-levels-catalog><error>Query exceeded maximum size of '||l_max_size||' characters</error></location-levels-catalog>');
               else
                  cwms_util.append(l_data, '<location-levels><error>Query exceeded maximum size of '||l_max_size||' characters</error></location-levels>');
               end if;
            when 'JSON' then
               if l_names is null then
                  cwms_util.append(l_data, '{"location-levels-catalog":{"error":"Query exceeded maximum size of '||l_max_size||' characters"}}');
               else
                  cwms_util.append(l_data, '{"location-levels":{"error":"Query exceeded maximum size of '||l_max_size||' characters"}}');
               end if;
            when 'TAB' then
               cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
            when 'CSV' then
               cwms_util.append(l_data, 'ERROR,Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
            end case;
         else 
            cwms_err.raise('ERROR', dbms_utility.format_error_backtrace);
         end case;
   end;
   
   declare
      l_data2 clob;
   begin
      dbms_lob.createtemporary(l_data2, true);
      select db_unique_name into l_name from v$database;
      case 
      when l_format = 'XML' then
         ---------
         -- XML --
         ---------
         if l_names is not null then
            cwms_util.append(l_data, '</location-levels>');
            l_ts2 := systimestamp;
            l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;
            l_ts1 := systimestamp;
         end if;            
         cwms_util.append(
            l_data2, 
            '<query-info><processed-at>'
            ||utl_inaddr.get_host_name
            ||':'
            ||l_name
            ||'</processed-at><time-of-query>'
            ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
            ||'Z</time-of-query><process-query>'
            ||iso_duration(l_elapsed_query)
            ||'</process-query><format-output>'
            ||iso_duration(l_elapsed_format)
            ||'</format-output><requested-format>'
            ||l_format
            ||'</requested-format><requested-start-time>'
            ||cwms_util.get_xml_time(l_start, l_timezone)
            ||'</requested-start-time><requested-end-time>'
            ||cwms_util.get_xml_time(l_end, l_timezone)
            ||'</requested-end-time><requested-office>'
            ||l_office_id
            ||'</requested-office>');
            if l_names is null then
               cwms_util.append(
                  l_data2,
                  '<requested-unit>'
                  ||l_unit
                  ||'</requested-unit>');
               cwms_util.append(
                  l_data2, 
                  '<total-location-levels-cataloged>'
                  ||l_count
                  ||'</total-location-levels-cataloged><unique-location-levels-cataloged>'
                  ||l_unique_count
                  ||'</unique-location-levels-cataloged></query-info>');
            else
               for i in 1..l_names.count loop
                  cwms_util.append(
                     l_data2,
                     '<requested-items position="'||i||'"><name>'
                     ||l_names(i)
                     ||'</name><unit>'
                     ||l_units(i)
                     ||'</unit><datum>'
                     ||l_datums(i)
                     ||'</datum></requested-items>');
               end loop;
               cwms_util.append(
                  l_data2, 
                  '<total-location-levels-retrieved>'
                  ||l_count
                  ||'</total-location-levels-retrieved><unique-location-levels-retrieved>'
                  ||l_unique_count
                  ||'</unique-location-levels-retrieved></query-info>');
            end if;
         l_data := regexp_replace(l_data, '(<location-levels(-catalog)?>)', '\1'||l_data2, 1, 1);
         p_results := l_data;
      when l_format = 'JSON' then
         ----------
         -- JSON --
         ----------
         if l_names is not null and instr(substr(l_data, 1, 50), '"error"') = 0 then
            cwms_util.append(l_data, ']}}');
         end if;
         cwms_util.append(
            l_data2, 
            '{"query-info":{"processed-at":"'
            ||utl_inaddr.get_host_name
            ||':'
            ||l_name
            ||'","time-of-query":"'
            ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
            ||'Z","process-query":"'
            ||iso_duration(l_elapsed_query)
            ||'","format-output":"'
            ||iso_duration(l_elapsed_format)
            ||'","requested-format":"'
            ||l_format
            ||'","requested-start-time":"'
            ||cwms_util.get_xml_time(l_start, l_timezone)
            ||'","requested-end-time":"'
            ||cwms_util.get_xml_time(l_end, l_timezone)
            ||'","requested-office":"'
            ||l_office_id
            ||'"');
            if l_names is null then
               cwms_util.append(
                  l_data2,
                  ',"requested-unit":"'
                  ||l_unit
                  ||'"');
               cwms_util.append(
                  l_data2, 
                  ',"total-location-levels-cataloged":'
                  ||l_count
                  ||',"unique-location-levels-cataloged":'
                  ||l_unique_count
                  ||'},');
            else
               cwms_util.append(l_data2, ',"requested-items":[');
               for i in 1..l_names.count loop
                  cwms_util.append(
                     l_data2,
                     case i when 1 then '{"name":"' else ',{"name":"' end
                     ||l_names(i)
                     ||'","unit":"'
                     ||l_units(i)
                     ||'","datum":"'
                     ||l_datums(i)
                     ||'"}');
               end loop;
               cwms_util.append(l_data2, ']');
               cwms_util.append(
                  l_data2, 
                  ',"total-location-levels-retrieved":'
                  ||l_count
                  ||',"unique-location-levels-retrieved":'
                  ||l_unique_count
                  ||'},');
            end if;
         l_data := regexp_replace(l_data, '^({"location-levels.*?":){', '\1'||l_data2, 1, 1);
         p_results := l_data;
      when l_format in ('TAB', 'CSV') then
         ----------------
         -- TAB or CSV --
         ----------------
         cwms_util.append(l_data2, '#Processed At'||chr(9)||utl_inaddr.get_host_name ||':'||l_name||chr(10));
         cwms_util.append(l_data2, '#Time Of Query'||chr(9)||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||chr(10));
         cwms_util.append(l_data2, '#Process Query'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' milliseconds'||chr(10));
         cwms_util.append(l_data2, '#Format Output'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' milliseconds'||chr(10));
         cwms_util.append(l_data2, '#Requested Start Time'||chr(9)||to_char(l_start, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
         cwms_util.append(l_data2, '#Requested End Time'||chr(9)||to_char(l_end, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
         cwms_util.append(l_data2, '#Requested Format'   ||chr(9)||l_format||chr(10));
         cwms_util.append(l_data2, '#Requested Office'   ||chr(9)||l_office_id||chr(10));
         if l_names is not null then
            cwms_util.append(l_data2, '#Requested Names'    ||chr(9)||cwms_util.join_text(l_names, chr(9))||chr(10));
            cwms_util.append(l_data2, '#Requested Units'    ||chr(9)||cwms_util.join_text(l_units, chr(9))||chr(10));
            cwms_util.append(l_data2, '#Requested Datums'   ||chr(9)||cwms_util.join_text(l_datums, chr(9))||chr(10));
            cwms_util.append(l_data2, '#Total Location Levels Cataloged'||chr(9)||l_count||chr(10));
            cwms_util.append(l_data2, '#Unique Location Levels Cataloged'||chr(9)||l_unique_count||chr(10)||chr(10));
         else
            cwms_util.append(l_data2, '#Total Location Levels Retrieved'||chr(9)||l_count||chr(10));
            cwms_util.append(l_data2, '#Unique Location Levels Retrieved'||chr(9)||l_unique_count||chr(10)||chr(10));
         end if;
         cwms_util.append(l_data2, l_data);
         if l_format = 'CSV' then
            l_data2 := cwms_util.tab_to_csv(l_data2);
         end if;
         p_results := l_data2;
      end case;
   end;
         
   p_date_time   := l_query_time;
   p_query_time  := trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)));
   p_format_time := trunc(1000 * (extract(minute from l_elapsed_format) *60 +  extract(second from l_elapsed_format)));
   p_count       := l_count;
end retrieve_location_levels;   
         
            
END cwms_level;
/
show errors;

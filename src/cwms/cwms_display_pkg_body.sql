create or replace package body cwms_display as

--------------------------------------------------------------------------------
-- procedure adjust_scale_limits
--------------------------------------------------------------------------------
procedure adjust_scale_limits(
   p_min_value        in out number,
   p_max_value        in out number,
   p_adjustment_level in     integer)
is
   l_min_value number;
   l_max_value number;
   l_diff      number;
   l_diff2     number;
   l_power     integer;
   l_interval  number;
   
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_min_value + p_max_value is null then
      cwms_err.raise(
         'ERROR',
         'Min or max value must not be null');
   end if;  
   if p_min_value >= p_max_value then
      cwms_err.raise(
         'ERROR',
         'Min value must be less than max value.');
   end if;
   if p_adjustment_level not in (0, 1, 2) then
      cwms_err.raise(
         'ERROR',
         'Scale adjustment level must be 0, 1, or 2.');
   end if;
   ----------------------------
   -- perform the adjustment --
   ----------------------------
   if p_adjustment_level > 0 then
      l_diff     := p_max_value - p_min_value;
      l_power    := trunc(log(10, l_diff));
      l_interval := power(10, l_power);
      l_diff2    := l_diff / l_interval;

      if    l_diff2 > 5 then l_diff2 := 10;
      elsif l_diff2 > 2 then l_diff2 :=  5;
      elsif l_diff2 > 1 then l_diff2 :=  2;
      else                   l_diff2 :=  1;
      end if;
      
      l_min_value := p_min_value - mod(p_min_value, l_interval);
      if p_adjustment_level > 1 then
         l_min_value := l_min_value - mod(l_min_value, l_diff2 * l_interval);
      end if;
      l_max_value := l_min_value + l_diff2 * l_interval;
      
      if l_max_value < p_max_value then
         if l_diff2 = 2 then l_diff2 :=5; 
         else                l_diff2 := l_diff2 * 2;
         end if;
         
         l_min_value := p_min_value - mod(p_min_value, l_interval);
         if p_adjustment_level > 1 then
            l_min_value := l_min_value - mod(l_min_value, l_diff2 * l_interval);
         end if;
         l_max_value := l_min_value + l_diff2 * l_interval;
      end if;
   
      p_min_value := l_min_value;
      p_max_value := l_max_value;
   end if;
   
end adjust_scale_limits;    
--------------------------------------------------------------------------------
-- procedure store_scale_limits
--------------------------------------------------------------------------------
procedure store_scale_limits(
   p_location_id    in varchar2,
   p_parameter_id   in varchar2, 
   p_unit_id        in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_scale_min      in number,
   p_scale_max      in number,
   p_office_id      in varchar2 default null)
is
   l_fail_if_exists boolean;
   l_ignore_nulls   boolean;
   l_exists         boolean;
   l_office_id      varchar2(16);
   l_rec            at_display_scale%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_parameter_id, 
      p_unit_id,
      p_fail_if_exists,
      p_ignore_nulls,
      p_office_id));
      
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);   
   l_ignore_nulls   := cwms_util.is_true(p_ignore_nulls);
   l_office_id      := nvl(upper(p_office_id), cwms_util.user_office_id);
   
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');
   end if;   
   if p_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Parameter identifier must not be null.');
   end if;   
   if p_unit_id is null then
      cwms_err.raise(
         'ERROR',
         'Unit identifier must not be null.');
   end if;
   ------------------------------   
   -- see if the record exsits --
   ------------------------------
   l_rec.location_code := cwms_loc.get_location_code(
      l_office_id, 
      p_location_id);
   l_rec.parameter_code := cwms_ts.get_parameter_code(
      cwms_util.get_base_id(p_parameter_id),
      cwms_util.get_sub_id(p_parameter_id),
      l_office_id,
      'F');
   select unit_code
     into l_rec.unit_code
     from cwms_unit
    where unit_id = cwms_util.get_unit_id(p_unit_id, l_office_id);            
   begin
      select *
        into l_rec
        from at_display_scale
       where location_code = l_rec.location_code
         and parameter_code = l_rec.parameter_code
         and unit_code = l_rec.unit_code;
         
      l_exists := true;         
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'CWMS scale limits',
            l_office_id
            ||'/'
            ||p_location_id
            ||'.'
            ||p_parameter_id
            ||'/'
            ||p_unit_id);
      end if;
   else
      if p_scale_min is null then
         cwms_err.raise(
            'ERROR',
            'Scale minimum must not be null on new record.');
      end if;   
      if p_scale_max is null then
         cwms_err.raise(
            'ERROR',
            'Scale maximum must not be null on new record.');
      end if;
   end if;
   -------------------------   
   -- populate the record --
   -------------------------
   if p_scale_min is not null or not l_ignore_nulls then
      l_rec.scale_min := p_scale_min;
   end if;   
   if p_scale_max is not null or not l_ignore_nulls then
      l_rec.scale_max := p_scale_max;
   end if;
   ---------------------------------   
   -- insert or update the record --
   ---------------------------------
   if l_exists then
      update at_display_scale
         set row = l_rec
       where location_code = l_rec.location_code
         and parameter_code = l_rec.parameter_code
         and unit_code = l_rec.unit_code;
   else
      insert
        into at_display_scale
      values l_rec;
   end if;   
end store_scale_limits;   

--------------------------------------------------------------------------------
-- procedure retrieve_scale_limits
--------------------------------------------------------------------------------
procedure retrieve_scale_limits(
   p_scale_min        out number,
   p_scale_max        out number,
   p_derived          out varchar2,
   p_location_id      in  varchar2,
   p_parameter_id     in  varchar2, 
   p_unit_id          in  varchar2, 
   p_adjustment_level in  number default 0,
   p_office_id        in  varchar2 default null)
is
   l_office_id varchar2(16);
   l_rec       at_display_scale%rowtype;
   l_exists    boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_parameter_id, 
      p_unit_id,
      p_office_id));
      
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');
   end if;   
   if p_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Parameter identifier must not be null.');
   end if;   
   if p_unit_id is null then
      cwms_err.raise(
         'ERROR',
         'Unit identifier must not be null.');
   end if;       
   ------------------------------   
   -- see if the record exsits --
   ------------------------------
   l_rec.location_code := cwms_loc.get_location_code(
      l_office_id, 
      p_location_id);
   l_rec.parameter_code := cwms_ts.get_parameter_code(
      cwms_util.get_base_id(p_parameter_id),
      cwms_util.get_sub_id(p_parameter_id),
      l_office_id,
      'F');
   select unit_code
     into l_rec.unit_code
     from cwms_unit
    where unit_id = cwms_util.get_unit_id(p_unit_id, l_office_id);            
   begin
      select *
        into l_rec
        from at_display_scale
       where location_code = l_rec.location_code
         and parameter_code = l_rec.parameter_code
         and unit_code = l_rec.unit_code;
         
      l_exists := true;         
   exception
      when no_data_found then
         l_exists := false;
   end;

   if l_exists then
      -----------------------------------
      -- record exists, get the limits --
      -----------------------------------
      p_scale_min := l_rec.scale_min;
      p_scale_max := l_rec.scale_max;
      p_derived   := 'F';
   else
      -----------------------------------------------------------
      -- record doesn't exist, derive limits from another unit --
      -----------------------------------------------------------
      declare
         l_unit_id    varchar2(16) := cwms_util.get_unit_id(p_unit_id, l_office_id);
         l_unit_codes number_tab_t;
         l_min_values number_tab_t;
         l_max_values number_tab_t;
      begin    
         select unit_code,
                scale_min,
                scale_max bulk collect
           into l_unit_codes,
                l_min_values,
                l_max_values
           from at_display_scale
          where location_code = l_rec.location_code
            and parameter_code = l_rec.parameter_code;
            
         p_scale_min := cwms_util.convert_units(l_min_values(1), l_unit_codes(1), l_unit_id);
         p_scale_max := cwms_util.convert_units(l_max_values(1), l_unit_codes(1), l_unit_id);
         p_derived   := 'T';
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS scale limits',
               l_office_id
               ||'/'
               ||p_location_id
               ||'.'
               ||p_parameter_id
               ||'/<any unit>');
      end;
   end if;
   ------------------------------------------------------------
   -- modify the limits to provide a nice scale if specified --
   ------------------------------------------------------------
   if p_adjustment_level != 0 then
      adjust_scale_limits(
         p_scale_min,
         p_scale_max,
         p_adjustment_level);
   end if;
      
end retrieve_scale_limits;

--------------------------------------------------------------------------------
-- procedure delete_scale_limits
--------------------------------------------------------------------------------
procedure delete_scale_limits(
   p_location_id    in varchar2,
   p_parameter_id   in varchar2, 
   p_unit_id        in varchar2, -- NULL = delete all units
   p_office_id      in varchar2 default null)
is
   l_office_id      varchar2(16);
   l_location_code  number(10);
   l_parameter_code number(10);
   l_unit_code      number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_parameter_id, 
      p_unit_id,
      p_office_id));
      
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');
   end if;   
   if p_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Parameter identifier must not be null.');
   end if;   
   if p_unit_id is null then
      cwms_err.raise(
         'ERROR',
         'Unit identifier must not be null.');
   end if;       
   ----------------------------------   
   -- retrieve the necessary codes --
   ----------------------------------   
   l_location_code := cwms_loc.get_location_code(
      l_office_id, 
      p_location_id);
   l_parameter_code := cwms_ts.get_parameter_code(
      cwms_util.get_base_id(p_parameter_id),
      cwms_util.get_sub_id(p_parameter_id),
      l_office_id,
      'F');
   if p_unit_id is not null then
      select unit_code
        into l_unit_code
        from cwms_unit
       where unit_id = cwms_util.get_unit_id(p_unit_id, l_office_id);            
   end if;
   --------------------------      
   -- delete the record(s) --
   --------------------------
   begin
      delete
        from at_display_scale
       where location_code = l_location_code
         and parameter_code = l_parameter_code
         and unit_code = nvl(l_unit_code, unit_code);
   exception 
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS scale limits',
            l_office_id
            ||'/'
            ||p_location_id
            ||'.'
            ||p_parameter_id
            ||'/'
            ||nvl(p_unit_id, '<any unit>'));
   end;      
end delete_scale_limits;

--------------------------------------------------------------------------------
-- procedure cat_scale_limits
--------------------------------------------------------------------------------
procedure cat_scale_limits(
   p_limits_catalog    out sys_refcursor,
   p_location_id_mask  in  varchar2 default '*',
   p_parameter_id_mask in  varchar2 default '*', 
   p_unit_id_mask      in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null)
is
   l_location_id_mask  varchar2(49);
   l_parameter_id_mask varchar2(49); 
   l_unit_id_mask      varchar2(16);
   l_office_id_mask    varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id_mask,
      p_parameter_id_mask, 
      p_unit_id_mask,
      p_office_id_mask));
   ----------------------
   -- set up the masks --
   ----------------------
   l_location_id_mask  := upper(cwms_util.normalize_wildcards(p_location_id_mask));
   l_parameter_id_mask := upper(cwms_util.normalize_wildcards(p_parameter_id_mask)); 
   l_unit_id_mask      := upper(cwms_util.normalize_wildcards(p_unit_id_mask));
   l_office_id_mask    := upper(cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id)));
   -----------------------   
   -- perform the query --
   -----------------------
   open p_limits_catalog for
      select o.office_id,
             bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id as location_id,
             bp.base_parameter_id
             ||substr('-', 1, length(p.sub_parameter_id))
             ||p.sub_parameter_id as parameter_id,
             u.unit_id,
             d.scale_min,
             d.scale_max
        from at_display_scale d,
             at_physical_location pl,
             at_base_location bl,
             at_parameter p,
             cwms_base_parameter bp,
             cwms_unit u,
             cwms_office o
       where pl.location_code = d.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code
         and o.office_id like l_office_id_mask escape '\' 
         and upper(bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id) like p_location_id_mask escape '\'
         and p.parameter_code = d.parameter_code
         and bp.base_parameter_code = p.base_parameter_code
         and upper(bp.base_parameter_id
             ||substr('-', 1, length(p.sub_parameter_id))
             ||p.sub_parameter_id) like l_parameter_id_mask escape '\'
         and u.unit_code = d.unit_code
         and upper(u.unit_id) like l_unit_id_mask escape '\'
    order by o.office_id,
             bl.base_location_id,
             pl.sub_location_id nulls first,
             bp.base_parameter_id,
             p.sub_parameter_id nulls first,
             u.unit_id;         
   
end cat_scale_limits;

--------------------------------------------------------------------------------
-- function cat_scale_limits_f
--------------------------------------------------------------------------------
function cat_scale_limits_f(
   p_location_id_mask  in  varchar2 default '*',
   p_parameter_id_mask in  varchar2 default '*', 
   p_unit_id_mask      in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_scale_limits(
      l_cursor,
      p_location_id_mask,
      p_parameter_id_mask, 
      p_unit_id_mask,
      p_office_id_mask);
      
   return l_cursor;      
end cat_scale_limits_f;

--------------------------------------------------------------------------------
-- procedure store_unit
--------------------------------------------------------------------------------
procedure store_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_unit_id        in varchar2,
   p_office_id      in varchar2 default null)
is
   l_fail_if_exists boolean;
   l_ignore_nulls   boolean;
   l_exists         boolean;
   l_rec            at_display_units%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_parameter_id,
      p_unit_system,
      p_fail_if_exists,
      p_ignore_nulls,
      p_unit_id,
      p_office_id));
   if p_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Parameter identifier must not be null.');
   end if;
   if upper(p_unit_system) not in ('EN', 'SI') then
      cwms_err.raise(
         'INVALID_ITEM',
         nvl(p_unit_system, '<NULL>'),
         'CWMS Unit system - use ''EN'' or ''SI''');
   end if;
   if p_unit_id is null then
      cwms_err.raise(
         'ERROR',
         'Unit identifier must not be null.');
   end if;
   ------------------------------       
   -- see if the record exists --
   ------------------------------
   l_rec.db_office_code := cwms_util.get_db_office_code(p_office_id);
   l_rec.parameter_code := cwms_ts.get_parameter_code(
      cwms_util.get_base_id(p_parameter_id),
      cwms_util.get_sub_id(p_parameter_id),
      nvl(upper(p_office_id), cwms_util.user_office_id),
      'F');
   l_rec.unit_system := upper(p_unit_system);
   begin
      select *
        into l_rec
        from at_display_units
       where db_office_code = l_rec.db_office_code
         and parameter_code = l_rec.parameter_code
         and unit_system    = l_rec.unit_system;
         
      l_exists := true;         
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'CWMS display unit',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_parameter_id
         ||'/'
         ||p_unit_system);
   end if;
   -------------------------                
   -- populate the record --
   -------------------------
   begin
      select unit_code
        into l_rec.display_unit_code
        from cwms_unit
       where unit_id = cwms_util.get_unit_id(p_unit_id, p_office_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_unit_id,
            'CWMS unit identifier or alias.');
   end;
   ---------------------------------                   
   -- insert or update the record --
   ---------------------------------
   if l_exists then
      update at_display_units
         set row = l_rec
       where db_office_code = l_rec.db_office_code
         and parameter_code = l_rec.parameter_code
         and unit_system    = l_rec.unit_system;
   else
      insert
        into at_display_units
      values l_rec;
   end if;                   
end store_unit;      

--------------------------------------------------------------------------------
-- procedure retrieve_unit
--------------------------------------------------------------------------------
procedure retrieve_unit(
   p_unit_id        out varchar2,
   p_parameter_id   in  varchar2,
   p_unit_system    in  varchar2,
   p_office_id      in  varchar2 default null)
is
   l_rec at_display_units%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_parameter_id,
      p_unit_system,
      p_office_id));
   if p_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Parameter identifier must not be null.');
   end if;
   if upper(p_unit_system) not in ('EN', 'SI') then
      cwms_err.raise(
         'INVALID_ITEM',
         nvl(p_unit_system, '<NULL>'),
         'CWMS Unit system - use ''EN'' or ''SI''');
   end if;
   ------------------------------       
   -- see if the record exists --
   ------------------------------
   l_rec.db_office_code := cwms_util.get_db_office_code(p_office_id);
   l_rec.parameter_code := cwms_ts.get_parameter_code(
      cwms_util.get_base_id(p_parameter_id),
      cwms_util.get_sub_id(p_parameter_id),
      nvl(upper(p_office_id), cwms_util.user_office_id),
      'F');
   l_rec.unit_system := upper(p_unit_system);
   select u.unit_id
     into p_unit_id
     from at_display_units du,
          cwms_unit u
    where du.db_office_code = l_rec.db_office_code
      and du.parameter_code = l_rec.parameter_code
      and du.unit_system    = l_rec.unit_system
      and u.unit_code = du.display_unit_code;
exception
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'CWMS display unit',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_parameter_id
         ||'/'
         ||p_unit_system);
end retrieve_unit;

--------------------------------------------------------------------------------
-- procedure delete_unit
--------------------------------------------------------------------------------
procedure delete_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2, -- NULL = all unit systems
   p_office_id      in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_parameter_id,
      p_unit_system,
      p_office_id));
   if p_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Parameter identifier must not be null.');
   end if;
   if upper(nvl(p_unit_system, 'EN')) not in ('EN', 'SI') then
      cwms_err.raise(
         'INVALID_ITEM',
         p_unit_system,
         'CWMS Unit system - use ''EN'' or ''SI''');
   end if;
   delete
     from at_display_units
    where db_office_code = cwms_util.get_db_office_code(p_office_id)
      and unit_system = nvl(upper(p_unit_system), unit_system)
      and parameter_code = cwms_ts.get_parameter_code(
                              cwms_util.get_base_id(p_parameter_id),
                              cwms_util.get_sub_id(p_parameter_id),
                              nvl(upper(p_office_id), cwms_util.user_office_id),
                              'F');
exception
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'CWMS display unit',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_parameter_id
         ||'/'
         ||nvl(p_unit_system, '<any>'));
end delete_unit;

--------------------------------------------------------------------------------
-- procedure cat_unit
--------------------------------------------------------------------------------
procedure cat_unit(
   p_unit_catalog      out sys_refcursor,
   p_parameter_id_mask in  varchar2 default '*',
   p_unit_system_mask  in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null)
is
   l_parameter_id_mask varchar2(49);
   l_unit_system_mask  varchar2(2);
   l_office_id_mask    varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_parameter_id_mask,
      p_unit_system_mask,
      p_office_id_mask));
   ----------------------      
   -- set up the masks --
   ----------------------      
   l_parameter_id_mask := cwms_util.normalize_wildcards(upper(p_parameter_id_mask));
   l_unit_system_mask  := cwms_util.normalize_wildcards(upper(p_unit_system_mask));
   l_office_id_mask    := cwms_util.normalize_wildcards(nvl(upper(p_office_id_mask), cwms_util.user_office_id));
   -----------------------
   -- perform the query --
   -----------------------
   open p_unit_catalog for
      select o.office_id,
             bp.base_parameter_id
             ||substr('-', 1, length(p.sub_parameter_id))
             ||p.sub_parameter_id as parameter_id,
             du.unit_system,
             u.unit_id
        from at_display_units du,
             at_parameter p,
             cwms_base_parameter bp,
             cwms_unit u,
             cwms_office o
       where o.office_id like l_office_id_mask escape '\'
         and du.db_office_code = o.office_code
         and p.parameter_code = du.parameter_code
         and bp.base_parameter_code = p.base_parameter_code
         and upper(bp.base_parameter_id
             ||substr('-', 1, length(p.sub_parameter_id))
             ||p.sub_parameter_id) like l_parameter_id_mask escape '\'
         and du.unit_system like l_unit_system_mask escape '\'
         and u.unit_code = du.display_unit_code
    order by o.office_id,
             bp.base_parameter_id,
             p.sub_parameter_id nulls first,         
             du.unit_system;
             
end cat_unit;

--------------------------------------------------------------------------------
-- function cat_unit_f
--------------------------------------------------------------------------------
function cat_unit_f(
   p_parameter_id_mask in varchar2 default '*',
   p_unit_system_mask  in varchar2 default '*',
   p_office_id_mask    in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_unit(
      l_cursor,
      p_parameter_id_mask,
      p_unit_system_mask,
      p_office_id_mask);
      
   return l_cursor;      
end cat_unit_f;

--------------------------------------------------------------------------------
-- procedure retrieve_status_indicators
--------------------------------------------------------------------------------
procedure retrieve_status_indicators(
   p_indicators   out tsv_array,
   p_tsid         in  varchar2,
   p_level_id     in  varchar2,
   p_indicator_id in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_time_zone    in  varchar2 default 'UTC',
   p_expression   in  varchar2 default null,
   p_office_id    in  varchar2 default null)
is
   type l_cursor_rec_t is record (
      indicator_id     varchar2(423),
      attribute_id     varchar2(83),
      attribute_value  number,
      attribute_units  varchar2(16),
      indicator_values ztsv_array);  

   l_cursor sys_refcursor;
   l_rec    l_cursor_rec_t;
   l_tokens str_tab_t;   
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_tsid,
      p_level_id,
      p_indicator_id,
      p_time_zone,
      p_expression,
      p_office_id));
   if p_tsid is null then
      cwms_err.raise(
         'ERROR',
         'Time series identifier must not be null.');
   end if;
   if p_level_id is null then
      cwms_err.raise(
         'ERROR',
         'Specified level identifier must not be null.');
   end if;
   if p_indicator_id is null then
      cwms_err.raise(
         'ERROR',
         'Level indicator identifier must not be null.');
   end if;
   if p_start_time is null then
      cwms_err.raise(
         'ERROR',
         'Start time must not be null.');
   end if;
   ---------------------------------------      
   -- retrieve the indicator max values --
   ---------------------------------------      
   cwms_level.get_level_indicator_max_values(
      p_cursor               => l_cursor,
      p_tsid                 => p_tsid,
      p_start_time           => p_start_time,
      p_end_time             => p_end_time,
      p_time_zone            => p_time_zone,
      p_specified_level_mask => p_level_id,
      p_indicator_id_mask    => p_indicator_id,
      p_office_id            => p_office_id);
   loop
      fetch l_cursor into l_rec;
      exit when l_cursor%notfound; 
      if l_rec.attribute_id is null then
         p_indicators := tsv_array();
         p_indicators.extend(l_rec.indicator_values.count);
         for i in 1..l_rec.indicator_values.count loop
            p_indicators(i).date_time    := from_tz(cast(l_rec.indicator_values(i).date_time as timestamp), p_time_zone);
            p_indicators(i).value        := l_rec.indicator_values(i).value;
            p_indicators(i).quality_code := l_rec.indicator_values(i).quality_code;
         end loop;
         exit;
      end if;
   end loop;
   close l_cursor;
   ---------------------------------------------------      
   -- modify the indicator values by the expression --
   ---------------------------------------------------
   if p_expression is not null then
      -------------------------------
      -- tokenize algebraic or RPN --
      -------------------------------
      l_tokens := cwms_util.tokenize_expression(p_expression);
      --------------------------------------------------
      -- apply the expression to each indicator value --
      --------------------------------------------------
      for i in 1..p_indicators.count loop
         p_indicators(i).value := cwms_util.eval_tokenized_expression(
            l_tokens,
            double_tab_t(p_indicators(i).value));
      end loop;
   end if;
         
end retrieve_status_indicators;   

--------------------------------------------------------------------------------
-- function retrieve_status_indicators_f
--------------------------------------------------------------------------------
function retrieve_status_indicators_f(
   p_tsid         in varchar2,
   p_level_id     in varchar2,
   p_indicator_id in varchar2,
   p_start_time   in date,
   p_end_time     in date,
   p_time_zone    in varchar2 default 'UTC',
   p_expression   in varchar2 default null,
   p_office_id    in varchar2 default null)
   return tsv_array
is
   l_indicators tsv_array;
begin
   retrieve_status_indicators(
      l_indicators,
      p_tsid,
      p_level_id,
      p_indicator_id,
      p_start_time,
      p_end_time,
      p_time_zone,
      p_expression,
      p_office_id);
      
   return l_indicators;      
end retrieve_status_indicators_f;   

end cwms_display;
/
show errors;
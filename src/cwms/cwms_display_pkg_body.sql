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
      
      while l_max_value < p_max_value loop
         if l_diff2 = 2 then l_diff2 := 5;
         else                l_diff2 := l_diff2 * 2;
         end if;
         
         l_min_value := p_min_value - mod(p_min_value, l_interval);
         if p_adjustment_level > 1 then
            l_min_value := l_min_value - mod(l_min_value, l_diff2 * l_interval);
         end if;
         l_max_value := l_min_value + l_diff2 * l_interval;
      end loop;
   
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
   p_unit_id        in varchar2,
   p_fail_if_exists in varchar2,
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
-- function make_user_unit_property
--------------------------------------------------------------------------------
function make_user_unit_property_id(
   p_user_id      in varchar2,
   p_parameter_id in varchar2,
   p_unit_system  in varchar2)
   return varchar2
is
begin
   return cwms_util.join_text(str_tab_t(
      'display_unit',
      upper(p_user_id),
      upper(p_unit_system),
      p_parameter_id),
      '.');
end make_user_unit_property_id;

--------------------------------------------------------------------------------
-- procedure store_user_unit
--------------------------------------------------------------------------------
procedure store_user_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_unit_id        in varchar2,
   p_fail_if_exists in varchar2,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null)
is
   l_user_id     varchar2(30);
   l_office_id   varchar2(16);
   l_base_param  number(10);
   l_property_id varchar2(256);
   l_unit_id     varchar2(256);
   l_comment     varchar2(256);
begin
   -------------------
   -- sanity checks --
   -------------------
   if upper(p_unit_system) not in ('EN', 'SI') then
      cwms_err.raise('INVALID_ITEM', p_unit_system, 'CWMS unit system');
   end if;
   begin
      select base_parameter_code
        into l_base_param
        from cwms_base_parameter
       where base_parameter_id = cwms_util.get_base_id(p_parameter_id);
   exception
      when no_data_found then
         cwms_err.raise('INVALID_PARAM_ID', p_parameter_id);
   end;
   declare
      l_converted binary_double;
   begin
      l_converted := cwms_util.convert_units(
         1.0,
         cwms_util.get_default_units(p_parameter_id),
         p_unit_id);
   exception
      when others then
         cwms_err.raise('ERROR', p_unit_id||' is not a valid unit for '||p_parameter_id);
   end;
   l_user_id   := upper(nvl(p_user_id, cwms_util.get_user_id));
   l_office_id := nvl(p_office_id, cwms_util.user_office_id);
   ----------------------------------------------
   -- determine if the property already exists --
   ----------------------------------------------
   l_property_id := make_user_unit_property_id(
      l_user_id,
      p_parameter_id,
      p_unit_system);
   if cwms_util.is_true(p_fail_if_exists) then
      cwms_properties.get_property(
         l_unit_id,
         l_comment,
         'CWMSDB',
         l_property_id,
         null,
         l_office_id);
      if l_unit_id is not null then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Property '||l_office_id||'/CWMSDB/'||l_property_id);
      end if;
   end if;
   ----------------------
   -- set the property --
   ----------------------
   cwms_properties.set_property(
      'CWMSDB',
      l_property_id,
      p_unit_id,
      null,
      l_office_id);
end store_user_unit;

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
-- function retrieve_unit_f
--------------------------------------------------------------------------------
function retrieve_unit_f(
   p_parameter_id   in  varchar2,
   p_unit_system    in  varchar2,
   p_office_id      in  varchar2 default null)
   return varchar2
is
   l_unit varchar2(16);
begin
   retrieve_unit(l_unit, p_parameter_id, p_unit_system, p_office_id);
   return l_unit;
end retrieve_unit_f;

--------------------------------------------------------------------------------
-- procedure retrieve_user_unit
--------------------------------------------------------------------------------
procedure retrieve_user_unit(
   p_unit_id        out varchar2,
   p_parameter_id   in  varchar2,
   p_unit_system    in  varchar2 default null,
   p_user_id        in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   item_does_not_exist exception; pragma exception_init(item_does_not_exist, -20034);
   l_user_id     varchar2(30);
   l_office_id   varchar2(16);
   l_unit_system varchar2(2);
   l_property_id varchar2(256);
   l_comment     varchar2(256);
   l_unit_id     varchar2(16);
   l_base_param  number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_unit_system is not null and upper(p_unit_system) not in ('EN', 'SI') then
      cwms_err.raise('INVALID_ITEM', p_unit_system, 'CWMS unit system');
   end if;
   begin
      select base_parameter_code
        into l_base_param
        from cwms_base_parameter
       where base_parameter_id = cwms_util.get_base_id(p_parameter_id);
   exception
      when no_data_found then
         cwms_err.raise('INVALID_PARAM_ID', p_parameter_id);
   end;
   l_user_id   := upper(nvl(p_user_id, cwms_util.get_user_id));
   l_office_id := nvl(p_office_id, cwms_util.user_office_id);
   if p_unit_system is null then
      begin
         select display_unit_system
           into l_unit_system
           from at_user_preferences
          where db_office_code = cwms_util.get_db_office_code(l_office_id)
            and username = l_user_id;
      exception
         when no_data_found then l_unit_system := 'SI';
      end;
   else
      l_unit_system := p_unit_system;      
   end if;
   --------------------------------
   -- see if the property exists --
   --------------------------------
   l_property_id := make_user_unit_property_id(
      l_user_id,
      p_parameter_id,
      l_unit_system);

   cwms_properties.get_property(
      l_unit_id,
      l_comment,
      'CWMSDB',
      l_property_id,
      null,
      l_office_id);
   -------------------------------------
   -- use office unit if no user unit --
   -------------------------------------
   begin
      retrieve_unit(l_unit_id, p_parameter_id, l_unit_system, l_office_id);
   exception
      when item_does_not_exist then null;
   end;
   ---------------------------------------
   -- use default unit as a last resort --
   ---------------------------------------
   if l_unit_id is null then
      l_unit_id := cwms_util.get_default_units(p_parameter_id, l_unit_system);
   end if;
   p_unit_id := l_unit_id;
end retrieve_user_unit;

--------------------------------------------------------------------------------
-- function retrieve_user_unit_f
--------------------------------------------------------------------------------
function retrieve_user_unit_f(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2 default null,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null)
   return varchar2
is
   l_unit_id varchar2(16);
begin
   retrieve_user_unit(
      l_unit_id,
      p_parameter_id,
      p_unit_system,
      p_user_id,
      p_office_id);
   return l_unit_id;
end retrieve_user_unit_f;

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
-- procedure delete_user_unit
--------------------------------------------------------------------------------
procedure delete_user_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_user_id        in varchar2 default null,
   p_office_id      in varchar2 default null)
is
   l_user_id     varchar2(30);
   l_office_id   varchar2(16);
   l_property_id varchar2(256);
begin
   -------------------
   -- sanity checks --
   -------------------
   l_user_id   := upper(nvl(p_user_id, cwms_util.get_user_id));
   l_office_id := nvl(p_office_id, cwms_util.user_office_id);
   -------------------------
   -- delete the property --
   -------------------------
   l_property_id := make_user_unit_property_id(
      l_user_id,
      p_parameter_id,
      p_unit_system);
   cwms_properties.delete_property(
      'CWMSDB',
      l_property_id,
      l_office_id);
end delete_user_unit;

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
   p_indicators      out tsv_array,
   p_tsid            in  varchar2,
   p_level_id        in  varchar2,
   p_indicator_id    in  varchar2,
   p_start_time      in  date,
   p_end_time        in  date,
   p_attribute_id    in  varchar2 default null,
   p_attribute_value in  number   default null,
   p_attribute_unit  in  varchar2 default null,
   p_time_zone       in  varchar2 default 'UTC',
   p_expression      in  varchar2 default null,
   p_office_id       in  varchar2 default null)
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
   l_parts  str_tab_t;
   l_match  boolean := false;   
begin
   -------------------
   -- sanity checks --
   -------------------
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
   l_parts := cwms_util.split_text(p_level_id, '.');
   if l_parts.count != 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_level_id,
         'CWMS location level identifier');
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
      p_specified_level_mask => l_parts(5),
      p_indicator_id_mask    => p_indicator_id,
      p_office_id            => p_office_id);
   loop
      fetch l_cursor into l_rec;
      exit when l_cursor%notfound;
      if p_attribute_id is null then
         if l_rec.attribute_id is null then
            l_match := true;
         end if;
      else
         if upper(l_rec.attribute_id) = upper(p_attribute_id) and
            cwms_util.convert_units(l_rec.attribute_value, l_rec.attribute_units, p_attribute_unit) = p_attribute_value
         then
            l_match := true;
         end if;
      end if;
      if l_match then 
         if l_rec.indicator_values is not null and l_rec.indicator_values.count > 0 then
            p_indicators := tsv_array();
            p_indicators.extend(l_rec.indicator_values.count);
            for i in 1..l_rec.indicator_values.count loop
               p_indicators(i) := tsv_type(  
                  from_tz(cast(l_rec.indicator_values(i).date_time as timestamp), p_time_zone),
                  l_rec.indicator_values(i).value,
                  l_rec.indicator_values(i).quality_code);
            end loop;
         end if;
         exit;
      end if;
   end loop;
   close l_cursor;
   ---------------------------------------------------      
   -- modify the indicator values by the expression --
   ---------------------------------------------------
   if p_expression is not null and p_indicators is not null then
      -------------------------------
      -- tokenize algebraic or RPN --
      -------------------------------
      l_tokens := cwms_util.tokenize_expression(p_expression);
      --------------------------------------------------
      -- apply the expression to each indicator value --
      --------------------------------------------------
      for i in 1..p_indicators.count loop
         if p_indicators(i).value > 0 then
            p_indicators(i).value := cwms_util.eval_tokenized_expression(
               l_tokens,
               double_tab_t(p_indicators(i).value));
         end if;
      end loop;
   end if;
         
end retrieve_status_indicators;   

--------------------------------------------------------------------------------
-- function retrieve_status_indicators_f
--------------------------------------------------------------------------------
function retrieve_status_indicators_f(
   p_tsid            in varchar2,
   p_level_id        in varchar2,
   p_indicator_id    in varchar2,
   p_start_time      in date,
   p_end_time        in date,
   p_attribute_id    in varchar2 default null,
   p_attribute_value in number   default null,
   p_attribute_unit  in varchar2 default null,
   p_time_zone       in varchar2 default 'UTC',
   p_expression      in varchar2 default null,
   p_office_id       in varchar2 default null)
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
      p_attribute_id,
      p_attribute_value,
      p_attribute_unit,
      p_time_zone,
      p_expression,
      p_office_id);
      
   return l_indicators;      
end retrieve_status_indicators_f;   

--------------------------------------------------------------------------------
-- function retrieve_status_indicators_f
--
-- p_expression
--    an algebraic or RPN expression to map the integer values of 1..5 onto
--    a different range, the indicator value to be mapped is specified as ARG1
--
--    the following expressions can be used to map the values onto the integer
--    range of 1..3 in various ways:
--
--    'TRUNC((ARG1 + 2) / 2)'              skinny bottom : 1,2,2,3,3
--    'TRUNC((ARG1 + 1) / 2)'              skinny top    : 1,1,2,2,3
--    'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'      fat bottom    : 1,1,1,2,3
--    'TRUNC((ARG1 - 2) / 3 + 2)',         fat middle    : 1,2,2,2,3 
--    'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'  fat top       : 1,2,3,3,3
--
--------------------------------------------------------------------------------
function retrieve_status_indicator_f(
   p_tsid            in varchar2,
   p_level_id        in varchar2,
   p_indicator_id    in varchar2,
   p_eval_time       in date     default sysdate,
   p_attribute_id    in varchar2 default null,
   p_attribute_value in number   default null,
   p_attribute_unit  in varchar2 default null,
   p_time_zone       in varchar2 default 'UTC',
   p_expression      in varchar2 default null,
   p_office_id       in varchar2 default null)
   return integer
is
   type l_rec_t is record(
      indicator_id     varchar2(423),
      attribute_id     varchar2(83),
      attribute_value  number,           
      attribute_units  varchar2(16),
      indicator_values number_tab_t);
   l_cursor sys_refcursor;
   l_parts  str_tab_t;
   l_rec    l_rec_t;
   l_value  integer := 0;
   l_match  boolean := false;
begin
   -------------------
   -- sanity checks --
   -------------------
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
   l_parts := cwms_util.split_text(p_level_id, '.');
   if l_parts.count != 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_level_id,
         'CWMS location level identifier');
   end if;
   ------------------------------   
   -- get the indicator values --
   ------------------------------   
   cwms_level.get_level_indicator_values(
      l_cursor,
      p_tsid,
      p_eval_time,
      p_time_zone,
      l_parts(5),
      p_indicator_id,
      'SI',
      p_office_id);
   loop
      fetch l_cursor into l_rec;
      exit when l_cursor%notfound;
      if p_attribute_id is null then
         if l_rec.attribute_id is null then
            l_match := true;
         end if;
      else
         if upper(l_rec.attribute_id) = upper(p_attribute_id) and
            cwms_util.convert_units(l_rec.attribute_value, l_rec.attribute_units, p_attribute_unit) = p_attribute_value
         then
            l_match := true;
         end if;
      end if;
      if l_match then
         if l_rec.indicator_values is not null and l_rec.indicator_values.count > 0 then
            l_value := l_rec.indicator_values(l_rec.indicator_values.count);
         end if;
         exit;
      end if;      
   end loop;
   close l_cursor;
   
   return l_value;            
end retrieve_status_indicator_f;

--------------------------------------------------------------------------------
-- procedure set_store_rule_ui_info
--------------------------------------------------------------------------------
procedure set_store_rule_ui_info(
   p_ordered_rules in varchar2,
   p_default_rule  in varchar2,
   p_office_id     in varchar2 default null)
is
   l_ordered_rules str_tab_t;
   l_default_rule  varchar2(32);
   l_office_code   integer;
   l_max_count     integer;
begin
   l_office_code  := cwms_util.get_office_code(upper(trim(p_office_id)));
   ----------------
   -- sort order --
   ----------------
   l_default_rule := upper(trim(p_default_rule));
   delete from at_store_rule_order where office_code = l_office_code;
   if p_ordered_rules is not null then
      l_ordered_rules := cwms_util.split_text(regexp_replace(upper(trim(p_ordered_rules)), '\s*,\s*', ','), ',');
      select count(*)
        into l_max_count
        from cwms_store_rule;
      for i in 1..least(l_ordered_rules.count, l_max_count) loop
         insert
           into at_store_rule_order
         values (l_office_code, l_ordered_rules(i), i);
      end loop;  
   end if;
   ------------------
   -- default rule --
   ------------------
   delete from at_store_rule_default where office_code = l_office_code;
   if l_default_rule is not null then
      insert
        into at_store_rule_default
      values (l_office_code, l_default_rule);  
   end if;
end set_store_rule_ui_info;   

--------------------------------------------------------------------------------
-- procedure set_specified_level_ui_info
--------------------------------------------------------------------------------
procedure set_specified_level_ui_info (
   p_ordered_levels in varchar2,
   p_office_id      in varchar2 default null)
is
   l_ordered_levels       str_tab_t;
   l_office_code          integer;
   l_specified_level_code integer;
begin
   l_office_code := cwms_util.get_office_code(upper(trim(p_office_id)));
   delete from at_specified_level_order where office_code = l_office_code;
   if p_ordered_levels is not null then
      l_ordered_levels := cwms_util.split_text(regexp_replace(upper(trim(p_ordered_levels)), '\s*,\s*', ','), ',');
      for i in 1..l_ordered_levels.count loop
         select specified_level_code
           into l_specified_level_code
           from at_specified_level
          where upper(specified_level_id) = l_ordered_levels(i)
            and office_code in (l_office_code, cwms_util.db_office_code_all); 
         insert
           into at_specified_level_order
         values (l_office_code, l_specified_level_code, i);  
      end loop;
   end if;
end set_specified_level_ui_info;      


end cwms_display;
/
show errors;
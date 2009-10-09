CREATE OR REPLACE PACKAGE BODY cwms_level as

--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE validate_input
--------------------------------------------------------------------------------
procedure validate_input(
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
-- PROCEDURE create_specified_level
--------------------------------------------------------------------------------
procedure create_specified_level(
   p_level_code     out number,
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null)
is   
   l_office_code    number;
   l_fail_if_exists boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_level_code     number(10) := null;
   l_rec            at_specified_level%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   validate_input(l_office_code, p_level_id, p_office_id);
   ----------------------------------------
   -- see if the level id already exists --
   ----------------------------------------
   begin
      select *
        into l_rec
        from at_specified_level
       where office_code = l_office_code
         and specified_level_id = upper(p_level_id);
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
   l_level_code        number(10) := null;
   l_fail_if_not_found boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   validate_input(l_office_code, p_office_id, p_level_id);
   l_fail_if_not_found := cwms_util.return_true_or_false(p_fail_if_not_found);
   -----------------------
   -- retrieve the code --
   -----------------------
   begin
      select specified_level_code
        into l_level_code
        from at_specified_level
       where office_code = l_office_code
         and specified_level_id = upper(p_level_id);
   exception
      when no_data_found then
         if l_fail_if_not_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Specified level',
               p_level_id);
         end if;
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
   p_location_level_code  out number,
   p_location_id          in  varchar2,
   p_parameter_id         in  varchar2,
   p_parameter_type_id    in  varchar2,
   p_duration_id          in  varchar2,
   p_spec_level_id        in  varchar2,
   p_level_value          in  number,
   p_level_units          in  varchar2,
   p_fail_if_exists       in  varchar2 default 'T',
   p_interval_in_local_tz in  varchar2 default 'T',
   p_interpolate          in  varchar2 default 'T',
   p_level_comment        in  varchar2 default null,
   p_effective_date       in  date default null,
   p_interval_origin      in  date default null,
   p_calendar_interval    in  interval year to month default null,
   p_time_interval        in  interval day to second default null,
   p_seasonal_values      in  seasonal_value_array default null,
   p_office_id            in  varchar2 default null)
is
   l_location_level_code number(10) := null;
   l_office_code         number;
   l_fail_if_exists      boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_spec_level_code     number(10);
   l_loc_level_code      number(10);
   l_interval_origin     date;
   l_location_code       number(10);
   l_parts               cwms_util.str_tab_t;
   l_base_parameter_id   varchar2(16);
   l_sub_parameter_id    varchar2(48);
   l_parameter_code      number(10);
   l_parameter_type_code number(10);
   l_duration_code       number(10);
   l_effective_date      date := nvl(p_effective_date,
         to_date('01JAN1900 0000', 'ddmonyyyy hh24mi'));
begin
   -------------------
   -- sanity checks --
   -------------------
   validate_input(l_office_code, p_spec_level_id, p_office_id);
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
      if p_calendar_interval is null and p_time_interval is null then
         cwms_err.raise(
            'ERROR',
            'seasonal values require either calendar interval or time interval '
            || 'in CREATE_LOCATION_LEVEL');
      elsif p_calendar_interval is not null and p_time_interval is not null then
         cwms_err.raise(
            'ERROR',
            'seasonal values cannot have calendar interval and time interval '
            || 'in CREATE_LOCATION_LEVEL');
      end if;
   end if;
   ---------------------------------
   -- get the codes for input ids --
   ---------------------------------
   l_location_code := cwms_loc.get_location_code(l_office_code, p_location_id);
   l_parts := cwms_util.split_text(p_parameter_id, '-', 1);
   l_base_parameter_id := l_parts(1);
   l_sub_parameter_id := l_parts(2);
   l_parameter_code := cwms_ts.get_parameter_code(
      l_base_parameter_id,
      l_sub_parameter_id,
      'F',
      p_office_id);
   begin
      select parameter_type_code
        into l_parameter_type_code
        from cwms_parameter_type
       where parameter_type_id = p_parameter_type_id;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_parameter_type_id,
            'parameter type id');
   end;
   begin
      select duration_code
        into l_duration_code
        from cwms_duration
       where duration_id = p_duration_id;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_duration_id,
            'duration id');
   end;
   l_spec_level_code := retrieve_specified_level(
      p_spec_level_id,
      'F',
      p_office_id);
   if l_spec_level_code is null then
      l_spec_level_code := create_specified_level(
         p_spec_level_id,
         null,
         'T',
         p_office_id);
   end if;
   --------------------------------------
   -- determine whether already exists --
   --------------------------------------
   begin
      select location_level_code
        into l_location_level_code
        from at_location_level
       where location_code = l_location_code
         and specified_level_code = l_spec_level_code
         and parameter_code = l_parameter_code
         and parameter_type_code = l_parameter_type_code
         and duration_code = l_duration_code;
      -----------------------------
      -- existing location level --
      -----------------------------
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Location level code',
            p_location_id
            || '.' || p_parameter_id
            || '.' || p_parameter_type_id
            || '.' || p_duration_id
            || '/' || p_spec_level_id);
      end if;
      -------------------------------
      -- update the existing level --
      -------------------------------
      if p_seasonal_values is null then
         --------------------
         -- constant value --
         --------------------
         update at_location_level
            set location_level_code = l_location_level_code,
                location_code = l_location_code,
                specified_level_code = l_spec_level_code,
                parameter_code = l_parameter_code,
                parameter_type_code = l_parameter_type_code,
                duration_code = l_duration_code,
                location_level_date = l_effective_date,
                calendar_interval = null,
                time_interval = null,
                interval_origin = null,
                interval_in_local_tz = null,
                interpolate = null,
                location_level_value = p_level_value,
                location_level_comment = p_level_comment;
         delete
           from at_seasonal_location_level
          where location_level_code = l_location_level_code;
      else
         ---------------------
         -- seasonal values --
         ---------------------
         l_interval_origin := nvl(
            p_interval_origin,
            to_date('01JAN1900 0000', 'ddmonyyyy hh24mi'));
         if p_calendar_interval is null then
            -------------------
            -- time interval --
            -------------------
            update at_location_level
               set location_level_code = l_location_level_code,
                   location_code = l_location_code,
                   specified_level_code = l_spec_level_code,
                   parameter_code = l_parameter_code,
                   parameter_type_code = l_parameter_type_code,
                   duration_code = l_duration_code,
                   location_level_date = l_effective_date,
                   calendar_interval = null,
                   time_interval = p_time_interval,
                   interval_origin = l_interval_origin,
                   interval_in_local_tz = p_interval_in_local_tz,
                   interpolate = p_interpolate,
                   location_level_value = null,
                   location_level_comment = p_level_comment;
         else
            -----------------------
            -- calendar interval --
            -----------------------
            update at_location_level
               set location_level_code = l_location_level_code,
                   location_code = l_location_code,
                   specified_level_code = l_spec_level_code,
                   parameter_code = l_parameter_code,
                   parameter_type_code = l_parameter_type_code,
                   duration_code = l_duration_code,
                   location_level_date = l_effective_date,
                   calendar_interval = p_calendar_interval,
                   time_interval = null,
                   interval_origin = l_interval_origin,
                   interval_in_local_tz = p_interval_in_local_tz,
                   interpolate = p_interpolate,
                   location_level_value = null,
                   location_level_comment = p_level_comment;
         end if;
         delete
           from at_seasonal_location_level
          where location_level_code = l_location_level_code;
         for i in 1..p_seasonal_values.count loop
            insert
              into at_seasonal_location_level
            values(l_location_level_code,
                   p_seasonal_values(i).offset_months,
                   p_seasonal_values(i).offset_minutes,
                   p_seasonal_values(i).value);
         end loop;
      end if;
   exception
      when no_data_found then
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
                   null, null, null, null, null,
                   p_level_value,
                   p_level_comment);
         else
            ---------------------
            -- seasonal values --
            ---------------------
            l_interval_origin := nvl(
               p_interval_origin,
               to_date('01JAN1900 0000', 'ddmonyyyy hh24mi'));
            if p_calendar_interval is null then
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
                      p_time_interval,
                      l_interval_origin,
                      p_interval_in_local_tz,
                      p_interpolate,
                      null,
                      p_level_comment);
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
                      p_calendar_interval,
                      null,
                      l_interval_origin,
                      p_interval_in_local_tz,
                      p_interpolate,
                      null,
                      p_level_comment);
            end if;
            for i in 1..p_seasonal_values.count loop
               insert
                 into at_seasonal_location_level
               values(l_location_level_code,
                      p_seasonal_values(i).offset_months,
                      p_seasonal_values(i).offset_minutes,
                      p_seasonal_values(i).value);
            end loop;
         end if;
   end;
end create_location_level;

END cwms_level;
/

show errors;
create or replace package body cwms_gage as

--------------------------------------------------------------------------------
-- function get_gage_code
--------------------------------------------------------------------------------
function get_gage_code(
   p_office_id   in varchar2,
   p_location_id in varchar2,
   p_gage_id     in varchar2)
   return number
is
   l_location_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_office_id,
      p_location_id,
      p_gage_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   
   l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   ---------------------------------------------------
   -- use cursor for loop construct for convenience --
   ---------------------------------------------------
   for rec in
      (  select gage_code
           from at_gage
          where gage_location_code = l_location_code
            and upper(gage_id) = trim(upper(p_gage_id))
      )
   loop
      return rec.gage_code;
   end loop;
   -------------------------------------
   -- exited the loop without a match --
   -------------------------------------
   cwms_err.raise(
      'ITEM_DOES_NOT_EXIST',
      'Gage id for '
      ||nvl(upper(p_office_id), cwms_util.user_office_id)
      ||'/'
      ||p_location_id,
      p_gage_id);      
end get_gage_code;   

--------------------------------------------------------------------------------
-- procedure store_gage
--------------------------------------------------------------------------------
procedure store_gage(
   p_location_id     in varchar2,
   p_gage_id         in varchar2,
   p_fail_if_exists  in varchar2,
   p_ignore_nulls    in varchar2,
   p_gage_type       in varchar2 default null,
   p_assoc_loc_id    in varchar2 default null,
   p_discontinued    in varchar2 default 'F',
   p_out_of_service  in varchar2 default 'F',
   p_manufacturer    in varchar2 default null,
   p_model_number    in varchar2 default null,
   p_serial_number   in varchar2 default null,
   p_phone_number    in varchar2 default null,
   p_internet_addr   in varchar2 default null,
   p_other_access_id in varchar2 default null,
   p_office_id       in varchar2 default null)
is
   item_does_not_exist exception; 
   l_fail_if_exists    boolean;
   l_ignore_nulls      boolean;
   l_exists            boolean;
   l_rec               at_gage%rowtype;
   pragma exception_init (item_does_not_exist, -20034);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_gage_type,
      p_fail_if_exists,
      p_ignore_nulls,
      p_assoc_loc_id,
      p_discontinued,
      p_out_of_service,
      p_manufacturer,
      p_model_number,
      p_serial_number,
      p_phone_number,
      p_internet_addr,
      p_other_access_id,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.is_true(p_ignore_nulls);
   ------------------------------------------                                                                          
   -- determine if the gage already exists --
   ------------------------------------------                                                                          
   begin
      l_rec.gage_code := get_gage_code(p_office_id, p_location_id, p_gage_id);
      l_exists := true;
      if p_gage_type is null and not l_ignore_nulls then
         cwms_err.raise(
            'ERROR',
            'Cannot set gage type to null');
      end if;
   exception
      when item_does_not_exist then
         l_exists := false;
         if p_gage_type is null then
            cwms_err.raise(
               'ERROR',
               'Gage type must not be null for new gage record');
         end if;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'CWMS gage',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_location_id
         ||'/'
         ||p_gage_id);
   end if;
   -------------------------
   -- populate the record --
   -------------------------
   if not l_exists then
      l_rec.gage_code := cwms_seq.nextval;
   end if;
   if p_gage_type is not null then
      select gage_type_code
        into l_rec.gage_type_code
        from cwms_gage_type
       where upper(gage_type_id) = upper(trim(p_gage_type)); 
   end if;
   if not l_exists then
      l_rec.gage_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   end if;
   if not l_exists then
      l_rec.gage_id := trim(p_gage_id);
   end if;
   if p_discontinued is not null or not l_ignore_nulls then
      l_rec.discontinued := upper(trim(p_discontinued));
   end if;
   if p_out_of_service is not null or not l_ignore_nulls then
      l_rec.out_of_service := upper(trim(p_out_of_service));
   end if;
   if p_manufacturer is not null or not l_ignore_nulls then
      l_rec.manufacturer := trim(p_manufacturer);
   end if;
   if p_model_number is not null or not l_ignore_nulls then
      l_rec.model_number := trim(p_model_number);
   end if;
   if p_serial_number is not null or not l_ignore_nulls then
      l_rec.serial_number := trim(p_serial_number);
   end if;
   if p_internet_addr is not null or not l_ignore_nulls then
      l_rec.internet_address := p_internet_addr;
   end if;
   if p_other_access_id is not null or not l_ignore_nulls then
      l_rec.other_access_id := p_other_access_id;
   end if;
   if p_assoc_loc_id is not null or not l_ignore_nulls then
      l_rec.associated_location_code := 
         case p_assoc_loc_id is null
            when true  then 
               null
            when false then 
               cwms_loc.get_location_code(
                  nvl(upper(p_office_id), cwms_util.user_office_id), 
                  p_assoc_loc_id)
         end;
   end if;
   ---------------------------------
   -- insert or update the record --
   ---------------------------------
   if l_rec.discontinued is null then
      l_rec.discontinued := 'F';
   end if;
   if l_rec.out_of_service is null then
      l_rec.out_of_service := 'F';
   end if;
   if l_exists then
      update at_gage
         set row = l_rec
       where gage_code = l_rec.gage_code;
   else
      insert
        into at_gage
      values l_rec;
   end if;   
   
end store_gage;   

--------------------------------------------------------------------------------
-- procedure retrieve_gage
--------------------------------------------------------------------------------
procedure retrieve_gage(
   p_gage_type       out varchar2,
   p_assoc_loc_id    out varchar2,
   p_discontinued    out varchar2,
   p_out_of_service  out varchar2,
   p_manufacturer    out varchar2,
   p_model_number    out varchar2,
   p_serial_number   out varchar2,
   p_phone_number    out varchar2,
   p_internet_addr   out varchar2,
   p_other_access_id out varchar2,
   p_location_id     in  varchar2,
   p_gage_id         in  varchar2,
   p_office_id       in  varchar2 default null)
is
   l_rec at_gage%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_office_id,
      p_location_id,
      p_gage_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   -------------------------
   -- retrieve the record --
   -------------------------
   select *
     into l_rec
     from at_gage
    where gage_code = get_gage_code(p_office_id, p_location_id, p_gage_id);
   --------------------------------    
   -- populate the out variables --
   --------------------------------  
   select gage_type_id
     into p_gage_type
     from cwms_gage_type
    where gage_type_code = l_rec.gage_type_code;

   if l_rec.associated_location_code is not null then
      select bl.base_location_id
             ||substr('-', 1, pl.sub_location_id)
             ||pl.sub_location_id
        into p_assoc_loc_id
        from at_physical_location pl,
             at_base_location bl
       where pl.location_code = l_rec.associated_location_code
         and bl.base_location_code = pl.base_location_code;
   end if;
   p_discontinued    := l_rec.discontinued;
   p_out_of_service  := l_rec.out_of_service;
   p_manufacturer    := l_rec.manufacturer;
   p_model_number    := l_rec.model_number;
   p_serial_number   := l_rec.serial_number;
   p_phone_number    := l_rec.phone_number;
   p_internet_addr   := l_rec.internet_address;
   p_other_access_id := l_rec.other_access_id;      
end retrieve_gage;

--------------------------------------------------------------------------------
-- procedure delete_gage
--------------------------------------------------------------------------------
procedure delete_gage(
   p_location_id   in varchar2,
   p_gage_id       in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_gage_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_office_id,
      p_location_id,
      p_gage_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   if upper(p_delete_action) not in
      (  cwms_util.delete_key,
         cwms_util.delete_data,
         cwms_util.delete_all
      )
   then
      cwms_err.raise(
         'INVALID_ITEM',
         nvl(p_delete_action, '<NULL>'),
         'CWMS delete action, must be one of '''
         ||cwms_util.delete_key
         ||''', '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
   end if;
   -----------------------
   -- locate the record --
   -----------------------
   l_gage_code := get_gage_code(p_office_id, p_location_id, p_gage_id);
   --------------------------------   
   -- delete the specified items --
   --------------------------------   
   if upper(p_delete_action) in (cwms_util.delete_data, cwms_util.delete_all) then
      delete from at_goes        where gage_code = l_gage_code;
      delete from at_gage_sensor where gage_code = l_gage_code;
   end if;
   if upper(p_delete_action) in (cwms_util.delete_key, cwms_util.delete_all) then
      delete from at_gage where gage_code = l_gage_code;
   end if;
      
end delete_gage;   

--------------------------------------------------------------------------------
-- procedure rename_gage
--------------------------------------------------------------------------------
procedure rename_gage(
   p_location_id   in varchar2,
   p_old_gage_id   in varchar2,
   p_new_gage_id   in varchar2,
   p_office_id     in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_office_id,
      p_location_id,
      p_old_gage_id,
      p_new_gage_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_old_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Existing gage identifier must not be null.');      
   end if;
   if p_new_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'New gage identifier must not be null.');      
   end if;
   -----------------------
   -- update the record --
   -----------------------
   update at_gage
      set gage_id = trim(p_new_gage_id)
    where gage_code = get_gage_code(p_office_id, p_location_id, p_old_gage_id);
    
end rename_gage;   
   
--------------------------------------------------------------------------------
-- procedure cat_gages
--------------------------------------------------------------------------------
procedure cat_gages(
   p_gage_catalog           out sys_refcursor,
   p_location_id_mask       in  varchar2 default '*',
   p_gage_id_mask           in  varchar2 default '*',
   p_gage_type_mask         in  varchar2 default '*',
   p_discontinued_mask      in  varchar2 default '*',
   p_out_of_service_mask    in  varchar2 default '*',
   p_manufacturer_mask      in  varchar2 default '*',
   p_model_number_mask      in  varchar2 default '*',
   p_serial_number_mask     in  varchar2 default '*',
   p_phone_number_mask      in  varchar2 default '*',
   p_internet_addr_mask     in  varchar2 default '*',
   p_other_access_id_mask   in  varchar2 default '*',
   p_assoc_location_id_mask in  varchar2 default '*',
   p_comments_mask          in  varchar2 default '*',
   p_office_id_mask         in  varchar2 default null)
is
   l_location_id_mask       varchar2(49);
   l_gage_id_mask           varchar2(32);
   l_gage_type_mask         varchar2(32);
   l_discontinued_mask      varchar2(1);
   l_out_of_service_mask    varchar2(1);
   l_manufacturer_mask      varchar2(32);
   l_model_number_mask      varchar2(32);
   l_serial_number_mask     varchar2(32);
   l_phone_number_mask      varchar2(16);
   l_internet_addr_mask     varchar2(32);
   l_other_access_id_mask   varchar2(32);
   l_assoc_location_id_mask varchar2(49);
   l_comments_mask          varchar2(256);
   l_office_id_mask         varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id_mask,
      p_gage_id_mask,
      p_gage_type_mask,
      p_discontinued_mask,
      p_out_of_service_mask,
      p_manufacturer_mask,
      p_model_number_mask,
      p_serial_number_mask,
      p_phone_number_mask,
      p_internet_addr_mask,
      p_other_access_id_mask,
      p_assoc_location_id_mask,
      p_comments_mask,
      p_office_id_mask));
   ----------------------      
   -- set up the masks --
   ----------------------      
   l_location_id_mask       := cwms_util.normalize_wildcards(upper(p_location_id_mask));
   l_gage_id_mask           := cwms_util.normalize_wildcards(upper(p_gage_id_mask));
   l_gage_type_mask         := cwms_util.normalize_wildcards(upper(p_gage_type_mask));
   l_discontinued_mask      := cwms_util.normalize_wildcards(upper(p_discontinued_mask));
   l_out_of_service_mask    := cwms_util.normalize_wildcards(upper(p_out_of_service_mask));
   l_manufacturer_mask      := cwms_util.normalize_wildcards(upper(p_manufacturer_mask));
   l_model_number_mask      := cwms_util.normalize_wildcards(upper(p_model_number_mask));
   l_serial_number_mask     := cwms_util.normalize_wildcards(upper(p_serial_number_mask));
   l_phone_number_mask      := cwms_util.normalize_wildcards(upper(p_phone_number_mask));
   l_internet_addr_mask     := cwms_util.normalize_wildcards(upper(p_internet_addr_mask));
   l_other_access_id_mask   := cwms_util.normalize_wildcards(upper(p_other_access_id_mask));
   l_assoc_location_id_mask := cwms_util.normalize_wildcards(upper(p_assoc_location_id_mask));
   l_comments_mask          := cwms_util.normalize_wildcards(upper(p_comments_mask));
   l_office_id_mask         := nvl(cwms_util.normalize_wildcards(upper(p_office_id_mask)), cwms_util.user_office_id);
   -----------------------
   -- perform the query --
   -----------------------
   open p_gage_catalog for
      select gage.office_id,
             gage.location_id,
             gage.gage_id,
             gage.gage_type,
             gage.discontinued,
             gage.out_of_service, 
             gage.manufacturer,
             gage.model_number,
             gage.serial_number,
             gage.phone_number,
             gage.internet_address,
             gage.other_access_id,
             loc.location_id as associated_location_id,
             gage.comments
        from ( select o.office_id,
                      bl.base_location_code
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as location_id,
                      g.gage_id,
                      gt.gage_type_id as gage_type,
                      g.discontinued,
                      g.out_of_service,
                      g.manufacturer,
                      g.model_number,
                      g.serial_number,
                      g.phone_number,
                      g.internet_address,
                      g.other_access_id,
                      g.associated_location_code,
                      g.comments
                 from at_gage g,
                      at_physical_location pl,
                      at_base_location bl,
                      cwms_office o,
                      cwms_gage_type gt
                where o.office_id like l_office_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and upper(bl.base_location_code
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_location_id_mask escape '\'
                  and g.gage_location_code = pl.location_code
                  and upper(g.gage_id) like l_gage_id_mask escape '\'
                  and upper(g.discontinued) like l_discontinued_mask escape '\'
                  and upper(g.out_of_service) like l_out_of_service_mask escape '\'  
                  and upper(g.manufacturer) like l_manufacturer_mask escape '\'
                  and upper(g.model_number) like l_model_number_mask escape '\'
                  and upper(g.serial_number) like l_serial_number_mask escape '\'
                      -- * matches null phone number, use *? or ?* to match only non-nulls
                  and ( upper(g.phone_number) like l_phone_number_mask escape '\' 
                        or 
                        (g.phone_number is null and l_phone_number_mask = '%')
                      )
                      -- * matches null internet address, use *? or ?* to match only non-nulls
                  and ( upper(g.internet_address) like l_internet_addr_mask escape '\'
                        or
                        (g.internet_address is null and l_internet_addr_mask = '%')
                      )
                      -- * matches null other access id, use *? or ?* to match only non-nulls
                  and ( upper(g.other_access_id) like l_other_access_id_mask escape '\'
                        or
                        (g.other_access_id is null and l_other_access_id_mask = '%')
                      )
                      -- * matches null comments, use *? or ?* to match only non-nulls
                  and ( upper(g.comments) like l_comments_mask escape '\'
                        or
                        (g.comments is null and l_comments_mask = '%')
                      )
                  and gt.gage_type_code = g.gage_type_code 
             ) gage                              
             left outer join
             ( select pl.location_code,
                      bl.base_location_code
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as location_id
                 from at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where o.office_id like l_office_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and upper(bl.base_location_code
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_assoc_location_id_mask escape '\'
             ) loc 
             on loc.location_code = gage.associated_location_code
             -- * matches null associated location id, use *? or ?* to match only non-nulls
       where ( loc.location_id like l_assoc_location_id_mask escape '\'
               or
               (gage.associated_location_code is null and l_assoc_location_id_mask = '%')
             )
    order by office_id,
             location_id,
             gage_id;  
end cat_gages;   
   
--------------------------------------------------------------------------------
-- function cat_gages_f
--------------------------------------------------------------------------------
function cat_gages_f(
   p_location_id_mask       in varchar2 default '*',
   p_gage_id_mask           in varchar2 default '*',
   p_gage_type_mask         in varchar2 default '*',
   p_discontinued_mask      in varchar2 default '*',
   p_out_of_service_mask    in varchar2 default '*',
   p_manufacturer_mask      in varchar2 default '*',
   p_model_number_mask      in varchar2 default '*',
   p_serial_number_mask     in varchar2 default '*',
   p_phone_number_mask      in varchar2 default '*',
   p_internet_addr_mask     in varchar2 default '*',
   p_other_access_id_mask   in varchar2 default '*',
   p_assoc_location_id_mask in varchar2 default '*',
   p_comments_mask          in varchar2 default '*',
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_gages(
      l_cursor,
      p_location_id_mask,
      p_gage_id_mask,
      p_gage_type_mask,
      p_discontinued_mask,
      p_out_of_service_mask,
      p_manufacturer_mask,
      p_model_number_mask,
      p_serial_number_mask,
      p_phone_number_mask,
      p_internet_addr_mask,
      p_other_access_id_mask,
      p_assoc_location_id_mask,
      p_comments_mask,
      p_office_id_mask);
      
   return l_cursor;      
end cat_gages_f;   

--------------------------------------------------------------------------------
-- procedure store_gage_sensor
--------------------------------------------------------------------------------
procedure store_gage_sensor(
   p_location_id      in varchar2,
   p_gage_id          in varchar2,
   p_sensor_id        in varchar2,
   p_fail_if_exists   in varchar2,
   p_ignore_nulls     in varchar2,
   p_parameter_id     in varchar2,
   p_report_unit_id   in varchar2 default null,
   p_valid_range_min  in binary_double default null,
   p_valid_range_max  in binary_double default null,
   p_zero_reading_val in binary_double default null,
   p_values_unit      in varchar2 default null,
   p_out_of_service   in varchar2 default 'F',
   p_manufacturer     in varchar2 default null,
   p_model_number     in varchar2 default null,
   p_serial_number    in varchar2 default null,
   p_comments         in varchar2 default null,
   p_office_id        in varchar2 default null)
is
   l_rec at_gage_sensor%rowtype;
   l_fail_if_exists  boolean;
   l_ignore_nulls    boolean;
   l_exists          boolean;
   l_param_unit_code number(10);
   l_value_unit_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_sensor_id,
      p_fail_if_exists,
      p_ignore_nulls,
      p_parameter_id,
      p_report_unit_id,
      p_out_of_service,
      p_values_unit,
      p_comments,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   if p_sensor_id is null then
      cwms_err.raise(
         'ERROR',
         'Sensor identifier must not be null.');      
   end if;
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.is_true(p_ignore_nulls);
   ------------------------------
   -- see if the record exists --
   ------------------------------
   l_rec.gage_code := get_gage_code(p_office_id, p_location_id, p_gage_id);
   l_rec.sensor_id := trim(p_sensor_id);
   begin
      select *
        into l_rec
        from at_gage_sensor
       where gage_code = l_rec.gage_code
         and upper(sensor_id) = upper(l_rec.sensor_id);
      l_exists := true;       
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXITS',
         'CWMS gage sensor',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_location_id
         ||'/'
         ||p_gage_id
         ||'/'
         ||p_sensor_id);
   end if;
   ----------------------------   
   -- populate the parameter --
   ----------------------------
   if p_parameter_id is null then
      if not l_exists then
         cwms_err.raise(
            'ERROR',
            'Parameter must not be null on new sensor record');
      end if;
   else
      select parameter_code
        into l_rec.parameter_code
        from cwms_v_parameter
       where parameter_id = p_parameter_id
         and db_office_id in (nvl(upper(p_office_id), cwms_util.user_office_id), 'CWMS');
   end if;      
   -------------------------------------
   -- get the unit codes to work with --
   -------------------------------------
   select bp.unit_code
     into l_param_unit_code
     from at_parameter p,
          cwms_base_parameter bp
    where p.parameter_code = l_rec.parameter_code
      and bp.base_parameter_code = p.base_parameter_code;
   
   select unit_code
     into l_value_unit_code
     from cwms_unit
    where unit_id = cwms_util.get_unit_id(p_values_unit, p_office_id);
   ------------------------------------------       
   -- populate the remainder of the record --
   ------------------------------------------
   if p_report_unit_id is null then
      if not l_ignore_nulls then
         l_rec.unit_code := null;
      end if;
   else
      select unit_code
        into l_rec.unit_code
        from cwms_unit
       where unit_id = cwms_util.get_unit_id(p_report_unit_id, p_office_id);      
   end if;
   if p_valid_range_min is not null or not l_ignore_nulls then
      l_rec.valid_range_min := cwms_util.convert_units(p_valid_range_min, l_value_unit_code, l_param_unit_code);
   end if;       
   if p_valid_range_max is not null or not l_ignore_nulls then
      l_rec.valid_range_max := cwms_util.convert_units(p_valid_range_max, l_value_unit_code, l_param_unit_code);
   end if;       
   if p_zero_reading_val is not null or not l_ignore_nulls then
      l_rec.zero_reading_value := cwms_util.convert_units(p_zero_reading_val, l_value_unit_code, l_param_unit_code);
   end if; 
   if p_out_of_service is null then
      if not l_exists then
         cwms_err.raise(
            'ERROR',
            'Out of service flag must not be null on new sensor record');
      end if;
   else
      l_rec.out_of_service := p_out_of_service;      
   end if;      
   if p_manufacturer is not null or not l_ignore_nulls then
      l_rec.manufacturer := trim(p_manufacturer);
   end if;
   if p_model_number is not null or not l_ignore_nulls then
      l_rec.model_number := trim(p_model_number);
   end if;
   if p_serial_number is not null or not l_ignore_nulls then
      l_rec.serial_number := trim(p_serial_number);
   end if;
   if p_comments is not null or not l_ignore_nulls then
      l_rec.comments := p_comments;
   end if; 
   ---------------------------------
   -- insert or update the record --
   ---------------------------------
   if l_exists then
      update at_gage_sensor
         set row = l_rec
       where gage_code = l_rec.gage_code
         and sensor_id = l_rec.sensor_id;
   else
      insert
        into at_gage_sensor
      values l_rec;
   end if;
      
end store_gage_sensor;   

--------------------------------------------------------------------------------
-- procedure retrieve_gage_sensor
--------------------------------------------------------------------------------
procedure retrieve_gage_sensor(
   p_parameter_id     out varchar2,
   p_report_unit_id   out varchar2,
   p_valid_range_min  out binary_double,
   p_valid_range_max  out binary_double,
   p_zero_reading_val out binary_double,
   p_out_of_service   out varchar2,
   p_manufacturer     out varchar2,
   p_model_number     out varchar2,
   p_serial_number    out varchar2,
   p_comments         out varchar2,
   p_location_id      in  varchar2,
   p_gage_id          in  varchar2,
   p_sensor_id        in  varchar2,
   p_values_unit      in  varchar2 default null,
   p_office_id        in  varchar2 default null)
is
   l_rec             at_gage_sensor%rowtype;
   l_param_unit_code number(10);
   l_value_unit_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_sensor_id,
      p_values_unit,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   if p_sensor_id is null then
      cwms_err.raise(
         'ERROR',
         'Sensor identifier must not be null.');      
   end if;
   -------------------------
   -- retrieve the record --
   -------------------------
   select *
     into l_rec
     from at_gage_sensor
    where gage_code = get_gage_code(p_office_id, p_location_id, p_gage_id)
      and upper(sensor_id) = upper(p_sensor_id);
   -------------------------------------
   -- get the unit codes to work with --
   -------------------------------------
   select bp.unit_code
     into l_param_unit_code
     from at_parameter p,
          cwms_base_parameter bp
    where p.parameter_code = l_rec.parameter_code
      and bp.base_parameter_code = p.base_parameter_code;

   if p_values_unit is null then
      l_value_unit_code := l_param_unit_code;
   else   
      select unit_code
        into l_value_unit_code
        from cwms_unit
       where unit_id = cwms_util.get_unit_id(p_values_unit, p_office_id);
   end if;
   ---------------------------------      
   -- populate the out parameters --
   ---------------------------------
   p_parameter_id := cwms_util.get_parameter_id(l_rec.parameter_code);
   if l_rec.unit_code is not null then
      select unit_id
        into p_report_unit_id
        from cwms_unit
       where unit_code = l_rec.unit_code;
   end if;
   p_valid_range_min  := cwms_util.convert_units(l_rec.valid_range_min, l_param_unit_code, l_value_unit_code);
   p_valid_range_max  := cwms_util.convert_units(l_rec.valid_range_max, l_param_unit_code, l_value_unit_code);
   p_zero_reading_val := cwms_util.convert_units(l_rec.zero_reading_value, l_param_unit_code, l_value_unit_code);
   p_out_of_service   := l_rec.out_of_service;
   p_manufacturer     := l_rec.manufacturer;
   p_model_number     := l_rec.model_number;
   p_serial_number    := l_rec.serial_number;
   p_comments         := l_rec.comments;      
exception
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'CWMS gage sensor',
         nvl(upper(p_office_id), cwms_util.user_office_id)
         ||'/'
         ||p_location_id
         ||'/'
         ||p_gage_id
         ||'/'
         ||p_sensor_id);
               
end retrieve_gage_sensor;   

--------------------------------------------------------------------------------
-- procedure delete_gage_sensor
--------------------------------------------------------------------------------
procedure delete_gage_sensor(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_sensor_id   in varchar2,
   p_office_id   in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_sensor_id,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   if p_sensor_id is null then
      cwms_err.raise(
         'ERROR',
         'Sensor identifier must not be null.');      
   end if;
   -----------------------
   -- delete the record --
   -----------------------
   begin
      delete
        from at_gage_sensor
       where gage_code = get_gage_code(p_office_id, p_location_id, p_gage_id)
         and upper(sensor_id) = upper(p_sensor_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS gage sensor',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_gage_id
            ||'/'
            ||p_sensor_id);
   end;   
end delete_gage_sensor;   

--------------------------------------------------------------------------------
-- procedure rename_gage_sensor
--------------------------------------------------------------------------------
procedure rename_gage_sensor(
   p_location_id   in varchar2,
   p_gage_id       in varchar2,
   p_old_sensor_id in varchar2,
   p_new_sensor_id in varchar2,
   p_office_id     in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_old_sensor_id,
      p_new_sensor_id,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise(
         'ERROR',
         'Location identifier must not be null.');      
   end if;
   if p_gage_id is null then
      cwms_err.raise(
         'ERROR',
         'Gage identifier must not be null.');      
   end if;
   if p_old_sensor_id is null then
      cwms_err.raise(
         'ERROR',
         'Existing sensor identifier must not be null.');
   end if;      
   if p_new_sensor_id is null then
      cwms_err.raise(
         'ERROR',
         'New sensor identifier must not be null.');      
   end if;
   -----------------------
   -- update the record --
   -----------------------
   begin
      update at_gage_sensor
         set sensor_id = p_new_sensor_id
       where gage_code = get_gage_code(p_office_id, p_location_id, p_gage_id)
         and upper(sensor_id) = upper(p_old_sensor_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS gage sensor',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_gage_id
            ||'/'
            ||p_old_sensor_id);
   end;   
end rename_gage_sensor;      

--------------------------------------------------------------------------------
-- procedure cat_gage_sensors
--------------------------------------------------------------------------------
procedure cat_gage_sensors(
   p_sensor_catalog         out sys_refcursor,
   p_location_id_mask       in  varchar2 default '*',
   p_gage_id_mask           in  varchar2 default '*',
   p_sensor_id_mask         in  varchar2 default '*',
   p_parameter_id_mask      in  varchar2 default '*',
   p_reporting_unit_id_mask in  varchar2 default '*',
   p_out_of_service_mask    in  varchar2 default '*',
   p_manufacturer_mask      in  varchar2 default '*',
   p_model_number_mask      in  varchar2 default '*',
   p_serial_number_mask     in  varchar2 default '*',
   p_comments_mask          in  varchar2 default '*',
   p_unit_system            in  varchar2 default 'SI',
   p_office_id_mask      in  varchar2 default null)
is
   l_location_id_mask       varchar2(49);
   l_gage_id_mask           varchar2(32);
   l_sensor_id_mask         varchar2(32);
   l_parameter_id_mask      varchar2(49);
   l_reporting_unit_id_mask varchar2(16);
   l_out_of_service_mask    varchar2(1);
   l_manufacturer_mask      varchar2(32);
   l_model_number_mask      varchar2(32);
   l_serial_number_mask     varchar2(32);
   l_comments_mask          varchar2(256);
   l_office_id_mask         varchar2(16);
   l_unit_system            varchar2(2);
begin
   -------------------   
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(   
      p_location_id_mask,
      p_gage_id_mask,
      p_sensor_id_mask,
      p_parameter_id_mask,
      p_reporting_unit_id_mask,
      p_out_of_service_mask,
      p_manufacturer_mask,
      p_model_number_mask,
      p_serial_number_mask,
      p_comments_mask,
      p_unit_system,
      p_office_id_mask));
   if p_unit_system not in ('EN', 'SI') then
      cwms_err.raise(
         'INVALID_ITEM',
         nvl(p_unit_system, '<NULL>'),
         'CWMS unit system, use either SI or EN');
   end if;      
   ----------------------      
   -- set up the masks --
   ----------------------      
   l_location_id_mask       := cwms_util.normalize_wildcards(upper(p_location_id_mask));
   l_gage_id_mask           := cwms_util.normalize_wildcards(upper(p_gage_id_mask));
   l_sensor_id_mask         := cwms_util.normalize_wildcards(upper(p_sensor_id_mask));
   l_parameter_id_mask      := cwms_util.normalize_wildcards(upper(p_parameter_id_mask));
   l_reporting_unit_id_mask := cwms_util.normalize_wildcards(upper(p_reporting_unit_id_mask));
   l_out_of_service_mask    := cwms_util.normalize_wildcards(upper(p_out_of_service_mask));
   l_manufacturer_mask      := cwms_util.normalize_wildcards(upper(p_manufacturer_mask));
   l_model_number_mask      := cwms_util.normalize_wildcards(upper(p_model_number_mask));
   l_serial_number_mask     := cwms_util.normalize_wildcards(upper(p_serial_number_mask));
   l_comments_mask          := cwms_util.normalize_wildcards(upper(p_comments_mask));
   l_office_id_mask         := cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.user_office_id)));
   -----------------------
   -- perform the query --
   -----------------------
   open p_sensor_catalog for
      select sensor.office_id,
             sensor.location_id,
             sensor.gage_id,
             sensor.sensor_id,
             sensor.parameter_id,
             unit.unit_id as report_unit_id,
             sensor.valid_range_min,
             sensor.valid_range_max,
             sensor.zero_reading_value,
             sensor.value_units,
             sensor.out_of_service,
             sensor.manufacturer,
             sensor.model_number,
             sensor.serial_number,
             sensor.comments
        from ( select o.office_id,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as location_id,
                      g.gage_id,
                      gs.sensor_id,
                      cwms_util.get_parameter_id(gs.parameter_code) as parameter_id,
                      gs.unit_code,
                      cwms_util.convert_units(
                         gs.valid_range_min,
                         cwms_util.get_db_unit_code(gs.parameter_code),
                         cwms_util.get_default_units(cwms_util.get_parameter_id(gs.parameter_code), p_unit_system)) as valid_range_min,
                      cwms_util.convert_units(
                         gs.valid_range_max,
                         cwms_util.get_db_unit_code(gs.parameter_code),
                         cwms_util.get_default_units(cwms_util.get_parameter_id(gs.parameter_code), p_unit_system)) as valid_range_max,
                      cwms_util.convert_units(
                         gs.zero_reading_value,
                         cwms_util.get_db_unit_code(gs.parameter_code),
                         cwms_util.get_default_units(cwms_util.get_parameter_id(gs.parameter_code), p_unit_system)) as zero_reading_value,
                      cwms_util.get_default_units(cwms_util.get_parameter_id(gs.parameter_code), p_unit_system) as value_units,
                      gs.out_of_service,
                      gs.manufacturer,
                      gs.model_number,
                      gs.serial_number,
                      gs.comments
                 from at_gage_sensor gs,
                      at_gage g,
                      at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where o.office_id like l_office_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and upper(bl.base_location_code
                            ||substr('-', 1, length(pl.sub_location_id))
                            ||pl.sub_location_id) like l_location_id_mask escape '\'
                  and g.gage_location_code = pl.location_code
                  and upper(g.gage_id) like l_gage_id_mask escape '\'
                  and gs.gage_code = g.gage_code
                  and upper(gs.sensor_id) like l_sensor_id_mask escape '\'
                  and gs.out_of_service like l_out_of_service_mask escape '\'
                  and upper(gs.manufacturer) like l_manufacturer_mask escape '\'
                  and upper(gs.model_number) like l_model_number_mask escape '\'
                  and upper(gs.serial_number) like l_serial_number_mask escape '\'
                  -- * matches null comments, use *? or ?* to match only non-nulls
                  and ( upper(gs.comments) like l_comments_mask escape '\'
                        or
                        (gs.comments is null and l_comments_mask = '%')
                      )
             ) sensor
             
             left outer join
             ( select unit_code,
                      unit_id
                 from cwms_unit
             ) unit
             on unit.unit_code = sensor.unit_code  
             
       where sensor.parameter_id like l_parameter_id_mask escape '\' 
         -- * matches null unit id, use *? or ?* to match only non-nulls
         and ( unit.unit_id like l_reporting_unit_id_mask escape '\'
               or
               (sensor.unit_code is null and l_reporting_unit_id_mask = '%')
             )        
    order by sensor.office_id,
             sensor.location_id,
             sensor.gage_id,
             sensor.sensor_id;                                               
   
end cat_gage_sensors;
--------------------------------------------------------------------------------
-- function cat_gage_sensors_f
--------------------------------------------------------------------------------
function cat_gage_sensors_f(
   p_location_id_mask       in varchar2 default '*',
   p_gage_id_mask           in varchar2 default '*',
   p_sensor_id_mask         in varchar2 default '*',
   p_parameter_id_mask      in varchar2 default '*',
   p_reporting_unit_id_mask in varchar2 default '*',
   p_out_of_service_mask    in varchar2 default '*',
   p_manufacturer_mask      in varchar2 default '*',
   p_model_number_mask      in varchar2 default '*',
   p_serial_number_mask     in varchar2 default '*',
   p_comments_mask          in varchar2 default '*',
   p_unit_system            in varchar2 default 'SI',
   p_office_id_mask      in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_gage_sensors(
      l_cursor,
      p_gage_id_mask,
      p_sensor_id_mask,
      p_parameter_id_mask,
      p_reporting_unit_id_mask,
      p_out_of_service_mask,
      p_manufacturer_mask,
      p_model_number_mask,
      p_serial_number_mask,
      p_comments_mask,
      p_unit_system,
      p_office_id_mask);
      
   return l_cursor;      
end cat_gage_sensors_f;      

--------------------------------------------------------------------------------
-- procedure store_goes
--------------------------------------------------------------------------------
procedure store_goes(
   p_location_id        in varchar2,
   p_gage_id            in varchar2,
   p_fail_if_exists     in varchar2,
   p_ignore_nulls       in varchar2,
   p_goes_id            in varchar2 default null,
   p_goes_satellite     in varchar2 default null,
   p_selftimed_channel  in number   default null,
   p_selftimed_rate     in number   default null, -- bits/s
   p_selftimed_interval in number   default null, -- minutes
   p_selftimed_offset   in number   default null, -- minutes
   p_selftimed_length   in number   default null, -- seconds
   p_random_channel     in number   default null,
   p_random_rate        in number   default null, -- bits/s
   p_random_interval    in number   default null, -- minutes
   p_random_offset      in number   default null, -- minutes
   p_office_id          in varchar2 default null)
is
   item_does_not_exist exception; pragma exception_init(item_does_not_exist, -20034);
   item_already_exists exception; pragma exception_init(item_already_exists, -20020);
   l_rec            at_goes%rowtype;
   l_fail_if_exists boolean;
   l_ignore_nulls   boolean;
   l_exists         boolean;
   l_group_id       varchar2(32)  := upper(p_gage_id);
   l_group_desc     varchar2(128) := goes_group_desc_prefix || l_group_id;
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_goes_id,
      p_fail_if_exists,
      p_ignore_nulls,
      p_goes_satellite,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise('ERROR', 'Location identifier must not be null.');
   end if;      
   if p_gage_id is null then
      cwms_err.raise('ERROR', 'Gage identifier must not be null.');
   end if;      
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.is_true(p_ignore_nulls);
   ------------------------------
   -- see if the record exists --
   ------------------------------
   l_rec.gage_code := get_gage_code(p_office_id, p_location_id, p_gage_id);
   begin
      select *
        into l_rec
        from at_goes
       where gage_code = l_rec.gage_code;
       l_exists := true;
   exception
      when others then
         l_exists := false;
   end;
   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'GOES record for CWMS gage',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_gage_id);
      end if;      
   else
      if p_goes_id is null then
         cwms_err.raise('ERROR', 'GOES identifier must not be null on new record');
      end if;
   end if;
   ---------------------------------------------------------
   -- create the location alias group if it doesn't exist --
   ---------------------------------------------------------
   begin
      cwms_loc.create_loc_category(
         goes_category_id, 
         goes_category_desc, 
         p_office_id);
   exception 
      when item_already_exists then null;
   end;    
   begin
      cwms_loc.create_loc_group(
         goes_category_id, 
         l_group_id,
         l_group_desc, 
         p_office_id);
   exception 
      when item_already_exists then null;
   end;    
   -------------------------------------
   -- set the GOES alias for the gage --
   -------------------------------------
   cwms_loc.assign_loc_group(
      goes_category_id, 
      l_group_id, 
      p_location_id, 
      p_goes_id, 
      p_office_id);
   -------------------------
   -- populate the record --
   ------------------------- 
   if p_goes_satellite is not null or not l_ignore_nulls then
      l_rec.goes_satellite := upper(p_goes_satellite);
   end if;
   if p_selftimed_channel is not null or not l_ignore_nulls then
      l_rec.selftimed_channel := p_selftimed_channel;
   end if;      
   if p_selftimed_rate is not null or not l_ignore_nulls then
      l_rec.selftimed_data_rate := p_selftimed_rate;
   end if;      
   if p_selftimed_interval is not null or not l_ignore_nulls then
      l_rec.selftimed_interval := numtodsinterval(p_selftimed_interval, 'minute');
   end if;      
   if p_selftimed_offset is not null or not l_ignore_nulls then
      l_rec.selftimed_offset := numtodsinterval(p_selftimed_offset, 'minute');
   end if;      
   if p_selftimed_length is not null or not l_ignore_nulls then
      l_rec.selftimed_length := numtodsinterval(p_selftimed_length, 'second');
   end if;      
   if p_random_channel is not null or not l_ignore_nulls then
      l_rec.random_channel := p_random_channel;
   end if;      
   if p_random_rate is not null or not l_ignore_nulls then
      l_rec.random_data_rate := p_random_rate;
   end if;      
   if p_random_interval is not null or not l_ignore_nulls then
      l_rec.random_interval := numtodsinterval(p_random_interval, 'minute');
   end if;      
   if p_random_offset is not null or not l_ignore_nulls then
      l_rec.random_offset := numtodsinterval(p_random_offset, 'minute');
   end if;      
   ---------------------------------      
   -- insert or update the record --
   ---------------------------------
   if l_exists then
      update at_goes
         set row = l_rec
       where gage_code = l_rec.gage_code;
   else
      insert
        into at_goes
      values l_rec;
   end if;      

end store_goes;   

--------------------------------------------------------------------------------
-- procedure retrieve_goes
--------------------------------------------------------------------------------
procedure retrieve_goes(
   p_goes_id            out varchar2,
   p_goes_satellite     out varchar2,
   p_selftimed_channel  out number,
   p_selftimed_rate     out number, -- bits/s
   p_selftimed_interval out number, -- minutes
   p_selftimed_offset   out number, -- minutes
   p_selftimed_length   out number, -- seconds
   p_random_channel     out number,
   p_random_rate        out number, -- bits/s
   p_random_interval    out number, -- minutes
   p_random_offset      out number, -- minutes
   p_location_id        in  varchar2,
   p_gage_id            in  varchar2,
   p_office_id          in  varchar2 default null)
is
   l_rec at_goes%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise('ERROR', 'Location identifier must not be null.');
   end if;      
   if p_gage_id is null then
      cwms_err.raise('ERROR', 'Gage identifier must not be null.');
   end if;
   -------------------------
   -- retrieve the record --
   -------------------------      
   l_rec.gage_code := get_gage_code(p_office_id, p_location_id, p_gage_id);
   begin
      select *
        into l_rec
        from at_goes
       where gage_code = l_rec.gage_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'GOES record for CWMS gage',
            nvl(upper(p_office_id), cwms_util.user_office_id)
            ||'/'
            ||p_location_id
            ||'/'
            ||p_gage_id);
   end;
   --------------------------------
   -- populate the out variables --
   --------------------------------
   select alias_id
     into p_goes_id
     from cwms_v_loc_grp_assgn
    where db_office_id = nvl(upper(p_office_id), cwms_util.user_office_id)
      and category_id = goes_category_id
      and group_id = upper(p_gage_id)
      and upper(location_id) = upper(p_location_id); 
      
   p_goes_satellite     := l_rec.goes_satellite;
   p_selftimed_channel  := l_rec.selftimed_channel;
   p_selftimed_rate     := l_rec.selftimed_data_rate;
   p_selftimed_interval := extract(day    from l_rec.selftimed_interval) * 1440 +        
                           extract(hour   from l_rec.selftimed_interval) * 60 +
                           extract(minute from l_rec.selftimed_interval); 
   p_selftimed_offset   := extract(day    from l_rec.selftimed_offset) * 1440 +        
                           extract(hour   from l_rec.selftimed_offset) * 60 +
                           extract(minute from l_rec.selftimed_offset); 
   p_selftimed_length   := extract(day    from l_rec.selftimed_length) * 86400 +        
                           extract(hour   from l_rec.selftimed_length) * 3600 +
                           extract(minute from l_rec.selftimed_length) * 60 +
                           extract(second from l_rec.selftimed_length);
   p_random_channel     := l_rec.random_channel;
   p_random_rate        := l_rec.random_data_rate;
   p_random_interval    := extract(day    from l_rec.random_interval) * 1440 +        
                           extract(hour   from l_rec.random_interval) * 60 +
                           extract(minute from l_rec.random_interval); 
   p_random_offset      := extract(day    from l_rec.random_offset) * 1440 +        
                           extract(hour   from l_rec.random_offset) * 60 +
                           extract(minute from l_rec.random_offset); 
end retrieve_goes;   

--------------------------------------------------------------------------------
-- procedure delete_goes
--------------------------------------------------------------------------------
procedure delete_goes(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_office_id   in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise('ERROR', 'Location identifier must not be null.');
   end if;      
   if p_gage_id is null then
      cwms_err.raise('ERROR', 'Gage identifier must not be null.');
   end if;
   ----------------------------------------
   -- delete the GOES alias for the gage --
   ----------------------------------------
   cwms_loc.unassign_loc_group(
      goes_category_id, 
      upper(p_gage_id), 
      p_location_id, 
      'F', 
      p_office_id);
   -----------------------
   -- delete the record --
   -----------------------
   delete 
     from at_goes 
    where gage_code = get_gage_code(p_office_id, p_location_id, p_gage_id);
end delete_goes;   

--------------------------------------------------------------------------------
-- procedure rename_goes
--------------------------------------------------------------------------------
procedure rename_goes(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_new_goes_id in varchar2,
   p_office_id   in varchar2 default null)
is
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id,
      p_gage_id,
      p_new_goes_id,
      p_office_id));
   if p_location_id is null then
      cwms_err.raise('ERROR', 'Location identifier must not be null.');
   end if;      
   if p_gage_id is null then
      cwms_err.raise('ERROR', 'Gage identifier must not be null.');
   end if;
   if p_new_goes_id is null then
      cwms_err.raise('ERROR', 'GOES identifier must not be null.');
   end if;
   ----------------------------------------
   -- delete the GOES alias for the gage --
   ----------------------------------------
   cwms_loc.unassign_loc_group(
      goes_category_id, 
      upper(p_gage_id), 
      p_location_id, 
      'F', 
      p_office_id);
   -------------------------------------
   -- set the GOES alias for the gage --
   -------------------------------------
   cwms_loc.assign_loc_group(
      goes_category_id, 
      upper(p_gage_id), 
      p_location_id, 
      p_new_goes_id, 
      p_office_id);
end rename_goes;   

--------------------------------------------------------------------------------
-- procedure cat_goes
--------------------------------------------------------------------------------
procedure cat_goes(
   p_goes_catalog          out sys_refcursor,
   p_location_id_mask      in  varchar2 default '*',
   p_gage_id_mask          in  varchar2 default '*',
   p_goes_id_mask          in  varchar2 default '*',
   p_satellite_mask        in  varchar2 default '*',
   p_min_selftimed_channel in  number default 0,
   p_max_selftimed_channel in  number default 999999,
   p_min_random_channel    in  number default 0,
   p_max_random_channel    in  number default 999999,
   p_office_id_mask        in  varchar2 default null)
is
   l_location_id_mask varchar2(49);
   l_gage_id_mask     varchar2(32);
   l_goes_id_mask     varchar2(32);
   l_satellite_mask   varchar2(1);
   l_office_id_mask   varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   cwms_util.check_inputs(str_tab_t(
      p_location_id_mask,
      p_gage_id_mask,
      p_goes_id_mask,
      p_satellite_mask, 
      p_office_id_mask));
   ----------------------
   -- set up the masks --
   ----------------------
   l_location_id_mask := cwms_util.normalize_wildcards(upper(p_location_id_mask));
   l_gage_id_mask     := cwms_util.normalize_wildcards(upper(p_gage_id_mask));
   l_goes_id_mask     := cwms_util.normalize_wildcards(upper(p_goes_id_mask));
   l_satellite_mask   := cwms_util.normalize_wildcards(upper(p_satellite_mask));
   l_office_id_mask   := cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.user_office_id)));
   ----------------------
   -- peform the query --
   ----------------------
   open p_goes_catalog for
      select o.office_id,
             bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id as location_id,
             gage.gage_id,
             v.alias_id as goes_id,
             goes.goes_satellite,
             goes.selftimed_channel,
             goes.selftimed_data_rate as selftimed_rate,
             extract(day    from goes.selftimed_interval) * 1440 +        
             extract(hour   from goes.selftimed_interval) * 60 +
             extract(minute from goes.selftimed_interval) as selftimed_interval,  
             extract(day    from goes.selftimed_offset) * 1440 +        
             extract(hour   from goes.selftimed_offset) * 60 +
             extract(minute from goes.selftimed_offset) as selftimed_offset,  
             extract(day    from goes.selftimed_length) * 86400 +        
             extract(hour   from goes.selftimed_length) * 3600 +
             extract(minute from goes.selftimed_length) * 60 +  
             extract(second from goes.selftimed_length) as selftimed_length,  
             goes.random_channel,
             goes.random_data_rate as random_rate,
             extract(day    from goes.random_interval) * 1440 +        
             extract(hour   from goes.random_interval) * 60 +
             extract(minute from goes.random_interval) as random_interval,  
             extract(day    from goes.random_offset) * 1440 +        
             extract(hour   from goes.random_offset) * 60 +
             extract(minute from goes.random_offset) as random_offset
        from at_goes goes,
             at_gage gage,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o,
             cwms_v_loc_grp_assgn v
       where o.office_id like l_office_id_mask escape '\'
         and bl.db_office_code = o.office_code
         and pl.base_location_code = bl.base_location_code
         and upper(bl.base_location_code
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id) like l_location_id_mask escape '\'
         and gage.gage_location_code = pl.location_code
         and upper(gage.gage_id) like l_gage_id_mask escape '\'
         and goes.gage_code = gage.gage_code
         and goes.goes_satellite like l_satellite_mask escape '\'
         and goes.selftimed_channel between p_min_selftimed_channel and p_max_selftimed_channel    
         and goes.random_channel between p_min_random_channel and p_max_random_channel
         and v.category_id = goes_category_id
         and v.group_id = upper(gage.gage_id)
         and v.db_office_id = o.office_id
         and v.base_location_id = bl.base_location_id
         and nvl(v.sub_location_id, '.') = nvl(pl.sub_location_id, '.')
         and v.alias_id like l_goes_id_mask escape '\';    
             
end cat_goes;      

--------------------------------------------------------------------------------
-- function cat_goes_f
--------------------------------------------------------------------------------
function cat_goes_f(
   p_location_id_mask      in varchar2 default '*',
   p_gage_id_mask          in varchar2 default '*',
   p_goes_id_mask          in varchar2 default '*',
   p_satellite_mask        in varchar2 default '*',
   p_min_selftimed_channel in number default 0,
   p_max_selftimed_channel in number default 999999,
   p_min_random_channel    in number default 0,
   p_max_random_channel    in number default 999999,
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_goes(
      l_cursor,
      p_location_id_mask,
      p_gage_id_mask,
      p_goes_id_mask,
      p_satellite_mask,
      p_min_selftimed_channel,
      p_max_selftimed_channel,
      p_min_random_channel,
      p_max_random_channel,
      p_office_id_mask);

   return l_cursor;
end cat_goes_f;      
   
end cwms_gage;
/
show errors;
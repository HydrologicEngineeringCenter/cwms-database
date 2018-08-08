create or replace package body cwms_basin as
--------------------------------------------------------------------------------
-- function get_basin_code
--------------------------------------------------------------------------------
function get_basin_code(
   p_office_id in varchar2,
   p_basin_id  in varchar2)
   return number
is
   l_basin_code number(10);
   l_office_id  varchar2(16);
begin
   if p_basin_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_BASIN_ID');
   end if;
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   begin
      l_basin_code := cwms_loc.get_location_code(l_office_id, p_basin_id);
      select basin_location_code
        into l_basin_code
        from at_basin
       where basin_location_code = l_basin_code;
   exception
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS basin identifier.',
            l_office_id
            ||'/'
            ||p_basin_id);
   end;
   return l_basin_code;   
end get_basin_code;   
   
--------------------------------------------------------------------------------
-- procedure store_basin
--------------------------------------------------------------------------------
procedure store_basin(
   p_basin_id                   in varchar2,
   p_fail_if_exists             in varchar2,
   p_ignore_nulls               in varchar2,
   p_parent_basin_id            in varchar2 default null,
   p_sort_order                 in binary_double default null,
   p_primary_stream_id          in varchar2 default null,
   p_total_drainage_area        in binary_double default null,
   p_contributing_drainage_area in binary_double default null,
   p_area_unit                  in varchar2 default null,
   p_office_id                  in varchar2 default null)
is
   l_office_id        varchar2(16);
   l_location_kind_id varchar2(32);
   l_fail_if_exists   boolean;
   l_ignore_nulls     boolean;
   l_exists           boolean;
   l_rec              at_basin%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_basin_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_BASIN_ID');
   end if;
   if p_area_unit is null then
      if coalesce(p_total_drainage_area, p_contributing_drainage_area) is not null then
         cwms_err.raise(
            'ERROR',
            'Area unit must be specified if areas are specified');
      end if;
   end if;
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls   := cwms_util.is_true(p_ignore_nulls);
   l_rec.basin_location_code := cwms_loc.get_location_code(l_office_id, p_basin_id);
   if not cwms_loc.can_store(l_rec.basin_location_code, 'BASIN') then
      cwms_err.raise(
         'ERROR', 
         'Cannot store BASIN information to location '
         ||l_office_id||'/'||p_basin_id
         ||' (location kind = '
         ||cwms_loc.check_location_kind(l_rec.basin_location_code)
         ||')');
   end if;
   begin
      select *
        into l_rec
        from at_basin
       where basin_location_code = l_rec.basin_location_code;
      l_exists := true;       
   exception
      when no_data_found then
         l_exists := false;
   end;
   if l_exists and l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'CWMS basin',
            l_office_id
            ||'/'
            ||p_basin_id);
   end if;
   -------------------------
   -- populate the record --
   -------------------------
   if p_parent_basin_id is not null or not l_ignore_nulls then
      if p_parent_basin_id is null then
         l_rec.parent_basin_code := null;
      else
         l_rec.parent_basin_code := get_basin_code(l_office_id, p_parent_basin_id);
      end if;
   end if;      
   if p_primary_stream_id is not null or not l_ignore_nulls then
      if p_primary_stream_id is null then
         l_rec.primary_stream_code := null;
      else
         l_rec.primary_stream_code := cwms_stream.get_stream_code(l_office_id, p_primary_stream_id);
      end if;
   end if;      
   if p_sort_order is not null or not l_ignore_nulls then
      l_rec.sort_order := p_sort_order;
   end if;
   if p_total_drainage_area is not null or not l_ignore_nulls then
      l_rec.total_drainage_area := cwms_util.convert_units(
         p_total_drainage_area, 
         cwms_util.get_unit_id(p_area_unit), 
         'm2');
   end if;
   if p_contributing_drainage_area is not null or not l_ignore_nulls then
      l_rec.contributing_drainage_area := cwms_util.convert_units(
         p_contributing_drainage_area, 
         cwms_util.get_unit_id(p_area_unit), 
         'm2');
   end if;
   ---------------------------------   
   -- update or insert the record --
   ---------------------------------
   if l_exists then
      update at_basin
         set row = l_rec
       where basin_location_code = l_rec.basin_location_code;
   else
      insert
        into at_basin
      values l_rec;
   end if;
   ---------------------------      
   -- set the location kind --
   ---------------------------
   cwms_loc.update_location_kind(l_rec.basin_location_code, 'BASIN', 'A');
end store_basin;   
      
--------------------------------------------------------------------------------
-- procedure retrieve_basin
--------------------------------------------------------------------------------
procedure retrieve_basin(
   p_parent_basin_id            out varchar2,
   p_sort_order                 out binary_double,
   p_primary_stream_id          out varchar2,
   p_total_drainage_area        out binary_double,
   p_contributing_drainage_area out binary_double,
   p_basin_id                   in  varchar2,
   p_area_unit                  in  varchar2,
   p_office_id                  in  varchar2 default null)
is
   l_rec at_basin%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_basin_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS basin identifier');
   end if;
   if p_area_unit is null then
      cwms_err.raise(
         'ERROR',
         'Area unit must not be null.');
   end if;
   --------------------
   -- get the record --
   --------------------
   select *
     into l_rec
     from at_basin
    where basin_location_code = get_basin_code(p_office_id, p_basin_id);
   -------------------------    
   -- populate the output --
   -------------------------
   if l_rec.parent_basin_code is not null then
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id
        into p_parent_basin_id
        from at_physical_location pl,
             at_base_location bl
       where pl.location_code = l_rec.parent_basin_code
         and bl.base_location_code = pl.base_location_code;
   end if;
   p_sort_order := l_rec.sort_order;
   if l_rec.primary_stream_code is not null then
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id
        into p_primary_stream_id
        from at_physical_location pl,
             at_base_location bl
       where pl.location_code = l_rec.primary_stream_code
         and bl.base_location_code = pl.base_location_code;
   end if;
   p_total_drainage_area := cwms_util.convert_units(
      l_rec.total_drainage_area,
      'm2',
      cwms_util.get_unit_id(p_area_unit));
   p_contributing_drainage_area := cwms_util.convert_units(
      l_rec.contributing_drainage_area,
      'm2',
      cwms_util.get_unit_id(p_area_unit));
end retrieve_basin;   
      
--------------------------------------------------------------------------------
-- procedure delete_basin
--------------------------------------------------------------------------------
procedure delete_basin(
   p_basin_id      in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
begin
   delete_basin2(
      p_basin_id      => p_basin_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_office_id);
end delete_basin;
--------------------------------------------------------------------------------
-- procedure delete_basin2
--------------------------------------------------------------------------------
procedure delete_basin2(
   p_basin_id               in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null)
is
   l_basin_code       number(10);
   l_delete_location  boolean;
   l_delete_action1   varchar2(16);
   l_delete_action2   varchar2(16);
   l_location_kind_id cwms_location_kind.location_kind_id%type;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_basin_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_BASIN_ID');
   end if;
   l_delete_action1 := upper(substr(p_delete_action, 1, 16));
   if l_delete_action1 not in (
      cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
   then
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
   end if;
   l_delete_location := cwms_util.return_true_or_false(p_delete_location);
   if l_delete_location then
      l_delete_action2 := upper(substr(p_delete_location_action, 1, 16));
      if l_delete_action2 not in (
         cwms_util.delete_key,
         cwms_util.delete_data,
         cwms_util.delete_all)
      then
         cwms_err.raise(
            'ERROR',
            'Delete action must be one of '''
            ||cwms_util.delete_key
            ||''',  '''
            ||cwms_util.delete_data
            ||''', or '''
            ||cwms_util.delete_all
            ||'');
      end if;
   end if;
   l_basin_code := get_basin_code(p_office_id, p_basin_id);
   l_location_kind_id := cwms_loc.check_location_kind(l_basin_code);
   if l_location_kind_id != 'BASIN' then
      cwms_err.raise(
         'ERROR',
         'Cannot delete basin information from location'
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_basin_id
         ||' (location kind = '
         ||l_location_kind_id
         ||')');
   end if;
   l_location_kind_id := cwms_loc.can_revert_loc_kind_to(p_basin_id, p_office_id); -- revert-to kind
   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
   if l_delete_action1 in (cwms_util.delete_data, cwms_util.delete_all) then
      for rec in
         (  select bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id as basin_id
              from at_physical_location pl,
                   at_base_location bl
             where pl.location_code in 
                   ( select basin_location_code
                       from at_basin
                      where parent_basin_code = l_basin_code
                   )
               and bl.base_location_code = pl.base_location_code
         )
      loop
         delete_basin(rec.basin_id, cwms_util.delete_all, p_office_id);
      end loop;
   end if;
   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
   if l_delete_action1 in (cwms_util.delete_key, cwms_util.delete_all) then
      delete from at_basin where basin_location_code = l_basin_code;
      cwms_loc.update_location_kind(l_basin_code, 'BASIN', 'D');
   end if; 
   -------------------------------------
   -- delete the location if required --
   -------------------------------------
   if l_delete_location then
      cwms_loc.delete_location(p_basin_id, l_delete_action2, p_office_id);
   end if;
end delete_basin2;   
      
--------------------------------------------------------------------------------
-- procedure rename_basin
--------------------------------------------------------------------------------
procedure rename_basin(
   p_old_basin_id in varchar2,
   p_new_basin_id in varchar2,
   p_office_id    in varchar2 default null)
is
   l_basin_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_old_basin_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS basin identifier');
   end if;
   if p_new_basin_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS basin identifier');
   end if;
   l_basin_code := get_basin_code(p_office_id, p_old_basin_id);
   -------------------------------
   -- rename the basin location --
   -------------------------------
   cwms_loc.rename_location(p_old_basin_id, p_new_basin_id, p_office_id);
end rename_basin;   

--------------------------------------------------------------------------------
-- procedure cat_basins
--
-- the catalog contains the following fields, sorted by the first 4
--
--    office_id                  varchar2(16)
--    basin_id                   varchar2(49)
--    parent_basin_id            varchar2(49)
--    sort_order                 binary_double
--    primary_stream_id          varchar2(49)
--    total_drainage_area        binary_double
--    contributing_drainage_area binary_double
--    area_unit                  varchar2(16)
--
--------------------------------------------------------------------------------
procedure cat_basins(
   p_basins_catalog         out sys_refcursor,
   p_basin_id_mask          in  varchar2 default '*',
   p_parent_basin_id_mask   in  varchar2 default '*',
   p_primary_stream_id_mask in  varchar2 default '*',
   p_area_unit              in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null)
is
   l_basin_id_mask          varchar2(49);
   l_parent_basin_id_mask   varchar2(49);
   l_primary_stream_id_mask varchar2(49);
   l_office_id_mask         varchar2(16);
   l_area_unit              varchar2(16);
begin
   ------------------
   -- sanity check --
   ------------------
   l_basin_id_mask          := cwms_util.normalize_wildcards(upper(p_basin_id_mask));
   l_parent_basin_id_mask   := cwms_util.normalize_wildcards(upper(p_parent_basin_id_mask));
   l_primary_stream_id_mask := cwms_util.normalize_wildcards(upper(p_primary_stream_id_mask));
   l_office_id_mask         := cwms_util.normalize_wildcards(
                                  nvl(upper(p_office_id_mask), cwms_util.user_office_id));
   l_area_unit := cwms_util.get_unit_id(nvl(p_area_unit, 'm2'));
      
   open p_basins_catalog for
      select basin.office_id,
             basin.basin_id,
             parent_basin.basin_id as parent_basin_id,
             basin.sort_order,
             primary_stream.stream_id as primary_stream_id,
             basin.total_drainage_area,
             basin.contributing_drainage_area,
             l_area_unit as area_unit
        from ( select o.office_id,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as basin_id,
                      sort_order,
                      cwms_util.convert_units(
                         total_drainage_area, 
                         'm2', 
                         l_area_unit) as total_drainage_area,                                  
                      cwms_util.convert_units(
                         contributing_drainage_area, 
                         'm2', 
                         l_area_unit) as contributing_drainage_area,
                      b.parent_basin_code,
                      b.primary_stream_code
                 from at_basin b,
                      at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where pl.location_code = b.basin_location_code
                  and bl.base_location_code = pl.base_location_code
                  and o.office_code = bl.db_office_code
                  and o.office_id like l_office_id_mask escape '\'
                  and upper(bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_basin_id_mask escape '\'
             ) basin

             left outer join
             ( select pl.location_code,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as basin_id
                 from at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where o.office_id like l_office_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and upper(bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_parent_basin_id_mask 
             ) parent_basin
             on parent_basin.location_code = basin.parent_basin_code

             left outer join
             ( select pl.location_code,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as stream_id
                 from at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where o.office_id like l_office_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and upper(bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_primary_stream_id_mask
             ) primary_stream 
             on primary_stream.location_code = basin.primary_stream_code
             
       where ( parent_basin.basin_id like l_parent_basin_id_mask escape '\'
               or 
               (basin.parent_basin_code is null and l_parent_basin_id_mask = '%')
             )
         and ( primary_stream.stream_id like l_primary_stream_id_mask escape '\'
               or 
               (basin.primary_stream_code is null and l_primary_stream_id_mask = '%')
             )
    order by basin.office_id,
             basin.basin_id,
             parent_basin.basin_id,
             basin.sort_order nulls first;                                                        
end cat_basins;   

--------------------------------------------------------------------------------
-- function cat_basins_f
--
-- the catalog contains the following fields, sorted by the first 4
--
--    office_id                  varchar2(16)
--    basin_id                   varchar2(49)
--    parent_basin_id            varchar2(49)
--    sort_order                 binary_double
--    primary_stream_id          varchar2(49)
--    total_drainage_area        binary_double
--    contributing_drainage_area binary_double
--    area_unit                  varchar2(16)
--
--------------------------------------------------------------------------------
function cat_basins_f(
   p_basin_id_mask          in varchar2 default '*',
   p_parent_basin_id_mask   in varchar2 default '*',
   p_primary_stream_id_mask in varchar2 default '*',
   p_area_unit              in varchar2 default null,
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_basins(
      l_cursor,
      p_basin_id_mask,
      p_parent_basin_id_mask,
      p_primary_stream_id_mask,
      p_area_unit,
      p_office_id_mask);
      
   return l_cursor;      
end cat_basins_f;   

--------------------------------------------------------------------------------
-- procedure get_runoff_volume
--------------------------------------------------------------------------------
procedure get_runoff_volume(
   p_runoff_volume       out binary_double,
   p_basin_id            in  varchar2,
   p_precip_excess_depth in  binary_double,
   p_precip_unit         in  varchar2,
   p_volume_unit         in  varchar2,
   p_office_id           in  varchar2 default null)
is
   l_contributing_area binary_double;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_basin_id is null then
      cwms_err.raise(
         'INVALID_ITEM',
         '<NULL>',
         'CWMS basin identifier');
   end if;
   if p_precip_unit is null then
      cwms_err.raise(
         'ERROR',
         'Precipitation unit must not be null.');
   end if;
   if p_volume_unit is null then
      cwms_err.raise(
         'ERROR',
         'Volume unit must not be null.');
   end if;
   select contributing_drainage_area
     into l_contributing_area
     from at_basin
    where basin_location_code = get_basin_code(p_office_id, p_basin_id);
   p_runoff_volume := cwms_util.convert_units(
      l_contributing_area * cwms_util.convert_units(
         p_precip_excess_depth, 
         cwms_util.get_unit_id(p_precip_unit), 
         'm'),
      'm3',
      cwms_util.get_unit_id(p_volume_unit));
end get_runoff_volume;   

--------------------------------------------------------------------------------
-- function get_runoff_volume_f
--------------------------------------------------------------------------------
function get_runoff_volume_f(
   p_basin_id            in varchar2,
   p_precip_excess_depth in binary_double,
   p_precip_unit         in varchar2,
   p_volume_unit         in varchar2,
   p_office_id           in varchar2 default null)
   return binary_double
is
   l_runoff_volume binary_double;
begin
   get_runoff_volume(
      l_runoff_volume,
      p_basin_id,
      p_precip_excess_depth,
      p_precip_unit,
      p_volume_unit,
      p_office_id);   

   return l_runoff_volume;
end get_runoff_volume_f;
            
end cwms_basin;
/
show errors;
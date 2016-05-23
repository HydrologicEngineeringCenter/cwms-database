create or replace package body cwms_overflow
as
--------------------------------------------------------------------------------
-- PROCEDURE STORE_OVERFLOW
procedure store_overflow(
   p_location_id        in varchar2,
   p_fail_if_exists     in varchar2,
   p_ignore_nulls       in varchar2,
   p_crest_elev         in binary_double default null,
   p_elev_unit          in varchar2      default null,
   p_length_or_diameter in binary_double default null,
   p_length_unit        in varchar2      default null,
   p_is_circular        in varchar2      default null,
   p_rating_spec_id     in varchar2      default null,
   p_description        in varchar2      default null,
   p_office_id          in varchar2      default null)
is
   location_id_not_found exception;
   pragma exception_init(location_id_not_found, -20025);
   l_rec                at_overflow%rowtype;
   l_parts              str_tab_t;
   l_base_location_code integer;
   l_location_code      integer;
   l_rating_spec_code   integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'   ); end if;
   begin
      l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   exception
      when location_id_not_found then null;
   end;   
   if p_fail_if_exists is null then cwms_err.raise('NULL_ARGUMENT', 'P_Fail_If_Exists'); end if;
   if p_ignore_nulls   is null then cwms_err.raise('NULL_ARGUMENT', 'P_Ignore_Nulls'  ); end if;
   if p_fail_if_exists not in ('T','F') then cwms_err.raise('ERROR', 'Argument P_Fail_If_Exists must be ''T'' or ''F'''); end if;
   if p_ignore_nulls   not in ('T','F') then cwms_err.raise('ERROR', 'Argument P_Ignore_Nulls   must be ''T'' or ''F'''); end if;
   if p_crest_elev is not null and p_elev_unit is null then
      cwms_err.raise('ERROR', 'Arugment P_Elev_Unit must not be NULL when argument P_Crest_Elev is specified');
   end if;
   if p_length_or_diameter is not null and p_length_unit is null then
      cwms_err.raise('ERROR', 'Arugment P_Length_Unit must not be NULL when argument P_Length_Or_Diameter is specified');
   end if;
   if p_is_circular is not null and p_is_circular not in ('T', 'F') then
      cwms_err.raise('ERROR', 'Arugment P_Is_Circular must be NULL, ''T'', or ''F''');
   end if;
   -------------------------------------
   -- create the location if ncessary --
   -------------------------------------
   l_parts := cwms_util.split_text(p_location_id, '-', 1);
   if l_location_code is null then
      if l_parts.count = 2 and 
         cwms_loc.check_location_kind(cwms_loc.get_location_code(p_office_id, l_parts(1))) = 'PROJECT'
      then
         -------------------------
         -- create the location --
         -------------------------
         cwms_loc.create_location_raw (
            p_base_location_code => l_base_location_code,
            p_location_code      => l_location_code,
            p_base_location_id   => l_parts(1),
            p_sub_location_id    => l_parts(2),
            p_db_office_code     => cwms_util.get_db_office_code(p_office_id));
      else
         ------------------
         -- can't create --
         ------------------
         cwms_err.raise(
            'ERROR',
            'Overflow location '
            ||cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||p_location_id
            ||' does not exist and cannot be created by this procedure');
      end if;
   end if;
   ------------------------------
   -- get the rating spec code --
   ------------------------------
   if p_rating_spec_id is not null then
      l_parts := cwms_util.split_text(p_rating_spec_id, '.');
      if l_parts.count != 4 then
         cwms_err.raise('INVALID_ITEM', p_rating_spec_id, 'CWMS Rating Specification');
      end if;
      if upper(l_parts(1)) not in (upper(p_location_id), upper(cwms_util.get_base_id(p_location_id))) then
         cwms_err.raise(
            'ERROR',
            'Argument P_Rating_Spec_Id specifies a location other than argument P_Location_Id');
      end if;
      begin
         select rs.rating_spec_code
           into l_rating_spec_code
           from at_rating_spec rs,
                at_rating_template rt
          where rs.location_code = cwms_loc.get_location_code(p_office_id, l_parts(1))
            and rt.template_code = rs.template_code
            and upper(rt.parameters_id) = upper(l_parts(2))
            and upper(rt.version) = upper(l_parts(3))
            and upper(rs.version) = upper(l_parts(4));
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Rating specification',
               cwms_util.get_db_office_id(p_office_id)
               ||'/'
               ||p_rating_spec_id);
      end;
   end if;
   -------------------------
   -- check for existence --
   -------------------------
   begin
      select *
        into l_rec
        from at_overflow
       where overflow_location_code = l_location_code;
       
      if p_fail_if_exists = 'T' then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Overflow',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||p_location_id);
      end if;
   exception
      when no_data_found then null;
   end;
   -----------------------------------------
   -- check for appropriate location kind --
   -----------------------------------------
   if not cwms_loc.can_store(l_location_code, 'OVERFLOW') then
      ---------------------------------------------------------------------------
      -- can't move directly to OVERFLOW kind, try moving to OUTLET kind first --
      ---------------------------------------------------------------------------
      if l_parts.count = 2 and 
         cwms_loc.check_location_kind(cwms_loc.get_location_code(p_office_id, l_parts(1))) = 'PROJECT'
      then
         cwms_outlet.store_outlet(
            project_structure_obj_t(
               location_ref_t(l_parts(1), p_office_id),
               location_obj_t(location_ref_t(p_location_id, p_office_id)),
               null));
      end if;
   end if;
   if not cwms_loc.can_store(l_location_code, 'OVERFLOW') then
      cwms_err.raise(
         'ERROR',
         'Cannot store overflow information to location '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_location_id
         ||' (location kind = '
         ||cwms_loc.check_location_kind(l_location_code)
         ||')');
   end if;   
   -------------------------
   -- populate the record --
   -------------------------
   if p_crest_elev is not null or p_ignore_nulls = 'F' then
      l_rec.crest_elevation := cwms_util.convert_units(p_crest_elev, p_elev_unit, 'm');
   end if;
   if p_length_or_diameter is not null or p_ignore_nulls = 'F' then
      l_rec.length_or_diameter := cwms_util.convert_units(p_length_or_diameter, p_length_unit, 'm');
   end if;
   if p_is_circular is not null or p_ignore_nulls = 'F' then
      l_rec.is_circular := p_is_circular;
   end if;
   if p_rating_spec_id is not null or p_ignore_nulls = 'F' then
      l_rec.rating_spec_code := l_rating_spec_code;
   end if;
   if p_description is not null or p_ignore_nulls = 'F' then
      l_rec.description := p_description;
   end if;
   ---------------------------------
   -- insert or update the record --
   ---------------------------------
   if l_rec.overflow_location_code is null then
      l_rec.overflow_location_code := l_location_code;
      insert into at_overflow values l_rec;
      cwms_loc.update_location_kind(l_location_code, 'OVERFLOW', 'A');
   else
      update at_overflow set row = l_rec where overflow_location_code = l_location_code;
   end if;
end store_overflow;   
--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_OVERFLOW
procedure retrieve_overflow(   
   p_crest_elev         out binary_double,
   p_length_or_diameter out binary_double,
   p_is_circular        out varchar2,
   p_rating_spec_id     out varchar2,
   p_description        out varchar2,
   p_location_id        in  varchar2,
   p_elev_unit          in  varchar2 default null,
   p_length_unit        in  varchar2 default null,
   p_office_id          in  varchar2 default null)
is
   l_rec at_overflow%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'); end if;
   -----------------
   -- do the work --
   -----------------
   select *
     into l_rec
     from at_overflow
    where overflow_location_code = cwms_loc.get_location_code(p_office_id, p_location_id);

   p_crest_elev         := cwms_util.convert_units(l_rec.crest_elevation, 'm', nvl(p_elev_unit, 'm'));
   p_length_or_diameter := cwms_util.convert_units(l_rec.length_or_diameter, 'm', nvl(p_length_unit, 'm'));
   p_is_circular        := l_rec.is_circular;
   p_description        := l_rec.description;
   if l_rec.rating_spec_code is not null then
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id
             ||'.'
             ||rt.parameters_id
             ||'.'
             ||rt.version
             ||'.'
             ||rs.version
        into p_rating_spec_id
        from at_rating_spec rs,
             at_rating_template rt,
             at_physical_location pl,
             at_base_location bl
       where rs.rating_spec_code = l_rec.rating_spec_code
         and rt.template_code = rs.template_code
         and pl.location_code = rs.location_code
         and bl.base_location_code = pl.base_location_code;
   end if;
end retrieve_overflow;   
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_OVERFLOW
procedure delete_overflow(   
   p_location_id   in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_location_code integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'); end if;
   if p_delete_action not in (cwms_util.delete_key, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'Arugment P_Delete_Action must be '''
         ||cwms_util.delete_key
         ||''' or '''
         ||cwms_util.delete_all
         ||'''');         
   end if;
   -----------------
   -- do the work --
   -----------------
   l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   if p_delete_action = cwms_util.delete_key then
      delete from at_overflow where overflow_location_code = l_location_code;
      cwms_loc.update_location_kind(l_location_code, 'OVERFLOW', 'D');
   else
      cwms_loc.delete_location(p_location_id, p_delete_action, p_office_id);
   end if;
end delete_overflow;
--------------------------------------------------------------------------------
-- PROCEDURE RENAME_OVERFLOW
procedure rename_overflow(
   p_old_location_id in varchar2,
   p_new_location_id in varchar2,
   p_office_id       in varchar2 default null)
is
begin
   cwms_loc.rename_location(p_old_location_id, p_new_location_id, p_office_id);
end rename_overflow;   
   
end cwms_overflow;
/
show errors
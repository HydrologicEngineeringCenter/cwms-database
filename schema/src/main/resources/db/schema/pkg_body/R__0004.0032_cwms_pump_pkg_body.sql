create or replace package body cwms_pump
as
--------------------------------------------------------------------------------
-- PROCEDURE STORE_PUMP
procedure store_pump(
   p_location_id    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_description    in varchar2 default null,
   p_office_id      in varchar2 default null)
is
   l_location_code integer;
   l_rec           at_pump%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'); end if;
   if p_fail_if_exists not in ('T','F') then cwms_err.raise('ERROR', 'Argument P_Fail_If_Exists must be ''T'' or ''F'''); end if;
   if p_ignore_nulls   not in ('T','F') then cwms_err.raise('ERROR', 'Argument P_Ignore_Nulls must be ''T'' or ''F'''); end if;
   -----------------
   -- do the work --
   -----------------
   l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
   if not cwms_loc.can_store(l_location_code, 'PUMP') then
      cwms_err.raise(
         'ERROR',
         'Cannot store PUMP information for location '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_location_id
         ||' (location kind = '
         ||cwms_loc.check_location_kind(l_location_code)
         ||')');
   end if;
   begin
      select * into l_rec from at_pump where pump_location_code = l_location_code;
      if p_fail_if_exists = 'T' then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Pump location '
            ||cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||p_location_id);
      end if;
   exception
      when no_data_found then null;
   end;
   if p_description is not null or p_ignore_nulls = 'F' then
      l_rec.description := p_description;
   end if;
   if l_rec.pump_location_code is null then
      l_rec.pump_location_code := l_location_code;
      insert into at_pump values l_rec;
      cwms_loc.update_location_kind(l_location_code, 'PUMP', 'A');
   else
      update at_pump set row = l_rec where pump_location_code = l_location_code;
   end if;
end store_pump;
--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_PUMP
procedure retrieve_pump(
   p_description out varchar2,
   p_location_id in  varchar2,
   p_office_id   in  varchar2 default null)
is
   l_rec at_pump%rowtype;
begin
   if p_location_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'); end if;
   select * into l_rec from at_pump where pump_location_code = cwms_loc.get_location_code(p_office_id, p_location_id);
   p_description := l_rec.description;
end retrieve_pump;
--------------------------------------------------------------------------------
-- PROCEDURE RENAME_PUMP
procedure rename_pump(
   p_old_location_id in varchar2,
   p_new_location_id in varchar2,
   p_office_id       in varchar2 default null)
is
begin
   cwms_loc.rename_location(p_old_location_id, p_new_location_id, p_office_id);
end rename_pump;
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_PUMP
procedure delete_pump(
   p_location_id   in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_rec at_pump%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_location_id is null then cwms_err.raise('NULL_ARGUMENT', 'P_Location_Id'); end if;
   if p_delete_action not in (cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'Argument P_Delete_Action must be '''
         ||cwms_util.delete_key
         ||''', '''
         ||cwms_util.delete_data
         ||''' or '''
         ||cwms_util.delete_all
         ||'''');
   end if;
   select * into l_rec from at_pump where pump_location_code = cwms_loc.get_location_code(p_office_id, p_location_id);
   -----------------
   -- do the work --
   -----------------
   if p_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      delete from at_wat_usr_contract_accounting where pump_location_code = l_rec.pump_location_code;
      update at_water_user_contract set pump_out_location_code       = null where pump_out_location_code       = l_rec.pump_location_code;
      update at_water_user_contract set pump_out_below_location_code = null where pump_out_below_location_code = l_rec.pump_location_code;
      update at_water_user_contract set pump_in_location_code        = null where pump_in_location_code        = l_rec.pump_location_code;
   end if;
   if p_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      delete from at_pump where pump_location_code = l_rec.pump_location_code;
      update at_physical_location
         set location_kind = (select location_kind_code from cwms_location_kind where location_kind_id = 'STREAM_LOCATION')
       where location_code = l_rec.pump_location_code;
   end if;
end delete_pump;

end cwms_pump;
/

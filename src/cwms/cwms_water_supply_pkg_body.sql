whenever sqlerror exit sql.sqlcode
--------------------------------------------------------------------------------
-- package cwms_water_supply.
-- used to manipulate the tables at_water_user, at_water_user_contract,
-- at_wat_usr_contract_accounting, at_xref_wat_usr_contract_docs.
-- also manipulates at_document.
--------------------------------------------------------------------------------
create or replace
package body cwms_water_supply
as
--------------------------------------------------------------------------------
-- procedure cat_water_user
-- returns a catalog of water users.
--
-- security: can be called by user and dba group.
--
-- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
-- Changing them will end up breaking external code (so make any changes prior
-- to development).
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    project_office_id         varchar2(16)  the office id of the parent project.
--    project_id                varchar2(49)  the identification (id) of the parent project.
--    entity_name               varchar2
--    water_right               varchar2
--
--------------------------------------------------------------------------------
-- errors will be thrown as exceptions
--
-- p_cursor
--   described above
-- p_project_id_mask
--   a mask to limit the query to certain projects.
-- p_db_office_id_mask
--   defaults to the connected user's office if null
--   the office id can use sql masks for retrieval of additional offices.
procedure cat_water_user(
	p_cursor            out sys_refcursor,
	p_project_id_mask   in  varchar2 default null,
	p_db_office_id_mask in  varchar2 default null )
is
   l_office_id_mask  varchar2(16) := 
      cwms_util.normalize_wildcards(nvl(upper(p_db_office_id_mask), '%'), true);
   l_project_id_mask varchar2(49) := 
      cwms_util.normalize_wildcards(nvl(upper(p_project_id_mask), '%'), true);
begin
	cwms_util.check_inputs(str_tab_t(
		p_project_id_mask,
		p_db_office_id_mask));
   open p_cursor for
      select o.office_id as project_office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id as project_id,
             wu.entity_name, 
             wu.water_right
        from at_water_user wu,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id like l_office_id_mask escape '\'
         and bl.db_office_code = o.office_code
         and pl.base_location_code = bl.base_location_code
         and upper(bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id) like l_project_id_mask escape '\'
         and wu.project_location_code = pl.location_code;
end cat_water_user;
--------------------------------------------------------------------------------
-- procedure cat_water_user_contract
-- returns a catalog of water user contracts.
--
-- security: can be called by user and dba group.
--
-- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
-- Changing them will end up breaking external code (so make any changes prior
-- to development).
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    project_office_id         varchar2(16)  the office id of the parent project.
--    project_id                varchar2(49)  the identification (id) of the parent project.
--    entity_name               varchar2
--    contract_name             varchar2
--    contracted_storage        binary_double
--    contract_type             varchar2      the display value of the lookup.
--
--------------------------------------------------------------------------------
-- errors will be thrown as exceptions
--
-- p_cursor
--    described above
-- p_project_id_mask
--    a mask to limit the query to certain projects.
-- p_entity_name_mask
--    a mask to limit the query to certain entities.
-- p_db_office_id_mask
--    defaults to the connected user's office if null
--    the office id can use sql masks for retrieval of additional offices.
procedure cat_water_user_contract(
   p_cursor            out sys_refcursor,
   p_project_id_mask   in  varchar2 default null,
   p_entity_name_mask  in  varchar2 default null,
   p_db_office_id_mask in  varchar2 default null )
is
   l_office_id_mask  varchar2(16) := 
      cwms_util.normalize_wildcards(nvl(upper(p_db_office_id_mask), '%'), true);
   l_project_id_mask varchar2(49) := 
      cwms_util.normalize_wildcards(nvl(upper(p_project_id_mask), '%'), true);
   l_entity_name_mask varchar2(49) := 
      cwms_util.normalize_wildcards(nvl(upper(p_entity_name_mask), '%'), true);
begin
	cwms_util.check_inputs(str_tab_t(
		p_project_id_mask,
		p_entity_name_mask,
		p_db_office_id_mask));
   open p_cursor for
      select o.office_id as project_office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id as project_id,
             wu.entity_name,
             wuc.contract_name,
             wuc.contracted_storage,
             wct.ws_contract_type_display_value 
        from at_water_user wu,
             at_water_user_contract wuc,
             at_ws_contract_type wct,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id like l_office_id_mask escape '\'
         and bl.db_office_code = o.office_code
         and pl.base_location_code = bl.base_location_code
         and upper(bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id) like l_project_id_mask escape '\'
         and wu.project_location_code = pl.location_code
         and upper(wu.entity_name) like l_entity_name_mask escape '\'
         and wuc.water_user_code = wu.water_user_code
         and wct.ws_contract_type_code = wuc.water_supply_contract_type;
end cat_water_user_contract;
--------------------------------------------------------------------------------
-- Returns a set of water users for a given project. Returned data is encapsulated
-- in a table of water user oracle types.
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued as a thrown exception
--
-- p_water_users
--    returns a filled set of objects including location ref data
-- p_project_location_ref
--    a project location refs that identify the objects we want to retrieve.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
procedure retrieve_water_users(
	p_water_users          out water_user_tab_t,
	p_project_location_ref in  location_ref_t )
is
begin
   p_water_users := water_user_tab_t();
   for rec in (
      select entity_name,
             water_right
        from at_water_user
       where project_location_code = p_project_location_ref.get_location_code)
   loop
      p_water_users.extend;
      p_water_users(p_water_users.count) := water_user_obj_t(
         p_project_location_ref,
         rec.entity_name,
         rec.water_right);
   end loop;       
end retrieve_water_users;

procedure store_water_user(
   p_water_user     in water_user_obj_t,
   p_fail_if_exists in varchar2 default 'T' )
is
   l_rec           at_water_user%rowtype;
   l_proj_loc_code number := p_water_user.project_location_ref.get_location_code; 
begin
	cwms_util.check_input(p_fail_if_exists);
   begin
      select *
        into l_rec
        from at_water_user
       where project_location_code = l_proj_loc_code 
         and upper(entity_name) = upper(p_water_user.entity_name);
      if cwms_util.is_true(p_fail_if_exists) then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Water User',
            p_water_user.project_location_ref.get_office_id
            ||'/'
            || p_water_user.project_location_ref.get_location_id
            ||'/'
            || p_water_user.entity_name);
      end if;
      if l_rec.water_right != p_water_user.water_right then
         l_rec.water_right := p_water_user.water_right;
         update at_water_user
            set row = l_rec
          where water_user_code = l_rec.water_user_code; 			 
      end if;
   exception
      when no_data_found then
         l_rec.water_user_code := cwms_seq.nextval;
         l_rec.project_location_code := l_proj_loc_code;
         l_rec.entity_name := p_water_user.entity_name;
         l_rec.water_right := p_water_user.water_right;
      insert
        into at_water_user
      values l_rec;			 			 
   end;
	
end store_water_user;
--------------------------------------------------------------------------------
-- store a set of water users.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_water_user
-- p_fail_if_exists
--    a flag that will cause the procedure to fail if the object already exists
procedure store_water_users(
   p_water_users    in water_user_tab_t,
   p_fail_if_exists in varchar2 default 'T' )
is
begin
	cwms_util.check_input(p_fail_if_exists);
   if p_water_users is not null then
      for i in 1..p_water_users.count loop
         store_water_user(p_water_users(i), p_fail_if_exists);
      end loop;
   end if;
end store_water_users;
--------------------------------------------------------------------------------
-- deletes the water user identified by the project location ref and entity name.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_project_location_ref
--    project location ref.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
-- p_entity_name
-- p_delete_action
--    the water user entity name.
--    delete key will fail if there are references.
--    delete all will also delete the referring children.
procedure delete_water_user(
	p_project_location_ref in location_ref_t,
	p_entity_name          in varchar,
	p_delete_action        in varchar2 default cwms_util.delete_key )
is
   l_proj_loc_code number := p_project_location_ref.get_location_code;
begin
	cwms_util.check_inputs(str_tab_t(p_entity_name, p_delete_action));
   if not p_delete_action in (cwms_util.delete_key, cwms_util.delete_all ) then
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be '''
         || cwms_util.delete_key
         || ''' or '''
         || cwms_util.delete_all
         || '');
   end if;
   if p_delete_action = cwms_util.delete_all then
      ---------------------------------------------------
      -- delete AT_WAT_USR_CONTRACT_ACCOUNTING records --
      ---------------------------------------------------
      delete
        from at_wat_usr_contract_accounting
       where water_user_contract_code in
             ( select water_user_contract_code
                 from at_water_user_contract
                where water_user_code in
                      ( select water_user_code
                          from at_water_user
                         where project_location_code = l_proj_loc_code
                           and upper(entity_name) = upper(p_entity_name)
                      )
             );
      --------------------------------------------------
      -- delete AT_XREF_WAT_USR_CONTRACT_DOCS records --
      --------------------------------------------------
      delete
        from at_xref_wat_usr_contract_docs
       where water_user_contract_code in
             ( select water_user_contract_code
                 from at_water_user_contract
                where water_user_code in
                      ( select water_user_code
                          from at_water_user
                         where project_location_code = l_proj_loc_code
                           and upper(entity_name) = upper(p_entity_name)
                      )
             );
      -------------------------------------------             
      -- delete AT_WATER_USER_CONTRACT records --
      -------------------------------------------             
      delete
        from at_water_user_contract
       where water_user_code in
             ( select water_user_code
                 from at_water_user
                where project_location_code = l_proj_loc_code
                  and upper(entity_name) = upper(p_entity_name)
             );
   end if;
   ---------------------------------- 
   -- delete AT_WATER_USER records --
   ---------------------------------- 
   delete 
     from at_water_user
    where project_location_code = l_proj_loc_code
      and upper(entity_name) = upper(p_entity_name);
end delete_water_user;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_project_location_ref
--    project location ref.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
-- p_entity_name_old
-- p_entity_name_new
procedure rename_water_user(
	p_project_location_ref in location_ref_t,
	p_entity_name_old      in varchar2,
	p_entity_name_new      in varchar2 )
is
begin
	cwms_util.check_inputs(str_tab_t(p_entity_name_old, p_entity_name_new));
   update at_water_user
      set entity_name = p_entity_name_new
    where project_location_code = p_project_location_ref.get_location_code
      and upper(entity_name) = upper(p_entity_name_old);
end rename_water_user;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- water user contract procedures.
-- p_contracts
-- p_project_location_ref
--    a project location refs that identify the objects we want to retrieve.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
-- p_entity_name
procedure retrieve_contracts(
   p_contracts            out water_user_contract_tab_t,
   p_project_location_ref in  location_ref_t,
   p_entity_name          in  varchar2 )
is
begin
	cwms_util.check_input(p_entity_name);
   p_contracts := water_user_contract_tab_t();
   for rec in (
      select wuc.contract_name,
             wuc.contracted_storage * uc.factor + uc.offset as contracted_storage,
             wuc.water_supply_contract_type,
             wuc.ws_contract_effective_date,
             wuc.ws_contract_expiration_date,
             wuc.initial_use_allocation * uc.factor + uc.offset as initial_use_allocation,
             wuc.future_use_allocation * uc.factor + uc.offset as future_use_allocation,
             wuc.future_use_percent_activated,
             wuc.total_alloc_percent_activated,
             wuc.withdrawal_location_code,
             wuc.supply_location_code,
             wuc.pump_in_location_code,
             o.office_id,
             wct.ws_contract_type_display_value,
             wct.ws_contract_type_tooltip,
             wct.ws_contract_type_active,
             wu.entity_name,
             wu.water_right,
             uc.to_unit_id as storage_unit_id
        from at_water_user_contract wuc,
             at_water_user wu,
             at_ws_contract_type wct,
             cwms_base_parameter bp,
             cwms_unit_conversion uc,
             cwms_office o
       where wu.project_location_code = p_project_location_ref.get_location_code
         and upper(wu.entity_name) = upper(p_entity_name)
         and wuc.water_user_code = wu.water_user_code
         and wct.ws_contract_type_code = wuc.water_supply_contract_type
         and o.office_code = wct.db_office_code
         and bp.base_parameter_id = 'Stor'
         and uc.from_unit_code = bp.unit_code
         and uc.to_unit_code = wuc.storage_unit_code
         )
   loop
      p_contracts.extend;
      p_contracts(p_contracts.count) := water_user_contract_obj_t(
         water_user_contract_ref_t(
            water_user_obj_t(
               p_project_location_ref,
               rec.entity_name,
               rec.water_right),
            rec.contract_name),
         lookup_type_obj_t(
            rec.office_id,
            rec.ws_contract_type_display_value,
            rec.ws_contract_type_tooltip,
            rec.ws_contract_type_active),
         rec.ws_contract_effective_date,
         rec.ws_contract_expiration_date,
         rec.contracted_storage,
         rec.initial_use_allocation,
         rec.future_use_allocation,
         rec.storage_unit_id,
         rec.future_use_percent_activated,
         rec.total_alloc_percent_activated,
         cwms_loc.retrieve_location(rec.withdrawal_location_code),
         cwms_loc.retrieve_location(rec.supply_location_code),
         cwms_loc.retrieve_location(rec.pump_in_location_code));
   end loop;
end retrieve_contracts;
--------------------------------------------------------------------------------
-- stores a set of water user contracts.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_contracts
-- p_fail_if_exists
--    a flag that will cause the procedure to fail if the objects already exist
procedure store_contracts(
   p_contracts      in water_user_contract_tab_t,
   p_fail_if_exists in varchar2 default 'T' )
is
   l_fail_if_exists boolean;
   l_rec            at_water_user_contract%rowtype;
   l_ref            water_user_contract_ref_t;
   l_water_user_code number(10);
   
   procedure populate_contract(
      p_rec in out nocopy at_water_user_contract%rowtype,
      p_obj in            water_user_contract_obj_t)
   is
      l_factor             binary_double;
      l_offset             binary_double;
      l_contract_type_code number(10);
      l_storage_unit_code  number(10);
      l_water_user_code    number(10);
   begin
      ----------------------------------
      -- get the unit conversion info --
      ----------------------------------
      select uc.factor,
             uc.offset,
             uc.from_unit_code
        into l_factor,
             l_offset,
             l_storage_unit_code
        from cwms_base_parameter bp,
             cwms_unit_conversion uc
       where bp.base_parameter_id = 'Stor'
         and uc.to_unit_code = bp.unit_code
         and uc.from_unit_id = nvl(p_obj.storage_units_id,'m3');
      --------------------------------         
      -- get the contract type code --
      --------------------------------
      select ws_contract_type_code
        into l_contract_type_code
        from at_ws_contract_type
       where db_office_code = cwms_util.get_office_code(p_obj.water_supply_contract_type.office_id)
         and upper(ws_contract_type_display_value) = upper(p_obj.water_supply_contract_type.display_value);
      

      ---------------------------                  
      -- set the record fields --
      ---------------------------      
      p_rec.contracted_storage := p_obj.contracted_storage * l_factor + l_offset;
      p_rec.water_supply_contract_type := l_contract_type_code;
      p_rec.ws_contract_effective_date := p_obj.ws_contract_effective_date;
      p_rec.ws_contract_expiration_date := p_obj.ws_contract_expiration_date;
      p_rec.initial_use_allocation := p_obj.initial_use_allocation * l_factor + l_offset;
      p_rec.future_use_allocation := p_obj.future_use_allocation * l_factor + l_offset;
      p_rec.future_use_percent_activated := p_obj.future_use_percent_activated;
      p_rec.total_alloc_percent_activated := p_obj.total_alloc_percent_activated;
      if p_obj.withdraw_location is not null
      then
        --store location data
        cwms_loc.store_location(p_obj.withdraw_location,'F');
        --get location code
        p_rec.withdrawal_location_code := p_obj.withdraw_location.location_ref.get_location_code('F');
      end if;
      if p_obj.supply_location is not null
      then
        --store location data
        cwms_loc.store_location(p_obj.supply_location,'F');
        --get location code
        p_rec.supply_location_code := p_obj.supply_location.location_ref.get_location_code('F');
      end if;
      if p_obj.pump_in_location is not null
      then
        --store location data
        cwms_loc.store_location(p_obj.pump_in_location,'F');
        --get location code.
        p_rec.pump_in_location_code := p_obj.pump_in_location.location_ref.get_location_code('F');
      end if;      
      p_rec.storage_unit_code := l_storage_unit_code;
   end;
begin
	cwms_util.check_input(p_fail_if_exists);
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   if p_contracts is not null then
      for i in 1..p_contracts.count loop
         l_ref := p_contracts(i).water_user_contract_ref;
         begin
            -- select the water user code
            select water_user_code 
            into l_water_user_code
            from at_water_user
            where project_location_code = l_ref.water_user.project_location_ref.get_location_code
            and upper(entity_name) = upper(l_ref.water_user.entity_name);
        
            -- select the contract row.
            select *
            into l_rec
            from at_water_user_contract
            where water_user_code = l_water_user_code
            and upper(contract_name) = upper(l_ref.contract_name);
            -- contract row exists
            -- check fail if exists
            if l_fail_if_exists then
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'Water supply contract',
                  l_ref.water_user.project_location_ref.get_office_id
                  || '/'
                  || l_ref.water_user.project_location_ref.get_location_id
                  || '/'
                  || l_ref.water_user.entity_name
                  || '/'
                  || l_ref.contract_name);                  
            end if;
            -- update row
            populate_contract(l_rec, p_contracts(i));
            update at_water_user_contract
            set row = l_rec
            where water_user_contract_code = l_rec.water_user_contract_code;
         exception
            -- contract row not found
            when no_data_found then
              -- copy incoming non-key contract data to row.
              populate_contract(l_rec, p_contracts(i));
              -- set the contract name
              l_rec.contract_name := l_ref.contract_name;
              -- assign water user code
              l_rec.water_user_code := l_water_user_code;
              -- generate new key
              l_rec.water_user_contract_code := cwms_seq.nextval;
              -- insert into table
              insert
              into at_water_user_contract
              values l_rec;
         end;
      end loop;
   end if;
end store_contracts;
--------------------------------------------------------------------------------
-- deletes the water user contract associated with the argument ref.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_contract_ref
--    contains the identifying parts of the contract to delete.
-- p_delete_action
--    delete key will fail if there are references.
--    delete all will also delete the referring children.
procedure delete_contract(
   p_contract_ref  in water_user_contract_ref_t,
   p_delete_action in varchar2 default cwms_util.delete_key )
is
   l_contract_code number;
begin
   if not p_delete_action in (cwms_util.delete_key, cwms_util.delete_all ) then
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be '''
         || cwms_util.delete_key
         || ''' or '''
         || cwms_util.delete_all
         || '');
   end if;
   select water_user_contract_code
     into l_contract_code
     from at_water_user_contract
    where water_user_code =
          ( select water_user_code
              from at_water_user
             where project_location_code = p_contract_ref.water_user.project_location_ref.get_location_code
               and upper(entity_name) = upper(p_contract_ref.water_user.entity_name)
          )
      and upper(contract_name) = upper(p_contract_ref.contract_name);    
   if p_delete_action = cwms_util.delete_all then
      delete
        from at_wat_usr_contract_accounting
       where water_user_contract_code = l_contract_code;
      delete
        from at_xref_wat_usr_contract_docs
       where water_user_contract_code = l_contract_code;
   end if;
   delete
     from at_water_user_contract
    where water_user_contract_code = l_contract_code;    
end delete_contract;
--------------------------------------------------------------------------------
-- renames the water user contract associated with the contract arg from
-- the old contract name to the new contract name.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
PROCEDURE rename_contract(
   p_water_user_contract IN water_user_contract_ref_t,
   p_old_contract_name   IN VARCHAR2,
   p_new_contract_name   IN VARCHAR2 )
is
begin
	cwms_util.check_inputs(str_tab_t(p_old_contract_name, p_new_contract_name));
   update at_water_user_contract
      set contract_name = p_new_contract_name
    where water_user_code = 
          ( select water_user_code
              from at_water_user
             where project_location_code 
                   = p_water_user_contract.water_user.project_location_ref.get_location_code
               and upper(entity_name) 
                   = upper(p_water_user_contract.water_user.entity_name)
          )
      and upper(contract_name) = upper(p_old_contract_name); 
end rename_contract;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- look up procedures.
-- returns a listing of lookup objects.
-- p_lookup_type_tab_t
-- p_db_office_id
--    defaults to the connected user's office if null
procedure get_contract_types(
	p_contract_types out lookup_type_tab_t,
	p_db_office_id   in  varchar2 default null )
is
begin
	cwms_util.check_input(p_db_office_id);
   p_contract_types := lookup_type_tab_t();
   for rec in (
      select o.office_id,
             wct.ws_contract_type_display_value,
             wct.ws_contract_type_tooltip,
             wct.ws_contract_type_active
        from at_ws_contract_type wct,
             cwms_office o
       where o.office_id = nvl(upper(p_db_office_id), cwms_util.user_office_id)
         and wct.db_office_code = o.office_code)
   loop
      p_contract_types.extend;
      p_contract_types(p_contract_types.count) := lookup_type_obj_t(
         rec.office_id,
         rec.ws_contract_type_display_value,
         rec.ws_contract_type_tooltip,
         rec.ws_contract_type_active);
   end loop;              
end get_contract_types;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- inserts or updates a set of lookups.
-- if a lookup does not exist it will be inserted.
-- if a lookup already exists and p_fail_if_exists is false, the existing
-- lookup will be updated.
--
-- a failure will cause the whole set of lookups to not be stored.
-- p_lookup_type_tab_t IN lookup_type_tab_t,
-- p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )AS
--    a flag that will cause the procedure to fail if the objects already exist
procedure set_contract_types(
	p_contract_types in lookup_type_tab_t,
	p_fail_if_exists in varchar2 default 'T' )
is
   l_office_code    number;
   l_fail_if_exists boolean; 
   l_rec            at_ws_contract_type%rowtype;
begin
	cwms_util.check_input(p_fail_if_exists);
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists); 
   if p_contract_types is not null then
      for i in 1..p_contract_types.count loop
         l_office_code := cwms_util.get_office_code(p_contract_types(i).office_id);
         begin
            select *
              into l_rec
              from at_ws_contract_type
             where db_office_code = l_office_code
               and upper(ws_contract_type_display_value) = 
                   upper(p_contract_types(i).display_value);
            if l_fail_if_exists then
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'WS_CONTRACT_TYPE',
                  upper(p_contract_types(i).office_id)
                  || '/'
                  || p_contract_types(i).display_value);
            end if;                   
            l_rec.ws_contract_type_display_value := p_contract_types(i).display_value;                  
            l_rec.ws_contract_type_tooltip := p_contract_types(i).tooltip;                  
            l_rec.ws_contract_type_active := p_contract_types(i).active;
            update at_ws_contract_type
               set row = l_rec
             where ws_contract_type_code = l_rec.ws_contract_type_code;                  
         exception
            when no_data_found then
               l_rec.ws_contract_type_code := cwms_seq.nextval;
               l_rec.db_office_code := l_office_code;
               l_rec.ws_contract_type_display_value := p_contract_types(i).display_value;                  
               l_rec.ws_contract_type_tooltip := p_contract_types(i).tooltip;                  
               l_rec.ws_contract_type_active := p_contract_types(i).active;
               insert
                 into at_ws_contract_type
               values l_rec;
         end;
      end loop;
   end if;
end set_contract_types;
--------------------------------------------------------------------------------
-- water supply accounting
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- store a water user contract accounting set.
--------------------------------------------------------------------------------
-- p_accounting_set IN wat_usr_contract_acct_tab_t,
--    a flag that will cause the procedure to fail if the objects already exist
-- p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )AS
--    a flag that will cause the procedure to fail if the objects already exist
PROCEDURE store_accounting_set(
    -- the set of water user contract accountings to store to the database.
    p_accounting_set IN wat_usr_contract_acct_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    -- p_fail_if_exists in varchar2 default 'T' 

		-- store rule, only delete insert initially supported.
    p_store_rule		in varchar2 default null,
    -- start time of data to delete.
    p_start_time	  in		date default null,
    --end time of data to delete.
    p_end_time		  in		date default null,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive in varchar2 default 'T',
    -- if protection is to be ignored, not initially supported.
		p_override_prot	in varchar2 default 'F'
    )   
   
   
is
   -- l_fail_if_exists boolean;
   l_rec            at_wat_usr_contract_accounting%rowtype;
   l_ref            water_user_contract_ref_t;
   l_factor         binary_double;
   l_offset         binary_double;
   l_water_usr_code number(10);
   l_contract_code  number(10);
   l_xfer_type_code number(10);
   l_time_zone      varchar2(28);
   
   procedure populate_accounting(
      p_rec in out nocopy at_wat_usr_contract_accounting%rowtype,
      p_obj in            wat_usr_contract_acct_obj_t)
   is
   begin
      p_rec.water_user_contract_code := l_contract_code;
      p_rec.physical_transfer_type_code := l_xfer_type_code;
      -- p_rec.accounting_credit_debit := p_obj.accounting_credit_debit;
      p_rec.accounting_volume := p_obj.accounting_volume * l_factor + l_offset;
      p_rec.transfer_start_datetime := 
         cwms_util.change_timezone(
            p_obj.transfer_start_datetime, 
            l_time_zone, 
            'UTC');             
      -- p_rec.transfer_end_datetime := 
      --   cwms_util.change_timezone(
      --      p_obj.transfer_end_datetime, 
      --      l_time_zone, 
      --      'UTC');             
      p_rec.accounting_remarks := p_obj.accounting_remarks;             
   end;
begin
	-- cwms_util.check_input(p_fail_if_exists);
   -- l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   if p_accounting_set is not null then
      for i in 1..p_accounting_set.count loop
         l_ref := p_accounting_set(i).water_user_contract_ref;
         -----------------------------
         -- get the water user code --
         -----------------------------
         select water_user_code
           into l_water_usr_code
           from at_water_user
          where project_location_code 
                = l_ref.water_user.project_location_ref.get_location_code
            and upper(entity_name) 
                = upper(l_ref.water_user.entity_name);
         -----------------------             
         -- get the time zone --
         -----------------------
         select tz.time_zone_name
           into l_time_zone
           from at_water_user wu,
                at_physical_location pl,
                cwms_time_zone tz
          where wu.water_user_code = l_water_usr_code
            and pl.location_code = wu.project_location_code
            and tz.time_zone_code = nvl(
                  pl.time_zone_code, 
                  (  select time_zone_code 
                       from cwms_time_zone 
                      where time_zone_name = 'UTC'
                  ));
         ---------------------------
         -- get the contract code --
         ---------------------------
         select water_user_contract_code
           into l_contract_code
           from at_water_user_contract
          where water_user_code = l_water_usr_code 
            and upper(contract_name) = upper(l_ref.contract_name);
         ----------------------------------
         -- get the unit conversion info --
         ----------------------------------
         select uc.factor,
                uc.offset
           into l_factor,
                l_offset
           from cwms_base_parameter bp,
                cwms_unit_conversion uc,
                at_water_user_contract wuc
          where bp.base_parameter_id = 'Stor'
            and uc.to_unit_code = bp.unit_code
            and wuc.water_user_contract_code = l_contract_code
            and uc.from_unit_code = wuc.storage_unit_code;
         -----------------------------------------         
         -- get the physical transfer type code --
         -----------------------------------------
         select physical_transfer_type_code
           into l_xfer_type_code
           from at_physical_transfer_type ptt,
                cwms_office o
          where o.office_id = upper(p_accounting_set(i).physical_transfer_type.office_id)
            and ptt.db_office_code = o.office_code
            and upper(ptt.phys_trans_type_display_value) 
                = upper(p_accounting_set(i).physical_transfer_type.display_value);
         ---------------------------------                
         -- store the accounting record --
         ---------------------------------                
         begin
            select *
              into l_rec
              from at_wat_usr_contract_accounting
             where water_user_contract_code = l_water_usr_code
               and physical_transfer_type_code = l_xfer_type_code
               and transfer_start_datetime = cwms_util.change_timezone(
                     p_accounting_set(i).transfer_start_datetime, 
                     l_time_zone, 
                     'UTC');
               --and transfer_end_datetime = cwms_util.change_timezone(
               --      p_accounting_set(i).transfer_end_datetime, 
               --      l_time_zone, 
               --      'UTC');             
            -- if l_fail_if_exists then
             --  cwms_err.raise(
             --     'ITEM_ALREADY_EXITS',
             --     'Water user contract accounting',
             --     l_ref.water_user.project_location_ref.get_office_id
             --     || '/'
             --     || l_ref.water_user.project_location_ref.get_location_id
             --     || '/'
             --     || l_ref.water_user.entity_name
             --     || '/'
             --     || l_ref.contract_name
             --     || '/'
             --     || p_accounting_set(i).physical_transfer_type.display_value
             --     || ' ('
             --     || to_char(p_accounting_set(i).transfer_start_datetime, 'dd-Mon-yyyy hh24mi')                  
             --     || ' to '
             --     || to_char(p_accounting_set(i).transfer_end_datetime, 'dd-Mon-yyyy hh24mi')
             --     || ')');                  
            -- end if;
            populate_accounting(
               l_rec,
               p_accounting_set(i));
            update at_wat_usr_contract_accounting
               set row = l_rec
             where wat_usr_contract_acct_code = l_rec.wat_usr_contract_acct_code;
         exception
            when no_data_found then
               populate_accounting(
                  l_rec,
                  p_accounting_set(i));
               l_rec.wat_usr_contract_acct_code := cwms_seq.nextval;
               insert
                 into at_wat_usr_contract_accounting
               values l_rec;
         end;
      end loop;
   end if;
end store_accounting_set;
--------------------------------------------------------------------------------
-- retrieve a water user contract accounting set.
--------------------------------------------------------------------------------
PROCEDURE retrieve_accounting_set(
    -- the retrieved set of water user contract accountings
    p_accounting_set out wat_usr_contract_acct_tab_t,

    -- the water user contract ref
    p_contract_ref IN water_user_contract_ref_t,
    
    -- the units to return the volume as.
    p_units IN VARCHAR2,
    --time window stuff
    -- the transfer start date time
    p_start_time IN DATE,
    -- the transfer end date time
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive IN VARCHAR2 DEFAULT 'T',
    
    -- a boolean flag indicating if the returned data should be the head or tail
    -- of the set, i.e. the first n values or last n values.
    p_ascending_flag IN VARCHAR2 DEFAULT 'T',
    
    -- limit on the number of rows returned
    p_row_limit IN INTEGER DEFAULT NULL,
    
    -- a mask for the transfer type.
    -- if null, return all transfers.
    -- do we need this?
    p_transfer_type IN VARCHAR2 DEFAULT NULL
  )
  is
    l_contract_code          number(10);
    l_project_location_code  number(10);
    l_adjusted_start_time    date;
    l_adjusted_end_time      date;
    l_start_time_inclusive   boolean;
    l_end_time_inclusive     boolean;
    l_time_zone_code         number(10);
    l_location_ref         location_ref_t;
    l_pump_location_ref        location_ref_t;
   
begin
    -- instantiate a table array to hold the output records.
    p_accounting_set := wat_usr_contract_acct_tab_t();
    -- null check the contract.
    if p_contract_ref is null then
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Contract Reference');
    end if;
    
    
    
    cwms_util.check_inputs(str_tab_t(
       p_units,
       p_time_zone,
       p_start_inclusive,
       p_end_inclusive
       ));
    --------------------------------
    -- prepare selection criteria --
    --------------------------------
    l_project_location_code :=  p_contract_ref.water_user.project_location_ref.get_location_code('F');
    
    select water_user_contract_code 
    into l_contract_code
    from at_water_user_contract wuc,
        at_water_user wu
    where wuc.water_user_code = wu.water_user_code
        and upper(wuc.contract_name) = upper(p_contract_ref.contract_name)
        and upper(wu.entity_name) = upper(p_contract_ref.water_user.entity_name)
        and wu.project_location_code = l_project_location_code;
    
    l_start_time_inclusive := cwms_util.is_true(p_start_inclusive);
    l_end_time_inclusive   := cwms_util.is_true(p_end_inclusive);
    
    l_adjusted_start_time := cwms_util.change_timezone(
                     p_start_time,
                     cwms_loc.get_local_timezone(l_project_location_code), 
                     'UTC');
    l_adjusted_end_time := cwms_util.change_timezone(
                     p_end_time,
                     cwms_loc.get_local_timezone(l_project_location_code), 
                     'UTC');
    
    if l_start_time_inclusive = FALSE then
       l_adjusted_start_time := l_adjusted_start_time + (1 / 86400);
    end if;
    
    if l_end_time_inclusive = FALSE then
       l_adjusted_end_time := l_adjusted_end_time - (1 / 86400);
    end if;
    
    if p_time_zone is not null then
       select tz.time_zone_code
         into l_time_zone_code
         from cwms_time_zone tz
        where upper(tz.time_zone_name) = upper(p_time_zone);
    end if;
   
   ----------------------------------------
   -- select records and populate output --
   ----------------------------------------
   for rec in (  
WITH ordered_wuca AS
  (SELECT
    /*+ FIRST_ROWS(100) */
    wat_usr_contract_acct_code,
    water_user_contract_code,
    pump_location_code,
    physical_transfer_type_code,
    accounting_volume,
    transfer_start_datetime,
    accounting_remarks
  FROM at_wat_usr_contract_accounting
  WHERE water_user_contract_code = 623051
  AND transfer_start_datetime BETWEEN to_date('2010/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') AND to_date('2010/03/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss')
  ORDER BY transfer_start_datetime DESC
  ) ,
  limited_wuca AS
  (SELECT wat_usr_contract_acct_code,
    water_user_contract_code,
    pump_location_code,
    physical_transfer_type_code,
    accounting_volume,
    transfer_start_datetime,
    accounting_remarks
  FROM ordered_wuca
  WHERE rownum <= 50
  )
SELECT limited_wuca.pump_location_code,
  limited_wuca.transfer_start_datetime,
  limited_wuca.accounting_volume,
  u.unit_id AS units_id,
  uc.factor,
  uc.offset,
  o.office_id AS transfer_type_office_id,
  ptt.phys_trans_type_display_value,
  ptt.physical_transfer_type_tooltip,
  ptt.physical_transfer_type_active,
  limited_wuca.accounting_remarks
FROM limited_wuca
INNER JOIN at_water_user_contract wuc
ON (limited_wuca.water_user_contract_code = wuc.water_user_contract_code)
INNER JOIN at_physical_transfer_type ptt
ON (limited_wuca.physical_transfer_type_code = ptt.physical_transfer_type_code)
inner join cwms_office o on ptt.db_office_code = o.office_code
INNER JOIN cwms_unit u
ON (wuc.storage_unit_code = u.unit_code)
INNER JOIN cwms_unit_conversion uc
ON uc.to_unit_code = wuc.storage_unit_code
INNER JOIN cwms_base_parameter bp
ON uc.from_unit_code     = bp.unit_code
AND bp.base_parameter_id = 'Stor'

   )
   loop
      --extend the array.
      p_accounting_set.extend;
      
      --dont need full pump location, just ref.
      l_pump_location_ref := new location_ref_t(rec.pump_location_code);
      
      p_accounting_set(p_accounting_set.count) := wat_usr_contract_acct_obj_t(
         --re-use arg contract ref
        p_contract_ref,
        l_pump_location_ref,  -- the pump location
        lookup_type_obj_t(
          rec.transfer_type_office_id,
          rec.phys_trans_type_display_value,
          rec.physical_transfer_type_tooltip,
          rec.physical_transfer_type_active),
        rec.accounting_volume * rec.factor + rec.offset,
        rec.units_id,
        cwms_util.change_timezone(
           rec.transfer_start_datetime, 
           'UTC',
           cwms_loc.get_local_timezone(
              l_pump_location_ref.get_location_id,
              l_pump_location_ref.get_office_id)),
        rec.accounting_remarks);
   end loop;      
end retrieve_accounting_set;
end cwms_water_supply;

/
show errors;
grant execute on cwms_water_supply to cwms_user;

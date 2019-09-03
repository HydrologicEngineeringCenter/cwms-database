WHENEVER sqlerror exit SQL.sqlcode
--------------------------------------------------------------------------------
-- package cwms_water_supply.
-- used to manipulate the tables at_water_user, at_water_user_contract,
-- at_wat_usr_contract_accounting, at_xref_wat_usr_contract_docs.
-- also manipulates at_document.
--------------------------------------------------------------------------------
CREATE OR REPLACE
PACKAGE BODY cwms_water_supply
AS
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
--    project_id                varchar2(57)  the identification (id) of the parent project.
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
PROCEDURE cat_water_user(
	p_cursor            out sys_refcursor,
	p_project_id_mask   IN  VARCHAR2 DEFAULT NULL,
	p_db_office_id_mask IN  VARCHAR2 DEFAULT NULL )
IS
   l_office_id_mask  VARCHAR2(16) :=
      cwms_util.normalize_wildcards(nvl(upper(p_db_office_id_mask), '%'), TRUE);
   l_project_id_mask VARCHAR2(57) :=
      cwms_util.normalize_wildcards(nvl(upper(p_project_id_mask), '%'), TRUE);
BEGIN
   OPEN p_cursor FOR
      SELECT o.office_id AS project_office_id,
             bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id AS project_id,
             wu.entity_name,
             wu.water_right
        FROM at_water_user wu,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       WHERE o.office_id LIKE l_office_id_mask ESCAPE '\'
         AND bl.db_office_code = o.office_code
         AND pl.base_location_code = bl.base_location_code
         AND upper(bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id) LIKE l_project_id_mask ESCAPE '\'
         AND wu.project_location_code = pl.location_code;
END cat_water_user;
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
--    project_id                varchar2(57)  the identification (id) of the parent project.
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
PROCEDURE cat_water_user_contract(
   p_cursor            out sys_refcursor,
   p_project_id_mask   IN  VARCHAR2 DEFAULT NULL,
   p_entity_name_mask  IN  VARCHAR2 DEFAULT NULL,
   p_db_office_id_mask IN  VARCHAR2 DEFAULT NULL )
IS
   l_office_id_mask  VARCHAR2(16) :=
      cwms_util.normalize_wildcards(nvl(upper(p_db_office_id_mask), '%'), TRUE);
   l_project_id_mask VARCHAR2(57) :=
      cwms_util.normalize_wildcards(nvl(upper(p_project_id_mask), '%'), TRUE);
   l_entity_name_mask VARCHAR2(49) :=
      cwms_util.normalize_wildcards(nvl(upper(p_entity_name_mask), '%'), TRUE);
BEGIN
   OPEN p_cursor FOR
      SELECT o.office_id AS project_office_id,
             bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id AS project_id,
             wu.entity_name,
             wuc.contract_name,
             wuc.contracted_storage,
             wct.ws_contract_type_display_value
        FROM at_water_user wu,
             at_water_user_contract wuc,
             at_ws_contract_type wct,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       WHERE o.office_id LIKE l_office_id_mask ESCAPE '\'
         AND bl.db_office_code = o.office_code
         AND pl.base_location_code = bl.base_location_code
         AND upper(bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id) LIKE l_project_id_mask ESCAPE '\'
         AND wu.project_location_code = pl.location_code
         AND upper(wu.entity_name) LIKE l_entity_name_mask ESCAPE '\'
         AND wuc.water_user_code = wu.water_user_code
         AND wct.ws_contract_type_code = wuc.water_supply_contract_type;
END cat_water_user_contract;
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
PROCEDURE retrieve_water_users(
	p_water_users          out water_user_tab_t,
	p_project_location_ref IN  location_ref_t )
IS
BEGIN
   p_water_users := water_user_tab_t();
   FOR rec IN (
      SELECT entity_name,
             water_right
        FROM at_water_user
       WHERE project_location_code = p_project_location_ref.get_location_code)
   loop
      p_water_users.EXTEND;
      p_water_users(p_water_users.count) := water_user_obj_t(
         p_project_location_ref,
         rec.entity_name,
         rec.water_right);
   END loop;
END retrieve_water_users;

PROCEDURE store_water_user(
   p_water_user     IN water_user_obj_t,
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
IS
   l_rec           at_water_user%rowtype;
   l_proj_loc_code NUMBER := p_water_user.project_location_ref.get_location_code;
BEGIN
   BEGIN
      SELECT *
        INTO l_rec
        FROM at_water_user
       WHERE project_location_code = l_proj_loc_code
         AND upper(entity_name) = upper(p_water_user.entity_name);
      IF cwms_util.is_true(p_fail_if_exists) THEN
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Water User',
            p_water_user.project_location_ref.get_office_id
            ||'/'
            || p_water_user.project_location_ref.get_location_id
            ||'/'
            || p_water_user.entity_name);
      END IF;
      IF l_rec.water_right != p_water_user.water_right THEN
         l_rec.water_right := p_water_user.water_right;
         UPDATE at_water_user
            SET ROW = l_rec
          WHERE water_user_code = l_rec.water_user_code;
      END IF;
   exception
      WHEN no_data_found THEN
         l_rec.water_user_code := cwms_seq.nextval;
         l_rec.project_location_code := l_proj_loc_code;
         l_rec.entity_name := p_water_user.entity_name;
         l_rec.water_right := p_water_user.water_right;
      INSERT
        INTO at_water_user
      VALUES l_rec;
   END;

END store_water_user;
--------------------------------------------------------------------------------
-- store a set of water users.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_water_user
-- p_fail_if_exists
--    a flag that will cause the procedure to fail if the object already exists
PROCEDURE store_water_users(
   p_water_users    IN water_user_tab_t,
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
IS
BEGIN
   IF p_water_users IS NOT NULL THEN
      FOR i IN 1..p_water_users.count loop
         store_water_user(p_water_users(i), p_fail_if_exists);
      END loop;
   END IF;
END store_water_users;
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
PROCEDURE delete_water_user(
	p_project_location_ref IN location_ref_t,
	p_entity_name          IN VARCHAR,
	p_delete_action        IN VARCHAR2 DEFAULT cwms_util.delete_key )
IS
   l_proj_loc_code NUMBER := p_project_location_ref.get_location_code;
BEGIN
   IF NOT p_delete_action IN (cwms_util.delete_key, cwms_util.delete_all ) THEN
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be '''
         || cwms_util.delete_key
         || ''' or '''
         || cwms_util.delete_all
         || '');
   END IF;
   IF p_delete_action = cwms_util.delete_all THEN
      ---------------------------------------------------
      -- delete AT_WAT_USR_CONTRACT_ACCOUNTING records --
      ---------------------------------------------------
      DELETE
        FROM at_wat_usr_contract_accounting
       WHERE water_user_contract_code IN
             ( SELECT water_user_contract_code
                 FROM at_water_user_contract
                WHERE water_user_code IN
                      ( SELECT water_user_code
                          FROM at_water_user
                         WHERE project_location_code = l_proj_loc_code
                           AND upper(entity_name) = upper(p_entity_name)
                      )
             );
      --------------------------------------------------
      -- delete AT_XREF_WAT_USR_CONTRACT_DOCS records --
      --------------------------------------------------
      DELETE
        FROM at_xref_wat_usr_contract_docs
       WHERE water_user_contract_code IN
             ( SELECT water_user_contract_code
                 FROM at_water_user_contract
                WHERE water_user_code IN
                      ( SELECT water_user_code
                          FROM at_water_user
                         WHERE project_location_code = l_proj_loc_code
                           AND upper(entity_name) = upper(p_entity_name)
                      )
             );
      -------------------------------------------
      -- delete AT_WATER_USER_CONTRACT records --
      -------------------------------------------
      DELETE
        FROM at_water_user_contract
       WHERE water_user_code IN
             ( SELECT water_user_code
                 FROM at_water_user
                WHERE project_location_code = l_proj_loc_code
                  AND upper(entity_name) = upper(p_entity_name)
             );
   END IF;
   ----------------------------------
   -- delete AT_WATER_USER records --
   ----------------------------------
   DELETE
     FROM at_water_user
    WHERE project_location_code = l_proj_loc_code
      AND upper(entity_name) = upper(p_entity_name);
END delete_water_user;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_project_location_ref
--    project location ref.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
-- p_entity_name_old
-- p_entity_name_new
PROCEDURE rename_water_user(
	p_project_location_ref IN location_ref_t,
	p_entity_name_old      IN VARCHAR2,
	p_entity_name_new      IN VARCHAR2 )
IS
BEGIN
   UPDATE at_water_user
      SET entity_name = p_entity_name_new
    WHERE project_location_code = p_project_location_ref.get_location_code
      AND upper(entity_name) = upper(p_entity_name_old);
END rename_water_user;
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
PROCEDURE retrieve_contracts(
   p_contracts            out water_user_contract_tab_t,
   p_project_location_ref IN  location_ref_t,
   p_entity_name          IN  VARCHAR2 )
IS
BEGIN
   p_contracts := water_user_contract_tab_t();
   FOR rec IN (
      SELECT wuc.contract_name,
             wuc.contracted_storage * uc.factor + uc.offset AS contracted_storage,
             wuc.water_supply_contract_type,
             wuc.ws_contract_effective_date,
             wuc.ws_contract_expiration_date,
             wuc.initial_use_allocation * uc.factor + uc.offset AS initial_use_allocation,
             wuc.future_use_allocation * uc.factor + uc.offset AS future_use_allocation,
             wuc.future_use_percent_activated,
             wuc.total_alloc_percent_activated,
             wuc.pump_out_location_code,
             wuc.pump_out_below_location_code,
             wuc.pump_in_location_code,
             o.office_id,
             wct.ws_contract_type_display_value,
             wct.ws_contract_type_tooltip,
             wct.ws_contract_type_active,
             wu.entity_name,
             wu.water_right,
             uc.to_unit_id AS storage_unit_id
        FROM at_water_user_contract wuc,
             at_water_user wu,
             at_ws_contract_type wct,
             cwms_base_parameter bp,
             cwms_unit_conversion uc,
             cwms_office o
       WHERE wu.project_location_code = p_project_location_ref.get_location_code
         AND upper(wu.entity_name) = upper(p_entity_name)
         AND wuc.water_user_code = wu.water_user_code
         AND wct.ws_contract_type_code = wuc.water_supply_contract_type
         AND o.office_code = wct.db_office_code
         AND bp.base_parameter_id = 'Stor'
         AND uc.from_unit_code = bp.unit_code
         AND uc.to_unit_code = wuc.storage_unit_code
         )
   loop
      p_contracts.EXTEND;
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
         cwms_loc.retrieve_location(rec.pump_out_location_code),
         cwms_loc.retrieve_location(rec.pump_out_below_location_code),
         cwms_loc.retrieve_location(rec.pump_in_location_code));
   END loop;
END retrieve_contracts;
--------------------------------------------------------------------------------
-- stores a set of water user contracts.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_contracts
-- p_fail_if_exists
--    a flag that will cause the procedure to fail if the objects already exist
PROCEDURE store_contracts(
    p_contracts in water_user_contract_tab_t,
    p_fail_if_exists IN varchar2 default 'T')
is
begin
   store_contracts2(p_contracts, p_fail_if_exists, 'T');
end store_contracts;
--------------------------------------------------------------------------------
-- stores a set of water user contracts.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_contracts
-- p_fail_if_exists
--    a flag that will cause the procedure to fail if the objects already exist
--    a flag that specifies whether the routine should ignore null values in the input data
PROCEDURE store_contracts2(
   p_contracts      IN water_user_contract_tab_t,
    p_fail_if_exists IN varchar2 default 'T',
    p_ignore_nulls IN varchar2 default 'T')
IS
   l_fail_if_exists boolean;
   l_ignore_nulls   boolean;
   l_rec            at_water_user_contract%rowtype;
   l_ref            water_user_contract_ref_t;
   l_water_user_code NUMBER(10);

   PROCEDURE populate_contract(
      p_rec IN out nocopy at_water_user_contract%rowtype,
      p_obj IN            water_user_contract_obj_t)
   IS
      l_factor              binary_double;
      l_offset              BINARY_DOUBLE;
      l_contract_type_code  NUMBER(10);
      l_storage_unit_code   number(10);
      l_water_user_code     number(10);
      l_stream_location_rec at_stream_location%rowtype;
   BEGIN
      ----------------------------------
      -- get the unit conversion info --
      ----------------------------------
      SELECT uc.factor,
             uc.offset,
             uc.from_unit_code
        INTO l_factor,
             l_offset,
             l_storage_unit_code
        FROM cwms_base_parameter bp,
             cwms_unit_conversion uc
       WHERE bp.base_parameter_id = 'Stor'
         AND uc.to_unit_code = bp.unit_code
         AND uc.from_unit_id = nvl(p_obj.storage_units_id,'m3');
      --------------------------------
      -- get the contract type code --
      --------------------------------
      SELECT ws_contract_type_code
        INTO l_contract_type_code
        from at_ws_contract_type
       WHERE db_office_code in (cwms_util.db_office_code_all, cwms_util.get_office_code(p_obj.water_supply_contract_type.office_id))
         AND upper(ws_contract_type_display_value) = upper(p_obj.water_supply_contract_type.display_value);


      ---------------------------
      -- set the record fields --
      ---------------------------
      p_rec.contracted_storage := p_obj.contracted_storage * l_factor + l_offset;
      p_rec.water_supply_contract_type := l_contract_type_code;
      IF p_obj.ws_contract_effective_date IS NOT NULL OR NOT l_ignore_nulls
      THEN
         p_rec.ws_contract_effective_date := p_obj.ws_contract_effective_date;
      END IF;
      IF p_obj.ws_contract_expiration_date IS NOT NULL OR NOT l_ignore_nulls
      THEN
         p_rec.ws_contract_expiration_date := p_obj.ws_contract_expiration_date;
      END IF;
      IF p_obj.initial_use_allocation IS NOT NULL OR NOT l_ignore_nulls
      THEN
         p_rec.initial_use_allocation := p_obj.initial_use_allocation * l_factor + l_offset;
      END IF;
      IF p_obj.future_use_allocation IS NOT NULL OR NOT l_ignore_nulls
      THEN
         p_rec.future_use_allocation := p_obj.future_use_allocation * l_factor + l_offset;
      END IF;
      IF p_obj.future_use_percent_activated IS NOT NULL OR NOT l_ignore_nulls
      THEN
         p_rec.future_use_percent_activated := p_obj.future_use_percent_activated;
      END IF;
      IF p_obj.total_alloc_percent_activated IS NOT NULL OR NOT l_ignore_nulls
      THEN
         p_rec.total_alloc_percent_activated := p_obj.total_alloc_percent_activated;
      END IF;
      IF p_obj.pump_out_location IS NOT NULL
      THEN
        -- make sure we have a valid location
        cwms_loc.store_location(p_obj.pump_out_location,'F');
        p_rec.pump_out_location_code := p_obj.pump_out_location.location_ref.get_location_code('F');
        -- make sure we have a valid stream location
        cwms_stream.store_stream_location(
          p_location_id    => p_obj.pump_out_location.location_ref.get_location_id,
          p_stream_id      => null,
          p_fail_if_exists => 'F',
          p_ignore_nulls   => 'T',
          p_station        => null,
          p_station_unit   => null,
          p_office_id      => p_obj.pump_out_location.location_ref.office_id);
        -- make sure we have a valid pump location
        cwms_pump.store_pump (
          p_location_id	   => p_obj.pump_out_location.location_ref.get_location_id,
          p_fail_if_exists	=> 'F',
          p_ignore_nulls   => 'T',
          p_description    => p_obj.pump_out_location.description,
          p_office_id      => p_obj.pump_out_location.location_ref.office_id);
      ELSIF NOT l_ignore_nulls
      THEN
         p_rec.pump_out_location_code := NULL;
      END IF;
      IF p_obj.pump_out_below_location IS NOT NULL
      THEN
        -- make sure we have a valid location
        cwms_loc.store_location(p_obj.pump_out_below_location,'F');
        p_rec.pump_out_below_location_code := p_obj.pump_out_below_location.location_ref.get_location_code('F');
        -- make sure we have a valid stream location
        cwms_stream.store_stream_location(
          p_location_id    => p_obj.pump_out_below_location.location_ref.get_location_id,
          p_stream_id      => null,
          p_fail_if_exists => 'F',
          p_ignore_nulls   => 'T',
          p_station        => null,
          p_station_unit   => null,
          p_office_id      => p_obj.pump_out_below_location.location_ref.office_id);
        -- make sure we have a valid pump location
        cwms_pump.store_pump (
          p_location_id	   => p_obj.pump_out_below_location.location_ref.get_location_id,
          p_fail_if_exists	=> 'F',
          p_ignore_nulls   => 'T',
          p_description    => p_obj.pump_out_below_location.description,
          p_office_id      => p_obj.pump_out_below_location.location_ref.office_id);
      ELSIF NOT l_ignore_nulls
      THEN
         p_rec.pump_out_below_location_code := null;
      END IF;
      IF p_obj.pump_in_location IS NOT NULL
      THEN
        -- make sure we have a valid location
        cwms_loc.store_location(p_obj.pump_in_location,'F');
        p_rec.pump_in_location_code := p_obj.pump_in_location.location_ref.get_location_code('F');
        -- make sure we have a valid stream location
        cwms_stream.store_stream_location(
          p_location_id    => p_obj.pump_in_location.location_ref.get_location_id,
          p_stream_id      => null,
          p_fail_if_exists => 'F',
          p_ignore_nulls   => 'T',
          p_station        => null,
          p_station_unit   => null,
          p_office_id      => p_obj.pump_in_location.location_ref.office_id);
        -- make sure we have a valid pump location
        cwms_pump.store_pump (
          p_location_id	   => p_obj.pump_in_location.location_ref.get_location_id,
          p_fail_if_exists	=> 'F',
          p_ignore_nulls   => 'T',
          p_description    => p_obj.pump_in_location.description,
          p_office_id      => p_obj.pump_in_location.location_ref.office_id);
      ELSIF NOT l_ignore_nulls
      THEN
         p_rec.pump_in_location_code := null;
      END IF;
      p_rec.storage_unit_code := l_storage_unit_code;
   END;
BEGIN
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls := cwms_util.is_true(p_ignore_nulls);
   IF p_contracts IS NOT NULL THEN
      FOR i IN 1..p_contracts.count loop
         l_ref := p_contracts(i).water_user_contract_ref;
         BEGIN
            -- select the water user code
            SELECT water_user_code
            INTO l_water_user_code
            FROM at_water_user
            WHERE project_location_code = l_ref.water_user.project_location_ref.get_location_code
            AND upper(entity_name) = upper(l_ref.water_user.entity_name);

            -- select the contract row.
            SELECT *
            INTO l_rec
            FROM at_water_user_contract
            WHERE water_user_code = l_water_user_code
            AND upper(contract_name) = upper(l_ref.contract_name);
            -- contract row exists
            -- check fail if exists
            IF l_fail_if_exists THEN
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
            END IF;
            -- update row
            populate_contract(l_rec, p_contracts(i));
            UPDATE at_water_user_contract
            SET ROW = l_rec
            WHERE water_user_contract_code = l_rec.water_user_contract_code;
         exception
            -- contract row not found
            WHEN no_data_found THEN
              -- copy incoming non-key contract data to row.
              populate_contract(l_rec, p_contracts(i));
              -- set the contract name
              l_rec.contract_name := l_ref.contract_name;
              -- assign water user code
              l_rec.water_user_code := l_water_user_code;
              -- generate new key
              l_rec.water_user_contract_code := cwms_seq.nextval;
              -- insert into table
              INSERT
              INTO at_water_user_contract
              VALUES l_rec;
         END;
      END loop;
   end if;
END store_contracts2;
--------------------------------------------------------------------------------
-- deletes the water user contract associated with the argument ref.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_contract_ref
--    contains the identifying parts of the contract to delete.
-- p_delete_action
--    delete key will fail if there are references.
--    delete all will also delete the referring children.
PROCEDURE delete_contract(
   p_contract_ref  IN water_user_contract_ref_t,
   p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key )
IS
   l_contract_code NUMBER;
BEGIN
   IF NOT p_delete_action IN (cwms_util.delete_key, cwms_util.delete_all ) THEN
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be '''
         || cwms_util.delete_key
         || ''' or '''
         || cwms_util.delete_all
         || '');
   END IF;
   SELECT water_user_contract_code
     INTO l_contract_code
     FROM at_water_user_contract
    WHERE water_user_code =
          ( SELECT water_user_code
              FROM at_water_user
             WHERE project_location_code = p_contract_ref.water_user.project_location_ref.get_location_code
               AND upper(entity_name) = upper(p_contract_ref.water_user.entity_name)
          )
      AND upper(contract_name) = upper(p_contract_ref.contract_name);
   IF p_delete_action = cwms_util.delete_all THEN
      DELETE
        FROM at_wat_usr_contract_accounting
       WHERE water_user_contract_code = l_contract_code;
      DELETE
        FROM at_xref_wat_usr_contract_docs
       WHERE water_user_contract_code = l_contract_code;
   END IF;
   DELETE
     FROM at_water_user_contract
    WHERE water_user_contract_code = l_contract_code;
END delete_contract;
--------------------------------------------------------------------------------
-- renames the water user contract associated with the contract arg from
-- the old contract name to the new contract name.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
PROCEDURE rename_contract(
   p_water_user_contract IN water_user_contract_ref_t,
   p_old_contract_name   IN VARCHAR2,
   p_new_contract_name   IN VARCHAR2 )
IS
BEGIN
   UPDATE at_water_user_contract
      SET contract_name = p_new_contract_name
    WHERE water_user_code =
          ( SELECT water_user_code
              FROM at_water_user
             WHERE project_location_code
                   = p_water_user_contract.water_user.project_location_ref.get_location_code
               AND upper(entity_name)
                   = upper(p_water_user_contract.water_user.entity_name)
          )
      AND upper(contract_name) = upper(p_old_contract_name);
END rename_contract;
--------------------------------------------------------------------------------
-- procedure associate_pump
--------------------------------------------------------------------------------
procedure associate_pump(
    p_water_user_contract IN water_user_contract_ref_t,
    p_pump_location_id    IN varchar2,
    p_pump_usage_id       IN varchar2)
is
   l_water_user_contract_code integer;
   l_pump_location_code       integer;
   l_existing_pump_code       integer;
   l_pump_usage_id            varchar2(8) := upper(trim(p_pump_usage_id));
begin
   select wuc.water_user_contract_code
     into l_water_user_contract_code
     from at_water_user_contract wuc,
          at_water_user wu
    where wu.project_location_code = p_water_user_contract.water_user.project_location_ref.get_location_code
      and upper(wu.entity_name) = upper(p_water_user_contract.water_user.entity_name)
      and wuc.water_user_code = wu.water_user_code
      and upper(contract_name) = upper(p_water_user_contract.contract_name);

   l_pump_location_code := cwms_loc.get_location_code(p_water_user_contract.water_user.project_location_ref.get_office_id, p_pump_location_id);

   case
   when instr('IN', l_pump_usage_id) = 1 then
      -------------
      -- PUMP IN --
      -------------
      select pump_in_location_code
        into l_existing_pump_code
        from at_water_user_contract
       where water_user_contract_code = l_water_user_contract_code;

      if l_existing_pump_code is not null then
         cwms_err.raise('ERROR', 'Contract already has pump associated for pump-in usage: '||cwms_loc.get_location_id(l_existing_pump_code));
      end if;
      update at_water_user_contract
         set pump_in_location_code = l_pump_location_code
       where water_user_contract_code = l_water_user_contract_code;
   when instr('OUT', l_pump_usage_id) = 1 then
      --------------
      -- PUMP OUT --
      --------------
      select pump_out_location_code
        into l_existing_pump_code
        from at_water_user_contract
       where water_user_contract_code = l_water_user_contract_code;

      if l_existing_pump_code is not null then
         cwms_err.raise('ERROR', 'Contract already has pump associated for pump-out usage: '||cwms_loc.get_location_id(l_existing_pump_code));
      end if;
      update at_water_user_contract
         set pump_out_location_code = l_pump_location_code
       where water_user_contract_code = l_water_user_contract_code;
   when instr('BELOW', l_pump_usage_id) = 1 then
      --------------------
      -- PUMP OUT BELOW --
      --------------------
      select pump_out_below_location_code
        into l_existing_pump_code
        from at_water_user_contract
       where water_user_contract_code = l_water_user_contract_code;

      if l_existing_pump_code is not null then
         cwms_err.raise('ERROR', 'Contract already has pump associated for pump-out-below usage: '||cwms_loc.get_location_id(l_existing_pump_code));
      end if;
      update at_water_user_contract
         set pump_out_below_location_code = l_pump_location_code
       where water_user_contract_code = l_water_user_contract_code;
   else
      cwms_err.raise('ERROR', 'P_PUMP_USAGE_ID is invalid, must be one of ''IN'', ''OUT'', or ''BELOW''');
   end case;
end associate_pump;
--------------------------------------------------------------------------------
-- procedure disassociate_pump
--------------------------------------------------------------------------------
procedure disassociate_pump(
    p_water_user_contract IN water_user_contract_ref_t,
    p_pump_location_id    IN varchar2,
    p_pump_usage_id       IN varchar2,
    p_delete_acct_data    IN varchar2 default 'F')
is
   l_water_user_contract_code integer;
   l_pump_location_code       integer;
   l_existing_pump_code       integer;
   l_pump_usage_id            varchar2(8) := upper(trim(p_pump_usage_id));
begin
   select wuc.water_user_contract_code
     into l_water_user_contract_code
     from at_water_user_contract wuc,
          at_water_user wu
    where wu.project_location_code = p_water_user_contract.water_user.project_location_ref.get_location_code
      and upper(wu.entity_name) = upper(p_water_user_contract.water_user.entity_name)
      and wuc.water_user_code = wu.water_user_code
      and upper(contract_name) = upper(p_water_user_contract.contract_name);

   l_pump_location_code := cwms_loc.get_location_code(p_water_user_contract.water_user.project_location_ref.get_office_id, p_pump_location_id);

   case
   when instr('IN', l_pump_usage_id) = 1 then
      -------------
      -- PUMP IN --
      -------------
      select pump_in_location_code
        into l_existing_pump_code
        from at_water_user_contract
       where water_user_contract_code = l_water_user_contract_code;

      if l_existing_pump_code is null or l_existing_pump_code != l_pump_location_code then
         cwms_err.raise('ERROR', 'Specified pump is not associated with this contract for pump-in usage');
      end if;
      update at_water_user_contract
         set pump_in_location_code = null
       where water_user_contract_code = l_water_user_contract_code;
   when instr('OUT', l_pump_usage_id) = 1 then
      --------------
      -- PUMP OUT --
      --------------
      select pump_out_location_code
        into l_existing_pump_code
        from at_water_user_contract
       where water_user_contract_code = l_water_user_contract_code;

      if l_existing_pump_code is null or l_existing_pump_code != l_pump_location_code then
         cwms_err.raise('ERROR', 'Specified pump is not associated with this contract for pump-out usage');
      end if;
      update at_water_user_contract
         set pump_out_location_code = null
       where water_user_contract_code = l_water_user_contract_code;
   when instr('BELOW', l_pump_usage_id) = 1 then
      --------------------
      -- PUMP OUT BELOW --
      --------------------
      select pump_out_below_location_code
        into l_existing_pump_code
        from at_water_user_contract
       where water_user_contract_code = l_water_user_contract_code;

      if l_existing_pump_code is null or l_existing_pump_code != l_pump_location_code then
         cwms_err.raise('ERROR', 'Specified pump is not associated with this contract for pump-out-below usage');
      end if;
      update at_water_user_contract
         set pump_out_below_location_code = null
       where water_user_contract_code = l_water_user_contract_code;
   else
      cwms_err.raise('ERROR', 'P_PUMP_USAGE_ID is invalid, must be one of ''IN'', ''OUT'', or ''BELOW''');
   end case;
   if cwms_util.is_true(p_delete_acct_data) then
      delete
        from at_wat_usr_contract_accounting
       where water_user_contract_code = l_water_user_contract_code
         and pump_location_code = l_pump_location_code;
   end if;
end disassociate_pump;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- look up procedures.
-- returns a listing of lookup objects.
-- p_lookup_type_tab_t
-- p_db_office_id
--    defaults to the connected user's office if null
PROCEDURE get_contract_types(
	p_contract_types out lookup_type_tab_t,
	p_db_office_id   IN  VARCHAR2 DEFAULT NULL )
IS
BEGIN
   p_contract_types := lookup_type_tab_t();
   FOR rec IN (
      SELECT o.office_id,
             wct.ws_contract_type_display_value,
             wct.ws_contract_type_tooltip,
             wct.ws_contract_type_active
        FROM at_ws_contract_type wct,
             cwms_office o
       WHERE o.office_id = nvl(upper(p_db_office_id), cwms_util.user_office_id)
         AND wct.db_office_code = o.office_code)
   loop
      p_contract_types.EXTEND;
      p_contract_types(p_contract_types.count) := lookup_type_obj_t(
         rec.office_id,
         rec.ws_contract_type_display_value,
         rec.ws_contract_type_tooltip,
         rec.ws_contract_type_active);
   END loop;
END get_contract_types;
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
PROCEDURE set_contract_types(
	p_contract_types IN lookup_type_tab_t,
	p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
IS
   l_office_code    NUMBER;
   l_fail_if_exists boolean;
   l_rec            at_ws_contract_type%rowtype;
BEGIN
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   IF p_contract_types IS NOT NULL THEN
      FOR i IN 1..p_contract_types.count loop
         l_office_code := cwms_util.get_office_code(p_contract_types(i).office_id);
         BEGIN
            SELECT *
              INTO l_rec
              from at_ws_contract_type
             WHERE db_office_code in( l_office_code, cwms_util.db_office_code_all)
               AND upper(ws_contract_type_display_value) =
                   upper(p_contract_types(i).display_value);
            IF l_fail_if_exists THEN
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'WS_CONTRACT_TYPE',
                  upper(p_contract_types(i).office_id)
                  || '/'
                  || p_contract_types(i).display_value);
            IF l_rec.db_office_code = cwms_util.db_office_code_all THEN
               cwms_err.raise('ERROR', 'Cannot update CWMS-owned contract type');
            END IF;
            END IF;
            l_rec.ws_contract_type_display_value := p_contract_types(i).display_value;
            l_rec.ws_contract_type_tooltip := p_contract_types(i).tooltip;
            l_rec.ws_contract_type_active := p_contract_types(i).active;
            UPDATE at_ws_contract_type
               SET ROW = l_rec
             WHERE ws_contract_type_code = l_rec.ws_contract_type_code;
         exception
            WHEN no_data_found THEN
               l_rec.ws_contract_type_code := cwms_seq.nextval;
               l_rec.db_office_code := l_office_code;
               l_rec.ws_contract_type_display_value := p_contract_types(i).display_value;
               l_rec.ws_contract_type_tooltip := p_contract_types(i).tooltip;
               l_rec.ws_contract_type_active := p_contract_types(i).active;
               INSERT
                 INTO at_ws_contract_type
               VALUES l_rec;
         END;
      END loop;
   END IF;
END set_contract_types;
--------------------------------------------------------------------------------
-- water supply accounting
--------------------------------------------------------------------------------


PROCEDURE retrieve_accounting_set(
    -- the retrieved set of water user contract accountings
    p_accounting_set out wat_usr_contract_acct_tab_t,
    -- the water user contract ref
    p_contract_ref IN water_user_contract_ref_t,
    -- the units to return the flow as.
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
    p_row_limit IN integer DEFAULT NULL,
    -- a mask for the transfer type.
    -- if null, return all transfers.
    -- do we need this?
    p_transfer_type IN VARCHAR2 DEFAULT NULL
  )
is
    l_contract_code          NUMBER(10);
    l_project_location_code  number(10);

    l_pump_out_code number(10);
    l_pump_out_below_code number(10);
    l_pump_in_code number(10);

    l_pump_out_set wat_usr_contract_acct_tab_t;
    l_pump_out_below_set wat_usr_contract_acct_tab_t;
    l_pump_in_set wat_usr_contract_acct_tab_t;
begin

    -- null check the contract.
    IF p_contract_ref IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Contract Reference');
    END IF;

    --grab the project loc code.
    l_project_location_code :=  p_contract_ref.water_user.project_location_ref.get_location_code('F');

    -- get the contract code and pump locs
    select water_user_contract_code, pump_out_location_code, pump_out_below_location_code, pump_in_location_code
    INTO l_contract_code, l_pump_out_code, l_pump_out_below_code, l_pump_in_code
    FROM at_water_user_contract wuc,
        at_water_user wu
    WHERE wuc.water_user_code = wu.water_user_code
        AND upper(wuc.contract_name) = upper(p_contract_ref.contract_name)
        AND upper(wu.entity_name) = upper(p_contract_ref.water_user.entity_name)
        AND wu.project_location_code = l_project_location_code;

    --build the aggregate accting set
    p_accounting_set := wat_usr_contract_acct_tab_t();

    --get the pump out recs
    IF l_pump_out_code IS NOT NULL THEN
        retrieve_pump_accounting(l_pump_out_set,
            l_contract_code,
            p_contract_ref,
            l_pump_out_code,
            p_units,
            p_start_time,
            p_end_time,
            p_time_zone,
            p_start_inclusive,
            p_end_inclusive,
            p_ascending_flag,
            p_row_limit,
            p_transfer_type);
        --add the recs to the aggregate.
        FOR i IN 1..l_pump_out_set.count loop
            p_accounting_set.extend;
            p_accounting_set(p_accounting_set.count) := l_pump_out_set(i);
        end loop;
    END IF;
    --get the pump out below recs
    IF l_pump_out_below_code IS NOT NULL THEN
        retrieve_pump_accounting(l_pump_out_below_set,
            l_contract_code,
            p_contract_ref,
            l_pump_out_below_code,
            p_units,
            p_start_time,
            p_end_time,
            p_time_zone,
            p_start_inclusive,
            p_end_inclusive,
            p_ascending_flag,
            p_row_limit,
            p_transfer_type);
        --add the recs to the aggregate.
        FOR i IN 1..l_pump_out_below_set.count loop
            p_accounting_set.extend;
            p_accounting_set(p_accounting_set.count) := l_pump_out_below_set(i);
        end loop;
    END IF;
    --pump in recs...
    IF l_pump_in_code IS NOT NULL THEN
        retrieve_pump_accounting(l_pump_in_set,
            l_contract_code,
            p_contract_ref,
            l_pump_in_code,
            p_units,
            p_start_time,
            p_end_time,
            p_time_zone,
            p_start_inclusive,
            p_end_inclusive,
            p_ascending_flag,
            p_row_limit,
            p_transfer_type);
        FOR i IN 1..l_pump_in_set.count loop
            p_accounting_set.extend;
            p_accounting_set(p_accounting_set.count) := l_pump_in_set(i);
        end loop;
    END IF;

end retrieve_accounting_set;

--------------------------------------------------------------------------------
-- retrieve a water user contract accounting set.
--------------------------------------------------------------------------------
PROCEDURE retrieve_pump_accounting(
    -- the retrieved set of water user contract accountings
    p_accounting_set out wat_usr_contract_acct_tab_t,

    -- the water user contract ref
    p_contract_code in number,
    -- the water user contract ref
    p_contract_ref IN water_user_contract_ref_t,

    p_pump_loc_code IN number,

    -- the units to return the flow as.
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
    p_row_limit IN integer DEFAULT NULL,

    -- a mask for the transfer type.
    -- if null, return all transfers.
    -- do we need this?
    p_transfer_type IN VARCHAR2 DEFAULT NULL
  )
  IS
    l_pump_loc_ref    location_ref_t;
    l_unit_code              number(10);
    l_adjusted_start_time    DATE;
    l_adjusted_end_time      DATE;
    l_start_time_inclusive   boolean;
    l_end_time_inclusive     boolean;
    l_time_zone              VARCHAR2(28) := nvl(p_time_zone, 'UTC');
    l_time_zone_code         number(10);
    l_orderby_mod     NUMBER(1);

BEGIN

    -- get the out going unit code.
    select unit_code
    into l_unit_code
    from cwms_unit
    where unit_id = nvl(p_units,'cms');

    --------------------------------
    -- prepare selection criteria --
    --------------------------------
    IF p_ascending_flag IS NULL OR p_ascending_flag IN ('t','T') THEN
        --default to asc order
        l_orderby_mod := 1;
    ELSE
        -- reverse order to desc
        l_orderby_mod := -1;
    end if;

    l_start_time_inclusive := cwms_util.is_true(p_start_inclusive);
    l_end_time_inclusive   := cwms_util.is_true(p_end_inclusive);

    l_adjusted_start_time := cwms_util.change_timezone(
                     p_start_time,
                     l_time_zone,
                     'UTC');
    l_adjusted_end_time := cwms_util.change_timezone(
                     p_end_time,
                     l_time_zone,
                     'UTC');

    IF l_start_time_inclusive = FALSE THEN
       l_adjusted_start_time := l_adjusted_start_time + (1 / 86400);
    END IF;

    IF l_end_time_inclusive = FALSE THEN
       l_adjusted_end_time := l_adjusted_end_time - (1 / 86400);
    END IF;

    l_time_zone_code := cwms_util.get_time_zone_code(l_time_zone);
    l_pump_loc_ref := new location_ref_t(p_pump_loc_code);

       -- instantiate a table array to hold the output records.
    p_accounting_set := wat_usr_contract_acct_tab_t();
    ----------------------------------------
    -- select records and populate output --
    ----------------------------------------
    FOR rec IN (
        WITH ordered_wuca AS
          (SELECT
            /*+ FIRST_ROWS(100) */
            wat_usr_contract_acct_code,
            water_user_contract_code,
            pump_location_code,
            phys_trans_type_code,
            pump_flow,
            transfer_start_datetime,
            accounting_remarks
          from at_wat_usr_contract_accounting
          where water_user_contract_code = p_contract_code
          and pump_location_code = p_pump_loc_code
          AND transfer_start_datetime BETWEEN l_adjusted_start_time AND l_adjusted_end_time
           ORDER BY cwms_util.to_millis(transfer_start_datetime) * l_orderby_mod),
          limited_wuca AS
          (SELECT wat_usr_contract_acct_code,
            water_user_contract_code,
            pump_location_code,
            phys_trans_type_code,
            pump_flow,
            transfer_start_datetime,
            accounting_remarks

          FROM ordered_wuca
          WHERE ROWNUM <= nvl(p_row_limit, rownum)
          )
        SELECT limited_wuca.pump_location_code,
          limited_wuca.transfer_start_datetime,
          limited_wuca.pump_flow,
          -- u.unit_id AS units_id,
          uc.factor,
          uc.offset,
          o.office_id AS transfer_type_office_id,
          ptt.phys_trans_type_display_value,
          ptt.phys_trans_type_tooltip,
          ptt.phys_trans_type_active,
          limited_wuca.accounting_remarks
        FROM limited_wuca
        INNER JOIN at_water_user_contract wuc
        ON (limited_wuca.water_user_contract_code = wuc.water_user_contract_code)
        INNER JOIN at_physical_transfer_type ptt
        on (limited_wuca.phys_trans_type_code = ptt.phys_trans_type_code)
        INNER JOIN cwms_office o ON ptt.db_office_code in (o.office_code, cwms_util.db_office_code_all)
        inner join cwms_unit_conversion uc
        on (uc.to_unit_code = l_unit_code)
        inner join cwms_base_parameter bp
        ON (uc.from_unit_code = bp.unit_code AND bp.base_parameter_id = 'Flow')
    )
    loop
      --extend the array.
      p_accounting_set.EXTEND;

      p_accounting_set(p_accounting_set.count) := wat_usr_contract_acct_obj_t(
         --re-use arg contract ref
        p_contract_ref,
        l_pump_loc_ref,  -- the pump location
        lookup_type_obj_t(
          rec.transfer_type_office_id,
          rec.phys_trans_type_display_value,
          rec.phys_trans_type_tooltip,
          rec.phys_trans_type_active),
        rec.pump_flow * rec.factor + rec.offset,
        -- rec.units_id,
        cwms_util.change_timezone(
           rec.transfer_start_datetime,
           'UTC',
           l_time_zone),
        rec.accounting_remarks);
   END loop;
END retrieve_pump_accounting;

--------------------------------------------------------------------------------
-- store a water user contract accounting set.
--------------------------------------------------------------------------------
PROCEDURE store_accounting_set(
    -- the set of water user contract accountings to store to the database.
    p_accounting_tab IN wat_usr_contract_acct_tab_t,

    -- the contract ref for the incoming accountings.
    p_contract_ref IN water_user_contract_ref_t,

    --the following represents pump time windows where data needs to be cleared
    --out as part of the delete insert process.
    p_pump_time_window_tab loc_ref_time_window_tab_t,

    -- the time zone of all of the incoming data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,

    -- the units of the incoming accounting flow data
    p_flow_unit_id IN VARCHAR2 DEFAULT NULL,

		-- store rule, this variable is not supported.
    -- only delete insert initially supported.
    p_store_rule		IN VARCHAR2 DEFAULT NULL,

    -- if protection is to be ignored.
    -- this variable is not supported.
		p_override_prot	IN VARCHAR2 DEFAULT 'F'
    )


IS

    l_contract_name at_water_user_contract.contract_name%TYPE;
    l_entity_name at_water_user.entity_name%TYPE;
    l_project_loc_code NUMBER(10);
    l_contract_code NUMBER(10);

    l_factor         BINARY_DOUBLE;
    l_offset         BINARY_DOUBLE;
    l_time_zone      varchar2(28) := nvl(p_time_zone, 'UTC');
--    l_count number;
BEGIN

    -- check arrays for errors
    IF p_pump_time_window_tab IS NULL
    THEN
      cwms_err.raise(
      'NULL_ARGUMENT',
      'Pump Location and Time Window Array');
    END IF;

    IF p_contract_ref IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Contract Reference');
    END IF;

    l_contract_name := p_contract_ref.contract_name; -- 'WU CONTRACT 1';
    IF l_contract_name IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Contract Name');
    END IF;

    IF  p_contract_ref.water_user IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Contract Water User');
    END IF;

    l_entity_name := p_contract_ref.water_user.entity_name; -- 'KEYS WU 1';
    IF  l_entity_name IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Entity Name');
    END IF;

    IF p_contract_ref.water_user.project_location_ref IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Project Location Ref');
    END IF;

    l_project_loc_code := p_contract_ref.water_user.project_location_ref.get_location_code('F'); -- 32051;

    -- get the contract code
    SELECT wuc.water_user_contract_code
    INTO l_contract_code
    FROM at_water_user_contract wuc
    INNER JOIN at_water_user wu ON (wuc.water_user_code = wu.water_user_code)
    WHERE upper(wuc.contract_name) = upper(l_contract_name)
    AND upper(wu.entity_name) = upper(l_entity_name)
    AND wu.project_location_code = l_project_loc_code;

    -- dbms_output.put_line('wuc code: '|| l_contract_code);

    --get the offset and factor
    ----------------------------------
    -- get the unit conversion info --
    ----------------------------------
    SELECT uc.factor,
          uc.offset
     INTO l_factor,
          l_offset
     from cwms_base_parameter bp,
          cwms_unit_conversion uc,
          cwms_unit u
    WHERE bp.base_parameter_id = 'Flow'
      and uc.to_unit_code = bp.unit_code
      and uc.from_unit_code = u.unit_code
      and u.unit_id = nvl(p_flow_unit_id,'cms');

    -- dbms_output.put_line('unit conv: '|| l_factor ||', '||l_offset);

--    select count(*) into l_count from at_wat_usr_contract_accounting;
--    dbms_output.put_line('row count: '|| l_count);
    -- delete existing data
    DELETE FROM at_wat_usr_contract_accounting
    WHERE wat_usr_contract_acct_code IN (
        SELECT wuca.wat_usr_contract_acct_code acct_code
        FROM at_wat_usr_contract_accounting wuca
        INNER JOIN (
            SELECT loc_tw_tab.location_ref.get_location_code('F') loc_code,
                -- convert to utc
--                loc_tw_tab.start_date start_date,
--                loc_tw_tab.end_date end_date
                cwms_util.change_timezone(
                  loc_tw_tab.start_date,
                  l_time_zone,
                  'UTC'
                )  start_date,
                cwms_util.change_timezone(
                  loc_tw_tab.end_date ,
                  l_time_zone,
                  'UTC'
                ) end_date
            FROM TABLE (CAST (p_pump_time_window_tab AS loc_ref_time_window_tab_t)) loc_tw_tab
        ) loc_tw ON (
            wuca.pump_location_code = loc_tw.loc_code
            --wuca value is in utc.
            AND wuca.transfer_start_datetime BETWEEN loc_tw.start_date AND loc_tw.end_date
        )
        WHERE wuca.water_user_contract_code = l_contract_code
    );
--    select count(*) into l_count from at_wat_usr_contract_accounting;
--    dbms_output.put_line('row count: '|| l_count);

     -- insert new data
    INSERT INTO at_wat_usr_contract_accounting (
        wat_usr_contract_acct_code,
        water_user_contract_code,
        pump_location_code,
        phys_trans_type_code,
        pump_flow,
        transfer_start_datetime,
        accounting_remarks )

        select cwms_seq.nextval pk_code,
            l_contract_code contract_code,
            acct_tab.pump_location_ref.get_location_code('F') pump_code,
            ptt.phys_trans_type_code xfer_code,
            acct_tab.pump_flow * l_factor + l_offset flow,
            cwms_util.change_timezone(
                  acct_tab.transfer_start_datetime,
                  l_time_zone,
                  'UTC'
              ) xfer_date,
            acct_tab.accounting_remarks remarks
        from table (cast (p_accounting_tab as wat_usr_contract_acct_tab_t)) acct_tab
            left outer join cwms_office o on (o.office_id in ('CWMS', acct_tab.physical_transfer_type.office_id))
            left outer join at_physical_transfer_type ptt on (
                ptt.phys_trans_type_display_value = acct_tab.physical_transfer_type.display_value
                and ptt.db_office_code in (o.office_code, cwms_util.db_office_code_all)
            )
            left outer join at_water_user_contract wuc on (
                upper(acct_tab.water_user_contract_ref.contract_name) = upper(wuc.contract_name)
                and wuc.water_user_contract_code = l_contract_code
            )
            left outer join at_water_user wu on (
                upper(acct_tab.water_user_contract_ref.water_user.entity_name) = upper(wu.entity_name)
                and cwms_loc.get_location_code(acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id,
                      acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id
                      || substr ('-', 1, length (acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id))
                      || acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
                    ) = l_project_loc_code
                and wuc.water_user_code = wu.water_user_code
            );
        -- where wuc.water_user_code = wu.water_user_code
        -- and wuc.water_user_contract_code = l_contract_code
--        and cwms_loc.get_location_code(acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id,
--              acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id
--              || substr ('-', 1, length (acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id))
--              || acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
--            ) = l_project_loc_code
--        and upper(acct_tab.water_user_contract_ref.contract_name) = upper(wuc.contract_name)
--        AND upper(acct_tab.water_user_contract_ref.water_user.entity_name) = upper(wu.entity_name)
--        and acct_tab.physical_transfer_type.office_id = o.office_id
--        and acct_tab.physical_transfer_type.display_value = ptt.phys_trans_type_display_value
--        and ptt.db_office_code = o.office_code;

END store_accounting_set;

END cwms_water_supply;

/
show errors;
GRANT EXECUTE ON cwms_water_supply TO cwms_user;

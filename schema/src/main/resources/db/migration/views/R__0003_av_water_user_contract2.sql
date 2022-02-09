-----------------------------
-- AV_WATER_USER_CONTRACT2 --
-----------------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_WATER_USER_CONTRACT2', null,
'
/**
 * Displays information on water user contracts, including aliased locations
 *
 * @since CWMS 3.0
 *
 * @field office_id                     The office that owns the project
 * @field project_id                    The name or alias of project that the contract is for
 * @field entity_name                   The name of the water user holding the contract
 * @field water_right                   A description of the water user''s water right
 * @field contract_name                 The identifying name of the water user contract
 * @field contract_type                 The contract type
 * @field contract_storage_unit         The unit of storage for this contract
 * @field contracted_storage            The contracted storage for this contract in the contract storage unit
 * @field contract_effective_date       The date the contract enters into effect
 * @field contract_expiration_date      The date the contract expires
 * @field initial_use_allocation        Initial contracted allocation for this contract in the contract storage unit
 * @field future_use_allocation         Future contracted allocation for this contract in the contract storage unit
 * @field future_use_percent_activated  Future percent allocated for this contract
 * @field total_alloc_percent_activated Total percent allocated for this contract
 * @field contracted_storage_m3         The contracted storage for this contract in cubic meters, can be used for comparing storages between contracts
 * @field pump_out_location_id          Name or alias of location where water is withdrawn from permanent pool
 * @field pump_out_below_location_id    Name or alias of location where water is withdrawn within or below the outlet works
 * @field pump_in_location_id           Name or alias of location where water is supplied to the permanent pool
 * @field project_aliased_item          Portion of project_id that is aliased
 * @field pump_out_aliased_item         Portion of pump_out_location_id that is aliased
 * @field pump_out_below_aliased_item   Portion of pump_out_below_location_id that is aliased
 * @field pump_in_aliased_item          Portion of pump_in_location_id that is aliased
 * @field loc_alias_category            Alias category for all location identifiers
 * @field loc_alias_group               Alias group for all location identifiers
 * @field project_location_code         Database location code for the project
 * @field pump_out_location_code        Database location code for the pump out location
 * @field pump_out_below_location_code  Database location code for the pump out below location
 * @field pump_in_location_code         Database location code for the pump in location
 */
');
create or replace force view av_water_user_contract2(
   office_id,
   project_id,
   entity_name,
   water_right,
   contract_name,
   contract_type,
   contract_storage_unit,
   contracted_storage,
   contract_effective_date,
   contract_expiration_date,
   initial_use_allocation,
   future_use_allocation,
   future_use_percent_activated,
   total_alloc_percent_activated,
   contracted_storage_m3,
   pump_out_location_id,
   pump_out_below_location_id,
   pump_in_location_id,
   project_aliased_item,
   pump_out_aliased_item,
   pump_out_below_aliased_item,
   pump_in_aliased_item,
   loc_alias_category,
   loc_alias_group,
   project_location_code,
   pump_out_location_code,
   pump_out_below_location_code,
   pump_in_location_code)
as
select office_id,
       project_id,
       entity_name,
       water_right,
       contract_name,
       contract_type,
       contract_storage_unit,
       contracted_storage,
       contract_effective_date,
       contract_expiration_date,
       initial_use_allocation,
       future_use_allocation,
       future_use_percent_activated,
       total_alloc_percent_activated,
       contracted_storage_m3,
       pump_out_location_id,
       pump_out_below_location_id,
       pump_in_location_id,
       q1.aliased_item as project_aliased_item,
       q2.aliased_item as pump_out_aliased_item,
       q3.aliased_item as pump_out_below_aliased_item,
       q4.aliased_item as pump_in_aliased_item,
       q1.loc_alias_category,
       q1.loc_alias_group,
       project_location_code,
       pump_out_location_code,
       pump_out_below_location_code,
       pump_in_location_code
  from (select vl.db_office_id as office_id,
               vl.location_id as project_id,
               wu.entity_name,
               wu.water_right,
               wc.contract_name,
               wct.ws_contract_type_display_value as contract_type,
               uc.to_unit_id as contract_storage_unit,
               wc.contracted_storage * uc.factor + uc.offset as contracted_storage,
               to_char(wc.ws_contract_effective_date, 'dd-Mon-yyyy') as contract_effective_date,
               to_char(wc.ws_contract_expiration_date, 'dd-Mon-yyyy') as contract_expiration_date,
               wc.initial_use_allocation * uc.factor + uc.offset as initial_use_allocation,
               wc.future_use_allocation * uc.factor + uc.offset as future_use_allocation,
               wc.future_use_percent_activated,
               wc.total_alloc_percent_activated,
               wc.contracted_storage as contracted_storage_m3,
               vl.aliased_item,
               vl.loc_alias_category,
               vl.loc_alias_group,
               pr.project_location_code,
               wc.pump_out_location_code,
               wc.pump_out_below_location_code,
               wc.pump_in_location_code
          from at_project pr,
               at_water_user wu,
               at_water_user_contract wc,
               av_loc2 vl,
               at_ws_contract_type wct,
               cwms_office o,
               cwms_unit_conversion uc
         where vl.active_flag = 'T'
           and vl.location_code = pr.project_location_code
           and wu.project_location_code = pr.project_location_code
           and wc.water_user_code = wu.water_user_code
           and uc.from_unit_id = 'm3'
           and uc.to_unit_code = wc.storage_unit_code
           and wct.db_office_code = o.office_code
           and o.office_id = vl.db_office_id
           and wct.ws_contract_type_code = wc.water_supply_contract_type
           and vl.unit_system = 'SI'
       ) q1
       left outer join
       (select vl.location_code,
               vl.location_id as pump_out_location_id,
               vl.aliased_item,
               vl.loc_alias_category,
               vl.loc_alias_group
          from av_loc2 vl
         where vl.active_flag = 'T'
           and vl.unit_system = 'SI'
       ) q2 on q2.location_code = q1.pump_out_location_code
               and nvl(q2.loc_alias_category, '.') = nvl(q1.loc_alias_category, '.')
               and nvl(q2.loc_alias_group, '.') = nvl(q1.loc_alias_group, '.')
       left outer join
       (select vl.location_code,
               vl.location_id as pump_out_below_location_id,
               vl.aliased_item,
               vl.loc_alias_category,
               vl.loc_alias_group
          from av_loc2 vl
         where vl.active_flag = 'T'
           and vl.unit_system = 'SI'
       ) q3 on q3.location_code = q1.pump_out_below_location_code
               and nvl(q3.loc_alias_category, '.') = nvl(q1.loc_alias_category, '.')
               and nvl(q3.loc_alias_group, '.') = nvl(q1.loc_alias_group, '.')
       left outer join
       (select vl.location_code,
               vl.location_id as pump_in_location_id,
               vl.aliased_item,
               vl.loc_alias_category,
               vl.loc_alias_group
          from av_loc2 vl
         where vl.active_flag = 'T'
           and vl.unit_system = 'SI'
       ) q4 on q4.location_code = q1.pump_in_location_code
               and nvl(q4.loc_alias_category, '.') = nvl(q1.loc_alias_category, '.')
               and nvl(q4.loc_alias_group, '.') = nvl(q1.loc_alias_group, '.')
 order by 1, 2, 3, 5;



create or replace public synonym cwms_v_water_user_contract2 for av_water_user_contract2;

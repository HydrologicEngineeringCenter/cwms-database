insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TURBINE_SETTING', null,
'
/**
 * Displays information on turbine settings at CWMS projects
 *
 * @since CWMS 2.1
 *
 * @field turbine_change_code  Unique numeric value identifying turbine change
 * @field office_id            Office owning project
 * @field turbine_id           Turbine identifier
 * @field old_discharge_en     Turbine discharge in English unit before the setting
 * @field new_discharge_en     Turbine discharge in English unit after the setting
 * @field discharge_unit_en    Discharge unit in English unit system
 * @field old_discharge_si     Tturbine discharge in SI unit before the setting
 * @field new_discharge_si     Turbine discharge in SI unit after the setting
 * @field discharge_unit_si    Discharge unit in SI unit system
 * @field scheduled_load       Scheduled load for the turbine at the time of the setting, in power unit
 * @field real_power           The actual power generated at the time of the setting, in power unit
 * @field power_unit           The unit of scheduled load and real power
 */
');
create or replace force view av_turbine_setting
(
   turbine_change_code,
   office_id,
   turbine_id,
   old_discharge_en,
   new_discharge_en,
   discharge_unit_en,
   old_discharge_si,
   new_discharge_si,
   discharge_unit_si,
   scheduled_load,
   real_power,
   power_unit
)
as
select ts.turbine_change_code,
       o.office_id as office_id,
       bl.base_location_id
       ||substr('-', 1, length(pl.sub_location_id))
       ||pl.sub_location_id as turbine_id,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(ts.old_discharge, 'cms', 'cfs'), 
          '9999999999') as old_discharge_en,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(ts.new_discharge, 'cms', 'cfs'), 
          '9999999999') as new_discharge_en,
       'cfs' as discharge_unit_en,
       cwms_rounding.round_dd_f(
          ts.old_discharge, 
          '9999999999') as old_discharge_si,
       cwms_rounding.round_dd_f(
          ts.new_discharge, 
          '9999999999') as new_discharge_si,
       'cms' as discharge_unit_si,
       cwms_rounding.round_dd_f(
          ts.scheduled_load, 
          '9999999999') as scheduled_load,
       cwms_rounding.round_dd_f(
          ts.real_power, 
          '9999999999') as real_power,
      'MW' as power_unit          
  from at_turbine_setting ts,
       at_physical_location pl,
       at_base_location bl,
       cwms_office o
 where pl.location_code = ts.turbine_location_code
   and bl.base_location_code = pl.base_location_code
   and o.office_code = bl.db_office_code;
/   

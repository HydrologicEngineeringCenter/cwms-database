insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TURBINE_CHANGE', null,
'
/**
 * Displays information on changes to power turbine settings at CWMS projects
 *
 * @since CWMS 2.1
 *
 * @field turbine_change_code       Unique numeric value identifying turbine change
 * @field office_id                 Office owning project
 * @field project_id                Location identifier of project
 * @field turbine_change_date       Date/time turbine change was made
 * @field time_zone                 Time zone associated with turbine change date/time
 * @field elev_pool_en              Pool elevation in English unit at the time of the turbine change
 * @field elev_tailwater_en         Tailwater elevation in English unit at the time of the turbine change
 * @field elev_unit_en              English unit used for elevations
 * @field elev_pool_si              Pool elevation in SI unit at the time of the turbine change
 * @field elev_tailwater_si         Tailwater elevation in SI unit at the time of the turbine change
 * @field elev_unit_si              SI unit used for elevations
 * @field old_discharge_override_en Overerride of computed dicharge before the turbine change in English unit
 * @field new_discharge_override_en Overerride of computed dicharge after the turbine change in English unit
 * @field discharge_unit_en         English unit used for discharge
 * @field old_discharg_override_si  Overerride of computed dicharge before the turbine change in SI unit
 * @field new_discharge_override_si Overerride of computed dicharge after the turbine change in SI unit
 * @field discharge_unit_si         SI unit used for discharge
 * @field discharge_comp            Discharge computation used for the turbine change
 * @field discharge_comp_descr      Description of the discharge computation
 * @field setting_reason            Reason for the turbine change
 * @field release_reason_descr      Description of the setting reason
 * @field turbine_change_notes      Notes about the turbine change
 * @field protected                 Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the turbine change is protected from future updates
 */
');
create or replace force view av_turbine_change
(
   turbine_change_code,
   office_id,
   project_id,
   turbine_change_date,
   time_zone,
   elev_pool_en,
   elev_tailwater_en,
   elev_unit_en,
   elev_pool_si,
   elev_tailwater_si,
   elev_unit_si,
   old_discharge_override_en,
   new_discharge_override_en,
   discharge_unit_en,
   old_discharge_override_si,
   new_discharge_override_si,
   discharge_unit_si,
   discharge_comp,
   discharge_comp_descr,
   setting_reason,
   setting_reason_descr,
   turbine_change_notes,
   protected
)
as
select tc.turbine_change_code,
       o.office_id as office_id,
       bl.base_location_id
       ||substr('-', 1, length(pl.sub_location_id))
       ||pl.sub_location_id as project_id,
       cwms_util.change_timezone(
          tc.turbine_change_datetime, 
          'UTC', 
          cwms_loc.get_local_timezone(tc.project_location_code)) as turbine_change_date,
       cwms_loc.get_local_timezone(tc.project_location_code) as time_zone,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(tc.elev_pool, 'm', 'ft'), 
          '9999999999') as elev_pool_en,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(tc.elev_tailwater, 'm', 'ft'), 
          '9999999999') as elev_tailwater_en,
       'ft' as elev_unit_en,
       cwms_rounding.round_dd_f(tc.elev_pool, '9999999999') as elev_pool_si,
       cwms_rounding.round_dd_f(tc.elev_tailwater, '9999999999') as elev_tailwater_si,
       'm' as elev_unit_si,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(tc.old_total_discharge_override, 'cms', 'cfs'), 
          '9999999999') as old_discharge_override_en,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(tc.new_total_discharge_override, 'cms', 'cfs'), 
          '9999999999') as new_discharge_override_en,
       'cfs' as discharge_unit_en,
       cwms_rounding.round_dd_f(
          tc.old_total_discharge_override, 
          '9999999999') as old_discharge_override_si,
       cwms_rounding.round_dd_f(
          tc.new_total_discharge_override, 
          '9999999999') as new_discharge_override_si,
       'cms' as discharge_unit_si,
       tcc.turbine_comp_display_value as discharge_comp,
       tcc.turbine_comp_tooltip as discharge_comp_descr,
       tsr.turb_set_reason_display_value as setting_reason,
       tsr.turb_set_reason_tooltip as setting_reason_descr,
       tc.turbine_change_notes,
       tc.protected
  from cwms_office o,
       at_base_location bl,
       at_physical_location pl,
       at_turbine_change tc,
       at_turbine_computation_code tcc,
       at_turbine_setting_reason tsr
 where bl.db_office_code = o.office_code
   and pl.base_location_code = bl.base_location_code
   and tc.project_location_code = pl.location_code 
   and tcc.turbine_comp_code = tc.turbine_discharge_comp_code
   and tsr.turb_set_reason_code = tc.turbine_setting_reason_code;
/

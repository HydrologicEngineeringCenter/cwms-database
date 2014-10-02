insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_GATE_CHANGE', null,
'
/**
 * Displays information on changes to gate settings at CWMS projects
 *
 * @since CWMS 2.1
 *
 * @field gate_change_code          Unique numeric value identifying gate change
 * @field office_id                 Office owning project
 * @field project_id                Location identifier of project
 * @field gate_change_date          Date/time gate change was made
 * @field time_zone                 Time zone associated with gate change date/time
 * @field elev_pool_en              Pool elevation in English unit at the time of the gate change
 * @field elev_tailwater_en         Tailwater elevation in English unit at the time of the gate change
 * @field elev_unit_en              English unit used for elevations
 * @field elev_pool_si              Pool elevation in SI unit at the time of the gate change
 * @field elev_tailwater_si         Tailwater elevation in SI unit at the time of the gate change
 * @field elev_unit_si              SI unit used for elevations
 * @field old_discharge_override_en Overerride of computed dicharge before the gate change in English unit
 * @field new_discharge_override_en Overerride of computed dicharge after the gate change in English unit
 * @field discharge_unit_en         English unit used for discharge
 * @field old_discharg_override_si  Overerride of computed dicharge before the gate change in SI unit
 * @field new_discharge_override_si Overerride of computed dicharge after the gate change in SI unit
 * @field discharge_unit_si         SI unit used for discharge
 * @field discharge_comp            Discharge computation used for the gate change
 * @field discharge_comp_descr      Description of the discharge computation
 * @field release_reason            Release reason for the gate change
 * @field release_reason_descr      Description of the release reason
 * @field gate_change_notes         Notes about the gate change
 * @field protected                 Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether the gate change is protected from future updates
 */
');
create or replace force view av_gate_change
(
   gate_change_code,
   office_id,
   project_id,
   gate_change_date,
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
   old_discharg_override_si,
   new_discharge_override_si,
   discharge_unit_si,
   discharge_comp,
   discharge_comp_descr,
   release_reason,
   release_reason_descr,
   gate_change_notes,
   protected
)
as
select gc.gate_change_code,
       o.office_id as office_id,
       bl.base_location_id
       ||substr('-', 1, length(pl.sub_location_id))
       ||pl.sub_location_id as project_id,
       cwms_util.change_timezone(
          gc.gate_change_date, 
          'UTC', 
          cwms_loc.get_local_timezone(gc.project_location_code)) as gate_change_date,
       cwms_loc.get_local_timezone(gc.project_location_code) as time_zone,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(gc.elev_pool, 'm', 'ft'), 
          '9999999999') as elev_pool_en,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(gc.elev_tailwater, 'm', 'ft'), 
          '9999999999') as elev_tailwater_en,
       'ft' as elev_unit_en,
       cwms_rounding.round_dd_f(gc.elev_pool, '9999999999') as elev_pool_si,
       cwms_rounding.round_dd_f(gc.elev_tailwater, '9999999999') as elev_tailwater_si,
       'm' as elev_unit_si,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(gc.old_total_discharge_override, 'cms', 'cfs'), 
          '9999999999') as old_discharge_override_en,
       cwms_rounding.round_dd_f(
          cwms_util.convert_units(gc.new_total_discharge_override, 'cms', 'cfs'), 
          '9999999999') as new_discharge_override_en,
       'cfs' as discharge_unit_en,
       cwms_rounding.round_dd_f(
          gc.old_total_discharge_override, 
          '9999999999') as old_discharg_override_si,
       cwms_rounding.round_dd_f(
          gc.new_total_discharge_override, 
          '9999999999') as new_discharge_override_si,
       'cms' as discharge_unit_si,
       gcc.discharge_comp_display_value as discharge_comp,
       gcc.discharge_comp_tooltip as discharge_comp_descr,
       grr.release_reason_display_value as release_reason,
       grr.release_reason_tooltip as release_reason_descr,
       gc.gate_change_notes,
       gc.protected
  from cwms_office o,
       at_base_location bl,
       at_physical_location pl,
       at_gate_change gc,
       at_gate_ch_computation_code gcc,
       at_gate_release_reason_code grr
 where bl.db_office_code = o.office_code
   and pl.base_location_code = bl.base_location_code
   and gc.project_location_code = pl.location_code 
   and gcc.discharge_comp_code = gc.discharge_computation_code
   and grr.release_reason_code = gc.release_reason_code
/   

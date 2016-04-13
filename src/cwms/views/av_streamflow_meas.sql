insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAMFLOW_MEAS', null,
'
/**
 * Displays information about stream flow measurements in the database
 *
 * @field office_id                The office that owns the location of the measurement
 * @field location_id              The location of the measurement
 * @field meas_number              The serial number of the measurement
 * @field date_time_utc            The date and time the measurement was performed in UTC
 * @field date_time_local          The date and time the measurement was performed in the location''s local time zone
 * @field measurement_used         Flag (T/F) indicating if the discharge measurement is marked as used
 * @field measuring_party          The person(s) that performed the measurement
 * @field measuring_agency         The agency that performed the measurement
 * @field unit_system              The unit system (EN/SI) for this record
 * @field height_unit              The unit for the gage_height, shift_used, and delta_height fields for this record
 * @field flow_unit                The unit for the flow field for this record
 * @field temperature_unit         The unit of the air_temperature and water_temperature fields for this record
 * @field gage_height              Gage height as shown on the inside staff gage or read off the recorder inside the gage house
 * @field flow                     The computed discharge
 * @field cur_rating_num           The number of the rating used to calculate the streamflow from the gage height
 * @field shift_used               The current shift being applied to the rating
 * @field pct_diff                 The percent difference between the measurement and the rating with the shift applied
 * @field quality                  The relative quality of the measurement
 * @field delta_height             The amount the gage height changed while the measurement was being made
 * @field delta_time               The amount of time elapsed while the measurement was being made (hours)
 * @field rating_control_condition The condition of the rating control at the time of the measurement
 * @field flow_adjustment          The adjustment code for the measured discharge
 * @field remarks                  Any remarks about the rating
 * @field air_temperature          The air temperature at the location when the measurement was performed
 * @field water_temperature        The water temperature at the location when the measurement was performed
 * @field wm_comments              Comments about the rating by water management personnel
 */                                
');                                
create or replace force view av_streamflow_meas(
   office_id,
   location_id,
   meas_number,
   date_time_utc,
   date_time_local,
   measurement_used,
   measuring_party,
   measuring_agency,
   unit_system,
   height_unit,
   flow_unit,
   temperature_unit,
   gage_height,
   flow,
   cur_rating_num,
   shift_used,
   pct_diff,
   quality,
   delta_height,
   delta_time,
   rating_control_condition,
   flow_adjustment,
   remarks,
   air_temperature,
   water_temperature,
   wm_comments)
as
   select distinct
          vl.db_office_id as office_id,
          vl.location_id as location_id,
          sm.meas_number,
          sm.date_time as date_time_utc,
          cwms_util.change_timezone(sm.date_time, 'UTC', cwms_loc.get_local_timezone(sm.location_code)) as date_time_local,
          sm.used as measurement_used,
          sm.party as measuring_party,
          e.entity_name as measuring_agency,
          vdu1.unit_system,
          vdu1.unit_id as height_unit,
          vdu2.unit_id as flow_unit,
          vdu3.unit_id as temperature_unit,
          cwms_util.convert_units(sm.gage_height, 'm', vdu1.unit_id) as gage_height,
          cwms_util.convert_units(sm.flow, 'cms', vdu2.unit_id) as flow,
          sm.cur_rating_num,
          cwms_util.convert_units(sm.shift_used, 'm', vdu1.unit_id) as shift_used,
          sm.pct_diff,
          cumq.qual_name as quality,
          cwms_util.convert_units(sm.delta_height, 'm', vdu1.unit_id) as delta_height,
          sm.delta_time,
          curcc.description as rating_control_condition,
          cufa.adj_name as flow_adjustment,
          sm.remarks,
          cwms_util.convert_units(sm.air_temp, 'C', vdu3.unit_id) as air_temparature,
          cwms_util.convert_units(sm.water_temp, 'C', vdu3.unit_id) as water_temparature,
          sm.wm_comments
     from at_streamflow_meas sm,
          av_loc vl,
          av_display_units vdu1,
          av_display_units vdu2,
          av_display_units vdu3,
          at_entity e,
          cwms_usgs_flow_adj cufa,
          cwms_usgs_rating_ctrl_cond curcc,
          cwms_usgs_meas_qual cumq
    where vl.unit_system = 'EN'
      and vl.location_code = sm.location_code
      and vdu1.office_id = vl.db_office_id
      and vdu1.parameter_id = 'Stage'
      and vdu2.office_id = vl.db_office_id
      and vdu2.unit_system = vdu1.unit_system
      and vdu2.parameter_id = 'Flow'
      and vdu3.office_id = vl.db_office_id
      and vdu3.unit_system = vdu1.unit_system
      and vdu3.parameter_id = 'Temp'
      and e.entity_code (+) = sm.agency_code
      and cumq.qual_id (+) = sm.quality
      and curcc.ctrl_cond_id (+) = sm.ctrl_cond_id
      and cufa.adj_id (+) = sm.flow_adj_id;
      
create or replace public synonym cwms_v_streamflow_meas for av_streamflow_meas;      


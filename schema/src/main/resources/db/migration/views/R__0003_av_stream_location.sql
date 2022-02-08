insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAM_LOCATION', null,'
/**
 * Contains non-geographic information for streams
 *
 * @since CWMS 2.1
 
 * @field location_code           Reference to physical location
 * @field stream_location_code    Reference to stream
 * @field db_office_id            The office that owns this location in the databaes
 * @field location_id             The text identifier of the location
 * @field stream_location_id      The text identifier of the stream
 * @field bank                    The bank of the stream the location is on
 * @field unit_system             The unit system for values (EN or SI)
 * @field stage_unit              The unit of the lowest measureable stage (ft or m)
 * @field station_unit            The unit of the station values (mi or km)
 * @field area_unit               The unit of the drainage area values (mi2 or km2)
 * @field lowest_measurable_stage Lowest stage that is measurable at this stream location
 * @field station                 Station of stream at location
 * @field navigation_station      Navigation station of stream at location
 * @field published_station       Published station of stream at location
 * @field drainage_area           Total drainage area above this stream location
 * @field ungaged_area            Drainage area above this stream location and below upstream gage(s)
 */
');
create or replace force view av_stream_location(
   location_code,
   stream_location_code,
   db_office_id,
   location_id,
   stream_location_id,
   bank,
   unit_system,
   stage_unit,
   station_unit,
   area_unit,
   lowest_measurable_stage,
   station,
   navigation_station,
   published_station,
   drainage_area,
   ungaged_area)
as
   select l1.location_code,
          sl.stream_location_code,
          l1.db_office_id,
          l1.location_id,
          l2.location_id stream_location_id,
          sl.bank,
          l1.unit_system,
          case 
             when l1.unit_system = 'EN' then 'ft' 
             else 'm' 
          end as stage_unit,
          case 
             when l1.unit_system = 'EN' then 'mi' 
             else 'km' 
          end as station_unit,
          case 
             when l1.unit_system = 'EN' then 'mi2' 
             else 'km2' 
          end as area_unit,
          case
             when l1.unit_system = 'SI' then cwms_rounding.round_dd_f(lowest_measurable_stage, '4444444444')
             else cwms_rounding.round_dd_f(cwms_util.convert_units(lowest_measurable_stage, 'm', 'ft'), '4444444444')
          end as lowest_measurable_stage,
          case 
             when l1.unit_system = 'SI' then cwms_rounding.round_nn_f(station, '4444444444') 
             else cwms_rounding.round_nn_f(cwms_util.convert_units(station, 'km', 'mi'), '4444444444') 
          end as station,
          case
             when l1.unit_system = 'SI' then cwms_rounding.round_nn_f(navigation_station, '4444444444')
             else cwms_rounding.round_nn_f(cwms_util.convert_units(navigation_station, 'km', 'mi'), '4444444444')
          end as navigation_station,
          case
             when l1.unit_system = 'SI' then cwms_rounding.round_nn_f(published_station, '4444444444')
             else cwms_rounding.round_nn_f(cwms_util.convert_units(published_station, 'km', 'mi'), '4444444444')
          end as published_station,
          case 
             when l1.unit_system = 'SI' then cwms_rounding.round_dd_f(cwms_util.convert_units(drainage_area, 'm2', 'km2'), '4444444444') 
             else cwms_rounding.round_dd_f(cwms_util.convert_units(drainage_area, 'm2', 'mi2'), '4444444444') 
          end as drainage_area,
          case 
             when l1.unit_system = 'SI' then cwms_rounding.round_dd_f(cwms_util.convert_units(ungaged_area, 'm2', 'km2'), '4444444444') 
             else cwms_rounding.round_dd_f(cwms_util.convert_units(ungaged_area, 'm2', 'mi2'), '4444444444') 
          end as ungaged_area
     from at_stream_location sl,
          cwms_office o,
          cwms_v_loc l1,
          cwms_v_loc l2
    where sl.location_code = l1.location_code
      and l1.db_office_id = o.office_id
      and sl.stream_location_code = l2.location_code
      and l2.unit_system = 'SI'
/
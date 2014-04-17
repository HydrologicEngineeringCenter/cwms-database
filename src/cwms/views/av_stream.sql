insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAM', null,'
/**
 * Contains non-geographic information for streams
 *
 * @since CWMS 2.1
 
 * @field stream_location_code  References stream location.
 * @field diverting_stream_code Reference to stream this stream diverts from, if any 
 * @field receiving_stream_code Reference to stream this stream flows into, if any 
 * @field db_office_id          Office that owns the stream location
 * @field location_id           The text identifier of stream
 * @field zero_station          Specifies whether streams stationing begins upstream or downstream
 * @field average_slope         Average slope in percent over the entire length of the stream
 * @field unit_system           The unit system for station and length values (EN or SI)
 * @field unit_id               The unit for station and length values (mi or km)
 * @field stream_length         The length of this streeam
 * @field diverting_stream_id   The text identifier of the stream this stream diverts, if any 
 * @field diversion_station     The station on the diverting stream at which this stream departs
 * @field diversion_bank        The bank on the diverting stream from which this stream departs
 * @field receiving_stream_id   The text identifier of the stream this stream flows into, if any
 * @field confluence_station    The station of the recieving stream at which this stream joins
 * @field confluence_bank       The bank on the receiving stream at which this stream joins
 * @field comments              Additional comments for stream
 */
');
create or replace force view av_stream(
   stream_location_code,
   diverting_stream_code,
   receiving_stream_code,
   db_office_id,
   location_id,
   zero_station,
   average_slope,
   unit_system,
   unit_id,
   stream_length,
   diverting_stream_id,
   diversion_station,
   diversion_bank,
   receiving_stream_id,
   confluence_station,
   confluence_bank,
   comments)
as
   select stream_location_code,
          diverting_stream_code,
          receiving_stream_code,
          l1.db_office_id,
          l1.location_id,
          zero_station,
          average_slope,
          l1.unit_system,
          case 
             when l1.unit_system = 'EN' then 'mi' 
             else 'km' 
          end as unit_id,
          case 
             when l1.unit_system = 'SI' then cwms_rounding.round_dd_f(stream_length, '4444444444') 
             else cwms_rounding.round_dd_f(cwms_util.convert_units(stream_length, 'km', 'mi'), '4444444444') 
          end as stream_length,
          l2.location_id as diverting_stream_id,
          case
             when l1.unit_system = 'SI' then cwms_rounding.round_dd_f(diversion_station, '4444444444')
             else cwms_rounding.round_dd_f(cwms_util.convert_units(diversion_station, 'km', 'mi'), '4444444444')
          end as diversion_station,
          diversion_bank,
          l3.location_id as receiving_stream_id,
          case
             when l1.unit_system = 'SI' then cwms_rounding.round_dd_f(confluence_station, '4444444444')
             else cwms_rounding.round_dd_f(cwms_util.convert_units(confluence_station, 'km', 'mi'), '4444444444')
          end as confluence_station,
          confluence_bank,
          comments
     from at_stream s,
          cwms_office o,
          av_loc l1,
          av_loc l2,
          av_loc l3
    where o.office_id = l1.db_office_id
      and l1.location_code = s.stream_location_code
      and l2.location_code(+) = s.diverting_stream_code
      and l3.location_code(+) = s.receiving_stream_code
/
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_GAGE_SENSOR', null,
'
/**
 * Displays CWMS Gages
 *
 * @since CWMS 3.0                                                              
 *
 * @field office_id                The office that owns the location where the sensor''s gage resides
 * @field location_id              The location where the sensor''s gage resides
 * @field gage_id                  The text identifier of the sensor''s gage
 * @field sensor_id                The text identifier of the sensor at the gage
 * @field parameter_id             The parameter that is measured by the sensor
 * @field unit_id                  The unit that the sensor''s data is converted to at the gage
 * @field valid_range_min          The lowest value that the sensor can reliably and accurately measure, in unit_id units
 * @field valid_range_max          The greatest value that the sensor can reliably and accurately measure, in unit_id units
 * @field zero_reading_value       The datum value for the sensor
 * @field out_of_service           A flag (''T''/''F'') specifying whether this sensor is currently out of service
 * @field manufacturer             The manufacturer of the sensor
 * @field model_number             The model number of the sensor
 * @field serial_number            The serial number of the sensor
 * @field comments                 Any comments about the sensor
 * @field gage_code                The unique numeric code that identifies the sensor''s gage in the database
 * @field location_code            The unique numeric code that identifies the location where the sensor''s gage resides in the database 
 */
');
create or replace force view av_gage_sensor(
   office_id,
   location_id,
   gage_id,
   sensor_id,
   parameter_id,
   unit_id,
   valid_range_min,
   valid_range_max,
   zero_reading_value,
   out_of_service,
   manufacturer,
   model_number,
   serial_number,
   comments,
   location_code,
   gage_code)
as
   select gv.office_id,
          gv.location_id,
          gv.gage_id,
          gs.sensor_id,
          pv.parameter_id,
          cu.unit_id,
          gs.valid_range_min,
          gs.valid_range_max,
          gs.zero_reading_value,
          gs.out_of_service,
          gs.manufacturer,
          gs.model_number,
          gs.serial_number,
          gs.comments,
          gv.location_code,
          gs.gage_code
     from at_gage_sensor gs,
          av_gage gv,
          av_parameter pv,
          cwms_unit cu
    where gv.gage_code = gs.gage_code and pv.parameter_code = gs.parameter_code and cu.unit_code = gs.unit_code;
SHOW ERRORS;

create or replace public synonym cwms_v_gage_sensor for av_gage_sensor;
                                               

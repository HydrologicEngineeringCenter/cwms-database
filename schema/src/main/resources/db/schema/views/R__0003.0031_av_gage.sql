/**
 * Displays CWMS Gages
 *
 * @since CWMS 3.0
 *
 * @field office_id                The office that owns the gage''s location
 * @field location_id              The location where the gage resides
 * @field gage_id                  The text identifier of the gage at this location
 * @field gage_type_id             The text identifier of the gage type
 * @field discontinued             A flag (''T''/''F'') specifying whether the gage has been discontinued
 * @field out_of_service           A flag (''T''/''F'') specifying whether the gage is currently out of service
 * @field manufacturer             The manufacturer of the gage
 * @field model_number             The model number of the gage
 * @field serial_number            The serial number of the gage
 * @field phone_number             The telephone number of the gage if applicable
 * @field internet_address         The internet address of the gage if applicable
 * @field other_access_id          The access identifier of some other communication method of with the gage if applicable
 * @field associated_location_id   The location associated with the gage
 * @field comments                 Any comments about the gage
 * @field gage_code                The unique numeric code that identifies the gage in the database
 * @field location_code            The unique numeric code that identifies the location in the database
 * @field associated_location_code The unique numeric code that identifies the associated location in the database
 */
create or replace force view av_gage(
   office_id,
   location_id,
   gage_id,
   gage_type_id,
   discontinued,
   out_of_service,
   manufacturer,
   model_number,
   serial_number,
   phone_number,
   internet_address,
   other_access_id,
   associated_location_id,
   comments,
   gage_code,
   location_code,
   associated_location_code)
as
   select a.office_id,
          a.location_id,
          a.gage_id,
          a.gage_type_id,
          a.discontinued,
          a.out_of_service,
          a.manufacturer,
          a.model_number,
          a.serial_number,
          a.phone_number,
          a.internet_address,
          a.other_access_id,
          b.location_id as associated_location_id,
          a.comments,
          a.gage_code,
          a.location_code,
          a.associated_location_code
     from (select db_office_id as office_id,
                  location_id,
                  gage_id,
                  gage_type_id,
                  discontinued,
                  out_of_service,
                  manufacturer,
                  model_number,
                  serial_number,
                  phone_number,
                  internet_address,
                  other_access_id,
                  associated_location_code,
                  comments,
                  gage_code,
                  gage_location_code as location_code
             from at_gage ag, cwms_gage_type gt, av_loc lv
            where gt.gage_type_code = ag.gage_type_code and lv.location_code = ag.gage_location_code) a
          left outer join (select location_code, location_id from av_loc) b on b.location_code = a.associated_location_code;


create or replace public synonym cwms_v_gage for av_gage;

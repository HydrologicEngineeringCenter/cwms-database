/**
 * Displays CWMS Gage Types
 *
 * @since CWMS 3.0
 *
 * @field gage_type_code  The unique numeric code that identifies the gage type in the database
 * @field gage_type_id    The text identifier of the gage type
 * @field manually_read   A flag (''T''/''F'') specifying whether the gage type must be manually read
 * @field inquiry_method  The communication type for inquiries to the gage
 * @field transmit_method The communication_type for gage transmissions
 * @field description     A description of the gage type
 */
create or replace force view av_gage_type(
   gage_type_code,
   gage_type_id,
   manually_read,
   inquiry_method,
   transmit_method,
   description)
as
   select gage_type_code,
          gage_type_id,
          manually_read,
          gmi.method_id as inquiry_method,
          gmt.method_id as transmit_method,
          description
     from (select gage_type_code,
                  gage_type_id,
                  manually_read,
                  inquiry_method,
                  transmit_method,
                  description
             from cwms_gage_type
          ) gt
          left outer join (select method_code, method_id from cwms_gage_method) gmi on gmi.method_code = gt.inquiry_method
          left outer join (select method_code, method_id from cwms_gage_method) gmt on gmt.method_code = gt.transmit_method;


create or replace public synonym cwms_v_gage_type for av_gage_type;

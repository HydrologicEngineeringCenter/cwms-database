/**
 * Displays CWMS Gage Communication Methods
 *
 * @since CWMS 3.0
 *
 * @field method_code The unique numeric code that identifies the gage communication method in the database
 * @field method_id   The text identifier of the gage communication method
 * @field description The description of the gage communication method
 */
create or replace force view av_gage_method(
   method_code,
   method_id,
   description)
as
   select method_code,
          method_id,
          description
     from cwms_gage_method;
/


create or replace public synonym cwms_v_gage_method for av_gage_method;

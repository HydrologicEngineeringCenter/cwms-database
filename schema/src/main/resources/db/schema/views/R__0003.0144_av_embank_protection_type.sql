/**
 * Displays information about embankment types
 *
 * @field db_office_id                  The office that owns the protection type
 * @field protection_type_display_value The text name of the protection type
 * @field protection_type_tooltip       A text description of the protection type
 * @field protection_type_active        A flag (T/F) specifying whether the protection type is active
 * @field db_office_code                The numeric code of the office that owns the protection type
 * @field protection_type_code          The numeric code of the protection type
 */
create or replace force view av_embank_protection_type(
   db_office_id,
   protection_type_display_value,
   protection_type_tooltip,
   protection_type_active,
   db_office_code,
   protection_type_code)
as
   select o.office_id db_office_id,
          ept.protection_type_display_value,
          ept.protection_type_tooltip,
          ept.protection_type_active,
          ept.db_office_code db_office_code,
          ept.protection_type_code
     from at_embank_protection_type ept,
          cwms_office o
    where ept.db_office_code = o.office_code;

create or replace public synonym cwms_v_embank_protection_type for av_embank_protection_type;

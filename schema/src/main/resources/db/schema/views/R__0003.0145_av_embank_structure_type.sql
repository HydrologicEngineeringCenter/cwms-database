/**
 * Displays information about embankment types
 *
 * @field db_office_id                 The office that owns the structure type
 * @field structure_type_display_value The text name of the structure type
 * @field structure_type_tooltip       A text description of the structure type
 * @field structure_type_active        A flag (T/F) specifying whether the structure type is active
 * @field db_office_code               The numeric code of the office that owns the structure type
 * @field structure_type_code          The numeric code of the structure type
 */
create or replace force view av_embank_structure_type(
   db_office_id,
   structure_type_display_value,
   structure_type_tooltip,
   structure_type_active,
   db_office_code,
   structure_type_code)
as
   select o.office_id db_office_id,
          ept.structure_type_display_value,
          ept.structure_type_tooltip,
          ept.structure_type_active,
          ept.db_office_code db_office_code,
          ept.structure_type_code
     from at_embank_structure_type ept, cwms_office o
    where ept.db_office_code = o.office_code;

create or replace public synonym cwms_v_embank_structure_type for av_embank_structure_type;

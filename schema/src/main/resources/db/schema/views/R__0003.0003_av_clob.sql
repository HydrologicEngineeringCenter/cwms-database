/**
 * Displays information about CLOBs in the database
 *
 * @field clob_code   Unique reference code for this CLOB
 * @field office_code Reference to CWMS office
 * @field id          Unique record identifier, may use hierarchical "/dir/subdir/.../file" format
 * @field description Description of this CLOB
 * @field value       The CLOB data
 */
create or replace force view av_clob(
   clob_code,
   office_code,
   id,
   description,
   value)
as
   select "CLOB_CODE",
          "OFFICE_CODE",
          "ID",
          "DESCRIPTION",
          "VALUE"
     from at_clob;

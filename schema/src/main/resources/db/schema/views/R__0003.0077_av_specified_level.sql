/**
 * Displays information about CWMS Specified Levels
 *
 * @field specified_level_code The primary key of the AT_SPECIFIED_LEVEL table
 * @field office_id            The office that owns the specified level.  Levels owned by ''CWMS'' are available to all offices.
 * @field specified_level_id   The specified level
 * @field description          Describes the specified level
 *
 * @see view av_specified_level_ui
 */
create or replace force view av_specified_level(
   specified_level_code,
   office_id,
   specified_level_id,
   description)
as
   select sl.specified_level_code,
          co.office_id,
          sl.specified_level_id,
          sl.description
     from cwms_office co, at_specified_level sl
    where co.office_code = sl.office_code;

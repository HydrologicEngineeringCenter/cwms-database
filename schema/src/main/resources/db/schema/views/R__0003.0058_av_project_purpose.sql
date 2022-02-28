/**
 * Displays information on purposes for specific projects
 *
 * @since CWMS 2.1
 *
 * @field project_location_code  The foreign key to the project this purpose relates to. This key found in AT_PROJECT
 * @field project_purpose_code   The foreign key to the project purpose.  This key is found in AT_PROJECT_PURPOSES
 * @field purpose_type           The purpose type.  Either OPERATIONAL or AUTHORIZED
 * @field additional_notes       Any additional notes pertinent to this project purpose
 */
create or replace force view av_project_purpose(
   project_location_code,
   project_purpose_code,
   office_id,
   project_id,
   purpose_display_value,
   purpose_type,
   additional_notes)
as
   select project_location_code,
          project_purpose_code,
          db_office_id as office_id,
          location_id as project_id,
          purpose_display_value,
          purpose_type,
          additional_notes
     from at_project_purpose pp,
          at_project_purposes pps,
          av_loc l
    where l.location_code = pp.project_location_code
      and pps.purpose_code = pp.project_purpose_code


/
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_PROJECT_PURPOSES_UI', null,'
/**
 * Displays information on purposes that can be associated with projects
 *
 * @since CWMS 2.1
 *
 * @field office_id              The office for which the project purpose applies.  All offices can apply project purposes owned by the CWMS office. 
 * @field purpose_code           Identifying key for the project purpose
 * @field purpose_display_value  The descriptive text to display for the project purpose
 * @field purpose_tooltip        The tooltip or short description of the project purpose 
 * @field purpose_active         Flag (T/F) specifying whether the project purpose is active
 * @field purpose_nid_code       National Inventory of Dams code for this purpose
 */
');
create or replace force view av_project_purposes_ui(
   office_id,
   purpose_code,
   purpose_display_value,
   purpose_tooltip,
   purpose_active,
   purpose_nid_code)
as
     select co.office_id,
            pp.purpose_code,
            pp.purpose_display_value,
            pp.purpose_tooltip,
            pp.purpose_active,
            pp.purpose_nid_code
       from cwms_office co, 
            at_project_purposes pp
      where pp.db_office_code in (co.office_code, 53)
   order by office_code, purpose_display_value
/
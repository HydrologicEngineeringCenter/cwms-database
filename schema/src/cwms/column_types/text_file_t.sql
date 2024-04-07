create or replace type text_file_t
/**
 * Holds a text-based file object
 *
 * @member the_text The text content of the file
 */
under file_t (
   the_text clob,
   
   constructor function text_file_t(filename varchar2, media_type varchar2, quality_code integer, the_text clob)
      return self as result,
 
   overriding map member function to_string
      return varchar2,

   overriding member procedure validate_obj
)
final;
/

show errors;

create or replace type text_file_tab_t as table of text_file_t;
/

show errors;

create or replace public synonym cwms_t_text_file for test_file_t;
create or replace public synonym cwms_t_text_file_tab for test_file_tab_t;
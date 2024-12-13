create or replace type blob_file_t
/**
 * Holds a blob-based file object
 *
 * @member the_blob The blob content of the file
 */
under file_t (
   the_blob blob,

   constructor function blob_file_t(filename varchar2, media_type varchar2, quality_code integer, description varchar2, the_blob blob)
      return self as result,

   constructor function blob_file_t(filename varchar2, media_type varchar2, quality_code integer, the_blob blob)
      return self as result,

   overriding map member function to_string
      return varchar2,

   overriding member procedure validate_obj
)
final;
/

show errors;

create or replace type blob_file_tab_t as table of blob_file_t;
/

show errors;

create or replace public synonym cwms_t_blob_file for blob_file_t;
create or replace public synonym cwms_t_blob_file_tab for blob_file_tab_t;
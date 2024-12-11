create or replace type file_t
/**
 * Base of any stored file type (blob or clob)
 *
 * @member filename        Name of file (extension should be consistent with media tye)
 * @member media_type      Media type string for file content
 * @member data_entry_date Date/time the file was stored
 * @member quality_code    Value in CWMS_DATA_QUALITY table
 * @member description     Description of file content
 */
as object (
   filename        varchar2(256),
   media_type      varchar2(256),
   data_entry_date timestamp with time zone,
   quality_code    number(14),
   description     varchar2(4000),
   
   map member function to_string
      return varchar2,

   member procedure validate_obj
)
not final
not instantiable;
/

show errors;

create or replace public synonym cwms_t_file for file_t;
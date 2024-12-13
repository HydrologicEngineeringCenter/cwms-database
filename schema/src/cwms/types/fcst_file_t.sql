create or replace type fcst_file_t
/**
 * Holds a forecast file
 *
 * @member file_name   The base name (no directories) of the file - must have a file extension
 * @member description A description of the file contents
 * @member file_data   The file contents
 *
 * @see type fcst_file_tab_t
 */
as object(
   file_name   varchar2(64),
   description varchar2(64),
   file_data   blob
);
/

create or replace public synonym cwms_t_fcst_file for fcst_file_t;

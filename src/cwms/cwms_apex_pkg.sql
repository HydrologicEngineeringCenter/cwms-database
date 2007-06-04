/* Formatted on 2007/06/01 09:45 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_20.cwms_apex
AS
/******************************************************************************
   NAME:       cwms_apex
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        3/23/2007             1. Created this package.
******************************************************************************/-- Utility functions --{{{
   PROCEDURE parse_textarea (                                           --{{{
      -- Parse a HTML textarea element into the specified HTML DB collection
      -- The c001 element from the collection is used
      -- The parser splits the text into tokens delimited by newlines, spaces
      -- and commas
      p_textarea          IN   VARCHAR2,
      p_collection_name   IN   VARCHAR2
   );                                                                   --}}}

   PROCEDURE parse_file (                                               --{{{
      -- Generic procedure to parse an uploaded CSV file into the...
      -- specified collection. The first line in the file is expected...
      -- to contain the column headings, these are set in session state...
      -- for the specified headings item.
      p_file_name               IN       VARCHAR2,
      p_collection_name         IN       VARCHAR2,
      p_error_collection_name   IN       VARCHAR2,
      p_headings_item           IN       VARCHAR2,
      p_columns_item            IN       VARCHAR2,
      p_ddl_item                IN       VARCHAR2,
      p_number_of_records       OUT      NUMBER,
      p_table_name              IN       VARCHAR2 DEFAULT NULL
   );

   --}}}
   FUNCTION get_equal_predicate (
      p_column_id         IN   VARCHAR2,
      p_expr_string       IN   VARCHAR2,
      p_expr_value        IN   VARCHAR2,
      p_expr_value_test   IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_primary_db_office_id
      RETURN VARCHAR2;

   PROCEDURE store_parsed_crit_file (
      p_parsed_collection_name      IN   VARCHAR2,
      p_store_err_collection_name   IN   VARCHAR2,
      p_loc_group_id                IN   VARCHAR2,
      p_data_stream_id              IN   VARCHAR2,
      p_db_office_id                IN   VARCHAR2 DEFAULT NULL
   );
      PROCEDURE aa1 (p_string IN VARCHAR2);
END cwms_apex;
/
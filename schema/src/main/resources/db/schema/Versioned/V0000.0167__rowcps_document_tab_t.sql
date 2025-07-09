CREATE TYPE document_tab_t
/**
 * Holds a collection of document identifiers
 *
 * @see type document_obj_t
 */
IS
  TABLE OF document_obj_t;
/


create or replace public synonym cwms_t_document_tab for document_tab_t;


CREATE TYPE document_obj_t
/**
 * Holds a document identifier
 *
 * @see type document_tab_t
 *
 * @member office_id   The office that owns the document
 * @member document_id The document identifier
 */
AS
  OBJECT
  (
    office_id   VARCHAR2 (16),    -- the office id for this lookup type
    document_id VARCHAR2(64 BYTE) -- The unique identifier for the individual document, user provided
  );
/


create or replace public synonym cwms_t_document_obj for document_obj_t;


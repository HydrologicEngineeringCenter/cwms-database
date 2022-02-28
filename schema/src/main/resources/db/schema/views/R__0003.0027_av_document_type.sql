/**
 * Displays information about documents types in the database
 * *
 * @field db_office_id                The text identifier of the office that owns the document type
 * @field document_type_code          The unique numeric value that identifies the document type in the database
 * @field db_office_code              The foreign key to the office that owns the document
 * @field document_type_display_value The value to display for the document type
 * @field document_type_tooltop       The tooltip or meaning of the document type
 * @field document_type_active        Whether this document type is currently active
 */
create or replace force view av_document_type(
   db_office_id,
   document_type_code,
   db_office_code,
   document_type_display_value,
   document_type_tooltip,
   document_type_active)
as
   (select o.office_id db_office_id,
           dt."DOCUMENT_TYPE_CODE",
           dt."DB_OFFICE_CODE",
           dt."DOCUMENT_TYPE_DISPLAY_VALUE",
           dt."DOCUMENT_TYPE_TOOLTIP",
           dt."DOCUMENT_TYPE_ACTIVE"
      from at_document_type dt, cwms_office o
     where dt.db_office_code = o.office_code);

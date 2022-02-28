/**
 * Displays information about documents in the database
 *
 * @field db_office_id           The text identfier of the office that owns the document
 * @field base_location_id       The base location identifier of the location that owns the document
 * @field sub_location_id        The sub-location identifier of the location that owns the document
 * @field location_id            The full location identifier of the location that owns the document
 * @field document_code          The unique numeric value that identifies the document in the database
 * @field db_office_code         The foriegn key to the office that owns the document
 * @field document_id            The text identifier of the document.  Must be unique for within an office
 * @field document_type_code     The foreign key to the document type lookup table
 * @field document_location_code The foriegn key to the location that owns the document
 * @field document_url           The URL where the document can be found
 * @field document_date          The initial date of the document
 * @field document_mod_date      The last modified date of the document
 * @field document_obsolete_date The date the document becomes/became obsolete
 * @field document_preview_code  The foreign key to a clob of preview text
 * @field stored_document        The foreign key to at_blob/at_clob that stores the document
 * @field document_type_id       The document type of the document
 */
create or replace force view av_document(
   db_office_id,
   base_location_id,
   sub_location_id,
   location_id,
   document_code,
   db_office_code,
   document_id,
   document_type_code,
   document_location_code,
   document_url,
   document_date,
   document_mod_date,
   document_obsolete_date,
   document_preview_code,
   stored_document,
   document_type_id)
as
   select o.office_id db_office_id,
          l.base_location_id,
          l.sub_location_id,
          l.location_id,
          d."DOCUMENT_CODE",
          d."DB_OFFICE_CODE",
          d."DOCUMENT_ID",
          d."DOCUMENT_TYPE_CODE",
          d."DOCUMENT_LOCATION_CODE",
          d."DOCUMENT_URL",
          d."DOCUMENT_DATE",
          d."DOCUMENT_MOD_DATE",
          d."DOCUMENT_OBSOLETE_DATE",
          d."DOCUMENT_PREVIEW_CODE",
          d."STORED_DOCUMENT",
          dt.document_type_display_value document_type_id
     from at_document d,
          cwms_office o,
          at_document_type dt,
          cwms_v_loc l
    where d.db_office_code = o.office_code
      and d.document_type_code = dt.document_type_code
      and d.document_location_code = l.location_code
      and l.unit_system = 'EN';

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_CWMS_MEDIA_TYPE', null,
'
/**
 * Displays information about internet media types (MIME types) in the database
 * *
 * @field media_type_code The unique numeric value that identifies the media type in the database
 * @field media_type_id   The text identifier of the media type
 */
');
create or replace force view av_cwms_media_type(
   media_type_code,
   media_type_id)
as
   select "MEDIA_TYPE_CODE", "MEDIA_TYPE_ID" from cwms_media_type;


CREATE OR REPLACE PROCEDURE CWMS_20.download_file (
   p_document_code   IN av_document.document_code%TYPE,
   p_db_Office_id    IN av_document.db_Office_id%TYPE DEFAULT CWMS_UTIL.USER_OFFICE_ID)
IS
BEGIN
   cwms_doc.p_download_file (p_document_code, p_db_Office_id);
   
--   htp.p('Hi Jeremy');
   
   
END download_file;
/

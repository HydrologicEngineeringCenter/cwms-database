CREATE OR REPLACE package CWMS_20.CWMS_DOC
/**
 * Routines to work with CWMS documents
 *
 * @author Jeremy Kellett
 *
 * @since CWMS 2.1
 */
AS
/* ****************************************************************************
   NAME:       CWMS_DOC
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.1        3/20/2014   u4rt9jdk         1. Created this package.
   1.2        08APR2014     JEREMY         1. Modified package per MP requests to add javadoc commenting and put the db_office_id last with a default of cwms_util.user_office_id
******************************************************************************/
   /**
    * Converts a blob to a clob
    *
    * @param p_blob is a blob
    *
    *
    * @return a clob
   */
FUNCTION f_blob_to_clob (f_blob IN BLOB) RETURN CLOB;

   /**
    * Deletes a document
    *
    * @param p_document_id is the document id to delete.
    * @param p_db_office_id is the
    *
   */

  PROCEDURE delete_document(p_document_id          IN av_document.document_id%TYPE
                           , p_db_Office_id         IN av_document.db_Office_id%TYPE DEFAULT CWMS_UTIL.USER_OFFICE_ID
                           );

   /**
    * Downloads a document via URL
    *
    * @param p_document_code is the document code to delete.
    * @param p_db_office_id is the
    *
   */

  PROCEDURE p_download_file(p_document_code           IN av_document.document_code%TYPE
                        , p_db_Office_id            IN av_document.db_Office_id%TYPE 
                         );

     /**
    * Downloads a document via URL
    *
    * @param p_document_code is the document code to delete.
    * @param p_db_office_id is the
    *
   */


  PROCEDURE load_document( p_document_id             IN av_document.document_id%TYPE
                           ,p_document_Type_code      IN av_document.document_Type_code%TYPE
                           ,p_document_location_code  IN av_document.document_location_code%TYPE
                           ,p_document_URL            IN av_document.document_URL%TYPE
                           ,p_document_date           IN av_document.document_date%TYPE
                           ,p_document_mod_date       IN av_document.document_mod_date%TYPE
                           ,p_document_obsolete_date  IN av_document.document_obsolete_date%TYPE
                           ,p_document_Preview_code   IN av_document.document_Preview_code%TYPE
                           --,p_stored_document         IN at_document.stored_document%TYPE
                           ,p_blob                    IN BLOB
                           ,p_media_type_id           IN cwms_media_type.media_type_id%TYPE
                           ,p_submit_file_rule        IN NUMBER
                           ,p_sync_index_tf           IN VARCHAR2 DEFAULT 'T'
                           ,p_db_office_id            IN av_document.db_office_id%TYPE DEFAULT CWMS_UTIL.USER_OFFICE_ID
                            );


   /**
    * Daily syncronizing of the indexes
    *
    * @param p_index_name is the index name of the index to sync/optimize. Leaving this blank will sync AND optimize ALL indexes
    * @param p_sync_or_optimize is the string SYNC or OPTIMIZE or ALL.
    *
   */
PROCEDURE Daily_Sync(p_index_name       IN all_indexes.index_name%TYPE DEFAULT 'ALL'
                    ,p_sync_or_optimize IN VARCHAR2 DEFAULT 'ALL');

--  PROCEDURE delete_document (p_db_Office_id           IN at

END CWMS_DOC;
/

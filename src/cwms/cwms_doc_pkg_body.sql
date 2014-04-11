CREATE OR REPLACE PACKAGE BODY CWMS_20.CWMS_DOC AS
/******************************************************************************
   NAME:       CWMS_DOC
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        3/20/2014   u4rt9jdk         1. Created this package.
******************************************************************************/
FUNCTION f_blob_to_clob (f_blob IN BLOB) RETURN CLOB
AS
     v_clob    CLOB;
     v_varchar VARCHAR2(32767);
     v_start   PLS_INTEGER := 1;
     v_buffer  PLS_INTEGER := 32767;
BEGIN
     DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);
     
     FOR i IN 1..CEIL(DBMS_LOB.GETLENGTH(f_blob) / v_buffer)
     LOOP
          
        v_varchar := UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(f_blob, v_buffer, v_start));

           DBMS_LOB.WRITEAPPEND(v_clob, LENGTH(v_varchar), v_varchar);

          v_start := v_start + v_buffer;
     END LOOP;
     
   RETURN v_clob;
  
END f_blob_to_clob;
  PROCEDURE delete_document(p_document_id          IN av_document.document_id%TYPE
                           ,p_db_Office_id         IN av_document.db_Office_id%TYPE DEFAULT CWMS_UTIL.USER_OFFICE_ID 
                           ) IS
  
  temp_office_code          av_office.office_code%TYPE;
  temp_document_id          av_document.document_id%TYPE DEFAULT UPPER(p_document_id);
  
  
  BEGIN 
        
    SELECT office_code
      INTO temp_office_code
      FROM av_office
     WHERE office_id = p_db_office_id
       ;
    
    FOR x IN (SELECT *
                FROM at_document
               WHERE db_office_code       = temp_office_code
                 AND UPPER(document_id)   = temp_document_id
             ) LOOP
             
                 DELETE at_document
                     WHERE db_office_code       = temp_office_code
                       AND UPPER(document_id)   = temp_document_id
                       ;

                    DELETE at_blob 
                     WHERE blob_code = x.stored_document;
                       
                    DELETE at_clob
                       WHERE clob_code = x.stored_document; 
                END LOOP;                         
    

    
  END;

  PROCEDURE download_file(p_document_code           IN av_document.document_code%TYPE
                         ,p_db_Office_id            IN av_document.db_Office_id%TYPE DEFAULT CWMS_UTIL.USER_OFFICE_ID 
                         ) IS

  
  
  
 v_mime         VARCHAR2(48);
 v_length       NUMBER;
 v_file_name    VARCHAR2(2000);
 Lob_loc        CLOB;
  BEGIN

        SELECT mt.media_type_id mime_type
             , c.value -- blob_conten
             , d.document_id --file_nam
             , DBMS_LOB.GETLENGTH(c.value)
          INTO v_mime
              ,lob_loc
              ,v_file_name
              ,v_length
          FROM av_document   d
             , av_clob       c
             , av_cwms_media_type mt
         WHERE d.stored_document    = c.clob_code
           AND d.document_type_code = mt.media_type_code
           AND d.document_code      = p_document_code
           AND d.db_office_id       = p_db_office_id;
            --
              -- set up HTTP header
              --
            -- use an NVL around the mime type and 
            -- if it is a null set it to application/octect
            -- application/octect may launch a download window from windows
            owa_util.mime_header( nvl(v_mime,'application/octet'), FALSE );
 
        -- set the size so the browser knows how much to download
        htp.p('Content-length: ' || v_length);
        -- the filename will be used by the browser if the users does a save as
        htp.p('Content-Disposition:  attachment; filename="'||replace(replace(substr(v_file_name,instr(v_file_name,'/')+1),chr(10),null),chr(13),null)|| '"');
        -- close the headers            
        owa_util.http_header_close;
        -- download the BLOB
        wpg_docload.download_file( Lob_loc );
   
  END;
  PROCEDURE Load_Document(p_document_id             IN av_document.document_id%TYPE
                           ,p_document_Type_code      IN av_document.document_Type_code%TYPE
                           ,p_document_location_code  IN av_document.document_location_code%TYPE
                           ,p_document_URL            IN av_document.document_URL%TYPE
                           ,p_document_date           IN av_document.document_date%TYPE
                           ,p_document_mod_date       IN av_document.document_mod_date%TYPE
                           ,p_document_obsolete_date  IN av_document.document_obsolete_date%TYPE
                           ,p_document_Preview_code   IN av_document.document_Preview_code%TYPE
                           --,p_stored_document         IN at_document.stored_document%TYPE
                           ,p_blob                    IN BLOB
                           ,p_media_type_id           IN cwms_media_type.media_type_id%TYPE          --mime type
                           ,p_submit_file_rule        IN NUMBER           --"1= Overwrite" or "2= Add New"
                           ,p_sync_index_tf           IN VARCHAR2 DEFAULT 'T'
                           ,p_db_office_id             IN av_document.db_office_id%TYPE DEFAULT  CWMS_UTIL.USER_OFFICE_ID
                        )IS
                        
  temp_document_code    NUMBER                          DEFAULT CWMS_SEQ.nextval;
  temp_lob_id           NUMBER                          DEFAULT CWMS_SEQ.nextval;
  temp_media_type_code  cwms_media_type.media_type_code%TYPE    DEFAULT 0;
  temp_document_date    av_document.document_date%TYPE      DEFAULT p_document_date;
  temp_document_id      av_document.document_id%TYPE        DEFAULT UPPER(p_document_id);
  
  bad_submit_file_rule   EXCEPTION;
  
  temp_office_code      av_document.db_office_code%TYPE;
  
  temp_num              NUMBER DEFAULT 0;
  temp_locatioN_id      av_loc.location_id%TYPE;
  temp_lob_name         av_clob.id%TYPE;
  
  BEGIN
  

  BEGIN
  SELECT media_type_code
    INTO temp_media_type_code
    FROM cwms_media_type
   WHERE media_type_id = p_media_type_id;
  EXCEPTION
   WHEN no_data_found THEN
    temp_media_type_code := 0;
  END;
  
  SELECT office_code 
    INTO temp_office_code
    FROM av_office
   WHERE office_id = p_db_office_id;
  
 
  
  SELECT location_id
    INTO temp_locatioN_id
    FROM av_loc
   WHERE db_Office_id = p_db_office_id
     AND unit_system  = 'EN'
     AND location_code = p_document_locatioN_code;

  CASE p_submit_file_rule
   WHEN 1 THEN --overwrite if exists


    FOR x IN (SELECT document_id
                   , db_Office_id
                FROM av_document
               WHERE db_office_id   = p_db_office_id
                 AND document_id    = UPPER(p_document_id)
              ) LOOP
        
                    delete_document(p_db_Office_id      =>  x.db_Office_id   -- IN av_document.db_Office_id%TYPE
                                   ,p_document_id       =>  x.document_id  --  IN av_document.document_id%TYPE
                                   );
    
                 END LOOP;

 NULL;

    ELSE
    
    temp_document_date := SYSDATE;
   
    
    
    SELECT COUNT(document_id) 
      INTO temp_num
      FROM av_document
     WHERE db_office_code     = temp_office_code
       AND SUBSTR(UPPER(document_id),1, LENGTH(p_document_id)) = temp_document_id;
      
       IF temp_Num = 0 THEN
            --first record, do nothing
            NULL;
       ELSE
        
           temp_document_id := SUBSTR(temp_document_id, 1, 60) || ' ' || LPAD(TO_CHAR(temp_num),3,'0');
           
       END IF;
    
  
  
  END CASE;


      temp_document_id := UPPER(temp_document_id);

      temp_lob_name := temp_locatioN_id || ' - ' || temp_document_id;




        INSERT INTO at_blob (blob_code
                        ,office_code
                        ,id
                        ,description
                        ,media_Type_code
                        ,value  
                        ) VALUES
                        (temp_lob_id
                        ,temp_office_code
                        ,temp_lob_name
                        ,temp_document_id
                        , 0 --media_type_code
                        ,p_blob
                        );
 
   FOR x IN (SELECT *
               FROM cwms_media_type
              WHERE media_type_id       = p_media_type_id
                AND media_type_clob_tf  = 'T'
             ) LOOP
                --if a clob_tf = t record exists, also create a CLOB of this rector
            
                    
                    INSERT INTO at_clob (clob_code,office_code,id,description,value)
                                    VALUES
                                        (temp_lob_id
                                        ,temp_office_code
                                        ,temp_lob_name
                                        ,temp_document_id, f_blob_to_clob (p_blob)
                                        );
    
              END LOOP;
   
   INSERT INTO at_document (document_code
                           ,db_office_code
                           ,document_id
                           ,document_Type_code
                           ,document_location_code
                           ,document_URL
                           ,document_date
                           ,document_mod_date  
                           ,document_obsolete_date
                           ,document_Preview_code
                           ,stored_document)
                           VALUES
                           (temp_document_code       --document_code
                           ,temp_office_code         --db_office_code
                           ,temp_document_id         --document_id
                           ,p_document_Type_code     --document_Type_code
                           ,p_document_location_code --document_location_code
                           ,p_document_URL           --document_URL
                           ,temp_document_date       --document_date
                           ,p_document_mod_date      --document_mod_date  
                           ,p_document_obsolete_date --document_obsolete_date
                           ,p_document_Preview_code  --document_Preview_code
                           ,temp_lob_id              --stored_documen
                           );   
   
  IF p_sync_index_tf = 'T' THEN
    ctx_ddl.sync_index('AT_CLOB_CIDX');
  END IF;
  
  
  
  
  END;


PROCEDURE Daily_Sync(p_index_name       IN all_indexes.index_name%TYPE DEFAULT 'ALL'
                    ,p_sync_or_optimize IN VARCHAR2 DEFAULT 'ALL') IS

BEGIN

-- ctx_ddl.sync_index('AT_CLOB_CIDX');
-- ctx_ddl.OPTIMIZE_INDEX('AT_CLOB_CIDX','FULL');
 
 
 FOR x IN (SELECT * 
             FROM all_indexes
            WHERE ityp_owner = 'CTXSYS'
              AND ityp_name  = 'CONTEXT'
              AND CASE 
                   WHEN p_index_name = 'ALL' THEN 'Hi Art' ELSE index_name END
                  =
                   CASE 
                   WHEN p_index_name = 'ALL' THEN 'Hi Art' ELSE p_index_name END
           ) LOOP
                 
                 IF p_sync_or_optimize IN ('ALL','SYNC') THEN
                  ctx_ddl.sync_index(x.index_name);
                 END IF;
                 IF p_sync_or_optimize IN ('OPTIMIZE','SYNC') THEN 
                     ctx_ddl.OPTIMIZE_INDEX(x.index_name,'FULL');
                 END IF;

             END LOOP;
 
END;


END CWMS_DOC;
/
show errors

-- run this once as sys
-- change dir to whatever dir holds the rating data.
--create or replace directory rating_data as 'C:/depots/rowcps/java/dev/Data/test/unit/src/resources/valid/rating';
--grant read on directory rating_data to cwms_dev;
--commit;

DECLARE
    dest_clob   clob;
    src_file    BFILE;
    dst_offset  number := 1 ;
    src_offset  number := 1 ;
    lang_ctx    number := DBMS_LOB.DEFAULT_LANG_CTX;
    warning     number;
begin
    --get to the src file
    src_file := bfilename('RATING_DATA','Ratings.xml');
    --open the src data
    dbms_lob.open(src_file, dbms_lob.lob_readonly);
    
    --create a temp clob for rating data.
    dbms_lob.createtemporary(
      dest_clob,
      true,
      dbms_lob.session);
      
    -- load file into the clob
    DBMS_LOB.LoadCLOBFromFile(
          DEST_LOB     => dest_clob
        , SRC_BFILE    => src_file
        , AMOUNT       => DBMS_LOB.GETLENGTH(src_file)
        , DEST_OFFSET  => dst_offset
        , SRC_OFFSET   => src_offset
        , BFILE_CSID   => DBMS_LOB.DEFAULT_CSID
        , lang_context => lang_ctx
        , WARNING      => warning
    );
    
    --store rating clob
    cwms_rating.store_ratings_xml(dest_clob,'F');
    
    -- free clob
    dbms_lob.FREETEMPORARY(dest_clob);
    
    -- close file
    dbms_lob.close(src_file);
    
    COMMIT;
end;
/
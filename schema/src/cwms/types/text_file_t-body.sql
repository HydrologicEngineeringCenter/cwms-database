create or replace type body text_file_t as
 
   /**
    * Constructor
    *
    * @param filename     The name of the file object - extension must be valid for media type
    * @param media_type   The media type code - must be a valid text media type
    * @param quality_code A QUALTITY_CODE value from CWMS_DATA_QUALITY table
    * @param the_text     The text content of the file
    * @return             The and validated constructed objecct
    */
   constructor function text_file_t(filename varchar2, media_type varchar2, quality_code integer, the_text clob)
      return self as result
   is
   begin
      self.filename := filename;
      self.media_type := media_type;
      self.quality_code := nvl(quality_code, 0);
      self.data_entry_date := systimestamp; -- CWMS systems must run in UTC
      self.the_text := the_text;
      validate_obj;
      return;
   end text_file_t;

   /**
    * Returns a text representation of the object
    */
   overriding map member function to_string
      return varchar2
   is
      l_text varchar2(32767);
   begin
      l_text := '{"text_file_t": {'
      ||'"fileName": "'||self.filename||'"'
      ||', "size": '||case when self.the_text is null then 0 else dbms_lob.getlength(self.the_text) end
      ||', "mediaType": "'||self.media_type||'"'
      ||', "storedOn": "'||to_char(self.data_entry_date, 'yyyy-mm-dd"T"hh24:mi:dd:ss"Z"')||'"'
      ||', "qualityCode": '||cwms_ts.normalize_quality(self.quality_code)
      || '}}';
      return l_text;
   end to_string;

   /**
    * Validates the file extension, media type and quality code
    */
   overriding member procedure validate_obj
   is
      l_media_type varchar2(256);
      l_file_ext   varchar2(16);
      l_code       integer;
      l_flag       varchar2(1);
      l_pos        integer;
   begin
      -----------------------
      -- valid media type? --
      -----------------------
      l_media_type := lower(substr(self.media_type, 1, length(self.media_type) - instr(self.media_type, ';')));
      begin
         select media_type_code,
                media_type_clob_tf
           into l_code,
                l_flag
           from cwms_media_type
          where media_type_id = l_media_type;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', l_media_type, 'media type');
      end;
      if l_flag = 'F' then
         cwms_err.raise('INVALID_ITEM', l_media_type, 'text media type');
      end if;
      ---------------------
      -- valid file ext? --
      ---------------------
      l_pos := instr(self.filename, '.', -1);
      if l_pos > 0 then
         l_file_ext := substr(self.filename, l_pos+1);
      end if;
      l_flag := 'F';
      select 'T'
        into l_flag
        from dual
       where exists (select file_ext
                       from at_file_extension
                      where media_type_code = l_code
                        and file_ext = l_file_ext
                        and office_code in (cwms_util.user_office_code, cwms_util.db_office_code_all)
                    );
      if l_flag = 'F' then
         cwms_err.raise('INVALID_ITEM', '.'||l_file_ext, 'file extension for media type '||l_media_type);
      end if;
      -------------------------
      -- valid quality_code? --
      -------------------------
      l_flag := 'F';
      select 'T'
        into l_flag
        from dual
       where exists (select quality_code
                      from cwms_data_quality
                     where quality_code = self.quality_code 
                    );
      if l_flag = 'F' then
         cwms_err.raise('INVALID_ITEM', self.quality_code, 'CWMS data quality code');
      end if;
   end validate_obj;
end;
/

show errors;
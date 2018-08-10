set define on
@@defines.sql

create or replace package body cwms_text
as
   function group_times(p_times_1 in date_table_type, p_times_2 in date_table_type)
      return date2_tab_t
   is
      l_times   date2_tab_t := date2_tab_t();
   begin
      l_times.extend(p_times_1.count);

      for i in 1 .. p_times_1.count loop
         l_times(i) := date2_t(p_times_1(i), p_times_2(i));
      end loop;

      return l_times;
   end group_times;

   function group_times(p_cursor in sys_refcursor)
      return date2_tab_t
   is
      l_times_1   date_table_type;
      l_times_2   date_table_type;
   begin
      fetch p_cursor
      bulk collect into l_times_1, l_times_2;

      close p_cursor;

      return group_times(l_times_1, l_times_2);
   end group_times; 

   function get_media_type_code(p_type_or_ext in varchar2, p_office_code in number)
      return number
   is
      l_media_type_code   number(10);
   begin
      if p_type_or_ext is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TYPE_OR_EXT');
      end if;

      if instr(p_type_or_ext, '/') > 0 then
         -----------------------
         -- check media types --
         -----------------------
         begin
            select media_type_code
              into l_media_type_code
              from cwms_media_type
             where media_type_id = p_type_or_ext;
         exception
            when no_data_found then
               begin
                  select media_type_code
                    into l_media_type_code
                    from cwms_media_type
                   where upper(media_type_id) = upper(p_type_or_ext);
               exception
                  when no_data_found then
                     null;
               end;
         end;
      else
         ---------------------------
         -- check file extensions --
         ---------------------------
         begin
            select media_type_code
              into l_media_type_code
              from at_file_extension
             where office_code in (p_office_code, cwms_util.db_office_code_all)
               and file_ext = substr(
                                 p_type_or_ext,
                                 instr(
                                    p_type_or_ext,
                                    '.',
                                    -1,
                                    1)
                                 + 1);
         exception
            when no_data_found then
               begin
                  select media_type_code
                    into l_media_type_code
                    from at_file_extension
                   where office_code in (p_office_code, cwms_util.db_office_code_all)
                     and upper(file_ext) = upper(substr(
                                                    p_type_or_ext,
                                                    instr(
                                                       p_type_or_ext,
                                                       '.',
                                                       -1,
                                                       1)
                                                    + 1));
               exception
                  when no_data_found then
                     null;
               end;
         end;
      end if;

      if l_media_type_code is null then
         cwms_err.raise('ERROR', 'No media type associated with "' || p_type_or_ext || '"');
      end if;

      return l_media_type_code;
   end get_media_type_code;
   
   --
   -- store binary with optional description
   -- 
   procedure store_binary(
      p_binary_code       out number, -- the code for use in foreign keys
      p_binary            in     blob, -- the binary, unlimited length
      p_id                in     varchar2, -- identifier with which to retrieve binary (256 chars max)
      p_media_type_or_ext in     varchar2, -- the MIME media type or file extension 
      p_description       in     varchar2 default null, -- description, defaults to null
      p_fail_if_exists    in     varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_ignore_nulls      in     varchar2 default 'T', -- flag specifying whether to ignore null parameters on update
      p_office_id         in     varchar2 default null) -- office id, defaults current user's office
   is
      l_rec            at_blob%rowtype;
      l_id             varchar2(256) := upper(p_id);
      l_office_code    number := cwms_util.get_office_code(p_office_id);
      l_fail_if_exists boolean := cwms_util.return_true_or_false(p_fail_if_exists);
      l_ignore_nulls   boolean := cwms_util.return_true_or_false(p_ignore_nulls);
      l_exists         boolean;
   begin
      cwms_util.check_office_permission(p_office_id);
      begin
         select *
           into l_rec
           from at_blob
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and id = l_id;
         l_exists := true;            
      exception           
         when no_data_found then
            l_exists := false;
      end;
      if l_exists then
         if l_fail_if_exists then
            cwms_err.raise('ITEM_ALREADY_EXISTS', 'Binary ID', p_id);
         else
            --
            -- update the record
            --
            if l_ignore_nulls then
               l_rec.value := case p_binary is null 
                                 when true then l_rec.value 
                                 else p_binary 
                              end;
               l_rec.description := nvl(p_description, l_rec.description);
               l_rec.media_type_code := case p_media_type_or_ext is null                               
                                           when true then l_rec.media_type_code
                                           else get_media_type_code(p_media_type_or_ext, l_office_code)
                                        end;
            else               
               l_rec.value := p_binary;
               l_rec.description := p_description;
               l_rec.media_type_code := get_media_type_code(p_media_type_or_ext, l_office_code);
            end if;
            update at_blob
               set row = l_rec;
         end if;
      else
         -- 
         -- insert the record
         --
         l_rec.blob_code := cwms_seq.nextval;
         l_rec.office_code := l_office_code;
         l_rec.value := p_binary;
         l_rec.description := p_description;
         l_rec.media_type_code := get_media_type_code(p_media_type_or_ext, l_office_code);
         insert into at_blob values l_rec;
      end if;
      p_binary_code := l_rec.blob_code;                          
   end store_binary;      

   --
   -- store text with optional description
   --
   procedure store_text(
      p_text_code         out number, -- the code for use in foreign keys
      p_text           in     clob, -- the text, unlimited length
      p_id             in     varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in     varchar2 default null, -- description, defaults to null
      p_fail_if_exists in     varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in     varchar2 default null) -- office id, defaults current user's office
   is
      l_id                 varchar2(256) := upper(p_id);
      l_fail_if_exists     boolean := cwms_util.return_true_or_false(p_fail_if_exists);
      l_count              binary_integer;
      l_office_code        number := cwms_util.get_office_code(p_office_id);
      l_cwms_office_code   number := cwms_util.get_office_code('CWMS');
      l_rowid              urowid;
   begin
      cwms_util.check_office_permission(p_office_id);
      select count(*)
        into l_count
        from at_clob
       where office_code in (l_office_code, l_cwms_office_code) and id = l_id;

      if l_count = 0 then
         insert into at_clob
              values (
                        cwms_seq.nextval,
                        l_office_code,
                        l_id,
                        p_description,
                        p_text)
           returning clob_code
                into p_text_code;
      else
         if l_fail_if_exists then
            cwms_err.raise('ITEM_ALREADY_EXISTS', 'Text ID', p_id);
         end if;

            update at_clob
               set description = p_description, value = p_text
             where office_code = l_office_code and id = l_id
         returning rowid, clob_code
              into l_rowid, p_text_code;

         if l_rowid is null then
            cwms_err.raise('ERROR', 'Cannot update text owned by the CWMS Office ID.');
         end if;
      end if;
   end store_text;

   --
   -- store text with optional description
   --
   function store_text(
      p_text           in clob, -- the text, unlimited length
      p_id             in varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in varchar2 default null, -- description, defaults to null
      p_fail_if_exists in varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in varchar2 default null) -- office id, defaults current user's office
      return number -- the code for use in foreign keys
   is
      l_text_code   number;
   begin
      store_text(
         p_text_code      => l_text_code,
         p_text           => p_text,
         p_id             => p_id,
         p_description    => p_description,
         p_fail_if_exists => p_fail_if_exists,
         p_office_id      => p_office_id);

      return l_text_code;
   end store_text;

   --
   -- store text with optional description
   --
   procedure store_text(
      p_text_code         out number, -- the code for use in foreign keys
      p_text           in     varchar2, -- the text, limited to varchar2 max size
      p_id             in     varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in     varchar2 default null, -- description, defaults to null
      p_fail_if_exists in     varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in     varchar2 default null) -- office id, defaults current user's office
   is
      l_text   clob;
   begin
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      dbms_lob.writeappend(l_text, length(p_text), p_text);
      dbms_lob.close(l_text);
      store_text(
         p_text_code      => p_text_code,
         p_text           => l_text,
         p_id             => p_id,
         p_description    => p_description,
         p_fail_if_exists => p_fail_if_exists,
         p_office_id      => p_office_id);
   end store_text;

   --
   -- store text with optional description
   --
   function store_text(
      p_text           in varchar2, -- the text, limited to varchar2 max size
      p_id             in varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in varchar2 default null, -- description, defaults to null
      p_fail_if_exists in varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in varchar2 default null) -- office id, defaults current user's office
      return number -- the code for use in foreign keys
   is
      l_text_code   number;
   begin
      store_text(
         p_text_code      => l_text_code,
         p_text           => p_text,
         p_id             => p_id,
         p_description    => p_description,
         p_fail_if_exists => p_fail_if_exists,
         p_office_id      => p_office_id);

      return l_text_code;
   end store_text;
   
   --
   -- retrieve binary only
   --
   procedure retrieve_binary(
      p_binary       out blob, -- the binary, unlimited length
      p_id        in     varchar2, -- identifier used to store binary (256 chars max)
      p_office_id in     varchar2 default null) -- office id, defaults current user's office
   is
      l_description     at_blob.description%type;
      l_media_type      cwms_media_type.media_type_id%type;
      l_file_extensions varchar2(256);
   begin                              
      retrieve_binary2(
         p_binary,
         l_description,
         l_media_type,
         l_file_extensions,
         p_id,
         p_office_id);
   end retrieve_binary;

   --
   -- retrieve binary only
   --
   function retrieve_binary(
      p_id        in varchar2, -- identifier used to store binary (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
      return blob
   is
      l_binary blob;
   begin            
      retrieve_binary(l_binary, p_id, p_office_id);
      return l_binary;
   end retrieve_binary;

   --
   -- Retrieve binary and associated information
   --
   procedure retrieve_binary2(
      p_binary             out blob, -- the binary, unlimited length
      p_description        out varchar2, -- the description
      p_media_type         out varchar2, -- the MIME media type
      p_file_extensions    out varchar2, -- comma-separated list of file extensions, if any
      p_id              in     varchar2, -- identifier used to store binary (256 chars max)
      p_office_id       in     varchar2 default null) -- office id, defaults current user's office
   is
      l_rec             at_blob%rowtype;
      l_description     at_blob.description%type;
      l_media_type      cwms_media_type.media_type_id%type;
      l_office_code     number(10) := cwms_util.get_office_code(p_office_id); 
      l_file_extensions str_tab_t := str_tab_t();
   begin
      begin
         select *
           into l_rec
           from at_blob
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and id = upper(p_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               case p_office_id is null
                  when true then p_id
                  else p_office_id||'/'||p_id
               end);
      end;
      select media_type_id
        into p_media_type
        from cwms_media_type
       where media_type_code = l_rec.media_type_code;
       
      for rec in 
         (  select file_ext
              from at_file_extension
             where office_code in (l_office_code, cwms_util.db_office_code_all)
               and media_type_code = l_rec.media_type_code
             order by file_ext
         )
      loop
         l_file_extensions.extend;
         l_file_extensions(l_file_extensions.count) := rec.file_ext;
      end loop;
      p_file_extensions := cwms_util.join_text(l_file_extensions, ',');       
   end retrieve_binary2;

   --
   -- retrieve text only
   --
   procedure retrieve_text(p_text out clob, -- the text, unlimited length
                                           p_id in varchar2, -- identifier used to store text (256 chars max)
                                                            p_office_id in varchar2 default null) -- office id, defaults current user's office
   is
      l_id                 varchar2(256) := upper(p_id);
      l_office_code        number := cwms_util.get_office_code(p_office_id);
      l_cwms_office_code   number := cwms_util.get_office_code('CWMS');
   begin
      select value
        into p_text
        from at_clob
       where office_code in (l_office_code, l_cwms_office_code) and id = l_id;
   end retrieve_text;

   --
   -- retrieve text only
   --
   function retrieve_text(p_id in varchar2, -- identifier used to store text (256 chars max)
                                           p_office_id in varchar2 default null) -- office id, defaults current user's office
      return clob -- the text, unlimited length
   is
      l_text   clob;
   begin
      retrieve_text(p_text => l_text, p_id => p_id, p_office_id => p_office_id);
      return l_text;
   end retrieve_text;

   --
   -- retrieve text and description
   --
   procedure retrieve_text2(
      p_text           out clob, -- the text, unlimited length
      p_description    out varchar2, -- the description
      p_id          in     varchar2, -- identifier used to store text (256 chars max)
      p_office_id   in     varchar2 default null) -- office id, defaults current user's office
   is
      l_id                 varchar2(256) := upper(p_id);
      l_office_code        number := cwms_util.get_office_code(p_office_id);
      l_cwms_office_code   number := cwms_util.get_office_code('CWMS');
   begin
      select value, description
        into p_text, p_description
        from at_clob
       where office_code in (l_office_code, l_cwms_office_code) and id = l_id;
   end retrieve_text2;

   --
   -- update text and/or description
   --
   procedure update_text(
      p_text         in clob, -- the text, unlimited length
      p_id           in varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description  in varchar2 default null, -- description, defaults to null
      p_ignore_nulls in varchar2 default 'T', -- flag specifying null inputs leave current values unchanged
      p_office_id    in varchar2 default null) -- office id, defaults current user's office
   is
      l_id                 varchar2(256) := upper(p_id);
      l_office_code        number := cwms_util.get_office_code(p_office_id);
      l_cwms_office_code   number := cwms_util.get_office_code('CWMS');
      l_ignore_nulls       boolean := cwms_util.return_true_or_false(p_ignore_nulls);
   begin
      cwms_util.check_office_permission(p_office_id);
      if l_ignore_nulls then
         if p_text is null then
            if p_description is not null then
               update at_clob
                  set description = p_description
                where office_code in (l_office_code, l_cwms_office_code) and id = l_id;
            end if;
         elsif p_description is null then
            update at_clob
               set value = p_text
             where office_code in (l_office_code, l_cwms_office_code) and id = l_id;
         else
            update at_clob
               set value = p_text, description = p_description
             where office_code in (l_office_code, l_cwms_office_code) and id = l_id;
         end if;
      else
         update at_clob
            set value = p_text, description = p_description
          where office_code in (l_office_code, l_cwms_office_code) and id = l_id;
      end if;
   end update_text;

   --
   -- append to text
   --
   procedure append_text(
      p_new_text  in out nocopy clob, -- the text to append, unlimited length
      p_id        in varchar2, -- identifier of text to append to (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
   is
      l_existing_text   clob;
      l_code            number(10);
      l_office_code     number(10);
   begin
      begin
         l_code := cwms_text.get_text_code(p_id, p_office_id);

         select office_code, value
           into l_office_code, l_existing_text
           from at_clob
          where clob_code = l_code;

         cwms_util.append(l_existing_text, p_new_text);

         update at_clob
            set value = l_existing_text
          where clob_code = l_code;
      exception
         when no_data_found then
            store_text(
               p_text_code      => l_code,
               p_text           => p_new_text,
               p_id             => p_id,
               p_description    => null,
               p_fail_if_exists => 'T',
               p_office_id      => p_office_id);
      end;
   end append_text;

   --
   -- append to text
   --
   procedure append_text(
      p_new_text  in varchar2, -- the text to append, limited to varchar2 max size
      p_id        in varchar2, -- identifier of text to append to (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
   is
      l_existing_text   clob;
      l_code            number(10);
      l_office_code     number(10);
   begin
      begin
         l_code := cwms_text.get_text_code(p_id, p_office_id);

         select office_code, value
           into l_office_code, l_existing_text
           from at_clob
          where clob_code = l_code;

         if l_office_code = cwms_util.db_office_code_all then
            cwms_err.raise('ERROR', 'Cannot update text owned by the CWMS Office ID.');
         end if;

         cwms_util.append(l_existing_text, p_new_text);

         update at_clob
            set value = l_existing_text
          where clob_code = l_code;
      exception
         when no_data_found then
            dbms_lob.createtemporary(l_existing_text, true);
            dbms_lob.open(l_existing_text, dbms_lob.lob_readwrite);
            dbms_lob.writeappend(l_existing_text, length(p_new_text), p_new_text);
            dbms_lob.close(l_existing_text);
            store_text(
               p_text_code      => l_code,
               p_text           => l_existing_text,
               p_id             => p_id,
               p_description    => null,
               p_fail_if_exists => 'T',
               p_office_id      => p_office_id);
      end;
   end append_text;

   --
   -- delete binary
   --
   procedure delete_binary(
      p_id        in varchar2, -- identifier used to store binary (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
   is
      l_id            varchar2(256) := upper(p_id);
      l_office_code   number := cwms_util.get_office_code(p_office_id);
   begin
      cwms_util.check_office_permission(p_office_id);
      delete 
        from at_blob
       where office_code = l_office_code and id = l_id;
   end delete_binary;

   --
   -- delete text
   --
   procedure delete_text(
      p_id        in varchar2, -- identifier used to store text (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
   is
      l_id            varchar2(256) := upper(p_id);
      l_office_code   number := cwms_util.get_office_code(p_office_id);
   begin
      cwms_util.check_office_permission(p_office_id);
      delete 
        from at_clob
       where office_code = l_office_code and id = l_id;
   end delete_text;

   --
   -- get matching ids in a cursor
   --
   procedure get_matching_ids(
      p_ids                  in out sys_refcursor, -- cursor of the matching office ids, text ids, and optionally descriptions
      p_id_masks             in     varchar2 default '%', -- delimited list of id masks, defaults to all ids
      p_include_descriptions in     varchar2 default 'F', -- flag specifying whether to retrieve descriptions also
      p_office_id_masks      in     varchar2 default null, -- delimited list of office id masks, defaults to user's office
      p_delimiter            in     varchar2 default ',') -- delimiter for masks, defaults to comma
   is
      type id_collection is table of boolean
                               index by varchar2(256);

      l_include_descriptions   boolean := cwms_util.return_true_or_false(p_include_descriptions);
      l_office_id_masks        varchar2(256) := nvl(p_office_id_masks, cwms_util.user_office_id);
      l_office_id_mask_tab     str_tab_t;
      l_id_mask_tab            str_tab_t;
      l_ids                    id_collection;
      l_office_id_bind_str     varchar2(32767);
      l_id_bind_str            varchar2(32767);
      l_query_str              varchar2(32767);
      l_office_id              varchar2(16);
      l_id                     varchar2(256);
      l_cwms_matched           boolean := false;
      l_id_mask                varchar2(256);
   begin
      ------------------------------------
      -- build office ids bind variable --
      ------------------------------------
      l_office_id_mask_tab := cwms_util.split_text(l_office_id_masks, p_delimiter);

      for i in 1 .. l_office_id_mask_tab.count loop
         l_id_mask := cwms_util.normalize_wildcards(upper(l_office_id_mask_tab(i)), true);
         for rec in (select office_id
                       from cwms_office
                      where office_id like l_id_mask) loop
            if not l_ids.exists(rec.office_id) then
               l_ids(rec.office_id) := true;
            end if;
         end loop;
      end loop;

      l_office_id          := l_ids.first;

      loop
         if l_office_id = 'CWMS' then
            l_cwms_matched := true;
         end if;

         l_office_id_bind_str := l_office_id_bind_str || '''' || l_office_id || '''';
         l_office_id          := l_ids.next(l_office_id);
         exit when l_office_id is null;
         l_office_id_bind_str := l_office_id_bind_str || ',';
      end loop;

      l_ids.delete;

      if not l_cwms_matched then
         l_office_id_bind_str := l_office_id_bind_str || ',' || '''CWMS''';
      end if;

      -----------------------------
      -- build ids bind variable --
      -----------------------------
      l_id_mask_tab        := cwms_util.split_text(p_id_masks, p_delimiter);

      for i in 1 .. l_id_mask_tab.count loop
         l_id_mask := cwms_util.normalize_wildcards(upper(l_id_mask_tab(i)), true);
         for rec in (select id
                       from at_clob
                      where id like l_id_mask) loop
            if not l_ids.exists(rec.id) then
               l_ids(rec.id) := true;
            end if;
         end loop;
      end loop;

      l_id                 := l_ids.first;

      loop
         l_id_bind_str := l_id_bind_str || '''' || l_id || '''';
         l_id          := l_ids.next(l_id);
         exit when l_id is null;
         l_id_bind_str := l_id_bind_str || ',';
      end loop;

      l_ids.delete;

      ----------------------------
      -- build the query string --
      ----------------------------
      if l_include_descriptions then
         l_query_str := 
            'select o.office_id,
                    c.id,
                    c.description
               from cwms_office o,
                    at_clob c
              where o.office_id in (:office_ids)
                and c.office_code = o.office_code
                and c.id in (:ids)';
      else
         l_query_str := 
            'select o.office_id,
                    c.id
               from cwms_office o,
                    at_clob c
              where o.office_id in (:office_ids)
                and c.office_code = o.office_code
                and c.id in (:ids)';
      end if;

      l_query_str := replace(l_query_str, ':office_ids', l_office_id_bind_str);
      l_query_str := replace(l_query_str, ':ids', l_id_bind_str);
      cwms_util.check_dynamic_sql(l_query_str);
      -----------------------
      -- perform the query --
      -----------------------
      open p_ids for l_query_str;
   end get_matching_ids;

   --
   -- get matching ids in a delimited clob
   --
   procedure get_matching_ids(
      p_ids                     out clob, -- delimited clob of the matching office ids, text ids, and optionally descriptions
      p_id_masks             in     varchar2 default '%', -- comma-separated list of id masks, defaults to all ids
      p_include_descriptions in     varchar2 default 'F', -- flag specifying whether to retrieve descriptions also
      p_office_id_masks      in     varchar2 default null, -- delimited list of office id masks, defaults to user's office
      p_delimiter            in     varchar2 default ',') -- delimiter for masks, defaults to comma
   is
      type rec1_t is record(
         office_id   varchar2(16),
         id          varchar2(256));

      type rec2_t is record(
         office_id     varchar2(16),
         id            varchar2(256),
         description   varchar2(256));

      l_include_descriptions   boolean := cwms_util.return_true_or_false(p_include_descriptions);
      l_rec1                   rec1_t;
      l_rec2                   rec2_t;
      l_cursor                 sys_refcursor;
      l_ids                    clob;
      l_first                  boolean := true;

      procedure write_clob(p1 varchar2, p2 varchar2)
      is
         l_data   varchar2(32767);
      begin
         if l_first then
            l_data  := p1 || cwms_util.field_separator || p2;
            l_first := false;
         else
            l_data := cwms_util.record_separator || p1 || cwms_util.field_separator || p2;
         end if;

         dbms_lob.writeappend(l_ids, length(l_data), l_data);
      end;

      procedure write_clob(p1 varchar2, p2 varchar2, p3 varchar2)
      is
         l_data   varchar2(32767);
      begin
         if l_first then
            l_data  := p1 || cwms_util.field_separator || p2 || cwms_util.field_separator || p3;
            l_first := false;
         else
            l_data := cwms_util.record_separator || p1 || cwms_util.field_separator || p2 || cwms_util.field_separator || p3;
         end if;

         dbms_lob.writeappend(l_ids, length(l_data), l_data);
      end;
   begin
      get_matching_ids(
         l_cursor,
         p_id_masks,
         p_include_descriptions,
         p_office_id_masks,
         p_delimiter);

      dbms_lob.createtemporary(l_ids, true);
      dbms_lob.open(l_ids, dbms_lob.lob_readwrite);

      loop
         if l_include_descriptions then
            fetch l_cursor into l_rec2;

            exit when l_cursor%notfound;
            write_clob(l_rec2.office_id, l_rec2.id, l_rec2.description);
         else
            fetch l_cursor into l_rec1;

            exit when l_cursor%notfound;
            write_clob(l_rec1.office_id, l_rec1.id);
         end if;
      end loop;
      close l_cursor;

      dbms_lob.close(l_ids);
      p_ids := l_ids;
   end get_matching_ids;

   --
   -- get code for id
   --
   procedure get_text_code(
      p_text_code out number, -- the code for use in foreign keys
      p_id        in varchar2, -- identifier with which to retrieve text (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
   is
      l_office_code        number := cwms_util.get_office_code(p_office_id);
      l_cwms_office_code   number := cwms_util.get_office_code('CWMS');
   begin
      select clob_code
        into p_text_code
        from at_clob
       where office_code in (l_office_code, l_cwms_office_code) and id = upper(p_id);
   end get_text_code;

   --
   -- get code for id
   --
   function get_text_code(
      p_id        in varchar2, -- identifier with which to retrieve text (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
      return number -- the code for use in foreign keys
   is
      l_text_code   number;
   begin
      get_text_code(l_text_code, p_id, p_office_id);
      return l_text_code;
   end get_text_code;

   -------------------------
   -- store standard text --
   -------------------------
   procedure store_std_text(
      p_std_text_id    in varchar2,
      p_std_text       in clob default null,
      p_fail_if_exists in varchar2 default 'T',
      p_office_id      in varchar2 default null)
   is
      l_office_code      number(10);
      l_clob_code        number(10);
      l_office_id        varchar2(16);
      l_std_text_id      varchar2(16);
      l_clob             clob;
      l_exists           boolean;
      l_fail_if_exists   boolean;
      l_rec              at_std_text%rowtype;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_std_text_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_STD_TEXT_ID');
      end if;

      l_std_text_id    := upper(trim(p_std_text_id));
      l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
      l_office_code    := cwms_util.get_office_code(p_office_id);

      select office_id
        into l_office_id
        from cwms_office
       where office_code = l_office_code;

      if cwms_util.get_db_office_code(null) != cwms_util.db_office_code_all and l_office_id != cwms_util.user_office_id then
         cwms_err.raise(
            'ERROR',
            'Cannot set standard text for office ('
            || l_office_id
            || ') that is not your default office ('
            || cwms_util.user_office_id
            || ')');
      end if;

      ---------------------------------
      -- determine if already exists --
      ---------------------------------
      begin
         select *
           into l_rec
           from at_std_text
          where office_code in (l_office_code, cwms_util.db_office_code_all) and std_text_id = l_std_text_id;

         l_exists := true;
      exception
         when no_data_found then
            l_exists := false;
      end;

      if l_exists then
         if l_rec.office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
            cwms_err.raise(
               'ERROR',
               'Cannot store standard text for office '
               || l_office_id
               || '; Identifier '
               || l_rec.std_text_id
               || ' is already used by CWMS office');
         end if;

         if l_fail_if_exists then
            cwms_err.raise('ITEM_ALREADY_EXISTS', 'CWMS standard text', l_rec.std_text_id);
         end if;

         ------------------------------
         -- update the standard text --
         ------------------------------
         l_clob_code       := l_rec.clob_code;

         if l_clob_code is null then
            if p_std_text is not null then
               ----------------------
               -- store a new clob --
               ----------------------
               l_rec.clob_code      :=
                  store_text(
                     p_text           => p_std_text,
                     p_id             => '/Standard Text/' || l_std_text_id,
                     p_description    => 'Actual text for standard text identifier ' || l_std_text_id,
                     p_fail_if_exists => 'F',
                     p_office_id      => l_office_id);
            end if;
         else
            if p_std_text is null then
               ------------------------------
               -- delete the existing clob --
               ------------------------------
               delete from at_clob
                     where clob_code = l_clob_code;
            else
               -------------------------------------------
               -- update the existing clob if necessary --
               -------------------------------------------
               select value
                 into l_clob
                 from at_clob
                where clob_code = l_clob_code;

               if dbms_lob.compare(p_std_text, l_clob) != 0 then
                  update at_clob
                     set value = p_std_text
                   where clob_code = l_clob_code;
               end if;
            end if;
         end if;

         -----------------------------------
         -- update the at_std_text record --
         -----------------------------------
         l_rec.std_text_id := l_std_text_id; -- to change case if necessary

         update at_std_text
            set row = l_rec;
      else
         ------------------------------
         -- create new standard text --
         ------------------------------
         if p_std_text is not null then
            ----------------------
            -- store a new clob --
            ----------------------
            l_rec.clob_code      :=
               store_text(
                  p_text           => p_std_text,
                  p_id             => '/Standard Text/' || l_std_text_id,
                  p_description    => 'Actual text for standard text identifier ' || l_std_text_id,
                  p_fail_if_exists => 'F',
                  p_office_id      => l_office_id);
         end if;

         ---------------------------------------
         -- create the new at_std_text record --
         ---------------------------------------
         l_rec.std_text_code := cwms_seq.nextval;
         l_rec.office_code   := l_office_code;
         l_rec.std_text_id   := l_std_text_id;

         insert into at_std_text
              values l_rec;
      end if;
   end store_std_text;

   procedure retrieve_std_text(
      p_std_text    out clob, 
      p_std_text_id in  varchar2, 
      p_office_id   in  varchar2 default null)
   is
   begin
      p_std_text := retrieve_std_text_f(p_std_text_id, p_office_id);
   end retrieve_std_text;

   function retrieve_std_text_f(
      p_std_text_id in varchar2, 
      p_office_id   in varchar2 default null)
      return clob
   is
      l_std_text      clob;
      l_office_code   number(10);
      l_clob_code     number(10);
      l_office_id     varchar2(16);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_std_text_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_STD_TEXT_ID');
      end if;

      l_office_code := cwms_util.get_office_code(p_office_id);

      -----------------------
      -- get the clob code --
      -----------------------
      begin
         select clob_code
           into l_clob_code
           from at_std_text
          where office_code in (l_office_code, cwms_util.db_office_code_all) and std_text_id = upper(p_std_text_id);
      exception
         when no_data_found then
            select office_id
              into l_office_id
              from cwms_office
             where office_code = l_office_code;

            cwms_err.raise('ITEM_DOES_NOT_EXIST', 'CWMS standard text for office ' || l_office_id, p_std_text_id);
      end;

      ------------------
      -- get the clob --
      ------------------
      if l_clob_code is not null then
         select value
           into l_std_text
           from at_clob
          where clob_code = l_clob_code;
      end if;

      return l_std_text;
   end retrieve_std_text_f;

   procedure delete_std_text(
      p_std_text_id   in varchar2,
      p_delete_action in varchar2 default cwms_util.delete_key,
      p_office_id     in varchar2 default null)
   is
      l_office_code   number(10);
      l_std_text_code number(10);
      l_delete_key    boolean := false;
      l_delete_data   boolean := false;
   begin
      cwms_util.check_office_permission(p_office_id);
      l_office_code := cwms_util.get_db_office_code(p_office_id);
      case upper(trim(p_delete_action))
      when cwms_util.delete_key then
         l_delete_key := true;
      when cwms_util.delete_data then
         l_delete_data := true;
      when cwms_util.delete_all then
         l_delete_key  := true;
         l_delete_data := true;
      else
         cwms_err.raise('INVALID_ITEM', p_delete_action, 'delete action');
      end case;
      
      select std_text_code
        into l_std_text_code
        from at_std_text
       where upper(std_text_id) = upper(trim(p_std_text_id))
         and office_code = l_office_code;
         
      if l_delete_data then
         delete
           from at_tsv_std_text
          where std_text_code = l_std_text_code;    
      end if;
      
      if l_delete_key then
         delete
           from at_std_text
          where std_text_code = l_std_text_code; 
      end if;
      
   end delete_std_text;

   procedure cat_std_text(
      p_cursor              out sys_refcursor,
      p_std_text_id_mask in     varchar2 default '*',
      p_office_id_mask   in     varchar2 default null)
   is
      l_std_text_id_mask varchar2(32);
      l_office_id_mask   varchar2(32);
   begin
      l_std_text_id_mask := cwms_util.normalize_wildcards(upper(trim(p_std_text_id_mask)));
      l_office_id_mask   := cwms_util.normalize_wildcards(upper(trim(p_office_id_mask)));
      open p_cursor for
         select a.office_id,
                a.std_text_id,
                b.value as std_text
           from (select o.office_id,
                        s.std_text_id,
                        s.clob_code
                   from at_std_text s,
                        cwms_office o
                  where o.office_id like l_office_id_mask escape '\'
                    and s.office_code = o.office_code
                    and s.std_text_id like l_office_id_mask escape '\'
                ) a
                left outer join
                (select clob_code,
                        value
                   from at_clob     
                ) b on b.clob_code = a.clob_code;         
   end cat_std_text;

   function cat_std_text_f(
      p_std_text_id_mask in varchar2 default '*', 
      p_office_id_mask   in varchar2 default null)
      return sys_refcursor
   is
      l_cursor sys_refcursor;
   begin
      cat_std_text(
         l_cursor,
         p_std_text_id_mask,
         p_office_id_mask);
         
      return l_cursor;
   end cat_std_text_f;

   procedure store_ts_std_text(
      p_ts_code             in number,
      p_date_time_utc       in date,
      p_version_date_utc    in date,
      p_std_text_code       in number,
      p_data_entry_date_utc in timestamp,
      p_attribute           in number)
   is
      l_rec       at_tsv_std_text%rowtype;
      l_office_id varchar2(16);
   begin
      select db_office_id
        into l_office_id
        from at_cwms_ts_id
       where ts_code = p_ts_code; 
      cwms_util.check_office_permission(l_office_id);
      l_rec.ts_code         := p_ts_code;
      l_rec.date_time       := p_date_time_utc;
      l_rec.version_date    := nvl(p_version_date_utc, cast(p_data_entry_date_utc as date));
      l_rec.std_text_code   := p_std_text_code;
      l_rec.data_entry_date := p_data_entry_date_utc;
      l_rec.attribute       := p_attribute;

      ----------------------------------
      -- see if record already exists --
      ----------------------------------
      select *
        into l_rec
        from at_tsv_std_text
       where ts_code = l_rec.ts_code
         and date_time = l_rec.date_time
         and version_date = l_rec.version_date
         and std_text_code = l_rec.std_text_code;

      ------------------------------------------------
      -- record exists, update it only if necessary --
      ------------------------------------------------
      if l_rec.attribute != p_attribute then
         l_rec.attribute := p_attribute;

         update at_tsv_std_text
            set row = l_rec;
      end if;
   exception
      when no_data_found then
         -------------------------------------
         -- record doesn't exist; create it --
         -------------------------------------
         insert into at_tsv_std_text
              values l_rec;
   end store_ts_std_text;

   procedure store_ts_std_text(
      p_ts_code           in integer,
      p_std_text_code     in integer,
      p_date_times_utc    in date_table_type,
      p_version_dates_utc in date_table_type,
      p_version_date_utc  in date,
      p_max_version       in boolean,
      p_replace_all       in boolean,
      p_attribute         in number)
   is
      l_date_times           date_table_type;
      l_version_dates        date_table_type;
      l_regular_times        date_table_type;
      l_cursor               sys_refcursor;
      l_is_versioned_str     varchar2(1);
      l_is_versioned         boolean;
      l_off_interval_count   integer;
      l_store_date           timestamp := sys_extract_utc(systimestamp);
      l_office_id            varchar2(16);
   begin
      select db_office_id
        into l_office_id
        from at_cwms_ts_id
       where ts_code = p_ts_code; 
      cwms_util.check_office_permission(l_office_id);
      if p_version_dates_utc is null then
         ------------------------------------------------------------
         -- need to validate date/times and retrieve version dates --
         ------------------------------------------------------------
         cwms_ts.is_ts_versioned(l_is_versioned_str, p_ts_code);
         l_is_versioned := cwms_util.return_true_or_false(l_is_versioned_str);

         ------------------------------------------------------
         -- get valid times for regular interval time series --
         ------------------------------------------------------
         begin
            l_regular_times      :=
               cwms_ts.get_times_for_time_window(
                  p_date_times_utc(1),
                  p_date_times_utc(p_date_times_utc.count),
                  p_ts_code,
                  'UTC');
         exception
            when others then
               case
                  when instr(sqlerrm, 'irregular') > 0 then
                     null;
                  when instr(sqlerrm, 'undefined') > 0 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot set time series text for regular time series with undefined interval offset.');
                  else
                     raise;
               end case;
         end;

         if l_regular_times is not null then
            ---------------------------------------------------------
            -- verify valid times for regular interval time series --
            ---------------------------------------------------------
            select count(*)
              into l_off_interval_count
              from (select column_value from table(p_date_times_utc)
                    minus
                    select column_value from table(l_regular_times));

            if l_off_interval_count > 0 then
               cwms_err.raise(
                  'ERROR',
                  'Times include ' || l_off_interval_count || ' invalid time(s) for specified time series.');
            end if;
         end if;

         l_cursor       :=
            cwms_ts.retrieve_existing_times_f(
               p_ts_code          => p_ts_code,
               p_start_time_utc   => null,
               p_end_time_utc     => null,
               p_date_times_utc   => p_date_times_utc,
               p_version_date_utc => p_version_date_utc,
               p_max_version      => p_max_version);

         loop
            fetch l_cursor
            bulk collect into l_date_times, l_version_dates
            limit 50000;

            exit when l_date_times.count = 0;

            for i in 1 .. l_date_times.count loop
               ------------------------------------------------
               -- delete existing standard text if necessary --
               ------------------------------------------------
               if p_replace_all then
                  begin
                     delete from at_tsv_std_text
                           where ts_code = p_ts_code and date_time = l_date_times(i) and version_date = l_version_dates(i);
                  exception
                     when no_data_found then
                        null;
                  end;
               end if;

               -----------------------------------------------------
               -- store the standard text for existing date_times --
               -----------------------------------------------------
               store_ts_std_text(
                  p_ts_code,
                  l_date_times(i),
                  l_version_dates(i),
                  p_std_text_code,
                  l_store_date,
                  p_attribute);
            end loop;
         end loop;

         close l_cursor;

         ---------------------------------------------------------
         -- store the standard text for non-existing date_times --
         ---------------------------------------------------------
         l_cursor       := null;
         l_date_times.delete;

         loop
            if l_cursor is null then
               open l_cursor for
                  select column_value
                    from table(p_date_times_utc)
                   where column_value not in (select date_time
                                                from cwms_v_tsv
                                               where ts_code = p_ts_code);
            else
               l_date_times.delete;
            end if;

            fetch l_cursor
            bulk collect into l_date_times
            limit 50000;

            exit when l_date_times.count = 0;

            for i in 1 .. l_date_times.count loop
               store_ts_std_text(
                  p_ts_code,
                  l_date_times(i),
                  case p_version_date_utc is null
                     when true then case l_is_versioned when true then null else cwms_util.non_versioned end
                     else p_version_date_utc
                  end,
                  p_std_text_code,
                  l_store_date,
                  p_attribute);
            end loop;
         end loop;

         close l_cursor;
      else
         -----------------------------------------
         -- valid dates/times already retrieved --
         -----------------------------------------
         for i in 1 .. p_date_times_utc.count loop
            store_ts_std_text(
               p_ts_code,
               p_date_times_utc(i),
               p_version_dates_utc(i),
               p_std_text_code,
               l_store_date,
               p_attribute);
         end loop;
      end if;
   end store_ts_std_text;

   procedure store_ts_std_text(
      p_tsid         in varchar2,
      p_std_text_id  in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_std_text_code      number(10);
      l_start_time_utc     date;
      l_end_time_utc       date := sysdate;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_existing           boolean;
      l_non_existing       boolean;
      l_is_versioned       boolean;
      l_is_regular         boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
      l_version_id         varchar2(32);
      l_cursor             sys_refcursor;
      l_store_date         timestamp := cast(systimestamp at time zone 'UTC' as timestamp);
      l_date_times         date_table_type;
      l_version_dates      date_table_type;
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_std_text_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_STD_TEXT_ID');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      if p_version_date = cwms_util.all_version_dates then
         cwms_err.raise('ERROR', 'Cannot specify all version dates in this call.');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version    := cwms_util.return_true_or_false(p_max_version);
      l_existing       := cwms_util.return_true_or_false(p_existing);
      l_non_existing   := cwms_util.return_true_or_false(p_non_existing);
      l_replace_all    := cwms_util.return_true_or_false(p_replace_all);
      l_office_id      := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      l_tsid           := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_is_regular     := cwms_ts.get_ts_interval(l_tsid) > 0;

      if l_is_regular and not l_existing and not l_non_existing then
         return;
      end if;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            ----------------------------------------------------------------
            -- time series doesn't exist - abort on irregular time series --
            ----------------------------------------------------------------
            if not l_is_regular then
               cwms_err.raise(
                  'ERROR',
                  'Cannot use this version of STORE_TS_STD_TEXT to store text to a non-existent irregular time series');
            end if;

            ----------------------------------------------------------------------------------------
            -- don't create regular time series if we're not going to store to non-existing times --
            ----------------------------------------------------------------------------------------
            if not l_non_existing then
               return;
            end if;

            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the start time --
            -----------------------------------------------------------------------------------------
            cwms_ts.create_ts_code(
               p_ts_code    => l_ts_code,
               p_office_id  => l_office_id,
               p_cwms_ts_id => l_tsid,
               p_utc_offset => cwms_ts.get_utc_interval_offset(l_start_time_utc, cwms_ts.get_ts_interval(l_tsid)));
      end;

      l_is_versioned   := cwms_util.return_true_or_false(cwms_ts.is_tsid_versioned_f(l_tsid, l_office_id));

      begin
         select std_text_code
           into l_std_text_code
           from at_std_text
          where office_code in (l_office_code, cwms_util.db_office_code_all) and std_text_id = upper(trim(p_std_text_id));
      exception
         when no_data_found then
            cwms_err.raise('ITEM_DOES_NOT_EXIST', 'CWMS standard text for office ' || l_office_id, p_std_text_id);
      end;

      ------------------------
      -- get the date/times --
      ------------------------
      if l_is_regular then
         -------------------------
         -- regular time series --
         -------------------------
         if l_non_existing then
            if l_existing then
               ----------------------------------------------
               -- store to existing and non-existing times --
               ----------------------------------------------
               l_date_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
            else
               --------------------------------------
               -- store to non-existing times only --
               --------------------------------------
               declare
                  l_regular_times    date_table_type;
                  l_existing_times   date_table_type;
               begin
                  l_regular_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
                  l_cursor        :=
                     cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        null,
                        l_version_date_utc,
                        l_max_version);

                  fetch l_cursor
                  bulk collect into l_existing_times, l_version_dates;

                  close l_cursor;

                    select column_value
                      bulk collect into l_date_times
                      from (select column_value from table(l_regular_times)
                            minus
                            select column_value from table(l_existing_times))
                  order by column_value;
               end;
            end if;
         else
            ----------------------------------
            -- store to existing times only --
            ----------------------------------
            l_cursor      :=
               cwms_ts.retrieve_existing_times_f(
                  l_ts_code,
                  l_start_time_utc,
                  l_end_time_utc,
                  null,
                  l_version_date_utc,
                  l_max_version);

            fetch l_cursor
            bulk collect into l_date_times, l_version_dates;

            close l_cursor;
         end if;
      else
         ---------------------------
         -- irregular time series --
         ---------------------------
         l_cursor      :=
            cwms_ts.retrieve_existing_times_f(
               l_ts_code,
               l_start_time_utc,
               l_end_time_utc,
               null,
               l_version_date_utc,
               l_max_version);

         fetch l_cursor
         bulk collect into l_date_times, l_version_dates;

         close l_cursor;
      end if;

      --------------------
      -- store the text --
      --------------------
      store_ts_std_text(
         l_ts_code,
         l_std_text_code,
         l_date_times,
         l_version_dates,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_std_text;

   procedure store_ts_std_text(
      p_tsid         in varchar2,
      p_std_text_id  in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_std_text_id        varchar2(16);
      l_std_text_code      number(10);
      l_times_utc          date_table_type := date_table_type();
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_is_versioned       boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
   begin
      cwms_util.check_office_permission(p_office_id);
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_std_text_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_STD_TEXT_ID');
      end if;

      if p_times is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TIMES');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id   := cwms_util.get_db_office_id(p_office_id);
      l_tsid        := cwms_ts.get_ts_id(p_tsid, l_office_id);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_std_text_id := trim(upper(p_std_text_id));
      l_replace_all := cwms_util.return_true_or_false(p_replace_all);
      l_max_version := cwms_util.return_true_or_false(p_max_version);

      begin
         select std_text_code
           into l_std_text_code
           from at_std_text
          where office_code in (l_office_code, cwms_util.db_office_code_all) and std_text_id = l_std_text_id;
      exception
         when no_data_found then
            cwms_err.raise('ITEM_DOES_NOT_EXIST', 'CWMS standard text for office ' || l_office_id, p_std_text_id);
      end;

      l_times_utc.extend(p_times.count);

      for i in 1 .. p_times.count loop
         l_times_utc(i) := cwms_util.change_timezone(p_times(i), l_time_zone, 'UTC');
      end loop;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the first time --
            -----------------------------------------------------------------------------------------
            if cwms_ts.get_ts_interval(l_tsid) > 0 then
               cwms_ts.create_ts_code(
                  p_ts_code    => l_ts_code,
                  p_office_id  => l_office_id,
                  p_cwms_ts_id => l_tsid,
                  p_utc_offset => cwms_ts.get_utc_interval_offset(l_times_utc(1), cwms_ts.get_ts_interval(l_tsid)));
            else
               cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_office_id => l_office_id, p_cwms_ts_id => l_tsid);
            end if;
      end;

      --------------------
      -- store the text --
      --------------------
      store_ts_std_text(
         l_ts_code,
         l_std_text_code,
         l_times_utc,
         null,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_std_text;

   procedure retrieve_ts_std_text(
      p_cursor              out sys_refcursor,
      p_tsid             in     varchar2,
      p_std_text_id_mask in     varchar2,
      p_start_time       in     date,
      p_end_time         in     date default null,
      p_version_date     in     date default null,
      p_time_zone        in     varchar2 default null,
      p_max_version      in     varchar2 default 'T',
      p_retrieve_text    in     varchar2 default 'T',
      p_min_attribute    in     number default null,
      p_max_attribute    in     number default null,
      p_office_id        in     varchar2 default null)
   is
   begin
      p_cursor      :=
         retrieve_ts_std_text_f(
            p_tsid,
            p_std_text_id_mask,
            p_start_time,
            p_end_time,
            p_version_date,
            p_time_zone,
            p_max_version,
            p_retrieve_text,
            p_min_attribute,
            p_max_attribute,
            p_office_id);
   end retrieve_ts_std_text;

   function retrieve_ts_std_text_f(
      p_tsid             in varchar2,
      p_std_text_id_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_retrieve_text    in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return sys_refcursor
   is
      l_office_id            varchar2(16);
      l_tsid                 varchar2(191);
      l_std_text_id_mask     varchar2(256);
      l_start_time_utc       date;
      l_end_time_utc         date;
      l_version_date_utc     date;
      l_time_zone            varchar2(28);
      l_ts_code              number(10);
      l_cursor               sys_refcursor;
      l_date_time_versions   date2_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_std_text_id_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_STD_TEXT_ID_MASK');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id        := cwms_util.get_db_office_id(p_office_id);
      l_tsid             := cwms_ts.get_ts_id(p_tsid, l_office_id);
      l_ts_code          := cwms_ts.get_ts_code(l_tsid, l_office_id);
      l_std_text_id_mask := cwms_util.normalize_wildcards(p_std_text_id_mask);
      l_time_zone        :=
         nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      l_start_time_utc   := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is null then
         l_end_time_utc := l_start_time_utc;
      else
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      -----------------------------------------
      -- get the existing times and versions --
      -----------------------------------------
      l_date_time_versions      :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        p_ts_code          => l_ts_code,
                        p_start_time_utc   => l_start_time_utc,
                        p_end_time_utc     => l_end_time_utc,
                        p_date_times_utc   => null,
                        p_version_date_utc => l_version_date_utc,
                        p_max_version      => cwms_util.return_true_or_false(p_max_version)));

      ------------------
      -- get the text --
      ------------------
      if cwms_util.return_true_or_false(p_retrieve_text) then
         -------------------
         -- with the clob --
         -------------------
         open l_cursor for
              select cwms_util.change_timezone(d.date_1, 'UTC', l_time_zone) as date_time,
                     cwms_util.change_timezone(d.date_2, 'UTC', case 
                                                                when d.date_2 = cwms_util.non_versioned then 'UTC' 
                                                                else l_time_zone 
                                                                end) as version_date,
                     cwms_util.change_timezone(t.data_entry_date, 'UTC', l_time_zone) as data_entry_date,
                     s.std_text_id,
                     t.attribute,
                     c.value as std_text
                from table(l_date_time_versions) d,
                     at_tsv_std_text t,
                     at_std_text s,
                     at_clob c
               where t.ts_code = l_ts_code
                 and t.date_time = d.date_1
                 and t.version_date = d.date_2
                 and t.std_text_code = s.std_text_code
                 and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                   or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
                 and upper(s.std_text_id) like upper(l_std_text_id_mask) escape '\'
                 and c.clob_code = s.clob_code
            order by d.date_1,
                     d.date_2,
                     t.attribute,
                     t.data_entry_date;
      else
         ----------------------
         -- without the clob --
         ----------------------
         open l_cursor for
              select cwms_util.change_timezone(d.date_1, 'UTC', l_time_zone) as date_time,
                     cwms_util.change_timezone(d.date_2, 'UTC', case 
                                                                when d.date_2 = cwms_util.non_versioned then 'UTC' 
                                                                else l_time_zone 
                                                                end) as version_date,
                     cwms_util.change_timezone(t.data_entry_date, 'UTC', l_time_zone) as data_entry_date,
                     s.std_text_id,
                     t.attribute
                from table(l_date_time_versions) d, at_tsv_std_text t, at_std_text s
               where t.ts_code = l_ts_code
                 and t.date_time = d.date_1
                 and t.version_date = d.date_2
                 and t.std_text_code = s.std_text_code
                 and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                   or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
                 and upper(s.std_text_id) like upper(l_std_text_id_mask) escape '\'
            order by d.date_1,
                     d.date_2,
                     t.attribute,
                     t.data_entry_date;
      end if;

      return l_cursor;
   end retrieve_ts_std_text_f;

   function get_ts_std_text_count(
      p_tsid             in varchar2,
      p_std_text_id_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_date_times       in date_table_type default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return pls_integer
   is
      l_office_id          varchar2(16);
      l_tsid               varchar2(191);
      l_std_text_id_mask   varchar2(16);
      l_start_time_utc     date;
      l_end_time_utc       date;
      l_date_times_utc     date_table_type;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_max_version        boolean;
      l_office_code        number(10);
      l_ts_code            number(10);
      l_times_utc          date2_tab_t;
      l_count              pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_std_text_id_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_STD_TEXT_ID_MASK');
      end if;

      if p_start_time is null and p_date_times is null then
         cwms_err.raise('ERROR', 'One of P_START_TIME or P_DATE_TIMES must be non-NULL');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version      := cwms_util.return_true_or_false(p_max_version);
      l_std_text_id_mask := cwms_util.normalize_wildcards(p_std_text_id_mask);
      l_office_id        := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      l_tsid             := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      if p_start_time is not null then
         l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
      end if;

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_date_times is not null then
         l_date_times_utc := date_table_type();
         l_date_times_utc.extend(p_date_times.count);

         for i in 1 .. p_date_times.count loop
            l_date_times_utc(i) := cwms_util.change_timezone(p_date_times(i), l_time_zone, 'UTC');
         end loop;
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_ts_code          := cwms_ts.get_ts_code(l_tsid, l_office_code);

      l_times_utc        :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        l_date_times_utc,
                        l_version_date_utc,
                        l_max_version,
                        cwms_util.ts_std_text));

      select count(*)
        into l_count
        from at_tsv_std_text t, at_std_text s, table(l_times_utc) d
       where t.ts_code = l_ts_code
         and t.date_time = d.date_1
         and t.version_date = d.date_2
         and t.std_text_code = s.std_text_code
         and upper(s.std_text_id) like upper(l_std_text_id_mask) escape '\'
         and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
           or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute));

      l_times_utc.delete;
      return l_count;
   end get_ts_std_text_count;

   procedure delete_ts_std_text(
      p_tsid             in varchar2,
      p_std_text_id_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
   is
      l_office_id            varchar2(16);
      l_tsid                 varchar2(191);
      l_std_text_id_mask     varchar2(256);
      l_start_time_utc       date;
      l_end_time_utc         date;
      l_version_date_utc     date;
      l_time_zone            varchar2(28);
      l_ts_code              number(10);
      l_date_time_versions   date2_tab_t := date2_tab_t();
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_std_text_id_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_STD_TEXT_ID_MASK');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id        := cwms_util.get_db_office_id(p_office_id);
      l_tsid             := cwms_ts.get_ts_id(p_tsid, l_office_id);
      l_ts_code          := cwms_ts.get_ts_code(l_tsid, l_office_id);
      l_std_text_id_mask := cwms_util.normalize_wildcards(p_std_text_id_mask);
      l_time_zone        :=
         nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      l_start_time_utc   := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is null then
         l_end_time_utc := l_start_time_utc;
      else
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      -----------------------------------------
      -- get the existing times and versions --
      -----------------------------------------
      l_date_time_versions      :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        p_ts_code          => l_ts_code,
                        p_start_time_utc   => l_start_time_utc,
                        p_end_time_utc     => l_end_time_utc,
                        p_date_times_utc   => null,
                        p_version_date_utc => l_version_date_utc,
                        p_max_version      => cwms_util.return_true_or_false(p_max_version)));

      delete from at_tsv_std_text
            where rowid in
                     (select t.rowid
                        from table(l_date_time_versions) d, at_tsv_std_text t, at_std_text s
                       where t.ts_code = l_ts_code
                         and t.date_time = d.date_1
                         and t.version_date = d.date_2
                         and t.std_text_code = s.std_text_code
                         and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                           or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
                         and upper(s.std_text_id) like upper(l_std_text_id_mask) escape '\');

      l_date_time_versions.delete;
   end delete_ts_std_text;

   procedure store_ts_text(
      p_ts_code             in number,
      p_date_time_utc       in date,
      p_version_date_utc    in date,
      p_clob_code           in number,
      p_data_entry_date_utc in timestamp,
      p_attribute           in number)
   is
      l_rec       at_tsv_text%rowtype;
      l_office_id varchar2(16);
   begin
      select db_office_id
        into l_office_id
        from at_cwms_ts_id
       where ts_code = p_ts_code; 
      cwms_util.check_office_permission(l_office_id);
      l_rec.ts_code         := p_ts_code;
      l_rec.date_time       := p_date_time_utc;
      l_rec.version_date    := nvl(p_version_date_utc, cast(p_data_entry_date_utc as date));
      l_rec.clob_code       := p_clob_code;
      l_rec.data_entry_date := p_data_entry_date_utc;
      l_rec.attribute       := p_attribute;

      ----------------------------------
      -- see if record already exists --
      ----------------------------------
      select *
        into l_rec
        from at_tsv_text
       where ts_code = l_rec.ts_code
         and date_time = l_rec.date_time
         and version_date = l_rec.version_date
         and clob_code = l_rec.clob_code;

      ------------------------------------------------
      -- record exists, update it only if necessary --
      ------------------------------------------------
      if l_rec.attribute != p_attribute then
         l_rec.attribute := p_attribute;

         update at_tsv_text
            set row = l_rec;
      end if;
   exception
      when no_data_found then
         -------------------------------------
         -- record doesn't exist; create it --
         -------------------------------------
         insert into at_tsv_text
              values l_rec;
   end store_ts_text;

   procedure store_ts_text(
      p_ts_code           in integer,
      p_clob_code         in integer,
      p_date_times_utc    in date_table_type,
      p_version_dates_utc in date_table_type,
      p_version_date_utc  in date,
      p_max_version       in boolean,
      p_replace_all       in boolean,
      p_attribute         in number)
   is
      l_date_times           date_table_type;
      l_version_dates        date_table_type;
      l_regular_times        date_table_type;
      l_cursor               sys_refcursor;
      l_is_versioned_str     varchar2(1);
      l_is_versioned         boolean;
      l_off_interval_count   integer;
      l_store_date           timestamp := sys_extract_utc(systimestamp);
      l_office_id            varchar2(16);
   begin
      select db_office_id
        into l_office_id
        from at_cwms_ts_id
       where ts_code = p_ts_code; 
      cwms_util.check_office_permission(l_office_id);
      if p_version_dates_utc is null then
         ------------------------------------------------------------
         -- need to validate date/times and retrieve version dates --
         ------------------------------------------------------------
         cwms_ts.is_ts_versioned(l_is_versioned_str, p_ts_code);
         l_is_versioned := cwms_util.return_true_or_false(l_is_versioned_str);

         ------------------------------------------------------
         -- get valid times for regular interval time series --
         ------------------------------------------------------
         begin
            l_regular_times      :=
               cwms_ts.get_times_for_time_window(
                  p_date_times_utc(1),
                  p_date_times_utc(p_date_times_utc.count),
                  p_ts_code,
                  'UTC');
         exception
            when others then
               case
                  when instr(sqlerrm, 'irregular') > 0 then
                     null;
                  when instr(sqlerrm, 'undefined') > 0 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot set time series text for regular time series with undefined interval offset.');
                  else
                     raise;
               end case;
         end;

         if l_regular_times is not null then
            ---------------------------------------------------------
            -- verify valid times for regular interval time series --
            ---------------------------------------------------------
            select count(*)
              into l_off_interval_count
              from (select column_value from table(p_date_times_utc)
                    minus
                    select column_value from table(l_regular_times));

            if l_off_interval_count > 0 then
               cwms_err.raise(
                  'ERROR',
                  'Times include ' || l_off_interval_count || ' invalid time(s) for specified time series.');
            end if;
         end if;

         l_cursor       :=
            cwms_ts.retrieve_existing_times_f(
               p_ts_code          => p_ts_code,
               p_start_time_utc   => null,
               p_end_time_utc     => null,
               p_date_times_utc   => p_date_times_utc,
               p_version_date_utc => p_version_date_utc,
               p_max_version      => p_max_version);

         loop
            fetch l_cursor
            bulk collect into l_date_times, l_version_dates
            limit 50000;

            exit when l_date_times.count = 0;

            for i in 1 .. l_date_times.count loop
               ---------------------------------------
               -- delete existing text if necessary --
               ---------------------------------------
               if p_replace_all then
                  begin
                     delete from at_tsv_text
                           where ts_code = p_ts_code and date_time = l_date_times(i) and version_date = l_version_dates(i);
                  exception
                     when no_data_found then
                        null;
                  end;
               end if;

               --------------------------------------------
               -- store the text for existing date_times --
               --------------------------------------------
               store_ts_text(
                  p_ts_code,
                  l_date_times(i),
                  l_version_dates(i),
                  p_clob_code,
                  l_store_date,
                  p_attribute);
            end loop;
         end loop;

         close l_cursor;

         ------------------------------------------------
         -- store the text for non-existing date_times --
         ------------------------------------------------
         l_cursor       := null;
         l_date_times.delete;

         loop
            if l_cursor is null then
               open l_cursor for
                  select column_value
                    from table(p_date_times_utc)
                   where column_value not in (select date_time
                                                from cwms_v_tsv
                                               where ts_code = p_ts_code);
            else
               l_date_times.delete;
            end if;

            fetch l_cursor
            bulk collect into l_date_times
            limit 50000;

            exit when l_date_times.count = 0;

            for i in 1 .. l_date_times.count loop
               store_ts_text(
                  p_ts_code,
                  l_date_times(i),
                  case p_version_date_utc is null
                     when true then case l_is_versioned when true then null else cwms_util.non_versioned end
                     else p_version_date_utc
                  end,
                  p_clob_code,
                  l_store_date,
                  p_attribute);
            end loop;
         end loop;

         close l_cursor;
      else
         -----------------------------------------
         -- valid dates/times already retrieved --
         -----------------------------------------
         for i in 1 .. p_date_times_utc.count loop
            ---------------------------------------
            -- delete existing text if necessary --
            ---------------------------------------
            if p_replace_all then
               begin
                  delete from at_tsv_text
                        where ts_code = p_ts_code and date_time = p_date_times_utc(i) and version_date = p_version_dates_utc(i);
               exception
                  when no_data_found then
                     null;
               end;
            end if;
            store_ts_text(
               p_ts_code,
               p_date_times_utc(i),
               p_version_dates_utc(i),
               p_clob_code,
               l_store_date,
               p_attribute);
         end loop;
      end if;
   end store_ts_text;

   procedure store_ts_text(
      p_tsid         in varchar2,
      p_text         in clob,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_clob_code          number(10);
      l_start_time_utc     date;
      l_end_time_utc       date := sysdate;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_existing           boolean;
      l_non_existing       boolean;
      l_is_versioned       boolean;
      l_is_regular         boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
      l_version_id         varchar2(32);
      l_cursor             sys_refcursor;
      l_store_date         timestamp := cast(systimestamp at time zone 'UTC' as timestamp);
      l_date_times         date_table_type;
      l_version_dates      date_table_type;
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_text is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      if p_version_date = cwms_util.all_version_dates then
         cwms_err.raise('ERROR', 'Cannot specify all version dates in this call.');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version    := cwms_util.return_true_or_false(p_max_version);
      l_existing       := cwms_util.return_true_or_false(p_existing);
      l_non_existing   := cwms_util.return_true_or_false(p_non_existing);
      l_replace_all    := cwms_util.return_true_or_false(p_replace_all);
      l_office_id      := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      l_tsid           := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_is_regular     := cwms_ts.get_ts_interval(l_tsid) > 0;

      if l_is_regular and not l_existing and not l_non_existing then
         return;
      end if;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            ----------------------------------------------------------------
            -- time series doesn't exist - abort on irregular time series --
            ----------------------------------------------------------------
            if not l_is_regular then
               cwms_err.raise(
                  'ERROR',
                  'Cannot use this version of STORE_TS_TEXT to store text to a non-existent irregular time series');
            end if;

            ----------------------------------------------------------------------------------------
            -- don't create regular time series if we're not going to store to non-existing times --
            ----------------------------------------------------------------------------------------
            if not l_non_existing then
               return;
            end if;

            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the start time --
            -----------------------------------------------------------------------------------------
            cwms_ts.create_ts_code(
               p_ts_code    => l_ts_code,
               p_office_id  => l_office_id,
               p_cwms_ts_id => l_tsid,
               p_utc_offset => cwms_ts.get_utc_interval_offset(l_start_time_utc, cwms_ts.get_ts_interval(l_tsid)));
      end;

      l_is_versioned   := cwms_util.return_true_or_false(cwms_ts.is_tsid_versioned_f(l_tsid, l_office_id));

      l_clob_code      := cwms_seq.nextval;

      insert into at_clob
           values (
                     l_clob_code,
                     l_office_code,
                     '/TIME SERIES TEXT/' || l_clob_code,
                     null,
                     p_text);

      ------------------------
      -- get the date/times --
      ------------------------
      if l_is_regular then
         -------------------------
         -- regular time series --
         -------------------------
         if l_non_existing then
            if l_existing then
               ----------------------------------------------
               -- store to existing and non-existing times --
               ----------------------------------------------
               l_date_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
            else
               --------------------------------------
               -- store to non-existing times only --
               --------------------------------------
               declare
                  l_regular_times    date_table_type;
                  l_existing_times   date_table_type;
               begin
                  l_regular_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
                  l_cursor        :=
                     cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        null,
                        l_version_date_utc,
                        l_max_version);

                  fetch l_cursor
                  bulk collect into l_existing_times, l_version_dates;

                  close l_cursor;

                    select column_value
                      bulk collect into l_date_times
                      from (select column_value from table(l_regular_times)
                            minus
                            select column_value from table(l_existing_times))
                  order by column_value;
               end;
            end if;
         else
            ----------------------------------
            -- store to existing times only --
            ----------------------------------
            l_cursor      :=
               cwms_ts.retrieve_existing_times_f(
                  l_ts_code,
                  l_start_time_utc,
                  l_end_time_utc,
                  null,
                  l_version_date_utc,
                  l_max_version);

            fetch l_cursor
            bulk collect into l_date_times, l_version_dates;

            close l_cursor;
         end if;
      else
         ---------------------------
         -- irregular time series --
         ---------------------------
         l_cursor      :=
            cwms_ts.retrieve_existing_times_f(
               l_ts_code,
               l_start_time_utc,
               l_end_time_utc,
               null,
               l_version_date_utc,
               l_max_version);

         fetch l_cursor
         bulk collect into l_date_times, l_version_dates;

         close l_cursor;
      end if;

      --------------------
      -- store the text --
      --------------------
      store_ts_text(
         l_ts_code,
         l_clob_code,
         l_date_times,
         l_version_dates,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_text;

   procedure store_ts_text(
      p_tsid         in varchar2,
      p_text         in clob,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_clob_code          number(10);
      l_times_utc          date_table_type := date_table_type();
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_is_versioned       boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
   begin
      cwms_util.check_office_permission(p_office_id);
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_text is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT');
      end if;

      if p_times is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TIMES');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id   := cwms_util.get_db_office_id(p_office_id);
      l_office_code := cwms_util.get_db_office_code(l_office_id);
      l_tsid        := cwms_ts.get_ts_id(p_tsid, l_office_id);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_replace_all := cwms_util.return_true_or_false(p_replace_all);
      l_max_version := cwms_util.return_true_or_false(p_max_version);

      l_clob_code   := cwms_seq.nextval;

      insert into at_clob
           values (
                     l_clob_code,
                     l_office_code,
                     '/TIME SERIES TEXT/' || l_clob_code,
                     null,
                     p_text);

      l_times_utc.extend(p_times.count);

      for i in 1 .. p_times.count loop
         l_times_utc(i) := cwms_util.change_timezone(p_times(i), l_time_zone, 'UTC');
      end loop;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the first time --
            -----------------------------------------------------------------------------------------
            if cwms_ts.get_ts_interval(l_tsid) > 0 then
               cwms_ts.create_ts_code(
                  p_ts_code    => l_ts_code,
                  p_office_id  => l_office_id,
                  p_cwms_ts_id => l_tsid,
                  p_utc_offset => cwms_ts.get_utc_interval_offset(l_times_utc(1), cwms_ts.get_ts_interval(l_tsid)));
            else
               cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_office_id => l_office_id, p_cwms_ts_id => l_tsid);
            end if;
      end;

      --------------------
      -- store the text --
      --------------------
      store_ts_text(
         l_ts_code,
         l_clob_code,
         l_times_utc,
         null,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_text;

   procedure store_ts_text_id(
      p_tsid         in varchar2,
      p_text_id      in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_clob_code          number(10);
      l_start_time_utc     date;
      l_end_time_utc       date := sysdate;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_existing           boolean;
      l_non_existing       boolean;
      l_is_versioned       boolean;
      l_is_regular         boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
      l_version_id         varchar2(32);
      l_cursor             sys_refcursor;
      l_store_date         timestamp := cast(systimestamp at time zone 'UTC' as timestamp);
      l_date_times         date_table_type;
      l_version_dates      date_table_type;
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_text_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT_ID');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      if p_version_date = cwms_util.all_version_dates then
         cwms_err.raise('ERROR', 'Cannot specify all version dates in this call.');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version    := cwms_util.return_true_or_false(p_max_version);
      l_existing       := cwms_util.return_true_or_false(p_existing);
      l_non_existing   := cwms_util.return_true_or_false(p_non_existing);
      l_replace_all    := cwms_util.return_true_or_false(p_replace_all);
      l_office_id      := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      select clob_code
        into l_clob_code
        from at_clob
       where office_code = l_office_code and id = upper(trim(p_text_id));

      l_tsid           := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_is_regular     := cwms_ts.get_ts_interval(l_tsid) > 0;

      if l_is_regular and not l_existing and not l_non_existing then
         return;
      end if;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            ----------------------------------------------------------------
            -- time series doesn't exist - abort on irregular time series --
            ----------------------------------------------------------------
            if not l_is_regular then
               cwms_err.raise(
                  'ERROR',
                  'Cannot use this version of STORE_TS_TEXT to store text to a non-existent irregular time series');
            end if;

            ----------------------------------------------------------------------------------------
            -- don't create regular time series if we're not going to store to non-existing times --
            ----------------------------------------------------------------------------------------
            if not l_non_existing then
               return;
            end if;

            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the start time --
            -----------------------------------------------------------------------------------------
            cwms_ts.create_ts_code(
               p_ts_code    => l_ts_code,
               p_office_id  => l_office_id,
               p_cwms_ts_id => l_tsid,
               p_utc_offset => cwms_ts.get_utc_interval_offset(l_start_time_utc, cwms_ts.get_ts_interval(l_tsid)));
      end;

      l_is_versioned   := cwms_util.return_true_or_false(cwms_ts.is_tsid_versioned_f(l_tsid, l_office_id));

      ------------------------
      -- get the date/times --
      ------------------------
      if l_is_regular then
         -------------------------
         -- regular time series --
         -------------------------
         if l_non_existing then
            if l_existing then
               ----------------------------------------------
               -- store to existing and non-existing times --
               ----------------------------------------------
               l_date_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
            else
               --------------------------------------
               -- store to non-existing times only --
               --------------------------------------
               declare
                  l_regular_times    date_table_type;
                  l_existing_times   date_table_type;
               begin
                  l_regular_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
                  l_cursor        :=
                     cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        null,
                        l_version_date_utc,
                        l_max_version);

                  fetch l_cursor
                  bulk collect into l_existing_times, l_version_dates;

                  close l_cursor;

                    select column_value
                      bulk collect into l_date_times
                      from (select column_value from table(l_regular_times)
                            minus
                            select column_value from table(l_existing_times))
                  order by column_value;
               end;
            end if;
         else
            ----------------------------------
            -- store to existing times only --
            ----------------------------------
            l_cursor      :=
               cwms_ts.retrieve_existing_times_f(
                  l_ts_code,
                  l_start_time_utc,
                  l_end_time_utc,
                  null,
                  l_version_date_utc,
                  l_max_version);

            fetch l_cursor
            bulk collect into l_date_times, l_version_dates;

            close l_cursor;
         end if;
      else
         ---------------------------
         -- irregular time series --
         ---------------------------
         l_cursor      :=
            cwms_ts.retrieve_existing_times_f(
               l_ts_code,
               l_start_time_utc,
               l_end_time_utc,
               null,
               l_version_date_utc,
               l_max_version);

         fetch l_cursor
         bulk collect into l_date_times, l_version_dates;

         close l_cursor;
      end if;

      --------------------
      -- store the text --
      --------------------
      store_ts_text(
         l_ts_code,
         l_clob_code,
         l_date_times,
         l_version_dates,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_text_id;

   procedure store_ts_text_id(
      p_tsid         in varchar2,
      p_text_id      in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_clob_code          number(10);
      l_times_utc          date_table_type := date_table_type();
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_is_versioned       boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_text_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT_ID');
      end if;

      if p_times is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TIMES');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id   := cwms_util.get_db_office_id(p_office_id);
      l_tsid        := cwms_ts.get_ts_id(p_tsid, l_office_id);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_replace_all := cwms_util.return_true_or_false(p_replace_all);
      l_max_version := cwms_util.return_true_or_false(p_max_version);

      l_times_utc.extend(p_times.count);

      for i in 1 .. p_times.count loop
         l_times_utc(i) := cwms_util.change_timezone(p_times(i), l_time_zone, 'UTC');
      end loop;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      select clob_code
        into l_clob_code
        from at_clob
       where office_code = l_office_code and id = upper(trim(p_text_id));

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the first time --
            -----------------------------------------------------------------------------------------
            if cwms_ts.get_ts_interval(l_tsid) > 0 then
               cwms_ts.create_ts_code(
                  p_ts_code    => l_ts_code,
                  p_office_id  => l_office_id,
                  p_cwms_ts_id => l_tsid,
                  p_utc_offset => cwms_ts.get_utc_interval_offset(l_times_utc(1), cwms_ts.get_ts_interval(l_tsid)));
            else
               cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_office_id => l_office_id, p_cwms_ts_id => l_tsid);
            end if;
      end;

      --------------------
      -- store the text --
      --------------------
      store_ts_text(
         l_ts_code,
         l_clob_code,
         l_times_utc,
         null,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_text_id;

   procedure retrieve_ts_text(
      p_cursor           out sys_refcursor,
      p_tsid          in     varchar2,
      p_text_mask     in     varchar2,
      p_start_time    in     date,
      p_end_time      in     date default null,
      p_version_date  in     date default null,
      p_time_zone     in     varchar2 default null,
      p_max_version   in     varchar2 default 'T',
      p_min_attribute in     number default null,
      p_max_attribute in     number default null,
      p_office_id     in     varchar2 default null)
   is
   begin
      p_cursor      :=
         retrieve_ts_text_f(
            p_tsid,
            p_text_mask,
            p_start_time,
            p_end_time,
            p_version_date,
            p_time_zone,
            p_max_version,
            p_min_attribute,
            p_max_attribute,
            p_office_id);
   end retrieve_ts_text;

   function retrieve_ts_text_f(
      p_tsid          in varchar2,
      p_text_mask     in varchar2,
      p_start_time    in date,
      p_end_time      in date default null,
      p_version_date  in date default null,
      p_time_zone     in varchar2 default null,
      p_max_version   in varchar2 default 'T',
      p_min_attribute in number default null,
      p_max_attribute in number default null,
      p_office_id     in varchar2 default null)
      return sys_refcursor
   is
      l_office_id            varchar2(16);
      l_tsid                 varchar2(191);
      l_text_mask            varchar2(256);
      l_start_time_utc       date;
      l_end_time_utc         date;
      l_version_date_utc     date;
      l_time_zone            varchar2(28);
      l_ts_code              number(10);
      l_cursor               sys_refcursor;
      l_date_time_versions   date2_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_text_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT_MASK');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id      := cwms_util.get_db_office_id(p_office_id);
      l_tsid           := cwms_ts.get_ts_id(p_tsid, l_office_id);
      l_ts_code        := cwms_ts.get_ts_code(l_tsid, l_office_id);
      l_text_mask      := cwms_util.normalize_wildcards(p_text_mask);
      l_time_zone      := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is null then
         l_end_time_utc := l_start_time_utc;
      else
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      -----------------------------------------
      -- get the existing times and versions --
      -----------------------------------------
      l_date_time_versions      :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        p_ts_code          => l_ts_code,
                        p_start_time_utc   => l_start_time_utc,
                        p_end_time_utc     => l_end_time_utc,
                        p_date_times_utc   => null,
                        p_version_date_utc => l_version_date_utc,
                        p_max_version      => cwms_util.return_true_or_false(p_max_version)));

      ------------------
      -- get the text --
      ------------------
      open l_cursor for
           select cwms_util.change_timezone(d.date_1, 'UTC', l_time_zone) as date_time,
                  cwms_util.change_timezone(d.date_2, 'UTC', case 
                                                             when d.date_2 = cwms_util.non_versioned then 'UTC' 
                                                             else l_time_zone 
                                                             end) as version_date,
                  cwms_util.change_timezone(t.data_entry_date, 'UTC', l_time_zone) as data_entry_date,
                  c.id as text_id,
                  t.attribute,
                  c.value as text
             from table(l_date_time_versions) d, at_tsv_text t, at_clob c
            where t.ts_code = l_ts_code
              and t.date_time = d.date_1
              and t.version_date = d.date_2
              and t.clob_code = c.clob_code
              and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
              and upper(c.value) like upper(l_text_mask) escape '\'
         order by d.date_1,
                  d.date_2,
                  t.attribute,
                  t.data_entry_date;

      return l_cursor;
   end retrieve_ts_text_f;

   function get_ts_text_count(
      p_tsid          in varchar2,
      p_text_mask     in varchar2,
      p_start_time    in date,
      p_end_time      in date default null,
      p_date_times    in date_table_type default null,
      p_version_date  in date default null,
      p_time_zone     in varchar2 default null,
      p_max_version   in varchar2 default 'T',
      p_min_attribute in number default null,
      p_max_attribute in number default null,
      p_office_id     in varchar2 default null)
      return pls_integer
   is
      l_office_id          varchar2(16);
      l_tsid               varchar2(191);
      l_text_mask          varchar2(16);
      l_start_time_utc     date;
      l_end_time_utc       date;
      l_date_times_utc     date_table_type;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_max_version        boolean;
      l_office_code        number(10);
      l_ts_code            number(10);
      l_times_utc          date2_tab_t;
      l_count              pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_text_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT_MASK');
      end if;

      if p_start_time is null and p_date_times is null then
         cwms_err.raise('ERROR', 'One of P_START_TIME or P_DATE_TIMES must be non-NULL');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version := cwms_util.return_true_or_false(p_max_version);
      l_text_mask   := cwms_util.normalize_wildcards(p_text_mask);
      l_office_id   := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      l_tsid        := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      if p_start_time is not null then
         l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
      end if;

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_date_times is not null then
         l_date_times_utc := date_table_type();
         l_date_times_utc.extend(p_date_times.count);

         for i in 1 .. p_date_times.count loop
            l_date_times_utc(i) := cwms_util.change_timezone(p_date_times(i), l_time_zone, 'UTC');
         end loop;
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_ts_code     := cwms_ts.get_ts_code(l_tsid, l_office_code);

      l_times_utc      :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        l_date_times_utc,
                        l_version_date_utc,
                        l_max_version,
                        cwms_util.ts_text));

      select count(*)
        into l_count
        from at_tsv_text t, at_clob c, table(l_times_utc) d
       where t.ts_code = l_ts_code
         and t.date_time = d.date_1
         and t.version_date = d.date_2
         and t.clob_code = c.clob_code
         and upper(c.value) like upper(l_text_mask) escape '\'
         and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
           or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute));

      l_times_utc.delete;
      return l_count;
   end get_ts_text_count;

   procedure delete_ts_text(
      p_tsid          in varchar2,
      p_text_mask     in varchar2,
      p_start_time    in date,
      p_end_time      in date default null,
      p_version_date  in date default null,
      p_time_zone     in varchar2 default null,
      p_max_version   in varchar2 default 'T',
      p_min_attribute in number default null,
      p_max_attribute in number default null,
      p_office_id     in varchar2 default null)
   is
      l_office_id            varchar2(16);
      l_tsid                 varchar2(191);
      l_text_mask            varchar2(256);
      l_start_time_utc       date;
      l_end_time_utc         date;
      l_version_date_utc     date;
      l_time_zone            varchar2(28);
      l_ts_code              number(10);
      l_date_time_versions   date2_tab_t := date2_tab_t();
   begin
      cwms_util.check_office_permission(p_office_id);
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_text_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT_MASK');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id      := cwms_util.get_db_office_id(p_office_id);
      l_tsid           := cwms_ts.get_ts_id(p_tsid, l_office_id);
      l_ts_code        := cwms_ts.get_ts_code(l_tsid, l_office_id);
      l_text_mask      := cwms_util.normalize_wildcards(p_text_mask);
      l_time_zone      := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is null then
         l_end_time_utc := l_start_time_utc;
      else
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      -----------------------------------------
      -- get the existing times and versions --
      -----------------------------------------
      l_date_time_versions      :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        p_ts_code          => l_ts_code,
                        p_start_time_utc   => l_start_time_utc,
                        p_end_time_utc     => l_end_time_utc,
                        p_date_times_utc   => null,
                        p_version_date_utc => l_version_date_utc,
                        p_max_version      => cwms_util.return_true_or_false(p_max_version)));

      delete from at_tsv_text
            where rowid in
                     (select t.rowid
                        from table(l_date_time_versions) d, at_tsv_text t, at_clob c
                       where t.ts_code = l_ts_code
                         and t.date_time = d.date_1
                         and t.version_date = d.date_2
                         and t.clob_code = c.clob_code
                         and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                           or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
                         and upper(c.value) like upper(l_text_mask) escape '\');

      l_date_time_versions.delete;
   end delete_ts_text;

   procedure delete_ts_text(
      p_text_id       in varchar2,
      p_delete_action in varchar2 default cwms_util.delete_key,
      p_office_id     in varchar2)
   is
      l_office_code     number(10);
      l_clob_code       number(10);
      l_delete_action   varchar2(22);
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_text_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TEXT_ID');
      end if;

      if p_delete_action is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_DELETE_ACTION');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_delete_action      :=
         case
            when p_delete_action in (cwms_util.delete_key, cwms_util.delete_ts_id) then cwms_util.delete_key
            when p_delete_action in (cwms_util.delete_data, cwms_util.delete_ts_data) then cwms_util.delete_data
            when p_delete_action in (cwms_util.delete_all, cwms_util.delete_ts_cascade) then cwms_util.delete_all
            else null
         end;

      if l_delete_action is null then
         cwms_err.raise('INVALID_DELETE_ACTION');
      end if;

      l_office_code := cwms_util.get_db_office_code(p_office_id);

      select clob_code
        into l_clob_code
        from at_clob
       where office_code = l_office_code and upper(id) = upper(trim(p_text_id));

      if l_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
         delete from at_tsv_text
               where clob_code = l_clob_code;
      end if;

      if l_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
         delete from at_clob
               where clob_code = l_clob_code;
      end if;
   end delete_ts_text;

   procedure store_ts_binary(
      p_ts_code             in number,
      p_date_time_utc       in date,
      p_version_date_utc    in date,
      p_blob_code           in number,
      p_data_entry_date_utc in timestamp,
      p_attribute           in number)
   is
      l_rec       at_tsv_binary%rowtype;
      l_office_id varchar2(16);
   begin
      select db_office_id
        into l_office_id
        from at_cwms_ts_id
       where ts_code = p_ts_code; 
      cwms_util.check_office_permission(l_office_id);
      l_rec.ts_code         := p_ts_code;
      l_rec.date_time       := p_date_time_utc;
      l_rec.version_date    := nvl(p_version_date_utc, cast(p_data_entry_date_utc as date));
      l_rec.blob_code       := p_blob_code;
      l_rec.data_entry_date := p_data_entry_date_utc;
      l_rec.attribute       := p_attribute;

      ----------------------------------
      -- see if record already exists --
      ----------------------------------
      select *
        into l_rec
        from at_tsv_binary
       where ts_code = l_rec.ts_code
         and date_time = l_rec.date_time
         and version_date = l_rec.version_date
         and blob_code = l_rec.blob_code;

      ------------------------------------------------
      -- record exists, update it only if necessary --
      ------------------------------------------------
      if l_rec.attribute != p_attribute then
         l_rec.attribute := p_attribute;

         update at_tsv_binary
            set row = l_rec;
      end if;
   exception
      when no_data_found then
         -------------------------------------
         -- record doesn't exist; create it --
         -------------------------------------
         insert into at_tsv_binary
              values l_rec;
   end store_ts_binary;

   procedure store_ts_binary(
      p_ts_code           in integer,
      p_blob_code         in integer,
      p_date_times_utc    in date_table_type,
      p_version_dates_utc in date_table_type,
      p_version_date_utc  in date,
      p_max_version       in boolean,
      p_replace_all       in boolean,
      p_attribute         in number)
   is
      l_date_times           date_table_type;
      l_version_dates        date_table_type;
      l_regular_times        date_table_type;
      l_cursor               sys_refcursor;
      l_is_versioned_str     varchar2(1);
      l_is_versioned         boolean;
      l_off_interval_count   integer;
      l_store_date           timestamp := sys_extract_utc(systimestamp);
      l_office_id            varchar2(16);
   begin
      select db_office_id
        into l_office_id
        from at_cwms_ts_id
       where ts_code = p_ts_code; 
      cwms_util.check_office_permission(l_office_id);
      if p_version_dates_utc is null then
         ------------------------------------------------------------
         -- need to validate date/times and retrieve version dates --
         ------------------------------------------------------------
         cwms_ts.is_ts_versioned(l_is_versioned_str, p_ts_code);
         l_is_versioned := cwms_util.return_true_or_false(l_is_versioned_str);

         ------------------------------------------------------
         -- get valid times for regular interval time series --
         ------------------------------------------------------
         begin
            l_regular_times      :=
               cwms_ts.get_times_for_time_window(
                  p_date_times_utc(1),
                  p_date_times_utc(p_date_times_utc.count),
                  p_ts_code,
                  'UTC');
         exception
            when others then
               case
                  when instr(sqlerrm, 'irregular') > 0 then
                     null;
                  when instr(sqlerrm, 'undefined') > 0 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot set time series binary data for regular time series with undefined interval offset.');
                  else
                     raise;
               end case;
         end;

         if l_regular_times is not null then
            ---------------------------------------------------------
            -- verify valid times for regular interval time series --
            ---------------------------------------------------------
            select count(*)
              into l_off_interval_count
              from (select column_value from table(p_date_times_utc)
                    minus
                    select column_value from table(l_regular_times));

            if l_off_interval_count > 0 then
               cwms_err.raise(
                  'ERROR',
                  'Times include ' || l_off_interval_count || ' invalid time(s) for specified time series.');
            end if;
         end if;

         l_cursor       :=
            cwms_ts.retrieve_existing_times_f(
               p_ts_code          => p_ts_code,
               p_start_time_utc   => null,
               p_end_time_utc     => null,
               p_date_times_utc   => p_date_times_utc,
               p_version_date_utc => p_version_date_utc,
               p_max_version      => p_max_version);

         loop
            fetch l_cursor
            bulk collect into l_date_times, l_version_dates
            limit 50000;

            exit when l_date_times.count = 0;

            for i in 1 .. l_date_times.count loop
               ----------------------------------------------
               -- delete existing binary data if necessary --
               ----------------------------------------------
               if p_replace_all then
                  begin
                     delete from at_tsv_binary
                           where ts_code = p_ts_code and date_time = l_date_times(i) and version_date = l_version_dates(i);
                  exception
                     when no_data_found then
                        null;
                  end;
               end if;

               ---------------------------------------------------
               -- store the binary data for existing date_times --
               ---------------------------------------------------
               store_ts_binary(
                  p_ts_code,
                  l_date_times(i),
                  l_version_dates(i),
                  p_blob_code,
                  l_store_date,
                  p_attribute);
            end loop;
         end loop;

         close l_cursor;

         -------------------------------------------------------
         -- store the binary data for non-existing date_times --
         -------------------------------------------------------
         l_cursor       := null;
         l_date_times.delete;

         loop
            if l_cursor is null then
               open l_cursor for
                  select column_value
                    from table(p_date_times_utc)
                   where column_value not in (select date_time
                                                from cwms_v_tsv
                                               where ts_code = p_ts_code);
            else
               l_date_times.delete;
            end if;

            fetch l_cursor
            bulk collect into l_date_times
            limit 50000;

            exit when l_date_times.count = 0;

            for i in 1 .. l_date_times.count loop
               store_ts_binary(
                  p_ts_code,
                  l_date_times(i),
                  case p_version_date_utc is null
                     when true then case l_is_versioned when true then null else cwms_util.non_versioned end
                     else p_version_date_utc
                  end,
                  p_blob_code,
                  l_store_date,
                  p_attribute);
            end loop;
         end loop;

         close l_cursor;
      else
         -----------------------------------------
         -- valid dates/times already retrieved --
         -----------------------------------------
         for i in 1 .. p_date_times_utc.count loop
            store_ts_binary(
               p_ts_code,
               p_date_times_utc(i),
               p_version_dates_utc(i),
               p_blob_code,
               l_store_date,
               p_attribute);
         end loop;
      end if;
   end store_ts_binary;

   procedure store_ts_binary(
      p_tsid         in varchar2,
      p_binary       in blob,
      p_binary_type  in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_blob_code          number(10);
      l_media_type_code    number(10);
      l_start_time_utc     date;
      l_end_time_utc       date := sysdate;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_existing           boolean;
      l_non_existing       boolean;
      l_is_versioned       boolean;
      l_is_regular         boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
      l_version_id         varchar2(32);
      l_cursor             sys_refcursor;
      l_store_date         timestamp := cast(systimestamp at time zone 'UTC' as timestamp);
      l_date_times         date_table_type;
      l_version_dates      date_table_type;
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_binary is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY');
      end if;

      if p_binary_type is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_TYPE');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      if p_version_date = cwms_util.all_version_dates then
         cwms_err.raise('ERROR', 'Cannot specify all version dates in this call.');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version     := cwms_util.return_true_or_false(p_max_version);
      l_existing        := cwms_util.return_true_or_false(p_existing);
      l_non_existing    := cwms_util.return_true_or_false(p_non_existing);
      l_replace_all     := cwms_util.return_true_or_false(p_replace_all);
      l_office_id       := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      l_media_type_code := get_media_type_code(p_binary_type, l_office_code);

      l_tsid            := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_start_time_utc  := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_is_regular      := cwms_ts.get_ts_interval(l_tsid) > 0;

      if l_is_regular and not l_existing and not l_non_existing then
         return;
      end if;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            ----------------------------------------------------------------
            -- time series doesn't exist - abort on irregular time series --
            ----------------------------------------------------------------
            if not l_is_regular then
               cwms_err.raise(
                  'ERROR',
                  'Cannot use this version of STORE_TS_BINARY to store binary to a non-existent irregular time series');
            end if;

            ----------------------------------------------------------------------------------------
            -- don't create regular time series if we're not going to store to non-existing times --
            ----------------------------------------------------------------------------------------
            if not l_non_existing then
               return;
            end if;

            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the start time --
            -----------------------------------------------------------------------------------------
            cwms_ts.create_ts_code(
               p_ts_code    => l_ts_code,
               p_office_id  => l_office_id,
               p_cwms_ts_id => l_tsid,
               p_utc_offset => cwms_ts.get_utc_interval_offset(l_start_time_utc, cwms_ts.get_ts_interval(l_tsid)));
      end;

      l_is_versioned    := cwms_util.return_true_or_false(cwms_ts.is_tsid_versioned_f(l_tsid, l_office_id));

      l_blob_code       := cwms_seq.nextval;

      insert into at_blob
           values (
                     l_blob_code,
                     l_office_code,
                     '/TIME SERIES BINARY/' || l_blob_code,
                     null,
                     l_media_type_code,
                     p_binary);

      ------------------------
      -- get the date/times --
      ------------------------
      if l_is_regular then
         -------------------------
         -- regular time series --
         -------------------------
         if l_non_existing then
            if l_existing then
               ----------------------------------------------
               -- store to existing and non-existing times --
               ----------------------------------------------
               l_date_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
            else
               --------------------------------------
               -- store to non-existing times only --
               --------------------------------------
               declare
                  l_regular_times    date_table_type;
                  l_existing_times   date_table_type;
               begin
                  l_regular_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
                  l_cursor        :=
                     cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        null,
                        l_version_date_utc,
                        l_max_version);

                  fetch l_cursor
                  bulk collect into l_existing_times, l_version_dates;

                  close l_cursor;

                    select column_value
                      bulk collect into l_date_times
                      from (select column_value from table(l_regular_times)
                            minus
                            select column_value from table(l_existing_times))
                  order by column_value;
               end;
            end if;
         else
            ----------------------------------
            -- store to existing times only --
            ----------------------------------
            l_cursor      :=
               cwms_ts.retrieve_existing_times_f(
                  l_ts_code,
                  l_start_time_utc,
                  l_end_time_utc,
                  null,
                  l_version_date_utc,
                  l_max_version);

            fetch l_cursor
            bulk collect into l_date_times, l_version_dates;

            close l_cursor;
         end if;
      else
         ---------------------------
         -- irregular time series --
         ---------------------------
         l_cursor      :=
            cwms_ts.retrieve_existing_times_f(
               l_ts_code,
               l_start_time_utc,
               l_end_time_utc,
               null,
               l_version_date_utc,
               l_max_version);

         fetch l_cursor
         bulk collect into l_date_times, l_version_dates;

         close l_cursor;
      end if;

      ---------------------------
      -- store the binary data --
      ---------------------------
      store_ts_binary(
         l_ts_code,
         l_blob_code,
         l_date_times,
         l_version_dates,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_binary;

   procedure store_ts_binary(
      p_tsid         in varchar2,
      p_binary       in blob,
      p_binary_type  in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_blob_code          number(10);
      l_media_type_code    number(10);
      l_times_utc          date_table_type := date_table_type();
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_is_versioned       boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_binary is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY');
      end if;

      if p_binary_type is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_TYPE');
      end if;

      if p_times is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TIMES');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id       := cwms_util.get_db_office_id(p_office_id);
      l_office_code     := cwms_util.get_db_office_code(l_office_id);
      l_media_type_code := get_media_type_code(p_binary_type, l_office_code);
      l_tsid            := cwms_ts.get_ts_id(p_tsid, l_office_id);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_replace_all     := cwms_util.return_true_or_false(p_replace_all);
      l_max_version     := cwms_util.return_true_or_false(p_max_version);

      l_blob_code       := cwms_seq.nextval;

      insert into at_blob
           values (
                     l_blob_code,
                     l_office_code,
                     '/TIME SERIES binary/' || l_blob_code,
                     null,
                     l_media_type_code,
                     p_binary);

      l_times_utc.extend(p_times.count);

      for i in 1 .. p_times.count loop
         l_times_utc(i) := cwms_util.change_timezone(p_times(i), l_time_zone, 'UTC');
      end loop;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the first time --
            -----------------------------------------------------------------------------------------
            if cwms_ts.get_ts_interval(l_tsid) > 0 then
               cwms_ts.create_ts_code(
                  p_ts_code    => l_ts_code,
                  p_office_id  => l_office_id,
                  p_cwms_ts_id => l_tsid,
                  p_utc_offset => cwms_ts.get_utc_interval_offset(l_times_utc(1), cwms_ts.get_ts_interval(l_tsid)));
            else
               cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_office_id => l_office_id, p_cwms_ts_id => l_tsid);
            end if;
      end;

      --------------------
      -- store the binary --
      --------------------
      store_ts_binary(
         l_ts_code,
         l_blob_code,
         l_times_utc,
         null,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_binary;

   procedure store_ts_binary_id(
      p_tsid         in varchar2,
      p_binary_id    in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_blob_code          number(10);
      l_start_time_utc     date;
      l_end_time_utc       date := sysdate;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_existing           boolean;
      l_non_existing       boolean;
      l_is_versioned       boolean;
      l_is_regular         boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
      l_version_id         varchar2(32);
      l_cursor             sys_refcursor;
      l_store_date         timestamp := cast(systimestamp at time zone 'UTC' as timestamp);
      l_date_times         date_table_type;
      l_version_dates      date_table_type;
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_binary_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_ID');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      if p_version_date = cwms_util.all_version_dates then
         cwms_err.raise('ERROR', 'Cannot specify all version dates in this call.');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version    := cwms_util.return_true_or_false(p_max_version);
      l_existing       := cwms_util.return_true_or_false(p_existing);
      l_non_existing   := cwms_util.return_true_or_false(p_non_existing);
      l_replace_all    := cwms_util.return_true_or_false(p_replace_all);
      l_office_id      := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      select blob_code
        into l_blob_code
        from at_blob
       where office_code = l_office_code and id = upper(trim(p_binary_id));

      l_tsid           := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_is_regular     := cwms_ts.get_ts_interval(l_tsid) > 0;

      if l_is_regular and not l_existing and not l_non_existing then
         return;
      end if;

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            ----------------------------------------------------------------
            -- time series doesn't exist - abort on irregular time series --
            ----------------------------------------------------------------
            if not l_is_regular then
               cwms_err.raise(
                  'ERROR',
                  'Cannot use this version of STORE_TS_BINARY to store binary to a non-existent irregular time series');
            end if;

            ----------------------------------------------------------------------------------------
            -- don't create regular time series if we're not going to store to non-existing times --
            ----------------------------------------------------------------------------------------
            if not l_non_existing then
               return;
            end if;

            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the start time --
            -----------------------------------------------------------------------------------------
            cwms_ts.create_ts_code(
               p_ts_code    => l_ts_code,
               p_office_id  => l_office_id,
               p_cwms_ts_id => l_tsid,
               p_utc_offset => cwms_ts.get_utc_interval_offset(l_start_time_utc, cwms_ts.get_ts_interval(l_tsid)));
      end;

      l_is_versioned   := cwms_util.return_true_or_false(cwms_ts.is_tsid_versioned_f(l_tsid, l_office_id));

      ------------------------
      -- get the date/times --
      ------------------------
      if l_is_regular then
         -------------------------
         -- regular time series --
         -------------------------
         if l_non_existing then
            if l_existing then
               ----------------------------------------------
               -- store to existing and non-existing times --
               ----------------------------------------------
               l_date_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
            else
               --------------------------------------
               -- store to non-existing times only --
               --------------------------------------
               declare
                  l_regular_times    date_table_type;
                  l_existing_times   date_table_type;
               begin
                  l_regular_times := cwms_ts.get_times_for_time_window(l_start_time_utc, l_end_time_utc, l_ts_code);
                  l_cursor        :=
                     cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        null,
                        l_version_date_utc,
                        l_max_version);

                  fetch l_cursor
                  bulk collect into l_existing_times, l_version_dates;

                  close l_cursor;

                    select column_value
                      bulk collect into l_date_times
                      from (select column_value from table(l_regular_times)
                            minus
                            select column_value from table(l_existing_times))
                  order by column_value;
               end;
            end if;
         else
            ----------------------------------
            -- store to existing times only --
            ----------------------------------
            l_cursor      :=
               cwms_ts.retrieve_existing_times_f(
                  l_ts_code,
                  l_start_time_utc,
                  l_end_time_utc,
                  null,
                  l_version_date_utc,
                  l_max_version);

            fetch l_cursor
            bulk collect into l_date_times, l_version_dates;

            close l_cursor;
         end if;
      else
         ---------------------------
         -- irregular time series --
         ---------------------------
         l_cursor      :=
            cwms_ts.retrieve_existing_times_f(
               l_ts_code,
               l_start_time_utc,
               l_end_time_utc,
               null,
               l_version_date_utc,
               l_max_version);

         fetch l_cursor
         bulk collect into l_date_times, l_version_dates;

         close l_cursor;
      end if;

      --------------------
      -- store the binary --
      --------------------
      store_ts_binary(
         l_ts_code,
         l_blob_code,
         l_date_times,
         l_version_dates,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_binary_id;

   procedure store_ts_binary_id(
      p_tsid         in varchar2,
      p_binary_id    in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null)
   is
      ts_id_not_found      exception;
      pragma exception_init(ts_id_not_found, -20001);
      l_tsid               varchar2(191);
      l_ts_code            number(10);
      l_blob_code          number(10);
      l_times_utc          date_table_type := date_table_type();
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_replace_all        boolean;
      l_max_version        boolean;
      l_is_versioned       boolean;
      l_office_id          varchar2(16);
      l_office_code        number(10);
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_binary_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_ID');
      end if;

      if p_times is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TIMES');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id   := cwms_util.get_db_office_id(p_office_id);
      l_tsid        := cwms_ts.get_ts_id(p_tsid, l_office_id);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      l_replace_all := cwms_util.return_true_or_false(p_replace_all);
      l_max_version := cwms_util.return_true_or_false(p_max_version);

      l_times_utc.extend(p_times.count);

      for i in 1 .. p_times.count loop
         l_times_utc(i) := cwms_util.change_timezone(p_times(i), l_time_zone, 'UTC');
      end loop;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      select blob_code
        into l_blob_code
        from at_blob
       where office_code = l_office_code and id = upper(trim(p_binary_id));

      begin
         l_ts_code := cwms_ts.get_ts_code(l_tsid, l_office_code);
      exception
         when ts_id_not_found then
            -----------------------------------------------------------------------------------------
            -- create the regular time series with the interval offset defined from the first time --
            -----------------------------------------------------------------------------------------
            if cwms_ts.get_ts_interval(l_tsid) > 0 then
               cwms_ts.create_ts_code(
                  p_ts_code    => l_ts_code,
                  p_office_id  => l_office_id,
                  p_cwms_ts_id => l_tsid,
                  p_utc_offset => cwms_ts.get_utc_interval_offset(l_times_utc(1), cwms_ts.get_ts_interval(l_tsid)));
            else
               cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_office_id => l_office_id, p_cwms_ts_id => l_tsid);
            end if;
      end;

      --------------------
      -- store the binary --
      --------------------
      store_ts_binary(
         l_ts_code,
         l_blob_code,
         l_times_utc,
         null,
         l_version_date_utc,
         l_max_version,
         l_replace_all,
         p_attribute);
   end store_ts_binary_id;

   procedure retrieve_ts_binary(
      p_cursor              out sys_refcursor,
      p_tsid             in     varchar2,
      p_binary_type_mask in     varchar2,
      p_start_time       in     date,
      p_end_time         in     date default null,
      p_version_date     in     date default null,
      p_time_zone        in     varchar2 default null,
      p_max_version      in     varchar2 default 'T',
      p_retrieve_binary  in     varchar2 default 'T',
      p_min_attribute    in     number default null,
      p_max_attribute    in     number default null,
      p_office_id        in     varchar2 default null)
   is
   begin
      p_cursor      :=
         retrieve_ts_binary_f(
            p_tsid,
            p_binary_type_mask,
            p_start_time,
            p_end_time,
            p_version_date,
            p_time_zone,
            p_max_version,
            p_retrieve_binary,
            p_min_attribute,
            p_max_attribute,
            p_office_id);
   end retrieve_ts_binary;

   function retrieve_ts_binary_f(
      p_tsid             in varchar2,
      p_binary_type_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_retrieve_binary  in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return sys_refcursor
   is
      l_office_id            varchar2(16);
      l_tsid                 varchar2(191);
      l_binary_type_mask     varchar2(256);
      l_start_time_utc       date;
      l_end_time_utc         date;
      l_version_date_utc     date;
      l_time_zone            varchar2(28);
      l_ts_code              number(10);
      l_office_code          number(10);
      l_cursor               sys_refcursor;
      l_date_time_versions   date2_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_binary_type_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_TYPE_MASK');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id        := cwms_util.get_db_office_id(p_office_id);
      l_office_code      := cwms_util.get_db_office_code(l_office_id);
      l_tsid             := cwms_ts.get_ts_id(p_tsid, l_office_id);
      l_ts_code          := cwms_ts.get_ts_code(l_tsid, l_office_id);
      l_binary_type_mask := cwms_util.normalize_wildcards(p_binary_type_mask);
      l_time_zone        :=
         nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      l_start_time_utc   := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is null then
         l_end_time_utc := l_start_time_utc;
      else
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      -----------------------------------------
      -- get the existing times and versions --
      -----------------------------------------
      l_date_time_versions      :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        p_ts_code          => l_ts_code,
                        p_start_time_utc   => l_start_time_utc,
                        p_end_time_utc     => l_end_time_utc,
                        p_date_times_utc   => null,
                        p_version_date_utc => l_version_date_utc,
                        p_max_version      => cwms_util.return_true_or_false(p_max_version)));

      ------------------
      -- get the data --
      ------------------
      if cwms_util.return_true_or_false(p_retrieve_binary) then
         -------------------
         -- with the blob --
         -------------------
         open l_cursor for
              select cwms_util.change_timezone(d.date_1, 'UTC', l_time_zone) as date_time,
                     cwms_util.change_timezone(d.date_2, 'UTC', l_time_zone) as version_date,
                     cwms_util.change_timezone(t.data_entry_date, 'UTC', l_time_zone) as data_entry_date,
                     b.id,
                     t.attribute,
                     e.file_ext,
                     m.media_type_id,
                     b.value
                from table(l_date_time_versions) d,
                     at_tsv_binary t,
                     at_blob b,
                     cwms_media_type m,
                     at_file_extension e
               where t.ts_code = l_ts_code
                 and t.date_time = d.date_1
                 and t.version_date = d.date_2
                 and t.blob_code = b.blob_code
                 and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                   or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
                 and b.media_type_code = m.media_type_code
                 and m.media_type_code in
                        (select media_type_code
                           from cwms_media_type
                          where upper(media_type_id) like upper(l_binary_type_mask) escape '\'
                         union
                         select media_type_code
                           from at_file_extension
                          where office_code in (l_office_code, cwms_util.db_office_code_all)
                            and upper(file_ext) like upper(l_binary_type_mask) escape '\')
            order by d.date_1,
                     d.date_2,
                     t.attribute,
                     t.data_entry_date;
      else
         ----------------------
         -- without the blob --
         ----------------------
         open l_cursor for
              select cwms_util.change_timezone(d.date_1, 'UTC', l_time_zone) as date_time,
                     cwms_util.change_timezone(d.date_2, 'UTC', l_time_zone) as version_date,
                     cwms_util.change_timezone(t.data_entry_date, 'UTC', l_time_zone) as data_entry_date,
                     b.id,
                     t.attribute,
                     e.file_ext,
                     m.media_type_id
                from table(l_date_time_versions) d,
                     at_tsv_binary t,
                     at_blob b,
                     cwms_media_type m,
                     at_file_extension e
               where t.ts_code = l_ts_code
                 and t.date_time = d.date_1
                 and t.version_date = d.date_2
                 and t.blob_code = b.blob_code
                 and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                   or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
                 and b.media_type_code = m.media_type_code
                 and m.media_type_code in
                        (select media_type_code
                           from cwms_media_type
                          where upper(media_type_id) like upper(l_binary_type_mask) escape '\'
                         union
                         select media_type_code
                           from at_file_extension
                          where office_code in (l_office_code, cwms_util.db_office_code_all)
                            and upper(file_ext) like upper(l_binary_type_mask) escape '\')
            order by d.date_1,
                     d.date_2,
                     t.attribute,
                     t.data_entry_date;
      end if;

      return l_cursor;
   end retrieve_ts_binary_f;

   function get_ts_binary_count(
      p_tsid             in varchar2,
      p_binary_type_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_date_times       in date_table_type default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return pls_integer
   is
      l_office_id          varchar2(16);
      l_tsid               varchar2(191);
      l_binary_type_mask   varchar2(16);
      l_start_time_utc     date;
      l_end_time_utc       date;
      l_date_times_utc     date_table_type;
      l_version_date_utc   date;
      l_time_zone          varchar2(28);
      l_max_version        boolean;
      l_office_code        number(10);
      l_ts_code            number(10);
      l_times_utc          date2_tab_t;
      l_count              pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_binary_type_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_TYPE_MASK');
      end if;

      if p_start_time is null and p_date_times is null then
         cwms_err.raise('ERROR', 'One of P_START_TIME or P_DATE_TIMES must be non-NULL');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_max_version      := cwms_util.return_true_or_false(p_max_version);
      l_binary_type_mask := cwms_util.normalize_wildcards(p_binary_type_mask);
      l_office_id        := cwms_util.get_db_office_id(p_office_id);

      select office_code
        into l_office_code
        from cwms_office
       where office_id = l_office_id;

      l_tsid             := cwms_ts.get_ts_id(p_tsid, l_office_code);

      if l_tsid is null then
         l_tsid      := p_tsid;
         l_time_zone := nvl(p_time_zone, 'UTC');
      else
         l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      end if;

      if p_start_time is not null then
         l_start_time_utc := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
      end if;

      if p_end_time is not null then
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_date_times is not null then
         l_date_times_utc := date_table_type();
         l_date_times_utc.extend(p_date_times.count);

         for i in 1 .. p_date_times.count loop
            l_date_times_utc(i) := cwms_util.change_timezone(p_date_times(i), l_time_zone, 'UTC');
         end loop;
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      l_ts_code          := cwms_ts.get_ts_code(l_tsid, l_office_code);

      l_times_utc        :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        l_ts_code,
                        l_start_time_utc,
                        l_end_time_utc,
                        l_date_times_utc,
                        l_version_date_utc,
                        l_max_version,
                        cwms_util.ts_binary));

      select count(*)
        into l_count
        from table(l_times_utc) d,
             at_tsv_binary t,
             at_blob b,
             cwms_media_type m,
             at_file_extension e
       where t.ts_code = l_ts_code
         and t.date_time = d.date_1
         and t.version_date = d.date_2
         and t.blob_code = b.blob_code
         and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
           or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
         and b.media_type_code = m.media_type_code
         and m.media_type_code in
                (select media_type_code
                   from cwms_media_type
                  where upper(media_type_id) like upper(l_binary_type_mask) escape '\'
                 union
                 select media_type_code
                   from at_file_extension
                  where office_code in (l_office_code, cwms_util.db_office_code_all)
                    and upper(file_ext) like upper(l_binary_type_mask) escape '\');

      l_times_utc.delete;
      return l_count;
   end get_ts_binary_count;

   procedure delete_ts_binary(
      p_tsid             in varchar2,
      p_binary_type_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
   is
      l_office_id            varchar2(16);
      l_tsid                 varchar2(191);
      l_binary_type_mask     varchar2(256);
      l_start_time_utc       date;
      l_end_time_utc         date;
      l_version_date_utc     date;
      l_time_zone            varchar2(28);
      l_ts_code              number(10);
      l_office_code          number(10);
      l_date_time_versions   date2_tab_t := date2_tab_t();
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_tsid is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TSID');
      end if;

      if p_binary_type_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_TYPE_MASK');
      end if;

      if p_start_time is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_office_id        := cwms_util.get_db_office_id(p_office_id);
      l_office_code      := cwms_util.get_db_office_code(l_office_id);
      l_tsid             := cwms_ts.get_ts_id(p_tsid, l_office_id);
      l_ts_code          := cwms_ts.get_ts_code(l_tsid, l_office_id);
      l_binary_type_mask := cwms_util.normalize_wildcards(p_binary_type_mask);
      l_time_zone        :=
         nvl(p_time_zone, cwms_loc.get_local_timezone(substr(l_tsid, 1, instr(l_tsid, '.') - 1), l_office_id));
      l_start_time_utc   := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');

      if p_end_time is null then
         l_end_time_utc := l_start_time_utc;
      else
         l_end_time_utc := cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC');
      end if;

      if p_version_date is not null then
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;

      -----------------------------------------
      -- get the existing times and versions --
      -----------------------------------------
      l_date_time_versions      :=
         group_times(cwms_ts.retrieve_existing_times_f(
                        p_ts_code          => l_ts_code,
                        p_start_time_utc   => l_start_time_utc,
                        p_end_time_utc     => l_end_time_utc,
                        p_date_times_utc   => null,
                        p_version_date_utc => l_version_date_utc,
                        p_max_version      => cwms_util.return_true_or_false(p_max_version)));

      delete from at_tsv_binary
            where rowid in
                     (select t.rowid
                        from table(l_date_time_versions) d,
                             at_tsv_binary t,
                             at_blob b,
                             cwms_media_type m,
                             at_file_extension e
                       where t.ts_code = l_ts_code
                         and t.date_time = d.date_1
                         and t.version_date = d.date_2
                         and t.blob_code = b.blob_code
                         and ((p_min_attribute is null and p_max_attribute is null and t.attribute is null)
                           or t.attribute between nvl(p_min_attribute, t.attribute) and nvl(p_max_attribute, t.attribute))
                         and b.media_type_code = m.media_type_code
                         and m.media_type_code in
                                (select media_type_code
                                   from cwms_media_type
                                  where upper(media_type_id) like upper(l_binary_type_mask) escape '\'
                                 union
                                 select media_type_code
                                   from at_file_extension
                                  where office_code in (l_office_code, cwms_util.db_office_code_all)
                                    and upper(file_ext) like upper(l_binary_type_mask) escape '\'));

      l_date_time_versions.delete;
   end delete_ts_binary;

   procedure delete_ts_binary(
      p_binary_id     in varchar2,
      p_delete_action in varchar2 default cwms_util.delete_key,
      p_office_id     in varchar2 default null)
   is
      l_office_code     number(10);
      l_blob_code       number(10);
      l_delete_action   varchar2(22);
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_binary_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_BINARY_ID');
      end if;

      if p_delete_action is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_DELETE_ACTION');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_delete_action      :=
         case
            when p_delete_action in (cwms_util.delete_key, cwms_util.delete_ts_id) then cwms_util.delete_key
            when p_delete_action in (cwms_util.delete_data, cwms_util.delete_ts_data) then cwms_util.delete_data
            when p_delete_action in (cwms_util.delete_all, cwms_util.delete_ts_cascade) then cwms_util.delete_all
            else null
         end;

      if l_delete_action is null then
         cwms_err.raise('INVALID_DELETE_ACTION');
      end if;

      l_office_code := cwms_util.get_db_office_code(p_office_id);

      select blob_code
        into l_blob_code
        from at_blob
       where office_code = l_office_code and upper(id) = upper(trim(p_binary_id));

      if l_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
         delete from at_tsv_binary
               where blob_code = l_blob_code;
      end if;

      if l_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
         delete from at_blob
               where blob_code = l_blob_code;
      end if;
   end delete_ts_binary;

   procedure store_file_extension(
      p_file_extension in varchar2,
      p_media_type     in varchar2,
      p_fail_if_exists in varchar2 default 'T',
      p_office_id      in varchar2 default null)
   is
      l_file_extension    varchar2(16);
      l_office_code       number(10);
      l_media_type_code   number(10);
      l_rec               at_file_extension%rowtype;
      l_exists            boolean;
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_file_extension is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_FILE_EXTENSION');
      end if;

      if p_media_type is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_MEDIA_TYPE');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_file_extension      :=
         trim(substr(
                 l_file_extension,
                 instr(
                    l_file_extension,
                    '.',
                    -1,
                    1)));
      l_office_code := cwms_util.get_db_office_code(p_office_id);

      select media_type_code
        into l_media_type_code
        from cwms_media_type
       where upper(media_type_id) = upper(trim(p_media_type));

      ----------------------------------------------
      -- see if the file extension already exists --
      ----------------------------------------------
      begin
         select *
           into l_rec
           from at_file_extension
          where office_code in (l_office_code, cwms_util.db_office_code_all) and file_ext = l_file_extension;

         l_exists := true;
      exception
         when no_data_found then
            l_exists := false;
      end;

      if l_exists then
         if cwms_util.return_true_or_false(p_fail_if_exists) then
            cwms_err.raise('ITEM_ALREADY_EXISTS', 'File extension', l_file_extension);
         end if;

         if l_rec.media_type_code != l_media_type_code then
            -----------------------
            -- update the record --
            -----------------------
            if l_rec.office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
               cwms_err.raise('ERROR', 'Cannot update file extension for office CWMS');
            end if;

            l_rec.media_type_code := l_media_type_code;

            update at_file_extension
               set row = l_rec
             where office_code = l_rec.office_code and file_ext = l_rec.file_ext;
         end if;
      else
         -------------------------
         -- insert a new record --
         -------------------------
         l_rec.office_code     := l_office_code;
         l_rec.file_ext        := l_file_extension;
         l_rec.media_type_code := l_media_type_code;

         insert into at_file_extension
              values l_rec;
      end if;
   end store_file_extension;

   procedure delete_file_extension(
      p_file_extension in varchar2, 
      p_office_id      in varchar2 default null)
   is
      l_file_extension   varchar2(16);
      l_office_code      number(10);
      l_rec              at_file_extension%rowtype;
   begin
      -------------------
      -- sanity checks --
      -------------------
      cwms_util.check_office_permission(p_office_id);
      if p_file_extension is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_FILE_EXTENSION');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_file_extension      :=
         trim(substr(
                 l_file_extension,
                 instr(
                    l_file_extension,
                    '.',
                    -1,
                    1)));
      l_office_code := cwms_util.get_db_office_code(p_office_id);

      -----------------------
      -- delete the record --
      -----------------------
      select *
        into l_rec
        from at_file_extension
       where office_code in (l_office_code, cwms_util.db_office_code_all) and file_ext = l_file_extension;

      if l_rec.office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
         cwms_err.raise('ERROR', 'Cannot delete file extension for office CWMS');
      end if;

      delete from at_file_extension
            where office_code = l_rec.office_code and file_ext = l_rec.file_ext;
   end delete_file_extension;

   procedure cat_file_extensions(
      p_cursor                 out sys_refcursor,
      p_file_extension_mask in     varchar2 default '*',
      p_office_id_mask      in     varchar2 default null)
   is
   begin
      p_cursor := cat_file_extensions_f(p_file_extension_mask, p_office_id_mask);
   end cat_file_extensions;

   function cat_file_extensions_f(
      p_file_extension_mask in varchar2 default '*', 
      p_office_id_mask      in varchar2 default null)
      return sys_refcursor
   is
      l_file_extension_mask   varchar2(16);
      l_office_id_mask        varchar2(16);
      l_cursor                sys_refcursor;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_file_extension_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_FILE_EXTENSION_MASK');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_file_extension_mask := upper(trim(p_file_extension_mask));
      l_file_extension_mask      :=
         substr(
            l_file_extension_mask,
            instr(
               l_file_extension_mask,
               '.',
               -1,
               1)
            + 1);
      l_file_extension_mask := cwms_util.normalize_wildcards(l_file_extension_mask);

      if p_office_id_mask is null then
         l_office_id_mask := cwms_util.user_office_id;
      else
         l_office_id_mask := cwms_util.normalize_wildcards(p_office_id_mask);
      end if;

      ---------------------
      -- open the cursor --
      ---------------------
      open l_cursor for
           select o.office_id, e.file_ext as file_extension, m.media_type_id as media_type
             from at_file_extension e, cwms_media_type m, cwms_office o
            where (o.office_id like upper(l_office_id_mask) escape '\' or o.office_id = 'CWMS')
              and e.office_code = o.office_code
              and upper(e.file_ext) like l_file_extension_mask escape '\'
              and m.media_type_code = e.media_type_code
         order by o.office_id, e.file_ext, m.media_type_id;

      return l_cursor;
   end cat_file_extensions_f;

   procedure cat_media_types(
      p_cursor             out sys_refcursor,
      p_media_type_mask in     varchar2 default '*',
      p_office_id_mask  in     varchar2 default null)
   is
   begin
      p_cursor := cat_media_types_f(p_media_type_mask, p_office_id_mask);
   end cat_media_types;

   function cat_media_types_f(
      p_media_type_mask in varchar2 default '*', 
      p_office_id_mask  in varchar2 default null)
      return sys_refcursor
   is
      l_media_type_mask   varchar2(84);
      l_office_id_mask    varchar2(16);
      l_cursor            sys_refcursor;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_media_type_mask is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_MEDIA_TYPE_MASK');
      end if;

      ----------------------------
      -- assign local variables --
      ----------------------------
      l_media_type_mask := cwms_util.normalize_wildcards(p_media_type_mask);

      if p_office_id_mask is null then
         l_office_id_mask := cwms_util.user_office_id;
      else
         l_office_id_mask := cwms_util.normalize_wildcards(p_office_id_mask);
      end if;

      ---------------------
      -- open the cursor --
      ---------------------
      open l_cursor for
           select distinct o.office_id, m.media_type_id as media_type, e.file_ext as file_extension
             from cwms_media_type m, at_file_extension e, cwms_office o
            where (o.office_id like upper(l_office_id_mask) escape '\' or o.office_id = 'CWMS')
              and e.office_code = o.office_code
              and e.media_type_code = m.media_type_code
              and upper(m.media_type_id) like upper(l_media_type_mask) escape '\'
         order by o.office_id, m.media_type_id, e.file_ext;

      return l_cursor;
   end cat_media_types_f;

   procedure store_text_filter(
      p_text_filter_id in varchar2,
      p_description    in varchar2,
      p_text_filter    in str_tab_t,
      p_fail_if_exists in varchar2 default 'T',
      p_uses_regex     in varchar2 default 'F',
      p_regex_flags    in varchar2 default null,
      p_office_id      in varchar2 default null)
   is      
      type filter_elements_t is table of at_text_filter_element%rowtype; 
      c_element_pattern1 constant varchar2(57) := '^\s*(i(n(c(l(u(de?)?)?)?)?)?|e(x(c(l(u(de?)?)?)?)?)?)\s*:';
      c_element_pattern2 constant varchar2(35) := '\s*:\s*f(l(a(gs?)?)?)?\s*=.*$';
      l_header_rec       at_text_filter%rowtype;
      l_elements         filter_elements_t;
      l_exists           boolean;
      l_fail_if_exists   boolean := cwms_util.is_true(p_fail_if_exists);
      l_is_regex         boolean := cwms_util.is_true(p_uses_regex);
      l_office_id        varchar2(16) := cwms_util.get_db_office_id(p_office_id);
      l_office_code      integer := cwms_util.get_db_office_code(l_office_id);
      l_parts            str_tab_t;
      l_pos              integer;
   begin
      cwms_util.check_office_permission(p_office_id);
      -------------------------------------------------
      -- get the existing header record if it exists --
      -------------------------------------------------
      l_header_rec.text_filter_id := trim(p_text_filter_id);
      begin
         select *
           into l_header_rec
           from at_text_filter
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and upper(text_filter_id) = upper(l_header_rec.text_filter_id);
         l_exists := true;            
      exception
         when no_data_found then l_exists := false; 
      end;
      if l_exists then
         if l_fail_if_exists then
            select office_id
              into l_office_id
              from cwms_office
             where office_code = l_header_rec.office_code; 
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'Text filter',
               l_office_id||'/'||l_header_rec.text_filter_id);
         elsif l_header_rec.office_code = cwms_util.db_office_code_all and l_office_code != cwms_util.db_office_code_all then
            cwms_err.raise(
               'ERROR',
               'Cannot store text filter '
               ||l_office_id
               ||'/'
               ||l_header_rec.text_filter_id
               ||' because '
               ||'CWMS/'
               ||l_header_rec.text_filter_id
               ||' exists');
         end if;
         ------------------------------------------
         -- exists, delete the existing elements --
         ------------------------------------------
         delete 
           from at_text_filter_element
          where text_filter_code = l_header_rec.text_filter_code;
      else
         --------------------------------------------
         -- doesn't exist, prime header for insert --
         --------------------------------------------
         l_header_rec.text_filter_code := cwms_seq.nextval; 
         l_header_rec.office_code      := l_office_code;
      end if;
      ------------------------------------------------      
      -- finish setting header for update or insert --
      ------------------------------------------------
      l_header_rec.description := trim(p_description);      
      l_header_rec.is_regex := case l_is_regex when true then 'T' else 'F' end;
      l_header_rec.regex_flags := lower(trim(p_regex_flags));
      ---------------------------------      
      -- update or insert the header --
      ---------------------------------      
      if l_exists then
         update at_text_filter
            set row = l_header_rec
          where text_filter_code = l_header_rec.text_filter_code;  
      else
         insert
           into at_text_filter
         values l_header_rec;  
      end if;                                              
      
      if p_text_filter is not null then
         l_elements := filter_elements_t();
         for i in 1..p_text_filter.count loop
            l_elements.extend;
            l_elements(i).text_filter_code := l_header_rec.text_filter_code;
            l_elements(i).element_sequence := i;
            l_elements(i).regex_flags := l_header_rec.regex_flags; -- may be overwritten       
            l_pos := regexp_instr(p_text_filter(i), c_element_pattern1, 1, 1, 1, 'i'); 
            if l_pos = 0 then
               cwms_err.raise(
                  'ERROR',
                  'Filter element must be like (INCLUDE|EXCLUDE):<filter>[:FLAGS=<flags>]'
                  ||chr(10)
                  ||'<'||p_text_filter(i)||'>');
            end if;
            l_parts := str_tab_t(
               lower(trim(substr(p_text_filter(i), 1, l_pos-1))),
               substr(p_text_filter(i), l_pos));
            if substr(l_parts(1), 1, 1) = 'i' then
                  l_elements(i).include := 'T';
            else
                  l_elements(i).include := 'F';
            end if;
            l_pos := regexp_instr(l_parts(2), c_element_pattern2, 1, 1, 0, 'i');
            if l_pos = 0 then
               l_elements(i).filter_text := l_parts(2);
               l_elements(i).regex_flags := null;
            else   
               l_elements(i).filter_text := substr(l_parts(2), 1, l_pos - 1);
               l_parts(2) := regexp_replace(substr(l_parts(2), l_pos), '\s+', null, 1, 0);
               l_parts(2) := lower(trim(substr(l_parts(2), instr(l_parts(2), '=') + 1))); 
               if instr(l_parts(2), 'm') != 0 then
                  l_elements(i).regex_flags := l_elements(i).regex_flags || 'm';
               end if;
               if instr(l_parts(2), 'n') != 0 then
                  l_elements(i).regex_flags := l_elements(i).regex_flags || 'n';
               end if;
               if instr(l_parts(2), 'x') != 0 then
                  l_elements(i).regex_flags := l_elements(i).regex_flags || 'x';
               end if;
               if instr(l_parts(2), 'i') != 0 then
                  l_elements(i).regex_flags := l_elements(i).regex_flags || 'i';
               end if;
            end if;
         end loop;
         forall i in 1..l_elements.count
            insert into at_text_filter_element values l_elements(i);
      end if;
   end store_text_filter;      
      
   procedure retrieve_text_filter(
      p_text_filter    out str_tab_t,
      p_uses_regex     out varchar2,
      p_text_filter_id in  varchar2,
      p_office_id      in  varchar2 default null)
   is
      type filter_elements_t is table of at_text_filter_element%rowtype;
      l_office_code integer := cwms_util.get_db_office_code(p_office_id);
      l_header_rec  at_text_filter%rowtype;
      l_elements    filter_elements_t;
      l_text_filter str_tab_t;
   begin
      cwms_util.check_office_permission(p_office_id);
      l_header_rec.text_filter_id := trim(p_text_filter_id);
      begin
         select *
           into l_header_rec
           from at_text_filter
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and upper(text_filter_id) = upper(l_header_rec.text_filter_id);
      exception
         when no_data_found then 
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Text filter',
               l_header_rec.text_filter_id);
      end;
      begin
         select *      
           bulk collect
           into l_elements
           from at_text_filter_element
          where text_filter_code = l_header_rec.text_filter_code
          order by element_sequence;
          
         l_text_filter := str_tab_t();
         l_text_filter.extend(l_elements.count);
         for i in 1..l_elements.count loop
            l_text_filter(i) := case l_elements(i).include when 'T' then 'include:' else 'exclude:' end;
            if l_elements(i).regex_flags is not null and length(l_elements(i).regex_flags) > 0 then
               l_text_filter(i) := l_text_filter(i)||'flags='||l_elements(i).regex_flags||':';
            elsif l_header_rec.regex_flags is not null and length(l_header_rec.regex_flags) > 0 then
               l_text_filter(i) := l_text_filter(i)||'flags='||l_header_rec.regex_flags||':';
            end if;
            l_text_filter(i) := l_text_filter(i)||l_elements(i).filter_text;
         end loop;            
      exception
         when no_data_found then null;
      end;
      p_text_filter := l_text_filter;
      p_uses_regex := l_header_rec.is_regex; 
   end retrieve_text_filter;               
                                      
   procedure delete_text_filter(
      p_text_filter_id in varchar2,
      p_office_id      in varchar2 default null)
   is      
      l_header_rec  at_text_filter%rowtype;
      l_office_id   varchar2(16) := cwms_util.get_db_office_id(p_office_id);
      l_office_code integer := cwms_util.get_db_office_code(l_office_id);
   begin                     
      cwms_util.check_office_permission(p_office_id);
      l_header_rec.text_filter_id := trim(p_text_filter_id);
      begin
         select *
           into l_header_rec
           from at_text_filter
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and upper(text_filter_id) = upper(l_header_rec.text_filter_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Text filter',
               l_office_id||'/'||l_header_rec.text_filter_id); 
      end;
      if l_header_rec.office_code = cwms_util.db_office_code_all then
         if l_office_code != cwms_util.db_office_code_all then
            cwms_err.raise(
               'ERROR',
               'Text filter '
               ||l_header_rec.text_filter_id
               ||' is owned by CWMS - cannot delete.');
         end if;
      end if;
      delete 
        from at_text_filter_element
       where text_filter_code = l_header_rec.text_filter_code;
       
      delete 
        from at_text_filter
       where text_filter_code = l_header_rec.text_filter_code;
       
   end delete_text_filter;
                                      
   procedure rename_text_filter(
      p_old_text_filter_id in varchar2,
      p_new_text_filter_id in varchar2,
      p_office_id          in varchar2 default null)
   is      
      l_header_old  at_text_filter%rowtype;
      l_header_new at_text_filter%rowtype;
      l_office_id   varchar2(16) := cwms_util.get_db_office_id(p_office_id);
      l_office_code integer := cwms_util.get_db_office_code(l_office_id);
   begin                     
      cwms_util.check_office_permission(p_office_id);
      l_header_old.text_filter_id := trim(p_old_text_filter_id);
      begin
         select *
           into l_header_old
           from at_text_filter
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and upper(text_filter_id) = upper(l_header_old.text_filter_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Text filter',
               l_office_id||'/'||l_header_old.text_filter_id); 
      end;
      l_header_new.text_filter_id := trim(p_new_text_filter_id);
      begin
         select *
           into l_header_new
           from at_text_filter
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and upper(text_filter_id) = upper(l_header_new.text_filter_id);
            
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Text filter',
            l_office_id||'/'||l_header_new.text_filter_id);           
      exception
         when no_data_found then null;
      end;
      
      update at_text_filter
         set text_filter_id = l_header_new.text_filter_id
       where text_filter_code = l_header_old.text_filter_code;         
       
   end rename_text_filter;
            
   function filter_text(
      p_text_filter_id in varchar2,
      p_values         in str_tab_t,
      p_office_id      in varchar2 default null)
      return str_tab_t
   is
      type filter_elements_t is table of at_text_filter_element%rowtype;
      l_office_id        varchar2(16) := cwms_util.get_db_office_id(p_office_id);
      l_office_code      integer := cwms_util.get_db_office_code(l_office_id);
      l_header_rec       at_text_filter%rowtype;
      l_elements         filter_elements_t;
      l_filters          str_tab_t;
      l_case_insensitive str_tab_t;
      l_is_regex         boolean;
      l_included str_tab_t := str_tab_t();
      l_excluded str_tab_t := str_tab_t();
      l_matched  str_tab_t := str_tab_t();
   begin
      l_header_rec.text_filter_id := trim(p_text_filter_id);
      begin
         select *
           into l_header_rec
           from at_text_filter
          where office_code in (l_office_code, cwms_util.db_office_code_all)
            and upper(text_filter_id) = upper(l_header_rec.text_filter_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Text filter',
               l_office_id||'/'||l_header_rec.text_filter_id); 
      end;
      begin
         select *      
           bulk collect
           into l_elements
           from at_text_filter_element
          where text_filter_code = l_header_rec.text_filter_code
          order by element_sequence;
      exception
         when no_data_found then null;
      end;
      
      if p_values is not null and l_elements is not null then
         l_is_regex := l_header_rec.is_regex = 'T';
         if not l_is_regex then
            select cwms_util.normalize_wildcards(filter_text),
                   case
                   when regex_flags is null then 'F'
                   when instr(regex_flags, 'i') > 0 then 'T'
                   else 'F'
                   end
              bulk collect
              into l_filters,
                   l_case_insensitive
              from at_text_filter_element
             where text_filter_code = l_header_rec.text_filter_code
             order by element_sequence;
         end if;
         
         if l_elements(1).include = 'T' then
            l_excluded := p_values;
         else
            l_included := p_values;
         end if;
         for i in 1..l_elements.count loop
            if l_elements(i).include = 'T' then
               if l_is_regex then
                  if l_elements(i).regex_flags is not null then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_excluded)
                      where regexp_like(column_value, l_elements(i).filter_text, l_elements(i).regex_flags); 
                  else
                     if l_header_rec.regex_flags is not null then
                        select *
                          bulk collect
                          into l_matched
                          from table(l_excluded)
                         where regexp_like(column_value, l_elements(i).filter_text, l_header_rec.regex_flags); 
                     else
                        select *
                          bulk collect
                          into l_matched
                          from table(l_excluded)
                         where regexp_like(column_value, l_elements(i).filter_text); 
                     end if;
                  end if;
               else
                  if l_case_insensitive(i) = 'T' or instr(l_header_rec.regex_flags, 'i') > 0 then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_excluded)
                      where upper(column_value) like upper(l_filters(i)); 
                  else
                     select *
                       bulk collect
                       into l_matched
                       from table(l_excluded)
                      where column_value like l_filters(i); 
                  end if;
               end if;
               l_included := l_included multiset union all l_matched;
               l_excluded := l_excluded multiset except all l_matched;
            else
               if l_is_regex then
                  if l_elements(i).regex_flags is not null then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_included)
                      where regexp_like(column_value, l_elements(i).filter_text, l_elements(i).regex_flags); 
                  else
                     if l_header_rec.regex_flags is not null then
                        select *
                          bulk collect
                          into l_matched
                          from table(l_included)
                         where regexp_like(column_value, l_elements(i).filter_text, l_header_rec.regex_flags); 
                     else
                        select *
                          bulk collect
                          into l_matched
                          from table(l_included)
                         where regexp_like(column_value, l_elements(i).filter_text); 
                     end if;
                  end if;
               else
                  if l_case_insensitive(i) = 'T' or instr(l_header_rec.regex_flags, 'i') > 0 then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_included)
                      where upper(column_value) like upper(l_filters(i)); 
                  else
                     select *
                       bulk collect
                       into l_matched
                       from table(l_included)
                      where column_value like l_filters(i); 
                  end if;
               end if;
               l_included := l_included multiset except all l_matched;
               l_excluded := l_excluded multiset union all l_matched;
            end if;
         end loop;
      else 
         l_included := p_values;
      end if;
            
      return l_included;
   end filter_text;           
      
   function filter_text(
      p_text_filter_id in varchar2,
      p_value          in varchar2,
      p_office_id      in varchar2 default null)
      return varchar2
   is
      l_filtered str_tab_t;
   begin
      l_filtered := filter_text(p_text_filter_id, str_tab_t(p_value), p_office_id);
      return case l_filtered is null
                when true then null
                else l_filtered(0)
             end; 
   end filter_text;           
   
   function filter_text(
      p_filter in str_tab_t,
      p_values in str_tab_t,
      p_regex  in varchar2 default 'F')
      return str_tab_t
   is                      
      type filter_element_t is record(include boolean, flags varchar2(16), text varchar2(256));
      type filter_element_tab_t is table of filter_element_t;
      c_element_pattern1 constant varchar2(57) := '^\s*(i(n(c(l(u(de?)?)?)?)?)?|e(x(c(l(u(de?)?)?)?)?)?)\s*:';
      c_element_pattern2 constant varchar2(35) := '\s*:\s*f(l(a(gs?)?)?)?\s*=.*$';
      l_regex            boolean := cwms_util.is_true(p_regex);
      l_filter           filter_element_tab_t;
      l_pos              integer;
      l_case_insensitive str_tab_t;
      l_parts            str_tab_t;
      l_included         str_tab_t;
      l_excluded         str_tab_t;
      l_matched          str_tab_t;
   begin   
      if p_filter is null then
         l_included := p_values;
      else 
         ----------------------
         -- build the filter --
         ----------------------         
         l_filter := filter_element_tab_t();
         l_filter.extend(p_filter.count);
         for i in 1..p_filter.count loop
         
            l_pos := regexp_instr(p_filter(i), c_element_pattern1, 1, 1, 1, 'i'); 
            if l_pos = 0 then
               cwms_err.raise(
                  'ERROR',
                  'Filter element must be like (INCLUDE|EXCLUDE):<filter>[:FLAGS=<flags>]'
                  ||chr(10)
                  ||'<'||p_filter(i)||'>');
            end if;
            l_parts := str_tab_t(
               lower(trim(substr(p_filter(i), 1, l_pos-1))),
               substr(p_filter(i), l_pos));
            if substr(l_parts(1), 1, 1) = 'i' then
                  l_filter(i).include := true;
            else
                  l_filter(i).include := false;
            end if;

            l_pos := regexp_instr(l_parts(2), c_element_pattern2, 1, 1, 0, 'i');
            if l_pos = 0 then
               l_filter(i).text := l_parts(2);
               l_filter(i).flags := null;
            else   
               l_filter(i).text := substr(l_parts(2), 1, l_pos - 1);
               l_parts(2) := regexp_replace(substr(l_parts(2), l_pos), '\s+', null, 1, 0);
               l_parts(2) := lower(trim(substr(l_parts(2), instr(l_parts(2), '=') + 1))); 
               if instr(l_parts(2), 'm') != 0 then
                  l_filter(i).flags := l_filter(i).flags || 'm';
               end if;
               if instr(l_parts(2), 'n') != 0 then
                  l_filter(i).flags := l_filter(i).flags || 'n';
               end if;
               if instr(l_parts(2), 'x') != 0 then
                  l_filter(i).flags := l_filter(i).flags || 'x';
               end if;
               if instr(l_parts(2), 'i') != 0 then
                  l_filter(i).flags := l_filter(i).flags || 'i';
               end if;
            end if;
            if not l_regex then
               l_filter(i).text := cwms_util.normalize_wildcards(l_filter(i).text); 
            end if;
         end loop;
         ---------------------      
         -- filter the text --
         ---------------------
         if l_filter(1).include then
            l_included := str_tab_t();
            l_excluded := p_values;
         else
            l_included := p_values;
            l_excluded := p_values;
         end if;
         for i in 1..l_filter.count loop
            if l_filter(i).include then
               if l_regex then
                  if l_filter(i).flags is not null then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_excluded)
                      where regexp_like(column_value, l_filter(i).text, l_filter(i).flags); 
                  else
                     select *
                       bulk collect
                       into l_matched
                       from table(l_excluded)
                      where regexp_like(column_value, l_filter(i).text); 
                  end if;
               else
                  if instr(l_filter(i).flags, 'i') > 0 then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_excluded)
                      where upper(column_value) like upper(l_filter(i).text); 
                  else
                     select *
                       bulk collect
                       into l_matched
                       from table(l_excluded)
                      where column_value like l_filter(i).text; 
                  end if;
               end if;
               l_included := l_included multiset union all l_matched;
               l_excluded := l_excluded multiset except all l_matched;
            else
               if l_regex then
                  if l_filter(i).flags is not null then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_included)
                      where regexp_like(column_value, l_filter(i).text, l_filter(i).flags); 
                  else
                     select *
                       bulk collect
                       into l_matched
                       from table(l_included)
                      where regexp_like(column_value, l_filter(i).text); 
                  end if;
               else
                  if instr(l_filter(i).flags, 'i') > 0 then
                     select *
                       bulk collect
                       into l_matched
                       from table(l_included)
                      where upper(column_value) like upper(l_filter(i).text); 
                  else
                     select *
                       bulk collect
                       into l_matched
                       from table(l_included)
                      where column_value like l_filter(i).text; 
                  end if;
               end if;
               l_included := l_included multiset except all l_matched;
               l_excluded := l_excluded multiset union all l_matched;
            end if;
         end loop;
      end if;
      return l_included;
   end filter_text;            
      
   function filter_text(
      p_filter in str_tab_t,
      p_value  in varchar2,
      p_regex  in varchar2 default 'F')
      return varchar2
   is
      l_filtered str_tab_t;
   begin
      l_filtered := filter_text(p_filter, str_tab_t(p_value), p_regex);
      return case l_filtered is null
                when true then null
                else l_filtered(0)
             end; 
    end filter_text;
end;
/

show errors;
commit;
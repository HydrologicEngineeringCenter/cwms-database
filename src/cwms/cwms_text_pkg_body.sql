SET define on
@@defines.sql

create or replace
package body cwms_text
as
--
-- store text with optional description
--
procedure store_text(
   p_text_code      out number,                 -- the code for use in foreign keys
	p_text           in  clob,                   -- the text, unlimited length
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in  varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in  varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in  varchar2 default null) -- office id, defaults current user's office
is
   l_id               varchar2(256) := upper(p_id);
   l_fail_if_exists   boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_count            binary_integer;
   l_office_code      number := cwms_util.get_office_code(p_office_id);
   l_cwms_office_code number := cwms_util.get_office_code('CWMS');
   l_rowid            urowid;
begin
   select count(*)
     into l_count
     from at_clob
    where office_code in (l_office_code, l_cwms_office_code)
      and id = l_id;

   if l_count = 0 then
      insert
        into at_clob
      values (cwms_seq.nextval, l_office_code, l_id, p_description, p_text)
   returning clob_code into p_text_code;
   else
      if l_fail_if_exists then
         cwms_err.raise('ITEM_ALREADY_EXISTS', 'Text ID', p_id);
      end if;
      update at_clob
         set description = p_description,
             value = p_text
      where office_code = l_office_code
         and id = l_id
      returning rowid, clob_code into l_rowid, p_text_code;
      if l_rowid is null then
         cwms_err.raise(
            'ERROR',
            'Cannot update text owned by the CWMS Office ID.');
      end if;
   end if;

end store_text;

--
-- store text with optional description
--
function store_text(
	p_text           in clob,                   -- the text, unlimited length
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number                               -- the code for use in foreign keys
is
   l_text_code number;
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
   p_text_code      out number,                 -- the code for use in foreign keys
	p_text           in  varchar2,               -- the text, limited to varchar2 max size
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in  varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in  varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in  varchar2 default null)  -- office id, defaults current user's office
is
   l_text clob;
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
	p_text           in varchar2,               -- the text, limited to varchar2 max size
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number                               -- the code for use in foreign keys
is
   l_text_code number;
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
-- retrieve text only
--
procedure retrieve_text(
   p_text      out clob,                   -- the text, unlimited length
   p_id        in  varchar2,               -- identifier used to store text (256 chars max)
   p_office_id in  varchar2 default null)  -- office id, defaults current user's office
is
   l_id               varchar2(256) := upper(p_id);
   l_office_code      number := cwms_util.get_office_code(p_office_id);
   l_cwms_office_code number := cwms_util.get_office_code('CWMS');
begin
   select value
     into p_text
     from at_clob
    where office_code in (l_office_code, l_cwms_office_code)
      and id = l_id;

end retrieve_text;

--
-- retrieve text only
--
function retrieve_text(
   p_id        in  varchar2,              -- identifier used to store text (256 chars max)
   p_office_id in  varchar2 default null) -- office id, defaults current user's office
   return clob                            -- the text, unlimited length
is
   l_text clob;
begin
   retrieve_text(
      p_text      => l_text,
      p_id        => p_id,
      p_office_id => p_office_id);
   return l_text;
end retrieve_text;

--
-- retrieve text and description
--
procedure retrieve_text(
   p_text        out clob,                   -- the text, unlimited length
   p_description out varchar2,               -- the description
   p_id          in  varchar2,               -- identifier used to store text (256 chars max)
   p_office_id   in  varchar2 default null)  -- office id, defaults current user's office
is
   l_id               varchar2(256) := upper(p_id);
   l_office_code      number := cwms_util.get_office_code(p_office_id);
   l_cwms_office_code number := cwms_util.get_office_code('CWMS');
begin
   select value,
          description
     into p_text,
          p_description
     from at_clob
    where office_code in (l_office_code, l_cwms_office_code)
      and id = l_id;

end retrieve_text;

--
-- update text and/or description
--
procedure update_text(
   p_text           in clob,                   -- the text, unlimited length
   p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
   p_description    in varchar2 default null,  -- description, defaults to null
   p_ignore_nulls   in varchar2 default 'T',   -- flag specifying null inputs leave current values unchanged
   p_office_id      in varchar2 default null)  -- office id, defaults current user's office
is
   l_id               varchar2(256) := upper(p_id);
   l_office_code      number := cwms_util.get_office_code(p_office_id);
   l_cwms_office_code number := cwms_util.get_office_code('CWMS');
   l_ignore_nulls     boolean := cwms_util.return_true_or_false(p_ignore_nulls);
begin
   if l_ignore_nulls then
      if p_text is null then
         if p_description is not null then
            update at_clob
               set description = p_description
             where office_code in (l_office_code, l_cwms_office_code)
               and id = l_id;
         end if;
      elsif p_description is null then
         update at_clob
            set value = p_text
          where office_code in (l_office_code, l_cwms_office_code)
            and id = l_id;
      else
         update at_clob
            set value = p_text,
                description = p_description
          where office_code in (l_office_code, l_cwms_office_code)
            and id = l_id;
      end if;
   else
      update at_clob
         set value = p_text,
             description = p_description
       where office_code in (l_office_code, l_cwms_office_code)
         and id = l_id;
   end if;
end update_text;

--
-- delete text
--
procedure delete_text(
   p_id        in  varchar2,               -- identifier used to store text (256 chars max)
   p_office_id in  varchar2 default null)  -- office id, defaults current user's office
is
   l_id          varchar2(256) := upper(p_id);
   l_office_code number := cwms_util.get_office_code(p_office_id);
begin
   delete
     from at_clob
    where office_code = l_office_code
      and id = l_id;
end delete_text;

--
-- get matching ids in a cursor
--
procedure get_matching_ids(
   p_ids                  in out sys_refcursor,       -- cursor of the matching office ids, text ids, and optionally descriptions
   p_id_masks             in  varchar2 default '%',   -- delimited list of id masks, defaults to all ids
   p_include_descriptions in  varchar2 default 'F',   -- flag specifying whether to retrieve descriptions also
   p_office_id_masks      in  varchar2 default null,  -- delimited list of office id masks, defaults to user's office
   p_delimiter            in  varchar2 default ',')   -- delimiter for masks, defaults to comma
is
   type id_collection is  table of boolean index by varchar2(256);
   l_include_descriptions boolean := cwms_util.return_true_or_false(p_include_descriptions);
   l_office_id_masks      varchar2(256) := nvl(p_office_id_masks, cwms_util.user_office_id);
   l_office_id_mask_tab   cwms_util.str_tab_t;
   l_id_mask_tab          cwms_util.str_tab_t;
   l_ids                  id_collection;
   l_office_id_bind_str   varchar2(32767);
   l_id_bind_str          varchar2(32767);
   l_query_str            varchar2(32767);
   l_office_id            varchar2(16);
   l_id                   varchar2(256);
   l_cwms_matched         boolean := false;
   l_id_mask              varchar2(256);
begin
   ------------------------------------
   -- build office ids bind variable --
   ------------------------------------
   l_office_id_mask_tab := cwms_util.split_text(l_office_id_masks, p_delimiter);
   for i in 1..l_office_id_mask_tab.count loop
       l_id_mask := cwms_util.normalize_wildcards(upper(l_office_id_mask_tab(i)), true);
       for rec in
           (select office_id
              from cwms_office
              where office_id like l_id_mask)
       loop
          if not l_ids.exists(rec.office_id) then
              l_ids(rec.office_id) := true;
          end if;
       end loop;
   end loop;
   l_office_id := l_ids.first;
   loop
      if l_office_id = 'CWMS' then
         l_cwms_matched := true;
      end if;
      l_office_id_bind_str := l_office_id_bind_str || '''' || l_office_id || '''';
      l_office_id := l_ids.next(l_office_id);
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
   l_id_mask_tab := cwms_util.split_text(p_id_masks, p_delimiter);
   for i in 1..l_id_mask_tab.count loop
       l_id_mask := cwms_util.normalize_wildcards(upper(l_id_mask_tab(i)), true);
       for rec in
          (select id
             from at_clob
             where id like l_id_mask)
       loop
          if not l_ids.exists(rec.id) then
             l_ids(rec.id) := true;
          end if;
       end loop;
   end loop;
   l_id := l_ids.first;
   loop
      l_id_bind_str := l_id_bind_str || '''' || l_id || '''';
      l_id := l_ids.next(l_id);
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
   l_query_str := replace(l_query_str, ':ids',        l_id_bind_str);
   -----------------------
   -- perform the query --
   -----------------------
   open p_ids for l_query_str;
end get_matching_ids;

--
-- get matching ids in a delimited clob
--
procedure get_matching_ids(
   p_ids                  out clob,                   -- delimited clob of the matching office ids, text ids, and optionally descriptions
   p_id_masks             in  varchar2 default '%',   -- comma-separated list of id masks, defaults to all ids
   p_include_descriptions in  varchar2 default 'F',   -- flag specifying whether to retrieve descriptions also
   p_office_id_masks      in  varchar2 default null,  -- delimited list of office id masks, defaults to user's office
	p_delimiter            in  varchar2 default ',')  -- delimiter for masks, defaults to comma
is
   type rec1_t is record(office_id varchar2(16), id varchar2(256));
   type rec2_t is record(office_id varchar2(16), id varchar2(256), description varchar2(256));
   l_include_descriptions boolean := cwms_util.return_true_or_false(p_include_descriptions);
   l_rec1                 rec1_t;
   l_rec2                 rec2_t;
   l_cursor               sys_refcursor;
   l_ids                  clob;
   l_first                boolean := true;

   procedure write_clob(p1 varchar2, p2 varchar2)
   is
      l_data varchar2(32767);
   begin
      if l_first then
         l_data := p1
            || cwms_util.field_separator
            || p2;
         l_first := false;
      else
         l_data := cwms_util.record_separator
            || p1
            || cwms_util.field_separator
            || p2;
      end if;
      dbms_lob.writeappend(l_ids, length(l_data), l_data);
   end;

   procedure write_clob(p1 varchar2, p2 varchar2, p3 varchar2)
   is
      l_data varchar2(32767);
   begin
      if l_first then
         l_data := p1
            || cwms_util.field_separator
            || p2
            || cwms_util.field_separator
            || p3;
         l_first := false;
      else
         l_data := cwms_util.record_separator
            || p1
            || cwms_util.field_separator
            || p2
            || cwms_util.field_separator
            || p3;
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

   dbms_lob.close(l_ids);
   p_ids := l_ids;
end get_matching_ids;

--
-- get code for id
--
procedure get_text_code(
   p_text_code      out number,                 -- the code for use in foreign keys
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_office_id      in  varchar2 default null)  -- office id, defaults current user's office
is
   l_id               varchar2(256) := upper(p_id);
   l_office_code      number := cwms_util.get_office_code(p_office_id);
   l_cwms_office_code number := cwms_util.get_office_code('CWMS');
begin
   select clob_code
     into p_text_code
     from at_clob
    where office_code in (l_office_code, l_cwms_office_code)
      and id = l_id;
end get_text_code;

--
-- get code for id
--
function get_text_code(
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number                               -- the code for use in foreign keys
is
   l_text_code number;
begin
   get_text_code(l_text_code, p_id, p_office_id);
   return l_text_code;
end get_text_code;

end;
/

show errors;
commit;

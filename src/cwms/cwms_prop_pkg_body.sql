CREATE OR REPLACE PACKAGE BODY cwms_properties
AS
-------------------------------------------------------------------------------
-- function str_tab_tab2property_info_tab(...)
--
--
   FUNCTION str_tab_tab2property_info_tab(
      p_text_tab in cwms_util.str_tab_tab_t)
      return property_info_tab_t
   is
      l_property_tab property_info_tab_t := property_info_tab_t();
      i pls_integer := p_text_tab.first;
   begin 
      while i is not null loop
         if p_text_tab(i).count != 3 then
            cwms_err.raise('INVALID_ITEM', 'Record with ' || p_text_tab(i).count || ' fields', 'property record.');
         end if;
        l_property_tab.extend;
        l_property_tab(i).office_id := p_text_tab(i)(1);
        l_property_tab(i).category  := p_text_tab(i)(2);
        l_property_tab(i).id        := p_text_tab(i)(3);
        i := p_text_tab.next(i);
      end loop;
       
      return l_property_tab;
      
   end str_tab_tab2property_info_tab;

-------------------------------------------------------------------------------
-- procedure get_properties(...)
--
--
   PROCEDURE get_properties (
      p_cwms_cat      OUT sys_refcursor,
      p_property_info IN  property_info_tab_t)
   is
      l_office_code     number(10)    := null;
      l_office_id       varchar2(16);
      l_prop_category   varchar2(256);
      l_prop_id         varchar2(256);
      l_query           varchar2(32767);
      l_output          varchar(1000);
   begin
      p_cwms_cat := null;
      if p_property_info is not null then
         for i in p_property_info.first .. p_property_info.last loop
            --l_office_id := upper(nvl(p_property_info(i).office_id, cwms_util.user_office_id));
            l_office_id := upper(p_property_info(i).office_id);
            l_prop_category :=
                 upper(replace(replace(nvl(p_property_info(i).category, '%'), '*', '%'), '?', '_'));
            l_prop_id :=
                 upper(replace(replace(nvl(p_property_info(i).id, '%'), '*', '%'), '?', '_'));
            if i = 1 then
               l_query := 
                  'select o.office_id, p.prop_category, p.prop_id, p.prop_value, p.prop_comment '
                  || 'from at_properties p, cwms_office o '
                  || 'where ';
            end if;
            l_query := l_query 
               || '(o.office_id = '''|| l_office_id 
               || ''' and p.office_code = o.office_code'
               || ' and upper(p.prop_category) like ''' || l_prop_category || ''' escape ''\'' '
               || ' and upper(p.prop_id) like ''' || l_prop_id || ''' escape ''\'')';
            if i < p_property_info.last then
               l_query := l_query || ' or ';
            else
               l_query := l_query || ' order by o.office_id, upper(p.prop_category), upper(p.prop_id) asc';
            end if;
         end loop;
       open p_cwms_cat for l_query;
     end if;
   end get_properties;
   
-------------------------------------------------------------------------------
-- function set_properties(...)
--
--
   FUNCTION set_properties (p_property_info IN  property_info2_tab_t)
   return binary_integer
   is
      l_office_code     number(10)    := null;
      l_office_id       varchar2(16);
      l_prop_category   varchar2(256);
      l_prop_id         varchar2(256);
      l_prop_value      varchar2(256);
      l_prop_comment    varchar2(256);
      l_table_row       at_properties%rowtype;
      l_updated         boolean;
      l_fetch_again     boolean;
      l_success_count   binary_integer := 0;
      cursor l_query is 
         select office_code, prop_category, prop_id, prop_value, prop_comment
         from   at_properties
         where  office_code in (select office_code from cwms_office where office_id = l_office_id)
                and upper(prop_category) = upper(l_prop_category)
                and upper(prop_id) =  upper(l_prop_id)
         for update of prop_value, prop_comment;
   begin
      if p_property_info is null then 
         return 0;
      end if;
      for i in p_property_info.first .. p_property_info.last loop 
         -- l_office_id := upper(nvl(p_property_info(i).office_id, cwms_util.user_office_id));
         l_office_id     := upper(p_property_info(i).office_id);
         l_prop_category := p_property_info(i).category;
         l_prop_id       := p_property_info(i).id;
         open l_query;
         fetch l_query into l_table_row;
         if l_query%notfound then
            ------------
            -- insert --
            ------------
            begin
               select office_code into l_table_row.office_code from cwms_office where office_id = l_office_id;
               l_table_row.prop_category := p_property_info(i).category;
               l_table_row.prop_id       := p_property_info(i).id;
               l_table_row.prop_value    := p_property_info(i).value;
               l_table_row.prop_comment  := p_property_info(i).comment;
               begin
                  insert into at_properties values l_table_row;
                  l_success_count := l_success_count + 1;
               exception
                  when others then
                       dbms_output.put_line('Cannot insert: ');
                       dbms_output.put_line('   Office_id = ' || l_office_id);
                       dbms_output.put_line('   Category  = ' || l_table_row.prop_category);
                       dbms_output.put_line('   Name      = ' || l_table_row.prop_id);
                       dbms_output.put_line('   Value     = ' || l_table_row.prop_value);
                       dbms_output.put_line('   Comment   = ' || l_table_row.prop_comment);
                       dbms_output.put_line('   Error     : ' || sqlerrm);
               end;
            exception
               when no_data_found then null;
            end;
         else
            ------------
            -- update --
            ------------
            begin
               l_updated := false;
               if nvl(l_table_row.prop_value, '~') != nvl(p_property_info(i).value, '~') then
                  l_updated := true;
               end if;
               if nvl(l_table_row.prop_comment, '~') != nvl(p_property_info(i).comment, '~') then
                  l_updated := true;
               end if;
               if l_updated then
                  begin
                     update at_properties
                     set prop_value = p_property_info(i).value, prop_comment = p_property_info(i).comment 
                     where current of l_query;
                     l_success_count := l_success_count + 1;
                  exception
                     when others then
                          dbms_output.put_line('Cannot update: ');
                          dbms_output.put_line('   Office_id = ' || l_office_id);
                          dbms_output.put_line('   Category  = ' || l_table_row.prop_category);
                          dbms_output.put_line('   Name      = ' || l_table_row.prop_id);
                          dbms_output.put_line('   Value     = ' || l_table_row.prop_value);
                          dbms_output.put_line('   Comment   = ' || l_table_row.prop_comment);
                          dbms_output.put_line('   Error     : ' || sqlerrm);
                  end;
               end if;
            exception
               when no_data_found then null;
            end;
         end if;
         close l_query;
      end loop;
      commit;
      return l_success_count;
   end set_properties;
   
-------------------------------------------------------------------------------
-- procedure get_properties(...)
--
--
   PROCEDURE get_properties (
      p_cwms_cat      OUT sys_refcursor,
      p_property_info IN  VARCHAR2)
   is
      l_property_tab property_info_tab_t := property_info_tab_t();
      l_text_table cwms_util.str_tab_tab_t;
      i pls_integer;
   begin 
      p_cwms_cat := null;
      if p_property_info is null then return; end if;
      l_text_table := cwms_util.parse_string_recordset(p_property_info);
      i := l_text_table.first;
      while i is not null loop
         if l_text_table(i).count != 3 then
            cwms_err.raise('INVALID_ITEM', 'Record with ' || l_text_table(i).count || ' fields', 'property record.');
         end if;
        l_property_tab.extend;
        l_property_tab(i).office_id := l_text_table(i)(1);
        l_property_tab(i).category  := l_text_table(i)(2);
        l_property_tab(i).id        := l_text_table(i)(3);
        i := l_text_table.next(i);
      end loop;
      
      get_properties(p_cwms_cat, l_property_tab);
      
   end get_properties;                                                         
   
   
-------------------------------------------------------------------------------
-- procedure get_properties(...)
--
--
   PROCEDURE get_properties (
      p_cwms_cat      OUT sys_refcursor,
      p_property_info IN  CLOB)
   is
      l_property_tab property_info_tab_t := property_info_tab_t();
      l_text_table cwms_util.str_tab_tab_t;
   begin
      p_cwms_cat := null;
      if p_property_info is null then return; end if;
      l_text_table := cwms_util.parse_clob_recordset(p_property_info);
      for i in l_text_table.first .. l_text_table.last loop
         if l_text_table(i).count != 3 then
            cwms_err.raise('INVALID_ITEM', 'Record with ' || l_text_table(i).count || ' fields', 'property record.');
         end if;
        l_property_tab.extend;
        l_property_tab(i).office_id := l_text_table(i)(1);
        l_property_tab(i).category  := l_text_table(i)(2);
        l_property_tab(i).id        := l_text_table(i)(3);
      end loop;
      
      get_properties(p_cwms_cat, l_property_tab);
      
   end get_properties;                                                         
   
-------------------------------------------------------------------------------
-- function get_properties_xml(...)
--
--
   FUNCTION get_properties_xml (
      p_property_info IN VARCHAR2)
      return CLOB
   is
      l_xml clob;
      l_properties sys_refcursor := null;  
      l_prop_row property_info2_t;  
      l_last_office varchar2(16) := ' ';
      l_indent varchar2(256);
      l_categories cwms_util.str_tab_t := cwms_util.str_tab_t();
      l_ids cwms_util.str_tab_t := cwms_util.str_tab_t();
      l_this_category cwms_util.str_tab_t := cwms_util.str_tab_t();
      l_this_id cwms_util.str_tab_t := cwms_util.str_tab_t();
      l_level binary_integer := 0;
      spc constant varchar2(1) := ' ';
      nl constant varchar(1) := chr(10);
      
      procedure write_clob(p_clob in out nocopy clob, p_data varchar2) is
      begin
         dbms_lob.writeappend(p_clob, length(p_data), p_data);
      end;
      
      procedure set_category(p_category in varchar2) is
         l_pos  binary_integer;
         l_part varchar2(256);
         l_category varchar(256) := p_category;
      begin
         l_this_category.delete;
         loop     
            l_pos := nvl(instr(l_category, '.'), 0);
            case l_pos
               when 0 then
                  l_part := l_category;
                  l_category := null;
               when 1 then
                  l_part := '';
                  l_category := substr(l_category, 2);
               else
                  l_part := substr(l_category, 1, l_pos - 1);
                  l_category := substr(l_category, l_pos + 1);
            end case;
            l_this_category.extend;
            l_this_category(l_this_category.last) := l_part;
            exit when l_pos = 0;
         end loop;
      end;
      
      procedure push_category(p_category in varchar2) is
      begin         
         l_categories.extend;
         l_categories(l_categories.count) := p_category;
         l_level := l_level + 1;
         l_indent := l_indent || spc;
         write_clob(l_xml, l_indent || '<category name="' || p_category || '">' || nl);
      end;
      
      procedure pop_category is
      begin         
         write_clob(l_xml, l_indent || '</category>' || nl);
         l_categories.trim;
         l_level := l_level - 1;
         l_indent := substr(l_indent, 1, length(spc) * l_level);
      end;
       
      procedure pop_categories is
      begin
         while l_categories.count > 0 loop
            pop_category;
         end loop;
      end;
       
      procedure set_id(p_id in varchar2) is
         l_pos  binary_integer;
         l_part varchar2(256);
         l_id varchar(256) := p_id;
      begin
         l_this_id.delete;
         loop     
            l_pos := nvl(instr(l_id, '.'), 0);
            case l_pos
               when 0 then
                  l_part := l_id;
                  l_id := null;
               when 1 then
                  l_part := '';
                  l_id := substr(l_id, 2);
               else
                  l_part := substr(l_id, 1, l_pos - 1);
                  l_id := substr(l_id, l_pos + 1);
            end case;
            l_this_id.extend;
            l_this_id(l_this_id.count) := l_part;
            exit when l_pos = 0;
         end loop;
      end;
      
      procedure push_id(p_id in varchar2) is
      begin
         l_ids.extend;
         l_ids(l_ids.count) := p_id;
         l_level := l_level + 1;
         l_indent := l_indent || spc;
         write_clob(l_xml, l_indent || '<id name="' || p_id || '">' || nl);
      end;
      
      procedure pop_id is
      begin
         write_clob(l_xml, l_indent || '</id>' || nl);
         l_ids.trim;
         l_level := l_level - 1;    
         l_indent := substr(l_indent, 1, length(spc) * l_level);
      end;
       
      procedure pop_ids is
      begin
         while l_ids.count > 0 loop
            pop_id;
         end loop;
      end;
      
   begin                            
      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      write_clob(l_xml, '<?xml version="1.0" encoding="UTF-8"?>' || nl);
      write_clob(l_xml, '<cwms_properties>' || nl);
      l_level := 1;
      l_indent := spc;
      get_properties(
         l_properties, 
         str_tab_tab2property_info_tab(cwms_util.parse_string_recordset(p_property_info)));
      loop
         fetch l_properties into l_prop_row; 
         exit when l_properties%notfound; 
         if l_prop_row.office_id != l_last_office then
            pop_ids;
            pop_categories;                                  
            if l_last_office != '' then
               write_clob(l_xml, l_indent || '</office>' || nl);
            end if;
            write_clob(l_xml, l_indent || '<office name="' || l_prop_row.office_id || '">' || nl);
            l_last_office := l_prop_row.office_id;
         end if;
         set_category(l_prop_row.category);
         for i in l_this_category.first .. l_this_category.count loop
            if i <= l_categories.count then
               if l_categories(i) != l_this_category(i) then
                  pop_ids;
                  while l_categories.count >= i loop
                     pop_category;
                  end loop;
               end if;
            end if;
            if i > l_categories.count then
               pop_ids;
               push_category(l_this_category(i)); 
            end if;
         end loop;
         set_id(l_prop_row.id);
         for i in l_this_id.first .. l_this_id.last loop
            if i <= l_ids.count then
               if l_ids(i) != l_this_id(i) then
                  while l_ids.count >= i loop
                     pop_id;
                  end loop;
               end if;
            end if;
            if i > l_ids.count then
               push_id(l_this_id(i));
            end if;
         end loop;
         if l_prop_row.value is null then
            write_clob(l_xml, l_indent || spc || '<value/>' || nl);
         else
            write_clob(l_xml, l_indent || spc || '<value text="' || l_prop_row.value || '"/>' || nl);
         end if;
         if l_prop_row.comment is null then
            write_clob(l_xml, l_indent || spc || '<comment/>' || nl);
         else
            write_clob(l_xml, l_indent || spc || '<comment text="' || l_prop_row.comment || '"/>' || nl);
         end if;
      end loop;
      close l_properties;
      pop_ids;
      pop_categories;
      write_clob(l_xml,  spc || '</office>' || nl);
      write_clob(l_xml,  '</cwms_properties>' || nl);
      dbms_lob.close(l_xml);
      return l_xml;
   end get_properties_xml;
   
-------------------------------------------------------------------------------
-- function get_property(...)
--
--
   FUNCTION get_property (
      p_office_id in varchar2,
      p_category  in varchar2,
      p_id        in varchar2)
      return varchar2
   is
      l_office_id  varchar2(16);
      l_prop_value varchar2(256) := null;
   begin
      begin
         l_office_id := upper(p_office_id);
         select prop_value
           into l_prop_value
           from at_properties p, cwms_office o
          where o.office_id = l_office_id
            and p.office_code = o.office_code
            and upper(p.prop_category) = upper(p_category)
            and upper(p.prop_id) = upper(p_id);
      exception
         when others then null;
      end;
      
      return l_prop_value;
           
   end get_property;
   
-------------------------------------------------------------------------------
-- function set_properties(...)
--
--
   FUNCTION set_properties (p_property_info IN VARCHAR2)
   return binary_integer
   is
      l_property_tab property_info2_tab_t := property_info2_tab_t();
      l_text_table cwms_util.str_tab_tab_t;
   begin
      if p_property_info is null then return 0; end if;
      l_text_table := cwms_util.parse_string_recordset(p_property_info);
      for i in l_text_table.first .. l_text_table.last loop
         if l_text_table(i).count != 5 then
            cwms_err.raise('INVALID_ITEM', 'Record with ' || l_text_table(i).count || ' fields', 'property record.');
         end if;
        l_property_tab.extend;
        l_property_tab(i).office_id := l_text_table(i)(1);
        l_property_tab(i).category  := l_text_table(i)(2);
        l_property_tab(i).id        := l_text_table(i)(3);
        l_property_tab(i).value     := l_text_table(i)(4);
        l_property_tab(i).comment   := l_text_table(i)(5);
      end loop;
      return set_properties(l_property_tab);
   end set_properties;
   
-------------------------------------------------------------------------------
-- function set_properties(...)
--
--
   FUNCTION set_properties (p_property_info IN CLOB)
   return binary_integer
   is
      l_property_tab property_info2_tab_t := property_info2_tab_t();
      l_text_table cwms_util.str_tab_tab_t;
   begin
      if p_property_info is null then return 0; end if;
      l_text_table := cwms_util.parse_clob_recordset(p_property_info);
      for i in l_text_table.first .. l_text_table.last loop
         if l_text_table(i).count != 5 then
            cwms_err.raise('INVALID_ITEM', 'Record with ' || l_text_table(i).count || ' fields', 'property record.');
         end if;
        l_property_tab.extend;
        l_property_tab(i).office_id := l_text_table(i)(1);
        l_property_tab(i).category  := l_text_table(i)(2);
        l_property_tab(i).id        := l_text_table(i)(3);
        l_property_tab(i).value     := l_text_table(i)(4);
        l_property_tab(i).comment   := l_text_table(i)(5);
      end loop;
      return set_properties(l_property_tab);
   end set_properties;
   
-------------------------------------------------------------------------------
-- procedure set_property(...)
--
--
   PROCEDURE set_property (
      p_office_id in varchar2,
      p_category  in varchar2,
      p_id        in varchar2,
      p_value     in varchar2,
      p_comment   in varchar2)
   is
      l_office_id  varchar2(16);
      l_table_row  at_properties%rowtype;
      
      cursor l_query is 
         select office_code, prop_category, prop_id, prop_value, prop_comment
         from   at_properties
         where  office_code in (select office_code from cwms_office where office_id = l_office_id)
                and upper(prop_category) = upper(p_category)
                and upper(prop_id) =  upper(p_id)
         for update of prop_value, prop_comment;
   begin
      -- l_office_id := upper(nvl(p_office_id, cwms_util.user_office_id));
      l_office_id := upper(p_office_id);
      open l_query;
      fetch l_query into l_table_row;
      if l_query%notfound then
         ------------
         -- insert --
         ------------
         begin
            select office_code into l_table_row.office_code from cwms_office where office_id = l_office_id;
         exception
            when no_data_found then
               cwms_err.raise('INVALID_OFFICE_ID', p_office_id);
         end;
         l_table_row.prop_category := p_category;
         l_table_row.prop_id       := p_id;
         l_table_row.prop_value    := p_value;
         l_table_row.prop_comment  := p_comment;
         insert into at_properties values l_table_row;
         
      else
         ------------
         -- update --
         ------------
         update at_properties
            set prop_value = p_value, prop_comment = p_comment
          where current of l_query;
      end if;
      close l_query;
      
   end set_property;
   
END cwms_properties;
/
show errors;

create or replace type body rating_template_t
as
   constructor function rating_template_t(
      p_template_code in number)
   return self as result
   is
   begin
      init(p_template_code);
      return;
   end;
   
   constructor function rating_template_t(
      p_office_id         in varchar2,
      p_version           in varchar2,
      p_ind_parameters    in rating_ind_par_spec_tab_t,
      p_dep_parameter_id  in varchar2,
      p_description       in varchar2)
   return self as result
   is
   begin
      self.office_id        := p_office_id;
      self.version          := p_version;
      self.ind_parameters   := p_ind_parameters;
      self.dep_parameter_id := p_dep_parameter_id;
      self.description      := p_description;
      for i in 1..ind_parameters.count  loop
         self.parameters_id := self.parameters_id || ind_parameters(i).parameter_id;
         if i < ind_parameters.count then
            self.parameters_id := self.parameters_id || cwms_rating.separator3;
         end if;
      end loop;
      self.parameters_id := self.parameters_id || cwms_rating.separator2 || dep_parameter_id;
      return;
   end;
   
   constructor function rating_template_t(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   return self as result
   is
   begin
      init(p_office_id, p_parameters_id, p_version);
      return;
   end;
   
   constructor function rating_template_t(
      p_office_id   in varchar2,
      p_template_id in varchar2)
   return self as result
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, cwms_rating.separator1);
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id,
            'Rating template identifier');
      end if;
      init(p_office_id, l_parts(1), l_parts(2));
      return;
   end;
   
   constructor function rating_template_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml   xmltype;
      l_node  xmltype;
      l_parts str_tab_t;
      i       binary_integer;
      ------------------------------
      -- local function shortcuts --
      ------------------------------
      function get_node(p_xml in xmltype, p_path in varchar2) return xmltype is
      begin
         return cwms_util.get_xml_node(p_xml, p_path);
      end;
      function get_text(p_xml in xmltype, p_path in varchar2) return varchar2 is
      begin
         return cwms_util.get_xml_text(p_xml, p_path);
      end;
      function get_number(p_xml in xmltype, p_path in varchar2) return number is
      begin
         return cwms_util.get_xml_number(p_xml, p_path);
      end;
   begin
      if p_xml.existsnode('//rating-template') = 1 then
         l_xml := get_node(p_xml, '//rating-template');
      else
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating-template> element');
      end if;         
      self.office_id := get_text(l_xml, '/rating-template/@office-id');
      if self.office_id is null then
         cwms_err.raise(
            'ERROR',
            'Required "office-id" attribute is not found in <rating-template> element');
      end if;         
      self.parameters_id := get_text(l_xml, '/rating-template/parameters-id');
      if self.parameters_id is null then
         cwms_err.raise(
            'ERROR',
            '<parameters-id> element is not found under <rating-template> element');
      end if;         
      self.version := get_text(l_xml, '/rating-template/version');
      if self.version is null then
         cwms_err.raise(
            'ERROR',
            '<version> element is not found under <rating-template> element');
      end if;         
      self.dep_parameter_id := get_text(l_xml, '/rating-template/dep-parameter');
      if self.dep_parameter_id is null then
         cwms_err.raise(
            'ERROR',
            '<dep-parameter> element is not found under <rating-template> element');
      end if;
      for i in 1..9999999 loop
         l_node := get_node(l_xml, '/rating-template/ind-parameter-specs/ind-parameter-spec['||i||']');
         exit when l_node is null;
         if i = 1 then
            self.ind_parameters := rating_ind_par_spec_tab_t();
         end if;
         self.ind_parameters.extend;
         self.ind_parameters(i) := rating_ind_param_spec_t(l_node);
      end loop;
      self.description := get_text(l_xml, '/rating-template/description');
      self.validate_obj;
      return;
   end;
   
   member procedure init(
      p_template_code in number)
   is
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         ( select *
             from at_rating_template
            where template_code = p_template_code
         ) 
      loop
         self.ind_parameters    := rating_ind_par_spec_tab_t();
         self.parameters_id     := rec.parameters_id;
         self.version           := rec.version;        
         self.dep_parameter_id  := cwms_util.get_parameter_id(rec.dep_parameter_code);
         self.description       := rec.description; 
           
         select office_id
           into self.office_id
           from cwms_office
          where office_code = rec.office_code;
          
         for rec2 in 
            (  select ind_param_spec_code,
                      parameter_position
                 from at_rating_ind_param_spec
                where template_code = p_template_code
             order by parameter_position
            )
         loop
            self.ind_parameters.extend;
            self.ind_parameters(rec2.parameter_position) := -- will blow up if parameter_position is not same as .count 
               rating_ind_param_spec_t(rec2.ind_param_spec_code);
         end loop;          
      end loop;
      self.validate_obj;
   end;
   
   member procedure init(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   is
      l_template_code number;
   begin
      l_template_code := rating_template_t.get_template_code(
         p_parameters_id,
         p_version,
         cwms_util.get_office_code(p_office_id));
         
      init(l_template_code);
   end;
   
   member procedure validate_obj
   is
      l_code  number(10);
      l_parts str_tab_t;
      l_base_id varchar2(16);
      l_sub_id  varchar2(32);
   begin
      ---------------
      -- office_id --
      ---------------
      begin
         select office_code
           into l_code
           from cwms_office
          where office_id = upper(self.office_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_OFFICE_ID',
               self.office_id);
      end;
      -------------
      -- version --
      -------------
      if self.version is null then
         cwms_err.raise(
            'ERROR',
            'Rating template version cannot be null');
      end if;
      -------------------
      -- parameters_id --
      -------------------
      l_parts := cwms_util.split_text(self.parameters_id, cwms_rating.separator2);
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            self.parameters_id,
            'Rating template parameters identifier');
      end if;
      if upper(l_parts(2)) != upper(self.dep_parameter_id) then
         cwms_err.raise(
            'ERROR',
            'Rating template dependent parameter ('
            ||self.dep_parameter_id
            ||') does not agree with parameters identifier ('
            ||self.parameters_id
            ||')');
      end if;
      l_parts := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      if l_parts.count != self.ind_parameters.count then
         cwms_err.raise(
            'ERROR',
            'Rating template parameters identifier ('
            ||self.parameters_id
            ||') has '
            ||l_parts.count
            ||' independent parameters, but template contains '
            ||self.ind_parameters.count
            ||' independent parameters');
      end if;
      for i in 1..l_parts.count loop
         if upper(l_parts(i)) != upper(self.ind_parameters(i).parameter_id) then
            cwms_err.raise(
               'ERROR',
               'Rating template independent parameter position '
               ||i
               ||' ('
               ||self.ind_parameters(i).parameter_id
               ||') does not agree with parameters_id ('
               ||l_parts(i)
               ||')');
         end if;
      end loop;
      ---------------------------------         
      -- validate the lookup methods --
      ---------------------------------         
      for i in 1..self.ind_parameters.count loop
         if self.ind_parameters(i).in_range_rating_method is null or
            self.ind_parameters(i).in_range_rating_method = 'NEAREST'
         then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.ind_parameters(i).in_range_rating_method, '<NULL>'),
               'CWMS in-range rating template method');
         end if;
         if self.ind_parameters(i).out_range_low_rating_method is null or
            self.ind_parameters(i).out_range_low_rating_method in ('PREVIOUS', 'LOWER')
         then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.ind_parameters(i).out_range_low_rating_method, '<NULL>'),
               'CWMS out-range-low rating template method');
         end if;
         if self.ind_parameters(i).out_range_high_rating_method is null or
            self.ind_parameters(i).out_range_high_rating_method in ('NEXT', 'HIGHER')
         then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.ind_parameters(i).out_range_high_rating_method, '<NULL>'),
               'CWMS out-range-high rating template method');
         end if;
      end loop;
      -----------------------------
      -- case correct parameters --
      -----------------------------
      for i in 1..self.ind_parameters.count loop
         l_base_id := cwms_util.get_base_id(self.ind_parameters(i).parameter_id);
         l_sub_id := cwms_util.get_sub_id(self.ind_parameters(i).parameter_id);
         begin
            l_code := cwms_util.get_base_param_code(l_base_id, 'F');
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_PARAM_ID',
                  self.ind_parameters(i).parameter_id);
         end;
         select base_parameter_id
           into l_base_id 
           from cwms_base_parameter
          where base_parameter_code = l_code;
         if l_sub_id is not null then
            begin
               select distinct
                      sub_parameter_id
                 into l_sub_id 
                 from at_parameter
                where upper(sub_parameter_id) = upper(l_sub_id)
                  and db_office_code in (cwms_util.user_office_code, cwms_util.db_office_code_all); 
            exception                                                                                
               when no_data_found then null;
            end;
         end if;
         self.ind_parameters(i).parameter_id := l_base_id
            ||substr('-', 1, length(l_sub_id))
            ||l_sub_id;            
      end loop;
      l_base_id := cwms_util.get_base_id(self.dep_parameter_id);
      l_sub_id := cwms_util.get_sub_id(self.dep_parameter_id);
      begin
         l_code := cwms_util.get_base_param_code(l_base_id, 'F');
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_PARAM_ID',
               self.dep_parameter_id);
      end;
      select base_parameter_id
        into l_base_id 
        from cwms_base_parameter
       where base_parameter_code = l_code;
      if l_sub_id is not null then
         begin
            select distinct
                   sub_parameter_id
              into l_sub_id 
              from at_parameter
             where upper(sub_parameter_id) = upper(l_sub_id)
               and db_office_code in (cwms_util.user_office_code, cwms_util.db_office_code_all); 
         exception                                                                                
            when no_data_found then null;
         end;
      end if;
      self.dep_parameter_id := l_base_id
         ||substr('-', 1, length(l_sub_id))
         ||l_sub_id;
      ----------------------------------------------------------------------                     
      -- reconstruct the parameters id from the case-corrected parameters --
      ----------------------------------------------------------------------
      self.parameters_id := self.ind_parameters(1).parameter_id;
      for i in 2..self.ind_parameters.count loop
         self.parameters_id := self.parameters_id 
            ||cwms_rating.separator3
            ||self.ind_parameters(i).parameter_id;
      end loop;                     
      self.parameters_id := self.parameters_id 
         ||cwms_rating.separator2
         ||self.dep_parameter_id;
         return;
   end;
      
   member function get_office_code
   return number
   is
      l_office_code number;
   begin
      select office_code
        into l_office_code
        from cwms_office
       where office_id = upper(self.office_id);
       
      return l_office_code;       
   end;
   
   member function get_dep_parameter_code
   return number
   is
      l_base_param_id varchar2(16) := cwms_util.get_base_id(self.dep_parameter_id);
      l_sub_param_id  varchar2(32) := cwms_util.get_sub_id(self.dep_parameter_id);
   begin
      return cwms_ts.get_parameter_code(l_base_param_id, l_sub_param_id, self.office_id, 'T');
   end;
   
   member procedure store(
      p_fail_if_exists in varchar2)
   is
      l_rec at_rating_template%rowtype;
      l_max_parameter_position integer := self.ind_parameters.count;
   begin
      l_rec.office_code   := self.get_office_code;
      l_rec.parameters_id := self.parameters_id;
      l_rec.version       := self.version;
      
      select *
        into l_rec
        from at_rating_template
       where office_code = l_rec.office_code
         and upper(parameters_id) = upper(l_rec.parameters_id)
         and upper(version) = upper(l_rec.version);

      if cwms_util.is_true(p_fail_if_exists) then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Rating template',
            self.office_id || '/' || self.parameters_id || cwms_rating.separator1 || self.version);
      end if;
      
      l_rec.dep_parameter_code := self.get_dep_parameter_code;
      l_rec.description        := self.description;
      
      update at_rating_template
         set row = l_rec
       where template_code = l_rec.template_code;
       
      for i in 1..l_max_parameter_position loop
         self.ind_parameters(i).store(l_rec.template_code, p_fail_if_exists);
      end loop;                
      
      delete 
        from at_rating_ind_param_spec
       where template_code = l_rec.template_code
         and parameter_position > l_max_parameter_position;
         
   exception         
      when no_data_found then
         l_rec.template_code      := cwms_seq.nextval;
         l_rec.dep_parameter_code := self.get_dep_parameter_code;
         l_rec.description        := self.description;
         
         insert
           into  at_rating_template
         values l_rec;
         
         for i in 1..l_max_parameter_position loop
            self.ind_parameters(i).store(l_rec.template_code, p_fail_if_exists);
         end loop;                
   end;

   member function to_xml
   return xmltype
   is
   begin
      return xmltype(self.to_clob);
   end;

   member function to_clob
   return clob
   is
      l_text clob;
   begin
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text, '<rating-template office-id="'||self.office_id||'">'
         ||'<parameters-id>'||self.parameters_id||'</parameters-id>'
         ||'<version>'||self.version||'</version>'
         ||'<ind-parameter-specs>');
      for i in 1..self.ind_parameters.count loop
         cwms_util.append(l_text, self.ind_parameters(i).to_xml);
      end loop;
      cwms_util.append(l_text, '</ind-parameter-specs>'
         ||'<dep-parameter>'||self.dep_parameter_id||'</dep-parameter>'
         ||case self.description is null
              when true  then '<description/>'
              when false then '<description>'||self.description||'</description>'
           end
         ||'</rating-template>');
      dbms_lob.close(l_text);                  
      return l_text;
   end;

   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_id     in varchar2 default null)
   return number result_cache
   is
   begin
      return get_template_code(
         p_parameters_id,
         p_version,
         cwms_util.get_office_code(p_office_id));
   end;      
            
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_code   in number)
   return number result_cache
   is
      l_template_code number(10);
   begin
      select template_code
        into l_template_code
        from at_rating_template
       where office_code = p_office_code
         and upper(parameters_id) = upper(p_parameters_id)
         and upper(version) = upper(p_version);
         
      return l_template_code;
   exception
      when no_data_found then
         declare
            l_office_id varchar2(16);
         begin
            select office_id 
              into l_office_id 
              from cwms_office 
             where office_code = p_office_code;
             
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Rating template',
               l_office_id 
               || '/' 
               || p_parameters_id 
               || cwms_rating.separator1 
               || p_version);
         end;
   end;      
      
   static function get_template_code(
      p_template_id in varchar2,
      p_office_code in number)
   return number result_cache
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, cwms_rating.separator1);
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id,
            'Rating template identifier');
      end if;
      return rating_template_t.get_template_code(
         l_parts(1), 
         l_parts(2),
         p_office_code); 
   end;
   
end;
/
show errors;
